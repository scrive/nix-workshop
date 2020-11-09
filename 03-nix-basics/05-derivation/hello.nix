let
  nixpkgs = import <nixpkgs> {};
in
nixpkgs.stdenv.mkDerivation {
  name = "hello.txt";
  unpackPhase = "true";
  installPhase = ''
    echo -n "Hello World!" > $out
  '';
}