#!/bin/bash

# Set your New Relic Insert API Key and Account ID
API_KEY="YOUR_INSERT_API_KEY"
ACCOUNT_ID="YOUR_ACCOUNT_ID"
HOSTNAME=$(hostname)

# Define unique patterns to identify each JVM in the process list
JVM_PATTERNS=("AppServer1" "AppServer2" "AppServer3" "AppServer4" "AppServer5")

total_up=0

for jvm in "${JVM_PATTERNS[@]}"; do
  if ps aux | grep -v grep | grep -q "$jvm"; then
    status=1  # JVM is running
    ((total_up++))
  else
    status=0  # JVM is down
  fi

  # Send individual JVM status to New Relic
  curl -s -X POST https://insights-collector.newrelic.com/v1/accounts/$ACCOUNT_ID/events \
    -H "X-Insert-Key:$API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"eventType\": \"JVMHealth\",
      \"host\": \"$HOSTNAME\",
      \"jvm\": \"$jvm\",
      \"status\": $status
    }"
done

# Send overall summary (optional)
summary_status=$([[ $total_up -eq 5 ]] && echo 1 || echo 0)

curl -s -X POST https://insights-collector.newrelic.com/v1/accounts/$ACCOUNT_ID/events \
  -H "X-Insert-Key:$API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"eventType\": \"JVMHealthSummary\",
    \"host\": \"$HOSTNAME\",
    \"jvms_up\": $total_up,
    \"overall_status\": $summary_status
  }"
