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

### Show Derivation

First we instantiate `upper-greet.drv` without building it yet:

```bash
drv=$(nix-instantiate 04-derivations/02-dependencies/upper-greet.nix)
```

We can use `nix show-derivation` to find out the dependency graph of the
derivation of `upper-greet`:

```bash
$ nix show-derivation $drv
{
  "/nix/store/n61g8616l7g7zv32q52yrzmzr850mjp0-upper-greet.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet"
      }
    },
    "inputSrcs": [
      "/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"
    ],
    "inputDrvs": {
      "/nix/store/7gby8zic1p851ap63q1vdpwy7z1db85c-coreutils-8.32.drv": [
        "out"
      ],
      "/nix/store/97lmyym0isl0ism7pfnv1b0ls4cahpi8-greet.drv": [
        "out"
      ],
      "/nix/store/l54djrh1n7d8zdfn26w7v6zjh5wp7faa-bash-4.4-p23.drv": [
        "out"
      ],
      "/nix/store/x9why09hwx2pcnmw0fw7hhh1511hyskl-stdenv-linux.drv": [
        "out"
      ]
    },
    ...
    "env": {
      "buildInputs": "",
      "buildPhase": "echo \"building upper-greet...\"\nsleep 3\n",
      "builder": "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash",
      ...
      "installPhase": "mkdir -p $out/bin\n\ncat <<'EOF' > $out/bin/upper-greet\n#!/usr/bin/env bash\n/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin/greet \"$@\" | /nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/tr [a-z] [A-Z]\nEOF\n\nchmod +x $out/bin/upper-greet\n",
      "name": "upper-greet",
...
```

We can see that `greet.drv` is included as one of `inputDrvs`. This means that when
`upper-greet.drv` is being built, `greet.drv` will have to be built first.

The output path of `upper-greet.drv` is listed in `outputs`. This shows that
the output hash of a derivation is fixed, regardless of the content of the
build result.

This is also why the output path of `greet.drv` is used directly in `env.installPhase`
of `upper-greet.drv`, even for the case when `greet.drv` has not been built.

### Build Derivation


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

### Runtime Dependency

If we query the references of the `upper-greet` output (not the derivation),
we can see that `greet` is still a _runtime_ dependency of `upper-greet`.

```bash
$ nix-store --query --references /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
/nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32
/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
```

We can use `nix why-depends` to find out why Nix thinks `greet` is a runtime
dependency to `upper-greet`:

```bash
$ nix why-depends /nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet /nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
/nix/store/dj2vp64gbja0bp65lngrw9q4lrm1a8r3-upper-greet
╚═══bin/upper-greet: …ash-4.4-p23/bin/bash./nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin/greet "$@" | /nix/sto…
    => /nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
```