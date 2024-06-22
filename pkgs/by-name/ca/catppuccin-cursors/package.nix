{ lib
, stdenvNoCC
, fetchFromGitHub
, inkscape
, xcursorgen
, hyprcursor
, flavor ? "macchiato"
, accents ? [ "mauve" ]
}:
let
  version = "0.3.0";
in

lib.checkListOfEnum "${pname}: theme accent" validAccents accents
lib.checkListOfEnum "${pname}: theme flavor" validFlavor [flavor]

stdenvNoCC.mkDerivation {
  pname = "catppuccin-cursors";
  inherit version;

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "cursors";
    rev = "v${version}";
    hash = "sha256-LJyBnXDUGBLOD4qPI7l0YC0CcqYTtgoMJc1H2yLqk9g=";
  };

  nativeBuildInputs = [ inkscape xcursorgen hyprcursor ];

  outputsToInstall = [];

  buildPhase = ''
    runHook preBuild

    patchShebangs .

    ./build -f ${flavor} -a ${builtins.toString accents} -h

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for accent in ${builtins.toString accents}
    do
      mv "dist/catppuccin-${flavor}-$accent-cursors" "$out/share/icons"
    done

    runHook postInstall
  '';

  meta = {
    description = "Catppuccin cursor theme based on Volantes";
    homepage = "https://github.com/catppuccin/cursors";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ dixslyf ];
  };
}
