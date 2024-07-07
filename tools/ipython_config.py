# Configuration file for ipython.
c = get_config()  #noqa

c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2']

# c.InteractiveShell.colors = 'Linux'  # Set color scheme
# c.InteractiveShell.confirm_exit = False  # Don't ask for confirmation when exiting
# c.TerminalIPythonApp.display_banner = False  # Hide the banner
# c.TerminalInteractiveShell.editing_mode = 'vi'  # Set editing mode to vi

# Optional: Uncomment to enable auto-suggestions
# c.TerminalInteractiveShell.autosuggestions_provider = 'AutoSuggestFromHistory'

c.InteractiveShellApp.exec_lines.append('print("\033[92m[AUTORELOAD]\033[0m")')