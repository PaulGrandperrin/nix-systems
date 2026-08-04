---
name: add-flake-input
description: add a new input to a flake and integrate its features (packages, overlays, cache etc)
---

- the user should have given you a URL-like argument for the flake to add. If not or if the URL looks wrong, abort now and report the issue to the user
- if the user gave you a URL that is not directly compatible with nix, convert it (e.g. `https://github.com/NixOS/nixpkgs.git` to `github:NixOS/nixpkgs`)
- we'll call the flake in the current directory the local flake, and the flake referenced by the given URL as the external flake
- find the external flake's project repository and read its `README.md` and `flake.nix` and any other file needed to understand how to integrate this external flake into the local flake
- read the result of `nix flake metadata` on this external flake 
- optionally read the result of `nix flake show` on this external flake, but be careful as the output can potentially be huge 
- integrate the external flake in the local `flake.nix` input section while respecting the alphabetical order of the inputs.
- in the local `flake.nix`, in the inputs section of the external flake, override its inputs (using `.follows =`) that are already inputs to our local flake in order to avoid duplicated evaluations. The only exception to this is when the external flake provides a nix cache and its provided packages are built from source (instead of from binaries like `firefox-bin`); in this case, don't override any inputs that would prevent hitting the external flake's provided cache; all the others inputs like `flake-parts` should still be overriden when possible. if you decide to override the `nixpkgs` input, use `nixos-stable`.
- read result of `nix flake metadata` on the local flake. if you see that the external flake was used as an input to other inputs of the local flake, override their own inputs using `.follows =`.
- if you determined that the external flake provides a binary cache and that it will be usefull, add it both to the `nixConfig` section of the local `flake.nix` and to `nix/nix.nix`
- if the external flake provides overlays, ask the user if they want you to integrate them in `overlays.nix` (put them in the list given to `composeManyExtensions` that builds the local `default` overlay)
- if the external flake provides packages, ask the user if they want you to integrate them in `overlays.nix` (create a new overlay in the form `NAME = (final: prev: inputs.NAME.packages.${prev.stdenv.hostPlatform.system});` and then add it to the `default` overlay)
- update the local `flake.lock` using `nix flake lock`
- read result of `nix flake metadata` on the local flake. if you see that some of the external flake's non-overriden inputs are also not overriden for other input flakes, notify the user and offer to add this common sub dependency as a new input to the local flake using the same `SKILL.md` as you are doing right now. 
- when done, ask the user if they want you to commit those changes

