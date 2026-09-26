# Your question

**Start `04-Technology-Stack-and-Codebase.md`.**

Files 01–03 answered:

**What is the project? → What is the architecture? → How does one invoice travel through the system?**

Now File 04 answers:

> **What technologies make this project work, what responsibility does each technology have, and where should I look in the codebase when an interviewer asks, “Where did you implement that?”**

This file is important because knowing an architecture diagram is not enough. You need to connect:

**Technology → Purpose → Project implementation → Code → AWS service.**

---

# 04 — Technology Stack and Codebase

![Technology Stack and Codebase](images\technology-stack-and-codebase.png)

## 1. What Will I Learn?

In this file, I will understand:

- The project's technology stack
- Frontend technologies
- Backend technologies
- AWS services
- Infrastructure as Code
- Storage technologies
- AI/document-processing technologies
- Monitoring technologies
- CI/CD tooling
- Why each technology exists
- How the repository is logically organized
- The difference between application code and infrastructure code
- How to trace an interview question back to implementation
- Which technologies are **not** part of this project

According to the Codex inspection, this repository contains a React frontend, Python Lambda backend, five AWS CDK stacks, eight application Lambda functions, tests, and GitHub Actions workflow definitions. :chatgpt-content-reference{index="0"}

---

# 2. Technology Stack at a Glance

The easiest way to understand the stack is by responsibility.

| Layer | Main Technology |
|---|---|
| Frontend | React |
| Frontend language/tooling | TypeScript / JavaScript ecosystem |
| Frontend delivery | Amazon S3 + CloudFront |
| Authentication | Amazon Cognito |
| API | Amazon API Gateway |
| Backend compute | AWS Lambda |
| Backend language | Python |
| File storage | Amazon S3 |
| Queue | Amazon SQS |
| Workflow orchestration | AWS Step Functions |
| Invoice extraction | Amazon Textract |
| Generative AI | Amazon Bedrock — Nova Micro |
| Business/risk logic | Python |
| Application database | Amazon DynamoDB |
| Events/notifications | EventBridge + SNS |
| Monitoring | CloudWatch |
| Tracing | AWS X-Ray |
| Infrastructure as Code | AWS CDK / CloudFormation |
| CI/CD definitions | GitHub Actions |

Don't memorize this table.

Understand **why every row exists**.

---

# 3. The Most Important Mental Model

Think of your stack like this:

```text
┌──────────────────────────────┐
│ PRESENTATION                 │
│ React                        │
│ S3 + CloudFront              │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ ACCESS                       │
│ Cognito                      │
│ API Gateway                  │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ COMPUTE / ORCHESTRATION      │
│ Lambda                       │
│ SQS                          │
│ Step Functions               │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ DOCUMENT + AI               │
│ Textract                     │
│ Bedrock Nova Micro           │
│ Python Rules                 │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ DATA                         │
│ S3                           │
│ DynamoDB                     │
└──────────────┬───────────────┘
               ↓
┌──────────────────────────────┐
│ OPERATIONS                   │
│ CloudWatch                   │
│ X-Ray                        │
│ CDK                          │
│ GitHub Actions               │
└──────────────────────────────┘
```

Now let's understand each layer.

---

# 4. Frontend — React

The user interacts with a **React web application**.

Its responsibility is mainly:

```text
Display UI
   +
Accept user actions
   +
Call backend APIs
   +
Upload invoices
   +
Poll processing status
   +
Display results
```

For example:

```text
User clicks Upload
        ↓
React handles action
        ↓
React calls backend
        ↓
Gets presigned URL
        ↓
Uploads invoice
```

React does **not** perform:

```text
❌ OCR
❌ Bedrock inference
❌ Final backend risk processing
❌ Step Functions orchestration
```

Those belong to the backend/AWS processing layers.

---

# 5. Why React?

React is useful for building an interactive web interface.

Your application needs screens and states such as:

```text
Login

Dashboard

Invoice Upload

Processing Status

Invoice List

Invoice Details

Risk Findings

Analytics
```

Those aren't simply static HTML pages.

The UI changes according to application data.

Conceptually:

```text
Backend status = PROCESSING
        ↓
React displays
"Processing invoice..."


Backend status = COMPLETED
        ↓
React displays
Invoice results
```

We'll study frontend state and polling deeply in File 15.

---

# 6. Frontend Hosting — S3 + CloudFront

After the React application is built, its static assets can be hosted from S3.

Conceptually:

```text
React source code
      ↓
Build
      ↓
HTML + CSS + JS
      ↓
Amazon S3
      ↓
CloudFront
      ↓
User
```

Remember the difference:

**S3 = stores frontend files**

**CloudFront = delivers/caches those files closer to users**

This S3 usage is different from the S3 bucket used for invoice/document storage.

---

# 7. Authentication — Amazon Cognito

Cognito manages application authentication.

```text
User
 ↓
Username/password
 ↓
Cognito
 ↓
Authenticated user/token
```

The frontend can then use the authentication token when accessing protected APIs.

Think:

> **Cognito = identity/authentication layer.**

But don't say:

> “Because I use Cognito, my application has perfect tenant isolation.”

Codex found authorization/isolation gaps that we'll study in File 05. :chatgpt-content-reference{index="1"}

---

# 8. API Layer — Amazon API Gateway

API Gateway exposes HTTP APIs used by the React frontend.

Conceptually:

```text
React
 ↓
HTTP request
 ↓
API Gateway
 ↓
Lambda
```

Possible operations include:

```text
Generate upload URL

Get processing status

List invoices

Get invoice details

Delete invoice

Get analytics
```

API Gateway is therefore the **HTTP-facing entry point** for application backend operations.

---

# 9. Backend Language — Python

The serverless backend uses Python.

Python is used for responsibilities such as:

```text
Lambda handlers
AWS SDK calls
Processing logic
Data transformation
Risk/business rules
Bedrock interaction
Textract processing
Persistence logic
```

This is different from the frontend.

Simplified:

```text
Frontend
React / TypeScript
       ↓
     APIs
       ↓
Backend
Python / Lambda
```

---

# 10. AWS SDK — Boto3

Python Lambda functions need to communicate with AWS services.

For example:

```text
Python
 ↓
S3

Python
 ↓
DynamoDB

Python
 ↓
Step Functions

Python
 ↓
Bedrock
```

In Python AWS applications, this is commonly done using **Boto3**, the AWS SDK for Python.

Conceptually:

```python
import boto3

s3 = boto3.client("s3")
```

The important idea is not memorizing syntax.

Understand:

> **Boto3 lets Python application code call AWS service APIs.**

---

# 11. Backend Compute — AWS Lambda

Lambda runs backend code without requiring you to maintain a continuously running server.

Your repository contains multiple application Lambda functions rather than one giant backend function.

Codex identifies **eight application Lambda functions**. :chatgpt-content-reference{index="2"}

This is important.

Don't confuse:

```text
8 Lambda functions
```

with:

```text
5 CDK stacks
```

They are completely different concepts.

---

# 12. Why Multiple Lambda Functions?

Different functions can own different responsibilities.

Conceptually:

```text
Lambda A
Generate upload URL

Lambda B
Handle API operations

Lambda C
Start workflow

Lambda D
Process document

Lambda E
Analyze invoice

Lambda F
Calculate risk

Lambda G
Store results

...
```

The exact mapping should always follow the repository rather than this simplified teaching example.

The architectural principle is:

> **Separate responsibilities instead of putting the entire application into one huge function.**

---

# 13. Object Storage — Amazon S3

S3 has multiple responsibilities in the overall project.

Examples include:

```text
Frontend assets
Original invoice documents
Extracted text/artifacts
Analysis-related files
```

Think of S3 as:

> **Object storage.**

Don't think of S3 as the same thing as DynamoDB.

---

# 14. Database — Amazon DynamoDB

DynamoDB stores structured application records.

Conceptually:

```text
Invoice Record
├── invoice_id
├── user/tenant information
├── processing status
├── risk score
├── findings
└── metadata
```

and:

```text
Processing Job
├── job_id
├── status
├── invoice reference
└── timestamps
```

Codex identifies invoice/result records and processing job records as important DynamoDB data. :chatgpt-content-reference{index="3"}

Later, File 13 will answer:

> Why DynamoDB instead of an SQL database?

---

# 15. Queue — Amazon SQS

SQS provides the asynchronous queue.

```text
S3 Event
   ↓
  SQS
   ↓
Lambda Consumer
```

Its responsibilities include:

```text
Buffer work
Decouple components
Support retries
Support DLQ behavior
```

Think:

> **SQS stores work waiting to be processed.**

Not:

> **SQS permanently stores invoice business data.**

That is not its purpose.

---

# 16. Orchestration — AWS Step Functions

Step Functions coordinates the multi-stage invoice-processing workflow.

Think:

```text
Step Functions
      ↓
Which step runs now?
      ↓
What runs next?
      ↓
What if something fails?
```

Its role is **orchestration**.

That's different from Lambda.

```text
Step Functions
=
coordinates work

Lambda
=
executes application code
```

This distinction is a common interview question.

---

# 17. Document Intelligence — Amazon Textract

Textract extracts information from invoices.

```text
PDF / Image
     ↓
Textract
     ↓
Structured fields + text
```

The project uses Textract for invoice/document extraction rather than using an LLM as the primary OCR engine.

This separation is important:

```text
Textract
=
extract


Bedrock
=
analyze
```

---

# 18. Generative AI — Amazon Bedrock

Amazon Bedrock provides access to foundation models through a managed AWS service.

Your project uses:

**Amazon Nova Micro**

for Generative AI analysis.

Conceptually:

```text
Extracted invoice information
            ↓
        Prompt/context
            ↓
     Amazon Bedrock
            ↓
       Nova Micro
            ↓
       AI findings
```

Codex identifies Bedrock Nova Micro as the model used for the project's GenAI analysis. :chatgpt-content-reference{index="4"}

---

# 19. Bedrock vs Nova Micro

Do not confuse these.

Think:

```text
Amazon Bedrock
=
AWS managed Generative AI service/platform

Nova Micro
=
Foundation model being invoked
```

So a better explanation is:

> “The application uses Amazon Bedrock to invoke Amazon Nova Micro.”

rather than:

> “Bedrock is my model.”

---

# 20. Business Logic — Python Rules

The project contains deterministic Python risk/business logic.

This is important because the architecture is not:

```text
Invoice
 ↓
LLM
 ↓
Whatever the LLM says becomes final
```

Instead:

```text
Textract data
      +
AI findings
      ↓
Python rules
      ↓
Risk score
```

Codex states that deterministic rules generate the final numeric score. :chatgpt-content-reference{index="5"}

This is one of the project's strongest interview discussion points.

---

# 21. Eventing — Amazon EventBridge

EventBridge appears in the high-risk notification architecture.

Conceptually:

```text
High-risk result
       ↓
Event
       ↓
EventBridge
       ↓
Matching rule
       ↓
Target
```

In this project, the intended target path involves SNS.

But remember:

> The Codex analysis found this notification path incomplete/unverified.

So understand the technology without overstating implementation maturity. :chatgpt-content-reference{index="6"}

---

# 22. Notifications — Amazon SNS

SNS is intended to participate in high-risk invoice notifications.

Conceptually:

```text
EventBridge
     ↓
SNS Topic
     ↓
Subscriber
     ↓
Notification
```

Do not currently claim:

> “Every high-risk invoice definitely emails the finance team.”

The local evidence doesn't support that strong statement.

---

# 23. Monitoring — Amazon CloudWatch

CloudWatch is important for operations.

Think:

```text
Lambda
Step Functions
Application
AWS services
       ↓
CloudWatch
       ↓
Logs
Metrics
Alarms
```

When an invoice fails, CloudWatch becomes part of your troubleshooting toolkit.

For example:

```text
Invoice not processed
       ↓
Check trigger Lambda logs
       ↓
Check processing Lambda logs
       ↓
Check errors
```

We'll study this properly in File 20.

---

# 24. Distributed Tracing — AWS X-Ray

X-Ray helps with tracing requests or operations across distributed components where configured.

Conceptually:

```text
Request
 ↓
Component A
 ↓
Component B
 ↓
Component C
```

Tracing can help answer:

> “Where did the request spend time or fail?”

But don't automatically claim complete end-to-end tracing unless the repository/configuration supports it.

---

# 25. Infrastructure as Code — AWS CDK

Your infrastructure is defined using **AWS CDK**.

Instead of manually creating every AWS resource in the console:

```text
Click S3
Create bucket

Click Lambda
Create function

Click API Gateway
Create API
...
```

infrastructure is represented as code.

Conceptually:

```text
CDK code
   ↓
Synthesize
   ↓
CloudFormation
   ↓
AWS resources
```

This improves repeatability and version control.

---

# 26. The Five CDK Stacks

Codex identifies these five stacks:

```text
StorageStack

AuthStack

ProcessingStack

ApiStack

FrontendStack
```

:chatgpt-content-reference{index="7"}

At a high level:

### StorageStack

Storage/data-related resources.

### AuthStack

Authentication resources.

### ProcessingStack

Invoice-processing infrastructure.

### ApiStack

API-facing infrastructure.

### FrontendStack

Frontend hosting/delivery resources.

We'll inspect their dependencies more deeply in File 17.

---

# 27. AWS CDK vs CloudFormation

Another common interview confusion:

```text
CDK
≠
CloudFormation
```

but they're related.

Simplified:

```text
You write CDK
      ↓
CDK synthesizes
      ↓
CloudFormation template
      ↓
CloudFormation provisions AWS
```

So if an interviewer asks:

> “Are you using CloudFormation?”

A good conceptual answer is:

> “The infrastructure is defined using AWS CDK, which synthesizes CloudFormation templates that AWS uses to provision the resources.”

---

# 28. CI/CD — GitHub Actions

The repository contains GitHub Actions workflow definitions.

Conceptually:

```text
Developer
 ↓
Git push
 ↓
GitHub
 ↓
GitHub Actions
 ↓
Build / test / deployment workflow
```

But this project has an important evidence distinction:

```text
Workflow definitions exist
```

does **not automatically mean**:

```text
Live CI/CD has been verified working successfully
```

Codex marks the live operational state as unverified. :chatgpt-content-reference{index="8"}

This is exactly the kind of distinction interviewers appreciate.

---

# 29. Code vs Infrastructure

This distinction is extremely important.

## Application code

Answers:

> **What should the application do?**

Examples:

```text
Generate presigned URL

Parse invoice

Call Bedrock

Calculate score

Write record
```

## Infrastructure code

Answers:

> **What AWS resources should exist and how are they connected?**

Examples:

```text
Create S3 bucket

Create SQS queue

Create Lambda

Create DynamoDB table

Grant IAM permission

Configure event source
```

Therefore:

```text
Python Lambda code
=
application behavior


CDK
=
AWS infrastructure definition
```

---

# 30. Codebase Mental Map

At this stage, you don't need to memorize every filename.

Instead, build this mental map:

```text
PROJECT ROOT
│
├── Frontend
│   ├── React application
│   ├── UI components
│   ├── API communication
│   └── State/polling
│
├── Backend / Lambda Functions
│   ├── API logic
│   ├── Upload logic
│   ├── Workflow trigger
│   ├── Document processing
│   ├── AI processing
│   ├── Risk rules
│   └── Persistence
│
├── Infrastructure
│   └── AWS CDK
│       ├── StorageStack
│       ├── AuthStack
│       ├── ProcessingStack
│       ├── ApiStack
│       └── FrontendStack
│
├── Tests
│   └── Unit tests
│
└── GitHub Workflows
    └── CI/CD definitions
```

This is a **logical learning map**, not a claim that those are the literal folder names in every case.

For exact filenames, always follow the actual repository/Codex evidence.

---

# 31. How to Read the Project Like an Engineer

Suppose an interviewer asks:

> **“Where is your Bedrock implementation?”**

Don't answer only:

> “Amazon Bedrock.”

Think in layers:

```text
Question
   ↓
Which component?
   ↓
Bedrock analysis Lambda
   ↓
Which code?
   ↓
Python implementation
   ↓
Which AWS call?
   ↓
Boto3 / Bedrock Runtime
   ↓
What input?
   ↓
Extracted invoice context
   ↓
What output?
   ↓
AI findings
   ↓
Where does it go next?
   ↓
Risk/business logic
```

That's how we will gradually learn your codebase.

---

# 32. Technology Dependency Chain

Your technologies don't exist independently.

They form a chain:

```text
React
 ↓
Cognito + API Gateway
 ↓
Lambda
 ↓
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
Bedrock Nova Micro
 ↓
Python Rules
 ↓
S3 + DynamoDB
 ↓
API
 ↓
React
```

When studying a technology, always ask:

**What comes before it?**

**What does it receive?**

**What does it do?**

**What does it produce?**

**What comes after it?**

That is far more useful than memorizing definitions.

---

# 33. What Technologies Are NOT in This Project?

This is just as important.

According to the Codex analysis, don't claim this project currently uses:

```text
❌ LangChain
❌ LangGraph
❌ RAG
❌ Embeddings
❌ Vector database
❌ Bedrock Knowledge Bases
❌ Autonomous agents
❌ ML training pipeline
❌ MLflow
❌ Custom fraud ML model
```

Codex explicitly classifies RAG, vector storage, autonomous agents, and ML training as not present. :chatgpt-content-reference{index="9"}

Do not mix technologies from your other GenAI projects into this one.

---

# 34. Technology vs Responsibility Cheat Sheet

This is the most useful summary of File 04:

```text
React
→ User interface

CloudFront
→ Frontend delivery

S3
→ Files/object storage

Cognito
→ Authentication

API Gateway
→ HTTP API entry point

Lambda
→ Execute backend code

SQS
→ Queue / decouple processing

Step Functions
→ Orchestrate workflow

Textract
→ Extract invoice information

Bedrock
→ Managed GenAI access

Nova Micro
→ Foundation model

Python Rules
→ Deterministic checks/risk logic

DynamoDB
→ Application records

EventBridge
→ Event routing

SNS
→ Notifications

CloudWatch
→ Logs/metrics/alarms

X-Ray
→ Tracing

CDK
→ Infrastructure as Code

CloudFormation
→ AWS resource provisioning

GitHub Actions
→ CI/CD workflow definitions
```

---

# 35. Interview Preparation — 10 Questions

## Q1 — What technology stack did you use?

**Difficulty:** Basic

### Word-by-word practice answer

> “The frontend is built with React and is hosted using Amazon S3 and CloudFront. The backend uses Python-based AWS Lambda functions exposed through API Gateway, with Cognito for authentication. For asynchronous invoice processing, the application uses S3, SQS and Step Functions. Textract performs invoice extraction, and Amazon Bedrock with Nova Micro performs Generative AI analysis. Deterministic Python rules calculate the final risk score, while DynamoDB and S3 store application data and artifacts. The AWS infrastructure is defined using CDK, and the repository also contains GitHub Actions workflow definitions.”

---

# Q2 — What programming languages are used?

**Difficulty:** Basic

### Word-by-word practice answer

> “The frontend uses the React JavaScript and TypeScript ecosystem, while the serverless backend is primarily implemented in Python. Python is used for Lambda handlers, AWS service integration, invoice-processing logic, Generative AI interaction and deterministic business rules.”

---

# Q3 — Why did you use Python for the backend?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “Python fits the serverless processing requirements of the project and provides straightforward integration with AWS services through Boto3. In this project it is used for Lambda functions, document-processing logic, Bedrock integration, data transformation and deterministic risk rules. I would describe Python as an implementation choice that fits the workload rather than claiming it is always the best backend language.”

---

# Q4 — What is Boto3 and where do you use it?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Boto3 is the AWS SDK for Python. It allows Python code running in the Lambda functions to call AWS service APIs. In this type of project it is used to interact programmatically with services such as S3, DynamoDB, Step Functions, Textract and Bedrock rather than manually interacting with those services.”

---

# Q5 — What is the difference between Lambda and Step Functions?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Lambda executes application code, while Step Functions coordinates multiple processing stages. For example, a Lambda can perform a specific processing task, while Step Functions determines the sequence of those tasks and can manage workflow-level retry and error behavior. I use them together because execution and orchestration are different responsibilities.”

---

# Q6 — What is the difference between S3 and DynamoDB?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “S3 is object storage and is suitable for files such as uploaded invoice documents, extracted artifacts and frontend assets. DynamoDB is a NoSQL database used for structured application records such as invoice metadata, processing jobs, status information, findings and risk scores. They solve different storage problems.”

---

# Q7 — What is the difference between Textract, Bedrock and Nova Micro?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Textract is the document-intelligence service used to extract text and structured information from invoices. Amazon Bedrock is the managed AWS Generative AI service through which the application invokes a foundation model. Nova Micro is the specific foundation model used for the AI analysis. So Textract extracts the document information, Bedrock provides the model-access layer, and Nova Micro performs the Generative AI inference.”

---

# Q8 — Why didn't you use LangChain or LangGraph?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current project does not require LangChain or LangGraph for its implemented workflow. The processing sequence is predefined and is orchestrated using AWS Step Functions. Textract handles invoice extraction, Bedrock handles Generative AI inference, and Python implements the deterministic business logic. I would add an additional framework only if it solved a real orchestration or AI application requirement rather than adding it simply because it is popular.”

---

# Q9 — How is your codebase organized?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I think about the repository in separate responsibilities. There is a React frontend for the user interface, Python Lambda code for backend and invoice-processing behavior, AWS CDK code for infrastructure, tests for application behavior, and GitHub Actions workflow definitions for automation. On the infrastructure side, the project is divided into five CDK stacks: StorageStack, AuthStack, ProcessingStack, ApiStack and FrontendStack. This separation helps me distinguish application logic from infrastructure configuration.”

---

# Q10 — If an interviewer asks you to show where a feature is implemented, what would you do?

**Difficulty:** Advanced / Practical

### Word-by-word practice answer

> “I would first identify which architectural component owns that feature and then trace it to the relevant application and infrastructure code. For example, for invoice AI analysis I would identify the Lambda responsible for that stage, show the Python code that constructs the model request and calls Bedrock, then show the CDK configuration that provisions the function and grants the required permissions. I would also explain what data enters that component and where its output goes next. That demonstrates the connection between architecture and actual implementation rather than only showing a diagram.”

---

# 36. Interviewer Technology Drill

An interviewer may rapidly ask:

```text
Why React?
      ↓
Why S3?
      ↓
Why CloudFront?
      ↓
Why Cognito?
      ↓
Why API Gateway?
      ↓
Why Lambda?
      ↓
Why SQS?
      ↓
Why Step Functions?
      ↓
Why Textract?
      ↓
Why Bedrock?
      ↓
Why Nova Micro?
      ↓
Why Python rules?
      ↓
Why DynamoDB?
      ↓
Why CDK?
```

Don't answer:

> “Because AWS provides it.”

For every technology, eventually you should be able to answer:

```text
WHAT IS IT?
      ↓
WHAT PROBLEM DOES IT SOLVE?
      ↓
WHERE IS IT USED IN MY PROJECT?
      ↓
WHY DID WE NEED IT?
      ↓
WHAT DATA GOES IN?
      ↓
WHAT COMES OUT?
      ↓
WHAT ALTERNATIVE COULD WE USE?
      ↓
WHAT IS THE TRADE-OFF?
```

That's the level we're building toward.

---

# 37. What You Should Remember From File 04

Don't memorize all the AWS services.

Remember their **jobs**:

```text
React
= UI

Cognito
= Who are you?

API Gateway
= Backend HTTP entry

S3
= Store files

SQS
= Queue work

Lambda
= Run code

Step Functions
= Coordinate work

Textract
= Read invoice

Bedrock
= Access GenAI

Nova Micro
= Analyze invoice information

Python Rules
= Deterministic scoring

DynamoDB
= Store application records

CloudWatch
= Observe/troubleshoot

CDK
= Define infrastructure

GitHub Actions
= Automation workflow definitions
```

If you understand this mapping, you've understood the main purpose of File 04.

---

# 38. Check Your Understanding

Before we start `05-Cognito-Authentication-and-User-Isolation.md`, answer these **three questions in your own words**:

### Question 1

An interviewer says:

> **“You used many AWS services. Why didn't you just put everything inside one Lambda?”**

What would you say?

### Question 2

Explain the difference between:

> **Textract, Bedrock and Nova Micro**

as if you're explaining them to a beginner.

### Question 3

Suppose I point at the architecture and ask:

> **“Which parts are application code, and which parts are infrastructure?”**

How would you explain the difference?

Don't copy the word-by-word answers. Your own simple English is better at this stage.