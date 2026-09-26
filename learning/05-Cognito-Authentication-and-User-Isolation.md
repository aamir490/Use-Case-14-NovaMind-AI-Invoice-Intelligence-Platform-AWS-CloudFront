# Your question

**Start `05-Cognito-Authentication-and-User-Isolation.md`.**

This is our first **security-focused** learning file.

The most important idea is:

> **Cognito proves who the user is. It does not automatically prove that the user owns every invoice or job they request.**

That difference between **authentication** and **authorization** is central to this project.

---

# 05 — Cognito Authentication and User Isolation

## 1. What Will I Learn?

In this file, I will understand:

- What authentication means
- What authorization means
- Why they are different
- What Amazon Cognito does
- How the React frontend uses AWS Amplify
- What happens during login
- What an ID token is at project level
- How the token reaches API Gateway
- What the Cognito authorizer does
- How the backend gets the user's `sub`
- Why this project uses that `sub` as `tenant_id`
- How invoice ownership is scoped
- Why frontend protected routes are not real backend security
- The current job-status authorization gap
- The current browser-cache isolation gap
- What I would improve for production
- How to explain all of this in an interview

Codex confirms that the project uses **Cognito with Amplify and an API Gateway Cognito authorizer**. It also classifies authorization as only partial because job-status and browser-cache isolation have gaps. :chatgpt-content-reference{index="0"}

---

# 2. First Understand Two Words

Before learning Cognito, understand:

## Authentication

Authentication asks:

> **Who are you?**

Example:

```text
User enters credentials
        ↓
System verifies them
        ↓
"This is User A"
```

## Authorization

Authorization asks:

> **What are you allowed to access?**

Example:

```text
Authenticated User A
        ↓
Requests Invoice A
        ↓
Does Invoice A belong to User A?
        ↓
YES → Allow
NO  → Deny
```

Therefore:

```text
Authentication
      ≠
Authorization
```

You need **both**.

---

# 3. Simple Real-World Example

Imagine a hotel.

Your identity card proves:

> “I am Aamir.”

That's similar to **authentication**.

But it doesn't mean:

> “I am allowed to enter every hotel room.”

Your room key determines what you're allowed to access.

That's closer to **authorization**.

Similarly:

```text
Cognito verifies:
"Who is this user?"

Application authorization verifies:
"Does this user own this invoice?"
```

---

# 4. Authentication Flow in This Project

Codex traced the actual login flow as:

```text
Login Form
    ↓
AWS Amplify
    ↓
Amazon Cognito
    ↓
ID Token / Session
    ↓
Frontend
    ↓
API Request
    ↓
Authorization Header
    ↓
API Gateway
    ↓
Cognito Authorizer
    ↓
Validated Claims
    ↓
claims.sub
    ↓
tenant_id
```

This is directly supported by the local project analysis. :chatgpt-content-reference{index="1"}

Now we'll understand each part.

---

# 5. Step 1 — User Opens the Login Page

The React frontend provides login, registration and confirmation functionality.

Conceptually:

```text
React Login Form

Email:    __________
Password: __________

        [ Login ]
```

The frontend uses **AWS Amplify** to interact with Cognito.

Important distinction:

```text
React
=
User interface


Amplify
=
Frontend library/integration


Cognito
=
AWS identity service
```

Don't say:

> “Amplify authenticates the user instead of Cognito.”

For this project, Amplify is the frontend integration; Cognito is the authentication service.

---

# 6. Step 2 — Amplify Communicates With Cognito

The flow becomes:

```text
User
 ↓
React Login Form
 ↓
AWS Amplify
 ↓
Amazon Cognito
```

Codex found that Amplify is configured before the application renders and is used for login, registration and confirmation interactions. :chatgpt-content-reference{index="2"}

---

# 7. Step 3 — Cognito Authenticates the User

Amazon Cognito verifies the user's identity.

At a simplified level:

```text
Credentials
     ↓
Cognito
     ↓
Valid?
 ┌───┴───┐
YES      NO
 ↓        ↓
Session  Reject
```

The repository also configures password complexity and email confirmation as authentication controls. :chatgpt-content-reference{index="3"}

---

# 8. Step 4 — Frontend Gets the Session

After successful authentication, the frontend obtains the current user/session information.

Codex traced:

```text
Cognito
   ↓
Session
   ↓
Frontend
   ↓
Zustand
```

The frontend uses **Zustand** to maintain user information for UI rendering. :chatgpt-content-reference{index="4"}

At this point, the UI knows there is an authenticated user.

---

# 9. What Is an ID Token?

You don't need deep JWT cryptography yet.

For this project, think of an ID token as a signed identity document containing claims about the authenticated user.

Conceptually:

```text
ID TOKEN

{
   "sub": "user-unique-id",
   "email": "...",
   ...
}
```

The most important claim for this project is:

```text
sub
```

---

# 10. What Is `sub`?

`sub` means **subject**.

It uniquely identifies the Cognito user.

Conceptually:

```text
User A

sub:
abc-123
```

and:

```text
User B

sub:
xyz-789
```

So:

```text
User A
≠
User B
```

even if both use the same application.

---

# 11. Step 5 — Frontend Calls the API

Suppose the authenticated user wants an upload URL.

The frontend calls:

```text
POST /invoices/upload-url
```

But it doesn't simply send:

```text
"Trust me. I'm Aamir."
```

The API interceptor obtains the Cognito ID token and adds it to the request's authorization header.

Codex explicitly traced this behavior. :chatgpt-content-reference{index="5"}

Simplified:

```text
React
 ↓
Get ID token
 ↓
Authorization Header
 ↓
API Gateway
```

---

# 12. Why Should the Backend Not Trust a User ID From the Browser?

Imagine the frontend sent:

```json
{
  "user_id": "user-a"
}
```

A malicious user could potentially change it to:

```json
{
  "user_id": "user-b"
}
```

Therefore, security-sensitive identity should not simply be trusted because the browser supplied it.

Your project instead derives identity from **validated authorizer claims**.

Codex identifies this as an implemented security control. :chatgpt-content-reference{index="6"}

---

# 13. Step 6 — API Gateway Cognito Authorizer

Before protected application APIs are allowed through, API Gateway uses the Cognito authorizer.

Conceptually:

```text
API Request
     ↓
Cognito Authorizer
     ↓
Is authentication valid?
   ┌─┴─┐
  YES  NO
   ↓    ↓
Allow Reject
```

The authorizer establishes the validated identity information available to the backend.

Codex confirms that a Cognito authorizer is attached to application API methods. :chatgpt-content-reference{index="7"}

---

# 14. Step 7 — Backend Gets `claims.sub`

After authorization at API Gateway, backend code extracts:

```text
claims.sub
```

Codex labels the shared backend helper responsible for this as `B10`.

It converts the validated user subject into the application's:

```text
tenant_id
```

So conceptually:

```text
Cognito

sub = abc-123
      ↓
Backend
      ↓
tenant_id = abc-123
```

:chatgpt-content-reference{index="8"}

---

# 15. What Does `tenant_id` Mean Here?

This needs careful explanation.

In many enterprise systems, a tenant might mean:

```text
Company A
Company B
Company C
```

But that is **not what this repository currently implements**.

Codex specifically says:

> The current tenant is effectively an **individual Cognito user**, not an organization-level tenant. :chatgpt-content-reference{index="9"}

So conceptually:

```text
Cognito User A
      ↓
tenant_id = A


Cognito User B
      ↓
tenant_id = B
```

Don't tell an interviewer:

> “I implemented full organization-level multi-tenancy.”

That isn't supported by the current repository.

---

# 16. User Isolation

Now suppose:

```text
User A
owns
Invoice A
```

and:

```text
User B
owns
Invoice B
```

The desired behavior is:

```text
User A
 ↓
Invoice A
 ↓
ALLOW
```

but:

```text
User A
 ↓
Invoice B
 ↓
DENY
```

This is **resource-level authorization / isolation**.

---

# 17. Tenant-Prefixed Upload Keys

The project creates generated upload keys that contain tenant/user context.

Conceptually:

```text
invoices/
   └── tenant-A/
          └── invoice-001.pdf
```

versus:

```text
invoices/
   └── tenant-B/
          └── invoice-002.pdf
```

The exact key format should always follow the repository, but the important verified fact is:

> **Generated upload keys are tenant-prefixed.**

Codex identifies this as an implemented security control. :chatgpt-content-reference{index="10"}

---

# 18. Presigned URL Security

The backend generates a temporary presigned upload URL.

Codex found that the URL lasts approximately:

```text
5 minutes
```

:chatgpt-content-reference{index="11"}

So:

```text
Authenticated User
       ↓
Backend determines tenant
       ↓
Creates controlled S3 key
       ↓
Creates temporary URL
       ↓
Browser uploads
```

This is much better than making the invoice bucket public.

The S3 buckets themselves are private. :chatgpt-content-reference{index="12"}

---

# 19. Frontend Protected Route vs Backend Security

This is an excellent interview concept.

The React application can have something like:

```text
if authenticated:
    show dashboard
else:
    show login
```

That is useful for the UI.

But it is **not sufficient security**.

Why?

Because an attacker doesn't have to use your React interface.

They can try calling:

```text
API Gateway
```

directly.

Therefore:

```text
Frontend Route Guard
=
UI/navigation control
```

while:

```text
API Gateway Authorizer
+
Backend ownership checks
=
actual backend protection
```

Codex explicitly says the frontend route guard is a UI control; backend protection comes from API Gateway and application ownership checks. :chatgpt-content-reference{index="13"}

---

# 20. A Valid Token Is Not Enough

This is probably the most important security lesson in File 05.

Suppose:

```text
User A
```

has a perfectly valid Cognito token.

Does that mean User A should be able to request:

```text
/invoices/USER_B_INVOICE
```

?

No.

The token proves:

> **This really is User A.**

It does **not** prove:

> **User A owns User B's invoice.**

Therefore the backend still needs:

```text
Authenticated identity
        +
Requested resource
        +
Ownership check
```

---

# 21. Current Authorization Pattern

For invoice operations, the application uses user/tenant-scoped keys and queries.

Conceptually:

```text
claims.sub
    ↓
tenant_id
    ↓
Query invoice belonging to tenant
```

So:

```text
User A
 ↓
tenant_id=A
 ↓
A's invoice records
```

Codex describes user-scoped invoice keys as implemented authorization behavior. :chatgpt-content-reference{index="14"}

But there is an important exception.

---

# 22. Security Gap #1 — Job Status Ownership

This is a **real project-specific finding**.

Codex found that the job-status logic first performs a tenant-scoped invoice lookup, but its fallback retrieves:

```text
job_<invoice_id>
```

without comparing the stored job's `tenant_id` with the requester. :chatgpt-content-reference{index="15"}

In simplified terms:

```text
User A requests status
        ↓
Check invoice belonging to A
        ↓
Invoice not available yet?
        ↓
Lookup job_<invoice_id>
        ↓
⚠ Missing tenant comparison
```

This creates a potential information-disclosure problem.

---

# 23. Why Is That Dangerous?

Imagine:

```text
User A
```

somehow knows:

```text
User B's invoice ID
```

If the fallback retrieves the job only using:

```text
job_<invoice_id>
```

without checking:

```text
job.tenant_id == authenticated_user
```

then User A could potentially receive information such as:

```text
Processing status
Processing stage
Error details
```

belonging to another user's job.

Codex specifically identifies this as a high-priority security gap. :chatgpt-content-reference{index="16"}

---

# 24. How Should It Be Fixed?

Conceptually, authorization needs to be applied consistently.

For example:

```text
Authenticated tenant
        ↓
Retrieve requested job
        ↓
Compare job.tenant_id
        ↓
Does it match?
   ┌────┴────┐
  YES        NO
   ↓          ↓
Return       Deny
```

Even better, data-access design can make cross-tenant access difficult by construction.

The key lesson:

> **Never assume knowing a resource ID proves ownership.**

---

# 25. Security Gap #2 — Browser Cache Isolation

Security problems aren't limited to AWS backend services.

Codex found a frontend isolation problem involving the query cache.

The frontend uses query keys that don't include the current user identity. Logout clears authentication display state but does **not** clear all private query/upload/filter state. :chatgpt-content-reference{index="17"}

Let's understand why that matters.

---

# 26. Example of Browser Cache Problem

Suppose:

```text
User A logs in
      ↓
Loads invoices
      ↓
Browser caches User A's data
```

Then:

```text
User A logs out
```

and:

```text
User B logs in
```

If the old private cache survives:

```text
Browser cache
      ↓
User A invoice data
      ↓
User B session
```

User B could temporarily receive stale information from User A's session.

That is a security/privacy problem even if the backend APIs themselves are correctly scoped.

---

# 27. Why Doesn't Correct Backend Authorization Automatically Fix It?

Because the data may already exist in the browser.

Consider:

```text
Backend
 ↓
Correctly returns User A data
 ↓
Browser caches it
```

Later:

```text
User A logs out
 ↓
Cache remains
 ↓
User B logs in
 ↓
UI reads old cache
```

The backend didn't necessarily leak anything during User B's request.

The browser already had the data.

Codex's interview material explicitly emphasizes this distinction. :chatgpt-content-reference{index="18"}

---

# 28. How Should Browser Isolation Be Improved?

Two useful concepts are:

### Clear private state on logout

Conceptually:

```text
Logout
 ↓
Clear Cognito session
 ↓
Clear user state
 ↓
Clear React Query private cache
 ↓
Clear upload/filter/private state
```

### Namespace queries by user

Instead of:

```text
["invoices"]
```

conceptually use something like:

```text
["invoices", userId]
```

Then:

```text
User A cache
≠
User B cache
```

The exact implementation belongs to later improvement work, but this is the design principle.

---

# 29. How Would We Test the Fix?

This is an excellent interview answer.

```text
1. Login as User A
2. Load User A invoices
3. Logout
4. Login as User B
5. Verify User A data NEVER appears
6. Verify User B receives only User B data
```

Codex explicitly proposes this type of test for proving the browser-cache isolation fix. :chatgpt-content-reference{index="19"}

---

# 30. Authentication Security Already Implemented

The Codex report identifies several implemented controls relevant to this area:

```text
✓ Cognito authorizer on application APIs

✓ Identity from validated authorizer claims

✓ Tenant-prefixed upload keys

✓ Short-lived presigned URLs

✓ Private S3 buckets

✓ Password complexity

✓ Email confirmation

✓ Per-function IAM roles/resource grants
```

:chatgpt-content-reference{index="20"}

So this isn't:

> “The project has no security.”

Instead:

> **The project implements several good controls, but user isolation is incomplete.**

That is the accurate explanation.

---

# 31. What Authentication Features Are Missing?

According to Codex, current gaps include:

```text
No MFA configuration

No organization membership model

No role hierarchy

No completed password-reset UI
```

:chatgpt-content-reference{index="21"}

Don't turn all of these into mandatory requirements automatically.

Whether you need them depends on production requirements.

For financial-document processing, however, some could become important.

---

# 32. Authentication vs Authorization vs IAM

Don't confuse three different security concepts.

## Cognito Authentication

```text
Who is the application user?
```

Example:

```text
Aamir
```

## Application Authorization

```text
Which invoice can this user access?
```

Example:

```text
Aamir → Aamir's invoices
```

## IAM Authorization

```text
Which AWS service actions can this Lambda perform?
```

Example:

```text
Processing Lambda
 ↓
Can call Textract
```

So:

```text
Cognito
=
human/application user identity


Application authorization
=
user → business resource access


IAM
=
AWS principal → AWS resource/action access
```

This distinction is extremely useful in AWS interviews.

---

# 33. User Isolation vs Multi-Tenancy

Another important distinction.

Your application has user-scoped data.

But Codex warns against describing this as complete enterprise multi-tenancy.

Current conceptual model:

```text
Cognito User
      ↓
tenant_id
      ↓
User's invoices
```

A more advanced organization-level system could look like:

```text
Organization
   ├── Admin
   ├── Finance Manager
   ├── Reviewer
   └── Auditor
```

with:

```text
organization_id
role
permissions
```

The current project does not implement that complete model. :chatgpt-content-reference{index="22"}

---

# 34. Production V2 Authentication Model

If this became an enterprise finance platform, one possible future design could introduce:

```text
Organization
      ↓
Users
      ↓
Roles
      ↓
Permissions
      ↓
Invoices
```

For example:

```text
Company A

Admin
 ├── Manage users
 ├── View invoices
 └── Configure settings

Reviewer
 ├── View invoices
 └── Review findings

Auditor
 └── Read-only access
```

But this is:

> **Production improvement / future design**

not:

> **Current implementation.**

---

# 35. Security Boundary Mental Model

Remember this:

```text
                 USER
                   │
                   ▼
            React Frontend
                   │
             UI route guard
                   │
             NOT ENOUGH
                   ▼
             ID Token
                   │
                   ▼
             API Gateway
                   │
          Cognito Authorizer
                   │
                   ▼
          Validated claims.sub
                   │
                   ▼
             tenant_id
                   │
                   ▼
        Resource ownership check
                   │
             ┌─────┴─────┐
             │           │
           MATCH       NO MATCH
             │           │
           ALLOW        DENY
```

That's the security flow you should understand.

---

# 36. The One Sentence to Remember

> **Cognito authenticates the user, API Gateway validates the token, and the backend uses the validated Cognito `sub` as the application's `tenant_id` to scope invoice access; however, the current implementation still has gaps in job-status ownership and browser-cache isolation.**

That is a very strong project-specific understanding.

---

# 37. Interview Preparation — 10 Questions

## Q1 — How does authentication work in your project?

**Difficulty:** Basic

### Word-by-word practice answer

> “The React frontend uses AWS Amplify to integrate with Amazon Cognito for user registration and login. After authentication, the frontend obtains the user's session and ID token. When it calls protected APIs, an interceptor adds the ID token to the Authorization header. API Gateway uses a Cognito authorizer to validate the identity, and the backend extracts the validated `sub` claim and uses it as the application's `tenant_id`.”

This follows the actual login flow traced by Codex. :chatgpt-content-reference{index="23"}

---

# Q2 — What is the difference between authentication and authorization?

**Difficulty:** Basic

### Word-by-word practice answer

> “Authentication verifies who the user is, while authorization determines what that authenticated user is allowed to access. In my project, Cognito and the API Gateway authorizer establish the user's identity. The backend then uses the user's subject claim to scope invoice operations. A valid token alone does not mean the user owns every requested invoice.”

This closely follows Codex's existing interview answer. :chatgpt-content-reference{index="24"}

---

# Q3 — Why don't you send `user_id` from the frontend and trust it?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “I should not trust a user identifier supplied by the browser for authorization because client-side values can be manipulated. Instead, the backend derives the user's identity from the claims that were validated by the Cognito authorizer. In this project, the validated `sub` claim becomes the tenant identifier used to scope application operations.”

---

# Q4 — What is `sub` and how do you use it?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The `sub` is the Cognito subject claim that uniquely identifies an authenticated user. After API Gateway validates the request, the backend extracts that claim and treats it as the current `tenant_id`. Invoice operations can then be scoped using that identity instead of trusting an arbitrary user identifier from the request.”

---

# Q5 — Is a protected React route enough to secure your API?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “No. A protected React route only controls what the user can navigate to in the browser interface. A caller could bypass the frontend and call the API directly. Real backend protection comes from the API Gateway Cognito authorizer together with application-level resource ownership checks.”

Codex explicitly identifies the frontend route guard as a UI control rather than backend protection. :chatgpt-content-reference{index="25"}

---

# Q6 — How do you isolate invoices between users?

**Difficulty:** Intermediate

### Word-by-word practice answer

> “The application derives the current tenant from the authenticated user's Cognito `sub`. Generated upload keys are tenant-prefixed, and invoice operations use user-scoped data access. However, I would describe the isolation as partial rather than perfect because the Codex review identified a job-status ownership gap and a separate browser-cache isolation issue.”

---

# Q7 — What security problem exists in the job-status endpoint?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The status logic first performs a tenant-scoped invoice lookup, but its job fallback retrieves the job using the invoice ID without comparing the stored job tenant with the authenticated requester. If someone knows another invoice ID, that can potentially expose processing status, stage or error information. I would fix this by enforcing the authenticated tenant on every resource-access path, including the job fallback.”

This is a direct project-specific finding. :chatgpt-content-reference{index="26"}

---

# Q8 — What is the frontend cache security issue?

**Difficulty:** Advanced

### Word-by-word practice answer

> “The query client survives logout and its query keys do not include the current user identity. Logout clears authentication display state, but cached invoice and analytics information can remain. If another user signs in during the same application session, stale data from the previous user could be rendered. I would clear private application state on logout and namespace user-specific query keys by identity.”

This closely follows the Codex interview bank. :chatgpt-content-reference{index="27"}

---

# Q9 — Do you consider this a fully multi-tenant application?

**Difficulty:** Advanced / Pressure

### Word-by-word practice answer

> “I would not describe the current implementation as complete enterprise multi-tenancy. The current tenant identifier effectively represents an individual Cognito user, and invoice data is scoped around that identity. There is no organization membership model or role hierarchy, and the current implementation also has isolation gaps that I would fix before making stronger multi-tenancy claims.”

---

# Q10 — How would you improve authentication and authorization for production?

**Difficulty:** Advanced / Design

### Word-by-word practice answer

> “First, I would close the existing authorization gaps by enforcing ownership checks consistently for every invoice and job access path and by clearing or namespacing private frontend cache state between users. Then I would evaluate production requirements such as MFA, password recovery, rate limiting, organization-level tenancy and role-based permissions. I would also add automated security tests that attempt cross-user resource access, because authentication alone does not prove authorization.”

---

# 38. Interview Pressure Chain

An interviewer might start with:

> **“How do users log in?”**

Then immediately continue:

```text
Why Cognito?
      ↓
What token do you use?
      ↓
What is sub?
      ↓
Where do you validate it?
      ↓
What does API Gateway authorizer do?
      ↓
Authentication vs authorization?
      ↓
How do you know an invoice belongs to the user?
      ↓
Can User A access User B's invoice?
      ↓
What about job status?
      ↓
You have an authorization bug then?
      ↓
How would you fix it?
      ↓
What happens when User A logs out
and User B logs in?
      ↓
What about React Query cache?
      ↓
How would you test your fix?
```

This is why simply memorizing:

> “We use Cognito for authentication.”

is nowhere near enough.

---

# 39. What You Must Remember

The entire file can be reduced to this:

```text
LOGIN
 ↓
Amplify
 ↓
Cognito
 ↓
ID Token
 ↓
Authorization Header
 ↓
API Gateway
 ↓
Cognito Authorizer
 ↓
Validated sub
 ↓
tenant_id
 ↓
Ownership Check
 ↓
User's Invoice
```

And remember the two current weaknesses:

```text
⚠ Job-status ownership gap

⚠ Browser-cache isolation gap
```

Codex therefore classifies the project's authorization/user isolation as **partial**, not complete. :chatgpt-content-reference{index="28"}

---

# 40. Check Your Understanding

Before `06-Presigned-S3-Upload-and-Ingestion.md`, answer these three in your **own simple words**:

**Question 1:** What is the difference between **authentication and authorization** in this project?

**Question 2:** Why does the backend use Cognito's validated **`sub`** instead of trusting a `user_id` sent by React?

**Question 3:** User A logs in, views invoices, logs out, and then User B logs in on the same browser. **What security problem did Codex find, and how would you fix it?**