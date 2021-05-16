# Personal Bash coding style guide

```
   .---------------------------.
  /,--..---..---..---..---..--. `.
 //___||___||___||___||___||___\_|
 [j__ ######################## [_|
    \============================|
 .==|  |"""||"""||"""||"""| |"""||
/======"---""---""---""---"=|  =||
|____    []*          ____  | ==||
//  \\               //  \\ |===||  hjw
"\__/"---------------"\__/"-+---+'
```                     

> Written by Paul Buetow 2021-05-16

Lately, I have been polishing and writing a lot of Bash code. Not that I never wrote a lot of Bash, but now as I also looked through the "Google Shell Style Guide" I thought it is time to also write my own thoughts on that. I agree to that guide in most, but not in all points. 

[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)  

## My modifications

These are my personal modifications of the Google Guide.

### Shebang

Google recommends using always

```
#!/bin/bash 
```

as the shebang line. But that does not really work on all Unix and Unix like operating systems (e.g. the *BSDs don't have Bash installed to /bin/bash). Better is:

```
#!/usr/bin/env bash
```

### 2 space soft-tabs indentation

I know there have been many tab- and soft-tab wars on this planet. Google recommends using 2 space soft-tabs for Bash scripts. 

I personally don't really care if I use 2 or 4 space indentations. I agree however that tabs should not be used. I personally tend to use 4 space soft-tabs as that's currently how my Vim is configured for any programming language. What matters most though is consistency within the same script/project.

Google also recommends limiting the line length to 80 characters. For some people that seem's to be an ancient habit from the 80's, where all computer terminals couldn't display longer lines. But I think that the 80 character mark is still a good practice at least for shell scripts. For example, I am often writing code on a Microsoft Go Tablet PC (running Linux of course) and it comes in very handy if the lines are not too long due to the relatively small display on the device.

I hit the 80 character line length quicker with the 4 spaces than with 2 spaces, but that makes me refactor the Bash code more aggressively which is actually a good thing. 

### Breaking long pipes

Google recommends breaking up long pipes like this:

```
# All fits on one line
command1 | command2

# Long commands
command1 \
  | command2 \
  | command3 \
  | command4
```

I think there is a better way like the following, which is less noisy. The pipe | already indicates the Bash that another command is expected, thus making the explicit line breaks with \ obsolete:

```
# Long commands
command1 |
    command2 |
    command3 |
    command4
```

### Quoting your variables

Google recommends to always quote your variables. I think generally you should do that only for variables where you are unsure about the content/values of the variables (e.g. content is from an external input source and may contains whitespace or other special characters). In my opinion, the code will become quite noisy when you always quote your variables like this:

```
greet () {
    local -r greeting="${1}"
    local -r name="${2}"
    echo "${greeting} ${name}!"
}
```

In this particular example I agree that you should quote them as you don't really know what is the input (are there for example whitespace characters?). But if you are sure that you are only using simple bare words then I think that the code looks much cleaner when you do this instead:

```
say_hello_to_paul () {
    local -r greeting=Hello
    local -r name=Paul
    echo "$greeting $name!"
}
```

You see I also omitted the curly braces { } around the variables. I only use the curly braces around variables when it makes the code either easier/clearer to read or if it is necessary to use them:

```
declare FOO=bar
# Curly braces around FOO are necessary
echo "foo${FOO}baz"
```

A few more words on always quoting the variables: For the sake of consistency (and for the sake of making ShellCheck happy) I am not against quoting everything I encounter. I personally also think that the larger the Bash script becomes, the more important it becomes to always quote variables. That's because it will be more likely that you might not remember that some of the functions don't work on values with spaces in it for example.  It's just that I won't quote everything in every small script I write. 

### Prefer builtin commands over external commands

Google recommends using the builtin commands over external available commands where possible:

```
# Prefer this:
addition=$(( X + Y ))
substitution="${string/#foo/bar}"

# Instead of this:
addition="$(expr "${X}" + "${Y}")"
substitution="$(echo "${string}" | sed -e 's/^foo/bar/')"
```

I don't agree fully here. The external commands (especially sed) are much more sophisticated and powerful than the Bash builtin versions. Sed can do much more than the Bash can ever do natively when it comes to text manipulation (the name "sed" stands for streaming editor after all).

I prefer to do light text processing with the Bash builtins and more complicated text processing with external programs such as sed, grep, awk, cut and tr. There is however also the case of medium-light text processing where I would want to use external programs too. That is so because I remember using them better than the Bash builtins. The Bash can get quite obscure here (even Perl will be more readable then - Side note: I love Perl).

Also, you would like to use an external command for floating-point calculation (e.g. bc) instead using the Bash builtins (worth noticing that ZSH supports builtin floating-points).

I even didn't get started what you can do with Awk (especially GNU Awk), a fully fledged programming language. Tiny Awk snippets tend to be used quite often in Shell scripts without honouring the real power of Awk. But if you did everything in Perl or Awk or another scripting language, then it wouldn't be a Bash script anymore, wouldn't it? ;-)

## My additions

### Use of 'yes' and 'no'

Bash does not support a boolean type. I tend to just use the strings 'yes' and 'no' here. For some time I used 0 for false and 1 for true, but I think that the yes/no strings are easier to read. Yes, the Bash script would need to perform string comparisons on every check, but if performance is important to you, you wouldn't want to use a Bash script anyway, correct?

```
declare -r SUGAR_FREE=yes
declare -r I_NEED_THE_BUZZ=no

buy_soda () {
    local -r sugar_free=$1

    if [[ $sugar_free == yes ]]; then
        echo 'Diet Dr. Pepper'
    else
        echo 'Pepsi Coke'
    fi
}

buy_soda $I_NEED_THE_BUZZ
```

### Non-evil alternative to variable assignments via eval

Google is in the opinion that eval should be avoided. I think so too. They list these examples in their guide:

```
# What does this set?
# Did it succeed? In part or whole?
eval $(set_my_variables)

# What happens if one of the returned values has a space in it?
variable="$(eval some_function)"

```

However, if I want to read variables from another file I don't have to use eval here. I just source the file:

```
% cat vars.source.sh
declare foo=bar
declare bar=baz
declare bay=foo

% bash -c 'source vars.source.sh; echo $foo $bar $baz'
bar baz foo
```

And if I want to assign variables dynamically then I could just run an external script and source its output (This is how you could do metaprogramming in Bash without the use of eval - write code which produces code for immediate execution):

```
% cat vars.sh
#!/usr/bin/env bash
cat <<END
declare date="$(date)"
declare user=$USER
END

% bash -c 'source <(./vars.sh); echo "Hello $user, it is $date"'
Hello paul, it is Sat 15 May 19:21:12 BST 2021
```

The downside is that ShellCheck won't be able to follow the dynamic sourcing anymore.

### Prefer pipes over arrays for list processing

When I do list processing in Bash, I prefer to use pipes. You can chain then through Bash functions as well which is pretty neat. Usually my list processing scripts are of a structure like this:

```
filter_lines () {
    echo 'Start filtering lines in a fancy way!' >&2
    grep ... | sed ....
}

process_lines () {
    echo 'Start processing line by line!' >&2
    while read -r line; do
        ... do something and produce a result...
        echo "$result"
    done 
}

# Do some post processing of the data
postprocess_lines () {
    echo 'Start removing duplicates!' >&2
    sort -u
}

genreate_report () {
    echo 'My boss wants to have a report!' >&2
    tee outfile.txt
    wc -l outfile.txt
}

main () {
    filter_lines |
        process_lines |
        postprocess_lines |
        generate_report
}

main
```

The stdout is always passed as a pipe to the next following stage. The stderr is used for info logging.

### Assign-then-shift

I often refactor existing Bash code. That leads me to adding and removing function arguments quite often. It's quite repetitive work changing the $1, $2.... function argument numbers every time you change the order or add/remove possible arguments.

The solution is to use of the "assign-then-shift"-method, which goes like this: "local -r var1=$1; shift; local -r var2=$1; shift". The idea is that you only use "$1" to assign function arguments to named (better readable) local function variables. You will never have to bother about "$2" or above. That is very useful when you constantly refactor your code and remove or add function arguments. It's something what I picked up from a colleague (a pure Bash wizard) some time ago:

```
some_function () {
    local -r param_foo="$1"; shift
    local -r param_baz="$1"; shift
    local -r param_bay="$1"; shift
    ...
}
```

Want to add a param_baz? Just do this:

```
some_function () {
    local -r param_foo="$1"; shift
    local -r param_bar="$1"; shift
    local -r param_baz="$1"; shift
    local -r param_bay="$1"; shift
    ...
}
```

Want to remove param_foo? Nothing easier than that:

```
some_function () {
    local -r param_bar="$1"; shift
    local -r param_baz="$1"; shift
    local -r param_bay="$1"; shift
    ...
}
```

As you can see I didn't need to change any other assignments within the function. Of course you would also need to change the function argument lists at every occasion where the function is invoked - you would do that within the same refactoring session.

### Paranoid mode

I call this the paranoid mode. The Bash will stop executing when a command exists with a status not equal to 0:

```
set -e
grep -q foo <<< bar
echo Jo
```

Here 'Jo' will never be printed out as the grep didn't find any match. It's unrealistic for most scripts to purely run in paranoid mode so there must be a way to add exceptions. Critical Bash scripts of mine tend to look like this:

```
#!/usr/bin/env bash

set -e

some_function () {
    .. some critical code
    ...

    set +e
    # Grep might fail, but that's OK now
    grep ....
    local -i ec=$?
    set -e

    .. critical code continues ...
    if [[ $ec -ne 0 ]]; then
        ...
    fi
    ...
}
```

## Learned

There are also a couple of things I've learned from Googles guide.

### Unintended lexicographical comparison.

The following looks like valid Bash code:

```
if [[ "${my_var}" > 3 ]]; then
    # True for 4, false for 22.
    do_something
fi
```

... but is probably unintended lexicographical comparison. A correct way would be:

```
if (( my_var > 3 )); then
    do_something
fi
```

or

```
if [[ "${my_var}" -gt 3 ]]; then
    do_something
fi
```

### PIPESTATUS

To be honest, I have never used the PIPESTATUS variable before. I knew that it's there, but I never bothered to fully understand it how it works until now.

The PIPESTATUS variable in Bash allows checking of the return code from all parts of a pipe. If it’s only necessary to check success or failure of the whole pipe, then the following is acceptable:

```
tar -cf - ./* | ( cd "${dir}" && tar -xf - )
if (( PIPESTATUS[0] != 0 || PIPESTATUS[1] != 0 )); then
    echo "Unable to tar files to ${dir}" >&2
fi
```

However, as PIPESTATUS will be overwritten as soon as you do any other command, if you need to act differently on errors based on where it happened in the pipe, you’ll need to assign PIPESTATUS to another variable immediately after running the command (don’t forget that [ is a command and will wipe out PIPESTATUS).

```
tar -cf - ./* | ( cd "${DIR}" && tar -xf - )
return_codes=( "${PIPESTATUS[@]}" )
if (( return_codes[0] != 0 )); then
    do_something
fi
if (( return_codes[1] != 0 )); then
    do_something_else
fi
```

## Use common sense and BE CONSISTENT.

The following 2 paragraphs are completely quoted from the Google guidelines. But they hit the hammer on the head:

> If you are editing code, take a few minutes to look at the code around you and determine its style. If they use spaces around their if clauses, you should, too. If their comments have little boxes of stars around them, make your comments have little boxes of stars around them too.

> The point of having style guidelines is to have a common vocabulary of coding so people can concentrate on what you are saying, rather than on how you are saying it. We present global style rules here so people know the vocabulary. But local style is also important. If code you add to a file looks drastically different from the existing code around it, the discontinuity throws readers out of their rhythm when they go to read it. Try to avoid this.


## Advanced Bash learning pro tip

I also highly recommend having a read through the "Advanced Bash-Scripting Guide" (which is not from Google). I use it as the universal Bash reference and learn something new every time I have a look at it.

[Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)  

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  