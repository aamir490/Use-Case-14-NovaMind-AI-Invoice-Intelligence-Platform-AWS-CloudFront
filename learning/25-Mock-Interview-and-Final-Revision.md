# Your question

**Create `25-Mock-Interview-and-Final-Revision.md`. I want the interview questions AND proper word-by-word answers so I can first study the answers, understand them, and later practice answering without notes.**

# `25-Mock-Interview-and-Final-Revision.md`

> **Project:** NovaMind AI – Invoice Intelligence Platform  
> **Purpose:** Final project interview preparation  
> **Mode:** Study → Practice → Mock Interview → Pressure Questions → Revision

---

# 1. Purpose of This Final File

You have now studied the project from:

```text
01 Project Overview
        ↓
02 Architecture
        ↓
03 Application Flow
        ↓
04 Technology Stack
        ↓
05 Authentication
        ↓
06 S3 Upload
        ↓
07 SQS / DLQ / Idempotency
        ↓
08 Step Functions
        ↓
09 Textract
        ↓
10 Bedrock
        ↓
11 AI Validation
        ↓
12 Risk Scoring
        ↓
13 DynamoDB
        ↓
14 Application State
        ↓
15 Frontend
        ↓
16 EventBridge / SNS
        ↓
17 CDK
        ↓
18 Deployment / CI/CD
        ↓
19 Security
        ↓
20 Reliability / Observability
        ↓
21 Testing / AI Quality
        ↓
22 Cost / Scaling
        ↓
23 Limitations / Production V2
        ↓
24 Project Storytelling
        ↓
25 MOCK INTERVIEW
```

The repository analysis describes the implemented main path as login → presigned upload → S3 → SQS → trigger → OCR → AI → rules → persistence → API reads. It classifies the main processing/display path as implemented, while isolation, alerts, schema validation, lifecycle management, UI refresh, and deployment reliability remain partial. :chatgpt-content-reference{index="0"}

This file is therefore not about learning another AWS service.

It is about answering:

> **Can I explain and defend my project in an interview?**

---

# 2. How to Use This File

There are **three stages**.

### Stage 1 — Study Mode

Read the question.

Try to understand the answer.

Then read the word-by-word answer.

At this stage, using the answer is completely fine.

### Stage 2 — Practice Mode

Hide the answer.

Read only:

> **Question**

Speak your answer aloud.

Then compare your answer with the reference answer.

### Stage 3 — Real Mock Interview

Eventually:

```text
I ask ONE question
        ↓
You answer WITHOUT notes
        ↓
I evaluate
        ↓
Technical correctness
        ↓
Communication
        ↓
Missing concepts
        ↓
Better answer
        ↓
Pressure follow-up
```

That is where interview readiness develops.

---

# 3. Five Things You Must Never Overclaim

Before the mock interview, memorize these boundaries.

```text
❌ This is NOT RAG.

❌ This is NOT Agentic AI.

❌ The risk score is NOT a fraud probability.

❌ Repository CI/CD files do NOT prove a currently successful pipeline.

❌ This is NOT verified fully production-ready.
```

The verified project fact sheet specifically identifies no RAG, vector database, autonomous agents, or ML training, and describes live deployment, operational CI/CD, quotas, performance, and actual cost as unverified. :chatgpt-content-reference{index="1"}

---

# ROUND 1 — PROJECT INTRODUCTION

---

# Q1. Tell Me About Your Project

### Difficulty

**Basic — MUST MASTER**

### What interviewer is checking

Can you explain your own project without dumping technology names?

### Word-by-word answer

> “My project is NovaMind AI, a serverless and event-driven invoice intelligence application built on AWS.
>
> The purpose of the application is to take invoice documents, extract structured information from them, analyze possible inconsistencies, and provide review signals to the user.
>
> A user authenticates through Amazon Cognito and uploads an invoice from a React frontend using a presigned S3 URL. Once the document reaches S3, an event goes through SQS, and a Lambda starts an Express Step Functions workflow.
>
> Inside the workflow, Amazon Textract extracts invoice fields and OCR text, Amazon Bedrock Nova Micro analyzes the extracted content for possible anomalies, and deterministic Python rules calculate a heuristic risk score.
>
> The final results are stored in DynamoDB, extracted text is stored in S3, and the frontend displays the processing status and invoice analysis.
>
> I describe it as an invoice intelligence and review-support application rather than an autonomous fraud-detection system.”

That description matches the repository's implemented processing and display path. :chatgpt-content-reference{index="2"}

### Short version

> “NovaMind AI is a serverless invoice intelligence application on AWS. It uses Textract for invoice extraction, Bedrock Nova Micro for AI-assisted anomaly analysis, deterministic Python rules for risk scoring, and DynamoDB and S3 for persistence. The processing is asynchronous using SQS and Step Functions.”

---

# Q2. What Problem Does the Project Solve?

### Difficulty

**Basic**

### Word-by-word answer

> “The project addresses the problem of extracting and reviewing information from invoice documents. Instead of requiring a reviewer to manually locate every important field and inspect the invoice from scratch, the system extracts structured information and generates signals about possible inconsistencies.
>
> The goal is to help invoice reviewers decide which documents may require closer attention. I would not claim a specific percentage of time or cost savings because the repository does not contain measured business-impact data.”

The project analysis likewise describes the intended audience as invoice/finance reviewers and explicitly cautions against inventing measured savings. :chatgpt-content-reference{index="3"}

---

# Q3. Who Are the Intended Users?

### Word-by-word answer

> “The intended users are people responsible for reviewing invoices, such as finance teams, accounts-payable staff or invoice reviewers. However, that target audience is inferred from the application workflow. I would not claim that the repository proves real production customers are currently using the system.”

---

# ROUND 2 — ARCHITECTURE

# Q4. Explain Your Complete Architecture

### Difficulty

**MUST MASTER**

### Word-by-word answer

> “The architecture is serverless and event-driven.
>
> On the frontend, I use React, with the static application delivered using S3 and CloudFront. Cognito handles user authentication.
>
> Authenticated API requests go through API Gateway to Lambda functions.
>
> For invoice upload, the backend generates a short-lived presigned S3 URL. The browser then uploads the document directly to the private S3 bucket.
>
> S3 generates an ObjectCreated event that is sent to SQS. A trigger Lambda consumes the message and starts an Express Step Functions workflow.
>
> The workflow coordinates four main processing stages. Textract performs document extraction, Bedrock Nova Micro performs Generative AI analysis, deterministic Python rules calculate the review score, and the final stage persists the results.
>
> DynamoDB stores invoice and processing-job records, while S3 stores the original documents and extracted text.
>
> Finally, the React frontend calls authenticated APIs to poll processing status and retrieve the result.”

The project's verified fact sheet describes this as an event-driven serverless application and lists the same major AWS components. :chatgpt-content-reference{index="4"}

---

# Q5. Why Did You Choose Serverless Architecture?

### Word-by-word answer

> “The workload is naturally event-driven. An invoice is uploaded, an event is generated, processing starts, and resources are needed only while requests or processing jobs are running.
>
> Managed services such as Lambda, SQS, Step Functions, DynamoDB, Textract and Bedrock reduce the amount of infrastructure I need to operate directly.
>
> However, serverless does not mean unlimited scalability or zero operational work. I still need to manage service quotas, concurrency, retries, idempotency, observability, security and cost.”

---

# Q6. Why Event-Driven Architecture?

### Word-by-word answer

> “Invoice processing contains multiple potentially slow operations such as OCR and Generative AI inference. I did not want the browser's upload request to remain synchronously connected to that entire process.
>
> The event-driven architecture separates ingestion from processing. After the document reaches S3, events move the work into the asynchronous pipeline through SQS and Step Functions.
>
> The benefit is decoupling and buffering. The trade-off is that asynchronous systems require careful state management, retry handling, idempotency and observability.”

---

# ROUND 3 — UPLOAD AND S3

# Q7. Explain the Invoice Upload Flow

### Word-by-word answer

> “The authenticated frontend first requests an upload URL from the backend. The backend derives the tenant identity from the validated Cognito claims, generates an invoice ID, creates a pending processing-job record, and returns a short-lived presigned S3 PUT URL.
>
> The browser uses that URL to upload the invoice directly to S3.
>
> Once the object is created under the configured invoice prefix, S3 sends an event to SQS. That event begins the asynchronous processing flow.”

---

# Q8. Why Presigned URL Instead of Uploading Through Lambda?

### Word-by-word answer

> “I wanted to separate the control path from the data-transfer path.
>
> The API handles authentication, authorization and generation of the upload permission, while the actual document goes directly from the browser to S3.
>
> That avoids unnecessarily proxying the invoice binary through API Gateway and Lambda.
>
> The S3 bucket remains private because the presigned URL provides temporary permission for a specific operation rather than making the bucket public.”

---

# Q9. Is the S3 Bucket Public Because You Use Presigned URLs?

### Word-by-word answer

> “No. A presigned URL does not require the bucket to be public. The bucket can remain private while the URL grants temporary permission to perform a specific S3 operation on a specific object.”

---

# Q10. How Do You Validate Uploaded Files?

### Word-by-word answer

> “The frontend currently checks allowed MIME types and applies a 10 MiB browser-side size limit. However, I would not treat browser-side validation as a security boundary.
>
> The current backend does not comprehensively verify the actual uploaded object's size, content, page count and document structure before OCR.
>
> In Production V2, I would add server-side object validation before expensive processing begins.”

---

# ROUND 4 — SQS, DLQ AND IDEMPOTENCY

# Q11. Why Do You Use SQS?

### Word-by-word answer

> “SQS decouples document ingestion from downstream processing. If invoice uploads arrive faster than the processing system can handle them, the queue can buffer those events.
>
> It also provides retry behavior at the queue-consumer boundary.
>
> However, SQS provides at-least-once delivery, so duplicate messages are possible and the application must be designed for idempotency.”

---

# Q12. What Is At-Least-Once Delivery?

### Word-by-word answer

> “At-least-once delivery means SQS attempts to make sure a message is processed, but the same message can sometimes be delivered more than once.
>
> Therefore, I cannot assume that one invoice event always produces exactly one processing attempt. My processing logic needs to safely handle duplicate deliveries.”

---

# Q13. How Do You Handle Idempotency?

### Difficulty

**Advanced**

### Word-by-word answer

> “Complete idempotency is currently a gap in the project.
>
> Simply overwriting the final DynamoDB record is not sufficient because duplicate executions may already have called Textract, Bedrock or other downstream services.
>
> For Production V2, I would create a stable idempotency key and use an atomic DynamoDB conditional write to claim the invoice before expensive processing starts. Only the execution that successfully claims the processing unit should continue.”

Idempotency is identified among the project's top production gaps. :chatgpt-content-reference{index="5"}

---

# Q14. Does Your DLQ Catch Textract or Bedrock Failures?

### Difficulty

**Pressure Question**

### Word-by-word answer

> “Not automatically.
>
> The SQS-trigger Lambda starts the Step Functions workflow asynchronously and then returns. Once that workflow has successfully started, later failures in Textract, Bedrock or result storage are outside the original SQS retry boundary.
>
> So the SQS DLQ mainly protects the SQS-to-trigger and workflow-start handoff. Downstream processing failures need Step Functions error handling, failure-state persistence and appropriate monitoring.”

The project's own pressure-question guidance explicitly makes this distinction. :chatgpt-content-reference{index="6"}

---

# ROUND 5 — STEP FUNCTIONS

# Q15. Why Did You Use Step Functions?

### Word-by-word answer

> “Invoice processing contains multiple dependent stages with different responsibilities. Step Functions gives me explicit workflow orchestration instead of putting OCR, AI analysis, scoring and persistence into one large Lambda.
>
> It also gives better visibility into workflow stages and provides places to configure retries and error handling.
>
> This separation makes the processing flow easier to reason about and troubleshoot.”

---

# Q16. What Are the Main Workflow Stages?

### Word-by-word answer

> “The repository has four main processing stages.
>
> The first stage processes the document using Textract.
>
> The second stage performs AI analysis using Bedrock Nova Micro.
>
> The third stage applies deterministic Python risk rules.
>
> The fourth stage stores the final result.
>
> Some architecture diagrams may visually separate preparation or validation, but I would describe the repository implementation as four main processing stages.”

---

# ROUND 6 — TEXTRACT

# Q17. Why Amazon Textract?

### Word-by-word answer

> “The application needs information from invoice documents before any semantic AI analysis can happen. I use Amazon Textract `AnalyzeExpense` for document extraction.
>
> It provides invoice-related fields and OCR content that can then be processed by the application.
>
> Textract is the extraction layer. It is not the component that calculates the final risk score or performs the Generative AI analysis.”

---

# Q18. What Information Do You Extract?

### Word-by-word answer

> “The current parser extracts information such as invoice number, vendor, dates, total, subtotal, tax and line items. It also collects raw OCR line text.
>
> One limitation is that many values remain strings, and the current parser does not comprehensively normalize dates and monetary formats or preserve field-level confidence and coordinates.”

---

# Q19. Does Textract Guarantee Correct Data?

### Word-by-word answer

> “No. OCR and document extraction can make mistakes, especially with unusual layouts, poor scans or ambiguous text.
>
> That matters because downstream AI analysis and deterministic financial rules operate on the extracted values. An OCR error can therefore propagate into later findings or scoring.
>
> For production, I would preserve confidence information, normalize important values and route uncertain extraction to review.”

---

# ROUND 7 — BEDROCK AND GENERATIVE AI

# Q20. Where Exactly Is Generative AI Used?

### Word-by-word answer

> “Generative AI is used after Textract.
>
> The application sends structured invoice fields, line-item information and raw OCR text to Amazon Bedrock Nova Micro. The prompt asks the model to identify possible anomalies and produce a structured response containing findings, a summary and confidence.
>
> The model assists with semantic analysis. It does not independently calculate the complete final risk score.”

---

# Q21. Does Nova Micro Receive the Invoice Image?

### Word-by-word answer

> “No. In the current implementation, Nova Micro receives the structured values and OCR text produced from the Textract stage. It does not directly receive the original invoice image.”

---

# Q22. Why Both Textract and Bedrock?

### Word-by-word answer

> “They solve different problems.
>
> Textract converts the document into usable fields and text.
>
> Bedrock Nova Micro reasons over that extracted content and produces possible anomaly findings and explanations.
>
> So Textract is the extraction layer, while Bedrock is the semantic analysis layer.”

---

# Q23. What Model Are You Using?

### Word-by-word answer

> “The current implementation uses Amazon Nova Micro through Amazon Bedrock. The configured model ID is `us.amazon.nova-micro-v1:0`, and the application invokes it through the Bedrock Runtime API.”

---

# Q24. Why Nova Micro?

### Word-by-word answer

> “Nova Micro is the model currently integrated into the project for text-based invoice analysis.
>
> I would not claim that it is objectively the best model because the repository does not contain a comparative model evaluation.
>
> For a production decision, I would evaluate candidate models using the same representative invoice dataset and compare output quality, schema compliance, latency and cost.”

---

# ROUND 8 — PROMPTING AND AI VALIDATION

# Q25. What Does Your Prompt Contain?

### Word-by-word answer

> “The prompt instructs the model to act as an invoice auditor. It includes structured invoice fields, line-item information and raw OCR text and asks the model to return possible anomalies, severity, descriptions, affected fields, a summary and confidence.
>
> The prompt also tells the model not to invent findings.
>
> However, prompt instructions are guidance, not guarantees, so I still need output validation.”

---

# Q26. How Do You Validate the LLM Output?

### Word-by-word answer

> “The current implementation is stronger at parsing than at full validation.
>
> It first attempts direct JSON parsing. If that fails, it removes Markdown fences and retries. It can then try extracting content between the first opening brace and final closing brace. If parsing still fails, it returns a fallback result.
>
> The limitation is that valid JSON can still have the wrong schema or invalid business values. Pydantic models exist in the repository, but the AI Lambda does not currently enforce them. Strict schema and business validation is therefore an important Production V2 improvement.”

---

# Q27. Is Low Temperature Enough to Prevent Hallucinations?

### Word-by-word answer

> “No. Lower temperature can make generation more consistent, but it does not guarantee factual correctness and it is not a validation mechanism.
>
> The model output still needs schema validation and evaluation against representative examples. Important business decisions should not depend only on an LLM response.”

---

# Q28. What Happens if Bedrock Fails?

### Word-by-word answer

> “For some handled Bedrock failures, the application can return a fallback analysis and continue through deterministic scoring and storage.
>
> That improves availability because OCR data is not necessarily lost when AI analysis is unavailable.
>
> However, it creates an important semantic issue: the business job can still become COMPLETED even though the AI stage degraded. The empty AI findings can also reduce the resulting risk score.
>
> In Production V2, I would separate processing completion from AI-analysis quality and mark these cases as degraded or requiring manual review.”

---

# ROUND 9 — RISK SCORING

# Q29. How Is the Risk Score Calculated?

### Word-by-word answer

> “The numeric score is calculated by deterministic Python rules rather than by the language model alone.
>
> The current rules add 40 points for a mathematical discrepancy, 8 points for each important missing field such as invoice number, receipt date, total or vendor, 10 points for a short purely numeric invoice number, and 15 points for a repeated normalized item description.
>
> AI findings also contribute according to severity: HIGH adds 15, MEDIUM adds 7, and LOW or unrecognized severity adds 3.
>
> The score is capped at 100. Zero to 29 is LOW, 30 to 69 is MEDIUM, and 70 to 100 is HIGH.
>
> I describe this as a heuristic review score, not a calibrated fraud probability.”

---

# Q30. Is a Score of 80 an 80% Fraud Probability?

### Word-by-word answer

> “No. The score is a deterministic heuristic created from rule weights and AI findings. It has not been calibrated as a probability of fraud.
>
> An 80 means the current scoring logic accumulated enough points to fall into the HIGH review category. It does not mean there is an 80 percent probability that the invoice is fraudulent.”

---

# Q31. Can AI and Deterministic Rules Double Count the Same Problem?

### Word-by-word answer

> “Yes, that is possible in the current design.
>
> For example, a deterministic rule may identify a mathematical discrepancy while Bedrock describes the same underlying problem as an AI anomaly. Both can contribute to the final score.
>
> In Production V2, I would normalize findings into canonical categories and deduplicate correlated AI and deterministic findings before calculating the final score.”

---

# ROUND 10 — DATABASE AND STATE

# Q32. How Is DynamoDB Designed?

### Word-by-word answer

> “The invoices table uses `tenant_id` as the partition key and `invoice_id` as the sort key. That supports tenant-scoped invoice access.
>
> Processing jobs are stored separately using `job_id` as the partition key.
>
> The invoice record stores completed invoice information, findings and risk results, while the processing-job record tracks processing status, stage and related metadata.”

---

# Q33. Why Use Both S3 and DynamoDB?

### Word-by-word answer

> “They store different types of data.
>
> S3 is used for object data such as original invoice documents, extracted text and frontend assets.
>
> DynamoDB is used for structured application state such as invoice records, processing jobs, status and risk results.
>
> So S3 is my object-storage layer and DynamoDB is my application-state database.”

---

# Q34. What Is Wrong With the Current Job TTL?

### Word-by-word answer

> “The processing-jobs table has TTL configured on the `ttl` attribute, but the current job-creation logic does not populate that attribute.
>
> So the infrastructure supports TTL, but the created jobs do not automatically expire through that mechanism.
>
> I would fix the write path to calculate and store the expiry timestamp and then verify expiration behavior.”

---

# ROUND 11 — FRONTEND

# Q35. How Does the Frontend Know Processing Has Finished?

### Word-by-word answer

> “Processing is asynchronous, so after upload the frontend navigates to the invoice detail flow and polls the status API roughly every three seconds.
>
> Polling stops when the job reaches a terminal state such as COMPLETED or FAILED.
>
> The frontend also queries invoice detail information to display the completed result.”

---

# Q36. What Frontend Problem Did You Identify?

### Word-by-word answer

> “One important issue is stale detail state.
>
> The detail query can initially return 404 because processing has not yet created the final invoice record. Later, the status query may reach COMPLETED, but the detail query is not reliably invalidated and refetched.
>
> So the backend can finish successfully while the UI still shows stale or failed detail state.
>
> I would explicitly invalidate or refetch the detail query when processing reaches COMPLETED.”

---

# Q37. What Is the Browser Cache Security Issue?

### Word-by-word answer

> “The React Query keys are not fully scoped by user identity, and logout clears authentication state but does not comprehensively clear cached invoice data and related UI state.
>
> That means another user signing into the same SPA session could potentially receive stale data from the previous user's browser cache.
>
> I would use user-scoped query keys and clear private query and application state whenever authentication identity changes.”

---

# ROUND 12 — SECURITY

# Q38. Explain Authentication and Authorization

### Word-by-word answer

> “Authentication answers who the user is. Authorization answers what that authenticated user is allowed to access.
>
> In this project, Cognito authenticates the user. The frontend retrieves the Cognito token and sends it in the Authorization header. API Gateway validates it using a Cognito authorizer.
>
> The backend derives `tenant_id` from the validated Cognito `sub` claim.
>
> After authentication, the application still needs resource-level authorization to make sure that user can only access their own invoice and processing data.”

---

# Q39. What Is the Current Job-Status Authorization Gap?

### Word-by-word answer

> “The current status flow first performs a tenant-scoped invoice lookup, but its fallback then retrieves the processing job using `job_<invoice_id>` without independently comparing the stored job tenant with the requesting tenant.
>
> That means knowledge of another invoice ID may expose processing status, stage or error information.
>
> I would require ownership validation on every resource lookup, including processing jobs.”

---

# Q40. How Is Service-to-Service Authorization Handled?

### Word-by-word answer

> “Cognito protects user-facing API access, but AWS services and Lambda functions use IAM for service-to-service authorization.
>
> The project defines per-function roles and resource grants. I would still audit those policies for least privilege rather than assuming that simply having separate roles means every permission is perfectly minimal.”

---

# ROUND 13 — DATA LIFECYCLE

# Q41. What Happens When a User Deletes an Invoice?

### Word-by-word answer

> “The current delete flow removes the tenant-scoped invoice record and attempts to delete the original S3 object.
>
> However, deletion is not yet a complete data-purge workflow. The processing-job record, processed text and historical S3 versions are not comprehensively removed.
>
> For Production V2, I would define an explicit retention and deletion policy and implement a complete cascade deletion workflow across all related data.”

---

# Q42. Where Is Processed Text Stored?

### Word-by-word answer

> “The processed S3 bucket stores extracted text using a path such as `processed-text/{tenant_id}/{invoice_id}.txt`.
>
> The current storage handler does not store the complete OCR and AI-analysis JSON as processed S3 artifacts, so I would not claim that every intermediate result is archived there.”

---

# ROUND 14 — NOTIFICATIONS

# Q43. How Do High-Risk Notifications Work?

### Word-by-word answer

> “The repository contains EventBridge and SNS infrastructure intended for high-risk notifications.
>
> Conceptually, a high-risk business event would be routed through EventBridge to SNS and then delivered to a subscriber.
>
> However, complete producer-to-EventBridge-to-SNS-to-subscriber delivery is not fully verified in the current repository, so I would describe notifications as partially implemented rather than guaranteed.”

The project fact sheet classifies alerts as partial and automatic email notifications as documented/intended rather than fully verified. :chatgpt-content-reference{index="7"}

---

# Q44. Why EventBridge and SNS?

### Word-by-word answer

> “EventBridge and SNS serve different purposes. EventBridge is useful for routing business events based on rules, while SNS provides publish-subscribe delivery to subscribers.
>
> Keeping notifications outside the core invoice-processing logic also reduces coupling. A notification failure should not necessarily invalidate an otherwise successfully analyzed invoice.”

---

# ROUND 15 — CDK AND DEPLOYMENT

# Q45. How Did You Define Infrastructure?

### Word-by-word answer

> “The project uses AWS CDK as infrastructure as code. CDK defines infrastructure using code and synthesizes CloudFormation templates that AWS CloudFormation deploys.
>
> The project separates infrastructure into five stacks: StorageStack, AuthStack, ProcessingStack, ApiStack and FrontendStack.
>
> That provides logical separation between persistent data, authentication, processing, APIs and frontend delivery.”

The repository's verified fact sheet identifies AWS CDK as its infrastructure framework. :chatgpt-content-reference{index="8"}

---

# Q46. CDK or CloudFormation — Which One Are You Actually Using?

### Word-by-word answer

> “Both are involved, but at different layers. I author the infrastructure using AWS CDK. CDK synthesizes CloudFormation templates, and CloudFormation performs the AWS resource provisioning.
>
> So CDK is the higher-level development abstraction and CloudFormation remains the underlying deployment engine.”

---

# Q47. Explain Your CI/CD

### Word-by-word answer

> “The repository contains GitHub Actions workflow definitions and uses GitHub OIDC in the deployment design rather than storing long-lived AWS access keys.
>
> OIDC allows GitHub Actions to assume an authorized AWS IAM role using temporary credentials.
>
> However, repository definitions alone do not prove that the current CI/CD pipeline is successfully deploying every release, so I distinguish between implemented workflow definitions and an operationally verified production pipeline.”

Operational CI/CD is explicitly listed as unverified in the project analysis. :chatgpt-content-reference{index="9"}

---

# Q48. What Deployment Challenge Did You Face?

### Word-by-word practice answer

> “One documented technical challenge was Lambda dependency packaging. Shared Python code has to be placed in the correct layer directory structure, and compiled dependencies must be compatible with the Lambda runtime environment.
>
> This taught me that code working in a local environment does not guarantee that the same package will import correctly in Lambda. Reproducible serverless deployment requires controlling the runtime version, CPU architecture, operating-system compatibility, package versions and layer structure.”

For the phrase **“I faced”**, use it only if this was actually your personal troubleshooting work. The source specifically warns not to infer personal authorship merely from repository contents. :chatgpt-content-reference{index="10"}

---

# ROUND 16 — OBSERVABILITY AND TROUBLESHOOTING

# Q49. How Do You Monitor the Application?

### Word-by-word answer

> “The project has CloudWatch logging, X-Ray tracing configuration and a DLQ alarm foundation.
>
> For troubleshooting, I would correlate events using identifiers such as invoice ID and workflow execution information and follow the request across ingestion, workflow execution, OCR, AI analysis, persistence and frontend retrieval.
>
> I would not claim the current repository demonstrates a complete production observability platform because a complete operational dashboard and full runtime tracing have not been verified.”

The source describes logs, tracing configuration and a DLQ alarm, but not a demonstrated complete operational dashboard. :chatgpt-content-reference{index="11"}

---

# Q50. An Invoice Was Uploaded but No Result Appeared. How Would You Troubleshoot?

### Difficulty

**Very Important**

### Word-by-word answer

> “I would troubleshoot according to the architecture rather than randomly checking services.
>
> First, I would verify that the invoice object actually exists in the expected S3 location.
>
> Second, I would check whether the S3 event reached SQS and whether there is queue backlog or DLQ activity.
>
> Third, I would inspect the trigger Lambda logs and verify that it started a Step Functions execution.
>
> Fourth, I would inspect the Step Functions execution history to identify the failed stage.
>
> If OCR failed, I would investigate Textract input, permissions and document compatibility. If AI analysis failed, I would inspect Bedrock invocation errors, throttling and parsing. If storage failed, I would inspect DynamoDB or S3 permissions and payloads.
>
> Finally, if the backend completed successfully, I would check the status and detail APIs and then the frontend polling and cache behavior.
>
> This lets me isolate the failure boundary systematically.”

---

# ROUND 17 — TESTING

# Q51. How Did You Test the Project?

### Word-by-word answer

> “The repository contains unit-test code, and the analysis identified 44 unit-test functions. However, those tests were not executed during the repository analysis, and an OCR import defect was identified.
>
> Therefore, I would not claim that all 44 tests pass.
>
> For production, I would combine unit tests with contract tests for AI output, AWS integration tests, end-to-end invoice-flow tests, tenant-isolation tests and failure-path tests.”

The verified fact sheet says 44 unit-test functions were found, execution was not performed, and an OCR import defect exists. :chatgpt-content-reference{index="12"}

---

# Q52. How Would You Test the AI?

### Word-by-word answer

> “I would create a representative labeled invoice evaluation dataset with expected extracted fields and expected review findings.
>
> Then I would measure things such as schema-valid response rate, relevant finding precision and recall, false positives, false negatives, consistency, fallback rate, latency and cost.
>
> I would also version prompts and models so changes can be regression-tested against the same evaluation dataset before deployment.
>
> The current repository does not contain measured results proving those production AI-quality metrics.”

---

# ROUND 18 — COST AND SCALABILITY

# Q53. How Much Does Your Application Cost?

### Word-by-word answer

> “I would not claim a verified production cost because the repository does not contain measured billing evidence for a representative workload.
>
> The important cost drivers include Textract document processing, Bedrock inference, Lambda execution, Step Functions, DynamoDB operations, S3 storage and requests, API Gateway and CloudFront.
>
> For production, I would tag the resources, run representative workloads, measure the AWS bill and calculate metrics such as cost per successfully analyzed invoice.”

Actual cost is classified as unverified. :chatgpt-content-reference{index="13"}

---

# Q54. How Many Users Can Your System Handle?

### Word-by-word answer

> “I do not have a verified maximum-user number because the project analysis does not include production load-test evidence.
>
> The architecture uses managed serverless services that can scale independently, but actual capacity depends on Lambda concurrency, service quotas, Bedrock throughput, Textract behavior, SQS backlog, DynamoDB capacity behavior and downstream limits.
>
> I would load-test the complete workflow before giving a production capacity number.”

Performance and service quotas are also classified as unverified. :chatgpt-content-reference{index="14"}

---

# Q55. What Would Become a Scaling Problem First?

### Word-by-word answer

> “I would measure before declaring one guaranteed first bottleneck, but there are several areas I would watch closely.
>
> These include Bedrock and Textract quotas, Lambda concurrency, the current local-only Bedrock rate limiter, growing Step Functions payloads, frontend polling volume and analytics endpoints that aggregate a tenant's invoice history in Python.
>
> Those are areas I would include in load testing and operational dashboards.”

---

# ROUND 19 — LIMITATIONS AND PRODUCTION READINESS

# Q56. Is This Project Production-Ready?

### Difficulty

**MUST MASTER**

### Word-by-word answer

> “I would describe it as a substantial production-oriented prototype rather than fully production-ready.
>
> The main processing and display path is implemented, and the project has strong foundations such as authentication, direct S3 upload, asynchronous processing, workflow orchestration, infrastructure as code and observability components.
>
> But important areas still need strengthening, including resource authorization, idempotency, AI-output validation, financial correctness, frontend state isolation, notification wiring, deployment reproducibility and comprehensive testing.
>
> I would close those gaps before claiming full production readiness.”

The source's project assessment uses essentially this same maturity distinction. :chatgpt-content-reference{index="15"}

---

# Q57. What Are the Top Three Improvements You Would Make?

### Word-by-word answer

> “My first priority would be security and correctness: fix the processing-job ownership gap, browser cache isolation and complete idempotency.
>
> Second, I would improve AI and financial correctness through strict schema validation, degraded-analysis states, better monetary normalization and deduplication of AI and deterministic findings.
>
> Third, I would strengthen production operations with automated tests, reproducible Lambda packaging, verified CI/CD, notification delivery, observability and load testing.”

---

# Q58. What Would Production V2 Look Like?

### Word-by-word answer

> “Production V2 would keep the main serverless architecture but strengthen the boundaries around it.
>
> I would add complete ownership checks, atomic idempotency before expensive processing, stronger backend upload validation, strict AI response schemas, normalized financial data, finding deduplication and explicit degraded-analysis status.
>
> I would also improve data lifecycle management, verified notification delivery, reproducible dependency builds, automated integration and security tests, operational dashboards, service-level alarms and representative load and cost testing.
>
> I would make those improvements before adding unnecessary complexity such as agents or additional infrastructure.”

---

# ROUND 20 — TECHNOLOGY TRAPS

# Q59. Is This a RAG Application?

### Word-by-word answer

> “No. The project does not contain a retrieval pipeline, embeddings, vector database or knowledge base. Nova Micro receives content extracted from the current invoice. Therefore, I describe it as Generative AI analysis over OCR output, not RAG.”

No RAG or vector database is present according to the verified fact sheet. :chatgpt-content-reference{index="16"}

---

# Q60. Is This Agentic AI?

### Word-by-word answer

> “No. The workflow is predefined using Step Functions. The language model analyzes invoice content inside one stage, but it does not autonomously select tools or decide which processing step should execute next.
>
> So the accurate description is fixed workflow orchestration with Generative AI analysis, not autonomous Agentic AI.”

The source's pressure-question guidance makes the same distinction. :chatgpt-content-reference{index="17"}

---

# Q61. Is This an ML Project?

### Word-by-word answer

> “The application uses managed AI services, but it does not train a custom machine-learning model. Textract performs document extraction and Nova Micro performs foundation-model inference through Bedrock. There is no custom training pipeline, model registry or MLflow-based model lifecycle in this project.”

---

# ROUND 21 — BEHAVIORAL + PROJECT OWNERSHIP

# Q62. What Was Your Personal Role?

This answer **must ultimately be yours**.

Do not claim ownership of every repository component just because you understand it. The project's interview bank explicitly warns that repository contents alone do not prove personal authorship. :chatgpt-content-reference{index="18"}

### Word-by-word practice template

> “My work on this project focused on the AWS serverless architecture, backend processing flow, Generative AI integration and deployment-related components. I worked with services such as S3, Lambda, SQS, Step Functions, Textract, Bedrock, DynamoDB, Cognito, API Gateway and CDK.
>
> I also worked through integration and deployment issues and learned how the individual services behave as one asynchronous system.
>
> When I explain the project, I separate the components I personally implemented or troubleshot from components that exist in the overall repository rather than claiming that I wrote every line.”

**Important:** edit this answer so every personal claim is true for you.

---

# Q63. What Was the Most Difficult Part?

### Word-by-word practice answer

> “One of the most difficult parts was understanding and managing the boundaries in an asynchronous serverless system.
>
> An upload can succeed while downstream processing fails. SQS can redeliver messages. Step Functions has its own execution state. DynamoDB stores business job state. Bedrock can degrade while the overall job still becomes COMPLETED, and the frontend has its own cached state.
>
> That taught me that reliability is not just about making each AWS service work individually. I need consistent state semantics, idempotency, failure handling and observability across the complete system.”

---

# Q64. Tell Me About a Problem You Troubleshot

### Word-by-word practice answer

> “One documented deployment problem involved Lambda dependency packaging and shared Python imports.
>
> The important lesson was that dependencies have to be packaged in the structure expected by Lambda and must be compatible with the target runtime environment. Something working in my local Python environment does not guarantee that it will import successfully inside Lambda.
>
> I learned to inspect the deployed artifact itself, verify the layer directory structure, check runtime and architecture compatibility, and make the build process reproducible instead of repeatedly fixing the artifact manually.”

Again, only use **“I troubleshot”** if you actually did.

---

# Q65. What Is the Biggest Thing You Learned?

### Word-by-word answer

> “My biggest learning is that building an AI feature is only one part of building an AI application.
>
> The difficult engineering problems are often around the model: authentication, authorization, event delivery, duplicate processing, OCR uncertainty, model-output validation, business rules, application state, dependency packaging, observability and failure recovery.
>
> I also learned to distinguish AI-generated suggestions from deterministic business logic and not to overclaim what a heuristic score or language model output represents.”

---

# ROUND 22 — INTERVIEWER PRESSURE MODE

These are intentionally aggressive.

---

## Pressure 1

### Interviewer

> **“You told me this is Agentic AI. Show me where the agent selects a tool.”**

### Answer

> “It doesn't. I would correct that description. The current project uses a predefined Step Functions workflow with Generative AI analysis. It is not autonomous Agentic AI.”

---

## Pressure 2

### Interviewer

> **“You called this RAG. Show me your vector database.”**

### Answer

> “There isn't one. The current implementation has no retrieval or vector-search pipeline. Nova Micro analyzes the current invoice's extracted content, so I would not classify the project as RAG.”

---

## Pressure 3

### Interviewer

> **“You said SQS makes retries safe. What happens if I deliver the same message twice?”**

### Answer

> “That exposes one of the current limitations. SQS provides at-least-once delivery, and the current project does not have complete atomic idempotency. Production V2 should claim each processing unit through a conditional write before performing expensive or externally visible side effects.”

---

## Pressure 4

### Interviewer

> **“You said the DLQ catches OCR failures.”**

### Answer

> “I would correct that statement. The queue message is handled by a Lambda that starts Step Functions asynchronously. Later OCR failures occur after that queue-consumer boundary, so they do not automatically send the original SQS message to the ingestion DLQ.”

This correction is explicitly represented in the project's pressure-question bank. :chatgpt-content-reference{index="19"}

---

## Pressure 5

### Interviewer

> **“Your score says LOW. So the invoice is safe?”**

### Answer

> “No. LOW means the current heuristic accumulated fewer than 30 points. It is not proof that the invoice is legitimate, and it is not a calibrated fraud probability.”

---

## Pressure 6

### Interviewer

> **“Your Python rules are deterministic. So they're 100% accurate?”**

### Answer

> “No. Deterministic means the same inputs produce the same result. The rules can still contain simplified financial assumptions, and their inputs can be wrong because of OCR extraction errors.”

---

## Pressure 7

### Interviewer

> **“Bedrock returned confidence 0.95. So you have 95% accuracy?”**

### Answer

> “No. That confidence is model-generated. It is not measured accuracy. Accuracy would require evaluation against labeled ground-truth examples.”

---

## Pressure 8

### Interviewer

> **“Cognito means tenant isolation is secure, correct?”**

### Answer

> “Cognito establishes authenticated identity, but resource-level authorization still has to be enforced by the application. The current job-status fallback has an ownership-check gap, so I would not claim complete tenant isolation yet.”

---

## Pressure 9

### Interviewer

> **“You said email alerts work. Show me the subscriber.”**

### Answer

> “The repository contains EventBridge and SNS infrastructure and notification intent, but complete subscriber delivery is not verified. I would describe the notification path as partial rather than claim guaranteed email delivery.”

The source similarly warns against claiming that an email was sent when subscription/wiring is not verified. :chatgpt-content-reference{index="20"}

---

## Pressure 10

### Interviewer

> **“You say your CI/CD works. Show me the latest successful deployment.”**

### Answer

> “I cannot prove a currently successful pipeline from repository definitions alone. GitHub Actions workflows exist, but current operational execution is unverified. I would verify workflow history and deployment evidence before making that claim.”

---

## Pressure 11

### Interviewer

> **“You say your application handles thousands of users. Show me your load test.”**

### Answer

> “I don't have verified load-test evidence supporting that number, so I would not claim it. I would measure end-to-end throughput, concurrency, queue depth, service throttling, latency and cost before stating a supported production capacity.”

---

## Pressure 12

### Interviewer

> **“What did YOU actually build?”**

### Answer

> “I would answer that based on my actual implementation and troubleshooting work rather than claiming ownership of every repository component. I can explain the complete architecture, but understanding a component and personally implementing that component are different claims.”

This distinction is also explicit in the source interview material. :chatgpt-content-reference{index="21"}

---

# 66. Troubleshooting Round

An interviewer may give you scenarios rather than definitions.

Use:

```text
SYMPTOM
   ↓
Find the boundary
   ↓
Check logs/state
   ↓
Identify root cause
   ↓
Fix
   ↓
Prevent recurrence
```

---

# Scenario 1 — Upload Works, Processing Never Starts

### Answer

> “I would first verify that the S3 object exists under the expected key. Then I would verify S3 event delivery to SQS, inspect queue depth and DLQ activity, and check the trigger Lambda logs. If the Lambda received the message, I would verify whether it successfully called StartExecution on Step Functions. That isolates whether the failure is S3-to-SQS, SQS-to-Lambda or Lambda-to-Step-Functions.”

---

# Scenario 2 — Step Functions Fails at OCR

### Answer

> “I would inspect the failed Step Functions state and the Textract Lambda logs. Then I would check the S3 object reference, document compatibility, IAM permissions and the Textract API response. I would not expect the original SQS DLQ to automatically handle this failure because the workflow has already started.”

---

# Scenario 3 — Bedrock Is Throttling

### Answer

> “I would inspect Bedrock error responses and retry behavior. The project already has application-level retry with backoff and jitter, but the current rate limiter is local to an individual warm Lambda environment and therefore does not coordinate globally across concurrent instances.
>
> For production, I would measure actual Bedrock quotas and concurrency and use an architecture that controls aggregate request rate rather than assuming local process memory can enforce a global limit.”

---

# Scenario 4 — Backend Says COMPLETED but UI Still Shows Error

### Answer

> “I would check the frontend query state. The detail request can initially return 404 while processing is incomplete, and the current status query reaching COMPLETED does not reliably invalidate the stale detail query. I would fix that by invalidating or explicitly refetching the invoice-detail query when status becomes COMPLETED.”

---

# Scenario 5 — User B Sees User A's Previous Invoice After Login

### Answer

> “I would investigate the client cache before assuming a backend authorization failure. The current query keys do not fully include user identity, and logout does not comprehensively clear private cached state. I would scope query keys by authenticated user and clear private React Query and application state whenever identity changes.”

---

# Scenario 6 — User Deletes Invoice but Processed Text Remains

### Answer

> “That is consistent with the current lifecycle limitation. The delete operation is not a complete cascade purge across all storage. I would implement a deletion workflow that removes or expires the invoice record, original object, processed text, processing job and any other retained artifacts according to a defined retention policy.”

---

# 67. Final 30-Second Answer

Memorize the **flow**, then say it naturally:

> “NovaMind AI is a serverless invoice intelligence application on AWS. A user uploads an invoice directly to S3 using a presigned URL. SQS and Step Functions coordinate asynchronous processing, Textract extracts invoice information, Bedrock Nova Micro generates possible anomaly findings, and deterministic Python rules calculate a review score. Results are stored using DynamoDB and S3 and displayed through a React frontend. I describe the system as invoice review support rather than autonomous fraud detection.”

---

# 68. Final 60-Second Answer

> “NovaMind AI is a serverless, event-driven invoice intelligence application built on AWS.
>
> Users authenticate through Cognito and upload invoices from a React frontend using presigned S3 URLs. Once an invoice reaches S3, an event is sent to SQS, and a trigger Lambda starts an Express Step Functions workflow.
>
> Textract extracts invoice fields and OCR text. Bedrock Nova Micro analyzes that extracted information for possible anomalies, and deterministic Python rules calculate a heuristic risk score. Results are persisted in DynamoDB and S3 and displayed back to the user through authenticated APIs.
>
> The main workflow is implemented, but I consider it a production-oriented prototype rather than fully production-ready because areas such as idempotency, authorization, AI-output validation, financial correctness, frontend state, testing and deployment reliability still need strengthening.”

---

# 69. Final 2-Minute Answer

> “My project is NovaMind AI, a serverless and event-driven invoice intelligence platform built on AWS.
>
> The problem it addresses is invoice extraction and review. Instead of manually locating every field and checking invoices from scratch, the application extracts structured information and generates review signals that can help identify documents requiring closer attention.
>
> The frontend is built with React and authentication is handled through Cognito. After authentication, the user requests a presigned upload URL and uploads the invoice directly to a private S3 bucket.
>
> S3 sends an event to SQS. A trigger Lambda consumes the message and starts an Express Step Functions workflow.
>
> The workflow has four main stages. First, Textract `AnalyzeExpense` extracts invoice fields and OCR text. Second, Bedrock Nova Micro analyzes those extracted values for possible anomalies. Third, deterministic Python business rules calculate a heuristic risk score using financial checks and AI findings. Finally, the results are persisted in DynamoDB and extracted text is stored in S3.
>
> Because processing is asynchronous, the frontend polls processing status and retrieves the final invoice result through authenticated APIs.
>
> One important design principle is that I do not treat the language model as the final business decision maker. The LLM produces review findings, while deterministic Python logic calculates the score.
>
> I also don't describe the current system as fully production-ready. The main workflow exists, but I would still strengthen idempotency, resource authorization, AI-output validation, financial normalization, frontend cache isolation, notification delivery, automated testing and deployment reproducibility before production.”

---

# 70. Final “Why Should I Believe You Understand This Project?” Answer

If an interviewer keeps digging:

> “I can explain not only the happy path but also the failure boundaries and current limitations. For example, I know SQS provides at-least-once delivery, so duplicate processing needs idempotency. I know the ingestion DLQ does not automatically capture later Textract failures after Step Functions has started. I know Bedrock failure can still lead to a business COMPLETED state, and that a model-generated confidence value is not measured accuracy. I also know Cognito authentication does not automatically guarantee resource authorization. Those boundaries are the areas I focused on understanding rather than only memorizing the AWS service names.”

---

# 71. Final Project Mental Model

If you forget everything during an interview:

```text
              NOVAMIND AI

                  USER
                   │
                   ▼
              AUTHENTICATE
                Cognito
                   │
                   ▼
                 UPLOAD
          Presigned URL → S3
                   │
                   ▼
                 BUFFER
                   SQS
                   │
                   ▼
              ORCHESTRATE
             Step Functions
                   │
        ┌──────────┼───────────┐
        ▼          ▼           ▼
     EXTRACT     ANALYZE      SCORE
     Textract    Bedrock      Python
        │          │           │
        └──────────┼───────────┘
                   ▼
                  STORE
             S3 + DynamoDB
                   │
                   ▼
                 DISPLAY
                  React
```

Remember:

```text
Textract = WHAT IS IN THE DOCUMENT?

Bedrock = WHAT MIGHT BE SUSPICIOUS?

Python = HOW MANY REVIEW POINTS?

DynamoDB = WHAT IS THE APPLICATION STATE?

React = WHAT DOES THE USER SEE?
```

---

# 72. Final Interview Revision Checklist

Before claiming you are ready, you should be able to explain these without notes:

```text
□ Project purpose
□ Business problem
□ Intended users
□ Complete architecture
□ Why serverless
□ Why event-driven
□ Authentication
□ Authorization
□ Presigned upload
□ S3
□ SQS
□ At-least-once delivery
□ DLQ boundary
□ Idempotency
□ Step Functions
□ Textract
□ OCR limitations
□ Bedrock Nova Micro
□ Prompt
□ Output parsing
□ Output validation
□ Hallucination
□ Bedrock failure
□ Risk-scoring formula
□ Score limitations
□ AI/rule double counting
□ DynamoDB design
□ Application state
□ Frontend polling
□ Frontend stale-state problem
□ Browser cache isolation
□ EventBridge/SNS
□ CDK
□ CloudFormation
□ Lambda packaging
□ GitHub Actions
□ OIDC
□ CloudWatch
□ X-Ray
□ Troubleshooting
□ Testing
□ AI evaluation
□ Cost drivers
□ Scaling limitations
□ Security gaps
□ Data lifecycle
□ Production limitations
□ Production V2
□ Why NOT RAG
□ Why NOT Agentic AI
□ What you personally implemented
□ Biggest challenge
□ What you learned
```

---

# 73. Final Top 10 Questions — MUST MASTER

Before practicing 50+ questions, master these ten:

### 1. Tell me about your project.

> “NovaMind AI is a serverless invoice intelligence application on AWS. Users upload invoices through a React application using presigned S3 URLs. SQS and Step Functions coordinate asynchronous processing, Textract extracts invoice information, Bedrock Nova Micro performs semantic anomaly analysis, deterministic Python rules calculate a heuristic risk score, and DynamoDB and S3 persist the results.”

### 2. Explain the architecture.

> “React and CloudFront form the frontend layer, Cognito provides authentication, API Gateway and Lambda provide the API layer, S3 and SQS handle ingestion, Step Functions orchestrates Textract, Bedrock, Python scoring and persistence, and DynamoDB and S3 hold application data and artifacts.”

### 3. Why SQS?

> “SQS decouples upload from processing and buffers work, but because delivery is at least once, the application must handle duplicates.”

### 4. Why Step Functions?

> “It explicitly orchestrates OCR, AI analysis, scoring and persistence rather than coupling everything inside one Lambda.”

### 5. Textract vs Bedrock?

> “Textract extracts document content. Bedrock performs semantic Generative AI analysis over that extracted content.”

### 6. Who calculates the score?

> “Deterministic Python rules calculate the numeric score. Bedrock findings contribute inputs to that calculation.”

### 7. Is it RAG or Agentic AI?

> “Neither. There is no retrieval pipeline or vector database, and there is no autonomous tool-selection agent. It is a predefined workflow with Generative AI analysis.”

### 8. Biggest limitation?

> “The major gaps include resource authorization, complete idempotency, AI-output validation, financial correctness, frontend state isolation, notification verification, testing and deployment reproducibility.”

### 9. Production-ready?

> “I describe it as a substantial production-oriented prototype, not a verified fully production-ready system.”

### 10. Production V2?

> “I would first strengthen security and idempotency, then AI and financial correctness, followed by testing, deployment, observability, notification reliability, load testing and cost measurement.”

The source identifies the same broad central areas—architecture, SQS boundaries, AI trust, financial correctness, security, delivery, troubleshooting, scaling and production readiness—as the most important interview topics. :chatgpt-content-reference{index="22"}

---

# 74. The Most Important Interview Rule

Do not try to sound more experienced by exaggerating.

A strong answer can be:

> “That part is not implemented.”

> “That is partially implemented.”

> “I haven't verified that.”

> “The repository contains the configuration, but I don't have runtime evidence.”

> “That is a limitation I identified.”

> “That would be part of Production V2.”

> “I don't have measured performance data, so I wouldn't claim a number.”

These answers are much safer than inventing an implementation.

---

# 75. Final Learning Strategy

You now have **25 project-learning files**.

Do **not** restart from File 01 and memorize every sentence.

Use:

```text
ROUND 1
Files 01–10
Understand architecture + AWS + AI

        ↓

ROUND 2
Files 11–18
Understand correctness + state + deployment

        ↓

ROUND 3
Files 19–23
Understand production engineering

        ↓

ROUND 4
File 24
Learn project storytelling

        ↓

ROUND 5
File 25
Study interview answers

        ↓

ROUND 6
Close ALL files

        ↓

REAL MOCK INTERVIEW

Question 1
    ↓
Your answer
    ↓
Feedback
    ↓
Pressure question
    ↓
Your answer
    ↓
Correction
    ↓
Next question
```

---

# 76. Final Readiness Levels

### Level 1 — Memorized

You can repeat:

> “S3 → SQS → Lambda → Step Functions…”

But follow-up questions confuse you.

**Not ready yet.**

### Level 2 — Understand

You can explain why each service exists.

**Improving.**

### Level 3 — Defend

Interviewer asks:

> “Why SQS?”

> “Why not Lambda directly?”

> “What about duplicates?”

> “What about DLQ?”

And you can answer.

**Good.**

### Level 4 — Troubleshoot

Interviewer says:

> “Invoice uploaded but result never appeared.”

You can systematically locate the failed boundary.

**Strong.**

### Level 5 — Critique Your Own Architecture

You can explain:

```text
What works
What does not
Why
Trade-offs
Security gaps
Reliability gaps
AI limitations
How Production V2 fixes them
```

**This is the target.**

---

# 77. Your Final Interview Rule

Do not memorize 77 sections word-for-word.

Remember this:

```text
WHAT
 ↓
WHY
 ↓
HOW
 ↓
WHY THIS DESIGN
 ↓
WHAT CAN FAIL
 ↓
HOW I TROUBLESHOOT
 ↓
CURRENT LIMITATION
 ↓
HOW I WOULD IMPROVE IT
```

That framework can answer almost any project question.

---

# 78. Final Master Answer

When you eventually can say something like this naturally, you understand the project:

> “NovaMind AI is a serverless, event-driven invoice intelligence application built on AWS. Users authenticate through Cognito and upload invoices directly to private S3 using presigned URLs. S3 events go through SQS, and a Lambda starts an Express Step Functions workflow.
>
> Textract extracts invoice fields and OCR text, Bedrock Nova Micro analyzes that content for possible anomalies, and deterministic Python rules calculate a heuristic review score. DynamoDB stores invoice and job state, S3 stores documents and extracted text, and the React frontend retrieves the results through authenticated APIs.
>
> The interesting part of the project is not only the AI integration. It is handling the boundaries around AI: duplicate events, asynchronous state, OCR uncertainty, LLM-output validation, authorization, deterministic business rules, frontend caching, deployment and observability.
>
> The main application path is implemented, but I would not call it fully production-ready. My Production V2 priorities would be complete ownership enforcement, atomic idempotency, strict AI schema validation, better financial normalization, clearer degraded-analysis states, stronger data lifecycle management, automated testing, reproducible deployment, verified notifications, observability and load testing.
>
> I also make clear that the project is not RAG, not autonomous Agentic AI and does not train a custom ML model. It is a fixed AWS workflow that combines document intelligence, Generative AI inference and deterministic business rules.”

That framing stays aligned with the repository evidence: the main processing/display path is implemented, several production concerns remain partial, live operational claims remain unverified, and RAG/agents/ML training are not present. :chatgpt-content-reference{index="23"}

---

# Project 1 Learning Roadmap — Complete

```text
01 → Project Overview                         ✅
02 → Current Architecture                    ✅
03 → End-to-End Application Flow             ✅
04 → Technology Stack and Codebase           ✅
05 → Cognito Authentication                  ✅
06 → Presigned S3 Upload                     ✅
07 → SQS / DLQ / Idempotency                 ✅
08 → Step Functions                          ✅
09 → Textract                                ✅
10 → Bedrock Nova Micro                      ✅
11 → AI Output Validation                    ✅
12 → Risk Scoring                            ✅
13 → DynamoDB                                ✅
14 → Application State                       ✅
15 → Frontend                                ✅
16 → EventBridge / SNS                       ✅
17 → CDK                                     ✅
18 → Deployment / CI/CD                      ✅
19 → Security / Data Lifecycle               ✅
20 → Reliability / Observability             ✅
21 → Testing / AI Quality                    ✅
22 → Cost / Scalability                      ✅
23 → Limitations / Production V2             ✅
24 → Project Storytelling                    ✅
25 → Mock Interview / Final Revision         ✅
```

The next stage should **not** be another theory file. It should be the actual mock interview: start with **“Tell me about your NovaMind AI Invoice Intelligence project”**, let you answer without looking at these notes, then evaluate your technical correctness, communication, missing points, and follow-up handling before moving to Question 2.