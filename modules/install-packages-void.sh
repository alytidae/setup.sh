#!/bin/bash
set -e

echo "Installing packages:"

while read -r package; do
  echo " - $package"
  xbps-install -S "$package"
done < packages.txt

