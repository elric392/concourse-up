#!/bin/bash

set -eu

deployment="system-test-$RANDOM"

cp "$BINARY_PATH" ./cup
chmod +x ./cup

echo "DEPLOY WITH AUTOGENERATED CERT, NO DOMAIN, CUSTOM REGION, DEFAULT WORKERS"

./cup deploy --region us-east-1 $deployment

sleep 60

config=$(./cup info --region us-east-1 --json $deployment)
domain=$(echo "$config" | jq -r '.config.domain')
username=$(echo "$config" | jq -r '.config.concourse_username')
password=$(echo "$config" | jq -r '.config.concourse_password')
echo "$config" | jq -r '.config.concourse_ca_cert' > generated-ca-cert.pem

fly --target system-test login \
  --ca-cert generated-ca-cert.pem \
  --concourse-url "https://$domain" \
  --username "$username" \
  --password "$password"

curl -k "https://$domain:3000"

set -x
fly --target system-test sync
fly --target system-test workers --details
set +x

echo "DESTROY CUSTOM-REGION DEPLOYMENT"

./cup --non-interactive destroy --region us-east-1 $deployment
