# 1loop for Nix

Independent, source-based Nix packaging for [Feur-Inc/1loop](https://github.com/Feur-Inc/1loop).
It does not require upstream to accept a flake or maintain a fork of the app.
Only the packaging and two compatibility patches live here; the application is
fetched directly from upstream at the revision pinned in `flake.lock`.

## Outputs

| Output | Purpose |
| --- | --- |
| `packages.<system>.default` / `1loop` | Desktop, with X11 and native Wayland backends |
| `packages.<system>.1loop-server` | Headless server, without GUI dependencies |
| `apps.<system>.default` / `1loop` / `1loop-server` | `nix run` entry points |
| `overlays.default` | Adds `pkgs."1loop"` and `pkgs."1loop-server"` |
| `devShells.<system>.default` | Go and desktop build dependencies |
| `checks.<system>` | Package builds and updater tests |

Targets: `x86_64-linux` and `aarch64-linux`. Nix with flakes enabled is required.
AArch64 outputs have been evaluated, but have not been built or run locally.

## Run or install

From a checkout:

```sh
nix run .
nix run .#1loop-server -- -help
nix profile add .#1loop
```

From GitHub:

```sh
nix run github:GMkonan/1loop-nix
nix profile add github:GMkonan/1loop-nix#1loop
```

`nix run` does not install the app. A profile or declarative installation makes
`1loop` available on PATH and installs its desktop menu entry.

## Home Manager or NixOS

Add this input to your configuration's flake:

```nix
inputs.oneloop = {
  url = "github:GMkonan/1loop-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

For local development, the URL can be `path:/absolute/path/to/1loop-nix`.

If your module already receives `inputs`, add this to Home Manager:

```nix
home.packages = [
  inputs.oneloop.packages.${pkgs.stdenv.hostPlatform.system}."1loop"
];
```

For NixOS, use the same package in `environment.systemPackages` instead.
Use `."1loop-server"` for the headless package. No custom installation module
is required. Do not install the desktop in both package lists unnecessarily.

For a standalone Home Manager configuration, forward `inputs` via
`homeManagerConfiguration.extraSpecialArgs = { inherit inputs; };`.
For NixOS modules, use `nixosSystem.specialArgs = { inherit inputs; };`.
For Home Manager embedded in NixOS, use
`home-manager.extraSpecialArgs = { inherit inputs; };` as well.
These examples assume the outputs function binds `inputs`, for example
`outputs = inputs@{ self, nixpkgs, ... }: ...;`, and the consuming module
accepts `{ inputs, pkgs, ... }`.

An overlay is available if you prefer `pkgs."1loop"`:

```nix
nixpkgs.overlays = [ inputs.oneloop.overlays.default ];
home.packages = [ pkgs."1loop" ];
```

## Following upstream

The upstream input tracks `Feur-Inc/1loop`'s `main` branch, but **builds use the
locked revision**, not a moving network source. Updates are explicit:

```sh
# In this packaging repository:
nix flake update upstream
nix flake check --no-build --all-systems
nix flake check -L
nix run . -- -help
nix run .#1loop-server -- -help
```

Review and commit the new lock after testing. The package version is read from
upstream's `VERSION` file. To update build dependencies separately, run
`nix flake update nixpkgs` and validate again.

If upstream changes Go dependencies, the build may report a `vendorHash`
mismatch. Replace `vendorHash` in `nix/common.nix` with the reported `got` hash
(after reviewing the dependency changes), then rebuild both packages. Set it
to `lib.fakeHash` first if you need to force recalculation.

If a compatibility patch no longer applies, review the upstream change and
refresh or remove the patch; do not silently ignore failed patches. The source
filter in `nix/common.nix` must also be updated if upstream moves/adds required
source directories. It intentionally retains upstream's local Fyne fork.

Once changes to this repository are published, consuming configurations must
update their own lock too:

```sh
# In your NixOS/Home Manager flake:
nix flake update oneloop
home-manager switch --flake .#YOUR_HOST
# Or use your normal nixos-rebuild command for a NixOS installation.
```

Updating a consumer's `oneloop` input alone does not advance this repository's
nested `upstream` lock. Update and publish the packaging repository first.

### Automatic upstream updates

Included workflows provide:

- **Nix checks:** formatting, evaluation of both architectures, x86_64 package
  builds/updater tests and CLI help checks on pushes and pull requests.
- **Update upstream:** daily (07:23 UTC) and manual checks of upstream `main`,
  followed by builds/tests and a lock-update PR. It explicitly dispatches
  **Nix checks** on the update branch and enables squash auto-merge for that
  exact PR head. The protected `main` branch requires the `check` job to pass
  against the current base before merging. No personal access token is needed.
  Only `flake.lock` is proposed by this automation; `nixpkgs` is unchanged.
  If patches or dependency hashes break, the workflow fails before proposing
  an update; maintenance is still required. GUI behavior is not tested by CI.

Repository setup (also needed for a fork): enable Actions, allow GitHub Actions
to create pull requests, enable squash merging and auto-merge, and protect
`main` with the required GitHub Actions status check `check` (strict/up-to-date,
including administrators). No approving review is required for these automated
updates. The updater has `actions: write`, `contents: write` and
`pull-requests: write`; the CI workflow only has `contents: read`.
Scheduled workflows run on the default branch and GitHub may delay them.
There is no binary cache configured here, so consumers may build locally.

To check for an update immediately:

```sh
gh workflow run update-upstream.yml --repo GMkonan/1loop-nix
gh run list --repo GMkonan/1loop-nix
```

Merging here does **not** update an installed application. Consumers must
update their `oneloop` input and apply their NixOS/Home Manager configuration.

## Runtime details

- The desktop wrapper supplies Bash, Git, Python with D-Bus/PyGObject/Pillow,
  GL/Wayland libraries and GTK/GStreamer/PipeWire plugin discovery.
- Browser features require Chrome/Chromium accessible to the app. Math
  rendering can additionally need LaTeX and `dvipng`; these are not bundled.
- Computer Use requires host PipeWire services, a working desktop portal
  backend supporting RemoteDesktop and ScreenCast, and user consent. Installing
  this package does not configure services or grant permissions. Not every
  compositor/portal backend supports these features.
- Settings/tokens and caches remain in the usual XDG user directories.
- Built-in release downloading/replacement is disabled for Nix builds; update
  via Nix. The package ships its own desktop entry pointing to the wrapper.
- Both backend executables remain siblings in `libexec/1loop`, preserving
  backend handoff, restart and sandbox re-execution.
- Graphical use on non-NixOS distributions may need additional graphics
  integration such as nixGL; that environment has not been tested here.

## Validation and licensing

Locally verified on x86_64 NixOS: both package builds and updater tests,
`nix flake check`, CLI help, the development shell, Home Manager evaluation,
and isolated X11/native Wayland startup with the expected backend executables.
Python imports and GStreamer/PipeWire plugin discovery passed in each app's
wrapper environment, and the app did not generate a duplicate user launcher.
The GitHub workflow definitions also passed actionlint locally.

This standalone package is built from unmodified upstream source plus the
included patches, rather than relying on a modified local app checkout.
Actual model-provider requests and desktop-control consent/capture were not
tested; the included GitHub CI does not exercise graphical startup.

Upstream currently does not declare a license for its own source. Package
metadata intentionally does not infer a license from its vendored dependencies.
This repository is independent packaging, not an upstream-endorsed release.
