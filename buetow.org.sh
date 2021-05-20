#!/usr/bin/env bash
#
# The buetow.org.sh static site generator
# by Paul Buetow 2021

declare -r ARG="$1"; shift
declare DATE=date
declare SED=sed
declare GREP=grep
which gdate &>/dev/null && DATE=gdate
which gsed &>/dev/null && SED=gsed
which ggrep &>/dev/null && GREP=ggrep
readonly DATE
readonly SED
readonly GREP

set -e

if [[ -n "$CONFIG_FILE_PATH" ]]; then
    source "$CONFIG_FILE_PATH"
elif [[ -f ~/.config/buetow.org.conf ]]; then
    source ~/.config/buetow.org.conf
else
    source ./buetow.org.conf
fi

source ./packages/assert.source.sh
source ./packages/git.source.sh
source ./packages/atomfeed.source.sh
source ./packages/gemfeed.source.sh
source ./packages/generate.source.sh
source ./packages/html.source.sh
source ./packages/log.source.sh
source ./packages/md.source.sh

help () {
    cat <<HELPHERE
$0's possible arguments:
    --feed      Generates Gemtext Atom feed and Gemfeed.
    --generate  Generates all known output formats (html, md, ...).
                If USE_GIT=yes set, all files will be commited to git too.
                If GIT_PUSH=yes is set, all content will be pushed to origin.
    --test      Only runs some shellcheck and unit tests.
    --help      Prints this retty text.
Example:
    USE_GIT=yes GIT_PUSH=yes $0 --generate
HELPHERE
}

setup () {
    if [ ! -d "$CONTENT_BASE_DIR" ]; then
        cat <<END
The content base directory, does not exist. Run the following to create it, it
also adds some sample Gemtext content:

    mkdir -p $CONTENT_BASE_DIR/{meta,md,html}
    git clone --branch content-gemtext https://github.com/snonux/buetow.org $CONTENT_BASE_DIR/gemtext
    rm -Rf $CONTENT_BASE_DIR/gemtext/.git

Once done, you are ready to edit the files in $CONTENT_BASE_DIR/gemtext. Every
time you want to generate other formats from Gemtext (e.g. HTML, Markdown), run
    $0 --generate
again.

For a list of other available arguments run
    $0 --help

Pro tip: You could make all the directories in $CONTENT_BASE_DIR separate git
repositories or branches. You can then run
    USE_GIT=yes $0 --generate
so that all static files are commited to the content repositories too. 
END
        exit 1
    fi
}

main () {
    local -r arg="$1"; shift

    setup

    case $arg in
        --test)
            LOG_VERBOSE=yes
            assert::shellcheck
            html::test
            md::test
            ;;
        --feed)
            gemfeed::generate
            atomfeed::generate
            ;;
        --generate)
            gemfeed::generate
            atomfeed::generate
            generate::fromgmi html md
            ;;
        --help|*)
            help
            ;;
    esac

    return 0
}

main "$ARG"
exit $?
