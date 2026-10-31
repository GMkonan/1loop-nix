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
    "third_party/fyne(/.*)?"
  ];

  patches = [
    ../patches/python-from-path.patch
    ../patches/managed-installation.patch
  ];

  # Keep the upstream Fyne fork in src; the module proxy contains external modules.
  proxyVendor = true;
  vendorHash = "sha256-BfTReOzgAlNWHHltADaTc/aY1zr6gn8O+KbmJVEzoi0=";

  ldflags = [
    "-s"
    "-w"
    "-X 1loop/internal/update.Version=${version}"
    "-X 1loop/internal/update.ManagedBy=Nix"
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
    # Upstream does not currently declare a license for its own source code.
    # Do not infer one from the vendored dependencies' licenses.
  };
}
