pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'workstation-367612'
        GKE_CLUSTER_NAME = 'example-autopilot-cluster'
        REGION = 'us-central1'
        GCP_CREDENTIALS_ID = 'gke-sa-json'
        VAULT_ADDR = 'http://<vault-cli-ip>:8200'
        VAULT_TOKEN = credentials('vault-token')
    }

    stages {
        stage('Connect to GKE') {
            steps {
                withCredentials([file(credentialsId: "${env.GCP_CREDENTIALS_ID}", variable: 'GOOGLE_CREDENTIALS' )]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_CREDENTIALS
                        gcloud config set project $PROJECT_ID
                        gcloud container clusters get-credentials $GKE_CLUSTER_NAME --region $REGION
                        kubectl get nodes
                    '''
                }
            }
        }

        stage('Create Script') {
    //   environment {
    //     VAULT_TOKEN = credentials('VAULT_TOKEN') // Secret Text credential in Jenkins
    //   }

      steps {
        script {
          // Write the shell script to a file
          writeFile file: 'rotate_and_upload_keys.sh', text: '''
echo "Listing all the keys for all tha SAs"
for sa in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Keys for $sa:"
  gcloud iam service-accounts keys list --iam-account="$sa" --format="table(name, keyType, validAfterTime, validBeforeTime)"
  echo ""
done

#Get the date 90 days ago in RFC3339 format (compatible with gcloud output)
cutoff_date=$(date -d '15 days ago' +"%Y-%m-%dT%H:%M:%SZ")
expiry_date=$(date -d '100 days' +"%Y-%m-%dT%H:%M:%SZ")

echo "Listing keys created before: $cutoff_date"
# echo "New keys will expire after: $expiry_date"
echo ""

# Loop through all service accounts in the current project
for sa in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Checking keys for: $sa"
  
  # List keys and filter those created before the cutoff_date
  gcloud iam service-accounts keys list \
    --iam-account="$sa" \
    --format="value(name, validAfterTime)" | while read -r name created; do
    
    if [[ "$created" < "$cutoff_date" ]]; then
      echo "  OLD KEY: $name (Created: $created)"

    # Create a new key for this service account (without expiration date)
      echo "Creating new key for $sa"

      # Create the key and save to a temporary file
        output_file=$(mktemp)
        gcloud iam service-accounts keys create "$output_file" --iam-account="$sa"

        # Extract key ID from the created JSON key file
        key_id=$(jq -r '.private_key_id' "$output_file")
        # key_name=$(gcloud iam service-accounts keys create "$output_file" --iam-account="$sa" --format="value(name)")

        echo "  New key created: $key_id"

        # Extract the key ID (it's the last part of the key name)
        # key_id=$(basename "$key_name")

        # Get current date
        today=$(date +"%d_%m_%Y")

        # Format the service account name to be Vault path-safe
        vault_sa_name=\$(echo "$sa" | sed "s/@/-/g" | sed "s/\\./-/g")
        echo "Vault-safe SA name: \$vault_sa_name"
        # Construct Vault path
        vault_path="kv/secret/$vault_sa_name/${key_id}_${today}"

        # Push the key JSON to Vault
        vault kv put "$vault_path" key=@"$output_file"

        echo "  Key stored in Vault at: $vault_path"

        # Clean up local file
        rm -f "$output_file"


    #   # Specify the file to save the key
    #   output_file="/tmp/$sa-new-key.json"  # Change the location if needed

    #   # Create the key and save to the specified file
    #   new_key=$(gcloud iam service-accounts keys create "$output_file" \
    #     --iam-account="$sa")
        
    #   echo "  New key created and saved to: $output_file"
    fi
  done
  echo ""
done


#!/bin/bash

# Get the date 97 days ago in RFC3339 format
cutoff_delete_date=$(date -d '97 days ago' +"%Y-%m-%dT%H:%M:%SZ")

echo "Deleting keys created before: $cutoff_date"
echo ""

# Loop through all service accounts in the current project
for sa in $(gcloud iam service-accounts list --format="value(email)"); do
  echo "Checking keys for: $sa"

  # List keys and filter those created before the cutoff_date
  gcloud iam service-accounts keys list \
    --iam-account="$sa" \
    --format="value(name, validAfterTime)" | while read -r name created; do

    if [[ "$created" < "$cutoff_delete_date" ]]; then
      echo "  DELETING OLD KEY: $name (Created: $created)"
      
      # Extract only the key ID (the last part of the key name)
      key_id=$(basename "$name")

      # Delete the key
      gcloud iam service-accounts keys delete "$key_id" \
        --iam-account="$sa" --quiet
    fi
  done
  echo ""
done

          '''
        }
      }
    }

    stage('Execute Script') {
      steps {
        sh 'chmod +x rotate_and_upload_keys.sh && bash rotate_and_upload_keys.sh'
      }
    }
    }
}
