{
  config,
  lib,
  pkgs,
  ...
}:

{

  systemd.services.docker-pull-images = {
    description = "Pre-pull Docker images";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker pull nvcr.io/nvidia/pytorch:25.09-py3
      ${pkgs.docker}/bin/docker pull ghcr.io/huggingface/text-generation-inference:latest
    '';
  };

  systemd.services.ollama.serviceConfig = {
    DeviceAllow = [
      "/dev/nvidia0 rw"
      "/dev/nvidiactl rw"
      "/dev/nvidia-uvm rw"
    ];
    SupplementaryGroups = [
      "video"
      "nvidia"
    ];
  };

}
