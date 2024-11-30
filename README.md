# Bevy Flake Template
Simple Nix Flake template for the Bevy game engine using [Crate2Nix](https://github.com/nix-community/crate2nix).

### Features
- Builds dependanices individualy with [Crate2Nix](https://github.com/nix-community/crate2nix) so they can be reused between builds.
- Uploads built crates to a binary cache server during CI/CD.
- Local builds will pull crates from the cache server meaning the same crate doesn't need to built more than once.
- Dev shell with everything needed to build using Cargo.
- Release and dev profiles with opt levels recommended by Bevy.
- Wayland support.

### Usage

Running without cloning.
```bash
nix run github:justryanw/bevy-flake-template
```

Build with Nix.
```bash
# Clone and cd into repo
nix develop -c $SHELL # Enter dev shell (if you dont have nom installed)
nom build .#dev # Nice build output ( can be skipped )
nix run .#dev
# Or use alias for nom build and run
rundev
```

or enter dev environment and build using Cargo.
```bash
nix develop -c $SHELL # Use direnv to do this automatically
cargo run
```

### Issues / Limitations

- Not tested on MacOS.
- The way setting the opt levels for the dev profile is implemented is pretty hacky, there's probably a better way to do it.
- NixGL is needed to run using Nix on non NixOS systems.
```bash
nix run --impure github:guibou/nixGL -- nix run
```
