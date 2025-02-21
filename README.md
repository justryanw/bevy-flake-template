# Bevy Flake Template
Simple Nix Flake template for the Bevy game engine using [Crate2Nix](https://github.com/nix-community/crate2nix).

### Features
- Builds dependanices individualy with [Crate2Nix](https://github.com/nix-community/crate2nix) so they can be reused between builds.
- Uploads built crates to a binary cache server during CI/CD.
- Local builds will pull crates from the cache server meaning the same crate doesn't need to built more than once.
- Dev shell with everything needed to build using Cargo.
- Wayland support.

### Usage

Running without cloning.
```bash
nix run github:justryanw/bevy-flake-template
```

Build with Nix.
```bash
# Clone and cd into repo
nix develop -c nom build # Nice build output ( can be skipped )
nix run
```

or enter dev environment and build using Cargo.
```bash
nix develop -c $SHELL # Use direnv to do this automatically
cargo run
```

### Issues / Limitations

- Not tested on MacOS.
- NixGL is needed to run using Nix on non NixOS systems.
```bash
nix run --impure github:guibou/nixGL -- nix run github:justryanw/bevy-flake-template
```
