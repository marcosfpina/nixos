{ pkgs, self }:

let
  mkLd = pkgs.lib.makeLibraryPath;
in
{
  # VM and ISO builds
  vm-image = self.nixosConfigurations.kernelcore.config.system.build.vm;
  iso = self.nixosConfigurations.kernelcore-iso.config.system.build.isoImage;

  # Docker images - exposed as individual packages
  image-app = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/app";
    tag = "dev";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [
        pkgs.bash
        pkgs.coreutils
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [ "PATH=/bin" ];
      Cmd = [
        "bash"
        "-lc"
        "echo hello-from-app"
      ];
    };
  };

  # imagem base com runtime CUDA a partir do closure Nix (sem puxar ubuntu)
  image-cuda-runtime = pkgs.dockerTools.buildImage {
    name = "ghcr.io/voidnxlabs/cuda-runtime";
    tag = "cuda-12";
    copyToRoot = pkgs.buildEnv {
      name = "cuda-image-root";
      paths = with pkgs; [
        bash
        coreutils
        cudatoolkit
        cudaPackages.cudnn
        cudaPackages.nccl
      ];
      pathsToLink = [ "/bin" ];
    };
    config = {
      Env = [
        "LD_LIBRARY_PATH=${
          mkLd [
            pkgs.cudatoolkit
            pkgs.stdenv.cc.cc.lib
          ]
        }"
        "PATH=/bin"
      ];
      Cmd = [ "bash" ];
    };
  };
}
