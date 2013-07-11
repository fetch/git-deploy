#!/usr/bin/env bash
set -e

oldrev=$(git rev-parse $1)
newrev=$(git rev-parse $2)
refname="$3"
tag=$(git describe --tags $refname)

run() {
  [ -x $1 ] && $1 $oldrev $newrev $refname
}

log() {
  echo -e "----->   $@\n"
}

against=$oldrev

# prevent comparing to bad object
if [ -z "${oldrev//0}" ]; then
  against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

echo
log "Publishing Fetch CMS $tag"

log "Files changed between versions: ${oldrev:0:7}..${newrev:0:7}:\
 $(git diff $against $newrev --diff-filter=ACDMR --name-only | wc -l | tr -d ' ')"

umask 002

git submodule sync && git submodule update --init --recursive

FRAMEWORK_DIR=/usr/share/php/fetch-cms-core

. /usr/local/nvm/nvm.sh

cd $FRAMEWORK_DIR/source

composer --no-interaction install | sed 's/^/----->   /'
echo

nvm use | sed 's/^/----->   /'
echo

log "Installing npm packages"
nvm use 1> /dev/null && npm --silent install

log "Building assets using grunt"
grunt --no-color release &> /dev/null

log "Syncing to $FRAMEWORK_DIR/$tag"
rsync -lrpt --delete \
  --exclude=".git" \
  --exclude=".DS_Store" \
  $FRAMEWORK_DIR/source/* $FRAMEWORK_DIR/$tag

log "Done!"
