# Your question

**Start `10-Amazon-Bedrock-Nova-Micro-and-Prompting.md`.**

File 09 ended here:

```text
Invoice
   ↓
Amazon Textract
   ↓
Structured invoice fields + raw OCR text
   ↓
?
```

File 10 explains what happens at that `?`:

```text
Extracted Invoice Data
        ↓
AI Analysis Lambda
        ↓
Amazon Bedrock
        ↓
Amazon Nova Micro
        ↓
AI Findings
        ↓
Deterministic Risk Rules
```

The most important project-specific fact is:

> **This project uses Amazon Bedrock with `us.amazon.nova-micro-v1:0`. The model receives extracted invoice fields and raw OCR text—not the original invoice image—and is asked to return anomalies, a summary, and confidence.** :chatgpt-content-reference{index="0"}

---

# 10 — Amazon Bedrock, Nova Micro and Prompting

## 1. What Will I Learn?

In this file, I will understand:

- What Amazon Bedrock is
- What a foundation model is
- What Amazon Nova Micro is doing here
- Bedrock vs Nova Micro
- Why Textract comes before Bedrock
- What the AI Lambda sends to the model
- What prompt engineering means
- How this project's prompt is constructed
- Structured fields vs raw OCR text
- What output the model is asked to produce
- `temperature`, `topP`, and `maxTokens`
- Why low temperature is used
- JSON parsing vs JSON validation
- Hallucination risk
- Retry behavior
- What happens when Bedrock fails
- Why `COMPLETED` can be misleading
- Why this project is **not RAG**
- Why this project is **not Agentic AI**
- Current limitations and production improvements
- 10 project-specific interview questions with word-by-word answers

---

# 2. Where Are We in the Architecture?

We have reached the second major Step Functions processing stage:

```text
Step Functions
      │
      ▼
┌──────────────────────┐
│ 1. Document Process  │
│                      │
│ Textract             │
└──────────┬───────────┘
           ↓
    Extracted Data
           ↓
┌──────────────────────┐
│ 2. AI Analysis       │
│                      │
│ AI Lambda            │
│      ↓               │
│ Amazon Bedrock       │
│      ↓               │
│ Nova Micro           │
└──────────┬───────────┘
           ↓
      AI Findings
           ↓
┌──────────────────────┐
│ 3. Risk Rules        │
└──────────────────────┘
```

File 10 focuses entirely on:

**AI Analysis Lambda → Bedrock → Nova Micro → AI response**

---

# 3. First — What Is Amazon Bedrock?

Very simply:

> **Amazon Bedrock is the AWS service through which this application accesses a foundation model.**

Think of the relationship like this:

```text
Your Python Code
      ↓
Amazon Bedrock
      ↓
Foundation Model
      ↓
AI Response
```

Your application doesn't contain the Nova model itself.

Instead, the Lambda makes a request through AWS.

---

# 4. Bedrock vs Nova Micro

Do not confuse these.

## Amazon Bedrock

Think:

> **The AWS managed service/platform used to access the model.**

## Amazon Nova Micro

Think:

> **The actual foundation model selected by this application.**

So:

```text
AI Lambda
   ↓
Amazon Bedrock
   ↓
Nova Micro
```

A useful interview sentence is:

> “Amazon Bedrock is the managed AWS service I use to invoke the foundation model, and Nova Micro is the model used by my application.”

---

# 5. Which Model Does This Project Actually Use?

The Codex analysis found the exact model ID:

```text
us.amazon.nova-micro-v1:0
```

and the provider is:

```text
Amazon Bedrock
```

The invocation uses:

```text
bedrock_runtime.invoke_model
```

:chatgpt-content-reference{index="1"}

This is important because you should **not** say:

```text
Claude
GPT
Titan
Llama
```

when explaining the current implementation.

Your actual project uses:

> **Amazon Nova Micro.**

---

# 6. What Is a Foundation Model?

At beginner level:

> A foundation model is a large AI model trained on broad data that can perform language-related tasks from instructions and context.

In your project, you are not training Nova Micro.

You are doing:

```text
Existing Foundation Model
        +
Your Invoice Context
        +
Your Instructions
        ↓
Invoice Analysis
```

So this project is performing:

> **model inference**

not:

> **model training**

and not:

> **fine-tuning**

based on the Codex project evidence.

---

# 7. Does Nova Micro Receive the Invoice PDF?

**No.**

This is one of your most important interview facts.

The flow is:

```text
Invoice PDF/Image
        ↓
Amazon Textract
        ↓
Structured Fields
+
Raw OCR Text
        ↓
AI Lambda
        ↓
Nova Micro
```

The Codex analysis explicitly states that the Bedrock request contains one user message with **structured fields and raw OCR text**. :chatgpt-content-reference{index="2"}

Therefore don't say:

> “Nova Micro looks directly at my invoice image.”

That's not what this implementation does.

---

# 8. Why Does Textract Come Before Bedrock?

Because the two services solve different problems.

```text
TEXTRACT
=
Extract information
```

```text
BEDROCK + NOVA MICRO
=
Analyze information
```

For example:

```text
Invoice PDF
    ↓
Textract
    ↓
Vendor = ABC Ltd
Total = $5,000
Invoice = INV-123
Line Items = [...]
Raw OCR = ...
    ↓
Nova Micro
    ↓
Potential anomaly findings
```

This separation is central to the architecture.

---

# 9. What Does the AI Lambda Do?

At a high level:

```text
Receive OCR output
       ↓
Build prompt
       ↓
Create Bedrock request
       ↓
Invoke Nova Micro
       ↓
Receive text response
       ↓
Parse response
       ↓
Return AI findings
```

So the AI Lambda acts as the application layer between:

```text
Step Functions
```

and:

```text
Amazon Bedrock
```

---

# 10. What Is Prompt Engineering?

Very simple definition:

> **Prompt engineering means designing the instructions and context given to the model so it knows what task to perform and what kind of output we expect.**

Imagine simply sending:

```text
Analyze this.
```

That's vague.

Instead, the project provides:

```text
Role/instructions
+
Structured invoice data
+
Line items
+
Raw OCR text
+
Expected output structure
```

That gives the model much more context.

---

# 11. How Is This Project's Prompt Constructed?

Codex inspected `build_analysis_prompt()`.

The prompt asks the model to behave as an:

> **invoice auditor**

It provides:

```text
Structured invoice fields
        +
Line items
        +
Raw OCR text
```

Then it asks for information including:

```text
Anomaly type

Severity

Description

Affected field

Summary

Confidence
```

:chatgpt-content-reference{index="3"}

---

# 12. Conceptual Prompt Structure

Do **not** treat this as the literal source code. It is a learning model:

```text
ROLE / TASK
────────────
Act as an invoice auditor.

INVOICE INFORMATION
───────────────────
Vendor: ...
Invoice Number: ...
Date: ...
Total: ...
Subtotal: ...
Tax: ...

LINE ITEMS
──────────
...

RAW OCR TEXT
────────────
...

TASK
────
Analyze the invoice for anomalies.

EXPECTED OUTPUT
───────────────
{
   anomalies: [...],
   summary: "...",
   confidence: ...
}
```

That's the basic prompt architecture.

---

# 13. Why Include Structured Fields?

Suppose Textract already extracted:

```text
vendor = ABC Ltd

total = 5000

invoice_number = INV-123
```

Instead of forcing the model to rediscover these values from raw OCR text, the application can explicitly provide them.

This gives the model direct access to the important invoice fields.

---

# 14. Why Also Include Raw OCR Text?

Because structured extraction may not capture every useful piece of document context.

Imagine the invoice contains:

```text
SPECIAL NOTE:
Payment account recently changed.
```

That information might exist in the raw OCR text even if it isn't represented as one of the application's main structured fields.

So the model receives:

```text
Structured Data
      +
Raw OCR Context
```

This gives it broader information for analysis.

---

# 15. What Does the Model Return?

The requested output is conceptually:

```text
{
  "anomalies": [...],
  "summary": "...",
  "confidence": ...
}
```

Each anomaly is expected to contain information such as:

```text
type

severity

description

affected_field
```

:chatgpt-content-reference{index="4"}

This is much easier for application code to work with than unrestricted prose.

---

# 16. Example

Imagine the extracted invoice is:

```text
Vendor: ABC Ltd
Invoice: 12
Total: $10,000
```

The model might conceptually return something shaped like:

```text
{
  "anomalies": [
    {
      "type": "...",
      "severity": "HIGH",
      "description": "...",
      "affected_field": "..."
    }
  ],
  "summary": "...",
  "confidence": 0.8
}
```

This is only an illustrative shape.

Do not memorize invented anomaly content as actual project output.

---

# 17. Important — AI Does NOT Calculate the Final Score

This is one of the most important architecture facts.

The model generates:

```text
AI Findings
```

Then the next stage runs:

```text
Deterministic Python Rules
```

which calculates the final numeric risk score.

So:

```text
Nova Micro
    ↓
AI anomalies
    ↓
Python rules
    ↓
Final score
```

Not:

```text
Nova Micro
    ↓
Final authoritative fraud score
```

Codex explicitly identifies deterministic rules as the source of the final numeric score. :chatgpt-content-reference{index="5"}

---

# 18. Why Is This Design Useful?

Generative AI is probabilistic.

Deterministic code is predictable.

So this project combines:

```text
Generative AI
     +
Business Rules
     ↓
Hybrid Analysis
```

For example:

Nova Micro can identify a semantic anomaly.

Then Python can apply a fixed rule:

```text
HIGH AI anomaly
→ add defined risk points
```

We'll study the exact scoring formula in the next file.

---

# 19. Bedrock Request Configuration

The Codex analysis found these exact settings:

```text
maxTokens = 1500

temperature = 0.2

topP = 0.9
```

And the application can make up to:

```text
5 application-level attempts
```

meaning:

```text
1 initial attempt
+
4 retries
```

:chatgpt-content-reference{index="6"}

You should know what these mean rather than simply memorizing the numbers.

---

# 20. What Is `maxTokens`?

Very simply:

> **`maxTokens` limits how much output the model can generate.**

Your configuration:

```text
maxTokens = 1500
```

means the application limits the model's generated response length.

Important distinction:

```text
maxTokens
≠
input token limit
```

The Codex analysis found that the application does **not** have an explicit token-budgeting or truncation strategy for its input prompt. :chatgpt-content-reference{index="7"}

---

# 21. What Is Temperature?

Temperature influences output randomness.

Simple mental model:

```text
Lower temperature
        ↓
More consistent / less random
```

```text
Higher temperature
        ↓
More varied / creative
```

Your project uses:

```text
temperature = 0.2
```

For invoice analysis, this makes conceptual sense because the goal is structured analysis, not creative storytelling.

But don't say:

> “0.2 guarantees correct answers.”

It does not.

---

# 22. What Is `topP`?

`topP` is another generation-control parameter.

At beginner level, think:

> **It controls how broadly the model considers possible next-token choices.**

Your project uses:

```text
topP = 0.9
```

For interviews, first understand:

```text
temperature
+
topP
=
generation behavior controls
```

They do **not** provide correctness guarantees.

---

# 23. Is There a Separate System Prompt?

This is a project-specific detail.

**No.**

Codex found:

> **There is no separate system-message object. The role instruction is inside the user prompt.** :chatgpt-content-reference{index="8"}

So conceptually:

```text
messages
   ↓
User Message
   ├── role/task instruction
   ├── invoice fields
   ├── OCR text
   └── requested output
```

Don't tell an interviewer:

> “I use a separate system prompt to define the invoice-auditor role.”

That isn't the current implementation.

---

# 24. Prompt Instruction vs Guarantee

The prompt tells the model not to invent findings.

That's useful.

But:

```text
Instruction
≠
Guarantee
```

A prompt can say:

> “Do not invent anything.”

But a generative model can still produce incorrect or unsupported output.

This is why:

```text
Prompt Engineering
+
Output Validation
```

are both important.

---

# 25. What Is Hallucination?

In this context:

> **Hallucination means the model produces information that is not properly supported by the invoice context.**

For example, if the invoice contains no evidence of:

```text
duplicate bank account
```

but the model invents that finding, that's a problem.

For financial workflows, this matters because AI findings can affect downstream scoring.

---

# 26. Prompt Engineering Is Not Validation

Suppose your prompt says:

```text
Return valid JSON.
```

The model might return:

```text
```json
{
   ...
}
```
```

or malformed JSON.

Or it might return syntactically valid JSON with incorrect structure.

Therefore:

```text
"Please return JSON"
```

does not equal:

```text
Guaranteed valid application data
```

---

# 27. How Does This Project Parse the Response?

Codex found that `_parse_json_response()` tries several steps:

```text
1. Direct JSON parsing

2. Remove markdown fences

3. Extract content between
   first { and final }

4. Use fallback if parsing fails
```

:chatgpt-content-reference{index="9"}

This makes the parser tolerant of some common LLM formatting behavior.

---

# 28. Example — Markdown Fence

The model might return:

````text
```json
{
  "anomalies": [],
  "summary": "...",
  "confidence": 0.9
}
```
````

Instead of failing immediately, the parser attempts to remove the formatting wrapper and parse the JSON.

That's useful.

But another major problem remains.

---

# 29. Parsing Is NOT Validation

This distinction is extremely important.

Suppose the model returns:

```text
[
  "hello",
  "world"
]
```

That is:

```text
Valid JSON ✓
```

But your application expected:

```text
{
   "anomalies": [...],
   "summary": "...",
   "confidence": ...
}
```

So:

```text
Valid JSON
≠
Valid application response
```

---

# 30. Current Output-Validation Limitation

Codex found that the project mostly validates JSON **syntax**, not the complete semantic/schema correctness.

Examples of problematic but potentially parseable responses include:

```text
JSON list instead of object

anomalies = null

anomalies containing strings

unsupported severity

missing fields

confidence outside expected range
```

:chatgpt-content-reference{index="10"}

This is an important production gap.

---

# 31. But Doesn't the Project Have Types?

Yes—Codex found helpful types/models elsewhere in the repository.

However:

> **The AI Lambda does not actually enforce the available Pydantic model on the model output.** :chatgpt-content-reference{index="11"}

This distinction is important.

Having:

```text
Pydantic Model
```

in the repository does not automatically mean:

```text
Runtime AI output validation
```

is happening.

---

# 32. Stronger Output Validation

A stronger production approach would conceptually validate:

```text
Top-level value is object?
        ↓
anomalies is list?
        ↓
Each anomaly has expected fields?
        ↓
Severity allowed?
        ↓
Description valid?
        ↓
Confidence in expected range?
        ↓
PASS
```

If validation fails:

```text
Do not blindly use output
        ↓
Retry / fallback / review
```

The exact policy depends on business requirements.

---

# 33. What Happens If Parsing Completely Fails?

According to the Codex interview material, the current fallback produces no anomalies and a summary recommending manual review. :chatgpt-content-reference{index="12"}

Conceptually:

```text
Model Response
      ↓
Cannot parse
      ↓
Fallback
      ↓
No AI anomalies
+
Review-oriented summary
```

This prevents one parsing problem from necessarily destroying the entire invoice pipeline.

But it creates another concern.

---

# 34. What Happens When Bedrock Fails?

Handled Bedrock errors can produce:

```text
anomalies = empty

summary = "analysis unavailable" style result

confidence = 0
```

Then:

```text
Pipeline continues
      ↓
Deterministic scoring
      ↓
Result stored
      ↓
COMPLETED
```

:chatgpt-content-reference{index="13"}

This is a very important behavior.

---

# 35. Why Continue Without AI?

There is a legitimate architectural reason:

Suppose:

```text
Textract succeeded
```

but:

```text
Bedrock temporarily failed
```

You may still want to preserve:

```text
Extracted invoice data
+
Deterministic checks
```

instead of losing everything.

So the current design favors some graceful degradation.

But the way that degradation is represented has a weakness.

---

# 36. The Dangerous Interpretation

Suppose Invoice A gets:

```text
Bedrock succeeds
AI anomalies = none
Risk score = LOW
```

Invoice B gets:

```text
Bedrock FAILS
AI anomalies = empty
Risk score = LOW
```

These two situations are **not equivalent**.

Invoice A means:

> AI analysis ran and didn't report anomalies.

Invoice B means:

> AI analysis wasn't successfully available.

Yet both could potentially end with a low score.

Codex explicitly warns that a low score after AI failure should not be interpreted as equivalent to a fully analyzed low-risk invoice. :chatgpt-content-reference{index="14"}

---

# 37. Better Production Status

Instead of only:

```text
COMPLETED
```

a production system could distinguish:

```text
COMPLETED
```

from something such as:

```text
COMPLETED_WITH_WARNINGS
```

or maintain:

```text
processing_status = COMPLETED

ocr_status = SUCCESS

ai_status = FAILED

risk_status = PARTIAL
```

Then users and operators know:

> **The invoice finished processing, but AI analysis was degraded.**

This is a proposed improvement, not current behavior.

---

# 38. Retry Behavior

The Codex report says throttling can be retried using:

```text
Exponential backoff
+
Jitter
```

and the application allows up to:

```text
5 attempts
```

total. :chatgpt-content-reference{index="15"}

Conceptually:

```text
Attempt 1
   ↓
Throttled
   ↓
Wait
   ↓
Attempt 2
   ↓
Throttled
   ↓
Wait longer
   ↓
...
```

---

# 39. What Is Exponential Backoff?

Instead of retrying:

```text
retry
retry
retry
retry
retry
```

immediately, you progressively wait.

Conceptually:

```text
Failure
 ↓
wait
 ↓
Retry
 ↓
wait longer
 ↓
Retry
```

This helps reduce pressure on a temporarily overloaded/throttled service.

---

# 40. What Is Jitter?

Imagine 100 Lambda executions are throttled at the same time.

Without jitter:

```text
100 requests fail
      ↓
all wait 2 seconds
      ↓
all retry together
      ↓
another traffic spike
```

Jitter introduces some randomness into retry timing:

```text
Request A → retry after slightly different wait
Request B → different wait
Request C → different wait
```

This reduces synchronized retry spikes.

---

# 41. Does Every Failure Safely Fall Back?

**No.**

This is important.

The Codex interview material explicitly warns:

> A Lambda timeout cannot simply be caught by an ordinary exception block, and not every network exception is necessarily converted into the graceful AI fallback. :chatgpt-content-reference{index="16"}

Therefore don't say:

> “Any Bedrock problem is automatically handled and the pipeline always continues.”

That's too strong.

---

# 42. Input Token Management Limitation

The project limits:

```text
OUTPUT
→ maxTokens = 1500
```

But Codex found:

> **There is no explicit input token-budgeting or truncation strategy.** :chatgpt-content-reference{index="17"}

Remember the prompt contains:

```text
Structured fields
+
Line items
+
Raw OCR text
```

For larger documents, that can grow.

A stronger implementation should deliberately manage prompt size.

---

# 43. Why Input Size Matters

Larger input can affect:

```text
Model limits

Latency

Cost

Reliability
```

Therefore a production system could decide:

```text
What information is essential?

How much raw OCR should be included?

Should text be truncated?

Should sections be summarized?

Should processing be split?
```

But don't claim the current project already implements those strategies.

---

# 44. Is This RAG?

**No.**

This is a very important interview answer.

RAG generally requires retrieval of external/relevant information that is added to the model context.

But Codex found:

```text
No vector retrieval

No embeddings

No vector database

No chunk retrieval

No historical database retrieval
feeding the prompt
```

:chatgpt-content-reference{index="18"}

Therefore:

```text
Textract
 ↓
Prompt
 ↓
Nova Micro
```

is **not RAG**.

---

# 45. But We Send Data to the Prompt. Isn't That RAG?

No.

Providing application data directly to a model does not automatically make something RAG.

Your flow is:

```text
Current Invoice
      ↓
Textract
      ↓
Prompt
```

There is no retrieval system doing something like:

```text
Query
 ↓
Search knowledge source
 ↓
Retrieve relevant documents
 ↓
Add documents to prompt
 ↓
LLM
```

So don't label this project as RAG.

---

# 46. Is This Agentic AI?

Also **no**, based on the current implementation.

Codex found:

```text
No model-selected tools

No iterative agent decisions

No autonomous planning loop

No LangGraph
```

:chatgpt-content-reference{index="19"}

Step Functions controls a predetermined workflow:

```text
OCR
 ↓
AI
 ↓
Rules
 ↓
Storage
```

The model doesn't decide:

> “Which tool should I use next?”

Therefore:

> **Fixed orchestration is not the same as agentic AI.**

---

# 47. Important Terminology

You can confidently describe this as:

> **A serverless AI-powered invoice intelligence application using Amazon Textract, Amazon Bedrock Nova Micro, deterministic risk rules, and AWS Step Functions orchestration.**

Do **not** add:

```text
RAG
Agentic AI
LangGraph
Vector Search
Trained Fraud ML Model
```

because the Codex analysis explicitly says those are not implemented. :chatgpt-content-reference{index="20"}

---

# 48. What About Model Confidence?

Nova Micro is asked to return:

```text
confidence
```

But be careful.

The Codex analysis specifically warns:

> **This confidence is model-generated; it is not measured accuracy.** :chatgpt-content-reference{index="21"}

These are different:

```text
Model says:
confidence = 0.90
```

does **not** mean:

```text
System has scientifically measured
90% accuracy
```

Don't make that claim in an interview.

---

# 49. Why Model Evaluation Matters

Suppose someone asks:

> “Why Nova Micro? Is it the best model for invoice anomaly detection?”

The correct answer is not:

> “Yes, it is the best.”

Codex specifically notes that the project is missing evaluation evidence for that claim. :chatgpt-content-reference{index="22"}

A proper comparison would require an evaluation dataset and metrics.

Conceptually:

```text
Representative invoices
       ↓
Expected findings
       ↓
Model outputs
       ↓
Evaluate
       ↓
Compare models/prompts
```

Without that, you can explain why it fits the AWS integration, but not prove it's objectively best.

---

# 50. Prompt Injection Consideration

Because raw OCR text becomes part of the model prompt, remember that document content is **untrusted input**.

Conceptually, an invoice could contain text resembling:

```text
Ignore previous instructions...
```

A production design should not assume all document text is benign instructions.

This specific mitigation is not established by the Codex report, so treat prompt-injection hardening as a **production improvement**, not a current feature.

---

# 51. Stronger Production AI Layer

A stronger future design could look like:

```text
Textract Output
      ↓
Normalize + Validate
      ↓
Control Prompt Size
      ↓
Build Structured Prompt
      ↓
Bedrock Nova
      ↓
Schema Validation
      ↓
Valid?
  ┌───┴────┐
 YES       NO
  ↓         ↓
Continue   Retry/Fallback
  ↓         ↓
Risk      Explicit degraded
Rules     status / review
```

This improves reliability around the probabilistic model boundary.

---

# 52. What Is Implemented?

According to the Codex analysis:

```text
✓ Amazon Bedrock

✓ Nova Micro

✓ Model ID:
  us.amazon.nova-micro-v1:0

✓ bedrock_runtime.invoke_model

✓ Structured invoice fields as input

✓ Line items as input

✓ Raw OCR text as input

✓ Invoice-auditor instruction

✓ Requested JSON-style output

✓ Anomalies

✓ Summary

✓ Confidence

✓ maxTokens = 1500

✓ temperature = 0.2

✓ topP = 0.9

✓ JSON parsing/fallback logic

✓ Application-level retry behavior
```

:chatgpt-content-reference{index="23"}

---

# 53. What Is NOT Implemented / Limited?

Based on the same project analysis:

```text
⚠ No separate system prompt

⚠ No explicit input token budgeting

⚠ Prompt instruction does not guarantee truth

⚠ JSON parsing is not full schema validation

⚠ Existing Pydantic model is not enforced here

⚠ Handled AI failure can continue to COMPLETED

⚠ AI confidence is not measured accuracy

⚠ No model-comparison evaluation proving
  Nova Micro is best

❌ No RAG

❌ No vector retrieval

❌ No agentic AI

❌ No LangGraph

❌ No trained fraud-detection model
```

:chatgpt-content-reference{index="24"}

---

# 54. Interview Preparation — 10 Questions

## Q1 — What is Amazon Bedrock and how do you use it?

**Difficulty:** Basic

### Word-by-word practice answer

> “Amazon Bedrock is the managed AWS service I use to access the foundation model in my invoice-analysis pipeline. My AI Lambda invokes the model through the Bedrock runtime client. The model used in the current implementation is Amazon Nova Micro.”

---

## Q2 — Which model do you use and how is it invoked?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The AI Lambda invokes `us.amazon.nova-micro-v1:0` through the Bedrock runtime client using `invoke_model`. It sends one user message containing invoice fields and OCR text. The request limits output to 1,500 tokens and uses temperature 0.2 and top-p 0.9. It then reads the returned text content and attempts to parse it as JSON.”

This preserves the existing Codex interview answer. :chatgpt-content-reference{index="25"}

---

## Q3 — Does Nova Micro receive the invoice image?

**Difficulty:** Basic/Intermediate

### Word-by-word practice answer

> “No. In the current implementation, Textract processes the invoice first. Nova Micro receives the extracted structured invoice fields, line items and raw OCR text. It does not directly receive the original invoice image.”

---

## Q4 — How is your prompt constructed?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The prompt asks the model to act as an invoice auditor. It provides structured invoice fields and line items followed by the raw OCR text. It asks the model to return anomaly information including type, severity, description and affected field, along with a summary and confidence. The prompt tells the model not to invent findings, but I treat that as guidance rather than a correctness guarantee.”

This closely follows the Codex-generated practice answer. :chatgpt-content-reference{index="26"}

---

## Q5 — Do you use a system prompt?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Not as a separate system-message object in the current implementation. The invoice-auditor role and task instructions are included inside the single user-message prompt together with the invoice context.”

---

## Q6 — How do you validate the model output?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current implementation mainly validates JSON syntax. It tries direct JSON parsing, removes common markdown wrappers and can extract content between braces before using a fallback. However, valid JSON does not guarantee a valid application response. The repository contains helpful Pydantic types, but the AI Lambda does not enforce them on the model output. For production, I would validate the top-level object, anomaly fields, allowed severities, length limits and confidence range before scoring.”

:chatgpt-content-reference{index="27"}

---

## Q7 — What happens when Bedrock fails?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The application has retry handling for cases such as throttling, with up to five application-level attempts including the initial call. Certain handled failures are converted into an empty AI result with zero confidence and an analysis-unavailable style summary, allowing deterministic processing to continue. The limitation is that this can still lead to a completed job even though AI analysis was degraded, so I would expose that as a separate state requiring review.”

:chatgpt-content-reference{index="28"}

---

## Q8 — Why did you choose Nova Micro?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “Nova Micro fits the existing AWS Bedrock integration and the text-analysis role used by this project. However, I would not claim that it is objectively the best model because the repository does not contain a proper comparative model evaluation. For a production decision, I would evaluate candidate models on representative invoice data for output quality, latency, cost and reliability before making that claim.”

---

## Q9 — Is this project RAG or Agentic AI?

**Difficulty:** Intermediate / Pressure

### Word-by-word practice answer

> “No. I would not describe the current implementation as RAG or Agentic AI. There is no embedding or vector-retrieval pipeline adding external knowledge to the prompt, and there is no model-driven tool selection or autonomous agent loop. Step Functions provides fixed workflow orchestration, while Nova Micro performs one defined invoice-analysis task.”

:chatgpt-content-reference{index="29"}

---

## Q10 — What would you improve in the Bedrock integration?

**Difficulty:** Advanced / Design

### Word-by-word practice answer

> “I would first enforce strict schema validation on the model response rather than relying mainly on JSON parsing. I would add explicit input token management, strengthen prompt-injection handling for untrusted OCR text, clearly distinguish successful AI analysis from degraded fallback processing, and build a representative evaluation dataset to measure prompt and model quality. I would also make retry behavior and observability explicit so AI failures cannot silently look equivalent to successful low-risk analysis.”

---

# 55. Interview Pressure Chain

An interviewer may start with:

> **“How are you using Bedrock?”**

and continue:

```text
Which model?
   ↓
Exact model ID?
   ↓
How do you invoke it?
   ↓
What does the model receive?
   ↓
Does it receive the image?
   ↓
Why Textract first?
   ↓
How is your prompt built?
   ↓
Do you use a system prompt?
   ↓
What output do you request?
   ↓
What is temperature?
   ↓
Why 0.2?
   ↓
What is topP?
   ↓
What is maxTokens?
   ↓
How do you parse JSON?
   ↓
Is parsing the same as validation?
   ↓
Do you enforce Pydantic?
   ↓
What happens if Bedrock fails?
   ↓
How many retries?
   ↓
Can a failed AI call still become COMPLETED?
   ↓
Could that create a misleading low-risk result?
   ↓
How would you fix it?
   ↓
Is this RAG?
   ↓
Is this Agentic AI?
   ↓
Why Nova Micro?
   ↓
How did you evaluate the model?
```

If you can answer that chain comfortably, you'll understand this part of the project rather than merely knowing that “Bedrock is used.”

---

# 56. One Diagram to Remember

```text
                  TEXTRACT OUTPUT
                        │
             ┌──────────┴──────────┐
             │                     │
      Structured Fields        Raw OCR Text
             │                     │
             └──────────┬──────────┘
                        ↓
                  AI LAMBDA
                        ↓
                 BUILD PROMPT
                        ↓
              AMAZON BEDROCK
                        ↓
        us.amazon.nova-micro-v1:0
                        ↓
                MODEL RESPONSE
                        ↓
                 JSON PARSER
                        ↓
          ┌─────────────┼─────────────┐
          ↓             ↓             ↓
      Anomalies       Summary     Confidence
          │
          ↓
    DETERMINISTIC
      RISK RULES
          ↓
     FINAL SCORE
```

The mental model is:

```text
Textract = EXTRACT

Nova Micro = ANALYZE

Python Rules = SCORE

Step Functions = ORCHESTRATE
```

That four-line distinction is extremely valuable for explaining your architecture.

---

# 57. Five Facts You Must Never Mix Up

**1. Bedrock and Nova Micro are not the same thing.**

```text
Bedrock = AWS model-access service
Nova Micro = selected foundation model
```

**2. Nova Micro does not directly receive the invoice image in this implementation.**

```text
Invoice → Textract → text/fields → Nova Micro
```

**3. Nova Micro does not produce the final numeric risk score.**

```text
Nova → AI findings → Python rules → score
```

**4. Valid JSON does not mean valid AI output.**

```text
Parsing ≠ Schema Validation
```

**5. This project is neither RAG nor Agentic AI.**

The local analysis found no retrieval/vector pipeline or autonomous model-controlled agent loop. :chatgpt-content-reference{index="30"}

---

# 58. Check Your Understanding

Before we move to **`11-Deterministic-Risk-Scoring-and-Business-Rules.md`**, answer these three in your own words:

**Question 1:** What is the difference between **Amazon Bedrock** and **Amazon Nova Micro**, and what exactly does Nova Micro receive from this project?

**Question 2:** Suppose Nova Micro returns perfectly valid JSON, but `"anomalies": null` and `"confidence": 500`. Why is **successful JSON parsing not enough**?

**Question 3:** Suppose Bedrock completely fails, the fallback produces no AI anomalies, and deterministic rules give a LOW score. Why would it be dangerous to tell the user simply **“This invoice is low risk”**?