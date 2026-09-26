# Your question

**Start `07-SQS-DLQ-Retries-and-Idempotency.md`.**

This file begins exactly where File 06 ended:

> **The invoice has reached S3. S3 sends an event to SQS. What happens if processing is delayed, fails, retries, or the same message is delivered more than once?**

The most important concept in this file is:

> **SQS helps make the pipeline reliable, but SQS does not guarantee that a message will be processed only once. Therefore, the application must be designed for duplicate delivery.**

---

# 07 — SQS, DLQ, Retries and Idempotency

## 1. What Will I Learn?

In this file, I will understand:

- Why SQS exists in this project
- What decoupling means
- What an SQS message represents
- How S3 events reach SQS
- How the trigger Lambda consumes messages
- What happens when many invoices arrive together
- What SQS visibility timeout means
- How retries work
- What a Dead-Letter Queue (DLQ) is
- Why SQS provides at-least-once delivery
- Why duplicate messages are possible
- What idempotency means
- Why duplicate workflow execution is dangerous
- The current idempotency weakness
- How I would improve the design
- How to troubleshoot SQS failures
- How to answer SQS/idempotency interview questions

---

# 2. Where Are We in the Architecture?

File 06 ended here:

```text
Browser
   ↓
Amazon S3
   ↓
ObjectCreated Event
   ↓
Amazon SQS
```

File 07 focuses here:

```text
                    ┌───────────────┐
S3 ObjectCreated ──→│      SQS      │
                    │ Invoice Queue │
                    └───────┬───────┘
                            │
                            ▼
                    Trigger Lambda
                            │
                            ▼
                     Step Functions
```

But we also need to understand the failure path:

```text
SQS
 │
 │ Processing fails
 ▼
Retry
 │
 ▼
Retry again
 │
 ▼
Maximum receives exceeded
 │
 ▼
DLQ
```

---

# 3. Why Do We Need SQS?

Imagine we removed SQS:

```text
S3
 ↓
Lambda
 ↓
Step Functions
```

This is possible architecturally.

But this project places a queue between ingestion and workflow startup:

```text
S3
 ↓
SQS
 ↓
Trigger Lambda
 ↓
Step Functions
```

Why?

Because SQS provides a **buffer** between:

```text
Invoice arrives
```

and:

```text
Invoice processing begins
```

This is called **decoupling**.

---

# 4. What Does Decoupling Mean?

Very simple example:

Imagine a restaurant.

Without a waiting area:

```text
Customer
 ↓
Chef
```

If 50 customers arrive together, the chef immediately receives 50 requests.

With an order queue:

```text
Customers
 ↓
Order Queue
 ↓
Kitchen
```

The customers can place orders while the kitchen processes them according to available capacity.

Your project follows a similar principle:

```text
Invoice uploads
      ↓
     SQS
      ↓
Processing consumers
```

---

# 5. Burst Example

Suppose:

```text
09:00:00 → Invoice 1 uploaded
09:00:01 → Invoice 2 uploaded
09:00:01 → Invoice 3 uploaded
09:00:02 → Invoice 4 uploaded
09:00:02 → Invoice 5 uploaded
```

SQS can temporarily hold:

```text
┌─────────────────────┐
│ Invoice 1 Event     │
├─────────────────────┤
│ Invoice 2 Event     │
├─────────────────────┤
│ Invoice 3 Event     │
├─────────────────────┤
│ Invoice 4 Event     │
├─────────────────────┤
│ Invoice 5 Event     │
└─────────────────────┘
```

Then the Lambda consumer processes available messages.

So:

> **Upload speed does not have to exactly equal processing speed.**

---

# 6. What Does the SQS Message Contain?

The queue isn't storing the entire invoice PDF.

The actual invoice is already in:

```text
Amazon S3
```

The queue contains an event/message that identifies the uploaded S3 object.

Conceptually:

```text
SQS Message

{
    S3 bucket information,
    S3 object key,
    event information
}
```

The important distinction is:

```text
S3
=
stores invoice file
```

while:

```text
SQS
=
stores processing message
```

---

# 7. S3 Event Is Nested Inside the Message

The trigger Lambda receives the queue event and needs to understand which S3 object caused it.

Conceptually:

```text
Lambda Event
   ↓
SQS Record
   ↓
Message Body
   ↓
S3 Event
   ↓
Bucket + Object Key
```

The Codex analysis traced the queue bridge as reading the nested S3 event and extracting tenant/invoice information from the object key. :chatgpt-content-reference{index="0"}

This is why understanding the object-key structure from File 06 matters.

---

# 8. Extract Tenant and Invoice Information

Recall that the uploaded object uses a tenant-aware key.

Conceptually:

```text
S3 Object Key
      ↓
Tenant information
      +
Invoice information
```

The queue bridge can use this information to determine:

```text
Which tenant?

Which invoice?

Which S3 object?
```

Then it can start the correct processing workflow.

---

# 9. Trigger Lambda

The SQS queue invokes the trigger/bridge Lambda.

```text
SQS
 ↓
Trigger Lambda
```

Its main responsibility is not OCR.

It is not the Bedrock Lambda.

It is not the risk-scoring Lambda.

Think:

> **Its job is to bridge the ingestion event into the processing workflow.**

Conceptually:

```text
Receive SQS message
        ↓
Parse nested S3 event
        ↓
Extract invoice information
        ↓
Prepare workflow input
        ↓
Start Step Functions
```

---

# 10. SQS Is Event-Driven

The Lambda does not need to repeatedly ask:

```text
SQS:

"Any message?"

"Any message?"

"Any message?"
```

The Lambda event-source integration handles message consumption.

Conceptually:

```text
Message available
       ↓
SQS/Lambda integration
       ↓
Invoke Lambda
```

Therefore this part of the architecture is **event-driven**.

---

# 11. Successful Message Processing

The normal path looks like:

```text
SQS Message
     ↓
Trigger Lambda
     ↓
Parse event
     ↓
Start workflow successfully
     ↓
Lambda succeeds
     ↓
Message removed
```

At a simplified level:

> If processing succeeds, the message no longer needs to remain in the queue.

---

# 12. What If Lambda Fails?

Now suppose:

```text
SQS
 ↓
Trigger Lambda
 ↓
ERROR
```

The message should not simply disappear.

SQS/Lambda retry behavior allows it to become available for another processing attempt.

Conceptually:

```text
Message
   ↓
Lambda attempt
   ↓
FAIL
   ↓
Message becomes available again
   ↓
Retry
```

This improves reliability.

---

# 13. Visibility Timeout

This introduces an important SQS concept:

## Visibility Timeout

When a consumer receives a message, SQS temporarily hides it from other consumers.

Think:

```text
Message available
       ↓
Lambda receives it
       ↓
Message becomes invisible
       ↓
Lambda processes it
```

If processing succeeds, the message can be removed.

If processing does not complete successfully:

```text
Visibility timeout expires
       ↓
Message becomes visible again
       ↓
Can be retried
```

---

# 14. Simple Visibility Timeout Example

Imagine:

```text
10:00:00
Message received

10:00:00 → 10:01:00
Message temporarily hidden
```

If processing succeeds:

```text
SUCCESS
 ↓
Message removed
```

If processing fails:

```text
FAIL
 ↓
Visibility timeout expires
 ↓
Message appears again
```

The exact configured timeout should always come from the project's infrastructure configuration; do not invent a number during an interview.

---

# 15. Why Do Retries Matter?

Distributed systems experience temporary failures.

For example:

```text
Temporary Lambda failure

Temporary AWS API error

Network/service issue

Throttling

Unexpected exception
```

A temporary problem shouldn't necessarily cause the invoice to be permanently lost.

Retries give the system another chance.

---

# 16. But Infinite Retries Are Bad

Suppose a message is permanently invalid.

```text
Message
 ↓
Fail
 ↓
Retry
 ↓
Fail
 ↓
Retry
 ↓
Fail
 ↓
Retry
 ↓
...
```

That message could continuously consume resources.

This is where the **Dead-Letter Queue** becomes important.

---

# 17. What Is a DLQ?

DLQ means:

> **Dead-Letter Queue**

A DLQ stores messages that repeatedly fail processing.

Conceptually:

```text
Main SQS Queue
      ↓
Attempt 1
      ↓
FAIL
      ↓
Attempt 2
      ↓
FAIL
      ↓
Attempt 3
      ↓
FAIL
      ↓
DLQ
```

The exact number of allowed receives must come from the project's configured redrive policy.

Don't memorize the illustrative `3` above as your project's value.

---

# 18. Why Is a DLQ Useful?

Without a DLQ:

```text
Bad message
 ↓
Retry forever
```

With a DLQ:

```text
Bad message
 ↓
Retries exhausted
 ↓
DLQ
 ↓
Investigate
```

The failed message is isolated instead of repeatedly interfering with the normal queue.

---

# 19. What Should We Do With DLQ Messages?

A DLQ isn't:

> **a magic automatic repair system.**

It gives operators somewhere to inspect failed messages.

A production workflow could include:

```text
DLQ receives message
       ↓
CloudWatch alarm
       ↓
Engineer investigates
       ↓
Identify root cause
       ↓
Fix underlying problem
       ↓
Safely redrive/reprocess
```

This is part of operational maturity.

---

# 20. Main Queue vs DLQ

Remember:

```text
MAIN QUEUE
=
work waiting for normal processing
```

```text
DLQ
=
messages that exceeded normal retry handling
```

A DLQ does not replace the main queue.

It is a failure destination.

---

# 21. Now the Hard Part — Duplicate Delivery

Many beginners think:

```text
One SQS message
=
Lambda executes exactly once
```

That is unsafe.

The safer model is:

> **Standard SQS provides at-least-once delivery.**

That means:

```text
A message will normally be delivered at least once

BUT

it can potentially be delivered more than once
```

---

# 22. What Does At-Least-Once Mean?

Suppose we have:

```text
Invoice A
```

The normal case:

```text
Message A
 ↓
Lambda
 ↓
Process A
```

But a possible case is:

```text
Message A
 ↓
Lambda

and later

Message A
 ↓
Lambda again
```

Therefore your application should be prepared for:

```text
duplicate delivery
```

---

# 23. Why Can Duplicates Happen?

One simple distributed-systems scenario:

```text
Lambda performs important action
       ↓
Action succeeds
       ↓
But acknowledgement/completion fails
       ↓
Message becomes available again
       ↓
Lambda receives it again
```

From the application's perspective:

```text
The first action may already have happened.
```

That is why retries and duplicate delivery are related.

---

# 24. Why Is Duplicate Processing Dangerous Here?

Suppose the first delivery starts:

```text
Step Functions Execution A
```

Then the message is delivered again.

The second delivery could start:

```text
Step Functions Execution B
```

Now the same invoice may have:

```text
Invoice
 ├── Workflow A
 └── Workflow B
```

Both could potentially perform:

```text
Textract
Bedrock
Risk calculation
Writes
```

This creates several problems.

---

# 25. Problem 1 — Duplicate Cost

If the same invoice runs twice:

```text
Textract call × 2

Bedrock call × 2

Lambda execution × 2
```

That can increase unnecessary cost.

---

# 26. Problem 2 — Duplicate Side Effects

Suppose processing eventually publishes:

```text
HIGH RISK event
```

Duplicate processing could potentially lead to:

```text
Event 1
Event 2
```

and eventually:

```text
Notification 1
Notification 2
```

if downstream components don't also protect against duplicates.

---

# 27. Problem 3 — Incorrect State

Imagine:

```text
Workflow A
 ↓
PROCESSING
```

then:

```text
Workflow B
 ↓
PROCESSING
```

then:

```text
Workflow A
 ↓
COMPLETED
```

while:

```text
Workflow B
 ↓
FAILS
```

Now:

> What should the final business status be?

Duplicate execution can make state management more complicated.

---

# 28. What Is Idempotency?

This is one of the most important words in this project.

## Idempotency

In simple English:

> **Performing the same logical operation multiple times should not create incorrect additional effects.**

Example:

```text
Process Invoice A
```

first time:

```text
Start processing
```

second duplicate attempt:

```text
Recognize:
"Invoice A is already being processed."

Do not start another workflow.
```

---

# 29. Real-World Idempotency Example

Imagine paying ₹1,000.

You click:

```text
PAY
```

The browser freezes.

So you click again.

A badly designed system:

```text
₹1,000 charged
+
₹1,000 charged again
```

An idempotent payment operation tries to recognize:

```text
Same logical payment request
```

and avoid creating a second charge.

Invoice processing has a similar concept.

---

# 30. Idempotency in This Project

The natural identifier available to us is:

```text
invoice_id
```

and potentially its corresponding:

```text
job_<invoice_id>
```

Conceptually, an idempotency design could ask:

```text
Message received
       ↓
Which invoice?
       ↓
Has processing already started?
       ↓
 ┌─────┴─────┐
YES           NO
 ↓             ↓
Don't start   Atomically claim
duplicate     processing
workflow      and start workflow
```

But simply checking first is not always enough.

---

# 31. The Check-Then-Act Race Condition

Suppose two duplicate deliveries happen almost simultaneously.

```text
Lambda A                     Lambda B
   │                            │
   ▼                            ▼
Check job                    Check job
   │                            │
Not started                  Not started
   │                            │
   ▼                            ▼
Start workflow              Start workflow
```

Both checked before either updated the state.

Result:

```text
Duplicate workflows
```

This is called a:

> **race condition**

---

# 32. Stronger Pattern — Atomic Claim

A stronger design uses an atomic/conditional state transition.

Conceptually:

```text
job status = PENDING
       ↓
Try:

PENDING → PROCESSING
```

Only one consumer should successfully perform that transition.

For example:

```text
Lambda A

PENDING → PROCESSING
SUCCESS
```

then:

```text
Lambda B

PENDING → PROCESSING
FAIL

because current status
is already PROCESSING
```

Therefore:

```text
Only Lambda A
starts the workflow
```

This is an example of using data-store semantics to enforce idempotency.

---

# 33. Why DynamoDB Can Help

DynamoDB supports conditional operations.

Conceptually:

```text
Update job

SET status = PROCESSING

ONLY IF

status = PENDING
```

This allows the database to make the decision atomically.

Instead of:

```text
Read
 ↓
Decide in Lambda
 ↓
Write
```

we can ask DynamoDB to enforce:

```text
Update only when condition is true
```

That is much safer under concurrency.

---

# 34. Current Project Limitation

The Codex analysis identified duplicate-processing/job-reset behavior as an area requiring improvement and explicitly warns against claiming exactly-once processing. :chatgpt-content-reference{index="1"}

Therefore you should **not** say:

> “SQS guarantees every invoice is processed exactly once.”

And you should not say:

> “My application already has perfect idempotency.”

The accurate position is:

> **The queue provides reliable asynchronous delivery, but because duplicate delivery is possible, stronger idempotency around workflow startup is an important production improvement.**

---

# 35. Retry Is Not the Same as Idempotency

This distinction is interview-important.

## Retry

Means:

> **Try the operation again after failure.**

```text
Attempt
 ↓
Fail
 ↓
Retry
```

## Idempotency

Means:

> **If the operation is repeated, don't create incorrect duplicate effects.**

```text
Attempt
 ↓
Maybe succeeded
 ↓
Repeated attempt
 ↓
Recognize duplicate
```

You often need **both**.

---

# 36. DLQ Is Not the Same as Idempotency

Also don't confuse:

```text
DLQ
```

with:

```text
Idempotency
```

DLQ solves:

> What do we do with a message that repeatedly fails?

Idempotency solves:

> What do we do if the same logical work is attempted more than once?

Different problems.

---

# 37. Retry + DLQ + Idempotency

Together they form a stronger reliability model:

```text
                   Message
                      ↓
                   Process
                      ↓
             ┌────────┴────────┐
          SUCCESS            FAILURE
             │                  │
             ▼                  ▼
          Finish              Retry
                                │
                         Too many failures?
                           ┌────┴────┐
                          NO        YES
                          │          │
                        Retry       DLQ


Idempotency protects the entire process
against duplicate attempts.
```

Remember:

```text
Retry
=
recover from temporary failure

DLQ
=
isolate repeated failure

Idempotency
=
protect against duplicate effects
```

---

# 38. What About Step Functions Retries?

There are different retry boundaries in this architecture.

For example:

```text
SQS/Lambda boundary
```

can retry message consumption.

Inside the workflow:

```text
Step Functions
```

can also have retry/error behavior for individual processing states.

Therefore:

```text
SQS Retry
≠
Step Functions State Retry
```

They occur at different layers.

We'll study workflow-specific behavior in the next file.

---

# 39. Troubleshooting Scenario

Suppose:

> **An invoice exists in S3, but processing never completes.**

Start at the boundary:

```text
1. Is the S3 object present?
        ↓
2. Did the event reach SQS?
        ↓
3. Is the message still visible/in-flight?
        ↓
4. Is the queue depth increasing?
        ↓
5. Did trigger Lambda run?
        ↓
6. Did Lambda throw an exception?
        ↓
7. Was Step Functions started?
        ↓
8. Did the message move to the DLQ?
```

Don't immediately inspect Bedrock.

You first need to determine whether processing ever reached Bedrock.

---

# 40. Troubleshooting Scenario — Queue Growing

Suppose CloudWatch shows:

```text
Queue depth:

10
20
50
100
300
```

Possible questions:

```text
Are messages arriving faster
than they are processed?

Is Lambda failing?

Is Lambda throttled?

Is downstream workflow startup failing?

Is concurrency constrained?

Are messages repeatedly becoming visible?
```

This is called **backlog**.

Queue backlog is an important operational signal.

---

# 41. Troubleshooting Scenario — DLQ Has Messages

Suppose:

```text
Main Queue
 ↓
DLQ = 17 messages
```

Do not immediately delete them.

Investigate:

```text
Which invoice?

What exception occurred?

Is this one malformed document?

Is IAM permission missing?

Did an AWS API fail?

Is the object key unexpected?

Is the failure transient or permanent?
```

Then determine whether safe reprocessing is appropriate.

---

# 42. Observability We Would Want

Useful operational signals include:

```text
Queue depth

Oldest message age

Messages received

Messages deleted

DLQ message count

Lambda errors

Lambda throttles

Lambda duration

Step Functions failures
```

We'll study monitoring properly in the observability file.

For now understand:

> **A queue is not something we deploy and forget.**

It needs monitoring.

---

# 43. Production Improvement — Idempotent Consumer

A stronger version of the trigger could conceptually do:

```text
SQS message
    ↓
Parse invoice_id
    ↓
Atomic DynamoDB update
    ↓
PENDING → PROCESSING
    ↓
Did update succeed?
 ┌──────┴──────┐
YES             NO
 ↓               ↓
Start           Duplicate/
workflow        already claimed
 ↓               ↓
Continue        No new workflow
```

This is a proposed production pattern, not a claim that the current implementation already does it perfectly.

---

# 44. Production Improvement — Deterministic Execution Identity

Another design consideration is associating workflow execution with a stable logical processing identity.

Conceptually:

```text
invoice_id
   ↓
stable processing identity
```

Then duplicate requests can be recognized more easily.

The exact mechanism should be chosen based on the actual Step Functions execution type and project constraints rather than assumed here.

---

# 45. Production Improvement — Safe Redrive

Suppose an operator moves a message from:

```text
DLQ
```

back to:

```text
Main Queue
```

Without idempotency:

```text
Reprocessing
 ↓
Potential duplicate side effects
```

With proper idempotency:

```text
Reprocessing
 ↓
Check logical processing state
 ↓
Safely continue / reject duplicate
```

So idempotency also makes operational recovery safer.

---

# 46. Production Improvement — Backpressure

Suppose uploads suddenly become:

```text
10 invoices/minute
        ↓
1,000 invoices/minute
```

SQS helps buffer that burst.

But downstream services still have capacity and quota considerations.

Eventually you need to think about:

```text
Lambda concurrency

Textract capacity/quotas

Bedrock quotas

Step Functions execution capacity

DynamoDB capacity behavior

Cost
```

SQS provides buffering, but it doesn't make downstream capacity unlimited.

---

# 47. What Is Implemented vs What Should Be Improved?

## IMPLEMENTED / PROJECT FLOW

```text
✓ S3 ObjectCreated event

✓ SQS invoice-processing queue

✓ Trigger/bridge Lambda

✓ Nested S3-event parsing

✓ Tenant/invoice extraction from object key

✓ Step Functions workflow startup

✓ DLQ/retry architecture
```

The project analysis supports the queue-driven ingestion and failure-handling architecture. :chatgpt-content-reference{index="2"}

## IMPORTANT LIMITATION

```text
⚠ SQS can redeliver messages

⚠ Exactly-once processing must not be claimed

⚠ Duplicate workflow execution is a concern

⚠ Job reset/duplicate-processing behavior
  requires stronger protection

⚠ Stronger idempotency is a production improvement
```

:chatgpt-content-reference{index="3"}

---

# 48. Interview Preparation — 10 Questions

## Q1 — Why did you use SQS?

**Difficulty:** Basic

### Word-by-word practice answer

> “I use SQS to decouple invoice ingestion from invoice processing. After an invoice is uploaded to S3, the S3 event is placed on the queue instead of tightly coupling the upload to the processing workflow. The queue can buffer bursts, support retry behavior, and allow the processing consumer to work independently from the upload path.”

---

# Q2 — What is stored in SQS?

**Difficulty:** Basic

### Word-by-word practice answer

> “The actual invoice file is stored in S3. SQS contains the event message describing the uploaded S3 object. The trigger Lambda parses that message to determine the bucket, object key and the invoice information needed to start processing.”

---

# Q3 — What happens after SQS receives the message?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “The queue invokes the trigger Lambda through its event-source integration. The Lambda parses the nested S3 event, extracts the tenant and invoice information from the object key, prepares the workflow input, and starts the Step Functions invoice-processing workflow.”

---

# Q4 — What happens if the Lambda fails?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “If message processing fails, the message is not treated as successfully completed. After the visibility and retry behavior applies, it can become available for another processing attempt. The queue also has a dead-letter path for messages that repeatedly fail, so a permanently failing message does not need to retry forever.”

---

# Q5 — What is a DLQ?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “A dead-letter queue stores messages that could not be processed successfully after the configured retry or receive policy is exhausted. It isolates repeatedly failing messages so they can be investigated without continuously interfering with the main processing queue. I would monitor the DLQ and investigate the root cause before redriving messages.”

---

# Q6 — Does SQS guarantee exactly-once processing?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “No. I would not claim exactly-once processing with this design. Standard SQS should be treated as at-least-once delivery, so duplicate message delivery is possible. The application therefore needs idempotent processing so repeated delivery of the same logical invoice does not create duplicate workflows or other incorrect side effects.”

---

# Q7 — What is idempotency?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Idempotency means that repeating the same logical operation does not create incorrect additional effects. In this project, if the same invoice-processing message is delivered more than once, an idempotent trigger should recognize that the invoice is already being processed or has already been processed instead of blindly starting another workflow.”

---

# Q8 — Does your current implementation fully solve duplicate processing?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “I would not claim that it fully solves it. The local Codex review identified duplicate-processing and job-reset behavior as an area that needs stronger protection. Because SQS can redeliver messages, I would improve the trigger path using an atomic idempotency mechanism, such as a conditional job-state transition, before starting the workflow.”

This is the important answer: acknowledge the actual project limitation instead of pretending it doesn't exist. :chatgpt-content-reference{index="4"}

---

# Q9 — How would you implement idempotency?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I would use the invoice or job identifier as the logical processing key and atomically claim the job before starting Step Functions. For example, DynamoDB could conditionally transition the job from `PENDING` to `PROCESSING` only if it is still pending. If two duplicate consumers race, only one conditional update should succeed. The successful consumer starts the workflow, while the other recognizes that the job has already been claimed.”

---

# Q10 — How would you troubleshoot an SQS backlog?

**Difficulty:** Advanced / Scenario

### Word-by-word practice answer

> “I would first check queue metrics such as message count and oldest message age to confirm the backlog. Then I would inspect the trigger Lambda for errors, throttling and duration, verify that messages are being consumed successfully, and check whether workflow startup is failing. I would also inspect the DLQ and downstream service limits. I would trace the problem from the queue forward rather than immediately assuming the OCR or AI stage is responsible.”

---

# 49. Interview Pressure Chain

One simple question:

> **“Why SQS?”**

can become:

```text
Why SQS?
   ↓
What does decoupling mean?
   ↓
Why not S3 directly to Lambda?
   ↓
What is visibility timeout?
   ↓
What happens when Lambda fails?
   ↓
How are messages retried?
   ↓
What is a DLQ?
   ↓
What is at-least-once delivery?
   ↓
Can SQS deliver duplicates?
   ↓
What is idempotency?
   ↓
Is your implementation idempotent?
   ↓
What weakness did you find?
   ↓
How would you fix it?
   ↓
Why isn't read-then-write enough?
   ↓
What is a race condition?
   ↓
How can DynamoDB conditional writes help?
```

This is why File 07 is much more than learning the definition of SQS.

---

# 50. The Mental Model to Remember

```text
                  S3
                   ↓
            ObjectCreated
                   ↓
                  SQS
                   │
          ┌────────┴────────┐
          │                 │
        Buffer            Retry
          │                 │
          └────────┬────────┘
                   ↓
             Trigger Lambda
                   ↓
          Parse S3 event
                   ↓
          Identify invoice
                   ↓
        Idempotency needed
                   ↓
            Step Functions


Repeated failures
       ↓
      DLQ
```

And remember these three definitions:

```text
RETRY
=
Try failed work again
```

```text
DLQ
=
Isolate repeatedly failing messages
```

```text
IDEMPOTENCY
=
Repeated work must not create
incorrect duplicate effects
```

---

# 51. Check Your Understanding

Before moving to `08-Step-Functions-Workflow-Orchestration.md`, answer these three questions **without copying the answers above**:

**Question 1:** Why do we put **SQS between S3 and the processing workflow** instead of processing everything during the upload request?

**Question 2:** Suppose SQS delivers the same invoice message twice. **What could go wrong in this project?**

**Question 3:** Why is this logic unsafe?

```text
Read job
↓
If status == PENDING
↓
Start workflow
↓
Update status
```

And how could an **atomic DynamoDB conditional update** make it safer?