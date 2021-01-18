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

## Nix Dependency Management with Niv

We will use multiple Nix sources including nixpkgs and Haskell.nix
in our Haskell projects. However specifying the Nix dependencies
explicitly like in [`nixpkgs.nix`](../nixpkgs.nix) can be a bit
cumbersome.

```nix
{{#include ../nixpkgs.nix}}
```

Instead we can use [niv](https://github.com/nmattia/niv.git) to
manage the dependencies for us. Niv allows us to easily add
any remote sources as a Nix dependency, and provide them
in a single `sources` object.

We can initialize niv in the project directory as follows:

```bash
$ nix-shell -j4 -E \
  'let nixpkgs = import ./nixpkgs.nix;
    in nixpkgs.mkShell { buildInputs = [ nixpkgs.niv ]; }'

[nix-shell]$ 05-package-management/haskell-project-v1

[nix-shell]$ niv init
```

By default, niv will initialize with the latest nixpkgs version
available. We can explicitly override the commit version of
nixpkgs to the one in this tutorial.

```bash
[nix-shell]$ niv update nixpkgs --branch nixpkgs-unstable \
              --rev c1e5f8723ceb684c8d501d4d4a
e738fef704747e
Update nixpkgs
Done: Update nixpkgs
```

We can also add new dependencies such as Haskell.nix using
`niv add`:

```bash
[nix-shell]$ niv add input-output-hk/haskell.nix \
              --rev 180779b7f530dcd2a45c7d00541f0f3e3d8471b5
Adding package haskell.nix
  Writing new sources file
Done: Adding package haskell.nix
```

Two new files, `nix/sources.json` and `sources.nix` will be created
by niv. To load the source dependencies, we can simply do
`sources = import ./nix/sources.nix {}` to import the source object.
The source files are then available in the corresponding
attributes of the sources object, such as `sources.nixpkgs`.

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
 - haskell-project-0.1.0.0 (exe:hello) (first run)
Configuring executable 'hello' for haskell-project-0.1.0.0..
Preprocessing executable 'hello' for haskell-project-0.1.0.0..
Building executable 'hello' for haskell-project-0.1.0.0..
[1 of 1] Compiling Main             ( Main.hs, /mnt/gamma/scrive/nix-workshop/code/05-package-management/haskell-project-v1/haskell/dist-newstyle/build/x86_64-linux/ghc-8.10.2/haskell-project-0.1.0.0/x/hello/build/hello/hello-tmp/Main.o )
Linking /mnt/gamma/scrive/nix-workshop/code/05-package-management/haskell-project-v1/haskell/dist-newstyle/build/x86_64-linux/ghc-8.10.2/haskell-project-0.1.0.0/x/hello/build/hello/hello ...
```

## Default Attempt

We can instead try the default way of building Haskell packages in Nix.
There is a full tutorial by
[Gabriel](https://github.com/Gabriel439/haskell-nix). Here we will
just take a quick tour.

```nix
{{#include ./haskell-project-v1/nix/02-nixpkgs/default.nix}}
```

  - We use the `hsPkgs.callCabal2nix` function to create a nixpkgs-style package.

  - We then call `hsPkgs.callPackage` to "instantiate" our project with the
    dependencies taken from `hsPkgs`.

Now try to build it:

```bash
$ nix-build 05-package-management/haskell-project-v1/nix/02-nixpkgs/
building '/nix/store/8rgnd9620lf287i0nw4j3z4wb01pd36a-cabal2nix-haskell-project.drv'...
installing
these derivations will be built:
  /nix/store/as92yri0vvfi5yck5gajckfx064fy0qy-haskell-project-0.1.0.0.drv
building '/nix/store/as92yri0vvfi5yck5gajckfx064fy0qy-haskell-project-0.1.0.0.drv'...
...
Preprocessing executable 'hello' for haskell-project-0.1.0.0..
Building executable 'hello' for haskell-project-0.1.0.0..
[1 of 1] Compiling Main             ( Main.hs, dist/build/hello/hello-tmp/Main.o )
Linking dist/build/hello/hello ...
...
/nix/store/3aq34n1ba3pvl6cs6f63xd737fz6604r-haskell-project-0.1.0.0

$ /nix/store/3aq34n1ba3pvl6cs6f63xd737fz6604r-haskell-project-0.1.0.0/bin/hello
Hello, Haskell!
```

That works. We can also create a separate `shell.nix` to derive a Nix shell
environment based on our Haskell environment.


```nix
{{#include ./haskell-project-v1/nix/02-nixpkgs/shell.nix}}
```

We use `nixpkgs.mkShell` to create a Nix derivation that is explicitly used
for Nix shell. `inputsFrom` propagates all build inputs of a derivation to
the new derivation. We use `project.env` which is a sub-derivation given
by `callCabal2nix` which contains the GHC shell environment for building
our project.

Notice that we have to explicitly provide `cabal-install` as `buildInput`
to our shell derivation. This shows that internally, the Haskell packages
in nixpkgs are built by directly calling GHC, skipping `cabal` entirely.

## How Haskell in Nixpkgs Work

The Haskell packages in nixpkgs are _mono-versioned_. This means for each
Haskell package such as `base`, `aeson`, etc, there is exactly one version
provided by a Haskell packages set. There are however multiple versions
of Haskell packages in nixpkgs, determined by the GHC versions.

For instance, `nixpkgs.haskell.packages.ghc8102` contains mono-versioned
Haskell packages that works in GHC 8.10.2, while
`nixpkgs.haskell.packages.ghc884` contains mono-versioned Haskell packages
that works in GHC 8.8.4.

```bash
$ nix-shell 05-package-management/haskell-project-v1/nix/02-nixpkgs/shell.nix

[nix-shell]$ cd 05-package-management/haskell-project-v1/haskell/

[nix-shell]$ cabal build all
Resolving dependencies...
Build profile: -w ghc-8.10.2 -O1
In order, the following will be built (use -v for more details):
 - haskell-project-0.1.0.0 (exe:hello) (first run)
Configuring executable 'hello' for haskell-project-0.1.0.0..
Preprocessing executable 'hello' for haskell-project-0.1.0.0..
Building executable 'hello' for haskell-project-0.1.0.0..
[1 of 1] Compiling Main             ( Main.hs, /mnt/gamma/scrive/nix-workshop/code/05-package-management/haskell-project-v1/haskell/dist-newstyle/build/x86_64-linux/ghc-8.10.2/haskell-project-0.1.0.0/x/hello/build/hello/hello-tmp/Main.o )
Linking /mnt/gamma/scrive/nix-workshop/code/05-package-management/haskell-project-v1/haskell/dist-newstyle/build/x86_64-linux/ghc-8.10.2/haskell-project-0.1.0.0/x/hello/build/hello/hello ...
```

### Stackage Upstream

The mono versions of Haskell packages used to follow Stackage LTS,
which is also mono-versioned. However recently the team have
[switched to Stackage nightly](https://discourse.nixos.org/t/new-ghc-default-version-8-10-2-package-versions-now-from-stackage-nightly/10117)
to reduce the maintenance burden.

### Callpackage Pattern

As we discussed in previous chapter, Nix itself does not provide any
mechanism for dependency resolution. So nixpkgs come out with the
[Callpackage design pattern](https://nixos.org/guides/nix-pills/callpackage-design-pattern.html)
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
that connects all packages with their dependencies. If this succeeds
we get a Nix derivation with the dependency derivations provided
to our partial package.

### Dependency Injection

`callPackage` is essentially a dependency injection pattern, where
components can specify what they need without hardcoding the
reference. This allows dependencies to be _overridden_ before
the `callPackage` is called.

Using functional programming techniques, it is relatively trivial
to compose partial package functions so that dependencies can
be overridden either locally or globally. For example, nixpkgs
use the
[override](https://nixos.org/guides/nix-pills/override-design-pattern.html)
pattern to allow dependencies of a package be overridden.

While functional programming makes it easy to override dependencies,
it does not make it easy to _inspect_ the dependency graph to find
out what is overridden. This is the downside of composing using
closures as blackboxes, as compared to composing ADTs
(algebraic data types) as whiteboxes.

Because of this, heavy usage of `callPackage` and `override` may impact
readability and maintainability. Readers of a Nix code base may no longer
be able to statically infer which final versions of dependencies are
linked to a package.

## Haskell.nix

There is an alternative approach to managing Haskell dependencies
using [Haskell.nix](https://github.com/input-output-hk/haskell.nix).
Unlike the mono-versioned Haskell packages in nixpkgs, Haskell.nix
gives more flexibilities and allows interoperability with the
multi-versioned approach of package management with cabal.

As we will see in the next chapter, the multi-versioned approach
of Haskell.nix makes it much easier to add bleeding-edge dependencies
from Hackage. Haskell.nix also offers many other features, such as
cross compiling Haskell packages.

The biggest hurdle of adopting Haskell.nix is unfortunately to
properly add Haskell.nix as a dependency in your Nix project.
From the first section of the
[project readme](https://github.com/input-output-hk/haskell.nix#help-something-isnt-working):

> **Help! Something isn't working**
>
> The #1 problem that people have when using haskell.nix is that they find themselves building GHC. This should not happen, but you must follow the haskell.nix setup instructions properly to avoid it. If you find this happening to you, please check that you have followed the
> [getting started instructions](https://input-output-hk.github.io/haskell.nix/tutorials/getting-started/#setting-up-the-binary-cache)
> and consult the corresponding
> [troubleshooting section](https://input-output-hk.github.io/haskell.nix/troubleshooting/#why-am-i-building-ghc).

As mentioned, the most important step to start using Haskell.nix is to
add the `hydra.iohk.io` Nix cache to your `~/.config/nix/nix.conf`:

```
trusted-public-keys = [...] hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= [...]
substituters = [...] https://hydra.iohk.io [...]
```

### Haskell.nix-based derivation

Aside from that first hurdle, defining a Haskell.nix-based Nix derivation
is relatively straightforward. First we define a `project.nix`:

```nix
{{#include ./haskell-project-v1/nix/03-haskell.nix/project.nix}}
```

We use the version of Haskell.nix managed by niv and import it. Here we
also use the version of nixpkgs provided by Haskell.nix, which adds
additional functionalities in `nixpkgs.haskell-nix`. We then call the
function `haskell-nix.pkgs.haskell-nix.cabalProject` to define a
cabal-based Haskell.nix project.

We provide the Haskell source code through the `src` attribute, and
also a `compiler-nix-name` field to specify the GHC version we want
to use, GHC 8.10.2.

### Project Outputs

To actually build our Haskell project, we define a `default.nix` to
build the `hello` executable we have in our project:

```nix
{{#include ./haskell-project-v1/nix/03-haskell.nix/default.nix}}
```

A Haskell.nix project can have multiple derivation outputs for
each cabal component. For our case, we do not have any library
but have one executable named `hello`. To load that, the executable
is unfortunately located in a long and obscure path
`project.haskell-project.components.exes.hello`.

```bash
$ nix-build 05-package-management/haskell-project-v1/nix/03-haskell.nix/
trace: No index state specified, using the latest index state that we know about (2020-12-04T00:00:00Z)!
these derivations will be built:
  /nix/store/xdpklq1y86h6jw6d8fyw6xwhr93l8g73-haskell-project-exe-hello-0.1.0.0-config.drv
  /nix/store/j0azqvy5iccbfqp6s0gbfwdgjjp8x2ji-haskell-project-exe-hello-0.1.0.0-ghc-8.10.2-env.drv
  /nix/store/mp20hw7kjpqfwqsspjff0h8w8qng8n9d-haskell-project-exe-hello-0.1.0.0.drv
...
/nix/store/yr533l33zrpri7n47lsfm2cih5i0800a-haskell-project-exe-hello-0.1.0.0

$ /nix/store/yr533l33zrpri7n47lsfm2cih5i0800a-haskell-project-exe-hello-0.1.0.0/bin/hello
Hello, Haskell!
```
