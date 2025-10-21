{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.network.vpn.nordvpn;
in
{
  options.kernelcore.network.vpn.nordvpn = {
    enable = mkEnableOption "Enable NordVPN with NordLynx (WireGuard) integration";

    credentialsFile = mkOption {
      type = types.str;
      default = "/etc/nixos/secrets/vpn/nordvpn-credentials";
      description = "Path to NordVPN credentials file (SOPS encrypted)";
    };

    autoConnect = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically connect to NordVPN on boot";
    };

    preferredCountry = mkOption {
      type = types.str;
      default = "United_States";
      description = "Preferred NordVPN server country";
    };

    protocol = mkOption {
      type = types.enum [
        "nordlynx"
        "wireguard"
        "openvpn"
      ];
      default = "nordlynx";
      description = "VPN protocol to use";
    };
  };

  config = mkIf cfg.enable {
    # WireGuard kernel module for NordLynx
    boot.kernelModules = [ "wireguard" ];

    # Install NordVPN and related tools
    environment.systemPackages = with pkgs; [
      wireguard-tools
      openresolv
      curl
      jq
    ];

    # Create NordVPN configuration directory
    systemd.tmpfiles.rules = [
      "d /etc/nordvpn 0750 root root -"
      "d /var/lib/nordvpn 0750 root root -"
      "d /etc/nixos/secrets/vpn 0750 root root -"
    ];

    # NordVPN API helper script
    environment.etc."nordvpn/api-helper.sh" = {
      mode = "0750";
      text = ''
        #!/usr/bin/env bash
        # NordVPN API Helper for NordLynx configuration

        API_BASE="https://api.nordvpn.com/v1"
        CRED_FILE="${cfg.credentialsFile}"

        # Get recommended server for country
        get_recommended_server() {
          local country="$1"
          ${pkgs.curl}/bin/curl -s "''${API_BASE}/servers/recommendations?filters\\[country_id\\]=$(get_country_id $country)&filters\\[servers_technologies\\]\\[identifier\\]=wireguard_udp&limit=1" | \
            ${pkgs.jq}/bin/jq -r '.[0].hostname'
        }

        # Get country ID from name
        get_country_id() {
          local country="$1"
          ${pkgs.curl}/bin/curl -s "''${API_BASE}/servers/countries" | \
            ${pkgs.jq}/bin/jq -r ".[] | select(.name==\"$country\") | .id"
        }

        # Get server info
        get_server_info() {
          local hostname="$1"
          ${pkgs.curl}/bin/curl -s "''${API_BASE}/servers?filters\\[hostname\\]=$hostname"
        }

        # Main command dispatcher
        case "$1" in
          recommend)
            get_recommended_server "${cfg.preferredCountry}"
            ;;
          server-info)
            get_server_info "$2"
            ;;
          *)
            echo "Usage: $0 {recommend|server-info <hostname>}"
            exit 1
            ;;
        esac
      '';
    };

    # WireGuard NordLynx configuration template
    networking.wg-quick.interfaces = mkIf (cfg.protocol == "nordlynx") {
      wgnord = {
        autostart = cfg.autoConnect;

        # Address assigned by NordVPN (user must obtain from NordVPN account)
        address = [ "10.5.0.2/16" ];

        # Private key (stored in SOPS secrets)
        privateKeyFile = "${cfg.credentialsFile}/private-key";

        # DNS servers
        dns = [
          "103.86.96.100"
          "103.86.99.100"
        ];

        peers = [
          {
            # Public key from NordVPN server (must be updated per server)
            # User needs to get this from NordVPN API or account
            publicKey = "SERVER_PUBLIC_KEY_HERE";

            # NordVPN server endpoint
            endpoint = "xx.nordvpn.com:51820";

            # Route all traffic through VPN
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];

            # Keep alive
            persistentKeepalive = 25;
          }
        ];
      };
    };

    # Firewall rules for VPN
    networking.firewall = {
      # Allow WireGuard
      allowedUDPPorts = [ 51820 ];

      # Prevent leaks - only allow traffic through VPN interface when connected
      extraCommands = mkIf cfg.autoConnect ''
        # Kill switch: drop non-VPN traffic when VPN is supposed to be active
        iptables -I OUTPUT ! -o wgnord -m mark ! --mark $(wg show wgnord fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
      '';
    };

    # NordVPN connection management service
    systemd.services.nordvpn-manager = {
      description = "NordVPN Connection Manager";
      after = [ "network-online.target" ];
      wantedBy = mkIf cfg.autoConnect [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "nordvpn-connect" ''
          #!/bin/sh
          # Get recommended server
          SERVER=$(/etc/nordvpn/api-helper.sh recommend)

          echo "Connecting to NordVPN server: $SERVER"
          logger -t nordvpn "Connecting to $SERVER"

          # Start WireGuard interface
          ${pkgs.wireguard-tools}/bin/wg-quick up wgnord || true
        '';

        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down wgnord || true";
        Restart = "on-failure";
        RestartSec = 30;
      };
    };

    # GNOME Shell extension integration (optional UI)
    # This allows monitoring VPN status from GNOME top bar
    environment.shellAliases = {
      vpn-connect = "sudo systemctl start nordvpn-manager";
      vpn-disconnect = "sudo systemctl stop nordvpn-manager";
      vpn-status = "${pkgs.wireguard-tools}/bin/wg show wgnord";
      vpn-logs = "journalctl -u nordvpn-manager -f";
    };

    # VPN status monitoring script
    environment.etc."nordvpn/check-connection.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Check if VPN is connected and working

        if ${pkgs.wireguard-tools}/bin/wg show wgnord 2>/dev/null | grep -q "interface: wgnord"; then
          echo "VPN Connected"

          # Check public IP
          PUBLIC_IP=$(${pkgs.curl}/bin/curl -s --max-time 5 https://api.ipify.org)
          echo "Public IP: $PUBLIC_IP"

          # Verify it's a NordVPN IP
          ${pkgs.curl}/bin/curl -s "https://nordvpn.com/wp-admin/admin-ajax.php?action=get_user_info_data" | \
            ${pkgs.jq}/bin/jq -r '.status'
        else
          echo "VPN Disconnected"
          exit 1
        fi
      '';
    };
  };
}
