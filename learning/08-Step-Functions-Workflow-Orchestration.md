# Your question

**Start `08-Step-Functions-Workflow-Orchestration.md`.**

File 07 ended here:

```text
SQS
 ↓
Trigger Lambda
 ↓
Start Step Functions
```

Now we go inside the **main invoice-processing workflow**.

The key idea for File 08 is:

> **Lambda functions perform individual tasks. AWS Step Functions controls the order in which those tasks run and manages the workflow between them.**

For this project, keep the verified workflow model as **four main processing stages** rather than turning visual subdivisions into extra implemented states.

---

# 08 — Step Functions Workflow Orchestration

## 1. What Will I Learn?

In this file, I will understand:

- What workflow orchestration means
- Why this project uses AWS Step Functions
- What happens after the SQS trigger Lambda runs
- What a state machine is
- What Step Functions Express Workflow means in this project
- The four main processing stages
- What data moves between stages
- Step Functions vs Lambda
- Orchestration vs business logic
- Sequential processing
- Retry and failure handling
- Workflow status vs application job status
- Why `COMPLETED` needs careful interpretation
- Current workflow limitations
- How I would improve the workflow for production
- How to troubleshoot a failed execution
- 10 project-specific interview questions and word-by-word answers

---

# 2. Where Are We in the Architecture?

We have already reached:

```text
Invoice
   ↓
S3
   ↓
SQS
   ↓
Trigger Lambda
   ↓
STEP FUNCTIONS
```

Now Step Functions coordinates the processing pipeline:

```text
                STEP FUNCTIONS
                       │
                       ▼
             ┌─────────────────┐
             │ 1. Process      │
             │    Document     │
             └────────┬────────┘
                      ↓
             ┌─────────────────┐
             │ 2. AI Analysis  │
             └────────┬────────┘
                      ↓
             ┌─────────────────┐
             │ 3. Risk Rules   │
             └────────┬────────┘
                      ↓
             ┌─────────────────┐
             │ 4. Store        │
             │    Results      │
             └─────────────────┘
```

These are the **four main workflow stages** identified in the Codex analysis.

---

# 3. First — What Is Orchestration?

Imagine four workers:

```text
Worker A → Extract invoice
Worker B → Analyze invoice
Worker C → Calculate risk
Worker D → Store result
```

Each worker knows how to perform its own task.

But who decides:

```text
Who goes first?

What comes next?

What input should the next worker receive?

What happens if Worker B fails?

Should something retry?
```

We need a coordinator.

In this project:

> **AWS Step Functions is that coordinator.**

---

# 4. Orchestration vs Execution

This distinction is extremely important.

## Lambda

Lambda answers:

> **What work should I perform?**

For example:

```text
Extract document
Analyze data
Calculate risk
Store result
```

## Step Functions

Step Functions answers:

> **How should these pieces of work be coordinated?**

For example:

```text
Run A
 ↓
If successful
 ↓
Run B
 ↓
Then C
 ↓
Then D
```

So:

```text
Lambda
=
Task execution
```

while:

```text
Step Functions
=
Workflow orchestration
```

---

# 5. What Is a State Machine?

AWS Step Functions represents a workflow as a:

> **State machine**

A state machine contains states.

Simplified:

```text
START
  ↓
State A
  ↓
State B
  ↓
State C
  ↓
State D
  ↓
END
```

Each state can represent something such as:

```text
Task

Choice

Wait

Parallel

Success

Failure
```

But only claim state types actually used by this project when discussing the implementation.

---

# 6. Why Not Put Everything Inside One Lambda?

Imagine:

```text
One Giant Lambda
      │
      ├── Validate document
      ├── Call Textract
      ├── Transform OCR
      ├── Call Bedrock
      ├── Parse AI response
      ├── Calculate risk
      ├── Save S3 output
      ├── Save DynamoDB
      └── Publish events
```

This would tightly combine many responsibilities.

Instead, the project separates processing responsibilities and coordinates them with Step Functions.

Conceptually:

```text
Step Functions

   ├── Lambda A
   │
   ├── Lambda B
   │
   ├── Lambda C
   │
   └── Lambda D
```

This makes the workflow easier to reason about and gives each processing stage a clearer responsibility.

---

# 7. Why Step Functions Fits This Project

Invoice processing is naturally a multi-stage workflow.

The later stage depends on earlier output:

```text
Invoice document
      ↓
Extract information
      ↓
Analyze information
      ↓
Calculate risk
      ↓
Store result
```

You cannot meaningfully calculate the final invoice risk before obtaining the required invoice information.

So there is a natural processing sequence.

---

# 8. Step Functions Express Workflow

The architecture identifies the processing state machine as an:

> **AWS Step Functions Express Workflow**

At this stage, understand the project connection:

```text
SQS Trigger Lambda
       ↓
Starts Express Workflow
       ↓
Short-lived serverless
invoice processing
```

Do not turn this into a generic claim that Express is always better than Standard workflows.

The choice depends on workflow requirements such as execution duration, execution semantics, observability, volume and cost characteristics.

Later, when discussing architecture decisions, we can compare Express vs Standard specifically against this workload.

---

# 9. Workflow Input

The workflow needs to know which invoice it is processing.

Conceptually, the input needs information such as:

```text
Invoice identity

Tenant identity

S3 object location

Job context
```

So think:

```text
Trigger Lambda
      ↓
{
   invoice context,
   tenant context,
   document location
}
      ↓
Step Functions
```

Do not memorize an invented JSON structure. The exact fields should come from the implementation.

---

# 10. Stage 1 — Process Document

The first major workflow stage deals with the uploaded document.

```text
Step Functions
      ↓
Process Document
      ↓
Amazon Textract
```

The purpose is to transform:

```text
PDF / Image
```

into information the application can work with.

Conceptually:

```text
Invoice Document
      ↓
Document Processing Lambda
      ↓
Textract
      ↓
Extracted invoice information
```

---

# 11. What Happens During Document Processing?

At a high level, this stage is responsible for obtaining the invoice data required by later processing.

Examples can include:

```text
Text

Vendor information

Invoice number

Dates

Amounts

Line items
```

The exact extraction behavior will be studied in:

**`09-Textract-OCR-and-Invoice-Extraction.md`**

For File 08, the important thing is:

> **Step Functions coordinates this stage; Textract performs the document extraction.**

---

# 12. Output Becomes Input for the Next Stage

This is a fundamental workflow concept.

Think:

```text
Stage 1

Input:
S3 invoice

Output:
Extracted invoice data
```

Then:

```text
Stage 2

Input:
Extracted invoice data

Output:
AI findings
```

Then:

```text
Stage 3

Input:
Invoice data + findings

Output:
Risk information
```

Then:

```text
Stage 4

Input:
Final processing result

Output:
Persisted result
```

So data moves through the workflow.

---

# 13. Stage 2 — AI Analysis

After invoice information has been extracted:

```text
Extracted Data
      ↓
AI Analysis Stage
      ↓
Amazon Bedrock
      ↓
Nova Micro
```

The model performs Generative AI analysis of the invoice context.

Conceptually:

```text
Textract output
      ↓
Prompt construction
      ↓
Bedrock Nova Micro
      ↓
AI-generated findings
```

This stage is different from OCR.

Remember:

```text
Textract
=
extract
```

```text
Bedrock + Nova Micro
=
analyze
```

---

# 14. Why Does AI Come After Textract?

Because the invoice begins as:

```text
PDF / Image
```

The application first needs useful invoice information.

Therefore:

```text
Document
 ↓
Textract
 ↓
Structured/textual information
 ↓
Bedrock
```

This separates:

**document understanding/extraction**

from:

**Generative AI reasoning/analysis**.

---

# 15. Stage 3 — Risk Rules

Next comes deterministic business logic.

```text
Invoice Data
      +
AI Findings
      ↓
Risk Rules
      ↓
Numeric Risk Score
      ↓
Risk Classification
```

For example:

```text
0–100 score
      ↓
LOW / MEDIUM / HIGH
```

The exact scoring implementation belongs in File 12.

The critical architecture lesson is:

> **The language model does not independently control the final numeric risk score.**

The final scoring logic is deterministic Python business logic.

---

# 16. Why Keep Risk Logic Separate?

Suppose the LLM says:

```text
"This invoice appears suspicious."
```

That's useful analysis.

But financial/business rules may require repeatable logic such as:

```text
IF condition A:
    add risk points

IF condition B:
    add risk points
```

This produces more predictable scoring behavior.

Therefore:

```text
Generative AI
       +
Deterministic Rules
       ↓
Hybrid Analysis
```

This is an important project design decision.

---

# 17. Stage 4 — Store Results

The final stage persists processing results.

Conceptually:

```text
Extracted Data
      +
AI Findings
      +
Risk Information
      ↓
Store Results Lambda
      ↓
S3 + DynamoDB
```

This gives the frontend something persistent to retrieve later.

Without persistence:

```text
Workflow completes
 ↓
Result disappears
```

With persistence:

```text
Workflow completes
 ↓
Result stored
 ↓
Frontend retrieves later
```

---

# 18. Complete Workflow

Now combine all four major stages:

```text
Trigger Lambda
      ↓
START WORKFLOW
      ↓
┌─────────────────────────┐
│ 1. PROCESS DOCUMENT     │
│                         │
│ Lambda → Textract       │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│ 2. AI ANALYSIS          │
│                         │
│ Lambda → Bedrock        │
│          Nova Micro     │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│ 3. RISK RULES           │
│                         │
│ Deterministic Python    │
└───────────┬─────────────┘
            ↓
┌─────────────────────────┐
│ 4. STORE RESULTS        │
│                         │
│ S3 + DynamoDB           │
└───────────┬─────────────┘
            ↓
          END
```

This is the workflow backbone you need to remember.

---

# 19. Why Did Our Architecture Diagram Show Five Boxes?

Your earlier architecture visualization showed something like:

```text
Validate & Prepare
 ↓
Extract with Textract
 ↓
Analyze with Bedrock
 ↓
Apply Business Rules
 ↓
Store Results
```

That's useful for **learning the internal flow**.

But the Codex analysis identifies the implemented state machine in terms of **four main processing stages**.

Therefore don't automatically tell an interviewer:

> “My Step Functions state machine has exactly five independently implemented task states.”

Instead:

> “The main workflow has four processing stages. Within document processing, I conceptually separate preparation and Textract extraction when explaining the flow.”

That keeps the diagram useful without contradicting repository evidence.

---

# 20. Sequential Processing

The main workflow is logically sequential:

```text
A
↓
B
↓
C
↓
D
```

Why?

Because later stages depend on earlier results.

For example:

```text
Bedrock analysis
```

needs extracted invoice information.

And:

```text
Risk rules
```

need the relevant analysis/input.

This isn't a good candidate for blindly running every stage simultaneously.

---

# 21. Could Anything Run in Parallel?

Potentially, a future architecture could parallelize independent work.

But you should not claim:

> “My current workflow uses parallel states”

unless the repository actually shows that.

The current learning model should remain:

```text
Process
 ↓
Analyze
 ↓
Score
 ↓
Store
```

We distinguish **current implementation** from **possible optimization**.

---

# 22. What Happens If a State Fails?

Imagine:

```text
Process Document
      ↓
SUCCESS
      ↓
AI Analysis
      ↓
FAIL
```

The workflow needs defined error behavior.

Possible workflow mechanisms can include:

```text
Retry

Catch

Fail

Fallback
```

But exact behavior must come from the project's state-machine definition.

Do not tell an interviewer:

> “Every state retries exactly three times.”

unless the actual CDK/state-machine definition proves that.

---

# 23. Retry at Different Layers

Remember File 07?

We already had:

```text
SQS
 ↓
Trigger Lambda
```

with message retry behavior.

Now we're inside:

```text
Step Functions
```

These are different failure boundaries.

```text
SQS retry
=
retry consuming/starting work
```

while:

```text
Step Functions retry
=
retry a processing state
```

This distinction matters.

---

# 24. Why Too Many Retry Layers Can Be Dangerous

Imagine:

```text
SQS retries
      ↓
Workflow starts again

AND

Step Functions retries
      ↓
Bedrock invocation retries
```

Poorly designed retry policies can multiply work.

Conceptually:

```text
Retry
 ×
Retry
 ×
Retry
=
Potential retry amplification
```

That can affect:

```text
Cost

Latency

Duplicate side effects

Service throttling
```

So retries should be deliberate.

---

# 25. Workflow Status vs Business Job Status

This is one of the most important concepts in your project.

There are potentially two different views of status.

## Step Functions execution status

This describes the technical workflow execution.

Conceptually:

```text
RUNNING

SUCCEEDED

FAILED
```

## Application job status

Your application stores business-facing processing state.

Conceptually:

```text
PENDING

PROCESSING

COMPLETED

FAILED
```

These are related, but they are **not automatically the same thing**.

---

# 26. Example

Suppose:

```text
Step Functions
      ↓
AI stage encounters a problem
```

The application may have fallback/error behavior.

Depending on how the workflow/application logic handles it, the business record could still end up:

```text
COMPLETED
```

even though:

```text
AI analysis did not succeed normally
```

This is why:

> **Business status must have clearly defined semantics.**

---

# 27. Important Codex Finding

The Codex analysis found an especially important behavior:

> **An AI failure can still result in the business job becoming `COMPLETED`.** :chatgpt-content-reference{index="0"}

Therefore:

```text
COMPLETED
```

currently does **not necessarily mean**:

```text
Textract succeeded
+
Bedrock succeeded normally
+
Rules succeeded
+
Every expected result is healthy
```

This is a very good interview discussion point because it demonstrates that you understand a real limitation instead of only describing the happy path.

---

# 28. Why Is That Potentially Confusing?

Imagine the frontend shows:

```text
Status: COMPLETED
```

The user may reasonably interpret that as:

> “Everything succeeded.”

But internally:

```text
OCR          ✓

AI           ✗ / degraded

Rules        maybe continued

Persistence  ✓
```

The word `COMPLETED` may hide important degradation.

---

# 29. Better Production Status Model

A production design could make status more explicit.

For example:

```text
PENDING

PROCESSING

COMPLETED

COMPLETED_WITH_WARNINGS

FAILED
```

or store separate component information:

```text
job_status = COMPLETED

ocr_status = SUCCESS

ai_status = FAILED

risk_status = DEGRADED
```

The exact model depends on requirements.

This is a **production improvement**, not the current implementation.

---

# 30. Why Not Let Step Functions Status Be the Only Status?

Because your frontend and business application may need domain-specific information.

Step Functions understands:

```text
workflow execution
```

Your application understands:

```text
invoice processing job
```

The application may need:

```text
invoice_id

user/tenant

processing stage

business error

risk result

timestamps
```

So maintaining a business job record can still be useful.

The problem isn't having two status systems.

The problem is:

> **Their meaning must be consistent and clearly defined.**

---

# 31. Workflow Input and Output Size

Another design concept to understand:

Don't think of Step Functions as your permanent database.

The workflow should coordinate processing data, while persistent data belongs in services designed for storage.

Conceptually:

```text
Step Functions
=
workflow state/context
```

```text
S3
=
documents/artifacts
```

```text
DynamoDB
=
application/job records
```

This separation is important.

---

# 32. Don't Pass Huge Documents Through the Workflow

Your original invoice is already in:

```text
S3
```

So instead of moving huge document bytes through every workflow stage:

```text
PDF bytes
 ↓
State A
 ↓
State B
 ↓
State C
```

a better architectural model is:

```text
S3 object reference
       ↓
Workflow
       ↓
Components access
required data
```

For large intermediate artifacts, S3 can similarly be preferable to bloating workflow state.

The exact project's payload strategy should always be verified from code.

---

# 33. Step Functions vs SQS

Another common interview question:

> “If you already have SQS, why do you need Step Functions?”

Because they solve different problems.

## SQS

```text
Who is waiting to be processed?
```

It provides:

```text
Queueing
Buffering
Decoupling
Retry delivery
```

## Step Functions

```text
What processing stage happens next?
```

It provides:

```text
Workflow orchestration
State transitions
Task coordination
Workflow-level error handling
```

So:

```text
SQS
=
before/at workflow ingestion
```

while:

```text
Step Functions
=
inside processing coordination
```

---

# 34. SQS + Step Functions Together

Your architecture uses both:

```text
Uploads
   ↓
SQS
   ↓
Trigger Lambda
   ↓
Step Functions
   ↓
Task A
   ↓
Task B
   ↓
Task C
   ↓
Task D
```

Think:

> **SQS absorbs and delivers work. Step Functions coordinates that work once processing starts.**

---

# 35. Step Functions vs EventBridge

Also different:

```text
Step Functions
=
orchestrate a defined workflow
```

```text
EventBridge
=
route events between producers and consumers
```

In this project:

```text
Step Functions
```

coordinates invoice processing.

The EventBridge/SNS architecture is associated with the intended high-risk notification path.

Don't mix their responsibilities.

---

# 36. Step Functions vs Lambda Chaining

Without Step Functions, you could imagine:

```text
Lambda A
 ↓
directly invokes Lambda B
 ↓
directly invokes Lambda C
 ↓
directly invokes Lambda D
```

But then workflow coordination becomes embedded inside application functions.

With Step Functions:

```text
             Step Functions
             /     |     \
            ↓      ↓      ↓
         Lambda  Lambda  Lambda
```

The orchestration becomes more explicit.

That's a major architectural benefit.

---

# 37. Troubleshooting — Workflow Failed

Suppose:

> **Invoice uploaded successfully, but processing failed.**

Now we know:

```text
S3 ✓
SQS ✓
Trigger Lambda ✓
Step Functions started ✓
```

So inspect the workflow.

Ask:

```text
Which state failed?
       ↓
What input did it receive?
       ↓
What error did it produce?
       ↓
Did retry happen?
       ↓
Was the error handled?
       ↓
What did the corresponding Lambda log?
```

This dramatically narrows troubleshooting.

---

# 38. Example Troubleshooting Path

Suppose execution shows:

```text
Process Document   ✓

AI Analysis        ✗

Risk Rules         -

Store Results      -
```

Then you probably don't start debugging:

```text
Cognito
```

or:

```text
presigned S3 upload
```

Those already worked.

Instead inspect:

```text
AI Analysis Lambda
       ↓
CloudWatch logs
       ↓
Bedrock request
       ↓
Model response/error
       ↓
IAM permission
       ↓
Payload/validation
```

This is why Step Functions provides useful operational visibility into multi-stage workflows.

---

# 39. Another Scenario

Suppose:

```text
Process Document ✓

AI Analysis      ✓

Risk Rules       ✓

Store Results    ✗
```

The problem is probably much closer to:

```text
Persistence

DynamoDB

S3 result storage

IAM

Data serialization
```

rather than Textract.

Again:

> **Follow the execution path instead of guessing.**

---

# 40. Current Workflow Strengths

At a high level, the architecture gives you:

```text
✓ Explicit processing sequence

✓ Separation of processing responsibilities

✓ Serverless orchestration

✓ Observable workflow stages

✓ Integration with Lambda-based processing

✓ Ability to define workflow error behavior

✓ Separation between ingestion and processing
```

These are useful architectural properties.

---

# 41. Current Workflow Risks / Limitations

From our Codex analysis and previous files, important concerns include:

```text
⚠ Duplicate workflow startup/idempotency

⚠ Business status can hide AI degradation

⚠ Retry behavior needs careful reasoning

⚠ Exactly-once processing must not be claimed

⚠ Workflow status and business status
  need clear semantics
```

:chatgpt-content-reference{index="1"}

These limitations are not something to hide.

They become useful architecture discussion points.

---

# 42. Production Improvement Model

A stronger conceptual workflow might be:

```text
SQS
 ↓
Atomic Idempotency Claim
 ↓
Start Workflow
 ↓
Validate Document
 ↓
Extract Invoice
 ↓
Validate Extraction
 ↓
AI Analysis
 ↓
Validate AI Output
 ↓
Apply Risk Rules
 ↓
Persist Results
 ↓
Publish Event
 ↓
Set Explicit Final Status
```

With clearly defined error paths:

```text
Transient error
 ↓
Controlled retry
```

```text
Permanent error
 ↓
FAILED
```

```text
AI degraded
 ↓
COMPLETED_WITH_WARNINGS
```

Again, this is a **production improvement model**, not a claim about today's implementation.

---

# 43. Why This Matters for Interviews

A weak answer is:

> “I used Step Functions because it is an AWS service for workflows.”

A stronger answer is:

> “My invoice-processing pipeline has multiple dependent stages: document extraction, AI analysis, deterministic risk calculation and result persistence. I use Step Functions to make that orchestration explicit instead of embedding the complete sequence inside one Lambda or manually chaining functions. It gives the workflow defined state transitions and a clearer place to handle retries and failures.”

That connects:

```text
AWS concept
+
actual project
+
architecture decision
```

---

# 44. Interview Preparation — 10 Questions

## Q1 — What is AWS Step Functions?

**Difficulty:** Basic

### Word-by-word practice answer

> “AWS Step Functions is a serverless workflow orchestration service. In my project, I use it to coordinate the multi-stage invoice-processing pipeline. The individual Lambda functions perform specific tasks, while Step Functions controls the sequence and movement between those tasks.”

---

# Q2 — Why did you use Step Functions in this project?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “Invoice processing contains several dependent stages. The document must first be processed and extracted, then the extracted information can be analyzed using Bedrock, then deterministic risk rules can run, and finally the result can be stored. Step Functions gives me an explicit orchestration layer for that sequence instead of putting all of the workflow coordination inside one large Lambda.”

---

# Q3 — Explain your Step Functions workflow.

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The trigger Lambda starts the invoice-processing state machine with the invoice and document context. The main workflow has four processing stages. First, the document-processing stage uses Textract to obtain invoice information. Second, the AI-analysis stage uses Amazon Bedrock with Nova Micro to generate findings. Third, deterministic Python business rules calculate the risk information. Finally, the storage stage persists the results to the application's storage layer so they can later be retrieved by the frontend.”

---

# Q4 — What is the difference between Lambda and Step Functions?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Lambda executes application code, while Step Functions orchestrates the workflow between multiple tasks. For example, a Lambda can call Textract or calculate a risk score, but Step Functions determines when that task should run and what processing stage comes next. I use Lambda for execution and Step Functions for coordination.”

---

# Q5 — Why do you need both SQS and Step Functions?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “They solve different problems. SQS decouples invoice ingestion from processing and buffers incoming work. Once a message is consumed, the trigger Lambda starts Step Functions. Step Functions then coordinates the internal processing stages for that invoice. So SQS manages queued work before processing, while Step Functions manages the workflow after processing begins.”

---

# Q6 — Why didn't you put the entire workflow in one Lambda?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The pipeline has several distinct responsibilities, including document extraction, Generative AI analysis, deterministic business rules and persistence. Putting everything into one function would tightly couple those responsibilities and make workflow-level failure handling and troubleshooting harder. Step Functions keeps the orchestration explicit while the Lambda functions remain focused on their processing responsibilities.”

---

# Q7 — What happens if one workflow stage fails?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The exact behavior depends on the retry and error-handling configuration of that state, so I would verify the state-machine definition rather than claim a generic retry count. Operationally, I use the workflow execution to identify the failed state and then inspect the corresponding Lambda and CloudWatch logs. I also distinguish a technical workflow failure from the application's business job status because they are not necessarily identical.”

This answer avoids inventing retry settings.

---

# Q8 — Does `COMPLETED` mean every stage succeeded normally?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “Not necessarily in the current implementation. One important finding from my local project review is that an AI failure can still result in the business job being marked as completed. Because of that, I would not interpret the current `COMPLETED` status as proof that every processing stage succeeded normally. For production, I would make degraded processing explicit through clearer status semantics or separate component-level statuses.”

:chatgpt-content-reference{index="2"}

---

# Q9 — How would you troubleshoot a failed Step Functions execution?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I would first identify the last successful state and the state that failed. Then I would inspect the failed state's input, output and error information and correlate that with the corresponding Lambda logs in CloudWatch. From there, I would check the relevant downstream dependency, such as Textract, Bedrock, DynamoDB or S3, along with IAM permissions and request data. I would troubleshoot from the failed boundary rather than restarting from the beginning of the architecture.”

---

# Q10 — How would you improve the workflow for production?

**Difficulty:** Advanced / Design

### Word-by-word practice answer

> “I would first strengthen idempotency before workflow startup so duplicate SQS deliveries cannot easily create duplicate processing. Inside the workflow, I would define deliberate retry and failure policies based on whether an error is transient or permanent. I would also validate important intermediate outputs, make AI degradation explicit instead of hiding it behind a generic completed status, keep business job state consistent with workflow outcomes, and add monitoring around workflow failures, latency and downstream service errors.”

---

# 45. Interview Pressure Chain

An interviewer may begin with:

> **“Why Step Functions?”**

and continue:

```text
Why Step Functions?
      ↓
What is orchestration?
      ↓
What is a state machine?
      ↓
What starts your workflow?
      ↓
What input does it receive?
      ↓
How many main processing stages?
      ↓
What happens in stage 1?
      ↓
Why Textract before Bedrock?
      ↓
Why separate risk rules?
      ↓
Why not one Lambda?
      ↓
Why SQS AND Step Functions?
      ↓
What happens when a state fails?
      ↓
How do retries work?
      ↓
Can duplicate workflows happen?
      ↓
How would you prevent that?
      ↓
Workflow status vs job status?
      ↓
Does COMPLETED mean AI succeeded?
      ↓
How would you improve that?
```

That's the depth we eventually want you to handle confidently.

---

# 46. What You Should Remember

Don't memorize the entire file.

Remember this:

```text
SQS
 ↓
Trigger Lambda
 ↓
STEP FUNCTIONS
 ↓
1. Process Document
   └── Textract
 ↓
2. AI Analysis
   └── Bedrock Nova Micro
 ↓
3. Risk Rules
   └── Deterministic Python
 ↓
4. Store Results
   └── S3 + DynamoDB
```

And remember the responsibility:

```text
Lambda
=
DO the task
```

```text
Step Functions
=
COORDINATE the tasks
```

And the project-specific warning:

```text
COMPLETED
≠
guarantee that every internal
stage succeeded normally
```

because the local analysis found that an AI failure can still result in the business job being marked `COMPLETED`. :chatgpt-content-reference{index="3"}

---

# 47. Check Your Understanding

Before starting **`09-Textract-OCR-and-Invoice-Extraction.md`**, answer these three questions in your own words:

**Question 1:** Why does this project need **Step Functions if it already has Lambda functions?**

**Question 2:** Explain the four main processing stages from **document processing → final storage** without looking above.

**Question 3:** Suppose the Step Functions execution technically reaches the end, but the Bedrock AI stage had degraded/fallback behavior. Why could simply showing **`COMPLETED`** to the user be misleading?