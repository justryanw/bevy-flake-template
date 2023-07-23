{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk-src.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs @ { nixpkgs, flake-parts, rust-overlay, naersk-src, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" ];
    perSystem = { pkgs, system, ... }:
      with pkgs;
      let
        overlays = [ (import rust-overlay) ];
        pkgs = (import nixpkgs) {
          inherit system overlays;
        };

        rustStable = pkgs.rust-bin.stable.latest.default;

        naersk = pkgs.callPackage naersk-src {
          cargo = rustStable;
          rustc = rustStable;
        };

        buildDeps = [
          pkg-config
          makeWrapper
          clang
          mold
        ];

        runtimeDeps = [
          libxkbcommon
          alsa-lib
          pipewire.lib
          udev
          vulkan-loader

          # WINIT_UNIX_BACKEND=wayland
          wayland
        ] ++ (with xorg; [
          # WINIT_UNIX_BACKEND=x11
          libXcursor
          libXrandr
          libXi
          libX11
        ]);

        commonConfig = rec {
          pname = "bevy-flake-template";
          src = ./.;

          nativeBuildInputs = buildDeps;
          buildInputs = runtimeDeps;

          overrideMain = attrs: {
            fixupPhase = ''
              wrapProgram $out/bin/${pname} \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeDeps} \
                --prefix XCURSOR_THEME : "Adwaita" \
                --prefix ALSA_PLUGIN_DIR : ${pipewire.lib}/lib/alsa-lib
              mkdir -p $out/bin/assets
              cp -a assets $out/bin'';
          };
        };
      in
      with pkgs; rec {

        packages = {
          # `nix run .#dev`:
          dev = naersk.buildPackage commonConfig // {
            release = false;
          };

          # `nix run .#release`:
          release = naersk.buildPackage commonConfig;

          # `nix run`:
          default = packages.release;
        };

        # For `nix develop`
        devShells.default = pkgs.mkShell {
          # Fix for rust-analyzer in vscode
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

          nativeBuildInputs = buildDeps ++ [ rustStable ];
          buildInputs = runtimeDeps;

          LD_LIBRARY_PATH = "${lib.makeLibraryPath runtimeDeps}";
          XCURSOR_THEME = "Adwaita";
        };
      };
  };
}
