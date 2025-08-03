#!/bin/bash

echo "📥 Cloning microservice repositories..."

repos=(
  "iam-api-gateway"
  "iam-auth-service"
  "iam-authorization-service"
  "iam-chat-service"
  "iam-common-utilities"
  "iam-database-mongo"
  "iam-database-postgres"
  "iam-frontend-react"
  "iam-infrastructure"
  "iam-notification-service"
  "iam-redis-config"
  "iam-user-service"
  "iam-vault-config"
)

base_url="https://github.com/malak29"

for repo in "${repos[@]}"; do
  if [ -d "$repo" ]; then
    echo "⚠️  $repo already exists, skipping..."
  else
    git clone "$base_url/$repo.git"
  fi
done

echo "✅ All repositories cloned."
