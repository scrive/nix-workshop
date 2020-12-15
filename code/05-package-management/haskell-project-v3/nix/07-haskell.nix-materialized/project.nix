{ useMaterialization ? true }:
let
  sources = import ../sources.nix {};

  haskell-nix = import sources."haskell.nix" {};

  nixpkgs = haskell-nix.pkgs;

  src = builtins.path {
    name = "haskell-project-src";
    path = ../../haskell;
    filter = path: type:
      let
        basePath = builtins.baseNameOf path;
      in
      basePath != "dist-newstyle"
    ;
  };

  project = nixpkgs.haskell-nix.cabalProject {
    inherit src;

    compiler-nix-name = "ghc8102";

    inherit useMaterialization;

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
