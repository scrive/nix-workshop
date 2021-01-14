# Nix Derivation Basics

First import a pinned version of `nixpkgs` so that we all get the same result:

```nix
nix-repl> nixpkgs-src = builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/c1e5f8723ceb684c8d501d4d4ae738fef704747e.tar.gz";
            sha256 = "02k3l9wnwpmq68xmmfy4wb2panqa1rs04p1mzh2kiwn0449hl86j";
          }

nix-repl> nixpkgs = import nixpkgs-src {}
```

We use the pinned version of `nixpkgs` so that everyone following the
tutorial will get the exact same derivation.

## Standard Derivation

```nix
nix-repl> hello-drv = nixpkgs.stdenv.mkDerivation {
            name = "hello.txt";
            unpackPhase = "true";
            installPhase = ''
              echo -n "Hello World!" > $out
            '';
          }

nix-repl> hello-drv
«derivation /nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv»
```

```bash
$ cat /nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv
Derive([("out","/nix/store/f6qq9bwv0lxw5glzjmin1y1r1s3kangv-hello.txt","","")],...)

$ nix show-derivation /nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv
{
  "/nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt"
      }
    },
    "inputSrcs": [
      "/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"
    ],
    ...
  }
}
```

## Building Derivation

We can now build our derivation:

```bash
$ nix-build /nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv
/nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt

$ cat /nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt
Hello World!
```

This may take some time to load on your computer, as Nix fetches the essential
build tools that are commonly needed to build Nix packages.

We can also build the derivation within Nix repl using the `:b` command:

```nix
nix-repl> :b hello-drv
[1 built, 0.0 MiB DL]

this derivation produced the following outputs:
  out -> /nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt
```

## Tracing Derivation

Our `hello-drv` produce the same output as `hello.txt` in previous chapter,
but produce different output in the Nix store. (previously we had
`/nix/store/925f1jb1ajrypjbyq7rylwryqwizvhp0-hello.txt`)

We can trace the dependencies of the derivation back to its source:

```bash
$ nix-store --query --deriver /nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt
/nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv

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
$ nix-store -qR /nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv
/nix/store/01n3wxxw29wj2pkjqimmmjzv7pihzmd7-which-2.21.tar.gz.drv
/nix/store/03f77phmfdmsbfpcc6mspjfff3yc9fdj-setup-hook.sh
...
```

That's a lot of dependencies! Where are they being used? We will learn about it
in the next chapter.

## Derivation in a Nix File

We save the same earlier derivation we defined inside a Nix file named
[`hello.nix`](01-derivation-basics/hello.nix). Now we can build our derivation directly:

```bash
$ nix-build 04-derivations/01-derivation-basics/hello.nix
/nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt
```

We can also get the derivation without building it using `nix-instantiate`:

```bash
$ nix-instantiate 04-derivations/01-derivation-basics/hello.nix
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/ad6c51ia15p9arjmvvqkn9fys9sf1kdw-hello.txt.drv
```

Ignore the warning from `nix-instantiate`, as we don't care whether the derivation
is deleted during Nix garbage collection.

Notice that both the derivation and the build output have the same hash
as the earlier result we had in `nix repl`.

## Caching Nix Build Artifacts

We create [`hello-sleep.nix`](01-derivation-basics/hello-sleep.nix) as a variant of
`hello.nix` which sleeps for 10 seconds in its `buildPhase`.
(We will go through how each phases work in the next chapter)
The 10 seconds sleep simulates the time taken to compile a program.
We can see what happens when we try to build the same Nix derivation
multiple times.

First, instantiating a derivation is not affected by the build time:

```bash
$ time nix-instantiate 04-derivations/01-derivation-basics/hello-sleep.nix
/nix/store/58ngrpwgv6hl633a1iyjbmjqlbdqjw92-hello.txt.drv

real    0m0,217s
user    0m0,179s
sys     0m0,032s
```

The first time we build `hello-sleep.nix`, it is going to take about 10 seconds.
We can also see the logs we printed during the build phase is shown:

```bash
$ time nix-build 04-derivations/01-derivation-basics/hello-sleep.nix
these derivations will be built:
  /nix/store/58ngrpwgv6hl633a1iyjbmjqlbdqjw92-hello.txt.drv
building '/nix/store/58ngrpwgv6hl633a1iyjbmjqlbdqjw92-hello.txt.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
Building hello world...
Finished building hello world!
installing
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/lm801yriwjj4298ry74hdv5j0rpkpacq-hello.txt
strip is /nix/store/bnjps68g8ax6abzvys2xpx12imrx8949-binutils-2.31.1/bin/strip
patching script interpreter paths in /nix/store/lm801yriwjj4298ry74hdv5j0rpkpacq-hello.txt
checking for references to /build/ in /nix/store/lm801yriwjj4298ry74hdv5j0rpkpacq-hello.txt...
/nix/store/lm801yriwjj4298ry74hdv5j0rpkpacq-hello.txt

real    0m12,202s
user    0m0,371s
sys     0m0,084s
```

But the next time we build `hello-sleep.nix`, it will take no time to build,
and there is no build output:

```bash
$ time nix-build 03-nix-basics/05-derivation/hello-sleep.nix
/nix/store/lm801yriwjj4298ry74hdv5j0rpkpacq-hello.txt

real    0m0,310s
user    0m0,256s
sys     0m0,047s
```

Nix determines whether a derivation needs to be rebuilt based on the input
derivation. For our case, in both calls to `hello-sleep.nix`,
`nix-build` instantiates the derivation behind the scene: i.e.
`/nix/store/58ngrpwgv6hl633a1iyjbmjqlbdqjw92-hello.txt.drv`. 
So it determines that the result has previously already
been built, and reuse the same Nix artifact.

## Derivation as File

With the duck-typing nature of Nix, derivations acts just like files in Nix.
We can actually treat the `hello-drv` we defined earlier as a file and
read from it:

```nix
nix-repl> builtins.readFile hello-drv
querying info about missing paths"Hello World!"
```

How does that works? Internally Nix lazily builds a
derivation when it is evaluated, and turn it into
a file path. We can verify that by using `builtins.toPath`:

```nix
nix-repl> builtins.toPath hello-drv
"/nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt"
```

With this property, we can also import derivations
from a Nix file, and then use it as if the derivation
has been built:

```nix
nix-repl> hello = import ./code/04-derivations/01-derivation-basics/hello.nix

nix-repl> builtins.readFile hello
querying info about missing paths"Hello World!"
```

We can even use a derivation as a string. Nix automatically
builds the derivation when it is evaluated as a string:

```nix
nix-repl> "path of hello: ${hello}"
"path of hello: /nix/store/z449wrqvwncs8clk7bsliabv1g1ci3n3-hello.txt"
```
