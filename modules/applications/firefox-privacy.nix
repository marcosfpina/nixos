{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.firefox-privacy;
in
{
  options.programs.firefox-privacy = {
    enable = mkEnableOption "Enable privacy-focused Firefox configuration";

    enableGoogleAuthenticator = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Google Authenticator integration";
    };

    enableHardening = mkOption {
      type = types.bool;
      default = true;
      description = "Enable enhanced security and privacy settings";
    };

    enableContainers = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Multi-Account Containers for privacy isolation";
    };
  };

  config = mkIf cfg.enable {
    # Install Firefox with custom profile
    programs.firefox = {
      enable = true;

      # Privacy-focused policies
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableFormHistory = true;
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "never";

        # Search engine (DuckDuckGo)
        SearchEngines = {
          Default = "DuckDuckGo";
          PreventInstalls = false;
        };

        # Enhanced Tracking Protection
        EnableTrackingProtection = {
          Value = true;
          Cryptomining = true;
          Fingerprinting = true;
          Locked = true;
        };

        # Permissions
        Permissions = {
          Camera = {
            BlockNewRequests = true;
            Locked = true;
          };
          Microphone = {
            BlockNewRequests = true;
            Locked = true;
          };
          Location = {
            BlockNewRequests = true;
            Locked = true;
          };
          Notifications = {
            BlockNewRequests = true;
            Locked = true;
          };
        };

        # Security
        Certificates = {
          ImportEnterpriseRoots = false;
        };

        # Disable AutoFill
        PasswordManagerEnabled = false;

        # Extensions (privacy-focused)
        ExtensionSettings = {
          # uBlock Origin
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };

          # Privacy Badger
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          };

          # HTTPS Everywhere
          "https-everywhere@eff.org" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/https-everywhere/latest.xpi";
          };

          # Decentraleyes
          "jid1-BoFifL9Vbdl2zQ@jetpack" = mkIf cfg.enableHardening {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";
          };

          # Cookie AutoDelete
          "CookieAutoDelete@kennydo.com" = mkIf cfg.enableHardening {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-autodelete/latest.xpi";
          };

          # Multi-Account Containers
          "@testpilot-containers" = mkIf cfg.enableContainers {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
          };
        };
      };

      # Custom user preferences (about:config)
      preferences = {
        # Privacy
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.resistFingerprinting" = true;
        "privacy.firstparty.isolate" = true;

        # Disable telemetry
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        # Disable Pocket
        "extensions.pocket.enabled" = false;

        # DNS over HTTPS
        "network.trr.mode" = 2;  # 2 = prefer DoH, 3 = require DoH
        "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";

        # WebRTC privacy
        "media.peerconnection.enabled" = false;  # Disable WebRTC
        "media.peerconnection.ice.default_address_only" = true;
        "media.peerconnection.ice.no_host" = true;
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

        # Referrer policy
        "network.http.referer.XOriginPolicy" = 2;
        "network.http.referer.XOriginTrimmingPolicy" = 2;

        # Disable prefetching
        "network.prefetch-next" = false;
        "network.dns.disablePrefetch" = true;
        "network.predictor.enabled" = false;

        # Security
        "security.ssl.require_safe_negotiation" = true;
        "security.tls.version.min" = 3;  # TLS 1.3 minimum
        "security.OCSP.require" = true;

        # Disable location tracking
        "geo.enabled" = false;
        "geo.provider.network.url" = "";

        # Hardware acceleration (keep for performance)
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;

        # Password management (disable built-in)
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;

        # Search suggestions
        "browser.search.suggest.enabled" = false;
        "browser.urlbar.suggest.searches" = false;

        # Safe Browsing (keep for security)
        "browser.safebrowsing.malware.enabled" = true;
        "browser.safebrowsing.phishing.enabled" = true;

        # New tab page
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
      };
    };

    # Google Authenticator integration (via PAM)
    security.pam.oath = mkIf cfg.enableGoogleAuthenticator {
      enable = true;
    };

    # Install Google Authenticator PAM module
    environment.systemPackages = with pkgs; [
      google-authenticator
    ] ++ optional cfg.enableGoogleAuthenticator libpam_oath;

    # Firefox hardening script
    environment.etc."firefox/harden.sh" = mkIf cfg.enableHardening {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # Additional Firefox hardening for user profiles

        PROFILE_DIR="$HOME/.mozilla/firefox"

        if [ ! -d "$PROFILE_DIR" ]; then
          echo "Firefox profile not found. Run Firefox first."
          exit 1
        fi

        # Find default profile
        DEFAULT_PROFILE=$(${pkgs.gnugrep}/bin/grep -oP "(?<=Path=).*" "$PROFILE_DIR/profiles.ini" | head -1)

        if [ -z "$DEFAULT_PROFILE" ]; then
          echo "No default profile found"
          exit 1
        fi

        PREFS_FILE="$PROFILE_DIR/$DEFAULT_PROFILE/user.js"

        echo "Applying privacy hardening to $DEFAULT_PROFILE"

        # Additional user.js preferences for maximum privacy
        cat >> "$PREFS_FILE" <<'EOF'
        // Additional privacy hardening
        user_pref("privacy.resistFingerprinting.letterboxing", true);
        user_pref("privacy.partition.network_state", true);
        user_pref("privacy.partition.serviceWorkers", true);
        user_pref("privacy.query_stripping.enabled", true);
        user_pref("privacy.query_stripping.enabled.pbmode", true);

        // WebGL fingerprinting protection
        user_pref("webgl.disabled", true);
        user_pref("webgl.enable-webgl2", false);

        // Canvas fingerprinting protection
        user_pref("privacy.resistFingerprinting.autoDeclineNoUserInputCanvasPrompts", true);

        // Battery API
        user_pref("dom.battery.enabled", false);

        // Gamepad API
        user_pref("dom.gamepad.enabled", false);

        // Network Information API
        user_pref("dom.netinfo.enabled", false);

        // WebVR/WebXR
        user_pref("dom.vr.enabled", false);
        EOF

        echo "Firefox privacy hardening complete"
      '';
    };

    # Firejail profile for Firefox (optional sandboxing)
    environment.etc."firejail/firefox.local" = mkIf cfg.enableHardening {
      text = ''
        # Firefox Firejail profile
        private-dev
        private-tmp
        noroot
        seccomp
        netfilter
        apparmor

        # Allow Firefox config
        noblacklist ''${HOME}/.mozilla

        # Read-only system directories
        read-only /opt
        read-only /srv
      '';
    };
  };
}
