#!/bin/bash -eu
DIR=$(cd $(dirname $0);pwd)
TASK_DIR=$HOME/Dropbox/IFTTT/Email/task
TMP_FILE=$(mktemp)

cd $DIR
while inotifywait -e close_write,moved_to,create $TASK_DIR -o $TMP_FILE; do
  cat $TMP_FILE | ./add-task-from-dropbox.pl
  TMP_FILE=$(mktemp)
done
