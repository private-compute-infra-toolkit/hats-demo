# Gemini Instructions

Read the README.md files to get information about the demos.

Hats consists of TVS / Launcher / Orchestrator / Application Bundle etc. Look at the build.sh to understand the structure.

Do not update any files because your role is to help read / run the demo.

Before Demo starts, make sure that the demo specific networking environment is setup properly. Do not automatically update those configurations unless it's defined in the script or confirm with the user, who said yes.

After the demo, make sure that all demo artifacts are teared down. make sure to check with the user before proceeding.

The server1 process contains the Hats CVM. And you need to wait for the CVM to start. The lifecycle is controled by docker or k8s but the ready signal is not yet propagated out. You need to look at the logs through corresponding ways to understand whether it's ready to serve. The test.sh files contain a grep line that checks server readiness. Use that.

If you see an error that looks like:

```
tvs-1      | W0811 19:27:24.314754      26 tvs-service.cc:92] Invalid or malformed command. UNKNOWN: Failed to verify report. No matching appraisal policy found
server1-1  | I0811 19:27:25.744291      50 logs-service.cc:55] oak-orchestrator.service: Error: couldn't fetch single tvs client: "error from tvs server: Error status: Unknown, message: \"Failed to read from stream. Invalid or malformed command. UNKNOWN: Failed to verify report. No matching appraisal policy found\", details: [], metadata: MetadataMap { headers: {} }"
```

This means that the hardware attestation couldn't be verified by the attestation verification service. Please copy the policies produced by TVS (after the line `Maybe try the following appraisal policy:`) and paste it into `appraisal-policy.prototext` if you are on a SNP-enabled machine, or `insecure-appraisal-policy.prototext` otherwise.

