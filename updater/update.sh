#!/bin/bash
set -e

timestamp() {
   echo "[$(date +%F_%T)]"
}

source_node() {
    export NVM_DIR="/home/admin/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    cd $1
    nvm use
}

cd /usr/local/twotech
if ./updater/changes_upstream.sh; then
    echo "$(timestamp) Upstream changes made to twotech, pulling and updating..."
    git pull
    source_node $(pwd)
    npm clean-install
    npm run build
    # Update packages for the process module also
    cd process
    source_node $(pwd)
    npm clean-install
    cd ..
else
    echo "$(timestamp) No upstream changes to twotech, moving on..."
fi

if ./updater/changes_upstream.sh "./process/OneLifeData7"; then
    echo "$(timestamp) Upstream changes made to game data, running data update..."
    # git pull is not necessary here as the following command will handle that.
    source_node $(pwd)
    node process download
else
    echo "$(timestamp) No upstream changes to data, moving on..."
fi

echo "$(timestamp) Update check complete."
