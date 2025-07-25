#!/bin/bash

ls -d 0* | sort | while read dir; do
  echo "### Entering ${dir} ..."
  cd ${dir}
  echo "[${dir}/setup.sh]"
  ./setup.sh
  echo "### Leaving ${dir} ..."
  cd ..
done

echo "Deploying Open WebUI..."

oc apply -f open-webui.yaml

while true; do
  curl -s https://$(oc get route/open-webui -o jsonpath={'.spec.host'})/ | grep "Open WebUI" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 3
done

echo "Open WebUI is ready."
echo "https://$(oc get route/open-webui -n user1 -o jsonpath='{.spec.host}'/)"

