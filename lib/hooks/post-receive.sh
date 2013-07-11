#!/bin/bash
set -e

if [ "$GIT_DIR" = "." ]; then
  # The script has been called as a hook; chdir to the working copy
  cd ..
  unset GIT_DIR
fi

# try to obtain the usual system PATH
if [ -f /etc/profile ]; then
  PATH=$(source /etc/profile; echo $PATH)
  export PATH
fi

print_error(){
  printf '\e[1G\033[31m%s\033[0m\n' "ERROR: $1"
}

print_warning(){
  printf '\e[1G\033[33m%s\033[0m\n' "WARN: $1"
}

publish_tag(){
  oldrev=$(git rev-parse $1)
  newrev=$(git rev-parse $2)
  refname="$3"

  if [ -z "${oldrev//0}" ]; then
    change_type="create"
  else
    if [ -z "${newrev//0}" ]; then
      change_type="delete"
    else
      change_type="update"
    fi
  fi

  # abort if not a tag
  if ! [[ "$refname" =~ ^refs/tags/ ]]; then
    print_error "Can only deploy tags, aborting.."
    exit
  fi

  # abort in case of delete
  if [ $change_type == "delete" ]; then
    print_warning "Deleting a tag does not unpublish it"
    exit
  fi

  umask 002

  # Reset working copy to $refname
  git reset --hard $refname > /dev/null

  # Clean working copy of build products
  git clean -x -f -d > /dev/null

  [ -x deploy/after_push ] && deploy/after_push $oldrev $newrev $refname
}

while read oldrev newrev refname
do
  publish_tag $oldrev $newrev $refname
done
