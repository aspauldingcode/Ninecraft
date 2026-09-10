{
  ancmp,
  bash,
  cmake,
  copyDesktopItems,
  glad,
  lib,
  makeNinecraftDesktopItems,
  makeWrapper,
  pkg-config,
  python312Packages,
  SDL2,
  stb,
  stdenv,
  unzip,
  wrapGAppsHook,
  zenity ? null,
  zlib,
  mcpeVersions,
  ninecraft-extract ? ../../tools/extract.sh,
  writeShellScriptBin,
  ...
}: let
  defaultVersion = mcpeVersions.a0_6_1 or mcpeVersions.a0_6_0;
  hostPlatform = stdenv.hostPlatform or {};
  hostSystem = hostPlatform.system or stdenv.system or "";
  isDarwinHost = builtins.match ".*-darwin" hostSystem != null;
  isLinuxHost = builtins.match ".*-linux" hostSystem != null;
in
stdenv.mkDerivation rec {
  pname = "ninecraft";
  version = "1.2.0";
  # dontUnpack = true;
  src = ../..;
  nativeBuildInputs =
    [
      cmake
      pkg-config
      copyDesktopItems
      makeWrapper
    ]
    ++ lib.optionals isLinuxHost [wrapGAppsHook];
  buildInputs =
    [
      python312Packages.jinja2
      zlib
      SDL2
    ];
  zenityBinary =
    if isDarwinHost
    then writeShellScriptBin "zenity" (builtins.readFile ../../tools/zenity-mac.sh)
    else if zenity == null
    then throw "zenity package is required on non-macOS platforms"
    else zenity;
  patches = [./use-system-dependancies.patch];
  dontWrapGApps = true;
  NIX_CFLAGS_COMPILE = lib.optionalString isDarwinHost "-DANDROID_ARM_LINKER";
  prePhases = "submoduleFetchPhase";
  patchPhase = ''
    runHook prePatch
    for patch in $patches; do
      echo "applying patch $patch"
      patch -p1 < $patch
    done
    runHook postPatch
  '' + lib.optionalString isDarwinHost ''
    # Disable ancmp on macOS and use stub headers
    substituteInPlace CMakeLists.txt \
      --replace-fail 'add_subdirectory(''${ANCMP_DIR} ''${ANCMP_DIR})' '# add_subdirectory(''${ANCMP_DIR} ''${ANCMP_DIR}) # Disabled on macOS'
    substituteInPlace ninecraft/CMakeLists.txt \
      --replace-fail 'target_link_libraries(ninecraft ''${CMAKE_DL_LIBS} ZLIB::ZLIB SDL2::SDL2 SDL2main glad ancmp)' \
                     'target_link_libraries(ninecraft ''${CMAKE_DL_LIBS} ZLIB::ZLIB SDL2::SDL2 SDL2main glad)'
    
    # Copy stub header and replace ancmp includes
    cp ${./ancmp-stubs-darwin.h} ninecraft/include/ninecraft/ancmp-stubs.h
    for f in $(find ninecraft \( -name '*.c' -o -name '*.h' \)); do
      sed -i'.bak' -e 's|<ancmp/android_dlfcn\.h>|<ninecraft/ancmp-stubs.h>|g' \
                    -e 's|<ancmp/android_alloc\.h>|<ninecraft/ancmp-stubs.h>|g' "$f"
      rm "$f.bak"
    done
  '';
  
  submoduleFetchPhase = ''
    export glad=$PWD/deps_src/glad
          export ancmp=$PWD/deps_src/ancmp
          export stb=$PWD/deps_src/stb
        mkdir -p deps_src
        cp --no-preserve=mode,ownership -r ${glad} $glad
        cp --no-preserve=mode,ownership -r ${ancmp} $ancmp
        cp --no-preserve=mode,ownership -r ${stb} $stb
        ls -al deps_src
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install ninecraft/ninecraft $out/bin/${pname}
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/${pname}" --set PATH ${lib.makeBinPath [zenityBinary]}
    makeWrapper ${ninecraft-extract} "$out/bin/${pname}-extract" --set PATH ${lib.makeBinPath [bash unzip]}
  '';

  desktopItems = makeNinecraftDesktopItems {
    version = defaultVersion;
  };

  meta = import ./meta.nix {inherit lib;};
}
