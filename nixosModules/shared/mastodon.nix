# We use the Grafana stack, but Uptrace, SigNoz and Jaeger are also interested but not well integrated in NixOS

{ config, pkgs, inputs, ... }:
{

  #nixpkgs.overlays = [(final: prev: { 
  #  mastodon = prev.callPackage (inputs.master.outPath + "/pkgs/servers/mastodon") {};
  #})]; 

  services.mastodon = {
    enable = true;
    streamingProcesses = 1;
    localDomain = "social.paulg.fr";
    configureNginx = true;
    smtp = {
      createLocally = false;
      fromAddress = "admin@social.paulg.fr";
    };
    extraConfig = {
      SINGLE_USER_MODE = "true";
    };
  };
}


