# Build Environment


## Inspecting Build Environment

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "inspect";
            unpackPhase = "true";

            buildPhase = ''
              set -x
              env
              whoami
              echo $HOME
              ls -la /
              set +x
            '';

            installPhase = ''
              mkdir -p $out
            '';
          }
«derivation /nix/store/lshnm68rsynbpn3pkrrlfjr34m8s9kp6-inspect.drv»
```

```bash
$ nix-build /nix/store/lshnm68rsynbpn3pkrrlfjr34m8s9kp6-inspect.drv
these derivations will be built:
  /nix/store/lshnm68rsynbpn3pkrrlfjr34m8s9kp6-inspect.drv
building '/nix/store/lshnm68rsynbpn3pkrrlfjr34m8s9kp6-inspect.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
++ env
...
unpackPhase=true
propagatedBuildInputs=
stdenv=/nix/store/ajq5dfwn4hzlx1qf2xxwb6rj8a7s65nm-stdenv-linux
TZ=UTC
OLDPWD=/build
out=/nix/store/0vl5qkgk0xq2pfh5yihbz66lqs8lads1-inspect
CONFIG_SHELL=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
buildInputs=
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
...
++ whoami
nixbld
++ echo /homeless-shelter
/homeless-shelter
++ ls -la /
total 32
drwxr-x---   9 nixbld nixbld  4096 Nov 23 18:21 .
drwxr-x---   9 nixbld nixbld  4096 Nov 23 18:21 ..
drwxr-xr-x   2 nixbld nixbld  4096 Nov 23 18:21 bin
drwx------   2 nixbld nixbld  4096 Nov 23 18:21 build
drwxr-xr-x   4 nixbld nixbld  4096 Nov 23 18:21 dev
drwxr-xr-x   2 nixbld nixbld  4096 Nov 23 18:21 etc
drwxr-xr-x   3 nixbld nixbld  4096 Nov 23 18:21 nix
dr-xr-xr-x 469 nobody nogroup    0 Nov 23 18:21 proc
drwxrwxrwt   2 nixbld nixbld  4096 Nov 23 18:21 tmp
...
/nix/store/0vl5qkgk0xq2pfh5yihbz66lqs8lads1-inspect
```

## Nix Sandbox

[Nix manual](https://nixos.org/manual/nix/unstable/command-ref/conf-file.html):

> If set to true, builds will be performed in a sandboxed environment, i.e., they’re isolated from the normal file system hierarchy and will only see their dependencies in the Nix store, the temporary build directory, private versions of /proc, /dev, /dev/shm and /dev/pts (on Linux), and the paths configured with the sandbox-paths option. This is useful to prevent undeclared dependencies on files in directories such as /usr/bin. In addition, on Linux, builds run in private PID, mount, network, IPC and UTS namespaces to isolate them from other processes in the system (except that fixed-output derivations do not run in private network namespace to ensure they can access the network).

```bash
$ nix show-config | grep sandbox
extra-sandbox-paths =
sandbox = true
sandbox-build-dir = /build
sandbox-dev-shm-size = 50%
sandbox-fallback = true
sandbox-paths = /bin/sh=/nix/store/w0xp1k96c1dvmx6m4wl1569cdzy47w5r-busybox-1.31.1-x86_64-unknown-linux-musl/bin/busybox
```

## Nix Shell

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "env";
            unpackPhase = "true";
            installPhase = ''
              env > $out
            '';
          }
«derivation /nix/store/msg52lvxnrbwsrwnxw69amr1plj9fmfd-env.drv»
```

```bash
$ drv=/nix/store/msg52lvxnrbwsrwnxw69amr1plj9fmfd-env.drv
$ cat $(nix-build $drv)
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

```bash
$ nix-shell --pure $drv --run env
...
unpackPhase=true
propagatedBuildInputs=
stdenv=/nix/store/ajq5dfwn4hzlx1qf2xxwb6rj8a7s65nm-stdenv-linux
__ETC_PROFILE_SOURCED=1
DISPLAY=:1
out=/nix/store/rkjhcjhdj6ba7r7n7fasq8gmzxi5hk72-env
CONFIG_SHELL=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
buildInputs=
builder=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
...
```


```bash
$ diff --color=always <(cat $(nix-build $drv)) <(nix-shell $drv --pure --run env)
5,6c5,6
< TZ=UTC
< OLDPWD=/build
---
> __ETC_PROFILE_SOURCED=1
> DISPLAY=:1
12a13
> USER=user
17d17
< NIX_LOG_FD=2
21,23c21,23
< PWD=/build
< HOME=/homeless-shelter
< TMP=/build
---
> PWD=/path/to/scrive/nix-workshop/code
> HOME=/home/user
> TMP=/run/user/1000
35,36c35,36
< configureFlags=--prefix=/nix/store/rkjhcjhdj6ba7r7n7fasq8gmzxi5hk72-env
< TMPDIR=/build
---
> configureFlags=
> TMPDIR=/run/user/1000
39a40
> IN_NIX_SHELL=pure
45c46
< SHELL=/nix/store/qdp56fi357fgxxnkjrwx1g67hrk775im-bash-4.4-p23/bin/bash
...
```

Exercise:

```bash
$ diff --color=always <(nix-shell $drv --pure --run env) <(nix-shell $drv --run env)
```

## Environment Variables

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "foo";
            foo = "foo val";
            unpackPhase = "true";
            installPhase = ''
              env
              echo $foo > $out
            '';
          }
«derivation /nix/store/q669jm7mh44wdjxa1a3195cqmnxpwb1a-foo.drv»
```

```bash
$ nix-build /nix/store/q669jm7mh44wdjxa1a3195cqmnxpwb1a-foo.drv
these derivations will be built:
  /nix/store/q669jm7mh44wdjxa1a3195cqmnxpwb1a-foo.drv
building '/nix/store/q669jm7mh44wdjxa1a3195cqmnxpwb1a-foo.drv'...
...
outputs=out
foo=foo val
configureFlags=--prefix=/nix/store/5fcz8sik4nbxvg7rn2f5dmi58bg37psf-foo
...
/nix/store/5fcz8sik4nbxvg7rn2f5dmi58bg37psf-foo

$ cat $(nix-build /nix/store/q669jm7mh44wdjxa1a3195cqmnxpwb1a-foo.drv)
foo val
```

## Setting Dependencies as Variables

```nix
nix-repl> greet = import ./04-derivations/02-dependencies/greet.nix

nix-repl> nixpkgs.stdenv.mkDerivation {
            inherit greet;

            name = "greet-alice";
            unpackPhase = "true";
            installPhase = ''
              $greet/bin/greet Alice > $out
            '';
          }
«derivation /nix/store/97gi315afz5zl7pq2v8zhkqgy1z0ck2l-greet-alice.drv»
```

```bash
$ drv=/nix/store/97gi315afz5zl7pq2v8zhkqgy1z0ck2l-greet-alice.drv
$ cat $(nix-build $drv)
these derivations will be built:
  /nix/store/97gi315afz5zl7pq2v8zhkqgy1z0ck2l-greet-alice.drv
building '/nix/store/97gi315afz5zl7pq2v8zhkqgy1z0ck2l-greet-alice.drv'...
...
Hello, Alice!
```

```bash
nix-shell $drv --pure --run 'echo $greet'
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet
```

## Build Inputs

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "greet-alice";
            buildInputs = [ greet ];

            unpackPhase = "true";
            installPhase = ''
              greet Alice > $out
            '';
          }
«derivation /nix/store/n2qq1f93wcj2b9ipz9zc69nax0hfic7q-greet-alice.drv»
```

```bash
$ drv=/nix/store/n2qq1f93wcj2b9ipz9zc69nax0hfic7q-greet-alice.drv
$ cat $(nix-build $drv)
these derivations will be built:
  /nix/store/n2qq1f93wcj2b9ipz9zc69nax0hfic7q-greet-alice.drv
building '/nix/store/n2qq1f93wcj2b9ipz9zc69nax0hfic7q-greet-alice.drv'...
...
Hello, Alice!
```

```bash
$ nix-shell $drv --pure --run "command -v greet"
/nix/store/l6xy4qjr8x3ni16skfilw0fvnda13szq-greet/bin/greet
```