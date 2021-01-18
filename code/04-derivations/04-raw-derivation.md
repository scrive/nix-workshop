# Raw Derivation

We have previously used `stdenv.mkDerivation` to define toy derivations without
looking into how derivations work. Here we will go deeper into Nix derivations,
starting with the most basic derivation construct, `builtins.derivation`.

From the repl, we can see that `builtins.derivation` is a function:

```nix
nix-repl> builtins.derivation
«lambda @ /nix/store/qxayqjmlpqnmwg5yfsjjayw220ls8i2r-nix-2.3.8/share/nix/corepkgs/derivation.nix:4:1»
```

Since `builtins.derviation` is more primitive as compared to `stdenv.mkDerivation`,
the way we can build a derivation is also more involved:

```nix
nix-repl> builtins.derivation {
            name = "hello";
            system = builtins.currentSystem;
            builder = "${nixpkgs.bash}/bin/bash";
            args = [
              "-c"
              ''
              echo "Hello World!" > $out
              ''
            ];
          }
«derivation /nix/store/hbsv13kn5imfri16f6g2l5c2jy6dfmxl-hello.drv»
```

### System

First we have to supply a `system` attribute, which we set it to
the current OS we are running on. It is most common to have the
system values as `"x86_64-linux"` or `"x86_64-darwin"`.

```nix
nix-repl> builtins.currentSystem
"x86_64-linux"
```

The `system` attribute is required because Nix supports cross compilation.
So we can also define derivations that are built on different platforms
than the one we are on.

### Builder

The `builder` attribute expects a file path to an executable script that is
called when the derivation is built. To keep things simple, we use the bash
shell from `nixpkgs.bash` as the builder program.

The `args` attribute is used to specify the command line line arguments
passed to the builder program. Since bash itself do not know how to
build the program we want, we pass the command string using `-c`
to execute the bash script `echo "Hello World!" > $out`

Now we can try to build the derivation and see that it works:

```bash
$ nix-build /nix/store/hbsv13kn5imfri16f6g2l5c2jy6dfmxl-hello.drv
these derivations will be built:
  /nix/store/hbsv13kn5imfri16f6g2l5c2jy6dfmxl-hello.drv
building '/nix/store/hbsv13kn5imfri16f6g2l5c2jy6dfmxl-hello.drv'...
/nix/store/dsgf85gxzw167v320sy08as72c0hk8wd-hello

$ cat /nix/store/dsgf85gxzw167v320sy08as72c0hk8wd-hello
Hello World!
```

## Explicit Dependencies

Inside `builtins.derivation`, almost all dependencies have to be provided
explicitly, even the bash shell that we are running on. Since we specify
`bash` as the builder program, it is also shown in the list of `inputDrvs`
of our derivation.

```bash
$ nix show-derivation /nix/store/hbsv13kn5imfri16f6g2l5c2jy6dfmxl-hello.drv
{
  "/nix/store/hbsv13kn5imfri16f6g2l5c2jy6dfmxl-hello.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/dsgf85gxzw167v320sy08as72c0hk8wd-hello"
      }
    },
    "inputSrcs": [],
    "inputDrvs": {
      "/nix/store/l54djrh1n7d8zdfn26w7v6zjh5wp7faa-bash-4.4-p23.drv": [
        "out"
      ]
    },
    "platform": "x86_64-linux",
    "builder": "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash",
    "args": [
      "-c",
      "echo \"Hello World!\" > $out\n"
    ],
    "env": {
      "builder": "/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash",
      "name": "hello",
      "out": "/nix/store/dsgf85gxzw167v320sy08as72c0hk8wd-hello",
      "system": "x86_64-linux"
    }
  }
}

```

## Inspecting the Build Environment

We can use the `env` command to inspect the environment variables inside our build script.
Let's try and build a derivation that prints the environment to the terminal.

```nix
nix-repl> builtins.derivation {
            name = "env";
            system = builtins.currentSystem;
            builder = "${nixpkgs.bash}/bin/bash";
            args = [
              "-c"
              ''
                set -x
                ls -la .
                ls -la /
                env
                touch $out
              ''
            ];
          }
«derivation /nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv»
```

```bash
$ nix-build /nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv
+ nix-build /nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv
these derivations will be built:
  /nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv
building '/nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv'...
+ ls -la .
bash: line 1: ls: command not found
+ ls -la /
bash: line 2: ls: command not found
+ env
bash: line 3: env: command not found
+ touch /nix/store/blcl4m2vgga6i86kh13nqlvx1l2ha7v5-env
bash: line 4: touch: command not found
builder for '/nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv' failed with exit code 127
error: build of '/nix/store/4nq2kgcmryhwjh5sg05jgwsd4ixh81ia-env.drv' failed
```

Not good, with `builtins.derivation`, not even basic commands like `ls`, `env`, and `touch`
are provided. (As seen previously, `echo` is provided though)

Instead, we also have to specify our build dependencies explicitly with `nixpkgs.coreutils`
providing the basic shell commands:


```nix
nix-repl> builtins.derivation {
            name = "env";
            system = builtins.currentSystem;
            builder = "${nixpkgs.bash}/bin/bash";
            args = [
              "-c"
              ''
                set -x
                ${nixpkgs.coreutils}/bin/ls -la .
                ${nixpkgs.coreutils}/bin/ls -la /
                ${nixpkgs.coreutils}/bin/env
                ${nixpkgs.coreutils}/bin/touch $out
              ''
            ];
          }
«derivation /nix/store/c4bp5bvx73fz9jf1si64i00as30k9fga-env.drv»
```

```bash
$ nix-build /nix/store/c4bp5bvx73fz9jf1si64i00as30k9fga-env.drv
these derivations will be built:
  /nix/store/c4bp5bvx73fz9jf1si64i00as30k9fga-env.drv
building '/nix/store/c4bp5bvx73fz9jf1si64i00as30k9fga-env.drv'...
+ /nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/ls -la .
total 8
drwx------ 2 nixbld nixbld 4096 Nov 30 19:09 .
drwxr-x--- 9 nixbld nixbld 4096 Nov 30 19:09 ..
+ /nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/ls -la /
total 32
drwxr-x---   9 nixbld nixbld  4096 Nov 30 19:09 .
drwxr-x---   9 nixbld nixbld  4096 Nov 30 19:09 ..
drwxr-xr-x   2 nixbld nixbld  4096 Nov 30 19:09 bin
drwx------   2 nixbld nixbld  4096 Nov 30 19:09 build
drwxr-xr-x   4 nixbld nixbld  4096 Nov 30 19:09 dev
drwxr-xr-x   2 nixbld nixbld  4096 Nov 30 19:09 etc
drwxr-xr-x   3 nixbld nixbld  4096 Nov 30 19:09 nix
dr-xr-xr-x 410 nobody nogroup    0 Nov 30 19:09 proc
drwxrwxrwt   2 nixbld nixbld  4096 Nov 30 19:09 tmp
+ /nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/env
out=/nix/store/3rv14i75j4wyp6n9fila5rll4f99yksi-env
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
NIX_LOG_FD=2
system=x86_64-linux
PWD=/build
HOME=/homeless-shelter
TMP=/build
NIX_STORE=/nix/store
TMPDIR=/build
name=env
TERM=xterm-256color
TEMPDIR=/build
SHLVL=1
NIX_BUILD_CORES=8
TEMP=/build
PATH=/path-not-set
NIX_BUILD_TOP=/build
_=/nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/env
+ /nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/touch /nix/store/3rv14i75j4wyp6n9fila5rll4f99yksi-env
/nix/store/3rv14i75j4wyp6n9fila5rll4f99yksi-env
```

### Nix Sandbox

From above we can see that the build environment inside a Nix build script
is _sandboxed_.

According to
[Nix manual](https://nixos.org/manual/nix/unstable/command-ref/conf-file.html):

> If set to true, builds will be performed in a sandboxed environment, i.e., they’re isolated from the normal file system hierarchy and will only see their dependencies in the Nix store, the temporary build directory, private versions of /proc, /dev, /dev/shm and /dev/pts (on Linux), and the paths configured with the sandbox-paths option. This is useful to prevent undeclared dependencies on files in directories such as /usr/bin. In addition, on Linux, builds run in private PID, mount, network, IPC and UTS namespaces to isolate them from other processes in the system (except that fixed-output derivations do not run in private network namespace to ensure they can access the network).

Nix sandbox should be enabled by default. You can check your sandbox configuration with:

```bash
$ nix show-config | grep sandbox
extra-sandbox-paths =
sandbox = true
sandbox-build-dir = /build
sandbox-dev-shm-size = 50%
sandbox-fallback = true
sandbox-paths = /bin/sh=/nix/store/w0xp1k96c1dvmx6m4wl1569cdzy47w5r-busybox-1.31.1-x86_64-unknown-linux-musl/bin/busybox
```

## Capturing Build Environment

We can capture the build environment as a file by saving the output of `env` to `$out`.

```nix
nix-repl> builtins.derivation {
            name = "env";
            system = builtins.currentSystem;
            builder = "${nixpkgs.bash}/bin/bash";
            args = [
              "-c"
              "${nixpkgs.coreutils}/bin/env > $out"
            ];
          }
«derivation /nix/store/39ah25v6iwlka3jl2angxrlx00mk2ijd-env.drv»
```

```bash
$ nix-build /nix/store/39ah25v6iwlka3jl2angxrlx00mk2ijd-env.drv
these derivations will be built:
  /nix/store/39ah25v6iwlka3jl2angxrlx00mk2ijd-env.drv
building '/nix/store/39ah25v6iwlka3jl2angxrlx00mk2ijd-env.drv'...
/nix/store/6kjgg8j3y44g1ja95swqdd1v8xp6mwi1-env

$ cat /nix/store/6kjgg8j3y44g1ja95swqdd1v8xp6mwi1-env
out=/nix/store/6kjgg8j3y44g1ja95swqdd1v8xp6mwi1-env
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
NIX_LOG_FD=2
system=x86_64-linux
PWD=/build
HOME=/homeless-shelter
TMP=/build
NIX_STORE=/nix/store
TMPDIR=/build
name=env
TERM=xterm-256color
TEMPDIR=/build
SHLVL=1
NIX_BUILD_CORES=8
TEMP=/build
PATH=/path-not-set
NIX_BUILD_TOP=/build
_=/nix/store/2shqhfsyzz4rnfyysbzgyp5kbfk29750-coreutils-8.32/bin/env
```


## Nix Shell

Nix achieves reproducible build by carefully setting/unsetting the appropriate
environment variables, so that our derivations are always built with the same
environment regardless of where it is being built.

However since the derivation is built in a sandboxed environment, it may be difficult
to debug when there are build errors, or rapid prototyping with the source code
changed frequently.

We can get almost the same environment as inside nix build by entering a _Nix shell_.

```
$ nix-shell --pure --run env /nix/store/39ah25v6iwlka3jl2angxrlx00mk2ijd-env.drv
__ETC_PROFILE_SOURCED=1
DISPLAY=:1
out=/nix/store/6kjgg8j3y44g1ja95swqdd1v8xp6mwi1-env
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
USER=user
system=x86_64-linux
PWD=/path/to/nix-workshop
HOME=/home/user
TMP=/run/user/1000
NIX_STORE=/nix/store
TMPDIR=/run/user/1000
name=env
IN_NIX_SHELL=pure
TERM=xterm-256color
TEMPDIR=/run/user/1000
SHLVL=3
NIX_BUILD_CORES=8
TEMP=/run/user/1000
LOGNAME=user
PATH=/nix/store/lf467z8nr5y50q1vqnlbhpv2jachx3cs-bash-interactive-4.4-p23/bin:/home/user/.nix-profile/bin:...
NIX_BUILD_TOP=/run/user/1000
_=/usr/bin/env
```

Our pure Nix environment look pretty similar to the environment we captured in `nix-build`.
There are however a few differences, in particular with `$PATH`.

[According the manual](https://nixos.org/manual/nix/unstable/command-ref/nix-shell.html)
for the `--pure` option in `nix-shell`:

> If this flag is specified, the environment is almost entirely cleared before the interactive shell is started, so you get an environment that more closely corresponds to the “real” Nix build. A few variables, in particular `HOME`, `USER` and `DISPLAY`, are retained. Note that (depending on your Bash installation) `/etc/bashrc` is still sourced, so any variables set there will affect the interactive shell.

We can compare the differences by diffing the output of both environments:

```bash
$ drv=/nix/store/39ah25v6iwlka3jl2angxrlx00mk2ijd-env.drv
$ diff --color <(cat $(nix-build $drv)) <(nix-shell $drv --pure --run env)
```

In contrast, the default impure Nix shell keeps all existing environment variables, and only
add or override variables that are introduced by the derivation.

```bash
$ nix-shell $drv --run env
```


## Environment Variables

If we observe the captured build environment, almost all attributes we passed to
`builtins.derivation` are converted into environment variables.

In fact, we can define any number of attributes to be used as environment variables
inside our build script.

```nix
nix-repl> builtins.derivation {
            name = "foo";
            foo = "foo val";
            system = builtins.currentSystem;
            builder = "${nixpkgs.bash}/bin/bash";
            args = [
              "-c"
              "echo $foo > $out"
            ];
          }
«derivation /nix/store/v1i0khcvxy5bkyv2iq0kqzhcbfcfml8m-foo.drv»
```

We can see from the build output that the value of `$foo` is in fact
captured.

```bash
$ nix-build /nix/store/v1i0khcvxy5bkyv2iq0kqzhcbfcfml8m-foo.drv
these derivations will be built:
  /nix/store/v1i0khcvxy5bkyv2iq0kqzhcbfcfml8m-foo.drv
building '/nix/store/v1i0khcvxy5bkyv2iq0kqzhcbfcfml8m-foo.drv'...
/nix/store/zmgp33rl2sh3l32syhq4h8gph3f4s1k9-foo

$ cat /nix/store/zmgp33rl2sh3l32syhq4h8gph3f4s1k9-foo
foo val
```

We can also get the same `$foo` variable set when entering Nix shell:

```bash
$ nix-shell --pure --run 'echo $foo' /nix/store/v1i0khcvxy5bkyv2iq0kqzhcbfcfml8m-foo.drv
foo val
```


## Setting Dependencies as Variables

We can set out dependencies as custom attributes in a derivation
and then refer to them as environment variables during the build.

For example, we can add the `greet` package we defined earlier
and set it as `$greet` in the shell.

```nix
nix-repl> greet = import ./04-derivations/02-dependencies/greet.nix

nix-repl> builtins.derivation {
            inherit greet;
            name = "greet-alice";
            system = builtins.currentSystem;
            builder = "${nixpkgs.bash}/bin/bash";
            args = [
              "-c"
              "$greet/bin/greet Alice > $out"
            ];
          }
«derivation /nix/store/68gdf6z0rjcyl8xcwix3gfafndsa50jj-greet-alice.drv»
```

```bash
$ nix-build /nix/store/68gdf6z0rjcyl8xcwix3gfafndsa50jj-greet-alice.drv
these derivations will be built:
  /nix/store/68gdf6z0rjcyl8xcwix3gfafndsa50jj-greet-alice.drv
building '/nix/store/68gdf6z0rjcyl8xcwix3gfafndsa50jj-greet-alice.drv'...
/nix/store/dd290zmn983fs1w33nnq9gyh3cnj2jif-greet-alice

$ cat /nix/store/dd290zmn983fs1w33nnq9gyh3cnj2jif-greet-alice
Hello, Alice!
```