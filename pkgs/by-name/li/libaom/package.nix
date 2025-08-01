{
  lib,
  stdenv,
  fetchurl,
  fetchzip,
  yasm,
  perl,
  cmake,
  pkg-config,
  python3,
  enableVmaf ? true,
  libvmaf,
  gitUpdater,

  # for passthru.tests
  ffmpeg,
  libavif,
  libheif,
}:

let
  isCross = stdenv.buildPlatform != stdenv.hostPlatform;
in
stdenv.mkDerivation rec {
  pname = "libaom";
  version = "3.12.1";

  src = fetchzip {
    url = "https://aomedia.googlesource.com/aom/+archive/v${version}.tar.gz";
    hash = "sha256-AAS6wfq4rZ4frm6+gwKoIS3+NVzPhhfW428WXJQ2tQ8=";
    stripRoot = false;
  };

  patches = [
    ./outputs.patch
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    # This patch defines `_POSIX_C_SOURCE`, which breaks system headers
    # on Darwin.
    (fetchurl {
      name = "musl.patch";
      url = "https://gitweb.gentoo.org/repo/gentoo.git/plain/media-libs/libaom/files/libaom-3.4.0-posix-c-source-ftello.patch?id=50c7c4021e347ee549164595280cf8a23c960959";
      hash = "sha256-6+u7GTxZcSNJgN7D+s+XAVwbMnULufkTcQ0s7l+Ydl0=";
    })
  ];

  nativeBuildInputs = [
    yasm
    perl
    cmake
    pkg-config
    python3
  ];

  propagatedBuildInputs = lib.optional enableVmaf libvmaf;

  env = lib.optionalAttrs stdenv.hostPlatform.isFreeBSD {
    # This can be removed when we switch to libcxx from llvm 20
    # https://github.com/llvm/llvm-project/pull/122361
    NIX_CFLAGS_COMPILE = "-D_XOPEN_SOURCE=700";
  };

  preConfigure = ''
    # build uses `git describe` to set the build version
    cat > $NIX_BUILD_TOP/git << "EOF"
    #!${stdenv.shell}
    echo v${version}
    EOF
    chmod +x $NIX_BUILD_TOP/git
    export PATH=$NIX_BUILD_TOP:$PATH
  '';

  # Configuration options:
  # https://aomedia.googlesource.com/aom/+/refs/heads/master/build/cmake/aom_config_defaults.cmake

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DENABLE_TESTS=OFF"
  ]
  ++ lib.optionals enableVmaf [
    "-DCONFIG_TUNE_VMAF=1"
  ]
  ++ lib.optionals (isCross && !stdenv.hostPlatform.isx86) [
    "-DCMAKE_ASM_COMPILER=${lib.getBin stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc"
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch32 [
    # armv7l-hf-multiplatform does not support NEON
    # see lib/systems/platform.nix
    "-DENABLE_NEON=0"
  ];

  postFixup = ''
    moveToOutput lib/libaom.a "$static"
  ''
  + lib.optionalString stdenv.hostPlatform.isStatic ''
    ln -s $static $out
  '';

  outputs = [
    "out"
    "bin"
    "dev"
    "static"
  ];

  passthru = {
    updateScript = gitUpdater {
      url = "https://aomedia.googlesource.com/aom";
      rev-prefix = "v";
      ignoredVersions = "(alpha|beta|rc).*";
    };
    tests = {
      inherit libavif libheif;
      ffmpeg = ffmpeg.override { withAom = true; };
    };
  };

  meta = {
    description = "Alliance for Open Media AV1 codec library";
    longDescription = ''
      Libaom is the reference implementation of the AV1 codec from the Alliance
      for Open Media. It contains an AV1 library as well as applications like
      an encoder (aomenc) and a decoder (aomdec).
    '';
    homepage = "https://aomedia.org/av1-features/get-started/";
    changelog = "https://aomedia.googlesource.com/aom/+/refs/tags/v${version}/CHANGELOG";
    maintainers = with lib.maintainers; [
      kiloreux
      dandellion
    ];
    platforms = lib.platforms.all;
    outputsToInstall = [ "bin" ];
    license = lib.licenses.bsd2;
  };
}
