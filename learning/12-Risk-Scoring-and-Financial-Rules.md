# Your question

**Create `12-Risk-Scoring-and-Financial-Rules.md`.**

This file starts exactly where File 11 ended:

```text
Textract
   ↓
Extracted invoice data
   ↓
Bedrock Nova Micro
   ↓
AI findings
   ↓
?
```

The `?` is the project's **deterministic Python risk-scoring engine**.

The most important fact to understand is:

> **Nova Micro does not directly calculate the final 0–100 risk score. Python business rules combine invoice-data checks with AI anomaly severities to calculate a deterministic heuristic score.**

The verified scoring formula in the project is:

```text
Math discrepancy                     +40

Missing invoice number               +8
Missing receipt date                 +8
Missing total                        +8
Missing vendor                       +8

Short numeric invoice number         +10

Repeated normalized item description +15

Each AI HIGH anomaly                 +15
Each AI MEDIUM anomaly               +7
Each AI LOW/unknown anomaly          +3

Maximum score                        100
```

Risk bands:

```text
0–29    → LOW
30–69   → MEDIUM
70–100  → HIGH
```

:chatgpt-content-reference{index="0"}

---

# 12 — Risk Scoring and Financial Rules

## 1. What Will I Learn?

In this file, I will understand:

- What deterministic risk scoring means
- Why the project doesn't let the LLM directly decide the final score
- The exact current scoring formula
- LOW, MEDIUM and HIGH risk bands
- Math-discrepancy checking
- Missing-field checks
- Invoice-number checks
- Duplicate-description checks
- How AI anomalies contribute to the score
- Why this is a **heuristic score**
- Why 80 does **not** mean 80% fraud probability
- Financial limitations in the current rules
- False positives and false negatives
- Why extracted monetary strings need normalization
- Why AI failure can influence the final score
- How the scoring engine could be improved
- 10 project-specific interview questions with word-by-word answers

---

# 2. Where Are We in the Architecture?

We are here:

```text
Invoice
   ↓
Textract
   ↓
Extracted Fields
   ↓
Nova Micro
   ↓
AI Findings
   ↓
┌────────────────────────────┐
│ DETERMINISTIC PYTHON RULES │
│                            │
│ Math Check                 │
│ Missing Fields             │
│ Invoice Number             │
│ Duplicate Items            │
│ AI Severity                │
└─────────────┬──────────────┘
              ↓
        Numeric Score
              ↓
       LOW / MEDIUM / HIGH
              ↓
       Store Final Result
```

The scoring engine consumes information from **two main sources**:

```text
           ┌── Textract fields
           │
Risk Rules ┤
           │
           └── Nova AI findings
```

---

# 3. First — What Does “Deterministic” Mean?

This word is very important.

A deterministic rule means:

> **For the same input, the same programmed rule produces the same result.**

For example:

```python
if math_discrepancy:
    score += 40
```

If:

```text
math_discrepancy = True
```

the rule adds:

```text
40 points
```

every time.

There is no creativity involved.

---

# 4. Deterministic Rules vs Generative AI

Compare the two.

### Nova Micro

```text
Invoice Context
      ↓
Foundation Model
      ↓
AI Interpretation
```

The model is probabilistic.

### Python Risk Rules

```text
Known Input
    ↓
if condition:
    add points
    ↓
Numeric Score
```

The scoring logic is deterministic.

Therefore the architecture combines:

```text
Generative AI
     +
Deterministic Business Rules
```

---

# 5. Why Not Ask Nova Micro for the Final Score?

You could theoretically prompt an LLM:

```text
Give this invoice a risk score
between 0 and 100.
```

But then the scoring behavior would be harder to control and explain.

The current architecture instead uses:

```text
Nova Micro
     ↓
Anomaly findings
     ↓
Python rules
     ↓
Final numeric score
```

That makes the numeric scoring logic more explicit.

In an interview, a strong explanation is:

> “I use the LLM for semantic anomaly analysis, but the final numeric risk score is calculated through deterministic Python rules. That keeps the scoring logic explicit and easier to inspect.”

---

# 6. The Exact Current Scoring Formula

Let's learn the actual project.

## Rule 1 — Math discrepancy

```text
Math discrepancy
        ↓
      +40
```

## Rule 2 — Missing invoice number

```text
Missing invoice number
        ↓
       +8
```

## Rule 3 — Missing receipt date

```text
Missing receipt date
        ↓
       +8
```

## Rule 4 — Missing total

```text
Missing total
        ↓
       +8
```

## Rule 5 — Missing vendor

```text
Missing vendor
        ↓
       +8
```

## Rule 6 — Suspiciously short numeric invoice number

```text
Purely numeric invoice number
shorter than 3 digits
        ↓
       +10
```

## Rule 7 — Repeated normalized item description

```text
Repeated description
        ↓
       +15
```

## AI findings

```text
AI HIGH anomaly    → +15 each

AI MEDIUM anomaly  → +7 each

AI LOW anomaly     → +3 each

Unknown severity   → +3 each
```

Finally:

```text
score = min(score, 100)
```

:chatgpt-content-reference{index="1"}

---

# 7. Risk Classification

After calculating the score:

```text
Score
  ↓
Risk Band
```

The project's current thresholds are:

| Score | Risk Level |
|---:|---|
| 0–29 | LOW |
| 30–69 | MEDIUM |
| 70–100 | HIGH |

:chatgpt-content-reference{index="2"}

So:

```text
25 → LOW

45 → MEDIUM

80 → HIGH
```

---

# 8. Very Important: What Does 80 Mean?

Suppose:

```text
risk_score = 80
```

Does this mean:

> “There is an 80% probability this invoice is fraudulent”?

**No.**

Absolutely do not explain it that way in an interview.

The project uses a:

> **heuristic point score**

not a calibrated fraud probability. :chatgpt-content-reference{index="3"}

So:

```text
80 points
```

means:

> The programmed rules accumulated 80 risk points.

It does **not** mean:

```text
80% fraud probability
```

---

# 9. What Does “Heuristic” Mean?

Very simple definition:

> **A heuristic is a practical rule or scoring method used to make a useful judgment, but it isn't necessarily statistically proven to represent probability.**

For example:

```text
Missing vendor
     ↓
+8 points
```

Why exactly 8?

The repository implements that weight.

But Codex did **not** find a calibration study proving:

```text
8 points = exact statistical fraud risk
```

Similarly:

```text
Math mismatch = +40
```

is a business-rule weight.

It is not automatically a scientifically calibrated probability.

---

# 10. Rule 1 — Math Discrepancy

This is currently one of the highest-weight rules:

```text
Math mismatch
     ↓
+40
```

Conceptually, the project compares:

```text
Sum of extracted line-item price values
                vs
         Extracted invoice total
```

If they don't match sufficiently according to the implemented logic:

```text
+40
```

This can have a major effect because:

```text
40
```

already puts the invoice into the:

```text
MEDIUM
```

band.

---

# 11. Simple Math Example

Suppose Textract extracts:

```text
Invoice Total = 100

Item 1 price = 50
Item 2 price = 30
```

Then:

```text
50 + 30 = 80
```

but:

```text
Invoice Total = 100
```

So:

```text
80 ≠ 100
```

The rule detects a discrepancy.

Result:

```text
Risk Score = 40
```

Therefore:

```text
Risk Level = MEDIUM
```

even before other rules are considered.

---

# 12. But There Is a Financial Problem

An invoice total isn't always simply:

```text
item 1
+
item 2
+
item 3
```

There could also be:

```text
Subtotal
+ Tax
+ Shipping
- Discount
- Credit
──────────
Total
```

The current math rule does not explicitly reconcile all those financial concepts. :chatgpt-content-reference{index="4"}

This is a major limitation.

---

# 13. Example of a False Positive

Imagine a completely legitimate invoice:

```text
Item A = $50
Item B = $30

Subtotal = $80
Tax      = $20

Total    = $100
```

The current simplified check may conceptually compare:

```text
50 + 30
   =
80
```

against:

```text
Total = 100
```

and see:

```text
80 ≠ 100
```

Potentially adding:

```text
+40
```

even though the invoice math is legitimate.

This demonstrates why financial semantics matter.

---

# 14. Current Math Rule Limitations

Codex specifically identified that the current math logic does not explicitly reconcile:

```text
Tax

Discounts

Shipping

Credits

Unit price vs line total

Quantity

Negative amounts

Locale-specific decimal separators
```

:chatgpt-content-reference{index="5"}

This is extremely useful interview knowledge because it shows you understand not only what your project does, but also where its business logic can fail.

---

# 15. Quantity Problem

Imagine:

```text
Quantity = 5

Unit Price = $10

Line Total = $50
```

If the extracted `price` field represents:

```text
$10
```

instead of:

```text
$50
```

then simply summing `price` fields may not correctly reconstruct the invoice total.

So before financial reconciliation, you need to understand:

> **What does each extracted field actually represent?**

---

# 16. Negative Amount Problem

Suppose an invoice contains a credit:

```text
-$50.00
```

Codex found the current amount parsing removes characters except digits and periods.

That can transform:

```text
-$50.00
```

into something effectively interpreted as:

```text
50.00
```

rather than:

```text
-50.00
```

:chatgpt-content-reference{index="6"}

That's a meaningful financial bug.

---

# 17. Locale Problem

Different regions represent numbers differently.

For example:

```text
1,234.56
```

versus formats using commas and periods differently.

A simplistic parser that removes characters without understanding locale can misinterpret monetary values.

Codex specifically flags locale-specific decimal separators as an unhandled limitation. :chatgpt-content-reference{index="7"}

---

# 18. Amounts Written in Words

Another interesting edge case from the analysis:

Amounts expressed entirely in words can become:

```text
0
```

in the parser used by the current rule.

That can cause the discrepancy check to be skipped or behave incorrectly. :chatgpt-content-reference{index="8"}

For example:

```text
Total:
One Thousand Dollars
```

is very different from a clean numeric:

```text
1000.00
```

This shows why production financial normalization is more difficult than simply stripping characters.

---

# 19. Missing Field Rules

The project checks four important fields:

```text
Invoice Number

Receipt Date

Total

Vendor
```

Each missing field adds:

```text
+8
```

:chatgpt-content-reference{index="9"}

Therefore, if all four are missing:

```text
8 + 8 + 8 + 8
=
32
```

That alone produces:

```text
MEDIUM
```

risk.

---

# 20. Why Missing Fields Increase Risk

Imagine an invoice where Textract cannot find:

```text
Vendor
```

There are at least two possibilities:

```text
Actual invoice is incomplete
```

or:

```text
OCR/extraction failed
```

The scoring rule doesn't automatically know which one happened.

It simply sees:

```text
vendor missing
```

and adds points.

This distinction is important.

---

# 21. Missing Data ≠ Fraud

Never say:

> “If vendor is missing, the invoice is fraudulent.”

The rule only means:

> **Missing expected information contributes to the heuristic risk score.**

There could be a legitimate reason:

```text
Poor scan

Unusual invoice layout

OCR extraction error

Damaged document

Different language/format
```

So this project is better described as:

> **risk prioritization / invoice review support**

rather than:

> **automatic fraud proof**

---

# 22. Short Numeric Invoice Number Rule

The current logic includes:

```text
Invoice number is purely numeric
AND
length < 3
        ↓
      +10
```

:chatgpt-content-reference{index="10"}

Examples:

```text
7
```

or:

```text
42
```

could trigger this rule.

But:

```text
123
```

would not trigger the “shorter than three digits” condition.

---

# 23. Why Is This a Heuristic?

Because a short invoice number isn't automatically fraudulent.

A small vendor might legitimately issue:

```text
Invoice #7
```

Therefore:

```text
Short invoice number
```

is treated as a **risk signal**, not proof.

Again:

```text
signal ≠ fraud
```

---

# 24. Duplicate Description Rule

The project also checks repeated normalized line-item descriptions.

If a repeated description is detected:

```text
+15
```

:chatgpt-content-reference{index="11"}

Conceptually:

```text
Consulting Service
Consulting Service
```

may be treated as a duplicate.

---

# 25. But Duplicate Description Can Be Legitimate

Suppose an invoice contains:

```text
USB Cable     $10
USB Cable     $10
USB Cable     $10
```

Maybe the customer legitimately purchased three cables.

Repeated description alone does not prove duplicate billing.

Codex specifically notes:

> The duplicate rule can treat repeated descriptions as duplicates even when quantities, prices or legitimate repeated purchases differ. :chatgpt-content-reference{index="12"}

This can create false positives.

---

# 26. A Better Duplicate Rule

A more mature future rule might consider:

```text
Description

Quantity

Unit price

Line total

SKU/product ID

Position

Other invoice context
```

instead of only:

```text
Normalized description
```

Then:

```text
"USB Cable", quantity=3
```

would not necessarily be treated the same as an accidental duplicated charge.

This is a proposed improvement, not current behavior.

---

# 27. How AI Findings Affect the Score

Now we connect File 10 and File 11 to File 12.

Nova Micro can produce anomaly findings with severity.

The deterministic scorer converts severity into points:

```text
HIGH
 ↓
+15

MEDIUM
 ↓
+7

LOW
 ↓
+3
```

And Codex found that unrecognized severity also contributes:

```text
+3
```

:chatgpt-content-reference{index="13"}

---

# 28. Example with One AI Anomaly

Suppose:

```text
No math mismatch

No missing fields

Normal invoice number

No duplicate description

1 HIGH AI anomaly
```

Then:

```text
Score = 15
```

Therefore:

```text
LOW
```

because:

```text
0–29 = LOW
```

This is interesting.

A single HIGH AI anomaly doesn't automatically create HIGH overall risk.

---

# 29. Example with Multiple AI Anomalies

Suppose Nova returns:

```text
HIGH
HIGH
MEDIUM
LOW
```

Points:

```text
15 + 15 + 7 + 3
=
40
```

Therefore:

```text
MEDIUM
```

assuming no other rules add points.

Again, this is deterministic once the AI severities have been supplied.

---

# 30. Important AI Validation Connection

Remember File 11.

Suppose the model returns:

```json
{
  "severity": "EXTREME"
}
```

Codex found that unrecognized severity can fall into the lower/default point behavior.

That means weak AI-output validation can affect downstream scoring. :chatgpt-content-reference{index="14"}

This gives us an important dependency:

```text
AI Output Quality
       ↓
AI Output Validation
       ↓
Risk Scoring Quality
```

If validation is weak, scoring can be affected.

---

# 31. Complete Example from the Project Analysis

Codex provided this realistic scoring example:

```text
Total = 100

Line-item prices:
50
30

All four required fields present

Normal invoice number

No duplicate descriptions

One HIGH AI anomaly
```

Math check:

```text
50 + 30 = 80

80 ≠ 100
```

Therefore:

```text
Math discrepancy = +40
```

AI:

```text
HIGH anomaly = +15
```

Total:

```text
40 + 15
=
55
```

Classification:

```text
55 → MEDIUM
```

This is an illustrative execution of the implemented formula, not a measured AWS run. :chatgpt-content-reference{index="15"}

---

# 32. Let's Do a Larger Example

Suppose:

```text
Math discrepancy             +40

Vendor missing               +8

Invoice number = "7"         +10

Duplicate description        +15

1 HIGH AI anomaly            +15
```

Total:

```text
40 + 8 + 10 + 15 + 15
=
88
```

Therefore:

```text
Risk Score = 88

Risk Level = HIGH
```

Again:

```text
88 ≠ 88% fraud probability
```

It means the rules accumulated 88 points.

---

# 33. Score Capping

Suppose the rules produce:

```text
125 points
```

The project caps the score:

```text
min(score, 100)
```

Therefore:

```text
125
 ↓
100
```

Final:

```text
Risk Score = 100

Risk Level = HIGH
```

:chatgpt-content-reference{index="16"}

---

# 34. Why Cap at 100?

It creates a simple user-facing scale:

```text
0 ─────────────────────────── 100
LOW         MEDIUM          HIGH
```

But remember:

> The scale is a business scoring scale, not a probability distribution.

---

# 35. Major Problem — AI Failure Can Lower the Score

Now connect this with File 10.

Handled Bedrock failure can produce:

```text
anomalies = []

confidence = 0

analysis unavailable
```

Then deterministic scoring continues. :chatgpt-content-reference{index="17"}

Imagine an invoice has:

```text
No math mismatch

No missing fields

No short invoice number

No duplicate descriptions
```

Bedrock fails.

AI anomalies:

```text
[]
```

Score could remain:

```text
0
```

Classification:

```text
LOW
```

But that does **not** mean:

> “AI analyzed this invoice and found it safe.”

It means:

> “The deterministic rules didn't add points, while AI analysis was unavailable.”

Huge difference.

---

# 36. LOW Risk vs LOW Risk with AI Failure

These should conceptually be different:

```text
CASE A

AI succeeded
No anomalies
Rules clean
      ↓
LOW
```

versus:

```text
CASE B

AI failed
No AI findings available
Rules clean
      ↓
LOW
```

The current project can conflate these situations because handled AI failure can continue into completed processing. :chatgpt-content-reference{index="18"}

---

# 37. Better Production Design

A stronger result could contain:

```text
risk_score = 10

risk_level = LOW

analysis_status = DEGRADED

ai_status = FAILED

manual_review_required = true
```

Then:

```text
LOW score
```

does not imply:

```text
complete AI verification
```

This is a proposed improvement.

---

# 38. False Positive

A **false positive** in this context means the system raises risk for something that is actually legitimate.

Example:

```text
Items = $80

Tax = $20

Total = $100
```

Simplified math rule sees:

```text
80 != 100
```

and adds:

```text
+40
```

even though the invoice may be perfectly valid.

That is the kind of edge case better financial reconciliation should reduce.

---

# 39. False Negative

A **false negative** means a genuinely problematic invoice isn't sufficiently flagged.

Example:

```text
Deterministic fields look normal

Bedrock fails

AI anomalies = []

Score stays LOW
```

Yet there might have been a semantic anomaly that only AI would have detected.

That's another reason degraded processing should be explicit.

---

# 40. Why Rule Weights Need Validation

Current rules say:

```text
Math discrepancy = 40

Missing vendor = 8

Duplicate description = 15
```

But why:

```text
40?
8?
15?
```

The repository contains the implemented weights.

Codex does **not** establish a calibration study validating those numbers. :chatgpt-content-reference{index="19"}

Therefore you should not say:

> “These are statistically optimal fraud weights.”

Instead:

> “They are heuristic business-rule weights in the current implementation.”

---

# 41. How Could We Calibrate the Rules?

This is a **future improvement**, not current implementation.

Suppose you obtain:

```text
Historical reviewed invoices
        ↓
Known outcomes
        ↓
Run current scoring rules
        ↓
Compare scores with outcomes
```

Then analyze:

```text
Do HIGH scores actually correlate
with higher review findings?

Are too many legitimate invoices
classified MEDIUM?

Does +40 over-penalize tax differences?

Is +8 appropriate for missing vendor?
```

Then adjust weights based on evidence.

---

# 42. Thresholds Also Need Evaluation

The current thresholds are:

```text
0–29 LOW

30–69 MEDIUM

70–100 HIGH
```

:chatgpt-content-reference{index="20"}

But just like weights, thresholds should ideally be evaluated against real business outcomes.

You could eventually ask:

```text
Should HIGH start at 70?

Should it start at 60?

Should some rules immediately
require manual review regardless
of numeric score?
```

Those are business/evaluation decisions.

---

# 43. Explainability Advantage

One strength of deterministic rules is explainability.

Instead of only displaying:

```text
Risk = 73
```

you can conceptually explain:

```text
Math discrepancy       +40

Duplicate item         +15

AI HIGH anomaly        +15

AI LOW anomaly         +3
──────────────────────────
Total                  73
```

Then a reviewer can understand why the score increased.

This is much easier to audit than an unexplained:

```text
LLM says 73
```

---

# 44. But Explainable Doesn't Mean Correct

This is another important distinction.

A rule can be completely explainable:

```text
Math mismatch
→ +40
```

while still being wrong for a particular invoice because tax wasn't considered.

So:

```text
Explainability
≠
Accuracy
```

Both matter.

---

# 45. Separation of Responsibilities

Your architecture has a useful conceptual separation:

```text
Amazon Textract
      ↓
"What information is
in the invoice?"

Amazon Nova Micro
      ↓
"What semantic anomalies
might exist?"

Python Rules
      ↓
"How many deterministic
risk points should be added?"
```

That is a very strong way to explain the system in an interview.

---

# 46. Is This Machine Learning Risk Scoring?

Not in the sense of a custom trained risk model.

The current scoring engine is:

```text
Hand-coded deterministic Python rules
```

It is **not**:

```text
Logistic Regression

Random Forest

XGBoost

Neural Network

Custom fraud classifier
```

based on the project analysis.

Don't call the risk scorer an ML model.

---

# 47. Is This Fraud Detection?

Be careful with terminology.

The project detects:

```text
Potential anomalies

Risk signals

Missing information

Math inconsistencies

AI-generated suspicious patterns
```

and produces a:

```text
heuristic risk score
```

That can support invoice review.

But the score does not mathematically prove:

```text
Fraud = True
```

A safer and more accurate interview phrase is:

> **“The system performs invoice anomaly analysis and risk prioritization to support human review.”**

---

# 48. Current Implementation vs Production Improvement

### Current

```text
Extracted fields
      +
AI anomalies
      ↓
Fixed Python weights
      ↓
0–100 score
      ↓
LOW / MEDIUM / HIGH
```

### Stronger future design

```text
Normalized financial fields
         ↓
Validated invoice semantics
         ↓
Tax/discount/shipping reconciliation
         ↓
Improved duplicate detection
         ↓
Validated AI findings
         ↓
Calibrated risk rules
         ↓
Explicit degraded-processing status
         ↓
Human review policy
```

---

# 49. Current Project — What Is Implemented?

According to the Codex analysis:

```text
✓ Deterministic Python scoring

✓ Math-discrepancy rule

✓ Missing invoice-number rule

✓ Missing receipt-date rule

✓ Missing-total rule

✓ Missing-vendor rule

✓ Short numeric invoice-number rule

✓ Duplicate-description rule

✓ AI anomaly severity contribution

✓ Score capped at 100

✓ LOW / MEDIUM / HIGH classification
```

:chatgpt-content-reference{index="21"}

---

# 50. Current Project — Important Limitations

The analysis identifies several important limitations:

```text
⚠ Risk score is heuristic,
  not calibrated probability

⚠ Rule weights are not backed by
  a calibration study in the repository

⚠ Math check does not fully reconcile tax

⚠ Discounts aren't fully reconciled

⚠ Shipping isn't fully reconciled

⚠ Credits aren't fully reconciled

⚠ Quantity semantics aren't fully handled

⚠ Unit price vs line total can be ambiguous

⚠ Negative monetary values can be misparsed

⚠ Locale-specific formats can be misinterpreted

⚠ Amounts written in words can cause problems

⚠ Repeated descriptions can be legitimate

⚠ AI failure can reduce available risk evidence

⚠ AI output validation weakness can affect scoring
```

:chatgpt-content-reference{index="22"}

---

# 51. The Full Scoring Mental Model

Memorize the logic, not just numbers:

```text
              EXTRACTED INVOICE
                     │
       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼
 Math Check    Missing Fields   Metadata
       │             │             │
      +40           +8 each     +10 / +15
       │             │             │
       └─────────────┼─────────────┘
                     │
                     │
              AI ANOMALIES
                     │
           ┌─────────┼─────────┐
           ▼         ▼         ▼
          HIGH     MEDIUM      LOW
          +15        +7         +3
           │         │          │
           └─────────┼──────────┘
                     ↓
                Sum Points
                     ↓
                 Cap at 100
                     ↓
             ┌───────┼────────┐
             ▼       ▼        ▼
           0–29    30–69    70–100
            LOW     MEDIUM     HIGH
```

---

# 52. Interview Preparation — 10 Questions

## Q1 — How is the final risk score calculated?

**Difficulty:** Basic

### Word-by-word practice answer

> “The final risk score is calculated using deterministic Python rules. A math discrepancy adds 40 points, each of four missing required fields adds 8, a very short numeric invoice number adds 10, and repeated normalized item descriptions add 15. AI findings contribute 15 points for HIGH severity, 7 for MEDIUM and 3 for LOW or unrecognized severity. The score is capped at 100.”

:chatgpt-content-reference{index="23"}

---

## Q2 — What are your risk thresholds?

**Difficulty:** Basic

### Word-by-word practice answer

> “The current implementation classifies scores from 0 to 29 as LOW, 30 to 69 as MEDIUM, and 70 to 100 as HIGH. These are heuristic thresholds in the current business rules; I would not describe them as calibrated fraud probabilities.”

---

## Q3 — Does Nova Micro calculate the final risk score?

**Difficulty:** Basic / Intermediate

### Word-by-word practice answer

> “No. Nova Micro produces semantic anomaly findings, including severity information. The final numeric risk score is calculated separately by deterministic Python business rules. This gives me a hybrid design where AI contributes semantic signals, but the final point calculation remains explicit and predictable.”

---

## Q4 — Is a score of 80 equal to an 80% fraud probability?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “No. The score is a heuristic point score, not a calibrated probability. A score of 80 means the implemented rules accumulated 80 risk points and therefore placed the invoice in the HIGH band. The repository does not contain a calibration study that would justify interpreting 80 as an 80 percent probability of fraud.”

:chatgpt-content-reference{index="24"}

---

## Q5 — Explain your math-discrepancy rule.

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The current rule compares the sum of extracted line-item price values with the extracted invoice total. A discrepancy contributes 40 points. However, the current implementation is simplified because it does not fully reconcile tax, discounts, shipping, credits, quantity or unit-price-versus-line-total semantics. So I treat it as a risk signal rather than proof of incorrect billing.”

:chatgpt-content-reference{index="25"}

---

## Q6 — What is wrong with the current duplicate-item rule?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The current duplicate rule relies on repeated normalized item descriptions and adds 15 points. The limitation is that repeated descriptions can be legitimate. For example, a customer can purchase multiple identical items with different quantities or prices. In a stronger implementation I would consider quantity, price, line total and other identifiers rather than relying only on the description.”

:chatgpt-content-reference{index="26"}

---

## Q7 — What happens to the score if Bedrock fails?

**Difficulty:** Advanced

### Word-by-word practice answer

> “For certain handled Bedrock failures, the current implementation produces an empty AI-anomaly result with zero confidence and continues into deterministic scoring. That preserves the non-AI processing, but it can produce a lower score because no AI anomaly points are available. Therefore I would not interpret that LOW score as equivalent to a fully analyzed LOW-risk invoice. I would expose AI failure as a separate degraded-analysis status.”

:chatgpt-content-reference{index="27"}

---

## Q8 — Why did you use deterministic rules instead of asking the LLM for a 0–100 score?

**Difficulty:** Advanced

### Word-by-word practice answer

> “I separate semantic analysis from numeric scoring. Nova Micro is useful for interpreting invoice context and producing anomaly findings, while deterministic Python rules make the final point calculation explicit and reproducible. That improves explainability because I can show exactly which conditions added points. However, deterministic rules still need proper business validation and calibration; being explainable does not automatically make them correct.”

---

## Q9 — What financial edge cases does your current scorer have?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “The current scorer has several financial limitations. The math rule does not fully reconcile tax, discounts, shipping or credits, and it does not reliably distinguish unit price from line total or incorporate quantity semantics. The amount parser can also mishandle negative values and locale-specific number formats. These limitations can create false positives or false negatives, so I would add normalized monetary parsing and explicit financial reconciliation before considering the rules production-grade.”

:chatgpt-content-reference{index="28"}

---

## Q10 — How would you improve the risk-scoring engine for production?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “First, I would normalize monetary values using currency-aware parsing and explicitly model quantity, unit price, line total, tax, discounts, shipping and credits. Second, I would improve duplicate detection using multiple fields rather than description alone. Third, I would strictly validate AI findings before allowing them to affect scoring. Fourth, I would distinguish successful AI analysis from degraded processing. Finally, I would use reviewed historical invoice data to evaluate and calibrate rule weights and LOW, MEDIUM and HIGH thresholds instead of treating the current heuristic values as statistical probabilities.”

---

# 53. Interview Pressure Chain

An interviewer may start:

> **“Explain your risk score.”**

Then attack deeper:

```text
Who calculates the score?
        ↓
Does Nova calculate it?
        ↓
What are the exact rules?
        ↓
Why does math mismatch add 40?
        ↓
Why does missing vendor add 8?
        ↓
How were these weights calibrated?
        ↓
What are the thresholds?
        ↓
Does 80 mean 80% fraud?
        ↓
How do you handle tax?
        ↓
What about discounts?
        ↓
What about shipping?
        ↓
What about quantity × unit price?
        ↓
What about negative amounts?
        ↓
What about European number formats?
        ↓
What about duplicate legitimate items?
        ↓
What if Bedrock fails?
        ↓
Can the score still be LOW?
        ↓
Would you trust that LOW score?
        ↓
How would you improve the system?
```

If you understand this chain, you can defend the scoring architecture instead of only memorizing:

> “HIGH is 70 to 100.”

---

# 54. One Example You Should Be Able to Calculate Yourself

Interviewer says:

> “Suppose there is a math mismatch, vendor is missing, there is one duplicate description and Nova returns one HIGH anomaly. What's the score?”

Calculate:

```text
Math mismatch       = 40

Missing vendor      = 8

Duplicate           = 15

HIGH AI anomaly     = 15
                      ──
Total               = 78
```

Therefore:

```text
78
 ↓
HIGH
```

But your final sentence should be:

> “That is a HIGH heuristic risk score under the current rules, not a 78% probability of fraud.”

That distinction matters.

---

# 55. Five Things You Must Remember

**1. Nova Micro doesn't calculate the final score.**

```text
Nova → findings
Python → score
```

**2. The score is deterministic once its inputs are known.**

```text
Same inputs
→ same scoring rules
→ same numeric score
```

**3. The score is heuristic.**

```text
80 points
≠
80% fraud probability
```

**4. Financial rules have important limitations.**

Especially:

```text
tax
discounts
shipping
credits
quantity
negative amounts
number formats
duplicates
```

**5. A LOW score after AI failure isn't equivalent to a fully analyzed LOW-risk invoice.**

---

# 56. Your 30-Second Interview Answer

> “My project uses a hybrid risk-analysis approach. Textract first extracts invoice data, and Nova Micro provides semantic anomaly findings. The final numeric score is not generated directly by the LLM; deterministic Python rules calculate it. For example, a math discrepancy adds 40 points, missing required fields add 8 each, duplicate descriptions add 15, and AI anomalies contribute points based on severity. The score is capped at 100 and mapped to LOW, MEDIUM or HIGH. I treat this as a heuristic review score, not a fraud probability, because the current weights and thresholds are not statistically calibrated.” :chatgpt-content-reference{index="29"}

---

# 57. Your 10-Second Mental Model

```text
Textract
   ↓
Extract facts

Nova Micro
   ↓
Find semantic anomalies

Python Rules
   ↓
Add risk points

0–100
   ↓
LOW / MEDIUM / HIGH
```

Or even shorter:

> **Textract extracts → Nova analyzes → Python scores.**

---

# 58. Check Your Understanding

Before moving to **`13-DynamoDB-Data-Model-and-Access-Patterns.md`**, answer these three without looking above.

**Question 1:** An invoice has a **math discrepancy (+40)**, **missing vendor (+8)**, **one MEDIUM AI anomaly (+7)** and no other findings. What is the final score and risk level?

**Question 2:** An interviewer says:

> “Your invoice received a risk score of 85, so your system says there is an 85% probability of fraud, correct?”

How will you correct them?

**Question 3:** Why can this perfectly legitimate invoice potentially cause problems for the current math rule?

```text
Item A       $50
Item B       $30
----------------
Subtotal     $80
Tax          $20
----------------
Total       $100
```