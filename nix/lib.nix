{pkgs ? import <nixpkgs> {}}: let
  hostPlatform = pkgs.stdenv.hostPlatform or {};
  isIntel86 = hostPlatform.isx86 or false;
  isLinux = hostPlatform.isLinux or false;
  flakeLock = builtins.fromJSON (builtins.readFile ../flake.lock);
  getHash = name: flakeLock.nodes.${name}.locked.narHash;
  nixglSrc = pkgs.fetchFromGitHub {
    owner = "nix-community";
    repo = "nixGL";
    rev = "main";
    hash = getHash "nixgl";
  };
in {
  inherit getHash;
  nixgl =
    if isLinux
    then
      import nixglSrc {
        pkgs = pkgs;
        enable32bits = isIntel86;
        enableIntelX86Extensions = isIntel86;
      }
    else null;
}
