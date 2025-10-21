{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.llamacpp;

in
{
  options.services.llamacpp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable llamacpp service";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.llama-cpp;
      description = "The llamacpp package to use";
    };

    model = mkOption {
      type = types.str;
      description = "Path to the model file";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host to bind to";
    };

    n_threads = mkOption {
      type = types.int;
      default = 8;
      description = "Number of threads to use";
    };

    n_gpu_layers = mkOption {
      type = types.int;
      default = 0;
      description = "Number of layers to offload to GPU";
    };

    n_batch = mkOption {
      type = types.int;
      default = 512;
      description = "Batch size for processing";
    };

    n_ctx = mkOption {
      type = types.int;
      default = 2048;
      description = "Context size";
    };

    n_predict = mkOption {
      type = types.int;
      default = 128;
      description = "Number of tokens to predict";
    };

    temp = mkOption {
      type = types.float;
      default = 0.8;
      description = "Temperature for sampling";
    };

    top_p = mkOption {
      type = types.float;
      default = 0.9;
      description = "Top-p sampling parameter";
    };

    repeat_penalty = mkOption {
      type = types.float;
      default = 1.1;
      description = "Penalty for repeated tokens";
    };

    numa = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NUMA support";
    };

    mmap = mkOption {
      type = types.bool;
      default = true;
      description = "Use memory mapping";
    };

    mlock = mkOption {
      type = types.bool;
      default = false;
      description = "Lock memory pages";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose output";
    };

    log_disable = mkOption {
      type = types.bool;
      default = false;
      description = "Disable logging";
    };

    embedding = mkOption {
      type = types.bool;
      default = false;
      description = "Enable embedding mode";
    };

    lora_adapter = mkOption {
      type = types.str;
      default = "";
      description = "LoRA adapter path";
    };

    n_ubatch = mkOption {
      type = types.int;
      default = 512;
      description = "Un-batched processing size";
    };

    n_parallel = mkOption {
      type = types.int;
      default = 1;
      description = "Number of parallel requests";
    };

    rope_freq_base = mkOption {
      type = types.float;
      default = 10000.0;
      description = "RoPE frequency base";
    };

    rope_freq_scale = mkOption {
      type = types.float;
      default = 1.0;
      description = "RoPE frequency scale";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.llamacpp = {
      description = "Llama.cpp server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/llama-server ${
          builtins.concatStringsSep " " (
            [
              "--host ${cfg.host}"
              "--port ${toString cfg.port}"
              "--model ${cfg.model}"
              "--threads ${toString cfg.n_threads}"
              "--gpu-layers ${toString cfg.n_gpu_layers}"
              "--batch-size ${toString cfg.n_batch}"
              "--ctx-size ${toString cfg.n_ctx}"
              "--predict ${toString cfg.n_predict}"
              "--temp ${toString cfg.temp}"
              "--top-p ${toString cfg.top_p}"
              "--repeat-penalty ${toString cfg.repeat_penalty}"
              "--rope-freq-base ${toString cfg.rope_freq_base}"
              "--rope-freq-scale ${toString cfg.rope_freq_scale}"
              "--parallel ${toString cfg.n_parallel}"
              "--ubatch-size ${toString cfg.n_ubatch}"
            ]
            ++ lib.optionals cfg.numa [ "--numa distribute" ]
            ++ lib.optionals (!cfg.mmap) [ "--no-mmap" ]
            ++ lib.optionals cfg.mlock [ "--mlock" ]
            ++ lib.optionals cfg.verbose [ "--log-verbose" ]
            ++ lib.optionals cfg.log_disable [ "--log-disable" ]
            ++ lib.optionals cfg.embedding [ "--embeddings" ]
            ++ lib.optionals (cfg.lora_adapter != "") [ "--lora ${cfg.lora_adapter}" ]
          )
        }";
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
