#!/bin/bash
set -e

echo "Update the system:"
xbps-install -Suy
echo

echo "Installing packages:"

while read -r package; do
  echo " - $package"
  xbps-install -S "$package"
done < packages.txt

