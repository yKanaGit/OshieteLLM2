#!/bin/sh

### create a secret for kserve

ingress_cert=$(oc get secret -n openshift-ingress | grep ingress-cert | awk '{print $1}')
if [ "${ingress_cert}" == "" ]; then
  ingress_cert=$(oc get secret -n openshift-ingress | grep router-certs | awk '{print $1}')
fi
oc get secret/${ingress_cert} -n openshift-ingress -o yaml > /tmp/rhods-internal-primary-cert-bundle-secret.yaml_
cat /tmp/rhods-internal-primary-cert-bundle-secret.yaml_ | sed -e "/^  *creationTimestamp:.*$/d" | sed -e "/^  *labels:.*$/d" | sed -e "/^  *certificate-type:.*$/d" | sed -e "/^  *resourceVersion:.*$/d" | sed -e "/^  *uid:.*$/d" | sed -e "s/namespace:.*/namespace: istio-system/g" | sed -e "s/type:.*/type: kubernetes.io\/tls/g" | sed -e "s/name:.*/name: rhods-internal-primary-cert-bundle-secret/g" > /tmp/rhods-internal-primary-cert-bundle-secret.yaml

oc apply -f /tmp/rhods-internal-primary-cert-bundle-secret.yaml -n istio-system
rm -f /tmp/rhods-internal-primary-cert-bundle-secret.yaml_ /tmp/rhods-internal-primary-cert-bundle-secret.yaml

while true; do oc get secret/rhods-internal-primary-cert-bundle-secret -n istio-system 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "secret/rhods-internal-primary-cert-bundle-secret does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.kind}'=Secret secret/rhods-internal-primary-cert-bundle-secret --timeout 10m -n istio-system

### create a data science cluster

oc apply -f data_science_cluster.yaml

while true; do oc get dsc/default-dsc 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "dsc/default-dsc does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.phase}'=Ready --timeout 60m dsc/default-dsc

