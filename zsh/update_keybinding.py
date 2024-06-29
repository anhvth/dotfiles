import json

# Load the JSON data
with open("keybindings.json", "r") as file:
    keybindings_data = json.load(file)


def generate_sh_script(keybindings):
    script_lines = []
    script_lines.append("# Keybindings Script\n")

    for binding in keybindings:
        key = binding["key"].lower().replace("ctrl+", "^")
        command = binding["command"]

        function_name = "_".join(
            [part for part in command.split() if not part.startswith("$")]
        )
        function_name = function_name.replace("-", "_").replace(".", "_")

        script_lines.append(f"# {command.split()[0].capitalize()}")
        script_lines.append(f"function {function_name}() {{")

        if "$BUFFER" in command:
            script_lines.append(f'\tBUFFER="{command}"')
            if (
                "cd" in command
                or "clear" in command
                or "ls" in command
                or "fc" in command
            ):
                script_lines.append("\tzle accept-line")
            else:
                script_lines.append("\tzle end-of-line")
        elif "$filename" in command or "$hostname" in command:
            if "$filename" in command:
                script_lines.append("\tfilename=$(ls | fzf)")
            if "$hostname" in command:
                script_lines.append(
                    "\thostname=$(cat ~/.ssh/config | grep \"Host \"| fzf | awk {'print $2'})"
                )
            script_lines.append(f'\tBUFFER="{command}"')
            script_lines.append("\tzle end-of-line")
        else:
            script_lines.append(f'\tBUFFER="{command}"')
            script_lines.append("\tzle accept-line")

        script_lines.append("}")
        script_lines.append(f"zle -N {function_name}")
        script_lines.append(f'bindkey "{key}" {function_name}\n')

    return "\n".join(script_lines)


# Generate the sh script
sh_script_content = generate_sh_script(keybindings_data["keybindings"])

# Output the sh script to a file
with open("keybindings.sh", "w") as file:
    file.write(sh_script_content)

print("Shell script has been generated as keybindings.sh")
