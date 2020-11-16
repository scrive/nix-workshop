# Introduction

What is Nix?

## Programming Language

- Dynamic typed - Similar semantics with JavaScript and Lisp.

- Functional programming - Higher order functions, immutability, etc.

- Lazy - Values are not evaluated until needed.

## Package Manager

- Packages as special Nix objects that produce derivations and build artifacts.

- One package can serve as build input of another package.

- Multiple versions of the "same" package can present on the same system.

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

  - Global "installation" are merely symlink to Nix artifacts in
    `/nix/store`.

- Lightweight activation of global Nix packages.

  - Add `~/.nix-profile/bin/` to `$PATH`.

  - Call `source ~/.nix-profile/etc/profile.d/nix.sh` to activate Nix.

  - Otherwise Nix is almost invisible to users if it is not activated.

- NixOS as a full Linux operating system.

## Reproducibility

- Key differentiation of Nix as compared to other solutions.

- Nix packages are built inside a lightweight sandbox.

  - No containerization.

  - Sanitize all environment variables.

  - Special `$HOME` directory at `/homeless-shelter`.

  - Reset date to Unix time 0.

  - Very difficult to accidentally escape the sandbox.

- Content addressable storage.

  - Address of Nix packages are based on checksum of source code,
    plus other factors such as CPU architecture and operating system.

  - If checksum of source code changes, the address of the derivation
    and build artifact also changes.

  - If the address of a dependency changes, the address of the
    derivation and build artifact also changes.