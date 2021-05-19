# Add a static content file to git
git::add () {
    local -r content_dir="$CONTENT_BASE_DIR/$1"; shift
    local file="$1"; shift
    file=${file/$content_dir/.\/}

    cd "$content_dir" &>/dev/null
    git add "$file"
    cd - &>/dev/null
}

# Remove a static content file from git
git::rm () {
    local -r content_dir="$CONTENT_BASE_DIR/$1"; shift
    local file="$1"; shift
    file=${file/$content_dir/.\/}

    cd "$content_dir" &>/dev/null
    git rm "$file"
    cd - &>/dev/null
}

# Commit all changes
git::commit () {
    local -r content_dir="$CONTENT_BASE_DIR/$1"; shift
    local -r message="$1"; shift

    cd "$content_dir" &>/dev/null
    git commit -a -m "$message"
    if [[ "$GIT_PUSH" == yes ]]; then
        git pull
        git push
    fi
    cd - &>/dev/null
}

# Commit all changes
git::commit () {
    local -r content_dir="$CONTENT_BASE_DIR/$1"; shift
    local -r message="$1"; shift

    cd "$content_dir" &>/dev/null
    git commit -a -m "$message"
    cd - &>/dev/null
}
