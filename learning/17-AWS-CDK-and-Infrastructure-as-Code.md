# Your question

**Create `17-AWS-CDK-and-Infrastructure-as-Code.md`.**

> I assume `7-AWS-CDK...` was a typo and you mean the next roadmap file: **`17-AWS-CDK-and-Infrastructure-as-Code.md`**.

# 17 — AWS CDK and Infrastructure as Code

## 1. What Will I Learn?

By the end of this file, I should understand:

- What Infrastructure as Code means
- Why manual AWS Console creation becomes difficult
- What AWS CDK is
- CDK vs CloudFormation
- What a CDK App, Stack and Construct are
- How my NovaMind AI infrastructure is organized
- Why my project uses **five CDK stacks**
- What each stack is responsible for
- Dependencies between stacks
- How CDK turns code into AWS infrastructure
- What `cdk synth`, `cdk diff`, `cdk deploy`, and `cdk destroy` mean
- Environment-specific configuration
- IAM and least privilege in IaC
- Resource references between stacks
- Deployment order
- CDK advantages and limitations
- Infrastructure code vs application code
- What I can accurately claim about this project's IaC
- How I would improve the IaC for production
- 10 project-specific interview questions with answers

---

# 2. First: What Problem Does Infrastructure as Code Solve?

Imagine building NovaMind AI manually.

You open the AWS Console and create:

```text
S3 buckets
↓
DynamoDB tables
↓
Cognito
↓
SQS
↓
DLQ
↓
Lambda functions
↓
Step Functions
↓
API Gateway
↓
EventBridge
↓
SNS
↓
CloudFront
↓
IAM permissions
```

Now imagine someone asks:

> “Can you create exactly the same environment again?”

You have to remember:

```text
Which bucket settings?

Which Lambda environment variables?

Which IAM permissions?

Which SQS configuration?

Which API routes?

Which CloudFront settings?

Which resources depend on which others?
```

Manual infrastructure becomes difficult to reproduce consistently.

That is one major problem **Infrastructure as Code** solves.

---

# 3. What Is Infrastructure as Code?

**Infrastructure as Code — IaC — means defining and managing infrastructure using code instead of manually creating every resource through the AWS Console.**

Instead of:

```text
Open Console
→ click
→ configure
→ click
→ create
```

we define infrastructure as code:

```text
Infrastructure Code
       ↓
AWS Deployment System
       ↓
AWS Resources
```

For NovaMind AI:

```text
CDK Code
   ↓
CloudFormation
   ↓
AWS Infrastructure
```

---

# 4. Simple Real-World Analogy

Imagine constructing five identical houses.

Without a blueprint:

```text
House 1 → manually decide everything
House 2 → manually remember House 1
House 3 → probably different
```

With a blueprint:

```text
Blueprint
   ↓
House 1
House 2
House 3
```

Infrastructure as Code works similarly.

The infrastructure code becomes a repeatable definition of the environment.

---

# 5. Why Is IaC Important for NovaMind AI?

This project isn't:

```text
React
+
one Lambda
```

It contains many AWS resources.

Conceptually:

```text
                    NovaMind AI
                         │
       ┌─────────────────┼─────────────────┐
       ▼                 ▼                 ▼
     Storage          Processing         API/Auth
       │                 │                 │
      S3                SQS              Cognito
   DynamoDB             Lambda           API Gateway
                     Step Functions
                       Textract
                       Bedrock
                         │
                         ▼
                    Frontend
                         │
                  S3 + CloudFront
```

Manually managing all those relationships would become error-prone.

---

# 6. What Is AWS CDK?

CDK stands for:

> **Cloud Development Kit**

Simple definition:

> **AWS CDK lets developers define AWS infrastructure using programming languages and then synthesizes that definition into AWS CloudFormation templates.**

Mental model:

```text
CDK Code
   ↓
cdk synth
   ↓
CloudFormation Template
   ↓
CloudFormation
   ↓
AWS Resources
```

This relationship is extremely important for interviews.

---

# 7. Does CDK Replace CloudFormation?

Not exactly.

A common mistake is saying:

> ❌ “I use CDK instead of CloudFormation.”

A better explanation is:

> **“I define the infrastructure using AWS CDK, and CDK synthesizes CloudFormation templates that CloudFormation uses to provision the AWS resources.”**

Think:

```text
Developer
   ↓
CDK
   ↓
CloudFormation
   ↓
AWS
```

---

# 8. Why Use CDK?

Raw CloudFormation can involve large declarative templates.

Conceptually:

```yaml
Resources:
  Bucket:
    Type: AWS::S3::Bucket
```

CDK lets you represent infrastructure using programming-language abstractions.

Conceptually:

```python
bucket = s3.Bucket(...)
```

The exact syntax depends on the language and project implementation.

The major idea is:

> **Infrastructure can be organized using normal software-development concepts.**

---

# 9. What Is a CDK App?

At the highest level:

```text
CDK App
```

contains one or more:

```text
Stacks
```

For example:

```text
CDK App
│
├── StorageStack
├── AuthStack
├── ProcessingStack
├── ApiStack
└── FrontendStack
```

Those are the five major stacks identified in your NovaMind AI repository analysis.

---

# 10. What Is a CDK Stack?

A **stack** is a deployable collection of related AWS resources.

For example:

```text
StorageStack
│
├── S3 resources
└── DynamoDB resources
```

while another stack can focus on:

```text
AuthStack
│
└── Authentication resources
```

This helps organize infrastructure by responsibility.

---

# 11. Why Not Put Everything in One Giant Stack?

Technically, many resources could be placed together.

But imagine:

```text
One Giant Stack
│
├── S3
├── DynamoDB
├── Cognito
├── API Gateway
├── 8 Lambdas
├── SQS
├── Step Functions
├── CloudFront
├── SNS
├── EventBridge
└── IAM
```

The infrastructure becomes harder to understand and maintain.

Instead, NovaMind AI separates major responsibilities.

```text
Storage

Authentication

Processing

API

Frontend
```

This provides clearer boundaries.

---

# 12. NovaMind AI — Five CDK Stacks

The repository analysis identified:

```text
1. StorageStack

2. AuthStack

3. ProcessingStack

4. ApiStack

5. FrontendStack
```

Memorize the **responsibilities**, not just the names.

---

# 13. Stack 1 — StorageStack

Think:

> **Where does persistent application data live?**

The storage layer supports things such as:

```text
S3
+
DynamoDB
```

which we studied in Files 13 and 14.

Conceptually:

```text
StorageStack
      │
      ├── S3
      │    ├── uploaded invoices
      │    └── processed artifacts
      │
      └── DynamoDB
           ├── invoice records
           └── processing jobs
```

The exact resource definitions should always be taken from the repository when discussing implementation details.

---

# 14. Stack 2 — AuthStack

Think:

> **Who is the user?**

This stack is responsible for authentication infrastructure centered around:

```text
Amazon Cognito
```

Conceptually:

```text
AuthStack
    ↓
Cognito
    ↓
User authentication
```

Recall the runtime flow:

```text
React
 ↓
Amplify
 ↓
Cognito
 ↓
Token
 ↓
API Gateway Authorizer
```

---

# 15. Stack 3 — ProcessingStack

This is the core asynchronous processing infrastructure.

Think:

```text
Invoice uploaded
       ↓
Processing Pipeline
```

This area includes infrastructure supporting the flow around:

```text
SQS
↓
Trigger Lambda
↓
Step Functions
↓
Processing Lambdas
↓
Textract
↓
Bedrock
↓
Risk Rules
↓
Storage
```

This is one of the most important stacks in the application because it connects many processing components.

---

# 16. Stack 4 — ApiStack

Think:

> **How does React communicate with backend application functionality?**

Conceptually:

```text
React
   ↓
API Gateway
   ↓
Backend Lambda
   ↓
DynamoDB / S3
```

This stack represents the application's API-facing infrastructure.

It also connects authentication to API access through Cognito authorization.

---

# 17. Stack 5 — FrontendStack

Think:

> **How is the React application delivered to the user?**

The project architecture uses:

```text
React Build
     ↓
S3
     ↓
CloudFront
     ↓
Browser
```

So the frontend infrastructure layer deals with hosting/distribution resources around:

```text
S3
+
CloudFront
```

---

# 18. Five-Stack Mental Model

Remember this:

```text
                  CDK APP
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
   Storage         Auth        Processing
      │              │              │
      │              │              │
      └──────────────┼──────────────┘
                     │
                     ▼
                    API
                     │
                     ▼
                  Frontend
```

Or simply:

```text
Storage
Auth
Processing
API
Frontend
```

---

# 19. Why Do Stacks Depend on Each Other?

These stacks are logically separated, but the application is connected.

For example:

```text
ProcessingStack
```

may need access to resources created by:

```text
StorageStack
```

because processing Lambdas need to read/write application data.

Similarly:

```text
ApiStack
```

needs authentication information from:

```text
AuthStack
```

and application resources from other layers.

Therefore:

> **Stack separation does not mean stack isolation.**

---

# 20. Example Dependency

Conceptually:

```text
StorageStack
     ↓
Creates DynamoDB Table
     ↓
ProcessingStack
     ↓
Lambda needs table access
```

The processing infrastructure needs:

```text
table reference
```

and appropriate:

```text
IAM permission
```

---

# 21. Another Dependency

```text
AuthStack
   ↓
Cognito User Pool
   ↓
ApiStack
   ↓
Cognito Authorizer
```

So API infrastructure depends on authentication infrastructure.

This affects deployment relationships.

---

# 22. Dependency Graph

Think about infrastructure as a graph:

```text
StorageStack ──────────┐
                      │
AuthStack ─────────┐   │
                  ▼   ▼
                ApiStack
                    │
                    ▼
               FrontendStack

StorageStack
     │
     ▼
ProcessingStack
```

This is a conceptual dependency model. Exact stack dependencies should come from the CDK code.

---

# 23. What Is a Construct?

CDK uses another important concept:

> **Construct**

A construct represents one or more cloud components.

Conceptually:

```text
CDK App
   ↓
Stack
   ↓
Constructs
   ↓
AWS Resources
```

For example, a construct might represent:

```text
S3 Bucket

Lambda Function

DynamoDB Table
```

or a higher-level collection of resources.

---

# 24. CDK Construct Levels

You may hear:

```text
L1
L2
L3
```

### L1 constructs

Low-level CloudFormation-style resources.

Often closely map to CloudFormation resources.

### L2 constructs

Higher-level AWS-aware abstractions with convenient defaults and methods.

### L3 constructs

Patterns combining multiple resources into reusable architectural components.

You don't need to memorize every construct class.

Understand the abstraction idea.

---

# 25. CDK Deployment Lifecycle

A useful mental model is:

```text
Write CDK Code
      ↓
cdk synth
      ↓
CloudFormation Template
      ↓
cdk diff
      ↓
Review Changes
      ↓
cdk deploy
      ↓
CloudFormation
      ↓
AWS Resources
```

Let's understand each command.

---

# 26. `cdk synth`

`synth` means:

> **Synthesize**

Conceptually:

```bash
cdk synth
```

takes:

```text
CDK application
```

and produces:

```text
CloudFormation template
```

Think:

```text
CDK
↓
SYNTH
↓
CloudFormation
```

---

# 27. Why Is `cdk synth` Useful?

It can help answer:

> “What infrastructure will my CDK code actually translate into?”

It also catches certain infrastructure-definition problems before deployment.

And it reminds you that:

```text
CDK abstraction
```

ultimately becomes:

```text
CloudFormation resources
```

---

# 28. `cdk diff`

Conceptually:

```bash
cdk diff
```

answers:

> **What infrastructure changes would this new code introduce compared with the deployed stack?**

Example:

```text
Current AWS
   ↓
1 Lambda
```

New CDK:

```text
2 Lambdas
```

`cdk diff` helps inspect the planned infrastructure difference before deployment.

---

# 29. Why Is `cdk diff` Important?

Imagine changing:

```text
IAM policy
```

accidentally from:

```text
specific resource
```

to:

```text
*
```

Or changing:

```text
S3 deletion behavior
```

You don't want to discover every infrastructure change only after deployment.

A mature workflow includes reviewing the diff.

---

# 30. `cdk deploy`

Conceptually:

```bash
cdk deploy
```

means:

> **Deploy the synthesized infrastructure changes through CloudFormation.**

Flow:

```text
CDK Code
   ↓
CloudFormation
   ↓
Create / Update Stack
   ↓
AWS Resources
```

---

# 31. `cdk destroy`

Conceptually:

```bash
cdk destroy
```

requests deletion of resources belonging to the stack.

But be careful.

Not every data resource should necessarily disappear just because an application stack is destroyed.

For example:

```text
Production invoice data
```

may need protection.

This brings us to removal policies.

---

# 32. Removal Policy

For persistent resources such as:

```text
S3

DynamoDB
```

you need to think carefully about what happens during stack deletion.

Conceptually:

```text
Destroy Stack
      ↓
Should data also disappear?
```

Possible strategies include retaining important data rather than automatically deleting it.

The correct choice depends on:

```text
Environment

Data importance

Compliance

Recovery requirements
```

Do not claim a specific production removal policy unless verified in the repository.

---

# 33. Infrastructure Code vs Application Code

This is very important.

## Application code

Answers:

> **What does my application do?**

Examples:

```text
Parse Textract result

Call Bedrock

Calculate risk score

Handle API request
```

## Infrastructure code

Answers:

> **Where and how does the application run?**

Examples:

```text
Create Lambda

Create SQS queue

Create DynamoDB table

Create API Gateway

Grant IAM permissions
```

---

# 34. Example

Application code:

```python
def calculate_risk(...):
    ...
```

Infrastructure code conceptually says:

```text
Create Lambda function
    ↓
Package application code
    ↓
Configure runtime
    ↓
Configure timeout
    ↓
Configure environment variables
    ↓
Grant AWS permissions
```

Two completely different responsibilities.

---

# 35. CDK and IAM

Infrastructure as Code is not only about:

```text
creating resources
```

It also defines:

```text
who can access those resources
```

For example:

```text
Processing Lambda
       ↓
Needs S3 read
```

Therefore CDK can grant appropriate permissions.

Conceptually:

```text
Lambda
   ↓
Read access
   ↓
Specific S3 bucket
```

rather than:

```text
Lambda
   ↓
AdministratorAccess
```

---

# 36. Least Privilege

Recall our security principle:

> **Give each component only the permissions it needs.**

For example:

```text
OCR Lambda
```

may need:

```text
Read invoice from S3
Call Textract
```

while:

```text
API Lambda
```

may need different DynamoDB/S3 permissions.

They should not automatically share unrestricted permissions.

---

# 37. Why IaC Helps Security

With manual configuration, someone might make a console change and forget about it.

With IaC, permissions can be:

```text
Defined

Reviewed

Version controlled

Compared

Reproduced
```

This doesn't automatically make the infrastructure secure.

Bad IAM can still be written as code.

But IaC makes security configuration easier to review systematically.

---

# 38. Environment Variables

Lambda functions often need resource identifiers such as:

```text
TABLE_NAME

BUCKET_NAME

QUEUE_URL
```

Instead of hard-coding them into application code, infrastructure can provide them as configuration.

Conceptually:

```text
CDK
 ↓
Create DynamoDB table
 ↓
Get table name
 ↓
Lambda environment variable
 ↓
Application reads table name
```

This connects infrastructure and application code cleanly.

---

# 39. Why Hard-Coding Resource Names Is Risky

Imagine application code contains:

```text
novamind-production-table
```

everywhere.

Now you want:

```text
development

staging

production
```

You may need different resources.

Configuration should generally be environment-aware rather than deeply hard-coded into business logic.

---

# 40. Development, Staging and Production

A mature infrastructure strategy may have:

```text
Development
    ↓
Staging
    ↓
Production
```

Each environment can use similar infrastructure definitions but different configuration.

For example:

```text
Dev
→ smaller/cheaper settings

Prod
→ stronger protection/monitoring
```

This is a general production pattern.

Do not claim NovaMind AI currently has a fully verified multi-environment deployment unless repository evidence supports it.

---

# 41. Reusability

Suppose you repeatedly need:

```text
Lambda
+
CloudWatch log settings
+
IAM permissions
+
environment variables
```

CDK lets developers build reusable constructs/patterns instead of duplicating everything.

This is one reason programming-language-based IaC can be useful.

---

# 42. Version Control

Because infrastructure is code, it can live in Git.

Then:

```text
Developer changes infrastructure
       ↓
Git diff
       ↓
Code review
       ↓
CI/CD
       ↓
Deployment
```

This gives an infrastructure history.

For example, you can investigate:

> “When was this SQS configuration changed?”

through source history—assuming infrastructure changes are consistently managed through IaC.

---

# 43. Infrastructure Drift

Now an important real-world problem.

Suppose CDK says:

```text
Setting A
```

but someone manually opens AWS Console and changes it to:

```text
Setting B
```

Now:

```text
Infrastructure definition
≠
Actual infrastructure
```

This is called:

> **configuration drift**

Manual production changes should therefore be carefully controlled.

---

# 44. IaC Does Not Mean “Never Use AWS Console”

The AWS Console remains useful for:

```text
Observability

Logs

Troubleshooting

Inspecting resources

Learning

Validation
```

The problem is relying on manual console operations as the primary reproducible infrastructure definition.

For important infrastructure changes:

```text
Update IaC
↓
Review
↓
Deploy
```

is generally preferable.

---

# 45. CDK and CloudFormation State

When CDK deploys:

```text
CDK
↓
CloudFormation Stack
```

CloudFormation manages the deployed resources associated with that stack.

This provides features such as:

```text
Create

Update

Delete

Dependency management

Rollback behavior
```

according to CloudFormation semantics and resource configuration.

---

# 46. What Happens When Deployment Fails?

Imagine:

```text
Resource A ✓
Resource B ✓
Resource C ✗
```

CloudFormation manages stack deployment state and may perform rollback behavior depending on the operation/configuration.

This is far safer than writing an arbitrary deployment script that manually creates 30 resources with no coherent state management.

But CloudFormation deployment failures still require troubleshooting.

---

# 47. Common CDK Deployment Problems

Examples include:

```text
Missing IAM permissions

Resource already exists

Wrong region

Wrong account

Invalid configuration

Circular dependencies

CloudFormation validation errors

Lambda packaging problems

Resource quotas

Deletion policies

Cross-stack reference problems
```

Your previous AWS work should make several of these concepts familiar.

---

# 48. CDK Does Not Package Everything Magically

An important distinction:

CDK can define:

```text
Lambda function
```

but the application still needs deployable code and dependencies.

For Python Lambda, dependencies may require:

```text
packaging

Lambda layers

compatible binaries
```

This becomes especially important in the next file:

**`18-Deployment-Lambda-Layers-and-CICD.md`**

---

# 49. CDK Does Not Prove the Application Works

This is important for interviews.

Successful:

```text
cdk deploy
```

means infrastructure deployment succeeded.

It does **not** prove:

```text
Textract parsing is correct

Bedrock output is valid

Risk score is correct

Frontend polling works

Notification delivery works
```

Those require application and integration testing.

---

# 50. Infrastructure Success vs Application Success

Remember our state lesson:

```text
Infrastructure deployed
       ↓
Application starts
       ↓
Runtime integration
       ↓
Business behavior
```

These are separate validation levels.

You can have:

```text
CloudFormation CREATE_COMPLETE
```

while:

```text
Application has runtime bug
```

Both can be true.

---

# 51. CDK and the Five-Stack Architecture

Let's connect everything.

```text
┌──────────────────────────────────────────┐
│                CDK APP                   │
├──────────────────────────────────────────┤
│                                          │
│ StorageStack                             │
│   └─ persistent storage/data resources   │
│                                          │
│ AuthStack                                │
│   └─ Cognito authentication              │
│                                          │
│ ProcessingStack                          │
│   └─ async invoice-processing resources  │
│                                          │
│ ApiStack                                 │
│   └─ authenticated backend API           │
│                                          │
│ FrontendStack                            │
│   └─ frontend hosting/distribution       │
│                                          │
└──────────────────────────────────────────┘
                    │
                    ▼
              CloudFormation
                    │
                    ▼
                  AWS
```

That's the architecture you should remember.

---

# 52. Why Five Stacks?

A strong answer is not:

> “Because five is a good number.”

The reason is **separation of infrastructure responsibilities**.

Think:

```text
Storage
→ persistent data

Auth
→ identity

Processing
→ asynchronous business pipeline

API
→ application interface

Frontend
→ web delivery
```

This makes the infrastructure easier to reason about.

---

# 53. Does Five Stacks Mean Five Microservices?

No.

Very important.

```text
5 CDK stacks
```

does **not** mean:

```text
5 microservices
```

A CDK stack is an:

```text
infrastructure deployment boundary/group
```

not automatically an application microservice.

Never use those terms interchangeably.

---

# 54. Eight Lambdas vs Five Stacks

The repository analysis identified:

```text
5 CDK stacks
```

and approximately:

```text
8 application Lambda functions
```

Those numbers represent different things.

```text
Stack
→ infrastructure grouping
```

```text
Lambda
→ compute function
```

One stack can contain multiple Lambda resources.

---

# 55. What About Textract and Bedrock?

You don't “deploy the Textract model” using CDK in this project.

Likewise, you're not deploying Nova Micro as your own model server.

They are managed AWS services.

Your infrastructure/application needs things such as:

```text
IAM permission

Configuration

Integration code
```

to call them.

This is different from:

```text
hosting your own model
```

---

# 56. CDK and Serverless Architecture

Your application is largely serverless.

IaC defines serverless resources such as:

```text
Lambda

API Gateway

DynamoDB

S3

SQS

Step Functions

Cognito

EventBridge

SNS

CloudFront
```

AWS manages the underlying server infrastructure for these managed/serverless services.

You define the architecture and configuration.

---

# 57. Is CDK Serverless?

Be careful with terminology.

CDK itself is:

> **an infrastructure-development framework/toolkit.**

It can define:

```text
Serverless infrastructure
```

or:

```text
EC2 infrastructure
```

or many other AWS architectures.

So don't say:

> “CDK is a serverless service.”

---

# 58. CDK vs Terraform

An interviewer may ask:

> “Why CDK instead of Terraform?”

A neutral answer:

> “Both can provide Infrastructure as Code. For this AWS-focused project, CDK integrates naturally with AWS constructs and CloudFormation and lets the infrastructure be expressed using a programming language. Terraform would also be a valid choice, especially where multi-cloud or an organization-wide Terraform ecosystem is important.”

Don't say:

> “CDK is always better than Terraform.”

---

# 59. CDK vs CloudFormation

A concise comparison:

| CDK | CloudFormation |
|---|---|
| Programming-language abstraction | Declarative AWS template system |
| Constructs | Resources/templates |
| Can create reusable abstractions | Native AWS IaC engine |
| Synthesizes templates | Deploys/manages stacks |
| Developer-friendly abstraction layer | Underlying deployment mechanism for CDK |

Mental model:

```text
CDK
=
How I conveniently DEFINE it
```

```text
CloudFormation
=
How AWS DEPLOYS/MANAGES it
```

for this project.

---

# 60. CDK vs AWS Console

```text
Console
→ Manual configuration
```

```text
CDK
→ Reproducible infrastructure definition
```

The console is useful for investigation.

CDK is useful for maintaining the architecture as code.

---

# 61. What Is Strong in This Project?

From an infrastructure-design perspective, useful foundations include:

```text
✓ AWS CDK

✓ Five responsibility-oriented stacks

✓ Serverless architecture

✓ Infrastructure defined in code

✓ Cognito integration

✓ S3/DynamoDB infrastructure

✓ SQS-based asynchronous ingestion

✓ Step Functions orchestration

✓ API Gateway

✓ CloudFront/S3 frontend architecture

✓ EventBridge/SNS infrastructure

✓ IAM/resource grants

✓ GitHub Actions workflow definitions
```

But remember:

> Infrastructure definitions do not prove every runtime integration works perfectly.

---

# 62. What Should We Not Overclaim?

Do not say:

> ❌ “Everything is fully automated and production-ready.”

The Codex analysis found several areas that still need improvement or runtime verification.

Do not say:

> ❌ “The CDK proves high-risk email alerts work.”

It doesn't.

Do not say:

> ❌ “The project has fully verified CI/CD.”

Workflow definitions exist, but live/current operation was not verified.

Do not say:

> ❌ “Five stacks means five microservices.”

It doesn't.

---

# 63. Production Improvements

For a stronger production IaC design, I would evaluate:

```text
Clear dev/staging/prod strategy

Stronger data-retention policies

Explicit backup/recovery configuration

Security scanning

cdk diff review in CI/CD

Automated tests

Deployment approvals for production

Drift detection

Tagging standards

Cost allocation tags

Monitoring/alarm definitions

Environment-specific configuration

Stricter IAM review

Reproducible Lambda packaging

Rollback/recovery procedures
```

These are recommended improvements, not claims about the current repository.

---

# 64. Infrastructure Testing

IaC should also be tested.

Possible layers include:

```text
CDK Code
   ↓
Synthesis test
   ↓
Template assertions
   ↓
Deployment
   ↓
Integration test
   ↓
Application test
```

For example:

```text
Does template contain expected SQS queue?

Does API require Cognito authorization?

Does Lambda have only expected permissions?

Does the deployed upload flow actually work?
```

Infrastructure testing and application testing complement each other.

---

# 65. Deployment Pipeline Concept

A stronger future CI/CD flow might look like:

```text
Git Push
   ↓
Tests
   ↓
CDK Synth
   ↓
Security Checks
   ↓
CDK Diff
   ↓
Approval
   ↓
CDK Deploy
   ↓
Integration Tests
```

For production:

```text
Manual approval
```

may be appropriate before deployment depending on organizational requirements.

Again, this is a recommended production workflow, not a claim that the current GitHub Actions pipeline does every step.

---

# 66. Interview Preparation — 10 Questions

## Q1 — What is Infrastructure as Code?

**Difficulty:** Basic

### Word-by-word practice answer

> “Infrastructure as Code means defining and managing infrastructure using code instead of manually creating every resource through the AWS Console. In my NovaMind AI project, I use AWS CDK to define the AWS infrastructure, which makes the architecture more reproducible, version-controlled and easier to review.”

---

## Q2 — What is AWS CDK?

**Difficulty:** Basic

### Word-by-word practice answer

> “AWS CDK, or Cloud Development Kit, is a framework for defining AWS infrastructure using programming languages. CDK synthesizes my infrastructure definitions into CloudFormation templates, and CloudFormation then provisions and manages the AWS resources.”

---

## Q3 — What is the difference between CDK and CloudFormation?

**Difficulty:** Basic / Intermediate

### Word-by-word practice answer

> “CDK is the higher-level development framework I use to define infrastructure using programming-language constructs. When I run synthesis, CDK generates CloudFormation templates. CloudFormation is the AWS infrastructure engine that actually creates and manages the stacks and resources. So CDK does not replace CloudFormation; it provides an abstraction over it.”

---

## Q4 — How is your CDK infrastructure organized?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The project organizes its infrastructure into five major CDK stacks: StorageStack, AuthStack, ProcessingStack, ApiStack and FrontendStack. Storage handles persistent data resources, Auth handles Cognito authentication, Processing contains the asynchronous invoice-processing infrastructure, Api exposes the backend application APIs, and Frontend handles the web-hosting and distribution layer.”

---

## Q5 — Why did you use multiple stacks instead of one stack?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “I separate the infrastructure by responsibility so that storage, authentication, processing, API and frontend resources are easier to understand and maintain. The stacks can still depend on each other, but the separation prevents the entire infrastructure definition from becoming one large tightly organized unit. It also makes dependencies and ownership clearer.”

---

## Q6 — What do `cdk synth`, `cdk diff`, and `cdk deploy` do?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “`cdk synth` converts the CDK application into CloudFormation templates. `cdk diff` shows the infrastructure differences between my current CDK definition and the deployed environment. `cdk deploy` uses the synthesized infrastructure through CloudFormation to create or update the AWS resources. I would normally review the diff before applying important infrastructure changes.”

---

## Q7 — How do the CDK stacks communicate with each other?

**Difficulty:** Intermediate / Advanced

### Word-by-word practice answer

> “The stacks are separated by responsibility but they are not completely independent. For example, processing infrastructure needs references and permissions for storage resources, while API infrastructure needs authentication resources such as Cognito. CDK can pass resource references between constructs or stacks and establish the necessary dependencies. I would verify the exact cross-stack implementation from the repository before describing a specific reference mechanism.”

---

## Q8 — How does CDK help with security?

**Difficulty:** Advanced

### Word-by-word practice answer

> “CDK lets me define IAM permissions, private storage configuration and other security controls as version-controlled infrastructure. For example, a Lambda can be granted access only to the S3 bucket or DynamoDB table it needs instead of using broad administrative permissions. IaC does not automatically make an application secure, but it makes the security configuration reproducible and easier to review.”

---

## Q9 — If `cdk deploy` succeeds, does that mean your application works?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “No. A successful CDK and CloudFormation deployment proves that the infrastructure deployment completed, but it does not prove the complete application behavior. I still need integration and application testing for flows such as upload, SQS processing, Textract extraction, Bedrock analysis, risk scoring, frontend polling and notifications. Infrastructure success and business-function success are different validation layers.”

---

## Q10 — How would you improve the project's IaC for production?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “I would strengthen the environment strategy for development, staging and production, review data-retention and removal policies, improve IAM and security validation, add infrastructure tests and security scanning, and include CDK synthesis and diff review in the deployment pipeline. I would also define stronger monitoring, backup and recovery requirements, control manual infrastructure drift, and make Lambda dependency packaging fully reproducible before treating the platform as production-ready.”

---

# 67. Interview Pressure Chain

An interviewer starts:

> **“How did you create the AWS infrastructure?”**

Then:

```text
What is Infrastructure as Code?
        ↓
Why not create it manually?
        ↓
Which IaC tool did you use?
        ↓
What is AWS CDK?
        ↓
What language does it use?
        ↓
What does CDK generate?
        ↓
What is CloudFormation?
        ↓
Does CDK replace CloudFormation?
        ↓
What is a CDK App?
        ↓
What is a Stack?
        ↓
What is a Construct?
        ↓
How many stacks are in your project?
        ↓
Why five?
        ↓
What does StorageStack do?
        ↓
What does ProcessingStack do?
        ↓
How do stacks depend on each other?
        ↓
What is cdk synth?
        ↓
What is cdk diff?
        ↓
What is cdk deploy?
        ↓
How do you manage IAM?
        ↓
What happens if deployment fails?
        ↓
What happens to persistent data
if you destroy the stack?
        ↓
How do you manage environments?
        ↓
How do you prevent manual drift?
        ↓
Does successful deployment mean
the application is working?
```

If you can answer this chain, you understand IaC beyond simply saying:

> “I used CDK.”

---

# 68. Troubleshooting Scenario

Interviewer:

> **“Your CDK deployment succeeded, but invoice processing doesn't work. What would you do?”**

### Word-by-word answer

> “I would first separate infrastructure deployment success from runtime application success. CloudFormation completing successfully only tells me that the defined resources were provisioned. I would trace the runtime flow from S3 to SQS, the trigger Lambda and Step Functions, then inspect the processing Lambdas and their CloudWatch logs. I would also verify environment variables, IAM permissions and resource references created by the CDK stacks. If infrastructure configuration was recently changed, I would compare the CDK definition and deployed environment and review the deployment diff rather than assuming the application code is the only possible cause.”

---

# 69. Architecture Decision Question

Interviewer:

> **“Why CDK instead of creating everything from the AWS Console?”**

### Strong answer

> “The application contains multiple interconnected AWS resources, so manually reproducing the architecture would be difficult and error-prone. CDK lets me define those resources, permissions and relationships as version-controlled code. It also synthesizes CloudFormation, which gives me a consistent deployment mechanism. I still use the AWS Console for monitoring and troubleshooting, but important infrastructure changes should ideally be represented in the IaC definition so the environment remains reproducible.”

---

# 70. CDK vs CloudFormation vs AWS Console — Remember This

```text
AWS Console
     ↓
Human manually configures resources
```

```text
AWS CDK
     ↓
Developer defines infrastructure
using programming-language abstractions
```

```text
CloudFormation
     ↓
AWS creates/manages the infrastructure
```

For your project:

```text
YOU
 ↓
CDK CODE
 ↓
cdk synth
 ↓
CLOUDFORMATION
 ↓
AWS
 ↓
NovaMind AI Infrastructure
```

---

# 71. Five Things You Must Remember

**1. IaC means infrastructure defined as code.**

```text
Manual clicks
      ↓
replace with
      ↓
Version-controlled definition
```

**2. CDK does not replace CloudFormation.**

```text
CDK
↓
Synthesizes
↓
CloudFormation
↓
AWS
```

**3. Your project has five major CDK stacks.**

```text
StorageStack
AuthStack
ProcessingStack
ApiStack
FrontendStack
```

**4. Stack ≠ microservice.**

```text
CDK Stack
=
Infrastructure grouping/deployment boundary
```

**5. Infrastructure deployment success ≠ application success.**

```text
cdk deploy ✓
```

does not automatically prove:

```text
Upload ✓
Textract ✓
Bedrock ✓
Risk scoring ✓
Notifications ✓
Frontend ✓
```

Those need runtime testing.

---

# 72. Your 30-Second Interview Answer

> “I manage the NovaMind AI infrastructure using AWS CDK rather than manually creating the architecture through the console. The CDK application is organized into five responsibility-based stacks: StorageStack, AuthStack, ProcessingStack, ApiStack and FrontendStack. CDK lets me define resources, dependencies and IAM permissions as version-controlled code, and it synthesizes those definitions into CloudFormation templates for deployment. This makes the infrastructure more reproducible and maintainable. I also distinguish infrastructure deployment from runtime validation, because a successful CloudFormation deployment does not prove that flows such as Textract, Bedrock or notifications work end to end.”

---

# 73. Your 10-Second Mental Model

```text
CDK Code
   ↓
CloudFormation
   ↓
AWS Resources
```

Your five stacks:

```text
Storage
+
Auth
+
Processing
+
API
+
Frontend
```

Or remember one sentence:

> **“CDK defines my AWS architecture as code; CloudFormation deploys and manages that infrastructure.”**

---

# 74. Check Your Understanding

Before moving to **`18-Deployment-Lambda-Layers-and-CICD.md`**, answer these three questions in your own words.

**Question 1:** What is the relationship between:

```text
AWS CDK
    ↓
CloudFormation
    ↓
AWS Resources
```

and why would it be inaccurate to say **“CDK completely replaces CloudFormation”**?

**Question 2:** Why does NovaMind AI use:

```text
StorageStack
AuthStack
ProcessingStack
ApiStack
FrontendStack
```

instead of treating all infrastructure as one conceptual block?

**Question 3:** Suppose:

```text
cdk deploy
→ SUCCESS
```

but uploading an invoice never starts processing.

Why does the successful CDK deployment **not** prove that the application works, and which runtime components would you investigate first?