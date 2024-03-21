{
  allowUnfree = true;
  android_sdk.accept_license = true;
  permittedInsecurePackages = [
    "nix-2.15.3" "nix-2.16.2" # https://github.com/nix-community/nixd/issues/357
  ];
}
