{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.trezor;
in
{
  options.hardware.trezor = {
    enable = mkEnableOption "Trezor hardware wallet udev rules";
  };

  config = mkIf cfg.enable {
    # Add trezor package for trezorctl and dependencies
    environment.systemPackages = with pkgs; [
      trezor-suite
    ];

    # Trezor udev rules
    services.udev.packages = with pkgs; [
      trezor-udev-rules
    ];

    # Add user to plugdev group for Trezor access
    users.groups.plugdev = {};

    # Note: Users need to be added to plugdev group manually
    # users.users.<username>.extraGroups = [ "plugdev" ];
  };
}
