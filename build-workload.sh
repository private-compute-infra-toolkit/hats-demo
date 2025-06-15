WORKSPACE=$(readlink -f ./src/)
RUNTIME=$(readlink -f ./run/)
HATS_CACHE=$(readlink -f ./.hats-cache/)
docker run \
  -it \
  -v $WORKSPACE:/workspace \
  -v $RUNTIME:/run \
  -v $HATS_CACHE/nix:/nix \
  -v $HATS_CACHE/bazel:/root/.cache/ \
  -v $HATS_CACHE/optsuser:/home/optsuser/ \
  -v $HATS_CACHE/optsuser-bazel:/home/optsuser/.cache \
  hats-demo-builder:latest \
  /workspace/workloads/trusted-application/build-in-docker.sh

cp -r ./src/tvs_appraisal_policy_gen/ ./run/
cp -r ./src/system_check/ ./run/
