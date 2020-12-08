# Transitive Haskell Version Conflicts

Let's look at another example of nixpkgs-based Haskell project, where version
conflicts are propagated to transitive dependencies.

We have another Haskell project,
[haskell-project-v3](./haskell-project-v3/haskell/haskell-project.cabal)
with a dependency on the latest `QuickCheck-2.14.2`:

```
{{#include ./haskell-project-v3/haskell/haskell-project.cabal}}
```

Now try building the project with the default `callCabal2nix`:

```nix
{{#include ./haskell-project-v3/nix/01-nixpkgs-conflict/default.nix}}
```

We should see that the building failed, because the
[version of nixpkgs](https://raw.githubusercontent.com/NixOS/nixpkgs/c1e5f8723ceb684c8d501d4d4ae738fef704747e/pkgs/development/haskell-modules/hackage-packages.nix)
we are using only has `QuickCheck-2.13.2` in it.

```bash
$ nix-build 05-package-management/haskell-project-v3/nix/01-nixpkgs-conflict
building '/nix/store/12qzjbk3514sj9v4j99brbxr4b83bzy5-cabal2nix-haskell-project.drv'...
installing
these derivations will be built:
  /nix/store/d5jyli1v9y12il9wyzs5x6gyx6q68gig-haskell-project-0.1.0.0.drv
...
Setup: Encountered missing or private dependencies:
QuickCheck ==2.14.2

builder for '/nix/store/d5jyli1v9y12il9wyzs5x6gyx6q68gig-haskell-project-0.1.0.0.drv' failed with exit code 1
error: build of '/nix/store/d5jyli1v9y12il9wyzs5x6gyx6q68gig-haskell-project-0.1.0.0.drv' failed
```

## Using Latest Hackage Package

Now we try using the override pattern in the previous chapter to override the
version of `QuickCheck`:

```nix
{{#include ./haskell-project-v3/nix/02-nixpkgs-not-found/default.nix}}
```

This time the build actually failed with another error:

```bash
$ nix-build 05-package-management/haskell-project-v3/nix/01-nixpkgs-conflict
building '/nix/store/12qzjbk3514sj9v4j99brbxr4b83bzy5-cabal2nix-haskell-project.drv'...
installing
these derivations will be built:
  /nix/store/d5jyli1v9y12il9wyzs5x6gyx6q68gig-haskell-project-0.1.0.0.drv
...
Configuring haskell-project-0.1.0.0...
CallStack (from HasCallStack):
  $, called at libraries/Cabal/Cabal/Distribution/Simple/Configure.hs:1024:20 in Cabal-3.2.0.0:Distribution.Simple.Configure
  configureFinalizedPackage, called at libraries/Cabal/Cabal/Distribution/Simple/Configure.hs:477:12 in Cabal-3.2.0.0:Distribution.Simple.Configure
  configure, called at libraries/Cabal/Cabal/Distribution/Simple.hs:625:20 in Cabal-3.2.0.0:Distribution.Simple
  confHook, called at libraries/Cabal/Cabal/Distribution/Simple/UserHooks.hs:65:5 in Cabal-3.2.0.0:Distribution.Simple.UserHooks
  configureAction, called at libraries/Cabal/Cabal/Distribution/Simple.hs:180:19 in Cabal-3.2.0.0:Distribution.Simple
  defaultMainHelper, called at libraries/Cabal/Cabal/Distribution/Simple.hs:116:27 in Cabal-3.2.0.0:Distribution.Simple
  defaultMain, called at Setup.hs:2:8 in main:Main
Setup: Encountered missing or private dependencies:
QuickCheck ==2.14.2

builder for '/nix/store/d5jyli1v9y12il9wyzs5x6gyx6q68gig-haskell-project-0.1.0.0.drv' failed with exit code 1
error: build of '/nix/store/d5jyli1v9y12il9wyzs5x6gyx6q68gig-haskell-project-0.1.0.0.drv' failed
soares@soares-workstation:~/scrive/nix-workshop/code$ nix-build 05-package-management/haskell-project-v3/nix/02-nixpkgs-not-found
building '/nix/store/ybvimf0jbsbx997588kbipkpbq97iv3d-all-cabal-hashes-component-QuickCheck-2.14.2.drv'...
tar: */QuickCheck/2.14.2/QuickCheck.json: Not found in archive
tar: */QuickCheck/2.14.2/QuickCheck.cabal: Not found in archive
tar: Exiting with failure status due to previous errors
builder for '/nix/store/ybvimf0jbsbx997588kbipkpbq97iv3d-all-cabal-hashes-component-QuickCheck-2.14.2.drv' failed with exit code 2
cannot build derivation '/nix/store/73pfc98xfaj7l818nznr8r4gbls5xmls-cabal2nix-QuickCheck-2.14.2.drv': 1 dependencies couldn't be built
error: build of '/nix/store/73pfc98xfaj7l818nznr8r4gbls5xmls-cabal2nix-QuickCheck-2.14.2.drv' failed
(use '--show-trace' to show detailed location information)
```

What happened this time? If we check the
[commit log](https://github.com/NixOS/nixpkgs/commit/c1e5f8723ceb684c8d501d4d4ae738fef704747e)
of our nixpkgs version, we will find out that the nixpkgs we have is commited
on 9 November 2020, but on
[Hackage](https://hackage.haskell.org/package/QuickCheck)
`QuickCheck-2.14.2` is only released on 14 November 2020.

## Hackage Index in Nixpkgs

Inside the override call, when we call `callHackage` to get a Haskell package
from Hackage, we are really just downloading the Haskell source from Hackage
based on the snapshot cached in nixpkgs.

Recall from the principal of reproducibility, with just a version number, there
is no way Nix can tell if we will always get the exact same source code from
Hackage every time a source code is requested. In theory the
`QuickCheck-2.14.2` we fetched today may be totally different from the
`QuickCheck-2.14.2` we fetch tomorrow, or when it is fetched by someone else.

Nixpkgs solves this by computing the content hash of every Hackage package
at the time of snapshot. So we can know for sure that the same Hackage pacakge
we fetch with the same nixpkgs will always give back the same result.
Nixpkgs also does implicit patching on some Hackage package, if their
default configuration breaks.

One option for us may be to simply update to the latest version of nixpkgs
so that it contains `QuickCheck-2.14.2`. However nixpkgs do not immediately
update the Hackage snapshot every time a new Haskell pacakge is published.
Rather there is usually 1~2 weeks lag as the Haskell packages are updated
in bulk. So we can't rely on that if we want to use a Haskell package
just published an hour ago.

Furthermore, updating nixpkgs also means all other packages in nixpkgs
also being updated. That may result in breaking some of our own Nix
packages.

In theory we could use a stable Nix channel like `nixos-20.09`
instead of `nixpkgs-unstable` so that it is safer to update nixpkgs.
But stability always needs tradeoff with rapid releases,
so it will take even longer before the Hackage snapshot update
is propagated there.

## CallHackageDirect

If we want to get the latest Hackage package beyond what is available
in nixpkgs, we can instead use `callHackageDirect` to directly
download the package from Hackge, skipping nixpkgs entirely:

```nix
{{#include ./haskell-project-v3/nix/03-nixpkgs-transitive-deps/default.nix}}
```

`callHackageDirect` works similarly to other ways of fetching source code,
such as `builtins.fetchTarball` and `builtins.fetchgit`. In fact,
we can also override a Haskell dependency with a GitHub commit or
source tarball. Here we just need to provide an additional information,
which is the SHA256 checksum of the package.

There is currently straightforward way to compute the hash, but we can
first supply a dummy hash such as
`0000000000000000000000000000000000000000000000000000`,
then copy the correct hash from the hash mismatch error when
the derivation is built.

## Transitive Conflicts

If we try to build it this time however, we are greeted with another error:

```bash
$ nix-build 05-package-management/haskell-project-v3/nix/03-nixpkgs-transitive-deps
these derivations will be built:
  /nix/store/6my008rqdjb9kbmx0pr80c0zc0fyqqyh-QuickCheck-2.14.2.drv
  /nix/store/lvclw4q2jmk89v5ppkfw3mr72qb8ch2d-haskell-project-0.1.0.0.drv
building '/nix/store/6my008rqdjb9kbmx0pr80c0zc0fyqqyh-QuickCheck-2.14.2.drv'...
...
Configuring QuickCheck-2.14.2...
CallStack (from HasCallStack):
  $, called at libraries/Cabal/Cabal/Distribution/Simple/Configure.hs:1024:20 in Cabal-3.2.0.
  ...
  defaultMain, called at Setup.lhs:8:10 in main:Main
Setup: Encountered missing or private dependencies:
splitmix ==0.1.*

builder for '/nix/store/6my008rqdjb9kbmx0pr80c0zc0fyqqyh-QuickCheck-2.14.2.drv' failed with exit code 1
cannot build derivation '/nix/store/lvclw4q2jmk89v5ppkfw3mr72qb8ch2d-haskell-project-0.1.0.0.drv': 1 dependencies couldn't be built
error: build of '/nix/store/lvclw4q2jmk89v5ppkfw3mr72qb8ch2d-haskell-project-0.1.0.0.drv' failed
```

So it turns out that `QuickCheck-2.14.2` depends on `splitmix ==0.1.*`, but nixpkgs only
have `splitmix-0.0.5`, despite `splitmix-0.1` has been released since May 2020.

We can see this as the effect of transitive dependency update. If `splitmix` is upgraded
to version `0.1`, it will break many packages that directly depend on it, which
in turns breaks other packages that indirectly depend on it. With nixpkgs's
mono-versioning approach, there is no easy way around this other than upgrading
all affecting packages at once, or upgrading none of them. Mono-versioning
is hard!

Still, we can workaround this by overriding `splitmix` as well:

```nix
{{#include ./haskell-project-v3/nix/04-nixpkgs-infinite-recursion/default.nix}}
```

## Infinite Recursion

If we build this, we once again get another error: the infamous infinite recursion
error:

```bash
$ nix-build --show-trace 05-package-management/haskell-project-v3/nix/04-nixpkgs-infinite-recursion/
error: while evaluating the attribute 'buildInputs' of the derivation 'haskell-project-0.1.0.0' at /nix/store/kk346951sg2anjjh8cgfbmrijg983z5q-nixpkgs-src/pkgs/development/haskell-modules/generic-builder.nix:291:3:
while evaluating the attribute 'propagatedBuildInputs' of the derivation 'QuickCheck-2.14.2' at /nix/store/kk346951sg2anjjh8cgfbmrijg983z5q-nixpkgs-src/pkgs/development/haskell-modules/generic-builder.nix:291:3:
while evaluating the attribute 'buildInputs' of the derivation 'splitmix-0.1.0.3' at /nix/store/kk346951sg2anjjh8cgfbmrijg983z5q-nixpkgs-src/pkgs/development/haskell-modules/generic-builder.nix:291:3:
while evaluating the attribute 'propagatedBuildInputs' of the derivation 'async-2.2.2' at /nix/store/kk346951sg2anjjh8cgfbmrijg983z5q-nixpkgs-src/pkgs/development/haskell-modules/generic-builder.nix:291:3:
while evaluating the attribute 'buildInputs' of the derivation 'hashable-1.3.0.0' at /nix/store/kk346951sg2anjjh8cgfbmrijg983z5q-nixpkgs-src/pkgs/development/haskell-modules/generic-builder.nix:291:3:
infinite recursion encountered, at undefined position
```

So `QuickCheck` depends on `splitmix`, but `splitmix` tests also indirectly depend on
`QuickCheck`, causing a cyclic dependency. Unfortunately the callPackage
pattern do not have a way to deal with cyclic dependencies, so we have to
manually find ways around it.

Fortunately in this case, it is simple to avoid it by no running unit tests on
`splitmix`:


```nix
{{#include ./haskell-project-v3/nix/05-nixpkgs-override/default.nix}}
```

Now our package finally builds.

## Haskell.nix

In comparison, there is no manual intervention needed for Haskell.nix-based
derivation:

```nix
{{#include ./haskell-project-v3/nix/06-haskell.nix/project.nix}}
```

Hoepfully this shows why we prefer to use Haskell.nix, especially if we
want it to work the same way as cabal and get the latest Haskell packages
from Hackage.
