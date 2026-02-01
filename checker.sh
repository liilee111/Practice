#!/usr/bin/env bash
set -euo pipefail

# chmod u+x ./checker.sh

# Commands:
#   ./checker.sh where -> show current branch 
#   ./checker.sh sync -> update local dev from origin/dev
#   ./checker.sh new-feature <feature-name> -> create a new feature branch <name> from dev  
#   ./checker.sh remove-feature <feature-name> -> delete a feature branch <name> from dev  


print() { 
    printf "\n== %s ==\n" "$*"; 
}

die() { 
    printf "\nERROR: %s\n" "$*" >&2; exit 1; 
}

require_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repo."
}


ensure_clean_worktree() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        die "Working tree has uncommitted changes. Commit them first."
    fi

    local untracked
    untracked="$(git status --porcelain | grep '^??' || true)"

    if [[ -n "$untracked" ]]; then
        print "WARNING: Untracked files detected:"
        echo "$untracked"
        echo
        echo "If these are local-only files, add them to .gitignore."
        echo
    fi
}


cmd_where() {
    local branch
    branch=$(git branch | grep '^\*' | sed 's/\* //')
    print "You are on: $branch"
}

cmd_sync() {
    require_git_repo
    ensure_clean_worktree
    git fetch origin 
    git switch dev
    git pull --ff-only
    print "Done. dev is up to date."
}

cmd_new_feature() {
    require_git_repo
    local feature="${1:-}"
    [[ -n "$feature" ]] || die "Usage: new-feature <branch-name>"

    ensure_clean_worktree
    git fetch origin
    git switch dev
    git pull --ff-only
    local branch="$feature"
    print "Creating and switching to $branch"
    git switch -c "$branch"
}

cmd_rm_feature() {
    local branch="${1:-}"
    [[ -n "$branch" ]] || die "Usage: remove-feature <branch-name>"

    git switch dev
    git pull --ff-only

    print "Deleting local branch: $branch"
    git branch -D "$branch"
}


main() {
    local cmd="${1:-}"
    shift || true

    case "$cmd" in
        where)    cmd_where "$@" ;; 
        sync)     cmd_sync "$@" ;; 
        new-feature)    cmd_new_feature "$@" ;;
        remove-feature)    cmd_rm_feature "$@" ;;
        *) die "Unknown command" ;;
    esac
}

main "$@"
