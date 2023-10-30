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
