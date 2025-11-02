# KubeCon Demo for AI Conformance

* GKE 1.34 standard cluster with a DRA node pool with L4 GPUs
  * See more details in [set up DRA](https://cloud.google.com/kubernetes-engine/docs/how-to/set-up-dra)
  * Note: Creating Spot VM node pools is usually easier to obtain GPUs 
* `dcgm-exporter-config.yaml` is used for configuring GPU metrics for DRA nodepools, given that DRA requires disabling the default device plugin.

```sh
gcloud container clusters create ${CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --location=${LOCATION} \
    --release-channel=rapid \
    --num-nodes=1 \
    --enable-managed-prometheus \
    --monitoring=SYSTEM,DCGM

gcloud container node-pools create drapool \
    --project=${PROJECT_ID} \
    --cluster=${CLUSTER_NAME} \
    --location=${LOCATION} \
    --node-locations=${LOCATION}-b \
    --machine-type "g2-standard-24" \
    --accelerator "type=nvidia-l4,count=2,gpu-driver-version=disabled" \
    --spot \
    --num-nodes "1" \
    --node-labels=gke-no-default-nvidia-gpu-device-plugin=true,nvidia.com/gpu.present=true
```

You need to create a secret to download models in your vLLM service

```sh
kubectl create secret generic hf-secret \
    --from-literal=hf_api_token=${HF_TOKEN} \
    --dry-run=client -o yaml | kubectl apply -f -
```

Start a demo by running `./run-demo.sh`, which uses demo magic to type commands.