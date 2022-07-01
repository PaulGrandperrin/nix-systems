{ config, pkgs, ... }:
{
   environment.systemPackages = with pkgs; [
     powertop
     cpufrequtils
     i7z
   ];

}


