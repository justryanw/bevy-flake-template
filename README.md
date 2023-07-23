# Bevy Flake Template
Simple flake template for the Bevy game engine using Naersk.

### Usage

Build with nix
```bash
nix build
nix run
```

Use dev or release profiles
```bash
nix run # Runs in release mode by default
nix run .#dev
nix run .#release
```

or enter dev environment and build using cargo
```bash
nix develop -c $SHELL # Use direnv to do this automatically
cargo build
cargo run
```

### Issues / Limitations

- Doesn't work on non NixOS systems currently since Bevy can't find the gpu, not sure why and I'm still looking into a fix for this.
- Not setup for MacOS yet.
- Still trying to figure out how to get multiple binaries to work.