{ mkDerivation, base, stdenv }:
mkDerivation {
  pname = "haskell-project-v1";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base ];
  license = stdenv.lib.licenses.isc;
}
