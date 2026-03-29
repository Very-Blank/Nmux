{
  lib,
  config,
}: {
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
}
