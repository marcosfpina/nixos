{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.virtualization.enable = mkEnableOption "Enable virtualization support (QEMU/KVM)";
    kernelcore.virtualization.virt-manager = mkEnableOption "Enable virt-manager GUI";
    kernelcore.virtualization.libvirtdGroup = mkOption {
      type = types.listOf types.str;
      default = [ "kernelcore" ];
      description = "Users to add to the libvirtd group for VM management";
    };
    kernelcore.virtualization.virtiofs.enable = mkEnableOption "Enable VirtioFS for easy host-guest file sharing";
  };

  config = mkIf config.kernelcore.virtualization.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";

        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;

          # OVMF submodule was removed - UEFI/TPM images now available by default with QEMU
          # For custom OVMF configs, add to environment.systemPackages instead

          # VirtioFS enabled conditionally
          vhostUserPackages = mkIf config.kernelcore.virtualization.virtiofs.enable [ pkgs.virtiofsd ];
        };

        # Allow libvirt group members to manage VMs
        allowedBridges = [
          "virbr0"
          "br0"
        ];
      };

      spiceUSBRedirection.enable = true;
    };

    # PolicyKit rules for non-root VM management
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("libvirtd")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Libvirt extraConfig - moved to top level
    programs.dconf.enable = mkIf config.kernelcore.virtualization.virt-manager true;

    # User group for non-root VM access
    users.groups.libvirtd.members = config.kernelcore.virtualization.libvirtdGroup;

    systemd.tmpfiles.rules = [
      "d /srv/vms/shared 0755 root libvirtd -"
    ];

    # Permite virtiofsd acessar
    #virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

    environment.systemPackages =
      with pkgs;
      [
        qemu
        qemu_kvm
        bridge-utils
      ]
      ++ optionals config.kernelcore.virtualization.virtiofs.enable [
        virtiofsd
      ]
      ++ optionals config.kernelcore.virtualization.virt-manager [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
      ];
  };
}
