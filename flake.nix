{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay.url = "github:oxalica/rust-overlay";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, flake-parts, rust-overlay, crane, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" ];
    perSystem = { pkgs, system, ... }:
      with pkgs;
      let
        overlays = [ (import rust-overlay) ];
        pkgs = (import nixpkgs) {
          inherit system overlays;
        };

        rustStable = pkgs.rust-bin.stable.latest.default;

        craneLib = crane.lib.${system};

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

        sharedAttrs = rec {
          # pname = "bevy-flake-template";
          src = craneLib.cleanCargoSource (craneLib.path ./.);

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

        devAttrs = { release = false; };
      in
      rec {
        packages = {
          dev = craneLib.buildPackage sharedAttrs // devAttrs;
          release = craneLib.buildPackage sharedAttrs;

          default = packages.release;
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
