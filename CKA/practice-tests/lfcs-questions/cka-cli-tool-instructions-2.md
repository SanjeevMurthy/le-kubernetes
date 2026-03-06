Goal is to verify, refine and fix the CKA CLI tool /Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/tests/lfcs-questions/cka-cli-tool

Follow the below steps:

Step1:
For all Questions, to build the scenario to solve the question, it is already assumed that we are running this CLI tool in a kubernetes playground with latest version of kubernetes installed and cluster is running fine without issues.
Step2
So in a correctly running k8s cluster, to create the scenario, need to create some resource, or stop some exisitng resource or need to modify the existing resource or config to re create teh scnearion, which a user will solve. Check the CLI is handling all this cases. Once scenario is setup, cluster should look like how it is explained in the question, so that user will try to troublehsoot and fix the issue.

Step3
Once user solves the scenario, the CLI should verify the solution and if correct, it should stop the timer and mention the minutes spent to solve the question. If not correct, it should ask the user to try again. Check if this functionality is working fine.

Step4
Fix the CKA CLI tool if needed and make it robust and user friendly.
