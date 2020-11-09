# Install Global Packages

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