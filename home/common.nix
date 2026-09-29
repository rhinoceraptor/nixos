# Universal home-manager config for jack — imported on every host.
{ config, pkgs, lib, ... }:

{
  imports = [ ./identities.nix ];

  home.username = "jack";
  home.homeDirectory = "/home/jack";
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.git
    pkgs.wget
    pkgs.curl
    pkgs.httpie
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # tmux-battery prefers acpi over upower (lower CPU usage); guarantee it's
    # present rather than depending on some other module pulling it in.
    pkgs.acpi
  ];

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jack Lewis";
        # No email here: it comes from the generated include in
        # home/identities.nix, so this file has none to leak. `git commit`
        # errors with "Please tell me who you are" until that's generated
        # (i.e. until ~/.config/nixos-identities.json exists and `op` is
        # signed in) — a clear failure rather than a wrong-identity commit.
      };

      push = {
        autoSetupRemote = true;
      };

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

      # Per-identity Host blocks (github.com plus any github-<alias> work
      # accounts) come from the generated include in home/identities.nix.
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
      set -g status-interval 1
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
      {
        plugin = battery.overrideAttrs (old: {
          # Upstream bug: scripts/helpers.sh's is_wsl() treats the substring
          # "Linux" in /proc/version as a WSL signal, but that string is
          # present on every Linux kernel, not just WSL. This makes
          # battery_remain.sh always take the WSL branch first (reading
          # charge_now/charge_full/current_now from sysfs), which errors out
          # with nothing on stdout on real hardware whose battery driver
          # reports energy_now/energy_full/power_now instead (confirmed on
          # this machine) — #{battery_remain} silently renders blank.
          # Narrow the check to the actual WSL signal.
          postInstall = (old.postInstall or "") + ''
            substituteInPlace $out/share/tmux-plugins/battery/scripts/helpers.sh \
              --replace-fail '"$version" == *"Linux"* || ' ""
          '';
        });
        # status-right has to be set here rather than in the top-level
        # extraConfig above: home-manager emits that via mkAfter (i.e. after
        # every plugin's run-shell), but tmux-battery's #{battery_*} tokens
        # aren't live tmux format variables — battery.tmux does a one-time
        # textual substitution into status-right's *current* value when its
        # own run-shell executes, so the placeholders must already be in
        # status-right (and catppuccin's default status-right already
        # overridden) by that point. This also runs after catppuccin above,
        # so it wins over catppuccin's own default status-right.
        #
        # battery_charging_watts is macOS-only (empty string on Linux) but
        # harmless to include everywhere.
        extraConfig = ''
          set -g @batt_remain_short 'true'
          set -g status-right '#{battery_color_bg} #{battery_percentage} #{battery_icon_status} #{battery_remain} #{battery_charging_watts}#[default] %a %b %d %I:%M %p '
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

  # Public keys, the 1Password agent's vault list, and per-identity SSH/git
  # config are all generated at activation time — see home/identities.nix.

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  programs.home-manager.enable = true;
}
