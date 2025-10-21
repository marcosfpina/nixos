{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.dns-resolver;
in
{
  options.kernelcore.network.dns-resolver = {
    enable = mkEnableOption "Enable DNS resolver optimization for network performance";

    preferredServers = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1" # Cloudflare Primary
        "1.0.0.1" # Cloudflare Secondary
        "8.8.8.8" # Google Primary
        "8.8.4.4" # Google Secondary
      ];
      description = "Preferred DNS servers in priority order";
    };

    enableDNSSEC = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DNSSEC validation for enhanced security";
    };

    enableDNSCrypt = mkOption {
      type = types.bool;
      default = false;
      description = "Enable DNSCrypt for encrypted DNS queries";
    };

    cacheTTL = mkOption {
      type = types.int;
      default = 3600;
      description = "DNS cache TTL in seconds";
    };
  };

  config = mkIf cfg.enable {
    # Use systemd-resolved for modern DNS management
    services.resolved = {
      enable = true;
      dnssec = if cfg.enableDNSSEC then "true" else "false";
      dnsovertls = "opportunistic";

      # Fallback DNS servers
      fallbackDns = cfg.preferredServers;

      extraConfig = ''
        DNSStubListener=yes
        Cache=yes
        CacheFromLocalhost=yes
        ReadEtcHosts=yes
        MulticastDNS=yes
        LLMNR=yes
      '';
    };

    # DNSCrypt-proxy for encrypted DNS (optional)
    services.dnscrypt-proxy2 = mkIf cfg.enableDNSCrypt {
      enable = true;
      settings = {
        listen_addresses = [ "127.0.0.1:53" ];
        server_names = [
          "cloudflare"
          "google"
        ];

        ipv4_servers = true;
        ipv6_servers = false;

        dnscrypt_servers = true;
        doh_servers = true;

        require_dnssec = cfg.enableDNSSEC;
        require_nolog = true;
        require_nofilter = true;

        timeout = 5000;
        keepalive = 30;

        cache = true;
        cache_size = 4096;
        cache_min_ttl = 2400;
        cache_max_ttl = cfg.cacheTTL;
        cache_neg_ttl = 60;
      };
    };

    # Network configuration
    networking = {
      nameservers = mkIf (!cfg.enableDNSCrypt) cfg.preferredServers;

      # Optimize network parameters for DNS performance
      firewall.allowedUDPPorts = mkIf cfg.enableDNSCrypt [ 53 ];

      dhcpcd.extraConfig = ''
        # Use custom DNS servers instead of DHCP-provided ones
        nohook resolv.conf
      '';
    };

    # Create systemd-resolved stub resolver
    systemd.services.systemd-resolved = {
      serviceConfig = {
        # DNS resolver hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallFilter = "@system-service @network-io";
        SystemCallErrorNumber = "EPERM";
      };
    };

    # DNS monitoring and diagnostics
    environment.systemPackages = with pkgs; [
      bind # for dig, nslookup
      dnsutils
      dog # modern dig alternative
      ldns # for drill
    ];

    # DNS performance testing aliases
    environment.shellAliases = {
      dns-test = "${pkgs.bind}/bin/dig @1.1.1.1 google.com";
      dns-bench = "${pkgs.bash}/bin/bash -c 'for srv in 1.1.1.1 8.8.8.8 9.9.9.9; do echo \"Testing \$srv:\"; time ${pkgs.bind}/bin/dig @\$srv google.com +short >/dev/null; done'";
      dns-flush = "systemctl restart systemd-resolved";
      dns-status = "resolvectl status";
    };

    # Systemd service for DNS health monitoring
    systemd.services.dns-health-monitor = {
      description = "DNS Health Monitor";
      after = [
        "network-online.target"
        "systemd-resolved.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 60;
        User = "nobody";
        Group = "nobody";

        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
      };

      script = ''
        while true; do
          sleep 300  # Check every 5 minutes

          # Test DNS resolution
          if ! ${pkgs.bind}/bin/dig +short +time=5 google.com @1.1.1.1 >/dev/null 2>&1; then
            echo "DNS health check failed for Cloudflare (1.1.1.1)"
            logger -t dns-health "Cloudflare DNS unresponsive"
          fi

          if ! ${pkgs.bind}/bin/dig +short +time=5 google.com @8.8.8.8 >/dev/null 2>&1; then
            echo "DNS health check failed for Google (8.8.8.8)"
            logger -t dns-health "Google DNS unresponsive"
          fi
        done
      '';
    };
  };
}
