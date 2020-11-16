let
  nixpkgs = import ../../nixpkgs.nix;

  inherit (nixpkgs) coreutils;

  greet = import ./greet.nix;
in
nixpkgs.stdenv.mkDerivation {
  name = "upper-greet";

  unpackPhase = "true";

  buildPhase = ''
    echo "building upper-greet..."
    sleep 3
  '';

  installPhase = ''
    mkdir -p $out/bin

    cat <<'EOF' > $out/bin/upper-greet
    #!/usr/bin/env bash
    ${greet}/bin/greet "$@" | ${coreutils}/bin/tr [a-z] [A-Z]
    EOF

    chmod +x $out/bin/upper-greet
  '';

}