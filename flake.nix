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

        sharedNativeBuildInputs = [ pkg-config ];

        sharedBuildInputs = [
          libxkbcommon
          alsa-lib
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
      in
      with pkgs; {
        # For `nix build` & `nix run`:
        packages.default = naersk.buildPackage rec {
          src = ./.;

          nativeBuildInputs = sharedNativeBuildInputs;
          buildInputs = sharedBuildInputs;
          LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
        };

        # For `nix develop`
        devShells.default = pkgs.mkShell rec {
          # Fix for rust-analyzer in vscode
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

          nativeBuildInputs = sharedNativeBuildInputs ++ [ rustToolchain ];
          buildInputs = sharedBuildInputs;
          LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
        };
      };
  };
}
