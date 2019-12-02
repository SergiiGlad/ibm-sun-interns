#!/bin/bash

# This script check the version of kubectl; the version must be equal or greater then #RequiredMinimalVersion

# Please, input below Required Minimal Version of kubectl in format RequiredMinimalVersion = v1.14.7  (USE THIS FORMAT!)
RequiredMinimalVersion=v1.14.7

# Convert to Integer (e.g. v1.14.7 => 1147)
RequiredMinimalVersionInt=`echo $RequiredMinimalVersion | sed 's/^.//' | sed 's/\.//g'`

# Check if kubectl is installed
if ! hash kubectl; then
    echo "kubectl is not installed, kubectl 1.14.7 or later is required"
    exit 1;
fi

# show current kubectl client version
echo "================================================="
echo "=== Current kubectl `kubectl version --client --short=true`   ==="
echo "================================================="
# Convert installed kubectl version to Integer (e.g. v1.14.7 => 1147)
kubectl_ver=`kubectl version --client --short=true 2>&1 | awk '{print $3}' | sed 's/^.//' | sed 's/\.//g'`

# Compare installed and minimal required versions of kubectl
if [ "$kubectl_ver" -lt "$RequiredMinimalVersionInt" ]; then
    echo "It is required to use kubectl "$RequiredMinimalVersion" or greater"
    exit 1;
fi


