let
  project = import ./project.nix {
    useMaterialization = true;
  };
in
project.haskell-project.components.exes.hello
