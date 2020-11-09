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