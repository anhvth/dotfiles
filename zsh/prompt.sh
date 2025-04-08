# Reference for colors: http://stackoverflow.com/questions/689765/how-can-i-change-the-color-of-my-prompt-in-zsh-different-from-normal-text

# Load colors and initialize them
autoload -U colors && colors

# Enable prompt substitution to allow dynamic content
setopt PROMPT_SUBST

# Function to detect the current Git branch
function get_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    echo "$branch"
}

# Function to set the prompt
set_prompt() {
    # Initialize prompt components
    local cname_indicator=""
    local virtualenv_indicator=""
    local opening_bracket="%{$fg[white]%}[%{$reset_color%}"
    local path=""
    local env_name_indicator=""
    local status_indicators=""
    local separator="%{$fg[white]%}|%{$reset_color%}"
    local closing_bracket="%{$fg[white]%}]%{$reset_color%} %{$fg_bold[white]%}"
    local git_branch_indicator=""

    # Cname indicator
    if [[ -n "$cname" ]]; then
        cname_indicator="%{$fg_bold[white]%}${cname}%{$reset_color%}"
    fi

    # Virtual environment indicator
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name="${VIRTUAL_ENV:t}"
        virtualenv_indicator="%{$fg_bold[green]%}($venv_name)%{$reset_color%}"
    fi

    # Path handling
    local display_pwd="${PWD/#$HOME/~}"
    path="%{$fg_bold[cyan]%}${display_pwd}%{$reset_color%}"

    # Environment name indicator
    if [[ -n "$env_name" ]]; then
        env_name_indicator="%{$fg_bold[blue]%}${env_name}%{$reset_color%}"
    fi

    # Git branch indicator
    local branch="$(get_git_branch)"
    if [[ -n "$branch" ]]; then
        git_branch_indicator="%{$fg_bold[yellow]%}${branch}%{$reset_color%}"
    fi

    # Status indicators
    local indicators_array=()

    # Exit status

    if (( ${#indicators_array[@]} > 0 )); then
        status_indicators="${(j:, :)indicators_array}"
    fi

    # Construct PS1 with the desired order: cname, venv, path
    PS1="${opening_bracket}"

    [[ -n "$cname_indicator" ]] && PS1+="${cname_indicator}"

    if [[ -n "$virtualenv_indicator" && -n "$cname_indicator" ]]; then
        PS1+="${separator}"
    fi
    [[ -n "$virtualenv_indicator" ]] && PS1+="${virtualenv_indicator}"

    if [[ (-n "$path") && (-n "$cname_indicator" || -n "$virtualenv_indicator") ]]; then
        PS1+="${separator}"
    elif [[ -n "$path" ]]; then
        PS1+="" # No separator needed if path is the first component after the opening bracket
    fi
    PS1+="${path}"

    if [[ -n "$env_name_indicator" ]]; then
        PS1+="${separator}${env_name_indicator}"
    fi

    [[ -n "$status_indicators" ]] && PS1+="$status_indicators"
    PS1+="${closing_bracket}"
    if [[ ${#PS1} -gt 250 ]]; then
        PS1+=$'\n❯%{$reset_color%} '
    else
        PS1+="❯%{$reset_color%} "
    fi
}

# # Prevent duplicate registration of set_prompt in precmd_functions
# if [[ ! " ${precmd_functions[@]} " =~ " set_prompt " ]]; then
#     precmd_functions+=(set_prompt)
# fi

# set_prompt
# echo "Prompt set to: $PS1"
# export PROMPT="$(set_prompt)"
export PROMPT='%F{111}'"${cname}"'|%F{2}%~ %(!.#.$)%f '
