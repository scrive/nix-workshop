# Caching Nix Packages

## Cachix

https://docs.cachix.org

```bash
make docker
```

```bash
CACHIX_STORE=$(cat ~/nix-workshop/config/cachix-store)
cachix use $CACHIX_STORE
cachix authtoken $(cat ~/nix-workshop/config/cachix-token)
```

```bash
$ drv=$(nix-instantiate -E '
  import ./code/04-derivations/03-fibonacci/fib.nix
    "foo" 4
')
...
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
```

```bash
$ echo $drv
/nix/store/a4qb7vq7ws2q01jd5a07zpml5hw381nl-foo-fib-4.drv

$ nix-build --no-out-link $drv
...
```

```bash
$ nix-store -qR $drv
/nix/store/01n3wxxw29wj2pkjqimmmjzv7pihzmd7-which-2.21.tar.gz.drv
/nix/store/03f77phmfdmsbfpcc6mspjfff3yc9fdj-setup-hook.sh
...
```

```bash
$ nix-store -qR $drv | grep fib-
/nix/store/6mc3ccymdyfmqacrq5vyc43zb2gl81ml-foo-fib-1.drv
/nix/store/hj0g7hn703axx44x29l27xb1nrdg83rh-foo-fib-0.drv
/nix/store/k65i01s85dix9xcgxyaggc8l13lx1rrz-foo-fib-2.drv
/nix/store/wgcp26v3g23x9i9iqiirn20pgmv4mgki-foo-fib-3.drv
/nix/store/a4qb7vq7ws2q01jd5a07zpml5hw381nl-foo-fib-4.drv
```


```bash
$ nix-store -qR --include-outputs $drv | grep fib-
/nix/store/20flzbyx97kly3n34krlmjg9awjn6a5z-foo-fib-3
/nix/store/52j5p1a03vi8dxn7rh4s8y6n5ml318rq-foo-fib-0
/nix/store/6mc3ccymdyfmqacrq5vyc43zb2gl81ml-foo-fib-1.drv
/nix/store/hj0g7hn703axx44x29l27xb1nrdg83rh-foo-fib-0.drv
/nix/store/k65i01s85dix9xcgxyaggc8l13lx1rrz-foo-fib-2.drv
/nix/store/wgcp26v3g23x9i9iqiirn20pgmv4mgki-foo-fib-3.drv
/nix/store/a4qb7vq7ws2q01jd5a07zpml5hw381nl-foo-fib-4.drv
/nix/store/c7lwn4mfn3pk0hhvc98lg1r6z6c8pb6c-foo-fib-1
/nix/store/qih0iazs5yl3dg694a2fz0jzzlxzy7k8-foo-fib-2
/nix/store/zdq2p21pq836n3k1xkh4yb8wkvl9fy0l-foo-fib-4
```

```bash
$ nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
compressing and pushing /nix/store/0rgf63snfi078knpghs1jf2q3913gd17-bootstrap-stage4-gcc-wrapper-10.2.0.drv (7.05 KiB)
compressing and pushing /nix/store/0vjq3889mc2z9v02hcw072ay0fivbshx-nuke-references.drv (1.41 KiB)
...
compressing and pushing /nix/store/20flzbyx97kly3n34krlmjg9awjn6a5z-foo-fib-3 (288.00 B)
...
compressing and pushing /nix/store/wgcp26v3g23x9i9iqiirn20pgmv4mgki-foo-fib-3.drv (1.82 KiB)
...
compressing and pushing /nix/store/zdq2p21pq836n3k1xkh4yb8wkvl9fy0l-foo-fib-4 (288.00 B)
All done.
```


```bash
$ drv=$(nix-instantiate -E '
  import ./code/04-derivations/03-fibonacci/fib.nix
    "foo" 7
')
...
warning: you did not specify '--add-root'; the result might be removed by the garbage collector
```

```bash
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
these derivations will be built:
  /nix/store/m3sspba1wz9ffp5qyjplg8fjbnhy7d73-foo-fib-5.drv
  /nix/store/zyhq28hxak4jk7xak6lixa4lbfxdjwvz-foo-fib-6.drv
  /nix/store/ih1jzl51hcahsi9dikbn040888jb4hb9-foo-fib-7.drv
building '/nix/store/m3sspba1wz9ffp5qyjplg8fjbnhy7d73-foo-fib-5.drv'...
...
/nix/store/zhc126b7clx2wnkjzfmxswnknjiwrjrn-foo-fib-7
compressing and pushing /nix/store/ih1jzl51hcahsi9dikbn040888jb4hb9-foo-fib-7.drv (1.82 KiB)
compressing and pushing /nix/store/nwd8xbar6rwbiqz05ndwgkchw6mbyp3c-foo-fib-5 (288.00 B)
compressing and pushing /nix/store/vrzxqqj6q11lgpizsd78r2cx2c7zfban-foo-fib-6 (288.00 B)
compressing and pushing /nix/store/m3sspba1wz9ffp5qyjplg8fjbnhy7d73-foo-fib-5.drv (1.82 KiB)
compressing and pushing /nix/store/zhc126b7clx2wnkjzfmxswnknjiwrjrn-foo-fib-7 (288.00 B)
compressing and pushing /nix/store/zyhq28hxak4jk7xak6lixa4lbfxdjwvz-foo-fib-6.drv (1.82 KiB)
All done.
```



```bash
$ drv=$(nix-instantiate -E '
  import ./code/04-derivations/03-fibonacci/fib.nix
    "bar" 4
')
```


```bash
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
these derivations will be built:
  /nix/store/a44j7217bvmh415a2addg8v6yvzawcqw-bar-fib-1.drv
  /nix/store/dhdcjy4r1r9rw5np91mgjd3yfsam9q0d-bar-fib-0.drv
  /nix/store/hwqf5pc5im5arcr1lg57s96zhb9mqwaw-bar-fib-2.drv
  /nix/store/i77c7ma4sdwx6cw2p0k23pkqqvmbmi3q-bar-fib-3.drv
  /nix/store/dhvm4d289zzz0v569mz4sffm3r0f8hk3-bar-fib-4.drv
building '/nix/store/dhdcjy4r1r9rw5np91mgjd3yfsam9q0d-bar-fib-0.drv'...
...
compressing and pushing /nix/store/08hv7bz0mmhjzg8n97r61qxcxggsgfqa-bar-fib-3 (288.00 B)
compressing and pushing /nix/store/dhdcjy4r1r9rw5np91mgjd3yfsam9q0d-bar-fib-0.drv (1.41 KiB)
compressing and pushing /nix/store/dhvm4d289zzz0v569mz4sffm3r0f8hk3-bar-fib-4.drv (1.82 KiB)
compressing and pushing /nix/store/a44j7217bvmh415a2addg8v6yvzawcqw-bar-fib-1.drv (1.41 KiB)
compressing and pushing /nix/store/hwqf5pc5im5arcr1lg57s96zhb9mqwaw-bar-fib-2.drv (1.82 KiB)
compressing and pushing /nix/store/i77c7ma4sdwx6cw2p0k23pkqqvmbmi3q-bar-fib-3.drv (1.82 KiB)
compressing and pushing /nix/store/hnv7grj1iwr4flrgxgb1nqlgwlbq6l0q-bar-fib-1 (288.00 B)
compressing and pushing /nix/store/php68w3q89r9rc1qaqswj5i132xrpkgf-bar-fib-2 (288.00 B)
compressing and pushing /nix/store/vc1v4ar8x69g90zfh0838imrky01j82r-bar-fib-4 (288.00 B)
compressing and pushing /nix/store/xwwjcif66j752gizc5m76nrl0g9f1vp8-bar-fib-0 (288.00 B)
All done.
```

## Evaluation-time Dependencies

```bash
$ drv=$(nix-instantiate -E '
  import ./code/04-derivations/03-fibonacci/fib-serialized.nix
    "bar" 4
')
building '/nix/store/dcjdgkddn532k2r1jvnfqxax1q29akcr-bar-fib-2.drv'...
...
checking for references to /tmp/nix-build-bar-fib-3.drv-0/ in /nix/store/x2sff6cgg4pdj0lz1jz9wkxbg5mdq622-bar-fib-3...
```

```bash
$ nix-build $drv && nix-store -qR --include-outputs $drv | cachix push $CACHIX_STORE
these derivations will be built:
  /nix/store/i8xrxxqnsjh83gpzhx7giwzcf6zl8v29-bar-fib-4.drv
building '/nix/store/i8xrxxqnsjh83gpzhx7giwzcf6zl8v29-bar-fib-4.drv'...
...
/nix/store/pzbrdava4phdgcxmls7nyrv0b2sysgcg-bar-fib-4
compressing and pushing /nix/store/i8xrxxqnsjh83gpzhx7giwzcf6zl8v29-bar-fib-4.drv (1.52 KiB)
compressing and pushing /nix/store/pzbrdava4phdgcxmls7nyrv0b2sysgcg-bar-fib-4 (288.00 B)
All done.
```
