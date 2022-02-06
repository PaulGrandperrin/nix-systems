{pkgs, isLinux, ...}: {

  targets.darwin.defaults = {
    NSGlobalDomain = {
      AppleLanguages = ["en_US" "fr_FR" "pt_BR"];
      AppleLocale = "en_GB@currency=EUR"; # dd/mm/yyyy - 3.14 - 10,000 - week starts on Monday 
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
