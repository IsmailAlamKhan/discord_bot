    gcloud projects add-iam-policy-binding supple-serenity-458409-n0 \
        --member="serviceAccount:github-actions-sa@supple-serenity-458409-n0.iam.gserviceaccount.com" \
        --role="roles/artifactregistry.writer"

    gcloud projects add-iam-policy-binding supple-serenity-458409-n0 \
        --member="serviceAccount:github-actions-sa@supple-serenity-458409-n0.iam.gserviceaccount.com" \
        --role="roles/run.developer"

    gcloud projects add-iam-policy-binding supple-serenity-458409-n0 \
        --member="serviceAccount:github-actions-sa@supple-serenity-458409-n0.iam.gserviceaccount.com" \
        --role="roles/secretmanager.secretAccessor"

    gcloud projects add-iam-policy-binding supple-serenity-458409-n0 \
        --member="serviceAccount:github-actions-sa@supple-serenity-458409-n0.iam.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"
        
