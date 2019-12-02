#!/bin/bash

# This script check the version of helm; the version must be equal to  #RequiredMinimalVersion

# Please, input below Required Minimal Version of helm in format RequiredMinimalVersion = v2.15.2  (USE THIS FORMAT!)
RequiredMinimalVersion=v2.13.0

# Convert to Integer (e.g. v2.15.2 => 2152)
RequiredMinimalVersionInt=`echo $RequiredMinimalVersion | sed 's/^.//' | sed 's/\.//g'`

# Check if kubectl is installed
if ! which helm; then
    echo "helm is not installed, helm "$RequiredMinimalVersion" or later version is required"
    exit 1;
fi

# show current kubectl client version
echo "================================================="
echo "=== Current helm `helm version --short -c`   ==="
echo "================================================="
# Convert installed helm version to Integer (e.g. "Client: v2.15.2+g8dce272" => 2152)
helm_ver=`helm version --short -c 2>&1 | awk '{print $2}' | sed 's/^.//' | sed 's/\.//g' | sed 's/^\(.*\)+.*$/\1/'`

# Compare installed and minimal required versions of kubectl
if [ "$helm_ver" -lt "$RequiredMinimalVersionInt" ]; then
    echo "It is required to use helm "$RequiredMinimalVersion" or greater"
    exit 1;
fi

# for test commit; ignore it
