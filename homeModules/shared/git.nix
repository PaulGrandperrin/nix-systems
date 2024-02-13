{pkgs, ...}: {

  home = {
    packages = with pkgs; [
      tig
    ];
  };
  programs = {
    gh.enable = true;
    lazygit.enable = true;
    git = {
      enable = true;
      userName = "Paul Grandperrin";
      userEmail = "paul.grandperrin@gmail.com";
      aliases = {
        pushf = "push --force-with-lease"; # only force pushes if no new commits have pushed after the last pull
        blamex = "blame -w -C -C -C"; # ignores whitespaces and code that has just been moved around
        diffw = "diff --word-diff"; # inline diff
        stasha = "stash --all"; # stash even untracked and ignored files
      };
      delta = {
        enable = true;
        options = {
          navigate = true;
          line-numbers = true;
          syntax-theme = "Dracula";
        };
      };
      difftastic = {
        #enable = true;
        background = "dark";
        #display = "side-by-side"; # "side-by-side", "side-by-side-show-both", "inline"
      };
      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
        merge.conflictstyle = "diff3";
        rerere = {
          enabled = true;
          autoUpdate = true;
        };
        column.ui = "auto";
        branch.sort = "-committerdate";
        #core.fsmonitor = true; # watch FS for faster git status
      };
      signing = {
        key = "4AB1353033774DA3";
      };
      lfs = {
        enable = true;
        skipSmudge = true;
      };
    };
  };
}
