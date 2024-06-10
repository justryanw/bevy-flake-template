# Bevy Flake Template WASM
Simple flake template for the Bevy game engine using [Crane](https://github.com/ipetkov/crane).

### Usage

Serve localy without cloning
```bash
nix run github:justryanw/bevy-flake-template/crane-wasm#serve
```

Serve with Nix
```bash
# Clone and cd into repo
nix run .#serve
```

Serve with Trunk
```bash
# Clone and cd into repo
nix develop -c $SHELL # Use direnv to do this automatically
trunk serve
```

### Issues / Limitations

- Not tested on MacOS.
- Github pages broke (WIP) https://justryanw.github.io/bevy-flake-template/
