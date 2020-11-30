# Standard Derivation

`builtins.derivation` provides the minimal functionality to define a Nix
derivation. However all dependencies have to be manually managed, which
can be pretty cumbersome. In practice, most Nix derivations are built
on top of `stdenv.mkDerivation`, which provide many battery-included
functionalities that helps make defining derivations easy.

The tradeoff is that `stdenv.mkDerivation` is much more complex than
`builtins.derivation`. With the detour to understand
`builtins.derivation` first, we can hopefully have an easier time
understanding `stdenv.mkDerivation`


## Inspecting Build Environment

We can inspect the standard environment in similar way.

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "inspect";
            unpackPhase = "true";

            buildPhase = ''
              set -x
              ls -la .
              ls -la /
              env
              set +x
            '';

            installPhase = "touch $out";
          }
«derivation /nix/store/vdyp9cxs0li87app03vm8zbxmq0lhw5l-inspect.drv»
```

```bash
$ nix-build /nix/store/vdyp9cxs0li87app03vm8zbxmq0lhw5l-inspect.drv
these derivations will be built:
  /nix/store/vdyp9cxs0li87app03vm8zbxmq0lhw5l-inspect.drv
building '/nix/store/vdyp9cxs0li87app03vm8zbxmq0lhw5l-inspect.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
++ ls -la .
total 16
drwx------ 2 nixbld nixbld 4096 Nov 30 19:42 .
drwxr-x--- 9 nixbld nixbld 4096 Nov 30 19:42 ..
-rw-r--r-- 1 nixbld nixbld 5013 Nov 30 19:42 env-vars
++ ls -la /
total 32
drwxr-x---   9 nixbld nixbld  4096 Nov 30 19:42 .
drwxr-x---   9 nixbld nixbld  4096 Nov 30 19:42 ..
drwxr-xr-x   2 nixbld nixbld  4096 Nov 30 19:42 bin
drwx------   2 nixbld nixbld  4096 Nov 30 19:42 build
drwxr-xr-x   4 nixbld nixbld  4096 Nov 30 19:42 dev
drwxr-xr-x   2 nixbld nixbld  4096 Nov 30 19:42 etc
drwxr-xr-x   3 nixbld nixbld  4096 Nov 30 19:42 nix
dr-xr-xr-x 405 nobody nogroup    0 Nov 30 19:42 proc
drwxrwxrwt   2 nixbld nixbld  4096 Nov 30 19:42 tmp
++ env
...
unpackPhase=true
propagatedBuildInputs=
stdenv=/nix/store/ajq5dfwn4hzlx1qf2xxwb6rj8a7s65nm-stdenv-linux
TZ=UTC
OLDPWD=/build
out=/nix/store/a226brzfy71vr6vkfy4m188qs9f7k7g7-inspect
CONFIG_SHELL=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
buildInputs=
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
...
buildPhase=set -x
ls -la .
ls -la /
env
set +x

PATH=/nix/store/cr86kfhzfwa558mzav4rnfkbz00hw27w-patchelf-0.12/bin:/nix/store/ppfvi0cfcpdr83klw5kx6si2l260n1gh-gcc-wrapper-9.3.0/bin:...
NIX_BUILD_TOP=/build
depsBuildTargetPropagated=
NIX_ENFORCE_PURITY=1
SIZE=size
nativeBuildInputs=
LD=ld
patches=
depsTargetTargetPropagated=
_=/nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/env
++ set +x
installing
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/a226brzfy71vr6vkfy4m188qs9f7k7g7-inspect
strip is /nix/store/bnjps68g8ax6abzvys2xpx12imrx8949-binutils-2.31.1/bin/strip
patching script interpreter paths in /nix/store/a226brzfy71vr6vkfy4m188qs9f7k7g7-inspect
checking for references to /build/ in /nix/store/a226brzfy71vr6vkfy4m188qs9f7k7g7-inspect...
/nix/store/a226brzfy71vr6vkfy4m188qs9f7k7g7-inspect
```

As we can see, our standard environment is quite more complicated than the minimal environment
provided by `builtins.derivation`. We also have a number of executables added to `$PATH`,
which we can use without specifying them as dependencies.

## Capturing the Build Environment

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "env";
            unpackPhase = "true";
            installPhase = "env > $out";
          }
«derivation /nix/store/5rgcvwndbc4525ypbb0r1vgqpbxgcy2g-env.drv»
```

```bash
$ cat $(nix-build /nix/store/5rgcvwndbc4525ypbb0r1vgqpbxgcy2g-env.drv)
...
unpackPhase=true
propagatedBuildInputs=
stdenv=/nix/store/ajq5dfwn4hzlx1qf2xxwb6rj8a7s65nm-stdenv-linux
TZ=UTC
OLDPWD=/build
out=/nix/store/rkjhcjhdj6ba7r7n7fasq8gmzxi5hk72-env
CONFIG_SHELL=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
buildInputs=
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
...
```

## Build Inputs

`stdenv.mkDerivation` also provides a convenient way of adding dependencies
to appropriate environment variables with the `buildInputs` attribute.

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "greet-alice";
            buildInputs = [ greet ];

            unpackPhase = "true";
            installPhase = "greet Alice > $out";
          }
«derivation /nix/store/in40c5fl13ziqzds3wfg2ag7ax2xmq5l-greet-alice.drv»
```

```bash
$ nix-build /nix/store/in40c5fl13ziqzds3wfg2ag7ax2xmq5l-greet-alice.drv
these derivations will be built:
  /nix/store/in40c5fl13ziqzds3wfg2ag7ax2xmq5l-greet-alice.drv
building '/nix/store/in40c5fl13ziqzds3wfg2ag7ax2xmq5l-greet-alice.drv'...
...
/nix/store/kp32rzq63barqa55q3mf761gsggi2bq6-greet-alice

$ cat /nix/store/kp32rzq63barqa55q3mf761gsggi2bq6-greet-alice
Hello, Alice!
```

We can check that `greet` is added to `$PATH` using Nix shell:

```bash
$ drv=/nix/store/in40c5fl13ziqzds3wfg2ag7ax2xmq5l-greet-alice.drv

$ nix-shell $drv --pure --run "command -v greet"
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin/greet

$ nix-shell $drv --pure --run 'echo $PATH' | tr ':' '\n'
...
/nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin
...
```

`stdenv` also adds the build inputs to other variables.

```
$ nix-shell $drv --pure --run 'echo $NIX_LDFLAGS'
-rpath /nix/store/kp32rzq63barqa55q3mf761gsggi2bq6-greet-alice/lib64 -rpath /nix/store/kp32rzq63barqa55q3mf761gsggi2bq6-greet-alice/lib
```

Note that the paths /nix/store/kp32rzq63barqa55q3mf761gsggi2bq6-greet-alice/lib
does not exist, but `stdenv` still sets the variables anyway.

## Stdenv Script

How do `stdenv.mkDerivation` do the magic compared to `builtins.derivation`?
We can find out by first inspecting the derivation:

```bash
$ nix show-derivation $drv
{
  "/nix/store/in40c5fl13ziqzds3wfg2ag7ax2xmq5l-greet-alice.drv": {
    ...
    "builder": "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash",
    "args": [
      "-e",
      "/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"
    ],
    "env": {
      "buildInputs": "/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet",
      "builder": "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash",
      ...
      "installPhase": "greet Alice > $out",
      "name": "greet-alice",
      ...
      "stdenv": "/nix/store/ajq5dfwn4hzlx1qf2xxwb6rj8a7s65nm-stdenv-linux",
      ...
    }

  }
}
```

`stdenv` is also using `bash` as the builder, and have it evaluate the
script at `/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh`.
Let's see what's inside there:

```
$ cat /nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh
source $stdenv/setup
genericBuild
```

So the magic is hidden inside `$stdenv/setup`, with the `$stdenv`
variable set to `/nix/store/ajq5dfwn4hzlx1qf2xxwb6rj8a7s65nm-stdenv-linux`.

We can open it and see what's inside.

```bash
nix-shell $drv --run 'cat $stdenv/setup'
```

There are quite a lot of shell scripts happening. If we search through the script,
we can see that environment variables such as `buildInputs`, `buildPhase`, and
`installPhase` are being referred inside `$stdenv/setup`.

In other words, instead of having to figure how to setup various environment
variables to work with various dependencies, `$stdenv/setup` provides a higher
level abstraction of doing the setup for us. We just have to define
the build inputs and steps that we need, and `$stdenv/setup` will fill
in the missing pieces from us.


In fact, `$stdenv/setup` is also being sourced when we enter a Nix shell of a
`stdenv` derivation.
From the [nix-shell manual](https://nixos.org/manual/nix/unstable/command-ref/nix-shell.html):

> The command nix-shell will build the dependencies of the specified derivation, but not the derivation itself. It will then start an interactive shell in which all environment variables defined by the derivation path have been set to their corresponding values, and the script $stdenv/setup has been sourced. This is useful for reproducing the environment of a derivation for development.

## Deriving Environment at Build Time

One question we might ask is, why is `stdenv` doing the heavyweight steps only
at build time inside a shell script. We could as well parse the dependencies
inside Nix at evaluation time, and produce a derivation with everything
setup already.

However recall from the [previous example](./03-fibonacci.md) of
`fib-serialized.nix`. If we try to peek into the content of a dependency derivation,
that would instead become an evaluation time dependency. If `stdenv` is
looking into the content of all dependencies inside Nix, then we can
only know how to build the derivation after all dependencies have been built.

Instead, `stdenv` avoids this to allow the derivation dependencies to
be built in parallel by Nix. With that, we can only read the content
of our dependencies at build time, which happens inside the build script.