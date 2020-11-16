let
  foo = import ./foo.nix;
  bar = import ./bar.nix;
in
{ inherit foo bar; }