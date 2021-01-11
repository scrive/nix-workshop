let
  nixpkgs = import ../../nixpkgs.nix;

  inherit (nixpkgs) stdenv;

  prefixed-fib = prefix:
    let fib = n:
      assert builtins.isInt n;
      assert n >= 0;
      let
        n-str = builtins.toString n;
      in
        if n == 0 || n == 1
        then
          stdenv.mkDerivation {
            name = "${prefix}-fib-${n-str}";
            unpackPhase = "true";

            buildPhase = ''
              echo "Producing base case fib(${n-str})..."
              sleep 3
              echo "The answer to fib(${n-str}) is ${n-str}"
            '';

            installPhase = ''
              mkdir -p $out
              echo "${n-str}" > $out/answer
            '';
          }
        else
          let
            fib-1 = fib (n - 1);
            fib-2 = fib (n - 2);

            n-1-str = builtins.toString (n - 1);
            n-2-str = builtins.toString (n - 2);

            fib-1-answer = nixpkgs.lib.removeSuffix "\n"
              (builtins.readFile "${fib-1}/answer");
            fib-2-answer = nixpkgs.lib.removeSuffix "\n"
              (builtins.readFile "${fib-2}/answer");
          in
          stdenv.mkDerivation {
            name = "${prefix}-fib-${n-str}";
            unpackPhase = "true";

            buildPhase = ''
              echo "Calculating the answer of fib(${n-str}).."
              echo "Given fib(${n-1-str}) = ${fib-1-answer},"
              echo "and given fib(${n-2-str}) = ${fib-2-answer}.."

              sleep 3

              answer=$(( ${fib-1-answer} + ${fib-2-answer} ))
              echo "The answer to fib(${n-str}) is $answer"
            '';

            installPhase = ''
              mkdir -p $out
              echo "$answer" > $out/answer
            '';
          }
    ;
  in fib;
in
prefixed-fib