#!/bin/bash

set -e

if [ ! -f /etc/.report-creds ]; then
  echo "Credentials not found in /etc/.report-creds"
  exit 1
fi

# Set the script directory
FOLDER="$HOME/weekly-reporting"

# Check if "Weekly-Reporting" folder exists
# If not then make the parent directory and clone the repo to it.
if [ ! -d "$HOME/weekly-reporting/Weekly-Reporting" ]; then
  mkdir -p $FOLDER
  git clone https://github.com/stfc/cloud-ops-tools.git $FOLDER
fi

# Change to script directory
SCRIPT_FOLDER="$FOLDER/Weekly-Reporting"
cd "$SCRIPT_FOLDER"


# Check if venv exists
if [ ! -d "$SCRIPT_FOLDER/venv" ]; then
  sudo apt update
  sudo apt install python3-venv -y
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  deactivate
fi

# Reset git repo to get latest changes
# Only if the repo is still on the main branch
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

if [[ "$BRANCH_NAME" == "main" ]]; then
   git fetch && git reset --h origin/main
fi

echo "Sourcing the Python Virtual Environment."
echo "..."
source venv/bin/activate

echo "Setting environment variables from .report-creds"
echo "..."
export $(cat /etc/.report-creds | xargs)

./report.sh

echo "Exporting data to ${INFLUX_HOST}."
echo "..."

python3 export.py --host $INFLUX_HOST --org $INFLUX_ORG --bucket $INFLUX_BUCKET --report-file "weekly-report-$(date +%F).yaml"

echo "Done."

deactivate
