#!/bin/sh
set -e
python3 -m venv .env
source .env/bin/activate
pip install -r requirements.txt
sphinx-autobuild . ./_build/html $@
