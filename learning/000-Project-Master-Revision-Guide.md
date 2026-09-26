# NovaMind AI Invoice Intelligence Platform
## Master Revision Guide

> **Purpose:** Understand the complete project, revise quickly, and prepare for interviews without repeatedly reading all 25 detailed learning files.

---

# How to Use This File

This is my **MAIN STUDY FILE**.

The other 25 learning files are my **REFERENCE LIBRARY**.

I should NOT try to memorize all 25 files.

My learning process is:

```text
Master Revision Guide
        ↓
Understand one section
        ↓
Explain it without notes
        ↓
Can I explain it?
   ┌────┴────┐
  YES        NO
   │          │
   ↓          ↓
Continue    Open the detailed
            learning file
                ↓
            Understand it
                ↓
             Come back
```

---

# PART 1 — PROJECT IDENTITY

## What is my project?

**NovaMind AI Invoice Intelligence Platform** is a serverless, event-driven invoice processing and review-support application built on AWS.

It combines:

- document processing,
- OCR,
- Generative AI,
- deterministic Python business rules,
- asynchronous AWS services,
- authentication,
- storage,
- and a React dashboard.

The system accepts invoice documents, extracts invoice information, performs AI-assisted anomaly analysis, calculates a heuristic risk score, stores the results, and presents them to authenticated users.

---

# One-Sentence Project Answer

> “NovaMind AI is a serverless, event-driven invoice intelligence application on AWS that uses Amazon Textract for invoice extraction, Amazon Bedrock Nova Micro for AI-assisted anomaly analysis, deterministic Python rules for heuristic risk scoring, and a React dashboard for presenting the results.”

---

# What Problem Does It Solve?

Invoice reviewers may need to:

- read invoices,
- locate important fields,
- check totals,
- identify missing information,
- inspect unusual values,
- and decide which invoices need closer review.

NovaMind AI assists this process.

It does **not** prove that an invoice is fraudulent.

A better description is:

> **Invoice intelligence and review-support system**

rather than:

> **Autonomous fraud-detection system**

---

# Intended Users

Possible users include:

- finance teams,
- accounts-payable teams,
- invoice reviewers,
- auditors,
- small-business operators.

Important:

The repository supports the workflow for these types of users.

It does **not** prove that real production customers are currently using the application.

---

# PART 2 — THE COMPLETE PROJECT IN ONE DIAGRAM

```text
                         USER
                           │
                           ▼
                    React Frontend
                           │
                           ▼
                   Amazon Cognito
                    Authentication
                           │
                           ▼
                     API Gateway
                           │
                           ▼
                Request Presigned URL
                           │
                           ▼
                  Upload directly to
                      Amazon S3
                           │
                           ▼
                    S3 ObjectCreated
                           │
                           ▼
                         SQS
                           │
                           ▼
                   Trigger Lambda
                           │
                           ▼
              AWS Step Functions
                    Express Workflow
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
           Textract      Bedrock       Python
             OCR        Nova Micro      Rules
              │            │            │
              └────────────┼────────────┘
                           │
                           ▼
                      Store Results
                           │
                  ┌────────┴────────┐
                  ▼                 ▼
              DynamoDB              S3
                  │                 │
                  └────────┬────────┘
                           ▼
                  Authenticated APIs
                           │
                           ▼
                    React Dashboard
                           │
                           ▼
                         USER
```

---

# PART 3 — THE 10-STEP END-TO-END FLOW

If I can explain these ten steps confidently, I understand the core project.

## Step 1 — User Authentication

The user opens the React application.

Amazon Cognito handles authentication.

The frontend uses AWS Amplify to interact with Cognito.

After login, the frontend retrieves the authenticated session/token.

Authenticated API calls include the token in the:

```text
Authorization
```

header.

API Gateway uses a Cognito authorizer to validate the identity.

The backend derives:

```text
tenant_id
```

from the validated Cognito:

```text
sub
```

claim.

### Remember

```text
Cognito = Who are you?
Authorization = What are you allowed to access?
```

Cognito authentication alone does NOT guarantee complete resource authorization.

---

## Step 2 — Request an Upload URL

The frontend does not send the invoice binary through Lambda.

Instead:

```text
React
  ↓
API Gateway
  ↓
Upload Lambda
  ↓
Generate Presigned S3 URL
```

The backend:

1. identifies the authenticated user,
2. generates an invoice ID,
3. creates a processing job,
4. creates a short-lived presigned S3 PUT URL,
5. returns the URL to the browser.

---

## Step 3 — Upload Directly to S3

The browser uploads the invoice directly to S3.

```text
Browser
   │
   │ Presigned PUT
   ▼
Private S3 Bucket
```

### Why?

Because we do not need:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

for a potentially large document.

Direct upload reduces unnecessary API/Lambda data transfer.

### Important

A presigned URL does NOT make the bucket public.

The bucket remains private.

---

## Step 4 — S3 Generates an Event

After the invoice is uploaded:

```text
S3 ObjectCreated
      ↓
     SQS
```

The event is placed onto Amazon SQS.

---

## Step 5 — SQS Buffers Processing

SQS separates ingestion from processing.

```text
Upload
   ↓
 SQS
   ↓
Processing
```

This gives the architecture asynchronous buffering.

### Important interview concept

SQS provides:

> **At-least-once delivery**

That means the same message may occasionally be delivered more than once.

Therefore:

> duplicate processing is possible.

This is why:

> **idempotency matters.**

---

## Step 6 — Trigger Lambda Starts Step Functions

The SQS event invokes a trigger Lambda.

The Lambda extracts information such as:

- tenant,
- invoice ID,
- S3 object information.

It then starts an **Express Step Functions workflow**.

Important:

The Lambda starts the workflow asynchronously.

---

## Step 7 — Step Functions Coordinates Processing

The actual repository workflow has **four main processing stages**:

```text
1. Textract
      ↓
2. Bedrock
      ↓
3. Python Risk Rules
      ↓
4. Store Results
```

Do NOT accidentally claim that a conceptual architecture diagram showing “Validate & Prepare” means there are five independently verified workflow states.

---

## Step 8 — Textract Extracts the Invoice

The application uses:

```text
Amazon Textract
AnalyzeExpense
```

Textract extracts invoice-related information such as:

- invoice number,
- vendor,
- dates,
- subtotal,
- tax,
- total,
- line items,
- raw OCR text.

### Textract's job

```text
DOCUMENT
   ↓
TEXT + STRUCTURED FIELDS
```

Textract does NOT perform the final Generative AI reasoning.

---

## Step 9 — Bedrock Performs AI Analysis

The application uses:

```text
Amazon Bedrock
      +
Amazon Nova Micro
```

Model ID:

```text
us.amazon.nova-micro-v1:0
```

The model receives:

```text
Structured invoice fields
        +
Line items
        +
Raw OCR text
```

The model does NOT directly receive the invoice image in the current implementation.

It is asked to return information such as:

```text
Anomalies
Severity
Description
Affected field
Summary
Confidence
```

---

## Step 10 — Python Rules Calculate the Score

The LLM does NOT independently calculate the complete numeric score.

The final numeric score is calculated using deterministic Python rules.

Then results are stored and displayed to the user.

---

# PART 4 — REMEMBER THE PROJECT WITH FIVE QUESTIONS

If I forget the architecture, remember:

```text
1. WHO IS THE USER?
   Cognito

2. WHERE IS THE DOCUMENT?
   S3

3. HOW IS PROCESSING COORDINATED?
   SQS + Step Functions

4. WHERE IS AI USED?
   Textract + Bedrock

5. WHERE ARE RESULTS?
   DynamoDB + S3 → React
```

---

# PART 5 — WHY EACH AWS SERVICE EXISTS

| Service | Why it exists |
|---|---|
| CloudFront | Delivers the frontend |
| S3 | Stores frontend assets, invoices, and extracted text |
| Cognito | Authenticates users |
| API Gateway | Provides authenticated HTTP APIs |
| Lambda | Executes backend/serverless logic |
| SQS | Buffers and decouples invoice processing |
| Step Functions | Orchestrates processing stages |
| Textract | Extracts invoice fields and OCR text |
| Bedrock | Provides foundation-model inference |
| Nova Micro | Performs text-based anomaly analysis |
| DynamoDB | Stores invoice and processing state |
| EventBridge | Routes business events |
| SNS | Supports notification delivery |
| CloudWatch | Logs and monitoring |
| X-Ray | Distributed tracing foundation |
| CDK | Defines AWS infrastructure as code |
| CloudFormation | Deploys infrastructure synthesized by CDK |

---

# PART 6 — THE MOST IMPORTANT ARCHITECTURE DECISIONS

## Why Serverless?

The workload is event-driven.

Resources are needed when:

- API requests occur,
- invoices arrive,
- workflows execute.

Managed AWS services reduce infrastructure-management work.

But:

> Serverless does NOT mean unlimited scalability.

We still need to think about:

- quotas,
- concurrency,
- retries,
- cost,
- observability,
- idempotency.

---

## Why SQS?

Without SQS:

```text
Upload → Immediately Process
```

With SQS:

```text
Upload
   ↓
Queue
   ↓
Process when consumer is ready
```

SQS provides:

- decoupling,
- buffering,
- retry behavior at the consumer boundary.

Trade-off:

- duplicate delivery is possible.

---

## Why Step Functions?

Without Step Functions:

```text
ONE LARGE LAMBDA

OCR
AI
Rules
Storage
Error handling
Retries
```

With Step Functions:

```text
Textract
   ↓
Bedrock
   ↓
Rules
   ↓
Storage
```

Benefits:

- explicit workflow,
- easier troubleshooting,
- stage visibility,
- retry/error-handling boundaries,
- separation of responsibilities.

---

## Why Textract + Bedrock?

Because they solve different problems.

```text
Textract
"What information is in this invoice?"

Bedrock
"What might be unusual about this information?"

Python Rules
"How should the system score the findings?"
```

This distinction is extremely important.

---

# PART 7 — GENERATIVE AI IN SIMPLE ENGLISH

## Where exactly is GenAI?

After Textract.

```text
Invoice
   ↓
Textract
   ↓
Extracted text
   ↓
Bedrock Nova Micro
   ↓
AI findings
```

Bedrock receives text, not the original invoice image in the current implementation.

---

# Prompt

The prompt asks Nova Micro to behave like an invoice auditor.

Input includes:

```text
Structured fields
Line items
Raw OCR text
```

Expected output includes:

```json
{
  "anomalies": [],
  "summary": "...",
  "confidence": 0.0
}
```

---

# Model Configuration

Current configuration includes approximately:

```text
maxTokens = 1500
temperature = 0.2
topP = 0.9
```

The application includes retry logic.

But remember:

```text
Low temperature ≠ guaranteed accuracy
Retry ≠ validation
JSON parsing ≠ schema validation
AI confidence ≠ measured accuracy
```

---

# PART 8 — AI OUTPUT VALIDATION

This is one of the project's important limitations.

The application tries to parse the model response.

Conceptually:

```text
AI Response
    ↓
Try JSON parse
    ↓
Failed?
    ↓
Remove Markdown fences
    ↓
Try again
    ↓
Failed?
    ↓
Extract {...}
    ↓
Try again
    ↓
Failed?
    ↓
Fallback response
```

But this only solves:

> “Can I parse this as JSON?”

It does NOT completely solve:

> “Is this JSON valid for my business?”

For example:

```json
{
  "anomalies": null,
  "confidence": 1000
}
```

may be JSON but still be invalid application data.

---

# Production Improvement

Use strict schema validation.

For example:

```text
LLM
 ↓
JSON Parse
 ↓
Pydantic Validation
 ↓
Business Validation
 ↓
Accept / Reject / Manual Review
```

---

# PART 9 — RISK SCORING

## Critical interview fact

The LLM does NOT calculate the complete final numeric score.

Python does.

---

# Current Formula

```text
Math discrepancy                         +40

Missing invoice number                    +8
Missing receipt date                      +8
Missing total                             +8
Missing vendor                            +8

Short numeric invoice number             +10

Repeated normalized item description     +15

AI HIGH anomaly                          +15
AI MEDIUM anomaly                         +7
AI LOW / unrecognized anomaly             +3
```

Maximum:

```text
100
```

Risk categories:

```text
0–29   → LOW
30–69  → MEDIUM
70–100 → HIGH
```

---

# Is 80 Equal to 80% Fraud Probability?

NO.

```text
Risk Score ≠ Probability
```

The score is:

> a heuristic review score.

It has not been calibrated as a fraud probability.

---

# Risk-Rule Limitations

The current financial rules have limitations.

Examples:

- OCR can provide incorrect input.
- tax may complicate arithmetic.
- discounts may complicate arithmetic.
- shipping may complicate arithmetic.
- negative values may be parsed incorrectly.
- repeated descriptions may be legitimate.
- AI and deterministic rules may detect the same issue.

---

# Double Counting

Example:

```text
Python:
Math discrepancy
+40

Bedrock:
HIGH anomaly — total mismatch
+15
```

Potentially:

```text
Same underlying issue
        ↓
Counted twice
```

Production improvement:

```text
Normalize findings
       ↓
Canonical categories
       ↓
Deduplicate correlated findings
       ↓
Calculate score
```

---

# PART 10 — DATA STORAGE

## S3

S3 stores object data.

Examples:

```text
Original invoices
Extracted text
Frontend assets
```

Processed text uses a path similar to:

```text
processed-text/{tenant_id}/{invoice_id}.txt
```

The current storage handler does NOT store complete OCR and AI JSON artifacts in the processed S3 bucket.

---

# DynamoDB

DynamoDB stores structured application state.

## Invoice Table

```text
Partition Key = tenant_id
Sort Key      = invoice_id
```

## Processing Jobs Table

```text
Partition Key = job_id
```

Remember:

```text
S3
= Objects

DynamoDB
= Application state
```

---

# TTL Limitation

The processing-jobs table has TTL configured on:

```text
ttl
```

But current job creation does not populate the attribute.

Therefore:

```text
TTL configured
      ≠
Jobs automatically expiring correctly
```

Production fix:

```text
Create job
   ↓
Calculate expiration
   ↓
Store ttl attribute
```

---

# PART 11 — AUTHENTICATION VS AUTHORIZATION

## Authentication

```text
User
 ↓
Cognito
 ↓
Identity
```

Question:

> Who are you?

---

## Authorization

Question:

> Are you allowed to access THIS invoice/job?

These are different.

---

# Authentication Flow

```text
React
 ↓
Amplify
 ↓
Cognito
 ↓
Token
 ↓
Authorization Header
 ↓
API Gateway Cognito Authorizer
 ↓
Validated claims
 ↓
sub
 ↓
tenant_id
```

---

# Current Tenant Model

Currently:

```text
tenant ≈ Cognito user
```

It is NOT currently a complete organization-level multi-tenant model with:

```text
Organization
 ├── Admin
 ├── Reviewer
 └── User
```

That could be a future enhancement if the business requires it.

---

# Important Security Gap

Processing-job ownership validation is incomplete in one status path.

Conceptually:

```text
User requests job status
        ↓
Job fetched
        ↓
Ownership must ALWAYS be verified
```

Production fix:

```text
Authenticated tenant
        =
Stored job tenant
```

before returning data.

---

# PART 12 — SQS, RETRIES, DLQ AND IDEMPOTENCY

This is one of the most important interview topics.

---

# SQS Delivery

SQS provides:

```text
AT-LEAST-ONCE
```

NOT:

```text
EXACTLY-ONCE
```

Therefore duplicate events are possible.

---

# What is Idempotency?

Simple definition:

> Running the same operation multiple times should not produce unintended duplicate effects.

Problem:

```text
Invoice Event
     ↓
Processing starts

Same event again
     ↓
Processing starts AGAIN
```

Potential duplicate:

- Textract call,
- Bedrock call,
- workflow,
- notifications,
- cost.

---

# Production V2 Idempotency

Use something like:

```text
Stable invoice/event ID
        ↓
DynamoDB conditional write
        ↓
Did I successfully claim processing?
       / \
     YES  NO
      │    │
      ▼    ▼
 Process  Stop
```

---

# Critical DLQ Interview Question

## Does the SQS DLQ catch a Textract failure?

**Not automatically.**

Why?

```text
SQS
 ↓
Trigger Lambda
 ↓
Start Step Functions
 ↓
Lambda successfully returns

--------------------------------
SQS responsibility largely ends
--------------------------------

Step Functions
 ↓
Textract FAILS
```

The original SQS message is not automatically sent back because of that later Textract failure.

Therefore:

> The SQS DLQ mainly protects the queue → trigger → workflow-start boundary.

Downstream workflow failures need:

- Step Functions error handling,
- failure-state persistence,
- alarms,
- possibly replay/recovery mechanisms.

---

# PART 13 — FRONTEND

The frontend uses technologies including:

```text
React
TypeScript
Vite
Tailwind CSS
AWS Amplify
React Query
Zustand
Axios
```

---

# Processing Status

Invoice processing is asynchronous.

The frontend therefore polls.

Approximately:

```text
Every 3 seconds
```

Conceptually:

```text
Upload
 ↓
PENDING
 ↓
PROCESSING
 ↓
COMPLETED / FAILED
```

---

# Frontend Limitation 1 — Stale Detail

Possible sequence:

```text
Upload invoice
      ↓
Detail request
      ↓
404 because result not ready
      ↓
Status eventually = COMPLETED
      ↓
Detail query remains stale
```

Production fix:

```text
Status becomes COMPLETED
        ↓
Invalidate detail query
        ↓
Refetch
```

---

# Frontend Limitation 2 — User Cache Isolation

Current query/cache state is not completely isolated by user identity.

Possible risk:

```text
User A logs in
 ↓
Data cached
 ↓
User A logs out
 ↓
User B logs in
 ↓
Old cached data could remain
```

Production fix:

```text
User-scoped query keys
+
Clear private state on logout/identity change
```

---

# PART 14 — EVENTBRIDGE AND SNS

The repository contains EventBridge and SNS infrastructure related to high-risk notifications.

Conceptually:

```text
High-risk result
      ↓
EventBridge
      ↓
SNS
      ↓
Subscriber
```

But:

> Complete end-to-end notification delivery is not fully verified.

Therefore say:

> “Notification infrastructure exists, but end-to-end delivery is partially implemented/unverified.”

Do NOT say:

> “Every high-risk invoice definitely sends an email.”

---

# PART 15 — INFRASTRUCTURE AS CODE

The project uses:

```text
AWS CDK
```

CDK defines infrastructure using code.

Then:

```text
CDK
 ↓
Synth
 ↓
CloudFormation Template
 ↓
CloudFormation
 ↓
AWS Resources
```

---

# Five CDK Stacks

Remember:

```text
StorageStack

AuthStack

ProcessingStack

ApiStack

FrontendStack
```

Important:

```text
5 stacks ≠ 5 microservices
```

Stacks are infrastructure organization boundaries.

---

# PART 16 — CI/CD

The repository contains GitHub Actions workflows for:

```text
Backend CI/CD

Frontend CI/CD

PR Checks
```

The workflow definitions also use GitHub OIDC for AWS authentication.

Concept:

```text
GitHub Actions
      ↓
OIDC
      ↓
Temporary AWS credentials
      ↓
Assume IAM role
```

This is preferable to storing long-lived AWS access keys.

But:

> Workflow files existing does NOT prove every current deployment succeeds.

Therefore say:

> “CI/CD workflow definitions exist; current operational success should be verified from workflow history.”

---

# PART 17 — OBSERVABILITY

Current foundations include:

```text
CloudWatch
X-Ray configuration
DLQ monitoring/alarm foundation
```

But do NOT claim:

> “We have complete production observability.”

Better:

> “The project has observability foundations that I would strengthen for production.”

---

# Troubleshooting Principle

Never randomly inspect AWS services.

Use:

> **LAST PROVEN STAGE**

Example:

```text
Was upload successful?
       ↓ YES

Did SQS receive event?
       ↓ YES

Did Lambda receive message?
       ↓ YES

Did Step Functions start?
       ↓ YES

Which state failed?
       ↓
Textract?
Bedrock?
Rules?
Storage?
```

This narrows the problem.

---

# PART 18 — TESTING

The repository analysis identified:

```text
44 unit-test functions
```

But the tests were NOT executed during that analysis.

An OCR test import defect was also identified.

Therefore NEVER say:

> “All 44 tests pass.”

Say:

> “The repository contains 44 unit-test functions, but I would verify the current execution results before claiming a passing test suite.”

---

# What Should Be Tested?

```text
Unit tests
      ↓
Integration tests
      ↓
AWS integration tests
      ↓
AI contract tests
      ↓
Security tests
      ↓
End-to-end tests
      ↓
Load tests
```

---

# AI Evaluation

Testing that the prompt runs is NOT enough.

We need a labeled dataset.

```text
Representative invoices
        ↓
Ground truth
        ↓
Textract
        ↓
Bedrock
        ↓
Compare result
```

Possible metrics:

- schema-valid response rate,
- false positives,
- false negatives,
- precision,
- recall,
- OCR extraction quality,
- fallback rate,
- latency,
- cost.

---

# PART 19 — BEDROCK FAILURE

This is an important interview question.

Some handled Bedrock failures can result in fallback analysis.

Then the pipeline may continue.

Therefore:

```text
Bedrock unavailable
       ↓
Fallback AI result
       ↓
Python rules
       ↓
Store
       ↓
COMPLETED
```

Problem:

```text
COMPLETED
```

may not necessarily mean:

```text
Every AI stage worked normally
```

---

# Production V2

Separate:

```text
PROCESSING STATUS

COMPLETED
FAILED
```

from:

```text
ANALYSIS QUALITY

FULL
DEGRADED
MANUAL_REVIEW_REQUIRED
```

This gives clearer business meaning.

---

# PART 20 — COST

Do NOT memorize an unverified dollar number.

Important cost drivers include:

```text
Textract
Bedrock
Lambda
Step Functions
DynamoDB
S3
API Gateway
CloudFront
CloudWatch
```

Also remember:

```text
Duplicate processing
      =
Duplicate expensive service calls
      =
Additional cost
```

Therefore:

> Idempotency is also a cost-control mechanism.

---

# Production Cost Metric

A useful future metric:

```text
Cost per successfully analyzed invoice
```

Do not claim a measured number until actual billing/workload data supports it.

---

# PART 21 — SCALABILITY

Do NOT say:

> “This supports 1 million users.”

unless tested.

Serverless services scale, but limits still exist.

Watch:

```text
Lambda concurrency
Textract quotas
Bedrock quotas
DynamoDB access patterns
SQS backlog
Step Functions payload size
API polling
Analytics queries
```

---

# Bedrock Rate-Limiter Limitation

The current limiter operates inside an individual warm Lambda environment.

Therefore:

```text
Lambda Instance A → limiter A
Lambda Instance B → limiter B
Lambda Instance C → limiter C
```

They do not automatically share one global rate counter.

That means application-level local rate limiting does not guarantee global Bedrock request control.

---

# PART 22 — DATA LIFECYCLE

Deleting an invoice currently does not guarantee complete deletion of every related artifact.

Possible remaining data includes:

```text
Processing job
Processed text
Historical S3 versions
Other related artifacts
```

Production V2 needs:

```text
Defined retention policy
        ↓
Complete deletion workflow
        ↓
Original object
Processed object
DynamoDB invoice
Processing job
Historical versions as required
```

---

# PART 23 — WHAT THIS PROJECT IS NOT

This is extremely important for interviews.

## NOT RAG

There is no verified:

```text
Embedding generation
Vector database
Semantic retrieval
Knowledge base
Retrieval-augmented prompt
```

Therefore:

> This project is NOT RAG.

---

## NOT Agentic AI

There is no autonomous agent deciding:

```text
Which tool should I use?
What action should I take next?
Should I call another agent?
```

Step Functions follows a predefined workflow.

Therefore:

> This project is NOT Agentic AI.

---

## NOT Custom ML Training

There is no:

```text
Custom model training
MLflow model registry
Training pipeline
Custom fraud classifier
```

The project uses managed AI services.

---

# PART 24 — CURRENT STRENGTHS

Current strengths include:

```text
✓ Serverless architecture

✓ Event-driven processing

✓ Direct S3 uploads

✓ Cognito authentication

✓ API Gateway authorization foundation

✓ SQS decoupling

✓ Step Functions orchestration

✓ Textract document extraction

✓ Bedrock Generative AI integration

✓ Deterministic Python risk scoring

✓ DynamoDB application state

✓ Infrastructure as Code

✓ GitHub Actions definitions

✓ CloudWatch/X-Ray foundations

✓ React dashboard
```

---

# PART 25 — CURRENT LIMITATIONS

The most important limitations to remember:

```text
1. Processing-job ownership gap

2. Browser cache isolation gap

3. Incomplete idempotency

4. SQS DLQ does not protect every downstream stage

5. Partial-batch failure configuration mismatch

6. Textract/OCR normalization limitations

7. Weak AI schema enforcement

8. AI failure can still result in COMPLETED

9. Heuristic score is not probability

10. Financial-rule simplifications

11. Possible AI + deterministic double counting

12. Job TTL attribute is not populated

13. Growing workflow payload

14. Frontend stale-detail behavior

15. Notification delivery not fully verified

16. CI/CD operation not fully verified

17. Test suite not verified as passing

18. No measured AI-quality benchmark

19. No verified load-test capacity

20. No verified production cost

21. Incomplete deletion lifecycle
```

---

# PART 26 — PRODUCTION V2

My Production V2 priorities:

```text
                    PRODUCTION V2

1. SECURITY
   │
   ├── Complete resource ownership checks
   ├── User-scoped browser cache
   └── Stronger authorization model if needed

2. CORRECTNESS
   │
   ├── Atomic idempotency
   ├── Financial normalization
   └── Finding deduplication

3. AI QUALITY
   │
   ├── Strict Pydantic/schema validation
   ├── Ground-truth evaluation dataset
   ├── Prompt regression testing
   └── Explicit degraded-analysis status

4. RELIABILITY
   │
   ├── Workflow failure handling
   ├── Replay/recovery
   └── Better alerting

5. DATA
   │
   ├── TTL fix
   ├── Artifact-pointer strategy
   └── Complete lifecycle/deletion

6. FRONTEND
   │
   ├── Correct query invalidation
   └── Cache isolation

7. DELIVERY
   │
   ├── Reproducible packaging
   ├── Verified CI/CD
   └── Automated integration testing

8. OPERATIONS
   │
   ├── Dashboards
   ├── SLOs
   ├── Load tests
   └── Cost measurement
```

---

# PART 27 — 30-SECOND PROJECT ANSWER

> “NovaMind AI is a serverless invoice intelligence application built on AWS. Users upload invoices directly to S3 using presigned URLs. SQS and Step Functions coordinate asynchronous processing, Textract extracts invoice information, Bedrock Nova Micro performs AI-assisted anomaly analysis, and deterministic Python rules calculate a heuristic risk score. Results are stored using DynamoDB and S3 and displayed through a React dashboard.”

---

# PART 28 — 1-MINUTE PROJECT ANSWER

> “NovaMind AI is a serverless, event-driven invoice intelligence application built on AWS.
>
> Users authenticate through Amazon Cognito and upload invoices from a React frontend using short-lived presigned S3 URLs.
>
> After an invoice reaches S3, an event goes to SQS. A trigger Lambda consumes the message and starts an Express Step Functions workflow.
>
> Textract extracts invoice fields and OCR text. Bedrock Nova Micro analyzes the extracted content for possible anomalies. Deterministic Python rules then calculate a heuristic risk score, and the results are persisted using DynamoDB and S3.
>
> The React frontend polls processing status and retrieves the completed result through authenticated APIs.
>
> I describe it as an invoice intelligence and review-support application rather than an autonomous fraud-detection system.”

---

# PART 29 — 2-MINUTE PROJECT ANSWER

> “My project is NovaMind AI, a serverless and event-driven invoice intelligence platform built on AWS.
>
> The purpose is to assist invoice reviewers by extracting structured information from invoice documents, identifying possible inconsistencies and prioritizing invoices that may require closer review.
>
> The frontend is built using React. Users authenticate through Amazon Cognito, and authenticated API requests go through API Gateway.
>
> For document upload, the backend generates a short-lived presigned S3 URL so the browser can upload directly to a private S3 bucket instead of proxying the document through Lambda.
>
> Once the invoice reaches S3, an ObjectCreated event is sent to SQS. A trigger Lambda consumes the message and starts an Express Step Functions workflow.
>
> The workflow contains four main processing stages. Textract extracts invoice fields and OCR text. Bedrock Nova Micro performs semantic anomaly analysis over that extracted information. Deterministic Python rules calculate a heuristic review score. Finally, the results are stored using DynamoDB and S3.
>
> Because processing is asynchronous, the frontend polls the processing status and retrieves the result when processing finishes.
>
> An important design principle is that the language model is not the sole business decision maker. AI produces findings, while deterministic Python logic calculates the numeric score.
>
> I consider the current system a production-oriented prototype rather than fully production-ready because areas such as idempotency, authorization, AI-output validation, financial normalization, frontend state isolation, testing and deployment reliability still need strengthening.”

---

# PART 30 — TOP 25 INTERVIEW QUESTIONS

---

## Q1. Tell me about your project.

### Word-by-word answer

> “NovaMind AI is a serverless, event-driven invoice intelligence application built on AWS. It allows authenticated users to upload invoices, extracts invoice information using Textract, analyzes the extracted content using Bedrock Nova Micro, applies deterministic Python risk rules, stores the results using DynamoDB and S3, and presents the analysis through a React dashboard.”

---

## Q2. Explain the architecture.

### Word-by-word answer

> “The frontend is React delivered through S3 and CloudFront. Cognito handles authentication, and API Gateway exposes authenticated APIs backed by Lambda. The browser uploads invoices directly to S3 using presigned URLs. S3 sends upload events to SQS, a Lambda starts an Express Step Functions workflow, and the workflow coordinates Textract, Bedrock Nova Micro, deterministic Python risk rules and result persistence. DynamoDB stores structured application state, S3 stores documents and extracted text, and the frontend retrieves the final result through authenticated APIs.”

---

## Q3. Why serverless?

### Word-by-word answer

> “The workload is event-driven and does not require continuously running application servers. Managed AWS services allow individual components to scale independently and reduce infrastructure-management work. However, I still need to manage service quotas, concurrency, retries, idempotency, observability and cost.”

---

## Q4. Why use a presigned S3 URL?

### Word-by-word answer

> “It allows the authenticated backend to grant temporary permission for a specific upload while the document moves directly from the browser to S3. This avoids proxying the invoice through API Gateway and Lambda and keeps the bucket private.”

---

## Q5. Why SQS?

### Word-by-word answer

> “SQS decouples ingestion from processing and provides buffering when processing cannot immediately keep up with incoming events. Because SQS provides at-least-once delivery, I also need to design for duplicate messages.”

---

## Q6. What is idempotency?

### Word-by-word answer

> “Idempotency means that processing the same logical request multiple times should not create unintended duplicate effects. It matters here because SQS may redeliver a message. For Production V2, I would use a stable idempotency key and an atomic DynamoDB conditional write before expensive processing begins.”

---

## Q7. Does the DLQ catch a Textract failure?

### Word-by-word answer

> “Not automatically. The SQS-trigger Lambda starts Step Functions asynchronously. Once the workflow successfully starts and the Lambda returns, a later Textract failure happens outside the original SQS retry boundary. The SQS DLQ mainly protects the queue-to-trigger and workflow-start handoff.”

---

## Q8. Why Step Functions?

### Word-by-word answer

> “Step Functions makes the multi-stage asynchronous workflow explicit. Instead of placing OCR, AI analysis, scoring, storage and error handling inside one large Lambda, I can separate responsibilities and observe the state transitions more clearly.”

---

## Q9. Textract vs Bedrock?

### Word-by-word answer

> “Textract extracts information from the invoice. Bedrock Nova Micro reasons over that extracted information and produces AI-assisted anomaly findings. Textract is the extraction layer and Bedrock is the semantic analysis layer.”

---

## Q10. Where is GenAI used?

### Word-by-word answer

> “Generative AI is used after OCR. Structured invoice fields, line-item information and raw OCR text are sent to Amazon Nova Micro through Bedrock. The model returns possible anomaly findings, a summary and confidence information.”

---

## Q11. Does Bedrock receive the image?

### Word-by-word answer

> “No. In the current implementation, Nova Micro receives the structured values and OCR text produced from the Textract stage rather than the original invoice image.”

---

## Q12. Who calculates the risk score?

### Word-by-word answer

> “Deterministic Python rules calculate the final numeric score. Bedrock contributes AI findings that can add points according to severity, but the LLM itself does not independently determine the complete score.”

---

## Q13. Is the risk score a fraud probability?

### Word-by-word answer

> “No. It is a heuristic review score based on predefined rule weights and AI findings. It has not been statistically calibrated as a probability of fraud.”

---

## Q14. How do you validate AI output?

### Word-by-word answer

> “The current implementation performs several JSON-parsing recovery steps, but parsing is not the same as complete validation. Valid JSON can still contain an invalid schema or business values. For Production V2, I would enforce strict Pydantic or JSON-schema validation followed by business-level validation.”

---

## Q15. What happens if Bedrock fails?

### Word-by-word answer

> “Some handled Bedrock failures can produce a fallback analysis and allow deterministic scoring and storage to continue. The limitation is that the business job may still become COMPLETED even though AI analysis degraded. I would separate processing completion from analysis-quality status in Production V2.”

---

## Q16. How does authentication work?

### Word-by-word answer

> “The frontend uses Amplify with Cognito. After login, it retrieves the authenticated session and sends the token in the Authorization header. API Gateway validates the token through a Cognito authorizer, and the backend derives the tenant identity from the validated Cognito sub claim.”

---

## Q17. What is the biggest security gap?

### Word-by-word answer

> “One important gap is processing-job ownership validation. A status fallback can retrieve a job by invoice-derived job ID without independently comparing the stored tenant with the requester. I would enforce resource ownership on every lookup.”

---

## Q18. Why S3 and DynamoDB?

### Word-by-word answer

> “S3 stores object data such as original invoices and extracted text. DynamoDB stores structured application state such as invoices, processing jobs, status and risk results. They solve different storage problems.”

---

## Q19. How does the frontend know processing finished?

### Word-by-word answer

> “The frontend polls processing status approximately every three seconds. When the job reaches a terminal state, polling stops. One current limitation is that successful completion does not reliably invalidate the existing detail query, which can leave stale UI state.”

---

## Q20. How did you define infrastructure?

### Word-by-word answer

> “The infrastructure is defined using AWS CDK and organized into StorageStack, AuthStack, ProcessingStack, ApiStack and FrontendStack. CDK synthesizes CloudFormation templates, and CloudFormation performs the underlying AWS resource deployment.”

---

## Q21. How do you monitor the application?

### Word-by-word answer

> “The project has CloudWatch logging, X-Ray configuration and monitoring foundations. When troubleshooting, I follow the request through S3, SQS, Lambda, Step Functions, Textract, Bedrock, persistence and frontend retrieval using the last successfully verified stage.”

---

## Q22. How did you test the project?

### Word-by-word answer

> “The repository analysis identified 44 unit-test functions, but those tests were not executed during the analysis and an OCR test import defect was identified. Therefore, I would verify current test execution before claiming a passing suite. Production testing should also include integration, end-to-end, security, AI-evaluation and load tests.”

---

## Q23. Is this RAG?

### Word-by-word answer

> “No. The project does not have a retrieval pipeline, embeddings, a vector database or a knowledge base. Nova Micro analyzes information extracted from the current invoice, so this is Generative AI analysis rather than RAG.”

---

## Q24. Is this Agentic AI?

### Word-by-word answer

> “No. The processing sequence is predefined by Step Functions. The model does not autonomously select tools or decide which workflow stage should execute next, so I would not describe the current system as Agentic AI.”

---

## Q25. Is it production-ready?

### Word-by-word answer

> “I describe it as a substantial production-oriented prototype rather than a fully production-ready system. The main processing path is implemented, but I would still strengthen resource authorization, idempotency, AI-output validation, financial correctness, frontend state isolation, notification verification, automated testing, deployment reproducibility, observability and load testing before making a full production-readiness claim.”

---

# PART 31 — PRESSURE QUESTIONS

These answers should become natural.

---

## “SQS guarantees exactly-once processing, right?”

> “No. Standard SQS provides at-least-once delivery, so duplicate delivery is possible. The application must design for idempotency.”

---

## “LOW means the invoice is safe?”

> “No. LOW only means the current heuristic accumulated fewer than 30 points. It is not proof that the invoice is legitimate.”

---

## “AI confidence 95% means 95% accurate?”

> “No. Model-generated confidence is not measured accuracy. Accuracy requires evaluation against ground truth.”

---

## “Cognito means your data isolation is secure?”

> “Not automatically. Cognito establishes identity, but the application still has to enforce resource-level authorization on every sensitive lookup.”

---

## “Your DLQ catches every failure?”

> “No. The ingestion DLQ mainly covers the SQS consumer and workflow-start boundary. Later Step Functions failures need their own error handling and monitoring.”

---

## “Your CI/CD works automatically?”

> “The repository contains CI/CD workflow definitions, but I would verify current GitHub Actions execution history before claiming that every deployment currently succeeds.”

---

## “How much does it cost?”

> “I do not have a verified production cost from measured billing data. I would calculate cost using representative workloads and measure cost per successfully analyzed invoice.”

---

## “How many users can it support?”

> “I don't have a verified maximum-user number because that requires representative load testing and service-quota measurements.”

---

## “Why didn't you use Kubernetes?”

> “The current workload fits managed serverless services well. Adding Kubernetes would increase operational complexity without a demonstrated requirement.”

---

## “Why didn't you use RAG?”

> “The task analyzes the contents of the currently uploaded invoice. It does not currently require retrieval from an external knowledge corpus, so RAG would not solve a demonstrated requirement.”

---

# PART 32 — TROUBLESHOOTING SCENARIOS

---

## Scenario 1 — Invoice Uploaded but Stuck

My troubleshooting:

```text
1. Verify S3 object exists

2. Check SQS

3. Check queue backlog / DLQ

4. Check trigger Lambda logs

5. Verify Step Functions execution started

6. Inspect execution history

7. Find failed stage

8. Check Textract / Bedrock / rules / storage

9. Verify API state

10. Verify frontend polling/cache
```

---

## Scenario 2 — Bedrock Returns Invalid JSON

```text
Check raw model response
      ↓
Check parser
      ↓
Check retry/fallback
      ↓
Do NOT blindly trust parsed data
      ↓
Production fix:
strict schema validation
```

---

## Scenario 3 — Duplicate SQS Message

```text
Same invoice
   ↓
Second event
   ↓
Could start second workflow
   ↓
Duplicate expensive calls
```

Production:

```text
Atomic idempotency claim
```

---

## Scenario 4 — Backend COMPLETED, UI Blank

Check:

```text
Status API
   ↓
Detail API
   ↓
React Query cache
   ↓
Was detail query invalidated?
```

Likely improvement:

```text
COMPLETED
   ↓
Invalidate detail query
   ↓
Refetch
```

---

## Scenario 5 — Another User Can Query Job Status

Check:

```text
Authenticated tenant
        ↓
Requested job
        ↓
Stored tenant
```

Require:

```text
Authenticated tenant == stored tenant
```

before returning information.

---

# PART 33 — CURRENT VS PRODUCTION V2

```text
CURRENT
─────────────────────────────

Cognito authentication
Presigned upload
SQS
Step Functions
Textract
Bedrock
Python rules
DynamoDB
S3
React
CDK
CloudWatch/X-Ray foundations


PRODUCTION V2
─────────────────────────────

Complete resource authorization
Atomic idempotency
Server-side document validation
OCR confidence handling
Financial normalization
Strict AI schema validation
Finding deduplication
Degraded-analysis state
Complete lifecycle deletion
Verified notification delivery
Reproducible Lambda builds
Verified CI/CD
Integration tests
Security tests
AI evaluation dataset
Load testing
Cost measurement
Operational dashboards
```

---

# PART 34 — THINGS I MUST NOT SAY

Do NOT say:

```text
❌ “This is RAG.”

❌ “This is Agentic AI.”

❌ “SQS gives exactly-once processing.”

❌ “The DLQ catches every processing failure.”

❌ “LOW risk means safe.”

❌ “The score is fraud probability.”

❌ “AI confidence is model accuracy.”

❌ “All 44 tests pass.”

❌ “CI/CD is fully operational.”

❌ “High-risk email definitely works.”

❌ “The application is fully production-ready.”

❌ “It costs exactly $X per month.”

❌ “It supports X million users.”
```

unless I have new evidence proving the claim.

---

# PART 35 — THINGS I SHOULD SAY

Good interview language:

> “The current implementation…”

> “The repository demonstrates…”

> “That is partially implemented.”

> “I would not claim that without runtime evidence.”

> “That is one of the limitations I identified.”

> “For Production V2, I would…”

> “The trade-off is…”

> “That service solves…”

> “I would verify that through…”

> “I don't have measured data supporting that number.”

These answers demonstrate engineering judgment.

---

# PART 36 — MY PROJECT STORY FRAMEWORK

For almost every project question:

```text
WHAT?
 ↓
WHY?
 ↓
HOW?
 ↓
WHY THIS DESIGN?
 ↓
WHAT CAN FAIL?
 ↓
HOW DO I TROUBLESHOOT?
 ↓
WHAT IS THE CURRENT LIMITATION?
 ↓
HOW WOULD I IMPROVE IT?
```

---

# PART 37 — FIVE SENTENCES I MUST KNOW

If I remember nothing else, remember these:

### 1

> “NovaMind AI is a serverless, event-driven invoice intelligence application built on AWS.”

### 2

> “Textract extracts invoice information, while Bedrock Nova Micro performs semantic AI-assisted anomaly analysis.”

### 3

> “The numeric risk score is calculated by deterministic Python rules and is a heuristic review score, not a fraud probability.”

### 4

> “SQS provides at-least-once delivery, so complete idempotency is an important Production V2 improvement.”

### 5

> “I consider the current system a production-oriented prototype rather than fully production-ready.”

---

# PART 38 — 10-SECOND ARCHITECTURE MEMORY

Say this:

```text
React
→ Cognito
→ API
→ S3
→ SQS
→ Step Functions
→ Textract
→ Bedrock
→ Python
→ DynamoDB/S3
→ React
```

Then expand each service when asked.

---

# PART 39 — FINAL REVISION METHOD

Do NOT read all 25 files every day.

Use this guide.

---

## Revision Pass 1 — Architecture

I should explain:

```text
Project purpose
Architecture
10-step flow
Why each service exists
```

---

## Revision Pass 2 — AI

I should explain:

```text
Textract
Bedrock
Prompt
Output parsing
Validation
Risk scoring
AI limitations
```

---

## Revision Pass 3 — Production

I should explain:

```text
SQS
DLQ
Idempotency
Security
Testing
CI/CD
Observability
Scaling
Cost
Production V2
```

---

## Revision Pass 4 — Interview

Practice:

```text
30-second story

1-minute story

2-minute story

Top 25 questions

Pressure questions

Troubleshooting
```

---

# PART 40 — WHEN SHOULD I OPEN THE OTHER 25 FILES?

Only when I find a weakness.

Example:

```text
Interviewer:
"What does idempotency mean?"

I struggle.
      ↓
Open:
07-SQS-DLQ-Retries-and-Idempotency.md
      ↓
Study that concept
      ↓
Close file
      ↓
Explain again
```

Another example:

```text
I struggle with Bedrock
      ↓
Open:
10-Amazon-Bedrock-Nova-Micro-and-Prompting.md
11-AI-Output-Validation-and-Evaluation.md
```

Another:

```text
I struggle with security
      ↓
Open:
05-Cognito-Authentication-and-User-Isolation.md
19-Security-and-Data-Lifecycle.md
```

The 25 files are:

> **Reference material**

This file is:

> **Revision material**

---

# PART 41 — FINAL INTERVIEW PRACTICE SYSTEM

Once I understand this guide:

```text
NO NOTES
   ↓
ChatGPT asks ONE question
   ↓
I answer aloud / type answer
   ↓
ChatGPT evaluates:

Technical accuracy
Architecture understanding
Project evidence
Clarity
Structure
Overclaiming
Missing concepts

   ↓
ChatGPT gives improved answer
   ↓
Pressure follow-up
   ↓
I answer again
   ↓
Weak concept?
   ↓
Open ONLY relevant detailed file
```

---

# PART 42 — MOCK INTERVIEW LEVELS

## Level 1 — Basic

Questions:

```text
What is your project?
What problem does it solve?
Explain architecture.
Why AWS?
Why serverless?
```

---

## Level 2 — Technical

Questions:

```text
Why SQS?
Why Step Functions?
Textract vs Bedrock?
How is risk calculated?
How is authentication implemented?
Why DynamoDB?
```

---

## Level 3 — Advanced

Questions:

```text
How do you handle duplicate SQS messages?
What is your DLQ boundary?
How do you validate LLM output?
What happens if Bedrock fails?
How do you enforce tenant isolation?
```

---

## Level 4 — Pressure

Questions:

```text
Show me where RAG is implemented.

Show me the autonomous agent.

Prove your score is a fraud probability.

Prove your tests pass.

Prove email alerts work.

Prove CI/CD is currently operational.

Show me your load-test result.

Show me your actual production cost.
```

The correct answer is sometimes:

> “That is not currently verified.”

That is better than inventing evidence.

---

# PART 43 — FINAL PROJECT CHEAT SHEET

```text
PROJECT
NovaMind AI Invoice Intelligence Platform


TYPE
Serverless + Event-driven + Generative AI


FRONTEND
React + TypeScript


AUTH
Cognito + Amplify


API
API Gateway + Lambda


UPLOAD
Presigned S3 PUT


INGESTION
S3 → SQS → Lambda


ORCHESTRATION
Express Step Functions


OCR
Textract AnalyzeExpense


GENAI
Amazon Bedrock
Amazon Nova Micro

Model:
us.amazon.nova-micro-v1:0


AI INPUT
Structured fields
Line items
Raw OCR text


AI OUTPUT
Anomalies
Severity
Descriptions
Summary
Confidence


RISK
Deterministic Python rules


RISK LEVELS
0–29   LOW
30–69  MEDIUM
70–100 HIGH


DATABASE
DynamoDB


INVOICE KEY
PK = tenant_id
SK = invoice_id


JOB KEY
PK = job_id


OBJECT STORAGE
S3


PROCESSED TEXT
processed-text/{tenant_id}/{invoice_id}.txt


INFRASTRUCTURE
AWS CDK


CDK STACKS
StorageStack
AuthStack
ProcessingStack
ApiStack
FrontendStack


CI/CD
GitHub Actions definitions
OIDC


OBSERVABILITY
CloudWatch
X-Ray configuration


IMPORTANT SQS FACT
At-least-once delivery


IMPORTANT DLQ FACT
Does not automatically catch later
Textract/Bedrock/storage workflow failures


IMPORTANT AI FACT
Parsing ≠ validation


IMPORTANT SCORE FACT
Risk score ≠ fraud probability


IMPORTANT SECURITY FACT
Authentication ≠ complete authorization


IMPORTANT STATUS FACT
COMPLETED ≠ AI definitely succeeded normally


NOT RAG
NOT Agentic AI
NOT custom ML training


MATURITY
Production-oriented prototype
with important Production V2 gaps
```

---

# PART 44 — FINAL SELF-TEST

Without looking above, answer:

### Question 1

What problem does NovaMind AI solve?

### Question 2

Explain the architecture from the browser to the final result.

### Question 3

Why do I use both Textract and Bedrock?

### Question 4

Why is SQS in the architecture?

### Question 5

Why is idempotency required?

### Question 6

Why doesn't the SQS DLQ automatically catch a Textract failure?

### Question 7

Who calculates the numeric risk score?

### Question 8

Why isn't the risk score a fraud probability?

### Question 9

What is the biggest authorization weakness?

### Question 10

What would I change for Production V2?

If I cannot answer one:

```text
DO NOT memorize the answer.

Find the relevant detailed .md file.
Understand the concept.
Come back.
Answer again.
```

---

# FINAL MENTAL MODEL

The entire project can be reduced to:

```text
UPLOAD
  ↓
QUEUE
  ↓
ORCHESTRATE
  ↓
EXTRACT
  ↓
ANALYZE
  ↓
SCORE
  ↓
STORE
  ↓
DISPLAY
```

AWS mapping:

```text
UPLOAD       = Presigned S3
QUEUE        = SQS
ORCHESTRATE  = Step Functions
EXTRACT      = Textract
ANALYZE      = Bedrock Nova Micro
SCORE        = Python Rules
STORE        = DynamoDB + S3
DISPLAY      = React
```

Security surrounds the flow:

```text
Cognito + API Gateway + IAM
```

Operations surround the flow:

```text
CloudWatch + X-Ray + CI/CD + Testing
```

Production engineering strengthens the flow:

```text
Authorization
Idempotency
Validation
Failure Handling
Observability
Testing
Scaling
Cost Control
Data Lifecycle
```

---

# FINAL RULE

I do not need to memorize 25 files.

I need to understand:

> **What happens, why it happens, what can fail, and how I would improve it.**

The detailed files are there when I need depth.

The Master Revision Guide is there for daily revision.

The mock interview is where I prove that I actually understand the project.

---

# NEXT STEP

After studying this guide, close all notes.

Then start the real mock interview with:

> **“Start my NovaMind AI mock interview. Ask me one question at a time. Do not show me the answer before I answer. Challenge me with follow-up questions like a real AWS Generative AI interviewer.”**