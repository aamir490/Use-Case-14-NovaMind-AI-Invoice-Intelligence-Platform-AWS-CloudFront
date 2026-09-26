# Your question

**Start `06-Presigned-S3-Upload-and-Ingestion.md`.**

This file focuses on one very important boundary:

> **How does an authenticated user upload an invoice securely and efficiently from the browser into the asynchronous processing pipeline?**

According to the Codex analysis, the real project flow is:

**React → `POST /invoices/upload-url` → API Lambda → 5-minute presigned PUT URL → direct S3 upload → S3 ObjectCreated event → SQS.** The backend also creates a `PENDING` job before returning the upload URL. :chatgpt-content-reference{index="0"}

---

# 06 — Presigned S3 Upload and Ingestion

## 1. What Will I Learn?

In this file, I will understand:

- Why the browser does not upload the invoice through Lambda
- What an S3 presigned URL is
- How authentication connects to upload authorization
- How the backend generates an invoice ID
- Why a `PENDING` job is created before upload
- How the S3 object key contains tenant information
- Why the presigned URL expires
- What the browser validates before upload
- What the backend currently validates
- What happens after S3 receives the invoice
- How S3 connects to SQS
- Security limitations in the current upload implementation
- Production improvements
- Interview questions about the upload architecture

---

# 2. Where Are We in the Architecture?

So far:

```text
User
 ↓
React
 ↓
Cognito Authentication
 ↓
API Gateway
 ↓
Generate Presigned URL
 ↓
Browser
 ↓
S3 Upload
 ↓
S3 Event
 ↓
SQS
 ↓
Processing Pipeline
```

File 06 focuses mainly on:

```text
┌─────────────────────────────────────┐
│ React                               │
│   ↓                                 │
│ API Gateway                         │
│   ↓                                 │
│ Upload Lambda                       │
│   ↓                                 │
│ Presigned URL                       │
│   ↓                                 │
│ Browser ───────────────→ S3         │
│                         ↓           │
│                    ObjectCreated    │
│                         ↓           │
│                        SQS          │
└─────────────────────────────────────┘
```

---

# 3. First Understand the Problem

Suppose the user selects:

```text
invoice.pdf
```

We need to move that file from:

```text
User's Browser
```

to:

```text
Amazon S3
```

One possible architecture would be:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

The file travels through the application backend.

But this project uses a different approach:

```text
Browser ───────────────→ S3
       direct upload
```

The backend provides temporary permission to perform that upload.

That permission is the **presigned URL**.

---

# 4. What Is a Presigned URL?

In very simple English:

> **A presigned URL is a temporary URL generated using AWS credentials that allows a client to perform a specific S3 operation without giving that client AWS credentials.**

For this project:

```text
Authenticated user
       ↓
Backend
       ↓
Generate temporary S3 PUT URL
       ↓
Browser receives URL
       ↓
Browser uploads invoice directly to S3
```

The browser does **not** receive your Lambda's IAM credentials.

---

# 5. Why Is This Useful?

Imagine giving the frontend permanent AWS credentials:

```text
React
 ↓
AWS Access Key
AWS Secret Key
 ↓
S3
```

That would be a serious security design problem.

Instead:

```text
Backend has AWS permission
        ↓
Creates limited temporary URL
        ↓
Frontend gets only URL
```

The browser receives delegated access for a specific operation.

---

# 6. Actual Project Upload Flow

Codex traced this exact high-level sequence:

```text
1. User selects one file
       ↓
2. Frontend validates basic file properties
       ↓
3. POST /invoices/upload-url
       ↓
4. Backend gets tenant from Cognito claims
       ↓
5. Backend generates invoice ID
       ↓
6. Backend creates PENDING job
       ↓
7. Backend creates 5-minute presigned PUT URL
       ↓
8. URL returned to browser
       ↓
9. Browser uploads directly to S3
       ↓
10. S3 ObjectCreated event
       ↓
11. SQS
```

:chatgpt-content-reference{index="1"}

Let's understand each step.

---

# 7. Step 1 — User Selects an Invoice

The upload UI accepts one selected file.

For example:

```text
invoice-2026.pdf
```

The frontend performs some validation before asking the backend for an upload URL.

Codex found two important browser-side checks:

```text
MIME type
+
10 MiB size limit
```

:chatgpt-content-reference{index="2"}

---

# 8. MIME Type Validation

MIME type describes the expected type of file.

For example:

```text
application/pdf
image/jpeg
image/png
```

The project has an explicit content-type allowlist as part of its upload controls. :chatgpt-content-reference{index="3"}

Conceptually:

```text
Selected file
      ↓
Allowed content type?
   ┌──┴──┐
  YES    NO
   ↓      ↓
Continue Reject
```

---

# 9. Frontend Size Validation

The browser also checks a:

```text
10 MiB
```

file-size limit before upload. :chatgpt-content-reference{index="4"}

Conceptually:

```text
invoice.pdf

Size = 4 MiB
   ↓
Allowed


invoice.pdf

Size = 15 MiB
   ↓
Reject in UI
```

But there is an important security limitation here.

We'll return to it later.

---

# 10. Step 2 — Frontend Requests an Upload URL

The browser calls:

```text
POST /invoices/upload-url
```

:chatgpt-content-reference{index="5"}

Conceptually:

```text
React
 ↓
POST /invoices/upload-url
 ↓
API Gateway
 ↓
Upload Lambda
```

Because this is a protected API, the authenticated identity is available through the Cognito-authorized request flow studied in File 05.

---

# 11. Step 3 — Backend Gets the Tenant

The backend derives the current tenant from validated authentication claims.

Recall:

```text
Cognito
 ↓
Validated sub
 ↓
tenant_id
```

Therefore the backend doesn't need the browser to say:

```text
"I belong to tenant ABC."
```

and blindly trust it.

The identity comes from the authenticated request.

---

# 12. Step 4 — Backend Generates an Invoice ID

Codex found that the backend generates an ID resembling:

```text
inv_YYYYMMDD_<random-suffix>
```

:chatgpt-content-reference{index="6"}

For example, conceptually:

```text
inv_20260926_a8f21c
```

The important concept is:

> **The server controls the generated invoice identifier.**

The user isn't simply choosing arbitrary application invoice IDs.

---

# 13. Step 5 — Tenant-Aware S3 Object Key

The generated upload key includes tenant/user context.

Conceptually:

```text
invoices/
   ↓
tenant-id/
   ↓
invoice-id/
   ↓
document.pdf
```

The exact repository key structure should be followed when working with the implementation, but Codex verifies that generated upload keys are **tenant-prefixed**. :chatgpt-content-reference{index="7"}

This becomes useful later because the processing system can recover identity information from the S3 object key.

---

# 14. Step 6 — Create the Processing Job

Before returning the upload URL, the backend creates a job record:

```text
job_<invoice_id>
```

with status:

```text
PENDING
```

Codex explicitly traced this behavior. :chatgpt-content-reference{index="8"}

Conceptually:

```text
Invoice ID created
       ↓
Create Job
       ↓
job_inv_xxx

status = PENDING
```

---

# 15. Why Create a Job Before Processing?

Because invoice processing is asynchronous.

The application needs something it can use to track:

```text
Has processing started?

Is it still running?

Did it complete?

Did it fail?
```

The job provides persistent processing state.

Conceptually:

```text
PENDING
   ↓
PROCESSING
   ↓
COMPLETED
```

or:

```text
PENDING
   ↓
PROCESSING
   ↓
FAILED
```

We'll study job-state behavior more deeply later.

---

# 16. Step 7 — Backend Generates Presigned PUT URL

The backend creates a presigned URL for uploading the object.

The operation is conceptually:

```text
PUT object into this S3 location
```

Hence:

> **Presigned PUT URL**

The URL is scoped to the generated S3 object operation rather than providing general access to the bucket.

---

# 17. The URL Is Short-Lived

Codex found that the generated URL is valid for approximately:

```text
5 minutes
```

:chatgpt-content-reference{index="9"}

Think:

```text
URL generated
    ↓
Temporary upload window
    ↓
URL expires
```

Why?

Because a URL that remained usable indefinitely would unnecessarily increase exposure.

---

# 18. What Does the Backend Return?

At a conceptual level, the frontend needs information such as:

```text
invoice_id
presigned_upload_url
```

The exact response structure should come from the implementation.

The important sequence is:

```text
Backend
 ↓
Returns upload information
 ↓
React
```

Then React has everything it needs to perform the direct upload.

---

# 19. Step 8 — Browser Uploads Directly to S3

Now the important part:

```text
React
  │
  │ PUT invoice bytes
  │ using presigned URL
  ▼
Amazon S3
```

The actual document does not need to pass through the API Lambda.

So the architecture separates:

```text
CONTROL PATH
```

from:

```text
DATA PATH
```

---

# 20. Control Path vs Data Path

This is a useful architecture concept.

## Control path

```text
React
 ↓
API Gateway
 ↓
Lambda
 ↓
Generate permission / URL
```

The backend decides:

> Where can this authenticated user upload?

## Data path

```text
Browser
 ↓
Invoice bytes
 ↓
S3
```

The file itself moves directly to storage.

This is one of the main reasons presigned uploads are useful.

---

# 21. Why Not Upload Through Lambda?

Suppose a 9 MiB invoice goes:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

The application backend becomes part of the file-transfer path.

With a presigned URL:

```text
Browser
       │
       │ invoice.pdf
       ▼
      S3
```

while the backend handles only:

```text
Authentication
Authorization
Object naming
Temporary upload permission
Job creation
```

This reduces unnecessary backend involvement in the file transfer.

---

# 22. Important Security Point

A presigned URL does **not** mean:

```text
S3 bucket = public
```

The project uses private S3 buckets. :chatgpt-content-reference{index="10"}

Think:

```text
Private S3 Bucket

Normally:
DENY browser direct access

But:

Valid presigned URL
       ↓
Temporarily allow
specific signed operation
```

That's very different from public object access.

---

# 23. Step 9 — Invoice Reaches S3

Once the upload succeeds:

```text
S3

invoices/...
   └── invoice.pdf
```

The document is now durable object storage.

But processing still hasn't finished.

Now S3 becomes the beginning of the **event-driven ingestion pipeline**.

---

# 24. Step 10 — S3 ObjectCreated Event

Codex found an S3 notification configured for the:

```text
invoices/
```

prefix. :chatgpt-content-reference{index="11"}

When an object is created in that relevant location:

```text
invoice.pdf
     ↓
S3 ObjectCreated
     ↓
Event
```

The system reacts to the upload.

---

# 25. S3 Doesn't Perform OCR

Important distinction:

```text
S3
=
stores invoice
+
produces event
```

It does not:

```text
❌ OCR the invoice

❌ invoke Nova Micro itself

❌ calculate risk

❌ store DynamoDB results
```

Those responsibilities belong to later processing components.

---

# 26. Step 11 — S3 Sends Event to SQS

The event goes to the processing queue.

```text
Amazon S3
    ↓
ObjectCreated
    ↓
Amazon SQS
```

This is the handoff between:

```text
INGESTION
```

and:

```text
PROCESSING
```

---

# 27. Why S3 → SQS?

We could imagine:

```text
S3
 ↓
Processing Lambda
```

But this project introduces SQS:

```text
S3
 ↓
SQS
 ↓
Trigger Lambda
```

The queue helps **decouple** file arrival from workflow startup.

Suppose many uploads arrive:

```text
Invoice 1 ─┐
Invoice 2 ─┤
Invoice 3 ─┤
Invoice 4 ─┼──→ SQS → Consumer
Invoice 5 ─┘
```

SQS can buffer pending work.

---

# 28. What Is Actually Inside the Event?

At a conceptual level, the S3 event contains information that identifies the uploaded object.

For example:

```text
Bucket
Object key
Event information
```

The trigger needs enough information to determine:

```text
Which invoice was uploaded?
Which tenant does it belong to?
Where is the object?
```

Codex found that the queue bridge reads the nested S3 event and extracts the tenant and invoice ID from the object key. :chatgpt-content-reference{index="12"}

---

# 29. Full Upload-to-Queue Flow

Now put everything together:

```text
USER
 ↓
Select invoice
 ↓
React validation
 ↓
POST /invoices/upload-url
 ↓
API Gateway
 ↓
Upload Lambda
 ↓
Validated Cognito identity
 ↓
Generate invoice ID
 ↓
Generate tenant-prefixed S3 key
 ↓
Create PENDING job
 ↓
Generate 5-minute presigned PUT URL
 ↓
Return URL
 ↓
Browser
 ↓
Direct PUT
 ↓
Private S3 Bucket
 ↓
ObjectCreated event
 ↓
SQS
```

That's File 06 in one diagram.

---

# 30. Current Security Limitation — File Size

This is important.

The frontend enforces the:

```text
10 MiB
```

limit.

But Codex found:

> **The backend does not independently verify the actual uploaded object size before OCR.** :chatgpt-content-reference{index="13"}

Why is this important?

Because:

```text
Frontend validation
≠
trusted security boundary
```

Client-side code can potentially be bypassed.

---

# 31. Client Validation vs Server Validation

Think:

```text
CLIENT VALIDATION
=
Better user experience
+
Early rejection
```

but:

```text
SERVER-SIDE VALIDATION
=
Trusted enforcement
```

A production system should not assume:

> “React rejected large files, therefore large files can never reach S3.”

The backend/processing path should verify important constraints independently.

---

# 32. Current Validation Gap

Codex specifically found that the backend does not fully verify:

```text
Actual object size

Actual uploaded content

Page count

Document structure
```

before OCR. :chatgpt-content-reference{index="14"}

So don't say in an interview:

> “All invoice files are fully validated server-side before processing.”

That would be inaccurate.

---

# 33. Content Type Is Not the Same as File Content

Suppose something claims:

```text
Content-Type: application/pdf
```

That alone doesn't prove the bytes are truly a valid PDF.

Conceptually:

```text
Metadata says:
"I am PDF"

Actual content:
maybe something else
```

This is why stronger production validation can inspect the actual object before expensive processing.

---

# 34. Why This Matters for Cost

This project invokes paid/managed processing services.

The downstream path includes:

```text
S3
 ↓
Lambda
 ↓
Textract
 ↓
Bedrock
```

If invalid or abusive input reaches that path unnecessarily, it can consume resources.

So input validation is not only about:

```text
Security
```

It can also affect:

```text
Reliability
Cost control
Service quotas
```

---

# 35. Another Important Gap — Processing Controls

Codex also found no application-specific:

```text
Rate limits
Tenant budgets
Processing concurrency controls
```

:chatgpt-content-reference{index="15"}

This matters because authenticated users could potentially create substantial processing workload.

A production version could evaluate controls such as:

```text
Per-user upload limits

Rate limits

Processing quotas

Concurrency limits

Cost alarms
```

based on actual business requirements.

---

# 36. Broad S3 CORS

Codex also identifies:

> **Broad S3 CORS** as a current security gap. :chatgpt-content-reference{index="16"}

Remember that browser direct upload requires appropriate CORS configuration.

But:

> CORS should be configured narrowly enough for the actual trusted frontend behavior.

We'll revisit CORS when studying deployment/security.

---

# 37. Failure Scenario — Presigned URL Expires

Suppose:

```text
12:00
URL generated

Valid for ~5 minutes

12:06
User attempts upload
```

The upload may fail because the temporary authorization is no longer valid.

The correct application behavior would be to request a new upload URL rather than making the original URL permanent.

---

# 38. Failure Scenario — Upload URL Created but User Never Uploads

Interesting case:

```text
Backend creates:

job_inv_123
status=PENDING
```

Then:

```text
User closes browser
```

No S3 upload occurs.

Now there may be a:

```text
PENDING job
```

without corresponding processing.

This is one reason lifecycle/cleanup behavior matters in production systems.

Codex classifies lifecycle management as partial. :chatgpt-content-reference{index="17"}

---

# 39. Failure Scenario — S3 Upload Succeeds but Processing Doesn't Start

Troubleshooting should follow the boundary:

```text
Is object in S3?
       ↓ YES
Was ObjectCreated notification generated/routed?
       ↓
Did message reach SQS?
       ↓
Did trigger Lambda receive it?
```

Don't immediately debug Bedrock.

Bedrock is much later in the pipeline.

This is why understanding application flow makes troubleshooting easier.

---

# 40. Production Improvement Model

A stronger ingestion boundary could conceptually look like:

```text
Authenticated User
       ↓
Request upload permission
       ↓
Server generates controlled key
       ↓
Short-lived presigned URL
       ↓
Direct S3 upload
       ↓
Trusted backend validation
       ↓
Check actual size
Check actual content
Check document rules
       ↓
Only then
       ↓
OCR / AI processing
```

This is a **proposed improvement**, not a claim about the current implementation.

---

# 41. What Is Implemented vs What Needs Improvement?

### IMPLEMENTED

```text
✓ Authenticated upload API

✓ Identity derived from validated claims

✓ Generated invoice ID

✓ Tenant-prefixed upload key

✓ PENDING job creation

✓ Presigned PUT URL

✓ ~5-minute URL lifetime

✓ Direct browser → S3 upload

✓ Private S3 bucket

✓ Content-type allowlist

✓ S3 ObjectCreated → SQS
```

:chatgpt-content-reference{index="18"}

### PARTIAL / NEEDS IMPROVEMENT

```text
⚠ Size limit mainly enforced in browser

⚠ Actual uploaded content not fully verified

⚠ Page count not verified before OCR

⚠ Document structure not fully verified

⚠ Broad S3 CORS

⚠ No application-specific rate limits

⚠ No tenant processing budgets

⚠ No explicit processing concurrency controls
```

:chatgpt-content-reference{index="19"}

This separation is extremely important for interviews.

---

# 42. Interview Preparation — 10 Questions

## Q1 — How does invoice upload work in your project?

**Difficulty:** Basic

### Word-by-word practice answer

> “After authentication, the React frontend calls the upload API to request a presigned S3 URL. The backend derives the tenant from the validated Cognito claims, generates an invoice ID and tenant-prefixed object key, creates a pending processing job, and returns a short-lived presigned PUT URL. The browser then uploads the invoice directly to the private S3 bucket. After the object is created, S3 sends an event to SQS, which begins the asynchronous processing path.”

---

# Q2 — What is a presigned URL?

**Difficulty:** Basic

### Word-by-word practice answer

> “A presigned URL is a temporary signed URL that allows a client to perform a specific S3 operation without receiving permanent AWS credentials. In my project, the backend generates a short-lived presigned PUT URL so the authenticated user's browser can upload an invoice directly to a controlled S3 object location.”

---

# Q3 — Why didn't you upload the invoice through Lambda?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “I use direct S3 upload so the application backend does not need to proxy the invoice bytes through API Gateway and Lambda. The backend remains responsible for authentication, object naming, job creation and temporary upload authorization, while S3 handles the actual file transfer. This separates the control path from the data-transfer path.”

---

# Q4 — Is your S3 bucket public because the browser uploads directly to it?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “No. The upload bucket is private. The browser receives temporary permission for a specific signed S3 operation through the presigned URL. Direct browser upload does not require making the bucket publicly accessible.”

---

# Q5 — How long is the upload URL valid?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “The current implementation generates the presigned PUT URL with an approximately five-minute lifetime. The short expiration limits how long that delegated upload permission remains usable.”

This is directly verified by the Codex flow. :chatgpt-content-reference{index="20"}

---

# Q6 — How do you prevent one user from uploading into another user's location?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The backend derives the tenant from the validated Cognito subject claim rather than trusting an arbitrary user identifier from the browser. It then generates the invoice ID and tenant-prefixed S3 object key itself before creating the presigned URL. This gives the backend control over the upload destination.”

---

# Q7 — What happens after the upload reaches S3?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “An S3 ObjectCreated event for the configured invoice prefix is sent to SQS. The queue decouples ingestion from processing. A queue-triggered Lambda later reads the nested S3 event, extracts the tenant and invoice information from the object key, and starts the Step Functions processing workflow.”

:chatgpt-content-reference{index="21"}

---

# Q8 — How do you validate uploaded invoices?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current implementation has an explicit content-type allowlist, and the frontend checks MIME type and a 10 MiB file-size limit. However, I would not describe the validation as complete server-side enforcement. The Codex review found that the backend does not independently verify the actual uploaded content, object size, page count or document structure before OCR. I would strengthen those controls for production.”

---

# Q9 — What if a user requests an upload URL but never uploads the file?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current flow creates the pending job before returning the presigned URL, so it is possible for a pending job to exist even if the user never completes the S3 upload. For production I would define lifecycle handling for abandoned pending jobs, such as expiration or cleanup based on timestamps, rather than allowing stale jobs to remain indefinitely.”

---

# Q10 — How would you make the upload pipeline more production-ready?

**Difficulty:** Advanced / Design

### Word-by-word practice answer

> “I would keep the direct presigned S3 upload pattern, but strengthen the trusted ingestion boundary. I would verify the actual uploaded object size and content before expensive processing, validate document structure and page limits, tighten S3 CORS, introduce appropriate per-user rate or workload controls, clean up abandoned pending jobs, and add tests covering invalid, oversized, expired and duplicate upload scenarios. I would choose exact limits based on measured business requirements.”

---

# 43. Interview Pressure Chain

An interviewer can turn one question into this:

```text
How do users upload invoices?
        ↓
What is a presigned URL?
        ↓
Who generates it?
        ↓
Why doesn't React need AWS credentials?
        ↓
Why PUT?
        ↓
Why five minutes?
        ↓
Is S3 public?
        ↓
How do you isolate user uploads?
        ↓
What if I fake the Content-Type?
        ↓
Where is file size validated?
        ↓
Can I bypass React validation?
        ↓
What happens after S3 upload?
        ↓
Why SQS?
        ↓
What if the upload URL is created
but the user never uploads?
        ↓
How would you improve it?
```

That's why we learn the actual implementation before memorizing interview answers.

---

# 44. The One Flow to Remember

```text
Authenticated User
       ↓
React
       ↓
POST /invoices/upload-url
       ↓
API Gateway
       ↓
Upload Lambda
       ↓
claims.sub → tenant
       ↓
Generate invoice ID
       ↓
Create PENDING job
       ↓
Generate tenant-prefixed S3 key
       ↓
Generate 5-minute Presigned PUT URL
       ↓
React
       ↓
Direct upload
       ↓
Private S3 Bucket
       ↓
ObjectCreated
       ↓
SQS
```

If you understand **why every arrow exists**, you understand File 06.

---

# 45. What Comes Next?

File 06 stops here:

```text
S3
 ↓
SQS
```

The next file should begin exactly there:

```text
SQS
 ↓
Trigger Lambda
 ↓
Step Functions
```

That means `07-SQS-Trigger-Lambda-and-Idempotency.md` should go deeper into **decoupling, at-least-once delivery, retries, DLQ behavior, duplicate processing, the queue bridge, and why idempotency is one of this project's important production gaps**.