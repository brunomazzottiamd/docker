# Add `cscripts` to PATH. 
export PATH="${PATH}:/triton_dev/docker/cscripts"

# General aliases.
alias ed='editor.sh'

# Git aliases.
alias gs='git status'
alias gf='git fetch --all --prune'
alias gl='git log --oneline'
alias gc='git commit --verbose'
alias gca='git commit --amend --verbose'
alias gap='git add --patch'
alias gri='git rebase --interactive'
alias gp='git push'
alias gpf='git push --force-with-lease'
