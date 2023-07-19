{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk-src.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, rust-overlay, naersk-src, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
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

        sharedNativeBuildInputs = (with pkgs; [
          pkg-config
        ]);

        sharedBuildInputs = (with pkgs; [
          libxkbcommon
          libGL
          alsa-lib
          udev

          # WINIT_UNIX_BACKEND=wayland
          wayland

          # WINIT_UNIX_BACKEND=x11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          xorg.libX11
        ]);

      in
      with pkgs; {
        # For `nix build` & `nix run`:
        defaultPackage = naersk.buildPackage rec {
          src = ./.;

          nativeBuildInputs = sharedNativeBuildInputs;
          buildInputs = sharedBuildInputs;
          LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
        };

        # For `nix develop`
        devShell = pkgs.mkShell rec {
          # Fix for rust-analyzer in vscode
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

          nativeBuildInputs = sharedNativeBuildInputs ++ [ rustToolchain ];
          buildInputs = sharedBuildInputs;
          LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
        };
      }
    );
}
