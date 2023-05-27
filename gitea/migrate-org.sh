#!/bin/bash

ORG=$1

#USERNAME=$1
USER_API_URL="https://api.github.com/users/$USERNAME/repos"

API_URL="https://api.github.com/orgs/$ORG/repos"
PAGE=1

# appears uncoupled from limit of 100 repos
PER_PAGE=100

# Function to retrieve repositories for a given page
get_repos() {
  local page=$1
  curl -s "$USER_API_URL?page=$page&per_page=$PER_PAGE"
}

# Query GitHub API for the first page of repositories
response=$(get_repos $PAGE)

# Check if organization exists
if [[ $response =~ "Not Found" ]]; then
  echo "Organization not found."
  exit 1
fi

# Get total number of repositories
total_repos=$(echo "$response" | grep -oE '"full_name": "[^"]+"' | wc -l)

# Initialize array for repositories
repos=()

# Parse repository names and add to the array
repos+=($(echo "$response" | grep -oE '"full_name": "[^"]+"' | awk -F': "' '{print $2}' | tr -d '"'))

# Calculate number of pages needed
num_pages=$((($total_repos + $PER_PAGE - 1) / $PER_PAGE))

# Loop through the remaining pages and retrieve repositories
for ((page=2; page<=num_pages; page++)); do
  response=$(get_repos $page)
  repos+=($(echo "$response" | grep -oE '"full_name": "[^"]+"' | awk -F': "' '{print $2}' | tr -d '"'))
done

# Loop through the array and output each repository
for repo in "${repos[@]}"; do
  echo "$repo"
  bash migrate-repo.sh $repo
done

# Display count of repositories
echo "Total Repositories: $total_repos"
