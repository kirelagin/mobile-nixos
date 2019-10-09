{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.redirect-log;

  # Used in the script
  logger_run = "/run/initrd";
  pipe    = "${logger_run}/init.log.pipe";
  pidfile = "${logger_run}/init.log.pid";
  fd_base = 3;
in
{
  options.mobile.boot.stage-1.redirect-log = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Redirects init log to /init.log.

        Do note that this only adds `/init.log` to `targets`.
      '';
    };

    targets = mkOption {
      type = types.listOf types.str;
      description = ''
        Where the init process logs are redirected to.

        This defaults to /dev/console to help debug targets without
        proper serial or graphical consoles.

        Add known serial consoles to device descriptions.
      '';
    };

    trace = mkEnableOption "logging commands with set -x";
  };

  config.mobile.boot.stage-1 = mkMerge [
    {
      redirect-log.targets = [
        # Always redirects (tautologically) to /dev/console at least.
        "/dev/console"
      ]
      ++ optional cfg.enable "/init.log"
      ;

      # FIXME : this may not cleanup nicely.
      # This implementation is naive and simple.
      init = lib.mkIf cfg.enable (lib.mkOrder AFTER_DEVICE_INIT ''
        _logger() {
          # Setup all redirections
          ${builtins.concatStringsSep "\n" (
            imap0 (i: t: ''
              exec ${toString(i+fd_base)}>${t} 2>&1
            '') cfg.targets
          )}

          # Continuously read from pipe
          while read -r line; do
          ${builtins.concatStringsSep "\n" (
            imap0 (i: t: ''
              printf '%s\n' "$line" >&${toString(i+fd_base)}
            '') cfg.targets
          )}
          done
          
          # Cleanup behind ourselves
          rm -f ${pipe} ${pidfile}
        }

        mkdir -p ${logger_run}
        mkfifo ${pipe}
        _logger < ${pipe} >/dev/console 2>&1 &
        printf %s $! > ${pidfile}
        exec >${pipe} 2>&1
      '');
    }
    {
      # FIXME : this may not cleanup nicely.
      # This implementation is naive and simple.
      init = lib.mkIf cfg.enable (lib.mkOrder AFTER_SWITCH_ROOT_INIT ''
        _stop_logger() {
          local i=0 pid
          # re-attach to /dev/console
          exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
          # Kill the process
          kill $(cat ${pidfile})
        }
      '');
    }

    {
      init = lib.mkIf cfg.trace (mkOrder (DEVICE_INIT + 3) ''
        PS4="$"
        set -x
      '');
    }
  ];
}
