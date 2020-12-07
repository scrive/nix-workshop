# Basic Haskell Project

We will take a quick look on the Nix structure for a trivial Haskell project,
in [haskell-project-v1](./haskell-project-v1).

`Main.hs`:

```haskell
{{#include ./haskell-project-v1/haskell/Main.hs}}
```

`haskell-project.cabal`:


```
{{#include ./haskell-project-v1/haskell/haskell-project.cabal}}
```

## Naive Attempt

Let's try to create a naive
[default.nix](./haskell-project-v1/nix/01-naive/default.nix)
that tries to build with cabal directly:

```nix
{{#include ./haskell-project-v1/nix/01-naive/default.nix}}
```

- We use `builtins.path` to include our Haskell source code, with
  a filter function to filter out the local `dist-newstyle`
  directory.

- We use GHC 8.10.2 provided from `nixpkgs.haskell.packages.ghc8102`.

- We add `ghc` and `cabal-install` into `buildInputs`.

Try building it:

```bash
$ nix-build 05-package-management/haskell-project-v1/nix/01-naive/
these derivations will be built:
  /nix/store/w1yscims73lrypddqcnri2vphqfnbim6-haskell-project.drv
building '/nix/store/w1yscims73lrypddqcnri2vphqfnbim6-haskell-project.drv'...
unpacking sources
unpacking source archive /nix/store/rc0pr7b71fm84az7d3gk4pdk62v8s0j0-haskell-project-src
source root is haskell-project-src
patching sources
configuring
no configure script, doing nothing
building
no Makefile, doing nothing
installing
Config file path source is default config file.
Config file /homeless-shelter/.cabal/config not found.
Writing default configuration to /homeless-shelter/.cabal/config
dieVerbatim: user error (cabal: Couldn't establish HTTP connection. Possible cause: HTTP proxy server
is down.
)
builder for '/nix/store/w1yscims73lrypddqcnri2vphqfnbim6-haskell-project.drv' failed with exit code 1
error: build of '/nix/store/w1yscims73lrypddqcnri2vphqfnbim6-haskell-project.drv' failed
```

Not good. Cabal tries to access the network to get the current Hackage
registry state and fails. There is good reason for this - there is no way
for Nix to know that cabal's access to network is reproducible.

We can still use it as a Nix shell to build our project manually, because
there is network access in Nix shell.

```bash
$ nix-shell 05-package-management/haskell-project-v1/nix/01-naive/

[nix-shell]$ cd 05-package-management/haskell-project-v1/haskell

[nix-shell]$ cabal build all
Resolving dependencies...
Build profile: -w ghc-8.10.2 -O1
In order, the following will be built (use -v for more details):
 - haskell-project-0.1.0.0 (exe:haskell-project-v1) (first run)
Configuring executable 'haskell-project-v1' for haskell-project-0.1.0.0..
Preprocessing executable 'haskell-project-v1' for haskell-project-0.1.0.0..
Building executable 'haskell-project-v1' for haskell-project-0.1.0.0..
[1 of 1] Compiling Main             ( Main.hs, /mnt/gamma/scrive/nix-workshop/code/05-package-management/haskell-project-v1/haskell/dist-newstyle/build/x86_64-linux/ghc-8.10.2/haskell-project-0.1.0.0/x/haskell-project-v1/build/haskell-project-v1/haskell-project-v1-tmp/Main.o )
Linking /mnt/gamma/scrive/nix-workshop/code/05-package-management/haskell-project-v1/haskell/dist-newstyle/build/x86_64-linux/ghc-8.10.2/haskell-project-0.1.0.0/x/haskell-project-v1/build/haskell-project-v1/haskell-project-v1 ...
```

## Default Attempt

We can instead try the default way of building Haskell packages in Nix.
There is a full tutorial by
[Gabriel](https://github.com/Gabriel439/haskell-nix). Here we will
just take a quick tour.

```
{{#include ./haskell-project-v1/nix/02-nixpkgs/default.nix}}
```

  - We use the `hsPkgs.callCabal2nix` function to create a nixpkgs-style package.

  - We then call `hsPkgs.callPackage` to "instantiate" our project with the
    dependencies taken from `hsPkgs`.

Now try to build it:

```bash
$ nix-build 05-package-management/haskell-project-v1/nix/02-nixpkgs/
building '/nix/store/9l4dx7q0fmm2v6mgl2rydjg21pp252y3-cabal2nix-haskell-project.drv'...
installing
these derivations will be built:
  /nix/store/pfai9bpr6p1kf7wy8b0sj0zl68173ci4-haskell-project-0.1.0.0.drv
building '/nix/store/pfai9bpr6p1kf7wy8b0sj0zl68173ci4-haskell-project-0.1.0.0.drv'...
...
Preprocessing executable 'haskell-project-v1' for haskell-project-0.1.0.0..
Building executable 'haskell-project-v1' for haskell-project-0.1.0.0..
[1 of 1] Compiling Main             ( Main.hs, dist/build/haskell-project-v1/haskell-project-v1-tmp/Main.o )
Linking dist/build/haskell-project-v1/haskell-project-v1 ...
...
/nix/store/d2r4ybp3c583ndf15vwss74wp0aiqimd-haskell-project-0.1.0.0
```

That works.

## How Haskell in Nixpkgs Work

The Haskell packages in nixpkgs are _mono-versioned_. This means for each
Haskell package such as `base`, `aeson`, etc, there is exactly one version
provided by a Haskell packages set. There are however multiple versions
of Haskell packages in nixpkgs, determined by the GHC versions.

For instance, `nixpkgs.haskell.packages.ghc8102` contains mono-versioned
Haskell packages that works in GHC 8.10.2, while
`nixpkgs.haskell.packages.ghc884` contains mono-versioned Haskell packages
that works in GHC 8.8.4.

### Stackage Upstream

The mono versions of Haskell packages used to follow Stackage LTS,
which is also mono-versioned. However recently the team have
[switched to Stackage nightly](https://discourse.nixos.org/t/new-ghc-default-version-8-10-2-package-versions-now-from-stackage-nightly/10117)
to reduce the maintenance burden.

### Callpackage Pattern

As we discussed in previous chapter, Nix itself do not provide any
mechanism for dependency resolution. So nixpkgs come out with the
[Callpackge design pattern](https://nixos.org/guides/nix-pills/callpackage-design-pattern.html)
to manage dependencies in nixpkgs.

In short, we define new packages in function form which accept
dependencies as function inputs. Let's call these functions
_partial packages_, since they are packages with dependencies
yet to be supplied.

For example, the `pickaxe` package we defined previously would
have a partial package definition that looks something like:

```nix
let pickaxe = { stick, planks }: ...
```

The partial package is then instantiated into a Nix derivation
by calling `nixpkgs.callPackage` with the package set containing
all its dependencies as partial packages.

```nix
let minePackages = {
  wood = { ... }: ...;
  stick = { wood, ... }: ...;
  planks = { wood, ... }: ...;
  ...
}
in
nixpkgs.callPackage minePackages pickaxe {}
```

The `nixpkgs.callPackage` automagically inspects the function arguments
as dependencies in the package set, and construct a dependency graph
that connects all packages with their dependencies. If this succeed
we get a Nix derivation with the dependency derivations provided
to our partial package.
