# Nix Derivation

First import `nixpkgs`:

```
nix-repl> nixpkgs = import <nixpkgs> {}
```

## Standard Derivation

```
nix-repl> hello-drv = nixpkgs.stdenv.mkDerivation {
            name = "hello.txt";
            unpackPhase = "true";
            installPhase = ''
              echo -n "Hello World!" > $out
            '';
          }

nix-repl> hello-drv
«derivation /nix/store/srgiayr9fjpvwb4wzbhflgx8lafnhbzp-hello.txt.drv»
```

```bash
$ cat /nix/store/srgiayr9fjpvwb4wzbhflgx8lafnhbzp-hello.txt.drv
Derive([("out","/nix/store/f6qq9bwv0lxw5glzjmin1y1r1s3kangv-hello.txt","","")],...)
```

## Building Derivation

```bash
$ nix-build /nix/store/srgiayr9fjpvwb4wzbhflgx8lafnhbzp-hello.txt.drv
/nix/store/f6qq9bwv0lxw5glzjmin1y1r1s3kangv-hello.txt

$ cat /nix/store/f6qq9bwv0lxw5glzjmin1y1r1s3kangv-hello.txt
Hello World!
```

## Tracing Derivation

Our `hello-drv` produce the same output as `hello.txt` in previous chapter,
but produce different output in the Nix store. (previously we had
`/nix/store/925f1jb1ajrypjbyq7rylwryqwizvhp0-hello.txt`)

We can trace the dependencies of the derivation back to its source:

```bash
$ nix-store --query --deriver /nix/store/f6qq9bwv0lxw5glzjmin1y1r1s3kangv-hello.txt
/nix/store/srgiayr9fjpvwb4wzbhflgx8lafnhbzp-hello.txt.drv

$ nix-store --query --deriver /nix/store/925f1jb1ajrypjbyq7rylwryqwizvhp0-hello.txt
unknown-deriver
```

Our `hello.txt` built from `stdenv.mkDerivation` is built from a derivation
artifact `hello.txt.drv`, but our `hello.txt` created from `builtins.path`
has no deriver.
In other words, the Nix artifacts are different because they are produced from
different derivations.

We can further trace the dependencies of `hello.txt.drv`:

```bash
$ nix-store -qR /nix/store/srgiayr9fjpvwb4wzbhflgx8lafnhbzp-hello.txt.drv
/nix/store/01n3wxxw29wj2pkjqimmmjzv7pihzmd7-which-2.21.tar.gz.drv
/nix/store/03f77phmfdmsbfpcc6mspjfff3yc9fdj-setup-hook.sh
...
```

That's a lot of dependencies! Where are they being used? We will learn about it
in the next chapter.

## Derivation in a Nix File

We save the same earlier derivation we defined inside a Nix file named
[`hello.nix`](05-derivation/hello.nix). Now we can build our derivation directly:

```bash
$ nix-build 03-nix-basics/05-derivation/hello.nix
/nix/store/f6qq9bwv0lxw5glzjmin1y1r1s3kangv-hello.txt
```

We can also get the derivation without building it using `nix-instantiate`:

```bash
$ nix-instantiate 03-nix-basics/05-derivation/hello.nix
/nix/store/srgiayr9fjpvwb4wzbhflgx8lafnhbzp-hello.txt.drv
```

Notice that both the derivation and the build output have the same hash
as the earlier result we had in `nix repl`.

## Caching Nix Build Artifacts

We create [`hello-sleep.nix`](05-derivation/hello-sleep.nix) as a variant of
`hello.nix` which sleeps for 10 seconds in its `buildPhase`.
(We will go through how each phases work in the next chapter)
The 10 seconds sleep simulates the time taken to compile a program.
We can see what happens when we try to build the same Nix derivation
multiple times.

First, instantiating a derivation is not affected by the build time:

```bash
$ time nix-instantiate 03-nix-basics/05-derivation/hello-sleep.nix
/nix/store/k3cq3qn2cx7vmqjrzlc5wcbm3ci75yxy-hello.txt.drv

real    0m0,230s
user    0m0,198s
sys     0m0,033s
```

The first time we build `hello-sleep.nix`, it is going to take about 10 seconds.
We can also see the logs we printed during the build phase is shown:

```bash
$ time nix-build 03-nix-basics/05-derivation/hello-sleep.nix
these derivations will be built:
  /nix/store/k3cq3qn2cx7vmqjrzlc5wcbm3ci75yxy-hello.txt.drv
building '/nix/store/k3cq3qn2cx7vmqjrzlc5wcbm3ci75yxy-hello.txt.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
Building hello world...
Finished building hello world!
installing
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/9gbvdswvm6v39cjjsn4jnh7cbkzn93ca-hello.txt
strip is /nix/store/hiwz81i1g3fn3p0acjs042a4h5fri6dh-binutils-2.31.1/bin/strip
patching script interpreter paths in /nix/store/9gbvdswvm6v39cjjsn4jnh7cbkzn93ca-hello.txt
checking for references to /build/ in /nix/store/9gbvdswvm6v39cjjsn4jnh7cbkzn93ca-hello.txt...
/nix/store/9gbvdswvm6v39cjjsn4jnh7cbkzn93ca-hello.txt

real    0m12,021s
user    0m0,407s
sys     0m0,097s
```

But the next time we build `hello-sleep.nix`, it will take no time to build:

```bash
$ time nix-build 03-nix-basics/05-derivation/hello-sleep.nix
/nix/store/9gbvdswvm6v39cjjsn4jnh7cbkzn93ca-hello.txt

real    0m0,223s
user    0m0,185s
sys     0m0,040s
```

Nix determines whether a derivation needs to be rebuilt based on the input
derivation. For our case, in both calls to `hello-sleep.nix`,
`nix-build` instantiates the derivation behind the scene at got
`/nix/store/k3cq3qn2cx7vmqjrzlc5wcbm3ci75yxy-hello.txt.drv`
as the result. So it determines that the result has previously already
been built, and reuse the same Nix artifact.