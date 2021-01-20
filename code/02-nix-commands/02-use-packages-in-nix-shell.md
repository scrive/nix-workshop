# Nix Shell

You can use Nix packages without installing them globally on your machine. This is a good way to bring in the tools you need for individual projects.

```bash
$ nix-shell -p hello

[nix-shell:nix-workshop]$ hello
Hello, world!
```

## Using Multiple Packages

```bash
$ nix-shell -p nodejs ghc cabal-install

[nix-shell:nix-workshop]$ which node
/nix/store/ndkzg5kpyp92mlzh5h66l4j393x6b256-nodejs-12.19.0/bin/node

[nix-shell:nix-workshop]$ which ghc
/nix/store/sbqnpfnx4w8jb7jq2yb71pifihwqy2a5-ghc-8.8.4/bin/ghc

[nix-shell:nix-workshop]$ which cabal
/nix/store/060x141b9fz2pm6yz4zn3i0ncavbdbf7-cabal-install-3.2.0.0/bin/cabal
```

## Using `shell.nix`

It is common practice for Nix-using projects to provide a `shell.nix` file that specifies the shell environment. The `nix-shell` command reads this file, allowing us to create reproducible shell environments without using `-p`. These environments can provide access to any tool written in any language, without polluting the global environment. We will cover the use of `shell.nix` in a [later chapter](../04-derivations/04-raw-derivation.md#nix-shell).
