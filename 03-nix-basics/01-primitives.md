# Nix Primitives

## Strings

```
nix-repl> "hello"
"hello"
```

## Booleans

```
nix-repl> true
true

nix-repl> false
false

nix-repl> true && false
false

nix-repl> true || false
true
```

## Null

```
nix-repl> null
null

nix-repl> true && null
error: value is null while a Boolean was expected, at (string):1:1
```

## Numbers

```
nix-repl> 1
1

nix-repl> 2
2

nix-repl> 1 + 2
3
```

## String Interpolation

```
nix-repl> name = "John"

nix-repl> name
"John"

nix-repl> "Hello, ${name}!"
"Hello, John!"
```

## Multi Line Strings

```
nix-repl> ''
            Lorem ipsum dolor sit amet, consectetur adipiscing elit.
              Nullam augue ligula, pharetra quis mi porta.

            - ${name}
          ''
"Lorem ipsum dolor sit amet, consectetur adipiscing elit.\n  Nullam augue ligula, pharetra quis mi porta.\n\n- John\n"
```

## String Concatenation

```
nix-repl> "Hello " + "World"
"Hello World"

nix-repl> "Hello " + 123
error: cannot coerce an integer to a string, at (string):1:1
```

## Set / Object

```
nix-repl> object = { foo = "foo val"; bar = "bar val"; }

nix-repl> object
{ bar = "bar val"; foo = "foo val"; }

nix-repl> object.foo
"foo val"

nix-repl> object.bar
"bar val"
```

## Merge Objects

```
nix-repl> a = { foo = "foo val"; bar = "bar val"; }

nix-repl> b = { foo = "override"; baz = "baz val"; }

nix-repl> a // b
{ bar = "bar val"; baz = "baz val"; foo = "override"; }
```

## Inherit

```
nix-repl> foo = "foo val"

nix-repl> bar = "bar val"

nix-repl> { foo = foo; bar = bar; }
{ bar = "bar val"; foo = "foo val"; }

nix-repl> { inherit foo bar; }
{ bar = "bar val"; foo = "foo val"; }
```

## List

```
nix-repl> list = [ "hello" 123 { foo = "foo"; } ]

nix-repl> list
[ "hello" 123 { ... } ]

nix-repl> builtins.elemAt list 2
{ foo = "foo"; }
```

## List Concatenation

```
nix-repl> [ 1 2 ] ++ [ "foo" "bar" ]
[ 1 2 "foo" "bar" ]
```
