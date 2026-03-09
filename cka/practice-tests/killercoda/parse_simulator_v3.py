import re
import os

def parse_simulator_content(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find question headers: Question \d+ \| .*
    question_pattern = re.compile(r'(Question \d+ \| .*)')
    
    parts = question_pattern.split(content)
    
    questions = []
    
    for i in range(1, len(parts), 2):
        header = parts[i].strip()
        body = parts[i+1] if i + 1 < len(parts) else ""
        
        if "CKA Tips Kubernetes" in body:
            body = body.split("CKA Tips Kubernetes")[0]
        
        match = re.search(r'Question (\d+) \| (.*)', header)
        if match:
            q_num = int(match.group(1))
            q_title = match.group(2).strip()
        else:
            continue

        answer_split = body.split('Answer:', 1)
        
        question_text = answer_split[0].strip()
        answer_text = answer_split[1].strip() if len(answer_split) > 1 else ""
        
        question_text = clean_text(question_text)
        
        steps = process_answer(answer_text)
        
        questions.append({
            'number': q_num,
            'title': q_title,
            'question': question_text,
            'steps': steps
        })

    questions.sort(key=lambda x: x['number'])

    generate_markdown(questions, output_file)

def clean_text(text):
    text = text.replace('---PAGE BREAK---', '')
    lines = text.split('\n')
    cleaned_lines = [line.rstrip() for line in lines]
    return "\n".join(cleaned_lines).strip()

def process_answer(text):
    lines = text.split('\n')
    steps = []
    
    current_step = {"events": []}
    
    # Simple state machine
    # events: {'type': 'text|code|yaml|tip', 'content': string}
    
    in_yaml = False
    yaml_lines = []
    
    def flush_yaml():
        nonlocal in_yaml, yaml_lines
        if in_yaml and yaml_lines:
            current_step["events"].append({'type': 'yaml', 'content': "\n".join(yaml_lines)})
        in_yaml = False
        yaml_lines = []

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Check for Step markers
        if re.match(r'^Step \d+', line, re.IGNORECASE):
            flush_yaml()
            if current_step["events"]:
                steps.append(current_step)
            current_step = {"events": []}
            current_step["events"].append({'type': 'text', 'content': f"**{line}**"})
            continue

        # Check for Command Prompts
        command_match = re.match(r'^➜\s+(?:[\w@:~\-\.]+\s+)?(.*)', line)
        if command_match:
            flush_yaml()
            cmd = command_match.group(1).strip()
            if cmd:
                 current_step["events"].append({'type': 'code', 'content': cmd})
            continue

        # Check for File Content headers (treat as code comment or text)
        if line.startswith("# ") and "/" in line:
            flush_yaml()
            current_step["events"].append({'type': 'code', 'content': line}) # Treat as code
            continue
            
        # Check for Tips
        if line.startswith("ℹ") or "Tip:" in line:
            flush_yaml()
            current_step["events"].append({'type': 'tip', 'content': line.replace("ℹ", "").strip()})
            continue
            
        # Check for YAML Start
        if line.startswith("apiVersion:") or line.startswith("kind:"):
             if not in_yaml:
                 flush_yaml() # Flush anything previous
                 in_yaml = True
        
        if in_yaml:
            # Heuristic to end YAML: line doesn't look like YAML (no colon, no indent, valid sentence)
            # But YAML can be just values.
            # Stop if we hit a Step or Command (already handled above)
            # Stop if we hit a clear sentence?
            
            # If line is valid YAML (has colon, or list dash, or is just a brace)
            if ":" in line or line.startswith("-") or line.endswith(":") or line == "{}" or line.startswith("metadata"):
                yaml_lines.append(line)
                continue
            else:
                # If it looks like a sentence, break YAML
                if len(line.split()) > 3 and line[0].isupper() and (line.endswith(".") or line.endswith(":")):
                    flush_yaml()
                    # Fall through to text processing
                else:
                    # Maybe it's just a value line in YAML? Keep it mostly.
                    # Unless it's garbage.
                    yaml_lines.append(line)
                    continue

        # Text Filtering (Aggressive)
        
        # 1. Output Table Headers
        if re.match(r'^(NAME\s|READY\s|STATUS\s|RESTARTS\s|AGE|IP\s|NODE|CLUSTER-IP|EXTERNAL-IP|PORT\(S\)|NAMESPACE|CAPACITY|ACCESS MODES|STORAGECLASS|VOLUME|CLAIM|ADDRESS|DATA|EVENTS|TYPE|VERSION)', line):
            continue
        
        # 2. Output key-value pairs (e.g. from describe)
        # e.g. "Name: my-pod", "Namespace: default"
        if re.match(r'^(Name|Namespace|Labels|Annotations|Status|Node|Start Time|IP|IPs|Controlled By|Containers|Conditions|Volumes|QoS Class|Node-Selectors|Tolerations|Events):', line):
            continue
            
        # 3. Garbage/Base64/Hashes
        if len(line) > 50 and re.match(r'^[A-Za-z0-9+/=]+$', line.replace(' ', '')):
            continue
        if re.match(r'^[a-f0-9]{10,}$', line): # Long hex string
            continue
            
        # 4. Table rows
        if re.match(r'^[\w\-\.]+\s+[\w\-\.\/]+\s+\w+', line):
             if not line.endswith('.') and len(line.split()) > 3:
                continue

        # 5. "..."
        if "..." in line and len(line) < 20: 
             continue

        # 6. Table rows (3+ spaces)
        if re.search(r'\s{3,}', line):
            continue

        # 7. Keep Instructions
        # Must start with letter, be reasonably long, or end with punctuation
        if re.match(r'^[A-Za-z]', line):
             # Assume it's an explanation if it survived above filters
             current_step["events"].append({'type': 'text', 'content': line})

    flush_yaml()
    if current_step["events"]:
        steps.append(current_step)
        
    return steps

def get_documentation_links(title, strings_to_search):
    links = []
    # Key: Keyword, Value: URL
    keywords = {
        'PV': 'https://kubernetes.io/docs/concepts/storage/persistent-volumes/',
        'PVC': 'https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims',
        'StorageClass': 'https://kubernetes.io/docs/concepts/storage/storage-classes/',
        'Sidecar': 'https://kubernetes.io/docs/concepts/workloads/pods/#sidecar-containers',
        'Kubelet': 'https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/',
        'Etcd': 'https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/',
        'Backup': 'https://kubernetes.io/docs/tasks/administer-cluster/backup-etcd/',
        'Restore': 'https://kubernetes.io/docs/tasks/administer-cluster/restore-etcd/',
        'NetworkPolicy': 'https://kubernetes.io/docs/concepts/services-networking/network-policies/',
        'Service': 'https://kubernetes.io/docs/concepts/services-networking/service/',
        'Ingress': 'https://kubernetes.io/docs/concepts/services-networking/ingress/',
        'Deployment': 'https://kubernetes.io/docs/concepts/workloads/controllers/deployment/',
        'DaemonSet': 'https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/',
        'StatefulSet': 'https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/',
        'ServiceAccount': 'https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/',
        'ClusterRole': 'https://kubernetes.io/docs/reference/access-authn-authz/rbac/',
        'RoleBinding': 'https://kubernetes.io/docs/reference/access-authn-authz/rbac/',
        'Secret': 'https://kubernetes.io/docs/concepts/configuration/secret/',
        'ConfigMap': 'https://kubernetes.io/docs/concepts/configuration/configmap/',
        'Upgrade': 'https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/',
        'Drain': 'https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/',
        'Taint': 'https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/',
        'Toleration': 'https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/',
        'Multi-Container': 'https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/',
        'InitContainer': 'https://kubernetes.io/docs/concepts/workloads/pods/init-containers/',
        'Logging': 'https://kubernetes.io/docs/concepts/cluster-administration/logging/',
        'Monitoring': 'https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/',
        'Troubleshooting': 'https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/',
        'DNS': 'https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/',
        'CoreDNS': 'https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/',
        'CNI': 'https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/',
        'Kubeconfig': 'https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/',
        'Context': 'https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/',
        'User': 'https://kubernetes.io/docs/reference/access-authn-authz/authentication/',
        'Certificate': 'https://kubernetes.io/docs/tasks/administer-cluster/certificates/',
        'CSR': 'https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/',
        'JSONPath': 'https://kubernetes.io/docs/reference/kubectl/jsonpath/',
    }
    
    links_found = {}
    combined_text = (title + " " + " ".join(strings_to_search)).lower()
    
    for key, url in keywords.items():
        if key.lower() in combined_text:
            links_found[key] = url
            
    return links_found

def generate_markdown(questions, output_file):
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# CKA Simulator 1 - Questions and Solutions\n\n")
        f.write("> [!NOTE]\n> This document contains questions and answers from the CKA Simulator. Always verify with official documentation.\n\n")
        
        f.write("## Table of Contents\n\n")
        for q in questions:
            link = f"question-{q['number']}-{q['title'].lower().replace(' ', '-').replace(',', '').replace('/', '')}"
            f.write(f"- [Question {q['number']}: {q['title']}](#{link})\n")
        f.write("\n---\n\n")
        
        for q in questions:
            f.write(f"## Question {q['number']}: {q['title']}\n\n")
            
            # Problem
            lines = q['question'].split('\n')
            formatted_question = []
            for line in lines:
                if "Solve this question on:" in line:
                    clean_line = line.strip().replace('>', '').strip()
                    f.write(f"> [!IMPORTANT]\n> **{clean_line}**\n\n")
                else:
                    formatted_question.append(line)
            
            f.write("### Context\n\n")
            f.write("\n".join(formatted_question))
            f.write("\n\n")
            
            # Solution
            f.write("### Solution\n\n")
            
            for step in q['steps']:
                # Group adjacent code events
                buffered_code = []
                
                # Helper to flush buffered code
                def flush_code(file_handle, codes):
                    if codes:
                        file_handle.write("```bash\n")
                        for c in codes:
                            file_handle.write(f"{c}\n")
                        file_handle.write("```\n\n")
                
                for event in step['events']:
                    if event['type'] == 'code':
                        buffered_code.append(event['content'])
                    else:
                        flush_code(f, buffered_code)
                        buffered_code = []
                        
                        if event['type'] == 'text':
                            f.write(f"{event['content']}\n\n")
                        elif event['type'] == 'tip':
                            f.write(f"> [!TIP]\n> {event['content']}\n\n")
                        elif event['type'] == 'yaml':
                            f.write("```yaml\n")
                            f.write(f"{event['content']}\n")
                            f.write("```\n\n")
                            
                flush_code(f, buffered_code)

            # References
            all_text_list = []
            for s in q['steps']:
                 for e in s['events']:
                     all_text_list.append(e['content'])
            
            links = get_documentation_links(q['title'], all_text_list)
            if links:
                f.write("### References\n\n")
                for key, url in links.items():
                    f.write(f"- [{key}]({url})\n")
                f.write("\n")
                
            f.write("---\n\n")

    print(f"Generated markdown file at {output_file}")

if __name__ == "__main__":
    input_file = 'simulator_content.txt'
    output_file = 'Simulator_1.md'
    if os.path.exists(input_file):
        parse_simulator_content(input_file, output_file)
    else:
        print(f"Input file {input_file} not found.")
