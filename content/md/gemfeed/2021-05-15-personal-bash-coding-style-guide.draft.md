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

> Written by Paul Buetow 2021-15-21

Lately I have been polishing and writing a lot of Bash code. Not that I never wrote a lot of Bash, but now as I also looked through the "Google Shell Style Guide" I thought it is time to also write my thoughts on that. I agree to that guide in most, but not in all points. 

[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)  

## My modifications

These are my personal modifications of the Google Guide.

### 2 space soft-tabs indentation

I know there have been many tab and soft-tab wars on this planet. Google recommends to use 2 space soft-tabs. 

My own reality is I don't really care if I use 2 or 4 space indentations. I agree however that tabs should not be used. I personally tend to use 4 space soft-tabs as that's currently how my personal Vim is configured for any programming language. What matters most though is consistency within the same script/project.

Google also recommends to limit line length to 80 characters. For some people that seem's to be an ancient habit from the 80's, where all computer terminals couldn't display longer lines. But I think that the 80 character mark is still a good practise at least for shell scripts. For example I am often writing code on a Microsoft Go Tablet PC (running Linux of course) and it comes in very handy if the lines are not too long due to the relatively small display on the device. 

I hit the 80 character line length quicker with the 4 spaces, but that makes me refactor the Bash code more aggressively which is actually a good thing. 

### Breaking long pipes

Google recommends to break up long pipes like this:

```
# All fits on one line
command1 | command2

# Long commands
command1 \
  | command2 \
  | command3 \
  | command4
```

I however think there is a better way like the following, which is less noisy. The pipe | already indicates the Bash that another command is expected, thus making the explicit line breaks with \ obsolete:

```
# Long commands
command1 |
    command2 |
    command3 |
    command4
```

### Quoting your variables

Google recommends to always quote your variables. I think you should do that only for variables where you aren't sure what the content is (e.g. content is from an external input source). In my opinion, the code will become quite noisy when you always quote your variables like this:

```
greet () {
    local -r greeting="${1}"
    local -r name="${2}"
    echo "${greeting} ${name}!"
}
```

In this particular example I agree that you should quote them as you don't really know what is the input (are there for example whitespace characters?). But if you are sure that you are only using simple bare words then I think that the code looks much better if you do:

```
greet () {
    local -r greeting=Hello
    local -r name=Paul
    echo "$greeting $name!"
}
```

You see I also omitted the curly braces { } around the variables. I also only use the curly braces around variables when it makes the code either easier/clearer to read or if it is necessary to use them:

```
declare FOO=bar
# Curly braces around FOO are necessary
echo "foo${FOO}baz"
```

One word more about always quoting your variables: For the sake of consistency (and for the sake of making ShellCheck happy) I am not against to always quote everything you encounter. It's just that I won't do that for every small script I write.

### Prefer builtin commands over external commands

Google prefers to use the builtin commands over external available commands where possible:

```
# Prefer this:
addition=$(( X + Y ))
substitution="${string/#foo/bar}"

# Instead of this:
addition="$(expr "${X}" + "${Y}")"
substitution="$(echo "${string}" | sed -e 's/^foo/bar/')"
```

To some degree I somehow agree here, but not fully. The external commands (especially sed) are much more sophisticated. Sed can do much more than the Bash can ever do with native capabilities when it comes to text editing.

I prefer to do light text processing with the Bash builtins and more complicated text processing with the help of external programs such as sed, grep, awk, cut and tr. There is however also the case of medium-light text processing you would want to perform occasionally in a Bash script. I tend to use the external programs here too because I remember using them better than the Bash builtins. The Bash can get quite obscure here (even Perl will be more readable then - Side note: I love Perl).

Also you would like to use an external command for floating point calculation (e.g. bc) instead using the Bash builtins (worth noticing that ZSH supports builtin floating points).

I even didn't get started what you can do with Awk (especially GNU Awk), a fully fledged programming language. Tiny Awk snippets tend to be used quite often in Shell scripts without respecting the real power of it. But if you did everything in Perl or Awk or another scripting language, then it wouldn't be a Bash script anymore, wouldn't it? ;-)

## My additions

### Use of 'yes' and 'no'

Bash does not support a boolean type. I tend to just use the strings 'yes' and 'no' here. For some time I used 0 for false and 1 for true, but I think that the yes/no strings are better readable. Yes, you would need to do string comparisons on every check, but if performance is important to you you wouldn't want to use a Bash script anyway.

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

Google is in the opinion that eval should be avoided. I think so too. They list this example in their guide:

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
local foo=bar
local bar=baz
local bay=foo

% bash -c 'source vars.source.sh; echo $foo $bar $baz'
bar baz foo
```

And if I want to assign variables dynamically then I could just run an external script and source it's output (This is how you could do metaprogramming in Bash - write code which produces code for immediate execution):

```
% cat vars.sh
#!/usr/bin/bash
cat <<END
declare date="$(date)"
declare user=$USER
END

% bash -c 'source <(./vars.sh); echo "Hello $user, it is $date"'
Hello paul, it is Sat 15 May 19:21:12 BST 2021
```

### Prefer pipes over arrays for list processing

When I do list processing in Bash I personally prefer to use pipes. You can chain then through Bash functions as well which is pretty neat. Usually my list processing scripts are of a structure like this:

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

## Learned

### Unintended lexicographical comparison.



```
# Probably unintended lexicographical comparison.
if [[ "${my_var}" > 3 ]]; then
  # True for 4, false for 22.
  do_something
fi
```

if (( my_var > 3 )); then
  do_something
fi

if [[ "${my_var}" -gt 3 ]]; then
  do_something
fi


### PIPESTATUS


## More

I also highly recommend to have a read through the "Advanced Bash-Scripting Guide" (which is not from Google). I use it as the universal Bash reference and learn something new every time I have a look at it.

[Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)  

E-Mail me your thoughts at comments@mx.buetow.org!

[Go back to the main site](../)  