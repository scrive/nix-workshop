# Build Phases

`stdenv` provides many different phases, with default behavior of
what to run if no script for that phase is provided.

Many of the phases follow the build steps introduced by
[Autotools](https://www.gnu.org/software/automake/manual/html_node/Autotools-Introduction.html).
When we are building non-C/C++ projects, only a few phases are essential.
Still, it is useful to take a quick look at what phases are there,
and what they offers.

The [nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable/#sec-stdenv-phases)
has the full list of phases.

## The `phases` Attribute

We can force `stdenv` to run only specific phases by specifying them
in the `phases` attribute.


```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "hello";
            phases = [ "installPhase" ];
            installPhase = "echo 'Hello World!' > $out";
          }
«derivation /nix/store/m09hj2xs3yc45y3d4rdm8wks7cay00ak-hello.drv»
```

```bash
$ nix-build /nix/store/m09hj2xs3yc45y3d4rdm8wks7cay00ak-hello.drv
these derivations will be built:
  /nix/store/m09hj2xs3yc45y3d4rdm8wks7cay00ak-hello.drv
building '/nix/store/m09hj2xs3yc45y3d4rdm8wks7cay00ak-hello.drv'...
installing
/nix/store/hpj3y6as9s07444qi6nap0f5dp5k84b6-hello

$ cat /nix/store/hpj3y6as9s07444qi6nap0f5dp5k84b6-hello
Hello World!
```

You may notice that the build log for this version of `hello` is much shorter
than the usual output of standard derivations. Messages such as
`post-installation fixup` are not shown here.

This is because those are implicit steps performed in phases such as `fixupPhase`.
We will go through later why those phases are there. But as you can see, these
phases can be disabled by explicitly specifying the `phases` to run.

There is also no need to explicitly skip required phases like `unpackPhase`,
which we previously set to `true`.

## Unpack Phase

The unpack phase is used to unpack source code into temporary directories
to be used for compilation. By default, `unpackPhase` unpacks the source
code specified in `$src`, and if none is provided, it will abort with an error.

```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "hello";
            installPhase = "echo 'Hello World!' > $out";
          }
«derivation /nix/store/cx3p30jp0y0l8ixl426drsp81vcqagpr-hello.drv»
```

```bash
$ nix-build /nix/store/cx3p30jp0y0l8ixl426drsp81vcqagpr-hello.drv
these derivations will be built:
  /nix/store/cx3p30jp0y0l8ixl426drsp81vcqagpr-hello.drv
building '/nix/store/cx3p30jp0y0l8ixl426drsp81vcqagpr-hello.drv'...
unpacking sources
variable $src or $srcs should point to the source
builder for '/nix/store/cx3p30jp0y0l8ixl426drsp81vcqagpr-hello.drv' failed with exit code 1
error: build of '/nix/store/cx3p30jp0y0l8ixl426drsp81vcqagpr-hello.drv' failed
```

This is why when we don't have any source code, we have to explicitly skip
the `unpackPhase` by telling it to run `true` instead.

Let's try to see what is done in `unpackPhase` when we give it some source directories.


```nix
nix-repl> nixpkgs.stdenv.mkDerivation {
            name = "fibonacci-src";
            src = ./04-derivations/03-fibonacci;
            installPhase = ''
              set -x

              pwd
              ls -la .
              cp -r ./ $out/

              set +x
            '';
          }
«derivation /nix/store/8l0s01nk0fc1zicb9qkdmpwsw01qr5p8-fibonacci.drv»
```

```bash
$ nix-build /nix/store/8l0s01nk0fc1zicb9qkdmpwsw01qr5p8-fibonacci.drv
these derivations will be built:
  /nix/store/8l0s01nk0fc1zicb9qkdmpwsw01qr5p8-fibonacci.drv
building '/nix/store/8l0s01nk0fc1zicb9qkdmpwsw01qr5p8-fibonacci.drv'...
unpacking sources
unpacking source archive /nix/store/a5f73yy0a8dn0p12pfriqbqyag0ksfkq-03-fibonacci
source root is 03-fibonacci
patching sources
configuring
no configure script, doing nothing
building
no Makefile, doing nothing
installing
++ pwd
/build/03-fibonacci
++ ls -la .
total 16
drwxr-xr-x 2 nixbld nixbld 4096 Jan  1  1970 .
drwx------ 3 nixbld nixbld 4096 Dec  1 09:19 ..
-rw-r--r-- 1 nixbld nixbld 1772 Jan  1  1970 fib-serialized.nix
-rw-r--r-- 1 nixbld nixbld 1602 Jan  1  1970 fib.nix
++ cp -r ./ /nix/store/qqd4msyqya0xhqxcyra0lf7v09z2q522-fibonacci/
++ set +x
post-installation fixup
shrinking RPATHs of ELF executables and libraries in /nix/store/qqd4msyqya0xhqxcyra0lf7v09z2q522-fibonacci
strip is /nix/store/bnjps68g8ax6abzvys2xpx12imrx8949-binutils-2.31.1/bin/strip
patching script interpreter paths in /nix/store/qqd4msyqya0xhqxcyra0lf7v09z2q522-fibonacci
checking for references to /build/ in /nix/store/qqd4msyqya0xhqxcyra0lf7v09z2q522-fibonacci...
/nix/store/qqd4msyqya0xhqxcyra0lf7v09z2q522-fibonacci

$ ls -la /nix/store/qqd4msyqya0xhqxcyra0lf7v09z2q522-fibonacci
total 5728
dr-xr-xr-x    2 user user    4096 Jan  1  1970 .
drwxr-xr-x 5403 user user 5849088 Dez  1 10:19 ..
-r--r--r--    1 user user    1602 Jan  1  1970 fib.nix
-r--r--r--    1 user user    1772 Jan  1  1970 fib-serialized.nix
```

As we can see, `unpackPhase` copies the content of the source code specified in `$src`
into the temporary build directory. It also modifies the chmod permissions to
allow write permission to the files and directories.

## Patch Phase

## Configure Phase

## Build Phase

## Check Phase

## Install Phase

## Fixup Phase