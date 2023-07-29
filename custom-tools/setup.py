from setuptools import setup, find_packages

setup(
    name='custom_python_tools',
    version='0.1',
    packages=find_packages(),
    entry_points={
        'console_scripts': [
            'vastai_utils.save_cost=vastai_utils.safe_cost:main',
        ],
    },
)
