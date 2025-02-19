# Add `cscripts` to PATH. 
export PATH="${PATH}:/triton_dev/docker/cscripts"

# Directory navigation aliases.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Unix aliases.
alias l1='ls -1'

# DOS remnants in my mind...
alias cls='clear'

# Text editor alias.
alias ed='editor.sh'

# Git aliases.
alias g='git'
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
alias gb='git branch -vv'
alias gba='git branch --all'
alias gco='git checkout'
alias gcop='git checkout --patch'
alias gsw='git show'
alias grm='git remote --verbose'
alias gbs='git bisect'
alias gbss='git bisect start'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsk='git bisect skip'
alias gbsr='git bisect reset'
alias gbsl='git bisect log'

# Triton aliases.
# "Clean Triton Cache"
alias ctc='rm -rf ~/.triton/cache'
# "Compile Triton"
alias ct='compile_triton.sh'

# Other aliases.
alias ss='cmatrix -b -s'  # ss = screen saver
