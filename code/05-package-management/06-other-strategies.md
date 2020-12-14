# Other Package Management Strategies

So far we have covered two approaches to managing dependencies in Nix.
Nixpkgs takes a mono-versioning approach by providing exactly one version
of each package in a particular version of nixpkgs. In contrast, Haskell.nix
captures the entire Hackage snapshot and uses Cabal to resolve the
dependencies with the plan derivation being an evaluation-time Nix dependency.

However these two are not the only approaches to managing dependencies
in Nix. In fact, other languages like Node.js and Rust have come out with
an alternative approach, which is much closer to generating traditional
package lock files.

## Size of Package Registry

Compared to mainstream languages like Node.js, the Haskell ecosystem is much
smaller and has much less packages available. Despite that, the state
of the Hackage registry is pretty large, taking over 100 MiB after compression.

Capturing the entire state of the package registry is obviously not scaleable.
If the Haskell ecosystem were to grow to the size of Node.js, not only
the nixpkgs and Haskell packages in nixpkgs have to be re-architected,
but also Cabal itself has to come up with better ways of managing dependencies.

Compared to Cabal, package managers like npm and cargo do not simply download
the entire state of the package registries. Instead, the package registries
provide APIs for the package managers to query the available versions of
specific packages. This way, the local package managers only have to query
the relevant packages they need, and ignore the rest of the packages exist
in the registry.

This approach has the advantage of significantly reducing the bandwidth
required to compute the dependency graph. However since it requires network
communication, this cannot be used inside a Nix build. After all, there
is no way Nix can know if a package registry always give back the same
answer given the same set of queries.

## Generating Nix Plans

Languages like Node.js and Rust come out with tools like
[node2nix](https://github.com/svanderburg/node2nix) and
[cargo2nix](https://github.com/cargo2nix/cargo2nix) to
convert the dependency resolution results directly into Nix expressions.

For these tools to work, they has to run outside of a Nix build to query
the package registry, and then generate the Nix expressions. Typically,
the Nix expressions are also derived directly from the lock files such as
`package-lock.json` and `Cargo.lock`.

The generated Nix expressions directly construct the dependency graph
required to build a Node.js or Rust project. When `nix-build` is called,
Nix can then easily use the dependency graph to download and build the
dependencies concurrently.

## Similar Approach In Haskell

While there is a similarly named
[cabal2nix](https://github.com/NixOS/cabal2nix) command for Haskell,
that is actually tied to the mono-versioning approach of nixpkgs.
As a result, cabal2nix never computes any dependency graph, but
instead simply generates a Nix expression that ask for the dependencies
from nixpkgs.

There is no reason why Haskell cannot adopt similar approaches as
node2nix or cargo2nix. It might be possible that such approaches are
more difficult to achieve, due to how Cabal and Hackage index works.
But that should not be an excuse to stop us from trying.

Whether to use Nix or not, if we want Haskell to gain wider adoption,
then the package manager Cabal needs
[significant improvement](https://mail.haskell.org/pipermail/hf-discuss/2020-December/000003.html)
to be made. We need to improve Cabal to not just have better integrations
with tools like Nix and IDEs, but also make it much easier for users to
use.
