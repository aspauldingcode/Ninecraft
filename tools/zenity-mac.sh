#!/usr/bin/env bash

set -euo pipefail

if ! command -v osascript >/dev/null 2>&1; then
  echo "osascript is required for the zenity shim" >&2
  exit 1
fi

mode=""
title="Ninecraft"
text="Enter a value:"
column=""
choices=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --entry)
      mode="entry"
      shift
      ;;
    --list)
      mode="list"
      shift
      ;;
    --file-selection)
      mode="file"
      shift
      ;;
    --title=*)
      title="${1#--title=}"
      shift
      ;;
    --title)
      title="$2"
      shift 2
      ;;
    --text=*)
      text="${1#--text=}"
      shift
      ;;
    --text)
      text="$2"
      shift 2
      ;;
    --column=*)
      column="${1#--column=}"
      shift
      ;;
    --column)
      column="$2"
      shift 2
      ;;
    --*)
      # Ignore unsupported flags
      shift
      ;;
    *)
      choices+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$column" && "$mode" == "list" ]]; then
  title="${title:-$column}"
fi

if [[ -z "$mode" ]]; then
  echo "Unsupported zenity invocation" >&2
  exit 1
fi

show_entry() {
  local output
  if output=$(
    osascript - "$title" "$text" <<'OSA'
on run argv
  set dialogTitle to item 1 of argv
  set promptText to item 2 of argv
  try
    display dialog promptText default answer "" with title dialogTitle
    text returned of result
  on error number -128
    error number -128
  end try
end run
OSA
  ); then
    printf '%s\n' "$output"
  else
    exit 1
  fi
}

show_list() {
  if [[ ${#choices[@]} -eq 0 ]]; then
    echo "zenity shim: no choices provided" >&2
    exit 1
  fi
  local output
  if output=$(
    osascript - "$title" "$text" "${choices[@]}" <<'OSA'
on run argv
  set dialogTitle to item 1 of argv
  set promptText to item 2 of argv
  if (count of argv) < 3 then error number -128
  set choiceItems to items 3 thru (count of argv) of argv
  try
    set selection to choose from list choiceItems with title dialogTitle with prompt promptText default items {item 1 of choiceItems}
    if selection is false then error number -128
    item 1 of selection
  on error number -128
    error number -128
  end try
end run
OSA
  ); then
    printf '%s\n' "$output"
  else
    exit 1
  fi
}

show_file() {
  local output
  if output=$(
    osascript - "$title" "$text" <<'OSA'
on run argv
  set dialogTitle to item 1 of argv
  set promptText to item 2 of argv
  try
    set chosenFile to choose file with prompt promptText
    POSIX path of chosenFile
  on error number -128
    error number -128
  end try
end run
OSA
  ); then
    printf '%s\n' "$output"
  else
    exit 1
  fi
}

case "$mode" in
  entry) show_entry ;;
  list) show_list ;;
  file) show_file ;;
  *)
    echo "zenity shim: unsupported mode $mode" >&2
    exit 1
    ;;
esac

