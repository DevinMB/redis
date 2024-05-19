#!/bin/bash

# Vault settings
VAULT_ADDR=${VAULT_ADDR}
ROLE_ID=${ROLE_ID}
SECRET_ID=${SECRET_ID}

# Function to fetch Vault token using AppRole
fetch_vault_token() {
  local role_id=$1
  local secret_id=$2
  curl --silent --request POST --data "{\"role_id\": \"${role_id}\", \"secret_id\": \"${secret_id}\"}" \
    ${VAULT_ADDR}/v1/auth/approle/login | jq -r .auth.client_token
}

# Function to fetch secret from Vault
fetch_secret() {
  local path=$1
  local key=$2
  local token=$3
  curl --silent --header "X-Vault-Token: $token" "$VAULT_ADDR/v1/$path" | jq -r .data.data.$key
}

# Fetch Vault token using AppRole
VAULT_TOKEN=$(fetch_vault_token ${ROLE_ID} ${SECRET_ID})

# Fetch admin credentials from Vault
admin_user=$(fetch_secret secret/redis-admin admin_user $VAULT_TOKEN)
admin_password=$(fetch_secret secret/redis-admin admin_password $VAULT_TOKEN)

# Inject credentials into redis.conf
sed -i "s/{{REDIS_ADMIN_USER}}/${admin_user}/g" /usr/local/etc/redis/redis.conf
sed -i "s/{{REDIS_ADMIN_PASSWORD}}/${admin_password}/g" /usr/local/etc/redis/redis.conf

# Start Redis server
exec "$@"
