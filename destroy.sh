#!/bin/bash
#
# Cleanup our mess
#

# Check for prerequisites
if ! command -v terraform;
then
  echo "Error: please ensure 'terraform' is installed and in your \$PATH";
  exit 1;
fi

# nuke it all from orbit
terraform destroy;