{ lib, upstream }:
let
  version = lib.trim (builtins.readFile "${upstream}/VERSION");
in
{
  inherit version;
  src = lib.sourceByRegex upstream [
    "go\\.(mod|sum)"
    "VERSION"
    "(cmd|internal|assets)(/.*)?"
    "third_party"
    "third_party/(fyne|glfw|glfw-js)(/.*)?"
  ];

  patches = [ ../patches/managed-installation.patch ];

  # Keep upstream's local forks in src; the module proxy contains external modules.
  proxyVendor = true;
  vendorHash = "sha256-0kWBfl9XQKw7WAP43B86slwovV+aCcZ1kvSvXH7LruU=";

  ldflags = [
    "-s"
    "-w"
    "-X 1loop/internal/update.Version=${version}"
    "-X 1loop/internal/update.Packaged=Nix"
  ];

  # Update/signature/archive tests need neither a display nor external network.
  checkPhase = ''
    runHook preCheck
    go test ./internal/update
    runHook postCheck
  '';

  meta = {
    homepage = "https://github.com/Feur-Inc/1loop";
    platforms = lib.platforms.linux;
    license = lib.licenses.mpl20;
  };
}
