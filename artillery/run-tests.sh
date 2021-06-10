#!/bin/bash

echo "Executing Artillery load tests from $ARTILLERY_YAML_FILE"

echo "list files inside of /tests folder"

ls /tests

artillery run $ARTILLERY_YAML_FILE -o "${REPORT_NAME}.json"

echo "Creating results file"

NOW=$(date +"%H_%M_%m_%d_%Y")
REPORT_FILE="${REPORT_NAME}-${NOW}.html"

artillery report -o "$REPORT_FILE" "${REPORT_NAME}.json"

#Upload the file
echo $AZURE_STORAGE_CONNECTION_STRING
az storage blob upload -f $REPORT_FILE -c '$web' -n $REPORT_FILE