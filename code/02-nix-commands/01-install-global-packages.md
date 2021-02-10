# Install Global Packages

For newcomers, we can think of Nix as a supercharged package manager. Similar to traditional package managers, we can use Nix to install packages globally. Nix "installs" a global package by adding symlinkgs to `~/.nix-profile/bin`, which should be automatically included in your shell's `$PATH`.

```bash
$ nix-env -i hello
installing 'hello-2.10'
building '/nix/store/mlfrpy1ahv3arh2n23p45vdpm0p4nl1x-user-environment.drv'...
created 39 symlinks in user environment
```

```bash
$ hello
Hello, world!

$ which hello
/home/user/.nix-profile/bin/hello

$ readlink $(which hello)
/nix/store/ylhzcjbchfihsrpsg0dxx9niwzp35y63-hello-2.10/bin/hello
```

## Uninstall

```bash
$ nix-env --uninstall hello
uninstalling 'hello-2.10'
```

While convenient, global packages pollute the global environment of our system. [Next](02-use-packages-in-nix-shell.html) we will look at how Nix shell can provide a local shell environment that provide the same dependencies that we need.
