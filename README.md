# Bevy Flake Template
Simple flake template for the Bevy game engine using [Crane](https://github.com/ipetkov/crane).

### Usage

Running without cloning
```bash
nix run github:justryanw/bevy-flake-template
```

Build with nix
```bash
# Clone and cd into repo
nix build
# Or
nix run # Runs client in release mode by default
```

Use dev or release profiles
```bash
nix run .#dev
nix run .#release
```

or enter dev environment and build using cargo
```bash
nix develop -c $SHELL # Use direnv to do this automatically
cargo run
```

### Issues / Limitations

- Not setup for MacOS yet.
- NixGL is needed to run on non NixOS systems
```bash
nix run --impure github:guibou/nixGL -- nix run
```