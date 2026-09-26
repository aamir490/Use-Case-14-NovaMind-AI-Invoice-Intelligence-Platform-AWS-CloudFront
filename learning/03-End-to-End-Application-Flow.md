# Your question

**Start `03-End-to-End-Application-Flow.md`.**

For File 02, we learned **what components exist in the architecture**.

Now File 03 answers a different question:

> **What exactly happens, step by step, when a real user uploads an invoice until the final result appears on the screen?**

Save the diagram we just created as:

```text
learning/images/end_to_end_application_flow.png
```

Then add this near the beginning:


![NovaMind AI - End-to-End Application Flow](images\end-to-end.png)

**Figure: NovaMind AI Invoice Intelligence Platform — End-to-End Application Flow | Built by Aamir**


---

# 03 — End-to-End Application Flow

## 1. What Will I Learn?

In this file, I will understand:

- What happens when a user opens the application
- How authentication happens
- How the frontend requests an upload URL
- Why the invoice goes directly to S3
- How an S3 upload starts asynchronous processing
- How SQS and the trigger Lambda participate
- How Step Functions coordinates processing
- How Textract extracts invoice information
- How Bedrock Nova Micro analyzes that information
- How deterministic Python rules calculate risk information
- Where results are stored
- How the frontend knows processing has completed
- How the user finally sees the result
- What happens when something fails
- How to explain the entire flow in an interview

The Codex report identifies the main flow as authentication → presigned upload → S3 → SQS → workflow launch → Textract → Bedrock → deterministic rules → persistence → frontend reads. :chatgpt-content-reference{index="0"}

---

# 2. End-to-End Application Flow Diagram

![NovaMind AI - End-to-End Application Flow](images\end-to-end.png)

**Figure: NovaMind AI Invoice Intelligence Platform — End-to-End Application Flow | Built by Aamir**

For learning, we can think about the project as approximately ten stages:

```text
1. User Login
       ↓
2. Request Upload URL
       ↓
3. Upload Invoice to S3
       ↓
4. S3 Event → SQS
       ↓
5. SQS → Trigger Lambda
       ↓
6. Step Functions Processing
       ↓
7. Store Results
       ↓
8. Notification Path (where applicable)
       ↓
9. Frontend Fetches Results
       ↓
10. User Views Result
```

One important accuracy note: the diagram is a **learning visualization**. When its visual grouping differs from the inspected code, the Codex/local repository analysis remains our primary source.

---

# 3. Start With One Example

Suppose a user has this invoice:

```text
Vendor: ABC Technologies
Invoice Number: INV-1045
Date: 20-09-2026

Laptop       ₹70,000
Monitor      ₹20,000
Keyboard      ₹5,000

Total        ₹95,000
```

The user wants NovaMind AI to analyze this invoice.

We'll follow this single invoice through the complete system.

---

# 4. Step 1 — User Opens the React Application

The process starts in the browser.

```text
User
 ↓
CloudFront
 ↓
React Application
```

The frontend is built using React.

The user can perform actions such as:

```text
Login
Upload invoice
Check processing status
View invoices
View findings
View analytics
Delete invoices
```

But the React application itself does **not** perform OCR or Generative AI processing.

It acts as the user interface.

---

# 5. Step 2 — User Authentication

Before accessing protected functionality, the user authenticates using Amazon Cognito.

Simplified:

```text
User
 ↓
Login credentials
 ↓
Amazon Cognito
 ↓
Authentication token
 ↓
React application
```

The frontend can then use authentication information when calling protected APIs.

At this stage, remember:

> **Cognito answers who the user is.**

The deeper authorization and tenant-isolation behavior belongs in File 05.

Codex specifically warns that current tenant isolation should not be described as complete isolation. :chatgpt-content-reference{index="1"}

---

# 6. Step 3 — User Selects an Invoice

Suppose the user selects:

```text
INV-1045.pdf
```

A common misunderstanding would be:

```text
React
 ↓
Send entire PDF to Lambda
 ↓
Lambda sends PDF to S3
```

That is **not the main upload design used here**.

Instead, the application uses a presigned S3 upload.

---

# 7. Step 4 — Frontend Requests a Presigned URL

The frontend first asks the backend for permission to upload the file.

Conceptually:

```text
React
 ↓
API request
 ↓
API Gateway
 ↓
Lambda
 ↓
Generate presigned S3 URL
 ↓
Return URL to React
```

The returned URL is temporary.

Think of it as:

> **Temporary permission to upload a specific object to S3.**

---

# 8. Why Doesn't the Backend Upload the File?

Without direct upload:

```text
Browser
 ↓
API Gateway
 ↓
Lambda
 ↓
S3
```

The backend unnecessarily sits in the file-transfer path.

With a presigned URL:

```text
Browser ───────────────→ S3
        direct upload
```

The backend only authorizes the upload.

This separates:

```text
CONTROL

Who can upload?
Where can they upload?
For how long?
```

from:

```text
DATA TRANSFER

Actually sending the PDF/image bytes
```

That is an important architecture concept.

---

# 9. Step 5 — Invoice Uploads Directly to S3

Now the browser uploads:

```text
INV-1045.pdf
```

directly to the invoice S3 bucket.

```text
React
   │
   │ Presigned PUT
   ▼
Amazon S3
   │
   └── INV-1045.pdf
```

At this point:

**the file has been uploaded**

but:

**the complete analysis is not finished.**

This is where the asynchronous part of the system becomes important.

---

# 10. Step 6 — S3 Produces an Event

When the object is created, an S3 object-created event is generated.

Conceptually:

```text
INV-1045.pdf
      ↓
Stored in S3
      ↓
ObjectCreated Event
```

The event contains information needed to locate the uploaded object.

For example, conceptually:

```text
Bucket
Object key
Event information
```

The system can now begin processing without the frontend directly starting every processing stage itself.

---

# 11. Step 7 — Event Reaches SQS

The upload event leads to a message being placed in the invoice-processing queue.

```text
S3
 ↓
S3 event
 ↓
SQS
```

SQS now acts as a buffer.

Think of SQS like a waiting line:

```text
┌────────────────────┐
│ Invoice 1 message  │
│ Invoice 2 message  │
│ Invoice 3 message  │
│ Invoice 4 message  │
└─────────┬──────────┘
          ↓
      Processing
```

This separates:

**uploading**

from

**processing**.

---

# 12. Why Is This Important?

Imagine 100 invoices arrive around the same time.

Without asynchronous decoupling, the upload request and processing workload can become tightly connected.

With SQS:

```text
Uploads
 ↓ ↓ ↓ ↓ ↓

SQS
 ↓

Consumers process messages
```

This provides buffering and retry behavior.

But remember:

> **SQS does not mean exactly-once processing.**

Messages can be delivered more than once.

That is why idempotency becomes important later.

Codex specifically warns against claiming exactly-once behavior for this project. :chatgpt-content-reference{index="2"}

---

# 13. Step 8 — SQS Invokes the Trigger Lambda

The SQS message is consumed by a Lambda function.

```text
SQS
 ↓
Trigger Lambda
```

This Lambda receives information about the uploaded invoice.

Its main responsibility is to move the invoice into the processing workflow.

Conceptually:

```text
Read SQS message
       ↓
Identify S3 invoice
       ↓
Create/start processing job
       ↓
Start Step Functions execution
```

The trigger Lambda does **not** need to perform the entire OCR + AI + rules workflow itself.

---

# 14. Step 9 — Step Functions Workflow Starts

Now AWS Step Functions becomes the orchestrator.

```text
Trigger Lambda
      ↓
Step Functions
      ↓
Invoice processing workflow
```

Think of Step Functions as the **workflow manager**.

It determines:

> Which processing stage runs next?

The core processing responsibilities identified by Codex are:

```text
Document processing / extraction
        ↓
AI analysis
        ↓
Risk calculation
        ↓
Result storage
```

Codex describes the actual workflow as four main processing stages. :chatgpt-content-reference{index="3"}

Our visual diagram separates preparation/validation to make the flow easier to understand, but you should not turn that visual grouping into a false claim about an additional independently verified workflow state.

---

# 15. Step 10 — Document Processing

The processing stage first needs information about the document.

Conceptually:

```text
S3 object
 ↓
Processing Lambda
 ↓
Validate/prepare document
 ↓
Call Textract
```

Responsibilities may include preparing the document information needed for extraction and passing the correct S3 object details forward.

The important concept is:

> **The workflow knows which uploaded document should be processed.**

---

# 16. Step 11 — Amazon Textract Extracts Invoice Information

Now we reach OCR/document intelligence.

```text
Invoice
 ↓
Amazon Textract
 ↓
Extracted invoice information
```

Textract can extract information such as:

```text
Vendor
Invoice number
Date
Amounts
Line items
Total
Raw text
```

For our example:

```text
INV-1045.pdf
        ↓
Textract
        ↓
Vendor: ABC Technologies
Invoice: INV-1045
Date: 20-09-2026
Total: ₹95,000
...
```

This converts the invoice from a document into information the application can process.

---

# 17. Important: Textract Is Not Bedrock

Do not say:

> “Bedrock extracts my PDF.”

For this project's main flow:

```text
DOCUMENT READING / EXTRACTION
        =
     TEXTRACT
```

while:

```text
GENERATIVE AI ANALYSIS
        =
BEDROCK NOVA MICRO
```

This distinction is one of the most important things to remember.

---

# 18. Step 12 — Extracted Information Goes to Bedrock

After extraction, relevant invoice information is used to construct the AI request.

Conceptually:

```text
Textract output
      ↓
Extracted invoice information
      ↓
Prompt/context
      ↓
Amazon Bedrock
      ↓
Nova Micro
```

Bedrock provides access to the foundation model.

The model used in this implementation is:

**Amazon Nova Micro.**

Codex identifies Nova Micro as the project's Generative AI model. :chatgpt-content-reference{index="4"}

---

# 19. Step 13 — Nova Micro Analyzes the Invoice

The LLM analyzes the extracted information.

It can produce findings about potentially suspicious or unusual information.

Conceptually:

```text
Extracted invoice
       ↓
Nova Micro
       ↓
AI analysis
       ↓
Possible findings
```

For example, conceptually:

```text
Possible unusual amount
Missing information
Formatting inconsistency
Other anomaly findings
```

Important:

> These are AI-generated findings.

They are not automatically proven facts.

---

# 20. Step 14 — Python Deterministic Rules Run

Now the project applies deterministic business/risk rules.

```text
Extracted invoice information
            +
AI findings
            ↓
Python rules
            ↓
Risk score
            ↓
Risk classification
```

For example:

```text
Risk Score: 65 / 100
Risk Level: MEDIUM
```

The exact scoring logic will be studied later in:

**`12-Risk-Scoring-and-Financial-Rules.md`**

For now remember:

> **The final numeric score comes from deterministic application logic, not simply from asking Nova Micro to invent a number.**

Codex explicitly identifies deterministic rules as producing the final numeric score. :chatgpt-content-reference{index="5"}

---

# 21. Why Combine AI With Rules?

This is an important design idea.

An LLM is useful for:

```text
Language understanding
Contextual analysis
Generating findings
Identifying possible anomalies
```

Deterministic code is useful for:

```text
Known calculations
Thresholds
Fixed validation
Repeatable scoring logic
```

So conceptually:

```text
            Invoice
               ↓
       ┌───────┴────────┐
       ↓                ↓
 AI reasoning      Fixed checks
       ↓                ↓
  Bedrock          Python rules
       └───────┬────────┘
               ↓
          Final result
```

This gives the project a **hybrid approach**.

---

# 22. Step 15 — Results Are Stored

After processing, results need to persist.

The architecture uses:

```text
S3
+
DynamoDB
```

At a high level:

### S3

Object/file-oriented storage.

Examples:

```text
Original invoice
Extracted artifacts/text
Other generated files
```

### DynamoDB

Application records.

Examples:

```text
Invoice metadata
Processing status
Job information
Risk score
Findings
Timestamps
```

Codex confirms DynamoDB stores invoice/results and job records. :chatgpt-content-reference{index="6"}

---

# 23. Step 16 — Processing Status Changes

The application needs to know whether an invoice is:

```text
Waiting
Processing
Completed
Failed
```

The repository maintains processing/job information.

This matters because the original upload request is already finished.

The browser isn't continuously connected to Step Functions waiting for a response.

---

# 24. Step 17 — What Happens With High-Risk Results?

The architecture includes an event/notification design involving:

```text
High-risk result
      ↓
EventBridge
      ↓
SNS
      ↓
Notification
```

However, the Codex analysis found the notification path incomplete or unverified.

So:

### Architecture intention

```text
HIGH risk
 ↓
Event
 ↓
SNS
 ↓
Email notification
```

### What you should claim carefully

> “The repository contains EventBridge and SNS infrastructure intended for high-risk notifications, but I would not claim confirmed end-to-end email delivery because the local analysis found the wiring incomplete or unverified.”

This distinction is interview-important. :chatgpt-content-reference{index="7"}

---

# 25. Step 18 — Frontend Checks Processing Status

Meanwhile, the frontend needs to know when processing finishes.

The current design uses **polling**.

Polling simply means:

```text
Frontend:
"Finished?"
     ↓
Backend:
"No."

Wait...

Frontend:
"Finished?"
     ↓
Backend:
"No."

Wait...

Frontend:
"Finished?"
     ↓
Backend:
"Yes."
```

Technically:

```text
React
 ↓
API Gateway
 ↓
Status API
 ↓
DynamoDB/job information
 ↓
Response
```

The frontend repeats this periodically.

---

# 26. Why Poll Instead of Keeping the Original Request Open?

Because invoice processing is asynchronous and may take longer than a normal lightweight API operation.

Instead of:

```text
Upload
 ↓
HTTP request waits...
 ↓
OCR waits...
 ↓
AI waits...
 ↓
Rules wait...
 ↓
Finally respond
```

the architecture behaves more like:

```text
Upload accepted
 ↓
Background processing
 ↓
Frontend checks status
 ↓
Fetch result when ready
```

This separates the user-facing request from the longer processing pipeline.

---

# 27. Step 19 — Frontend Fetches Invoice Result

Once the status indicates completion, the frontend retrieves the invoice details.

Conceptually:

```text
React
 ↓
API Gateway
 ↓
Backend Lambda
 ↓
DynamoDB / S3
 ↓
Result
 ↓
React
```

The result may contain:

```text
Extracted invoice data
AI findings
Risk score
Risk level
Processing information
```

---

# 28. Step 20 — User Sees Final Result

The final result appears in the React interface.

For our example:

```text
Invoice: INV-1045

Vendor:
ABC Technologies

Total:
₹95,000

Risk Score:
65 / 100

Risk Level:
MEDIUM

AI Findings:
- Finding 1
- Finding 2
- Finding 3
```

Remember that this is an illustrative example.

It is not evidence that the actual system will assign `65/100` to that invoice.

---

# 29. Complete Flow in One Diagram

Now compress everything:

```text
USER
 │
 ▼
React Application
 │
 ▼
Cognito Authentication
 │
 ▼
Request Presigned URL
 │
 ▼
API Gateway → Lambda
 │
 ▼
Presigned URL returned
 │
 ▼
Browser uploads invoice
 │
 ▼
S3
 │
 ▼
Object-created event
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
 │       ↓
 │   Extract invoice
 │
 ├── Bedrock Nova Micro
 │       ↓
 │   Generate findings
 │
 ├── Python Rules
 │       ↓
 │   Calculate risk
 │
 └── Store Results
         ↓
   S3 + DynamoDB
         │
         ▼
Frontend polls status
         │
         ▼
Fetch results
         │
         ▼
USER SEES RESULT
```

That is the flow you eventually need to explain confidently.

---

# 30. Synchronous vs Asynchronous Parts

This is a very useful concept.

## Synchronous

The user asks for something and waits for that immediate response.

Example:

```text
React
 ↓
Request presigned URL
 ↓
API
 ↓
Return URL
```

## Asynchronous

Work continues separately after the original operation.

Example:

```text
Upload invoice
 ↓
S3
 ↓
SQS
 ↓
Lambda
 ↓
Step Functions
 ↓
OCR / AI / Rules
```

So your project contains **both synchronous and asynchronous interactions**.

---

# 31. Where Can the Flow Fail?

Almost every boundary can fail.

```text
Login
 ↓
Cognito failure

Upload URL
 ↓
API/Lambda failure

Upload
 ↓
S3 failure

Queue
 ↓
SQS/message failure

Workflow
 ↓
Step Functions failure

OCR
 ↓
Textract failure

AI
 ↓
Bedrock failure

Rules
 ↓
Application logic failure

Storage
 ↓
DynamoDB/S3 failure

Frontend
 ↓
Polling/cache/API problem
```

This is why understanding the flow is so important for troubleshooting.

If you don't know:

> **Where the invoice currently is**

you cannot efficiently troubleshoot the system.

---

# 32. Important Failure Behavior

One particularly important Codex finding is:

> **AI failure can still result in the business job becoming `COMPLETED`.**

:chatgpt-content-reference{index="8"}

That means:

```text
COMPLETED
```

does not necessarily mean:

```text
Every AI operation succeeded perfectly.
```

This distinction will become important when we study:

**AI validation**

and

**reliability/troubleshooting**.

---

# 33. Workflow Status vs Business Status

This is another subtle but valuable concept.

There can be:

**technical workflow state**

and

**application/business job state**.

For example:

```text
Step Functions execution
```

has its own technical execution information.

Your application may separately store:

```text
PROCESSING
COMPLETED
FAILED
```

for a job.

These two concepts should not automatically be treated as identical.

Codex specifically highlights the importance of distinguishing workflow status from business status. :chatgpt-content-reference{index="9"}

---

# 34. The Most Important Flow to Remember

If an interviewer suddenly asks:

> **“What happens after I upload an invoice?”**

Your brain should immediately see:

```text
Upload
 ↓
S3
 ↓
SQS
 ↓
Lambda
 ↓
Step Functions
 ↓
Textract
 ↓
Bedrock
 ↓
Rules
 ↓
DynamoDB/S3
 ↓
Frontend
```

Don't start with a five-minute explanation.

First give them the backbone.

Then expand whichever component they ask about.

---

# 35. Interview Preparation — 10 Questions

## Q1 — Walk me through the complete invoice-processing flow.

**Difficulty:** Basic

### Word-by-word practice answer

> “The user first authenticates through Cognito and selects an invoice in the React application. The frontend requests a presigned upload URL through the backend and then uploads the invoice directly to S3. The S3 upload creates an event that leads to a message in SQS. An SQS-triggered Lambda reads the message and starts the Step Functions workflow. The workflow coordinates invoice extraction using Textract, Generative AI analysis using Bedrock Nova Micro, deterministic Python risk rules, and result persistence. The results are stored in S3 and DynamoDB. Because processing is asynchronous, the frontend checks the processing status and retrieves the final invoice result when it becomes available.”

---

# Q2 — What happens immediately after the user selects an invoice?

**Difficulty:** Basic

### Word-by-word practice answer

> “The frontend does not immediately send the entire invoice through the backend. It first calls the backend to request a temporary presigned S3 URL. After receiving that URL, the browser uploads the invoice directly to the invoice S3 bucket.”

---

# Q3 — What happens after the invoice reaches S3?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “After the invoice is stored in S3, an object-created event leads to a message being placed in the SQS invoice queue. SQS buffers the processing request. A Lambda function consumes the message and starts the Step Functions workflow for that invoice.”

---

# Q4 — Why is invoice processing asynchronous?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Invoice processing contains multiple potentially time-consuming operations, including document extraction and foundation-model inference. Instead of keeping the original upload request open while all of those operations run, the application accepts the upload and processes it asynchronously. SQS decouples ingestion from processing, and the frontend can check job status and retrieve the result when processing completes.”

---

# Q5 — What data goes from Textract to Bedrock?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Textract extracts text and structured invoice information such as vendor details, dates, amounts and line items. Relevant extracted information is then used to construct the request sent to Bedrock Nova Micro. The model analyzes that extracted invoice context and generates possible findings. The exact prompt construction and output parsing are separate implementation details that I would explain when discussing the Bedrock stage.”

Notice that this answer doesn't invent exact fields beyond what our evidence supports.

---

# Q6 — Does Bedrock calculate the final risk score?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Not by itself. Bedrock Nova Micro generates AI-based analysis and findings, but the final numeric risk score is produced by deterministic Python business rules. The system therefore combines Generative AI analysis with fixed application logic rather than allowing the language model alone to decide the final score.”

---

# Q7 — How does the frontend know processing has completed?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The processing is asynchronous, so the frontend does not wait on the original upload request. It polls the backend for processing status. Once the job is reported as completed, the frontend can retrieve the stored invoice details, findings and risk information and display them to the user.”

---

# Q8 — What happens if the same SQS message is delivered twice?

**Difficulty:** Advanced

### Word-by-word practice answer

> “SQS should be treated as an at-least-once delivery system, so duplicate delivery is possible. That means the application should make processing idempotent so processing the same logical job more than once does not create incorrect duplicate effects. The Codex analysis identified duplicate-processing and job-reset behavior as an area that needs improvement, so I would not claim the current implementation provides perfect exactly-once processing.”

---

# Q9 — What happens if Bedrock fails?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “The exact behavior depends on the application's error-handling path. One important finding from the local Codex analysis is that an AI failure can still result in the business job becoming completed, which means a completed status does not necessarily prove that the AI stage succeeded normally. For production, I would make degraded AI results explicit and ensure technical workflow state and business job state clearly represent what actually succeeded or failed.”

This answer is directly tied to a real project limitation. :chatgpt-content-reference{index="10"}

---

# Q10 — How would you troubleshoot an invoice that never shows a result?

**Difficulty:** Advanced / Scenario

### Word-by-word practice answer

> “I would troubleshoot the system in the same order as the end-to-end flow. First, I would confirm that the invoice was successfully uploaded to S3. Then I would check whether the expected queue message was created and whether the trigger Lambda consumed it. Next, I would inspect the Step Functions execution to identify the last successful or failed stage. Depending on the failure point, I would inspect the relevant Lambda, Textract, Bedrock or persistence logs in CloudWatch. I would also verify the job record in DynamoDB. If backend processing completed correctly, I would then investigate the API response, frontend polling and frontend cache or refresh behavior. This approach helps isolate the failed boundary instead of guessing.”

---

# 36. Interview Follow-Up Chain

This is how an interviewer can turn **one flow question into many questions**:

```text
Explain your application flow.
        ↓
Why presigned URL?
        ↓
Why direct S3 upload?
        ↓
What event happens next?
        ↓
Why SQS?
        ↓
Can SQS duplicate messages?
        ↓
How do you handle duplicates?
        ↓
Why Step Functions?
        ↓
Why Textract?
        ↓
Why Bedrock?
        ↓
Why not let the LLM calculate everything?
        ↓
Where do you store results?
        ↓
How does the frontend know processing finished?
        ↓
What happens when Bedrock fails?
        ↓
How would you troubleshoot it?
```

This is exactly why we are learning the project **one layer at a time** instead of memorizing one giant interview answer.

---

# 37. What You Should Understand From File 03

You don't need to memorize the paragraphs.

You need to understand this story:

> **The frontend authenticates the user and gets temporary permission to upload an invoice directly to S3. The S3 upload creates an asynchronous processing event. SQS buffers the work, a Lambda starts Step Functions, Textract extracts invoice information, Bedrock analyzes it, deterministic rules calculate risk information, the results are persisted, and the frontend later retrieves them.**

And especially understand these boundaries:

```text
React → API
API → S3
S3 → SQS
SQS → Lambda
Lambda → Step Functions
Step Functions → Textract
Textract → Bedrock
Bedrock → Rules
Rules → Storage
Storage → API
API → React
```

Those boundaries will later become your **troubleshooting map**.

---

# 38. Check Your Understanding

Before moving to `04-Technology-Stack-and-Codebase.md`, answer these **three questions without looking at the word-by-word answers**:

### Question 1

Explain the complete flow from:

**user selecting an invoice → final result appearing on screen.**

### Question 2

What is the difference between:

**Textract → Bedrock → Python Rules?**

Explain the responsibility of each one.

### Question 3

Suppose the invoice successfully reaches S3, but the user never receives a result.

**Where would you start checking, and what would you check next?**

Don't worry about perfect interview English yet. Write what you understand in your own words.