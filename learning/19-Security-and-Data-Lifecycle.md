# Your question

**Create `19-Security-and-Data-Lifecycle.md`.**

This is one of the most important files in the entire project because security is **not one AWS service**. In NovaMind AI, it spans authentication, authorization, tenant isolation, IAM, S3, presigned URLs, API Gateway, DynamoDB, CloudFront, CI/CD, browser caching, logging, and data deletion.

The key interview principle is:

> **Never say “my application is secure.” Explain the specific security controls you implemented, their boundaries, and the gaps you identified.**

# 19 — Security and Data Lifecycle

## 1. What Will I Learn?

By the end of this file, I should understand:

- Authentication vs authorization
- Cognito's security role
- API Gateway Cognito authorizer
- Why the backend derives `tenant_id` from Cognito claims
- Current user-level tenant isolation
- Resource ownership validation
- The current job-status authorization gap
- Frontend cache isolation
- IAM and least privilege
- Private S3 buckets
- Presigned URL security
- S3 encryption
- CloudFront Origin Access Control
- HTTPS
- API/logging security
- GitHub OIDC
- Sensitive-data exposure
- What data lifecycle means
- Where invoice data exists
- Creation, processing, storage and deletion
- DynamoDB TTL
- Why the current TTL configuration is incomplete
- Current deletion limitations
- S3 versioning implications
- Retention policies
- Data minimization
- Logging and AI data considerations
- Production security improvements
- 10 project-specific interview questions and answers

---

# 2. First: What Does Security Mean Here?

Security is not:

```text
Cognito = Security
```

The actual picture is much larger:

```text
                     NOVAMIND AI SECURITY
                              │
        ┌─────────────────────┼──────────────────────┐
        ▼                     ▼                      ▼
    Identity              Application              Data
        │                   Access                  │
     Cognito                   │                  S3
        │               API Gateway             DynamoDB
        │               Authorization               │
        └─────────────────────┼──────────────────────┘
                              │
                              ▼
                             IAM
                              │
                       AWS Service Access
```

And we also need:

```text
Frontend security
CI/CD security
Logging security
Data retention
Deletion
```

Security exists across the complete application lifecycle.

---

# 3. Authentication vs Authorization

This is one of the first questions an interviewer may ask.

### Authentication

> **Who are you?**

Example:

```text
Email + Password
      ↓
Cognito
      ↓
Authenticated User
```

### Authorization

> **What are you allowed to access?**

Example:

```text
Authenticated User A
       ↓
Can access Invoice A?
```

These are different problems.

---

# 4. Authentication in NovaMind AI

The verified authentication flow is:

```text
React
  ↓
AWS Amplify
  ↓
Amazon Cognito
  ↓
Authentication
  ↓
Session / ID Token
  ↓
Authorization Header
  ↓
API Gateway
  ↓
Cognito Authorizer
```

The frontend does not simply tell the backend:

```text
"I am User A."
```

The backend receives identity through a validated authentication mechanism.

---

# 5. Why the Cognito `sub` Matters

Each authenticated Cognito user has a stable identifier:

```text
sub
```

The backend derives:

```text
tenant_id
```

from that validated claim.

Conceptually:

```text
Validated Cognito Token
         ↓
       claims
         ↓
        sub
         ↓
     tenant_id
```

This is much safer than trusting a browser-supplied:

```json
{
  "tenant_id": "someone_else"
}
```

---

# 6. Never Trust Client-Supplied Identity

Imagine an insecure API:

```text
GET /invoices?tenant_id=user123
```

An attacker changes:

```text
user123
```

to:

```text
user456
```

If the backend trusts it:

```text
User A
 ↓
asks for User B
 ↓
Backend accepts
 ↓
DATA LEAK
```

NovaMind AI instead derives the identity from authenticated Cognito claims.

That is an important security decision.

---

# 7. Current Meaning of `tenant_id`

Be precise.

In this project:

```text
tenant_id
≈
authenticated Cognito user
```

It does **not** currently represent a verified enterprise organization containing multiple users and roles.

Therefore don't say:

> ❌ “The project implements full enterprise multi-tenancy with organizations and role hierarchies.”

It doesn't.

A more accurate statement is:

> **“The current isolation model is primarily per authenticated Cognito user.”**

---

# 8. Tenant Isolation in DynamoDB

Recall File 13.

The invoice table uses:

```text
Partition Key:
tenant_id

Sort Key:
invoice_id
```

Conceptually:

```text
User A
│
├── Invoice 1
├── Invoice 2
└── Invoice 3

User B
│
├── Invoice 4
└── Invoice 5
```

The backend can query:

```text
tenant_id = authenticated user's sub
```

rather than trusting a tenant supplied by the browser.

---

# 9. Tenant Isolation in S3

The upload path also contains tenant context.

Conceptually:

```text
invoices/
   └── tenant_id/
        └── invoice_id
```

This helps organize objects according to the authenticated user.

The presigned URL is generated for a backend-controlled object key.

The browser does not freely choose arbitrary tenant ownership.

---

# 10. Defense in Depth

One security mechanism should not carry the entire security model.

NovaMind AI has multiple layers:

```text
Cognito
   ↓
Authentication

API Gateway Authorizer
   ↓
Token validation

Backend
   ↓
tenant_id from claims

Application Logic
   ↓
Ownership checks

DynamoDB/S3
   ↓
Tenant-aware storage

IAM
   ↓
AWS service permissions
```

This idea is called:

> **Defense in depth.**

If one layer has a mistake, another layer may still reduce the impact.

---

# 11. Frontend Route Protection Is Not Security Enforcement

From File 15:

```text
React Protected Route
```

can stop normal users from navigating to a page.

But someone can bypass React:

```text
curl
Postman
custom script
```

and call the API directly.

Therefore:

```text
React route guard
=
UI control
```

while:

```text
API Gateway authorizer
+
backend authorization
=
security enforcement
```

---

# 12. Important Security Gap — Job Status

Now we reach a verified weakness.

The project has a processing-job record conceptually identified by:

```text
job_<invoice_id>
```

The job-status flow performs a tenant-scoped invoice lookup, but the subsequent job lookup does not independently compare the job record's stored `tenant_id` with the authenticated requester.

Conceptually:

```text
Authenticated User
       ↓
Invoice ownership check
       ↓
Get job_<invoice_id>
       ↓
Job tenant ownership
not independently enforced
```

This creates a potential information-disclosure gap.

---

# 13. What Could Be Exposed?

The risk is not necessarily:

```text
Complete invoice PDF
```

through this endpoint.

But potentially information such as:

```text
Processing status

Current stage

Error details
```

could be disclosed if another invoice identifier became known and the ownership logic allowed that path.

That's still a security issue.

---

# 14. How Would I Fix It?

A stronger implementation would enforce ownership directly on the job resource.

Conceptually:

```text
Get Job
   ↓
job.tenant_id
   ↓
Compare with authenticated tenant_id
      / \
    SAME DIFFERENT
     ↓       ↓
  Return   403/404
```

Even better, the data model could make tenant ownership part of the primary access pattern where appropriate.

The main rule is:

> **Every tenant-owned resource should enforce tenant ownership at the backend boundary where it is accessed.**

---

# 15. Frontend Cache Isolation

Security doesn't stop at AWS.

Remember:

```text
User A logs in
      ↓
React Query caches invoices
      ↓
User A logs out
      ↓
User B logs in
```

If User A's cached data remains:

```text
User B's browser session
       ↓
could temporarily see
User A's stale data
```

even if the backend correctly rejects new unauthorized requests.

---

# 16. Why This Matters

People sometimes think:

> “If the API is secure, the application is secure.”

But:

```text
Backend Authorization
        ✓

Browser Cache Isolation
        ✗
```

can still create a privacy problem.

Security must cover:

```text
Server
+
Client
```

---

# 17. Better Logout Security

Conceptually:

```text
Logout
   ↓
Cognito sign-out
   ↓
Clear authentication state
   ↓
Clear React Query private cache
   ↓
Clear upload state
   ↓
Clear user-specific filters
   ↓
Redirect
```

And user-specific query keys can be namespaced:

```text
["invoices", user_id]
```

instead of only:

```text
["invoices"]
```

These are recommended improvements to the current implementation.

---

# 18. IAM — Another Security Layer

Cognito controls:

```text
Application users
```

IAM controls:

```text
AWS identities/resources/services
```

These are different.

For example:

```text
Cognito
→ Can this user access my application?
```

while:

```text
IAM
→ Can this Lambda call Textract?
```

or:

```text
Can this Lambda write DynamoDB?
```

---

# 19. Least Privilege

The principle is:

> **Give each identity only the permissions it needs.**

For example:

```text
Textract Processing Lambda
        ↓
Needs S3 read
Needs Textract access
```

It doesn't automatically need:

```text
Delete every DynamoDB table

Modify Cognito

Delete CloudFront

Create IAM users
```

The project uses per-function roles/resource grants as part of its infrastructure design.

---

# 20. Why Per-Function IAM Is Useful

Imagine one enormous role:

```text
ALL LAMBDAS
    ↓
EVERY PERMISSION
```

If one function is compromised:

```text
Attacker
  ↓
Huge permission surface
```

With narrower roles:

```text
OCR Lambda
→ OCR permissions

Storage Lambda
→ storage permissions

API Lambda
→ required API data permissions
```

the blast radius can be reduced.

---

# 21. S3 Bucket Security

The application's S3 buckets are designed as private resources rather than public invoice repositories.

Important principle:

```text
Private Bucket
     +
Presigned URL
```

does not mean:

```text
Public Bucket
```

A presigned URL temporarily authorizes a specific operation.

---

# 22. Presigned URL Security

The upload Lambda creates a short-lived presigned PUT URL.

The verified project flow uses approximately:

```text
5-minute validity
```

Conceptually:

```text
Authenticated User
       ↓
Backend validates identity
       ↓
Generate tenant-specific key
       ↓
Presigned PUT URL
       ↓
Expires
```

This avoids giving the React application permanent AWS credentials.

---

# 23. Why Expiration Matters

Imagine a presigned URL that works forever.

If leaked:

```text
URL leaked
   ↓
Attacker can keep using it
```

A short expiration reduces that exposure window.

But remember:

> A presigned URL is still a credential-like capability while valid.

Don't casually expose it in:

```text
Logs

Analytics systems

Public URLs

Screenshots
```

---

# 24. Upload Validation Security

The frontend checks things such as:

```text
MIME type

File size <= 10 MiB
```

But frontend checks are not a trusted security boundary.

A malicious client can bypass React.

The Codex analysis found that the backend does not fully verify:

```text
Actual uploaded content

Actual object size

Page count

Document structure
```

before OCR processing.

That is a security and cost-control gap.

---

# 25. Why Backend Validation Matters

Imagine:

```text
React says:
"Maximum 10 MiB"
```

An attacker skips React and uploads differently using the authorized mechanism or exploits weak validation.

Trusted enforcement should exist on the backend/storage-processing boundary where required.

Production improvements could include:

```text
Server-side metadata validation

Actual content validation

Size validation

Page-count limits

File-signature validation

Malware scanning where required
```

These are improvements, not claims about the current implementation.

---

# 26. Content-Type Is Not Proof of Content

A file saying:

```text
Content-Type: application/pdf
```

doesn't mathematically prove:

```text
File is a safe valid PDF
```

Metadata can be incorrect or manipulated.

Therefore strong upload security may inspect:

```text
Actual file signature

Document parser result

Allowed format

Size

Page limits
```

depending on the threat model.

---

# 27. Encryption

The project configures encryption for the important upload/processed S3 storage.

At a high level:

```text
Data at rest
   ↓
Encryption
```

helps protect stored data.

But encryption is not a replacement for:

```text
Authentication

Authorization

IAM

Private access

Data minimization
```

You need multiple controls.

---

# 28. Encryption at Rest vs In Transit

### At rest

Data stored in:

```text
S3

DynamoDB
```

should have appropriate encryption protection.

### In transit

Traffic should use secure transport such as:

```text
HTTPS/TLS
```

The frontend delivery architecture includes CloudFront HTTPS redirect behavior.

Think:

```text
Stored data
→ encryption at rest

Moving data
→ encryption in transit
```

---

# 29. CloudFront Origin Access Control

The frontend architecture uses CloudFront with S3.

A useful security pattern is:

```text
Internet
   ↓
CloudFront
   ↓
Origin Access Control
   ↓
Private S3 Origin
```

rather than exposing the frontend S3 bucket broadly as a public origin.

This lets CloudFront act as the intended delivery layer.

---

# 30. CORS

CORS stands for:

> **Cross-Origin Resource Sharing**

It controls which browser origins can make certain cross-origin requests.

The project analysis identified:

```text
Broad S3 CORS
```

as an area that could be tightened.

For production, prefer allowing only the origins and methods actually required.

But remember:

> **CORS is a browser security mechanism, not authentication.**

It does not replace Cognito or backend authorization.

---

# 31. API Logging and Sensitive Data

The project disables API request-body tracing.

Why might that be useful?

Invoice requests can contain sensitive business information.

If everything is logged blindly:

```text
Request
 ↓
Full invoice-related data
 ↓
CloudWatch Logs
```

you have created another copy of potentially sensitive data.

Logs themselves then become sensitive storage.

---

# 32. Logging Principle

Log enough to troubleshoot:

```text
invoice_id

job_id

stage

status

error category

request/correlation ID
```

But avoid unnecessarily logging:

```text
Full invoice text

Passwords

Tokens

Presigned URLs

Financial details

Complete Bedrock prompts/responses
```

unless there is a justified, protected requirement.

This is called:

> **data minimization in logging.**

---

# 33. Secrets

Secrets should not be hard-coded into:

```text
Git repository

React source

Lambda source

README
```

Examples:

```text
AWS secret access keys

API secrets

Passwords

Private tokens
```

The project also uses GitHub OIDC for AWS workflow authentication, reducing reliance on long-lived AWS access keys in CI/CD.

---

# 34. OIDC Security Revisited

From File 18:

```text
GitHub Actions
      ↓
OIDC
      ↓
AWS IAM Role
      ↓
Temporary Credentials
```

This is preferable to permanently storing:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

for deployment.

But OIDC still needs:

```text
restricted trust policy
+
appropriate IAM permissions
```

OIDC by itself doesn't make the deployment role least-privileged.

---

# 35. Password Security

The Cognito setup includes password complexity and email confirmation behavior.

However, the project analysis also identified missing/incomplete areas such as:

```text
No verified MFA configuration

No complete password-reset UI
```

Therefore don't say:

> ❌ “The authentication system has MFA.”

unless you later implement and verify it.

---

# 36. Organization-Level Authorization

Current:

```text
Cognito User
    ↓
tenant_id
```

Future enterprise system might need:

```text
Organization
    │
    ├── Admin
    ├── Finance Manager
    ├── Reviewer
    └── Read-only Auditor
```

Then authorization becomes:

```text
User
+
Organization
+
Role
+
Resource Ownership
+
Action
```

The current project does not implement this full hierarchy.

---

# 37. What Is Data Lifecycle?

Now let's move to the second half of this file.

**Data lifecycle means what happens to data from the moment it enters the system until it is eventually deleted or archived.**

For NovaMind AI:

```text
CREATE
  ↓
UPLOAD
  ↓
PROCESS
  ↓
STORE
  ↓
READ
  ↓
ANALYZE
  ↓
RETAIN
  ↓
DELETE
```

Security applies to every stage.

---

# 38. Invoice Data Lifecycle

The current flow is approximately:

```text
Invoice File
    ↓
S3 Upload Bucket
    ↓
Textract
    ↓
Extracted Invoice Data
    ↓
Bedrock Analysis
    ↓
Risk Rules
    ↓
Final Results
    ↓
DynamoDB
```

Additionally:

```text
Extracted Text
    ↓
Processed S3 Storage
```

and frontend users later retrieve the application result through authenticated APIs.

---

# 39. Where Does Data Exist?

This question is extremely important for security and deletion.

Invoice-related information may exist across:

```text
Original S3 object

Processed text in S3

DynamoDB invoice record

DynamoDB processing-job record

Step Functions execution state/history

CloudWatch logs

AI request/response processing path

Browser cache/state
```

Potential notification/event data may create additional copies depending on the actual implementation.

So:

> **Deleting one DynamoDB row does not necessarily delete all invoice-related data.**

---

# 40. Original Invoice

The original uploaded invoice is stored in S3.

Conceptually:

```text
Original PDF/Image
       ↓
Private S3 Bucket
       ↓
Tenant-aware object key
```

This is the primary document object.

---

# 41. Processed Text

The storage stage writes extracted text using a pattern like:

```text
processed-text/
    tenant_id/
        invoice_id.txt
```

Important project fact:

> The current storage handler stores extracted text there, but does not write a complete OCR + AI-analysis JSON artifact to that processed bucket.

Do not describe a full JSON archive unless you implement it.

---

# 42. DynamoDB Invoice Record

The invoice record contains operational application data such as:

```text
Invoice metadata

Extracted information

Risk score

Risk level

Findings

Explanation/analysis information

Object references

Timestamps
```

This is what the application can use for invoice retrieval and display.

---

# 43. Processing Job Record

The processing-jobs table tracks lifecycle information such as:

```text
job_id

tenant_id

invoice_id

status

stage

timestamps

error information
```

This is separate from the final invoice record.

---

# 44. Why Separate Job Data?

Because during processing:

```text
Final invoice result
```

may not exist yet.

But the application still needs to know:

```text
PENDING?

PROCESSING?

FAILED?

COMPLETED?
```

So job state has a different lifecycle from final invoice data.

---

# 45. DynamoDB TTL

TTL means:

> **Time to Live**

DynamoDB TTL can automatically remove items after a configured expiration timestamp.

Conceptually:

```text
Job Record
   ↓
ttl = expiration time
   ↓
Time passes
   ↓
DynamoDB becomes eligible to remove item
```

This is useful for temporary operational records.

---

# 46. Important Current TTL Gap

The processing-jobs table is configured with a TTL attribute:

```text
ttl
```

but the project's:

```text
create_job()
```

logic does **not** populate that field.

Therefore:

```text
TTL configured on table ✓

TTL value on created job ✗
```

Result:

> **Automatic job expiry is incomplete.**

This is a very good interview finding.

---

# 47. Why Configuration Alone Isn't Enough

Imagine:

```text
DynamoDB Table:
TTL field = "ttl"
```

but items look like:

```json
{
  "job_id": "job_123",
  "status": "COMPLETED"
}
```

with no:

```text
ttl
```

Then DynamoDB has no expiration timestamp for that item.

Infrastructure capability:

```text
✓
```

Application usage:

```text
✗
```

This is another example of:

> **Infrastructure existing does not prove application behavior is complete.**

---

# 48. How Would I Fix TTL?

When creating a temporary job:

```text
current time
    +
retention period
    ↓
expiration timestamp
    ↓
ttl
```

Conceptually:

```python
ttl = now + retention_period
```

Then store it with the job record.

The exact retention period should come from business and compliance requirements, not an arbitrary number.

---

# 49. TTL Is Not Precise Immediate Deletion

An important DynamoDB concept:

> TTL expiration means an item becomes eligible for automatic deletion; it should not be treated as a precise second-by-second deletion scheduler.

Therefore if a requirement says:

> “At exactly 12:00:00 this record must be inaccessible,”

you should not rely solely on TTL timing for application authorization behavior.

---

# 50. Current Delete Flow

The current delete path roughly does:

```text
Authenticated User
       ↓
Tenant-scoped Invoice Lookup
       ↓
Delete Invoice Record
       ↓
Attempt Original S3 Object Deletion
```

This is useful.

But it is not a complete data-erasure workflow.

---

# 51. What Is Not Comprehensively Deleted?

The project analysis identified that deletion does not comprehensively clean up:

```text
Processing job record

Processed text

Historical S3 object versions
```

and other secondary traces may have their own lifecycle.

Therefore:

```text
Delete Invoice
```

does not currently mean:

```text
Every related byte everywhere
has been removed
```

---

# 52. Why Is This Important?

Imagine a user says:

> “Delete invoice 123.”

The application removes:

```text
DynamoDB invoice record ✓
Original current S3 object ✓
```

but leaves:

```text
processed-text/.../123.txt

job_123

historical S3 versions
```

Then the data still exists elsewhere.

That's a **data lifecycle gap**.

---

# 53. S3 Versioning and Deletion

When S3 versioning is involved, deleting the visible/current object may not necessarily erase all historical versions.

Conceptually:

```text
invoice.pdf
│
├── Version 1
├── Version 2
└── Delete Marker
```

If complete erasure is required, the deletion workflow needs to account for relevant historical versions according to the storage configuration and retention requirements.

---

# 54. Complete Deletion Needs a Data Map

Before implementing reliable deletion, ask:

> “Where can this invoice exist?”

Create a map:

```text
invoice_id
   │
   ├── Original S3 object
   ├── Processed text
   ├── Invoice DynamoDB item
   ├── Job DynamoDB item
   ├── Logs
   ├── Workflow history/state
   ├── Browser cache
   └── Events/notifications where applicable
```

Then define retention/deletion rules for each location.

This is why data lifecycle architecture matters.

---

# 55. Retention Policy

Not all data necessarily needs the same retention period.

For example:

```text
Original Invoice
→ business retention requirement

Processing Job
→ temporary operational data

Application Logs
→ operational retention period

Audit Records
→ potentially longer controlled retention
```

The correct durations depend on business/legal/compliance requirements.

Do not invent them.

---

# 56. Data Minimization

A powerful security principle is:

> **Don't store data you don't need.**

Every additional copy creates:

```text
Storage cost

Security risk

Deletion responsibility

Compliance scope
```

For example:

```text
Full invoice text
```

does not necessarily need to be duplicated into:

```text
DynamoDB
Logs
Events
Emails
```

unless required.

---

# 57. Data Lifecycle and Bedrock

The application sends invoice-derived text/data to:

```text
Amazon Bedrock Nova Micro
```

for inference.

From the application's perspective, this means sensitive invoice-derived data crosses another service boundary.

A production security review should therefore document:

```text
What fields are sent?

Is raw OCR included?

Is all of it necessary?

What AWS region is used?

What organizational policies apply?

What logging exists around requests?
```

For this project, we know the prompt includes:

```text
Structured invoice fields
+
line items
+
raw OCR text
```

So the model receives substantial invoice-derived content.

---

# 58. Minimize AI Input Where Possible

Current prompt:

```text
Structured Fields
+
Line Items
+
Raw OCR Text
```

A production review could ask:

> “Does Nova Micro really need every part of the raw OCR text?”

If not:

```text
Remove unnecessary content
       ↓
Smaller prompt
       ↓
Lower exposure
       +
potentially lower cost/latency
```

This would also help the token-budget problem identified earlier.

This is a future optimization, not a current implementation claim.

---

# 59. AI Output Is Also Data

Bedrock returns:

```text
Anomalies

Summary

Confidence
```

That output becomes application data.

Therefore AI output needs lifecycle decisions too:

```text
How long is it stored?

Who can access it?

Can users delete it?

Does it appear in logs?

Is it included in notifications?
```

AI security isn't only about the prompt.

---

# 60. Prompt Injection and Security

Because raw OCR text is inserted into the model prompt, document text becomes part of model input.

A malicious document could theoretically contain text resembling instructions.

For example:

```text
Ignore previous instructions...
```

The current project has not established a verified prompt-injection exploit.

So describe this as:

> **a threat to consider in production AI security**, not as a confirmed vulnerability that has already been exploited.

Potential defenses include:

```text
Clear separation of trusted instructions
and untrusted document content

Structured extraction

Output schema validation

Business-rule validation

Least privilege around model-driven actions
```

The last point is especially important.

In this project the LLM does not autonomously execute arbitrary AWS actions, which reduces some agentic-tool risks.

---

# 61. Why Deterministic Rules Help Security

The LLM does not independently decide:

```text
"Block this invoice"
```

and execute a financial action.

Instead:

```text
Bedrock
   ↓
AI findings
   ↓
Python risk logic
   ↓
Application result
```

This does not make the result automatically correct, but it prevents the model from being the sole uncontrolled business-decision mechanism.

The system is better described as:

> **invoice review support / anomaly prioritization**

rather than autonomous fraud enforcement.

---

# 62. Risk Score Is Not Security Proof

A:

```text
LOW
```

risk result does not mean:

```text
Invoice is safe
```

especially because:

```text
OCR may fail

AI may fail

Rules are heuristic

AI output validation is incomplete
```

Remember:

> **Risk scoring is business analysis, not an authentication/security control.**

---

# 63. Rate Limiting and Cost Abuse

The project analysis identified no strong application-specific:

```text
Tenant budgets

Rate limits

Processing concurrency controls
```

as a complete protection layer.

Why does this matter?

An authenticated user could potentially submit many invoices:

```text
Uploads
  ↓
Textract calls
  ↓
Bedrock calls
  ↓
Lambda
  ↓
Cost
```

So security also includes:

> **abuse and cost protection.**

---

# 64. Production Abuse Controls

Possible future controls include:

```text
Per-user upload limits

API throttling

File-size enforcement

Page-count limits

Processing quotas

Concurrency limits

Budget alarms

Anomaly detection

WAF where appropriate
```

These are recommendations, not claims about the current project.

---

# 65. Security Observability

Security controls should be observable.

Useful signals include:

```text
Authentication failures

Authorization failures

Unexpected access attempts

Upload volume

Large files

Repeated failures

DLQ growth

Unusual Bedrock usage

Deletion operations

IAM access errors
```

CloudWatch and X-Ray provide observability foundations, but don't claim the project currently implements a complete SIEM/security-monitoring platform.

---

# 66. Security and Error Messages

Remember the job-status gap.

Detailed backend errors may contain:

```text
AWS service names

Object keys

Internal stages

Exception messages
```

Don't expose unnecessary internal information to unauthorized users.

A good pattern is:

```text
User:
"Processing failed."

Operations:
Detailed diagnostic logs
```

The user gets useful information without unnecessary internal leakage.

---

# 67. Current Security Strengths

Based on the project analysis, the project has several meaningful controls:

```text
✓ Cognito authentication

✓ Email confirmation/password complexity

✓ API Gateway Cognito authorizer

✓ Backend identity from validated claims

✓ Tenant-prefixed generated upload keys

✓ Short-lived presigned URLs

✓ Private S3 buckets

✓ S3 encryption configuration

✓ CloudFront Origin Access Control

✓ HTTPS redirect

✓ Per-function IAM/resource grants

✓ API request-body tracing disabled

✓ GitHub OIDC instead of embedded
  long-lived AWS access keys
```

These are real security foundations.

---

# 68. Current Security Limitations

Important limitations include:

```text
⚠ Job-status ownership gap

⚠ Browser cache/user-state isolation gap

⚠ No verified MFA configuration

⚠ No organization membership model

⚠ No role hierarchy/RBAC model

⚠ Incomplete password-reset UI

⚠ Broad S3 CORS

⚠ Frontend-only upload size enforcement

⚠ Incomplete backend file validation

⚠ No strong app-specific tenant quotas

⚠ No complete processing concurrency controls

⚠ AI output validation weaknesses
```

Security maturity means knowing these weaknesses, not hiding them.

---

# 69. Current Data Lifecycle Strengths

```text
✓ Original objects have defined S3 storage

✓ Processed text has a defined S3 location

✓ Invoice records have a DynamoDB model

✓ Processing jobs are separated

✓ Job table has TTL capability configured

✓ Invoice deletion attempts tenant-scoped
  record and original-object deletion
```

---

# 70. Current Data Lifecycle Limitations

```text
⚠ create_job() does not populate ttl

⚠ Job cleanup therefore remains incomplete

⚠ Processed text isn't comprehensively
  removed during invoice deletion

⚠ Job record isn't comprehensively
  removed during invoice deletion

⚠ Historical S3 versions aren't
  comprehensively removed

⚠ Data lifecycle across logs/workflow
  history needs explicit policy

⚠ No complete erasure workflow
  across every data copy
```

---

# 71. Production Security Improvement Plan

A stronger production version should consider:

```text
1. Fix job-status ownership validation

2. Clear/private-scope frontend caches

3. Add MFA where requirements justify it

4. Add organization + role authorization

5. Complete password-reset experience

6. Tighten CORS

7. Add trusted backend file validation

8. Add upload/processing quotas

9. Add cost and abuse controls

10. Strengthen AI output validation

11. Minimize sensitive logs

12. Review Bedrock input minimization

13. Strengthen IAM review

14. Add security-focused monitoring

15. Test authorization boundaries
```

---

# 72. Production Data-Lifecycle Improvement Plan

For data lifecycle:

```text
1. Define retention requirements

2. Inventory every data location

3. Populate job TTL

4. Delete processed text with invoice

5. Delete/expire job records

6. Handle S3 historical versions
   according to retention policy

7. Define log retention

8. Define workflow-history retention

9. Define event/notification retention

10. Implement deletion audit trail

11. Test complete deletion

12. Document exceptions such as
    legally required retention
```

---

# 73. Interview Preparation — 10 Questions

## Q1 — How do you secure your application?

**Difficulty:** Basic

### Word-by-word practice answer

> “I use multiple security layers rather than relying on one service. Cognito handles user authentication, API Gateway uses a Cognito authorizer, and backend Lambdas derive the tenant identity from validated Cognito claims instead of trusting a user ID supplied by the browser. S3 buckets are private, uploads use short-lived presigned URLs, AWS service access is controlled through IAM, and the frontend is delivered through CloudFront with controlled S3 origin access.”

---

## Q2 — What is the difference between authentication and authorization?

**Difficulty:** Basic

### Word-by-word practice answer

> “Authentication answers who the user is, while authorization answers what that authenticated user is allowed to access. In my project, Cognito authenticates the user. After authentication, API Gateway and the backend enforce access, and the application uses the Cognito `sub` claim as the tenant identity for tenant-scoped invoice operations.”

---

## Q3 — How do you implement tenant isolation?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The backend derives the tenant ID from the authenticated Cognito `sub` claim rather than accepting tenant identity from the client. Invoice records use tenant ID together with invoice ID, and upload object keys are generated with tenant context. This provides user-level isolation. I would not call the current design full organization-level multi-tenancy because there is no organization membership or role hierarchy.”

---

## Q4 — Did you identify any authorization vulnerability?

**Difficulty:** Intermediate / Pressure

### Word-by-word practice answer

> “Yes. One gap exists in the job-status flow. The API performs a tenant-scoped invoice lookup, but the later processing-job lookup by `job_<invoice_id>` does not independently compare the job record's tenant ID with the authenticated requester. That can potentially disclose status, stage or error information if another invoice identifier is known. I would fix it by enforcing tenant ownership directly on every job lookup.”

---

## Q5 — Are presigned S3 URLs secure?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “A presigned URL provides temporary permission for a specific S3 operation, so it allows the browser to upload directly without receiving permanent AWS credentials. In my project, the backend generates a tenant-specific object key and returns a short-lived PUT URL. However, the URL should still be treated as sensitive while valid, and backend-side file validation is needed because frontend MIME-type and size checks can be bypassed.”

---

## Q6 — What is the data lifecycle of an invoice?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The original invoice is uploaded to private S3 storage. The processing pipeline uses Textract for extraction, sends invoice-derived data to Bedrock for analysis, applies deterministic Python risk rules, stores the final operational result in DynamoDB and stores extracted text in the processed S3 area. A separate DynamoDB processing-job record tracks status. Therefore deletion has to consider multiple locations rather than only deleting the final invoice row.”

---

## Q7 — How does DynamoDB TTL work in your project?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The processing-jobs table is configured with `ttl` as its TTL attribute, which is intended to support automatic expiration of temporary job records. However, the current `create_job()` logic does not populate that attribute, so the infrastructure supports TTL but newly created jobs do not actually receive the expiration value required for automatic cleanup. I would calculate the expiration timestamp from the required retention policy and store it when creating the job.”

---

## Q8 — Does deleting an invoice remove all its data?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “Not completely in the current implementation. The delete flow performs a tenant-scoped invoice deletion and attempts to delete the original S3 object, but related processing-job data, processed text and historical S3 versions are not comprehensively removed. For production I would build a complete data map and deletion workflow covering every relevant storage location according to the organization's retention and compliance requirements.”

---

## Q9 — What security concern exists with Bedrock?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The Bedrock prompt contains structured invoice fields, line items and raw OCR text, so invoice-derived information crosses into the model-inference boundary. I would minimize the input to only what is required, avoid logging sensitive prompts unnecessarily, validate model output before using it, and treat document text as untrusted input. Because raw OCR text is included in the prompt, prompt injection is also a threat I would consider, although I do not claim that a successful prompt-injection exploit has been demonstrated in this project.”

---

## Q10 — How would you make the project more secure for production?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “I would first close the known authorization gaps by enforcing tenant ownership on every resource lookup and isolating frontend caches between users. I would add stronger backend upload validation, tighter CORS, application-level quotas and abuse controls, and strengthen AI-output validation. For enterprise access I would introduce organization membership and role-based authorization where required. On the data side, I would define explicit retention policies, populate the job TTL, implement complete deletion across DynamoDB, processed S3 data and relevant object versions, minimize sensitive logging and test the entire deletion and authorization lifecycle.”

---

# 74. Interview Pressure Chain

An interviewer starts:

> **“How did you secure NovaMind AI?”**

Then:

```text
What does Cognito do?
        ↓
Authentication or authorization?
        ↓
What does API Gateway do?
        ↓
Where does tenant_id come from?
        ↓
Why don't you trust user_id from React?
        ↓
What is Cognito sub?
        ↓
Is this true enterprise multi-tenancy?
        ↓
What happens if User A knows
User B's invoice ID?
        ↓
Did you find any authorization gaps?
        ↓
Explain the job-status problem.
        ↓
How would you fix it?
        ↓
Are S3 buckets public?
        ↓
Then how can the browser upload?
        ↓
What is a presigned URL?
        ↓
Can frontend validation be bypassed?
        ↓
How do you validate actual files?
        ↓
How does IAM differ from Cognito?
        ↓
What is least privilege?
        ↓
What happens on logout?
        ↓
Can React Query leak stale user data?
        ↓
What data is sent to Bedrock?
        ↓
Could document text contain
malicious instructions?
        ↓
Where is invoice data stored?
        ↓
How is it deleted?
        ↓
Does delete remove everything?
        ↓
What is DynamoDB TTL?
        ↓
Is TTL actually working for jobs?
        ↓
How would you make deletion complete?
```

If you can answer this chain, you understand **application security**, not simply “Cognito authentication.”

---

# 75. Troubleshooting Scenario — Unauthorized Access

Interviewer:

> **“A user reports that they can see processing information for an invoice that isn't theirs. Where would you investigate?”**

### Word-by-word answer

> “I would first identify whether the data came from the backend or stale frontend cache. If the API actually returned another user's data, I would trace the authorization path from the Cognito token through API Gateway and the backend ownership check. In this project I would specifically inspect the job-status endpoint because the job lookup does not independently validate the processing job's tenant ID against the authenticated user. If the backend correctly rejected the request but the browser still displayed old information, I would investigate React Query cache isolation and logout-state cleanup.”

Excellent answer because you understand **both possible security boundaries**.

---

# 76. Troubleshooting Scenario — Delete Request

Interviewer:

> **“A customer asks you to prove that an invoice was completely deleted. What would you check?”**

### Word-by-word answer

> “I would not verify only the invoice row. I would start from the invoice ID and enumerate every storage location associated with that document. I would check the original S3 object and relevant versions, the DynamoDB invoice item, the processing-job item, the processed-text object, and any other retained operational copies according to the system's retention policy. I would also review whether logs, workflow history or notification data are subject to separate retention requirements. The current implementation does not yet provide complete deletion across all of those locations, so I would treat comprehensive erasure as a production improvement.”

---

# 77. Architecture Decision Question

Interviewer:

> **“Why don't you just make the S3 bucket public so React can upload directly?”**

### Strong answer

> “A public bucket would unnecessarily expose the storage layer. Instead, the application keeps the bucket private and the authenticated backend generates a short-lived presigned URL for a specific upload operation and tenant-specific object key. That lets the browser upload directly to S3 without receiving permanent AWS credentials or making the bucket public.”

---

# 78. Security Layers — Interview Mental Model

Memorize this architecture:

```text
USER
 │
 ▼
Cognito
 │
 │ Authentication
 ▼
Token
 │
 ▼
API Gateway Authorizer
 │
 │ Token validation
 ▼
Lambda
 │
 │ tenant_id from claims
 ▼
Ownership Check
 │
 ▼
S3 / DynamoDB
 │
 │ IAM
 ▼
AWS Resources
```

And don't forget the browser:

```text
Logout
  ↓
Clear Auth
+
Clear Private Cache
```

---

# 79. Data Lifecycle — Interview Mental Model

```text
                    INVOICE
                       │
                       ▼
                 Original S3
                       │
                       ▼
                    OCR
                       │
              ┌────────┴────────┐
              ▼                 ▼
        Processed Text       Bedrock
              │                 │
              └────────┬────────┘
                       ▼
                  Risk Rules
                       │
                       ▼
                   DynamoDB
                       │
                       ▼
                  Application
                       │
                       ▼
                    DELETE
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
 Original Object   Invoice Item   Related Data
                                     │
                                  must also
                                  be handled
```

The key idea:

> **Data lifecycle does not end when processing finishes. It ends when every required copy has reached its defined retention or deletion outcome.**

---

# 80. Five Things You Must Remember

**1. Authentication ≠ authorization.**

```text
Authentication
→ Who are you?

Authorization
→ What can you access?
```

**2. Never trust tenant identity from the browser.**

```text
Cognito token
↓
validated sub
↓
tenant_id
```

**3. The project has a real job-status ownership gap.**

```text
job_<invoice_id>
↓
tenant ownership needs stronger
independent enforcement
```

**4. Data exists in multiple places.**

```text
S3
+
DynamoDB
+
Jobs
+
Processed text
+
Operational traces
```

Therefore:

```text
Delete one row
≠
complete deletion
```

**5. TTL infrastructure exists, but job creation doesn't populate `ttl`.**

```text
TTL configured ✓
TTL value written ✗
Automatic cleanup incomplete
```

---

# 81. Your 30-Second Interview Answer

> “I use defense in depth for security. Cognito authenticates users, API Gateway validates the token, and backend Lambdas derive tenant identity from the validated Cognito `sub` rather than trusting client-supplied identity. Invoice storage is tenant-aware, S3 buckets are private, uploads use short-lived presigned URLs, and AWS service permissions are controlled through IAM. I also identified areas to improve, including job-status ownership validation, frontend cache isolation, stronger backend file validation and enterprise role-based authorization. For data lifecycle, invoice data exists across S3, DynamoDB and processing records, and the current delete flow does not yet remove every related artifact. The jobs table has TTL configured, but `create_job()` does not currently populate the TTL value, so cleanup also needs improvement.”

---

# 82. Your 10-Second Mental Model

For security:

```text
Authenticate
   ↓
Authorize
   ↓
Isolate
   ↓
Least Privilege
   ↓
Encrypt
   ↓
Monitor
```

For data:

```text
Create
 ↓
Process
 ↓
Store
 ↓
Use
 ↓
Retain
 ↓
Delete
```

One sentence to remember:

> **“Security controls who can access the data; data lifecycle controls what happens to that data from creation through final deletion.”**

---

# 83. Check Your Understanding

Before moving to **`20-Reliability-Troubleshooting-and-Observability.md`**, answer these three without looking above.

**Question 1:** Why is this:

```text
React sends:
tenant_id = "user123"
```

less secure than:

```text
Cognito Token
      ↓
Validated sub
      ↓
tenant_id
```

and which approach does your project use?

**Question 2:** A user clicks **Delete Invoice** and the DynamoDB invoice record disappears. Why can you **not** immediately say:

> “All of that user's invoice data has been permanently deleted.”

Name the other locations you would investigate.

**Question 3:** Explain this finding:

```text
Processing Jobs Table
        ↓
TTL configured on "ttl"
        ↓
create_job()
doesn't populate "ttl"
        ↓
Automatic cleanup incomplete
```

Why is this a good example of the difference between **infrastructure configuration** and **actual application behavior**?