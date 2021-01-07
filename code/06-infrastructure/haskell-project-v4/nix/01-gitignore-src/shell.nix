{ useMaterialization ? true }:
let
  project = import ./project.nix {
    inherit useMaterialization;
  };
in
project.shellFor {
  withHoogle = false;
}
