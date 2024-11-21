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

  outputs =
    inputs@{ flake-parts, crate2nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          system,
          pkgs,
          lib,
          ...
        }:
        let
          buildInputs = (
            with pkgs;
            [
              libxkbcommon
              alsa-lib
              udev
              vulkan-loader
              wayland
            ]
            ++ (with xorg; [
              libXcursor
              libXrandr
              libXi
              libX11
            ])
          );

          name = "bevy-flake-template";

          crateOverrides = pkgs.defaultCrateOverrides // {
            wayland-sys = atts: {
              nativeBuildInputs = with pkgs; [ pkg-config ];
              buildInputs = with pkgs; [ wayland ];
            };

            ${name} = attrs: {
              name = "${name}-${attrs.version}";

              nativeBuildInputs = with pkgs; [
                makeWrapper
                mold
              ];

              postInstall = ''
                wrapProgram $out/bin/${name} \
                  --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
                  --prefix XCURSOR_THEME : "Adwaita"
                mkdir -p $out/bin/assets
                cp -a assets $out/bin
              '';
            };
          };

          cargoNix =
            {
              release ? true,
            }:
            pkgs.callPackage
              (crate2nix.tools.${system}.generatedCargoNix {
                inherit name;
                src = ./.;
              })
              {
                inherit release;
                defaultCrateOverrides = crateOverrides;
              };

          cargoNixRelease = cargoNix { };
          cargoNixDev = cargoNix { release = false; };

        in
        {
          packages = {
            default = cargoNixRelease.rootCrate.build;

            dev = cargoNixDev.rootCrate.build.override {
              crateOverrides =
                crateOverrides
                // (builtins.listToAttrs (
                  builtins.map (
                    crate:
                    let
                      crateName = crate.crateName;
                      defaultOverride = crateOverrides.${crateName} or (crate: { });
                      opt1 = [ "-C opt-level=1" ];
                      opt3 = [ "-C opt-level=3" ];
                    in
                    {
                      name = crateName;
                      value =
                        crate:
                        (
                          let
                            defaultOverrideApplied = defaultOverride crate;
                            opt = if crateName == name then opt3 else opt1;
                          in
                          defaultOverrideApplied
                          // {
                            extraRustcOpts = (defaultOverrideApplied.extraRustcOpts or [ ]) ++ opt;
                            extraRustcOptsForBuildRs = (defaultOverrideApplied.extraRustcOptsForBuildRs or [ ]) ++ opt;
                          }
                        );
                    }
                  ) (builtins.attrValues cargoNixDev.internal.crates)
                ));
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs =
              buildInputs
              ++ (with pkgs; [
                cargo
                rustc
                pkg-config
                rustfmt
                clang
                mold
                cargo-watch
                nix-output-monitor
                (writeScriptBin "rundev" ''
                  ${nix-output-monitor}/bin/nom build .#dev;
                  nix run .#dev
                '')
              ]);

            RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildInputs}";
            XCURSOR_THEME = "Adwaita";
          };
        };
    };
}
