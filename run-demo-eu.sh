#!/bin/bash

# Usage: ./run-demo.sh -d -n -w5
# -d: Disables the simulated typing, which can be useful for debugging your script.
# -n: Sets "no wait" mode, where the script doesn't wait for you to press Enter after p and pe functions.
# -w <seconds>: Sets a timeout for waiting. If you don't press Enter within the specified time, the demo will proceed automatically.

. ./demo-magic.sh

export DEMO_PROMPT="☸️ \$ " 

#TYPE_SPEED=20
ORIGINAL_TYPE_SPEED=$TYPE_SPEED
FASTER_TYPE_SPEED=100

# hide the evidence
clear

# 'p' (Print)
# 'pe' (Print and Execute)
# 'pei' (Print and Execute immediately)
# 'wait' pause until Enter

export NAMESPACE=llm-d-pd
pei "# This demo uses a Kubernetes AI-conformant cluster"
pei "# ✅ AI-conformant platforms MUST support the Kubernetes Gateway API with an implementation for advanced traffic management for inference services"
pei "# First, check if the platform has defined a Gateway implementation"
pei "kubectl get gatewayclass"
pei "# Then, check if the Gateway is ready"
pei "kubectl get gateway -n \${NAMESPACE} -o custom-columns=NAME:.metadata.name,CLASS:.spec.gatewayClassName"
wait

pei "# ✅ AI-conformant platforms SHOULD support Gateway API Inference Extension (GAIE)"
pei "# Check that InferencePool is ready"
pei "kubectl get inferencepools -n \${NAMESPACE}"
pei "# Check that inference scheduler is ready"
pei "kubectl get pods -n \${NAMESPACE} -l inferencepool=gaie-pd-epp"
pei "# Check HTTPRoute status"
pei "kubectl get httproute -n \${NAMESPACE} -o yaml | grep -A 10 \"status:\""
pei "# Verify the HTTPRoute is properly attached to the Gateway and routing to the InferencePool"
pei "kubectl get gateway -n \${NAMESPACE} -o yaml | grep -A 5 \"attachedRoutes\""

pei "# ✅ AI-conformant platforms SHOULD support disaggregated inference"
pei "kubectl get deploy -n \${NAMESPACE}"
pei "# Prefill pods are running"
pei "kubectl get pods -n \${NAMESPACE} -l llm-d.ai/role=prefill --field-selector status.phase=Running"
pei "# Decode pods are running"
pei "kubectl get pods -n \${NAMESPACE} -l llm-d.ai/role=decode --field-selector status.phase=Running"

pei "# Disaggregated inference service is ready!"
pei "# Send a request through the gateway to verify end-to-end functionality"
pei "export GATEWAY_NAME=\$(kubectl get gateway -n \${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')"
pei "export IP=\$(kubectl get gateway \${GATEWAY_NAME} -n \${NAMESPACE} -o jsonpath='{.status.addresses[0].value}')"
pei "export PORT=\$(kubectl get gateway \${GATEWAY_NAME} -n \${NAMESPACE} -o jsonpath='{.spec.listeners[0].port}')"
TYPE_SPEED=$FASTER_TYPE_SPEED
CMD=$(cat <<EOF
curl http://\${IP}:\${PORT}/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BCCard/Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic",
    "prompt": "What is KubeCon?",
    "max_tokens": 50
  }' | jq -r '.choices[0].text'
EOF
)
pe "$CMD"
TYPE_SPEED=$ORIGINAL_TYPE_SPEED
wait
