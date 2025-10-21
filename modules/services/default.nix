{
  config,
  pkgs,
  lib,
  ...
}:

{

  services.prometheus = {
    enable = true;
    port = 9090;
    exporters = {
      node = {
        enable = true;
        port = 9100;
      }; # Métricas básicas
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [ { targets = [ "localhost:9100" ]; } ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "localhost";
        http_port = 4000;
      };
    };
  };

  #services.prometheus.exporters.dcgm = { enable = true; port = 9400; };  # Se disponível no Nixpkgs
  # Ou usa pacote custom: environment.systemPackages = [ pkgs.prometheus-nvidia-exporter ];

}
