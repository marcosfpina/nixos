{
  config,
  lib,
  pkgs,
  ...
}:

{

  kernelcore = {
    system = {
      memory.optimizations.enable = true;
      nix.optimizations.enable = true;
      nix.experimental-features.enable = true;
    };

    security = {
      hardening.enable = true;
      sandbox-fallback = true;
    };

    nvidia = {
      enable = true;
      cudaSupport = true;
    };

    development = {
      rust.enable = true;
      go.enable = true;
      python.enable = true;
      nodejs.enable = true;
      nix.enable = true;
      jupyter = {
        enable = true;
        kernels = {
          python.enable = true;
          rust.enable = true;
          nodejs.enable = true;
        };
        extensions.enable = true;
      };
    };

    containers = {
      docker.enable = true;
      nixos.enable = true;
    };

    virtualization = {
      enable = true;
      virt-manager = true;
      libvirtdGroup = [ "kernelcore" ];
      virtiofs.enable = true;
    };
  };

  services = {
    gnome.core-shell.enable = true;
    gnome.core-apps.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "br";
        variant = "";
      };
    };

    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    llamacpp = {
      enable = true;
      model = "/var/lib/llamacpp/models/L3-8B-Stheno-v3.2-Q4_K_S.gguf";
      port = 8080;
      n_threads = 16;
      n_gpu_layers = 35;
      n_parallel = 4;
      n_ctx = 4096;
    };

    ollama = {
      enable = true;
      host = "127.0.0.1"; # Security: Bind to localhost only
      acceleration = "cuda";
    };

    gitea = {
      enable = true;
      settings = {
        server = {
          DOMAIN = "git.voidnxlabs";
          ROOT_URL = "http://git.voidnxlabs:3000/";
          HTTP_PORT = 3000;
        };
        service = {
          DISABLE_REGISTRATION = false;
        };
        database = {
          DB_TYPE = "sqlite3";
          HOST = "localhost";
          NAME = "gitea";
          USER = "kernelcore";
        };
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "kernelcore" ];
      ensureUsers = [
        {
          name = "kernelcore";
          ensureDBOwnership = true;
        }
      ];
    };

    etcd = {
      enable = true;
      name = "etc";
    };

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    libinput.enable = true;
    printing.enable = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
    ];

  time.timeZone = "America/Scoresbysund";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "kl_GL.UTF-8";
    LC_IDENTIFICATION = "kl_GL.UTF-8";
    LC_MEASUREMENT = "kl_GL.UTF-8";
    LC_MONETARY = "kl_GL.UTF-8";
    LC_NAME = "kl_GL.UTF-8";
    LC_NUMERIC = "kl_GL.UTF-8";
    LC_PAPER = "kl_GL.UTF-8";
    LC_TELEPHONE = "kl_GL.UTF-8";
    LC_TIME = "kl_GL.UTF-8";
  };

  console.keyMap = "br-abnt2";

  security.rtkit.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  # hardware.nvidia-container-toolkit.enable moved to modules/hardware/nvidia.nix
  #hardware.nvidia.datacenter.enable = true; # Conflicting with xserver drivers

  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 (ForceFullCompositionPipeLIne=On)"
  '';

  users.users.kernelcore = {
    isNormalUser = true;
    description = "kernel";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "nvidia"
      "docker"
      "render"
      "qemu-libvirtd"
      "libvirtd"
    ];
    hashedPasswordFile = "/etc/nixos/sec/user-password";
    packages = with pkgs; [

      obsidian
      sssd
      vscodium
      trezor-suite
      tmux
      starship
      terraform

      gemini-cli
      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm

      libreoffice

      claude-code
      alacritty
      xclip

      glab
      gh
      codeberg-cli

      zed-editor
      rust-analyzer
      rustup

      terraform-providers.carlpett_sops
      terraform-providers.hashicorp_vault

      gnomeExtensions.gtile
      gnomeExtensions.awesome-tiles
    ];
  };

  # Guest user with nvidia group access for testing
  users.users.guest = {
    isNormalUser = true;
    description = "Guest User";
    extraGroups = [
      "video"
      "audio"
      "nvidia"
      "render"
    ];
    # Guest user with a simple password (change this!)
    initialPassword = "guest";
  };

  users.extraGroups.docker.members = [ "kernelcore" ];

  programs = {
    firefox.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.nvidia.acceptLicense = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    ninja
    cudatoolkit
    cmake
    gcc
    docker-compose
    docker-buildx
    docker
    gnumake
    ollama
  ];

  system.stateVersion = "25.05";
}
