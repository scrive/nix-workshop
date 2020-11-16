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