{pkgs, inputs, ...}: { # lib, config, options, specialArgs, helpers, pkgs, inputs
  imports = [
    ({
      config = {
        viAlias = true;
        vimAlias = true;
        clipboard.providers.wl-copy.enable = true;

        extraConfigVim = ''
        '';

        extraConfigLua = ''
        '';

        extraConfigLuaPre = ''
        '';

        extraConfigLuaPost = ''
        '';

        extraPackages = [];
        extraLuaPackages = [];

        options = { # vim.opt.* # vim.o # set
        };
        localOptions = { # vim.opt_local.* # setlocal
        };
        globalOptions = { # vim.opt_global.* # setglobal
        };

        globals = { # vim.g.*
          mapleader = " ";
          maplocalleader = " ";
        };

        match = {
        };

        keymaps = [
          #{
          #  action = "";
          #  key = "";
          #  #lua = true;
          #  mode = "";
          #  options = {
          #    desc = "";
          #  };
          #}
        ];

        ### theme
        
        colorschemes = {
          #gruvbox = {
          #  enable = true;
          #  settings = {
          #    contrastDark = "hard";
          #  };
          #};
          #ayu.enable = true;
          base16.colorscheme = "papercolor-dark"; # molokai sonokai
        };
      };
    })

    ({ ### git
      config = {
        plugins = {
          fugitive.enable = true; # git wrapper # kickstart
        };
        extraPlugins = [
          pkgs.vimPlugins.rhubarb # github wrapper # kickstart
        ];
      };
    })

    ({ ### status line
      config = {
        options.laststatus = 3; # only one statusline at the bottom
        #highlightOverride.WinSeparator.guibg = "None"; # fix separators # FIXME doesn't work
        
        plugins = {
          lualine.enable = true; # lazyvim, lunarvim, kickstart
          #airline.enable = true;
          #lightline.enable = true;
          #
        };
        #extraPlugins = [ # nvchad
        #  pkgs.vimPlugins.nvchad
        #  pkgs.vimPlugins.nvchad-ui
        #];
        #extraPlugins = [ # astrovim
        #  pkgs.vimPlugins.heirline-nvim # framework to create a statusline
        #];
      };
    })
    ({ ### editor
      config = {
        options = { # vim.opt.* # vim.o # set
          undofile = true; # saves to $XDG_STATE_HOME/nvim/undo
          # undolevels = 1000;
          # undoreload = 10000;

          relativenumber = true;

          signcolumn = "yes"; # reserves space for diagnostic icons
        };
        extraPlugins = [
          pkgs.vimPlugins.vim-sleuth # detect tabstop and shiftwidth automatically # kickstart
        ];
      };
    })
    ({ ### LSP
      config = {
        options = { # vim.opt.* # vim.o # set
        };
        plugins = {
          #TODO checkout rustaceanvim
          lsp = {
            enable = true;

            servers = {
              nil_ls.enable = true; # TODO use none_ls
              nixd.enable = true;
              rust-analyzer = let 
                my-rust = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.my-rust-stable;
              in {
                enable = true;
                package = my-rust;
                installCargo = true;
                cargoPackage = my-rust;
                installRustc = true;
                rustcPackage = my-rust;
              };
            };
          };
        };
      };
    })
    ({ ### lookup
      config = {
        options = { # vim.opt.* # vim.o # set
        };
        plugins = {
          harpoon = {
            enable = true;
          };
          treesitter.enable = true;
          telescope = {
            enable = true;
            keymaps."<leader>ff" = "find_files";
            keymaps."<leader>fg" = "live_grep";
            keymaps."<leader>fb" = "buffers";
            keymaps."<leader>fh" = "help_tags";
            extensions = {
              fzf-native = {
                enable = true;
              };
            };
          };
        };
      };
    })
  ];
}
   
  ### tabs and buffer manager: tabufline
  ### filetree: nerdtree, defx
  ### smooth scrolling
  ### autocomplete: none-ls
  ### checkers
  ### format
  ### edit
  #vim-surround # Shortcuts for setting () {} etc.
  #vim-repeat # repeat last action
  #splitjoin.vim # Switch between single-line and multiline forms of code 
  #multiple cursors
  #align
  #justification
  #highlight whitespace at end of line
  #edittorconfig
  ### ui
  #scrollbar
  #sidebar
  #indentline
  #cursorword
  ### banner (welcome page): alpha-nvim
  ### tabline
  ### fuzzy find: fzf, foldsearch
  ### git: git, gina, fugitive, gita
  ### github
  ### Universal Ctags
  ### LSP: nix and rust
  ### telescope + trouble.nvim



# defaults
# leader y => yank to system keyboard
# leader p => paste from system clipboard


#  DONE: scap spacevim for plugins and basic functionnalities
# TODO kickstart
# TODO: http://www.lazyvim.org/plugins


# gpt: for each of those neovim distributions: lazyvim, nvchad, lunarvim, kickstart.nvim, spacevim and astrovim, tell me which plugins they use or recommend for the customizing the statusline? and tell me if their is some special way they configure it and integrate it with the rest of their distribution or any other relevant information like this.
