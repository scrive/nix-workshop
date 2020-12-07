# Version Conflicts in Haskell Dependencies

In the previous chapter we have created a trivial Haskell project with no
dependency other than `base`. Let's look at what happen when our Haskell
project have some dependencies, which happen to conflict with the
dependencies available in `nixpkgs`.

We first define a new Haskell project,
[haskell-project-v2](./haskell-project-v2/haskell/haskell-project.cabal):

```
{{#include ./haskell-project-v2/haskell/haskell-project.cabal}}
```

We add a new dependency `yaml` and explicitly requiring version `0.11.3.0`.
At the time of writing, the latest version of `yaml` available on
[Hackage](https://hackage.haskell.org/package/yaml) is `0.11.5.0`.
However let's pretend there are
[breaking changes](https://github.com/snoyberg/yaml/issues/173)
in `0.11.5.0`, and we only support `0.11.3.0`.

## Nixpkgs

Let's try to follow our previous approach to define our Haskell derivation
using `callCabal2nix`. If we do that and try to build it, we would
run into an error:

```bash
$ nix-build 05-package-management/haskell-project-v2/nix/01-nixpkgs-conflict/
building '/nix/store/3gab06pwqjc16wdqhj5akxk21g1z0qnx-cabal2nix-haskell-project.drv'...
these derivations will be built:
  /nix/store/242x69pl2la3lb201qd57rghisrwclpy-haskell-project-0.1.0.0.drv
building '/nix/store/242x69pl2la3lb201qd57rghisrwclpy-haskell-project-0.1.0.0.drv'...
...
Setup: Encountered missing or private dependencies:
yaml ==0.11.3.0

builder for '/nix/store/242x69pl2la3lb201qd57rghisrwclpy-haskell-project-0.1.0.0.drv' failed with exit code 1
error: build of '/nix/store/242x69pl2la3lb201qd57rghisrwclpy-haskell-project-0.1.0.0.drv' failed
```
Why is that so?

If we try to enter Nix shell, it will still succeed. But if we try to build
our Haskell project in Nix shell, we will find out that the package `yaml`
has to be explicitly built by cabal:

```bash
$ nix-shell 05-package-management/haskell-project-v2/nix/01-nixpkgs-conflict/shell.nix

[nix-shell]$ cd 05-package-management/haskell-project-v2/haskell/

[nix-shell]$ cabal --dry-run build all
Resolving dependencies...
Build profile: -w ghc-8.10.2 -O1
In order, the following would be built (use -v for more details):
 - yaml-0.11.3.0 (lib) (requires build)
 - haskell-project-0.1.0.0 (exe:hello) (first run)
```

## Problem with Mono-versioning

If we look into
[nixpkgs source code](https://raw.githubusercontent.com/NixOS/nixpkgs/c1e5f8723ceb684c8d501d4d4ae738fef704747e/pkgs/development/haskell-modules/hackage-packages.nix),
we can in fact see that the version of `yaml` available in nixpkgs is the latest,
`0.11.5.0`.

As discussed earlier, with the mono-versioning approach by nixpkgs, there is
exactly one version of each package available. Mono-versioning conflicts
can happen when we need packages that are either older or newer than the version
provided by nixpkgs.

In theory we could switch to a version of nixpkgs that has `yaml-0.11.3.0`,
however we would then have to buy into the versions of other Haskell packages
available at that time.

## Overriding Versions

Nixpkgs provides a workaround for mono-versioning conflicts, by using the
[override pattern](https://nixos.org/guides/nix-pills/override-design-pattern.html).
We can override the version of `yaml` to the one we want as follows:

```nix
{{#include ./haskell-project-v2/nix/02-nixpkgs-override/default.nix}}
```

Essentially, we refer to the original haskell package set provided as
`hsPkgs-original`, and we call `hsPkgs-original.override` to produce
a new package set `hsPkgs` with `yaml` overridden to `0.11.3.0`.

Using `callHackage`, we can fetch the version of `yaml` from the
Hackage snapshot in nixpkgs. With that we can just provide the
string `"0.11.3.0"` to specify the version that we want. Note
however that this only works if the version can be found in the
given Hackage snapshot, which may be outdated over time.

An issue with overriding dependencies this way is that the override
affects the entire Haskell package set. This means that all other
Haskell packages that depend on `yaml` will also get `0.11.3.0`
instead of `0.11.5.0`. As a result, this may have the unintended
ripple effect of breaking other Haskell packages that we depends
on.

## Building Overridden Package

If we try to build our Haskell derivation with overridden `yaml`,
it would work this time:

```bash
$ nix-build 05-package-management/haskell-project-v2/nix/02-nixpkgs-override/
these derivations will be built:
  /nix/store/l0v04zz36b5s5r3qc2jisvggyc0gkj5w-remove-references-to.drv
  /nix/store/bg5z6b7m24fxqn8qq2l2w8c0w30wkbp3-yaml-0.11.3.0.drv
  /nix/store/p5sr404mzr8bnqqprv72lxczdr9cnnim-haskell-project-0.1.0.0.drv
...
/nix/store/0m0mr11ncii3z4zkn9z0xkwk4nswprqm-haskell-project-0.1.0.0
```

We can also enter the Nix shell to verify that this time, cabal will
not try to build `yaml` for us:

```bash
$ nix-shell 05-package-management/haskell-project-v2/nix/02-nixpkgs-override/shell.nix

[nix-shell]$ cd 05-package-management/haskell-project-v2/haskell/

[nix-shell]$ cabal --dry-run build all
Resolving dependencies...
Build profile: -w ghc-8.10.2 -O1
In order, the following would be built (use -v for more details):
 - haskell-project-0.1.0.0 (exe:hello) (first run)
```

## Haskell.nix

In comparison with the mono-versioned nixpkgs, Haskell.nix is much more flexible
in allowing any version of Haskell packages that are supported by cabal.
So we can leave the Nix project unchanged and still build it successfully:

```bash
$ nix-build 05-package-management/haskell-project-v2/nix/03-haskell.nix/
trace: No index state specified, using the latest index state that we know about (2020-12-04T00:00:00Z)!
building '/nix/store/v4pf9jffq0dh6xang25qviwb77947s7s-plan-to-nix-pkgs.drv'...
Using index-state 2020-12-04T00:00:00Z
Warning: The package list for 'hackage.haskell.org-at-2020-12-04T000000Z' is
18603 days old.
Run 'cabal update' to get the latest list of available packages.
Warning: Requested index-state2020-12-04T00:00:00Z is newer than
'hackage.haskell.org-at-2020-12-04T000000Z'! Falling back to older state
(2020-12-03T20:14:57Z).
Resolving dependencies...
Build profile: -w ghc-8.10.2 -O1
In order, the following would be built (use -v for more details):
 - base-compat-0.11.2 (lib) (requires download & build)
 - base-orphans-0.8.3 (lib) (requires download & build)
 ...
 - aeson-1.5.4.1 (lib) (requires download & build)
 - yaml-0.11.3.0 (lib) (requires download & build)
 - haskell-project-0.1.0.0 (exe:hello) (first run)
these derivations will be built:
these derivations will be built:
...
  /nix/store/y8vbr0b6y8bzgmadj0rfjp3d2rzx5wgs-yaml-lib-yaml-0.11.3.0-config.drv
  /nix/store/fhmib5kqsxl82r1z23mm59njw2dn0c8v-yaml-lib-yaml-0.11.3.0-ghc-8.10.2-env.drv
  /nix/store/j837v0cxk9dxqpxfjfngii007hq8wn3w-yaml-lib-yaml-0.11.3.0.drv
  /nix/store/nxwvfjaj40adyq002khld7ngnq3wggn7-haskell-project-exe-hello-0.1.0.0-config.drv
  /nix/store/y27wbd58f5d1k3lzbzpr5qcc4pgqrxg2-haskell-project-exe-hello-0.1.0.0-ghc-8.10.2-env.drv
  /nix/store/b4i7xhnha8007zqxd4gidsf7xyy338an-haskell-project-exe-hello-0.1.0.0.drv
...
/nix/store/phm2jk6xnvxsgp640r66cwgipc62kbc5-haskell-project-exe-hello-0.1.0.0

$ /nix/store/phm2jk6xnvxsgp640r66cwgipc62kbc5-haskell-project-exe-hello-0.1.0.0/bin/hello
Hello, Haskell!
```
