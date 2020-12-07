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
  };
in
project
