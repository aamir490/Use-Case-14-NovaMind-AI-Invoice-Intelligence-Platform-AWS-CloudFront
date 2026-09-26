# Your question

**Create my complete project-specific learning roadmap and recommended `.md` learning file structure for the NovaMind AI Invoice Intelligence Platform, using the Codex analysis as the primary source of truth and GitHub only as secondary verification.**

I’ve now found and reviewed the actual Codex report. The roadmap Codex proposed is already strong, but I recommend refining it slightly for **learning order**: first understand the whole system, then each critical subsystem, then reliability/security/production concerns, and only after that move into storytelling and interview answers.

The most important fact to lock in from the beginning is this:

> **This project is a serverless, event-driven Generative AI invoice-processing application. It is not a RAG project, not an Agentic AI project, and not an ML-training/MLOps project.**

The implemented flow is essentially:

**React → Cognito → API Gateway → presigned S3 upload → SQS → Lambda → Step Functions → Textract → Bedrock Nova Micro → Python risk rules → DynamoDB/S3 → frontend results.**

The Codex report identifies eight application Lambdas, five CDK stacks, Textract OCR, Bedrock Nova Micro inference, deterministic risk scoring, DynamoDB/S3 persistence, Cognito authentication, and a React frontend. It also explicitly says RAG, vector databases, autonomous agents, and ML training are not present. :chatgpt-content-reference{index="0"}

The public GitHub README broadly agrees with that architecture and technology stack. :chatgpt-content-reference{index="1"}

---

# Recommended learning structure

I recommend **25 learning files** for this project.

This isn't because your previous project had a similar number. These 25 come naturally from the actual subsystems and interview risks identified by Codex.

## Phase 1 — Understand the complete project

| File | Main topic/question | What you will learn | Why it matters here | Why interviewer may ask |
|---|---|---|---|---|
| `01-Project-Overview.md` | **What is NovaMind AI Invoice Intelligence?** | Business problem, users, inputs, outputs, features, actual scope, maturity | You need the big picture before AWS details | “Tell me about your project.” / “What problem does it solve?” |
| `02-Current-Architecture.md` | **What is the real current architecture?** | Serverless/event-driven architecture, five CDK stacks, eight Lambdas, frontend/backend boundaries | This becomes your mental map of everything else | “Explain your architecture.” |
| `03-End-to-End-Application-Flow.md` | **What happens when a user uploads an invoice?** | Login → upload → SQS → workflow → OCR → AI → rules → storage → UI | This is probably the single most important technical story | “Walk me through one request end-to-end.” |
| `04-Technology-Stack-and-Codebase.md` | **Where is everything implemented?** | React/TS, Python, Boto3, CDK, important folders/files, Lambda responsibilities | Connects architecture diagrams to real code | “Where exactly is this implemented?” |

These four files create your **foundation**.

Do not try to memorize the architecture before these concepts make sense.

---

# Phase 2 — Understand ingestion and asynchronous processing

## `05-Cognito-Authentication-and-User-Isolation.md`

**Main question:** How does authentication and user isolation work?

**You will learn:** Cognito User Pool, login flow, JWT/ID token, API Gateway authorizer, `sub`, `tenant_id`, authentication vs authorization, DynamoDB ownership checks, and the identified job-status/browser-cache isolation gaps.

**Why this matters:** Codex specifically found that isolation is **partial**, not perfect.

**Interview connection:** Expect questions such as “How do you authenticate users?”, “How do you prevent one user seeing another user's invoices?”, and “Authentication vs authorization?”

This is also where you learn why you must **not claim complete multi-tenant isolation**. :chatgpt-content-reference{index="2"}

---

## `06-Presigned-S3-Upload-and-Ingestion.md`

**Main question:** Why does the browser upload directly to S3?

**You will learn:** presigned URLs, PUT uploads, five-minute expiry, object keys, MIME/size validation, S3 `ObjectCreated`, and the synchronous→asynchronous boundary.

**Why this matters:** Upload is the beginning of your processing pipeline.

**Interview connection:** “Why not upload the invoice through Lambda/API Gateway?”

The GitHub README also describes direct browser-to-S3 upload. :chatgpt-content-reference{index="3"}

---

## `07-SQS-DLQ-Retries-and-Idempotency.md`

**Main question:** Why is SQS between S3 and processing?

**You will learn:** queue buffering, asynchronous processing, visibility timeout, retries, DLQ, at-least-once behavior, duplicate processing, idempotency, poison messages.

**Why this matters:** Codex identified duplicate-processing/job-reset risks.

**Interview connection:** “What happens if the same SQS message arrives twice?” is much more important than simply knowing what SQS stands for.

---

## `08-Step-Functions-Workflow-Orchestration.md`

**Main question:** Why use Step Functions instead of one giant Lambda?

**You will learn:** Express workflows, four processing stages, state transitions, retries/catches, workflow state vs business/job state, payload passing and failure isolation.

**Why this matters:** Step Functions is the backbone of processing.

**Interview connection:** “Why Step Functions?”, “Standard vs Express?”, “What happens when stage 2 fails?”

---

# Phase 3 — Understand the AI processing deeply

This is your most important **Generative AI phase**.

## `09-Amazon-Textract-and-OCR.md`

**Main question:** How does an invoice become structured data?

**You will learn:** OCR, `AnalyzeExpense`, expense documents, extracted fields, raw text, parsing, confidence, OCR errors and document limitations.

**Why this matters:** Bedrock does not magically read the original invoice in this architecture. Textract creates the information used downstream.

**Interview connection:** “Why Textract?”, “What if OCR extracts the wrong amount?”, “OCR vs LLM?”

---

## `10-Amazon-Bedrock-Nova-Micro-and-Prompting.md`

**Main question:** Where is Generative AI actually used?

**You will learn:** Amazon Bedrock, Nova Micro, model invocation, prompt construction, invoice context sent to the model, structured JSON output, anomaly generation, summary/confidence, parsing, retries/fallback behavior.

**Why this matters:** This is the project's actual GenAI implementation.

**Interview connection:** “Where exactly are you using Generative AI?”, “Why Bedrock?”, “Why Nova Micro?”, “What is sent to the model?”

---

## `11-AI-Output-Validation-and-Evaluation.md`

**Main question:** Can we trust the LLM response?

**You will learn:** hallucinations, structured-output limitations, schema validation, Pydantic not being fully enforced, malformed output, prompt injection considerations, AI failure/degraded behavior, evaluation datasets/fixtures and what production AI evaluation should measure.

**Why this matters:** Codex identified **weak model-output validation** as an important gap.

**Interview connection:** “How do you know your AI output is correct?”

This is where your answer becomes stronger than simply saying “Bedrock returns JSON.”

---

# Phase 4 — Understand the project's intelligence

## `12-Risk-Scoring-and-Financial-Rules.md`

**Main question:** How is the final risk score calculated?

**You will learn:** deterministic Python rules, AI findings, weights, thresholds, normalization, missing-field checks, math checks, duplicate line-item logic, risk levels, double counting and false-positive risks.

**Why this matters:** The LLM does **not** independently calculate the project's final risk score.

Codex specifically warns that the scores are heuristics rather than calibrated fraud probabilities. :chatgpt-content-reference{index="4"}

**Interview connection:** “Is this fraud detection?”, “How do you calculate 0–100?”, “Why combine AI with deterministic rules?”

---

# Phase 5 — Understand data and frontend behavior

## `13-DynamoDB-Data-Model-and-Access-Patterns.md`

**Main question:** How is project data stored?

Learn invoice records vs job records, tenant-oriented keys, DynamoDB access patterns, on-demand capacity, queries, pagination, ordering, TTL/lifecycle considerations and analytics limitations.

Interviewers may ask: **“Why DynamoDB instead of RDS?”**

---

## `14-S3-DynamoDB-and-Application-State.md`

**Main question:** Where does every type of data live?

Learn:

**S3:** original invoice + extracted text + frontend assets.

**DynamoDB:** invoice records + processing jobs.

**Frontend:** temporary React Query/Zustand state.

Also understand durable vs temporary state, browser refresh behavior, Lambda-local state and why there is **no conversational memory**.

This file prevents confusion between **storage, database, cache and application state**.

---

## `15-Frontend-React-State-Polling-and-Analytics.md`

**Main question:** How does the UI know processing finished?

Learn React, Vite, Axios, React Query, Zustand, status polling, API calls, invoice pages, analytics and cache/session behavior.

Most importantly, understand Codex's identified issue: polling exists, but completed invoice details do not always refresh correctly.

Interview question:

> “Backend says processing completed, but UI still shows old data. How would you troubleshoot?”

---

# Phase 6 — Events, AWS infrastructure and deployment

## `16-EventBridge-SNS-and-Notifications.md`

Learn the intended HIGH-risk event path:

**Store Results → EventBridge → Rule → SNS → notification**

But also learn the important distinction:

**alert infrastructure exists, but Codex found its wiring/delivery incomplete or unverified.**

So don't tell an interviewer:

> “High-risk invoices definitely send emails.”

Instead, you need to understand exactly what is implemented versus intended.

---

## `17-AWS-CDK-and-Infrastructure-as-Code.md`

**Main question:** How is AWS infrastructure defined?

Learn the five stacks:

**StorageStack  
AuthStack  
ProcessingStack  
ApiStack  
FrontendStack**

Then understand dependencies, CloudFormation, CDK synth/deploy, environment configuration and infrastructure ownership.

Interview connection:

> “Why separate your infrastructure into five stacks?”

---

## `18-Deployment-Lambda-Layers-and-CICD.md`

Learn local execution, Lambda packaging, Python 3.12/ARM64 compatibility, shared Lambda layers, configuration/environment variables, CDK deployment, GitHub Actions, OIDC and the manual layer-repair scripts.

This matters because Codex found **deployment reproducibility problems**.

The public README makes stronger claims about automatic GitHub Actions deployment than Codex could verify from the local repository/runtime evidence. :chatgpt-content-reference{index="5"}

---

# Phase 7 — Production engineering

## `19-Security-and-Data-Lifecycle.md`

Learn Cognito security, API authorization, IAM, least privilege, S3 security, HTTPS/CloudFront, CORS, file validation, tenant isolation, deletion/retention, browser caching and GenAI security.

Interview focus:

> “How would you secure sensitive financial invoices?”

This should go beyond saying “I used Cognito.”

---

## `20-Reliability-Troubleshooting-and-Observability.md`

Learn how to troubleshoot each boundary:

**Upload → S3 → SQS → trigger Lambda → Step Functions → Textract → Bedrock → rules → DynamoDB → API → frontend.**

Also learn CloudWatch logs, X-Ray configuration, job states, DLQ, retries, alarms and failure isolation.

This will prepare you for scenario questions instead of memorized definitions.

---

## `21-Testing-and-AI-Quality.md`

Learn what testing really exists.

Codex found **44 unit-test functions**, but did **not execute them**, and identified an OCR import defect. :chatgpt-content-reference{index="6"}

Study unit vs integration vs E2E testing, AWS mocking, workflow testing, AI evaluation, financial-rule tests, regression tests and missing production-quality coverage.

Interview question:

> “How did you test the system?”

Your answer must distinguish **tests existing** from **tests verified as passing**.

---

## `22-Cost-Scalability-and-Performance.md`

Learn what actually drives cost:

**Textract  
Bedrock  
Lambda  
Step Functions  
DynamoDB  
S3  
SQS  
API Gateway  
CloudFront**

Then study scaling bottlenecks, quotas, concurrency, queue depth, Bedrock/Textract throttling, DynamoDB access patterns, polling overhead and measurements you would need before claiming scale.

### Important GitHub/Codex difference

The public README gives an estimated **$17–20/month for 1,000 invoices**. :chatgpt-content-reference{index="7"}

Codex says **actual cost is unverified** and warns against presenting invented/unmeasured cost or capacity numbers as project facts. :chatgpt-content-reference{index="8"}

So the roadmap will teach you **how cost works**, not make you memorize `$17–20`.

---

# Phase 8 — Think like the system designer

## `23-Limitations-Production-V2-and-Design-Decisions.md`

I recommend combining three closely related subjects here rather than creating several repetitive files.

Learn the project's real weaknesses:

**security/isolation gaps → idempotency → financial correctness → AI validation → alert wiring → packaging/deployment → testing → UI refresh → lifecycle management.**

Then study realistic improvements and the major design decisions:

**Why serverless?  
Why direct S3 upload?  
Why SQS?  
Why Step Functions?  
Why Textract + Bedrock?  
Why AI + deterministic rules?  
Why DynamoDB?  
Why Cognito?  
Why CloudFront?**

For every decision:

**Requirement → Choice → Reason → Trade-off → Alternative → When alternative becomes better**

This is one of the most valuable interview files.

---

# Phase 9 — Turn knowledge into interview skill

Only **after Files 01–23** do we move here.

## `24-Complete-Project-Storytelling-and-Interview-QA.md`

This will contain two connected parts.

First, you learn to explain the project in:

**30 seconds → 1 minute → 2 minutes → 5 minutes → deep technical walkthrough.**

Then we use Codex's existing interview bank rather than unnecessarily replacing it.

For every major question:

**Question  
→ Why interviewer asks  
→ Concept you must understand  
→ Your answer first  
→ Compare with Codex word-by-word answer  
→ Follow-up  
→ Pressure follow-up  
→ Common mistake**

For example, Codex already contains:

> “Tell me about this project.”

and explicitly says you first need to understand the **upload path, processing stages, storage and limitations** before answering it. :chatgpt-content-reference{index="9"}

That's exactly why interview Q&A comes near the end rather than File 01.

---

## `25-Mock-Interview-and-Final-Revision.md`

This becomes the final stage.

I ask:

> “Tell me about your Invoice Intelligence project.”

**You answer without notes.**

Then I evaluate:

**Technical accuracy  
Architecture understanding  
AWS understanding  
GenAI understanding  
Clarity  
Interview structure  
Incorrect claims  
Missing details**

Then:

**Feedback → corrected understanding → stronger answer → follow-up → pressure question → retry.**

Eventually we practice interview chains such as:

**Project overview  
↓  
Architecture  
↓  
Why SQS?  
↓  
What happens twice?  
↓  
How do you prevent duplicate processing?  
↓  
What happens if Bedrock fails?  
↓  
Why can processing still complete?  
↓  
Can you trust the score?  
↓  
How would you improve production reliability?**

That tests **understanding**, not memorization.

---

# Final roadmap

Your learning folder should therefore look like:

```text
learning/
│
├── 01-Project-Overview.md
├── 02-Current-Architecture.md
├── 03-End-to-End-Application-Flow.md
├── 04-Technology-Stack-and-Codebase.md
│
├── 05-Cognito-Authentication-and-User-Isolation.md
├── 06-Presigned-S3-Upload-and-Ingestion.md
├── 07-SQS-DLQ-Retries-and-Idempotency.md
├── 08-Step-Functions-Workflow-Orchestration.md
│
├── 09-Amazon-Textract-and-OCR.md
├── 10-Amazon-Bedrock-Nova-Micro-and-Prompting.md
├── 11-AI-Output-Validation-and-Evaluation.md
├── 12-Risk-Scoring-and-Financial-Rules.md
│
├── 13-DynamoDB-Data-Model-and-Access-Patterns.md
├── 14-S3-DynamoDB-and-Application-State.md
├── 15-Frontend-React-State-Polling-and-Analytics.md
│
├── 16-EventBridge-SNS-and-Notifications.md
├── 17-AWS-CDK-and-Infrastructure-as-Code.md
├── 18-Deployment-Lambda-Layers-and-CICD.md
│
├── 19-Security-and-Data-Lifecycle.md
├── 20-Reliability-Troubleshooting-and-Observability.md
├── 21-Testing-and-AI-Quality.md
├── 22-Cost-Scalability-and-Performance.md
├── 23-Limitations-Production-V2-and-Design-Decisions.md
│
├── 24-Complete-Project-Storytelling-and-Interview-QA.md
└── 25-Mock-Interview-and-Final-Revision.md
```

## One major correction compared with a generic GenAI roadmap

We will **not** create files such as:

```text
RAG.md
Embeddings.md
Vector-Database.md
Knowledge-Base.md
LangChain.md
LangGraph.md
Agents.md
Agent-Memory.md
ML-Training.md
MLflow.md
Model-Registry.md
```

They aren't part of this project's current implementation. Codex explicitly classifies RAG, vector storage, autonomous agents and ML training as **not present**. :chatgpt-content-reference{index="10"}

That is important for your interviews. This project should showcase a different strength from your multi-agent project: **AWS serverless architecture + document intelligence + GenAI inference + asynchronous orchestration + deterministic financial risk logic.**

## GitHub vs local Codex findings

I found one especially important pattern already. The public [GitHub repository](https://github.com/aamir490/Use-Case-14-NovaMind-AI-Invoice-Intelligence-Platform-AWS-CloudFront?utm_source=chatgpt.com) describes the application more strongly—for example, “fully automated end to end,” strong multi-tenant isolation, automatic CI/CD, high-risk SNS email alerts, and a specific monthly cost estimate. :chatgpt-content-reference{index="12"}

The **local Codex inspection is more cautious**: tenant isolation is partial, notification wiring is incomplete, live CI/CD/current deployment are unverified, actual cost is unverified, and the project has several reliability/validation gaps. :chatgpt-content-reference{index="13"}

For our learning and interviews, **we will follow the Codex/local evidence whenever these conflict.** The GitHub README can describe the intended design, but we won't turn intended or unverified behavior into claims about the current implementation.

### Learning sequence

Your method fits this project very well:

**Evidence → Understand → Explain simply → Trace it in NovaMind → Connect to AWS → Understand why → Trade-offs → Interview question → Your answer → Codex practice answer → Follow-up → Feedback → Revision.**

And importantly, **we should not start with interview answers**.

We should start with **`01-Project-Overview.md`**, make sure you genuinely understand it, test you with a few simple questions, and only then move to `02-Current-Architecture.md`.