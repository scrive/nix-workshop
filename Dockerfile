FROM nixos/nix

COPY ./nix.conf /root/.config/nix/nix.conf

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
RUN nix-channel --update
