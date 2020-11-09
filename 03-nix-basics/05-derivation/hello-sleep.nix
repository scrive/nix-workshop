let
  nixpkgs = import <nixpkgs> {};
in
nixpkgs.stdenv.mkDerivation {
  name = "hello.txt";
  unpackPhase = "true";
  buildPhase = ''
    echo "Building hello world..."
    sleep 10
    echo "Finished building hello world!"
  '';
  installPhase = ''
    echo -n "Hello World!" > $out
  '';
}