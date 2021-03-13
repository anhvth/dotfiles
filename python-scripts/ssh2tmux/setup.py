from setuptools import setup
setup(
    name='ssh2tmux',
    version='0.0.1',
    entry_points={
        'console_scripts': [
            'ssh2tmux=ssh2tmux:run'
        ]
    }
)
