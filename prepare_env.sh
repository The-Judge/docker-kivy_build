#!/usr/bin/env bash
# Install Python requirements
cd /app/build || exit
python -m pip install --pre -r requirements.txt
cd - || exit

## Pull p4a Git commits
cd /usr/share/android/p4a || exit
git pull
cd - || exit
