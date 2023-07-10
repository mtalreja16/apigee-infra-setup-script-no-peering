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

# #1 - PROJECT_ID #2 - AUTH
check_org_status() {

    while true
    do
        ORG_STATE=$(curl -s -H "Authorization: Bearer ${2}" "https://apigee.googleapis.com/v1/organizations/${1}" | jq .state)
        if [ $ORG_STATE = '"ACTIVE"' ] 
        then
            echo "Org ${1} is already provisioned."
            break
        fi
        echo "3"
        echo "Org ${1} still not provisioned. Waiting for 30 seconds"
        sleep 30
    done
}

# #1 - PROJECT_ID #2 - AUTH #3 - INSTANCE_NAME
check_instance_status() {

    while true
    do
        INSTANCE_STATE=$(curl -s -H "Authorization: Bearer ${2}" "https://apigee.googleapis.com/v1/organizations/${1}/instances/${3}" | jq .state)
        if [ $INSTANCE_STATE = '"ACTIVE"' ] 
        then
            echo "Instance ${3} in org ${1} is already provisioned."
            break
        fi
        echo "Instance ${3} in org ${1} still not provisioned. Waiting for 30 seconds"
        sleep 30
    done
}

# #1 - PROJECT_ID #2 - AUTH #3 - ENV_NAME
check_env_status() {

    while true
    do
        ENV_STATE=$(curl -s -H "Authorization: Bearer ${2}" "https://apigee.googleapis.com/v1/organizations/${1}/environments/${3}" | jq .state)
        if [ $ENV_STATE = '"ACTIVE"' ] 
        then
            echo "Env ${3} in org ${1} is already provisioned."
            break
        fi
        echo "Env ${3} in org ${1} still not provisioned. Waiting for 30 seconds"
        sleep 30
    done
}

# #1 - PROJECT_ID #2 - AUTH #3 - ENV_NAME #4 - INSTANCE_NAME
check_attach_status() {

    while true
    do
        ATTACH_STATE=$(curl -s -H "Authorization: Bearer ${2}" "https://apigee.googleapis.com/v1/organizations/${1}/instances/${4}/attachments" | jq '.attachments[0].environment')
        if [ $ATTACH_STATE = '"'${3}'"' ] 
        then
            echo "Env ${3} in org ${1} is already attached to ${4} provisioned."
            break
        fi
        echo "Env ${3} in org ${1} still not attached to ${4}. Waiting for 30 seconds"
        sleep 30
    done
}

# $1 - PROJECT_ID #2 - AUTH
get_svc_attachment() {
    SVC_ATTACHMENT=$(curl -s -H "Authorization: Bearer ${2}" "https://apigee.googleapis.com/v1/organizations/${1}/instances" | jq '.instances[0].serviceAttachment' | tr -d '"' )
    echo $SVC_ATTACHMENT 
}