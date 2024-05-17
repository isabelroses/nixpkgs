{
  lib,
  dbus,
  glib,
  vips,
  openssl,
  webkitgtk,
  pkg-config,
  cargo-tauri,
  cairo,
  pngquant,
  rustPlatform,
  librsvg,
  wrapGAppsHook3,
  fetchFromGitHub,
  buildNpmPackage,
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

  frontend-build = buildNpmPackage {
    pname = "catppuccinifier-ui";
    inherit src sourceRoot version;

    packageJSON = "${sourceRoot}/package.json";
    npmDepsHash = "sha256-2YKrhZNAC+Z7TyxNkCMeXHb2zyGBiJTK1Z96hgoeWcI=";

    nativeBuildInputs = [ pkg-config ];

    buildInputs = [
      cairo
      librsvg
      vips
      webkitgtk
    ];

    configurePhase = ''
      runHook preConfigure
      ln -s $node_modules node_modules
      ln -sf ${lib.getExe pngquant} node_modules/pngquant-bin
      runHook postConfigure
    '';

    buildPhase = ''
      export HOME=$(mktemp -d)
      npm run build

      mkdir -p $out/dist
      cp -r dist/** $out/dist
    '';

    distPhase = "true";
    dontInstall = true;
  };
in
rustPlatform.buildRustPackage {
  pname = "catppuccinifier";
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

  postPatch = ''
    mkdir -p dist
    cp -R ${frontend-build}/dist/** dist

    substituteInPlace ./tauri.conf.json --replace '"distDir": "../dist",' '"distDir": "dist",'
    substituteInPlace ./tauri.conf.json --replace '"beforeBuildCommand": "npm run build",' '"beforeBuildCommand": "",'
  '';

  buildPhase = ''
    runHook preBuild

    cargo tauri build --bundles deb

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r target/release/bundle/deb/*/data/usr "$out"

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
