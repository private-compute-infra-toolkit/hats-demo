#!bin/bash
echoerr() { echo "$@" 1>&2; }

# Ensure required environment variables are set.
if [[ -z "${USER_KEY_ID}" ||
  -z "${USER_PUBLIC_KEY}" ||
  -z "${USER_SECRET}" ||
  -z "${USER_AUTHENTICATION_PUBLIC_KEY}" ||
  -z "${APPRAISAL_POLICY_FILE}"
  ]]; then
  printenv
  echoerr "USER_KEY_ID / USER_PUBLIC_KEY / USER_SECRET / USER_AUTHENTICATION_PUBLIC_KEY / APPRAISAL_POLICY_FILE is expected to be non-empty"
  exit 1
fi

RUST_LOG="debug" /tvs-server_main \
--primary_private_key="0000000000000000000000000000000000000000000000000000000000000001" \
--accept_insecure_policies \
--user_key_id=${USER_KEY_ID} \
--user_public_key="${USER_PUBLIC_KEY}" \
--user_secret="${USER_SECRET}" \
--user_authentication_public_key="${USER_AUTHENTICATION_PUBLIC_KEY}" \
--port=7774 \
--appraisal_policy_file="${APPRAISAL_POLICY_FILE}" \
--minloglevel 0 \
--stderrthreshold 0 \
--v -1

