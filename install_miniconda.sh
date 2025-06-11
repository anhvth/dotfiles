wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

sh Miniconda3-latest-Linux-x86_64.sh

cd /home/ubuntu/miniconda3/bin && \
    python3.12 -m venv ~/python-venv/default
source ~/python-venv/default/bin/activate
pip install uv