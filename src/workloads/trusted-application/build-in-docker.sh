#!bin/bash
cd /workspace/
runuser -u optsuser -- bazel build workloads/trusted-application/server:bundle
cp bazel-bin/workloads/trusted-application/server/bundle.tar /run/runtime_bundle.tar
runuser -u optsuser -- bazel build workloads/trusted-application/client:trusted_application_client_main
cp bazel-bin/workloads/trusted-application/client/trusted_application_client_main /run/trusted_application_client_main
cp workloads/trusted-application/deploy/* /run/
chmod 777 -R /run/
