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

export AUTH="$(gcloud auth print-access-token)"
export PROJECT_ID="YOUR_PROJECT_ID"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export RUNTIME_LOCATION="YOUR_RUNTIME_LOCATION"
export ANALYTICS_REGION="YOUR_ANALYTICS_REGION"
export BILLING_TYPE="YOUR_BILLING_TYPE"
export SUBNET_PSC_EP="SUBNET_FOR_PSC_EP" # full name such as "projects/PROJECT_ID/regions/us-east1/subnetworks/SUBNET_NAME"
export NETWORK_NAME="NETWORK WHERE PSC EP WILL RESIDE" # full name such as "projects/PROJECT_ID/global/networks/VPC_NAME"