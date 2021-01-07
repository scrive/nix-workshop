{
  pkgs = hackage:
    {
      packages = {
        "ghc-prim".revision = (((hackage."ghc-prim")."0.6.1").revisions).default;
        "mtl".revision = (((hackage."mtl")."2.2.2").revisions).default;
        "rts".revision = (((hackage."rts")."1.0").revisions).default;
        "QuickCheck".revision = (((hackage."QuickCheck")."2.14.2").revisions).default;
        "QuickCheck".flags.templatehaskell = true;
        "QuickCheck".flags.old-random = false;
        "deepseq".revision = (((hackage."deepseq")."1.4.4.0").revisions).default;
        "random".revision = (((hackage."random")."1.2.0").revisions).default;
        "splitmix".revision = (((hackage."splitmix")."0.1.0.3").revisions).default;
        "splitmix".flags.optimised-mixer = false;
        "template-haskell".revision = (((hackage."template-haskell")."2.16.0.0").revisions).default;
        "containers".revision = (((hackage."containers")."0.6.2.1").revisions).default;
        "bytestring".revision = (((hackage."bytestring")."0.10.10.0").revisions).default;
        "base".revision = (((hackage."base")."4.14.1.0").revisions).default;
        "transformers".revision = (((hackage."transformers")."0.5.6.2").revisions).default;
        "pretty".revision = (((hackage."pretty")."1.1.3.6").revisions).default;
        "ghc-boot-th".revision = (((hackage."ghc-boot-th")."8.10.2").revisions).default;
        "array".revision = (((hackage."array")."0.5.4.0").revisions).default;
        "integer-gmp".revision = (((hackage."integer-gmp")."1.0.3.0").revisions).default;
        };
      compiler = {
        version = "8.10.2";
        nix-name = "ghc8102";
        packages = {
          "ghc-prim" = "0.6.1";
          "mtl" = "2.2.2";
          "rts" = "1.0";
          "deepseq" = "1.4.4.0";
          "template-haskell" = "2.16.0.0";
          "containers" = "0.6.2.1";
          "bytestring" = "0.10.10.0";
          "base" = "4.14.1.0";
          "transformers" = "0.5.6.2";
          "pretty" = "1.1.3.6";
          "ghc-boot-th" = "8.10.2";
          "array" = "0.5.4.0";
          "integer-gmp" = "1.0.3.0";
          };
        };
      };
  extras = hackage:
    { packages = { haskell-project = ./.plan.nix/haskell-project.nix; }; };
  modules = [
    ({ lib, ... }:
      { packages = { "haskell-project" = { flags = {}; }; }; })
    ];
  }