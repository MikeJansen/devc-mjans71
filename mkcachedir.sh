#!/usr/bin/env sh

# usage: mkcachedir.sh <cache_name> <user_name> <link_dir>
# example: mkcachedir.sh gitcache mjans /home/mjans/.cache/git

set -e

cache_name="$1"
cache_dir="/dc/$cache_name"
user_name="$2"
link_dir="$3"

echo "Creating cache directory '$cache_dir' for user '$user_name' and linking to '$link_dir'"
mkdir -p "$cache_dir"
chown -R "$user_name:$user_name" "$cache_dir"
chmod 700 "$cache_dir"
ln -sf "$cache_dir" "$link_dir"
chown -R "$user_name:$user_name" "$link_dir"
chmod 700 "$link_dir"