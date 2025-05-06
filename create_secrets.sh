    #!/bin/bash

    # Check if .env file exists
    if [ ! -f ".env" ]; then
      echo "Error: .env file not found in the current directory."
      exit 1
    fi

    echo "Reading .env file and creating secrets in Google Secret Manager..."
    echo "TARGET PROJECT: red-door-bot"
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

      if [[ -z "$key" || -z "$value" ]]; then
        echo "Skipping invalid line: $line"
        continue
      fi

      secret_name=$(echo "$key" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')

      echo "Attempting to create secret: $secret_name for key: $key"

      if echo -n "$value" | gcloud secrets create "$secret_name" \
           --project=red-door-bot \
           --data-file=- \
           --replication-policy="automatic" \
           --quiet; then
        echo "Successfully created secret: $secret_name in project red-door-bot"
      else
        if [ $? -eq 6 ]; then
            echo "Secret '$secret_name' already exists in project red-door-bot. Skipping creation."
        else
            echo "Failed to create secret: $secret_name in project red-door-bot. Check permissions or gcloud output."
        fi
      fi
      echo "---"

    done < ".env"

    echo "Finished processing .env file."
    echo "IMPORTANT: Note the secret names created (e.g., bot-token, admin-user-id). You'll need these for your workflow file."