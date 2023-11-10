{ config, pkgs, lib, inputs, ... }: {

  # the specializations multiplies the evaluations
  specialisation = lib.mkForce {};

  # fish wants to regenerate all cache to have autocompletion of manual pages
  documentation.man.generateCaches = lib.mkForce false;

  # disable fish generation of completions
  environment.etc."fish/generated_completions".enable = lib.mkForce false;

  home-manager.users = {
    # fish wants to regenerate all cache to have autocompletion of manual pages
    paulg.programs.man.generateCaches = lib.mkForce false;
    root.programs.man.generateCaches = lib.mkForce false;

    # disable fish generation of completions
    paulg.xdg.dataFile."fish/home-manager_generated_completions".enable = lib.mkForce false;
    root.xdg.dataFile."fish/home-manager_generated_completions".enable = lib.mkForce false;
  };
}

