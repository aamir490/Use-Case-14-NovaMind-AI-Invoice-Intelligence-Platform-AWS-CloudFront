# Your question

**Start `01-Project-Overview.md`.**

Good. We will study **only File 01** now. We are **not moving to architecture, SQS, Step Functions, Textract, or Bedrock in depth yet**.

The goal of File 01 is simple:

> **You should understand what this project is, what problem it solves, what it actually does, and what you should and should not claim about it.**

Everything below is based primarily on the Codex analysis of your local project. Codex identifies NovaMind AI as an event-driven, serverless invoice-analysis application with a React frontend and Python AWS Lambda backend. :chatgpt-content-reference{index="0"}

---
## 3. Project Overview Diagram

![NovaMind AI Invoice Intelligence Platform - Project Overview](images\projec-overvew.png)

**Figure: NovaMind AI Invoice Intelligence Platform — Project Overview | Built by Aamir**

This diagram shows the complete project at a high level:

**User → React → Cognito/API → S3 → SQS → Step Functions → Textract → Bedrock Nova Micro → Python Rules → DynamoDB/S3 → Results Dashboard**

The purpose of this diagram is to understand the complete project before studying each component in detail.



# 01 — Project Overview

## 1. What is this project?

Your project is called:

**NovaMind AI Invoice Intelligence Platform**

In very simple English:

> It is a web application where a user uploads an invoice, and the system automatically extracts information from that invoice, analyzes it, calculates a risk score, and shows the results to the user.

For example, imagine a company receives this invoice:

```text
ABC Technologies

Invoice Number: INV-1045
Date: 20-09-2026

Laptop       ₹70,000
Monitor      ₹20,000
Keyboard     ₹5,000

Total:       ₹95,000
```

Instead of a finance employee manually reading every field, your system helps extract and analyze the invoice.

---

# 2. What problem does the project solve?

Companies can receive invoices as:

- PDF files
- scanned documents
- images

Those invoices contain useful information such as:

```text
Vendor
Invoice number
Invoice date
Line items
Subtotal
Tax
Total
```

But an invoice document itself is mostly **unstructured or semi-structured information** from the application's point of view.

A reviewer may need to:

```text
Open invoice
     ↓
Read information
     ↓
Check important values
     ↓
Look for suspicious information
     ↓
Decide which invoices require attention
```

Doing this manually becomes harder when there are many invoices.

Your project tries to automate part of this process.

The Codex report describes the purpose as converting invoice documents into **structured records and review signals**. :chatgpt-content-reference{index="1"}

---

# 3. Who would use this project?

According to the Codex analysis, likely users include:

**Finance staff**

**Accounts-payable teams**

**Invoice reviewers**

**Auditors**

**Small-business operators**

But there is an important interview distinction.

The repository suggests these are the **intended users**. It does not prove that real finance companies or customers currently use the application.

So don't say:

> “This application is currently being used by finance companies.”

unless you have independent evidence for that.

A safer explanation is:

> “The application is designed for finance or accounts-payable users who need to review invoices.”

Codex explicitly treats these users as inferred from the interface/workflow rather than evidence of a real customer base. :chatgpt-content-reference{index="2"}

---

# 4. What does the user actually do?

At a very high level:

```text
User
  ↓
Logs in
  ↓
Uploads invoice
  ↓
System processes invoice
  ↓
Extracts invoice information
  ↓
Analyzes the information
  ↓
Calculates review/risk information
  ↓
Stores result
  ↓
User views result
```

That's enough for File 01.

Later, in:

**`03-End-to-End-Application-Flow.md`**

we will understand every step technically.

---

# 5. What happens behind the scenes?

At a high level, your project uses this flow:

```text
React Web Application
        ↓
     Cognito
        ↓
   API Gateway
        ↓
Presigned S3 Upload
        ↓
       S3
        ↓
       SQS
        ↓
Trigger Lambda
        ↓
 Step Functions
        ↓
 ┌─────────────────────┐
 │ 1. Textract         │
 │ 2. Bedrock          │
 │ 3. Python Rules     │
 │ 4. Store Results    │
 └─────────────────────┘
        ↓
 S3 + DynamoDB
        ↓
      API
        ↓
React Dashboard
```

Codex confirms the primary processing path as authentication → presigned upload → S3 → SQS → workflow → Textract → Bedrock Nova Micro → deterministic rules → persistence → frontend reads. :chatgpt-content-reference{index="3"}

For now, don't worry if you cannot explain every box.

That's exactly why we created the remaining learning files.

---

# 6. What role does Amazon Textract play?

For File 01, remember just this:

> **Textract reads information from the invoice.**

Suppose the user uploads:

```text
invoice.pdf
```

Textract helps turn information inside that document into machine-readable invoice information.

Conceptually:

```text
Invoice PDF/Image
        ↓
   Amazon Textract
        ↓
Extracted invoice information
```

Later, `09-Amazon-Textract-and-OCR.md` will teach this properly.

---

# 7. What role does Generative AI play?

Your project uses:

**Amazon Bedrock + Amazon Nova Micro**

The AI analyzes the extracted invoice content and produces possible anomaly/review findings.

Very simplified:

```text
Invoice
   ↓
Textract
   ↓
Extracted information
   ↓
Amazon Bedrock
Nova Micro
   ↓
AI findings
```

This distinction is extremely important:

> **Textract extracts information. Bedrock analyzes the extracted information.**

Don't mix their responsibilities.

The Codex report identifies Textract for OCR/expense extraction and Bedrock Nova Micro for Generative AI inference. :chatgpt-content-reference{index="4"}

---

# 8. What role do Python rules play?

This is another important part of the project.

Your system doesn't simply say:

```text
Ask LLM → trust everything → finished
```

There are also **deterministic Python rules**.

At a conceptual level:

```text
Textract extraction
        +
Bedrock AI findings
        +
Python deterministic checks
        ↓
Review/risk result
```

These rules help calculate the final numeric risk score.

This means the project uses a **hybrid approach**:

> **AI analysis + deterministic business/risk rules**

Codex specifically says deterministic rules produce the final numeric score. :chatgpt-content-reference{index="5"}

We will understand the actual calculation later in:

**`12-Risk-Scoring-and-Financial-Rules.md`**

---

# 9. What result does the user receive?

The application can show information such as:

- extracted invoice data
- analysis findings
- risk information
- invoice details
- processing status
- analytics

The project uses risk classifications:

```text
LOW
MEDIUM
HIGH
```

and a risk score from:

```text
0 → 100
```

However, this is an important distinction:

> **The risk score is not a scientifically proven probability that an invoice is fraudulent.**

Codex specifically warns that these scores are **heuristics, not calibrated fraud probabilities**. :chatgpt-content-reference{index="6"}

So don't say:

> “A score of 90 means there is a 90% probability that the invoice is fraudulent.”

That is not supported.

---

# 10. Is this a fraud-detection system?

Be careful with this phrase.

The application can identify **suspicious information and review signals**.

But that does not mean it proves fraud.

For example:

```text
Unusual total
```

could be suspicious.

But it could also be completely legitimate.

Similarly:

```text
Missing vendor information
```

could result from:

**bad invoice formatting**

or

**Textract/OCR extraction failure**

rather than fraud.

Therefore, a better description is:

> **The application helps identify invoice anomalies and prioritize invoices for human review.**

Not:

> **The application proves whether an invoice is fraudulent.**

---

# 11. Is this a RAG project?

**No.**

Your Codex analysis explicitly says:

```text
NOT PRESENT:

RAG
Vector database
Autonomous agents
ML training
```

:chatgpt-content-reference{index="7"}

There is no flow such as:

```text
Document
 ↓
Chunking
 ↓
Embeddings
 ↓
Vector Database
 ↓
Retrieval
 ↓
LLM
```

So don't say:

> “I implemented RAG for invoice processing.”

You didn't, according to the inspected local repository.

---

# 12. Is this an Agentic AI project?

Again:

**No.**

There are multiple processing steps, but:

> **Multiple steps ≠ Agentic AI.**

Your workflow is predetermined.

Conceptually:

```text
OCR
 ↓
AI analysis
 ↓
Rules
 ↓
Store result
```

Step Functions orchestrates this fixed workflow.

That does not automatically make the application an autonomous AI agent.

This distinction is particularly important because you have another project involving agentic concepts. Don't accidentally mix the terminology between projects.

---

# 13. Is this an ML project?

Not in the sense of training your own ML model.

Your repository does **not** contain an ML training pipeline.

You are using an existing foundation model through Amazon Bedrock.

So:

```text
Your project

❌ Train fraud model
❌ Feature engineering pipeline
❌ MLflow experiment tracking
❌ Model registry
❌ Custom model training

✅ Call foundation model
✅ Prompt model
✅ Process model output
```

That makes the AI component primarily:

**Generative AI inference**

rather than custom ML model development.

---

# 14. What AWS services are involved?

At project-overview level, the Codex report identifies:

```text
Amazon S3
Amazon CloudFront
Amazon Cognito
Amazon API Gateway
AWS Lambda
Amazon SQS
AWS Step Functions
Amazon Textract
Amazon Bedrock
Amazon DynamoDB
Amazon EventBridge
Amazon SNS
Amazon CloudWatch
AWS X-Ray
AWS IAM
AWS CloudFormation/CDK
```

:chatgpt-content-reference{index="8"}

Do **not** try to memorize that list right now.

Our later files will answer:

> What does each service do?

and, more importantly:

> Why does this project need it?

---

# 15. What is actually implemented?

According to Codex, the main processing/display path is implemented.

The project includes capabilities such as:

**authentication**

**authenticated API access**

**presigned invoice upload**

**background invoice processing**

**Textract extraction**

**Bedrock analysis**

**deterministic checks**

**risk scoring**

**invoice listing/details**

**processing status**

**invoice deletion**

**analytics**

**infrastructure definitions**

Codex describes the repository as substantial: a frontend, five CDK stacks, eight application Lambda functions, unit tests, and GitHub Actions workflow definitions. :chatgpt-content-reference{index="9"}

---

# 16. What is only partially implemented?

This is where your interview explanation needs maturity.

Codex identifies partial areas including:

**user isolation**

**notifications**

**AI/output validation**

**UI result refresh**

**data lifecycle management**

**deployment reliability/reproducibility**

There are also risks involving duplicate processing and job reset behavior. :chatgpt-content-reference{index="10"}

That doesn't make the project useless.

It means you should describe it accurately.

---

# 17. Is the project production-ready?

Based on the Codex inspection:

**You should not claim that it is fully production-ready.**

Codex's assessment is closer to:

> **A substantial prototype/demo with production-oriented foundations.**

:chatgpt-content-reference{index="11"}

That is actually useful for learning because later we can discuss:

```text
Current application
       ↓
What's wrong?
       ↓
Why is it a problem?
       ↓
How would we improve it?
       ↓
Production V2
```

Those discussions prepare you for senior-style interview questions.

---

# 18. What should you confidently claim?

Based on the report, you can discuss the repository as implementing:

```text
React frontend
+
Python serverless backend
+
AWS CDK infrastructure
+
Direct S3 upload
+
SQS asynchronous ingestion
+
Step Functions orchestration
+
Textract invoice extraction
+
Bedrock Nova Micro inference
+
Deterministic Python risk rules
+
DynamoDB persistence
+
Invoice analytics UI
```

:chatgpt-content-reference{index="12"}

---

# 19. What should you NOT claim?

This is extremely important.

Don't describe this project as having:

```text
❌ RAG
❌ Vector search
❌ Bedrock Knowledge Bases
❌ LangGraph
❌ Autonomous agents
❌ Trained fraud-detection model
❌ Proven fraud-detection accuracy
❌ Perfect tenant isolation
❌ Exactly-once processing
❌ Guaranteed email alerts
❌ Verified live CI/CD
❌ Verified production readiness
❌ Measured production scalability
❌ Verified current AWS uptime
```

These limitations and non-present capabilities are explicitly called out by Codex. :chatgpt-content-reference{index="13"}

---

# 20. Your simplest mental model

Don't try to remember 15 AWS services.

For now, remember just this:

```text
             NOVAMIND AI
                  │
                  ▼
          User uploads invoice
                  │
                  ▼
           Extract information
              TEXTRACT
                  │
                  ▼
          Analyze information
          BEDROCK NOVA MICRO
                  │
                  ▼
         Apply business rules
               PYTHON
                  │
                  ▼
        Generate review result
                  │
                  ▼
              Store it
           S3 + DYNAMODB
                  │
                  ▼
        Show it to the user
```

If this mental model is clear, the rest of the architecture becomes much easier.

---

# 21. One-line project explanation

For understanding—not memorization:

> **NovaMind AI is a serverless invoice intelligence application that extracts invoice information using Amazon Textract, analyzes the extracted content using Amazon Bedrock Nova Micro, combines AI findings with deterministic Python rules to generate review signals and a risk score, and presents the results through a React web application.**

---

# 22. Interview Preparation — 10 Questions

These are included now as requested, but **don't memorize them yet**.

## Q1 — Tell me about your project.

**Difficulty:** Basic

**What interviewer is testing:** Whether you understand your own project at a high level.

**Word-by-word practice answer:**

> “NovaMind AI is a serverless invoice intelligence application built on AWS. A user uploads an invoice through a React web application. Amazon Textract extracts invoice fields and text, Amazon Bedrock Nova Micro analyzes the extracted information for possible anomalies, and deterministic Python rules calculate the final review score. The results are stored in AWS and displayed back to the user. The current repository implements the main processing flow, although there are still reliability, validation, security, and deployment improvements I would make before calling it fully production-ready.”

This closely follows the Codex interview material and verified project facts. :chatgpt-content-reference{index="14"}

---

## Q2 — What problem does your project solve?

**Difficulty:** Basic

**Word-by-word practice answer:**

> “The project helps automate invoice review. Instead of requiring a user to manually read every invoice, the system extracts important invoice information, analyzes the content for possible anomalies, applies deterministic checks, and produces review signals that can help a finance user decide which invoices need more attention.”

---

## Q3 — Who are the intended users?

**Difficulty:** Basic

**Word-by-word practice answer:**

> “The application is designed for users who review invoices, such as finance teams, accounts-payable staff, or auditors. However, these are intended users inferred from the project workflow, and I would not claim that the repository proves a real customer base.”

That final sentence is worth understanding because it prevents you from inventing business history. :chatgpt-content-reference{index="15"}

---

## Q4 — Where is Generative AI used?

**Difficulty:** Intermediate

**Word-by-word practice answer:**

> “Generative AI is used during the invoice-analysis stage. Amazon Textract first extracts structured fields and text from the invoice. That extracted information is then sent to Amazon Bedrock, where Nova Micro analyzes it and generates possible anomaly findings. The application combines those AI findings with deterministic Python rules rather than relying only on the language model.”

---

## Q5 — Why are both Textract and Bedrock required?

**Difficulty:** Intermediate

**Word-by-word practice answer:**

> “They have different responsibilities. Textract is responsible for extracting information from the invoice document, while Bedrock Nova Micro is responsible for analyzing the extracted information and generating possible findings. In simple terms, Textract helps the system read the invoice, while Bedrock helps the system reason about the extracted content.”

---

## Q6 — Is this a fraud-detection application?

**Difficulty:** Intermediate

**Word-by-word practice answer:**

> “I would describe it as an invoice intelligence and review-support application rather than a system that proves fraud. It generates anomaly findings and heuristic risk scores that can help prioritize invoices for human review. A suspicious result could also be caused by OCR errors, unusual but legitimate invoice formats, or limitations in the rules or AI analysis.”

---

## Q7 — Is this a RAG application?

**Difficulty:** Intermediate

**Word-by-word practice answer:**

> “No. The current implementation is not RAG. It does not perform embedding generation, vector storage, or retrieval of external knowledge before generation. It uses Textract to extract invoice information and Bedrock Nova Micro to analyze that information.”

Codex explicitly identifies RAG and vector storage as not present. :chatgpt-content-reference{index="16"}

---

## Q8 — Is this an Agentic AI application?

**Difficulty:** Advanced

**Word-by-word practice answer:**

> “No. The current implementation uses a predefined Step Functions workflow. The processing stages execute in a fixed sequence, such as OCR, AI analysis, deterministic rules, and persistence. There is no autonomous agent selecting tools or dynamically deciding its own execution path, so I would not describe the current implementation as Agentic AI.”

---

## Q9 — Is this project production-ready?

**Difficulty:** Advanced / Pressure

**Word-by-word practice answer:**

> “I would not claim that the current repository is fully production-ready. It has production-oriented foundations such as serverless AWS services, authentication, asynchronous processing, infrastructure as code, monitoring configuration, and automated workflow definitions. However, the Codex review identified gaps around user isolation, idempotency, AI-output validation, alert wiring, testing, financial-rule correctness, and deployment reproducibility. I would address those areas before describing it as production-ready.”

---

## Q10 — What is the biggest strength of this project?

**Difficulty:** Advanced

**Word-by-word practice answer:**

> “One important strength is that the processing pipeline separates responsibilities clearly. The browser handles the user experience, S3 handles document ingestion, SQS decouples the upload from processing, Step Functions orchestrates the processing stages, Textract performs invoice extraction, Bedrock performs Generative AI analysis, deterministic Python rules calculate the review score, and DynamoDB stores the results. This separation makes the system easier to understand, troubleshoot, and improve compared with putting the entire workflow inside one large function.”

---

# 23. Before we move to File 02

Don't study the 10 answers word-for-word yet.

I first want to check whether **File 01 actually makes sense to you**.

Answer these **two questions in your own simple English**, without copying my answers:

### Question 1

**What is NovaMind AI Invoice Intelligence Platform, and what problem does it solve?**

### Question 2

Suppose I ask:

**“Why are you using both Amazon Textract and Amazon Bedrock? Aren't they doing the same thing?”**

Explain the difference in your own words.

**Answer only these two questions.** I'll check your understanding, correct anything confusing, and we will stay in `01-Project-Overview.md` until you're comfortable.