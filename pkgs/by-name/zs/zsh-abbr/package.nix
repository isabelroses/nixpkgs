{
  stdenv,
  lib,
  fetchFromGitHub,
  installShellFiles,
}:
stdenv.mkDerivation rec {
  pname = "zsh-abbr";
  version = "6.3.2";

  src = fetchFromGitHub {
    owner = "olets";
    repo = "zsh-abbr";
    tag = "v${version}";
    hash = "sha256-XSmDcAMovQ4sDLp6e1PeRlvU7bY6rl7wbCh66VsUBD0=";
    fetchSubmodules = true;
  };

  strictDeps = true;
  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall

    install *.zsh -Dt $out/share/zsh/zsh-abbr/
    install completions/* -Dt $out/share/zsh/zsh-abbr/completions/

    install zsh-job-queue/*.zsh -Dt $out/share/zsh/zsh-abbr/zsh-job-queue/
    install zsh-job-queue/completions/* -Dt $out/share/zsh/zsh-abbr/zsh-job-queue/completions/

    # Required for `man` to find the manpage of abbr, since it looks via PATH
    installManPage man/man1/*

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/olets/zsh-abbr";
    description = "Zsh manager for auto-expanding abbreviations, inspired by fish shell";
    license = with licenses; [
      cc-by-nc-sa-40
      hl3
    ];
    maintainers = with maintainers; [ icy-thought ];
    platforms = platforms.all;
  };
}
