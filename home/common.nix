# Universal home-manager config for jack — imported on every host.
{ config, pkgs, lib, ... }:

let
  tmuxStatusRight = pkgs.writeShellApplication {
    name = "tmux-status-right";
    runtimeInputs = lib.optionals pkgs.stdenv.isLinux (with pkgs; [ upower gawk ]);
    text = ''
      battery() {
        local BATTERY="🔋️" CHARGER="🔌️" PERCENTAGE="" STATE=""

        if [[ "$(uname)" == "Linux" ]]; then
          local BAT_PATH UPOWER
          BAT_PATH=$(upower -e | grep 'BAT' || true)
          [[ -z "$BAT_PATH" ]] && return
          UPOWER=$(upower -i "$BAT_PATH")
          getfield() { echo "$UPOWER" | awk -v field="$1" 'match($0, field) { print $2 }'; }
          PERCENTAGE=$(getfield "percentage")
          [[ "$(getfield "state")" =~ .*"discharging".* ]] && STATE="$BATTERY" || STATE="$CHARGER"

        elif [[ "$(uname)" == "Darwin" ]]; then
          local POWER
          POWER=$(pmset -g batt)
          PERCENTAGE=$(echo "$POWER" | grep -oE "[0-9]{2,3}%")
          pmset -g batt | grep -q "Battery Power" && STATE="$BATTERY" || STATE="$CHARGER"
        fi

        if [[ -n "$PERCENTAGE" && -n "$STATE" ]]; then
          local COLOR
          case $PERCENTAGE in
            100%|9[0-9]%|8[0-9]%|7[0-9]%) COLOR="#[bg=#98c379]#[fg=#2a2f39]" ;;
            6[0-9]%|5[0-9]%|4[0-9]%|3[0-9]%) COLOR="#[bg=#e5c07b]#[fg=#2a2f39]" ;;
            2[0-9]%|1[0-9]%|[0-9]%) COLOR="#[bg=#e06c75]#[fg=#2a2f39]" ;;
          esac
          printf "%s " "$COLOR $PERCENTAGE $STATE #[default]"
        fi
      }

      battery
      printf "%s" "$(date +'%a %b %d %I:%M %p') "
    '';
  };
in

{
  home.username = "jack";
  home.homeDirectory = "/home/jack";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.git
    pkgs.wget
    pkgs.curl
    pkgs.httpie
  ];

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jack Lewis";
        email = "jack@jacklew.is";
      };

      push = {
        autoSetupRemote = true;
      };

      # Any clone of the silversight-ai org is transparently rewritten to the
      # github-work SSH alias, so it uses the work key even with a normal
      # git@github.com:silversight-ai/... URL. Applies at clone time (unlike
      # gitdir includes), and the rewrite persists for later fetch/push.
      url."git@github-work:silversight-ai/".insteadOf = "git@github.com:silversight-ai/";

      alias = {
        a = "add";
        aa = "add -A";
        b = "branch";
        bd = "branch -D";
        c = "commit";
        cm = "commit -m";
        co = "checkout";
        cb = "checkout -b";
        cl = "clone";
        d = "diff HEAD --ignore-space-at-eol -b -w";
        s = "status";
        st = "stash";
        sd = "stash shop -p";
        sp = "stash pop";
        stls = "stash list";
        l = "log --pretty=oneline --decorate --abbrev-commit --mac-count=15";
        ll = "log --graph --pretty=format:'%Cred%h%Creset %an: %s %Creset%Cgreen(%cr)%Creset' --abbrev-commit --date=relative";
      };
    };

    # Repos under ~/git/work/ commit as the Silversight identity. The SSH *key*
    # is selected by host alias (see programs.ssh below), not here — core.sshCommand
    # can't be used for this because it doesn't apply during `git clone`.
    includes = [{
      condition = "gitdir:~/git/work/";
      contents.user.email = "jlewis@silversight.ai";
    }];
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "jack@jacklew.is";
        name = "Jack Lewis";
      };
    };
  };

  programs.ssh = {
    enable = true;
    settings = {
      # Route all SSH auth through the 1Password agent.
      "*".IdentityAgent = "~/.1password/agent.sock";

      # Personal GitHub (default) -> personal key only.
      "github.com" = {
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_personal.pub";
      };

      # Work GitHub: clone/remote as git@github-work:ORG/repo.git to use the
      # Silversight key. Same real host (github.com), different account, so an
      # alias is the only way ssh can tell them apart.
      "github-work" = {
        HostName = "github.com";
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_work.pub";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withPython3 = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      plenary-nvim
      vim-tmux-navigator
      telescope-nvim
      persistence-nvim
      vim-better-whitespace
      neo-tree-nvim
      vim-suda
      fzf-wrapper
      vim-jsonnet
      ack-vim
      {
        plugin = catppuccin-nvim;
        type = "lua";
        config = ''vim.cmd.colorscheme "catppuccin-mocha"'';
      }
    ];

    initLua = ''
      vim.opt.list = true
      vim.opt.listchars = { tab = "> ", eol = "¬" }
      vim.opt.shiftwidth = 2
      vim.opt.number = true
      vim.opt.scrolloff = 10
      vim.opt.cursorline = true
      vim.opt.incsearch = true
      vim.opt.hlsearch = true
      vim.opt.laststatus = 2
      vim.opt.matchtime = 1
      vim.opt.shell = "zsh"
      vim.opt.redrawtime = 10000

      vim.keymap.set("n", "<C-p>", ":FZF<CR>")
      vim.keymap.set("n", "<F3>", ":Neotree toggle<CR>", { silent = true })

      require("neo-tree").setup({
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      })
      vim.keymap.set("x", "<", "<gv")
      vim.keymap.set("x", ">", ">gv")
      vim.keymap.set("n", "<leader><space>", ":nohlsearch<CR>")
      vim.keymap.set("n", "<C-s>", ":Ag<Space>")

      vim.cmd [[
        cnoreabbrev W w
        cnoreabbrev Q q
        cnoreabbrev Wq wq
        cnoreabbrev Wa wa
        cnoreabbrev wQ wq
        cnoreabbrev WQ wq
        cnoreabbrev WQa wqa
        cnoreabbrev Wqa wqa
        cnoreabbrev Qa qa
        cnoreabbrev QA qa
        cnoreabbrev Sp sp
        cnoreabbrev Vsp vsp
      ]]

      vim.g.better_whitespace_enabled = 1
      vim.g.strip_whitespace_on_save = 1
      vim.g.suda_smart_edit = 1
      vim.g.ackprg = "ag --vimgrep"

      vim.opt.undofile = true
      vim.opt.undodir = vim.fn.expand("~/.vim/tmp/undo//")
      vim.opt.directory = vim.fn.expand("~/.vim/tmp/swp//")
    '';
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      bind x confirm kill-pane
      bind X confirm kill-window
      set -g base-index 1
      unbind C-b
      set -g prefix C-a
      set -g mode-keys vi
      bind-key C-a send-prefix
      set -g mouse on
      set -g focus-events on
      bind m set -g mouse on\; display 'Mouse: ON'
      bind M set -g mouse off\; display 'Mouse: OFF'
      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -c "#{pane_current_path}"
      bind c new-window -c "$HOME"
      bind x confirm kill-pane
      bind R source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
      bind-key < swap-window -t -
      bind-key > swap-window -t +
      set-option -g renumber-windows on
      set-option -g automatic-rename off
      set-option -g allow-rename off
      bind-key n command-prompt "rename-window %%"
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      set -g status-right "#(${tmuxStatusRight}/bin/tmux-status-right)"
      set -g status-interval 10
    '';
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      {
        plugin = catppuccin;
        # Must be set before catppuccin loads (home-manager emits this before
        # the plugin's run-shell). catppuccin defaults these to "#T" (pane
        # title), so manual rename-window (#W) wasn't reflected in the status bar.
        extraConfig = ''
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
        '';
      }
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls = "ls -lAh";
      update = "sudo nixos-rebuild switch";
    };

    initContent = ''
      bindkey -v
      export KEYTIMEOUT=1
      bindkey '^w' backward-kill-word
      bindkey '^p' up-history
      bindkey '^n' down-history

      KEYTIMEOUT=1

      clear-screen() clear
      bindkey '^o' clear-screen
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^H' backward-delete-char
      zle -N history-substring-search-up
      zle -N history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down
      zle -N history-substring-search-up
      zle -N history-substring-search-down
    '';

    antidote = {
      enable = true;
      plugins = [''
        "mafredri/zsh-async"
        "sindresorhus/pure"
        "zsh-users/zsh-syntax-highlighting"
        "zsh-users/zsh-history-substring-search"
        "zsh-users/zsh-completions"
      ''];
    };
  };

  home.file = {
    # Public keys for the 1Password SSH agent. `IdentitiesOnly=yes` + `-i` in
    # git's core.sshCommand makes ssh offer only the matching agent key, so
    # personal and work repos can't cross-authenticate.
    ".ssh/id_personal.pub".text =
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuoCQe9g7LnKmnhLbiDE1UT0VkKNX43ofVvQODSVPKC8LspC0Ivi9M5paHLhGupdcGJEc9azVzdL4iP7I6c56if2UAGGp/IFe6tezokmfn4QoGKbjXXOZKl3wR4vs54XpSHUnUlW9UYBXwbk54ksp+TC5BU4RfPtHtXEXIQa8cUf9g5GXuyS0jyjz6JzooYGoFD/8IUU4il+N1aN3Xx8n9Le+0UOc0CovpUQe6RYXatr3luBA/GZNKTj9sM8NYZ7jtoKmtQp4lXn877Gzcw4JHuNmzWAWMDwcyCAICH0EQDZEk2olPXU7lqdr1l9APtSOBywJI5lMGJxPwqruiTjJW2gVGh1nE3jmUcl2+ZJvsXBK32Du7XBOt+E9Vi8Tl/9pGouvHHs+dJc62vrWjDH0pkbz7WoouAZ3ls1pFHb4hllFKjvVsQIO2kb/87/sI/odvs1+Jp/pLnp5elAGlpX3l0XQqMsrEBcOt8qmqvHfWw34ugCnh7j13Lw7EazoZf6E= Jack Personal (1Password)\n";
    ".ssh/id_work.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2GSggeyH8qm1W9usBHFeaTgj9GQGuUU+fXHjNfo0ew Silversight.ai (1Password)\n";

    # 1Password SSH agent: which vaults' keys it serves. Personal holds the
    # personal key; Silversight.ai holds the work key. Without this, the agent
    # only serves the Private/Personal vault and the work key is invisible.
    ".config/1Password/ssh/agent.toml".text = ''
      [[ssh-keys]]
      vault = "Personal"

      [[ssh-keys]]
      vault = "Silversight.ai"
    '';


  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  programs.home-manager.enable = true;
}
