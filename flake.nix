{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    wrappers = {
      url = "github:lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    wrapTmux = inputs.wrappers.lib.wrapModule (
      {
        lib,
        config,
        ...
      }: let
        tmuxConfig =
          ''
            set-option -g status-keys ${config.keyMode}
            set-option -g mode-keys ${config.keyMode}
            set-option -s escape-time ${toString config.escapeTime}
          ''
          + (
            if config.prefix != null
            then ''
              unbind C-b
              set-option -g prefix ${config.prefix}
              bind-key ${config.prefix} send-prefix
            ''
            else ""
          )
          + (
            if config.shell != null
            then ''
              set-option -g default-shell "${config.shell}"
            ''
            else ""
          )
          + config.extraConfig;
      in {
        options = {
          keyMode = lib.mkOption {
            default = "vi";
            example = "vi";
            type = lib.types.enum [
              "emacs"
              "vi"
            ];

            description = "VI or Emacs style shortcuts.";
          };

          escapeTime = lib.mkOption {
            default = 0;
            example = 500;
            type = lib.types.ints.unsigned;
            description = ''
              Time in milliseconds for which tmux waits after an escape is
              input.
            '';
          };

          prefix = lib.mkOption {
            default = "C-a";
            type = lib.types.nullOr lib.types.str;
            description = ''
              Set the prefix key. Overrules the "shortcut" option when set.
            '';
          };

          shell = lib.mkOption {
            default = null;
            example = "${lib.getExe config.pkgs.bash}";
            type = lib.types.nullOr lib.types.nonEmptyStr;
            description = "Set the default-shell tmux variable.";
          };

          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Additional configuration to add to the config.";
          };
        };

        config = {
          package = config.pkgs.tmux;

          flags = {
            "-f" = "${config.pkgs.writeText "config" tmuxConfig}";
          };
        };
      }
    );

    packages = forAllSystems (system: {
      default =
        (
          self.outputs.wrapTmux.apply {
            pkgs = nixpkgs.legacyPackages.${system};
          }
        ).wrapper;
    });
  };
}
