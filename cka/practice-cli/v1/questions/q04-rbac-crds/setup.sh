#!/bin/bash
# Q4 — RBAC for Custom Resources (CRDs): Setup
set -e

echo "Creating CRDs for students and classes..."

cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: students.school.example.com
spec:
  group: school.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                name:
                  type: string
                grade:
                  type: string
  scope: Namespaced
  names:
    plural: students
    singular: student
    kind: Student
    shortNames:
      - stu
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: classes.school.example.com
spec:
  group: school.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                subject:
                  type: string
                teacher:
                  type: string
  scope: Namespaced
  names:
    plural: classes
    singular: class
    kind: Class
    shortNames:
      - cls
EOF

echo ""
echo "CRDs created: students.school.example.com, classes.school.example.com"
echo ""
echo "Your tasks:"
echo "  1. Discover the CRD details (apiGroup, plural names, scope)"
echo "  2. Create a Role named 'school-admin' that grants get,list,create,update,delete"
echo "     on both students and classes resources"
echo "  3. Create a RoleBinding named 'school-admin-binding' binding the role to user 'jane'"
echo "  4. Verify with: kubectl auth can-i create students --as=jane"
