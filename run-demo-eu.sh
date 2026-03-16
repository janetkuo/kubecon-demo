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

# This demo uses a llm-d P/D workload on a GKE cluster with TPUs to demonstrate AI Conformance
export NAMESPACE=llm-d-pd

###############################################################################
# Gateway API (MUST requirement)
###############################################################################

pei "# Welcome to the AI Conformance Demo! We are running on an AI-conformant cluster."
pei "# ✅ AI-conformant platforms MUST support Kubernetes Gateway API for advanced traffic management"
pei "# Verify GatewayClasses. The 'CONTROLLER' column shows the underlying implementations backing these routing templates:"
pei "kubectl get gatewayclass -o custom-columns=NAME:.metadata.name,CONTROLLER:.spec.controllerName"
pei "# Verify that the inference Gateway is successfully instantiated using the L7 controller:"
pei "kubectl get gateway -n \${NAMESPACE} -o custom-columns=NAME:.metadata.name,CLASS:.spec.gatewayClassName"
wait

# To ensure the audience can focus on the following steps, we clear the screen
clear
###############################################################################
# Gateway API Inference Extension (SHOULD requirement)
###############################################################################

pei "# ✅ AI-conformant platforms SHOULD support Gateway API Inference Extension (GAIE) for advanced inference routing"
pei "# GAIE extends Gateway API to enable model-aware routing"
pei "# InferencePool defines the set of model-serving pods behind the Gateway"
pei "kubectl get inferencepools -n \${NAMESPACE}"
pei "# The inference scheduler (endpoint picker) makes cache-aware routing decisions"
pei "kubectl get pods -n \${NAMESPACE} -l inferencepool"
pei "# The HTTPRoute routes traffic to an InferencePool, not a Service, that's GAIE!"
pei "kubectl get httproute -n \${NAMESPACE} -o custom-columns=NAME:.metadata.name,BACKEND:.spec.rules[0].backendRefs[0].name,KIND:.spec.rules[0].backendRefs[0].kind"
pei "# Verify the route is properly attached to the Gateway"
pei "kubectl get gateway -n \${NAMESPACE} -o custom-columns=NAME:.metadata.name,ATTACHED-ROUTES:.status.listeners[0].attachedRoutes"
wait

# To ensure the audience can focus on the following steps, we clear the screen
clear
###############################################################################
# Disaggregated Inference on TPU (SHOULD requirement)
###############################################################################

pei "# ✅ AI-conformant platforms SHOULD support disaggregated inference"
pei "# To scale efficiently, disaggregated serving splits prefill and decode into separately scalable components, each can match different compute, memory, and network needs"
pei "# Prefill pods handle prompt processing (compute-heavy)"
pei "kubectl get pods -n \${NAMESPACE} -l llm-d.ai/role=prefill -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName"
pei "# Decode pods handle token generation (memory-bandwidth-heavy)"
pei "kubectl get pods -n \${NAMESPACE} -l llm-d.ai/role=decode -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName"
wait

# To ensure the audience can focus on the following steps, we clear the screen
clear
###############################################################################
# End-to-end request through the full stack
###############################################################################

pei "# All layers are in place. Let's send a live inference request."
pei "# Request → Gateway → GAIE (cache-aware routing) → Prefill → Decode → Response"
export GATEWAY_NAME=$(kubectl get gateway -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
export GATEWAY_IP=$(kubectl get gateway ${GATEWAY_NAME} -n ${NAMESPACE} -o jsonpath='{.status.addresses[0].value}')
export GATEWAY_PORT=$(kubectl get gateway ${GATEWAY_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.listeners[0].port}')
TYPE_SPEED=$FASTER_TYPE_SPEED
CMD=$(cat <<EOF
curl http://${GATEWAY_IP}:${GATEWAY_PORT}/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BCCard/Qwen3-Coder-480B-A35B-Instruct-FP8-Dynamic",
    "prompt": "Explain in two sentences how Kubernetes helps run AI workloads at scale.",
    "max_tokens": 100
  }' | jq -r '.choices[0].text'
EOF
)
pe "$CMD"
TYPE_SPEED=$ORIGINAL_TYPE_SPEED
wait

pei "# Kubernetes is the best platform for running AI workloads. 🎉"
wait