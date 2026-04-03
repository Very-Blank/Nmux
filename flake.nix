{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib;
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = lib.genAttrs systems;
  in {
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    mkPackage = {
      system,
      extraModule ? {},
    }: let
      pkgs = nixpkgs.legacyPackages.${system};

      eval = lib.evalModules {
        modules = [./modules extraModule];
        specialArgs = {pkgs = pkgs;};
      };

      cfg = eval.config.nmux;

      tmuxConfig =
        ''
          set-option -g status-keys ${cfg.keyMode}
          set-option -g mode-keys ${cfg.keyMode}
          set-option -s escape-time ${toString cfg.escapeTime}
        ''
        + (
          if cfg.prefix != null
          then ''
            unbind C-b
            set-option -g prefix ${cfg.prefix}
            bind-key ${cfg.prefix} send-prefix
          ''
          else ""
        )
        + (
          if cfg.shell != null
          then ''
            set-option -g default-shell "${cfg.shell}"
          ''
          else ""
        )
        + cfg.extraConfig;
    in
      pkgs.symlinkJoin {
        name = "tmux";
        buildInputs = [pkgs.makeWrapper];
        paths = [pkgs.tmux];
        postBuild = ''
          wrapProgram $out/bin/tmux --append-flags "-f ${pkgs.writeText "config" tmuxConfig}"
        '';
      };

    packages = forAllSystems (system: {
      default = self.mkPackage {system = system;};
    });

    meta.mainProgram = "tmux";
  };
}
