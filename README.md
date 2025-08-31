# Installation
```bash
git clone https://github.com/anhvth/dotfiles ~/dotfiles --single-branch && cd ~/dotfiles && ./setup.sh

```
## Python venv auto-activation

- cd-based auto-activation is enabled by default. Toggle it via helpers (writes to `~/.env`):

```bash
# Disable auto-activate on cd
ve_auto_chdir off

# Re-enable
ve_auto_chdir on
```

- Login-time auto-activation (activate mapped or last venv at shell start) is off by default. Enable/disable:

```bash
# Enable login-time auto-activation
ve_auto_login on

# Disable (unset)
ve_auto_login off
```

Notes:
- `ve_auto_chdir` controls activation on directory change using mappings from `atv <name>`.
- `ve_auto_login` controls one-time activation at shell startup.
- Reload with `source ~/.zshrc` to apply immediately in the current shell.



# Alias only
```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/master/bash/bashrc.sh -O ~/.alias.h

echo "source ~/.alias.h" >> ~/.bashrc


rm -rf ~/.fzf

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

~/.fzf/install

```
tmux
```bash
wget https://raw.githubusercontent.com/anhvth/dotfiles/main/tmux/tmux.conf -O ~/.tmux.conf
```


### Codegen
```
wget "https://raw.githubusercontent.com/anhvth/dotfiles/refs/heads/main/copilot/code-gen.md" -O .codegen
```
Ctrol+, -> add this line below
```json
    "github.copilot.chat.codeGeneration.instructions": [
        {
            "file": ".codegen"
        }
    ],
```
