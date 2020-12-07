let
  project = import ./project.nix;
in
project.haskell-project.components.exes.haskell-project
