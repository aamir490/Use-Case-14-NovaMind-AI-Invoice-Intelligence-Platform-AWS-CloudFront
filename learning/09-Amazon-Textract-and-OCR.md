# Your question

**Start `09-Amazon-Textract-and-OCR.md`.**

File 08 brought us inside the Step Functions workflow. Now we focus deeply on its first major processing stage:

> **How does this project convert an uploaded invoice PDF/image into structured information that Python and Bedrock can understand?**

The most important project-specific fact is:

> **The OCR Lambda calls Amazon Textract `AnalyzeExpense`. It reads the first `ExpenseDocument`, extracts invoice fields and line items, collects raw `LINE` text, and passes this information to the next AI stage.** :chatgpt-content-reference{index="0"}

---

# 09 — Amazon Textract and OCR

## 1. What Will I Learn?

In this file, I will understand:

- What OCR means
- What Amazon Textract does
- Why this project uses `AnalyzeExpense`
- Where Textract appears in the architecture
- How the OCR Lambda calls Textract
- What goes into Textract
- What comes back
- What `ExpenseDocuments` means
- Summary fields vs line items vs raw text
- Which fields this project's parser extracts
- Why values remain mostly strings
- Why Textract and Bedrock have different jobs
- Confidence-score limitations
- Date/currency normalization limitations
- Multipage-document limitations
- How OCR errors affect downstream AI and risk scoring
- Production improvements
- 10 interview questions with word-by-word answers

---

# 2. Where Are We in the Architecture?

Our flow is now:

```text
Invoice
   ↓
Amazon S3
   ↓
SQS
   ↓
Trigger Lambda
   ↓
Step Functions
   ↓
┌───────────────────────────┐
│ Document Processing       │
│                           │
│ OCR Lambda                │
│      ↓                    │
│ Amazon Textract           │
│ AnalyzeExpense            │
└─────────────┬─────────────┘
              ↓
       Extracted Data
              ↓
        Bedrock Stage
```

File 09 focuses on the highlighted section.

---

# 3. First — What Is OCR?

**OCR = Optical Character Recognition.**

Very simply:

> OCR converts text visible inside an image or document into machine-readable text.

Imagine an invoice contains:

```text
INVOICE #INV-2026-100

Vendor: ABC Technologies

Date: 26/09/2026

Laptop       $800
Keyboard      $50

Total:       $850
```

To a human, this is easy to read.

But the application first receives something like:

```text
invoice.pdf
```

It needs software to extract usable information.

That's where document processing/OCR comes in.

---

# 4. What Is Amazon Textract?

Amazon Textract is the AWS document-analysis service used by this project.

But don't explain your implementation as merely:

> “Textract converts image to text.”

Your project uses the invoice/receipt-oriented operation:

```text
AnalyzeExpense
```

Codex found:

> **B5 calls synchronous Textract `AnalyzeExpense`.** :chatgpt-content-reference{index="1"}

That distinction matters.

---

# 5. Why `AnalyzeExpense`?

There are two different problems:

### Problem A — Read text

```text
Invoice image
     ↓
"Vendor ABC"
"Total 850"
```

### Problem B — Understand invoice structure

```text
Vendor
→ ABC

Invoice Number
→ INV-2026-100

Total
→ 850

Line Items
→ Laptop
→ Keyboard
```

Your project needs the second type of information.

Codex describes the design choice as:

> **Expense extraction rather than generic text OCR because it produces useful summary and line-item structures.** :chatgpt-content-reference{index="2"}

---

# 6. Textract's Responsibility

In this project, think:

```text
DOCUMENT
   ↓
TEXTRACT
   ↓
EXTRACTED INFORMATION
```

Textract is responsible for extracting information from the invoice.

It is **not** responsible for:

```text
❌ Final fraud/risk score

❌ Generative AI reasoning

❌ Cognito authentication

❌ Workflow orchestration

❌ DynamoDB application queries
```

Those responsibilities belong elsewhere.

---

# 7. Textract vs Bedrock

This distinction is critical.

## Textract

Answers:

> **What information is written in this invoice?**

Example:

```text
Vendor = ABC Ltd
Invoice Number = INV-123
Total = $850
```

## Bedrock / Nova Micro

Answers something closer to:

> **What semantic anomalies or suspicious patterns can be identified from the extracted invoice information?**

Therefore:

```text
Invoice
   ↓
Textract
   ↓
Extract
   ↓
Bedrock
   ↓
Analyze
```

---

# 8. Does Nova Micro Receive the Invoice Image?

No.

This is an important project-specific interview fact.

Codex says the AI implementation sends:

> **structured fields and raw OCR text** to Nova Micro. :chatgpt-content-reference{index="3"}

So the actual conceptual flow is:

```text
PDF / Image
    ↓
Textract
    ↓
Fields + OCR Text
    ↓
Bedrock Nova Micro
```

Not:

```text
PDF/Image
    ↓
Nova Micro directly
```

Do not describe the current project as multimodal invoice-image inference.

---

# 9. What Does the OCR Lambda Send to Textract?

The invoice already exists in Amazon S3.

Conceptually:

```text
S3

Bucket:
invoice-bucket

Object:
invoices/.../invoice.pdf
```

The OCR Lambda tells Textract which S3 document to analyze.

Think:

```text
OCR Lambda
     ↓
"Analyze this S3 invoice"
     ↓
Textract AnalyzeExpense
```

The application doesn't need to manually perform OCR algorithms inside Python.

---

# 10. Synchronous `AnalyzeExpense`

This project specifically uses:

```text
AnalyzeExpense
```

rather than the asynchronous expense-analysis path. :chatgpt-content-reference{index="4"}

So conceptually:

```text
Lambda
   ↓
Call AnalyzeExpense
   ↓
Wait for response
   ↓
Parse response
```

This architectural choice becomes important when we discuss document size and multipage limitations.

---

# 11. What Does Textract Return?

Textract doesn't simply return:

```text
"Here is one huge string."
```

The response contains structured document information.

For this project, the important concept is:

```text
ExpenseDocuments
```

Conceptually:

```text
Textract Response
       │
       └── ExpenseDocuments
               │
               ├── Summary Fields
               │
               ├── Line Items
               │
               └── Blocks / text
```

The Python parser then transforms that AWS response into the simpler structure needed by the rest of the application.

---

# 12. Important Project Limitation — First Expense Document

Codex found something specific:

> **The parser reads only `ExpenseDocuments[0]`.** :chatgpt-content-reference{index="5"}

In simple English:

If Textract returns:

```text
ExpenseDocuments

[0] → Document 1
[1] → Document 2
[2] → Document 3
```

the current parser focuses on:

```text
ExpenseDocuments[0]
```

This is important when discussing complex/multipage inputs.

---

# 13. What Fields Does the Project Extract?

According to the Codex analysis, the parser extracts:

```text
Invoice Number

Vendor

Dates

Total

Subtotal

Tax

Line Items
```

It also collects raw `LINE` block text. :chatgpt-content-reference{index="6"}

So conceptually:

```text
Textract Response
       ↓
Python Parser
       ↓
{
  invoice_number,
  vendor,
  dates,
  total,
  subtotal,
  tax,
  line_items,
  raw_text
}
```

The exact object shape should come from the code; this is the learning model.

---

# 14. Summary Fields

An invoice contains top-level information.

For example:

```text
Invoice Number: INV-123

Vendor: ABC Ltd

Invoice Date: 26/09/2026

Subtotal: 800

Tax: 50

Total: 850
```

These are conceptually:

> **summary fields**

The parser maps the relevant Textract output into the application's invoice fields.

---

# 15. Line Items

Invoices often contain tables:

```text
Description    Quantity    Price

Laptop            1         800
Keyboard          1          50
```

These are:

> **line items**

The project extracts line-item information because later deterministic rules can use it.

For example, the risk logic performs a mathematical comparison involving extracted line-item `price` values and the total. :chatgpt-content-reference{index="7"}

So OCR quality directly affects risk scoring.

---

# 16. Raw OCR Text

The project also collects:

```text
LINE block text
```

from Textract. :chatgpt-content-reference{index="8"}

Why?

Because structured fields alone may not contain all useful invoice context.

Conceptually:

```text
Structured Fields
+
Raw OCR Text
        ↓
Bedrock Prompt
```

This gives Nova Micro more textual context for analysis.

---

# 17. Example

Suppose the invoice says:

```text
Vendor: ABC Electronics
Invoice: INV-7821
Date: 25/09/2026

Laptop × 1       $1000
Mouse × 1          $50

Subtotal          $1050
Tax                $189
Total             $1239
```

The application conceptually wants something like:

```text
vendor
→ ABC Electronics

invoice_number
→ INV-7821

date
→ 25/09/2026

subtotal
→ $1050

tax
→ $189

total
→ $1239

line_items
→ Laptop
→ Mouse
```

plus the raw OCR text.

That information then becomes input for downstream processing.

---

# 18. Important Limitation — Values Remain Mostly Strings

Codex found:

> **The parser retains values largely as strings.** :chatgpt-content-reference{index="9"}

For example:

```text
"$1,239.00"
```

may remain textual rather than immediately becoming a strongly normalized numeric representation.

Similarly:

```text
"25/09/2026"
```

can remain a string rather than becoming a standardized date object.

This matters later.

---

# 19. Extraction Is Not Normalization

This is an important engineering concept.

Suppose Textract gives:

```text
₹1,200.50
```

Extraction means:

> “I found the value `₹1,200.50`.”

Normalization means converting it into something consistently usable, such as conceptually:

```text
currency = INR
amount = 1200.50
```

The current parser does not fully normalize monetary and date values. :chatgpt-content-reference{index="10"}

So:

```text
Extraction
≠
Normalization
```

---

# 20. Currency Behavior

Codex found another specific implementation detail:

> **The parser defaults currency to USD.** :chatgpt-content-reference{index="11"}

This can be problematic if the application receives invoices from different currencies.

For example:

```text
₹10,000
```

and:

```text
$10,000
```

are not financially equivalent.

A stronger financial-processing system should explicitly determine and validate currency rather than relying on a default when the value is important.

---

# 21. Textract Confidence

Document extraction systems can have uncertainty.

Conceptually:

```text
Vendor:
ABC Technologies

Confidence:
98%
```

or perhaps:

```text
Total:
$1,500

Confidence:
62%
```

Confidence can be useful for deciding:

```text
High confidence
→ automated processing

Low confidence
→ review / validation
```

But there is an important limitation in your implementation.

---

# 22. Current Confidence Limitation

Codex found:

> **The parser does not preserve field-level Textract confidence.** :chatgpt-content-reference{index="12"}

So even if the underlying Textract response contains useful extraction-quality information, the current application parser doesn't retain it for downstream review decisions.

Therefore don't say:

> “Low-confidence Textract fields automatically go to human review.”

That is not implemented.

---

# 23. Coordinates Are Also Not Preserved

Textract can provide information related to where extracted content appeared in a document.

But Codex found that this project's parser:

> **does not preserve field coordinates.** :chatgpt-content-reference{index="13"}

Why might coordinates matter?

A future UI could potentially show:

```text
Invoice image

┌───────────────────────┐
│ Vendor: ABC Ltd       │ ← highlighted
│                       │
│ Total: $1,200         │ ← highlighted
└───────────────────────┘
```

Without retaining geometry/coordinates, building that review experience becomes harder.

---

# 24. OCR Is Not Perfect

This must be understood clearly.

Suppose the invoice says:

```text
Total: 8,500
```

OCR might potentially misread something.

Or a field might be:

```text
missing
```

or:

```text
poorly positioned
```

or:

```text
low quality
```

Therefore:

```text
Textract output
≠
guaranteed truth
```

Codex's existing interview material explicitly warns that fields can be missing or misread. :chatgpt-content-reference{index="14"}

---

# 25. Why OCR Errors Matter Downstream

This is a very important project concept.

Your pipeline is:

```text
Invoice
 ↓
Textract
 ↓
Bedrock
 ↓
Risk Rules
 ↓
Final Result
```

Suppose Textract extracts the wrong total.

```text
Actual Total
= 1000

OCR Total
= 100
```

Now Bedrock receives incorrect context.

And deterministic risk rules may also operate on incorrect data.

Therefore:

> **An upstream extraction error can propagate through the rest of the pipeline.**

---

# 26. Example of Error Propagation

Imagine:

```text
Actual Invoice

Line items:
500
500

Total:
1000
```

But OCR incorrectly produces:

```text
Line items:
500
500

Total:
100
```

The deterministic math check sees:

```text
500 + 500
≠
100
```

and may treat this as a discrepancy.

But the original invoice might actually be correct.

So a risk finding can sometimes originate from:

```text
OCR error
```

rather than:

```text
actual invoice problem
```

This is why extraction quality matters.

---

# 27. Current Risk Formula Makes OCR Quality Important

Codex found that the deterministic scoring logic uses extracted values for rules including:

```text
Math discrepancy

Missing invoice number

Missing date

Missing total

Missing vendor

Invoice-number pattern

Repeated descriptions
```

:chatgpt-content-reference{index="15"}

Therefore:

```text
Bad extraction
       ↓
Bad rule inputs
       ↓
Potentially misleading risk score
```

This is one reason the project should not claim proven fraud-detection accuracy.

---

# 28. Multipage Document Limitation

This is another important project-specific issue.

The UI accepts document types including PDF.

But:

> **Accepting PDF does not prove that the implemented synchronous Textract path correctly supports arbitrary multipage invoices.** :chatgpt-content-reference{index="16"}

This distinction is crucial.

Do not say:

> “Because PDF upload works, any 100-page PDF is supported.”

That's not justified by the project evidence.

---

# 29. Synchronous vs Asynchronous Expense Analysis

Your current project uses:

```text
Synchronous AnalyzeExpense
```

A different architecture can use asynchronous document-processing operations for workloads that require it.

Conceptually:

```text
CURRENT

Lambda
 ↓
AnalyzeExpense
 ↓
Response
```

versus a broader asynchronous pattern:

```text
Start document analysis
 ↓
Processing happens asynchronously
 ↓
Retrieve/receive completion
 ↓
Continue workflow
```

The Codex report specifically lists asynchronous expense analysis as an alternative when document types or lengths exceed the current approach. :chatgpt-content-reference{index="17"}

---

# 30. Why This Matters to Lambda

With synchronous processing:

```text
Lambda
 ↓
calls service
 ↓
waits
 ↓
receives response
```

For larger/longer document workloads, architectural limits such as duration, supported document behavior and processing patterns become more important.

This is why document constraints should be defined deliberately rather than accepting a broad file type and assuming every document shape works.

---

# 31. Current Input Validation Problem

Recall File 06.

The frontend checks:

```text
MIME type
+
10 MiB size
```

But the Codex report found that the backend does not fully validate:

```text
actual uploaded content

actual object size

page count

document structure
```

before OCR.

So:

```text
Browser says "PDF"
```

does not guarantee:

```text
Safe + supported Textract document
```

This is an important production gap.

---

# 32. A Better Document Validation Boundary

A stronger production design could be:

```text
S3 Upload
   ↓
Server-side validation
   ↓
Actual object size?
   ↓
Actual document type?
   ↓
Supported page count?
   ↓
Valid document structure?
   ↓
PASS
   ↓
Textract
```

Then only supported documents reach expensive processing.

This is a proposed improvement, not current behavior.

---

# 33. What Happens When OCR Fails?

Textract/document-processing failures occur inside the Step Functions workflow.

Conceptually:

```text
Process Document
      ↓
Textract
      ↓
ERROR
      ↓
Workflow error handling
```

The Codex analysis notes that several task failures are caught and routed to a DynamoDB job update, but also warns that workflow success and business success are not identical concepts. :chatgpt-content-reference{index="18"}

So troubleshooting should inspect both:

```text
Step Functions execution
```

and:

```text
Application job record
```

---

# 34. How Would I Troubleshoot Textract?

Suppose:

> Invoice uploaded successfully but OCR failed.

Follow the path:

```text
1. Is invoice present in S3?
        ↓
2. Did Step Functions start?
        ↓
3. Did document-processing state run?
        ↓
4. Check OCR Lambda CloudWatch logs
        ↓
5. Check Textract request/error
        ↓
6. Check S3 object reference
        ↓
7. Check IAM permission
        ↓
8. Check document format/size/pages
        ↓
9. Check parser assumptions
```

Do not immediately debug Nova Micro.

If Textract failed, Bedrock may never receive useful input.

---

# 35. Textract IAM Permission

The OCR Lambda needs AWS permission to perform its required actions.

Conceptually:

```text
OCR Lambda Role
      │
      ├── Read required S3 object
      │
      └── Call required Textract operation
```

This is separate from:

```text
Cognito
```

Remember:

```text
Cognito
=
application user identity
```

while:

```text
IAM
=
AWS service/resource authorization
```

---

# 36. Why Not Use Bedrock for Everything?

An interviewer may ask this.

Weak answer:

> “Textract is better.”

Better reasoning:

The project has two different requirements:

```text
Requirement 1:
Extract invoice-specific structure
        ↓
Textract AnalyzeExpense
```

```text
Requirement 2:
Perform semantic AI analysis
        ↓
Bedrock Nova Micro
```

So the architecture uses specialized services for different jobs.

---

# 37. Why Not Generic OCR?

The Codex analysis gives a project-specific design rationale.

Requirement:

> **Extract invoice-specific fields.**

Current choice:

> **Textract `AnalyzeExpense` rather than generic OCR.**

Why:

> **It provides useful summary and line-item structures.** :chatgpt-content-reference{index="19"}

Alternative:

```text
Generic OCR
    +
Custom invoice parser
```

But then your application would take on more document-structure parsing responsibility.

---

# 38. Current Trade-Off

The Codex analysis summarizes the trade-off well:

> **Extraction still needs normalization and quality checks.** :chatgpt-content-reference{index="20"}

So Textract solves:

```text
invoice-oriented extraction
```

but it does not eliminate the need for:

```text
validation

normalization

quality handling

business interpretation
```

---

# 39. Production Improvement — Preserve Confidence

Instead of:

```text
total = "$1,000"
```

a stronger internal representation might preserve:

```text
total.value = "$1,000"

total.confidence = ...
```

Then the application could establish business rules such as:

```text
Low-confidence critical field
        ↓
Do not automatically trust it
        ↓
Flag for review
```

The exact threshold should come from testing and business requirements, not an invented number.

---

# 40. Production Improvement — Normalize Values

For dates:

```text
"26/09/26"
"2026-09-26"
"Sep 26, 2026"
```

could be normalized to a consistent internal representation.

For money:

```text
"$1,200.50"
"1,200.50 USD"
```

could become structured values.

Conceptually:

```text
amount = 1200.50
currency = USD
```

This makes deterministic financial rules safer.

---

# 41. Production Improvement — Human Review

For financial documents, a future architecture could include:

```text
Textract
   ↓
Confidence / validation
   ↓
 ┌───────────────┐
 │ High quality  │ → continue automatically
 └───────────────┘

 ┌───────────────┐
 │ Uncertain     │ → review
 └───────────────┘
```

But remember:

> **This project does not currently implement a confidence-based human-review workflow.**

Don't claim it in interviews.

---

# 42. What Is Implemented?

Based on the Codex analysis:

```text
✓ Amazon Textract

✓ Synchronous AnalyzeExpense

✓ S3 document as OCR input

✓ First ExpenseDocument parsed

✓ Invoice number extraction

✓ Vendor extraction

✓ Date extraction

✓ Total extraction

✓ Subtotal extraction

✓ Tax extraction

✓ Line-item extraction

✓ LINE text collection

✓ Output passed downstream
```

:chatgpt-content-reference{index="21"}

---

# 43. What Is Limited?

The same project analysis identifies:

```text
⚠ Only ExpenseDocuments[0] is read

⚠ Values largely remain strings

⚠ Dates are not normalized

⚠ Monetary values are not fully normalized

⚠ Currency defaults to USD

⚠ Field-level confidence is not preserved

⚠ Coordinates are not preserved

⚠ Arbitrary multipage support should not be claimed

⚠ Server-side document validation is incomplete
```

:chatgpt-content-reference{index="22"}

These are extremely useful interview facts.

---

# 44. One Flow to Remember

```text
S3 Invoice
    ↓
Step Functions
    ↓
OCR Lambda
    ↓
Textract AnalyzeExpense
    ↓
ExpenseDocuments[0]
    │
    ├── Invoice Number
    ├── Vendor
    ├── Dates
    ├── Total
    ├── Subtotal
    ├── Tax
    ├── Line Items
    └── Raw LINE Text
             ↓
       Python Parser
             ↓
      Extracted Invoice
             ↓
      Bedrock Nova Micro
```

If you understand this flow, you've understood the core of File 09.

---

# 45. Interview Preparation — 10 Questions

## Q1 — What exactly does Amazon Textract do in your project?

**Difficulty:** Basic

### Word-by-word practice answer

> “The OCR Lambda calls Amazon Textract `AnalyzeExpense` using the invoice stored in S3. The parser reads the first expense document and extracts invoice-specific summary fields, line items and raw text lines. That extracted information is then passed to the downstream AI-analysis stage.”

This follows the existing Codex interview answer rather than replacing it. :chatgpt-content-reference{index="23"}

---

# Q2 — Why did you use `AnalyzeExpense` instead of generic OCR?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “My requirement is not only to read text but to extract invoice-specific information. `AnalyzeExpense` provides structures for expense summary fields and line items, which reduces the amount of custom invoice parsing I need to build compared with generic OCR. However, I still need application-level normalization and quality checks.”

---

# Q3 — What fields do you extract?

**Difficulty:** Basic

### Word-by-word practice answer

> “The current parser extracts information including the invoice number, vendor, dates, total, subtotal, tax and line items. It also collects raw LINE block text. Most extracted values remain largely as strings in the current implementation.”

:chatgpt-content-reference{index="24"}

---

# Q4 — What is the difference between Textract and Bedrock in your architecture?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “Textract performs document extraction, while Bedrock performs Generative AI analysis. The invoice PDF or image is processed by Textract first. My application then sends the extracted structured fields and OCR text to Nova Micro through Amazon Bedrock. The model does not directly receive the invoice image in the current implementation.”

---

# Q5 — Does Textract extract every invoice perfectly?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “No. Document extraction is not guaranteed to be perfect. Fields can be missing or misread. In my current implementation, another limitation is that the parser does not preserve field-level Textract confidence for downstream review decisions, so I would improve extraction-quality handling before treating this as production-grade financial processing.”

This is directly aligned with the Codex interview material. :chatgpt-content-reference{index="25"}

---

# Q6 — How do you use Textract confidence scores?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “The current parser does not preserve field-level Textract confidence, so I would not claim that confidence-based validation is implemented. For a stronger production version, I would retain confidence with critical extracted fields and use tested business thresholds to decide whether processing can continue automatically or requires additional validation or human review.”

---

# Q7 — Does your project support multipage invoices?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “I would not claim arbitrary multipage support. The current implementation uses synchronous `AnalyzeExpense`, and the parser reads only the first returned expense document. The upload interface accepting PDF does not by itself prove that every multipage PDF is supported. I would explicitly define document limits and use an appropriate asynchronous processing design if broader document support were required.”

:chatgpt-content-reference{index="26"}

---

# Q8 — What happens if Textract extracts the wrong value?

**Difficulty:** Advanced

### Word-by-word practice answer

> “That error can propagate downstream because Bedrock and the deterministic risk rules use the extracted invoice information. For example, if the total is misread, a mathematical discrepancy rule could produce a misleading risk signal. That is why extraction confidence, normalization, validation and potentially human review are important production improvements.”

---

# Q9 — Why are normalization and validation necessary after Textract?

**Difficulty:** Advanced

### Word-by-word practice answer

> “Extraction tells me what value was detected, but it does not guarantee that the value is normalized or financially correct. The current parser keeps most values as strings and does not fully normalize dates or monetary values. For reliable financial rules, I would convert important fields into consistent typed representations, validate required fields and currency, and preserve extraction-quality information.”

---

# Q10 — How would you make the OCR stage production-ready?

**Difficulty:** Advanced / Design

### Word-by-word practice answer

> “I would first strengthen server-side document validation so unsupported size, type, page count or structure is rejected before expensive processing. Then I would preserve Textract field-level confidence, normalize dates, amounts and currencies, validate critical fields, define handling for low-confidence extraction, and evaluate an asynchronous Textract path where document length requires it. I would also create representative invoice test datasets and measure extraction quality instead of assuming OCR accuracy.”

---

# 46. Interview Pressure Chain

The interviewer may begin:

> **“What does Textract do?”**

and continue:

```text
What does Textract do?
      ↓
What API do you call?
      ↓
Why AnalyzeExpense?
      ↓
Why not DetectDocumentText?
      ↓
Where is the invoice stored?
      ↓
What does Textract return?
      ↓
What fields do you extract?
      ↓
What are line items?
      ↓
Do you keep confidence scores?
      ↓
Why not?
      ↓
Are values normalized?
      ↓
What currency do you use?
      ↓
What happens if OCR is wrong?
      ↓
Does it affect Bedrock?
      ↓
Does it affect risk scoring?
      ↓
Do you support multipage PDFs?
      ↓
Why synchronous processing?
      ↓
How would you improve it?
```

That's the depth you eventually want.

---

# 47. Don't Make These Interview Claims

Based on the actual project evidence, avoid saying:

> ❌ “Textract perfectly understands every invoice.”

> ❌ “We automatically reject every low-confidence field.”

> ❌ “All monetary values are fully normalized.”

> ❌ “The system automatically understands every currency.”

> ❌ “Any multipage PDF is supported.”

> ❌ “Nova Micro directly analyzes the invoice image.”

> ❌ “OCR output is guaranteed financial truth.”

Instead, explain what is **actually implemented** and then explain what you would improve.

---

# 48. What You Should Remember

If you remember only one diagram from this file, remember:

```text
            S3 INVOICE
                 ↓
           OCR LAMBDA
                 ↓
     TEXTRACT ANALYZEEXPENSE
                 ↓
       ExpenseDocuments[0]
                 ↓
    ┌────────────┴────────────┐
    │                         │
Structured Fields         Raw Text
    │                         │
    ├ Vendor                  │
    ├ Invoice Number          │
    ├ Dates                   │
    ├ Total                   │
    ├ Subtotal                │
    ├ Tax                     │
    └ Line Items              │
    │                         │
    └────────────┬────────────┘
                 ↓
        BEDROCK NOVA MICRO
```

And remember the four limitations:

```text
Extraction ≠ guaranteed truth

Extraction ≠ normalization

PDF accepted ≠ arbitrary multipage support

Textract confidence exists conceptually
but this parser does not preserve it
```

---

# 49. Check Your Understanding

Before starting **`10-Bedrock-Nova-Micro-and-Prompt-Engineering.md`**, answer these three questions in your own words:

**Question 1:** Why does this project use **Textract `AnalyzeExpense` instead of sending the invoice directly to Nova Micro?**

**Question 2:** Suppose Textract reads the actual invoice total of `₹10,000` as `₹1,000`. How could that mistake affect **both Bedrock analysis and deterministic risk scoring**?

**Question 3:** If an interviewer asks, **“Does your application support all multipage PDFs?”**, why should you **not simply answer yes**?