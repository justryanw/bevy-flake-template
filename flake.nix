{
  nixConfig = {
    # Replace with your own cachix or binary cache server.
    extra-trusted-public-keys = "justryanw.cachix.org-1:oan1YuatPBqGNFEflzCmB+iwLPtzq1S1LivN3hUzu60=";
    extra-substituters = "https://justryanw.cachix.org";
    allow-import-from-derivation = true;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    crate2nix = {
      url = "github:nix-community/crate2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    flake-parts,
    crate2nix,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        pkgs,
        lib,
        system,
        ...
      }: let
        systemDeps =
          builtins.attrValues {
            inherit
              (pkgs)
              libxkbcommon
              alsa-lib
              udev
              vulkan-loader
              wayland
              ;
          }
          ++ builtins.attrValues {
            inherit
              (pkgs.xorg)
              libXcursor
              libXrandr
              libXi
              libX11
              ;
          };

        name = "bevy-flake-template";

        crateOverrides =
          pkgs.defaultCrateOverrides
          // {
            wayland-sys = atts: {
              nativeBuildInputs = [pkgs.pkg-config];
              buildInputs = [pkgs.wayland];
            };

            ${name} = attrs: {
              name = "${name}-${attrs.version}";

              nativeBuildInputs = builtins.attrValues {
                inherit (pkgs) makeWrapper mold;
              };

              postInstall = ''
                wrapProgram $out/bin/${name} \
                  --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath systemDeps} \
                  --prefix XCURSOR_THEME : "Adwaita"
                mkdir -p $out/bin/assets
                cp -a assets $out/bin
              '';
            };
          };

        cargoNix =
          pkgs.callPackage
          (crate2nix.tools.${system}.generatedCargoNix {
            inherit name;
            src = ./.;
          })
          {
            defaultCrateOverrides = crateOverrides;
          };
      in {
        packages = {
          default = cargoNix.rootCrate.build;
        };

        devShells.default = pkgs.mkShell {
          buildInputs =
            systemDeps
            ++ builtins.attrValues {
              inherit
                (pkgs)
                cargo
                rustc
                pkg-config
                rustfmt
                clang
                mold
                cargo-watch
                cargo-edit
                nix-output-monitor
                trunk
                lld
                ;
            };

          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath systemDeps}";
          XCURSOR_THEME = "Adwaita";
        };
      };
    };
}
