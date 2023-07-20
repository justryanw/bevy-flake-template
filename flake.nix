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
        overlays = [
          (import rust-overlay)
          (self: super: {
            rustToolchain = super.rust-bin.stable.latest.default;
          })
        ];

        pkgs = (import nixpkgs) {
          inherit system overlays;
        };

        naersk = pkgs.callPackage naersk-src { };

        buildDeps = [ 
          pkg-config
          makeWrapper
        ];

        runtimeDeps = [
          libxkbcommon
          alsa-lib
          alsa-plugins
          alsa-utils
          alsa-tools
          libpulseaudio
          udev
          libGL
          vulkan-loader
          vulkan-headers

          # WINIT_UNIX_BACKEND=wayland
          wayland
        ] ++ (with xorg; [
          # WINIT_UNIX_BACKEND=x11
          libXcursor
          libXrandr
          libXi
          libX11
          libxcb
        ]);
      in
      with pkgs; {
        # For `nix build` & `nix run`:
        packages.default = naersk.buildPackage rec {
          pname = "bevy-flake-template";
          src = ./.;

          nativeBuildInputs = buildDeps;
          buildInputs = runtimeDeps;

          overrideMain = attrs: {
            fixupPhase = ''
              wrapProgram $out/bin/${pname} \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeDeps} \
                --prefix XCURSOR_THEME : "Adwaita" \
                --set ALSA_PLUGIN_DIR ${alsa-plugins}/lib/alsa-lib
              mkdir -p $out/bin/assets
              cp -a assets $out/bin'';
          };
        };

        # For `nix develop`
        devShells.default = pkgs.mkShell {
          # Fix for rust-analyzer in vscode
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

          nativeBuildInputs = buildDeps ++ [ rustToolchain ];
          buildInputs = runtimeDeps;

          LD_LIBRARY_PATH = "${lib.makeLibraryPath runtimeDeps}";
          XCURSOR_THEME = "Adwaita";
        };
      };
  };
}
