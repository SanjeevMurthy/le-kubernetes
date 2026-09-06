#!/bin/bash
# Q20 audit forensics: generate a synthetic audit log with exactly one deletion
# of the target Secret, plus enough noise that grepping blind does not work.
set -e
source "$(dirname "$0")/../../lib/env.sh"

DIR=$(course_dir 20)
LOG="$DIR/audit.log"
ANSWER="$CKS_STATE_DIR/q20.answer"

python3 - "$LOG" "$ANSWER" <<'PY'
import json, random, sys

log_path, answer_path = sys.argv[1], sys.argv[2]
random.seed(20260907)

users = ["alice", "bob", "mallory", "system:serviceaccount:kube-system:default"]
ips = {"alice": "10.44.0.3", "bob": "10.44.0.5",
       "mallory": "10.44.0.7", "system:serviceaccount:kube-system:default": "10.44.0.1"}
resources = ["pods", "configmaps", "deployments", "services", "secrets"]
namespaces = ["default", "finance", "kube-system", "web"]
verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]

TARGET_SECRET, TARGET_NS = "db-creds", "finance"
CULPRIT, CULPRIT_IP = "mallory", "10.44.0.7"
DELETE_TS = "2026-11-14T02:41:07.884213Z"
GETS = 7

def event(user, verb, resource, ns, name, ts, ip=None, level="Metadata"):
    return {
        "kind": "Event", "apiVersion": "audit.k8s.io/v1", "level": level,
        "auditID": "%032x" % random.getrandbits(128),
        "stage": "ResponseComplete",
        "requestURI": "/api/v1/namespaces/%s/%s/%s" % (ns, resource, name),
        "verb": verb,
        "user": {"username": user, "groups": ["system:authenticated"]},
        "sourceIPs": [ip or ips[user]],
        "objectRef": {"resource": resource, "namespace": ns, "name": name},
        "responseStatus": {"code": 200},
        "requestReceivedTimestamp": ts,
    }

events = []
# noise
for i in range(232):
    u = random.choice(users)
    r = random.choice(resources)
    events.append(event(
        u, random.choice(verbs[:6]), r, random.choice(namespaces),
        "%s-%d" % (r[:-1], random.randint(1, 40)),
        "2026-11-14T0%d:%02d:%02dZ" % (random.randint(0, 5), random.randint(0, 59), random.randint(0, 59))))

# exactly GETS reads of the target secret, spread across users
for i in range(GETS):
    events.append(event(
        random.choice(users), "get", "secrets", TARGET_NS, TARGET_SECRET,
        "2026-11-14T0%d:%02d:%02dZ" % (random.randint(0, 2), random.randint(0, 59), random.randint(0, 59)),
        level="RequestResponse"))

# exactly one delete of the target secret
events.append(event(CULPRIT, "delete", "secrets", TARGET_NS, TARGET_SECRET,
                    DELETE_TS, ip=CULPRIT_IP, level="RequestResponse"))

# deletes of OTHER secrets, so "grep delete | grep secrets" is not enough
for name in ("api-token", "tls-cert"):
    events.append(event("alice", "delete", "secrets", "web", name,
                        "2026-11-14T03:1%d:00Z" % random.randint(0, 9), level="RequestResponse"))

random.shuffle(events)
with open(log_path, "w", encoding="utf-8") as fh:
    for e in events:
        # kube-apiserver writes compact JSON, one event per line, with no spaces
        # after the separators. Match that exactly so the log greps like a real one.
        fh.write(json.dumps(e, separators=(",", ":")) + "\n")

with open(answer_path, "w", encoding="utf-8") as fh:
    fh.write("user=%s\nip=%s\ntime=%s\ngets=%d\n" % (CULPRIT, CULPRIT_IP, DELETE_TS, GETS))
print("%d events" % len(events))
PY

echo "Setup complete."
echo "  Audit log:   $LOG ($(wc -l < "$LOG" | tr -d ' ') JSON events, one per line)"
echo "  Deliverable: $DIR/answer.txt"
echo "  There is no jq on this host, exactly as in the exam. Use grep, cut, awk or yq -p json."
