#!/bin/bash

API_KEY="YOUR_INSERT_API_KEY"
ACCOUNT_ID="YOUR_ACCOUNT_ID"
HOSTNAME=$(hostname)

JVM_PATTERNS=("AppServer1" "AppServer2" "AppServer3" "AppServer4" "AppServer5")

total_up=0
events="["

first=1
for jvm in "${JVM_PATTERNS[@]}"; do
  if ps aux | grep -v grep | grep -q "$jvm"; then
    status=1
    ((total_up++))
  else
    status=0
  fi

  if [ $first -eq 0 ]; then
    events+=","
  fi

  events+="
  {
    \"eventType\": \"JVMHealth\",
    \"host\": \"$HOSTNAME\",
    \"jvm\": \"$jvm\",
    \"status\": $status
  }"

  first=0
done

summary_status=$([[ $total_up -eq ${#JVM_PATTERNS[@]} ]] && echo 1 || echo 0)

events+=",{
  \"eventType\": \"JVMHealthSummary\",
  \"host\": \"$HOSTNAME\",
  \"jvms_up\": $total_up,
  \"overall_status\": $summary_status
}]"

curl -s -X POST https://insights-collector.newrelic.com/v1/accounts/$ACCOUNT_ID/events \
  -H "X-Insert-Key:$API_KEY" \
  -H "Content-Type: application/json" \
  -d "$events"
