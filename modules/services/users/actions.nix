{ config, pkgs, ... }:

let
  runnerVersion = "2.329.0";
  runnerArchive = "actions-runner-linux-x64-${runnerVersion}.tar.gz";
  runnerUrl = "https://github.com/actions/runner/releases/download/v${runnerVersion}/${runnerArchive}";
in
{
  # create a dedicated system user
  users.users.actions = {
    isSystemUser = true;
    createHome = true;
    home = "/var/lib/actions-runner";
    description = "GitHub Actions Runner user";
    extraGroups = [ "wheel" ]; # add docker if you need docker access: "docker"
  };

  # store registration env file (managed by Nix)
  environment.etc."github-runner.env".text = ''
    # WARNING: token is short-lived — update this before running registration
    RUNNER_URL="https://github.com/VoidNxSEC"
    RUNNER_TOKEN="BGNJEPYDKV4LUSOPUD532CLI65GXY"
    RUNNER_NAME="nixos-runner"
    RUNNER_WORK_DIR="/var/lib/actions-runner/_work"
  '';

  systemd.services.actions-runner = {
    description = "GitHub Actions Runner (managed by NixOS)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      User = "actions";
      Group = "actions";
      WorkingDirectory = "/var/lib/actions-runner";
      Restart = "always";
      RestartSec = "3s";
      EnvironmentFile = "/etc/github-runner.env";
    };

    # Pre-start will download/extract and run one-time registration if not already configured.
    # If you prefer to register manually, remove the ExecStartPre block and run ./config.sh manually.
    preStart = ''
      set -euo pipefail
      if [ ! -x /var/lib/actions-runner/run.sh ]; then
        mkdir -p /var/lib/actions-runner
        chown actions:actions /var/lib/actions-runner
        curl -fsSLo /tmp/${runnerArchive} "${runnerUrl}"
        tar xzf /tmp/${runnerArchive} -C /var/lib/actions-runner
        chown -R actions:actions /var/lib/actions-runner
      fi

      # if not configured yet, configure unattended
      if [ ! -f /var/lib/actions-runner/.runner ]; then
        if [ -z "${RUNNER_TOKEN-}" ] || [ -z "${RUNNER_URL-}" ]; then
          echo "RUNNER_TOKEN or RUNNER_URL missing in /etc/github-runner.env; cannot register runner"
          exit 1
        fi

        su -s /bin/sh actions -c '
          cd /var/lib/actions-runner
          ./config.sh --unattended --url "$RUNNER_URL" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME" --work "$RUNNER_WORK_DIR"
        '
      fi
    '';

    serviceConfig.ExecStart = "/var/lib/actions-runner/run.sh";
  };
}
