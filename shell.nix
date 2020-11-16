let
  nixpkgs = import ./code/nixpkgs.nix;
in
nixpkgs.mkShell {
  buildInputs = [
    nixpkgs.mdbook
  ];
}