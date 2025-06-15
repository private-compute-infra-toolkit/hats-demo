# Hats Demo in Docker compose

This demo shows running and attesting a container workload running in a CVM using the Hats Stack.

For this demo, the workload will be an oci container with ollama and gemma3 installed.

## Prerequisite

On both your `Build machine` and `Test machine`, install

-   `git` ( [Install guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) )
-   `docker engine` ( [Public install guide](https://docs.docker.com/engine/install/),
    [Googler cloudtop install guide](go/installdocker) )
    - Please use sudoless mode following [Postinstall instruction](https://docs.docker.com/engine/install/linux-postinstall/)
    - You may need to logout of your shell or run `newgrp docker` to activate the new groups for change to apply.
    - Check by running `docker ps`.
-   `docker compose`
    - [Public install guide](https://docs.docker.com/compose/install/)
    - [Googler install guide](go/installdocker#docker-compose)
    - Check by running `docker compose` or `docker-compose` depending on how it's installed.


On your `Test machine`, ensure `192.168.84.0/24` IP range is free to use and there's no network
interface named `hats-dev`.

You must set SELinux to permissive mode in order to run the CVMs. Run

```
sudo setenforce 0
```

## Build Source code

NOTE: Before open sourcing is done, the `Build machine` must be your `Cloudtop` with corp access!

On the `Build machine`, build the Hats stack and container workload

```
./build.sh

# The steps below can be replaced with the steps to build workload of your choice
cd ../build-ollama-gemma3-bundle
./build-image.sh
cp target/ollama-gemma3-image.tar ../on-prem-docker-demo/build_dependencies/output/workload.tar
# Here I am copying the appraisal policy and launcher config for my workload
cp conf/appraisal_policy.prototext ../on-prem-docker-demo/run_dependencies/conf/
cp conf/ollama_gemma3_1b.prototext ../on-prem-docker-demo/run_dependencies/conf/launcher_config.prototext
cd ../on-prem-docker-demo
```

The resulting artifacts are stored in `./build_dependencies/output` folder. It should contain the
following files:

```
launcher_main
system_bundle.tar
tvs-server_main
workload.tar
```

Once verified, please copy the `./build_dependencies/output` folder to `./run_dependencies/output`
folder. `ls ./run_dependencies/output` should result in the same set of files as above.

## Run the stack

Please transfer `run_dependencies` folder to the `Test machine`. You can do so with

-   SSH: `scp -r <build_machine>:<path to hats-demo>/run_dependencies <test_machine>:~/`
-   Google Drive: Upload `run_dependencies` folder to Google Drive and download it on the `Test machine`.

### Enable required kernel modules

First we need to enable vhost_vsock kernel module.

```
sudo modprobe vhost_vsock
```

### Update stage0 measurement in appraisal policy

Every machine may have different BIOS configuration leading to different stage0 measurement.

Update `run_dependencies/conf/appraisal_policy.prototext` by running `update_stage0_measurement.sh`
inside `run_dependencies/tvs_appraisal_policy_gen/`.

### Optional: Update container binary sha256

In the case that appraisal policy is out of sync with the container runc bundles ( e.g. bfe.tar
files ). We need to update the container binary sha256 field.

Update `run_dependencies/conf/appraisal_policy.prototext` by running
`update_container_binary_sha256.sh` inside `run_dependencies/tvs_appraisal_policy_gen/`.

### Fire up the workload on prem with docker compose

In `run_dependencies` folder, run

```
docker compose up
```

or, if you installed standalone docker compose:

```
docker-compose up
```

This creates a "hats-dev" docker network bridge for all the traffic at `192.168.84.0/24` and then the whole workload + hats stack onprem. Wait for a
line looks like

```
workload-launcher-1  | I0603 21:13:26.161902      37 logs-service.cc:55] oak-orchestrator.service: time=2025-06-03T21:13:24.896Z level=INFO source=ggml.go:351 msg="model weights" buffer=CPU size="1.0 GiB"
⠹ time=2025-06-03T21:13:24.930Z level=INFO source=ggml.go:638 msg="compute graph" backend=CPU buffer_type=CPU size="68.2 MiB"
⠼ time=2025-06-03T21:13:25.047Z level=INFO source=server.go:625 msg="waiting for server to become available" status="llm server loading model"
⠦ time=2025-06-03T21:13:25.298Z level=INFO source=server.go:630 msg="llama runner started in 0.51 seconds"
workload-launcher-1  | I0603 21:13:26.161917      37 logs-service.cc:55] oak-orchestrator.service: [GIN] 2025/06/03 - 21:13:25 | 200 |   689.82897ms |       127.0.0.1 | POST     "/api/generate"
```

to show up for `workload-launcher-1`. It means the stack is ready to serve traffic. _We're working on
improving the healthcheck monitoring_. You can safely ignore
`oak-agent.service: oak-agent: OTLP error: Metrics error: export timed out`.

### Query model using Ollama REST API
```
curl http://192.168.84.204:11434/api/chat -d '{
  "model": "gemma3:1b",
  "messages": [
    { "role": "user", "content": "why is the sky blue?" }
  ]
}'
```

### Start open-webui frontend
```
docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://192.168.84.204:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
```

Now we can interact with our gemma3 model through the ui on the host machine at http://localhost:8080.

**SSH Tunneling (for remote Test Machine):**

If the Test Machine is running remotely (e.g., on a separate Mac machine), establish an SSH tunnel
to forward the necessary ports:

```bash
ssh -L 8080:localhost:8080 <Test machine address>
```

In Chrome, open `localhost:8080`.
