{
  lib,
  buildGoModule,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "natscli";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "nats-io";
    repo = "natscli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ya3nNgPa9MEiDDwoBv8oXi7+Hji9fhUNIm55jJ6w++8=";
  };

  vendorHash = "sha256-NLsIX0B2YKGNWeAuKIQUs/2sXokUr6PYO5qvvfbbN1Y=";

  ldflags = [
    "-X main.version=${finalAttrs.version}"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/nats";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "NATS Command Line Interface";
    homepage = "https://github.com/nats-io/natscli";
    changelog = "https://github.com/nats-io/natscli/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [ asl20 ];
    maintainers = with lib.maintainers; [ fab ];
    mainProgram = "nats";
  };
})
