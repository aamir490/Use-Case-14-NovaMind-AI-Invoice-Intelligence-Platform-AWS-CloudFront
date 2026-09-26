# Your question

**Create `20-Reliability-Troubleshooting-and-Observability.md`.**

This file connects many things we have already learned: **S3 → SQS → Lambda → Step Functions → Textract → Bedrock → risk rules → DynamoDB → frontend polling**.

The most important idea is:

> **A reliable system is not one that never fails. A reliable system detects failures, limits their impact, preserves useful state, and gives engineers enough information to diagnose and recover from them.**

# 20 — Reliability, Troubleshooting and Observability

## 1. What Will I Learn?

By the end of this file, I should understand:

- What reliability means
- Availability vs reliability
- What observability means
- Monitoring vs observability
- Logs, metrics and traces
- CloudWatch's role
- X-Ray's role
- Why distributed systems are harder to troubleshoot
- How to trace one invoice through NovaMind AI
- S3 → SQS reliability
- SQS retries and duplicate delivery
- The real DLQ boundary
- Lambda failure scenarios
- Step Functions failure scenarios
- Textract failure scenarios
- Bedrock retry/fallback behavior
- Why `COMPLETED` can be misleading
- DynamoDB/storage failures
- Frontend polling failures
- Correlation IDs
- Idempotency
- Timeout and retry design
- Failure classification
- Alerting
- Production reliability improvements
- How to answer troubleshooting questions in interviews

---

# 2. What Is Reliability?

Simple definition:

> **Reliability is the ability of a system to continue behaving correctly and predictably, including when components fail.**

A beginner may think:

```text
Reliable System
=
Nothing ever fails
```

That is unrealistic.

AWS services, networks, APIs, code and external dependencies can fail.

A better model is:

```text
Failure happens
      ↓
Detect it
      ↓
Handle it safely
      ↓
Retry when appropriate
      ↓
Prevent duplicate damage
      ↓
Record useful state
      ↓
Alert when necessary
      ↓
Recover
```

---

# 3. Reliability in NovaMind AI

Your application contains many components:

```text
User
 ↓
React
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
 ↓
SQS
 ↓
Trigger Lambda
 ↓
Step Functions
 ↓
Textract
 ↓
Bedrock
 ↓
Risk Rules
 ↓
DynamoDB / S3
 ↓
Frontend
```

Every arrow is a possible failure boundary.

For example:

```text
S3 upload succeeds
```

doesn't guarantee:

```text
SQS processing succeeds
```

and:

```text
Textract succeeds
```

doesn't guarantee:

```text
Bedrock succeeds normally
```

and:

```text
Backend completes
```

doesn't guarantee:

```text
Frontend displays fresh result
```

This is why distributed systems require careful reliability engineering.

---

# 4. Availability vs Reliability

These words are related but not identical.

### Availability

> **Can the service be accessed right now?**

Example:

```text
API responds
✓
```

### Reliability

> **Does the system consistently perform the expected operation correctly?**

Example:

```text
Invoice uploaded
       ↓
Correctly processed
       ↓
Correct result stored
       ↓
Correctly shown to user
```

An API can technically be available while the business workflow is unreliable.

---

# 5. What Is Observability?

Simple definition:

> **Observability is the ability to understand what is happening inside a system by examining information it produces.**

Typical observability signals are:

```text
Logs
+
Metrics
+
Traces
```

Think:

```text
SYSTEM
  │
  ├── Logs
  ├── Metrics
  └── Traces
       ↓
Engineer understands
what happened
```

---

# 6. Monitoring vs Observability

A useful distinction:

### Monitoring

Answers known questions such as:

> “How many Lambda errors occurred?”

> “How many messages are in the queue?”

### Observability

Helps investigate questions such as:

> “Why did invoice `inv_123` get stuck after OCR?”

Monitoring might tell you:

```text
Bedrock Lambda errors increased.
```

Observability should help determine:

```text
Which invoice?

Which execution?

Which attempt?

Which error?

What happened before it?

What happened afterwards?
```

---

# 7. Three Pillars

## Logs

Detailed event information.

Example:

```text
invoice_id=inv_123
stage=bedrock_analysis
status=retry
attempt=2
```

## Metrics

Numeric measurements over time.

Example:

```text
Lambda Errors = 5

SQS Queue Depth = 42

Bedrock Latency = ...
```

## Traces

Follow a request/workflow across components.

Conceptually:

```text
API
 ↓
Lambda
 ↓
SQS
 ↓
Workflow
 ↓
Textract
 ↓
Bedrock
```

Together they provide a much stronger operational picture.

---

# 8. CloudWatch in This Project

NovaMind AI uses AWS observability foundations around:

```text
CloudWatch
```

CloudWatch can provide:

```text
Lambda logs

Service metrics

Error information

Operational dashboards/alarms
```

depending on what is configured.

Do not claim:

> ❌ “We have complete enterprise monitoring.”

The repository supports observability foundations, but the source analysis does not prove a complete production monitoring and alerting program.

---

# 9. AWS X-Ray

The project also contains X-Ray-related configuration.

X-Ray is useful for distributed tracing.

Conceptually:

```text
Request
  ↓
Service A
  ↓
Service B
  ↓
Service C
```

A trace can help understand:

```text
Where time was spent

Which service failed

How components interacted
```

But again:

> **X-Ray configuration existing does not prove every service interaction is fully traced end to end.**

Do not overclaim full tracing coverage.

---

# 10. The Most Important Troubleshooting Identifier

Imagine logs only say:

```text
Processing started.

OCR complete.

Bedrock failed.

Storage complete.
```

With 100 invoices processing simultaneously, those logs are difficult to correlate.

You need identifiers such as:

```text
tenant_id

invoice_id

job_id

Step Functions execution identifier

request/correlation identifier
```

Then:

```text
invoice_id = inv_123
```

becomes your investigation key.

---

# 11. Correlation

Suppose a user says:

> “Invoice 123 is stuck.”

Your troubleshooting process should follow:

```text
invoice_id
    ↓
job_id
    ↓
SQS event
    ↓
Step Functions execution
    ↓
Textract stage
    ↓
Bedrock stage
    ↓
Risk stage
    ↓
Storage stage
```

This is much better than randomly opening AWS services.

---

# 12. Golden Troubleshooting Rule

Do not begin with:

> “Maybe Bedrock is broken.”

Begin with:

> **“What is the last stage I can prove succeeded?”**

For example:

```text
Upload ✓

S3 object ✓

SQS event ✓

Trigger Lambda ✓

Step Functions ✓

Textract ✓

Bedrock ?
```

Now your investigation scope is small.

This is one of the strongest troubleshooting habits you can develop.

---

# 13. Troubleshooting From the Beginning

Suppose:

> “I uploaded an invoice but nothing happened.”

Start with:

```text
1. Did frontend upload succeed?
          ↓
2. Does S3 object exist?
          ↓
3. Was S3 event sent?
          ↓
4. Did SQS receive/process it?
          ↓
5. Did trigger Lambda run?
          ↓
6. Was Step Functions execution started?
          ↓
7. Which processing stage failed?
```

Never jump directly to Step 7.

---

# 14. Stage 1 — Upload Failure

Potential symptoms:

```text
Upload button fails

403 from S3

Presigned URL expired

CORS failure

Network failure
```

Investigate:

```text
Browser network request

Upload-url API response

Presigned URL expiration

S3 response

Content-Type

CORS configuration
```

Remember from File 6:

```text
Presigned URL
≈ 5 minutes
```

So an expired URL can produce an upload failure even when the application itself is otherwise healthy.

---

# 15. Stage 2 — S3 Object Exists but Processing Doesn't Start

Suppose:

```text
S3 object ✓

No processing result
```

Now inspect:

```text
S3 event configuration
        ↓
SQS
        ↓
Trigger Lambda
```

Questions:

```text
Did the object key match the expected prefix?

Did S3 send the event?

Did SQS receive it?

Was the message consumed?

Did the trigger Lambda execute?
```

---

# 16. Why SQS Improves Reliability

Without SQS:

```text
S3
 ↓
Processing directly
```

the producer and processor are tightly connected.

With SQS:

```text
S3
 ↓
SQS
 ↓
Consumer
```

the queue provides a buffer.

If processing temporarily slows:

```text
Incoming invoices
      ↓
     SQS
      ↓
Backlog
      ↓
Consumers process later
```

This helps absorb temporary differences between ingestion rate and processing rate.

---

# 17. But SQS Does Not Mean Exactly Once

Critical point:

> **Standard SQS provides at-least-once delivery semantics.**

Therefore:

```text
Message
 ↓
Consumer
```

may happen more than once.

Conceptually:

```text
Invoice Event
   ↓
Delivery 1
   ↓
Processing

Invoice Event
   ↓
Delivery 2
   ↓
Processing again
```

Your application therefore needs to think about:

> **Idempotency.**

---

# 18. What Is Idempotency?

Simple definition:

> **An idempotent operation can be repeated without causing unintended duplicate effects.**

Example:

Bad:

```text
Process same event twice
        ↓
Create duplicate records
        ↓
Send duplicate alerts
        ↓
Charge twice
```

Better:

```text
Event arrives
    ↓
Has invoice already started/completed?
    ↓
YES → safely skip/reuse state
NO  → process
```

---

# 19. Current Idempotency Risk

The project does not have a strong exactly-once guarantee.

The SQS path can redeliver events, and the job record can be rewritten/reset as processing starts.

Therefore duplicate processing remains a reliability concern.

Do not say:

> ❌ “SQS guarantees every invoice is processed exactly once.”

It doesn't.

---

# 20. Stronger Idempotency Design

A future improvement could use an atomic DynamoDB conditional operation.

Conceptually:

```text
Event arrives
      ↓
Try to create processing lock/state
      ↓
Condition:
invoice not already processing/completed
       / \
      /   \
 success   fails
   ↓         ↓
process    duplicate
            ↓
           skip
```

The key word is:

> **Atomic**

because:

```text
Check
then
Write
```

as two independent operations can still have race conditions.

This is a proposed improvement, not a claim about the current implementation.

---

# 21. The DLQ — Critical Correction

This is extremely important for your interview.

You have:

```text
SQS
 ↓
Trigger Lambda
 ↓
Start Step Functions
```

A beginner may say:

> ❌ “If Textract or Bedrock fails, the SQS message eventually goes to the DLQ.”

That is **not generally true for this project's current architecture**.

---

# 22. Why?

The trigger Lambda:

```text
Receives SQS message
       ↓
Starts Step Functions
       ↓
Returns
```

Once the trigger successfully starts the workflow and returns successfully:

```text
SQS
 ↓
considers consumer processing successful
```

Later:

```text
Step Functions
      ↓
Textract fails
```

does not automatically cause the original SQS message to return.

---

# 23. Real DLQ Boundary

Think of the SQS DLQ as mainly protecting:

```text
SQS
 ↓
Trigger Lambda
 ↓
Workflow-start handoff
```

not automatically:

```text
SQS
 ↓
Trigger
 ↓
Step Functions
 ↓
Textract
 ↓
Bedrock
 ↓
Risk Rules
 ↓
Storage
```

as one giant retry unit.

This distinction is extremely important.

---

# 24. Example

Suppose:

```text
SQS message
    ↓
Trigger Lambda
    ↓
start_execution()
    ↓
SUCCESS
```

Then:

```text
Step Functions
    ↓
Textract
    ↓
FAIL
```

The original SQS consumer invocation already succeeded.

Therefore:

```text
Original message → DLQ
```

does **not** automatically happen because Textract failed later.

---

# 25. What Protects Downstream Failures?

Downstream workflow failures need their own reliability mechanisms.

For example:

```text
Step Functions Retry/Catch

Job status updates

CloudWatch alarms

Workflow failure monitoring

Operational retry/reprocessing path
```

The queue DLQ and workflow failure handling solve different problems.

---

# 26. Partial Batch Failure Configuration

The project analysis identified another subtle issue.

The SQS event-source configuration enables partial batch failure handling, but the handler does not return the required partial-batch response structure.

Current batch size is:

```text
1
```

which limits the immediate impact.

But conceptually:

```text
Configuration says:
partial batch handling
```

while:

```text
Handler implementation
does not fully implement
that response contract
```

This is a reliability mismatch worth understanding.

---

# 27. Lambda Failure Types

A Lambda can fail because of:

```text
Application exception

Import error

Timeout

Out of memory

IAM AccessDenied

Bad environment variable

Invalid event format

Dependency problem

Downstream service error
```

The first question should be:

> **What type of failure is this?**

Different failures require different responses.

---

# 28. Retryable vs Non-Retryable Failure

Not every failure should be retried.

### Potentially transient

```text
Temporary throttling

Temporary service error

Short network interruption
```

Retry may help.

### Likely permanent until fixed

```text
Invalid input

Missing IAM permission

Programming bug

Wrong resource name

Malformed request
```

Retrying 100 times doesn't solve:

```text
AccessDenied
```

if the IAM policy is wrong.

---

# 29. Why Blind Retries Are Dangerous

Imagine:

```text
Bedrock throttles
   ↓
Retry
   ↓
Retry
   ↓
Retry
```

That's reasonable within limits.

But if every layer retries:

```text
SQS retry
   ×
Step Functions retry
   ×
Lambda retry
   ×
Bedrock application retry
```

you can create:

> **retry amplification**

One original operation may create many downstream attempts.

---

# 30. Retry Amplification

Conceptually:

```text
1 request
  ↓
3 workflow retries
  ↓
5 Bedrock attempts each
  ↓
15 model calls
```

This is only an illustrative example—not the exact current workflow configuration.

The point is:

> **Retries must be designed across the complete system, not independently in every component.**

---

# 31. Exponential Backoff

The Bedrock logic contains retry behavior using:

```text
Exponential backoff
+
Jitter
```

Simple backoff:

```text
Attempt 1 → wait 1
Attempt 2 → wait 2
Attempt 3 → wait 4
Attempt 4 → wait 8
```

The exact waits may differ.

The idea is:

> Don't immediately hammer a struggling service again.

---

# 32. What Is Jitter?

If 1,000 functions all retry at:

```text
exactly 2 seconds
```

they can create another traffic spike.

Jitter adds randomness:

```text
Function A → 2.1 sec
Function B → 2.7 sec
Function C → 2.3 sec
```

This spreads retry traffic.

---

# 33. Bedrock Retry Behavior

The project uses up to:

```text
5 application-level attempts
```

for relevant Bedrock retry behavior:

```text
Initial attempt
+
up to 4 retries
```

for handled scenarios such as throttling.

But don't say:

> ❌ “Every Bedrock failure is retried five times.”

Different error types can follow different paths.

---

# 34. Bedrock Fallback Behavior

This project has an important resilience decision.

For certain handled Bedrock failures:

```text
Bedrock fails
      ↓
Application returns fallback analysis
      ↓
anomalies = empty
      ↓
confidence = 0
      ↓
pipeline can continue
```

Then:

```text
Risk Rules
    ↓
Storage
    ↓
Business job may become COMPLETED
```

This preserves OCR results instead of losing the entire invoice.

But it creates a semantic problem.

---

# 35. Reliability vs Correctness

Imagine:

```text
Textract succeeds

Bedrock fails

Fallback created

Risk rules run

Job = COMPLETED
```

Operationally:

```text
Pipeline completed
```

But analytically:

```text
Full AI analysis did NOT complete normally
```

Therefore:

> **Reliability cannot mean merely reaching the final state.**

You also need to preserve **quality/degradation information**.

---

# 36. `COMPLETED` Can Be Misleading

A user sees:

```text
Status: COMPLETED
Risk: LOW
```

They may assume:

> “OCR, AI analysis and risk analysis all worked successfully.”

But the actual path could be:

```text
OCR ✓

Bedrock ✗

Fallback anomalies = []

Rules ✓

COMPLETED
```

Therefore:

```text
COMPLETED
≠
Every stage succeeded normally
```

This is one of the most important findings in the project.

---

# 37. Better Status Model

A stronger future model might distinguish:

```text
COMPLETED

COMPLETED_WITH_WARNINGS

AI_ANALYSIS_UNAVAILABLE

MANUAL_REVIEW_REQUIRED

FAILED
```

or separately store:

```text
workflow_status

ocr_status

ai_status

risk_status
```

Then the UI can say:

```text
Invoice processed,
but AI analysis was unavailable.
Manual review recommended.
```

Much safer than silently showing normal completion.

---

# 38. Lambda Timeout Is Different

Suppose the Bedrock Lambda has:

```text
try:
    call_bedrock()
except Exception:
    fallback()
```

You might think:

> “Every failure goes to fallback.”

No.

If the Lambda itself reaches its hard execution timeout:

```text
Lambda runtime terminates execution
```

ordinary application exception handling may not get the opportunity to create the fallback result.

Therefore:

> **A timeout is not equivalent to a caught API exception.**

---

# 39. Local Bedrock Rate Limiter Limitation

The Bedrock code contains application-level rate limiting.

But the rate limiter is local to one warm Lambda execution environment.

Imagine:

```text
Lambda Environment A
→ limiter A

Lambda Environment B
→ limiter B

Lambda Environment C
→ limiter C
```

They do not automatically share one global counter.

Therefore:

```text
local limiter
≠
account-wide distributed limiter
```

---

# 40. Why This Matters During Scale-Out

Suppose each environment believes:

```text
I am below the limit.
```

But together:

```text
A + B + C + D
```

may generate much more traffic.

A production design requiring strict global rate control needs a coordinated mechanism.

The current local limiter should not be described as globally enforcing Bedrock request rate.

---

# 41. Waiting Inside Lambda

The current limiter may sleep before a request.

Conceptually:

```text
Lambda starts
   ↓
Rate limiter says wait
   ↓
sleep()
   ↓
Bedrock request
```

But Lambda has a finite timeout.

Therefore:

```text
Time spent sleeping
+
Bedrock latency
+
Retries
```

can consume the function's execution budget.

Waiting itself can increase timeout risk.

---

# 42. Step Functions Reliability

Step Functions provides explicit orchestration.

Your main processing stages are:

```text
1. Textract

2. Bedrock

3. Risk Rules

4. Store Results
```

This is useful because each stage has a visible responsibility.

If Stage 2 fails, you don't have to think of the whole backend as one giant Lambda.

---

# 43. Workflow State vs Business State

This distinction is critical.

### Workflow state

What happened to the Step Functions execution?

```text
RUNNING

SUCCEEDED

FAILED

TIMED_OUT
```

### Business/job state

What does the application tell the user?

```text
PENDING

PROCESSING

COMPLETED

FAILED
```

These are related, but not identical.

Do not assume:

```text
Step Functions SUCCEEDED
=
every business analysis succeeded perfectly
```

because handled fallback paths may still produce successful workflow execution.

---

# 44. Textract Failure

Potential problems include:

```text
Invalid document

Unsupported document behavior

S3 access problem

Textract service error

Parsing error

Unexpected response structure
```

Troubleshooting path:

```text
Step Functions execution
      ↓
Textract Lambda
      ↓
CloudWatch logs
      ↓
Input bucket/key
      ↓
Textract response
      ↓
Parser
```

---

# 45. OCR Quality Failure vs Technical Failure

These are different.

### Technical failure

```text
Textract API call fails
```

### Quality failure

```text
Textract API succeeds
but extracts wrong total
```

CloudWatch may show:

```text
Lambda SUCCESS
```

while the business result is incorrect.

That's why:

> **Technical monitoring alone is not enough for AI/document-processing systems.**

You also need quality evaluation.

We studied that in File 11.

---

# 46. DynamoDB Failure

Suppose processing succeeds but final storage fails.

Then:

```text
Textract ✓
Bedrock ✓
Rules ✓
DynamoDB ✗
```

From the user's perspective:

```text
No result
```

even though expensive processing already occurred.

Troubleshoot:

```text
Storage Lambda logs

IAM permissions

Table name/configuration

Item structure

Item size

DynamoDB service response
```

---

# 47. Payload Size Risk

The workflow carries growing JSON state containing things such as:

```text
Identifiers

OCR data

AI output

Risk findings
```

and the final record can also become large.

This creates a scalability/reliability concern.

A stronger pattern for large artifacts is:

```text
Large Data
   ↓
S3
   ↓
Store Pointer
   ↓
Workflow / DynamoDB
```

rather than passing increasingly large payloads through every stage.

This is an improvement opportunity, not a description of the current implementation.

---

# 48. Artifact-Pointer Pattern

Instead of:

```text
Step 1
↓
500 KB payload

Step 2
↓
700 KB payload

Step 3
↓
900 KB payload
```

use:

```text
S3
└── processing/inv_123.json

Workflow:
{
  "artifact_key": "processing/inv_123.json"
}
```

Then each stage retrieves only what it needs.

Benefits can include:

```text
Smaller workflow state

Reduced payload-limit risk

Better artifact inspection

Easier replay/debugging
```

---

# 49. Frontend Reliability

Backend reliability is only half the story.

The frontend polls:

```text
Invoice detail

Job status
```

approximately every:

```text
3 seconds
```

during processing.

This allows the UI to discover completion without maintaining a persistent connection.

But the current implementation has a subtle reliability issue.

---

# 50. The Detail 404 Problem

Immediately after upload:

```text
Job exists
```

but:

```text
Final invoice record
does not exist yet
```

So:

```text
GET invoice detail
      ↓
404
```

can be normal during processing.

Later:

```text
Processing completes
      ↓
Invoice record exists
```

But if the frontend's detail query remains in stale error state and isn't correctly invalidated/refetched, the UI may fail to recover automatically.

---

# 51. Backend Success, Frontend Failure

This creates:

```text
Backend
COMPLETED ✓

DynamoDB
result exists ✓

Frontend
still showing stale error ✗
```

Very important lesson:

> **The system can succeed technically while the user still experiences failure.**

Reliability must be evaluated end to end.

---

# 52. Better Frontend Behavior

When status changes:

```text
PROCESSING
    ↓
COMPLETED
```

the frontend should:

```text
Invalidate invoice-detail query
        ↓
Refetch
        ↓
Display result
```

Similarly:

```text
FAILED
```

should produce a useful failure message rather than simply stopping polling.

---

# 53. Current Failure UI Gap

The project analysis found that the failure banner can disappear for:

```text
FAILED
```

instead of clearly surfacing the job error.

A stronger UX would say:

```text
Processing failed.

Stage: AI Analysis

Reference: inv_123

Please retry or contact support.
```

while avoiding unnecessary internal/security-sensitive details.

---

# 54. Observability for One Invoice

A strong logging pattern might include structured fields:

```json
{
  "invoice_id": "inv_123",
  "job_id": "job_inv_123",
  "stage": "bedrock_analysis",
  "status": "retrying",
  "attempt": 2
}
```

rather than:

```text
Something failed.
```

Structured logs are easier to search and aggregate.

---

# 55. What Should We Log?

Useful:

```text
invoice_id

job_id

stage

status

duration

attempt number

error category

AWS request identifier
```

Be careful with:

```text
Full invoice text

Authentication tokens

Presigned URLs

Full Bedrock prompt

Financial data
```

Observability must not create a new security problem.

---

# 56. Metrics Worth Monitoring

For this project, useful production metrics could include:

```text
API error rate

Lambda error count

Lambda duration

Lambda timeout count

SQS queue depth

Age of oldest SQS message

DLQ message count

Step Functions failures

Textract failures

Bedrock throttles

Bedrock fallback rate

Processing duration

Completed invoice count

Failed invoice count

Frontend/API error rate
```

These are recommended monitoring targets; do not claim every one currently has a configured alarm.

---

# 57. Business Metrics Matter Too

Technical metrics might say:

```text
Lambda error rate = low
```

while:

```text
40% of invoices
use AI fallback
```

That would be a serious quality/reliability problem.

Therefore monitor:

```text
Technical Health
+
Business Workflow Health
+
AI Quality/Degradation
```

---

# 58. AI Reliability Metrics

Useful future metrics include:

```text
Bedrock success rate

Fallback rate

JSON parse failure rate

Schema validation failure rate

AI latency

Retry count

Throttling rate

Manual-review rate
```

Recall File 11:

The project does not currently have a mature measured AI-evaluation framework proving these quality levels.

So treat these as recommended metrics.

---

# 59. Alerting

Monitoring without action can become:

```text
Beautiful dashboard
+
nobody notices outage
```

Alerts should correspond to meaningful operational conditions.

Examples:

```text
DLQ > 0

SQS oldest message too old

Step Functions failure rate high

Lambda errors spike

Bedrock fallback rate high

API 5xx rate high
```

Thresholds should come from expected behavior and service objectives—not arbitrary numbers copied from the internet.

---

# 60. What Is an SLO?

SLO means:

> **Service Level Objective**

Example concept:

```text
99.x% of invoice-processing jobs
complete within an agreed time
```

But we do **not** have verified project measurements supporting a specific SLO.

So don't invent:

> ❌ “Our SLA is 99.99%.”

unless actual business requirements and measurements establish it.

---

# 61. Reliability Needs Timeouts

Every remote operation should have a clear time budget.

Think:

```text
Overall processing budget
        │
        ├── Textract
        ├── Bedrock
        ├── Retry waiting
        └── Storage
```

If one component consumes all available time:

```text
downstream stages
cannot finish
```

Timeout design should therefore consider the complete request/workflow budget.

---

# 62. Retry + Timeout + Idempotency

These three concepts belong together.

```text
TIMEOUT
→ When should I stop waiting?
```

```text
RETRY
→ Should I try again?
```

```text
IDEMPOTENCY
→ If I try again, can I do it safely?
```

This is an excellent interview framework.

---

# 63. Example

Suppose storage request times out.

You don't know whether:

```text
Write failed
```

or:

```text
Write succeeded
but response was lost
```

Then you retry.

Without idempotency:

```text
Retry
→ duplicate side effect
```

With a deterministic key such as:

```text
tenant_id + invoice_id
```

you can often design safer repeated writes.

---

# 64. Failure Classification

When troubleshooting, classify the problem.

### Configuration

```text
Wrong environment variable

Wrong table name

Wrong IAM permission
```

### Code

```text
Import error

Parser bug

Unhandled exception
```

### Dependency

```text
Bedrock throttling

Textract service failure
```

### Data

```text
Malformed invoice

Unexpected OCR structure
```

### Scale

```text
Queue backlog

Concurrency pressure

Rate limits
```

### Frontend

```text
Stale query

Polling problem

Authentication state
```

This prevents random debugging.

---

# 65. Troubleshooting Decision Tree

Use this in interviews:

```text
User reports problem
        ↓
Can I reproduce it?
        ↓
Find invoice_id/job_id
        ↓
Determine last successful stage
        ↓
Check logs/metrics for next stage
        ↓
Classify failure
        ↓
Configuration?
Code?
Dependency?
Data?
Scale?
Frontend?
        ↓
Fix
        ↓
Replay/retry safely
        ↓
Validate end to end
        ↓
Add prevention/monitoring
```

This is much stronger than:

> “I check CloudWatch.”

---

# 66. Why “I Check CloudWatch” Is Weak

Interviewer:

> “How do you troubleshoot?”

Weak:

> “I check CloudWatch logs.”

Better:

> “I start with the invoice ID, identify the last successful stage, then use CloudWatch logs and workflow state to trace the invoice through SQS, the trigger Lambda and Step Functions. I classify the failure before deciding whether it is safe to retry.”

Tools are not the troubleshooting strategy.

They support the strategy.

---

# 67. Recovery

Detection alone isn't enough.

Suppose:

```text
Textract failed temporarily.
```

After fixing the issue, how do you recover that invoice?

Possible production mechanisms include:

```text
Retry workflow stage

Restart workflow

Replay invoice event

Requeue job

Manual retry endpoint
```

But any replay mechanism must consider:

```text
Idempotency
```

or recovery can create duplicates.

The current source analysis does not establish a mature universal replay mechanism, so treat this as a production design area.

---

# 68. DLQ Redrive

If an SQS message reaches the DLQ because the trigger/handoff repeatedly failed, you may eventually want to redrive/reprocess it after fixing the underlying issue.

But first ask:

```text
Why did it fail?

Has the cause been fixed?

Will replay create duplicates?
```

Never blindly replay a DLQ.

---

# 69. Failure Injection

A mature reliability program intentionally tests failure scenarios.

Examples:

```text
Make Bedrock unavailable

Use invalid document

Remove temporary IAM permission in test

Force storage failure

Send duplicate SQS event

Cause frontend detail 404

Simulate throttling
```

Then ask:

```text
Does retry behave correctly?

Does status remain accurate?

Does user see useful information?

Do we create duplicates?

Do alerts fire?
```

This is often called resilience/failure testing.

It is a recommended improvement, not a verified current test suite.

---

# 70. Current Reliability Strengths

From the project analysis:

```text
✓ Event-driven architecture

✓ SQS buffering

✓ SQS DLQ infrastructure

✓ Step Functions orchestration

✓ Stage-based processing

✓ Bedrock retry logic

✓ Exponential backoff + jitter

✓ AI fallback behavior

✓ Processing-job state

✓ CloudWatch foundations

✓ X-Ray configuration

✓ Frontend polling

✓ Separate persistent result storage
```

These are useful reliability foundations.

---

# 71. Current Reliability Limitations

Important limitations include:

```text
⚠ At-least-once duplicate-processing risk

⚠ Strong idempotency not guaranteed

⚠ Job state can be rewritten/reset

⚠ Partial-batch configuration/handler mismatch

⚠ SQS DLQ does not protect all
  downstream workflow failures

⚠ AI failure can still appear COMPLETED

⚠ Local Bedrock rate limiter is
  not globally coordinated

⚠ Waiting/retries can consume Lambda timeout

⚠ Growing workflow payload

⚠ Frontend stale detail-query behavior

⚠ FAILED UX does not clearly
  surface processing error

⚠ Full distributed tracing
  not verified

⚠ Complete alerting strategy
  not verified
```

---

# 72. Production Reliability Improvement Plan

A stronger production version could prioritize:

```text
1. Strong idempotency guard

2. Correct partial-batch behavior

3. Separate workflow and component statuses

4. Explicit degraded AI state

5. Downstream failure alarms

6. Safe workflow replay mechanism

7. DLQ operational runbook

8. Coordinated rate/concurrency controls

9. Artifact-pointer pattern

10. Structured correlated logging

11. End-to-end tracing

12. Frontend cache invalidation/refetch

13. Clear FAILED UI

14. Business-level health metrics

15. AI fallback/validation metrics

16. Failure-injection testing

17. Defined SLOs based on real measurements
```

---

# 73. Troubleshooting Runbook — Upload Doesn't Process

Use this exact mental sequence:

```text
STEP 1
Did upload-url API succeed?
        ↓
STEP 2
Did browser PUT succeed?
        ↓
STEP 3
Does object exist in S3?
        ↓
STEP 4
Did S3 produce event?
        ↓
STEP 5
Did SQS receive it?
        ↓
STEP 6
Did trigger Lambda consume it?
        ↓
STEP 7
Was Step Functions execution created?
        ↓
STEP 8
Which workflow state was last successful?
        ↓
STEP 9
Inspect that Lambda's logs
        ↓
STEP 10
Check downstream service response
        ↓
STEP 11
Fix root cause
        ↓
STEP 12
Safely retry/replay
        ↓
STEP 13
Verify frontend result
```

This is an excellent interview answer structure.

---

# 74. Troubleshooting Runbook — Result Says LOW but Looks Suspicious

This is not necessarily an infrastructure failure.

Investigate:

```text
Was OCR accurate?
      ↓
What fields did Textract extract?
      ↓
Did Bedrock succeed normally?
      ↓
Was fallback used?
      ↓
Were anomalies valid?
      ↓
Did Python rules parse amounts correctly?
      ↓
Was there double counting
or missed rule logic?
      ↓
What final score components
were applied?
```

This connects reliability with AI quality and business-rule correctness.

---

# 75. Interview Preparation — 10 Questions

## Q1 — How do you make your project reliable?

**Difficulty:** Basic

### Word-by-word practice answer

> “I use multiple reliability mechanisms across the asynchronous processing flow. SQS buffers invoice events between S3 and processing, Step Functions orchestrates the main stages, processing jobs track application status, and the Bedrock integration has retry logic with exponential backoff and jitter for handled transient failures. CloudWatch provides logging and operational visibility. I also identified areas that need improvement, especially idempotency, downstream failure handling, status semantics and frontend recovery.”

---

## Q2 — Why do you use SQS?

**Difficulty:** Basic

### Word-by-word practice answer

> “SQS decouples invoice ingestion from processing. When an invoice reaches S3, the event can be buffered in the queue rather than requiring all downstream processing to happen immediately. This helps absorb temporary processing delays and provides retry behavior for the SQS consumer. However, because SQS uses at-least-once delivery, the application must also handle duplicate delivery safely.”

---

## Q3 — What is idempotency and why do you need it?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Idempotency means that processing the same logical event more than once does not create unintended duplicate effects. It matters because SQS can deliver a message more than once. In this project, strong exactly-once processing is not guaranteed, so a production improvement would be an atomic idempotency check, for example using a DynamoDB conditional operation before starting processing.”

---

## Q4 — If Textract fails, will the SQS message go to the DLQ?

**Difficulty:** Intermediate / Pressure

### Word-by-word practice answer

> “Not necessarily, and this is an important boundary in my architecture. The SQS consumer Lambda starts the Step Functions workflow asynchronously and then returns. If that handoff succeeds, the SQS message can be considered successfully consumed. A later Textract failure inside Step Functions does not automatically return the original SQS message to the queue or its DLQ. The SQS DLQ mainly protects the queue-to-trigger and workflow-start handoff, while downstream workflow failures require separate Step Functions error handling, status tracking and monitoring.”

---

## Q5 — How does your Bedrock retry mechanism work?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The Bedrock integration has application-level retry behavior for handled transient failures such as throttling, using exponential backoff with jitter. The implementation allows up to five attempts including the initial request. However, I don't claim that every possible Bedrock failure is retried five times because different exceptions can follow different paths, and a Lambda execution timeout cannot simply be handled like an ordinary caught API exception.”

---

## Q6 — What happens if Bedrock fails?

**Difficulty:** Intermediate / Advanced

### Word-by-word practice answer

> “For certain handled Bedrock failures, the application can create a fallback analysis with no AI anomalies and zero confidence, then continue into deterministic risk scoring and result storage. This preserves the OCR result instead of losing the whole invoice. The weakness is that the business job can still become `COMPLETED`, so a low score after AI failure is not equivalent to a fully analyzed low-risk invoice. I would introduce an explicit degraded or manual-review status.”

---

## Q7 — How do you troubleshoot an invoice that is stuck?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I start with the invoice ID and job ID and identify the last stage I can prove succeeded. I verify the S3 upload, then SQS delivery, trigger Lambda invocation and Step Functions execution. Inside the workflow I identify whether Textract, Bedrock, risk scoring or storage was the last successful stage and inspect the corresponding CloudWatch logs and service response. I classify the problem as code, configuration, dependency, data, scale or frontend before deciding how to fix and safely replay it.”

---

## Q8 — What is the difference between monitoring and observability?

**Difficulty:** Advanced

### Word-by-word practice answer

> “Monitoring tells me about known system conditions, such as Lambda error count, queue depth or workflow failures. Observability helps me understand why a specific behavior occurred by correlating logs, metrics and traces across components. For this project, I want to be able to start with an invoice ID and trace that invoice through SQS, Lambda, Step Functions, Textract, Bedrock and storage rather than only seeing isolated service metrics.”

---

## Q9 — Can Step Functions show SUCCEEDED while the AI stage had a problem?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “Yes. A handled Bedrock failure can be converted into a fallback result, allowing the workflow to continue through risk scoring and storage. Therefore the workflow may complete successfully from an orchestration perspective even though AI analysis was unavailable or degraded. That is why I separate technical workflow state from business and analysis-quality state instead of treating `SUCCEEDED` or `COMPLETED` as proof that every stage worked normally.”

---

## Q10 — How would you improve reliability for production?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “I would first add stronger atomic idempotency so duplicate SQS deliveries cannot restart processing incorrectly. I would correct the partial-batch response behavior, separate workflow status from OCR, AI and risk-analysis status, and introduce an explicit degraded state when Bedrock analysis is unavailable. I would add structured correlated logging, alarms for downstream workflow failures and DLQ messages, safe replay procedures, coordinated rate and concurrency controls, and reduce workflow payload size using S3 artifact references. Finally, I would fix frontend query invalidation so backend completion reliably appears to the user and validate the design with failure-injection and end-to-end tests.”

---

# 76. Interview Pressure Chain

Interviewer:

> **“What happens when something fails?”**

Then expect:

```text
Where do you check first?
        ↓
How do you identify one invoice?
        ↓
What is CloudWatch?
        ↓
What is X-Ray?
        ↓
Why SQS?
        ↓
Does SQS guarantee exactly once?
        ↓
What is idempotency?
        ↓
How would you implement it?
        ↓
What is a DLQ?
        ↓
Does Textract failure send
the SQS message to DLQ?
        ↓
Why not?
        ↓
Where should downstream
failure handling happen?
        ↓
What if Bedrock throttles?
        ↓
What is exponential backoff?
        ↓
What is jitter?
        ↓
What if Bedrock still fails?
        ↓
Can job still say COMPLETED?
        ↓
Why is that dangerous?
        ↓
Can Lambda timeout be caught normally?
        ↓
Is your rate limiter global?
        ↓
What is retry amplification?
        ↓
What if DynamoDB fails?
        ↓
What if backend succeeds
but UI still shows 404?
        ↓
How would you monitor production?
        ↓
How would you replay safely?
```

If you can handle this chain, you can discuss **real distributed-system reliability**, not just list AWS services.

---

# 77. Interview Scenario — SQS DLQ

Interviewer:

> **“You have a DLQ, so every failed invoice is safe, correct?”**

### Strong answer

> “No. The DLQ has a specific failure boundary. In my architecture, SQS invokes a trigger Lambda whose responsibility is to start the Step Functions workflow. Once that Lambda successfully starts the workflow and returns, later failures such as Textract or storage errors occur outside the original SQS-consumer lifecycle. Therefore the SQS DLQ protects the handoff into processing, but downstream workflow failures need their own retry, status, alerting and recovery mechanisms.”

This answer is extremely important.

---

# 78. Interview Scenario — Production Incident

Interviewer:

> **“A customer says an invoice has been processing for 20 minutes. What do you do?”**

### Word-by-word answer

> “I would first obtain the invoice ID and inspect its processing-job state to identify the reported stage. Then I would verify the actual backend path rather than trusting only the frontend status. I would confirm the S3 object exists, check whether the SQS trigger started a Step Functions execution and inspect the workflow execution to find the last successful state. From there I would inspect the relevant Lambda logs and downstream service response. I would also check whether the backend has already completed but the frontend is showing stale data because of its polling and detail-query behavior. After finding the root cause, I would only replay the invoice after checking idempotency and duplicate-processing risk.”

---

# 79. Interview Scenario — Bedrock Outage

Interviewer:

> **“What if Bedrock becomes temporarily unavailable?”**

### Strong answer

> “For handled transient errors, the current integration retries using exponential backoff and jitter. Certain handled failures can then fall back to an analysis-unavailable result so OCR data can still be stored and the deterministic pipeline can continue. The limitation is that the current business status can still become `COMPLETED`, which may hide the degraded AI state. For production I would expose a separate AI status such as `AI_ANALYSIS_UNAVAILABLE` or `MANUAL_REVIEW_REQUIRED`, monitor the fallback rate and provide a controlled reprocessing mechanism when the service recovers.”

---

# 80. Interview Scenario — Duplicate Event

Interviewer:

> **“What if SQS delivers the same invoice event twice?”**

### Strong answer

> “SQS provides at-least-once delivery, so duplicate delivery must be expected. The current project does not provide a strong exactly-once guarantee, and duplicate processing or job-state reset is therefore a reliability risk. I would use a deterministic invoice identifier together with an atomic DynamoDB conditional write or state transition so that only the first valid processing attempt can acquire the right to start the workflow. Later duplicate deliveries would detect the existing state and safely exit.”

---

# 81. Reliability Mental Model

Remember this:

```text
                    INVOICE
                       │
                       ▼
                      S3
                       │
                       ▼
                 SQS + DLQ
                       │
                       ▼
                Trigger Lambda
                       │
                       ▼
                Step Functions
                 /     |      \
                /      |       \
               ▼       ▼        ▼
          Textract  Bedrock   Rules
                       │
                       ▼
                    Storage
                       │
                       ▼
                    Frontend
```

Now overlay reliability:

```text
Queue
→ buffering + retry

DLQ
→ failed handoff messages

Step Functions
→ orchestration/error boundaries

Bedrock
→ retry + fallback

Job state
→ user-visible progress

CloudWatch
→ logs/metrics

X-Ray
→ tracing foundation

DynamoDB
→ persistent operational state
```

---

# 82. Five Things You Must Remember

**1. SQS is at-least-once, not exactly-once.**

```text
Duplicate delivery
is possible
```

Therefore:

```text
Idempotency matters
```

**2. The SQS DLQ does NOT protect the whole Step Functions pipeline.**

```text
SQS
↓
Trigger
↓
Start Workflow
```

is its main boundary.

Later Textract/Bedrock/storage failures need separate handling.

**3. `COMPLETED` does not prove AI succeeded normally.**

```text
Bedrock failure
↓
Fallback
↓
Rules
↓
Storage
↓
COMPLETED
```

can happen.

**4. Troubleshoot using the last proven successful stage.**

```text
Upload ✓
SQS ✓
Workflow ✓
Textract ✓
Bedrock ?
```

Investigate Bedrock next.

**5. Observability is more than logs.**

```text
Logs
+
Metrics
+
Traces
+
Correlation
```

should help explain what happened to one invoice.

---

# 83. Your 30-Second Interview Answer

> “The project uses an asynchronous event-driven design for reliability. SQS buffers S3 upload events, a trigger Lambda starts an Express Step Functions workflow, and the workflow separates Textract, Bedrock analysis, deterministic risk scoring and storage into stages. Bedrock has retry logic with exponential backoff and jitter, and CloudWatch and X-Ray provide observability foundations. I also identified important limitations: SQS can deliver duplicates, strong idempotency is not guaranteed, the SQS DLQ mainly protects the workflow-start handoff rather than downstream Step Functions failures, and handled AI failures can still produce a `COMPLETED` business status. For production I would strengthen idempotency, degraded-state handling, correlated observability, alerting and safe replay.”

---

# 84. Your 10-Second Mental Model

For reliability:

```text
BUFFER
 ↓
RETRY
 ↓
IDEMPOTENCY
 ↓
FAILURE STATE
 ↓
RECOVERY
```

For troubleshooting:

```text
Invoice ID
    ↓
Last Successful Stage
    ↓
Next Failed Stage
    ↓
Logs + Metrics + Trace
    ↓
Root Cause
    ↓
Safe Recovery
```

For observability:

```text
Logs
+
Metrics
+
Traces
=
Understand the system
```

One sentence to remember:

> **“I don't troubleshoot by guessing which AWS service failed; I trace the invoice from the last verified successful stage, identify the failure boundary, fix the root cause, and only then retry or replay it safely.”**

---

# 85. Check Your Understanding

Before moving to **`21-Testing-and-AI-Quality.md`**, answer these three in your own words.

**Question 1:** Explain why this assumption is wrong:

```text
SQS has DLQ
     ↓
Textract fails later
     ↓
Original SQS message
must go to DLQ
```

Where is the real DLQ boundary in your architecture?

**Question 2:** Suppose the application shows:

```text
Status: COMPLETED
Risk: LOW
```

but Bedrock actually failed.

How can that happen in the current implementation, and why is it dangerous to interpret that result as a fully analyzed low-risk invoice?

**Question 3:** A user says:

> **“My invoice is stuck.”**

Explain how you would troubleshoot it using:

```text
invoice_id
    ↓
last successful stage
    ↓
CloudWatch / workflow state
    ↓
failure classification
    ↓
safe recovery
```

Do not answer only **“I check CloudWatch.”** Explain the actual investigation path.