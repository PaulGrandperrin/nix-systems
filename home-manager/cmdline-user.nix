{pkgs, ...}: {
  # install ssh authorized keys, sshd complains if that's a symlink to the /nix/store
  home.activation = let
    ssh-authorized-keys = pkgs.writeText "ssh-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+tckVW3zh58Cr246EuceDY/HdgoJrmSnYTNEv0Y3HW
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVW/7zXgQwIAk46daSBfP5ti7zpADrs1p//f5IyRHJH
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdJ9evK0Ay1KFOBG+EZC7xPOb8udcltjg8rTFpHimz5
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjsf+KqGyIAhHxL54740gfH+qQxQl7K1liLsvaGvlHK
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIChG+jbZaRNcbsQTyu6Dd9SaiaCSyR586FY5N1mHSRvE
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3KlABFus1z3jTDvylO6e6gSnn7nIqJKZOZJ9di5OW4
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOIxgOXuz4/8JB++umc4fEvFwIlM3eeVadTsvCZCQN2
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBBKbOypMYzisA9fwYtZVWWtcvsOqA294EEBIYN/9YCr
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMK/GnaGGlU7pl4po31XP6K5VpodTu67J+D1/3d74R57
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5s0Fe3Y2kX5bxhipkD/OGePPRew40fElqzgacdavuY
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSJQGYQs+KJX+V/X3KxhyQgahE0g+ITF2jr1wUY1s/3
  '';
  in {
    copySshAuthorizedKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
     $DRY_RUN_CMD install $VERBOSE_ARG -m700 -d ${config.home.homeDirectory}/.ssh
     $DRY_RUN_CMD install $VERBOSE_ARG -m600 ${ssh-authorized-keys} ${config.home.homeDirectory}/.ssh/authorized_keys
   '';
  };

  home = {
    packages = with pkgs; [
    ];
  };
}
