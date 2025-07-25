#!/bin/bash

USER=user1

HTPASSWD=$(oc get oauth/cluster -o jsonpath='{.spec.identityProviders[0].htpasswd.fileData.name}')
HTPASSWD_ADMIN=$(oc get secret/${HTPASSWD} -n openshift-config -o jsonpath='{.data.htpasswd}' | base64 -d | grep admin)
htpasswd -c -B -b /tmp/htpasswd ${USER} openshift
echo "${HTPASSWD_ADMIN}" >> /tmp/htpasswd

oc create secret generic htpass-secret --from-file=htpasswd=/tmp/htpasswd -n openshift-config
oc get oauth/cluster -o yaml | grep -B50 spec: | grep -v spec: > /tmp/oauth.yaml
cat <<EOF >> /tmp/oauth.yaml
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF
oc apply -f /tmp/oauth.yaml
rm -f /tmp/oauth.yaml /tmp/htpasswd

oc new-project minio
oc project minio
oc apply -f ./minio.yaml

while true; do oc get statefulset/minio -n minio 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "statefulset/minio does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.availableReplicas}'=1 --timeout 15m statefulset/minio -n minio

oc new-project ${USER}
oc project ${USER}

oc apply -f secret_aws-connection-minio.yaml -n ${USER}
while true; do oc get secret/aws-connection-minio -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "secret/aws-connection-minio does not exist yet. waiting..."; sleep 3; continue; else break; fi; done

oc apply -f job_setup_objectstorage.yaml -n ${USER}
while true; do oc get job/setup-objectstorage -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "job/setup-objectstorage does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.ready}'=1 --timeout 20m job/setup-objectstorage -n ${USER}
oc wait --for=jsonpath='{.status.active}'=1 --timeout 20m job/setup-objectstorage -n ${USER}
oc logs -f job/setup-objectstorage -n ${USER}
oc wait --for=jsonpath='{.status.succeeded}'=1 --timeout 20m job/setup-objectstorage -n ${USER}

oc label namespace/${USER} modelmesh-enabled=false
oc label namespace/${USER} opendatahub.io/dashboard=true

oc apply -f servingruntime_vllm.yaml -n ${USER}
#oc apply -f servingruntime_phi-4-quantized-w8a8-vllm.yaml -n ${USER}
oc apply -f inferenceservice_phi-4-quantized-w8a8.yaml -n ${USER}

#oc apply -f servingruntime_tanuki-8b-dpo-v1-0-vllm.yaml -n ${USER}
oc apply -f inferenceservice_tanuki-8b-dpo-v1-0.yaml -n ${USER}
#oc apply -f servingruntime_llama-3-elyza-jp-8b-vllm.yaml -n ${USER}
oc apply -f inferenceservice_llama-3-elyza-jp-8b.yaml -n ${USER}
#oc apply -f servingruntime_granite-3-0-8b-instruct-vllm.yaml -n ${USER}
oc apply -f inferenceservice_granite-3-0-8b-instruct.yaml -n ${USER}

oc apply -f servingruntime_multilingual-e5-large-hf-tei.yaml -n ${USER}
oc apply -f inferenceservice_multilingual-e5-large.yaml -n ${USER}
oc apply -f servingruntime_faster-whisper-large-v3-faster-whisper.yaml -n ${USER}
oc apply -f inferenceservice_faster-whisper-large-v3.yaml -n ${USER}
oc apply -f servingruntime_stablediffusion.yaml -n ${USER}
oc apply -f inferenceservice_stablediffusion.yaml -n ${USER}

while true; do oc get inferenceservices/phi-4-quantized-w8a8 -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/phi-4-quantized-w8a8 does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 60m inferenceservices/phi-4-quantized-w8a8 -n ${USER}

while true; do oc get inferenceservices/tanuki-8b-dpo-v1-0 -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/tanuki-8b-dpo-v1-0 does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 30m inferenceservices/tanuki-8b-dpo-v1-0 -n ${USER}

while true; do oc get inferenceservices/llama-3-elyza-jp-8b -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/llama-3-elyza-jp-8b does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 30m inferenceservices/llama-3-elyza-jp-8b -n ${USER}

while true; do oc get inferenceservices/granite-3-0-8b-instruct -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/granite-3-0-8b-instruct does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 30m inferenceservices/granite-3-0-8b-instruct -n ${USER}

while true; do oc get inferenceservices/multilingual-e5-large -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/multilingual-e5-large does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 30m inferenceservices/multilingual-e5-large -n ${USER}

while true; do oc get inferenceservices/faster-whisper-large-v3 -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/faster-whisper-large-v3 does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 30m inferenceservices/faster-whisper-large-v3 -n ${USER}

while true; do oc get inferenceservices/stablediffusion -n ${USER} 2>&1 | grep "not found" 1>/dev/null 2>&1; if [ $? -eq 0 ]; then echo "inferenceservices/stablediffusion does not exist yet. waiting..."; sleep 3; continue; else break; fi; done
oc wait --for=jsonpath='{.status.modelStatus.transitionStatus}'=UpToDate --timeout 30m inferenceservices/stablediffusion -n ${USER}

maxnum=$(oc get inferenceservice -n user1 | grep -v NAME | wc -l)
while true; do
  num=$(oc get pods -n user1 | grep predictor | grep -E "1/1 * *Running  *" | wc -l)
  if [ ${num} -eq ${maxnum} ]; then
    break
  fi
  echo "Waiting for all models being ready (${num}/${maxnum}) ..."
  sleep 5
done
echo "All models are now ready."
oc get pods -n user1 | grep predictor


