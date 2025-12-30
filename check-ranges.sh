#!/bin/bash

# List of your servers
SERVERS=("37.187.159.125" "135.125.223.211" "135.125.223.213")  # replace with your hostnames or IPs
SSH_USER="ubuntu"                       # replace with your SSH user
DHCP_START=100                             # your DHCP range start
DHCP_END=200                               # your DHCP range end
POOL_SIZE=10                               # number of IPs for MetalLB

echo "Checking servers..."

SUBNETS=()
for SERVER in "${SERVERS[@]}"; do
  echo "Connecting to $SERVER..."
  IP=$(ssh -o StrictHostKeyChecking=no $SSH_USER@$SERVER "ip -4 addr show | grep -v '127.0.0.1' | grep 'inet ' | awk '{print \$2}' | head -n1")
  if [[ -z "$IP" ]]; then
    echo "Could not get IP for $SERVER"
    exit 1
  fi
  SUBNET=${IP%.*}.0/24
  echo "Server $SERVER has subnet: $SUBNET"
  SUBNETS+=("$SUBNET")
done

# Make sure all subnets are identical
UNIQ_SUBNETS=($(echo "${SUBNETS[@]}" | tr ' ' '\n' | sort -u))
if [[ ${#UNIQ_SUBNETS[@]} -ne 1 ]]; then
  echo "Error: servers are on different subnets!"
  exit 1
fi

SUBNET_PREFIX=${UNIQ_SUBNETS[0]%.*}/24
BASE_IP=${UNIQ_SUBNETS[0]%.*}

# Pick free range above DHCP
START_IP=$((DHCP_END+1))
END_IP=$((START_IP + POOL_SIZE - 1))

echo ""
echo "Suggested MetalLB IP pool for subnet $SUBNET_PREFIX:"
echo "$BASE_IP.$START_IP-$BASE_IP.$END_IP"
echo ""
echo "Verify these IPs are free using ping before applying to MetalLB."
