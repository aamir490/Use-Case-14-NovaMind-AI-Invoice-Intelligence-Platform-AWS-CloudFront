# Your question

**Create `22-Cost-Scalability-and-Performance.md`.**

# 22 — Cost, Scalability, and Performance

This chapter answers three interview questions that often come together:

> **How much does your architecture cost? How does it scale? What happens when traffic increases?**

For NovaMind AI, these questions must be answered carefully. The repository contains a serverless architecture that can benefit from AWS managed scaling, but the analysis did **not** establish production throughput, maximum user count, measured performance, or actual monthly AWS cost. :chatgpt-content-reference{index="0"}

---

# 1. What Will I Learn?

By the end of this file, I should understand:

- Cost vs scalability vs performance
- Why serverless does not mean unlimited
- Main AWS cost drivers in NovaMind AI
- Textract and Bedrock cost behavior
- Lambda and Step Functions cost considerations
- S3 and DynamoDB cost considerations
- Polling and CloudWatch costs
- Duplicate-processing cost
- SQS as a buffer
- Why SQS does not automatically protect downstream services
- AWS service quotas
- Lambda concurrency
- Bedrock rate-limiter limitation
- Analytics scaling problem
- DynamoDB partition concentration
- Step Functions payload growth
- DynamoDB record-size risk
- End-to-end latency
- p50, p95 and p99
- Throughput
- Bottlenecks
- Backpressure
- Load testing
- Cost-per-invoice measurement
- Production optimization ideas
- 10 project-specific interview questions

---

# 2. First Separate Three Concepts

Do not mix these terms.

## Cost

Cost asks:

> **“How much money does the system consume?”**

Examples:

```text
Textract requests
Bedrock tokens
Lambda execution
DynamoDB operations
S3 storage
CloudWatch logs
```

---

## Scalability

Scalability asks:

> **“Can the system handle more workload?”**

For example:

```text
100 invoices/day
        ↓
1,000 invoices/day
        ↓
10,000 invoices/day
```

Can the architecture handle that increase?

---

## Performance

Performance asks:

> **“How quickly and efficiently does the system respond?”**

For NovaMind AI:

```text
Upload invoice
      ↓
How long until
result is available?
```

These are related, but they are not the same.

---

# 3. NovaMind AI Architecture from a Scaling View

Think about the project like this:

```text
                    USERS
                      │
                      ▼
              CloudFront + React
                      │
                      ▼
                 API Gateway
                      │
                      ▼
           Presigned S3 Upload
                      │
                      ▼
                     S3
                      │
                      ▼
                     SQS
                      │
                      ▼
               Trigger Lambda
                      │
                      ▼
            Step Functions Express
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
      Textract     Bedrock     Python Rules
                                  │
                                  ▼
                           S3 + DynamoDB
                                  │
                                  ▼
                            API Gateway
                                  │
                                  ▼
                           React Polling
```

Each service has its own:

```text
Cost
+
Capacity
+
Quota
+
Latency
+
Failure behavior
```

---

# 4. Why Serverless Helps

NovaMind AI uses managed/serverless services such as:

```text
API Gateway
Lambda
S3
SQS
Step Functions
DynamoDB
Textract
Bedrock
```

This means you do not manage application servers such as:

```text
EC2 instance
      ↓
install OS
      ↓
install application
      ↓
manually increase servers
```

Many AWS services automatically handle substantial infrastructure scaling.

That's a major advantage.

But never say:

> ❌ “Serverless means unlimited scalability.”

---

# 5. Serverless Does Not Mean Unlimited

Even serverless architectures have constraints:

```text
Lambda concurrency
Textract quotas
Bedrock quotas
Step Functions limits
DynamoDB access patterns
API Gateway limits
payload sizes
timeouts
downstream capacity
```

Therefore:

```text
Serverless
   ≠
Infinite capacity
```

Better mental model:

```text
Serverless
   =
AWS manages much of the infrastructure scaling

BUT

application design
+
quotas
+
downstream services
+
data access patterns
still matter
```

---

# 6. Current Cost Drivers

The Codex analysis identifies these project cost drivers:

```text
Textract requests/pages

Bedrock input/output tokens

Duplicate processing

Lambda duration

Step Functions executions/duration

DynamoDB queries/writes

S3 storage/versions/requests

API polling

CloudWatch logs

Frontend delivery/invalidations
```

:chatgpt-content-reference{index="1"}

We need to understand each one.

---

# 7. Textract Cost

Your OCR stage uses:

```text
Amazon Textract
AnalyzeExpense
```

Conceptually:

```text
Invoice
   ↓
Textract request
   ↓
OCR / expense extraction
```

Therefore, more documents/pages mean more Textract usage.

Your project currently uses synchronous expense extraction. :chatgpt-content-reference{index="2"}

---

# 8. Why Document Size Matters

Imagine:

```text
Invoice A
1 page
```

versus:

```text
Invoice B
many pages
```

They do not necessarily represent the same processing workload.

Document characteristics can influence:

```text
OCR work
data returned
workflow payload size
Bedrock prompt size
processing time
```

There is another important project-specific issue:

> The current parser reads only the first expense document.

So do not claim:

> ❌ “The system is fully optimized for arbitrary large multi-page invoice processing.”

That is not established by the current implementation.

---

# 9. Bedrock Cost

The application uses:

```text
Amazon Bedrock
        ↓
Nova Micro
```

Bedrock receives:

```text
Structured invoice fields
+
line items
+
raw OCR text
```

Therefore prompt size matters.

Conceptually:

```text
More OCR text
      ↓
Larger model input
      ↓
More token usage
      ↓
Potentially more cost
+
potentially more latency
```

The current implementation does not have an explicit input token-budgeting or truncation strategy.

---

# 10. Output Tokens Matter Too

The current Bedrock configuration allows:

```text
maxTokens = 1500
```

That does **not** mean every request generates 1,500 tokens.

It means the generation is bounded by that configured maximum.

Cost/performance thinking should consider both:

```text
Input tokens
+
Output tokens
```

rather than just:

```text
Number of Bedrock calls
```

---

# 11. Bedrock Retries Can Increase Cost and Latency

Recall the current retry design:

```text
Initial attempt
+
up to 4 retries
```

So a difficult request could involve multiple attempts.

Conceptually:

```text
Bedrock call
   ↓
Throttled
   ↓
Wait
   ↓
Retry
   ↓
Wait
   ↓
Retry
```

This affects:

```text
Latency
+
Lambda duration
+
request volume
```

So retry design is also a cost/performance concern.

---

# 12. Lambda Cost

Lambda cost is related to execution characteristics.

For this project, Lambda runs:

```text
API logic
Queue bridge
OCR processing
AI processing
Risk processing
Storage
```

Longer-running functions generally mean more compute usage.

A particularly important case is the Bedrock Lambda.

---

# 13. Waiting Inside Lambda

The project has application-level Bedrock rate limiting and retry waiting.

Conceptually:

```text
Lambda starts
     ↓
Rate limiter says wait
     ↓
Lambda sleeps
     ↓
Bedrock request
```

During that waiting period, the function invocation still exists.

So:

```text
Waiting
≠
Free processing architecture
```

More importantly, waiting consumes part of the function's available execution time.

---

# 14. Current Bedrock Rate Limiter Problem

This is a strong interview topic.

The rate limiter is:

```text
local to one warm Lambda environment
```

It does not coordinate across concurrent Lambda instances. A cold Lambda environment also resets that local state. :chatgpt-content-reference{index="3"}

Imagine:

```text
Lambda Instance A
Limiter A

Lambda Instance B
Limiter B

Lambda Instance C
Limiter C
```

They do not share one global limiter.

Therefore:

```text
More Lambda concurrency
        ↓
More independent limiters
        ↓
Higher aggregate Bedrock request rate
```

---

# 15. Another Rate Limiter Issue

Codex also found that the limiter records a pre-sleep timestamp after sleeping, weakening the intended rolling-window behavior. Waiting inside a Lambda with a 60-second timeout can itself increase timeout risk. :chatgpt-content-reference{index="4"}

That means this is not just:

```text
Cost problem
```

It is also:

```text
Reliability problem
+
Performance problem
```

---

# 16. Step Functions Cost

Your application uses:

```text
Step Functions Express
```

with a sequential four-stage processing workflow. :chatgpt-content-reference{index="5"}

Conceptually:

```text
OCR
 ↓
AI
 ↓
Risk Rules
 ↓
Store
```

More invoices mean:

```text
More workflow executions
```

Retries and longer execution durations can also affect overall resource usage.

---

# 17. S3 Cost

S3 is used for:

```text
Original invoices

Extracted text

Frontend static assets
```

The upload bucket also has versioning enabled. :chatgpt-content-reference{index="6"}

So S3 cost thinking includes:

```text
Storage
+
Requests
+
Object versions
+
Data lifecycle
```

---

# 18. Versioning Has a Cost Implication

With versioning:

```text
Object V1
Object V2
Object V3
```

old versions may remain stored.

That can be useful for recovery.

But:

```text
More historical versions
      ↓
More stored data
```

So lifecycle policy design matters.

This connects directly to File 19:

**Security and Data Lifecycle.**

---

# 19. Processed S3 Data

The processed bucket currently stores extracted text at:

```text
processed-text/{tenant_id}/{invoice_id}.txt
```

The storage handler does **not** currently write the complete OCR and analysis JSON artifacts there. :chatgpt-content-reference{index="7"}

This is important when discussing optimization.

Do not say:

> ❌ “All large intermediate AI artifacts are already offloaded to S3.”

They are not.

---

# 20. DynamoDB Cost

The project uses:

```text
Invoices table

Processing-jobs table
```

The repository defines DynamoDB as on-demand for these tables. :chatgpt-content-reference{index="8"}

DynamoDB cost/performance is influenced by:

```text
Reads

Writes

Amount of data

Access patterns

Item sizes
```

---

# 21. Current Invoice Key Design

Verified structure:

```text
Invoices Table

Partition Key:
tenant_id

Sort Key:
invoice_id
```

:chatgpt-content-reference{index="9"}

This makes tenant-scoped invoice retrieval natural:

```text
tenant_id
   ↓
all invoices belonging to that user
```

But it creates an important scaling question.

---

# 22. Tenant Partition Concentration

All invoices belonging to one user share the same partition-key value:

```text
tenant_id = User A
```

Conceptually:

```text
User A
 ├── Invoice 1
 ├── Invoice 2
 ├── Invoice 3
 ├── Invoice 4
 └── ...
```

Codex identifies high-volume tenant concentration as something that needs workload testing. :chatgpt-content-reference{index="10"}

Do not claim it is already a demonstrated bottleneck.

The correct wording is:

> **“The current access pattern concentrates one user's invoices under the same partition-key value, so high-volume tenant behavior should be validated through workload testing.”**

---

# 23. Analytics Is an Important Scaling Concern

The project has multiple analytics endpoints.

The current implementation independently retrieves the tenant's invoice collection and performs aggregation in application code.

Codex specifically identifies **four analytics endpoints** with this scaling characteristic. :chatgpt-content-reference{index="11"}

Think:

```text
Analytics Request
       ↓
Retrieve tenant invoices
       ↓
Python aggregation
       ↓
Return summary/chart data
```

---

# 24. Why This Works at Small Scale

Suppose a tenant has:

```text
20 invoices
```

Reading them and aggregating them in Python may be simple.

But imagine:

```text
20
↓
2,000
↓
200,000
```

The same pattern becomes increasingly expensive.

Potential impact:

```text
More DynamoDB reads
+
More Lambda processing
+
More latency
```

The repository does not establish at what exact volume this becomes unacceptable.

---

# 25. Future Analytics Optimization

A more scalable design could maintain:

```text
Pre-aggregated analytics
```

For example:

```text
Invoice Completed
       ↓
Event
       ↓
Update Aggregate Record
       ↓
Dashboard reads summary
```

instead of:

```text
Dashboard request
       ↓
Read every invoice
       ↓
Calculate everything again
```

This is a **proposed production improvement**, not the current implementation.

---

# 26. What Does SQS Do for Scalability?

Current flow:

```text
S3
 ↓
SQS
 ↓
Trigger Lambda
 ↓
Step Functions
```

SQS provides a buffer.

Imagine 1,000 invoices arrive quickly.

Without buffering:

```text
1,000 events
     ↓
downstream immediately
```

With SQS:

```text
1,000 events
     ↓
QUEUE
     ↓
consumers process messages
```

This decouples event arrival from processing.

---

# 27. But Here Is the Important Limitation

Do not say:

> ❌ “SQS automatically protects Textract and Bedrock from overload.”

The Codex analysis specifically warns:

> SQS buffers events, but the bridge launches workflows quickly and does not itself limit the number of active Textract or Bedrock operations. :chatgpt-content-reference{index="12"}

Current architecture:

```text
SQS
 ↓
Trigger Lambda
 ↓
Start Step Functions
 ↓
Trigger returns
```

Then workflows can continue independently.

---

# 28. Buffering vs Throttling

These are different concepts.

### Buffering

```text
Requests arrive
      ↓
Queue stores them
```

### Throttling

```text
Only allow N operations
at a controlled rate
```

SQS gives you buffering.

But your architecture does not automatically create a global:

```text
Only process X Bedrock requests
at one time
```

control.

---

# 29. Backpressure

Backpressure means preventing a fast producer from overwhelming a slower consumer.

Imagine:

```text
Uploads:
1,000/minute

Bedrock safe processing:
much lower
```

Without effective backpressure:

```text
Uploads
  ↓↓↓↓↓↓↓↓↓
Workflows
  ↓↓↓↓↓↓↓↓↓
Bedrock
  ↓
Throttling
```

A queue helps, but only if consumption is also controlled appropriately.

---

# 30. Production Backpressure Design

A future architecture might introduce controlled concurrency around processing.

Conceptually:

```text
SQS
 ↓
Controlled consumer concurrency
 ↓
Workflow
 ↓
Textract / Bedrock
```

or another quota-aware orchestration design.

The exact production design should depend on measured service quotas and workload.

Do not invent a concurrency number.

---

# 31. What Is Concurrency?

Concurrency means:

> **How many operations are running at the same time?**

Example:

```text
Invoice A → Bedrock
Invoice B → Bedrock
Invoice C → Bedrock
Invoice D → Bedrock
```

All four active together:

```text
Concurrency = 4
```

---

# 32. Lambda Concurrency

Lambda can execute multiple function instances concurrently.

Conceptually:

```text
Request 1 → Lambda Instance A

Request 2 → Lambda Instance B

Request 3 → Lambda Instance C
```

This helps scalability.

But more Lambda concurrency can also produce:

```text
More downstream calls
```

Therefore:

```text
Lambda scales
```

does not necessarily mean:

```text
Textract / Bedrock can accept
unlimited requests
```

---

# 33. Downstream Quotas

This is one of the most important cloud architecture concepts.

Imagine:

```text
Lambda
can scale quickly
```

but:

```text
Bedrock
has account/service limits
```

Then the bottleneck becomes:

```text
Bedrock
```

not Lambda.

A system scales only as well as its constrained dependencies.

---

# 34. Bottleneck

A bottleneck is:

> **The component limiting overall system throughput or performance.**

Think about a road:

```text
5-lane highway
      ↓
1-lane bridge
      ↓
5-lane highway
```

The bridge controls throughput.

In NovaMind AI, possible constraints include:

```text
Textract quotas

Bedrock quotas

Lambda concurrency

Workflow execution behavior

DynamoDB access patterns

Analytics design

Payload size

Frontend polling
```

These are **possible/likely constraints**, not verified measured bottlenecks.

---

# 35. Workflow Payload Growth

This is a project-specific concern that you must remember.

The workflow carries growing JSON containing:

```text
Identifiers
+
OCR data
+
AI output
+
Risk findings
```

Codex found no artifact-pointer strategy for large intermediate results. :chatgpt-content-reference{index="13"}

Conceptually:

```text
Step 1
small payload
   ↓
OCR
   ↓
larger payload
   ↓
AI output
   ↓
even larger payload
   ↓
Risk findings
   ↓
larger final state
```

---

# 36. Why Payload Growth Matters

Larger documents can produce:

```text
More OCR text

More line items

More AI findings
```

which means:

```text
Larger workflow state
```

Eventually this creates risk around service payload and record-size limits.

The important design principle is:

> **Do not move arbitrarily large documents and AI artifacts through orchestration state.**

---

# 37. Artifact-Pointer Pattern

A scalable alternative is:

```text
Large OCR Result
      ↓
Store in S3
      ↓
Workflow carries:
s3://reference
```

Instead of:

```text
Workflow carries
entire OCR result
```

Conceptually:

```text
BAD FOR LARGE PAYLOADS

Step Functions
{
  huge_ocr_text,
  huge_ai_result,
  huge_findings
}
```

versus:

```text
BETTER LARGE-ARTIFACT PATTERN

Step Functions
{
  invoice_id,
  tenant_id,
  artifact_reference
}
```

This is a **proposed improvement**.

The current project does not fully use this strategy.

---

# 38. DynamoDB Record-Size Risk

Some processed information also ends up in invoice records.

As:

```text
OCR-derived data
+
findings
+
analysis
```

grow, final records can become larger.

So large-document testing should examine both:

```text
Step Functions payload growth
```

and:

```text
DynamoDB item growth
```

Do not wait for a production failure to discover size problems.

---

# 39. Polling Cost

Frontend processing views poll status/detail APIs roughly every:

```text
3 seconds
```

Imagine:

```text
1 user
→ repeated requests
```

Now:

```text
1,000 users
→ many repeated requests
```

The Codex analysis specifically identifies polling as a scaling concern because every open processing view can generate repeated API requests. :chatgpt-content-reference{index="14"}

---

# 40. Polling Has Multiple Costs

Each polling cycle can involve:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
DynamoDB
```

Therefore repeated polling can increase:

```text
API requests
+
Lambda invocations
+
DynamoDB reads
+
network traffic
+
logs
```

---

# 41. Why Use Polling Anyway?

Because it is simple.

Architecture:

```text
Every 3 seconds:
"Is invoice ready?"
```

This is easier to implement than maintaining real-time connections.

So polling is not automatically a bad design.

The tradeoff is:

```text
Simple implementation
        vs
Repeated requests
```

---

# 42. Future Polling Optimization

Possible future approaches include:

```text
Exponential polling backoff

Longer polling intervals

WebSocket

Server-Sent Events

AWS AppSync subscriptions

Push-style notification
```

These are general/proposed alternatives.

They are **not current NovaMind AI architecture**.

---

# 43. Duplicate Processing = Hidden Cost

Recall:

```text
SQS
=
at-least-once delivery
```

So the same event can potentially be processed more than once.

If duplicate processing occurs:

```text
Same invoice
   ↓
Textract
   ↓
Bedrock
   ↓
Step Functions
```

again.

That means duplicate processing is not only a correctness problem.

It is also a:

```text
Cost problem
```

Codex explicitly lists duplicate processing as a project cost driver. :chatgpt-content-reference{index="15"}

---

# 44. Idempotency Can Reduce Waste

A stronger design would check:

```text
Have I already started/completed
processing this invoice?
```

before repeating expensive downstream work.

Conceptually:

```text
Event
 ↓
Atomic idempotency check
 ↓
Already processed?
 ├── YES → stop
 └── NO  → process
```

This improves:

```text
Correctness
+
Reliability
+
Cost efficiency
```

---

# 45. CloudWatch Cost

Observability also costs money.

Your project has:

```text
CloudWatch logs

API logging

Tracing configuration

DLQ alarm
```

:chatgpt-content-reference{index="16"}

More traffic can produce:

```text
More logs
```

and detailed logging of large payloads can increase both:

```text
Cost
+
data exposure risk
```

---

# 46. Logging Everything Is Not Always Better

A production system should balance:

```text
Enough logs to troubleshoot
```

against:

```text
Excessive logging
+
sensitive invoice data
+
cost
```

Recall from File 19 that some execution/logging paths can expose invoice-related data.

So logging strategy is simultaneously:

```text
Observability design

Security design

Cost design
```

---

# 47. CloudFront and Frontend Cost

Frontend:

```text
React build
 ↓
S3
 ↓
CloudFront
 ↓
Browser
```

CloudFront handles delivery of frontend assets.

Potential cost areas include:

```text
Requests
data transfer
cache invalidations
```

Codex includes frontend delivery and invalidations among the cost drivers. :chatgpt-content-reference{index="17"}

---

# 48. Direct S3 Upload Is a Good Scalability Decision

This is one of your architecture strengths.

Current flow:

```text
Browser
   │
   │ presigned URL
   ▼
S3
```

instead of:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

Why is this good?

Large binary transfer stays outside your application Lambda/API path.

Codex specifically identifies separating file transfer from API processing as an architectural strength. :chatgpt-content-reference{index="18"}

---

# 49. Cost per Invoice

A useful business metric is:

> **Cost per completed, fully analyzed invoice.**

Codex explicitly recommends measuring this. :chatgpt-content-reference{index="19"}

Conceptually:

```text
Total relevant AWS cost
───────────────────────
Number of successfully
fully analyzed invoices
```

Notice:

```text
fully analyzed
```

not simply:

```text
jobs marked COMPLETED
```

because Bedrock can fail while the business job still reaches a completed state.

---

# 50. Why “Cost per Completed Invoice” Needs Care

Suppose:

```text
1,000 invoices
```

are marked:

```text
COMPLETED
```

but:

```text
100
```

used AI fallback because Bedrock failed.

Then:

```text
COMPLETED count
```

does not necessarily mean:

```text
Fully analyzed count
```

So cost and quality metrics should be connected.

---

# 51. Can We Say This Project Costs $17–20 per Month?

No—not as a verified measured fact.

The repository README reportedly contains a monthly estimate around that range for a particular invoice volume.

But Codex explicitly states:

> **The README's monthly estimate is not a verified bill or current pricing calculation.** :chatgpt-content-reference{index="20"}

Therefore don't memorize:

> ❌ “My AWS cost is $17–20/month.”

---

# 52. Correct Interview Answer About Cost

Say:

> **“The README contains an illustrative cost estimate, but I don't present that as measured production cost. The actual cost depends on document volume and pages, Textract usage, Bedrock token consumption, retries, Lambda duration, workflow executions, DynamoDB operations, S3 storage, polling and observability. In production I would measure cost per fully analyzed invoice using actual AWS billing and workload data.”**

That's much stronger.

---

# 53. Never Invent Capacity

The repository does not establish:

```text
Maximum users

Maximum invoices/second

Maximum invoices/day

Maximum concurrent workflows

Production throughput
```

Codex explicitly says no capacity, throughput or user-count claim is established by the repository. :chatgpt-content-reference{index="21"}

So don't say:

> ❌ “It can handle one million users.”

---

# 54. Correct Scalability Language

Use:

> **“The architecture uses managed serverless services and asynchronous processing, so it has good scaling foundations. However, actual throughput has not been established through load testing, and downstream quotas such as Textract and Bedrock need to be considered.”**

This is accurate and professional.

---

# 55. What Is Throughput?

Throughput means:

> **How much work the system can process during a period of time.**

For example:

```text
Invoices / second

Invoices / minute

Invoices / hour
```

We do not currently have a verified throughput measurement for this project.

---

# 56. What Is Latency?

Latency means:

> **How long one operation takes.**

For NovaMind AI:

```text
Upload
 ↓
Processing
 ↓
Result available
```

The most useful user-facing metric is:

> **Upload-to-result latency.**

---

# 57. Important Current Timing Limitation

The project stores a processing timing value.

But Codex found that it sums:

```text
OCR time
+
AI time
+
partial storage interval
```

while excluding:

```text
Queue delay

Trigger time

Orchestration overhead

Risk-stage timing

Some later operations
```

Therefore:

> **The stored processing time is NOT end-to-end user latency.** :chatgpt-content-reference{index="22"}

This is an excellent interview detail.

---

# 58. Correct End-to-End Latency

Real user latency should conceptually measure:

```text
T0
User upload accepted
       ↓
S3
       ↓
SQS wait
       ↓
Trigger
       ↓
Step Functions
       ↓
Textract
       ↓
Bedrock
       ↓
Rules
       ↓
Storage
       ↓
Frontend observes completion
       ↓
T1
```

Then:

```text
End-to-End Latency
=
T1 - T0
```

---

# 59. Average Is Not Enough

Imagine five invoices:

```text
2 sec
2 sec
3 sec
3 sec
40 sec
```

Average hides the bad experience of the slow request.

Production systems often look at percentiles.

---

# 60. p50

p50 is approximately the median.

Conceptually:

> Half of requests are at or below this latency.

Example only:

```text
p50 = 4 seconds
```

means roughly half complete within 4 seconds.

This is **not a measured NovaMind AI number**.

---

# 61. p95

p95 means:

> About 95% of observed requests are at or below this latency.

This helps understand slower user experiences.

---

# 62. p99

p99 looks further into the slow tail.

Conceptually:

```text
Most requests are fast
but
a small percentage are very slow
```

p99 helps expose that tail.

Codex recommends measuring:

```text
Upload-to-result
p50 / p95 / p99
```

:chatgpt-content-reference{index="23"}

---

# 63. What Else Should We Measure?

The project analysis recommends:

```text
Upload-to-result p50/p95/p99

Queue age

Stage durations

OCR failure rate

Empty-extraction rate

AI availability

Schema-validity rate

Duplicate execution rate

Cost per fully analyzed invoice

DynamoDB capacity consumption by endpoint

Alert delivery success

Review-prioritization accuracy
```

:chatgpt-content-reference{index="24"}

These measurements connect:

```text
Performance
+
Reliability
+
AI quality
+
Cost
```

---

# 64. Queue Age

Suppose:

```text
Invoice uploaded
12:00:00
```

but SQS message starts processing:

```text
12:05:00
```

Queue age is already significant.

Even if:

```text
Textract + Bedrock
```

finish quickly afterward, the user waited.

Therefore:

```text
Stage execution time
≠
user-perceived latency
```

Queue age matters.

---

# 65. Stage-Level Timing

Measure separately:

```text
Queue Wait
     ↓
Trigger
     ↓
OCR
     ↓
AI
     ↓
Risk
     ↓
Storage
     ↓
UI Detection
```

Then if total latency becomes high, you can identify the slow stage.

Without stage metrics:

```text
"The app is slow"
```

is hard to diagnose.

---

# 66. Scaling Analytics Separately

Processing scalability and dashboard scalability are different.

### Invoice processing

```text
S3
→ SQS
→ Workflow
→ Textract
→ Bedrock
```

### Analytics

```text
Browser
→ API
→ DynamoDB
→ Python aggregation
```

A system can have excellent invoice processing and still have slow analytics.

---

# 67. Performance vs Cost Tradeoff

Many architecture decisions involve tradeoffs.

Example:

```text
Poll every 1 second
```

may reduce perceived update delay.

But increases:

```text
API calls
Lambda invocations
DynamoDB reads
```

Whereas:

```text
Poll every 10 seconds
```

reduces requests but can make the UI feel slower.

So:

```text
Performance
↔
Cost
```

often requires balance.

---

# 68. Reliability vs Cost Tradeoff

Retries improve resilience.

But:

```text
More retries
      ↓
More execution
      ↓
More service requests
      ↓
Potentially more cost
```

The solution is not:

> “Never retry.”

It is:

> **Use bounded, intelligent retries for transient failures.**

---

# 69. Scalability vs Cost Tradeoff

Higher concurrency may improve throughput:

```text
More concurrent processing
      ↓
Higher throughput
```

but can produce:

```text
More downstream pressure
+
more throttling
+
higher short-term spend
```

So concurrency should be quota-aware.

---

# 70. Performance Optimization Rule

Do not optimize blindly.

Use:

```text
Measure
   ↓
Find bottleneck
   ↓
Optimize
   ↓
Measure again
```

Not:

```text
Guess
 ↓
Change architecture
 ↓
Hope
```

---

# 71. Example Performance Investigation

Suppose users say:

> “Invoices take too long.”

Do not immediately blame Bedrock.

Investigate:

```text
Upload time
    ↓
SQS queue age
    ↓
Trigger latency
    ↓
Workflow start
    ↓
Textract duration
    ↓
Bedrock duration
    ↓
Retry waits
    ↓
Risk processing
    ↓
DynamoDB storage
    ↓
Frontend polling delay
```

The bottleneck could be anywhere.

---

# 72. Example Scaling Failure

Imagine traffic suddenly becomes 10× higher.

Possible sequence:

```text
More uploads
    ↓
More SQS messages
    ↓
More workflows launched
    ↓
More Bedrock calls
    ↓
Bedrock throttling
    ↓
Retries
    ↓
Longer Lambda duration
    ↓
More latency
    ↓
Potential timeout
```

Notice the feedback effect:

```text
Throttling
→ retries
→ longer processing
→ more resource usage
```

---

# 73. What Would I Check at 10× Traffic?

Use this order:

```text
1. SQS queue depth / age

2. Trigger Lambda errors/concurrency

3. Step Functions execution behavior

4. Textract throttling/errors

5. Bedrock throttling/errors

6. Bedrock retry rate

7. Lambda duration/timeouts

8. DynamoDB latency/capacity consumption

9. API latency

10. Frontend polling volume

11. Analytics latency

12. Cost per successful invoice
```

This is much stronger than:

> “AWS automatically scales everything.”

---

# 74. Load Testing

Before making production-scale claims:

```text
Generate controlled workload
        ↓
Observe architecture
        ↓
Measure
```

Examples:

```text
Low load
 ↓
Medium load
 ↓
High load
 ↓
Burst load
```

Track:

```text
Throughput

Latency

Error rate

Throttle rate

Queue age

Concurrency

Cost
```

The repository analysis found no load tests. :chatgpt-content-reference{index="25"}

---

# 75. Burst Testing

Invoice systems may experience bursts.

Example:

```text
Normal:
10 invoices/minute

Month-end:
large burst
```

SQS is valuable because:

```text
Burst
 ↓
Queue
 ↓
Asynchronous processing
```

But again:

> **The consumer side still needs controlled downstream concurrency.**

---

# 76. Scalability Improvement Plan

A future production version could consider:

```text
1. Establish real service quotas

2. Add load testing

3. Measure end-to-end latency

4. Add quota-aware concurrency controls

5. Strengthen idempotency

6. Improve Bedrock rate limiting

7. Add token/input-size management

8. Move large intermediate artifacts to S3

9. Carry references through workflows

10. Test DynamoDB high-volume tenant patterns

11. Pre-aggregate analytics

12. Reduce unnecessary polling

13. Add lifecycle policies

14. Tune log retention/verbosity

15. Track cost per fully analyzed invoice
```

These are proposed improvements.

---

# 77. Cost Optimization by Architecture Layer

Think layer by layer.

### Upload

Current strength:

```text
Browser → S3 directly
```

Avoid unnecessary Lambda/API file transfer.

### Processing

Improve:

```text
Idempotency
+
controlled concurrency
+
bounded retries
```

### AI

Improve:

```text
Prompt size management
+
avoid unnecessary retries
+
measure tokens
```

### Storage

Improve:

```text
Lifecycle policies
+
appropriate artifact strategy
```

### Analytics

Improve:

```text
Pre-aggregation
```

### Frontend

Improve:

```text
Smarter polling
or push updates
```

### Observability

Improve:

```text
Useful logs
without excessive sensitive payload logging
```

---

# 78. Current Architecture Strengths for Scale

You can confidently discuss several design strengths.

### Direct S3 upload

```text
Browser → S3
```

keeps document transfer away from application Lambda handlers. :chatgpt-content-reference{index="26"}

### SQS decoupling

```text
Upload events
→ Queue
→ processing
```

provides buffering.

### Serverless compute

Lambda removes server-management overhead.

### Managed workflow

Step Functions separates processing stages.

### DynamoDB

Provides managed NoSQL persistence with tenant-oriented access patterns.

### Independent stages

OCR, AI, rules and storage can be investigated separately. :chatgpt-content-reference{index="27"}

---

# 79. Current Scalability Limitations

The most important ones to remember:

```text
⚠ No verified load testing

⚠ No measured throughput

⚠ Downstream Textract/Bedrock quotas

⚠ SQS bridge does not globally throttle workflows

⚠ Bedrock rate limiter is per Lambda environment

⚠ Rate limiter has rolling-window weakness

⚠ Lambda waiting can contribute to timeout risk

⚠ Analytics repeatedly retrieves tenant invoices

⚠ High-volume tenant partition behavior untested

⚠ Workflow payload grows with OCR/AI data

⚠ No large-artifact pointer strategy

⚠ Final-record size can grow

⚠ Frontend polling creates repeated API traffic

⚠ Duplicate processing can waste expensive work
```

These align with the repository's identified scaling concerns. :chatgpt-content-reference{index="28"} :chatgpt-content-reference{index="29"}

---

# 80. Current Cost Limitations

Do not claim:

```text
Exact monthly production bill

Exact cost per invoice

Exact Bedrock cost

Exact Textract cost

Exact cost at 10× traffic
```

The project does not provide verified measurements for those.

Instead explain the cost model and what you would measure.

---

# 81. Interview Question 1 — What Are the Main Cost Drivers?

**Difficulty: Basic**

### Word-by-word answer

> “The main cost drivers are Textract document processing, Bedrock input and output tokens, Lambda execution duration, Step Functions executions, DynamoDB reads and writes, S3 storage and requests, frontend API polling, CloudWatch logging and frontend delivery. Duplicate processing is also important because the same invoice could consume expensive OCR and AI resources more than once. I would measure cost per fully analyzed invoice rather than relying only on a monthly estimate.” :chatgpt-content-reference{index="30"}

---

# 82. Interview Question 2 — How Does Your Application Scale?

**Difficulty: Basic**

### Word-by-word answer

> “The project uses a serverless and event-driven architecture. The browser uploads invoices directly to S3, SQS buffers upload events, Lambda handles compute, Step Functions orchestrates processing, and DynamoDB provides managed persistence. These services give the architecture good scaling foundations, but I would not call it unlimited scalability because actual throughput depends on service quotas, downstream Textract and Bedrock capacity, concurrency, payload sizes and access patterns.”

---

# 83. Interview Question 3 — Why Did You Use SQS?

**Difficulty: Intermediate**

### Word-by-word answer

> “SQS decouples invoice arrival from background processing and provides buffering during bursts. However, I would not say that SQS alone protects Textract and Bedrock from overload. In the current architecture the trigger Lambda starts Step Functions workflows quickly, so downstream workflow concurrency can still grow. For production scale I would combine queueing with quota-aware concurrency and backpressure controls.” :chatgpt-content-reference{index="31"}

---

# 84. Interview Question 4 — What Happens at 10× Traffic?

**Difficulty: Intermediate**

### Word-by-word answer

> “I would not assume that every service scales equally. More uploads create more SQS messages and potentially more Step Functions executions, which increase Textract and Bedrock traffic. The first constraints could come from downstream service quotas, throttling, Lambda concurrency, payload growth or data-access patterns. I would monitor queue age, workflow executions, throttling, Lambda duration, API latency and cost, then control concurrency based on measured quotas. The repository has not established a tested 10× capacity, so I would validate it with load testing rather than invent a throughput number.”

---

# 85. Interview Question 5 — Does SQS Prevent Bedrock Throttling?

**Difficulty: Intermediate / Pressure**

### Word-by-word answer

> “Not by itself. SQS buffers incoming events, but the current bridge starts Step Functions workflows asynchronously and returns. That means many workflows can still become active and invoke Bedrock. Queueing and throttling are different concepts. For stronger protection I would introduce quota-aware concurrency or another shared rate-control mechanism around the downstream processing path.” :chatgpt-content-reference{index="32"}

---

# 86. Interview Question 6 — What Is Wrong With the Current Bedrock Rate Limiter?

**Difficulty: Advanced**

### Word-by-word answer

> “The current rate limiter is local to one warm Lambda execution environment, so concurrent Lambda instances do not share a global request budget. Increasing Lambda concurrency can therefore increase aggregate Bedrock request rate even though each instance believes it is limiting requests. The implementation also has a timestamp behavior that weakens the intended rolling-window logic, and waiting inside a Lambda with a 60-second timeout can itself create timeout risk.” :chatgpt-content-reference{index="33"}

---

# 87. Interview Question 7 — What Is a Scaling Concern in DynamoDB?

**Difficulty: Advanced**

### Word-by-word answer

> “The invoice table uses `tenant_id` as the partition key and `invoice_id` as the sort key, so all invoices for one user share the same partition-key value. That is a natural access pattern for tenant-scoped queries, but high-volume tenants should be workload-tested rather than assuming unlimited performance. Another concern is that analytics endpoints repeatedly retrieve a tenant's invoice collection and aggregate it in application code, so read cost and latency can grow as invoice history increases.” :chatgpt-content-reference{index="34"} :chatgpt-content-reference{index="35"}

---

# 88. Interview Question 8 — What Is the Step Functions Payload Concern?

**Difficulty: Advanced**

### Word-by-word answer

> “The workflow carries a growing JSON payload containing identifiers, OCR data, AI output and risk findings. The current implementation does not use a general artifact-pointer strategy for large intermediate results, so larger documents can increase workflow-payload and final-record size risk. For a production version I would store large intermediate artifacts in S3 and pass compact references through the workflow instead of carrying large content between every state.” :chatgpt-content-reference{index="36"}

---

# 89. Interview Question 9 — How Would You Measure Performance?

**Difficulty: Advanced**

### Word-by-word answer

> “I would measure end-to-end upload-to-result latency using p50, p95 and p99 rather than relying only on an average. I would also measure queue age and individual stage durations for OCR, AI, rules and storage so I could identify the bottleneck. The current stored processing time is not true end-to-end latency because it excludes queue delay, trigger time, orchestration overhead, risk-stage timing and some later operations.” :chatgpt-content-reference{index="37"}

---

# 90. Interview Question 10 — How Would You Optimize Cost and Scale for Production?

**Difficulty: Advanced / System Design**

### Word-by-word answer

> “I would first measure real workload behavior instead of optimizing from assumptions. I would load-test the system, identify downstream quotas and measure end-to-end latency and cost per fully analyzed invoice. Then I would strengthen idempotency to avoid duplicate OCR and AI work, add quota-aware processing concurrency, replace the per-instance Bedrock limiter with coordinated rate control, manage prompt and payload sizes, move large intermediate artifacts to S3, pre-aggregate analytics, optimize frontend polling and apply appropriate storage and logging lifecycle policies. I would measure again after every major optimization.”

---

# 91. Interview Pressure Chain

If the interviewer asks:

> **“Is your architecture scalable?”**

expect:

```text
Why?
 ↓
What does serverless mean?
 ↓
Does serverless mean unlimited?
 ↓
Why SQS?
 ↓
What is buffering?
 ↓
What is backpressure?
 ↓
Does SQS throttle Bedrock?
 ↓
What happens at 10× traffic?
 ↓
What is Lambda concurrency?
 ↓
What if Lambda scales faster than Bedrock?
 ↓
What is your Bedrock rate limiter?
 ↓
Does it work across Lambda instances?
 ↓
What are your main cost drivers?
 ↓
What happens when retries increase?
 ↓
How can duplicates affect cost?
 ↓
How does DynamoDB scale?
 ↓
What about a very large tenant?
 ↓
How does analytics scale?
 ↓
Why can polling become expensive?
 ↓
What is the workflow payload problem?
 ↓
How would you handle large OCR data?
 ↓
What is throughput?
 ↓
What is latency?
 ↓
What are p50/p95/p99?
 ↓
What is your actual throughput?
 ↓
What is your actual monthly cost?
 ↓
How would you measure both?
```

---

# 92. The Most Dangerous Interview Answers

Do not say:

> ❌ “AWS automatically scales everything.”

Say:

> **“AWS manages much of the infrastructure scaling, but I still have to design for downstream quotas, concurrency, payload sizes, retries and access patterns.”**

Do not say:

> ❌ “SQS prevents Bedrock throttling.”

Say:

> **“SQS buffers events, but downstream concurrency still requires control.”**

Do not say:

> ❌ “My project costs $17–20 per month.”

Say:

> **“The README has an estimate, but it isn't a verified production bill.”** :chatgpt-content-reference{index="38"}

Do not say:

> ❌ “My architecture supports one million users.”

Say:

> **“No production capacity has been established through load testing.”** :chatgpt-content-reference{index="39"}

Do not say:

> ❌ “My processing-time field is end-to-end latency.”

Say:

> **“It measures only part of the pipeline and excludes several stages.”** :chatgpt-content-reference{index="40"}

---

# 93. 30-Second Interview Answer

> “NovaMind AI has good serverless scaling foundations because invoices upload directly to S3, SQS buffers events, Lambda provides managed compute, Step Functions orchestrates asynchronous processing and DynamoDB provides managed persistence. However, I don't claim unlimited scale because Textract and Bedrock quotas, concurrency, analytics access patterns, frontend polling and workflow payload growth can become constraints. I would load-test the system and measure upload-to-result p50, p95 and p99 latency, queue age, throttling, stage durations and cost per fully analyzed invoice. For production I would add quota-aware concurrency, stronger idempotency, coordinated Bedrock rate control, artifact pointers for large payloads and pre-aggregated analytics.” :chatgpt-content-reference{index="41"}

---

# 94. One-Minute Interview Answer

> “From a scalability perspective, I designed the processing path asynchronously. The browser uploads directly to S3 using a presigned URL, so large invoice files don't pass through the application Lambda layer. S3 events go through SQS, which provides buffering, and a Lambda starts a Step Functions Express workflow for Textract OCR, Bedrock Nova Micro analysis, deterministic risk rules and storage.
>
> The important limitation is that serverless does not mean unlimited. SQS buffers events, but the current trigger starts workflows quickly, so it does not globally control active Textract or Bedrock operations. The current Bedrock limiter is also local to each Lambda environment, so concurrent instances do not share one request budget.
>
> I would therefore load-test the architecture, measure downstream throttling, queue age, end-to-end p50, p95 and p99 latency and cost per fully analyzed invoice. For higher scale I would introduce quota-aware concurrency, stronger idempotency, better large-payload handling, pre-aggregated analytics and more efficient frontend update behavior.” :chatgpt-content-reference{index="42"} :chatgpt-content-reference{index="43"}

---

# 95. Cost Mental Model

Remember this:

```text
                ONE INVOICE
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
      OCR            AI       COMPUTE
    Textract       Bedrock       Lambda
        │            │            │
        └────────────┼────────────┘
                     ▼
                ORCHESTRATION
                Step Functions
                     │
                     ▼
                   DATA
              S3 + DynamoDB
                     │
                     ▼
                  ACCESS
             API + Polling
                     │
                     ▼
              OBSERVABILITY
                CloudWatch
```

Then ask:

> **“What happens to each cost when invoice volume increases?”**

---

# 96. Scalability Mental Model

```text
                    MORE USERS
                        ↓
                   MORE UPLOADS
                        ↓
                       SQS
                        ↓
                 MORE WORKFLOWS
                        ↓
             ┌──────────┴──────────┐
             ▼                     ▼
          Textract              Bedrock
             │                     │
             └──────────┬──────────┘
                        ▼
                   DynamoDB
                        ↓
                      APIs
                        ↓
                    Polling
```

At every arrow ask:

```text
Can this scale?

What quota exists?

What happens on throttling?

What does retry do?

What does it cost?

How do I measure it?
```

---

# 97. Five Things You Must Remember

### 1. Serverless ≠ unlimited.

Managed scaling still has quotas and architectural constraints.

### 2. SQS buffers; it does not automatically globally throttle Bedrock.

This distinction is essential. :chatgpt-content-reference{index="44"}

### 3. Current Bedrock rate limiting is local to each Lambda environment.

It is not a coordinated global limiter. :chatgpt-content-reference{index="45"}

### 4. Large OCR/AI data currently moves through workflow state.

There is no general artifact-pointer strategy, creating payload and record-size risk. :chatgpt-content-reference{index="46"}

### 5. Do not invent cost or capacity numbers.

The repository establishes neither actual production cost nor tested throughput/user capacity. :chatgpt-content-reference{index="47"}

---

# 98. Best Sentence to Remember

> **“My architecture has serverless and asynchronous scaling foundations, but I separate architectural scalability from proven capacity. I would validate actual capacity through load testing and measure downstream quotas, end-to-end latency, throttling, queue age and cost per fully analyzed invoice.”**

That is a strong AWS engineering answer because you are not saying:

```text
AWS = infinite scale
```

You are saying:

```text
Architecture
+
measurement
+
quotas
+
backpressure
+
cost awareness
=
production scalability
```

---

# 99. Check Your Understanding

Before moving to File 23, answer these without reading above.

### Question 1

Suppose:

```text
10,000 invoices
arrive suddenly
```

Explain why:

```text
S3 → SQS
```

helps, but why SQS alone does **not** guarantee Bedrock will avoid throttling.

### Question 2

Suppose Lambda scales from:

```text
1 instance
```

to:

```text
20 concurrent instances
```

Why can the current local Bedrock rate limiter become unreliable as a **global** rate limiter?

### Question 3

Explain why this architecture:

```text
Step Functions state
    ↓
OCR text
+
AI output
+
risk findings
```

can become a problem for large invoices.

What would an:

```text
S3 artifact-pointer design
```

change?

### Question 4

An interviewer asks:

> **“How much does your application cost per month?”**

Why should you **not** simply answer:

> “$17–20 per month”?

What would you measure instead?

---

# Next File

**`23-Limitations-Production-V2-and-Design-Decisions.md`**

That file is one of the most important files in the entire project because we will bring together everything we have discovered:

```text
Security gaps
+
Job-status isolation
+
Browser cache isolation
+
Idempotency
+
SQS/DLQ boundary
+
Textract limitations
+
AI validation
+
AI failure semantics
+
Risk-score limitations
+
Double counting
+
DynamoDB TTL issue
+
Workflow payload growth
+
Frontend refresh problem
+
Notification wiring
+
CI/CD reproducibility
+
Testing gaps
+
Cost/scaling limitations
        ↓
Production V2 Architecture
        ↓
Design Decisions
        ↓
"What would you improve?"
Interview Answers
```

That will prepare you for one of the hardest interview questions:

> **“If you had another month to make this project production-ready, what exactly would you change, and why?”**