{
  lib,
  dbus,
  pkgs,
  glib,
  vips,
  openssl,
  webkitgtk,
  pkg-config,
  cargo-tauri,
  cairo,
  callPackage,
  stdenvNoCC,
  pngquant,
  rustPlatform,
  librsvg,
  wrapGAppsHook3,
  fetchFromGitHub,
  nodePackages,
}:
let
  version = "8.0.0";
  src = fetchFromGitHub {
    owner = "lighttigerXIV";
    repo = "catppuccinifier";
    rev = version;
    hash = "sha256-CEjdCr7QgyQw+1VmeEyt95R0HKE0lAKZHrwahaxgJoU=";
  };

  sourceRoot = "${src.name}/src/catppuccinifier-gui";

  nodeDependencies =
    (callPackage ./composition.nix { inherit pkgs; }).nodeDependencies;

    ."pngquant-bin-6.0.1".override
      {
        dontNpmInstall = true;
        preRebuild = ''
          ln -s ${pngquant}/bin/pngquant ./vendor/pngquant
          npm run postinstall
        '';
      };

  frontend-build = stdenvNoCC.mkDerivation {
    pname = "catppuccinifier-gui-fe";
    inherit src sourceRoot version;

    nativeBuildInputs = [
      pkg-config
      nodePackages.npm
    ];

    buildInputs = [
      cairo
      librsvg
      vips
      webkitgtk
    ];

    configurePhase = ''
      runHook preConfigure

      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
      export PATH="${nodeDependencies}/bin:$PATH"

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      npm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/dist
      cp -r dist/** $out/dist

      runHook postInstall
    '';

    doDist = false;
  };
in
rustPlatform.buildRustPackage {
  pname = "catppuccinifier-gui";
  inherit version src;
  sourceRoot = "${sourceRoot}/src-tauri";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "catppuccinifier-rs-0.1.0" = "sha256-/lwc5cqLuCvGwcCiEHlYkbQZlS13z40OFVl26tpjsTQ=";
    };
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    pkg-config
    cargo-tauri
  ];

  buildInputs = [
    openssl
    dbus
    glib
    webkitgtk
  ];

  preConfigure = ''
    mkdir -p dist
    cp -R ${frontend-build}/dist/** dist
  '';

  postPatch = ''
    substituteInPlace ./tauri.conf.json \
      --replace-fail '"distDir": "../dist",' '"distDir": "dist",'
    substituteInPlace ./tauri.conf.json \
      --replace-fail '"beforeBuildCommand": "npm run build",' '"beforeBuildCommand": "",'
  '';

  buildPhase = ''
    runHook preBuild

    cargo tauri build --bundles deb

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp target/release/bundle/deb/*/data/usr/catppuccinifier-gui "$out/bin/catppuccinifier-gui"

    runHook postInstall
  '';

  meta = {
    description = "Apply catppuccin flavors to your wallpapers";
    homepage = "https://github.com/lighttigerXIV/catppuccinifier";
    maintainers = with lib.maintainers; [ isabelroses ];
    platforms = lib.platforms.linux;
    mainProgram = "catppuccinifier";
  };
}
