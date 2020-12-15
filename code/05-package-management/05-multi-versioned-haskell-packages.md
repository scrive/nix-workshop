# Multi-versioned Haskell Packages

As we seens in the previous chapters, the mono-versioned Haskell packages
provided by nixpkgs do not always provide the exact versions of Haskell
packages that we need. When version conflicts happen, it often require
manual intervention, because there is no mechanism to automatically
resolve the new set of dependency versions based on custom requirements.

In comparison, package managers like cabal-install are built with
multi-versioned Haskell packages in mind. We can give various
requirements of our dependencies to cabal by specifying version
bounds. If a solution exists, cabal can automatically generate a
dependency graph for us.

## Haskell.nix

Haskell.nix takes multi-versioned approach toward managing Haskell
packages in Nix. It does so by making use of cabal-install to
resolve the dependency graph, and converting it into Nix expressions.

Since Haskell.nix uses cabal-install for the actual package management,
it can usually work out of the box for existing cabal-based Haskell
projects.

Nevertheless, Cabal offers a wide range of features, some of which
are not currently well supported by Haskell.nix. Because of this,
it is important to understand how Haskell.nix works internally.
This would help us understand why certain limitations are present
in Haskell.nix.

Haskell.nix also provides other mode of Haskell development in Nix,
such as Stack-based Haskell projects. However in this chapter we
will focus only on using Haskell.nix for cabal projects.

## Hackage Index

To understand how Haskell.nix resolves dependencies, we have to first
understand how Cabal resolves dependencies. Recall from the chapter
[Dependency Management](./01-dependency-management.md) that for
a package manager to resolve dependencies, it has to run the
dependency resolution algorithm against the state of a package
registry.

For the case of Cabal, the dependency resolution is done against
the [Hackage](https://hackage.haskell.org) registry.
More specifically, Cabal resolves the dependencies by downloading
the [entire state](https://hackage.haskell.org/01-index.tar.gz)
of the Hackage index to your local machine.

Every time new packages are added to Hackage, a new Hackage index
snapshot is generated, and the entire index has to be re-downloaded.
(Technically, the update is incremental with append-only update to
the snapshot. However this relies on explicit HTTP caching mechanism
to work.)

Currently the Hackage index snapshot takes about 100 MiB after
compression. Furthermore the official Hackage bandwidth is pretty
low and do not always stay available. Because of this, it can often
take a long time to update cabal, especially when running it for
the first time.

When we build Haskell projects with `cabal`, the local Hackage
index is not updated automatically. Instead we have to manually
run `cabal update` to update the local Hackage index. As a result,
it is a common problem that a new Haskell package is published
to Hackage, but it cannot be found in local builds because
the local index is not updated.

## Accessing Hackage Index Inside Nix

Since Haskell.nix uses Cabal to resolve the dependencies inside
Nix, it needs to download and provide the Hackage snapshot
inside of a Nix build.

By default, Cabal downloads the Hackage snapshot into
`~/.cabal/packages`. However since there is no home directory
inside a Nix build, we need to put it somewhere local.
This can be done by specifying a `--remote-repo-cache`
option when running Cabal.

Even so, the next challenge is that we need to download
the Hackage snapshot, and save it to the Nix store.
The SHA256 checksum of the Hackage snapshot is also
needed, so that Nix can be sure that all Nix builds are using the exact
version of Hackage snapshot.

Fortunately Haskell.nix takes care of all these details for us. However this
comes at a cost: Haskell.nix needs to regularly update and convert the
Hackage snapshot into Nix expressions.

In fact, Haskell.nix manages this through the
[Hackage.nix](https://github.com/input-output-hk/hackage.nix) project.
It triggers regular CI builds to update to the latest Hackage snapshot,
and save the result as Nix expressions. Haskell.nix itself is also
regularly updated, to update the Hackage snapshot through
updating the version of Hackage.nix used in Haskell.nix.

Regardless, the state update do not run continuously, but rather
usually once every day. There can be up to a few days delay
for the Hackage snapshot to be included in Haskell.nix.
This also means that when a new Haskell package is published
to Hackage, we cannot always use it immediately in Haskell.nix.

If we really insist on getting the bleeding edge Haskell packages,
a workaround would be that we can maintain our own Hackage snapshot.
Since Hackage.nix is open source, there is no problem doing that.
However this would also adds a lot of overhead, as we would
have to regularly keep up to date our own version of Hackage.nix.
Because of this, we recommend readers to be patient and wait for
few days for a new Haskell packge to become available in Haskell.nix.

## Freezing Hackage Index

The Hackage index at hackage.haskell.org is constantly updated, and there is
no straightforward way to go back in time and get the old state of Hackage
at a time in the past.

This can cause issue when we try to download the Hackage snapshot from Nix.
To ensure reproducibility, the downloaded `01-index.tar.gz` is supposed
to have the exact same content for everyone by checking the SHA256
checksum. But since the Hackage index keeps changing, we cannot ask
Nix to just download the index from the URL.

As a workaround, Hackage instead guarantees that the index state is
updated in append-only mode. With this Haskell.nix uses a workaround
to _truncate_ the downloaded index with a known length of the
snapshot at a particular time during fetching. This helps make sure
that when Nix finally sees the index archive, the content is exactly
the same regardless of when the code is evaluated.

Nevertheless, this workaround is one part of the complexity in Haskell.nix.
In the daily update to Hackage.nix, it has to regularly check the new
length of the latest Hackage index, while keeping the old lengths for
each day in the past. As a `.tar.gz` file, the format is opaque, and
it needs to rely on the obscure interaction of Hackage with the file
compression to create a reproducible index snapshot.

## Source Repository Package

Haskell.nix also allows Haskell packages to be provided outside of Hackage.
This can be done by adding
[`source-repository-package`](https://cabal.readthedocs.io/en/3.4/cabal-project.html#specifying-packages-from-remote-version-control-locations)
fields in your cabal.project file. Haskell.nix automatically takes into
consideration these fields when resolving the depdendencies.

One additional detail that is needed when using `source-repository-package`
with Haskell.nix is that you may optionally needs to add the SHA256
checksum of the Haskell package with a `--sha256` comment line. More details
[here](https://input-output-hk.github.io/haskell.nix/tutorials/source-repository-hashes/#cabalproject).

## Resolving Dependencies

We have learned [earlier](../04-derivations/03-fibonacci.md) that
evaluation-time dependencies can cause various issues in Nix. However
Haskell.nix uses evaluation-time dependency, or more specifically
Import From Derivation (IFD), to resolve the dependency graph
of our Haskell projects.

To understand why IFD is needed, we need to first look at how Cabal
resolves the dependencies, and where it stores the dependency graph.

We can ask Cabal to resolve the dependencies of our Haskell project
by running `cabal configure`. Inside this command, Cabal will read the
cabal.project and .cabal file, read the local Hackage snapshot,
and try to come out with a dependency graph as the solution. When successful,
cabal stores the result locally in the `dist-newstyle/cache` directory.

Inside the `dist-newstyle/cache` directory, there is a `plan.json` file
which contains the dependency graph that third party tools such as
Haskell.nix can use to extract the result. There are libraries such as
[cabal-plan](https://hackage.haskell.org/package/cabal-plan) that are available,
which Haskell.nix uses to parse the dependency graph.

Now remember that to build a Haskell project with Nix, we need to construct
one or more Nix derivations that encapsulate our project and all its
dependencies. Since a Haskell project contains many dependencies, we want to
define each Haskell package as their own Nix derivation. This way Nix can
parallellize the build for each of our dependencies, and also reuse the build
result if only some of the dependencies changes.

However to construct our derivation, we need to first call `cabal configure`
to resolve the dependency graph, and then extract the result from `plan.json`.
In other words, to construct the actual Nix derivation of our project, we need
to first construct another derivation that produces a build plan that tells us
what dependencies are needed.

## Derivation Plan

In Haskell.nix, the build plan that is produced from calling Cabal is called
a _plan_. The name might be a bit confusing, but essentially
it represents the evaluation-time dependency of a Haskell project, of which the
Nix derivation that needs to be built first before the actual Nix derivation
for the Haskell project can be constructed.

Recall that Nix cannot identify which derivation is an evaluation-time
dependency of another package. This means that if we try to inspect the
derivation for our Haskell project, the derivation for the plan
would never show up there. This also means that the plan
cannot be cached easily.

Haskell.nix exports the plan for a Haskell project in
the `plan-nix` attribute. We can build this to see how the plan looks like:


```bash
$ nix-build -A plan-nix 05-package-management/haskell-project-v3/nix/06-haskell.nix/project.nix
trace: No index state specified, using the latest index state that we know about (2020-12-04T00:00:00Z)!
checking outputs of '/nix/store/5v1835nh26s8dldssz03cysm3aay6d7q-plan-to-nix-pkgs.drv'...
Using index-state 2020-12-04T00:00:00Z
Warning: The package list for 'hackage.haskell.org-at-2020-12-04T000000Z' is
18610 days old.
Run 'cabal update' to get the latest list of available packages.
Warning: Requested index-state2020-12-04T00:00:00Z is newer than
'hackage.haskell.org-at-2020-12-04T000000Z'! Falling back to older state
(2020-12-03T20:14:57Z).
Resolving dependencies...
Build profile: -w ghc-8.10.2 -O1
In order, the following would be built (use -v for more details):
 - splitmix-0.1.0.3 (lib) (requires download & build)
 - random-1.2.0 (lib) (requires download & build)
 - QuickCheck-2.14.1 (lib) (requires download & build)
 - haskell-project-0.1.0.0 (exe:hello) (first run)
/nix/store/pgdqan44d8ky1yz0d687d2nhqsqflc48-plan-to-nix-pkgs

$ cat /nix/store/pgdqan44d8ky1yz0d687d2nhqsqflc48-plan-to-nix-pkgs/default.nix
{
  pkgs = hackage:
    {
      packages = {
        "ghc-prim".revision = (((hackage."ghc-prim")."0.6.1").revisions).default;
        "mtl".revision = (((hackage."mtl")."2.2.2").revisions).default;
        "rts".revision = (((hackage."rts")."1.0").revisions).default;
        "QuickCheck".revision = (((hackage."QuickCheck")."2.14.1").revisions).default;
        ...
      }
      compiler = {
        version = "8.10.2";
        nix-name = "ghc8102";
        packages = {
          "ghc-prim" = "0.6.1";
          "mtl" = "2.2.2";
          ...
        }
      }
    }
  ...
}
```

We can see that the plan contains quite detailed information on
the exact versions of dependencies that are needed to build our Haskell
project.

## Caching Plans with Materialization

The dependency resolution algorithm is not a cheap operation to run, especially
in large Haskell projects. This is why Cabal caches the result inside of
`dist-newstyle/cache` instead of recomputing it every time commands such as
`cabal build` are called.

In the case of Nix, we know that a Nix build can be cached and reused if there
are no changes in the build inputs. However for the case of a materialized
plan, the result of the plan depends on the input source code of the Haskell
project. This means that every time the source code changes, the plan
needs to be recomputed from scratch.

Furthermore, computing the materialized plan requires a number of dependencies
that are not needed when building the Haskell project itself. On the other
hand, We know that the materialized plan only changes when either the dependencies
list is updated, or when the Hackage index state is updated. So we should be
able to cache the materialized plan so that there is no need for Haskell.nix
to recompute the dependencies all the time.

In Haskell.nix, the act of manually caching the derivation plan is called
[_materialization_](https://input-output-hk.github.io/haskell.nix/tutorials/materialization/).
To put it simply, we can materialize the derivation plan by copying the
build output of the `plan-nix` derivation and check that into the source
control of the project.

If we already have the plan files cached in version control, we can then
pass the path to the .nix file as the `materialized` attribute when defining
our Haskell.nix project.

## Example Materialized Haskell Project

The Nix project
[07-haskell.nix-materialized](./haskell-project-v3/nix/07-haskell.nix-materialized)
contains an example Haskell.nix project that provides basic support for
materialization.

As compared to the simplified version, the project.nix has a few more
additional fields passed to Haskell.nix:

```nix
{{#include ./haskell-project-v3/nix/07-haskell.nix-materialized/project.nix}}
```

The project.nix file is now a function accepting a `useMaterialization` argument.
If it is set to `true`, then the materialized plan is passed to Haskell.nix
through the `materialized` attribute.

We also need to explicitly provide Haskell.nix the version of Hackage snapshot
we want to use, which we hard code to `"2020-12-04T00:00:00Z"`.

We set the `exactDeps` option here to `true`, so that when the materialized
plan is out of sync, we get error when running `cabal build` inside the Nix shell.


There are also a new [plan](./haskell-project-v3/nix/07-haskell.nix-materialized/plan)
directory, a
[plan-hash.txt](./haskell-project-v3/nix/07-haskell.nix-materialized/plan-hash.txt)
file, and a
[sync-materialized.sh](./haskell-project-v3/nix/07-haskell.nix-materialized/sync-materialized.sh)
script:


```nix
{{#include ./haskell-project-v3/nix/07-haskell.nix-materialized/sync-materialized.sh}}
```

The script `sync-materialized.sh` creates a Haskell.nix project with
`useMaterialization` set to `false`. It then copies the build output of `plan-nix`
to the `plan/` directory, and compute the SHA256 hash of the directory and save it to
`plan-hash.txt`.

As we can see, a Haskell.nix project using materialized plan is a bit more involved.
However the performance trade off of using materialized plan in a large Haskell
project can be significant. The example project template can hopefully
serve as a reference on how to setup a Haskell.nix project with materialization.

## Syncing Materialized Plan

When we explicitly cache the materialized plans, there is a risk of the plan
file diverging from the actual Haskell dependencies when the .cabal file is
updated. It can also introduce additional noise in git commits when
dependencies are updated. This can introduce friction in Haskell projects,
as all team members become responsible to update the materialized plans
when the Haskell dependencies are updated.

Checking in dependencies metadata into version control is a common problem
in software projects, particularly Nix projects. As discussed in
[Dependency Management](./01-dependency-management.md), this is a
necessary evil to make sure that our dependencies are reproducible.
Syncing materialized plans can be seen as the same methods as
syncing other dependencies lock files such as `cabal.project.freeze`
and `package-lock.json`.

Nevertheless, the current workflow for managing materialization plans
in Haskell.nix is not very convenient, and there are a lot of
improvements that could have been made. We can only hope that
these steps can be improved in future versions of Haskell.nix.

Or perhaps there are better ways of managing Haskell dependencies,
as described in the next chapter.


## Caching Haskell.nix Dependencies

One of the downside of multi-versioning approach taken by Haskell.nix
is that it is much more difficult to provide a general Nix cache for
Haskell.nix projects.

When Haskell projects are built using unmodified nixpkgs, there is
usually no need to build any Haskell dependencies at all. Instead
the Haskell packages are downloaded directly from cache.nixos.org.

This is possible thanks to the mono-versioning approach of nixpkgs.
Since there is exactly one version of each package and their
dependencies, the build result of the same dependency can always be
reused for multiple packages. As such, the number of Nix packages
that need to be cached are relatively small, and the default NixOS
cache takes care of caching all of them.

In contrast, in Haskell.nix the dependencies for a package can
change depending on the requirements of its dependents. So instead of
caching one copy of each version of Haskell package, there is
a combinatory explosion of packages to be cached - one for
each possible combination of transitive dependencies for that package
alone.

Because of this, it is common that building a Haskell.nix project also
requires building all the Haskell dependencies. We will discuss about
how to use Cachix to cache such Nix dependencies in the future.
