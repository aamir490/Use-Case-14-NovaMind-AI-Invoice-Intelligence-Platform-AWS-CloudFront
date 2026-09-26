# Your question

**Create `14-S3-DynamoDB-and-Application-State.md`.**

In File 13, we learned the basic difference:

```text
S3       → objects/files
DynamoDB → structured application records/state
```

Now we go one level deeper.

The important question is:

> **When one invoice moves through an asynchronous pipeline, where does its state live, and which service is the source for each kind of information?**

In NovaMind AI, a single invoice is **not represented by only one record in one place**. Its lifecycle can involve:

```text
Original document        → S3
Processing/job state     → DynamoDB
Processed artifacts      → S3
Invoice/result metadata  → DynamoDB
Frontend application     → React Query / UI state
Workflow execution       → Step Functions
```

Understanding these boundaries is essential for debugging, deletion, retries, consistency, and production design.

---

# 14 — S3, DynamoDB and Application State

## 1. What Will I Learn?

By the end of this file, I should understand:

- What application state means
- Stateful data vs stateless compute
- Why Lambda itself should not be the permanent state store
- What S3 stores
- What DynamoDB stores
- Original vs processed data
- Job state vs invoice business state
- Workflow state vs application state
- Frontend state vs backend state
- Why the same invoice exists across multiple services
- Why asynchronous systems can temporarily appear inconsistent
- Why an invoice-detail request may initially return 404
- Why `COMPLETED` doesn't necessarily mean every AI stage succeeded
- How retries can affect state
- Why duplicate events can reset or overwrite state
- Why deletion requires lifecycle coordination
- Source of truth
- State transitions
- How I would improve state management for production
- 10 interview questions and answers

---

# 2. What Is “State”?

Simple definition:

> **State is information describing the current or previous condition of the application or its data.**

For example:

```text
Invoice uploaded?
        ↓
YES

Processing started?
        ↓
YES

OCR completed?
        ↓
YES

AI completed normally?
        ↓
NO

Final result stored?
        ↓
YES
```

All of those describe **state**.

---

# 3. A Real-Life Example

Think about tracking a parcel.

The parcel itself is one thing.

But the system also stores:

```text
Order created

Payment completed

Package collected

In transit

Reached warehouse

Out for delivery

Delivered
```

The package and the package's **state** are different concepts.

Similarly:

```text
Invoice PDF
```

is not the same thing as:

```text
Invoice processing state
```

---

# 4. One Invoice Creates Multiple Pieces of State

This is the first major concept.

When the user uploads:

```text
invoice.pdf
```

the system can eventually have:

```text
                    ONE LOGICAL INVOICE
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
      Original S3       DynamoDB Job     Step Functions
        Object             Record          Execution
          │                 │                 │
          │                 ▼                 ▼
          │              Status          Workflow State
          │
          ▼
     Processing
          │
    ┌─────┴─────┐
    ▼           ▼
Processed     DynamoDB
Artifacts     Invoice Result
```

So:

> **One business entity can have state distributed across several AWS services.**

---

# 5. Why Is This Important?

Because if something fails, asking:

> “Is my invoice in the system?”

is too vague.

You need to ask:

```text
Is the S3 object present?

Was the SQS event created?

Was the workflow started?

What is the DynamoDB job status?

Did Textract finish?

Did Bedrock succeed?

Was the final invoice record written?

What does the frontend currently have cached?
```

That is how production troubleshooting works.

---

# 6. Stateful vs Stateless

Another important concept.

## Stateful

Something stores information that survives individual requests.

Examples in this architecture:

```text
S3

DynamoDB

Step Functions execution state
```

## Stateless compute

Lambda should generally process the request/event without relying on its local runtime as durable application storage.

Conceptually:

```text
Lambda starts
   ↓
Reads input
   ↓
Processes
   ↓
Reads/writes durable state externally
   ↓
Returns
```

---

# 7. Why Not Store State Inside Lambda?

Imagine:

```python
current_invoice_status = "PROCESSING"
```

stored only in a Lambda process's memory.

Then that Lambda invocation finishes.

A later request might execute on:

```text
another Lambda execution environment
```

The previous in-memory value is not a reliable durable application database.

Therefore persistent state belongs in services such as:

```text
DynamoDB

S3
```

depending on the type of data.

---

# 8. What Does S3 Represent?

For this project, S3 is primarily the **object layer**.

Conceptually:

```text
S3
│
├── Original uploaded invoice
│
├── Extracted/processed artifacts
│
└── Frontend static assets
```

For invoice processing specifically, think:

```text
Document / Artifact
        ↓
       S3
```

---

# 9. Original Invoice State

Recall the upload flow:

```text
React
   ↓
Presigned PUT URL
   ↓
S3
```

Once upload succeeds:

```text
S3 contains original invoice object
```

This becomes the document that starts the asynchronous processing pipeline.

The object key also carries important application context used by downstream processing, including information used to derive:

```text
tenant

invoice ID
```

---

# 10. What Does DynamoDB Represent?

DynamoDB is the structured **application-state layer**.

Think:

```text
DynamoDB
│
├── Job state
│
├── Invoice records
│
├── Processing information
│
├── Risk results
│
├── Metadata
│
└── Analytics-related application data
```

So if the question is:

> “Where is the PDF?”

Think:

```text
S3
```

If the question is:

> “What is this invoice's risk score?”

Think:

```text
DynamoDB application record
```

---

# 11. S3 vs DynamoDB — Mental Model

```text
┌───────────────────────┬────────────────────────┐
│ S3                    │ DynamoDB               │
├───────────────────────┼────────────────────────┤
│ Objects               │ Structured items       │
│ Original invoices     │ Invoice records        │
│ Processed artifacts   │ Job records            │
│ OCR-related artifacts │ Status                 │
│ Static frontend files │ Risk results           │
│ Large file storage    │ Application metadata   │
└───────────────────────┴────────────────────────┘
```

The important point isn't:

> “Which service is better?”

They solve different problems.

---

# 12. The Invoice Has a Lifecycle

Let's trace the state.

### Stage 1 — User requests upload

```text
POST /invoices/upload-url
```

Backend generates:

```text
invoice_id
```

and creates something conceptually like:

```text
job_<invoice_id>

status = PENDING
```

So before the actual invoice has completed processing, application state already exists.

---

# 13. Stage 2 — Browser Uploads to S3

Then:

```text
Browser
   ↓
Presigned PUT
   ↓
S3
```

Now:

```text
Original object exists
```

But the final invoice analysis still does not exist.

So at this moment:

```text
S3 object       ✓

Job             ✓

Final result    ✗
```

This is normal.

---

# 14. Stage 3 — Event-Driven Processing Starts

S3 produces the event:

```text
S3 ObjectCreated
       ↓
      SQS
       ↓
Trigger Lambda
       ↓
Step Functions
```

Now more state exists.

Conceptually:

```text
S3 object         ✓

DynamoDB job      ✓

SQS message       maybe in-flight/consumed

Workflow          running

Final result      ✗
```

This is why distributed systems are more complicated than a single database application.

---

# 15. Stage 4 — Textract

Workflow calls:

```text
Amazon Textract
```

The system extracts invoice information.

The processing pipeline now has data such as:

```text
Vendor

Invoice Number

Date

Total

Line Items

Raw Text
```

Processed/extracted artifacts can be persisted in S3 as part of the application's storage design.

---

# 16. Stage 5 — Bedrock

The extracted information becomes context for:

```text
Amazon Bedrock
      ↓
Nova Micro
```

which produces AI analysis.

Now another logical state exists:

```text
AI analysis
```

But remember File 10 and File 11:

> AI analysis can fail or degrade independently of the rest of the workflow.

---

# 17. Stage 6 — Risk Rules

Then:

```text
Extracted Fields
       +
AI Findings
       ↓
Python Rules
       ↓
Risk Score
       ↓
Risk Level
```

Now we have business-level application state:

```text
risk_score

risk_level

findings
```

---

# 18. Stage 7 — Store Final Results

The pipeline stores application results.

Conceptually:

```text
Processing Output
       │
       ├────→ S3
       │      processed artifacts
       │
       └────→ DynamoDB
              invoice/result record
              status/metadata
              risk information
```

Then the frontend can retrieve the result through the API.

---

# 19. Full State Lifecycle

Put everything together:

```text
USER
 │
 ▼
Request Upload URL
 │
 ├──────────────→ DynamoDB
 │                 Job = PENDING
 │
 ▼
Presigned URL
 │
 ▼
Upload
 │
 ▼
S3
 │
 │ Original object exists
 │
 ▼
SQS
 │
 ▼
Trigger Lambda
 │
 ▼
Step Functions
 │
 ├── Textract
 │
 ├── Bedrock
 │
 ├── Risk Rules
 │
 └── Store
 │
 ├──────────────→ S3
 │                 Artifacts
 │
 └──────────────→ DynamoDB
                   Final result
                   Job status
                   Risk data
```

---

# 20. Application State vs Workflow State

This distinction is extremely important.

## Workflow state

Step Functions knows:

```text
Which state is currently executing?

Which Lambda succeeded?

Which state failed?

Was the execution successful?
```

## Application state

DynamoDB contains business/application concepts such as:

```text
Invoice processing status

Invoice result

Risk score

Risk level
```

These are related.

But they are **not automatically the same thing**.

---

# 21. Why This Difference Matters

Suppose Step Functions successfully executes a Lambda.

Technically:

```text
Lambda state = SUCCESS
```

But inside the Lambda, Bedrock may have encountered a handled failure and returned fallback information.

Then:

```text
Step Functions state
=
SUCCESS
```

doesn't necessarily mean:

```text
AI analysis
=
SUCCESS
```

That is a subtle but important production concept.

---

# 22. Three Different Meanings of “Success”

In this project, you should mentally separate:

```text
INFRASTRUCTURE SUCCESS
```

Example:

```text
Lambda invocation succeeded
```

from:

```text
WORKFLOW SUCCESS
```

Example:

```text
Step Functions reached successful completion
```

from:

```text
BUSINESS/AI SUCCESS
```

Example:

```text
Invoice was fully analyzed
and AI produced valid findings
```

Those can differ.

---

# 23. Example

Imagine:

```text
Bedrock call
    ↓
ERROR
```

Handler catches it and returns:

```text
anomalies = []

confidence = 0
```

Then:

```text
Risk rules
    ↓
Storage
    ↓
Job COMPLETED
```

The workflow can therefore appear technically successful even though:

```text
AI analysis was unavailable
```

This is why state modeling matters.

---

# 24. Better State Model

A stronger future design could represent multiple dimensions:

```text
processing_status = COMPLETED

ocr_status = SUCCESS

ai_status = FAILED

analysis_status = DEGRADED

risk_score = 10
```

instead of only:

```text
status = COMPLETED
```

This is a **proposed improvement**, not the current implementation.

---

# 25. Why One Status Field Can Be Dangerous

Imagine the frontend shows:

```text
COMPLETED
```

The user may interpret that as:

> “Everything worked.”

But technically it may mean only:

> “The processing workflow reached its final business state.”

Those are not always equivalent.

Therefore state names need clear semantics.

---

# 26. Frontend State Is Another Layer

The backend isn't the only place containing state.

React also has state.

In this project, frontend state includes concepts such as:

```text
Authenticated user

Selected invoice

Upload state

Query results

Filters

Cached API data
```

The project uses frontend state/query management to provide the UI experience.

This means we now have:

```text
S3 state

DynamoDB state

Step Functions state

Frontend state
```

All representing different aspects of the same application.

---

# 27. Backend State vs Frontend Cache

Suppose DynamoDB now says:

```text
Invoice = COMPLETED
```

but React Query still holds an earlier cached result:

```text
Invoice detail = 404
```

Then:

```text
Backend state
≠
Frontend displayed state
```

temporarily.

This is one of the actual weaknesses identified in the project.

---

# 28. Why Can Invoice Detail Initially Return 404?

After upload, the application can navigate to the invoice-detail page quickly.

But processing is asynchronous.

Timeline:

```text
T0
Upload finished

T1
Detail page opens

T2
Invoice processing still running

T3
Final invoice record does not exist yet
```

Therefore:

```text
GET invoice detail
       ↓
404 / not found yet
```

can occur even though the system is working normally.

---

# 29. Then What Happens?

The frontend separately polls status.

The current behavior includes polling approximately every:

```text
3 seconds
```

until processing reaches:

```text
COMPLETED
```

or:

```text
FAILED
```

But there is a problem.

---

# 30. Current UI Refresh Weakness

The project analysis found that the detail query can fail before the invoice record exists.

Later:

```text
Job status → COMPLETED
```

but the status transition does not necessarily invalidate/refetch the earlier detail query.

Conceptually:

```text
Detail request
   ↓
404
   ↓
cached/error state

Meanwhile...

Status polling
   ↓
COMPLETED
   ↓
polling stops
```

But:

```text
detail query
```

may not automatically recover immediately.

This is an application-state synchronization problem.

---

# 31. Better Frontend State Handling

A stronger design could do:

```text
Status changes to COMPLETED
          ↓
Invalidate invoice-detail query
          ↓
Fetch final invoice record
          ↓
Render result
```

Conceptually:

```javascript
if (status === "COMPLETED") {
    invalidateInvoiceDetail(invoiceId)
}
```

This is conceptual improvement code, not literal repository code.

---

# 32. Why This Is a State Problem

Nothing may be wrong with:

```text
S3

DynamoDB

Step Functions
```

The backend may have completed successfully.

The problem is:

```text
Frontend cached state
```

has not synchronized with:

```text
Backend durable state
```

This is why distributed application debugging requires knowing **which state layer is stale**.

---

# 33. Another Frontend State Problem — Logout

Recall File 05.

Current logout behavior clears authentication state.

But Codex identified that it does not comprehensively clear:

```text
React Query cache

Upload state

Filter state
```

This can create:

```text
User A logs in
     ↓
Invoice data cached
     ↓
User A logs out
     ↓
User B logs in
     ↓
Old cache potentially still exists
```

That is a security-sensitive state-management issue.

---

# 34. Authentication State and Data State

These should move together.

When:

```text
Authenticated User
changes
```

private application data should be:

```text
cleared
```

or:

```text
namespaced by user
```

A safer conceptual query key is:

```text
["invoices", userId]
```

rather than only:

```text
["invoices"]
```

Again, that's a conceptual improvement.

---

# 35. State and Idempotency

Now connect this file with File 07.

SQS provides:

```text
at-least-once delivery
```

Therefore the same logical invoice event can potentially be processed more than once.

Imagine:

```text
S3 event
   ↓
SQS
   ↓
Trigger
   ↓
Job state updated
   ↓
Workflow started
```

Then duplicate delivery:

```text
Same event
   ↓
Trigger again
```

What happens to application state?

That's an idempotency question.

---

# 36. Duplicate Processing Can Affect State

Potential effects include:

```text
Job record rewritten

Status reset

Another workflow execution

Repeated Textract calls

Repeated Bedrock calls

Repeated writes

Repeated notification attempts
```

This is why state transitions must be designed together with idempotency.

---

# 37. State Machine Thinking

Instead of allowing arbitrary transitions:

```text
PENDING
→ anything
```

a stronger application can define allowed transitions.

For example:

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

Then prevent invalid transitions such as:

```text
COMPLETED
   ↓
PENDING
```

caused by duplicate events.

This is a proposed production improvement.

---

# 38. Conditional Writes

DynamoDB supports mechanisms that can help protect state transitions, such as conditional operations.

Conceptually:

```text
Update status to PROCESSING

ONLY IF

current status == PENDING
```

Then a duplicate message arriving after:

```text
COMPLETED
```

can't simply reset the state.

This is one way application-state design can support idempotency.

Do not claim this exact conditional-write strategy is already implemented unless repository evidence confirms it.

---

# 39. State Versioning

Another production pattern could add:

```text
version = 1
```

Then update:

```text
version = 2
```

and use optimistic concurrency concepts.

This can help prevent stale writers from overwriting newer state.

Again:

> **This is an improvement pattern, not a verified current implementation.**

---

# 40. What Is a Source of Truth?

A **source of truth** means:

> The authoritative place the application should trust for a particular fact.

There doesn't need to be one universal source for everything.

For example:

```text
Question:
"What is the original uploaded document?"

Source:
S3
```

```text
Question:
"What risk score did the application store?"

Source:
DynamoDB
```

```text
Question:
"What state is this Step Functions execution in?"

Source:
Step Functions
```

```text
Question:
"What is currently displayed on screen?"

Source:
Frontend state
```

Different questions can have different authoritative sources.

---

# 41. Don't Treat the Frontend as Source of Truth

Suppose React says:

```text
status = PROCESSING
```

but DynamoDB says:

```text
status = COMPLETED
```

The browser may simply be stale.

Likewise, never trust a client-provided value such as:

```text
risk_score = 0
```

as authoritative business state.

Business results should come from trusted backend processing.

---

# 42. S3 Object Key as Application Context

The uploaded object's key isn't only a random filename.

The processing flow uses key structure to derive context such as:

```text
tenant

invoice ID
```

This is convenient because downstream processing can understand which logical invoice the object belongs to.

But it also means:

> **Object-key design becomes part of the application's data model.**

---

# 43. Why Object-Key Design Matters

Suppose conceptually:

```text
invoices/
   tenant-A/
      inv-001.pdf
```

The structure helps connect:

```text
S3 object
```

with:

```text
tenant
+
invoice
```

This can help with:

```text
processing

organization

ownership context

cleanup
```

But the exact repository key format should be taken from implementation evidence rather than invented from this conceptual example.

---

# 44. S3 Isn't a Transaction With DynamoDB

This is an important distributed-systems concept.

Imagine:

```text
1. Write S3 object ✓

2. Write DynamoDB record ✗
```

Now:

```text
S3 has data
```

but:

```text
DynamoDB does not
```

Or the reverse could happen in another workflow.

These services do not magically become one ACID transaction simply because your application uses both.

---

# 45. Partial Failure

Suppose storage stage does:

```text
Write processed artifact to S3
          ↓
SUCCESS
          ↓
Write invoice result to DynamoDB
          ↓
FAILURE
```

Now state is inconsistent:

```text
Processed S3 artifact ✓

DynamoDB result       ✗
```

A robust system must decide:

```text
Retry?

Compensate?

Mark failed?

Reconcile later?
```

This is a distributed-state problem.

---

# 46. Why Retries Must Be Idempotent

Now imagine retrying the failed storage step.

The retry should ideally produce:

```text
Same final desired state
```

rather than:

```text
Duplicate records

Duplicate notifications

Corrupted status

Repeated side effects
```

So these concepts connect:

```text
State
+
Retries
+
Idempotency
+
Error handling
```

You cannot design them independently.

---

# 47. Eventual Consistency at the Application Level

Even without focusing narrowly on DynamoDB consistency modes, the overall architecture is inherently asynchronous.

At time T1:

```text
S3 upload complete
```

At T2:

```text
workflow running
```

At T3:

```text
DynamoDB final result stored
```

At T4:

```text
frontend refreshes
```

Therefore different parts of the application can temporarily have different views of progress.

Think:

> **The whole system converges toward the final state over time.**

---

# 48. This Is Why Polling Exists

If processing were synchronous:

```text
Request
   ↓
Wait
   ↓
Complete response
```

the frontend would get the final result directly.

But here:

```text
Upload
   ↓
Async processing
   ↓
Return control to user
```

so the frontend needs another mechanism to discover progress.

Current mechanism:

```text
Polling
```

roughly every few seconds.

---

# 49. Could We Avoid Polling?

Yes, in a future design.

Alternatives might include:

```text
WebSocket

Server-Sent Events

AppSync subscription

Push notification patterns
```

But those add architectural complexity.

For the current project, polling is simpler.

Do not claim these alternatives are implemented.

---

# 50. Deletion Is Also a State Transition

Think about deletion as:

```text
ACTIVE
   ↓
DELETE REQUESTED
   ↓
CLEANUP
   ↓
DELETED
```

rather than simply:

```text
delete one DynamoDB item
```

because the logical invoice may exist in multiple places.

---

# 51. Current Deletion Problem

The project currently deletes the tenant-scoped invoice record and attempts deletion of the original S3 object.

But related data can remain:

```text
Job record

Processed text/artifacts

Historical S3 versions
```

Therefore the logical state can become:

```text
Invoice record       deleted

Original current S3  deleted/attempted

Job state            still exists

Processed artifact   still exists
```

That's incomplete lifecycle management.

---

# 52. Better Deletion State Machine

A stronger future design might be:

```text
DELETE REQUESTED
       ↓
Verify Ownership
       ↓
Delete/expire processed artifacts
       ↓
Delete original object/version data
       ↓
Delete job state
       ↓
Delete invoice state
       ↓
Record audit outcome
       ↓
DELETED
```

The exact order depends on business and compliance requirements.

This is proposed architecture, not current behavior.

---

# 53. Retention vs Deletion

Production systems often need both concepts.

### Deletion

```text
Remove data because
the user/business requests it.
```

### Retention

```text
Keep data for a defined period,
then expire/archive/delete it.
```

For example:

```text
Original invoices → X days

Processed artifacts → Y days

Operational logs → Z days
```

Those values must come from actual business/compliance requirements.

Do not invent retention periods.

---

# 54. S3 Lifecycle Policies

S3 lifecycle rules can help automate:

```text
Transition old objects

Expire objects

Handle non-current versions
```

This can be useful for:

```text
Cost management

Retention

Cleanup
```

But the policy should follow actual business requirements.

Do not say:

> “My project automatically deletes every invoice after 90 days.”

unless that is explicitly implemented and verified.

---

# 55. DynamoDB TTL

DynamoDB also supports TTL for automatically expiring eligible items.

Conceptually:

```text
Temporary job
     ↓
expires_at
     ↓
DynamoDB TTL
```

could help clean old temporary records.

But again:

> This is a possible production improvement, not something we should claim is implemented unless the repository confirms it.

---

# 56. Observability Needs State Context

Suppose the user says:

> “My invoice is stuck.”

A useful investigation would correlate:

```text
invoice_id
tenant_id
S3 object
SQS message
Step Functions execution
DynamoDB job
DynamoDB invoice result
CloudWatch logs
```

The common identifier:

```text
invoice_id
```

becomes extremely valuable for tracing the logical transaction across services.

---

# 57. Correlation ID Concept

A production system often uses an identifier to correlate events across distributed services.

Your:

```text
invoice_id
```

naturally serves as an important business correlation identifier.

Logs could conceptually include:

```text
invoice_id
tenant_id
job_id
execution_id
stage
status
```

Then troubleshooting becomes easier.

This is one reason consistent identifiers matter in distributed systems.

---

# 58. State Should Be Observable

A production system should let operators answer:

```text
Where is invoice X?

Did upload succeed?

Was queue processing successful?

Which workflow execution processed it?

Did OCR succeed?

Did AI succeed?

Was the result stored?

Was notification attempted?

What does the frontend think happened?
```

If these questions are difficult to answer, the state model and observability model need improvement.

---

# 59. Application State vs Infrastructure State

Another useful distinction:

## Infrastructure state

CDK/CloudFormation knows:

```text
Which bucket exists?

Which table exists?

Which Lambda exists?

Which queue exists?
```

## Application state

DynamoDB/S3/workflows know:

```text
Which invoice exists?

What is its status?

What is its score?

Where is its document?
```

Don't confuse:

```text
Infrastructure as Code state/design
```

with:

```text
Runtime business state
```

We'll discuss CDK deeply in File 17.

---

# 60. What Is Currently Strong?

The project has several useful architectural foundations:

```text
✓ Private S3 storage

✓ Direct presigned upload

✓ Event-driven ingestion

✓ Durable SQS handoff

✓ Step Functions orchestration

✓ DynamoDB application records

✓ Separate object/database responsibilities

✓ Explicit invoice IDs

✓ Processing job concept

✓ Authenticated tenant context
```

These are solid foundations for a production-oriented serverless design.

---

# 61. What Needs Improvement?

Important current weaknesses include:

```text
⚠ Duplicate processing/idempotency

⚠ Job state can be affected by repeated events

⚠ Job ownership enforcement gap

⚠ AI failure can be hidden behind COMPLETED

⚠ Frontend detail/status synchronization

⚠ User-specific frontend cache isolation

⚠ Incomplete deletion

⚠ Orphaned job/artifact possibilities

⚠ No complete enterprise lifecycle strategy

⚠ Notification state isn't fully verified
```

These are exactly the kinds of issues that distinguish:

```text
"Demo works"
```

from:

```text
"Production state model is robust"
```

---

# 62. The Most Important Mental Model

Remember:

```text
            ONE LOGICAL INVOICE
                    │
       ┌────────────┼─────────────┐
       ▼            ▼             ▼
      S3        DynamoDB      Step Functions
       │            │             │
   Document       Business      Workflow
   Artifacts       State         State
                    │
                    ▼
                 Frontend
                    │
                  Cache/
                 UI State
```

These states are related.

But they are not identical.

---

# 63. Interview Preparation — 10 Questions

## Q1 — Where do you store application state?

**Difficulty:** Basic

### Word-by-word practice answer

> “The application uses multiple state stores depending on the type of data. S3 stores original invoice documents and processed artifacts, while DynamoDB stores structured application state such as invoice records, processing jobs, metadata and risk results. Step Functions maintains workflow-execution state, and the React frontend also has temporary UI and query-cache state.”

---

## Q2 — Why don't you store everything in DynamoDB?

**Difficulty:** Basic

### Word-by-word practice answer

> “DynamoDB and S3 solve different problems. Invoice PDFs and processing artifacts are objects, so S3 is the appropriate object-storage layer. DynamoDB is used for structured, queryable application records such as job status, invoice metadata and risk results. Separating these responsibilities keeps the architecture aligned with each AWS service's strengths.”

---

## Q3 — Why can't Lambda store the invoice status in memory?

**Difficulty:** Basic / Intermediate

### Word-by-word practice answer

> “Lambda execution environments are not a reliable durable state store. One invocation can finish and a later request can run in another execution environment. Therefore persistent business state must be stored externally, such as in DynamoDB or S3, rather than relying on Lambda process memory.”

---

## Q4 — What is the difference between job state and invoice state?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The job record tracks the asynchronous processing lifecycle, such as whether processing is pending, completed or failed. The invoice record represents the processed business result, including invoice information and risk-related results. The job can exist before the final invoice result exists, which is important because processing is asynchronous.”

---

## Q5 — Why can the invoice-detail API initially return 404 after upload?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The browser uploads the file and can navigate to the detail page before asynchronous processing has finished. At that point the original S3 object and processing job can exist, but the final DynamoDB invoice record may not have been written yet. Therefore an early detail request can return not found even though the workflow is still processing normally.”

---

## Q6 — What state-management issue exists in the frontend?

**Difficulty:** Intermediate / Pressure

### Word-by-word practice answer

> “The frontend polls job status, but the invoice-detail query can initially fail before the final record exists. When status later becomes completed, the current flow does not reliably invalidate and refetch that earlier detail query, so the UI can temporarily remain stale. I would explicitly invalidate the invoice-detail query when processing transitions to completed.”

---

## Q7 — Does `COMPLETED` mean every AI stage succeeded?

**Difficulty:** Advanced

### Word-by-word practice answer

> “Not necessarily. Certain handled Bedrock failures can return degraded AI output and allow deterministic scoring and storage to continue, so the business job can reach completed even though AI analysis did not succeed normally. I would improve the state model by separating overall processing status from OCR status, AI status and analysis quality.”

---

## Q8 — How do retries affect application state?

**Difficulty:** Advanced

### Word-by-word practice answer

> “Because SQS provides at-least-once delivery, duplicate processing is possible. A repeated event can cause repeated job writes, workflow starts or downstream side effects if the handlers are not idempotent. For production I would make state transitions idempotent, use conditional writes or equivalent guards where appropriate, and prevent a stale duplicate from resetting a newer completed state.”

---

## Q9 — What happens to state when an invoice is deleted?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current deletion flow removes the tenant-scoped invoice record and attempts to delete the original S3 object, but it is not a complete lifecycle cleanup. Related job records, processed artifacts and historical S3 versions can remain. I would treat deletion as a coordinated lifecycle operation across every store associated with the logical invoice.”

---

## Q10 — How would you improve application-state management for production?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “I would first define explicit state machines for invoice processing and allowed transitions. I would separate workflow completion from OCR and AI-analysis status, make every retry idempotent, protect state changes with conditional operations where appropriate, and correlate all services using the invoice ID. I would also fix frontend cache synchronization, enforce tenant ownership on every state lookup, and implement a complete retention and deletion strategy across DynamoDB, S3 and historical object versions.”

---

# 64. Interview Pressure Chain

An interviewer asks:

> **“Where do you store invoice state?”**

Then:

```text
What do you mean by state?
       ↓
What is stored in S3?
       ↓
What is stored in DynamoDB?
       ↓
Why not store everything in S3?
       ↓
Why not store everything in DynamoDB?
       ↓
What does Step Functions store?
       ↓
What is job state?
       ↓
What is invoice state?
       ↓
Why can the invoice record
not exist immediately?
       ↓
Why does the frontend get 404?
       ↓
How does it know processing finished?
       ↓
What if status becomes COMPLETED
but detail stays stale?
       ↓
Can COMPLETED mean Bedrock failed?
       ↓
Then what does COMPLETED actually mean?
       ↓
What happens on duplicate SQS delivery?
       ↓
Can old state overwrite new state?
       ↓
How would you prevent that?
       ↓
What happens when the user deletes?
       ↓
Does every artifact disappear?
       ↓
How would you troubleshoot
an invoice stuck in processing?
```

If you understand that chain, you understand application state much more deeply than someone who only knows AWS service definitions.

---

# 65. A Troubleshooting Example

Suppose an interviewer says:

> **“The customer uploaded an invoice, but the result never appeared. How would you debug it?”**

A strong answer is:

> “I would trace the invoice ID across each state boundary rather than immediately assuming one service failed. First I would verify the original S3 object exists. Then I would check whether the S3 event reached SQS and whether the trigger Lambda successfully started the Step Functions execution. I would inspect the workflow and CloudWatch logs to identify whether Textract, Bedrock, scoring or storage failed. Then I would compare the DynamoDB job state with the final invoice record. Finally, if the backend completed successfully, I would verify whether the frontend is showing stale cached state.”

That answer connects:

```text
Architecture
+
State
+
Observability
+
Troubleshooting
```

which is exactly what interviewers want from project discussions.

---

# 66. Five Things You Must Remember

**1. One invoice has state in multiple places.**

```text
S3
DynamoDB
Step Functions
Frontend
```

**2. S3 and DynamoDB have different responsibilities.**

```text
S3       → objects/artifacts
DynamoDB → structured application state
```

**3. Workflow success and business/AI success are not automatically identical.**

```text
Step Functions SUCCESS
≠
AI definitely succeeded
```

**4. Asynchronous systems can temporarily look inconsistent.**

```text
Upload complete
≠
Final invoice record already available
```

**5. State management, retries and idempotency must be designed together.**

```text
Duplicate event
      ↓
Must not corrupt newer state
```

---

# 67. Your 30-Second Interview Answer

> “My application state is distributed according to responsibility. S3 stores the original invoice and processing artifacts, while DynamoDB stores structured application state such as processing jobs, invoice results, metadata and risk information. Step Functions maintains workflow-execution state, and the frontend has temporary cached UI state. Because processing is asynchronous, these states don't all update at exactly the same time—for example, the S3 object and job can exist before the final invoice record. One improvement I identified is making state transitions more explicit and idempotent, separating AI success from overall completion, synchronizing the frontend cache correctly, and implementing complete lifecycle cleanup across S3 and DynamoDB.”

---

# 68. Your 10-Second Mental Model

```text
S3
↓
Document state

DynamoDB
↓
Application state

Step Functions
↓
Workflow state

React
↓
UI/cache state
```

And:

> **One invoice → multiple state representations → one coordinated lifecycle.**

---

# 69. Check Your Understanding

Before moving to **`15-Frontend-React-State-Polling-and-Analytics.md`**, answer these three questions in your own words.

**Question 1:** Immediately after a successful S3 upload, why might the system have:

```text
S3 object       ✓
Job record      ✓
Invoice result  ✗
```

without anything being broken?

**Question 2:** Suppose Step Functions reaches successful completion but Bedrock failed in a handled way. Why can:

```text
COMPLETED
```

be misleading if we don't maintain a separate `ai_status`?

**Question 3:** A duplicate SQS event arrives after an invoice has already reached `COMPLETED`. Why would blindly rewriting its job to `PENDING` be dangerous, and how could you conceptually protect against that?