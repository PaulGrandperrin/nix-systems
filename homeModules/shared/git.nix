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
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        type = "cat-file -t";
        dump = "cat-file -p";
        pushf = "push --force-with-lease"; # only force pushes if no new commits have pushed after the last pull
        blamex = "blame -w -C -C -C"; # ignores whitespaces and code that has just been moved around
        diffw = "diff --word-diff"; # inline diff
        stasha = "stash --all"; # stash even untracked and ignored files
        l = "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all -n 15";
        lg = "lg1"; # https://stackoverflow.com/questions/1838873/visualizing-branch-topology-in-git/34467298#34467298
        lg1 = "lg1-specific --all";
        lg2 = "lg2-specific --all";
        lg3 = "lg3-specific --all";
        lg1-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
        lg2-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
        lg3-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
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
      signing = {
        key = "4AB1353033774DA3";
      };
      lfs = {
        enable = true;
        skipSmudge = true;
      };
      extraConfig = { # https://blog.gitbutler.com/how-git-core-devs-configure-git/ https://jvns.ca/blog/2024/02/16/popular-git-config-options/
        pull = {
          ff = "only";
          #rebase = true;
        };
        push = {
          autoSetupRemote = true;
          followTags = true; # push associated and annotated tags too
        };
        #fetch = { # auto delete remote branches and tags that were removed on the server
        #  prune = true;
        #  pruneTags = true;
        #  all = true;
        #};
        rebase = {
          autoSquash = true; # auto squash fixup commits
          autoStash = true;
          updateRefs = true; # takes stacked refs in a branch and makes sure they're also moved when a branch is rebased
        }; 
        merge.conflictstyle = "zdiff3";
        diff = {
          algorithm = "histogram"; # much better algo
          colorMoved = "plain"; # change moved lines color
          colorMovedWS = "allow-indentation-change";
          mnemonicPrefix = true; # use i/ (index), w/ (working directory) or c/ commit instead of a/, b/
          #dstPrefix = "./"; # make paths clickable links
          renames = true; # better fetect file renames
        };
        rerere = {
          enabled = true;
          autoUpdate = true;
        };

        column.ui = "auto";
        branch.sort = "-committerdate"; # sort branches by latest commit date
        tags.sort = "version:refname"; # sort tags by version numbers (as a series of integers)

        init.defaultBranch = "main";
        help.autocorrect = "prompt";
        commit.verbose = true;
        #apply.whitespace = "fix"; # removes trailing whitespaces
        log.date = "iso-local";

        # submodules
        status.submoduleSummary = true;
        diff.submodule = "log";
        submodule.recurse = true;

        # runs fsck frequently
        transfer.fsckobjects = true;
        fetch.fsckobjects = true;
        receive.fsckObjects = true;

        #core.fsmonitor = true; # watch FS for faster git status
      };
    };
  };
}
