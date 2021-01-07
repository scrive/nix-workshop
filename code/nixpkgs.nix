let
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fcc81bc974fabd86991b8962bd30a47eb43e7d34.tar.gz";
    sha256 = "1ysjmn79pl7srlzgfr35nsxq43rm1va8dqp60h09nlmw2fsq9zrc";
  };

  nixpkgs = import nixpkgs-src {};
in
nixpkgs
