# Your question

**Start `02-Current-Architecture.md` using the Current Architecture diagram we created.**

For this file, our goal changes from **“What is the project?”** to:

> **“What components make up the current system, how are they connected, and why is the architecture designed this way?”**

Save the architecture image as:

```text
learning/images/current_architecture.png
```

Then use the following as your `02-Current-Architecture.md`.

---

# 02 — Current Architecture

## 1. What Will I Learn?

In this file, I will understand:

- What architecture style this project uses
- What the major AWS components are
- How the frontend and backend communicate
- How an invoice enters the system
- Why S3, SQS and Step Functions are used
- How Textract and Bedrock fit into the architecture
- Where results are stored
- How authentication works at architecture level
- How monitoring, notifications and infrastructure are organized
- What parts are implemented, partial, or unverified
- How to explain this architecture confidently in an interview

The Codex analysis identifies the application as a **serverless, event-driven AWS application**, with infrastructure organized into five CDK stacks and eight application Lambda functions. :chatgpt-content-reference{index="0"}

---

# 2. Current Architecture Diagram

![NovaMind AI Invoice Intelligence Platform - Current Architecture](images\02-Current-Architecture.png)

**Figure: NovaMind AI Invoice Intelligence Platform — Current Architecture | Built by Aamir**

This diagram gives us the complete architecture map.

Do not try to memorize every service.

First understand the architecture as a few logical layers.

---

# 3. Architecture in One Sentence

The simplest description is:

> **NovaMind AI uses a serverless, event-driven AWS architecture where a React frontend uploads invoices directly to S3, SQS triggers asynchronous processing, Step Functions coordinates invoice-processing stages, Textract extracts invoice information, Bedrock Nova Micro analyzes it, Python rules calculate risk information, and the results are stored in S3 and DynamoDB and displayed back to the user.**

That is the architecture we will now break apart.

---

# 4. What Architecture Style Does the Project Use?

Two terms are especially important.

## Serverless architecture

The backend primarily uses managed AWS services such as:

```text
API Gateway
Lambda
S3
SQS
Step Functions
Textract
Bedrock
DynamoDB
```

You are not maintaining a traditional backend server such as:

```text
EC2
    ↓
Install OS
    ↓
Install Python
    ↓
Run backend continuously
```

Instead, AWS-managed services perform the backend work.

At a simple level:

```text
Traditional

Application
    ↓
Always-running server
    ↓
Backend


NovaMind

Request/Event
    ↓
AWS managed services
    ↓
Lambda/workflow executes when required
```

This is why **serverless** is an appropriate high-level description.

---

# 5. What Does Event-Driven Mean?

This is equally important.

Some parts of the application run because **an event occurs**.

For example:

```text
Invoice uploaded
       ↓
S3 event
       ↓
SQS message
       ↓
Lambda invoked
       ↓
Workflow starts
```

The processing system doesn't continuously ask:

> “Has someone uploaded an invoice yet?”

Instead, an event moves processing forward.

Therefore:

> **Event-driven architecture means components react to events occurring elsewhere in the system.**

In this project, invoice upload is an important event that begins asynchronous processing.

---

# 6. Architecture at the Highest Level

Before learning individual services, divide the architecture into these areas:

```text
┌──────────────────────────────┐
│ 1. USER / FRONTEND           │
│ React + S3 + CloudFront      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ 2. AUTHENTICATION / API      │
│ Cognito + API Gateway        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ 3. INGESTION                 │
│ Presigned URL + S3 + SQS     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ 4. PROCESSING                │
│ Lambda + Step Functions      │
│ Textract + Bedrock + Rules   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ 5. STORAGE                   │
│ S3 + DynamoDB                │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ 6. RESULTS                   │
│ API → React Dashboard        │
└──────────────────────────────┘
```

If you understand these six areas, the large architecture diagram becomes much easier.

---

# 7. Layer 1 — User and Frontend

The user interacts with a:

**React web application.**

At architecture level:

```text
User
 ↓
CloudFront
 ↓
S3-hosted React application
```

The frontend allows users to perform actions such as:

```text
Register/login
Upload invoice
Check processing status
View invoice details
View AI findings
View risk information
View analytics
Delete/manage invoices
```

### Responsibilities

The frontend is mainly responsible for:

**Presentation + user interaction + calling backend APIs.**

It should not perform OCR or AI processing itself.

---

# 8. Why S3 + CloudFront for the Frontend?

The compiled React application consists primarily of static assets.

For example:

```text
HTML
JavaScript
CSS
Images
```

Those can be stored in S3.

CloudFront distributes those frontend files to users.

Conceptually:

```text
             User
               ↓
          CloudFront
               ↓
       Frontend S3 Bucket
               ↓
        React Application
```

So CloudFront/S3 handle **frontend delivery**.

They are different from the invoice-processing S3 storage responsibilities.

---

# 9. Layer 2 — Amazon Cognito

Cognito handles user authentication.

Conceptually:

```text
User
 ↓
Login
 ↓
Amazon Cognito
 ↓
Authenticated identity/token
 ↓
Call protected APIs
```

This answers:

> **Who is the user?**

But there is an important distinction:

```text
Authentication
≠
Authorization
```

Authentication asks:

> “Who are you?”

Authorization asks:

> “What are you allowed to access?”

Codex found that user isolation is not completely perfect, so we will study this deeply in:

**`05-Cognito-Authentication-and-User-Isolation.md`**. :chatgpt-content-reference{index="1"}

---

# 10. Layer 2 — API Gateway

API Gateway acts as an entry point for backend API operations.

Conceptually:

```text
React
  ↓
API request
  ↓
API Gateway
  ↓
Authentication/authorization
  ↓
Backend Lambda
```

Examples include operations related to:

```text
Generate upload URL
Check processing status
Get invoices
Get invoice details
Delete invoice
Get analytics
```

So remember:

> **API Gateway exposes backend functionality to the frontend through HTTP APIs.**

---

# 11. Layer 3 — Presigned S3 Upload

This is an important architecture decision.

The invoice doesn't need to travel:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

Instead, the backend can provide a **presigned S3 URL**.

Then:

```text
React
   │
   │ Request upload URL
   ▼
API Gateway
   │
   │ Presigned URL
   ▼
React
   │
   │ Upload directly
   ▼
S3
```

This means the potentially large invoice file avoids unnecessary transfer through the application backend.

We'll study exactly how presigned URLs work in File 06.

---

# 12. Invoice S3 Bucket

The invoice is stored in Amazon S3.

Think of S3 here as **object storage**.

Examples:

```text
invoice-001.pdf
invoice-002.png
invoice-003.jpg
```

The important point:

> S3 stores invoice/document objects; DynamoDB stores structured application records.

Don't treat S3 and DynamoDB as interchangeable databases.

---

# 13. Layer 4 — S3 Event → SQS

After the invoice enters S3, asynchronous processing begins.

Conceptually:

```text
Invoice
   ↓
S3
   ↓
Object-created event
   ↓
SQS
```

SQS acts as a buffer between invoice ingestion and processing.

Instead of tightly coupling:

```text
Upload → immediately run everything
```

the architecture becomes:

```text
Upload
   ↓
Queue
   ↓
Process when consumer handles message
```

This is called **decoupling**.

---

# 14. Why SQS?

Imagine:

```text
1 invoice uploaded
```

No problem.

But imagine many invoices arrive close together.

Without buffering:

```text
Upload
 ↓
Processing
 ↓
Processing
 ↓
Processing
```

components can become tightly coupled.

With SQS:

```text
Invoices
 ↓ ↓ ↓ ↓ ↓
┌─────────────┐
│     SQS     │
│ Message     │
│ Message     │
│ Message     │
└──────┬──────┘
       ↓
    Consumer
```

SQS helps provide:

- asynchronous processing
- buffering
- loose coupling
- retry behavior

However:

> **SQS does not mean exactly-once processing.**

Codex specifically warns not to claim exactly-once behavior. :chatgpt-content-reference{index="2"}

We will study duplicates and idempotency in File 07.

---

# 15. Dead-Letter Queue

The architecture also contains a DLQ.

Think of it as a place for messages that repeatedly fail processing.

Simplified:

```text
SQS message
     ↓
Try processing
     ↓
Failure
     ↓
Retry
     ↓
Failure repeatedly
     ↓
DLQ
```

That prevents permanently failing messages from continuously cycling through normal processing.

But:

> A DLQ does not automatically solve every downstream failure in the application.

That distinction becomes important later.

---

# 16. Trigger Lambda

An SQS message invokes a Lambda responsible for starting the processing workflow.

Conceptually:

```text
SQS
 ↓
Trigger Lambda
 ↓
Start Step Functions execution
```

Its main job is not to perform the entire invoice analysis.

It acts as the bridge between:

**message ingestion**

and

**workflow orchestration**.

---

# 17. Layer 5 — AWS Step Functions

Step Functions coordinates the invoice-processing workflow.

Think of Step Functions as the **orchestrator**.

Instead of one huge Lambda:

```text
Lambda
 ├─ OCR
 ├─ AI
 ├─ Rules
 ├─ Storage
 ├─ Error handling
 └─ Retry logic
```

the work can be separated into stages.

Conceptually:

```text
        Step Functions
              │
              ▼
      Process Document
              │
              ▼
          Textract
              │
              ▼
           Bedrock
              │
              ▼
        Python Rules
              │
              ▼
        Store Results
```

Codex identifies the implemented workflow as orchestrating four main processing stages, while some diagrams/documentation may visually split preparation/validation into an additional conceptual step. :chatgpt-content-reference{index="3"}

This distinction matters: diagrams help learning, but the repository remains the source of truth.

---

# 18. Amazon Textract

Textract handles document extraction.

```text
Invoice PDF/Image
       ↓
Amazon Textract
       ↓
Extracted information
```

Examples:

```text
Vendor
Invoice number
Invoice date
Line items
Amounts
Total
Raw text
```

Textract's responsibility is primarily:

> **Read/extract information from the invoice.**

It is not responsible for your final business risk score.

---

# 19. Amazon Bedrock Nova Micro

Next comes Generative AI analysis.

```text
Extracted invoice information
             ↓
      Amazon Bedrock
             ↓
         Nova Micro
             ↓
        AI findings
```

The model can analyze extracted invoice information for possible anomalies/findings.

Remember:

**Textract = extraction**

**Bedrock = Generative AI analysis**

These are separate responsibilities.

---

# 20. Python Deterministic Rules

After AI analysis, deterministic business/risk logic is applied.

Conceptually:

```text
Extracted information
          +
AI findings
          ↓
Python deterministic rules
          ↓
Numeric risk score
          ↓
LOW / MEDIUM / HIGH
```

This means the architecture does **not** completely delegate financial decision logic to the LLM.

Codex specifically says deterministic rules produce the final numeric score. :chatgpt-content-reference{index="4"}

---

# 21. Store Results

After processing, the results need durable storage.

Your architecture uses:

```text
S3
+
DynamoDB
```

But for different purposes.

### S3

Used for object/file-oriented information such as:

```text
Original invoices
Extracted text/files
Analysis artifacts
Frontend static files
```

### DynamoDB

Used for application records such as:

```text
Invoice records
Processing jobs
Metadata
Risk scores
Status
Analytics-related information
```

At interview level:

> **S3 handles object storage, while DynamoDB provides structured NoSQL application data access.**

---

# 22. How Does the Result Return to the User?

An important concept:

The processing workflow doesn't simply keep an HTTP request open until all AI processing finishes.

The processing is asynchronous.

Conceptually:

```text
Upload invoice
      ↓
Processing begins asynchronously
      ↓
Frontend checks status
      ↓
Processing finishes
      ↓
Results stored
      ↓
Frontend retrieves result
```

The frontend currently uses polling/status requests.

We'll study that in:

**`15-Frontend-React-State-Polling-and-Analytics.md`**

---

# 23. Notifications

The architecture contains:

```text
High-risk result
      ↓
EventBridge
      ↓
SNS
      ↓
Notification
```

However, this requires an important warning.

The Codex analysis says notification infrastructure exists, but the wiring/delivery is **incomplete or unverified**. :chatgpt-content-reference{index="5"}

Therefore don't claim:

> “Every high-risk invoice automatically sends a confirmed email.”

Instead say:

> “The repository includes EventBridge and SNS infrastructure for high-risk notifications, but the Codex inspection found the end-to-end notification path incomplete or unverified.”

---

# 24. Monitoring and Observability

The architecture includes:

**Amazon CloudWatch**

and

**AWS X-Ray**

At a high level:

```text
Application
    ↓
CloudWatch
    ↓
Logs / Metrics / Alarms
```

and X-Ray can help with distributed tracing.

This becomes much more important when something fails somewhere inside:

```text
S3
 ↓
SQS
 ↓
Lambda
 ↓
Step Functions
 ↓
Textract
 ↓
Bedrock
 ↓
DynamoDB
```

We will study actual troubleshooting later rather than assuming that every observability feature is completely configured.

---

# 25. Infrastructure as Code

The project uses:

**AWS CDK**

which ultimately provisions AWS infrastructure through CloudFormation.

Codex identifies **five CDK stacks**:

```text
StorageStack
AuthStack
ProcessingStack
ApiStack
FrontendStack
```

:chatgpt-content-reference{index="6"}

This is an important architectural organization.

Instead of defining everything in one enormous infrastructure file, resources are grouped by responsibility.

We'll study this deeply in:

**`17-AWS-CDK-and-Infrastructure-as-Code.md`**

---

# 26. CI/CD

The repository contains GitHub Actions workflow definitions.

At a conceptual level:

```text
Developer
   ↓
GitHub
   ↓
GitHub Actions
   ↓
Build / Test / Deployment workflow
   ↓
AWS
```

But again, distinguish:

**workflow files exist**

from:

**verified live production CI/CD works successfully today**.

Codex says tests and CI/CD workflow files exist, but warns against claiming verified live CI/CD. :chatgpt-content-reference{index="7"}

---

# 27. Why Is This Architecture Asynchronous?

Imagine invoice processing requires:

```text
Upload
+
OCR
+
LLM inference
+
Rules
+
Storage
```

Those operations can take time.

Keeping one HTTP request waiting for the entire process would tightly couple the user request to backend processing.

Instead:

```text
User uploads
      ↓
Request finishes
      ↓
Background processing continues
      ↓
User checks status
      ↓
Result becomes available
```

This is one of the main architectural ideas you need to understand.

---

# 28. Five CDK Stacks vs Eight Lambda Functions

Don't confuse these.

A **CDK stack** is an infrastructure grouping.

A **Lambda function** is executable serverless compute.

So:

```text
5 CDK Stacks
≠
5 Lambda Functions
```

Codex found:

```text
Five CDK stacks
Eight application Lambda functions
```

:chatgpt-content-reference{index="8"}

The stacks provision and organize infrastructure; Lambda functions perform particular application responsibilities.

---

# 29. Current Architecture vs Proposed Architecture

This is another important interview rule.

When explaining your project, distinguish:

```text
CURRENT
```

from:

```text
FUTURE / PROPOSED
```

Do not add something to your current architecture simply because it would improve the system.

For example, if later we recommend additional security, better idempotency, stronger AI validation, improved alarms, or different event handling, those become:

> **Production V2 improvements**

not:

> **What my current system already does.**

---

# 30. Architecture Mental Model

If the large diagram feels difficult, memorize the **logic**, not the AWS icons:

```text
USER
 ↓
FRONTEND
 ↓
AUTHENTICATE
 ↓
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
RULES
 ↓
STORE
 ↓
DISPLAY
```

Then attach AWS services:

```text
USER
 ↓
React
 ↓
Cognito
 ↓
S3
 ↓
SQS
 ↓
Step Functions
 ↓
Textract
 ↓
Bedrock
 ↓
Python
 ↓
S3 + DynamoDB
 ↓
React
```

If you can explain **why each arrow exists**, you understand the architecture much better than someone who only memorized AWS service names.

---

# 31. Interview Preparation — 10 Questions

## Q1 — Explain the architecture of your project.

**Difficulty:** Basic

### Word-by-word practice answer

> “NovaMind AI uses a serverless, event-driven architecture on AWS. The frontend is a React application hosted using S3 and delivered through CloudFront. Cognito handles authentication, and API Gateway exposes the backend APIs. For invoice ingestion, the frontend receives a presigned URL and uploads the invoice directly to S3. The upload generates an event that is routed through SQS, and a Lambda starts the Step Functions workflow. The workflow coordinates invoice extraction using Textract, Generative AI analysis using Bedrock Nova Micro, deterministic Python risk rules, and result persistence. The results are stored in S3 and DynamoDB and later retrieved by the frontend.”

---

# Q2 — Why did you choose a serverless architecture?

**Difficulty:** Basic

### Word-by-word practice answer

> “The application is event-driven and its workload is naturally divided into independent processing stages. AWS managed services such as Lambda, S3, SQS, Step Functions and DynamoDB allow the application to execute processing when required without maintaining a continuously running application server. Serverless also fits well with asynchronous invoice processing. However, I would still evaluate service quotas, cold starts, execution limits and cost patterns before assuming serverless is the best solution at every scale.”

---

# Q3 — Why is this architecture event-driven?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “Invoice processing begins because events occur in the system. For example, after an invoice is uploaded to S3, an event results in a message being placed in SQS. That message invokes processing, which then starts the Step Functions workflow. This allows components to communicate without being tightly coupled to one synchronous request.”

---

# Q4 — Why upload directly to S3 instead of sending the invoice through Lambda?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The frontend uses a presigned S3 URL so the invoice can be uploaded directly to object storage. This avoids sending the entire file through API Gateway and Lambda unnecessarily. The backend controls the upload by generating a temporary presigned URL, while S3 handles the actual file transfer.”

---

# Q5 — Why is SQS needed between S3 and processing?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “SQS decouples invoice ingestion from downstream processing. If multiple invoices arrive, the queue can buffer messages rather than requiring all processing to happen immediately as part of the upload request. It also provides retry behavior and supports a dead-letter queue for messages that repeatedly fail. However, SQS provides at-least-once delivery, so the application still needs to consider duplicate processing and idempotency.”

---

# Q6 — Why use Step Functions instead of one large Lambda?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Invoice processing contains several separate responsibilities, including document extraction, Generative AI analysis, deterministic risk rules, and result storage. Step Functions allows those stages to be orchestrated as a workflow instead of putting all the logic inside one large Lambda. This makes the processing stages easier to separate, observe, retry and troubleshoot.”

---

# Q7 — What is the difference between Textract and Bedrock in your architecture?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Textract and Bedrock have different responsibilities. Textract extracts text and structured invoice fields from the uploaded document. Bedrock Nova Micro then analyzes that extracted information and generates possible anomaly findings. In simple terms, Textract extracts the information, while Bedrock performs Generative AI analysis on that information.”

---

# Q8 — What happens if many invoices are uploaded at the same time?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The architecture is asynchronous, so uploaded invoices create messages that can be buffered by SQS. Processing consumers handle those messages and start workflows independently. This provides better decoupling than processing every invoice synchronously during upload. However, I would not claim unlimited scalability. In production I would monitor queue depth, Lambda concurrency, Step Functions usage, Textract and Bedrock quotas, DynamoDB access patterns, throttling and actual processing latency.”

---

# Q9 — What happens if processing fails?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “The answer depends on where the failure occurs. SQS provides retry behavior for failures around message consumption, and a dead-letter queue exists for repeatedly failing messages. Step Functions can also define retry and catch behavior for workflow stages. However, the current repository does not provide complete automatic recovery for every downstream failure, so I would not claim that the architecture guarantees full recovery. I would first identify the failed stage using job state, Step Functions execution information and CloudWatch logs.”

---

# Q10 — What would you improve in this architecture for production?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “The current architecture has good serverless and event-driven foundations, but before calling it production-ready I would strengthen several areas. I would improve idempotency to handle duplicate processing safely, strengthen tenant authorization, validate AI output more strictly, improve financial-rule correctness, complete and verify the notification path, make Lambda packaging and deployment reproducible, expand integration and end-to-end testing, improve observability and alarms, and validate the architecture with real performance and cost measurements. I would make those improvements based on measured requirements rather than adding unnecessary AWS services.”

---

# 32. What You Must Be Able to Explain Before File 03

Before moving forward, you should eventually be able to explain this without looking:

```text
Why serverless?
Why event-driven?

React → what?
Cognito → why?
API Gateway → why?
Presigned URL → why?
S3 → why?
SQS → why?
Lambda → why?
Step Functions → why?
Textract → why?
Bedrock → why?
Python rules → why?
DynamoDB → why?
CloudWatch → why?
```

But **don't memorize all of those today**.

For now, I want to check whether the architecture itself makes sense.

## Your first two architecture questions

**Question 1:**  
An interviewer asks:

> **“A user uploads an invoice. Explain what happens from the browser until the final result is shown.”**

Explain it in your own simple English.

**Question 2:**  
Why do you think the project uses:

> **S3 → SQS → Lambda → Step Functions**

instead of processing the complete invoice directly when the user clicks **Upload**?

Answer these two in your own words. I’ll correct your understanding before we move to `03-End-to-End-Application-Flow.md`.