{
  lib,
  stdenv,
  fetchFromGitHub,
  qt5,
  openssl,
  protobuf,
  pkg-config,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ricochet-refresh";
  version = "3.0.34";

  src = fetchFromGitHub {
    owner = "blueprint-freespeech";
    repo = "ricochet-refresh";
    rev = "v${finalAttrs.version}-release";
    fetchSubmodules = true;
    hash = "sha256-/IT3K3PL2fNl4P7xzItVnI8xJx5MmKxhw3ZEX9rN7j4=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";

  strictDeps = true;

  buildInputs =
    (with qt5; [
      qtbase
      qttools
      qtmultimedia
      qtquickcontrols2
      qtwayland
    ])
    ++ [
      openssl
      protobuf
    ];

  nativeBuildInputs = [
    pkg-config
    protobuf
    cmake
    qt5.wrapQtAppsHook
  ];

  enableParallelBuilding = true;

  cmakeBuildType = "MinSizeRel";

  # https://github.com/blueprint-freespeech/ricochet-refresh/blob/main/BUILDING.md
  cmakeFlags = [
    (lib.cmakeBool "RICOCHET_REFRESH_INSTALL_DESKTOP" true)
    (lib.cmakeBool "USE_SUBMODULE_FMT" true)
  ];

  meta = {
    description = "Secure chat without DNS or WebPKI";
    mainProgram = "ricochet-refresh";
    longDescription = ''
      Ricochet Refresh is a peer-to-peer messenger app that uses Tor
      to connect clients.

      When you start Ricochet Refresh it creates a Tor hidden
      service on your computer.  The address of this hidden service
      is your anonymous identity on the Tor network and how others
      will be able to communicate with you.  When you start a chat
      with one of your contacts a Tor circuit is created between
      your machine and the your contact's machine.

      The original Ricochet uses onion "v2" hashed-RSA addresses,
      which are no longer supported by the Tor network.  Ricochet
      Refresh upgrades the original Ricochet protocol to use the
      current onion "v3" ed25519 addresses.
    '';
    homepage = "https://www.ricochetrefresh.net/";
    downloadPage = "https://github.com/blueprint-freespeech/ricochet-refresh/releases";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})
