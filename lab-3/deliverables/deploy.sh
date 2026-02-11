#!/bin/bash
set -euo pipefail

BASE="/home/lonix/Documents/TheoWAF/class7/AWS/Terraform/_armageddon/LAB1/1c_terrraform/lab-3"

echo "=== Deploying tokyo ==="
cd "$BASE/tokyo"
terraform apply -auto-approve
echo "=== tokyo complete ==="

echo "=== Deploying saopaulo ==="
cd "$BASE/saopaulo"
terraform apply -auto-approve
echo "=== saopaulo complete ==="

echo "=== Deploying interlink ==="
cd "$BASE/interlink"
terraform apply -auto-approve
echo "=== interlink complete ==="
