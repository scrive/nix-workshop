let
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/c1e5f8723ceb684c8d501d4d4ae738fef704747e.tar.gz";
    sha256 = "02k3l9wnwpmq68xmmfy4wb2panqa1rs04p1mzh2kiwn0449hl86j";
  };

  nixpkgs = import nixpkgs-src {};
in
nixpkgs
