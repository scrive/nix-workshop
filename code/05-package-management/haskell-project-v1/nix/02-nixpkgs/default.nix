let
  sources = import ../sources.nix {};
  nixpkgs = import sources.nixpkgs {};

  hsPkgs = nixpkgs.haskell.packages.ghc8102;

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

  project = hsPkgs.callCabal2nix "haskell-project" src;
in
hsPkgs.callPackage project {}
