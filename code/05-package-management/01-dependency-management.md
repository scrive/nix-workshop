# Dependency Management

We have seen in previous chapters that Nix makes it easy to construct
complex build depedencies with several benefits:

  - Non-related dependencies can be built in parallel.
  - Reproducible builds make it easy to cache and reuse dependencies.

However Nix does not provide any mechanism for dependency _resolution_,
e.g. choose from multiple _versions_ of dependencies and
determining the most suitable versions.

As an example, we will build hypothetical Nix packages resembling
[Minecraft crafting recipes](https://minecraft.gamepedia.com/Crafting)
with versioning schemes following [semver](https://semver.org/).
Let's first try to build our first version of `pickaxe`, which is
made of wood:

```
pickaxe
  - 1.0.0
    - stick ^1.0.1
    - planks ~2.1.0
stick
  - 1.0.3
  - 1.1.2
  - 2.0.0
planks
  - 2.1.0
  - 2.1.1
  - 2.2.1
```

The first step in deciding the appropriate versions to be used to build
`pickaxe-1.0.0` is to rule out invalid versions. With that, `stick-2.0.0`
is ruled out because it is outside of the `^1.0.1` range. Similarly
`planks-2.2.1` is outside the bound for `~2.1.0`.


After filtering out the invalid versions, there are still multiple versions
of `stick` and `planks` available. As a result there can be multiple
version candidates for building `pickaxe-1.0.0`. For example, we can use
`stick-1.0.3` and `planks-2.1.1`. But are those the best versions to be used?

Depending on the dependency resolution algorithm used, we may get different
answers. Though in general, we can usually expect the algorithm to choose
the latest versions that are compatible with the required range. So we should
expect to get `stick-1.1.2` and `planks-2.1.1` as the answers.

## Nested Dependencies

In reality, dependency resolution can be more complicated because of
_nested_ dependencies. Let's say both `stick` and `planks` both depend
on `wood`:

```
stick
  - 1.0.3
    - wood ^1.5.0
  - 1.1.2
    - wood ~2.0.0

planks
  - 2.1.0
    - wood ^2.0.0
  - 2.1.1
    - wood ~2.3.0

wood
  - 1.5.0
  - 2.0.1
  - 2.3.2
```

In such case, the only solution is to use `stick-1.1.2` and `planks-2.1.0`,
because the other version combinations do not have a common `wood` version
usable by both `stick` and `planks`.

## Package Managers

Dependency resolution is a complex topic on its own. Different languages
have their own package managers that deal with dependency resolution
differently. e.g. cabal-install, npm, mvn, etc. There are also OS-level
package managers that have to deal with dependencies resolution.
e.g. Debian, Ubuntu, Fedora, Arch, etc.

To support package management across multiple languages and multiple
platforms, Nix has its own unique challenge of managing dependencies.
At this point, Nix itself do not provide any mechanism for resolving
dependencies. Instead Nix users have to come out with their own
higher level design patterns to resolve dependencies, such as in
nixpkgs.

## Package Registry

For a dependency resolution algorithm to determine what versions of
dependency to use, it must first refer to a _registry_ that contains
all versions available to all packages. Each package manager have
their own registry, e.g. Hackage, npm registry, Debian registry, etc.

Package registries are usually mutable databases that are constantly
updated. This creates an issue with _reproducibility_: the result
given back from a dependency resolution algorithm depends on
the mutable state of the registry at the time the algorithm is
executed.

In other words, say if we try to resolve the dependencies of
`pickaxe-1.0.0` today, we may get `stick-1.1.2` and `planks-2.1.0`.
But if we resolve the same dependencies tomorrow, we might get
`stick-1.1.3` because new version of `stick` is published.
To make it worse, `stick-1.1.3` may contain unexpected changes
that causes `pickaxe-1.0.0` to break.

## Version Pinning

Even without Nix, there is a strong use case to fix the pin versions
to a particular snapshot in time. This is to make sure no matter when
we try to resolve the dependencies in the future, we will always get
back the exact dependencies.

### Package Lock

One common approach is to create a lock file containing the result of
running the dependency resolution algorithm, and check in the lock file
into the version control system. Examples are `package-lock.json` and
`cabal.project.freeze`. With the lock files available, we can even
skip dependency resolution in the future, and just use the result in the
lock file.

Although lock files help provide strong reproducibility to managing
dependencies, it has the downside of adding noise to version control.
When we generate a new lock file in the future to get new dependency
versions, the new lock file may contain a lot of changes, and this
may affect the diff output when inspect the commit history.

### Registry Snapshot

An alternative approach would be to specify the snapshot of the
package registry itself. For example, cabal accepts an
`index-state` option for us to specify a timestamp of the
Hackage snapshot that it should resolve the dependencies from.
With that we can specify the timestamp of the time we first
build our dependencies, and not worry about new versions of
packages being added in the future.

Specifying the snapshot version of the registry also result in
cleaner commit logs. However there can still be other variables
that can affect the outcome. For example, the package manager
itself may update the dependency resolution algorithm, so we
may still get different results depending on the version of
package manager used.

## Upgrading Dependencies

The strategies for pinning dependencies does not eliminate the
need to resolving the plans in the first place, or the need
to upgrade or install new depedencies.

In the ideal world, we would like to be able to just specify
the dependencies we need, and have the package manager give
us the best versions that just work. But reality is messy,
and dependencies can have breaking changes all the time.

### Versioning Schemes

There are many attempts at coming up with versioning schemes
that carry breakage information with them, such as
[semver](https://semver.org/) and
[PVP](https://pvp.haskell.org/).
However they require package authors to manually follow
the rules, and rules can be broken, intentionally or not.

## Exponential Versions

In reality, each combination of dependency versions produce
a unique version of the full package that needs to be tested.
There is never just one version of `pickaxe-1.0.0`, but
exponential number of versions of `pickaxe-1.0.0` depending
on the versions of `stick`, `planks`, and their transitive
dependencies.

To make matters worse, real world software also tend to have
implicit dependencies on the runtime environment, such as
executables, shared libraries, and operating system APIs.

So for each of the versions of `pickaxe-1.0.0` with pinned
dependencies, we would also have multiple versions of that
software for different platforms, e.g. Linux, MacOS, Windows,
Android, iOS, etc. Even among these platforms, there are
also multiple releases of the platform, e.g. Debian 10,
Ubuntu 20.04, MacOS Big Sur, etc.

## Mono Versioning

Despite all these complexities, we still like to pretend
that there is only one or few versions of `pickaxe-1.0.0`
ever existed. One way to tame down this complexity is
through _mono versioning_.

### Monorepo

The simplest kind of mono versioning is by having a single repository
that contains all its components and dependencies. For each commit
in this repository, there is exactly one version each component
and dependecy. We simply ignore the possibility of other
valid combinations of component versions, and not support them.

### Lockfiles in Monorepo

Package managers such as `godep` check in the source code of dependencies
into a monorepo. However that can greatly pollute the commit history.
As an alternative, we can check in just the lockfiles into the repostory,
and have the package managers fetch them separately.

Checking in the lock file is still effectively mono-versioning the
dependencies. For each commit in the repository, we support only the
exact dependencies specified in the lockfile of that commit. We simply
pretend that no other versions of the dependencies are available.

### Mono Registry

Taking the idea to extreme, we can also freeze all dependencies in a package
registry and provide only one version of each dependency at any point in time.

This is the approach for registries such as Stackage, which guarantees that
all Haskell dependencies only have one version that always work.

Mono registry tend to work more cleanly together with monorepo. In a project,
we can specify just the snapshot version of the mono registry that we are
using, and there is no need for messy details such as generating the lockfiles
in the first place.

### Mono Environment

Nixpkgs is also a mono registry for the standard packages in Nix. For each
version of nixpkgs, there is exactly one version of packages such as `bash`,
`gcc`, etc. But since these packages used to be provided by operating
systems, we can say that nixpkgs is also providing a _mono environment_
to our software.

When we create a monorepo with pinned nixpkgs, we are not only providing
exactly one version of each dependencies, but also exactly one version
of the environment to run on.

Mono environment restricts the specification of our software so that it
does not just run on platforms such as any version of Linux or any
version of Debian 10. We just pretend that there is exact one version
of OS as specified in nixpkgs.


## Pros and Cons of Mono Versioning

There is a fundamental difference in philosophy between multi-versioning
and mono-versioning that makes it difficult for the two camps to reconcile.
At its core, there are a few factors involved.

### Stability

Mono-versioning places much higher value in stability. People in this camp
want to make sure each version of the software always work. They achieve
that by significantly limit the number of versions of the software,
and throughoutly test the software before upgrading any version.

Mono-versioning tend to put emphasis in LTS (long term support) releases,
where its components are guaranteed to not have any breaking changes
and be given years of support.

### Rapid Releases

Mono versioning tend to suffer in providing slower releases. When a
new version of component is available, it has to be tested to not
break any other component before the new version can be released.

In contrast, multi-versioning allows a new component to be released
immediately. This allows software to independently upgrade the
dependencies, at the risk of it may break on some of the software.

## Blurring the Line

There is no clear cut of whether the mono-versioning or multi-versioning
approaches are better. In practice, we tend to take a hybrid approach
in large software projects.

For example, in a company each team may have different monorepos for their
projects to manage their own dependencies. The full release of the software
suite is then a multi-versioning combination of each team's projects,
which can break during development. Finally in production, the exact
versions of each subprojects are pinned to specific versions before
deployment.

Although Nix is more suitable for mono-versioning development, some of
its features also make it easier to manage multi-versioned projects,
by building a mono "Nixified" version of the projects.
