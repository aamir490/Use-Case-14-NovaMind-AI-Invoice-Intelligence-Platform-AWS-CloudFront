# Your question

**How can I create all 25 empty `.md` learning files in this folder?**

- Yes. Since you're on Windows, the easiest way is **PowerShell**.
- Open PowerShell and paste this **single command**:

```powershell
$path="E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\learning"; @("01-Project-Overview.md","02-Current-Architecture.md","03-End-to-End-Application-Flow.md","04-Technology-Stack-and-Codebase.md","05-Cognito-Authentication-and-User-Isolation.md","06-Presigned-S3-Upload-and-Ingestion.md","07-SQS-DLQ-Retries-and-Idempotency.md","08-Step-Functions-Workflow-Orchestration.md","09-Amazon-Textract-and-OCR.md","10-Amazon-Bedrock-Nova-Micro-and-Prompting.md","11-AI-Output-Validation-and-Evaluation.md","12-Risk-Scoring-and-Financial-Rules.md","13-DynamoDB-Data-Model-and-Access-Patterns.md","14-S3-DynamoDB-and-Application-State.md","15-Frontend-React-State-Polling-and-Analytics.md","16-EventBridge-SNS-and-Notifications.md","17-AWS-CDK-and-Infrastructure-as-Code.md","18-Deployment-Lambda-Layers-and-CICD.md","19-Security-and-Data-Lifecycle.md","20-Reliability-Troubleshooting-and-Observability.md","21-Testing-and-AI-Quality.md","22-Cost-Scalability-and-Performance.md","23-Limitations-Production-V2-and-Design-Decisions.md","24-Complete-Project-Storytelling-and-Interview-QA.md","25-Mock-Interview-and-Final-Revision.md") | ForEach-Object { New-Item -Path (Join-Path $path $_) -ItemType File -Force }
```

### Check that all 25 were created

Run:

```powershell
Get-ChildItem "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\learning" -Filter "*.md"
```

To check the count:

```powershell
(Get-ChildItem "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\learning" -Filter "*.md").Count
```

It should return:

```text
25
```

Then we can start with **`01-Project-Overview.md` only**. We should fully understand that first before touching File 02.