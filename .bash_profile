
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load the default .profileLIASES

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

complete -o default -o nospace -F _git_branch gb
complete -o default -o nospace -F _git_checkout gco
complete -o default -o nospace -F _git_diff gd

# Automatically add completion for all aliases to commands having completion functions
function alias_completion {
    local namespace="alias_completion"

    # parse function based completion definitions, where capture group 2 => function and 3 => trigger
    local compl_regex='complete( +[^ ]+)* -F ([^ ]+) ("[^"]+"|[^ ]+)'
    # parse alias definitions, where capture group 1 => trigger, 2 => command, 3 => command arguments
    local alias_regex="alias ([^=]+)='(\"[^\"]+\"|[^ ]+)(( +[^ ]+)*)'"

    # create array of function completion triggers, keeping multi-word triggers together
    eval "local completions=($(complete -p | sed -Ene "/$compl_regex/s//'\3'/p"))"
    (( ${#completions[@]} == 0 )) && return 0

    # create temporary file for wrapper functions and completions
    rm -f "/tmp/${namespace}-*.tmp" # preliminary cleanup
    local tmp_file="$(mktemp "/tmp/${namespace}-${RANDOM}.tmp")" || return 1

    # read in "<alias> '<aliased command>' '<command args>'" lines from defined aliases
    local line; while read line; do
        eval "local alias_tokens=($line)" 2>/dev/null || continue # some alias arg patterns cause an eval parse error
        local alias_name="${alias_tokens[0]}" alias_cmd="${alias_tokens[1]}" alias_args="${alias_tokens[2]# }"

        # skip aliases to pipes, boolan control structures and other command lists
        # (leveraging that eval errs out if $alias_args contains unquoted shell metacharacters)
        eval "local alias_arg_words=($alias_args)" 2>/dev/null || continue

        # skip alias if there is no completion function triggered by the aliased command
        [[ " ${completions[*]} " =~ " $alias_cmd " ]] || continue
        local new_completion="$(complete -p "$alias_cmd")"

        # create a wrapper inserting the alias arguments if any
        if [[ -n $alias_args ]]; then
            local compl_func="${new_completion/#* -F /}"; compl_func="${compl_func%% *}"
            # avoid recursive call loops by ignoring our own functions
            if [[ "${compl_func#_$namespace::}" == $compl_func ]]; then
                local compl_wrapper="_${namespace}::${alias_name}"
                    echo "function $compl_wrapper {
                        (( COMP_CWORD += ${#alias_arg_words[@]} ))
                        COMP_WORDS=($alias_cmd $alias_args \${COMP_WORDS[@]:1})
                        $compl_func
                    }" >> "$tmp_file"
                    new_completion="${new_completion/ -F $compl_func / -F $compl_wrapper }"
            fi
        fi

        # replace completion trigger by alias
        new_completion="${new_completion% *} $alias_name"
        echo "$new_completion" >> "$tmp_file"
    done < <(alias -p | sed -Ene "s/$alias_regex/\1 '\2' '\3'/p")
    source "$tmp_file" && rm -f "$tmp_file"
}; alias_completion


function prompt {
  local BLACK="\[\033[0;30m\]"
  local BLACKBOLD="\[\033[1;30m\]"
  local RED="\[\033[0;31m\]"
  local REDBOLD="\[\033[1;31m\]"
  local GREEN="\[\033[0;32m\]"
  local GREENBOLD="\[\033[1;32m\]"
  local YELLOW="\[\033[0;33m\]"
  local YELLOWBOLD="\[\033[1;33m\]"
  local BLUE="\[\033[0;34m\]"
  local BLUEBOLD="\[\033[1;34m\]"
  local PURPLE="\[\033[0;35m\]"
  local PURPLEBOLD="\[\033[1;35m\]"
  local CYAN="\[\033[0;36m\]"
  local CYANBOLD="\[\033[1;36m\]"
  local WHITE="\[\033[0;37m\]"
  local WHITEBOLD="\[\033[1;37m\]"
  local RESET="\[\033[1;37m\]"
  export PS1="$YELLOW\t $GREEN\u $BLUEBOLD\w$CYAN $WHITE "
  export PROMPT_COMMAND='echo -ne "\033]0;$PWD\007"'
}

prompt

export EDITOR="subl --wait"
export VISUAL=$EDITOR

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

#git/github
alias commands="cat ~/.bash_profile"
alias g="git status"
alias grm="git rebase master"
alias grc="git rebase --continue"
alias gco="git checkout"
alias gb="git branch"
alias gs="git status"
alias gl="git log"
alias gd="git diff"
alias gc="git commit"
alias gp="git push -u origin head"
function gpl {
  echo "Pulling from remote: origin/$1"
  eval "git pull origin $1"
}

#local db
alias dbrebuild="rake db:drop; rake db:create; bundle exec cap -S environment=production data:load_from_prod; rake db:migrate"
alias dbsyncprod="bundle exec cap -S environment=production data:load_from_prod"

alias l="ls -al"
alias gh="open https://github.com/littlebitselectronics/little_bits"
alias gdrive="open https://drive.google.com"
alias ghis="open https://github.com/littlebitselectronics/little_bits/issues?q=assignee%3Aoliverswitzer+is%3Aopen"
alias be="bundle exec"

# deploying to hub-stg2
alias addssh="ssh-add -D;ssh-add ~/.ssh/id_rsa"

function lb_depl {
  echo "Deploying $2 branch to $1.littlebits.cc:"
  eval "bundle exec cap deploy -S host=$1.littlebits.cc -S branch=$2"
}
function lb_ssh {
  echo "SSH into $1.littlebits.cc"
  eval "ssh spree@$1.littlebits.cc"
}
function lb_restart {
  echo "Sending restart to $1.littlebits.cc"
  eval "bundle exec cap deploy:restart -S host=$1.littlebits.cc"
}
function lb_migrate {
  echo "Migrating on $1.littlebits.cc"
  eval "bundle exec cap deploy:migrate -S host=$1.littlebits.cc"
}

#wordpress
alias wpclearlocal="curl -i --data 'key=unknowableunguessable' http://localhost:3000/wordpress_service/clear"
alias wpclearstg2="curl -i --data 'key=unknowableunguessable' http://hub-stg2.littlebits.cc/wordpress_service/clear"
