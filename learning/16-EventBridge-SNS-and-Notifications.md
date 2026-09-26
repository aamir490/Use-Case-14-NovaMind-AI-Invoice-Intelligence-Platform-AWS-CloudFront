# Your question

**Create `16-EventBridge-SNS-and-Notifications.md`.**

We have reached the **notification layer** of NovaMind AI.

One accuracy rule is especially important for this file:

> **EventBridge and SNS notification infrastructure exists in the project, but the Codex analysis did not verify the complete end-to-end high-risk notification path as fully wired and operational.**

So in an interview, do **not** say:

> ❌ “Whenever a high-risk invoice is detected, my production system automatically emails the finance team.”

Instead say:

> ✅ “The project includes EventBridge and SNS infrastructure for high-risk notification handling, but I classify the complete end-to-end notification delivery as partially implemented or unverified.”

That distinction will guide this entire file.

---

# 16 — EventBridge, SNS and Notifications

## 1. What Will I Learn?

By the end of this file, I should understand:

- Why invoice notifications are useful
- What an event is
- What event-driven notification means
- What Amazon EventBridge is
- What Amazon SNS is
- EventBridge vs SNS
- Producer and consumer
- Publisher and subscriber
- Topic
- Subscription
- High-risk invoice notification concept
- Where notifications belong in the architecture
- Why notification logic should be decoupled
- Business processing vs notification processing
- Why notification failure should be handled carefully
- Event filtering and routing
- Retry and DLQ concepts for notifications
- Idempotency and duplicate notifications
- Sensitive data in notifications
- Observability
- Current implementation vs intended design
- How I would improve this for production
- 10 project-specific interview questions and answers

---

# 2. Where Are Notifications in the Architecture?

The core processing pipeline is:

```text
Invoice
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
Bedrock Nova Micro
   ↓
Python Risk Rules
   ↓
Final Risk Result
```

Now imagine the result is:

```text
Risk Score = High
Risk Level = HIGH
```

The business may want another action:

```text
HIGH-RISK INVOICE
       ↓
Create Event
       ↓
EventBridge
       ↓
Notification Path
       ↓
SNS
       ↓
Subscriber
```

That is the notification concept.

---

# 3. Why Do We Need Notifications?

Imagine a finance employee uploads 500 invoices.

They don't want to manually open every invoice repeatedly just to discover:

```text
Invoice 173
→ HIGH RISK
```

A useful system can proactively communicate important events.

For example:

```text
Invoice Processing
       ↓
Risk Analysis
       ↓
HIGH
       ↓
Alert relevant user/team
```

This changes the system from purely:

> “Come and check the result.”

toward:

> “Something important happened, so the system can notify interested consumers.”

---

# 4. What Is an Event?

Simple definition:

> **An event is a record saying that something happened.**

Examples:

```text
Invoice uploaded

Invoice processed

OCR completed

Analysis completed

High-risk invoice detected

Invoice deleted
```

An event usually describes something that has **already happened**.

For example:

```text
HIGH_RISK_INVOICE_DETECTED
```

could represent a business event.

---

# 5. Command vs Event

This distinction is useful.

A command says:

```text
"Do this."
```

Example:

```text
Analyze this invoice.
```

An event says:

```text
"This happened."
```

Example:

```text
High-risk invoice detected.
```

Think:

```text
COMMAND
↓
Analyze invoice
```

versus:

```text
EVENT
↓
Invoice analysis completed
```

---

# 6. What Is Event-Driven Architecture?

We already encountered event-driven architecture with:

```text
S3 ObjectCreated
      ↓
SQS
      ↓
Lambda
```

Something happens:

```text
Object uploaded
```

and that event causes downstream processing.

Notifications can follow the same philosophy.

```text
High-risk result created
        ↓
Event
        ↓
Interested service reacts
```

The producer doesn't necessarily need to know every downstream action.

---

# 7. What Is Amazon EventBridge?

Simple definition:

> **Amazon EventBridge is an AWS event-routing service that receives events and routes matching events to targets based on rules.**

Mental model:

```text
Events
  ↓
EventBridge
  ↓
Rules
  ↓
Targets
```

Think of EventBridge as:

> **an event router.**

---

# 8. Simple EventBridge Example

Imagine the application produces:

```text
{
  "event_type": "invoice.analyzed",
  "risk_level": "HIGH"
}
```

Conceptually, EventBridge could have a rule:

```text
IF

event_type = invoice.analyzed

AND

risk_level = HIGH

THEN

send to notification target
```

This example is conceptual. Do not treat this exact event schema as verified repository code.

---

# 9. What Is Amazon SNS?

SNS stands for:

> **Simple Notification Service**

Simple definition:

> **Amazon SNS is a managed publish/subscribe messaging service used to distribute messages to subscribers.**

Mental model:

```text
Publisher
    ↓
SNS Topic
    ↓
Subscribers
```

Possible subscriber types can include things such as:

```text
Email

Lambda

SQS

HTTP/S endpoint
```

depending on the architecture.

---

# 10. What Is an SNS Topic?

Think of a topic as a logical communication channel.

For example:

```text
High Risk Invoice Topic
```

A producer publishes:

```text
High-risk invoice detected
```

to the topic.

Subscribers interested in that topic can receive the message.

```text
                    SNS Topic
                       │
            ┌──────────┼──────────┐
            ▼          ▼          ▼
          Email      Lambda      SQS
```

This is a generic SNS concept, not a statement that all three subscriber types exist in this project.

---

# 11. Publisher and Subscriber

Two important terms:

### Publisher

The system/component that sends a message.

```text
Publisher
   ↓
SNS Topic
```

### Subscriber

The endpoint that receives messages from the topic.

```text
SNS Topic
   ↓
Subscriber
```

This gives us:

```text
Publisher
   ↓
Topic
   ↓
Subscriber
```

---

# 12. EventBridge vs SNS

This is a very common AWS interview question.

A simple mental model:

```text
EventBridge
=
Route events based on rules
```

```text
SNS
=
Publish messages to subscribers
```

They overlap in some capabilities, but their architectural roles are different.

---

# 13. In This Project

The intended notification architecture can be thought about as:

```text
Invoice Processing
       ↓
Risk Result
       ↓
Business Event
       ↓
EventBridge
       ↓
Matching Rule
       ↓
SNS
       ↓
Notification Subscriber
```

The important word is:

> **intended**

because the complete end-to-end path was not fully verified by Codex.

---

# 14. What Is a Business Event?

There are technical events and business events.

### Technical event

```text
S3 object created
```

### Business event

```text
High-risk invoice detected
```

The second event has business meaning.

It communicates something important about the domain.

---

# 15. Why Is `HIGH_RISK_INVOICE` Useful as an Event?

Because other components may care about it.

Today:

```text
High Risk
   ↓
Send notification
```

Tomorrow:

```text
High Risk
   ├──→ Notification
   ├──→ Audit workflow
   ├──→ Manual review queue
   ├──→ Security workflow
   └──→ Analytics
```

The invoice-processing code does not necessarily need direct integration with every future consumer.

That is one benefit of event-driven architecture.

---

# 16. Tight Coupling Example

Imagine risk-scoring code directly does:

```text
Calculate Risk
    ↓
Send Email
    ↓
Write Audit Record
    ↓
Call Finance System
    ↓
Call Fraud Team API
    ↓
Send Slack Message
```

Now risk processing knows about everything.

That creates tight coupling.

---

# 17. Decoupled Design

Instead:

```text
Calculate Risk
      ↓
Publish:
HIGH_RISK_INVOICE_DETECTED
      ↓
Event Bus
```

Then:

```text
Event Bus
   ├──→ Notification
   ├──→ Audit
   ├──→ Manual Review
   └──→ Analytics
```

The producer only needs to publish the business event.

Consumers decide what to do with it.

---

# 18. Why Is Decoupling Valuable?

Because consumers can evolve independently.

For example:

```text
Today:
HIGH → Email
```

Later:

```text
HIGH → Email
     → Manual Review
```

Later:

```text
HIGH → Email
     → Manual Review
     → External Finance Workflow
```

The core risk engine doesn't necessarily need major redesign every time.

---

# 19. EventBridge Rule

An EventBridge rule determines:

> **Which events should go to which target?**

Conceptually:

```text
Incoming Event
      ↓
Does it match rule?
     / \
   YES  NO
    ↓    ↓
Target Ignore
```

Example:

```text
risk_level = HIGH
```

could route to:

```text
SNS
```

while lower-risk events might not.

Again, the exact current repository rule should be taken from the infrastructure code, not assumed from this example.

---

# 20. Event Pattern

An EventBridge rule can match event properties.

Conceptually:

```json
{
  "source": ["novamind.invoice"],
  "detail-type": ["High Risk Invoice"]
}
```

This is only a teaching example.

The important concept is:

```text
Event
   ↓
Pattern Matching
   ↓
Matching Target
```

---

# 21. Why Not Send Email Directly From Risk Lambda?

You technically could.

For example:

```text
Risk Lambda
    ↓
Send email
```

But now the core processing Lambda owns:

```text
Risk calculation
+
Notification delivery
```

If notification logic changes, the processing code changes.

A decoupled design is cleaner:

```text
Risk Processing
      ↓
Event
      ↓
Notification System
```

---

# 22. Most Important Reliability Question

Suppose:

```text
Invoice processing succeeds ✓

Risk score calculated ✓

Result stored ✓

Notification fails ✗
```

Should the entire invoice become:

```text
FAILED
```

?

Not necessarily.

This depends on business requirements.

In many architectures, the important distinction is:

```text
Invoice Processing Status
```

versus:

```text
Notification Status
```

---

# 23. Processing Success vs Notification Success

Imagine:

```text
processing_status = COMPLETED

notification_status = FAILED
```

This can be more accurate than:

```text
status = FAILED
```

because the invoice itself was processed correctly.

Only the notification failed.

This is similar to what we learned about:

```text
AI status
```

versus:

```text
overall processing status
```

in File 14.

---

# 24. State Dimensions Are Growing

A mature invoice could conceptually have:

```text
processing_status

ocr_status

ai_status

risk_status

storage_status

notification_status
```

You don't necessarily need six database fields in every design.

The lesson is:

> **Different subsystems can succeed or fail independently.**

A single `COMPLETED` field may hide too much information.

---

# 25. What Happens If SNS Delivery Fails?

In a production system, you need to consider:

```text
Retry?

DLQ?

Alarm?

Manual recovery?

Alternative channel?
```

The exact behavior depends on the subscription type and architecture.

For NovaMind AI, do not claim a fully verified notification retry/DLQ workflow unless the repository confirms it.

---

# 26. Important DLQ Distinction

Remember File 07.

The existing:

```text
SQS
 ↓
DLQ
```

in the invoice-ingestion path protects that queue-processing boundary.

It does **not** automatically mean:

> “Every notification failure goes into the same DLQ.”

Different asynchronous boundaries need their own failure-handling design.

This is a very important interview point.

---

# 27. The Existing SQS DLQ Does Not Protect Everything

The application has:

```text
S3
 ↓
SQS
 ↓
Trigger Lambda
```

with a DLQ-related ingestion design.

But later failures such as:

```text
Textract failure

Bedrock failure

Storage failure

SNS delivery failure
```

do not magically return the original SQS message to that queue.

Each boundary needs to be understood separately.

---

# 28. Duplicate Notifications

Now connect notifications with idempotency.

Suppose:

```text
High-risk event
      ↓
Notification sent
```

Then the event is retried or duplicated.

Potential result:

```text
Notification #1
Notification #2
Notification #3
```

The finance team may receive the same alert multiple times.

That is a notification idempotency problem.

---

# 29. Why Can Duplicate Events Happen?

Distributed event-driven systems often use:

```text
at-least-once delivery
```

patterns.

Retries can occur because of:

```text
timeouts

temporary failures

consumer failures

network problems
```

Therefore consumers should not blindly assume:

> “I will see each logical event exactly once.”

---

# 30. Notification Idempotency

A stronger notification system can conceptually create an identifier such as:

```text
notification_id
=
invoice_id + event_type
```

Then before sending:

```text
Have I already successfully
processed this notification?
```

If yes:

```text
Don't send duplicate
```

If no:

```text
Send
↓
Record success
```

This is a production improvement concept, not a verified current implementation.

---

# 31. Event IDs

Another useful pattern is:

```text
event_id
```

Each business event receives a unique identity.

For example:

```text
event_id
invoice_id
tenant_id
event_type
timestamp
```

Consumers can record which events they have already processed.

This helps with:

```text
deduplication

tracing

auditing

debugging
```

---

# 32. What Should Be Inside an Event?

A good event should contain enough information for the consumer to understand what happened.

Conceptually:

```json
{
  "event_id": "evt_123",
  "invoice_id": "inv_123",
  "event_type": "HIGH_RISK_DETECTED",
  "risk_level": "HIGH"
}
```

But be careful.

Do we want to include:

```text
Entire invoice PDF?

Bank details?

Sensitive customer information?

Full OCR text?
```

Probably not unless there is a strong requirement and appropriate protection.

---

# 33. Minimize Sensitive Event Data

A better principle is:

> **Publish only the information consumers actually need.**

For example, rather than putting the entire invoice into an event:

```text
invoice_id
risk_level
safe metadata
```

may be enough.

Then an authorized downstream service can retrieve additional data if required.

This reduces sensitive-data propagation.

---

# 34. Why Is This Important?

Once sensitive information is copied into:

```text
Events

SNS messages

Emails

Logs

DLQs
```

you now have more locations containing sensitive data.

That increases:

```text
Security scope

Retention complexity

Deletion complexity

Compliance scope
```

So event design is also a security decision.

---

# 35. Email Is Especially Important

Email is not the same security boundary as your authenticated application.

Inside NovaMind AI:

```text
User
 ↓
Cognito
 ↓
Authorized API
 ↓
Invoice
```

But email may leave that controlled application boundary.

Therefore a notification might say:

> “High-risk invoice detected. Review it in NovaMind AI.”

rather than including every sensitive invoice detail directly in the email.

The exact notification content must follow business requirements.

---

# 36. SNS Email Subscription Concept

With SNS email subscriptions, there is normally a subscription relationship between:

```text
SNS Topic
    ↓
Email Subscriber
```

The recipient must be appropriately configured/confirmed according to the subscription mechanism.

But remember:

> We have not verified the project's complete live subscription/delivery state.

So don't claim a specific finance email currently receives alerts unless verified.

---

# 37. Current Project Evidence

From the Codex project analysis, we can safely say:

```text
EventBridge infrastructure exists

SNS infrastructure exists

High-risk notification intent exists
```

But:

```text
Complete event production
        ↓
EventBridge matching
        ↓
SNS publication
        ↓
Confirmed subscriber
        ↓
Successful real-world delivery
```

was **not fully verified end to end**.

---

# 38. How Should We Classify It?

Use the implementation-status language from our project-analysis methodology.

Not:

```text
FULLY IMPLEMENTED AND VERIFIED
```

Better:

```text
PARTIAL / UNVERIFIED END-TO-END
```

depending on the exact component being discussed.

This is one of the reasons we built our Codex analysis system.

---

# 39. README vs Repository Evidence

A README can describe:

```text
High-risk SNS email alerts
```

as part of the architecture.

But documentation is not automatically proof that:

```text
Event producer
+
Rule
+
Target
+
Subscription
+
Runtime permissions
+
Real delivery
```

all currently work.

Our interview claims should follow verified implementation evidence.

---

# 40. How to Answer Without Underselling the Project

Don't say:

> “Notifications don't work.”

We don't have evidence for that broad statement.

Also don't say:

> “Notifications are completely production-ready.”

We don't have evidence for that either.

Say:

> “The repository contains EventBridge and SNS infrastructure for the high-risk notification path. However, my code review did not verify the complete event-to-subscriber delivery path, so I classify that integration as partially implemented or requiring end-to-end validation.”

That's precise engineering language.

---

# 41. How Would We Verify It?

To call it fully verified, we would want to trace:

```text
1. Where is the event produced?

2. What exact event payload is produced?

3. Which EventBridge bus receives it?

4. What rule matches it?

5. What is the rule target?

6. Does EventBridge have required permissions?

7. Which SNS topic receives it?

8. Which subscriptions exist?

9. Are subscriptions confirmed?

10. Does a real HIGH-risk invoice trigger delivery?

11. What happens on failure?

12. Where are logs/metrics?
```

Only after that should we confidently describe the runtime path.

---

# 42. How Would I Test It?

A proper integration test could be:

```text
Create/test invoice
       ↓
Produce HIGH risk condition
       ↓
Processing completes
       ↓
Verify event emitted
       ↓
Verify EventBridge rule matched
       ↓
Verify SNS publication
       ↓
Verify subscriber delivery
```

Then test:

```text
LOW risk
```

and verify:

```text
No high-risk notification
```

if that is the intended business rule.

---

# 43. Negative Testing Matters

Don't only test:

```text
Expected HIGH
→ notification arrives
```

Also test:

```text
LOW
→ no HIGH alert
```

```text
MEDIUM
→ expected behavior
```

```text
Duplicate event
→ no unwanted duplicate alert
```

```text
SNS failure
→ observable/recoverable
```

```text
Invalid event
→ safely handled
```

This gives you much stronger production confidence.

---

# 44. Observability

A notification system needs monitoring.

Useful questions include:

```text
Was the event produced?

Did the EventBridge rule match?

Was the target invoked?

Was SNS publish successful?

Did delivery fail?

Was it retried?

Did it reach a DLQ?

Which invoice caused it?
```

Without observability, users may say:

> “I didn't receive an alert.”

and you have no way to determine why.

---

# 45. Correlation

Remember File 14.

A useful identifier is:

```text
invoice_id
```

The same identifier can help correlate:

```text
Risk result
     ↓
Event
     ↓
EventBridge
     ↓
SNS
     ↓
Notification
```

Conceptually logs might include:

```text
invoice_id
event_id
event_type
notification_status
```

This makes troubleshooting much easier.

---

# 46. Notification Metrics

A production system might monitor:

```text
Events produced

Events matched

Notifications attempted

Notifications succeeded

Notifications failed

Retry count

DLQ count

Duplicate suppression count
```

These are recommended observability concepts.

Do not claim all of these custom metrics currently exist.

---

# 47. Notification Alarm Example

Conceptually:

```text
SNS delivery failures > threshold
        ↓
CloudWatch Alarm
        ↓
Operations Alert
```

Or:

```text
Notification DLQ contains messages
        ↓
Alarm
```

Again, this is production architecture guidance rather than a verified current project feature.

---

# 48. EventBridge vs SQS

Another interview question:

> “Why EventBridge instead of SQS?”

They solve different primary problems.

Think:

```text
SQS
=
Queue / buffering / worker decoupling
```

```text
EventBridge
=
Event routing / filtering
```

In this project:

```text
S3
 ↓
SQS
 ↓
Processing
```

is useful because the invoice needs durable asynchronous processing.

Whereas:

```text
Business Event
 ↓
EventBridge
 ↓
Matching Consumers
```

is useful for event routing.

---

# 49. EventBridge vs SNS vs SQS

Memorize the concepts, not a slogan:

| Service | Main mental model |
|---|---|
| SQS | Queue work/messages for consumers |
| SNS | Publish messages to subscribers |
| EventBridge | Route events based on rules/patterns |

Real AWS capabilities overlap, so don't claim these definitions describe every possible feature.

For interviews, this mental model is enough to explain why each appears in an architecture.

---

# 50. Example Using All Three

Your project provides a useful way to understand them.

```text
Invoice Uploaded
      ↓
     SQS
      ↓
Processing Worker
```

Think:

> “Please process this work reliably.”

Later:

```text
High Risk Detected
      ↓
EventBridge
```

Think:

> “This business event happened. Route it to interested targets.”

Then:

```text
EventBridge
     ↓
SNS
     ↓
Subscribers
```

Think:

> “Distribute this notification.”

That distinction is excellent for interviews.

---

# 51. Should Notification Block Invoice Processing?

Suppose:

```text
Risk result stored successfully
```

but:

```text
Notification service temporarily unavailable
```

If notification is non-critical to the core processing transaction, you may prefer:

```text
Invoice = successfully processed
Notification = pending/failed/retry
```

rather than:

```text
Invoice = failed
```

because an email failed.

The exact decision depends on business requirements.

---

# 52. What If Notification Is Legally Critical?

Then the architecture may need stronger guarantees.

For example, if a business requirement says:

> “Every HIGH-risk invoice must be reviewed.”

Then simply attempting an email is not enough.

You may need:

```text
Durable review queue

Acknowledgement state

Escalation

Retry

Audit record

SLA monitoring
```

This illustrates an important architectural principle:

> **Business requirements determine reliability requirements.**

---

# 53. Email Does Not Equal Workflow

Suppose SNS successfully sends:

```text
High-risk invoice detected.
```

Does that prove somebody reviewed the invoice?

No.

These are different:

```text
Notification sent
```

```text
Notification delivered
```

```text
Notification read
```

```text
Invoice reviewed
```

```text
Invoice approved/rejected
```

Don't confuse them.

---

# 54. Future Human Review Workflow

For a stronger enterprise version:

```text
HIGH Risk
   ↓
Create Review Task
   ↓
Notify Reviewer
   ↓
Reviewer Opens Application
   ↓
Review Invoice
   ↓
APPROVE / REJECT / ESCALATE
   ↓
Audit Decision
```

That is much stronger than:

```text
HIGH
 ↓
email
```

This is a future architecture idea, not the current implementation.

---

# 55. Notification Security

A production notification design should consider:

```text
Who is allowed to publish?

Who can subscribe?

Who can read messages?

What data is included?

Are messages encrypted appropriately?

Are logs exposing sensitive content?

How long are failed messages retained?
```

Notification architecture is part of the application's security model.

---

# 56. IAM

Just as with DynamoDB and S3, notification components should follow least privilege.

For example, conceptually:

```text
Event Producer
      ↓
Permission to publish event
```

```text
EventBridge
      ↓
Permission to invoke target
```

```text
Authorized publisher
      ↓
Permission to publish to SNS topic
```

Don't give broad:

```text
*
```

permissions when narrower permissions satisfy the requirement.

---

# 57. Event Schema Versioning

Imagine today your event is:

```json
{
  "invoice_id": "123",
  "risk": "HIGH"
}
```

Tomorrow you rename:

```text
risk
```

to:

```text
risk_level
```

An old consumer may break.

Therefore mature event-driven systems treat event schemas as contracts.

You can conceptually version them:

```text
event_version = 1
```

and evolve consumers carefully.

This is a production design concept, not a verified current implementation.

---

# 58. Why Events Should Be Stable

Once multiple consumers depend on an event:

```text
Producer
   ↓
Event
   ├── Consumer A
   ├── Consumer B
   └── Consumer C
```

changing the event can break multiple systems.

Therefore:

> **Events become integration contracts.**

This is why event naming and schemas matter.

---

# 59. Current Architecture Mental Model

For the current project, remember:

```text
                 INVOICE PIPELINE
                        │
                        ▼
                  Risk Analysis
                        │
                        ▼
                   Risk Result
                        │
                        ▼
              Notification Intent
                        │
                        ▼
                  EventBridge
                        │
                   Rule/Target
                        │
                        ▼
                       SNS
                        │
                        ▼
                   Subscriber
```

But place a warning beside it:

```text
⚠ Complete end-to-end notification
  delivery is not fully verified.
```

---

# 60. Current vs Future

## Verified / supported by project analysis

```text
✓ EventBridge infrastructure exists

✓ SNS infrastructure exists

✓ High-risk notification architecture/intention exists
```

## Partial / unverified

```text
⚠ Complete event-production wiring

⚠ Full EventBridge → SNS runtime path

⚠ Confirmed live subscriber state

⚠ Guaranteed email delivery

⚠ Complete failure/retry handling

⚠ End-to-end notification testing
```

## Future production improvements

```text
→ Explicit event schema

→ Event IDs

→ Idempotent consumers

→ Notification status

→ Dedicated failure handling/DLQ

→ Monitoring and alarms

→ Minimal sensitive payload

→ Review workflow

→ Audit trail

→ Integration tests
```

---

# 61. What NOT to Say in an Interview

Avoid:

> ❌ “SNS definitely emails the finance team whenever fraud is detected.”

Problems:

```text
"definitely"
→ not verified

"fraud"
→ risk score is not proof of fraud

"emails"
→ end-to-end delivery not verified
```

Also avoid:

> ❌ “My SQS DLQ catches notification failures.”

The ingestion DLQ does not automatically protect the later notification boundary.

Also avoid:

> ❌ “EventBridge sends the email.”

EventBridge primarily routes the event; SNS may be involved in notification distribution.

---

# 62. Better Interview Language

Say:

> “The project includes EventBridge and SNS infrastructure for a high-risk notification path. The intended design is to publish a business event when a high-risk invoice is identified, use EventBridge for event routing, and SNS for subscriber notification. However, during my code review I did not verify the complete event-to-subscriber delivery path, so I classify that integration as partially implemented and requiring end-to-end validation.”

This answer is technically mature because you separate:

```text
Architecture intention
```

from:

```text
Verified implementation
```

---

# 63. Interview Preparation — 10 Questions

## Q1 — What is Amazon EventBridge?

**Difficulty:** Basic

### Word-by-word practice answer

> “Amazon EventBridge is a managed event-routing service. Applications and AWS services can publish events, and EventBridge rules can match those events and route them to appropriate targets. In my project, it is part of the notification architecture for reacting to important invoice-processing events such as high-risk results.”

---

## Q2 — What is Amazon SNS?

**Difficulty:** Basic

### Word-by-word practice answer

> “Amazon SNS is a managed publish-and-subscribe messaging service. Publishers send messages to an SNS topic, and configured subscribers can receive those messages. In my project, SNS infrastructure is included as part of the intended high-risk notification path.”

---

## Q3 — What is the difference between EventBridge and SNS?

**Difficulty:** Basic / Intermediate

### Word-by-word practice answer

> “I mainly think of EventBridge as an event-routing layer and SNS as a publish-and-subscribe notification layer. EventBridge can match events using rules and route them to targets, while SNS distributes published messages to subscribers. Their capabilities overlap in some areas, but those are their main responsibilities in this architecture.”

---

## Q4 — Why use EventBridge instead of sending notifications directly from the risk Lambda?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Publishing a business event decouples the core invoice-processing logic from notification consumers. The risk-processing component does not need to know every downstream action. EventBridge can route the event to notification or other future consumers independently, which makes the architecture easier to extend without tightly coupling those consumers to the core risk logic.”

---

## Q5 — What happens when a high-risk invoice is detected?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The intended architecture includes a high-risk event and notification path using EventBridge and SNS. However, I would be careful not to claim that the complete runtime path is currently verified. The repository contains the notification infrastructure, but my code analysis did not confirm the entire producer-to-EventBridge-to-SNS-to-subscriber delivery flow end to end.”

---

## Q6 — Why don't you claim that high-risk emails definitely work?

**Difficulty:** Intermediate / Pressure

### Word-by-word practice answer

> “Because infrastructure definitions and documentation are not enough to prove runtime behavior. To make that claim confidently, I would verify where the event is produced, the exact EventBridge rule and target, SNS topic permissions and subscriptions, and then run an end-to-end test with a high-risk invoice and confirm actual delivery. Until that validation is complete, I describe the feature as partially implemented or unverified end to end.”

---

## Q7 — Should invoice processing fail if the notification fails?

**Difficulty:** Advanced

### Word-by-word practice answer

> “That depends on the business requirement. If notification is a secondary side effect, I would normally separate invoice-processing status from notification status so a successfully analyzed and stored invoice does not become failed only because notification delivery had a temporary problem. I would handle notification retries and failure independently and make that failure observable.”

---

## Q8 — How would you prevent duplicate notifications?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I would design the notification consumer to be idempotent because distributed event systems can deliver or process the same logical event more than once. I could assign each business event a stable event ID or derive a notification identity from the invoice and event type, then record successful processing and suppress repeated delivery of the same logical notification.”

---

## Q9 — What information would you include in a high-risk notification?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I would minimize sensitive information. The notification should contain enough context to identify the invoice and explain that it requires review, but I would avoid copying unnecessary OCR text, financial details or document contents into events and emails. An authorized user can open the application to view the full information through the normal Cognito-protected access path.”

---

## Q10 — How would you make the notification system production-ready?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “First, I would verify the complete event path from the risk result through EventBridge, SNS and the final subscriber. Then I would define a versioned event schema, use event IDs and idempotent consumers, separate notification status from processing status, implement appropriate retries and failure handling, and add monitoring and alarms. I would minimize sensitive event data and add integration tests for high-risk, non-high-risk, duplicate and failure scenarios. For enterprise use, I would also consider a durable human-review workflow rather than relying only on an email alert.”

---

# 64. Interview Pressure Chain

The interviewer starts:

> **“How do notifications work in your project?”**

Then:

```text
What is EventBridge?
        ↓
What is SNS?
        ↓
Why do you need both?
        ↓
Why not send email directly?
        ↓
What is an event?
        ↓
What is a business event?
        ↓
Who publishes the event?
        ↓
What rule matches it?
        ↓
What is the EventBridge target?
        ↓
Is the complete path implemented?
        ↓
Did you test actual email delivery?
        ↓
What happens if SNS fails?
        ↓
Does the invoice become FAILED?
        ↓
What happens on duplicate events?
        ↓
Can users receive duplicate emails?
        ↓
How would you make it idempotent?
        ↓
What data is inside the notification?
        ↓
Would you put the complete invoice in email?
        ↓
How do you monitor failures?
        ↓
Does your existing SQS DLQ
protect SNS failures?
```

If you can answer that chain correctly, you understand notification architecture rather than just knowing AWS service names.

---

# 65. Troubleshooting Scenario

Interviewer:

> **“A HIGH-risk invoice was processed successfully, but the user didn't receive the expected notification. How would you troubleshoot it?”**

### Word-by-word answer

> “I would trace the notification path independently from the invoice-processing path. First I would confirm that the invoice was actually classified as high risk and identify the invoice ID. Then I would verify whether the application produced the expected business event. Next I would check whether EventBridge received and matched that event, whether the configured rule invoked its target, and whether SNS received the publication. After that I would inspect the subscription and delivery state. I would also check CloudWatch metrics and logs for failures. I would not assume the original SQS ingestion DLQ contains this failure because that DLQ belongs to an earlier processing boundary.”

This is a strong troubleshooting answer because you follow the architecture one boundary at a time.

---

# 66. Architecture Decision Question

Interviewer:

> **“Why EventBridge? Couldn't you just call SNS directly?”**

### Strong answer

> “Yes, direct SNS publication could be a simpler design if notification were the only downstream requirement. EventBridge becomes useful when I want the application to publish a business event independently of its consumers and route that event based on rules. That allows additional consumers such as audit processing or manual-review workflows to be added without tightly coupling them to the invoice-processing code. I would choose between direct SNS and EventBridge plus SNS based on actual routing and extensibility requirements rather than adding EventBridge unnecessarily.”

This answer is important.

Don't say:

> “EventBridge + SNS is always better.”

Sometimes:

```text
Lambda → SNS
```

may be completely sufficient.

Architecture should match requirements.

---

# 67. EventBridge vs SNS vs SQS — Interview Cheat Sheet

```text
SQS
│
├── Queue
├── Buffer work
├── Consumer processes message
└── Useful for durable async processing
```

```text
SNS
│
├── Publish/Subscribe
├── Topic
├── Multiple subscribers possible
└── Useful for message distribution
```

```text
EventBridge
│
├── Event bus/router
├── Event patterns
├── Rules
├── Targets
└── Useful for event-driven integration
```

For NovaMind AI:

```text
S3
 ↓
SQS
 ↓
Invoice Processing
```

versus intended:

```text
High-Risk Business Event
 ↓
EventBridge
 ↓
SNS
 ↓
Notification
```

---

# 68. Five Things You Must Remember

**1. EventBridge and SNS are not the same thing.**

```text
EventBridge
→ route events

SNS
→ publish/distribute messages
```

**2. Notifications should ideally be decoupled from core invoice processing.**

```text
Risk Result
   ↓
Event
   ↓
Notification Consumer
```

rather than hard-coding every downstream action into the risk engine.

**3. Notification success and invoice-processing success are different states.**

```text
Invoice processing ✓

Notification ✗
```

can happen.

**4. Duplicate events can produce duplicate notifications.**

Therefore:

```text
Event IDs
+
Idempotent consumer
```

are useful production patterns.

**5. Most important for THIS project:**

```text
EventBridge infrastructure ✓

SNS infrastructure ✓

Notification intention ✓

Complete end-to-end delivery
fully verified ✗
```

Do not overclaim.

---

# 69. Your 30-Second Interview Answer

> “The project includes EventBridge and SNS infrastructure for a high-risk invoice notification path. The architectural idea is to keep notification handling decoupled from the core invoice-processing pipeline: a business event can represent a high-risk result, EventBridge can route matching events, and SNS can distribute the notification to configured subscribers. However, my repository review did not verify the complete producer-to-subscriber runtime path, so I classify that integration as partially implemented or requiring end-to-end validation. For production, I would add explicit event schemas and IDs, idempotent notification handling, independent notification status, failure monitoring and tests for delivery and duplicate events.”

---

# 70. Your 10-Second Mental Model

```text
Something important happened
        ↓
      EVENT
        ↓
   EventBridge
        ↓
  Route / Filter
        ↓
       SNS
        ↓
    Subscriber
```

Or:

> **EventBridge decides where an event goes; SNS distributes a message to subscribers.**

For **your project**, always add mentally:

> **Infrastructure exists, but complete high-risk notification delivery still needs end-to-end verification.**

---

# 71. Check Your Understanding

Before moving to **`17-AWS-CDK-and-Infrastructure-as-Code.md`**, answer these three in your own words.

**Question 1:** Why might we use:

```text
Risk Engine
    ↓
EventBridge
    ↓
SNS
```

instead of directly putting email-sending logic inside the risk Lambda?

**Question 2:** Suppose:

```text
Invoice Processing = COMPLETED
Notification = FAILED
```

Should we automatically change the invoice to `FAILED`? Explain why or why not.

**Question 3:** An interviewer asks:

> **“So your system definitely sends an email whenever a HIGH-risk invoice is detected?”**

Based on the actual Codex analysis, what is the accurate answer you should give?