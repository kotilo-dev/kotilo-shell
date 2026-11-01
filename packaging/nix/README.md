# Kotilo Shell on NixOS / home-manager

```nix
# flake.nix inputs
inputs.kotilo-shell.url = "github:kotilo-dev/kotilo-shell?dir=packaging/nix";

# home-manager
imports = [ inputs.kotilo-shell.homeManagerModules.default ];
programs.kotilo-shell = {
  enable = true;
  settings.theme.id = "gruvbox-dark";
  settings.plugins."bar.clock".zones = [ { label = "SFO"; tz = "America/Los_Angeles"; } ];
};
```

Then autostart `qs -c kotilo` from your Niri or Hyprland config. The module pins Quickshell from its upstream flake.
