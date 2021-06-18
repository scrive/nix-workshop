# File Management in Nix

## String to File

```nix
nix-repl> builtins.toFile "hello.txt" "Hello World!"
"/nix/store/r4mvpxzh7rgrm4j831b2yi90zq64grqm-hello.txt"
```

```bash
$ cat /nix/store/r4mvpxzh7rgrm4j831b2yi90zq64grqm-hello.txt
Hello World!
```


## Path

```nix
nix-repl> ./.
/path/to/nix-workshop

nix-repl> ./code/01-getting-started
/path/to/nix-workshop/code/01-getting-started

nix-repl> ./not-found
/path/to/nix-workshop/not-found
```

## Path Concatenation

```nix
nix-repl> ./. + "code/01-getting-started"
/path/to/nix-workshop/code/01-getting-started
```

## Read File

```nix
nix-repl> builtins.readFile ./code/03-nix-basics/03-files/hello.txt
"Hello World!"

nix-repl> builtins.readFile /nix/store/r4mvpxzh7rgrm4j831b2yi90zq64grqm-hello.txt
"Hello World!"

nix-repl> builtins.readFile (builtins.toFile "hello" "Hello World!")
"Hello World!"
```

## Path

```nix
nix-repl> builtins.path { path = ./.; }
"/nix/store/s0c3cc8k6dy51zx9xicfprsl9r35zvf6-nix-workshop"
```

```nix
nix-repl> "${./.}"
"/nix/store/s0c3cc8k6dy51zx9xicfprsl9r35zvf6-nix-workshop"
```

```
$ ls /nix/store/s0c3cc8k6dy51zx9xicfprsl9r35zvf6-nix-workshop
01-getting-started  02-nix-commands ...
```

The exact address changes every time the directory is updated.

## Named Path

```nix
nix-repl> workshop = builtins.path { path = ./.; name = "first-scrive-workshop"; }

nix-repl> workshop
"/nix/store/fp0lw035xhxqwgfqifxlb430lyw48r7m-first-scrive-workshop"

nix-repl> builtins.readFile (workshop + "/code/03-nix-basics/03-files/hello.txt")
"Hello World!"
```

## Content-Addressable Path

The files [hello.txt](03-files/hello.txt) and [hello-2.txt](03-files/hello-2.txt)
both have the same content `"Hello World!"`, but they produce different artifacts
in the Nix store, i.e. the name of a Nix artifact depends on the name of the
original file / directory.

```nix
nix-repl> builtins.path { path = ./code/03-nix-basics/03-files/hello.txt; }
"/nix/store/925f1jb1ajrypjbyq7rylwryqwizvhp0-hello.txt"

nix-repl> builtins.path { path = ./code/03-nix-basics/03-files/hello-2.txt; }
"/nix/store/bghk1lsjcylfm05j00zj5j42lv09i79z-hello-2.txt"
```

Solution: give a fixed name to path artifacts:

```nix
nix-repl> builtins.path {
            name = "hello.txt";
            path = ./code/03-nix-basics/03-files/hello-2.txt;
          }
"/nix/store/925f1jb1ajrypjbyq7rylwryqwizvhp0-hello.txt"
```


## Fetch URL

```nix
nix-repl> example = builtins.fetchurl "https://scrive.com/robots.txt"

nix-repl> example
[0.0 MiB DL] downloading 'https://scrive.com/robots.txt'"/nix/store/r98i29hkzwyykm984fpr4ldbai2r8lhj-robots.txt"

nix-repl> example
"/nix/store/r98i29hkzwyykm984fpr4ldbai2r8lhj-robots.txt"
```

```bash
$ cat /nix/store/r98i29hkzwyykm984fpr4ldbai2r8lhj-robots.txt
User-agent: *
Sitemap: https://scrive.com/sitemap.xml
Disallow: /amnesia/
Disallow: /api/
```

URLs are only fetched once locally!

## Fetch Tarball

```bash
nix-repl> nodejs-src = builtins.fetchTarball
            "https://nodejs.org/dist/v14.15.0/node-v14.15.0-linux-x64.tar.xz"
nix-repl> nodejs-src
"/nix/store/6wkj0blipzdqbsvwv03qy57n4l33scpw-source"
```

```bash
$ ls /nix/store/6wkj0blipzdqbsvwv03qy57n4l33scpw-source
bin  CHANGELOG.md  include  lib  LICENSE  README.md  share
```

## SHA256 Checksum

Make sure that the content retrieved is the same for all users.

```bash
nix-repl> nodejs-src = builtins.fetchTarball {
            name = "nodejs-src";
            url = "https://nodejs.org/dist/v14.15.0/node-v14.15.0-linux-x64.tar.xz";
            sha256 = "14jmakaxmlllyyprydc6826s7yk50ipvmwwrkzf6pdqis04g7a9v";
          }
nix-repl> nodejs-src
"/nix/store/6wkj0blipzdqbsvwv03qy57n4l33scpw-source"
```
