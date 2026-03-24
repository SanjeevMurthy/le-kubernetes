#!/bin/bash
# Q11 — ConfigMap Volume Mount: Verify
PASS=0; FAIL=0

echo "Checking ConfigMap web-config exists..."
if kubectl get configmap web-config &>/dev/null; then
  echo "  PASS: ConfigMap web-config exists"
  ((PASS++))
else
  echo "  FAIL: ConfigMap web-config not found"
  ((FAIL++))
fi

echo "Checking Pod web-pod exists..."
if kubectl get pod web-pod &>/dev/null; then
  echo "  PASS: Pod web-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod web-pod not found"
  ((FAIL++))
fi

echo "Checking Pod is Running..."
PHASE=$(kubectl get pod web-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$PHASE" == "Running" ]]; then
  echo "  PASS: Pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod phase is '$PHASE' (expected: Running)"
  ((FAIL++))
fi

echo "Checking pod has a volume from configmap web-config..."
HAS_CM_VOL=$(kubectl get pod web-pod -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
for v in spec['spec'].get('volumes', []):
    cm = v.get('configMap', {})
    if cm.get('name') == 'web-config':
        print('found')
        sys.exit(0)
print('missing')
" 2>/dev/null || echo "error")
if [[ "$HAS_CM_VOL" == "found" ]]; then
  echo "  PASS: Volume references configmap web-config"
  ((PASS++))
else
  echo "  FAIL: No volume referencing configmap web-config (expected: configMap volume)"
  ((FAIL++))
fi

echo "Checking mounted content includes expected HTML..."
# Find the mount path for the configmap volume
MOUNT_PATH=$(kubectl get pod web-pod -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
vol_name = None
for v in spec['spec'].get('volumes', []):
    if v.get('configMap', {}).get('name') == 'web-config':
        vol_name = v['name']
        break
if vol_name:
    for c in spec['spec']['containers']:
        for vm in c.get('volumeMounts', []):
            if vm.get('name') == vol_name:
                print(vm['mountPath'])
                sys.exit(0)
print('')
" 2>/dev/null || echo "")
if [[ -n "$MOUNT_PATH" ]]; then
  CONTENT=$(kubectl exec web-pod -- find "$MOUNT_PATH" -type f -exec cat {} \; 2>/dev/null || echo "")
  if echo "$CONTENT" | grep -q "Hello from ConfigMap"; then
    echo "  PASS: Mounted content contains 'Hello from ConfigMap'"
    ((PASS++))
  else
    echo "  FAIL: Mounted content is '$CONTENT' (expected: contains 'Hello from ConfigMap')"
    ((FAIL++))
  fi
else
  echo "  FAIL: Could not determine mount path (expected: volume mount for web-config)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
