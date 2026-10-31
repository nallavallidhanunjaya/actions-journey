#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== GitHub Actions Lab Setup Helper ==="

# Prompt the user for the token (standard read to support sh/bash environments)
read -p "Enter your GitHub Personal Access Token (PAT): " token
echo ""

if [ -z "$token" ]; then
    echo "Error: Token cannot be empty."
    exit 1
fi

# Ensure directories exist
mkdir -p /root/.github
echo "$token" > /root/.github/token

echo "Fetching GitHub username via API..."
login=$(curl -s -H "Authorization: token $token" https://api.github.com/user | jq -r '.login')

if [ "$login" == "null" ] || [ -z "$login" ]; then
    echo "Error: Failed to fetch GitHub username. Please check if your token is valid."
    exit 1
fi

echo "Authenticated as user: $login"

# Navigate to the repository directory
cd /root/actions-journey

# Configure remote URL safely (add if missing, update if it exists)
if git remote get-url origin > /dev/null 2>&1; then
    echo "Updating existing remote 'origin'..."
    git remote set-url origin https://${login}:${token}@github.com/${login}/actions-journey.git
else
    echo "Adding remote 'origin'..."
    git remote add origin https://${login}:${token}@github.com/${login}/actions-journey.git
fi

echo "Pulling latest changes with rebase..."
git pull origin main --rebase || echo "Pull skipped or already up to date."

echo "Staging workflows and changes..."
git add .github/workflows/

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit."
else
    read -p "Enter commit message (default: 'add workflow'): " commit_msg
    commit_msg=${commit_msg:-"add workflow"}
    git commit -m "$commit_msg"
fi

echo "Pushing to remote repository..."
git push origin -u main

echo "=== Setup and Push Completed Successfully! ==="
