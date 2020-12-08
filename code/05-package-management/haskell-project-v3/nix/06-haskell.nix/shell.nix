let
  project = import ./project.nix;
in
project.shellFor {
  withHoogle = false;
}
