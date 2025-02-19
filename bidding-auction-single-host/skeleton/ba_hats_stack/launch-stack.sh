#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

STACK="$1"
if [[ ! -d "$STACK" ]]; then
  echo "Expected the folder containing B&A stack prototext files"
  exit 1
fi
STACK=$(readlink -f "$STACK")
TVS_ADDRESS='localhost:7774'
SCRIPT_DIR=$(readlink -f $(dirname "$0"))
LAUNCHER_SCRIPT=$(readlink -f $(dirname "$0")/launcher_main)
if [[ ! -e "$LAUNCHER_SCRIPT" ]]; then
  echo "Expected usable launch script at $LAUNCHER_SCRIPT"
  exit 1
fi
CFG=(
    "$STACK/auction.prototext"
    "$STACK/bidding.prototext"
    "$STACK/bfe.prototext"
    "$STACK/sfe.prototext"
)

function launch_ba() {
if [[ ! -f "$1" ]]; then
  echo "Please provide a valid path containing launcher config."
  exit 1
fi

if [[ ! `curl -sS localhost:7774 2>&1 | grep "(1) Received HTTP/0.9 when not allowed"` ]]; then
  echo "TVS server at address $TVS_ADDRESS is not responding, please run the server again."
  exit 1
fi

sudo "$LAUNCHER_SCRIPT" \
  --curl_opt_cainfo=`curl-config --ca` \
  --tvs_addresses=localhost:7774 \
  --use_tls=false \
  --launcher_config_path=$1 \
  --tvs_authentication_key="$(cat ./launcher_hold_user_authentication_private_key_hex)" \
  --vmm_log_to_std \
  --minloglevel=0 \
  --stderrthreshold=0
}

PIDS=()

kill_scripts() {
    echo "Killing all running scripts..."
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "Killed script with PID $pid"
        fi
    done
    exit 0
}

# Trap SIGINT (Ctrl+C) and SIGTERM to kill all scripts
trap kill_scripts SIGINT SIGTERM

# Run each script in the background and redirect stdout/stderr to log files
for cfg in "${CFG[@]}"; do
    if [[ -e "$cfg" ]]; then
        LOG_FILE="${cfg}.log"
        ERROR_FILE="${cfg}_error.log"
        echo "Running ${cfg} stdout=$LOG_FILE, stderr=$ERROR_FILE"
        launch_ba "$cfg" > "$LOG_FILE" 2> "$ERROR_FILE" &
        PIDS+=($!)
        sleep 1
    else
        echo "Error: $cfg does not exist."
        kill_scripts
    fi
done

wait
echo "All scripts have finished."
