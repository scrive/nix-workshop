# Introduction

What is Nix?

## Programming Language

- Dynamically typed - Similar semantics to JavaScript and Lisp.

- Functional programming - Higher order functions, immutability, etc.

- Lazy - Values are not evaluated until needed.

## Package Manager

- Packages as special Nix objects that produce derivations and build artifacts.

- One package can serve as build input of another package.

- Multiple versions of the "same" package can be present on the same system.

## Build System

- Packages are built from source code.

- Build artifacts of packages are cached based on content address (SHA256 checksum).

- Multi language / multi repository build system.
  - Language agnostic.
  - Construct your own build system pipeline.

## Operating System

- Nix itself is a pseudo operating system.
  - Rich set of Nix packages that can typically be found in OS packages.

- Nix packages can co-exist non-destructively with native OS packages.

  - All Nix artifacts are stored in `/nix`.

  - Global "installation" is merely a set of symlinks to Nix artifacts in
    `/nix/store`.

- Lightweight activation of global Nix packages.

  - Add `~/.nix-profile/bin/` to `$PATH`.

  - Call `source ~/.nix-profile/etc/profile.d/nix.sh` to activate Nix.

  - Otherwise Nix is almost invisible to users if it is not activated.

- NixOS is a full Linux operating system.

## Reproducibility

- Key differentiation of Nix as compared to other solutions.

- Nix packages are built inside a lightweight sandbox.

  - No containerization.

  - Sanitize all environment variables.

  - Special `$HOME` directory at `/homeless-shelter`.

  - Reset date to Unix time 0.

  - Very difficult to accidentally escape the sandbox.

- Content-addressable storage.

  - Addresses of Nix packages are based on a checksum of the source code,
    plus other factors such as CPU architecture and operating system.

  - If the checksum of the source code changes, the addresses of the derivation
    and any build artifacts also change.

  - If the address of a dependency changes, the addresses of the
    derivation and build artifact also change.