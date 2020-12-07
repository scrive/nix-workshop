let
  sources = import ../sources.nix {};
  nixpkgs = import sources.nixpkgs {};

  hsPkgs = nixpkgs.haskell.packages.ghc8102;

  src = builtins.path {
    name = "haskell-project-v1-src";
    path = ../../src;
    filter = path: type:
      let
        basePath = builtins.baseNameOf path;
      in
      basePath != "dist-newstyle"
    ;
  };
in
nixpkgs.stdenv.mkDerivation {
  inherit src;

  name = "haskell-project-v1";

  buildInputs = [
    hsPkgs.ghc
    hsPkgs.cabal-install
  ];

  builPhase = ''
    cabal build all
  '';

  installPhase = ''
    cabal install --installdir=$out --install-method=copy
  '';
}
