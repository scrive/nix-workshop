{ useMaterialization ? true }:
let
  sources = import ../sources.nix {};

  haskell-nix = import sources."haskell.nix" {};

  nixpkgs = haskell-nix.pkgs;

  gitignore = (import sources."gitignore.nix" {
    inherit (nixpkgs) lib;
  }).gitignoreSource;

  src = nixpkgs.lib.cleanSourceWith {
    name = "haskell-project-src";
    src = gitignore ../../haskell;
  };

  project = nixpkgs.haskell-nix.cabalProject {
    inherit src;

    compiler-nix-name = "ghc8102";

    index-state = "2020-12-04T00:00:00Z";

    materialized = if useMaterialization
      then ./plan else null;

    plan-sha256 = if useMaterialization
      then nixpkgs.lib.removeSuffix "\n"
        (builtins.readFile ./plan-hash.txt)
      else null;

    exactDeps = true;
  };
in
project
