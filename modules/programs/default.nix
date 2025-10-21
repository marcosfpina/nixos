{ config, lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      # Modern plugin ecosystem
      telescope-nvim      # Better fuzzy finder
      nvim-treesitter     # Better syntax highlighting
      lualine-nvim        # Modern status line
      nvim-tree-lua       # Better file explorer
      lsp-zero-nvim       # Easy LSP setup
      cmp-nvim-lsp        # Better completion
    ];
    extraLuaConfig = ''
      -- Lua configuration (more powerful)
      require('telescope').setup{}
      require('nvim-treesitter.configs').setup{}
    '';
  };


  # home.nix
{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 10000;
    historyFileSize = 100000;
    
    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
    };
    
    bashrcExtra = ''
      # Better completion
      bind 'set completion-ignore-case on'
      bind 'set show-all-if-ambiguous on'
      bind 'set completion-map-case on'
      
      # Better history search
      bind '"\e[A": history-search-backward'
      bind '"\e[B": history-search-forward'
      
      # Custom prompt with git info
      source ${pkgs.git}/share/bash-completion/completions/git-prompt.sh
      PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(__git_ps1)\[\033[00m\]\$ '
    '';
  };
}

{
  # Modern terminals
  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 12;
      colors.bright.black = "0x666666";
      window.opacity = 0.9;
    };
  };
  
  programs.kitty = {
    enable = true;
    theme = "Dracula";
    settings = {
      font_size = 12;
      background_opacity = "0.9";
      tab_bar_style = "powerline";
    };
  };
  
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      return {
        font_size = 12.0,
        color_scheme = "Dracula",
        window_background_opacity = 0.9,
        use_fancy_tab_bar = false,
      }
    '';
  };
}


{{
  programs.starship = {
    enable = true;
    settings = {
      # Configure what modules to show
      format = "$directory$git_branch$git_status$python$nodejs$rust$golang$cmd_duration$character";
      
      # Customize appearance
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      directory = {
        truncation_length = 3;
        style = "bold blue";
      };
      
      git_branch = {
        symbol = " ";
        style = "bold purple";
      };
      
      python = {
        symbol = "🐍 ";
        python_binary = "python3";
      };
    };
  };
}
  # Better tools that enhance bash experience
  programs.starship.enable = true;  # Amazing prompt
  programs.direnv.enable = true;    # Auto environment loading
  programs.fzf.enable = true;       # Fuzzy finder (Ctrl+R history)
  programs.bat.enable = true;       # Better cat
  programs.eza.enable = true;       # Better ls
  programs.zoxide.enable = true;    # Smart cd
  
  # Terminal multiplexers
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      gruvbox
    ];
  };
}



{
  # Starship - cross-shell prompt (works with bash!)
  programs.starship = {
    enable = true;
    settings = {
      format = "$all$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      git_branch.symbol = " ";
      git_status = {
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };
    };
  };



  # Or 
  {
  programs.starship = {
    enable = true;
    settings = {
      # Configure what modules to show
      format = "$directory$git_branch$git_status$python$nodejs$rust$golang$cmd_duration$character";
      
      # Customize appearance
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      directory = {
        truncation_length = 3;
        style = "bold blue";
      };
      
      git_branch = {
        symbol = " ";
        style = "bold purple";
      };
      
      python = {
        symbol = "🐍 ";
        python_binary = "python3";
      };
    };
  };
}




  # Or pure bash solution - Bash-it framework
  programs.bash.initExtra = ''
    # Clone bash-it for rich themes
    export BASH_IT="$HOME/.bash_it"
    source "$BASH_IT/bash_it.sh"
  '';
}



{
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline          # Status line
      nerdtree            # File explorer  
      vim-gitgutter       # Git integration
      fzf-vim             # Fuzzy finder
      vim-commentary      # Easy commenting
    ];
    extraConfig = ''
      set number relativenumber
      set tabstop=2 shiftwidth=2 expandtab
      colorscheme gruvbox
    '';
  };
}


}
