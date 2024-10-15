# Add `cscripts` to PATH. 
export PATH="${PATH}:/triton_dev/docker/cscripts"

# Directory navigation aliases.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Text editor alias.
alias ed='editor.sh'

# Git aliases.
alias gs='git status'
alias gf='git fetch --all --prune'
alias gl='git log --oneline'
alias gc='git commit --verbose'
alias gca='git commit --amend --verbose'
alias ga='git add'
alias gap='git add --patch'
alias gr='git rebase'
alias gri='git rebase --interactive'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gd='git diff'
alias gds='git diff --staged'
