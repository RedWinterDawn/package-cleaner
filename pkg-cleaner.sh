#!/bin/bash

packages_to_remove=()

candidate_package_output=$(reprepro -b /srv/www/repo/debian/jive/ list wheezy-snapshot)
#candidate_package_output="wheezy-snapshot|main|amd64: libcom-jive-ftw-auth-test-resources-0.0.12-snapshot-java 2:0.0.12-20150113+002839
#"
IFS=$'\n'
for line in $candidate_package_output
do
  echo "Processing $line"
  raw_version=$(echo $line | awk '{print $3}')
  raw_package=$(echo $line | awk '{print $2}')
  release_epoch=${raw_version:0:1}
  release_version=`expr "$raw_version" : '^.*:\(.*\)-.*'`
  release_package_prefix=`expr "$raw_package" : "^\(.*\)-$release_version-snapshot-.*"`
  release_package_suffix=`expr "$raw_package" : "^.*-$release_version-snapshot-\(.*\)"`
  release_package="$release_package_prefix-$release_version-$release_package_suffix"

  echo "Looking for package $release_package in release repo..."
  search_result=$(reprepro -b /srv/www/repo/debian/jive/ list wheezy $release_package)

  pattern="^wheezy\|main\|amd64: $release_package $release_epoch:$release_version"
  if [[ $search_result =~ $pattern  ]]
  then
    echo "Found $release_package in release repo.  Scheduling removal of $raw_package from snapshot repo..."
    packages_to_remove=(${packages_to_remove[@]} $raw_package)
  else
    echo "Did not find $release_package in release repo.  Not removing snapshot."
  fi
  echo
done
if [ ${#packages_to_remove[@]} -gt 0 ]
then
  echo
  echo "The following packages will be removed from the snapshot repo:"
  for package_name in "${packages_to_remove[@]}"; do
    echo $package_name
  done
  echo

  read -p "Proceed [y/n]: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    for package_name in "${packages_to_remove[@]}"; do
      echo "Removing $package_name from the snapshot repo..."
      reprepro -b /srv/www/repo/debian/jive/ remove wheezy-snapshot $package_name
    done
  fi
else
    echo "No snapshot packages to remove."
fi

