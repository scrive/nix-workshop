# Nix Expressions

## If Expression

```
nix-repl> if true then 0 else 1
0

nix-repl> if false then 0 else "foo"
"foo"

nix-repl> if null then 1 else 2
error: value is null while a Boolean was expected
```

## Let Expression

```
nix-repl> let
            foo = "foo val";
            bar = "bar val";
          in
          { inherit foo bar; }
{ bar = "bar val"; foo = "foo val"; }
```

## Function

```
nix-repl> greet = name: "Hello, ${name}!"

nix-repl> greet "Alice"
"Hello, Alice!"

nix-repl> greet "Bob"
"Hello, Bob!"
```

## Curried Function

```
nix-repl> secret-greet = code: name:
            if code == "secret"
            then "Hello, ${name}!"
            else "Nothing here"

nix-repl> secret-greet "secret" "John"
"Hello, John!"

nix-repl> nothing = secret-greet "wrong"

nix-repl> nothing "Alice"
"Nothing here"

nix-repl> nothing "Bob"
"Nothing here"
```

## Named Arguments

```
nix-repl> greet = { name, title }: "Hello, ${title} ${name}"

nix-repl> greet { title = "Ms."; name = "Alice"; }
"Hello, Ms. Alice"

nix-repl> greet { name = "Alice"; }
error: anonymous function at (string):1:2 called without required argument 'title', at (string):1:1
```

## Default Arguments

```
nix-repl> greet = { name ? "Anonymous", title ? "Ind." }: "Hello, ${title} ${name}"

nix-repl> greet {}
"Hello, Ind. Anonymous"

nix-repl> greet { name = "Bob"; }
"Hello, Ind. Bob"

nix-repl> greet { title = "Mr."; }
"Hello, Mr. Anonymous"
```

## Lazy Evaluation

```
nix-repl> err = throw "something went wrong"

nix-repl> err
error: something went wrong

nix-repl> if true then 1 else err
1

nix-repl> if false then 1 else err
error: something went wrong

nix-repl> object = { foo = err; bar = "bar val"; }

nix-repl> object.bar
"bar val"

nix-repl> object.foo
error: something went wrong
```