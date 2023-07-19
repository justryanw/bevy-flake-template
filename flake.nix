{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk-src.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, naersk-src, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
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

      in with pkgs; {
        # For `nix build` & `nix run`:
        defaultPackage = naersk.buildPackage rec {
          src = ./.;

          nativeBuildInputs = sharedNativeBuildInputs;

          buildInputs = sharedBuildInputs;

          LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
        };

        # For `nix develop` (optional, can be skipped):
        devShell = pkgs.mkShell rec {
          nativeBuildInputs = sharedNativeBuildInputs ++ [
            rustc
            cargo
          ];

          buildInputs = sharedBuildInputs;

          LD_LIBRARY_PATH = "${lib.makeLibraryPath buildInputs}";
        };
      }
    );
}
