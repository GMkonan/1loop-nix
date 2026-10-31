{
  lib,
  upstream,
  buildGoModule,
  pkg-config,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  wrapGAppsHook3,
  gobject-introspection,
  pipewire,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxinerama,
  libxrandr,
  libxxf86vm,
  wayland,
  libxkbcommon,
  gtk3,
  gst_all_1,
  python3,
  bash,
  git,
  glib,
}:
let
  common = import ./common.nix { inherit lib upstream; };
  python = python3.withPackages (ps: [
    ps.dbus-python
    ps.pygobject3
    ps.pillow
  ]);
  gstreamerPackages = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
  ];
in
buildGoModule (
  common
  // {
    pname = "1loop";

    nativeBuildInputs = [
      pkg-config
      makeWrapper
      copyDesktopItems
      wrapGAppsHook3
      gobject-introspection
    ];
    buildInputs = [
      libGL
      libx11
      libxcursor
      libxi
      libxinerama
      libxrandr
      libxxf86vm
      wayland
      libxkbcommon
      gtk3
      pipewire
    ]
    ++ gstreamerPackages;

    # Preserve the plain/-wayland sibling names in libexec. os.Executable() is
    # used for backend switching, restarting and launching command sandboxes.
    buildPhase = ''
      runHook preBuild
      go build -p "$NIX_BUILD_CORES" -ldflags="''${ldflags[*]}" -o bin/1loop ./cmd/1loop
      CGO_CFLAGS="$CGO_CFLAGS -w" go build -p "$NIX_BUILD_CORES" \
        -ldflags="''${ldflags[*]}" -tags wayland -o bin/1loop-wayland ./cmd/1loop
      runHook postBuild
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "1loop";
        desktopName = "1loop";
        comment = "Your project. Your model. One loop.";
        exec = "1loop";
        icon = "1loop";
        terminal = false;
        categories = [ "Development" ];
        startupWMClass = "1loop";
        startupNotify = true;
      })
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/1loop "$out/libexec/1loop/1loop"
      install -Dm755 bin/1loop-wayland "$out/libexec/1loop/1loop-wayland"
      install -Dm644 assets/1loop-ring-on-black.png \
        "$out/share/icons/hicolor/512x512/apps/1loop.png"
      runHook postInstall
    '';

    dontWrapGApps = true;
    preFixup = ''
      for name in 1loop 1loop-wayland; do
        makeWrapper "$out/libexec/1loop/$name" "$out/bin/$name" \
          --prefix PATH : ${
            lib.makeBinPath [
              python
              bash
              git
              glib
            ]
          } \
          --prefix LD_LIBRARY_PATH : ${
            lib.makeLibraryPath [
              libGL
              wayland
              libxkbcommon
              libxcursor
            ]
          } \
          "''${gappsWrapperArgs[@]}"
      done
    '';

    meta = common.meta // {
      description = "Desktop coding agent with user-chosen models";
      mainProgram = "1loop";
    };
  }
)
