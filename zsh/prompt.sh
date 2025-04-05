# Reference for colors: http://stackoverflow.com/questions/689765/how-can-i-change-the-color-of-my-prompt-in-zsh-different-from-normal-text

# Load colors and initialize them
autoload -U colors && colors

# Enable prompt substitution to allow dynamic content
setopt PROMPT_SUBST

# Function to set the prompt
set_prompt() {
    # Start with an empty PS1
    PS1=""
    
    # Add virtual environment indicator at the beginning with better formatting
    if [[ -n "$VIRTUAL_ENV" ]]; then
        PS1+="%{$fg_bold[green]%}($(basename $VIRTUAL_ENV))%{$reset_color%} "
    fi
    
    # Opening bracket
    PS1+="%{$fg[white]%}[%{$reset_color%}"

    # Determine if the path is long (greater than 50 characters)
    if (( ${#PWD} > 50 )); then
        max_length=50
        keep_length=$((max_length - 4))
        shortened_pwd="${PWD: -$keep_length}"
        slash_index=$(echo "$shortened_pwd" | awk -F/ '{print index($0,"/")}')
        if [ "$slash_index" -gt 0 ]; then
            shortened_pwd="...${shortened_pwd:$slash_index-1}"
        else
            shortened_pwd=".../$shortened_pwd"
        fi
        display_pwd="$shortened_pwd"
    else
        display_pwd="${PWD/#$HOME/~}"
    fi

    # Add the path with bold cyan color
    PS1+="%{$fg_bold[cyan]%}${display_pwd}%{$reset_color%}"
    
    # Handle environment name and cname
    if [[ -n "$cname" || -n "$env_name" ]]; then
        PS1+="%{$fg[white]%}|%{$reset_color%}"
        
        if [[ -n "$cname" ]]; then
            PS1+="%{$fg_bold[yellow]%}${cname}%{$reset_color%}"
            [[ -n "$env_name" ]] && PS1+="%{$fg[white]%}>%{$reset_color%}"
        fi
        
        [[ -n "$env_name" ]] && PS1+="%{$fg_bold[blue]%}${env_name}%{$reset_color%}"
    fi

    # Add status indicators
    local indicators=""
    
    # Add exit status if non-zero
    indicators+='%(?.., %{$fg_bold[red]%}%?%{$reset_color%})'
    
    # Add elapsed time if applicable
    if [[ ${_elapsed[-1]} -ne 0 ]]; then
        [[ -n "$indicators" ]] && indicators+=", "
        indicators+="%{$fg[magenta]%}${_elapsed[-1]}s%{$reset_color%}"
    fi
    
    # Add PID if applicable
    if [[ $! -ne 0 ]]; then
        [[ -n "$indicators" ]] && indicators+=", "
        indicators+="%{$fg[yellow]%}PID:$!%{$reset_color%}"
    fi
    
    # Add indicators if any exist
    [[ -n "$indicators" ]] && PS1+="$indicators"
    
    # Close the bracket and add the prompt symbol
    PS1+="%{$fg[white]%}]%{$reset_color%} %{$fg_bold[white]%}❯%{$reset_color%} "
}

# Register the set_prompt function to be called before each prompt is displayed
precmd_functions+=(set_prompt)
