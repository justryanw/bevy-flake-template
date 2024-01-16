{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.lib.${system};

        buildDeps = (with pkgs; [
          pkg-config
          makeWrapper
          clang
          mold
        ]);

        runtimeDeps = (with pkgs; [
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
        ]));

        sharedAttrs = rec {
          pname = "bevy-flake-template";
          src = pkgs.lib.cleanSource ./.;

          nativeBuildInputs = buildDeps;
          buildInputs = runtimeDeps;

          postInstall = ''
            wrapProgram $out/bin/${pname} \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeDeps} \
              --prefix XCURSOR_THEME : "Adwaita"
            mkdir -p $out/bin/assets
            cp -a assets $out/bin
          '';
        };
      in
      {
        packages.default = craneLib.buildPackage sharedAttrs // { };
      });
}
