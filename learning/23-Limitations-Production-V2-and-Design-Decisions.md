# Your question

**Create `23-Limitations-Production-V2-and-Design-Decisions.md`.**

# 23 — Limitations, Production V2, and Design Decisions

This is one of the **most important interview files** for NovaMind AI.

Until now, we learned how the project works.

Now we answer the harder question:

> **“You built this system. What is wrong with it, what would you improve for production, and why?”**

A strong engineer does not pretend a project is perfect. A strong answer shows that you understand:

```text
Current Design
      ↓
Strengths
      ↓
Limitations
      ↓
Risk
      ↓
Production Improvement
      ↓
Trade-off
      ↓
Reason for the Decision
```

The repository analysis describes NovaMind AI as a **substantial prototype/demo with production-oriented foundations**, but not something that can yet be defended as fully production-ready. The main gaps include authorization isolation, duplicate processing, notification wiring, AI validation, financial-rule correctness, frontend refresh behavior, testing, and deployment reproducibility. :chatgpt-content-reference{index="0"}

---

# 1. What Will I Learn?

By the end of this file, I should be able to explain:

- What “production-ready” actually means
- What is already strong in NovaMind AI
- Current project limitations
- Security and tenant-isolation gaps
- Idempotency and duplicate-processing problems
- SQS/DLQ failure boundaries
- Textract/OCR limitations
- Bedrock output-validation weaknesses
- AI failure and `COMPLETED` status problem
- Risk-scoring limitations
- AI + deterministic-rule double counting
- DynamoDB TTL problem
- Workflow payload growth
- Frontend polling and cache problems
- Notification limitations
- Deployment/CI/CD limitations
- Testing limitations
- Cost/scaling limitations
- Production V2 architecture
- How to prioritize improvements
- How to defend architecture decisions
- How to answer “What would you improve?” in interviews

---

# 2. First: Is NovaMind AI Production-Ready?

The safest project-specific answer is:

> **Not yet.**

But that does **not** mean the project is bad.

The repository contains substantial implementation:

```text
React frontend
+
Cognito authentication
+
API Gateway
+
8 application Lambda functions
+
S3
+
SQS
+
Step Functions
+
Textract
+
Bedrock Nova Micro
+
DynamoDB
+
EventBridge/SNS infrastructure
+
CloudWatch/X-Ray configuration
+
5 CDK stacks
+
GitHub Actions workflows
+
unit tests
```

The analysis therefore describes it as:

> **A substantial prototype or demonstration application with production-oriented foundations.** :chatgpt-content-reference{index="1"}

That is the wording you should understand.

---

# 3. Prototype vs Production System

A prototype asks:

> **“Can this architecture and business idea work?”**

A production system must additionally answer:

```text
Is it secure?

Is tenant isolation correct?

Can duplicate events corrupt state?

Can it recover from failures?

Can AI output be trusted structurally?

Can we observe failures?

Can it scale under measured load?

Can it be deployed repeatedly?

Can we roll it back?

Can we test it automatically?

Can we manage data retention?

Can we prove important alerts are delivered?
```

Therefore:

```text
Working Demo
     ≠
Production Ready
```

---

# 4. Current Project Strengths

Before discussing limitations, understand what is already good.

The analysis identifies strengths such as:

- File transfer is separated from application processing through direct S3 upload.
- OCR, AI, risk scoring and storage have clear responsibilities.
- Deterministic rules complement AI output.
- Infrastructure is represented as code.
- Identity is derived server-side instead of trusting a caller-supplied tenant.
- Logging, tracing configuration, queueing, DLQ and alarm foundations exist.
- The UI exposes extracted information and findings rather than only displaying a score.

These are meaningful architectural foundations. :chatgpt-content-reference{index="2"}

So your interview answer should never sound like:

> “Everything is broken.”

Instead:

> **“The main processing path is implemented, but several controls need strengthening before production.”**

---

# 5. Production V2 Priority Model

Do not improve random things first.

Think:

```text
Priority 1
Security / Isolation

Priority 2
Correctness / Idempotency

Priority 3
AI Validation / Business Correctness

Priority 4
Failure Semantics / Reliability

Priority 5
Testing / Deployment Reproducibility

Priority 6
Observability

Priority 7
Scale / Cost Optimization

Priority 8
Advanced Features
```

Why?

Because adding something exciting such as:

```text
Agents
```

does not help if:

```text
User A can potentially inspect User B's job status
```

or:

```text
duplicate processing changes business state
```

Production engineering is often about fixing fundamentals first.

---

# 6. Limitation 1 — Job-Status Authorization Gap

Authentication exists:

```text
React
 ↓
Cognito
 ↓
ID Token
 ↓
API Gateway Cognito Authorizer
```

And backend identity is derived from the validated Cognito `sub`.

That part is good.

But authentication is not the same as authorization.

---

# 7. Current Job-Status Problem

The status flow first performs a tenant-scoped invoice lookup.

But when it falls back to the processing-job record:

```text
job_<invoice_id>
```

the retrieved job's stored `tenant_id` is not compared with the authenticated requester's tenant.

Conceptually:

```text
Authenticated User
      ↓
requests invoice status
      ↓
invoice lookup
      ↓
fallback to job record
      ↓
job retrieved by invoice ID
      ↓
⚠ ownership not revalidated
```

This is one of the repository analysis's highest-priority gaps: **missing ownership verification on the processing-job status fallback.** :chatgpt-content-reference{index="3"}

---

# 8. Production V2 Fix

The backend should enforce:

```text
Authenticated tenant
        ==
Job tenant
```

before returning status.

Conceptually:

```python
job = get_job(job_id)

if job["tenant_id"] != authenticated_tenant:
    deny_access()
```

This is conceptual code, not a claim that the current repository already contains this fix.

---

# 9. Design Principle

Remember:

```text
Authentication
=
Who are you?

Authorization
=
Are you allowed to access this resource?
```

Cognito answers the first question.

Your application still needs to answer the second.

---

# 10. Limitation 2 — Browser Cache Isolation

Backend authorization is not the only isolation boundary.

Your frontend uses React Query.

The current query keys do not sufficiently include user identity, and logout clears authentication state without comprehensively clearing cached queries/upload/filter state.

Imagine:

```text
User A logs in
      ↓
React Query caches invoices
      ↓
User A logs out
      ↓
User B logs in
      ↓
same SPA/browser session
      ↓
⚠ stale User A cache may still exist
```

The analysis classifies browser-cache isolation as incomplete. :chatgpt-content-reference{index="4"}

---

# 11. Production V2 Fix

Two important controls:

### User-scoped query keys

Conceptually:

```text
["invoices", userId]
```

instead of only:

```text
["invoices"]
```

### Clear private application state on logout

Conceptually:

```text
Logout
 ↓
Clear authentication state
 ↓
Clear React Query private caches
 ↓
Clear upload state
 ↓
Clear tenant/user-specific filters
```

This protects against stale cross-user UI state.

---

# 12. Important Security Lesson

A backend can be correct while the frontend still displays stale private data.

So security includes:

```text
Backend Authorization
+
Frontend State Isolation
+
Storage Isolation
+
IAM
+
Data Lifecycle
```

not simply:

```text
Cognito enabled
=
secure application
```

---

# 13. Limitation 3 — Current “Tenant” Is Really a User

Current isolation effectively uses:

```text
Cognito user sub
      ↓
tenant_id
```

So:

```text
User = Tenant
```

This is useful for a prototype.

But imagine a real company:

```text
ABC Finance Ltd.
 ├── Alice — Admin
 ├── Bob — Reviewer
 └── Carol — Auditor
```

The current model does not provide that organization-level membership and role hierarchy.

---

# 14. Production V2 Organization Model

A future model could separate:

```text
organization_id
user_id
role
```

For example:

```text
Organization
   │
   ├── Admin
   ├── Reviewer
   └── Auditor
```

Then invoice ownership becomes:

```text
organization_id
+
invoice_id
```

with application authorization determining which organization members can perform which operations.

This is **future/proposed architecture**, not current functionality.

---

# 15. Limitation 4 — Duplicate Processing / Idempotency

SQS provides:

```text
at-least-once delivery
```

That means duplicate delivery is possible.

Current conceptual risk:

```text
S3 Event
   ↓
SQS
   ↓
Trigger
   ↓
Workflow A

Same Event Again
   ↓
Trigger
   ↓
Workflow B
```

Now the same invoice can potentially be processed twice.

The analysis explicitly identifies **duplicate processing and job-reset risks** as production gaps. :chatgpt-content-reference{index="5"}

---

# 16. Why Overwriting DynamoDB Is Not Enough

An interviewer may ask:

> “But if both executions eventually write the same invoice ID, isn't that idempotent?”

No.

Suppose:

```text
Execution A
starts
```

then:

```text
Execution B
starts
```

Both can already perform:

```text
Textract
+
Bedrock
+
risk calculation
```

before the final record is overwritten.

So duplicate work has already happened.

It can cause:

```text
Extra cost

Race conditions

Status confusion

Duplicate notifications

Inconsistent timestamps

Different AI results
```

---

# 17. Production V2 Idempotency

A stronger pattern:

```text
Event arrives
     ↓
Atomic conditional write
     ↓
Already claimed?
 ┌───────┴───────┐
YES              NO
 ↓                ↓
Stop          Process
```

The important word is:

> **Atomic**

Two executions should not both successfully claim the same invoice.

---

# 18. Idempotency Key

A natural project identifier could be based on a stable invoice-processing identifier such as:

```text
invoice_id
```

The exact production key strategy should match the event semantics.

Conceptually:

```text
invoice_id
+
processing_version
```

could also become useful if future reprocessing is intentionally supported.

That second design is a **proposed improvement**, not current implementation.

---

# 19. Limitation 5 — SQS DLQ Does Not Cover the Entire Pipeline

This is extremely important.

Current flow:

```text
SQS
 ↓
Trigger Lambda
 ↓
Start Step Functions
 ↓
Trigger returns
```

Suppose Step Functions later reaches:

```text
Textract
 ↓
FAIL
```

That does **not** automatically make the original SQS message fail again.

Why?

Because the SQS consumer's responsibility was effectively:

```text
Start workflow
```

not:

```text
Wait until complete workflow finishes successfully
```

---

# 20. What the Current DLQ Mainly Protects

Think:

```text
SQS
 ↓
Trigger Lambda
 ↓
Can workflow be started?
```

So the ingestion DLQ primarily protects the:

```text
SQS → Trigger → Workflow Start
```

boundary.

It does **not** automatically capture every later:

```text
Textract failure

Bedrock failure

Risk-stage failure

Storage failure

Notification failure
```

This is an important architecture boundary.

---

# 21. Production V2 Failure Design

Each asynchronous boundary needs explicit failure handling.

Conceptually:

```text
SQS
 ↓
Trigger Failure
 ↓
SQS DLQ
```

while:

```text
Step Functions
 ↓
Stage Failure
 ↓
Catch
 ↓
Failure State / Failure Record / Alarm
```

and:

```text
Notification
 ↓
Delivery Failure
 ↓
Notification-specific monitoring/retry handling
```

Do not treat one DLQ as a universal error bucket.

---

# 22. Limitation 6 — Partial Batch Failure Configuration

The queue event-source configuration enables partial batch failure handling.

However, the handler does not return the required partial-failure response structure.

The current batch size is one, which reduces the immediate impact.

But the configuration and handler behavior are not fully aligned.

Production V2 should make these semantics explicit and test them.

---

# 23. Limitation 7 — Textract/OCR Boundaries

Current OCR uses:

```text
Textract AnalyzeExpense
```

and the parser reads:

```text
ExpenseDocuments[0]
```

It extracts fields such as:

```text
Invoice number
Vendor
Dates
Total
Subtotal
Tax
Line items
Raw LINE text
```

But several limitations remain.

---

# 24. OCR Normalization Limitations

Values are largely retained as strings.

The current processing does not comprehensively normalize:

```text
Dates

Currencies

Locale-specific amounts

Monetary representations
```

and it does not preserve important information such as:

```text
field-level confidence
coordinates
```

That matters because later financial rules depend on extracted values.

---

# 25. OCR Error Propagation

Think:

```text
Invoice
 ↓
OCR mistake
 ↓
Wrong extracted amount
 ↓
Python financial rule
 ↓
Risk finding
```

Example:

```text
Actual Total: 1,000.00

OCR:
100.00
```

The deterministic rule can be perfectly deterministic and still produce a wrong business conclusion because its input was wrong.

Therefore:

> **Deterministic does not automatically mean correct.**

---

# 26. Production V2 OCR Improvements

Possible improvements:

```text
Preserve Textract confidence

Normalize money

Normalize dates

Handle currency explicitly

Validate document/page limits

Validate extracted fields

Use confidence thresholds

Send uncertain documents to manual review
```

These are proposed improvements.

---

# 27. Limitation 8 — Bedrock JSON Parsing Is Not Validation

Nova Micro is asked to produce JSON.

The current parser tries:

```text
1. Direct JSON parsing

2. Remove Markdown fences

3. Extract first { ... last }

4. Fallback result
```

This improves robustness against formatting problems.

But:

```text
JSON parsing
≠
schema validation
```

---

# 28. Valid JSON Can Still Be Wrong

For example:

```json
{
  "anomalies": null,
  "confidence": 500
}
```

This is valid JSON.

But logically invalid for the expected contract.

Another example:

```json
{
  "anomalies": [
    "something looks strange"
  ]
}
```

Valid JSON.

But downstream code may expect structured anomaly objects.

---

# 29. Current Pydantic Limitation

The repository defines useful Pydantic/type models.

But the Bedrock AI Lambda does not enforce them on the model response.

Therefore:

```text
Model Output
 ↓
JSON parsing
 ↓
⚠ weak schema enforcement
 ↓
Risk stage
```

Weak model-output validation is explicitly identified as a major production gap. :chatgpt-content-reference{index="6"}

---

# 30. Production V2 AI Validation

Desired path:

```text
Bedrock
 ↓
Parse JSON
 ↓
Schema Validation
 ↓
Business Validation
 ↓
Valid?
 ├── YES → continue
 └── NO  → retry / degraded state / manual review
```

Example validations:

```text
Top-level object required

anomalies must be a list

each anomaly must have required fields

severity must be allowed value

confidence must be within expected range
```

---

# 31. Limitation 9 — AI Failure Can Look Like Successful Processing

This is one of the project's most subtle problems.

Certain handled Bedrock failures can become something like:

```text
anomalies = []

summary = analysis unavailable

confidence = 0
```

Then:

```text
Risk Rules
 ↓
Storage
 ↓
Job COMPLETED
```

So:

```text
COMPLETED
```

does not necessarily mean:

```text
AI analysis succeeded normally
```

---

# 32. Why This Is Dangerous

Imagine:

```text
OCR succeeded

Bedrock failed

AI anomalies = []
```

Then deterministic rules might produce:

```text
LOW risk
```

A user could interpret:

> “Low risk means the invoice was fully analyzed and looks safe.”

But actually:

```text
AI analysis unavailable
```

Therefore:

> **LOW risk after AI failure is not equivalent to fully analyzed LOW risk.**

The analysis explicitly identifies risk scores that can appear reassuring when AI analysis fails as a major production gap. :chatgpt-content-reference{index="7"}

---

# 33. Production V2 Analysis Status

Separate:

```text
Processing Status
```

from:

```text
AI Analysis Status
```

For example:

```text
processing_status = COMPLETED

ai_status = DEGRADED
```

or:

```text
review_status = MANUAL_REVIEW_REQUIRED
```

Then the UI can show:

```text
OCR completed
AI analysis unavailable
Manual review required
```

instead of silently presenting normal-looking results.

---

# 34. Limitation 10 — Risk Score Is a Heuristic

Current score:

```text
0–100
```

with:

```text
LOW
MEDIUM
HIGH
```

But this is not:

```text
fraud probability
```

It is:

```text
heuristic review-priority score
```

This distinction matters.

---

# 35. Current Rule Limitations

The math rule compares the sum of extracted price values with the invoice total.

But real invoices can include:

```text
Tax

Discount

Shipping

Credits

Quantity

Unit price

Line total

Negative amounts

Different decimal formats
```

The current financial rules do not comprehensively model these cases.

So:

```text
Difference detected
```

does not automatically mean:

```text
Fraud
```

---

# 36. Negative Number Problem

Current amount parsing can remove characters except digits and periods.

That means something like:

```text
-100.00
```

can effectively become:

```text
100.00
```

in the simplified numeric interpretation.

That can materially change financial meaning.

---

# 37. Duplicate-Line Limitation

The deterministic rules flag repeated normalized item descriptions.

Example:

```text
Consulting Service
Consulting Service
```

But legitimate invoices may contain repeated descriptions with different:

```text
Quantity
Price
Date
Unit
```

Therefore:

```text
Repeated description
```

is only a review signal.

It is not proof of a duplicate charge.

---

# 38. Important Missing Point — Double Counting

This is a limitation you must remember.

Suppose deterministic logic detects:

```text
Math discrepancy
```

and adds:

```text
+40
```

Then Bedrock also describes:

```text
"Invoice total does not match line items"
```

as a HIGH anomaly:

```text
+15
```

Now the same underlying problem can contribute:

```text
40 + 15 = 55
```

The system has no strong deduplication mechanism between:

```text
Deterministic Finding
```

and:

```text
AI Finding
```

when both describe the same issue.

Therefore the score can **double count related evidence**.

---

# 39. Production V2 Scoring

A stronger design could first create canonical finding categories:

```text
MATH_MISMATCH
MISSING_TOTAL
DUPLICATE_ITEM
SUSPICIOUS_VENDOR
DATE_ANOMALY
```

Then:

```text
Rule Finding
       +
AI Finding
       ↓
Normalize
       ↓
Deduplicate / Correlate
       ↓
Scoring Engine
```

Instead of:

```text
Rule Score
+
Every AI Finding
=
Final Score
```

This is a proposed V2 design.

---

# 40. Risk Score Calibration

Current weights such as:

```text
+40
+15
+8
```

are deterministic heuristics.

The repository does not establish a calibration study proving:

```text
70 = actual high fraud probability
```

So production evaluation should use representative labeled data and examine:

```text
False positives

False negatives

Review usefulness

Threshold behavior
```

Do not describe the current score as a scientifically calibrated fraud probability.

---

# 41. Limitation 11 — DynamoDB TTL Is Configured but Incomplete

This is a subtle project-specific fact.

The processing-jobs table has TTL enabled on:

```text
ttl
```

But:

```text
create_job()
```

does not populate that field.

Therefore:

```text
TTL configured
```

does **not** mean:

```text
job records automatically expire correctly
```

Automatic expiry is incomplete.

This is exactly why configuration alone is not enough—you must verify the data path too.

---

# 42. Production V2 TTL Fix

When creating temporary job records:

```text
create_job()
 ↓
calculate expiration timestamp
 ↓
write ttl attribute
```

Conceptually:

```text
ttl =
current_epoch_time
+
retention_period
```

The exact retention period must come from business/compliance requirements.

Do not invent it.

---

# 43. Limitation 12 — Workflow Payload Growth

Current Step Functions state carries growing JSON containing:

```text
Identifiers
+
OCR data
+
AI output
+
risk findings
```

There is no general artifact-pointer strategy for large intermediate results.

That creates:

```text
Workflow payload risk
+
Final-record size risk
```

as document complexity increases.

---

# 44. Current S3 Reality

The processed bucket stores extracted text under:

```text
processed-text/{tenant_id}/{invoice_id}.txt
```

But the current storage handler does **not** write the complete OCR and AI-analysis JSON artifacts into that bucket.

So do not claim:

> ❌ “All intermediate processing data is already stored in S3 and Step Functions only passes references.”

That is not the current implementation.

---

# 45. Production V2 Artifact Pattern

For larger documents:

```text
Textract
 ↓
Large OCR Artifact
 ↓
S3
 ↓
Step Functions carries:
{
  "invoice_id": "...",
  "ocr_artifact_key": "..."
}
```

Then:

```text
Bedrock Stage
 ↓
loads required artifact
```

instead of carrying everything through every state.

This can reduce workflow-state growth.

---

# 46. Limitation 13 — Frontend Completion Refresh

Current frontend behavior:

```text
Invoice uploaded
 ↓
Navigate to detail
 ↓
Detail query
+
Status query
 ↓
poll approximately every 3 seconds
```

The detail query can initially receive:

```text
404
```

because final invoice storage has not completed yet.

That's understandable in an asynchronous system.

The real issue comes later.

---

# 47. Stale Detail Problem

Status eventually becomes:

```text
COMPLETED
```

but the detail query is not reliably invalidated/refetched when processing finishes.

So:

```text
Backend
=
success
```

while:

```text
Frontend
=
still stale / error
```

The repository analysis explicitly identifies frontend polling that does not reliably refresh completed invoice details as a production gap. :chatgpt-content-reference{index="8"}

---

# 48. Production V2 Frontend Fix

Conceptually:

```text
Status becomes COMPLETED
        ↓
Invalidate invoice-detail query
        ↓
Refetch invoice
        ↓
Display result
```

Alternatively:

```text
Do not enable detail query
until processing status
is COMPLETED
```

That second design is a possible alternative, not necessarily the only solution.

---

# 49. Failure UI Limitation

Current UI handling can also fail to clearly preserve/display the detailed job failure information.

Production V2 should show:

```text
Processing failed

Stage:
AI_ANALYSIS

Reason:
...

Action:
Retry / Contact Support
```

rather than leaving the user uncertain.

Be careful with sensitive internal error details—user-facing errors should be safe and understandable.

---

# 50. Limitation 14 — Notifications Are Not Fully Verified

The repository contains:

```text
EventBridge
+
SNS
+
HIGH-risk matching intent
```

But complete:

```text
Producer
 ↓
EventBridge
 ↓
Rule
 ↓
SNS
 ↓
Subscriber
 ↓
Confirmed delivery
```

is not fully verified.

The project's fact sheet classifies alerts as partial, while confirmed email alert delivery remains documented/intended rather than established. :chatgpt-content-reference{index="9"}

---

# 51. Production V2 Notification Work

Verify the entire path:

```text
1. Risk result generated

2. Correct event published

3. EventBridge rule matches

4. SNS receives event

5. Subscriber exists

6. Subscription confirmed

7. Delivery succeeds

8. Failure is observable

9. Duplicate notifications are controlled
```

Only after this should you say:

> “High-risk email notifications are working end to end.”

---

# 52. Limitation 15 — Deployment Reproducibility

The repository contains:

```text
AWS CDK
+
GitHub Actions
+
OIDC
+
deployment scripts/workflows
```

But:

```text
workflow definition exists
```

does not equal:

```text
current automatic CI/CD is verified working
```

The analysis classifies live deployment and operational CI/CD as unverified. :chatgpt-content-reference{index="10"}

---

# 53. Lambda Packaging Risk

The repository also contains manual PowerShell layer-repair scripts, and deployment packaging/configuration reproducibility is one of the major identified gaps. :chatgpt-content-reference{index="11"}

Production deployment should make dependencies reproducible:

```text
Source
 ↓
Controlled Build Environment
 ↓
Dependencies
 ↓
Tests
 ↓
Package
 ↓
Deploy
```

rather than depending on manually repaired artifacts.

---

# 54. Production V2 CI/CD

A stronger pipeline would conceptually be:

```text
Git Push / Pull Request
        ↓
Static Checks
        ↓
Unit Tests
        ↓
Infrastructure Tests
        ↓
Frontend Build
        ↓
Lambda Build/Package
        ↓
CDK Synth
        ↓
CDK Diff / Review
        ↓
Deploy Dev
        ↓
Integration Tests
        ↓
Promote
        ↓
Production
        ↓
Post-deployment verification
```

This is proposed architecture.

Do not claim the current repository already performs all these steps successfully.

---

# 55. Limitation 16 — Testing Gaps

Codex found:

```text
44 unit-test functions
```

covering areas such as:

```text
response helpers

tenant extraction

Textract parsing

prompt construction

risk rules
```

But tests were **not executed** during the analysis.

There is also a static OCR test defect: tests import from `parser`, while the implementation file is `ocr_parser.py`. :chatgpt-content-reference{index="12"}

---

# 56. Important Missing Tests

The analysis identified missing coverage for areas such as:

```text
Model-response schema

Job ownership

Duplicate events

Storage partial failures

Notification wiring

User-switch cache behavior

Frontend completion refresh

Load testing

Labeled AI evaluation

Infrastructure assertions

Verified end-to-end testing
```

So do not say:

> ❌ “The project is fully tested.”

---

# 57. Production V2 Test Pyramid

Conceptually:

```text
          E2E Tests
             ▲
        Integration Tests
             ▲
         Contract Tests
             ▲
          Unit Tests
```

For this project:

### Unit

```text
OCR parsing
risk rules
prompt creation
response validation
```

### Contract

```text
Bedrock response schema
event schema
API response schema
```

### Integration

```text
S3 → SQS

SQS → Trigger

Workflow → Lambda

Lambda → DynamoDB
```

### Security

```text
User A cannot access User B invoice/job
```

### E2E

```text
Upload invoice
 ↓
Process
 ↓
Store
 ↓
Fetch
 ↓
Display
```

---

# 58. Limitation 17 — AI Quality Is Not Established

A prompt producing plausible answers is not enough.

The repository does not contain a demonstrated labeled evaluation corpus establishing AI quality. :chatgpt-content-reference{index="13"}

Production V2 should measure:

```text
Schema-valid rate

Supported anomaly precision

False positives

False negatives

Consistency

Fallback rate

Model availability

Latency

Cost
```

And remember:

```text
model confidence
≠
measured accuracy
```

---

# 59. Limitation 18 — Cost and Scale Are Not Proven

The architecture has good scaling foundations.

But there are no verified:

```text
Load tests

Production throughput numbers

Maximum-user measurements

Current production cost measurements
```

The fact sheet classifies quotas, performance and actual cost as unverified. :chatgpt-content-reference{index="14"}

Therefore production V2 needs measurement, not claims.

---

# 60. Production V2 Scaling Priorities

From File 22:

```text
Load testing

Quota-aware concurrency

Shared/coordinated Bedrock rate control

Stronger idempotency

Large-artifact handling

Analytics pre-aggregation

Smarter frontend update strategy

Cost-per-invoice measurement
```

These are sensible future improvements based on the identified scaling risks.

---

# 61. Limitation 19 — Data Deletion Is Incomplete

Current deletion:

```text
Delete tenant-scoped invoice record
+
attempt original S3 object deletion
```

But comprehensive deletion does not necessarily remove:

```text
Processing job

Processed extracted text

Historical S3 versions
```

This matters for:

```text
Data lifecycle

Privacy

Storage cost

Compliance
```

Production V2 needs an explicit retention/deletion policy.

---

# 62. Production V2 Data Lifecycle

Conceptually:

```text
Delete Invoice Request
       ↓
Authorization
       ↓
Delete invoice record
       ↓
Delete original object
       ↓
Delete processed artifacts
       ↓
Handle object versions
       ↓
Delete/expire processing job
       ↓
Record safe audit outcome
```

Exact retention requirements must come from business/legal requirements.

Do not invent them.

---

# 63. Limitation 20 — Observability Is a Foundation, Not Complete Operations

Current project includes:

```text
CloudWatch

X-Ray configuration

Log groups

API logging

DLQ alarm
```

But the repository does not demonstrate a complete production operational dashboard or fully distributed tracing. :chatgpt-content-reference{index="15"}

Production V2 should connect:

```text
invoice_id
+
tenant-safe correlation identifier
+
workflow execution
+
stage logs
+
metrics
+
alerts
```

so one invoice can be traced through the system.

---

# 64. Production V2 Architecture

Now combine the improvements.

```text
                         USER
                           │
                           ▼
                  CloudFront + React
                           │
                           ▼
                       Cognito
                           │
                           ▼
                     API Gateway
                           │
                  strict authorization
                           │
                           ▼
                  Presigned S3 Upload
                           │
                           ▼
                     Private S3
                           │
                           ▼
                          SQS
                           │
                    controlled intake
                           │
                           ▼
                    Trigger Lambda
                           │
                  atomic idempotency
                           │
                           ▼
                  Step Functions
                           │
       ┌───────────────────┼────────────────────┐
       ▼                   ▼                    ▼
    Textract            Bedrock            Risk Engine
       │                   │                    │
 confidence +          schema +            normalized
 normalization         business             findings
       │               validation               │
       └───────────────────┼────────────────────┘
                           ▼
                  Finding Deduplication
                           │
                           ▼
                   Review Risk Score
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
              DynamoDB              S3
             metadata/             larger
              status              artifacts
                 │                   │
                 └─────────┬─────────┘
                           ▼
                 EventBridge / SNS
                  verified delivery
                           │
                           ▼
                      Reviewer

Cross-cutting:
IAM + CloudWatch + X-Ray + alarms
CI/CD + tests + security tests
lifecycle + retention + cost metrics
```

Everything in this diagram after the current core architecture that strengthens validation, deduplication, coordinated intake, lifecycle, verified notifications, etc. should be described as **Production V2 / proposed**, not as currently implemented.

---

# 65. What Should NOT Be Added Just to Sound Advanced?

Do not automatically add:

```text
Kubernetes

EKS

Kafka

RAG

Vector Database

LangChain

LangGraph

Agents

SageMaker

Custom ML Model
```

unless there is a real requirement.

The current project does not contain RAG, vector search, autonomous agents or ML training. :chatgpt-content-reference{index="16"}

A good engineer asks:

> **“What problem does this technology solve?”**

not:

> “How many technologies can I put in my architecture diagram?”

---

# 66. Design Decision 1 — Why Direct S3 Upload?

Current:

```text
Browser
 ↓
Presigned URL
 ↓
S3
```

Alternative:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

### Why current design makes sense

It keeps binary file transfer away from the application Lambda/API processing path.

This separates:

```text
Control Path
```

from:

```text
Data Path
```

The analysis specifically identifies this separation as an architectural strength. :chatgpt-content-reference{index="17"}

---

# 67. Design Decision 2 — Why SQS?

Without SQS:

```text
S3 Event
 ↓
processing immediately
```

With SQS:

```text
S3 Event
 ↓
Queue
 ↓
Consumer
```

Benefits:

```text
Decoupling

Buffering

Retry at ingestion boundary

Burst absorption
```

Trade-off:

```text
More components
+
eventual consistency
+
duplicate-delivery handling required
```

---

# 68. Design Decision 3 — Why Step Functions?

Alternative:

```text
One giant Lambda
```

Current approach:

```text
OCR Lambda
 ↓
AI Lambda
 ↓
Risk Lambda
 ↓
Storage Lambda
```

orchestrated by Step Functions.

Benefits:

```text
Clear stages

Failure isolation

Retry/catch configuration

Better operational visibility

Independent responsibilities
```

Trade-off:

```text
More infrastructure

More state transitions/orchestration

Payload management becomes important
```

---

# 69. Design Decision 4 — Why Textract Before Bedrock?

Possible naive design:

```text
Invoice
 ↓
LLM
```

Current design:

```text
Invoice
 ↓
Textract
 ↓
Structured fields + OCR text
 ↓
Bedrock Nova Micro
```

This gives a specialized document extraction stage before generative reasoning.

Textract handles document extraction.

Bedrock handles semantic/anomaly analysis.

Different tools solve different problems.

---

# 70. Design Decision 5 — Why AI + Python Rules?

AI is useful for:

```text
Semantic interpretation

Flexible anomaly descriptions

Human-readable summaries
```

Python rules are useful for:

```text
Deterministic checks

Explainable score contributions

Repeatable business logic
```

Therefore the project combines them.

But V2 must address:

```text
double counting
+
rule correctness
+
AI validation
```

---

# 71. Design Decision 6 — Why DynamoDB?

The project needs serverless persistent application state such as:

```text
tenant-scoped invoice records

job records

status

risk results
```

Current invoice access naturally uses:

```text
tenant_id
+
invoice_id
```

which maps well to:

```text
Partition Key
+
Sort Key
```

Trade-offs include access-pattern-first modeling and careful handling of analytics/high-volume tenants.

---

# 72. Design Decision 7 — Why Polling?

Current frontend uses polling roughly every three seconds.

Benefits:

```text
Simple

Easy to understand

Works with asynchronous backend
```

Trade-off:

```text
Repeated API requests

Extra Lambda/DynamoDB activity

Delayed update between polls

Current refresh bug
```

Production V2 could improve polling or use a push mechanism if requirements justify the added complexity.

---

# 73. Design Decision 8 — Why Serverless?

Serverless services reduce:

```text
Server management

OS patching

Manual instance scaling

Always-on compute management
```

and fit the event-driven invoice workflow.

But trade-offs include:

```text
Service quotas

Distributed debugging

Cold-start considerations

Payload limits

Vendor-specific architecture

Concurrency management
```

So the correct answer is not:

> “Serverless is always better.”

It is:

> **“Serverless fits this event-driven workload, but it introduces its own operational constraints.”**

---

# 74. Design Decision 9 — Why AWS CDK?

Instead of manually creating infrastructure:

```text
Console
 ↓
click
 ↓
click
 ↓
click
```

the project defines infrastructure in source.

Benefits:

```text
Repeatability

Version control

Reviewability

Dependency management

Reproducible environments
```

Trade-off:

```text
More code

CDK/CloudFormation knowledge required

Cross-stack dependencies

Deployment failures still require troubleshooting
```

And remember:

```text
CDK code exists
≠
live environment currently verified
```

---

# 75. Design Decision 10 — Why Not RAG?

Because the project does not need external knowledge retrieval for its core function.

Its flow is:

```text
Invoice
 ↓
Textract
 ↓
Bedrock analysis
```

There is no:

```text
Embedding
 ↓
Vector Search
 ↓
Retrieved Context
 ↓
Generation
```

Therefore this is not RAG.

Do not add RAG just because the project uses Generative AI.

---

# 76. Why Not Agentic AI?

Current Step Functions workflow follows a predefined sequence:

```text
OCR
 ↓
AI
 ↓
Rules
 ↓
Store
```

The model does not autonomously decide:

```text
which tool to call

which path to choose

how many steps to execute

which agent should act next
```

Therefore this is workflow orchestration, not autonomous Agentic AI.

---

# 77. How to Prioritize Production V2

If interviewer asks:

> “You have one month. What do you fix first?”

Do not give 30 random improvements.

Use:

```text
WEEK 1
Security + correctness

WEEK 2
AI validation + financial correctness

WEEK 3
Testing + deployment + observability

WEEK 4
Load testing + scale/cost + UX reliability
```

This timeline is an interview planning framework, not a repository fact.

---

# 78. Week 1 — Security and Correctness

Focus:

```text
Fix job-status ownership

Clear/scoped frontend caches

Atomic idempotency

Correct duplicate-processing behavior

Explicit workflow/job state semantics

Complete deletion/lifecycle behavior
```

Why first?

Because:

```text
Security
+
data correctness
```

come before performance optimization.

---

# 79. Week 2 — AI and Business Correctness

Focus:

```text
Schema validation

Pydantic enforcement

Business validation

AI degraded-state handling

OCR confidence

Amount/date normalization

Financial-rule corrections

Finding deduplication

Score calibration plan
```

---

# 80. Week 3 — Delivery Quality

Focus:

```text
Fix broken tests

Add security tests

Add duplicate-event tests

Add AI contract tests

Add integration tests

Reproducible Lambda packaging

Verify CI/CD

Verify EventBridge/SNS

Improve alarms/tracing
```

---

# 81. Week 4 — Scale and UX

Focus:

```text
Load testing

Quota testing

End-to-end latency measurement

Bedrock rate-control improvement

Workflow payload optimization

Analytics scaling

Frontend completion refresh

Polling optimization

Cost-per-invoice measurement
```

---

# 82. Production Readiness Checklist

Before calling NovaMind AI production-ready, I would want evidence for:

```text
SECURITY
□ Resource ownership enforced
□ User cache isolation
□ Appropriate MFA/identity controls
□ Secrets handled correctly
□ Data lifecycle tested

CORRECTNESS
□ Idempotency
□ Financial normalization
□ Finding deduplication
□ AI degraded-state semantics

AI
□ Schema validation
□ Evaluation dataset
□ Quality metrics
□ Prompt/model versioning
□ Failure handling

RELIABILITY
□ Failure states
□ Retry boundaries
□ DLQ boundaries
□ Notification delivery
□ Recovery procedures

TESTING
□ Unit
□ Contract
□ Integration
□ Security
□ E2E
□ Load

DEPLOYMENT
□ Reproducible packages
□ CI/CD verified
□ Environment promotion
□ Rollback tested

OBSERVABILITY
□ Correlation
□ Metrics
□ Logs
□ Traces
□ Alarms

PERFORMANCE
□ p50/p95/p99
□ Queue age
□ Throughput
□ Throttling
□ Cost per fully analyzed invoice
```

This checklist is a **Production V2 evaluation framework**, not a statement that all items currently exist.

---

# 83. Interview Question 1 — Is Your Project Production-Ready?

**Difficulty: Basic**

### Word-by-word answer

> “I would describe the current project as a substantial production-oriented prototype rather than claim it is fully production-ready. The main processing path is implemented with Cognito, S3, SQS, Lambda, Step Functions, Textract, Bedrock and DynamoDB, but the repository analysis identified gaps in tenant isolation, idempotency, AI-output validation, financial-rule correctness, notification wiring, frontend state handling, testing and deployment reproducibility. I prefer to explain those limitations and how I would fix them rather than overstate the maturity of the system.” :chatgpt-content-reference{index="18"}

---

# 84. Interview Question 2 — What Is the Biggest Security Gap?

**Difficulty: Basic / Intermediate**

### Word-by-word answer

> “One important gap is the processing-job status fallback. The application authenticates users with Cognito and derives tenant identity from validated claims, but when the status endpoint falls back to a job record, the stored job tenant is not explicitly compared with the requesting tenant. I would fix that by enforcing ownership on every resource read, including job records. I would also fix browser cache isolation because private React Query data is not fully scoped or cleared when users change.” :chatgpt-content-reference{index="19"}

---

# 85. Interview Question 3 — What Is the Biggest Reliability Gap?

**Difficulty: Intermediate**

### Word-by-word answer

> “A major reliability gap is idempotency. SQS provides at-least-once delivery, so duplicate events are possible. If two consumers start workflows for the same invoice, both can perform Textract, Bedrock and downstream processing before the final record is overwritten. I would introduce an atomic idempotency claim using a conditional write so only one execution can claim a processing unit, while intentional reprocessing would use an explicit version or operation identifier.”

---

# 86. Interview Question 4 — Does Your DLQ Handle All Processing Failures?

**Difficulty: Intermediate / Pressure**

### Word-by-word answer

> “No. The ingestion SQS DLQ mainly protects the SQS-to-trigger and workflow-start boundary. The trigger starts Step Functions asynchronously and then returns, so a later Textract, Bedrock or storage failure does not automatically return the original SQS message to the queue. Those downstream failures need Step Functions catch paths, application failure records, alarms and stage-specific recovery mechanisms.”

---

# 87. Interview Question 5 — What Is the Biggest AI Limitation?

**Difficulty: Intermediate**

### Word-by-word answer

> “The biggest AI limitation is that parsing the Bedrock response is stronger than the actual schema validation. The code attempts to recover JSON from different formatting styles, but valid JSON can still have the wrong structure, invalid severity values or an invalid confidence range. Pydantic models exist in the repository, but the AI Lambda does not enforce them on the model response. In Production V2 I would add strict schema and business validation before the risk stage.” :chatgpt-content-reference{index="20"}

---

# 88. Interview Question 6 — What Happens If Bedrock Fails?

**Difficulty: Intermediate / Advanced**

### Word-by-word answer

> “For some handled Bedrock failures, the application creates a fallback result with no anomalies and an unavailable-analysis style summary, then continues through deterministic scoring and storage. This means a business job can become completed even though AI analysis did not succeed normally. That is risky because a low score could be interpreted as fully analyzed low risk. I would separate processing status from AI-analysis status and send degraded cases to manual review.”

---

# 89. Interview Question 7 — What Is Wrong With the Risk Score?

**Difficulty: Advanced**

### Word-by-word answer

> “The score is a deterministic heuristic, not a calibrated fraud probability. Some financial rules simplify real invoice behavior, for example around tax, discounts, quantity, negative amounts and repeated descriptions. Another issue is double counting: a deterministic rule and the AI can identify the same underlying problem and both add points. In Production V2 I would normalize findings into canonical categories, deduplicate correlated findings, improve financial normalization and validate thresholds against representative labeled data.”

---

# 90. Interview Question 8 — What Is the DynamoDB TTL Problem?

**Difficulty: Advanced**

### Word-by-word answer

> “The processing-jobs table has TTL configured on a `ttl` attribute, but the job-creation path does not populate that attribute. So TTL is configured at the infrastructure level but automatic job expiry is incomplete at the application-data level. I would calculate and write the TTL timestamp when temporary jobs are created, based on an explicit retention policy.”

---

# 91. Interview Question 9 — What Would You Change for Large Documents?

**Difficulty: Advanced**

### Word-by-word answer

> “The current workflow carries identifiers, OCR data, AI output and risk findings through Step Functions state, so payload size grows with document complexity. The processed S3 bucket currently stores extracted text, but the application does not use a general artifact-pointer pattern for all large intermediate results. For Production V2 I would store large OCR and analysis artifacts in S3 and pass compact references through the workflow, while keeping only the metadata required by each stage.”

---

# 92. Interview Question 10 — If You Had One Month, What Would You Improve First?

**Difficulty: Advanced / System Design**

### Word-by-word answer

> “I would prioritize production work by risk rather than adding new AI features. First I would close security and correctness gaps by fixing job ownership, frontend cache isolation and atomic idempotency. Second I would strengthen AI and business correctness with strict model-response validation, degraded-analysis status, financial normalization and finding deduplication. Third I would improve automated tests, reproducible Lambda packaging, CI/CD verification, notification delivery and observability. Finally I would load-test the system, measure end-to-end latency and cost, introduce quota-aware concurrency and improve large-payload, analytics and frontend polling behavior. Only after those fundamentals were reliable would I consider adding major new features.”

---

# 93. Interview Pressure Chain

The interviewer asks:

> **“What are the limitations of your project?”**

Expect:

```text
Is it production-ready?
 ↓
Why not?
 ↓
What is your biggest security problem?
 ↓
Does Cognito solve authorization?
 ↓
What happens when users switch accounts?
 ↓
Can SQS deliver duplicates?
 ↓
How do you prevent duplicate processing?
 ↓
Why isn't overwriting DynamoDB enough?
 ↓
Does your DLQ catch Textract failure?
 ↓
What happens if Bedrock fails?
 ↓
Can COMPLETED mean AI failed?
 ↓
Can valid JSON still be invalid?
 ↓
Why use Pydantic?
 ↓
Is your score fraud probability?
 ↓
Can the AI and rules double count?
 ↓
What financial rules are weak?
 ↓
What happens with large OCR payloads?
 ↓
Why not store large artifacts in S3?
 ↓
Does DynamoDB TTL currently work?
 ↓
Why can frontend show stale data?
 ↓
Are notifications working?
 ↓
Is CI/CD verified?
 ↓
Do tests pass?
 ↓
What load have you tested?
 ↓
What would you fix first?
 ↓
What would Production V2 look like?
```

If you can answer this chain naturally, your project understanding is becoming much stronger.

---

# 94. Strong “Current vs V2” Mental Model

```text
CURRENT
──────────────────────────────
Cognito authentication
User-level tenant model
Direct S3 upload
SQS buffering
Step Functions workflow
Textract
Bedrock Nova Micro
JSON recovery parsing
Deterministic scoring
DynamoDB/S3 persistence
Polling
EventBridge/SNS infrastructure
CDK
GitHub Actions definitions
CloudWatch/X-Ray foundations


PRODUCTION V2
──────────────────────────────
Strict ownership everywhere
Organization/role model if required
Atomic idempotency
Explicit failure semantics
OCR normalization/confidence
Strict AI schema validation
AI degraded status
Finding deduplication
Better financial rules
Calibrated review thresholds
Large-artifact S3 references
Correct TTL population
Complete data lifecycle
Reliable frontend refresh
User-scoped cache clearing
Verified notifications
Reproducible packaging
Verified CI/CD
Security/integration/E2E/load tests
Quota-aware concurrency
Measured cost/performance
```

---

# 95. What Not to Say in an Interview

Do not say:

> ❌ “The project is fully production-ready.”

Say:

> **“It has production-oriented foundations, but several controls still need strengthening.”**

Do not say:

> ❌ “Cognito gives complete multi-tenant security.”

Say:

> **“Cognito provides authentication, while application-level authorization still needs to be enforced for every resource.”**

Do not say:

> ❌ “SQS guarantees exactly-once processing.”

Say:

> **“SQS has at-least-once delivery semantics, so the application needs idempotency.”**

Do not say:

> ❌ “The DLQ catches every processing failure.”

Say:

> **“The ingestion DLQ protects its queue-consumer boundary; later workflow failures need separate handling.”**

Do not say:

> ❌ “Bedrock calculates the fraud score.”

Say:

> **“Bedrock generates anomaly findings; deterministic Python rules calculate the final heuristic review score.”**

Do not say:

> ❌ “LOW means the invoice is safe.”

Say:

> **“LOW is a heuristic review classification and does not prove the invoice is legitimate.”**

Do not say:

> ❌ “The AI confidence is model accuracy.”

Say:

> **“It is model-generated confidence, not measured accuracy.”**

---

# 96. Best 30-Second Answer — “What Would You Improve?”

> “The current project has a strong serverless processing foundation, but before production I would focus on correctness and reliability rather than adding more AI features. First I would close the job-ownership and browser-cache isolation gaps and add atomic idempotency. Then I would enforce strict Bedrock output validation, distinguish degraded AI analysis from successful analysis, improve financial rules and prevent AI/rule double counting. After that I would strengthen automated testing, deployment reproducibility, notification verification, observability and data lifecycle, then load-test the architecture and optimize concurrency, payload size and cost.”

---

# 97. Best One-Minute Answer

> “I would describe NovaMind AI as a substantial production-oriented prototype rather than fully production-ready. The core architecture is implemented: Cognito authentication, presigned S3 uploads, SQS, Lambda, Step Functions, Textract, Bedrock Nova Micro, deterministic risk scoring, DynamoDB and the React frontend.
>
> The highest-priority improvements are security and correctness. I would fix processing-job ownership checks, isolate frontend caches between users and add atomic idempotency because SQS can deliver duplicate events. On the AI side, I would enforce strict schema validation, distinguish AI failure from normal successful analysis and improve the financial rules because the current score is heuristic and AI plus deterministic findings can double count the same issue.
>
> Then I would fix the incomplete TTL and data-deletion lifecycle, move large intermediate artifacts to S3 references, make frontend completion refresh reliable, verify EventBridge/SNS delivery, make Lambda packaging and CI/CD reproducible and expand security, integration, end-to-end and load testing. Only after measuring latency, throughput, quotas and cost would I make production-scale claims.”

---

# 98. Best Two-Minute Production V2 Story

> “If I were taking this project from its current state to Production V2, I would not redesign everything because the basic architecture is reasonable. I would preserve the event-driven serverless flow: direct S3 upload, SQS buffering, Step Functions orchestration, Textract extraction, Bedrock analysis, deterministic rules and DynamoDB persistence.
>
> My first phase would be security and correctness. Cognito already authenticates users, but I would enforce ownership on every job read and isolate browser caches by user. Because SQS is at-least-once, I would add an atomic idempotency mechanism before expensive OCR and AI processing.
>
> My second phase would focus on AI and financial correctness. The current Bedrock parser can recover JSON formatting, but parsing is not validation, so I would enforce a schema and business rules before scoring. I would also distinguish AI unavailable from successful AI analysis so a degraded invoice cannot silently appear as normal low risk. I would normalize financial values and deduplicate AI and deterministic findings before calculating the final review score.
>
> My third phase would improve operations. I would fix TTL population and deletion lifecycle, use S3 artifact references for large workflow data, verify the EventBridge/SNS path, improve frontend refresh behavior, make Lambda packaging reproducible and strengthen CI/CD and automated tests.
>
> Finally, I would load-test the system and measure end-to-end p50, p95 and p99 latency, queue age, throttling, AI availability and cost per fully analyzed invoice. That would give me evidence for production-readiness claims instead of relying on architecture diagrams alone.”

---

# 99. The Most Important Interview Mindset

When an interviewer finds a limitation, do not panic.

For example:

> “Your idempotency isn't complete.”

A weak response:

> “No, I think it is fine.”

A stronger engineering response:

```text
Yes, I understand the limitation.
        ↓
Here is why it happens.
        ↓
Here is its impact.
        ↓
Here is how I would fix it.
        ↓
Here is the trade-off.
```

That demonstrates engineering understanding.

---

# 100. Final Mental Model

Remember:

```text
          CURRENT PROJECT
                 │
                 ▼
       Does the main path work?
                 │
                YES
                 │
                 ▼
        Is that enough for
          production?
                 │
                 NO
                 │
                 ▼
     ┌───────────┼────────────┐
     ▼           ▼            ▼
 Security    Correctness   Reliability
     │           │            │
     └───────────┼────────────┘
                 ▼
          AI Validation
                 │
                 ▼
             Testing
                 │
                 ▼
          Observability
                 │
                 ▼
             CI/CD
                 │
                 ▼
          Load Testing
                 │
                 ▼
        Cost Measurement
                 │
                 ▼
          PRODUCTION V2
```

The goal is **not**:

> “Make the architecture more complicated.”

The goal is:

> **Make the existing architecture more trustworthy.**

---

# 101. Check Your Understanding

Before moving to project storytelling, answer these without reading above.

### Question 1

Why can this happen?

```text
SQS message
 ↓
Trigger succeeds
 ↓
Step Functions starts
 ↓
Textract fails
```

but:

```text
original SQS message
```

does not necessarily go to the ingestion DLQ?

### Question 2

Why is this dangerous?

```text
Bedrock fails
 ↓
AI anomalies = []
 ↓
Python score = LOW
 ↓
Job = COMPLETED
```

### Question 3

Suppose:

```text
Python rule:
Math mismatch +40
```

and:

```text
Bedrock:
HIGH math mismatch +15
```

What is the **double-counting problem**, and how would Production V2 address it?

### Question 4

Why does:

```text
DynamoDB TTL configured
```

not mean TTL is actually working for the processing jobs?

### Question 5

An interviewer says:

> **“Why don't you just add LangGraph agents, a vector database and Kubernetes to make Production V2 better?”**

Explain why that is the wrong way to think about this project.

---

# Next File

## `24-Complete-Project-Storytelling-and-Interview-QA.md`

This is where everything we learned from Files **01–23** starts turning into your actual interview language.

We will build:

```text
"Tell me about your project"
        ↓
30-second answer
        ↓
1-minute answer
        ↓
2-minute answer
        ↓
5-minute detailed answer
        ↓
Architecture storytelling
        ↓
End-to-end flow storytelling
        ↓
"My role and responsibilities"
        ↓
"Why did you choose these AWS services?"
        ↓
"What was the hardest challenge?"
        ↓
"What problems did you face?"
        ↓
"How did you troubleshoot them?"
        ↓
"What would you improve?"
        ↓
Production V2 explanation
        ↓
Project-specific interview questions
        ↓
Pressure follow-ups
        ↓
Word-by-word practice answers
```

That file should focus less on learning individual AWS services and more on making you able to **tell the complete NovaMind AI story naturally in an interview**.