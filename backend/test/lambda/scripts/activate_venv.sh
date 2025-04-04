#!/usr/bin/bash

git_root=$(git rev-parse --show-toplevel)
lambda_test_path="${git_root}/backend/test/lambda"
activate="lambda-env/bin/activate"

cd "${lambda_test_path}"

if [ ! -d "${lambda_test_path}/lambda-env" ]; then
    python3.13 -m venv lambda-env/
    source "${activate}"
    python3 -m pip install --upgrade pip
    python3 -m pip install -r requirements.txt
    echo 'gnome-terminal -- bash -c "ptw --ext=.py,.json"' >> "${activate}"
else
    source "${activate}"
fi
