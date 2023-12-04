{ pkgs
, lib
, kernel ? pkgs.linuxPackages_latest.kernel
}:

pkgs.stdenv.mkDerivation {
  pname = "kernel-module-ath-patched";
  inherit (kernel) src version postPatch nativeBuildInputs;

  kernel_dev = kernel.dev;
  kernelVersion = kernel.modDirVersion;

  patches = [
    (pkgs.fetchpatch { # Force Atheros drivers to respect the user's regdomain settings with ATH_USER_REGD option
      url = "https://git.openwrt.org/?p=openwrt/openwrt.git;a=blob_plain;f=package/kernel/mac80211/patches/ath/402-ath_regd_optional.patch;h=601ebdc7583c2331735e45c75e77a35f31739f76;hb=HEAD";
      hash = "sha256-t5DPUjcohgPuPpoaNpMbgRNjFoxfa8YXU5dkSKGwMJc=";
      postFetch = ''
        substituteInPlace $out --replace "CPTCFG_" "CONFIG_" # OpenWRT patches are meant to linux-backport's drivers
      '';
      excludes = ["local-symbols"]; # file specific to OpenWRT packaging
    })
  ];

  modulePath = "drivers/net/wireless/ath";

  buildPhase = ''
    BUILT_KERNEL=$kernel_dev/lib/modules/$kernelVersion/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config        .
    chmod +w .config

    echo "CONFIG_ATH_USER_REGD=y" >> .config
    echo "CONFIG_ATH_REG_DYNAMIC_USER_REG_HINTS=y" >> .config
    echo "CONFIG_ATH_REG_DYNAMIC_USER_CERT_TESTING=y" >> .config

    cp $kernel_dev/vmlinux          .

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath modules
  '';

  installPhase = ''
    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      modules_install
  '';

  meta = {
    description = "Atheros kernel module with some OpenWRT patches";
    license = lib.licenses.gpl3;
  };
}

