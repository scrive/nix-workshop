let
  sources = import ../sources.nix {};
  nixpkgs = import sources.nixpkgs {};

  hsLib = nixpkgs.haskell.lib;
  hsPkgs-original = nixpkgs.haskell.packages.ghc8102;

  hsPkgs = hsPkgs-original.override {
    overrides = hsPkgs-old: hsPkgs-new: {
      QuickCheck = hsPkgs-new.callHackageDirect {
        pkg = "QuickCheck";
        ver = "2.14.2";
        sha256 = "0rx4lz5rj0s1v451cq6qdxhilq4rv9b9lnq6frm18h64civ2pwbq";
      } {};
    };
  };

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
