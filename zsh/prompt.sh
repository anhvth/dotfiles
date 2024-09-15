# Reference for colors: http://stackoverflow.com/questions/689765/how-can-i-change-the-color-of-my-prompt-in-zsh-different-from-normal-text

# Load colors and initialize them
autoload -U colors && colors

# Enable prompt substitution to allow dynamic content
setopt PROMPT_SUBST

# Function to set the prompt
set_prompt() {
    # Handle environment name (e.g., Conda environment)
    if [[ -z "$env_name" ]]; then
        cname_local="$cname"
    else
        cname_local="${cname}>"
    fi

    # Construct the initial part of PS1 based on cname_local and env_name
    if [[ -z "$cname_local" ]]; then
        PS1=""
    else
        PS1="${cname_local}${env_name}| "
    fi

    # Start the prompt with a newline and a white-colored opening bracket
    PS1="%{$fg[white]%}[%{$reset_color%}"$PS1
	# add a newline
	

    # Add the full current directory path
    PS1+="%{$fg_bold[cyan]%}${PWD/#$HOME/~}%{$reset_color%}"

    # Add the status code of the last executed command if it's non-zero
    PS1+='%(?.., %{$fg[red]%}%?%{$reset_color%})'

    # Add elapsed time if the last command took time to execute
    if [[ ${_elapsed[-1]} -ne 0 ]]; then
        PS1+=', '
        PS1+="%{$fg[magenta]%}${_elapsed[-1]}s%{$reset_color%}"
    fi

    # Add PID if applicable
    if [[ $! -ne 0 ]]; then
        PS1+=', '
        PS1+="%{$fg[yellow]%}PID:$!%{$reset_color%}"
    fi
	

    # Indicate if the user has sudo privileges active
    CAN_I_RUN_SUDO=$(sudo -n uptime 2>&1 | grep "load" | wc -l)
    if [[ $CAN_I_RUN_SUDO -gt 0 ]]; then
        PS1+=', '
        PS1+="%{$fg_bold[red]%}SUDO%{$reset_color%}"
    fi

    # Close the bracket and add the prompt symbol
    PS1+="%{$fg[white]%} ] %{$reset_color%}% "
	PS1+=$'\nCMD: '
}

# Register the set_prompt function to be called before each prompt is displayed
precmd_functions+=(set_prompt)

