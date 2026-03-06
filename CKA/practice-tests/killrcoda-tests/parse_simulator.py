import re
import os

def parse_simulator_content(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find question headers: Question \d+ \| .*
    question_pattern = re.compile(r'(Question \d+ \| .*)')
    
    parts = question_pattern.split(content)
    
    questions = []
    
    if len(parts) < 2:
        print("No questions found or unexpected format.")
        return

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
            q_num = int(match.group(1)) # Convert to int for sorting
            q_title = match.group(2).strip()
        else:
            continue # Skip if header doesn't match

        # Separate Question and Answer
        answer_split = body.split('Answer:', 1)
        
        question_text = answer_split[0].strip()
        answer_text = answer_split[1].strip() if len(answer_split) > 1 else ""
        
        # Clean up text
        question_text = clean_text(question_text)
        answer_text = clean_text(answer_text)
        
        questions.append({
            'number': q_num,
            'title': q_title,
            'question': question_text,
            'answer': answer_text
        })

    # Sort questions by number
    questions.sort(key=lambda x: x['number'])

    generate_markdown(questions, output_file)

def clean_text(text):
    # Remove page breaks
    text = text.replace('---PAGE BREAK---', '')
    
    # Truncate long Base64 strings to make it readable
    # Looking for long strings of alphanumeric characters (e.g., certificates)
    # This is a simple heuristic: if a line is very long and looks like base64, truncate it.
    lines = text.split('\n')
    cleaned_lines = []
    for line in lines:
        if len(line) > 100 and not " " in line.strip() and re.match(r'^[A-Za-z0-9+/=]+$', line.strip()):
             cleaned_lines.append(line[:50] + "... (truncated for readability)")
        else:
             cleaned_lines.append(line)
             
    return "\n".join(cleaned_lines).strip()

def get_documentation_links(title, content):
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
        'Sitemap': 'https://kubernetes.io/docs/home/', 
    }
    
    text_to_search = (title + " " + content).lower()
    
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
            
            # Identify "Solve this question on: ..." line and format it
            lines = q['question'].split('\n')
            formatted_question = []
            for line in lines:
                if "Solve this question on:" in line:
                     # Remove any leading/trailing whitespace and formatting chars
                    clean_line = line.strip().replace('>', '').strip()
                    f.write(f"> [!IMPORTANT]\n> **{clean_line}**\n\n")
                else:
                    formatted_question.append(line)
            
            f.write("### Problem\n\n")
            f.write("\n".join(formatted_question))
            f.write("\n\n")
            
            f.write("### Solution\n\n")
            f.write("```bash\n" + q['answer'] + "\n```") if "➜" in q['answer'] else f.write(q['answer'])
            f.write("\n\n")
            
            links = get_documentation_links(q['title'], q['question'])
            if links:
                f.write("### References\n\n")
                for key, url in links.items():
                    f.write(f"- [{key}]({url})\n")
                f.write("\n")
                
            f.write("---\n\n")

    print(f"Generated markdown file at {output_file}")

if __name__ == "__main__":
    input_file = '/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/Killrcoda/simulator_content.txt'
    output_file = '/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/Killrcoda/Simulator_1.md'
    
    if os.path.exists(input_file):
        parse_simulator_content(input_file, output_file)
    else:
        print(f"Input file not found: {input_file}")
