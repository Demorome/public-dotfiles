source /usr/share/cachyos-fish-config/cachyos-config.fish

# Increase file descriptor limit.
ulimit -n 4096

fish_add_path /home/demorome/.dotnet/tools

 # TODO: Switch to kakoune?
set -gx EDITOR nvim
# FIXME: This is broken somehow!
set -gx MANPAGER "nvim +Man!"

### INTERACTIVE SHELL SETTINGS ###
if not status --is-interactive
	exit
end

# Shortcuts to quick-open nvim with fuzzy file finding.
# Based on a tip from https://micahkepe.com/blog/workflow-automation/
# For fzf, the -m flag allows us to select multiple files with TAB,
# and then these will be put in open buffers when we open Neovim!
abbr --add n 'nvim $(fzf -m --preview="bat --color=always {}")'
abbr --add v 'nvim $(fzf -m --preview="bat --color=always {}")'

# Same thing but for Kakoune editor.
abbr --add k 'kak $(fzf -m --preview="bat --color=always {}")'

# # Adapted from https://github.com/fish-shell/fish-shell/issues/4434#issuecomment-332626369
# # only run in interactive (not automated SSH for example)
# if status is-interactive
# # don't nest inside another tmux
# and not set -q TMUX
#   # Adapted from https://unix.stackexchange.com/a/176885/347104
#   # Create session 'notes' or attach to it if it already exists.
#   tmux new-session -A -s notes
# end

# Add fuzzy-finding keybinds (ex: CTRL+t) to terminal.
fzf --fish | source
# Adds git fuzzy-finding shortcuts, which start with CTRL+G.
source ~/.config/fzf-git/fzf-git.fish

# Add Yazi wrapper that allows exiting with 'q' to auto-change CWD.
# Use 'Q' if you don't want to change the CWD.
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	command rm -f -- "$tmp"
end

bind alt-d y
bind ctrl-alt-d y

# ripgrep->fzf->text-editor [QUERY]
# Credits: https://junegunn.github.io/fzf/tips/ripgrep-integration/#wrap-up
# Converted for Fish shell.
# WARNING: May need to change args passed to $EDITOR if not using (n)vim.
function gr
  set --function RELOAD 'reload:rg --column --color=always --smart-case {q} || :'
  set --function OPENER 'if [ $FZF_SELECT_COUNT -eq 0 ]
            $EDITOR {1} +{2}     # No selection. Open the current line in text editor.
          else
            $EDITOR +cw -q {+f}  # Build quickfix list for the selected items.
          end'
  fzf --disabled --ansi --multi \
      --bind "start:$RELOAD" --bind "change:$RELOAD" \
      --bind "enter:become:$OPENER" \
      --bind "ctrl-o:execute:$OPENER" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --delimiter : \
      --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
      --preview-window '~4,+{2}+4/3,<80(up)' \
      --query "$argv"
end

# Can't use ctrl-g, since that's used by Git fzf keybinds.
bind alt-g gr
bind --mode "insert" alt-g gr

# fd (find) pipeline to CD to a file's directory.
# Uses 'disabled' fzf with bat for live previews.
# Arg1 is for additionnal fd flags.
#
# {q} is the placeholder expression for the current query, single-quoted.
# --ansi option for fzf is required to support '--color always'.
function interactive_find
  set --function RELOAD "reload:fd $argv[1] --color always {q} || :"
  set --function OPENER 'if [ $FZF_SELECT_COUNT -eq 0 ]
            cd {1}
          else
            $EDITOR +cw -q {+f}  # Build quickfix list for the selected items.
          end'
  set --function argv[1] ''
  fzf --disabled --ansi --multi \
      --bind "start:$RELOAD" --bind "change:$RELOAD" \
      --bind "enter:become:$OPENER" \
      --bind "ctrl-o:execute:$OPENER" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --preview 'bat --style=full --color=always {1}' \
      --preview-window '~4,+4/3,<80(up)' \
      --query "$argv"
end

function f
    interactive_find '--hidden --no-ignore'
end

# g for git, since it respects gitignore.
function fg
    interactive_find ''
end

abbr --add ifind interactive_find

# The 'ctrl' variants respect gitignore, since ctrl+g is used for git fzf.
bind ctrl-f fg
bind --mode "insert" ctrl-f fg
bind alt-f f
bind --mode "insert" alt-f f

# Sync Fish Vi-mode copy+pasting to global clipboard.
# If we don't specify a --mode, "default" is used, aka Vi's "normal" mode, aka command mode.
bind yy fish_clipboard_copy
bind Y fish_clipboard_copy
bind p fish_clipboard_paste

# Enable Vi keybinds
set -g fish_key_bindings fish_vi_key_bindings

# Show the mode in prompt
# TODO: Show this after the path?: https://www.reddit.com/r/fishshell/comments/lfb6ua/vi_mode_indicator_configuration/
function fish_mode_prompt
  switch $fish_bind_mode
    case default
      set_color --bold red
      echo '[N]'
    case insert
      set_color --bold green
      echo '[I]'
    case replace_one
      set_color --bold green
      echo '[R]'
    case replace
      set_color --bold bryellow
      echo '[R]'
    case visual
      set_color --bold brmagenta
      echo '[V]'
    case operator f F t T
      set_color --bold cyan
      echo '[N]'
    case '*'
      set_color --bold red
      echo '[?]'
  end
  set_color --reset
  echo ' '
end

## Restores Tmux session: https://thedroidguy.com/how-to-manage-and-restore-tmux-sessions-in-linux-1263582
#alias mux='pgrep -vx tmux > /dev/null && tmux new -d -s delete-me && tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh && tmux kill-session -t delete-me && tmux attach || tmux attach'


# Some abbr taken from https://github.com/lewisacidic/fish-scripting

# REMINDER: cdh is cool!
abbr --add - 'cd -'
abbr -a rm 'trash-put'
abbr -a sed sd
abbr -a awk string
# WARNING: rg and fd ignore hidden and .gitignore'd files by default!
# Flags are passed here to turn off that behavior.
abbr -a grep 'rg --smart-case -HI'
# fd does smart-case by default.
abbr -a find 'fd -HI'
abbr -a vim nvim
abbr -a cat bat
abbr -a ln 'ln -s'
abbr -a rd 'rmdir'
abbr -a md 'mkdir -p'

# Credits to u/Nukesor: https://www.reddit.com/r/fishshell/comments/1he9bd8/comment/m21vq0d/
abbr --add 'jf' 'sudo journalctl -f -u'
abbr --add 'jb' 'sudo journalctl -b -u'
abbr --add 'sys' 'sudo systemctl'

alias l='eza -blF --git --header --group-directories-first --icons=auto --color=auto'
alias d='dirs'

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    # smth smth
end

abbr -a xteink sudo setfacl -m u:demorome:rw /dev/ttyACM-1

# Dotnet
abbr -a dn 'dotnet'
abbr -a dnr 'dotnet run'
abbr -a dnb 'dotnet build'
abbr -a dnc 'dotnet clean'
abbr -a dnw 'dotnet watch'

# Git
# Mostly based on https://github.com/lewisacidic/fish-git-abbr
abbr --add g 'lazygit'

abbr --add ga "git add -p"
abbr --add gaa 'git add --all'
abbr --add gapp 'git apply'

abbr --add gb 'git branch'
abbr --add gba 'git branch -a'
abbr --add gbd 'git branch -d'
abbr --add gbD 'git branch -D'
abbr --add gbnm 'git branch --no-merged'
abbr --add gbr 'git branch --remote'

abbr --add gbl 'git blame -b -w'

abbr --add gbs 'git bisect'
abbr --add gbsb 'git bisect bad'
abbr --add gbsg 'git bisect good'
abbr --add gbsr 'git bisect reset'
abbr --add gbss 'git bisect start'

abbr --add gc 'git commit -v'
abbr --add gci 'git commit --allow-empty -v -m\'chore: initial commit\''
abbr --add gc! 'git commit -v --amend'
abbr --add gcn 'git commit -v --no-edit'
abbr --add gcn! 'git commit -v --amend --no-edit'
abbr --add gca 'git commit -a -v'
abbr --add gca! 'git commit -a -v --amend'
abbr --add gcan! 'git commit -a -v --no-edit --amend'
abbr --add gcans! 'git commit -a -v -s --no-edit --amend'
abbr --add gcam 'git commit -a -m'
abbr --add gcas 'git commit -a -s'
abbr --add gcasm 'git commit -a -s -m'
abbr --add gcsm 'git commit -s -m'
abbr --add gcm --position anywhere --set-cursor "git commit -m '%'"
abbr --add gcs 'git commit -S'

abbr --add gcf 'git config --list'

abbr --add gcl 'git clone --recurse-submodules'

abbr --add gclean 'git clean -id'

abbr --add gco 'git checkout'
abbr --add gcob 'git checkout -b'
abbr --add gcom 'git checkout (git_main_branch)'
abbr --add gcod 'git checkout (git_develop_branch)'
abbr --add gcof 'git checkout (git_feature_prepend)/'
abbr --add gcoh 'git checkout hotfix/'
abbr --add gcor 'git checkout release/'
abbr --add gcos 'git checkout support/'
abbr --add gcors 'git checkout --recurse-submodules'

abbr --add gcount 'git shortlog -sn'

abbr --add gcp 'git cherry-pick'
abbr --add gcpa 'git cherry-pick --abort'
abbr --add gcpc 'git cherry-pick --continue'

abbr --add gd 'git diff'
abbr --add gdca 'git diff --cached'
abbr --add gdcw 'git diff --cached --word-diff'
abbr --add gdct 'git diff --staged'
abbr --add gdt 'git diff-tree --no-commit-id --name-only -r'
# abbr --add gdnolock 'git diff ":(exclude)package-lock.json" ":(exclude)*.lock"'
abbr --add gdup 'git diff @{upstream}'
# abbr --add gdv 'git diff -w $@ | view -'

abbr --add gdct 'git describe --tags (git rev-list --tags --max-count=1)'

abbr --add gf 'git fetch'
abbr --add gfa 'git fetch --all --prune'
abbr --add gfo 'git fetch origin'

# gg
# gga
# ggf
# ggfl
# ggl
# ggp
# ggpnp
# ggpull
# ggpur
# ggpush
# ggsup
# ggu
# gpsup

abbr --add ghh 'git help'

abbr --add gi 'git init'

abbr --add gignore 'git update-index --assume-unchanged'
abbr --add gignored 'git ls-files -v | grep "^[[:lower:]]"'

abbr --add gk 'gitk --all --branches &!'
abbr --add gke 'gitk --all (git log -g --pretty=%h) &!'

abbr --add gfg 'git ls-files | grep'

# gl: git log
abbr --add gl 'git log'
abbr --add gls 'git log --stat'
abbr --add glsp 'git log --stat -p'
abbr --add glg 'git log --graph'
abbr --add glgda 'git log --graph --decorate --all'
abbr --add glgm 'git log --graph --max-count=10'
abbr --add glo 'git log --oneline --decorate'
abbr --add glog 'git log --oneline --decorate --graph'
abbr --add gloga 'git log --oneline --decorate --graph --all'
# abbr --add glol
# abbr --add glols
# abbr --add glod
# abbr --add glods
# abbr --add glola

# gm: git merge
abbr --add gm 'git merge'
abbr --add gmom 'git merge origin/(git_main_branch)'
abbr --add gmum 'git merge upstream/(git_main_branch)'
abbr --add gma 'git merge --abort'

# gmtl: git mergetool
abbr --add gmtl 'git mergetool --no-prompt'
abbr --add gmtlvim 'git mergetool --no-prompt --tool=vimdiff'

# gp: git push
abbr --add gp 'git push'
abbr --add gpd 'git push --dry-run'
abbr --add gpf 'git push --force-with-lease'
abbr --add gpf! 'git push --force'
abbr --add gpsu 'git push --set-upstream origin (git_current_branch)'
abbr --add gpt 'git push --tags'
abbr --add gptf 'git push --tags --force-with-lease'
abbr --add gptf! 'git push --tags --force'
abbr --add gpoat 'git push origin --all && git push origin --tags'
abbr --add gpoatf! 'git push origin --all --force-with-lease && git push origin --tags --force-with-lease'
abbr --add gpoatf! 'git push origin --all --force && git push origin --tags --force'
abbr --add gpv 'git push -v'

# gpl: git pull
abbr --add gpl 'git pull'
abbr --add gplo 'git pull origin'
abbr --add gplom 'git pull origin (git_main_branch)'
abbr --add gplu 'git pull upstream'
abbr --add gplum 'git pull upstream (git_main_branch)'

# gr: git remote
# abbr --add gr 'git remote -v'
abbr --add gra 'git remote add'
abbr --add grau 'git remote add upstream'
abbr --add grrm 'git remote remove'
abbr --add grmv 'git remote rename'
abbr --add grset 'git remote set-url'
abbr --add gru 'git remote update'
abbr --add grv 'git remote -v'
abbr --add grvv 'git remote -vvv'

# grb: git rebase
abbr --add grb 'git rebase'
abbr --add grba 'git rebase --abort'
abbr --add grbc 'git rebase --continue'
abbr --add grbd 'git rebase (git_develop_branch)'
abbr --add grbi 'git rebase -i'
abbr --add grbom 'git rebase origin/(git_main_branch)'
abbr --add grbo 'git rebase --onto'
abbr --add grbs 'git rebase --skip'

# grev: git revert
abbr --add grev 'git revert'

# grs: git reset
abbr --add grs 'git reset'
abbr --add grs! 'git reset --hard'
abbr --add grsh 'git reset HEAD'
abbr --add grsh! 'git reset HEAD --hard'
abbr --add grsoh 'git reset origin/(git_current_branch)'
abbr --add grsoh! 'git reset origin/(git_current_branch) --hard'
abbr --add gpristine 'git reset --hard && git clean -dffx'
abbr --add grs- 'git reset --'

# grm: git rm
abbr --add grm 'git rm'
abbr --add grmc 'git rm --cached'

# grst: git restore
abbr --add grst 'git restore'
abbr --add grsts 'git restore --source'
abbr --add grstst 'git restore --staged'

# grt: git return
abbr --add grt 'cd (git rev-parse --show-toplevel || echo .)'

# gs: git status
abbr --add gs 'git status'
abbr --add gss 'git status -s'
abbr --add gsb 'git status -sb'

# gshow: git show
abbr --add gshow 'git show'
abbr --add gshowps 'git show --pretty=short --show-signature'

# gst: git stash
abbr --add gst 'git stash'
abbr --add gsta 'git stash apply'
abbr --add gstc 'git stash clear'
abbr --add gstd 'git stash drop'
abbr --add gstl 'git stash list'
abbr --add gstp 'git stash pop'
abbr --add gstshow 'git stash show --text'
abbr --add gstall 'git stash --all'
abbr --add gsts 'git stash save'

# gsu: git submodule
abbr --add gsu 'git submodule update'

# gsw: git switch
abbr --add gsw 'git switch'
abbr --add gswc 'git switch -c'
abbr --add gswm 'git switch (git_main_branch)'
abbr --add gswd 'git switch (git_develop_branch)'

# gt: git tag
abbr --add gt 'git tag'
abbr --add gts 'git tag -s'
abbr --add gta 'git tag -a'
abbr --add gtas 'git tag -a -s'
# gtl

# gwch: git whatchanged
abbr --add gwch 'git whatchanged -p --abbrev-commit --pretty=medium'

# gwt: git worktree
abbr --add gwt 'git worktree'
abbr --add gwta 'git worktree add'
abbr --add gwtls 'git worktree list'
abbr --add gwtmv 'git worktree move'
abbr --add gwtrm 'git worktree remove'

# gam: git am
abbr --add gam 'git am'
abbr --add gamc 'git am --continue'
abbr --add gams 'git am --skip'
abbr --add gama 'git am --abort'
abbr --add gamscp 'git am --show-current-patch'

# Git fuzzy-finders
alias gbcopy='git branch | sed "s/^[* ] //" | fzf | wl-copy'
alias gcof='git checkout $(git branch | fzf | sed "s/^[* ] //")'
