{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    kernelcore.security.packages.enable = mkEnableOption "Install security and audit tools";
  };

  config = mkIf config.kernelcore.security.packages.enable {
    ##########################################################################
    # 🔧 Security & Audit Tools
    ##########################################################################

    environment.systemPackages = with pkgs; [
      # Security auditing
      lynis
      vulnix
      aide

      # VPN & Authentication
      wgnord
      google-authenticator

      # Network analysis
      nmap
      tcpdump
      wireshark-cli

      # Secrets management
      vault
      sops
      age

      # Password management
      keepassxc
      pass
      gnupg
      pinentry-curses
      libsecret

      # AI/ML tools (if needed for security analysis)
      ollama
      llama-cpp
      python313Packages.llama-stack-client

      # Uncomment if needed:
      # chkrootkit
      # rkhunter
      # wireshark
      # tripwire
      # htop
      # iotop
      # nethogs
    ];
  };
}
