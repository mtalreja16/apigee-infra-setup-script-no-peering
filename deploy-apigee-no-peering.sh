#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source ./utils.sh

gcloud config set project $PROJECT_ID

gcloud services enable apigee.googleapis.com \
  cloudkms.googleapis.com compute.googleapis.com --project=$PROJECT_ID

# gcloud services list

gcloud beta services identity create --service=apigee.googleapis.com \
  --project=$PROJECT_ID

RUNTIMEDBKEY_LOCATION=${RUNTIME_LOCATION}
RUNTIMEDB_KEY_RING_NAME="apigee-org-key-ring"
RUNTIMEDB_KEY_NAME="apigee-org-key"

gcloud kms keyrings create $RUNTIMEDB_KEY_RING_NAME \
  --location $RUNTIMEDBKEY_LOCATION --project $PROJECT_ID

gcloud kms keys create $RUNTIMEDB_KEY_NAME --keyring $RUNTIMEDB_KEY_RING_NAME \
  --location $RUNTIMEDBKEY_LOCATION --purpose "encryption" --project $PROJECT_ID

RUNTIMEDB_KEY_ID="projects/${PROJECT_ID}/locations/${RUNTIMEDBKEY_LOCATION}/keyRings/${RUNTIMEDB_KEY_RING_NAME}/cryptoKeys/${RUNTIMEDB_KEY_NAME}"

gcloud kms keys add-iam-policy-binding $RUNTIMEDB_KEY_NAME \
  --location $RUNTIMEDBKEY_LOCATION \
  --keyring $RUNTIMEDB_KEY_RING_NAME \
  --member serviceAccount:service-$PROJECT_NUMBER@gcp-sa-apigee.iam.gserviceaccount.com \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
  --project $PROJECT_ID

curl "https://apigee.googleapis.com/v1/organizations?parent=projects/$PROJECT_ID"  \
  -H "Authorization: Bearer $AUTH" \
  -X POST \
  -H "Content-Type:application/json" \
  -d '{
    "name":"'"$PROJECT_ID"'",
    "analyticsRegion":"'"$ANALYTICS_REGION"'",
    "runtimeType":"CLOUD",
    "billingType":"'"$BILLING_TYPE"'",
    "disableVpcPeering":"true",
    "runtimeDatabaseEncryptionKeyName":"'"$RUNTIMEDB_KEY_ID"'"
  }'

check_org_status $PROJECT_ID $AUTH

INSTANCE_NAME="test-instance"
DISK_KEY_RING_NAME="apigee-instance-key-ring"
DISK_KEY_NAME="apigee-instance-key"

gcloud kms keyrings create $DISK_KEY_RING_NAME \
  --location $RUNTIME_LOCATION \
  --project $PROJECT_ID

gcloud kms keys create $DISK_KEY_NAME --keyring $DISK_KEY_RING_NAME \
  --location $RUNTIME_LOCATION --purpose "encryption" --project $PROJECT_ID

DISK_KEY_ID="projects/${PROJECT_ID}/locations/${RUNTIME_LOCATION}/keyRings/${RUNTIMEDB_KEY_RING_NAME}/cryptoKeys/${RUNTIMEDB_KEY_NAME}"

gcloud kms keys add-iam-policy-binding $DISK_KEY_NAME \
  --location $RUNTIME_LOCATION \
  --keyring $DISK_KEY_RING_NAME \
  --member serviceAccount:service-$PROJECT_NUMBER@gcp-sa-apigee.iam.gserviceaccount.com \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
  --project $PROJECT_ID

curl "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances" \
    -X POST -H "Authorization: Bearer $AUTH" \
    -H "Content-Type:application/json" \
    -d '{
      "name":"'"$INSTANCE_NAME"'",
      "location":"'"$RUNTIME_LOCATION"'",
      "diskEncryptionKeyName":"'"$DISK_KEY_ID"'",
      "consumerAcceptList":["'"${PROJECT_ID}"'"]
    }'

check_instance_status $PROJECT_ID $AUTH $INSTANCE_NAME

ENVIRONMENT_NAME="dev"
ENV_GROUP_NAME="dev-test"
ENV_GROUP_HOSTNAME="dev.test"
MIN_NODE_COUNT="2"
MAX_NODE_COUNT="2"

curl "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/environments" \
  -H "Authorization: Bearer $AUTH" \
  -X POST \
  -H "Content-Type:application/json" \
  -d '{
    "name":"'"$ENVIRONMENT_NAME"'",
    "nodeConfig": {
      "minNodeCount":"'"$MIN_NODE_COUNT"'",
      "maxNodeCount":"'"$MAX_NODE_COUNT"'"
    }
  }'

check_env_status $PROJECT_ID $AUTH $ENVIRONMENT_NAME

curl "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/instances/$INSTANCE_NAME/attachments" \
    -X POST -H "Authorization: Bearer $AUTH" \
    -H "content-type:application/json" \
    -d '{
      "environment":"'"$ENVIRONMENT_NAME"'"
    }'

check_attach_status $PROJECT_ID $AUTH $ENVIRONMENT_NAME $INSTANCE_NAME

curl "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups" \
  -H "Authorization: Bearer $AUTH" \
  -X POST \
  -H "Content-Type:application/json" \
  -d '{
    "name": "'"$ENV_GROUP_NAME"'",
    "hostnames":["'"$ENV_GROUP_HOSTNAME"'"]
  }'

curl "https://apigee.googleapis.com/v1/organizations/$PROJECT_ID/envgroups/$ENV_GROUP_NAME/attachments" \
  -X POST \
  -H "Authorization: Bearer $AUTH" \
  -H "content-type:application/json" \
  -d '{
    "environment":"'"$ENVIRONMENT_NAME"'"
  }'