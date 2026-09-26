# Your question

**Create `15-Frontend-React-State-Polling-and-Analytics.md`.**

We have now reached the **frontend application layer** of NovaMind AI.

In File 14, we learned that backend state and frontend state are different:

```text
AWS Backend
    ↓
DynamoDB / S3
    ↓
API Gateway
    ↓
React Frontend
    ↓
What the user sees
```

The frontend has three especially important responsibilities in this project:

> **Authentication-aware UI + asynchronous processing status + invoice/analytics presentation.**

There are also two important implementation weaknesses we need to understand:

```text
1. Invoice detail can become stale after processing completes.

2. User-specific cached data is not completely cleared/namespaced
   when authentication changes.
```

---

# 15 — Frontend, React State, Polling and Analytics

## 1. What Will I Learn?

By the end of this file, I should understand:

- What React does in this project
- What frontend state means
- Local UI state vs server state
- Authentication state
- Zustand's role
- React Query's role
- API calls and authentication tokens
- Protected frontend routes
- Why frontend protection is not backend security
- Upload state
- Invoice-detail state
- Why polling is required
- How approximately 3-second polling works
- Why polling stops
- The current stale-detail problem
- Query invalidation
- Loading, error and completed states
- The current FAILED-state UI weakness
- How analytics reaches the frontend
- Why analytics is calculated in Python
- Analytics scalability limitations
- User-specific cache isolation
- Why logout should clear private state
- How I would improve the frontend
- 10 project-specific interview questions and answers

---

# 2. Where Is the Frontend?

Our full architecture contains many backend services:

```text
Cognito
API Gateway
Lambda
S3
SQS
Step Functions
Textract
Bedrock
DynamoDB
```

But the user doesn't directly interact with those services.

The user interacts with:

```text
┌─────────────────────────────┐
│       REACT FRONTEND        │
│                             │
│ Login                       │
│ Upload Invoice              │
│ Processing Status           │
│ Invoice Details             │
│ Risk Results                │
│ Analytics                   │
└──────────────┬──────────────┘
               │
               ▼
          API Gateway
               │
               ▼
           AWS Backend
```

So the frontend is the application's **user-facing layer**.

---

# 3. What Is React?

Simple definition:

> **React is a JavaScript library used to build user interfaces from reusable components.**

Instead of building one enormous page, we can conceptually have:

```text
Application
│
├── Login
├── Dashboard
├── Upload
├── Invoice List
├── Invoice Detail
├── Analytics
└── Navigation
```

Each part can be built from reusable React components.

---

# 4. What Does the Frontend Actually Do?

The frontend is responsible for things such as:

```text
User authentication UI
        ↓
Upload interface
        ↓
Calling backend APIs
        ↓
Showing processing progress
        ↓
Displaying invoice results
        ↓
Displaying risk information
        ↓
Displaying analytics
```

But it should **not** be responsible for trusted backend decisions such as:

```text
Authorizing another user's invoice

Calculating trusted final risk score

Deciding tenant identity

Performing OCR

Running Bedrock inference
```

Those belong on the backend.

---

# 5. What Is Frontend State?

State means information the UI needs to remember.

For example:

```text
Who is logged in?

Which invoice is selected?

Is upload running?

What invoices were returned?

Is processing complete?

What filters are selected?

What result is cached?
```

Those are all examples of frontend state.

---

# 6. Two Important Categories of Frontend State

A useful mental model is:

```text
FRONTEND STATE
     │
     ├── Client/UI State
     │
     └── Server State
```

Let's understand the difference.

---

# 7. Client / UI State

Client state is information primarily controlled by the frontend.

Examples:

```text
Selected file

Selected filter

Modal open/closed

Current UI selection

Authentication-related UI state
```

The application uses frontend state management for these kinds of concerns.

---

# 8. Server State

Server state comes from the backend.

Examples:

```text
Invoice list

Invoice details

Job status

Analytics results
```

The frontend doesn't own the authoritative version of this data.

The backend does.

The frontend:

```text
fetches
↓
caches
↓
renders
↓
refetches
```

it.

---

# 9. Zustand and React Query

The project uses different frontend state mechanisms for different responsibilities.

A useful conceptual separation is:

```text
Zustand
   ↓
Application/client state
```

and:

```text
React Query
   ↓
Backend/server data
```

For example, the verified authentication flow records the current user in Zustand for UI rendering.

React Query manages fetched API data and its cache.

---

# 10. Why Not Put Everything in One State Store?

Because server data behaves differently from ordinary UI state.

For example, invoice data may need:

```text
Fetching

Loading

Error handling

Caching

Retrying

Refetching

Invalidation
```

React Query is designed around this kind of server-state lifecycle.

Meanwhile something like:

```text
selected filter
```

doesn't necessarily need all of those behaviors.

---

# 11. Authentication Flow Revisited

Remember File 05.

The frontend authentication flow is approximately:

```text
React Application
      ↓
Amplify
      ↓
Amazon Cognito
      ↓
Authentication
      ↓
Current user/session
      ↓
Zustand
      ↓
UI knows user is authenticated
```

But another important step happens when calling APIs.

---

# 12. Authenticated API Request

The frontend retrieves the authenticated session/token and sends it with API requests.

Conceptually:

```text
React
   ↓
Get current Cognito session
   ↓
Retrieve ID token
   ↓
Authorization header
   ↓
API Gateway
   ↓
Cognito Authorizer
   ↓
Lambda
```

This is how the frontend communicates authenticated identity to the backend.

---

# 13. API Interceptor

Instead of manually writing authentication logic for every API request, the frontend uses an API interception pattern.

Conceptually:

```javascript
request
   ↓
interceptor
   ↓
get token
   ↓
add Authorization header
   ↓
send request
```

So components can make API calls while shared networking logic handles authentication.

---

# 14. Frontend Route Protection

The application also protects frontend routes.

Conceptually:

```text
User opens protected page
        ↓
Authenticated?
      /       \
    YES        NO
     ↓          ↓
Render       Redirect
Page          Login
```

This improves the user experience.

But there is an extremely important security lesson here.

---

# 15. Protected React Routes Are NOT Backend Security

Suppose someone bypasses the React application entirely and directly calls:

```text
API endpoint
```

Frontend route protection cannot stop that.

Therefore:

```text
React Protected Route
=
UI/navigation protection
```

while:

```text
API Gateway Cognito Authorizer
+
Backend ownership checks
=
Actual backend access control
```

Never say:

> “My API is secure because I use protected React routes.”

---

# 16. Upload Flow from the Frontend

Now let's connect React to File 06.

User selects an invoice.

Frontend performs checks such as:

```text
Allowed MIME type?

File <= 10 MiB?
```

Then:

```text
React
   ↓
POST /invoices/upload-url
   ↓
API Gateway
   ↓
Lambda
   ↓
Presigned S3 URL
```

Then the browser uploads directly:

```text
Browser
   ↓
PUT
   ↓
S3
```

---

# 17. Why Does React Upload Directly to S3?

Because the file does not need to travel:

```text
Browser
   ↓
API Gateway
   ↓
Lambda
   ↓
S3
```

Instead:

```text
Browser
   ↓
S3
```

using the temporary presigned URL.

The backend remains responsible for generating the authorized upload destination.

---

# 18. What Happens After Upload?

This is where frontend state becomes interesting.

The browser finishes uploading.

But:

```text
Upload complete
```

does **not** mean:

```text
Invoice analysis complete
```

Instead:

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

still needs to happen.

The frontend therefore needs to track asynchronous processing.

---

# 19. The User Goes to Invoice Detail

After upload, the application can navigate to the invoice detail view.

Conceptually:

```text
Upload succeeds
     ↓
invoice_id known
     ↓
Navigate:
Invoice Detail
```

The frontend then needs two important pieces of information:

```text
1. Invoice result

2. Processing status
```

These are related but different.

---

# 20. Why Two Queries?

Because the final invoice record may not exist yet.

Immediately after upload:

```text
Job record      ✓

Final invoice   ✗
```

Therefore:

```text
GET invoice detail
```

may initially fail/not find the final record.

Meanwhile:

```text
GET job status
```

can tell the frontend:

```text
PENDING
PROCESSING
COMPLETED
FAILED
```

depending on the application state.

---

# 21. What Is Polling?

Simple definition:

> **Polling means repeatedly asking the backend whether something has changed.**

For example:

```text
Frontend:
"Finished?"
    ↓
No

wait

"Finished?"
    ↓
No

wait

"Finished?"
    ↓
Yes
```

That's polling.

---

# 22. Polling in This Project

The invoice detail/status flow polls approximately every:

```text
3 seconds
```

while processing is ongoing.

Conceptually:

```text
GET status
    ↓
PROCESSING
    ↓
wait ~3 sec
    ↓
GET status
    ↓
PROCESSING
    ↓
wait ~3 sec
    ↓
GET status
    ↓
COMPLETED
```

Then status polling stops.

---

# 23. Why Use Polling?

Because processing is asynchronous.

The original HTTP upload request is not kept open while:

```text
Textract

Bedrock

Risk scoring

Storage
```

finish.

Therefore the browser needs a later mechanism to discover:

> “Is my invoice ready?”

Polling is a simple solution.

---

# 24. Why Not Keep the HTTP Request Open?

Imagine processing takes:

```text
several seconds
```

or encounters retries.

Holding one long synchronous request through the entire pipeline would tightly couple:

```text
User request
```

to:

```text
backend processing duration
```

Instead, the project uses:

```text
Submit
   ↓
Process asynchronously
   ↓
Poll status
```

This provides better decoupling.

---

# 25. Polling Is Not Free

Suppose one browser asks every 3 seconds.

That's approximately:

```text
20 requests/minute
```

while polling continues.

Now imagine:

```text
1,000 simultaneously processing users
```

Frequent polling can generate significant API traffic.

So polling interval design is a tradeoff:

```text
Short interval
   ↓
Faster UI updates
but
More requests
```

versus:

```text
Long interval
   ↓
Fewer requests
but
Slower visible updates
```

---

# 26. Why 3 Seconds?

For this project, the current implementation uses approximately a three-second polling interval.

Don't tell an interviewer:

> “Three seconds is mathematically optimal.”

There is no evidence for that.

Say:

> “The current frontend uses approximately three-second polling as a simple responsiveness-versus-request-frequency tradeoff.”

That's accurate.

---

# 27. When Does Polling Stop?

The current status polling stops when it reaches terminal states such as:

```text
COMPLETED
```

or:

```text
FAILED
```

This is important.

Otherwise the browser could continue sending requests indefinitely.

---

# 28. The Important Frontend Bug

Now we reach one of the most important findings.

Imagine:

```text
T0
Upload completed
```

Frontend opens detail page.

```text
T1
GET invoice detail
      ↓
404
```

because processing isn't finished.

React Query now has an error/not-found state associated with the detail request.

Meanwhile:

```text
T2
Status = PROCESSING
```

Then:

```text
T3
Backend finishes
```

DynamoDB now contains final invoice data.

Status becomes:

```text
COMPLETED
```

But...

---

# 29. Detail Query May Remain Stale

The current frontend does not reliably invalidate/refetch the invoice-detail query when status becomes:

```text
COMPLETED
```

So backend:

```text
Invoice exists ✓
```

while frontend can still behave as though:

```text
Invoice unavailable ✗
```

This is not necessarily an AWS backend failure.

It is a:

> **frontend server-state synchronization problem.**

---

# 30. What Is Query Invalidation?

Suppose React Query cached:

```text
Invoice X = not available
```

Later we know the backend changed.

We can tell React Query:

> “The cached value for Invoice X is stale. Fetch it again.”

Conceptually:

```text
Status = COMPLETED
       ↓
Invalidate invoice query
       ↓
Refetch invoice detail
       ↓
Receive final record
       ↓
Render result
```

That's query invalidation.

---

# 31. Better Flow

A stronger frontend flow would be:

```text
Upload
   ↓
Navigate to detail
   ↓
Poll status
   ↓
PROCESSING
   ↓
Show processing UI
   ↓
COMPLETED
   ↓
Invalidate detail query
   ↓
Fetch final invoice
   ↓
Render analysis
```

This connects the two server-state queries properly.

---

# 32. Alternative Approach

Another possible design would avoid aggressively requesting the final detail until status says it's ready.

For example:

```text
Status query
     ↓
PROCESSING
     ↓
Don't request final result yet
     ↓
COMPLETED
     ↓
Enable detail query
```

This can prevent the initial 404 problem entirely.

That's a **possible improvement**, not the current verified implementation.

---

# 33. FAILED State

The frontend also needs to handle:

```text
FAILED
```

properly.

A good UI should ideally tell the user:

```text
Processing failed

Where possible:
meaningful user-safe error information

Possible next action:
retry/re-upload/contact support
```

But the current UI has a weakness.

---

# 34. Current Failure-UI Weakness

The project analysis found that the failure banner can disappear for the:

```text
FAILED
```

state instead of clearly presenting the job error to the user.

That means backend state can correctly say:

```text
FAILED
```

while the frontend does not communicate the failure as clearly as it should.

Again:

```text
Correct backend state
≠
Good user experience
```

---

# 35. Better Error-State Design

A stronger frontend should deliberately represent:

```text
PENDING
PROCESSING
COMPLETED
FAILED
DEGRADED
```

if the backend supports those states.

For example:

```text
PROCESSING
→ spinner/progress message

COMPLETED
→ final analysis

FAILED
→ failure explanation + retry action

DEGRADED
→ result + warning
```

`DEGRADED` is a proposed improvement because the current backend doesn't cleanly expose all AI degradation as a separate business state.

---

# 36. Loading State Is Not Error State

These are different:

```text
Loading
```

means:

> “I don't have the response yet.”

```text
Error
```

means:

> “The request failed.”

```text
Processing
```

means:

> “The backend is still doing work.”

```text
Empty
```

means:

> “The request succeeded but there is no relevant data.”

A mature frontend should distinguish them.

---

# 37. Authentication State

Another frontend state is:

```text
current user
```

After Cognito authentication:

```text
Amplify
   ↓
Current session/user
   ↓
Zustand
   ↓
React renders authenticated UI
```

When the user logs out:

```text
Authentication state
```

must be cleared.

But that's not the only state that matters.

---

# 38. The Logout Cache Problem

Imagine:

```text
User A logs in
      ↓
GET /invoices
      ↓
React Query caches User A's data
```

Then:

```text
User A logs out
```

Then:

```text
User B logs in
```

If the query cache isn't cleared or user-scoped correctly, stale User A data can remain in the browser cache.

That creates a security-sensitive frontend isolation issue.

---

# 39. Why Query Keys Matter

Suppose the query key is only:

```text
["invoices"]
```

Then conceptually both users can map to:

```text
["invoices"]
```

in the client cache.

A stronger pattern is conceptually:

```text
["invoices", authenticatedUserId]
```

Then:

```text
User A
→ ["invoices", "A"]

User B
→ ["invoices", "B"]
```

This helps namespace cached server data by user.

This is an improvement pattern, not a claim that the project already does this.

---

# 40. Logout Should Clear Private State

A strong logout flow could conceptually do:

```text
Logout
   ↓
Sign out from Cognito
   ↓
Clear auth state
   ↓
Clear private React Query cache
   ↓
Clear upload state
   ↓
Clear user-specific filters/state
   ↓
Redirect to login
```

The current project does not comprehensively clear all of these areas.

---

# 41. Why Is This Security, Not Just UI?

Because stale data can belong to another authenticated user.

Imagine:

```text
Shared computer

User A logs out

User B logs in

User A's invoice information briefly appears
```

Even if the backend correctly prevents User B from requesting User A's data, exposing stale cached data is still a privacy/security problem.

Therefore:

> **Frontend cache isolation is part of end-to-end data isolation.**

---

# 42. Backend Authorization Still Matters

Even if frontend cache isolation is perfect, backend authorization remains mandatory.

Never think:

```text
User-specific React Query key
=
Security boundary
```

It isn't.

Actual backend protection remains:

```text
Cognito authentication
        +
API Gateway authorizer
        +
Tenant ownership enforcement
```

Frontend isolation is an additional protection.

---

# 43. Invoice List Flow

The dashboard/list view conceptually works like:

```text
React
   ↓
Authenticated API request
   ↓
API Gateway
   ↓
Lambda
   ↓
DynamoDB Query
   ↓
Tenant's invoices
   ↓
React Query
   ↓
Render invoice list
```

This is another example of:

```text
Backend server state
        ↓
Frontend cached server state
```

---

# 44. Invoice Detail Flow

Conceptually:

```text
User selects invoice
       ↓
React Router
       ↓
invoice_id
       ↓
React Query
       ↓
API request
       ↓
DynamoDB-backed API
       ↓
Invoice result
       ↓
Render
```

But for a newly uploaded invoice, asynchronous processing complicates this because the record may not yet exist.

---

# 45. Analytics Flow

Now let's connect File 13.

The frontend requests analytics.

Conceptually:

```text
Analytics Page
      ↓
API request
      ↓
API Gateway
      ↓
Lambda
      ↓
DynamoDB
      ↓
Query authenticated tenant's invoices
      ↓
Paginate through results
      ↓
Aggregate in Python
      ↓
Return analytics JSON
      ↓
React renders dashboard
```

There is no separately verified analytics warehouse in the current project.

---

# 46. Where Is Analytics Calculated?

Important interview answer:

> **The current analytics aggregation is performed in the backend using Python after retrieving the authenticated tenant's invoice records from DynamoDB.**

Don't say:

```text
React calculates all analytics
```

unless referring only to presentation-specific calculations actually verified in frontend code.

The main project analysis identifies backend Python aggregation.

---

# 47. Why Not Let React Download Everything and Calculate It?

Imagine returning every raw invoice record to the browser just so JavaScript can calculate:

```text
HIGH count

MEDIUM count

LOW count
```

That can:

```text
Increase network transfer

Expose unnecessary data

Move trusted business logic to client

Increase frontend work
```

Backend aggregation allows the API to return only the analytics result required by the UI.

---

# 48. Analytics Scalability Limitation

Current architecture:

```text
Analytics Request
       ↓
Query all relevant tenant invoices
       ↓
Pagination
       ↓
Aggregate in Python
```

This can work for a modest dataset.

But imagine one tenant has:

```text
500,000 invoices
```

Every analytics request could require substantial DynamoDB reads and backend computation.

That can affect:

```text
Latency

Read consumption/cost

Lambda duration

User experience
```

---

# 49. Better Analytics at Scale

A future architecture could maintain aggregate records.

For example:

```text
Invoice completed
      ↓
Risk = HIGH
      ↓
Update analytics counters
```

Store:

```text
total_invoices

low_count

medium_count

high_count

total_amount
```

Then:

```text
Analytics Page
      ↓
API
      ↓
Read small aggregate
      ↓
Return
```

This is a future design, not the current implementation.

---

# 50. Polling vs Push Architecture

Current:

```text
Browser
   ↓
"Are you done?"
   ↓
Backend
   ↓
"No"

3 sec later...

Browser
   ↓
"Are you done?"
```

This is:

```text
Polling
```

A push-oriented future architecture might use something like:

```text
Backend processing completes
       ↓
Push event
       ↓
Browser receives update
```

Possible technologies could include:

```text
WebSockets

AppSync subscriptions

Server-Sent Events
```

depending on requirements.

Do not claim these are currently implemented.

---

# 51. Is Polling Bad?

No.

Polling is not automatically bad architecture.

For a relatively simple application, it offers:

```text
Simple implementation

Easy mental model

Works with standard HTTP APIs

No persistent client connection required
```

The tradeoff is repeated requests.

A strong architect chooses based on:

```text
Scale

Latency requirements

Complexity

Cost

User experience
```

not because one technique is universally “better.”

---

# 52. Frontend and Presigned URL Security

The browser receives:

```text
temporary presigned URL
```

That doesn't mean the frontend receives permanent AWS credentials.

The flow is:

```text
Authenticated user
      ↓
Backend generates temporary URL
      ↓
Browser uploads using URL
```

This is very different from placing:

```text
AWS access key
AWS secret key
```

inside React.

Never put long-lived AWS credentials in frontend code.

---

# 53. Environment Configuration

Frontend applications often need public configuration such as:

```text
API endpoint

Cognito identifiers

Region

CloudFront/application URLs
```

But remember:

> **Frontend code is delivered to the user's browser.**

Therefore frontend environment variables should not be treated as a safe place for secrets.

A value becoming part of the browser bundle should be considered visible to the client.

---

# 54. React Does Not Enforce Tenant Isolation

This deserves repeating.

Suppose React hides:

```text
Delete button
```

for a user.

That does not prove the backend prevents:

```text
DELETE /invoice/X
```

from being called manually.

Therefore:

```text
Frontend controls
=
User experience
```

and:

```text
Backend authorization
=
Security enforcement
```

---

# 55. Loading, Processing and Result UX

A strong invoice experience should reflect backend lifecycle.

Conceptually:

```text
SELECT FILE
    ↓
UPLOADING
    ↓
UPLOAD COMPLETE
    ↓
PROCESSING
    ↓
ANALYZING
    ↓
RESULT READY
```

If failure occurs:

```text
PROCESSING
    ↓
FAILED
    ↓
Useful next action
```

The more clearly UI states map to real backend states, the easier the application is to understand and troubleshoot.

---

# 56. Don't Invent Progress

Suppose the backend only exposes:

```text
PROCESSING
```

The frontend should not fake:

```text
OCR 43% complete
```

unless it actually has evidence supporting that percentage.

A spinner or stage-based indicator can be more honest than fake precision.

---

# 57. Frontend Error Messages

There are two audiences:

```text
User
```

and:

```text
Developer/operator
```

A user may need:

> “Invoice processing failed. Please retry.”

The operator may need:

```text
invoice_id

execution ID

exception

stack trace

AWS service error
```

Don't expose internal stack traces or sensitive infrastructure information directly in the UI.

Detailed diagnostics belong in observability/logging systems.

---

# 58. Frontend State Mental Model

Remember:

```text
                   REACT
                     │
       ┌─────────────┼──────────────┐
       ▼             ▼              ▼
 Authentication   UI State      Server State
       │             │              │
    Zustand       Filters       React Query
       │          Upload            │
       │          Selection         ├── invoices
       │                            ├── detail
       │                            ├── status
       │                            └── analytics
       │
       └────────── authenticated API calls
```

The exact ownership of every small UI value should come from source code, but this is the useful project-level mental model.

---

# 59. Complete Frontend Request Flow

```text
USER
 │
 ▼
React
 │
 ├── Amplify/Cognito authentication
 │
 ▼
Authenticated Session
 │
 ▼
API Client
 │
 ├── Get token
 │
 └── Add Authorization header
 │
 ▼
API Gateway
 │
 ▼
Cognito Authorizer
 │
 ▼
Lambda
 │
 ▼
DynamoDB / Backend
 │
 ▼
JSON Response
 │
 ▼
React Query
 │
 ▼
React Components
 │
 ▼
USER
```

---

# 60. Complete Upload + Polling Flow

```text
User selects invoice
        │
        ▼
Frontend validation
        │
        ▼
Request presigned URL
        │
        ▼
Upload directly to S3
        │
        ▼
Navigate to invoice detail
        │
        ├───────────────┐
        ▼               ▼
 Detail Query       Status Query
        │               │
   may be 404       PROCESSING
                        │
                     ~3 sec
                        │
                        ▼
                   Status Query
                        │
                    COMPLETED
                        │
                        ▼
                  Stop Polling
                        │
                        ▼
             Detail should refetch
```

Current weakness:

```text
COMPLETED
   ↓
Detail refetch/invalidation
is not reliably connected
```

---

# 61. Complete Analytics Flow

```text
React Analytics Page
        ↓
Authenticated API request
        ↓
API Gateway
        ↓
Lambda
        ↓
tenant_id from Cognito claims
        ↓
DynamoDB Query
        ↓
Pagination
        ↓
Tenant invoice records
        ↓
Python aggregation
        ↓
Analytics JSON
        ↓
React Query
        ↓
Dashboard UI
```

---

# 62. What Is Strong in the Current Frontend?

The current design has several useful foundations:

```text
✓ React-based UI

✓ Cognito/Amplify authentication flow

✓ Authenticated API requests

✓ Frontend route protection

✓ Direct presigned S3 upload

✓ Asynchronous status polling

✓ Server-state caching/query mechanism

✓ Invoice detail/list presentation

✓ Analytics UI

✓ Separation between frontend
  and backend processing
```

---

# 63. What Needs Improvement?

Important verified/current concerns include:

```text
⚠ Detail query can become stale
  after processing completes

⚠ Status completion doesn't reliably
  invalidate/refetch invoice detail

⚠ FAILED-state UI does not clearly
  surface job failure information

⚠ Query keys lack user identity

⚠ Logout doesn't comprehensively
  clear React Query cache

⚠ Upload/filter state isn't fully cleared

⚠ Same-browser user switching can
  expose stale previous-user data

⚠ Polling creates repeated requests

⚠ Analytics becomes expensive as
  tenant invoice count grows
```

These are excellent interview discussion points because they show you understand both:

```text
what works
```

and:

```text
what needs engineering improvement
```

---

# 64. Production Improvement Plan

A stronger frontend could implement:

```text
1. User-scoped query keys

2. Clear all private cache/state on logout

3. Explicit query invalidation on COMPLETED

4. Better FAILED-state rendering

5. Separate DEGRADED state if backend supports it

6. Smarter polling/backoff

7. Stop polling when page is inactive,
   where appropriate

8. Better retry controls

9. Clear processing-state UX

10. Precomputed analytics at larger scale
```

Again, these are **future improvements**, not current claims.

---

# 65. Interview Preparation — 10 Questions

## Q1 — What frontend technology do you use?

**Difficulty:** Basic

### Word-by-word practice answer

> “The frontend is built with React. It provides the authentication interface, invoice upload flow, invoice listing and detail views, processing-status experience, risk-result presentation and analytics dashboard. The frontend communicates with the backend through authenticated API Gateway endpoints.”

---

## Q2 — How does the frontend authenticate API requests?

**Difficulty:** Basic

### Word-by-word practice answer

> “The frontend uses AWS Amplify with Amazon Cognito for authentication. After login, the application obtains the current authenticated session, and the API client retrieves the Cognito ID token and adds it to the Authorization header. API Gateway uses a Cognito authorizer to validate the token before the request reaches the backend Lambda.”

---

## Q3 — Why do you poll the backend?

**Difficulty:** Basic / Intermediate

### Word-by-word practice answer

> “Invoice processing is asynchronous. After the browser uploads the invoice to S3, SQS, Step Functions, Textract, Bedrock, risk scoring and storage still need to run. The frontend therefore polls the processing-status API approximately every three seconds until the job reaches a terminal state such as completed or failed.”

---

## Q4 — Why can invoice detail initially return 404?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The frontend can navigate to the invoice detail page immediately after upload, but the final invoice record is only created after asynchronous processing finishes. Therefore the detail API can initially return not found even though the job is still processing normally. The job-status endpoint exists separately so the frontend can track that lifecycle.”

---

## Q5 — What frontend bug did you identify in that flow?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The invoice-detail query can enter an error or empty state before processing finishes. The status query continues polling and eventually reaches completed, but the current implementation does not reliably invalidate and refetch the earlier detail query at that transition. I would explicitly invalidate the invoice-detail query when status becomes completed so the UI immediately retrieves the final record.”

---

## Q6 — Why isn't a protected React route enough for security?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “A protected React route only controls navigation in the browser. A user can bypass the frontend and call an API directly, so backend security must still be enforced by the Cognito authorizer and application-level tenant ownership checks. I treat frontend route protection as a user-experience feature, not the API security boundary.”

---

## Q7 — What security issue exists with frontend caching?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The current React Query keys are not sufficiently namespaced by authenticated user identity, and logout clears authentication state without comprehensively clearing private query and UI state. On a shared browser, stale data from User A could therefore remain when User B logs in. I would namespace private query keys by user and clear all private cache and user-specific state during logout.”

---

## Q8 — How does your analytics dashboard work?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The frontend calls an authenticated analytics API. The backend derives the tenant identity from the Cognito claims, queries that tenant's invoice records from DynamoDB using pagination, performs the aggregation in Python and returns the analytics result to the React application. The current design does not rely on a separate analytics warehouse or precomputed aggregate store.”

---

## Q9 — What is the scalability problem with your current analytics design?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “The backend currently reads the tenant's invoice records and recalculates analytics in Python for the request. That is straightforward at smaller scale, but as a tenant accumulates a very large number of invoices, read volume, Lambda execution time, latency and cost can increase. At larger scale I would evaluate incrementally maintained aggregate records so the dashboard can read precomputed statistics instead of repeatedly processing the full invoice dataset.”

---

## Q10 — How would you improve the frontend for production?

**Difficulty:** Advanced / System Design

### Word-by-word practice answer

> “I would first fix server-state synchronization by invalidating the invoice-detail query when processing reaches completed. I would make private query keys user-specific and clear all private caches and upload or filter state on logout. I would improve failed and degraded processing states so users clearly understand what happened, and I would evaluate smarter polling or a push-based update mechanism if concurrency made polling expensive. Finally, I would align the analytics UI with a more scalable backend aggregation strategy.”

---

# 66. Interview Pressure Chain

An interviewer might start:

> **“How does your React frontend know the invoice has finished processing?”**

Then continue:

```text
Why is processing asynchronous?
        ↓
What is polling?
        ↓
How frequently do you poll?
        ↓
Why three seconds?
        ↓
When do you stop?
        ↓
What happens before the
invoice result exists?
        ↓
Can detail return 404?
        ↓
What happens to that cached error?
        ↓
When status becomes COMPLETED,
does detail automatically refetch?
        ↓
What's wrong with the current flow?
        ↓
How would you fix it?
        ↓
What happens if processing fails?
        ↓
Does the UI show the failure properly?
        ↓
What happens when User A logs out
and User B logs in?
        ↓
Is React route protection security?
        ↓
Where is authorization enforced?
        ↓
How does analytics work?
        ↓
What happens with 500,000 invoices?
        ↓
Would you continue polling at scale?
```

If you can answer this chain, you understand the frontend as part of a **distributed production system**, not simply as a collection of React pages.

---

# 67. Troubleshooting Scenario

Interviewer:

> **“The AWS workflow completed successfully, but the user still can't see the invoice result. What would you check?”**

### Word-by-word answer

> “First, I would verify whether the final invoice record was actually written to DynamoDB, because workflow completion and final data availability should be checked separately. If the backend data exists, I would inspect the invoice-detail API response. If that API returns the correct result, I would move to the frontend and check the React Query state. In this project, the detail query can initially fail while processing is still running, and the completion transition does not reliably invalidate that query. So I would verify whether the frontend is displaying stale cached state before assuming the AWS processing pipeline failed.”

That's a very strong project-specific troubleshooting answer.

---

# 68. Architecture Decision Question

Interviewer:

> **“Why did you choose polling instead of WebSockets?”**

A good answer:

> “For the current project, polling keeps the frontend and backend architecture simple because processing updates are relatively coarse and the application already exposes HTTP APIs. The current implementation polls approximately every three seconds and stops at a terminal state. If concurrency or real-time responsiveness requirements increased significantly, I would compare that approach with a push-based design such as WebSockets or subscriptions, considering connection management, operational complexity and cost rather than assuming one approach is universally better.”

Notice the answer does **not** say:

> “WebSockets are better.”

Architecture decisions depend on requirements.

---

# 69. Five Things You Must Remember

**1. React is the presentation layer, not the security boundary.**

```text
React route protection
≠
backend authorization
```

**2. Upload completion is not processing completion.**

```text
S3 upload ✓
≠
Textract + Bedrock + scoring finished
```

**3. Polling exists because processing is asynchronous.**

```text
~3 seconds
↓
check status
↓
stop on terminal state
```

**4. Current frontend has a stale-detail problem.**

```text
Detail → 404
Status → COMPLETED
Detail → may remain stale
```

Potential fix:

```text
COMPLETED
↓
invalidate/refetch detail
```

**5. User-specific backend security is not enough if the browser leaks stale cached data.**

```text
Logout
↓
Clear authentication
+
Clear private frontend state
```

---

# 70. Your 30-Second Interview Answer

> “The frontend is built with React and uses Amplify with Cognito for authentication. Authenticated API requests include the Cognito token, while React Query manages server data such as invoices, job status and analytics. Because invoice processing is asynchronous, the frontend polls the job status approximately every three seconds until it reaches completed or failed. One issue I identified is that invoice detail can initially return 404 while processing is running, and the detail query is not reliably invalidated when status later becomes completed. I would fix that synchronization and also namespace or clear user-specific cached data on logout. Analytics is calculated on the backend by querying the authenticated tenant's DynamoDB invoices and aggregating them in Python.”

---

# 71. Your 10-Second Mental Model

```text
React
  ↓
Show UI

Amplify + Cognito
  ↓
Authenticate

React Query
  ↓
Fetch + cache backend data

Polling
  ↓
Track asynchronous processing

Analytics API
  ↓
Backend aggregates DynamoDB data
```

Or even shorter:

> **React displays → Cognito authenticates → React Query fetches → polling tracks → backend remains authoritative.**

---

# 72. Check Your Understanding

Before moving to **`16-EventBridge-SNS-and-Notifications.md`**, answer these three without looking above.

**Question 1:** Why can the invoice-detail API return `404` immediately after a successful S3 upload even though nothing is broken?

**Question 2:** Suppose status polling changes from:

```text
PROCESSING
↓
COMPLETED
```

but the page still shows the old detail error. **What is probably wrong, and how would you fix it?**

**Question 3:** User A views confidential invoice data, logs out, and User B logs in on the same browser. Why is:

```text
clear authentication state only
```

not enough, and what other frontend state should be cleared or isolated?