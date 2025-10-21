{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.clamav.enable = mkEnableOption "Enable ClamAV antivirus scanning";
  };

  config = mkIf config.kernelcore.security.clamav.enable {
    ##########################################################################
    # 🦠 ClamAV Antivirus
    ##########################################################################

    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
      updater.interval = "hourly";
      updater.frequency = 24;
    };

    # ClamAV log directory
    systemd.tmpfiles.rules = [
      "d /var/log/clamav 0755 clamav clamav -"
    ];

    # ClamAV scan service
    systemd.services.clamav-scan = {
      description = "ClamAV system scan";
      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "idle";
        ExecStart = ''
          ${pkgs.clamav}/bin/clamscan \
            --recursive \
            --infected \
            --log=/var/log/clamav/scan.log \
            --exclude-dir="^/sys" \
            --exclude-dir="^/proc" \
            --exclude-dir="^/dev" \
            --exclude-dir="^/run" \
            --exclude-dir="^/nix/store" \
            --max-filesize=100M \
            --max-scansize=300M \
            /home
        '';
      };
    };

    # Weekly ClamAV scan timer
    systemd.timers.clamav-scan = {
      description = "Weekly ClamAV scan";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        RandomizedDelaySec = "2h";
        Persistent = true;
      };
    };

    # Systemd hardening for ClamAV daemon
    systemd.services."clamav-daemon".serviceConfig = {
      PrivateTmp = mkForce true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        "/var/lib/clamav"
        "/var/log/clamav"
      ];
    };
  };
}
