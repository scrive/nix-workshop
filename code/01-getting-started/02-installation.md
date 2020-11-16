# Installation

Download available at https://nixos.org/download.html.

Simplest way is to run:

```bash
$ curl -L https://nixos.org/nix/install | sh
```

After installation, you might need to relogin to your shell to
reload the environment. Otherwise, run the following to use
Nix immediately:

```bash
source ~/.nix-profile/etc/profile.d/nix.sh
```

You may want to configure to load this automatically in `~/.bashrc` or similar
file.


## Update

If you have installed Nix before but have not updated it for a while,
you should update it with:

```bash
nix-channel --update
```

This helps ensure we are installing the latest version of packages
in global installation and global imports.