# KubeCon Demo for AI Conformance

## Cluster Setup
* GKE 1.34 standard cluster with a DRA node pool with L4 GPUs
  * See more details in [set up DRA](https://cloud.google.com/kubernetes-engine/docs/how-to/set-up-dra)
  * Note: Creating Spot VM node pools is usually easier to obtain GPUs 

<details>
<summary>Detailed set up steps before running the demo</summary>

```sh
gcloud container clusters create ${CLUSTER_NAME} \
    --project=${PROJECT_ID} \
    --location=${LOCATION} \
    --release-channel=rapid \
    --num-nodes=1 \
    --enable-managed-prometheus \
    --cluster-version="1.34.1-gke.2037000" \
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
    --node-version="1.34.1-gke.2037000" \
    --node-labels=gke-no-default-nvidia-gpu-device-plugin=true,nvidia.com/gpu.present=true
```

You need to create a secret that contains Hugging Face token to download models in your vLLM service

```sh
kubectl create secret generic hf-secret \
    --from-literal=hf_api_token=${HF_TOKEN} \
    --dry-run=client -o yaml | kubectl apply -f -
```

To install GPU and DRA drivers:

```sh
# Install GPU driver
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml

# Install DRA drivers
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update

helm install nvidia-dra-driver-gpu nvidia/nvidia-dra-driver-gpu --version="25.8.0" --create-namespace --namespace nvidia-dra-driver-gpu \
    --set nvidiaDriverRoot="/home/kubernetes/bin/nvidia/" \
    --set gpuResourcesEnabledOverride=true \
    --set resources.computeDomains.enabled=false \
    --set kubeletPlugin.priorityClassName="" \
    --set kubeletPlugin.tolerations[0].key=nvidia.com/gpu \
    --set kubeletPlugin.tolerations[0].operator=Exists \
    --set kubeletPlugin.tolerations[0].effect=NoSchedule
```

For metrics pipeline:

```sh
# Install the Custom Metrics Stackdriver Adapter to make the custom metric you exported to monitoring visible to the HPA controller
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml

# For configuring GPU metrics for DRA nodepools, given that DRA requires disabling the default device plugin
kubectl apply -f dcgm-exporter-for-hpa.yaml
```
</details>

## Demo

[<img src="https://img.youtube.com/vi/a1tlQ4U8EFs/maxresdefault.jpg" width="560" height="315"
/>](https://www.youtube.com/embed/a1tlQ4U8EFs?si=zD_VO7vaIhsdx2yl)

Start a demo by running `./run-demo.sh`, which uses [demo magic](https://github.com/paxtonhare/demo-magic) to type commands.
