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
          udev
          vulkan-loader
          wayland
        ] ++ (with xorg; [
          libXcursor
          libXrandr
          libXi
          libX11
        ]);

        sharedAttrs = { pname }: rec {
          inherit pname;
          src = ./.;

          copyBinsFilter = ''select(.reason == "compiler-artifact" and .executable != null and .profile.test == false and .target.name == "${pname}")'';

          nativeBuildInputs = buildDeps;
          buildInputs = runtimeDeps;

          overrideMain = attrs: {
            fixupPhase = ''
              wrapProgram $out/bin/${pname} \
                --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeDeps} \
                --prefix XCURSOR_THEME : "Adwaita"
              mkdir -p $out/bin/assets
              cp -a assets $out/bin
            '';
          };
        };

        clientAttrs = sharedAttrs { pname = "client"; };
        serverAttrs = sharedAttrs { pname = "server"; };

        devAttrs = { release = false; };
      in
      rec {
        packages = {
          clientDev = naersk.buildPackage (clientAttrs // devAttrs);
          serverDev = naersk.buildPackage (serverAttrs // devAttrs);

          client = naersk.buildPackage clientAttrs;
          server = naersk.buildPackage serverAttrs;

          default = packages.client;
        };

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
