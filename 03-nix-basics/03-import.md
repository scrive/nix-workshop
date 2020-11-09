# Import Modules

## Import Nix Modules

We have the following files in
[03-nix-basics/03-import](03-nix-basics/03-import):

  - [foo.nix](./03-import/foo.nix)
  - [bar.nix](./03-import/bar.nix)
  - [default.nix](./03-import/default.nix)

```
nix-repl> import ./03-nix-basics/03-import/foo.nix
"foo val"

nix-repl> import ./03-nix-basics/03-import/bar.nix
[ "bar val 1" "bar val 2" ]

nix-repl> import ./03-nix-basics/03-import
{ bar = [ ... ]; foo = "foo val"; }
```

## Import Global Modules

```
nix-repl> nixpkgs = import <nixpkgs> {}

nix-repl> nixpkgs.lib.stringLength "hello"
5
```
