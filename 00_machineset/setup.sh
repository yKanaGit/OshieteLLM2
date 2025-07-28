#!/bin/bash

#NORMAL_WORKER_TYPE=m6a.2xlarge
#NORMAL_WORKER_COUNT=1
#GPU1_WORKER_TYPE=g6.xlarge
#GPU1_WORKER_COUNT=1
#GPU2_WORKER_TYPE=g6.xlarge
#GPU2_WORKER_COUNT=3
#GPU3_WORKER_TYPE=g6.xlarge
#GPU3_WORKER_COUNT=1
GPU1_WORKER_TYPE=g5.xlarge
GPU1_WORKER_COUNT=1
GPU2_WORKER_TYPE=g5.xlarge
GPU2_WORKER_COUNT=3
GPU3_WORKER_TYPE=g5.xlarge
GPU3_WORKER_COUNT=1

#echo "NORMAL_WORKER_TYPE = ${NORMAL_WORKER_TYPE}"
#echo "NORMAL_WORKER_COUNT = ${NORMAL_WORKER_COUNT}"
echo "GPU1_WORKER_TYPE = ${GPU1_WORKER_TYPE}"
echo "GPU1_WORKER_COUNT = ${GPU1_WORKER_COUNT}"
echo "GPU2_WORKER_TYPE = ${GPU2_WORKER_TYPE}"
echo "GPU2_WORKER_COUNT = ${GPU2_WORKER_COUNT}"
echo "GPU3_WORKER_TYPE = ${GPU3_WORKER_TYPE}"
echo "GPU3_WORKER_COUNT = ${GPU3_WORKER_COUNT}"

# scale-down default machineset
machineset=$(oc get machineset -n openshift-machine-api | grep -v NAME | head -n 1 | awk '{print $1}')
oc scale machineset/${machineset} -n openshift-machine-api --replicas=0
oc wait --for jsonpath='{.status.replicas}'=0 --timeout 20m machineset/${machineset} -n openshift-machine-api

# normal machineset
#oc get machineset/${machineset} -o yaml -n openshift-machine-api > /tmp/normal_machineset.yaml
#sed -i "s/${machineset}/${machineset}n/g" /tmp/normal_machineset.yaml
#sed -i "s/instanceType: .*/instanceType: ${NORMAL_WORKER_TYPE}/g" /tmp/normal_machineset.yaml
#sed -i "s/replicas: .*/replicas: ${NORMAL_WORKER_COUNT}/g" /tmp/normal_machineset.yaml

# gpu machineset
oc get machineset/${machineset} -o yaml -n openshift-machine-api > /tmp/gpu_machineset.yaml
sed -i "s/${machineset}/${machineset}g1/g" /tmp/gpu_machineset.yaml
sed -i "s/instanceType: .*/instanceType: ${GPU1_WORKER_TYPE}/g" /tmp/gpu_machineset.yaml
sed -i "s/replicas: .*/replicas: ${GPU1_WORKER_COUNT}/g" /tmp/gpu_machineset.yaml

# gpu machineset 2
oc get machineset/${machineset} -o yaml -n openshift-machine-api > /tmp/gpu2_machineset.yaml
sed -i "s/${machineset}/${machineset}g2/g" /tmp/gpu2_machineset.yaml
sed -i "s/instanceType: .*/instanceType: ${GPU2_WORKER_TYPE}/g" /tmp/gpu2_machineset.yaml
sed -i "s/replicas: .*/replicas: ${GPU2_WORKER_COUNT}/g" /tmp/gpu2_machineset.yaml

# gpu machineset 3
oc get machineset/${machineset} -o yaml -n openshift-machine-api > /tmp/gpu3_machineset.yaml
sed -i "s/${machineset}/${machineset}g3/g" /tmp/gpu3_machineset.yaml
sed -i "s/instanceType: .*/instanceType: ${GPU3_WORKER_TYPE}/g" /tmp/gpu3_machineset.yaml
sed -i "s/replicas: .*/replicas: ${GPU3_WORKER_COUNT}/g" /tmp/gpu3_machineset.yaml

# create machines and wait them for being ready
#oc apply -f /tmp/normal_machineset.yaml
#rm -f /tmp/normal_machineset.yaml
oc apply -f /tmp/gpu_machineset.yaml
rm -f /tmp/gpu_machineset.yaml
oc apply -f /tmp/gpu2_machineset.yaml
rm -f /tmp/gpu2_machineset.yaml
oc apply -f /tmp/gpu3_machineset.yaml
rm -f /tmp/gpu3_machineset.yaml

#while true; do oc get machineset/${machineset}n -n openshift-machine-api 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "machineset/${machineset}n does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
#oc wait --for jsonpath='{.status.availableReplicas}'=${NORMAL_WORKER_COUNT} --timeout 30m machineset/${machineset}n -n openshift-machine-api

while true; do oc get machineset/${machineset}g1 -n openshift-machine-api 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "machineset/${machineset}g1 does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for jsonpath='{.status.availableReplicas}'=${GPU1_WORKER_COUNT} --timeout 30m machineset/${machineset}g1 -n openshift-machine-api

while true; do oc get machineset/${machineset}g2 -n openshift-machine-api 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "machineset/${machineset}g2 does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for jsonpath='{.status.availableReplicas}'=${GPU2_WORKER_COUNT} --timeout 30m machineset/${machineset}g2 -n openshift-machine-api

while true; do oc get machineset/${machineset}g3 -n openshift-machine-api 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "machineset/${machineset}g3 does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for jsonpath='{.status.availableReplicas}'=${GPU3_WORKER_COUNT} --timeout 30m machineset/${machineset}g3 -n openshift-machine-api

oc get machine -n openshift-machine-api -o wide | grep ${machineset}g1 | awk '{print $7}' | while read node; do
  oc adm taint nodes ${node} gpu-workload-only="":PreferNoSchedule
  oc label nodes ${node} gpu-node-type=1
done

oc get machine -n openshift-machine-api -o wide | grep ${machineset}g2 | awk '{print $7}' | while read node; do
  oc adm taint nodes ${node} gpu-workload-only="":PreferNoSchedule
  oc label nodes ${node} gpu-node-type=2
done

oc get machine -n openshift-machine-api -o wide | grep ${machineset}g3 | awk '{print $7}' | while read node; do
  oc adm taint nodes ${node} gpu-workload-only="":PreferNoSchedule
  oc label nodes ${node} gpu-node-type=3
done
