Goal is to buidl a CLI tool that can be used to run the CKA exam questions on kubernetes playground

Follow the below steps:

Step1
This folder `/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/tests/lfcs-questions/cka-prep-2025-v2` already has a `scripts` folder which has a script to create the scenario mentioned in the selected question passed as an argument to the script.

Step2
Consider this file `/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/tests/lfcs-questions/cka-retake-questions-final.md` as the source of truth for the questions and solutions and update the questions and solutions in `cka-prep-2025-v2` folder as needed.

Step3
Analyse this folder `/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/tests/lfcs-questions/cka-prep-2025-v2` for existing script and questions folder to understand the structure and how to use the scripts.

Step4
Design a CLI tool that can be used to run the CKA exam questions on kubernetes playground
So the CLI tool should be able to do the following:

1. List all the questions
2. Select a question
3. Run the script to create the scenario
4. Run the script to verify the solution
5. Run the script to clean up the scenario

Note:
Since i dont like the way, the current script is ran for every question passed as an argument, i want to change the way the scripts are run. Built a CLI tool that can be used to run the CKA exam questions on kubernetes playground with the steps mentioned in the Step4.

Basically when i run this script, i should be able to select the question, then create that scenario in kubernetres playground, then solve the scenrio, verify the solution and finally clean up the scenario.

create a new folder under `/Users/sanjeevmurthy/le/repos/le-kubernetes/CKA/tests/lfcs-questions/` called `cka-cli-tool` and build the CLI tool in that folder.

Use your creative way to build this CLI tool.
Ask me any questions you have to build this CLI tool.

Later prompts issued:
One change: When a question scenario is selected start a timer and upon verification of the solution, stop the timer and mention the minutes spent to solve the question.

I was testing the CLI tool, for Question 7, it was suppose to create the scenario with one pending pod with lack fo resources, but i can see all the pods are in running state in the cluster.Need to fix the cli tool

Verify for all questions if all the scenarios will be setup properly when running this CLI ? If needed fix it and also check the interactive terminal messges there are some duplication in printing task complete message
