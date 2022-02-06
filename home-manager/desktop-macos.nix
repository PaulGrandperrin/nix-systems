{pkgs, isLinux, ...}: {

  targets.darwin.defaults = {
    NSGlobalDomain = {
      AppleLanguages = ["en" "fr" "pt"];
      AppleLocale = "en_US";
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = true;
      AppleTemperatureUnit = "Celsius";
    };
    com.apple.desktopservices = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    com.googlecode.iterm2.OpenTmuxWindowsIn = 2; # Tabs in the attaching window
  };
}
