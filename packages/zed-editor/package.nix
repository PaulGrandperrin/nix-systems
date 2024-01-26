{ lib
, rustPlatform
, fetchFromGitHub
, curl
, pkg-config
, protobuf
, xcbuild
, fontconfig
, freetype
, libgit2
, openssl
, sqlite
, zlib
, zstd
, stdenv
, darwin
, alsa-lib
}:

rustPlatform.buildRustPackage rec {
  pname = "zed";
  version = "0.119.19";

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "zed";
    rev = "refs/tags/v${version}";
    hash = "sha256-bD/VyX3t6SnA4ESDMy8raBrNtsSacw7LlOYDH9aH8oA=";
    fetchSubmodules = true;
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "alacritty_config-0.1.2-dev" = "sha256-6pul2gpYnT9FCYWt7gwA60QESpHJ2Re2FTeLzcPGnYY=";
      "async-pipe-0.1.3" = "sha256-g120X88HGT8P6GNCrzpS5SutALx5H+45Sf4iSSxzctE=";
      "bromberg_sl2-0.6.0" = "sha256-+bwdnk3EgYEAxQSP4KpEPicCfO+r2er1DRZjvfF4jSM=";
      "cocoa-0.24.0" = "sha256-p8dARCWd2SxRcUOihnexQbBno5xw+cYzPhlhwiJ6wMc=";
      "font-kit-0.11.0" = "sha256-Lo2EeCK6GBPQo4FxAbBla3NP4TLccxWZ5kljks7JB84=";
      "lsp-types-0.94.1" = "sha256-kplgPsafrgZFMI1D9pQCwmg+FKMn5HNWLbcgdXHUFVU=";
      "nvim-rs-0.6.0-pre" = "sha256-bdWWuCsBv01mnPA5e5zRpq48BgOqaqIcAu+b7y1NnM8=";
      "procinfo-0.1.0" = "sha256-betDue3bA3LcXv+TVQRd4afYsXk+rfneuXSdZ3s30wM=";
      "taffy-0.3.11" = "sha256-0hXOEj6IjSW8e1t+rvxBFX6V9XRum3QO2Des1XlHJEw=";
      "tree-sitter-0.20.10" = "sha256-uhQY3cxpARrrg0WCT0VCfzjB8Zx74a0LWsvNafurSMQ=";
      "tree-sitter-bash-0.20.4" = "sha256-VP7rJfE/k8KV1XN1w5f0YKjCnDMYU1go/up0zj1mabM=";
      "tree-sitter-cpp-0.20.0" = "sha256-2QYEFkpwcRmh2kf4qEAL2a5lGSa316CetOhF73e7rEM=";
      "tree-sitter-css-0.19.0" = "sha256-5Qti/bFac2A1PJxqZEOuSLK3GGKYwPDKAp3OOassBxU=";
      "tree-sitter-elixir-0.1.0" = "sha256-hBHqQ3eBjknRPJjP+lQJU6NPFhUMtiv4FbKsTw28Bog=";
      "tree-sitter-elm-5.6.4" = "sha256-0LpuyebOB5ew9fULBcaw8aUbF7HM5sXQpv+Jroz4tXg=";
      "tree-sitter-glsl-0.1.4" = "sha256-TRuiT3ndCeDCsCFokAN8cosNKccB0NjWVRiBJuBJXZw=";
      "tree-sitter-go-0.19.1" = "sha256-5+L5QqVjZyeh+sKfxKZWrjIBFE5xM9KZlHcLiHzJCIA=";
      "tree-sitter-heex-0.0.1" = "sha256-6LREyZhdTDt3YHVRPDyqCaDXqcsPlHOoMFDb2B3+3xM=";
      "tree-sitter-json-0.20.0" = "sha256-fZNftzNavJQPQE4S1VLhRyGQRoJgbWA5xTPa8ZI5UX4=";
      "tree-sitter-markdown-0.0.1" = "sha256-F8VVd7yYa4nCrj/HEC13BTC7lkV3XSb2Z3BNi/VfSbs=";
      "tree-sitter-nix-0.0.1" = "sha256-+o+f1TlhcrcCB3TNw1RyCjVZ+37e11nL+GWBPo0Mxxg=";
      "tree-sitter-nu-0.0.1" = "sha256-4UpNY2yHJ7+gVoIXHEXpPvFztFU6EZmWbSyZFIcCvl4=";
      "tree-sitter-php-0.19.1" = "sha256-oHUfcuqtFFl+70/uJjE74J1JVV93G9++UaEIntOH5tM=";
      "tree-sitter-racket-0.0.1" = "sha256-ie64no94TtAWsSYaBXmic4oyRAA01fMl97+JWcFU1E8=";
      "tree-sitter-scheme-0.2.0" = "sha256-K3+zmykjq2DpCnk17Ko9LOyGQTBZb1/dgVXIVynCYd4=";
      "tree-sitter-svelte-0.10.2" = "sha256-TJVAQULTBTZxVwvpBpFmBPJM1jh2aN+KG8YfuT+/ylg=";
      "tree-sitter-toml-0.5.1" = "sha256-5nLNBxFeOGE+gzbwpcrTVnuL1jLUA0ZLBVw2QrOLsDQ=";
      "tree-sitter-typescript-0.20.2" = "sha256-cpOAtfvlffS57BrXaoa2xa9NUYw0AsHxVI8PrcpgZCQ=";
      "tree-sitter-uiua-0.3.3" = "sha256-kO+KfBd2SYwaeVq4ZmxuZx2Wn/qfqe9nDzcRmOroHqM=";
      "tree-sitter-vue-0.0.1" = "sha256-8v2e03A/Uj6zCJTH4j6TPwDQcNFeze1jepMADT6UVis=";
      "tree-sitter-yaml-0.0.1" = "sha256-S59jLlipBI2kwFuZDMmpv0TOZpGyXpbAizN3yC6wJ5I=";
    };
  };

  nativeBuildInputs = [
    curl
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ] ++ lib.optionals stdenv.isDarwin [
    xcbuild.xcrun
  ];

  buildInputs = [
    curl
    fontconfig
    freetype
    libgit2
    openssl
    sqlite
    zlib
    zstd
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    AppKit
    CoreAudio
    CoreFoundation
    CoreGraphics
    CoreServices
    CoreText
    Foundation
    IOKit
    Metal
    Security
    SystemConfiguration
  ]) ++ lib.optionals stdenv.isLinux [
    alsa-lib
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = with lib; {
    description = "A high-performance, multiplayer code editor from the creators of Atom and Tree-sitter";
    homepage = "https://zed.dev";
    changelog = "https://github.com/zed-industries/zed/releases/tag/v${version}";
    license = with licenses; [ asl20 agpl3Only gpl3Only ];
    maintainers = with maintainers; [ GaetanLepage ];
    mainProgram = "zed";
    platflorms = platforms.darwin;
  };
}
