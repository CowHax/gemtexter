# The Fype Programming Language

```
      ____                                      _        __       
     / / _|_   _ _ __   ___    _   _  ___  __ _| |__    / _|_   _ 
    / / |_| | | | '_ \ / _ \  | | | |/ _ \/ _` | '_ \  | |_| | | |
 _ / /|  _| |_| | |_) |  __/  | |_| |  __/ (_| | | | |_|  _| |_| |
(_)_/ |_|  \__, | .__/ \___|   \__, |\___|\__,_|_| |_(_)_|  \__, |
           |___/|_|            |___/                        |___/ 
```

> Written by Paul Buetow 2010-05-09, last updated 2021-05-05

Fype is an interpreted programming language created by me for learning and fun. The interpreter is written in C. It has been tested on FreeBSD and NetBSD and may also work on other Unix like operating systems such as Linux based ones. To be honest, besides learning and fun there is really no other use case of why Fype actually exists as many other programming languages are much faster and more powerful.

The Fype syntax is very simple and is using a maximum look ahead of 1 and a very easy top down parsing mechanism. Fype is parsing and interpreting its code simultaneously. This means, that syntax errors are only detected during program runtime. 

Fype is a recursive acronym and means "Fype is For Your Program Execution" or "Fype is Free Yak Programmed for ELF". You could also say "It's not a hype - it's Fype!".

## Object oriented C style

The Fype interpreter is written in an object oriented style of C. Each "main component" has its own .h and .c file. There is a struct type for each (most components at least) component which can be initialized using a "COMPONENT_new" function and destroyed using a "COMPONENT_delete" function. Method calls follow the same schema, e.g. "COMPONENT_METHODNAME". There is no such as class inheritance and polymorphism involved. 

To give you an idea how it works here as an example is a snippet from the main Fype "class header":

```
typedef struct {
   Tupel *p_tupel_argv; // Contains command line options
   List *p_list_token; // Initial list of token
   Hash *p_hash_syms; // Symbol table
   char *c_basename;
} Fype;
```

And here is a snippet from the main Fype "class implementation":

```
Fype*
fype_new() {
   Fype *p_fype = malloc(sizeof(Fype));

   p_fype->p_hash_syms = hash_new(512);
   p_fype->p_list_token = list_new();
   p_fype->p_tupel_argv = tupel_new();
   p_fype->c_basename = NULL;

   garbage_init();

   return (p_fype);
}

void
fype_delete(Fype *p_fype) {
   argv_tupel_delete(p_fype->p_tupel_argv);

   hash_iterate(p_fype->p_hash_syms, symbol_cleanup_hash_syms_cb);
   hash_delete(p_fype->p_hash_syms);

   list_iterate(p_fype->p_list_token, token_ref_down_cb);
   list_delete(p_fype->p_list_token);

   if (p_fype->c_basename)
      free(p_fype->c_basename);

   garbage_destroy();
}

int
fype_run(int i_argc, char **pc_argv) {
   Fype *p_fype = fype_new();

   // argv: Maintains command line options
   argv_run(p_fype, i_argc, pc_argv);

   // scanner: Creates a list of token
   scanner_run(p_fype);

   // interpret: Interpret the list of token
   interpret_run(p_fype);

   fype_delete(p_fype);

   return (0);
}
```

## Data types

Fype uses auto type conversion. However, if you want to know what's going on you may take a look at the following basic data types:
* integer - Specifies a number
* double - Specifies a double precision number
* string - Specifies a string
* number - May be an integer or a double number
* any- May be any type above
* void - No type
* identifier - It's a variable name or a procedure name or a function name

There is no boolean type, but we can use the integer values 0 for false and 1 for true. There is support for explicit type casting too.

## Syntax

### Comments

Text from a # character until the end of the current line is considered being a comment. Multi line comments may start with an #* and with a *# anywhere. Exceptions are if those signs are inside of strings.

### Variables

Variables can be defined with the "my" keyword (inspired by Perl :-). If you don't assign a value during declaration, then it's using the default integer value 0. Variables may be changed during program runtime. Variables may be deleted using the "undef" keyword! Example:

```
my foo = 1 + 2;
say foo; 

my bar = 12, baz = foo;
say 1 + bar;
say bar;

my baz;
say baz; # Will print out 0
```

You may use the "defined" keyword to check if an identifier has been defined or not:

```
ifnot defined foo {
	say "No foo yet defined";
}

my foo = 1;

if defined foo {
	put "foo is defined and has the value ";
	say foo;
}
```

### Synonyms

Each variable can have as many synonyms as wished. A synonym is another name to access the content of a specific variable. Here is an example of how to use is:

```
my foo = "foo";
my bar = \foo;
foo = "bar";

# The synonym variable should now also set to "bar"
assert "bar" == bar;
```

Synonyms can be used for all kind of identifiers. It's not limited to normal variables but can be also used for function and procedure names etc (more about functions and procedures later).

```
# Create a new procedure baz
proc baz { say "I am baz"; }

# Make a synonym baz, and undefine baz
my bay = \baz;

undef baz;

# bay still has a reference of the original procedure baz
bay; # this prints aut "I am baz" 
```

The "syms" keyword gives you the total number of synonyms pointing to a specific value:

```
my foo = 1;
say syms foo; # Prints 1

my baz = \foo; 
say syms foo; # Prints 2
say syms baz; # Prints 2

undef baz;
say syms foo; # Prints 1
```

## Statements and expressions

A Fype program is a list of statements. Each keyword, expression or function call is part of a statement. Each statement is ended with a semicolon. Example:

```
my bar = 3, foo = 1 + 2; 
say foo;
exit foo - bar;
```

### Parenthesis

All parenthesis for function arguments are optional. They help to make the code better readable. They also help to force precedence of expressions.

### Basic expressions

Any "any" value holding a string will be automatically converted to an integer value.

```
(any) <any> + <any>
(any) <any> - <any>
(any) <any> * <any>
(any) <any> / <any>
(integer) <any> == <any>
(integer) <any> != <any>
(integer) <any> <= <any>
(integer) <any> gt <any>
(integer) <any> <> <any>
(integer) <any> gt <any>
(integer) not <any>
```

### Bitwise expressions

```
(integer) <any> :< <any>
(integer) <any> :> <any>
(integer) <any> and <any>
(integer) <any> or <any>
(integer) <any> xor <any>
```

### Numeric expressions

```
(number) neg <number>
```

... returns the negative value of "number":

```
(integer) no <integer>
```

... returns 1 if the argument is 0, otherwise it will return 0! If no argument is given, then 0 is returned!

```
(integer) yes <integer>
```

... always returns 1. The parameter is optional. Example:

```
# Prints out 1, because foo is not defined
if yes { say no defined foo; } 
```

## Control statements

Control statements available in Fype:

```
if <expression> { <statements> }
```

... runs the statements if the expression evaluates to a true value.

```
ifnot <expression> { <statements> }
```

... runs the statements if the expression evaluates to a false value.

```
while <expression> { <statements> }
```

... runs the statements as long as the expression evaluates to a true value.

```
until <expression> { <statements> }
```

... runs the statements as long as the expression evaluates to a false value.

## Scopes

A new scope starts with an { and ends with an }. An exception is a procedure, which does not use its own scope (see later in this manual). Control statements and functions support scopes.  The "scope"  function prints out all available symbols at the current scope. Here is a small example:

```
my foo = 1;

{
	# Prints out 1
	put defined foo;
	{
		my bar = 2;

		# Prints out 1
		put defined bar;

		# Prints out all available symbols at this
		# point to stdout. Those are: bar and foo
		scope;
	}

	# Prints out 0
	put defined bar;

	my baz = 3;
}

# Prints out 0
say defined bar;
```

Another example including an actual output:

```
./fype -e ’my global; func foo { my var4; func bar { my var2, var3; func baz { my var1; scope; } baz; } bar; } foo;’
Scopes:
Scope stack size: 3
Global symbols:
SYM_VARIABLE: global (id=00034, line=-0001, pos=-001, type=TT_INTEGER, dval=0.000000, refs=-1)
SYM_FUNCTION: foo
Local symbols:
SYM_VARIABLE: var1 (id=00038, line=-0001, pos=-001, type=TT_INTEGER, dval=0.000000, refs=-1)
1 level(s) up:
SYM_VARIABLE: var2 (id=00036, line=-0001, pos=-001, type=TT_INTEGER, dval=0.000000, refs=-1)
SYM_VARIABLE: var3 (id=00037, line=-0001, pos=-001, type=TT_INTEGER, dval=0.000000, refs=-1)
SYM_FUNCTION: baz
2 level(s) up:
SYM_VARIABLE: var4 (id=00035, line=-0001, pos=-001, type=TT_INTEGER, dval=0.000000, refs=-1)
SYM_FUNCTION: bar
```

## Definedness 

```
(integer) defined <identifier>
```

... returns 1 if "identifier" has been defined. Returns 0 otherwise.

```
(integer) undef <identifier>
```

... tries to undefine/delete the "identifier". Returns 1 if it succeeded, otherwise 0 is returned.

## System 

These are some system and interpreter specific built-in functions supported:

```
(void) end
```

... exits the program with the exit status of 0.

```
(void) exit <integer>
```

... exits the program with the specified exit status.

```
(integer) fork
```

... forks a subprocess. It returns 0 for the child process and the pid of the child process otherwise! Example:

```
my pid = fork;

if pid {
	put "I am the parent process; child has the pid ";
	say pid;

} ifnot pid {
	say "I am the child process";
}
```

To execute the garbage collector do:

```
(integer) gc
```

It returns the number of items freed! You may wonder why most of the time it will return a value of 0! Fype tries to free not needed memory ASAP. This may change in future versions in order to gain faster execution speed!

### I/O 

```
(any) put <any>
```

... prints out the argument

```
(any) say <any>
```

is the same as put, but also includes an ending newline.

```
(void) ln
```

... just prints a newline.

## Procedures and functions

### Procedures

A procedure can be defined with the "proc" keyword and deleted with the "undef" keyword. A procedure does not return any value and does not support parameter passing. It's using already defined variables (e.g. global variables). A procedure does not have its own namespace. It's using the calling namespace. It is possible to define new variables inside of a procedure in the current namespace.

```
proc foo {
	say 1 + a * 3 + b;
	my c = 6;
}

my a = 2, b = 4;

foo; # Run the procedure. Print out "11\n"
say c; # Print out "6\n";
```

### Nested procedures

It's possible to define procedures inside of procedures. Since procedures don't have its own scope, nested procedures will be available to the current scope as soon as the main procedure has run the first time. You may use the "defined" keyword in order to check if a procedure has been defined or not.

```
proc foo {
	say "I am foo";

	undef bar;
	proc bar {
		say "I am bar";
	}
}

# Here bar would produce an error because 
# the proc is not yet defined!
# bar; 

foo; # Here the procedure foo will define the procedure bar!
bar; # Now the procedure bar is defined!
foo; # Here the procedure foo will redefine bar again!
```

### Functions

A function can be defined with the "func" keyword and deleted with the "undef" keyword. Function do not yet return values and do not yet supports parameter passing. It's using local (lexical scoped) variables. If a certain variable does not exist, when It's using already defined variables (e.g. one scope above). 

```
func foo {
	say 1 + a * 3 + b;
	my c = 6;
}

my a = 2, b = 4;

foo; # Run the procedure. Print out "11\n"
say c; # Will produce an error, because c is out of scoped!
```

### Nested functions

Nested functions work the same way the nested procedures work, with the exception that nested functions will not be available anymore after the function has been left!

```
func foo {
	func bar {
		say "Hello i am nested";
	}

	bar; # Calling nested
}

foo;
bar; # Will produce an error, because bar is out of scope!
```

## Arrays

Some progress on arrays has been made too. The following example creates a multi dimensional array "foo". Its first element is the return value of the func which is "bar". The fourth value is a string ”3” converted to a double number. The last element is an anonymous array which itself contains another anonymous array as its last element:

```
func bar { say ”bar” }
my foo = [bar, 1, 4/2, double ”3”, [”A”, [”BA”, ”BB”]]];
say foo;
```

It produces the following output:

```
% ./fype arrays.fy
bar
01
2
3.000000
A
BA
BB
```

## Fancy stuff

Fancy stuff like OOP or Unicode or threading is not planed. But fancy stuff like function pointers and closures may be considered.:) 

## May the source be with you

You can find all of this on the GitHub page. There is also an "examples" folders containing some Fype scripts!

[https://github.com/snonux/fype](https://github.com/snonux/fype)  

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  