# Your question

**Create `13-DynamoDB-Data-Model-and-Access-Patterns.md`.**

We have now reached the persistence layer of NovaMind AI.

The project flow so far is:

```text
Invoice
   ↓
Textract
   ↓
Bedrock Nova Micro
   ↓
Python Risk Rules
   ↓
Final Analysis Result
   ↓
?
```

The `?` is mainly:

```text
Amazon DynamoDB
+
Amazon S3
```

But they have different responsibilities.

For File 13, our focus is:

> **How DynamoDB stores application records, how the application retrieves them, how tenant isolation affects access patterns, and why DynamoDB data modeling starts from access patterns rather than traditional relational-table thinking.**

---

# 13 — DynamoDB Data Model and Access Patterns

## 1. What Will I Learn?

By the end of this file, I should understand:

- What Amazon DynamoDB is
- Why this project uses DynamoDB
- DynamoDB vs relational databases
- Table, item and attribute
- Partition key and sort key
- The project's key structure
- Invoice records
- Job/status records
- `tenant_id`
- `invoice_id`
- Why keys matter for authorization
- `Query` vs `Scan`
- How invoice listing works
- How invoice details are retrieved
- How job status is retrieved
- The current job-status ownership weakness
- How analytics data is produced
- DynamoDB pagination
- Why analytics can become expensive
- DynamoDB vs S3 responsibilities
- Deletion/data-lifecycle limitations
- 10 project-specific interview questions and answers

---

# 2. Where Is DynamoDB in the Architecture?

At a high level:

```text
                    Processing Pipeline
                           │
                           ▼
                 Final Invoice Result
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
             S3                     DynamoDB
        files/artifacts        application records
                                      │
                                      ▼
                                  API Lambda
                                      │
                                      ▼
                                 API Gateway
                                      │
                                      ▼
                                   React
```

Think:

> **S3 stores objects/files. DynamoDB stores application state and queryable records.**

---

# 3. What Is Amazon DynamoDB?

Simple definition:

> **Amazon DynamoDB is AWS's managed NoSQL database service.**

In traditional SQL, you might think about:

```text
Database
   ↓
Tables
   ↓
Rows
   ↓
Columns
```

In DynamoDB, think:

```text
Table
   ↓
Items
   ↓
Attributes
```

An item could conceptually look like:

```json
{
  "tenant_id": "user-123",
  "invoice_id": "inv_20260926_abc",
  "vendor": "ABC Ltd",
  "risk_score": 55,
  "risk_level": "MEDIUM"
}
```

This is a conceptual example, not a literal dump of a current DynamoDB item.

---

# 4. Why Does This Project Need a Database?

Imagine processing finishes successfully.

We now have information such as:

```text
Invoice ID

Tenant/User ID

Vendor

Invoice Number

Invoice Date

Total

Processing Status

Extracted Information

AI Findings

Risk Score

Risk Level

Metadata
```

The frontend later needs to ask:

```text
Show my invoices.

Show invoice ABC.

What is its status?

Show my analytics.
```

A queryable application database is useful for those operations.

That's where DynamoDB fits.

---

# 5. Why Not Store Everything Only in S3?

S3 is excellent for objects such as:

```text
PDF

PNG/JPEG

OCR artifacts

Processed files

Frontend static assets
```

But the frontend frequently needs structured application queries.

For example:

```text
Give me this user's invoices.
```

or:

```text
Give me invoice inv_123.
```

DynamoDB is better suited to those application access patterns.

So:

```text
S3
=
Object Storage
```

while:

```text
DynamoDB
=
Application Data / State
```

---

# 6. First DynamoDB Principle: Start With Access Patterns

This is one of the most important DynamoDB concepts.

With relational databases, beginners often think:

```text
What tables do I need?
```

With DynamoDB, an important question is:

> **How will my application access the data?**

For NovaMind AI, important access patterns include:

```text
1. Get one invoice

2. List invoices belonging to one tenant

3. Get processing status for an invoice

4. Aggregate invoice information for analytics

5. Delete an invoice belonging to a tenant
```

The data model should support those operations efficiently.

---

# 7. What Is a Partition Key?

Very simple:

> **A partition key is part of the primary key DynamoDB uses to identify and distribute data.**

Conceptually, if:

```text
tenant_id = user-123
```

is involved in the key design, records can be grouped around that tenant's identity.

Think:

```text
Tenant A
 ├── Invoice 1
 ├── Invoice 2
 └── Invoice 3

Tenant B
 ├── Invoice 4
 └── Invoice 5
```

That can also align naturally with user-scoped queries.

---

# 8. What Is a Sort Key?

When a DynamoDB table uses a composite primary key, it consists of:

```text
Partition Key
+
Sort Key
```

The sort key helps distinguish items within the same partition.

Conceptually:

```text
PK = tenant/user

SK = invoice
```

Then:

```text
user-A
   ├── invoice-001
   ├── invoice-002
   └── invoice-003
```

The exact repository key expressions should always be explained from the implementation rather than assumed from generic DynamoDB patterns.

---

# 9. Two Important Types of Records

For this project, mentally separate:

```text
INVOICE RECORD
```

from:

```text
JOB / PROCESSING RECORD
```

They solve different problems.

---

# 10. Invoice Record

The invoice record represents the application's processed invoice information.

Conceptually it can contain information related to:

```text
Invoice identity

Tenant identity

Extracted invoice information

Risk score

Risk level

Analysis findings

Metadata
```

This is what becomes useful when the frontend wants:

> “Show me this processed invoice.”

---

# 11. Job Record

The job record is about processing state.

Remember the upload flow:

```text
Request upload URL
      ↓
Generate invoice ID
      ↓
Create:
job_<invoice_id>
      ↓
Status = PENDING
```

The project creates a job before asynchronous processing completes.

This gives the application something to track while the invoice moves through:

```text
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
Storage
```

---

# 12. Why Separate Job State From Invoice Result?

Imagine upload just happened.

The final invoice result doesn't exist yet.

But the frontend still needs to know:

```text
Did processing start?

Is it still running?

Did it complete?

Did it fail?
```

Therefore:

```text
Job record
=
Processing lifecycle
```

while:

```text
Invoice record
=
Processed business result
```

That distinction is useful in asynchronous architectures.

---

# 13. Example Timeline

Think:

```text
T0
User requests upload URL
      ↓
Job = PENDING
```

Then:

```text
T1
File uploaded
      ↓
SQS message created
```

Then:

```text
T2
Workflow running
      ↓
Job status changes
```

Then:

```text
T3
Processing finishes
      ↓
Invoice result stored
      ↓
Job = COMPLETED
```

Or:

```text
Processing fails
      ↓
Job = FAILED
```

The important concept is:

> **The job tracks processing; the invoice record represents business data/results.**

---

# 14. Remember the Important Status Warning

From earlier files, we learned something subtle:

```text
COMPLETED
```

does not necessarily mean:

> Every AI component completed normally.

Certain handled Bedrock failures can produce degraded AI output while processing continues.

Therefore:

```text
Job status
```

and:

```text
AI-analysis status
```

are conceptually different things.

A stronger future data model could represent both explicitly.

---

# 15. What Is `tenant_id`?

In this project, `tenant_id` is effectively derived from the authenticated Cognito user's:

```text
sub
```

Recall File 05:

```text
User logs in
    ↓
Cognito
    ↓
JWT
    ↓
API Gateway validates JWT
    ↓
Backend reads:
claims.sub
    ↓
tenant_id
```

The current tenant model is essentially:

> **one Cognito user = one tenant identity**

It is not a full organization-based multi-tenant model.

---

# 16. Why Is Tenant Identity Important in DynamoDB?

Suppose:

```text
User A
```

owns:

```text
Invoice A
```

and:

```text
User B
```

owns:

```text
Invoice B
```

When User A requests data, backend logic should enforce:

```text
authenticated tenant
        =
record owner
```

This is not only a database-design concern.

It's an **authorization** concern.

---

# 17. Very Important Security Principle

Never trust:

```text
tenant_id sent by browser
```

as the source of identity.

Instead:

```text
Validated Cognito token
        ↓
claims.sub
        ↓
tenant_id
```

Then use that trusted tenant identity in database access.

This protects against something like:

```text
User A changes request:

tenant_id = User B
```

The backend should not accept that as authority.

---

# 18. Access Pattern 1 — List My Invoices

The frontend needs:

> “Show me all invoices belonging to the currently authenticated user.”

Conceptually:

```text
Authenticated User
       ↓
tenant_id
       ↓
DynamoDB Query
       ↓
Tenant's invoices
       ↓
React
```

The important word is:

> **Query**

not:

> **Scan the whole table and filter afterward.**

---

# 19. Query vs Scan

This is a common AWS interview question.

## Query

Think:

> “I know the key/group I want.”

Conceptually:

```text
Give me records for tenant A.
```

## Scan

Think:

> “Read through the table looking for matching data.”

Conceptually:

```text
Read everything
      ↓
Find tenant A
```

For tenant-specific access patterns, key-based `Query` operations are generally the more appropriate design.

---

# 20. Why Avoid Full Table Scans?

Imagine:

```text
100 invoices
```

A scan might not seem terrible.

Now imagine:

```text
10,000,000 invoices
```

Scanning large portions of the table for ordinary user requests would create scalability and cost problems.

DynamoDB design should therefore align keys with common access patterns.

---

# 21. Access Pattern 2 — Get One Invoice

The user opens:

```text
Invoice Detail Page
```

The backend needs:

```text
Authenticated tenant
+
Invoice ID
```

Conceptually:

```text
User
 ↓
GET invoice
 ↓
API Gateway
 ↓
Lambda
 ↓
tenant_id from Cognito
+
invoice_id
 ↓
DynamoDB
 ↓
Invoice record
```

The key security requirement is:

> **The requested invoice must belong to the authenticated tenant.**

---

# 22. Why Tenant-Scoped Lookup Is Powerful

Imagine an attacker knows:

```text
invoice_id = inv_secret_123
```

If backend code simply does:

```text
Get invoice by invoice_id
```

without ownership enforcement, knowing an identifier could expose another user's record.

A safer pattern is conceptually:

```text
Authenticated tenant
+
invoice identifier
```

used together to constrain access.

This connects:

```text
Data modeling
+
Authorization
```

---

# 23. Access Pattern 3 — Get Job Status

The frontend also polls processing status.

Conceptually:

```text
React
 ↓
GET job status
 ↓
API Lambda
 ↓
DynamoDB
 ↓
PENDING / RUNNING / COMPLETED / FAILED
```

This supports the asynchronous user experience.

But this is also where Codex identified an important authorization weakness.

---

# 24. Current Job-Status Ownership Gap

The current job-status logic performs a tenant-scoped invoice lookup first, but then retrieves:

```text
job_<invoice_id>
```

without independently comparing the job record's stored tenant identity to the requester.

This creates an incomplete ownership check in the status path.

The important lesson is:

> **Every resource lookup needs authorization enforcement at the point where that resource is accessed.**

A previous tenant check elsewhere in the flow doesn't automatically protect every subsequent lookup.

---

# 25. Why Is This Dangerous?

Imagine:

```text
User A
```

somehow knows:

```text
User B's invoice ID
```

If the status endpoint reaches:

```text
job_<invoice_id>
```

without correctly verifying:

```text
job.tenant_id == authenticated_user
```

the endpoint may expose information such as:

```text
Processing status

Current stage

Failure information

Error details
```

This doesn't necessarily mean the complete invoice document is exposed.

But it is still an authorization/data-isolation weakness.

---

# 26. How Should It Be Improved?

Conceptually:

```text
Request
   ↓
Validated Cognito user
   ↓
tenant_id
   ↓
Fetch job
   ↓
Compare:
job.tenant_id == tenant_id
   ↓
YES → return status
NO  → deny
```

Even better, data modeling can sometimes make cross-tenant access difficult by design.

For example:

```text
PK = tenant_id
SK = job_<invoice_id>
```

could naturally require the tenant identity as part of the lookup.

That exact redesign is a **future design suggestion**, not a claim about the current table.

---

# 27. Security Through Data Modeling

This is an advanced but important idea.

Suppose the data model is:

```text
PK = tenant_id
SK = invoice_id
```

To fetch an invoice, the application naturally needs:

```text
tenant_id + invoice_id
```

Now the authenticated identity is part of the database access pattern itself.

That's stronger than designing around:

```text
invoice_id only
```

and hoping every developer remembers to perform a separate ownership check.

Again, this is a conceptual design principle, not a claim that the current repository uses exactly this key schema.

---

# 28. Access Pattern 4 — Analytics

The frontend has analytics-related functionality.

How are analytics generated?

The current application does **not** rely on a separately verified analytics warehouse or precomputed aggregate store.

Instead, the API retrieves invoices belonging to the authenticated tenant using paginated DynamoDB `Query` operations and aggregates the results in Python.

Conceptually:

```text
Authenticated Tenant
       ↓
Query DynamoDB
       ↓
Invoice 1
Invoice 2
Invoice 3
...
       ↓
Python aggregation
       ↓
Analytics response
       ↓
React dashboard
```

---

# 29. Example Analytics

Suppose the tenant has:

```text
100 invoices
```

The backend can retrieve those records and calculate things such as:

```text
Total invoice count

Risk-level distribution

Aggregate totals

Other dashboard statistics
```

The exact analytics fields should be described from the repository implementation rather than invented.

The important architecture pattern is:

> **Retrieve tenant invoices → aggregate in Python → return analytics.**

---

# 30. Why Does Pagination Matter?

DynamoDB doesn't necessarily return an unlimited number of records in one request.

Therefore applications need to handle:

```text
Page 1
 ↓
More data?
 ↓
Page 2
 ↓
More data?
 ↓
Page 3
```

The current analytics/listing logic uses paginated DynamoDB Query calls.

This is an important implementation detail.

---

# 31. Pagination Mental Model

Conceptually:

```python
items = []

while more_pages:
    response = query(...)
    items.extend(response["Items"])

    if LastEvaluatedKey exists:
        continue
    else:
        stop
```

Do not memorize this as literal project source code.

The idea is:

```text
Query
 ↓
Items + continuation key
 ↓
Query next page
 ↓
Repeat
```

---

# 32. What Is `LastEvaluatedKey`?

In DynamoDB pagination, the response can indicate:

> “There is more data after this page.”

The application uses that continuation information to request the next page.

Conceptually:

```text
Query page 1
     ↓
LastEvaluatedKey
     ↓
Query page 2
     ↓
LastEvaluatedKey
     ↓
...
```

This prevents assuming one DynamoDB call always returns the complete dataset.

---

# 33. Analytics Scalability Problem

Current pattern:

```text
User requests analytics
        ↓
Read all relevant tenant invoices
        ↓
Aggregate in Python
```

For:

```text
50 invoices
```

this can be straightforward.

For:

```text
500,000 invoices
```

it becomes much more expensive and slower.

Therefore the current pattern has a scaling limitation.

---

# 34. Better Analytics Architecture

For larger scale, a future design could maintain precomputed aggregates.

For example:

```text
Invoice Completed
      ↓
Update aggregate counters
      ↓
Analytics table
```

Then dashboard request:

```text
GET /analytics
      ↓
Read small aggregate record
      ↓
Return quickly
```

instead of:

```text
Read every invoice
      ↓
Calculate everything again
```

This is a **future production improvement**, not the current implementation.

---

# 35. Example

Current:

```text
Tenant has 10,000 invoices

Analytics request
       ↓
Query many invoice records
       ↓
Python loops through them
       ↓
Calculate statistics
```

Potential future design:

```text
Every processed invoice
       ↓
Update:

total_count
low_count
medium_count
high_count
total_amount
...
```

Then:

```text
Analytics request
       ↓
Get aggregate record
       ↓
Return
```

This trades some write complexity for faster analytics reads.

---

# 36. DynamoDB vs S3

You should be able to answer this immediately.

| S3 | DynamoDB |
|---|---|
| Object storage | NoSQL database |
| Original invoices | Application records |
| OCR/processed artifacts | Job/status data |
| Files | Metadata |
| Large object storage | Queryable structured state |
| Frontend static files also stored in S3 | Risk/result records |

The project uses both because they solve different problems.

---

# 37. Why Not Put PDF Binary Data in DynamoDB?

Conceptually, invoice files belong in object storage.

You don't want your main application database to become your document-file store when S3 is purpose-built for that workload.

A cleaner architecture is:

```text
DynamoDB
   ↓
Metadata / application state

S3
   ↓
Actual document / artifact
```

Then a database record can reference information associated with the S3 object.

---

# 38. Why Not Put Every Small Piece of State in S3?

You technically can store JSON objects in S3.

But imagine needing:

```text
Get this user's invoices

Get one invoice's status

Filter/query application records

Update processing status
```

DynamoDB is much more natural for these frequent application-data access patterns.

Again:

```text
S3 = objects

DynamoDB = application state
```

is the mental model.

---

# 39. Deletion Flow

The project includes invoice deletion behavior.

At a high level:

```text
Authenticated User
       ↓
Delete Invoice API
       ↓
Verify tenant-scoped invoice
       ↓
Delete invoice record
       ↓
Attempt original S3 object deletion
```

But deletion is not currently a complete data-lifecycle cleanup.

---

# 40. Important Deletion Limitation

The current deletion path does not comprehensively remove all associated state.

Known gaps include things such as:

```text
Job record

Processed text/artifacts

Historical S3 versions
```

not necessarily being fully removed as part of one complete lifecycle operation.

This means:

```text
Delete invoice
```

does not automatically mean:

```text
Every trace of that invoice
has been deleted everywhere
```

That distinction matters for production data governance.

---

# 41. Why Historical S3 Versions Matter

If S3 versioning is enabled, deleting the current object doesn't necessarily mean old versions disappear.

Conceptually:

```text
invoice.pdf

Version 1
Version 2
Version 3
```

A delete operation may hide/remove the current version while historical versions remain depending on bucket/versioning behavior and lifecycle configuration.

Therefore:

> **Application deletion and physical data lifecycle are not automatically identical.**

We'll go much deeper into this in File 19.

---

# 42. Job Cleanup Matters Too

Suppose:

```text
Invoice record deleted ✓

Original PDF deleted ✓

Job record remains ✗
```

Now you have orphaned application state.

Similarly:

```text
Processed OCR artifact remains ✗
```

That's another orphan.

A production deletion workflow should understand all resources associated with one invoice.

---

# 43. Think in Terms of an Invoice Data Graph

One logical invoice can create multiple pieces of data:

```text
                    Invoice
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
 Original S3       DynamoDB         Processed S3
   Object          Invoice            Artifacts
                       │
                       ▼
                  Job Record
```

Potentially also:

```text
Events
Logs
Notifications
Historical versions
```

Therefore deletion needs a **data lifecycle strategy**, not simply one database delete call.

---

# 44. DynamoDB and Eventual Workflow State

This project is asynchronous.

That means the frontend can request invoice information before the processing workflow has finished storing the final record.

Remember from earlier:

```text
Upload
   ↓
Navigate to detail page
   ↓
Final invoice record may not exist yet
```

So an early invoice-detail request can return:

```text
404 / not available yet
```

while the job status still says:

```text
PENDING / PROCESSING
```

This isn't necessarily a database failure.

It can simply be a consequence of asynchronous processing.

---

# 45. This Creates Two Kinds of State

Think:

```text
PROCESSING STATE
────────────────
PENDING
RUNNING
FAILED
COMPLETED
```

and:

```text
BUSINESS DATA
─────────────
Vendor
Total
Risk Score
AI Findings
...
```

These don't necessarily appear at exactly the same time.

That's why understanding both invoice and job records matters.

---

# 46. NoSQL Does Not Mean “No Structure”

A common beginner mistake:

> “DynamoDB is NoSQL, so there is no structure.”

Wrong.

The application still needs a carefully designed structure.

You still care about:

```text
Keys

Attributes

Access patterns

Data types

Authorization

Indexes

Pagination

Consistency

Lifecycle
```

NoSQL means it isn't a traditional relational SQL database model.

It does **not** mean random data.

---

# 47. Why Not Use RDS?

Don't answer:

> “DynamoDB is always better than RDS.”

That's false.

A better interview answer is:

> “This project has a serverless event-driven architecture with relatively direct key-based access patterns, so DynamoDB fits the design well. If the workload required complex relational joins, transactional relational modeling or SQL-heavy reporting, I would evaluate a relational service such as RDS or Aurora instead.”

That shows architecture judgment rather than service loyalty.

---

# 48. Does DynamoDB Make the Application Serverless?

DynamoDB contributes to the serverless architecture because AWS manages the database infrastructure.

The application doesn't provision a traditional database server.

Combined with:

```text
API Gateway

Lambda

S3

SQS

Step Functions

DynamoDB
```

the application can avoid managing conventional backend servers.

But remember:

> **Serverless does not mean there are literally no servers.**

It means AWS manages the underlying infrastructure for you.

---

# 49. DynamoDB and IAM

Another security layer is:

```text
IAM
```

Your Lambda functions should receive only the DynamoDB permissions they require.

Conceptually:

```text
Invoice Read Lambda
      ↓
Read permission

Storage Lambda
      ↓
Required write permission
```

rather than giving every Lambda:

```text
dynamodb:*
on
*
```

The project analysis identifies per-function IAM roles/resource grants as one of its security foundations.

---

# 50. Three Different Security Layers

Do not mix these up.

### Layer 1 — Authentication

```text
Cognito
```

> Who is the user?

### Layer 2 — Application authorization

```text
tenant_id / ownership logic
```

> Is this user allowed to access this invoice?

### Layer 3 — AWS authorization

```text
IAM
```

> Is this Lambda allowed to access this DynamoDB resource?

These are different security problems.

---

# 51. Example

Suppose:

```text
Aamir logs in successfully
```

Cognito answers:

```text
Authentication ✓
```

But now Aamir requests another user's invoice.

Application must answer:

```text
Authorization ✗
```

Meanwhile, the Lambda itself needs IAM permission to query DynamoDB:

```text
AWS authorization ✓
```

Three different checks can exist in the same request path.

---

# 52. What Should We Improve in the Data Model?

Based on the current limitations, a stronger production design could focus on:

```text
1. Consistent tenant-scoped keys

2. Explicit ownership enforcement
   on every access path

3. Separate processing-stage status

4. Separate AI-analysis status

5. Better idempotency state

6. More deliberate analytics aggregates

7. Complete deletion/lifecycle mapping

8. Better orphan-record cleanup

9. Explicit retention policies

10. Access-pattern documentation
```

These are improvement directions, not claims that the current system already implements them.

---

# 53. A Production-Oriented Mental Model

Instead of thinking:

```text
"I need a DynamoDB table."
```

think:

```text
What does my application need to do?
             ↓
Define access patterns
             ↓
Define ownership boundaries
             ↓
Design keys
             ↓
Design item types
             ↓
Design indexes if needed
             ↓
Design write/update behavior
             ↓
Design deletion/lifecycle
             ↓
Design monitoring/cost
```

That is much closer to proper DynamoDB design thinking.

---

# 54. Current Project — What Is Implemented?

Based on our verified Codex project analysis:

```text
✓ DynamoDB used for application records/state

✓ Invoice records/results

✓ Processing job records

✓ Metadata/status information

✓ Risk-related result information

✓ Authenticated tenant identity used
  in invoice access paths

✓ Tenant-scoped invoice retrieval

✓ Paginated Query behavior

✓ Python-side analytics aggregation

✓ Invoice deletion behavior
```

Important:

> We should not invent an exact single-table key schema beyond what the repository evidence explicitly establishes.

---

# 55. Current Project — Important Limitations

```text
⚠ Current tenant effectively represents
  an individual Cognito user,
  not an organization

⚠ Job-status ownership enforcement
  is incomplete

⚠ Analytics reads tenant invoice records
  and aggregates in Python

⚠ This can become inefficient at scale

⚠ Job status and AI-stage success
  are not sufficiently distinguished

⚠ Deletion is not comprehensive

⚠ Job records can remain

⚠ Processed artifacts can remain

⚠ Historical S3 versions can remain

⚠ Complete enterprise data lifecycle
  is not implemented
```

These limitations are important because they help you discuss the project accurately instead of calling it perfectly production-ready.

---

# 56. Interview Preparation — 10 Questions

## Q1 — Why do you use DynamoDB in this project?

**Difficulty:** Basic

### Word-by-word practice answer

> “I use DynamoDB for structured application state and queryable invoice records. It stores information such as invoice results, processing-job state, metadata and risk-related information. S3 stores the actual document and file artifacts, while DynamoDB supports application access patterns such as listing invoices, retrieving invoice details and checking processing status.”

---

## Q2 — What is the difference between S3 and DynamoDB in your architecture?

**Difficulty:** Basic

### Word-by-word practice answer

> “S3 is my object-storage layer, so it is used for things such as original invoice files, processed artifacts and frontend static assets. DynamoDB is the NoSQL application database and stores structured records such as invoice metadata, results, processing state and risk information. I use each service for a different storage responsibility.”

---

## Q3 — What is an access pattern in DynamoDB?

**Difficulty:** Basic / Intermediate

### Word-by-word practice answer

> “An access pattern describes how my application needs to read or write data. In this project, examples include listing invoices for the authenticated tenant, retrieving one invoice, checking a processing job and generating tenant analytics. In DynamoDB I want the key and item design to support those common access patterns rather than designing the schema without considering how the application will query it.”

---

## Q4 — What is the difference between Query and Scan?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “A DynamoDB Query uses key conditions to retrieve a targeted set of items, while a Scan examines items across the table or index. For tenant-specific application access, I prefer key-based Query patterns because scanning the entire dataset for ordinary requests would become inefficient as the table grows.”

---

## Q5 — How do you isolate one user's invoices from another user?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The backend derives the tenant identity from the validated Cognito token rather than trusting a tenant ID supplied by the browser. The Cognito `sub` is effectively used as the current tenant identity, and invoice access is scoped to that authenticated tenant. However, I describe this as user-level tenant isolation rather than full organization-level multi-tenancy.”

---

## Q6 — Is your tenant isolation perfect?

**Difficulty:** Intermediate / Pressure

### Word-by-word practice answer

> “No. The main invoice paths are tenant scoped, but the current job-status path has an ownership gap. It performs a tenant-scoped invoice lookup and then retrieves the `job_<invoice_id>` record without independently comparing the job's stored tenant identity with the requester. For production I would enforce ownership directly on every resource access and preferably design the key structure so tenant identity is required for the lookup.”

---

## Q7 — How does your analytics endpoint work?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current analytics path retrieves the authenticated tenant's invoice records using paginated DynamoDB Query operations and performs the aggregation in Python. That is straightforward for a prototype or moderate dataset, but as the number of invoices grows it can increase read cost and latency. At larger scale I would consider maintaining precomputed aggregate records instead of recalculating everything from all invoice records on each request.”

---

## Q8 — Why do you need pagination with DynamoDB?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “I don't assume a DynamoDB query returns the complete logical dataset in one response. The application handles pagination and continues querying when DynamoDB provides continuation information such as a LastEvaluatedKey. That is important for invoice listing and especially analytics when a tenant has more records.”

---

## Q9 — What happens when a user deletes an invoice?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current deletion flow removes the tenant-scoped invoice record and attempts to delete the original S3 object. However, I would not call it complete data deletion because related job records, processed artifacts and historical S3 versions are not comprehensively removed. For production I would define a complete data-lifecycle workflow covering every resource associated with the invoice.”

---

## Q10 — How would you redesign the DynamoDB layer for production scale?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “I would start by documenting every access pattern and ownership boundary. Then I would design tenant-scoped keys that naturally require the authenticated tenant for invoice and job access, make processing and AI-stage statuses explicit, and add idempotency state where needed. For analytics, I would evaluate precomputed aggregate items rather than repeatedly reading all invoices. I would also define complete retention and deletion behavior across DynamoDB and S3 and validate the design against expected traffic before calling it production-ready.”

---

# 57. Interview Pressure Chain

An interviewer may begin:

> **“Why DynamoDB?”**

Then continue:

```text
Why not RDS?
    ↓
What do you store in DynamoDB?
    ↓
What do you store in S3?
    ↓
What is your partition key?
    ↓
What is your sort key?
    ↓
What are your access patterns?
    ↓
Do you use Query or Scan?
    ↓
Why?
    ↓
How do you paginate?
    ↓
How do you list one user's invoices?
    ↓
How do you enforce tenant isolation?
    ↓
Where does tenant_id come from?
    ↓
Can I send another tenant_id
from the frontend?
    ↓
What happens if I know
another invoice ID?
    ↓
Is your job-status endpoint secure?
    ↓
How does analytics work?
    ↓
What happens with
500,000 invoices?
    ↓
How would you redesign analytics?
    ↓
What happens when
an invoice is deleted?
    ↓
Does that remove every copy?
```

This is why File 13 is not simply:

> “DynamoDB is a NoSQL database.”

You need to understand how **your application uses it**.

---

# 58. One Diagram to Remember

```text
                   COGNITO
                      │
                      ▼
               Authenticated User
                      │
                 claims.sub
                      │
                      ▼
                  tenant_id
                      │
            ┌─────────┴─────────┐
            │                   │
            ▼                   ▼
      INVOICE ACCESS       JOB ACCESS
            │                   │
            ▼                   ▼
        DynamoDB             DynamoDB
            │                   │
      Invoice Result      Processing State
            │
            ├─────────────┐
            │             │
            ▼             ▼
      Detail/List      Analytics
                          │
                          ▼
                  Python Aggregation
```

And beside it:

```text
                    S3
                     │
       ┌─────────────┼─────────────┐
       ▼             ▼             ▼
    Original       Processed     Frontend
    Invoice        Artifacts      Assets
```

---

# 59. Five Things You Must Remember

**1. DynamoDB and S3 have different jobs.**

```text
S3       = objects/files
DynamoDB = structured application state
```

**2. DynamoDB design begins with access patterns.**

Not simply:

```text
"What columns should I create?"
```

but:

```text
"How will my application retrieve data?"
```

**3. Tenant identity comes from authenticated Cognito claims.**

```text
Cognito sub
→ tenant_id
```

not from blindly trusting browser input.

**4. Current tenant isolation has a known job-status weakness.**

Do not claim:

> “Every endpoint has perfect multi-tenant isolation.”

**5. Deleting the invoice record does not currently guarantee complete data deletion.**

Think:

```text
Invoice record
Original file
Job
Processed artifacts
Historical versions
```

as related lifecycle data.

---

# 60. Your 30-Second Interview Answer

> “I use DynamoDB as the structured application-state layer for invoice records, processing jobs, metadata and risk results, while S3 stores the actual documents and file artifacts. My DynamoDB access patterns include tenant-scoped invoice listing, invoice-detail retrieval, job-status checks and analytics. The authenticated Cognito `sub` is used as the current tenant identity rather than trusting a tenant ID from the client. Analytics currently retrieves the tenant's invoices through paginated queries and aggregates them in Python. I also identified improvement areas, particularly stronger ownership enforcement for job-status records, scalable analytics aggregation and complete deletion across DynamoDB and S3.”

---

# 61. Your 10-Second Mental Model

```text
Cognito
   ↓
Who owns the data?

DynamoDB
   ↓
Structured application state

S3
   ↓
Files and artifacts

Query
   ↓
Retrieve tenant data efficiently
```

Or even shorter:

> **S3 stores the document; DynamoDB stores the application's knowledge and state about the document.**

---

# 62. Check Your Understanding

Before moving to **`14-S3-DynamoDB-and-Application-State.md`**, answer these three without looking above.

**Question 1:** Why does this project use **both S3 and DynamoDB** instead of storing everything in only one of them?

**Question 2:** User A somehow learns User B's `invoice_id`. Why is knowing the invoice ID **not enough authorization** to return a job record?

**Question 3:** Today your analytics API reads all invoices for one tenant and aggregates them in Python. If one enterprise tenant eventually has **500,000 invoices**, what problem could appear, and what architecture change would you consider?