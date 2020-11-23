# Fibonacci

Nix dependencies can be nested arbitrarily deep. We can demonstrate that by building
a fibonacci Nix derivation with the following behavior:

  - Answers are produced in `$out/answer`.
  - Each build takes 3 seconds to produce the answer.
  - `fib(0)` is 0, and `fib(1)` is 1.
  - `fib(n)` depends on the answers from `fib(n-1)` and `fib(n-2)`.
  - The builds are prefixed with a name, so that we can force Nix to re-evaluate
    the whole sequence by changing the name.

[fib.nix](./03-fibonacci/fib.nix):


```nix
{{#include ./03-fibonacci/fib.nix}}
```

To make sure we build the fibonacci sequence from scratch each time, we can use
`$(date +%s)` with the Unix timestamp as the prefix to our builds.

Let's try `fib(0)` and `fib(1)`:

```bash
$ time nix-build -E "import ./04-derivations/03-fibonacci/fib.nix \"$(date +%s)\" 0"
these derivations will be built:
  /nix/store/yyy5fz5rsws6a812c9xc5ps1hwh9lm98-1605561354-fib-0.drv
building '/nix/store/yyy5fz5rsws6a812c9xc5ps1hwh9lm98-1605561354-fib-0.drv'...
...
no configure script, doing nothing
building
Producing base case fib(0)...
The answer to fib(0) is 0
...
checking for references to /build/ in /nix/store/9kvw6x88l9nx42mvrgzif60a72h66fqz-1605561354-fib-0...
/nix/store/9kvw6x88l9nx42mvrgzif60a72h66fqz-1605561354-fib-0

real    0m4,763s
user    0m0,476s
sys     0m0,130s
```

```bash
$ time nix-build -E "import ./04-derivations/03-fibonacci/fib.nix \"$(date +%s)\" 1"
these derivations will be built:
  /nix/store/qs2pc54dmd21xlhlqgzwmgfj98y1kr8n-1605561412-fib-1.drv
building '/nix/store/qs2pc54dmd21xlhlqgzwmgfj98y1kr8n-1605561412-fib-1.drv'...
...
Producing base case fib(1)...
The answer to fib(1) is 1
...
checking for references to /build/ in /nix/store/426cpqvvr7lbg92hywmbw7552vggpway-1605561412-fib-1...
/nix/store/426cpqvvr7lbg92hywmbw7552vggpway-1605561412-fib-1

real    0m5,279s
user    0m0,415s
sys     0m0,102s
```

So both `fib(0)` and `fib(1)` takes roughly 4~5 seconds to build.

Let's try `fib(2)`:

```bash
$ time nix-build -E "import ./04-derivations/03-fibonacci/fib.nix \"$(date +%s)\" 2"
these derivations will be built:
  /nix/store/r8n1v9ifk0q6mf75j35scn3s2dwa03j7-1605561535-fib-1.drv
  /nix/store/xxrzkbsnq1jpp4s5fdkpklxr3fbc0aq6-1605561535-fib-0.drv
  /nix/store/1bgy17jbakr9yn1yz0bnwhnnz1y1xsdc-1605561535-fib-2.drv
building '/nix/store/xxrzkbsnq1jpp4s5fdkpklxr3fbc0aq6-1605561535-fib-0.drv'...
...
Producing base case fib(0)...
The answer to fib(0) is 0
...
checking for references to /build/ in /nix/store/8k74irn8w8rzpccd30wdn8589nq0wdv5-1605561535-fib-0...
building '/nix/store/r8n1v9ifk0q6mf75j35scn3s2dwa03j7-1605561535-fib-1.drv'...
...
Producing base case fib(1)...
The answer to fib(1) is 1
...
checking for references to /build/ in /nix/store/p716qrpmyi4649k2njfy7gb97ksyi5y3-1605561535-fib-1...
building '/nix/store/1bgy17jbakr9yn1yz0bnwhnnz1y1xsdc-1605561535-fib-2.drv'...
...
Calculating the answer of fib(2)..
Given fib(1) = 1,
and given fib(0) = 0..
The answer to fib(2) is 1
...
checking for references to /build/ in /nix/store/qnaad56wgknlgki9r3kpmr4fhc7x8vxv-1605561535-fib-2...
/nix/store/qnaad56wgknlgki9r3kpmr4fhc7x8vxv-1605561535-fib-2

real    0m12,599s
user    0m0,658s
sys     0m0,198s
```

So building `fib(2)` causes `fib(1)` and `fib(0)` to also be built.

With this going on, if we are going to build `fib(5)`, then in total it is going to take a lot of time!
but if we have built `fib(4)` already, then building `fib(5)` will be very fast.

Let's fix our prefix to see Nix cache in effect:

```bash
$ prefix=$(date +%s)
$ time nix-build -E "import ./04-derivations/03-fibonacci/fib.nix \"$prefix\" 4"
these derivations will be built:
  /nix/store/gz9bgzmna8v7pw5giclfhrk81dp1z0rw-1605561962-fib-1.drv
  /nix/store/y2waqw60jqawallz4q3r64iwrrihnd1p-1605561962-fib-0.drv
  /nix/store/nwj4bmrqgfv1fkvhh00bl2v03c3zqpy1-1605561962-fib-2.drv
  /nix/store/17d2r2dd52qvmfa5k3dm9gkl1k09wdb8-1605561962-fib-3.drv
  /nix/store/w4w4la01p9a2i8mlg6fm15il6vmgcqzl-1605561962-fib-4.drv
building '/nix/store/y2waqw60jqawallz4q3r64iwrrihnd1p-1605561962-fib-0.drv'...
...
Calculating the answer of fib(4)..
Given fib(3) = 2,
and given fib(2) = 1..
The answer to fib(4) is 3
...
checking for references to /build/ in /nix/store/c26q5vs8vdfr268nqgamjk8bcypf8b7r-1605561962-fib-4...
/nix/store/c26q5vs8vdfr268nqgamjk8bcypf8b7r-1605561962-fib-4

real    0m19,486s
user    0m0,910s
sys     0m0,253s
```

Now run `fib(5)`:

```bash
$ time nix-build -E "import ./04-derivations/03-fibonacci/fib.nix \"$prefix\" 5"
these derivations will be built:
  /nix/store/nyb25403l4m5n69y3djlffsyzvpwyv6g-1605561962-fib-5.drv
building '/nix/store/nyb25403l4m5n69y3djlffsyzvpwyv6g-1605561962-fib-5.drv'...
unpacking sources
patching sources
configuring
no configure script, doing nothing
building
Calculating the answer of fib(5)..
Given fib(4) = 3,
and given fib(3) = 2..
The answer to fib(5) is 5
installing
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/p4iq9jaiid469ycgjm5v3ks3w0v35spi-1605561962-fib-5
strip is /nix/store/bnjps68g8ax6abzvys2xpx12imrx8949-binutils-2.31.1/bin/strip
patching script interpreter paths in /nix/store/p4iq9jaiid469ycgjm5v3ks3w0v35spi-1605561962-fib-5
checking for references to /build/ in /nix/store/p4iq9jaiid469ycgjm5v3ks3w0v35spi-1605561962-fib-5...
/nix/store/p4iq9jaiid469ycgjm5v3ks3w0v35spi-1605561962-fib-5

real    0m7,916s
user    0m0,461s
sys     0m0,151s
```

Now only `fib-5.drv` needs to be built.

## Lazy Evaluation

A derivation like `fib(10)` is going to take a long time to build. So we don't really want to build
it unless we actually need it. In fact, we also wouldn't want to build `fib(0)` through `fib(10)`
unless they are actually needed.

With Nix's lazy evaluation strategy, we in fact get the laziness property that none of
the fibonacci derivations are going to be built unless they are needed:


```bash
$ time nix-instantiate -E "import ./04-derivations/03-fibonacci/fib.nix \"$(date +%s)\" 10"
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
/nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv

real    0m0,235s
user    0m0,182s
sys     0m0,038s
```

We can see that while `fib(10)` has `fib(0)` through `fib(9)` as its dependencies,
but they are not being built just yet.

```bash
$ nix-store -qR /nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv | grep fib
/nix/store/31xdxhxynqndaiym043bjjky0l229vlg-1605562192-fib-1.drv
/nix/store/r4wkf6774ahva1zchk77kpvjf14xigrl-1605562192-fib-0.drv
/nix/store/8agah8vidgxi6yp9ki066yimfr16kigg-1605562192-fib-2.drv
/nix/store/ka3glx20pgzkvgan88xl87xki51y5pmi-1605562192-fib-3.drv
/nix/store/v5zra6kayssdg04n7xpjljqa1q5jjyqn-1605562192-fib-4.drv
/nix/store/1cqwdhnk8f55lxlajmjw6rzq2lq12x5l-1605562192-fib-5.drv
/nix/store/qrbrgdv16f7mc2xfalrgmypfz6c7yljq-1605562192-fib-6.drv
/nix/store/p5chc4l9mjqw5871lkd6har4hyjp55fj-1605562192-fib-7.drv
/nix/store/gn9hp9jcsfclrsdx6qlvjd051w4rsx8b-1605562192-fib-8.drv
/nix/store/6av3vlibm4knm4m3djcrfrhhb6jck3zx-1605562192-fib-9.drv
/nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv
```

### Input Derivations

If we inspect the derivation, the derivations `fib-9.drv` and `fib-8.drv`
are listed as one of the input derivations:

```bash
$ nix show-derivation /nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv
{
  "/nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/g7415lrzl6b43vnw58dgkxg5nzbjplp0-1605562192-fib-10"
      }
    },
    "inputSrcs": [
      "/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"
    ],
    "inputDrvs": {
      "/nix/store/6av3vlibm4knm4m3djcrfrhhb6jck3zx-1605562192-fib-9.drv": [
        "out"
      ],
      "/nix/store/gn9hp9jcsfclrsdx6qlvjd051w4rsx8b-1605562192-fib-8.drv": [
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
      "buildPhase": "fib_1=$(cat /nix/store/zr1ziy94ig8isdg0gdliz0sm59abh2l1-1605562192-fib-9/answer)\nfib_2=$(cat /nix/store/zvivby98nbjlb6pszp6qla4v1r6zwj82
-1605562192-fib-8/answer)\n\necho \"Calculating the answer of fib(10)..\"\necho \"Given fib(9) = $fib_1,\"\necho \"and given fib(8) = $fib_2..\"\n\nsleep 3\n\
nanswer=$(( $fib_1 + $fib_2 ))\necho \"The answer to fib(10) is $answer\"\n",
...
```

Interestingly, the `buildPhase` of the derivation refers to the output paths
of `fib-8.drv` and `fib-9.drv`, even when they have not been built! In other words,
the hash for a derivation output is deterministically derived ahead of time before
it is actually built.

In fact, the path to the build output for `fib-10.drv` can be found in the `output`
field of the derivation.

### Building Actual Derivation

We can build them later on when `nix-build` is actually called, or we can get the cached result
from else where before building them.

```bash
$ time nix-build /nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv
these derivations will be built:
  /nix/store/31xdxhxynqndaiym043bjjky0l229vlg-1605562192-fib-1.drv
  /nix/store/r4wkf6774ahva1zchk77kpvjf14xigrl-1605562192-fib-0.drv
  /nix/store/8agah8vidgxi6yp9ki066yimfr16kigg-1605562192-fib-2.drv
  /nix/store/ka3glx20pgzkvgan88xl87xki51y5pmi-1605562192-fib-3.drv
  /nix/store/v5zra6kayssdg04n7xpjljqa1q5jjyqn-1605562192-fib-4.drv
  /nix/store/1cqwdhnk8f55lxlajmjw6rzq2lq12x5l-1605562192-fib-5.drv
  /nix/store/qrbrgdv16f7mc2xfalrgmypfz6c7yljq-1605562192-fib-6.drv
  /nix/store/p5chc4l9mjqw5871lkd6har4hyjp55fj-1605562192-fib-7.drv
  /nix/store/gn9hp9jcsfclrsdx6qlvjd051w4rsx8b-1605562192-fib-8.drv
  /nix/store/6av3vlibm4knm4m3djcrfrhhb6jck3zx-1605562192-fib-9.drv
  /nix/store/dwjxm9rqxfbhf4m8nbg5wzddx1j4rcpl-1605562192-fib-10.drv
building '/nix/store/r4wkf6774ahva1zchk77kpvjf14xigrl-1605562192-fib-0.drv'...
...
Calculating the answer of fib(10)..
Given fib(9) = 34,
and given fib(8) = 21..
The answer to fib(10) is 55
...
checking for references to /build/ in /nix/store/g7415lrzl6b43vnw58dgkxg5nzbjplp0-1605562192-fib-10...
/nix/store/g7415lrzl6b43vnw58dgkxg5nzbjplp0-1605562192-fib-10

real    0m39,818s
user    0m1,260s
sys     0m0,413s
```

## Evaluation-Time Dependencies

In our original `fib.nix`, the build output of earlier fibonacci
numbers are used during the build phase of the current derivation.
But if we somehow uses the earlier fibonacci numbers to build
the derviation itself, Nix would behave quite differently.

[`fib-serialized.nix`](./03-fibonacci/fib-serialized.nix):

```nix
let
  fib-1 = fib (n - 1);
  fib-2 = fib (n - 2);

  n-1-str = builtins.toString (n - 1);
  n-2-str = builtins.toString (n - 2);

  fib-1-answer = nixpkgs.lib.removeSuffix "\n"
    (builtins.readFile "${fib-1}/answer");
  fib-2-answer = nixpkgs.lib.removeSuffix "\n"
    (builtins.readFile "${fib-2}/answer");
in
stdenv.mkDerivation {
  name = "${prefix}-fib-${n-str}";
  unpackPhase = "true";

  buildPhase = ''
    echo "Calculating the answer of fib(${n-str}).."
    echo "Given fib(${n-1-str}) = ${fib-1-answer},"
    echo "and given fib(${n-2-str}) = ${fib-2-answer}.."

    sleep 3

    answer=$(( ${fib-1-answer} + ${fib-2-answer} ))
    echo "The answer to fib(${n-str}) is $answer"
  '';
  ...
}
```

Let's try to instantiate the serialized version of `fib(4)`:

```bash
$ time nix-instantiate -E "import ./04-derivations/03-fibonacci/fib-serialized.nix \"$(date +%s)\" 4"
building '/nix/store/97h18adc1358s8ri9mjzmnbvbbsj7p0a-1606145205-fib-1.drv'...
...
Producing base case fib(1)...
The answer to fib(1) is 1
...
building '/nix/store/fyizpk51qr2k6pm6v2pbqynfqf8ws68p-1606145205-fib-0.drv'...
...
Producing base case fib(0)...
The answer to fib(0) is 0
...
building '/nix/store/8qglzk0vq984mx65f3993rqjpipc3q9j-1606145205-fib-2.drv'...
...
Calculating the answer of fib(2)..
Given fib(1) = 1,
and given fib(0) = 0..
The answer to fib(2) is 1
...
building '/nix/store/4p8xy858gwc348576h6rz39a3l7wk64l-1606145205-fib-3.drv'...
...
Calculating the answer of fib(3)..
Given fib(2) = 1,
and given fib(1) = 1..
The answer to fib(3) is 2
...
/nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv

real    0m20,016s
user    0m1,221s
sys     0m0,261s
```

What happened here? `fib(0)` to `fib(3)` are built even though we are just
instantiating `fib(4)`.

### Inspecting Input Derivation

Showing the derivation of `fib-4.drv` gives us a better idea:

```bash
$ nix show-derivation /nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv
{
  "/nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/fgq0j5mlqpy99mfdfc3v4bvbd6wr2slg-1606145205-fib-4"
      }
    },
    ...
    "inputDrvs": {
      "/nix/store/l54djrh1n7d8zdfn26w7v6zjh5wp7faa-bash-4.4-p23.drv": [
        "out"
      ],
      "/nix/store/x9why09hwx2pcnmw0fw7hhh1511hyskl-stdenv-linux.drv": [
        "out"
      ]
    },
    "env": {
      "buildInputs": "",
      "buildPhase": "echo \"Calculating the answer of fib(4)..\"\necho \"Given fib(3) = 2,\"\necho \"and given fib(2) = 1..\"\n\nsleep 3\n\nanswer=$(( 2 + 1 ))\necho \"The answer to fib(4) is $answer\"\n",
  ...
```

Thanks to `builtins.readFile`, the results for `fib(3)` and `fib(2)` have in fact
been calculated and inlined inside the the derivation itself. They are no longer
listed in the input derivation.

## Caching Problem of Evaluation-Time Dependencies

In fact, `fib(3)` and `fib(2)` are not even shown as dependencies in `fib(4)` anymore:

```bash
$ nix-store -qR /nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv | grep fib
/nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv
```

This has a consequence in caching Nix dependencies. Not knowing `fib(0)` to
`fib(3)` are actually input to `fib(4)`, it would be difficult to properly
cache these dependencies to Cachix.

This is part of the reason why caching Nix dependencies in Kontrakcja can be tricky.
There are many evaluation-time dependencies in libraries like Haskell.nix that
cannot be properly cached.

### Non-Lazy Build

If we build `fib(4)` now, indeed only `fib(4)` itself is being built.

```bash
$ nix-build /nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv
these derivations will be built:
  /nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv
building '/nix/store/c29ap9ljazs7k0jx687hnm3s0rgsz2vm-1606145205-fib-4.drv'...
...
Calculating the answer of fib(4)..
Given fib(3) = 2,
and given fib(2) = 1..
The answer to fib(4) is 3
...
/nix/store/fgq0j5mlqpy99mfdfc3v4bvbd6wr2slg-1606145205-fib-4
```

The same effect can also happen if we import `.nix` files from derivation outputs.

Lesson learnt: parallelization in Nix can still be tricky. Try your best to
include dependencies as input derivations, and lazily refer to the built output
of dependencies only during build time.