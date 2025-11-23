#!/usr/bin/env bash
#
# Simple Disk Usage Monitoring Script with AWS SNS Alerts
# Requires: awscli configured, SNS topic with email subscription
#

set -euo pipefail

########## CONFIGURATION ##########

# Disk usage threshold in percent (integer, no % sign)
THRESHOLD=1

# Filesystem / mount point to monitor (e.g. /, /data, /home)
TARGET_MOUNT="/"

# REPLACE WITH YOUR OWN AWS SNS Topic ARN
SNS_TOPIC_ARN="arn:aws:sns:ap-south-1:935987223376:disk-usage-monitoring"

# AWS Region (optional if already set in AWS config)
AWS_REGION="ap-south-1"

###################################

HOSTNAME=$(hostname)

# Get current disk usage percentage (numeric only)
CURRENT_USAGE=$(df -hP "$TARGET_MOUNT" | awk 'NR==2 { gsub("%","",$5); print $5 }')

# Safety: if CURRENT_USAGE is empty or non-numeric, exit
if ! [[ "$CURRENT_USAGE" =~ ^[0-9]+$ ]]; then
  echo "Error: Could not determine disk usage for $TARGET_MOUNT"
  exit 1
fi

echo "[$(date)] Disk usage on $TARGET_MOUNT: ${CURRENT_USAGE}% (threshold: ${THRESHOLD}%)"

if [ "$CURRENT_USAGE" -ge "$THRESHOLD" ]; then
  SUBJECT="Disk space alert on ${HOSTNAME}: ${CURRENT_USAGE}% used"
  MESSAGE="WARNING: Disk usage on host ${HOSTNAME} has reached ${CURRENT_USAGE}%.
Mount point: ${TARGET_MOUNT}
Threshold:  ${THRESHOLD}%

Please investigate and free up space if needed.

Timestamp: $(date)
"

  echo "Threshold exceeded. Sending SNS alert..."

  aws sns publish \
    --topic-arn "$SNS_TOPIC_ARN" \
    --subject "$SUBJECT" \
    --message "$MESSAGE" \
    --region "$AWS_REGION"

  echo "SNS alert sent."
else
  echo "Disk usage is below threshold. No action taken."
fi
