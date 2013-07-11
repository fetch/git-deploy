#!/usr/bin/env bash
set -e

oldrev=$(git rev-parse $1)
newrev=$(git rev-parse $2)
refname="$3"
tag=$(git describe --tags $refname)

# IO redirection
exec 6>&1           # Link file descriptor #6 with stdout. Saves stdout.
exec > /dev/null    # All normal output to /dev/null

run() {
  [ -x $1 ] && $1 $oldrev $newrev $refname
}

log() {
  echo -e "----->   $@\n" >&6
}

against=$oldrev

# prevent comparing to bad object
if [ -z "${oldrev//0}" ]; then
  against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

echo >&6
log "Publishing Fetch CMS $tag"

log "Files changed between versions: ${oldrev:0:7}..${newrev:0:7}:\
 $(git diff $against $newrev --diff-filter=ACDMR --name-only | wc -l | tr -d ' ')"

umask 002

git submodule sync && git submodule update --init --recursive

FRAMEWORK_DIR=/usr/share/php/fetch-cms-core

. /usr/local/nvm/nvm.sh

cd $FRAMEWORK_DIR/source

composer --no-interaction install | sed 's/^/----->   /' >&6
echo >&6

nvm use | sed 's/^/----->   /' >&6
echo >&6

log "Installing npm packages"
nvm use && npm --silent install

log "Building assets using grunt"
grunt --no-color release

log "Syncing to $FRAMEWORK_DIR/$tag"
rsync -lrpt --delete \
  --exclude=".git" \
  --exclude=".DS_Store" \
  $FRAMEWORK_DIR/source/* $FRAMEWORK_DIR/$tag

log "Done!"
