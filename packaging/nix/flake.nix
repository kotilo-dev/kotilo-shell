{
  description = "Kotilo Shell — developer-focused Quickshell desktop shell for Niri and Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell?rev=2b4501a282689792b62e94f3fb30d8f512324fe6";  # 0.3.2
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, quickshell }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
      version = "0.1.0";
    in {
      packages = forAll (pkgs: rec {
        kotilo-shell = pkgs.stdenvNoCC.mkDerivation {
          pname = "kotilo-shell";
          inherit version;
          src = ../..;
          installPhase = ''
            mkdir -p $out/share/kotilo-shell
            cp -r shell.qml Shell components services plugins themes assets config scripts $out/share/kotilo-shell/
          '';
          meta = with pkgs.lib; { description = "Developer-focused Quickshell desktop shell"; homepage = "https://kotilo.dev"; license = licenses.gpl3Plus; platforms = platforms.linux; };
        };
        default = kotilo-shell;
      });

      # home-manager module: programs.kotilo-shell.enable = true;
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let cfg = config.programs.kotilo-shell;
            pkg = self.packages.${pkgs.system}.kotilo-shell;
            qs = quickshell.packages.${pkgs.system}.default;
        in {
          options.programs.kotilo-shell = {
            enable = lib.mkEnableOption "Kotilo Shell";
            settings = lib.mkOption { type = lib.types.attrs; default = { }; description = "Merged into settings.json"; };
          };
          config = lib.mkIf cfg.enable {
            home.packages = [ qs pkg pkgs.jq pkgs.brightnessctl pkgs.playerctl pkgs.wl-clipboard pkgs.inter pkgs.jetbrains-mono ];
            xdg.configFile."quickshell/kotilo".source = "${pkg}/share/kotilo-shell";
            xdg.configFile."kotilo/shell/settings.json".text = builtins.toJSON
              (lib.recursiveUpdate (builtins.fromJSON (builtins.readFile "${pkg}/share/kotilo-shell/config/settings.default.json")) cfg.settings);
          };
        };

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [ quickshell.packages.${pkgs.system}.default pkgs.qt6.qtdeclarative pkgs.jq pkgs.python3 ];
          shellHook = "echo 'Kotilo Shell dev shell — run ./scripts/dev.sh'";
        };
      });
    };
}
