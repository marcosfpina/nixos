{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.system.memory = {
      optimizations.enable = mkEnableOption "Enable memory optimizations and OOM protection";
      zram.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ZRAM compressed swap";
      };
    };
  };

  config = mkIf config.kernelcore.system.memory.optimizations.enable {
    # Kernel memory management
    boot.kernel.sysctl = {
      # Prevent kernel panics
      "vm.panic_on_oom" = 0;
      "vm.oom_kill_allocating_task" = 1;

      # Memory optimization
      "vm.swappiness" = 80;
      "vm.vfs_cache_pressure" = 200;
      "vm.dirty_ratio" = 10;
      "vm.overcommit_memory" = 2;
      "vm.overcommit_ratio" = 80;
    };

    # Early OOM killer
    services.earlyoom = {
      enable = true;
      freeMemThreshold = 8;
      freeSwapThreshold = 20;
      enableNotifications = true;
    };

    # ZRAM swap
    zramSwap = mkIf config.kernelcore.system.memory.zram.enable {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
      priority = 10;
    };

    # Traditional swap file
    swapDevices = [
      {
        device = "/swapfile";
        size = 16096;
        priority = 5;
      }
    ];
  };
}
