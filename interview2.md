# NovaMind Ai Invoice Intelligence Platform
## My Interview Story — Speak This Naturally

> **Aamir** | [GitHub](https://github.com/aamir490) | [LinkedIn](https://www.linkedin.com/in/aamir-imran)
>
> Read this before every interview. It is written in first person so you can speak it directly.
> The sections are ordered so you can answer any question by jumping to the right part.

---

## THE 2-MINUTE OPENING

*Use this when they say "Tell me about yourself" or "Tell me about this project."*

---

"I built a platform called **NovaMind Ai Invoice Intelligence Platform**. It is a fully serverless application on AWS that automates invoice auditing using AI.

The idea is simple. A user uploads an invoice image — PNG, JPG, or PDF. Within about 30 seconds, the platform extracts every field from that invoice using **Amazon Textract**, runs it through **Amazon Bedrock's Nova Micro model** to detect anomalies and fraud patterns, applies a deterministic rules engine to check math errors and missing fields, and produces a risk score from 0 to 100.

The result is stored in **DynamoDB** and displayed in a **React dashboard** with charts, filters, and per-invoice AI explanations.

Everything is serverless — **8 Lambda functions**, **Step Functions** for orchestration, **SQS** for decoupling, **API Gateway** with **Cognito** for authentication, and **CloudFront** for the frontend.

I built the infrastructure as code using **AWS CDK v2 in TypeScript** — 5 separate stacks — and deployed it on a real AWS account. The whole system processes a typical invoice in about 15 to 30 seconds and costs roughly $17 to $20 per month at 1,000 invoices."

---

## 1. SITUATION — The Problem I Was Solving

*Use this when they ask: "What problem were you solving?" or "Why did you build this?"*

---

"I started this project because I wanted to build something that combines cloud architecture, AI, and real business value — not just a hello-world app.

The real-world problem I focused on is invoice fraud and processing errors. In any company that handles invoices — retail, logistics, finance — someone has to manually review vendor invoices before approving payment. That process is slow, error-prone, and expensive.

Common issues include math errors where line items don't add up to the stated total, missing required fields like invoice numbers or dates, duplicate line items, and outright fraud patterns like unusual prices or non-standard formats.

I wanted to build a system that could automatically catch these problems the moment an invoice is uploaded — without any human needing to read it first. And I wanted it to combine both AI analysis for nuanced pattern detection AND deterministic rules for guaranteed math checks. Neither alone is enough."

---

## 2. TASK — What I Needed to Build

*Use this when they ask: "What were your requirements?" or "What was your role?"*

---

"I designed and built the entire platform myself from scratch. My requirements were:

- Accept invoice images in multiple formats — PNG, JPG, PDF, TIFF
- Extract every structured field — vendor name, dates, total, line items, tax
- Run AI anomaly detection using a real LLM
- Apply deterministic business rules for guaranteed accuracy
- Combine both into a risk score from 0 to 100 with LOW, MEDIUM, HIGH bands
- Store results in a multi-tenant database where each user only sees their own invoices
- Display everything in a React dashboard with authentication
- Make the whole thing production-ready — retries, dead letter queues, error handling, monitoring, CI/CD

The engineering challenges were: how do I orchestrate a multi-step async pipeline reliably, how do I make AI failures non-fatal so the pipeline always completes, how do I isolate tenant data, and how do I keep costs near zero at low volume."

---

## 3. ACTION — How I Designed and Built It

*Use this when they ask: "Walk me through the architecture." or "How does it work?"*

---

### The Overall Architecture

"Let me walk you through the architecture step by step.

I have a **React SPA** served via **CloudFront** from a private S3 bucket. The bucket has no public access — CloudFront uses Origin Access Control to read from it. HTTPS is automatic.

The user authenticates through **Amazon Cognito** using SRP flow — the password is never sent in clear text. After login, Cognito issues a JWT token. The user's Cognito sub — that UUID — becomes their **tenant ID** throughout the entire system. Every DynamoDB query filters on that tenant ID. So data isolation is enforced at the data layer, not just in application code.

When the user wants to upload an invoice, the browser calls `POST /invoices/upload-url` through **API Gateway**. The Cognito JWT is validated by API Gateway before the Lambda even runs. The **Upload Lambda** generates a pre-signed S3 PUT URL expiring in 5 minutes and creates a processing job record in DynamoDB with status PENDING.

The browser then PUTs the file directly to S3 — it never goes through API Gateway. This was a deliberate decision to bypass the 10MB payload limit and avoid Lambda bandwidth costs.

When the file lands in S3, an **S3 ObjectCreated event** is sent to an **SQS queue**. I didn't wire S3 directly to Step Functions because S3 can't invoke Step Functions natively. SQS gives me buffering, retry, and a dead letter queue after 3 failed attempts.

The **SQS Trigger Lambda** reads from the queue with a batch size of 1, parses the S3 key to extract the tenant ID — because the key structure is `invoices/{tenant_id}/{invoice_id}.ext` — and starts a **Step Functions Express** state machine.

Why Express instead of Standard? Because my pipeline completes in under 5 minutes and Express is significantly cheaper at high volume. The trade-off is limited execution history retention, but I log everything to CloudWatch anyway."

---

### The 4-Stage Pipeline

"The Step Functions pipeline has 4 stages.

**Stage 1 — OCR.** The OCR Lambda calls **Textract AnalyzeExpense**. This is not generic OCR — AnalyzeExpense is purpose-built for invoices and receipts. It returns semantically typed fields: VENDOR_NAME, INVOICE_RECEIPT_ID, TOTAL, SUBTOTAL, TAX, DUE_DATE, and LINE_ITEMS. I don't need to write parsing heuristics. Each stage forwards its output merged into the pipeline payload using Python's `**event` spread — so each Lambda adds its results without losing previous stages' data.

**Stage 2 — AI Analysis.** The AI Lambda sends a carefully crafted prompt to **Amazon Bedrock Nova Micro**. The key decision here was the prompt structure. I pass both the structured OCR data AND the raw text lines. I instruct the model to return ONLY valid JSON — no markdown, no explanation — following a strict schema with anomaly type, severity, description, and field affected. The temperature is 0.2 to reduce hallucinations. And I include an explicit rule: 'Do not invent anomalies. Only flag what you can clearly see in the data.'

If Bedrock is throttled or fails, the Lambda returns an empty anomaly list and the pipeline continues. AI is enhancement, not a hard dependency.

**Stage 3 — Risk Scoring.** The Risk Lambda runs deterministic rules: math error check with 1% tolerance using regex amount parsing — that's plus 40 points. Missing required fields — 8 points each. Non-standard invoice number — 10 points. Duplicate line items — 15 points. Then it adds AI anomaly scores: HIGH severity adds 15, MEDIUM adds 7, LOW adds 3. Total is capped at 100. Below 30 is LOW, 30 to 69 is MEDIUM, 70 and above is HIGH.

**Stage 4 — Store Results.** The Store Lambda writes the complete invoice record to DynamoDB, saves the extracted text to a processed S3 bucket for audit history, and fires an **EventBridge event** with source `invoice-platform` and DetailType `InvoiceProcessed`. An EventBridge rule matches on `risk_level = HIGH` and routes to an **SNS topic** for email alerts. The CloudWatch DLQ alarm also points to the same SNS topic.

Every stage updates the processing jobs table with the current stage name, so the frontend can show 'OCR in progress', 'AI analysis running' etc. If any stage fails, the Step Functions catch block writes status FAILED to the jobs table directly using a DynamoDB update task — no separate failure Lambda needed."

---

### Frontend and API

"The **React frontend** is built with Vite, TypeScript, Tailwind CSS, Zustand for state, React Query for data fetching, and Recharts for charts. AWS Amplify handles Cognito auth.

The API has two Lambda functions: an Invoices Lambda handling list, get, status, and delete — all tenant-scoped — and an Analytics Lambda computing KPIs, risk trend by day, vendor stats, and anomaly type breakdowns.

The frontend polls `GET /invoices/{id}/status` every 3 seconds while the invoice is processing. When the status returns COMPLETED, it loads the full detail page.

All API Lambdas share common code through a **Lambda Layer** — the `shared` package contains the DynamoDB helpers, Pydantic models, response builders, and CORS logic. This was one of the implementation challenges I'll describe in more detail."

---

## 4. RESULT — What the Platform Achieves

*Use this when they ask: "What was the outcome?" or "What are the results?"*

---

"The platform is fully deployed on AWS and working end to end. Key outcomes:

**Processing time** — a typical invoice is processed in 15 to 30 seconds from upload to COMPLETED status in the dashboard.

**Cost efficiency** — at 1,000 invoices per month the total AWS cost is about $17 to $20. The dominant cost is Textract at about $15. Lambda, DynamoDB, SQS, Cognito, EventBridge are all near or within free tier. Step Functions Express charges about $1 per million executions.

**Reliability** — every Lambda has retry logic, the pipeline has catch-all error handling, SQS has a DLQ, and CloudWatch alarms notify on failures. Bedrock failures are non-fatal by design.

**Security** — multi-tenant isolation at the DynamoDB partition key level. Pre-signed URLs for file uploads bypass API Gateway limits. HTTPS everywhere. Cognito token validation before any Lambda runs. IAM least privilege on every function.

**Scalability** — SQS absorbs upload bursts. Lambda scales concurrently. Step Functions Express handles high throughput. The only bottlenecks at scale would be Textract and Bedrock service quotas — both addressable with quota increase requests."

---

## 5. CHALLENGES AND HOW I SOLVED THEM

*Use this when they ask: "What was your biggest challenge?" or "What problems did you run into?"*

---

### Challenge 1 — The Shared Module Import Problem

"One of the most time-consuming issues I faced was the Lambda shared module. All 8 Lambda functions import from a `shared` Python package — `shared.db`, `shared.models`, `shared.response`. But Lambda deploys each function as a separate zip from its own folder. The shared folder is a sibling, not inside any function's zip.

My first approach was using CDK's `local.tryBundle` to package the layer on the fly. On Windows with no Docker, this failed silently — CDK produced a malformed layer zip with the wrong directory structure. Lambda's Python runtime adds `/opt/python` to `sys.path`, so the layer zip must contain `python/shared/db.py` — not `python/db.py`. The flat structure doesn't work with `from shared.db import ...`.

My fix was to pre-build the layer manually: create `shared-layer-v2/python/shared/` with all the source files, pip install pydantic and boto3 into `shared-layer-v2/python/`, then publish the layer via AWS CLI with a PowerShell script that also handles the zip creation and function attachment. This script now runs as a required step after every CDK deploy."

### Challenge 2 — CORS with Cognito Auth

"CORS was trickier than I expected. I initially used `allowOrigins: ['*']` in API Gateway. But when the frontend sends an `Authorization` header — which it always does because we use Cognito JWT — browsers reject wildcard origins. They require the server to echo back the exact request origin.

I had to fix two places. In `api-stack.ts`, I changed to explicit allowed origins and added `allowCredentials: true`. But there was a second issue: API Gateway's own error responses — the 401 from the Cognito authorizer, for example — don't go through Lambda. They bypass my response code entirely. So I had to add Gateway Responses for UNAUTHORIZED, ACCESS_DENIED, DEFAULT_4XX and DEFAULT_5XX, each with the CORS headers injected. Without that, the browser sees a CORS error instead of a 401, which is very confusing to debug."

### Challenge 3 — Step Functions HandleFailure State

"In my Step Functions pipeline, when a stage fails, a catch block routes to a HandleFailure state that writes job status FAILED to DynamoDB. Initially I used `$.job_id` as the DynamoDB key source. But when an error occurs, Step Functions merges the error into the payload at `$.error` and the original `$.job_id` was sometimes missing.

The fix was to use `$$.Execution.Input.job_id` — referencing the original execution input rather than the current state input. The execution input never changes throughout the workflow, so this is always reliable."

### Challenge 4 — PowerShell JSON Quoting

"A smaller but frustrating challenge was passing JSON to AWS CLI from PowerShell. PowerShell single quotes don't behave like bash single quotes. Escaped double quotes get mangled by the shell. The fix was to use `[System.IO.File]::WriteAllText()` to write the JSON to a temp file without BOM encoding, then pass `file://path` to the AWS CLI. This completely bypasses shell quoting issues."

---

## 6. WHY I CHOSE THESE TECHNOLOGIES

*Use this when they ask: "Why did you use X?" or "Why not Y instead?"*

---

### Lambda over EC2 or ECS

"I chose Lambda because all my processing is event-driven and stateless. There is no background process, no persistent connection, no long-running computation. Each invoice is processed independently in under 5 minutes. Lambda's pay-per-invocation model means the cost is near zero when no invoices are being processed. EC2 would mean paying for an idle server 24/7. ECS containers would add orchestration complexity. Lambda was the simplest, cheapest, most appropriate choice."

### SQS between S3 and Step Functions

"S3 can trigger Lambda directly, but S3 cannot invoke Step Functions natively. I needed SQS in between. But more importantly, SQS adds value even if Step Functions supported direct S3 invocation: it buffers burst uploads, it handles retry via visibility timeout, and it provides a dead letter queue for poison messages. Without SQS, a burst of 100 simultaneous uploads could overwhelm downstream services."

### Step Functions Express over Lambda Chaining

"I could have chained Lambdas manually using SQS between each stage. But Step Functions gives me visual execution history, per-stage retry configuration, catch-all error routing, and state passing without writing plumbing code. Express type is cheaper than Standard and fits my under-5-minute pipeline perfectly."

### DynamoDB over RDS

"Invoice data is inherently variable. Invoices from different vendors have different numbers of line items, different tax structures, different field sets. A fixed relational schema would require many nullable columns or complex EAV tables. DynamoDB's flexible document model fits this use case naturally. PAY_PER_REQUEST billing means no capacity planning. And the composite key tenant_id + invoice_id gives me natural multi-tenant isolation."

### Bedrock Nova Micro over Other LLMs

"I needed an LLM accessible via AWS IAM — no separate API keys, no data leaving AWS, no secret rotation. Bedrock is the answer. I chose Nova Micro because it is fast, cheap — about $2 per month at 1,000 invoices — and handles structured JSON output reliably with a well-crafted prompt. Claude or GPT would give better reasoning but at 10 to 50 times the cost for a classification task that Nova Micro handles well."

### Textract AnalyzeExpense over Generic OCR

"Generic OCR like Tesseract gives raw text. I then have to write complex heuristics to find vendor name, total, line items across different invoice layouts. Textract's AnalyzeExpense API is purpose-built for financial documents. It returns semantically labeled fields regardless of invoice layout. No training, no heuristics, no maintenance."

### CloudFront over Direct S3 Website Hosting

"S3 static website hosting requires a public bucket or a public endpoint. I wanted the bucket to be completely private. CloudFront with Origin Access Control means only CloudFront can read the S3 bucket — direct S3 URLs return 403. CloudFront also gives HTTPS without me managing certificates, SPA routing fallback by rewriting 404s to index.html, and global edge caching."

### CDK over CloudFormation YAML or Terraform

"CDK lets me write infrastructure in TypeScript with type checking, code reuse, and L2 constructs that abstract away 90% of the boilerplate. Five stacks with clean dependency ordering is trivial in CDK. The same in raw CloudFormation YAML would be hundreds of lines of error-prone JSON."

---

## 7. END-TO-END DEMO STORY

*Use this when they say: "Walk me through what happens when a user uploads an invoice."*

---

"Let me walk you through the complete flow from a user's perspective.

The user opens the app at the CloudFront URL. They log in with their email and password. Cognito validates the credentials using SRP — the password is never sent in plain text. Cognito issues a JWT token with a unique sub claim. That sub becomes their tenant ID for everything that follows.

They go to the Invoices page and click Upload Invoice. They select an invoice image from their computer.

Behind the scenes, the React frontend calls `POST /invoices/upload-url` to API Gateway, including the Cognito JWT in the Authorization header. API Gateway validates the JWT before the Lambda runs. The Upload Lambda generates a unique invoice ID like `inv_20260826_a1b2c3d4`, creates a job record in DynamoDB with status PENDING, generates a pre-signed S3 PUT URL expiring in 5 minutes, and returns all of this to the browser.

The browser uses the pre-signed URL to PUT the file directly to S3. The file never touches API Gateway — this bypasses the 10MB payload limit entirely.

S3 detects the new file in the `invoices/` prefix and sends an ObjectCreated event to the SQS queue. The SQS Trigger Lambda polls the queue, parses the S3 key to extract the tenant ID and invoice ID, and starts a Step Functions Express execution.

Now the pipeline runs.

The OCR Lambda calls Textract AnalyzeExpense. Textract reads the invoice image and returns structured fields: vendor name, invoice number, dates, total, subtotal, tax, and all line items. The Lambda passes this data forward in the pipeline payload.

The AI Analysis Lambda takes the structured fields and the raw text lines, builds a prompt, and sends it to Bedrock Nova Micro. The prompt asks the model to identify anomalies in a specific JSON schema. If Bedrock responds with `No anomalies detected` — great. If it finds a math discrepancy or unusual price, it returns a typed anomaly with severity.

The Risk Scoring Lambda combines the AI findings with deterministic rules. It checks whether the line items sum to the stated total within 1% tolerance — a math error adds 40 points. Missing required fields add 8 each. Duplicate items add 15. AI anomalies add 3 to 15 depending on severity. The final score caps at 100. Above 70 is HIGH risk.

The Store Lambda writes the complete record to DynamoDB with all fields, saves the extracted text to S3 for audit purposes, and fires an EventBridge event with the invoice ID, tenant ID, risk score, and risk level.

If the risk level is HIGH, an EventBridge rule matches and publishes to SNS, which sends an email alert.

Meanwhile, the frontend has been polling `GET /invoices/{id}/status` every 3 seconds. When it sees COMPLETED, it loads the full invoice detail page showing the vendor, dates, total, line items, risk gauge, AI explanation, and the full anomaly list.

The whole thing — from button click to dashboard result — takes about 15 to 30 seconds."

---

## 8. PRODUCTION READINESS

*Use this when they ask: "Is this production-ready?" or "How do you handle failures?"*

---

### Security

"Every piece of data is isolated by tenant. The partition key is the Cognito sub UUID — impossible to guess. Every DynamoDB query filters on it. IAM roles on each Lambda are minimal — the OCR Lambda only has `textract:AnalyzeExpense` and `s3:GetObject` on the uploads bucket. Nothing more. S3 buckets block all public access. The frontend bucket is accessible only through CloudFront OAC. Pre-signed upload URLs expire in 5 minutes. Cognito tokens expire in 1 hour."

### Retries and Error Handling

"The OCR Lambda has 2 Step Functions retries on service exceptions. The AI Lambda has 3 retries at 5-second backoff intervals AND handles Bedrock throttling internally with exponential backoff — 4 attempts with random jitter. The Store Lambda has 3 retries. All stages have a catch-all that routes to the HandleFailure DynamoDB update task.

The SQS queue has a 120-second visibility timeout. The SQS Trigger Lambda uses `reportBatchItemFailures` — if one message fails, only that message returns to the queue, not the whole batch. After 3 failures, the message goes to the DLQ."

### Monitoring

"Every Lambda writes structured logs with prefixes like [OCR], [AI], [Store] including invoice_id, tenant_id, and elapsed milliseconds. All Lambdas have X-Ray active tracing — I can see a full trace from API Gateway through all Lambdas through to Textract and Bedrock calls. Step Functions logs at ERROR level to CloudWatch with execution data included. API Gateway logs at ERROR level with access logs to a 30-day retention log group.

There is a CloudWatch alarm on DLQ message count — if any message lands in the DLQ, the alarm fires within one evaluation period and sends to SNS."

### Idempotency

"The Upload Lambda generates a new invoice_id per request using a UUID suffix. Job creation is wrapped in try/except because the Upload API and the SQS Trigger Lambda both try to create the job — one will succeed, one will silently pass. The Store Lambda uses DynamoDB `put_item` which overwrites — safe for retries."

---

## 9. INTERVIEW QUESTIONS — PREDICTED AND ANSWERED

*Memorize these. They will ask these questions.*

---

**"Tell me about this project."**
→ Use the 2-minute opening at the top of this document.

---

**"Why didn't you use EC2?"**
→ "EC2 is for persistent servers. My workload is entirely event-driven and stateless. Each invoice is processed in under 5 minutes and then the compute is done. Lambda costs nothing when idle. EC2 would cost money 24/7 even when no invoices are being uploaded. Serverless was the right architectural fit."

---

**"Why SQS? Why not trigger Lambda directly from S3?"**
→ "S3 can trigger Lambda directly, but S3 cannot invoke Step Functions natively — I need a Lambda bridge either way. More importantly, SQS adds real value: it buffers burst uploads so downstream processing doesn't get overwhelmed, the 120-second visibility timeout handles transient failures automatically, and the DLQ catches messages that repeatedly fail so I can investigate without losing data."

---

**"How does multi-tenancy work?"**
→ "The Cognito JWT contains a sub claim — a UUID unique to each user. API Gateway validates the token and passes the claims to Lambda. Every Lambda extracts this sub as tenant_id. It is the DynamoDB partition key. Every query includes `KeyConditionExpression: tenant_id = :sub`. One tenant cannot access another's data without a valid JWT for that account."

---

**"What happens if Bedrock goes down?"**
→ "The AI Lambda retries 4 times with exponential backoff and random jitter. If all retries fail, the Lambda catches the exception and returns an empty anomaly list with an 'Analysis unavailable' message. The pipeline continues. The invoice still gets Textract OCR data and deterministic risk scoring — the score might be lower without AI input, but the record is stored as COMPLETED. AI is enhancement, not a hard dependency."

---

**"How do you debug a stuck invoice?"**
→ "I check the DynamoDB processing-jobs table for the job_id. It has the current stage and any error message. If it shows FAILED at the OCR stage, I go to CloudWatch Logs for `/aws/lambda/invoice-ocr-dev` and find the log entry with that invoice_id. If there's a Step Functions execution failure, the console shows exactly which state failed and what the error was. X-Ray traces show latency breakdown — if Textract took 55 seconds that tells me I'm hitting a size or quota issue."

---

**"How does the risk score work exactly?"**
→ "Math error — where line items don't sum to the stated total within 1% — adds 40 points. That's the highest weight because it's an objective fact. Each missing required field — invoice number, receipt date, total amount, vendor name — adds 8 points. Non-standard invoice number adds 10. Duplicate line items add 15. Then AI anomalies: HIGH severity adds 15, MEDIUM adds 7, LOW adds 3. The total is capped at 100. Below 30 is LOW, 30 to 69 is MEDIUM, 70 and above is HIGH."

---

**"What breaks first at 100 times the current load?"**
→ "Two things. First, Textract has account-level concurrent job limits. At high volume I'd hit those and the OCR Lambda would timeout. Solution: request a service quota increase. Second, the Analytics Lambda does a full paginated DynamoDB scan for every dashboard load. At thousands of invoices per tenant that becomes slow and expensive. Solution: materialize analytics using DynamoDB Streams into a separate aggregation table, or use a GSI with pre-computed aggregates."

---

**"Why Step Functions Express instead of Standard?"**
→ "My pipeline completes in under 5 minutes. Express is designed for high-volume short-duration workflows — much cheaper than Standard, which charges per state transition. The trade-off is that Express doesn't keep execution history as long and doesn't support `list-executions` the same way. I log everything to CloudWatch so I don't need the execution history from Step Functions itself."

---

**"Why DynamoDB instead of RDS?"**
→ "Invoices from different vendors have wildly different structures — different numbers of line items, different tax schemas, different field sets. A fixed relational schema would require many nullable columns or complex EAV tables. DynamoDB's flexible document model fits naturally. PAY_PER_REQUEST billing means no capacity planning at this stage. And the composite key tenant_id + invoice_id gives me natural multi-tenant isolation with two-digit millisecond latency reads."

---

**"How do you handle the 10MB API Gateway file upload limit?"**
→ "I avoid it entirely. The Upload Lambda generates a pre-signed S3 PUT URL. The browser uploads directly to S3 — the file never goes through API Gateway or Lambda. Pre-signed URLs are time-limited to 5 minutes and scoped to a specific S3 key, so a user can only upload to their own path."

---

**"How would you add real-time notifications instead of polling?"**
→ "I'd replace the 3-second polling with API Gateway WebSocket. When a user opens an invoice, the frontend opens a WebSocket connection keyed to the invoice_id. The Store Lambda, after writing to DynamoDB, pushes a message to the WebSocket connection. This eliminates the polling entirely. Alternatively, DynamoDB Streams into a Lambda that pushes to WebSocket. I didn't implement this because polling at 3-second intervals is sufficient for demo purposes."

---

**"What would you improve if you had more time?"**
→ Use Section 10 below.

---

## 10. FUTURE IMPROVEMENTS

*Use this when they ask: "What would you add?" or "What are the limitations?"*

---

"If I had more time, here's what I'd improve in priority order:

**Real-time push notifications** — Replace the 3-second polling loop with WebSocket API Gateway. The Store Lambda pushes to the connection when processing completes. Better user experience, fewer API calls.

**Analytics materialization** — The current analytics Lambda does a full DynamoDB scan for every dashboard load. At scale this breaks. I'd use DynamoDB Streams to trigger an aggregation Lambda that updates pre-computed metrics in a separate table. Dashboard reads become O(1) instead of O(n).

**CI/CD completion** — The GitHub Actions workflows are written but the OIDC role and GitHub secrets aren't configured yet. Setting those up is straightforward but I haven't done it. With that done, every push to main automatically deploys.

**WAF protection** — Add AWS WAF in front of API Gateway to block SQL injection, XSS, and rate-limit by IP. Important before sharing the CloudFront URL publicly.

**KMS encryption** — Replace AWS-managed S3 and DynamoDB encryption with customer-managed KMS keys. Required for compliance in financial services.

**Multi-region** — S3 Cross-Region Replication for the invoice bucket, DynamoDB Global Tables, Route 53 latency routing. Currently single region us-east-1.

**Forgot password flow** — Cognito supports it natively via `resetPassword` and `confirmResetPassword`. The frontend just needs two new form modes. Public users who forget their password are currently stuck.

**Invoice deduplication** — Generate a SHA-256 hash of the file content at upload time. Check DynamoDB for an existing hash before processing. Prevents duplicate work on re-uploads.

**Bedrock Guardrails** — Add content filtering to prevent PII from being sent to the LLM. Important for invoices containing employee data or personal addresses."

---

## 11. QUICK CHEAT SHEET

*Glance at this 5 minutes before walking into the room.*

---

| Question | One-Line Answer |
|----------|----------------|
| What is it? | Serverless invoice auditing with OCR + AI + risk scoring on AWS |
| How many services? | 14 AWS services across 5 CDK stacks |
| How many Lambdas? | 8 — 3 API + 5 pipeline |
| Processing time? | 15–30 seconds per invoice |
| Cost? | ~$17–20/month at 1,000 invoices |
| Multi-tenancy? | Cognito sub as DynamoDB partition key |
| Why not EC2? | Event-driven, stateless, pay-per-invocation fits better |
| Why SQS? | S3 can't invoke Step Functions; buffering + DLQ |
| Why Express SFN? | Under 5 minutes, cheaper, high-volume |
| Why DynamoDB? | Variable schema, serverless, natural partition key |
| Why Bedrock Nova Micro? | AWS-native IAM, cheap, structured JSON output |
| Why Textract AnalyzeExpense? | Purpose-built for invoices, typed fields |
| Risk score formula? | Math error +40, missing fields +8 each, duplicates +15, non-standard # +10, AI HIGH +15, MEDIUM +7, LOW +3 |
| What breaks at scale? | Textract quota + Analytics full scan |
| Biggest challenge? | Lambda shared module layer structure on Windows |

---

## 12. THREE VERSIONS OF THE PITCH

### 30 Seconds (elevator)

"I built NovaMind — a serverless AWS platform that automatically audits invoices using Amazon Textract for OCR, Bedrock AI for anomaly detection, and a deterministic rules engine for risk scoring. Upload an invoice image, get a risk score and AI explanation in 30 seconds. Built on Lambda, Step Functions, SQS, DynamoDB, and CloudFront. Infrastructure as code with CDK."

---

### 2 Minutes (phone screen)

Use the opening section at the top of this document.

---

### 5–10 Minutes (technical panel)

1. Start with the 2-minute opening
2. Draw the architecture — walk through the 22 components in Section 3
3. Explain the 4-stage pipeline in detail
4. Explain the risk scoring formula
5. Describe the CORS challenge or the Lambda layer challenge — shows real engineering
6. Invite questions

---

*Built by [Aamir](https://github.com/aamir490) — github.com/aamir490 — linkedin.com/in/aamir-imran*
