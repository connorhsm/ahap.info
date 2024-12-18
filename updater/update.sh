#!/bin/bash
set -e

timestamp() {
  echo "[$(date +%F_%T)]"
}

changes_upstream() {
  # Pass repo directory as arg 1 or defaults to current
  repo="${1:-.}"

  # Checkout main/master
  git -C $repo checkout $(git -C $repo rev-parse --abbrev-ref origin/HEAD | cut -d / -f 2)

  git -C $repo fetch
  test $(git -C $repo rev-parse HEAD) != $(git -C $repo rev-parse @{upstream})
  return $?
}

source_node() {
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  cd $1
  nvm use
}

if [[ -d "/var/www/ahap.info/onetech" ]]; then
  cd /var/www/ahap.info/onetech
fi

if changes_upstream; then
  echo "$(timestamp) Upstream changes made to tech site, pulling and updating..."
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
  echo "$(timestamp) No upstream changes to tech site, moving on..."
fi

if [[ ! -d "./process/OneLifeData7" ]]; then
  echo "$(timestamp) OneLifeData7 not found, running data update..."
  source_node $(pwd)
  node process download
elif changes_upstream "./process/OneLifeData7"; then
  echo "$(timestamp) Upstream changes made to game data, running data update..."
  # git pull is not necessary here as the following command will handle that.
  source_node $(pwd)
  node process download
else
  echo "$(timestamp) No upstream changes to data, moving on..."
fi

echo "$(timestamp) Update check complete."
