#!/bin/bash

# Usage: ./run-demo.sh -d -n -w5
# -d: Disables the simulated typing, which can be useful for debugging your script.
# -n: Sets "no wait" mode, where the script doesn't wait for you to press Enter after p and pe functions.
# -w <seconds>: Sets a timeout for waiting. If you don't press Enter within the specified time, the demo will proceed automatically.

# load demo-magic.sh
. ./demo-magic.sh

# export DEMO_PROMPT="[KubeCon-Demo] 👩‍💻 \$ "

#TYPE_SPEED=20
ORIGINAL_TYPE_SPEED=$TYPE_SPEED
FASTER_TYPE_SPEED=100

# hide the evidence
clear

# 'p' (Print)
# 'pe' (Print and Execute)
# 'pei' (Print and Execute immediately)
# 'wait' pause until Enter
pei "# AI-conformant clusters support Dynamic Resource Allocation (DRA) APIs"
pei "# Verify that DRA driver is running"
pei "kubectl get pods -n nvidia-dra-driver-gpu"
pei "# Confirm that the ResourceSlice lists the hardware devices"
pei "kubectl get resourceslices -o custom-columns=SLICE:.metadata.name,DEVICE_NAMES:.spec.devices[*].name"

pei "# Deploy a vLLM deployment serving Gemma model using DRA"
pe "less claim-template.yaml"
pei "kubectl apply -f claim-template.yaml"
pe "less vllm-3-1b-it-dra.yaml"
pei "kubectl apply -f vllm-3-1b-it-dra.yaml"
pei "kubectl wait --for=condition=Available --timeout=1800s deployment/vllm-gemma-deployment"
pei "kubectl logs -f -l app=gemma-server"

pei "# Now run 'kubectl port-forward service/llm-service 8000:8000' in a separate terminal"
pei "# Ask Gemma model about KubeCon"
TYPE_SPEED=$FASTER_TYPE_SPEED
CMD=$(cat <<EOF
curl http://127.0.0.1:8000/v1/chat/completions \
-X POST \
-H "Content-Type: application/json" \
-d '{
    "model": "google/gemma-3-1b-it",
    "messages": [
        {
          "role": "user",
          "content": "What is KubeCon?"
        }
    ]
}' | jq
EOF
)
pe "$CMD"
TYPE_SPEED=$ORIGINAL_TYPE_SPEED
wait

pei "# AI-conformant clusters exposes performance metrics of its accelerators"
pei "# Now run the following in a separate terminal for accessing exported GPU metrics:"
pei "# export DCGM_POD_NAME=\$(kubectl get pods --namespace gke-managed-system -l app.kubernetes.io/name=gke-managed-dcgm-exporter -o jsonpath='{.items[0].metadata.name}')"
pei "# kubectl -n gke-managed-system port-forward \${DCGM_POD_NAME} 9400:9400"
pei "# Check the GPU metrics"
pe "curl -s http://localhost:9400/metrics | grep DCGM_FI_DEV_GPU_"
wait

pei "# AI-conformant clusters can scale Pods utilizing accelerators based on custom metrics."
pei "# Autoscale the AI workload based on GPU utilization"
pei "less gemma-hpa.yaml"
wait
pei "kubectl apply -f gemma-hpa.yaml"
pei "# In a separate terminal, run ./request-looper.sh to generate some loads to the vLLM server..."
wait
pei "kubectl get hpa -w"
wait

# Clean up
