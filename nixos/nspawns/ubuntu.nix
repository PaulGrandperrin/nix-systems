{ config, pkgs, ... }:
{
  networking.firewall.trustedInterfaces =  [ "ve-ubuntu" ];
  #systemd.nspawn."ubuntu" = {
  #  enable = true;
  #  # wantedBy = [ "multi-user.target" ]; # doesn't work https://github.com/NixOS/nixpkgs/issues/189499
  #};
  environment.etc."systemd/nspawn/ubuntu.nspawn".text= ''
    [Exec]
    Hostname=ubuntu
    #ResolvConf

    [Network]
    Port=222:22
    Port=2379
    Port=20160
    Port=4000
    Port=9090
    Port=3000
  '';
  # systemd.services."systemd-nspawn@ubuntu".restartTriggers = [ config.environment.etc."systemd/nspawn/ubuntu.nspawn".source ]; # FIXME breaks the conf because it doesn't understand templates
  systemd.targets.machines.wants = [ "systemd-nspawn@ubuntu.service" ];
  systemd.targets.multi-user.wants = [ "machines.target" ];
}

