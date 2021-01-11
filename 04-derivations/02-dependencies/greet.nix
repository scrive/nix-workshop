let
  nixpkgs = import ../../nixpkgs.nix;

  greet = nixpkgs.stdenv.mkDerivation {
    name = "greet";
    unpackPhase = "true";

    buildPhase = ''
      echo "building greet..."
      sleep 3
    '';

    installPhase = ''
      mkdir -p $out/bin

      cat <<'EOF' > $out/bin/greet
      #!/usr/bin/env bash
      echo "Hello, $1!"
      EOF

      chmod +x $out/bin/greet
    '';
  };
in
greet