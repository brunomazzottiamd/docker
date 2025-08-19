# Add `cscripts` to PATH. 
export PATH="${PATH}:/triton_dev/docker/cscripts"

# Directory navigation aliases.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Unix aliases.
alias l1='ls -1'
alias rmrf='rm --recursive --force'
alias rmi='rm --interactive'

# DOS remnants in my mind...
alias cls='clear'

# Text editor alias.
alias ed='editor.sh'

# Git aliases.
alias g='git'
alias gs='git status'
alias gf='git fetch --all --prune'
alias gl='git log --oneline'
alias gl1='git log --oneline -1'
alias gl5='git log --oneline -5'
alias gl10='git log --oneline -10'
alias gc='git commit --verbose'
alias gca='git commit --amend --verbose'
alias gcnv='git commit --no-verify --verbose'
alias ga='git add'
alias gap='git add --patch'
alias gr='git rebase'
alias gri='git rebase --interactive'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
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
alias gfr='gf && gr'

# Triton aliases.
# ctc => "Clean Triton Cache"
alias ctc='clean_triton_cache.sh'
# cnttc => "Count Triton Cache"
alias cnttc='count_triton_cache.sh'
# ct => "Compile Triton"
alias ct='compile_triton.sh'

# Other aliases.
alias ss='cmatrix -b -s'  # ss = screen saver
alias pick_gpu='source pick_gpu.sh'  # source `HIP_VISIBLE_DEVICES` exported by `pick_gpu.sh`
