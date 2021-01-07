# Caching Haskell Nix Packages

```bash
$ drv=$(nix-instantiate ./code/05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized)
```

```bash
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
...
compressing and pushing /nix/store/13mqwjvf6p8brj8aw77qxa4ijaafm645-QuickCheck-lib-QuickCheck-2.14.2-ghc-8.10.2-env.drv (5.03 KiB)
...
compressing and pushing /nix/store/b2j1nrsjr8cpzmk58d476fc2snz17w75-ghc-8.10.2 (1.71 GiB)
...
compressing and pushing /nix/store/vlmbfxjj108656sjvq8lsxzwil41b9is-haskell-project-exe-hello-0.1.0.0.drv (4.20 KiB)
...
All done.
```


## Source Code Contamination

```haskell
module Main where

main :: IO ()
main = putStrLn "Hello, World!"
```

```bash
$ drv=$(nix-instantiate ./code/05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized)
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
...
/nix/store/3k48f7r4vkg8b6ai9jz4pwd26njf8qdi-haskell-project-exe-hello-0.1.0.0
compressing and pushing /nix/store/3k48f7r4vkg8b6ai9jz4pwd26njf8qdi-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
compressing and pushing /nix/store/6a049f3fv8x2rdxv34k14cxrwi9an43f-haskell-project-src (1.48 KiB)
compressing and pushing /nix/store/pvb2ahm7hw8x3a4jwh06y160sf76d3l9-haskell-project-exe-hello-0.1.0.0.drv (4.20 KiB)
All done.
```

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

## Leaking Secrets

```bash
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

```
$ drv=$(nix-instantiate ./code/05-package-management/haskell-project-v3/nix/07-haskell.nix-materialized)
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
...
/nix/store/nrmyzkww87ndyp44jkn56hrra8m9d9vy-haskell-project-exe-hello-0.1.0.0
compressing and pushing /nix/store/l4alhrlycg5rjvds64r8x7jxmliapv8y-haskell-project-exe-hello-0.1.0.0.drv (4.20 KiB)
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
```

## Gitignore.nix

https://github.com/hercules-ci/gitignore.nix


```nix
{{#include ./haskell-project-v4/nix/01-gitignore-src/project.nix}}
```


```bash
$ ls -la ./code/06-infrastructure/haskell-project-v4/haskell/
total 32
drwxrwxr-x 2 user user 4096 Jan  7 15:53 .
drwxrwxr-x 4 user user 4096 Jan  7 15:46 ..
-rw-rw-r-- 1 user user   26 Jan  7 15:53 .gitignore
-rw-r--r-- 1 user user   67 Jan  7 15:46 Main.hs
-rw-r--r-- 1 user user   46 Jan  7 15:46 Setup.hs
-rw-rw-r-- 1 user user   12 Jan  7 15:46 cabal.project
-rw-rw-r-- 1 user user  307 Jan  7 15:46 haskell-project.cabal
-rw-rw-r-- 1 user user    7 Jan  7 15:53 secret.key

$ drv=$(nix-instantiate ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src)
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
...
/nix/store/41spkzp8zhh4g1663lx472d803hnwn46-haskell-project-exe-hello-0.1.0.0
compressing and pushing /nix/store/41spkzp8zhh4g1663lx472d803hnwn46-haskell-project-exe-hello-0.1.0.0 (3.60 MiB)
compressing and pushing /nix/store/j7c4gl7qbi5kbpyvi6kw9pcnq56vqb6i-haskell-project-root (1.49 KiB)
compressing and pushing /nix/store/rn7wj8vv5dq08kngsgqki4bk09waqs7v-haskell-project-exe-hello-0.1.0.0.drv (4.20 KiB)
All done.
user@d6de47426c9f:~/nix-workshop$ ls -la /nix/store/j7c4gl7qbi5kbpyvi6kw9pcnq56vqb6i-haskell-project-root
total 300
dr-xr-xr-x 2 user user   4096 Jan  1  1970 .
drwxr-xr-x 1 user user 274432 Jan  7 16:27 ..
-r--r--r-- 1 user user     26 Jan  1  1970 .gitignore
-r--r--r-- 1 user user     67 Jan  1  1970 Main.hs
-r--r--r-- 1 user user     46 Jan  1  1970 Setup.hs
-r--r--r-- 1 user user     12 Jan  1  1970 cabal.project
-r--r--r-- 1 user user    307 Jan  1  1970 haskell-project.cabal
```

## Caching Haskell.nix Shell

```bash
drv=$(nix-instantiate ./code/06-infrastructure/haskell-project-v4/nix/01-gitignore-src/shell.nix )
$ nix-shell --run true $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
...
compressing and pushing /nix/store/13mqwjvf6p8brj8aw77qxa4ijaafm645-QuickCheck-lib-QuickCheck-2.14.2-ghc-8.10.2-env.drv (5.03 KiB)
...
compressing and pushing /nix/store/yqsrrbnpq7gag1c7vy2d46rpgg0by5wx-splitmix-lib-splitmix-0.1.0.3-config.drv (3.98 KiB)
...
All done.
```
