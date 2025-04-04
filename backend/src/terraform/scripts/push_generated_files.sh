#!/usr/bin/bash

git_root=$(git rev-parse --show-toplevel)
git_changes=$(git status --porcelain)

cd "${git_root}"

if [ -n "${git_changes}" ]; then
    # changes
    git config --global user.name "Carsten Singleton"
    git config --global user.email "carstensing@users.noreply.github.com"
    git add .
    git status
    git commit -m "Generated files during GitHub Action."
    git push origin "${1}"
else
    # no changes
    echo "No generated files."
fi