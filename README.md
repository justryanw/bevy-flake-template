# Bevy Flake Template
Simple flake template for the Bevy game engine using Naersk.

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
nix run .#clientDev
nix run .#serverDev

nix run .#client
nix run .#server
```

or enter dev environment and build using cargo
```bash
nix develop -c $SHELL # Use direnv to do this automatically
cargo build
cargo run --bin client
cargo run --bin server
```

### Issues / Limitations

- Not setup for MacOS yet.
- NixGL is needed to run on non NixOS systems
```bash
nix run --impure github:guibou/nixGL -- nix run
```