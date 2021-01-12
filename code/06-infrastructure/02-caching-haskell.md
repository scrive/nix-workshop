# Caching Haskell Nix Packages

Similar to the previous chapter, we can cache our Haskell.nix project in similar way.

```bash
$ drv=$(nix-instantiate ./code/05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized)

$ nix-build $drv && nix-store -qR --include-outputs $drv | grep -v .drv | cachix push $CACHIX_STORE
...
/nix/store/8vrdfinxxnwczn4jzknm44bsn3k5nghl-haskell-project-exe-hello-0.1.0.0
compressing and pushing /nix/store/8vrdfinxxnwczn4jzknm44bsn3k5nghl-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
compressing and pushing /nix/store/6apx83l6ss3hkn0kd4z4rkjbkgs0w4w2-default-Setup-setup (18.07 MiB)
compressing and pushing /nix/store/3pfy3dd8ch77km1wkwd6cdgqn57d4347-haskell-project-exe-hello-0.1.0.0-config (304.02 KiB)
compressing and pushing /nix/store/b2j1nrsjr8cpzmk58d476fc2snz17w75-ghc-8.10.2 (1.71 GiB)
...
All done.
```

As simple as it might look, the naive approach however has some flaws,
especially when dealing with private projects.

## Leaking Source Code

The first issue with pushing everything is source code contamination, i.e.
the source code of the project leaking to the cache. For instance, suppose
we modify the [main](../05-package-management/haskell-project-v3/haskell/Main.hs)
function to print "Hello, World!" instead of "Hello, Haskell!":

```bash
$ sed -i 's/Hello, Haskell!/Hello, World!/g' ./code/05-package-management/haskell-project-v3/haskell/Main.hs
$ cat ./code/05-package-management/haskell-project-v3/haskell/Main.hs
module Main where

main :: IO ()
main = putStrLn "Hello, World!"
```

If we try to rebuild our Haskell project and push it to Cachix, we can notice
that the modified source code is also pushed as well.
(Notice the `drv=$(nix-instantiate ...)` assignment has to be re-run to get the
new derivation with the modified source)

```bash
$ drv=$(nix-instantiate ./code/05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized)
$ nix-build $drv && nix-store -qR --include-outputs $drv | grep -v .drv | cachix push $CACHIX_STORE
...
/nix/store/hkqkig7y1dx96qbdwkhk0anb0xdmx6hm-haskell-project-exe-hello-0.1.0.0
compressing and pushing /nix/store/hkqkig7y1dx96qbdwkhk0anb0xdmx6hm-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
compressing and pushing /nix/store/wq6ry5x7b5x3ld0d7wd2wx3vkxp4wi66-haskell-project-src (1.49 KiB)
All done.
```

We can list the files in `/nix/store/6a049f3fv8x2rdxv34k14cxrwi9an43f-haskell-project-src`
and verify that it indeed contains our modified source code. Yikes!

```bash
$ ls -la /nix/store/6a049f3fv8x2rdxv34k14cxrwi9an43f-haskell-project-src
total 180
dr-xr-xr-x 2 user user   4096 Jan  1  1970 .
drwxr-xr-x 1 user user 151552 Jan  7 15:41 ..
-r--r--r-- 1 user user     15 Jan  1  1970 .gitignore
-r--r--r-- 1 user user     65 Jan  1  1970 Main.hs
-r--r--r-- 1 user user     46 Jan  1  1970 Setup.hs
-r--r--r-- 1 user user     12 Jan  1  1970 cabal.project
-r--r--r-- 1 user user    307 Jan  1  1970 haskell-project.cabal

$ cat /nix/store/6a049f3fv8x2rdxv34k14cxrwi9an43f-haskell-project-src/Main.hs
module Main where

main :: IO ()
main = putStrLn "Hello, World!"
```

Pushing source code to Cachix might not be a big deal for open source projects.
However this may be an issue for propritary projects with strict IP policies.
This could be partially mitigated by having a private Cachix store. But we
just have to be aware of it and be careful.

## Leaking Secrets

Even for the case of open source projects, indiscriminately pushing everything
to Cachix still carries another risk, which is accidentally leaking secrets
such as authentication credentials.

Suppose that we have some security credentials stored locally in the `secret.key`
file in the project directory. Since the file is included in `.gitignore`, it is
not pushed to the git repository.

```bash
$ echo secret > ./code/05-package-management/haskell-project-v3/haskell/secret.key
$ ls -la ./code/05-package-management/haskell-project-v3/haskell/
total 32
drwxrwxr-x 2 user user 4096 Jan  7 15:58 .
drwxrwxr-x 4 user user 4096 Dec  8 08:23 ..
-rw-rw-r-- 1 user user   26 Jan  7 15:58 .gitignore
-rw-r--r-- 1 user user   67 Jan  7 15:45 Main.hs
-rw-r--r-- 1 user user   46 Dec  7 08:37 Setup.hs
-rw-rw-r-- 1 user user   12 Dec  7 08:37 cabal.project
-rw-rw-r-- 1 user user  307 Jan  7 09:35 haskell-project.cabal
-rw-rw-r-- 1 user user    7 Jan  7 15:58 secret.key
```

But is `secret.key` being included when pushing to Cachix? Let's find out:

```
$ drv=$(nix-instantiate ./code/05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized)
$ nix-build $drv && nix-store -qR --include-outputs $drv | grep -v .drv | cachix push $CACHIX_STORE
...
compressing and pushing /nix/store/nrmyzkww87ndyp44jkn56hrra8m9d9vy-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
compressing and pushing /nix/store/ryz8an9z9bw7j1357k9b5w99fxvnhb74-haskell-project-src (1.69 KiB)
All done.

$ ls -la /nix/store/ryz8an9z9bw7j1357k9b5w99fxvnhb74-haskell-project-src
total 188
dr-xr-xr-x 2 user user   4096 Jan  1  1970 .
drwxr-xr-x 1 user user 155648 Jan  7 16:00 ..
-r--r--r-- 1 user user     26 Jan  1  1970 .gitignore
-r--r--r-- 1 user user     67 Jan  1  1970 Main.hs
-r--r--r-- 1 user user     46 Jan  1  1970 Setup.hs
-r--r--r-- 1 user user     12 Jan  1  1970 cabal.project
-r--r--r-- 1 user user    307 Jan  1  1970 haskell-project.cabal
-r--r--r-- 1 user user      7 Jan  1  1970 secret.key

$ cat /nix/store/ryz8an9z9bw7j1357k9b5w99fxvnhb74-haskell-project-src/secret.key
secret
```

That's not good! Our local security credentials have been leaked to Cachix!
If we also have a public Cachix store, the credentials can potentially be obtained
by anyone!

The real culprit is in how we create our source derivation in
[`project.nix`](../05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized/project.nix):

```nix
src = builtins.path {
  name = "haskell-project-src";
  path = ../../haskell;
  filter = path: type:
    let
      basePath = builtins.baseNameOf path;
    in
    basePath != "dist-newstyle"
  ;
};
```

Previously, we made a naive attempt of filtering our source directory and
excluding only the `dist-newstyle` directory to avoid rebuilding the Nix
build when the directory is modified by local `cabal` runs. However if
we want to push our source code to Cachix, we better be much more careful.

## Gitignore.nix

One way we can protect local secrets is by filtering out all gitignored
files so that our source code is close to a fresh git checkout when copied
into the Nix store. This can be done using Nix helper libraries such as
[gitignore.nix](https://github.com/hercules-ci/gitignore.nix).

Using gitignore.nix, we can now create a new
[haskell-project-v4](./haskell-project-v4) project with the source
filtered with gitignore.nix:

```nix
gitignore = (import sources."gitignore.nix" {
  inherit (nixpkgs) lib;
}).gitignoreSource;

src = nixpkgs.lib.cleanSourceWith {
  name = "haskell-project-src";
  src = gitignore ../../haskell;
};
```

We first add `gitignore.nix` into `sources` using `niv`, and then import
it as above. Following that, we use `gitignore ../../haskell` to
filter the gitignored files in the `haskell` directory. We then
use `nixpkgs.lib.cleanSourceWith` as a hack to give the filtered source a
name `haskell-project-src`, so that we can grep for it during inspection.

Now if we try to build our derivation, we should get the project source with
the local secret filtered out:

```bash
$ drv=$(nix-instantiate ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src)
$ nix-store -qR --include-outputs $drv | grep haskell-project-src
/nix/store/mhlj5xql8g6ib1wna4g9pc6cpraiz1q8-haskell-project-src-root

$ ls -la /nix/store/mhlj5xql8g6ib1wna4g9pc6cpraiz1q8-haskell-project-src-root
total 140
dr-xr-xr-x 2 nix nix   4096 Jan  1  1970 .
drwxr-xr-x 1 nix nix 114688 Jan 11 11:21 ..
-r--r--r-- 1 nix nix     26 Jan  1  1970 .gitignore
-r--r--r-- 1 nix nix     67 Jan  1  1970 Main.hs
-r--r--r-- 1 nix nix     46 Jan  1  1970 Setup.hs
-r--r--r-- 1 nix nix     12 Jan  1  1970 cabal.project
-r--r--r-- 1 nix nix    307 Jan  1  1970 haskell-project.cabal
```

### Caveats

Gitignore.nix can help us filter out files specified in `.gitignore`.
However it might still be possible that developers would add new secrets
locally without adding them to `.gitignore`. In such case, the secret
can still potentially leak to Cachix.

The best way to prevent secrets from leaking is to build from a published
git or tarball URL. That way it will be less likely for us to accidentally
mix up and leak the secrets in our local file systems. This will
however require more complex project organization, as we have to place
the Nix code separately from the source code.

Otherwise, it is still recommended to avoid pushing source code to
Cachix in the first place, both for proprietary and open source projects.
After all, users will almost always build a Nix project with their own
local source code, or source that are fetched directly from git or
remote URLs. There is rarely a need to use Cachix to distribute source
code to our users.

## Filtering Out Source

One simple way to filter out the source code is to filter out the name
of the source derivation using `grep` before pushing to Cachix:

```bash
$ nix-store -qR --include-outputs $drv \
  | grep -v .drv | grep -v haskell-project-src \
  | cachix push $CACHIX_STORE
```

Note however this may only work if no other paths pushed to Cachix depends
on the source code. This is because Cachix automatically pushes the whole
closure of a Nix path. For instance this would not work if we try to push
the `.drv` file of the build derivation to Cachix, because that would
also capture the source derivation as part of the closure.

This approach also would not work if there are some intermediate derivations
that make copy of the original source code and modify them to produce
new source derivation. The intermediate derivation may have a different
name, or even a generic one, which it would be difficult for us to filter
out without inspecting the derivation source.

As a result, it is best to make use of the `patchPhase` in
`stdenv.mkDerivation` to modify the source code if necessary.

## Caching Nix Shell

Another way to exclude source code from derivation is by creating a Nix shell
derivation and cache that instead. Haskell.nix provides a `shellFor`
function that creates a Nix shell derivation from the original
Haskell.nix project we defined.


```nix
{{#include ./haskell-project-v4/nix/01-gitignore-src/shell.nix}}
```

If we inspect the derivation tree from `shell.nix`, we can confirm that
indeed the source code not present in the list. And so we can
safely push only the Haskell.nix dependencies to Cachix.


```bash
drv=$(nix-instantiate ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src/shell.nix)

$ nix-store -qR --include-outputs $drv | grep haskell-project-src
```

We first use `nix-shell --run true $drv` to build only the dependencies of our shell derivation and
push them to Cachix.

```bash
$ nix-shell --run true $drv && nix-store -qR --include-outputs $drv | grep -v .drv | cachix push $CACHIX_STORE
...
All done.
```

If we want to cache the final build artifact as well, we can still run `nix-build $drv` and
then push _only_ the build output to Cachix.

```bash
$ nix-build ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src | cachix push $CACHIX_STORE
...
compressing and pushing /nix/store/9in65nlw9s255x8zh5g7hlvbnl23rqbz-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
All done.
```

## Double Check Leaking with Code Changes

Our attempt to cache only the Nix shell derivation seems to exclude the source code,
but is it really excluded? If we are not careful, we could easily let Nix give a
generic name like `source` to our source derivation. In that case it would not
be possible to detect it through `grep` if our source code has leaked through.

As a result, it is best to double check what is being cached by slightly modifying
our source code, and then try pushing to Cachix again.

```bash
$ sed -i 's/Hello, Haskell!/Hello, World!/g' ./code/06-infrastructure/haskell-project-v4/haskell/Main.hs
$ cat ./code/06-infrastructure/haskell-project-v4/haskell/Main.hs
module Main where

main :: IO ()
main = putStrLn "Hello, World!"

$ drv=$(nix-instantiate ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src/shell.nix)
$ nix-shell --run true $drv && nix-store -qR --include-outputs $drv | grep -v .drv | cachix push $CACHIX_STORE
All done.

$ nix-build ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src | cachix push $CACHIX_STORE
these derivations will be built:
  /nix/store/52qqdj4pq564ivyawpvfzsz2s3kv9wmp-haskell-project-exe-hello-0.1.0.0.drv
...
compressing and pushing /nix/store/fdb6b3dj79gqff0lz0xf34lrs4gpb5a0-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
All done.
```

As we expect, even though `Main.hs` has been modified, there is no new source
artifact being pushed to Cachix. Only `nix-build` produced a new binary, which
is then pushed to Cachix.

You can apply the same method on your own project to double check if your
source code is leaking to Cachix. Even if you do not care about the source
code leaking, this can still serve as a good way to check if any secret
is leaking.

## Caching Multiple Projects

The technique for caching Nix shell can only work if we have projects made of a
single Nix derivation. If we instead have a large project with multiple source
repositories, it is much harder to filter out the source code if the derivations
depend on each others.

In such cases, the simple way is to use `grep -v` and hope that it can filter
out all the source derivations. Otherwise you may need to use project-specific
techniques to make sure that only intended Nix artifacts are being cached.

## Conclusion

As we seen in this chapter, caching build results is not as straighforward if
there are things that we want to _prevent_ from being cached, such as proprietary
source code or local secrets. This is probably not a big issue right now, because
many people may not even be aware that their source code and secrets are leaking!

Even without considering leaking secrets, there are still too many different ways
of caching build results in Nix. While this provides more flexibility for us
to control what to cache, the learning curve is way too high for new users
who just want to get their Nix builds cached.

Nix and Cachix may need to implement additional features to help make caching
easier, and to protect sensitive data. For example, Cachix may add a command
line option to exclude paths matching specific pattern to never be pushed.
