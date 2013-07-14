#!/usr/bin/env bash
set -e

oldrev=$(git rev-parse $1)
newrev=$(git rev-parse $2)
refname="$3"
tag=$(git describe --tags $refname)

run() {
  [ -x $1 ] && $1 $oldrev $newrev $refname $tag
}

umask 002

git submodule sync && git submodule update --init --recursive

run deploy/before_restart
run deploy/restart && run deploy/after_restart
