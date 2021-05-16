# Standard ML and Haskell

> Written by Paul Buetow 2010-04-09

I am currently looking into the functional programming language Standard ML (aka SML). The purpose is to refresh my functional programming skills and to learn something new too. Since I already know a little Haskell, could I do not help myself and I implemented the same exercises in Haskell too.

As you will see, SML and Haskell are very similar (at least when it comes to the basics). However, the syntax of Haskell is a bit more "advanced". Haskell utilizes fewer keywords (e.g. no val, end, fun, fn ...). Haskell also allows to explicitly write down the function types. What I have been missing in SML so far is the so-called pattern guards. Although this is a very superficial comparison for now, so far I like Haskell more than SML. Nevertheless, I thought it would be fun to demonstrate a few simple functions of both languages to show off the similarities. 

Haskell is also a "pure functional" programming language, whereas SML also makes explicit use of imperative concepts. I am by far not a specialist in either of these languages but here are a few functions implemented in both, SML and Haskell:

## Defining a multi data type

Standard ML:

```
datatype ’a multi
	= EMPTY
	| ELEM of ’a
	| UNION of ’a multi * ’a multi
```

Haskell:

```
data (Eq a) => Multi a
    = Empty
    | Elem a
    | Union (Multi a) (Multi a)
    deriving Show
```

## Processing a multi

Standard ML:

```
fun number (EMPTY) _ = 0
	| number (ELEM x) w = if x = w then 1 else 0
	| number (UNION (x,y)) w = (number x w) + (number y w)
fun test_number w = number (UNION (EMPTY, \
    UNION (ELEM 4, UNION (ELEM 6, \
    UNION (UNION (ELEM 4, ELEM 4), EMPTY))))) w 
```

Haskell:

```
number Empty _ = 0
number (Elem x) w = if x == w then 1 else 0
test_number w = number (Union Empty \
    (Union (Elem 4) (Union (Elem 6) \
    (Union (Union (Elem 4) (Elem 4)) Empty)))) w
```

## Simplify function

Standard ML:

```
fun simplify (UNION (x,y)) =
    let fun is_empty (EMPTY) = true | is_empty _ = false
        val x’ = simplify x
        val y’ = simplify y
    in if (is_empty x’) andalso (is_empty y’)
            then EMPTY
       else if (is_empty x’)
            then y’
       else if (is_empty y’)
            then x’
       else UNION (x’, y’)
    end
  | simplify x = x
```

Haskell:

```
simplify (Union x y)
    | (isEmpty x’) && (isEmpty y’) = Empty
    | isEmpty x’ = y’
    | isEmpty y’ = x’
    | otherwise = Union x’ y’
    where
        isEmpty Empty = True
        isEmpty _ = False
        x’ = simplify x
        y’ = simplify y
simplify x = x
```

## Delete all

Standard ML:

```
fun delete_all m w =
    let fun delete_all’ (ELEM x) = if x = w then EMPTY else ELEM x
          | delete_all’ (UNION (x,y)) = UNION (delete_all’ x, delete_all’ y)
          | delete_all’ x = x
    in simplify (delete_all’ m)
    end
```

Haskell:

```
delete_all m w = simplify (delete_all’ m)
    where
        delete_all’ (Elem x) = if x == w then Empty else Elem x
        delete_all’ (Union x y) = Union (delete_all’ x) (delete_all’ y)
        delete_all’ x = x
```

## Delete one

Standard ML:

```
fun delete_one m w =
    let fun delete_one’ (UNION (x,y)) =
            let val (x’, deleted) = delete_one’ x
                in if deleted
                   then (UNION (x’, y), deleted)
                   else let val (y’, deleted) = delete_one’ y
                       in (UNION (x, y’), deleted)
                   end
                end
          | delete_one’ (ELEM x) =
            if x = w then (EMPTY, true) else (ELEM x, false)
          | delete_one’ x = (x, false)
            val (m’, _) = delete_one’ m
        in simplify m’
    end
```

Haskell:

```
delete_one m w = do
    let (m’, _) = delete_one’ m
    simplify m’
    where
        delete_one’ (Union x y) =
            let (x’, deleted) = delete_one’ x
            in if deleted
                then (Union x’ y, deleted)
                else let (y’, deleted) = delete_one’ y
                    in (Union x y’, deleted)
        delete_one’ (Elem x) =
            if x == w then (Empty, True) else (Elem x, False)
        delete_one’ x = (x, False)
```

## Higher order functions

The first line is always the SML code, the second line always the Haskell variant:

```
fun make_map_fn f1 = fn (x,y) => f1 x :: y
make_map_fn f1 = \x y -> f1 x : y

fun make_filter_fn f1 = fn (x,y) => if f1 x then x :: y else y
make_filter_fn f1 = \x y -> if f1 then x : y else y

fun my_map f l = foldr (make_map_fn f) [] l
my_map f l = foldr (make_map_fn f) [] l

fun my_filter f l = foldr (make_filter_fn f) [] l
my_filter f l = foldr (make_filter_fn f) [] l
```

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  