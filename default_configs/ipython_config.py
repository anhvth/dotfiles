# type: ignore
# Configuration file for ipython.
c = get_config()  # noqa: F821

# Set up auto reload for modules
c.InteractiveShellApp.extensions = ['autoreload']
c.InteractiveShellApp.exec_lines = ['%autoreload 2']

# Display settings
c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.true_color = True

# History settings
c.HistoryManager.enabled = True
