{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  accent ? "mauve",
  flavor ? "macchiato",
}: let
  pname = "catppuccin-kvantum";

  mkUpper = str: (lib.toUpper (builtins.substring 0 1 str)) + (builtins.substring 1 (builtins.stringLength str) str);
in
  lib.checkListOfEnum "${pname}: theme accent" ["blue" "flamingo" "green" "lavender" "maroon" "mauve" "peach" "pink" "red" "rosewater" "sapphire" "sky" "teal" "yellow"] [accent]
  lib.checkListOfEnum "${pname}: color flavor" ["latte" "frappe" "macchiato" "mocha"] [flavor]

  stdenvNoCC.mkDerivation {
    inherit pname;
    version = "unstable-2022-07-04";

    src = fetchFromGitHub {
      owner = "catppuccin";
      repo = "Kvantum";
      rev = "d1e174c85311de9715aefc1eba4b8efd6b2730fc";
      sha256 = "sha256-IrHo8pnR3u90bq12m7FEXucUF79+iub3I9vgH5h86Lk=";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/Kvantum
      cp -a src/Catppuccin-${mkUpper flavor}-${mkUpper accent} $out/share/Kvantum
      runHook postInstall
    '';

    meta = {
      description = "Soothing pastel theme for Kvantum";
      homepage = "https://github.com/catppuccin/Kvantum";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      maintainers = with lib.maintainers; [ bastaynav ];
    };
  }
