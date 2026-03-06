import re
import os

def parse_simulator_content(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find question headers: Question \d+ \| .*
    question_pattern = re.compile(r'(Question \d+ \| .*)')
    
    parts = question_pattern.split(content)
    
    questions = []
    
    # Skip the introduction text (parts[0])
    for i in range(1, len(parts), 2):
        header = parts[i].strip()
        body = parts[i+1] if i + 1 < len(parts) else ""
        
        # Stop if we hit the "CKA Tips" or "Exam Info" section which might be attached to the last question
        if "CKA Tips Kubernetes" in body:
            body = body.split("CKA Tips Kubernetes")[0]
        
        # Extract Question Number and Title
        match = re.search(r'Question (\d+) \| (.*)', header)
        if match:
            q_num = int(match.group(1))
            q_title = match.group(2).strip()
        else:
            continue

        # Separate Question and Answer
        answer_split = body.split('Answer:', 1)
        
        question_text = answer_split[0].strip()
        answer_text = answer_split[1].strip() if len(answer_split) > 1 else ""
        
        # Clean up text
        question_text = clean_text(question_text)
        
        # Process answer into structured steps
        steps = process_answer(answer_text)
        
        questions.append({
            'number': q_num,
            'title': q_title,
            'question': question_text,
            'steps': steps
        })

    # Sort questions by number
    questions.sort(key=lambda x: x['number'])

    generate_markdown(questions, output_file)

def clean_text(text):
    text = text.replace('---PAGE BREAK---', '')
    
    # Remove leading/trailing whitespace
    lines = text.split('\n')
    cleaned_lines = [line.rstrip() for line in lines]
    return "\n".join(cleaned_lines).strip()

def process_answer(text):
    lines = text.split('\n')
    cleaned_steps = []
    
    current_step = {"explanations": [], "commands": [], "tips": []}
    
    # State tracking
    is_code_block = False # Not really used since raw text
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Check for Step markers
        if re.match(r'^Step \d+$', line, re.IGNORECASE):
            # Save previous step if it has content
            if current_step["explanations"] or current_step["commands"]:
                cleaned_steps.append(current_step)
            current_step = {"explanations": [f"**{line}**"], "commands": [], "tips": []}
            continue

        # Check for Command Prompts
        # Matches: ➜  candidate@cka9412:~$ command...
        # Or: ➜  ssh cka9412
        # Or: ➜  root@cka2556-node1:~# command
        command_match = re.match(r'^➜\s+(?:[\w@:~\-\.]+\s+)?(.*)', line)
        if command_match:
            cmd = command_match.group(1).strip()
            
            # Filter out obvious output lines that might be misidentified (unlikely with this regex)
            # Filter out commands that are just empty prompts
            if cmd:
                 current_step["commands"].append(cmd)
            continue
        
        # Check for File Content headers or comments
        # # cka9412:/opt/course/1/contexts
        if line.startswith("# "):
            current_step["explanations"].append(f"`{line}`")
            continue

        # Heuristic for Output lines to Ignore
        # - Starts with specific headers: NAME, READY, STATUS, AGE, ID, NAMESPACE
        # - Long hashes or base64 (already truncated but maybe just remove?)
        # - "..."
        # - Lines starting with space inside output (indentation)
        
        if re.match(r'^(NAME|READY|STATUS|RESTARTS|AGE|IP|NODE|CLUSTER-IP|EXTERNAL-IP|PORT\(S\)|NAMESPACE|CAPACITY|ACCESS MODES|STORAGECLASS|VOLUME|CLAIM|ADDRESS|DATA|EVENTS|TYPE|VERSION)', line):
            continue
            
        if "..." in line and len(line) < 20: 
             continue
             
        # Ignore lines that look like table rows (columns)
        # e.g. "pod-1  1/1  Running  0  5m"
        # Regex: alphanumeric + spaces + alphanumeric + spaces...
        if re.match(r'^[\w\-\.]+\s+[\w\-\.\/]+\s+\w+', line):
            # Likely a table row, verify it doesn't look like a sentence
            if not line.endswith('.') and len(line.split()) > 3:
                continue

        # Identify Tips
        if line.startswith("ℹ") or "Tip:" in line:
            current_step["tips"].append(line.replace("ℹ", "").strip())
            continue

        # Treat remaining lines as explanation
        # But filter out lines that are just symbols or noise
        if re.match(r'^[A-Za-z0-9]', line):
             current_step["explanations"].append(line)

    # Save last step
    if current_step["explanations"] or current_step["commands"]:
        cleaned_steps.append(current_step)
        
    return cleaned_steps

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
    
    text_to_search = title.lower() + " " + " ".join(strings_to_search).lower()
    
    unique_links = {}
    for key, url in keywords.items():
        if key.lower() in text_to_search:
            unique_links[key] = url
            
    return unique_links

def generate_markdown(questions, output_file):
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# CKA Simulator 1 - Questions and Solutions\n\n")
        f.write("> [!NOTE]\n> This document contains questions and answers from the CKA Simulator. Always verify with official documentation.\n\n")
        
        # Table of Contents
        f.write("## Table of Contents\n\n")
        for q in questions:
            link = f"question-{q['number']}-{q['title'].lower().replace(' ', '-').replace(',', '').replace('/', '')}"
            f.write(f"- [Question {q['number']}: {q['title']}](#{link})\n")
        f.write("\n---\n\n")
        
        for q in questions:
            f.write(f"## Question {q['number']}: {q['title']}\n\n")
            
            # Problem Section
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
            
            # Solution Section
            f.write("### Solution\n\n")
            
            for step in q['steps']:
                # Explanations
                for exp in step['explanations']:
                    f.write(f"{exp}\n\n")
                
                # Commands
                if step['commands']:
                    f.write("```bash\n")
                    for cmd in step['commands']:
                        f.write(f"{cmd}\n")
                    f.write("```\n\n")
                
                # Tips
                for tip in step['tips']:
                    f.write(f"> [!TIP]\n> {tip}\n\n")

            # References
            all_text_list = []
            for s in q['steps']:
                 all_text_list.extend(s['explanations'])
                 all_text_list.extend(s['commands'])
            
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
