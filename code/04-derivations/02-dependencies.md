# Dependencies

Previously we have built toy derivations with dummy output. In practice,
Nix derivations are used for building programs, with build artifacts such as
compiled binaries being the derivation output.

We can demonstrate this property by "building" a greet program.
First we have to import a pinned version of nixpkgs as before.
To simplify the process we abstract it out into a [nixpkgs.nix](../nixpkgs.nix)
at the root directory.

Now we build a greet program in [greet.nix](./02-dependencies/greet.nix):

```nix
{{#include ./02-dependencies/greet.nix}}
```

```bash
$ nix-build 04-derivations/02-dependencies/greet.nix
these derivations will be built:
  /nix/store/97lmyym0isl0ism7pfnv1b0ls4cahpi8-greet.drv
building '/nix/store/97lmyym0isl0ism7pfnv1b0ls4cahpi8-greet.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
building greet...
installing
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
strip is /nix/store/bnjps68g8ax6abzvys2xpx12imrx8949-binutils-2.31.1/bin/strip
stripping (with command strip and flags -S) in /nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin
patching script interpreter paths in /nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin/greet: interpreter directive changed from "/usr/bin/env bash" to "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash"
checking for references to /build/ in /nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet...
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
```

Now we can run greet:

```bash
$ result/bin/greet John
Hello, John!
```

Let's try to see what's inside the produced `greet` script:

```bash
$ cat result/bin/greet
#!/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
echo "Hello, $1!"
```

The shebang to the bash shell has been modified to pin to the Nix version of Bash.

## Upper Greet

Our greet program can now be used as a dependency to other derivations.
Let's create an `upper-greet` derivation that convert any greet result to
upper case.

[upper-greet.nix](./02-dependencies/upper-greet.nix):

```nix
{{#include ./02-dependencies/upper-greet.nix}}
```

```bash
$ nix-build 04-derivations/02-dependencies/upper-greet.nix
these derivations will be built:
  /nix/store/n61g8616l7g7zv32q52yrzmzr850mjp0-upper-greet.drv
building '/nix/store/n61g8616l7g7zv32q52yrzmzr850mjp0-upper-greet.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
building upper-greet...
installing
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
strip is /nix/store/bnjps68g8ax6abzvys2xpx12imrx8949-binutils-2.31.1/bin/strip
stripping (with command strip and flags -S) in /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet/bin
patching script interpreter paths in /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
/nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet/bin/upper-greet: interpreter directive changed from "/usr/bin/env bash" to "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash"
checking for references to /build/ in /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet...
/nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
```

As expected, the greet results are turned into upper case.

```bash
$ result/bin/upper-greet John
HELLO, JOHN!
```

The absolute paths to `greet` and `coreutils` are extended:

```bash
$ cat result/bin/upper-greet
#!/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin/greet "$@" | /nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/tr [a-z] [A-Z]
```

If we query the dependency of the built `upper-greet` (not the derivation),
we can see that `greet` is still a _runtime_ dependency of `upper-greet`.

```bash
$ nix-store -qR /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
/nix/store/hfpiccrc1wsqv9p09mb2ddkakpg09bh4-libunistring-0.9.10
/nix/store/7bpq6jhxdans9csm7brrdj0qg8bk0m8v-libidn2-2.3.0
/nix/store/kah5n342wz4i0s9lz9ka4bgz91xa2i94-glibc-2.32
/nix/store/gyfqw8k2ibhn6mcka9mcd7wcmq14cnmm-attr-2.4.48
/nix/store/fg73gb66fnzlv9b9kc1bn1zvdq6w2dn4-acl-2.2.53
/nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32
/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
/nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
```