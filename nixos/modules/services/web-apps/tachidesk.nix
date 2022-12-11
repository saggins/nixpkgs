{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.tachidesk;
in
{
  ##### interface
  #https://github.com/Suwayomi/Tachidesk-Server/wiki/Configuring-Tachidesk-Server
  options = {
    services.tachidesk = {
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/tachidesk";
        description = "The directory where tachidesk stores its data files.";
      };

      enable = mkEnableOption (lib.mdDoc "tachidesk");

      user = mkOption {
        type = types.str;
        default = "tachidesk";
        description = lib.mdDoc ''
          The user to run tachidesk as.
          By default, a user named "tachidesk" will be created.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "tachidesk";
        description = lib.mdDoc ''
        The group to run tachidesk under.
        By default, a group named "tachidesk" will be created
        '';
      };

      ip = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = lib.mdDoc "option can be either domain or IP";
      };

      port = mkOption {
        type = types.int;
        default = 4567;
        description = lib.mdDoc "Port of Tachidesk";
      };

      socksProxyEnabled = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enables proxy for tachidesk";
      };

      socksProxyHost = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Host of Proxy.";
      };

      socksProxyPort = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Port of Proxy.";
      };

      basicAuthEnabled = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Socks Proxy.";
      };

      basicAuthUsername = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Username of web auth";
      };

      basicAuthPassword = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Password for web auth";
      };
    };
  };

  ##### implementation
  config =
    let
      serverConf = pkgs.writeText "server.conf" ''
        # Server ip and port bindings
        server.ip = "${cfg.ip}"
        server.port = ${toString cfg.port}

        # Socks5 proxy
        server.socksProxy = ${boolToString cfg.socksProxyEnabled}
        server.socksProxyHost = "${cfg.socksProxyHost}"
        server.socksProxyPort = "${cfg.socksProxyPort}"

        # misc
        server.debugLogsEnabled = ${boolToString cfg.debugLogsEnabled}
        server.systemTrayEnabled = false

        # webUI
        server.webUIEnabled = true
        server.initialOpenInBrowserEnabled = false
        server.webUIInterface = "browser"
        server.electronPath = ""
      '';
    in
    mkIf cfg.enable {
      systemd.tmpfiles.rules = [
        "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      ];

      systemd.services.tachidesk = {
        description = "tachidesk";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          unlink ${cfg.dataDir}/server.conf || true
          ln -s ${serverConf} ${cfg.dataDir}/server.conf
        '';

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${pkgs.tachidesk}/bin/tachidesk ${cfg.dataDir}";
          Restart = "on-failure";
        };
      };
      users.groups = mkIf (cfg.group == "tachidesk") {
        tachidesk = {
          members = [ "tachidesk" ];
        };
      };
      users.users = mkIf (cfg.user == "tachidesk") {
        tachidesk = {
          home = cfg.dataDir;
          group = "tachidesk";
          isNormalUser = true;
        };
      };
    };
}
