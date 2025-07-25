#!/bin/sh

### install operators

# oc apply -f operator_openshift_data_foundation.yaml 
oc apply -f operator_openshift_serverless.yaml
oc apply -f operator_openshift_service_mesh.yaml
#oc apply -f operator_openshift_pipelines.yaml

# for display in "OpenShift Data Foundation" "OpenShift Container Storage" "CSI Addons" "NooBaa Operator" "Red Hat OpenShift Serverless" "Red Hat OpenShift Service Mesh" "Red Hat OpenShift Pipelines"; do
for display in "Red Hat OpenShift Serverless" "Red Hat OpenShift Service Mesh"; do
  while true; do oc get csv -A | grep "${display}" 1>/dev/null 2>&1; if [ $? -ne 0 ]; then echo "${display} does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
  namespace=$(oc get csv -A | grep "${display}" 2>/dev/null | head -n 1 | awk '{print $1}')
  csv=$(oc get csv -A | grep "${display}" 2>/dev/null | head -n 1 | awk '{print $2}')
  oc wait --for=jsonpath='{.status.phase}'=Succeeded --timeout 10m csv/${csv} -n ${namespace}
done

oc apply -f operator_openshift_ai.yaml

for display in "Red Hat OpenShift AI"; do
  while true; do oc get csv -A | grep "${display}" 1>/dev/null 2>&1; if [ $? -ne 0 ]; then echo "${display} does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
  namespace=$(oc get csv -A | grep "${display}" 2>/dev/null | head -n 1 | awk '{print $1}')
  csv=$(oc get csv -A | grep "${display}" 2>/dev/null | head -n 1 | awk '{print $2}')
  oc wait --for=jsonpath='{.status.phase}'=Succeeded --timeout 10m csv/${csv} -n ${namespace}
done

while true; do oc get project/istio-system 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "project/istio-system does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.phase}'=Active project/istio-system

oc apply -f operator_openshift_nfd.yaml
oc apply -f operator_nvidia_gpu_operator.yaml

for display in "Node Feature Discovery Operator" "NVIDIA GPU Operator"; do
  while true; do oc get csv -A | grep "${display}" 1>/dev/null 2>&1; if [ $? -ne 0 ]; then echo "${display} does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
  namespace=$(oc get csv -A | grep "${display}" 2>/dev/null | head -n 1 | awk '{print $1}')
  csv=$(oc get csv -A | grep "${display}" 2>/dev/null | head -n 1 | awk '{print $2}')
  oc wait --for=jsonpath='{.status.phase}'=Succeeded --timeout 10m csv/${csv} -n ${namespace}
done

