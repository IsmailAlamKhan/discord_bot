#!/bin/bash

# Check if .env file exists
if [ ! -f ".env" ]; then
  echo "Error: .env file not found in the current directory."
  exit 1
fi

echo "Reading .env file and creating secrets in Google Secret Manager..."
echo "---"

# Read .env file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  if [[ -z "$line" || "$line" =~ ^# ]]; then
    continue
  fi

  # Split line into key and value at the first '='
  key=$(echo "$line" | cut -d '=' -f 1)
  value=$(echo "$line" | cut -d '=' -f 2-)

  # Simple check if key or value is empty after split
  if [[ -z "$key" || -z "$value" ]]; then
    echo "Skipping invalid line: $line"
    continue
  fi

  # Convert key to a suitable secret name (lowercase, underscores to hyphens)
  # Example: BOT_TOKEN -> bot-token
  secret_name=$(echo "$key" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')

  echo "Attempting to create secret: $secret_name for key: $key"

  # Use echo -n to avoid adding a newline to the secret value
  # Pipe the value to gcloud secrets create using --data-file=- for security
  # Add automatic replication policy
  if echo -n "$value" | gcloud secrets create "$secret_name" \
       --data-file=- \
       --replication-policy="automatic" \
       --quiet; then
    echo "Successfully created secret: $secret_name"
  else
    # Check if the secret already exists (exit code 6 is often 'Already Exists')
    if [ $? -eq 6 ]; then
        echo "Secret '$secret_name' already exists. Skipping creation."
        # Optionally, you could add code here to update the secret version if needed:
        # echo -n "$value" | gcloud secrets versions add "$secret_name" --data-file=- --quiet
        # echo "Added new version to existing secret: $secret_name"
    else
        echo "Failed to create secret: $secret_name. Check permissions or gcloud output."
    fi
  fi
  echo "---"

done < ".env"

echo "Finished processing .env file."
echo "IMPORTANT: Remember to update your cloudbuild.yaml file's '--set-secrets' argument with the generated secret names (e.g., bot-token, admin-user-id)."