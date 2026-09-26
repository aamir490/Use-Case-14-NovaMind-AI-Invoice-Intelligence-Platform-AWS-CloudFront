### Corrected question

**“For Project 1 — NovaMind AI Invoice Intelligence Platform, if an interviewer asks, ‘What were your roles and responsibilities in this project?’, how should I answer?”**

A more natural interview question would be:

> **“What were your roles and responsibilities on this project?”**

Or:

> **“What was your role in the NovaMind AI Invoice Intelligence Platform, and what were your key responsibilities?”**

Yes, this is an **important question we should prepare before completely closing Project 1**. Your answer should describe **your actual contribution**, not simply list every technology in the architecture.

We should prepare it in a structure like:

**My role → what I was responsible for → what I implemented/worked on → AWS/GenAI responsibilities → testing/troubleshooting/deployment → collaboration/ownership.**

But because this is a resume project, I don't want to invent your personal contribution. We already know what the **project contains**, but that's different from knowing exactly **what you personally did**.

So next, we should create your interview-ready answer to:

> **“What were your roles and responsibilities on this project?”**

and make sure every responsibility is something you can confidently defend with follow-up questions.

---

# Your question

**“For Project 1 — NovaMind AI Invoice Intelligence Platform, if an interviewer asks, ‘What were your roles and responsibilities on this project?’, how should I answer?”**

Use this as your **interview-practice answer**, but only keep responsibilities you can truthfully defend as your own work.

### Word-by-word answer

> **“My role in this project was mainly as an AWS Generative AI Engineer, with responsibility across the application architecture, Generative AI integration, AWS serverless services, deployment, and troubleshooting.**
>
> **I worked on the end-to-end invoice-processing workflow. On the frontend side, users authenticate through Amazon Cognito and upload invoice documents directly to Amazon S3 using presigned URLs. On the backend, I worked with API Gateway and Lambda for the APIs, and SQS for decoupling the upload process from asynchronous invoice processing.**
>
> **For workflow orchestration, I worked with AWS Step Functions to coordinate the major processing stages. Amazon Textract is used to extract structured invoice information and OCR text, and Amazon Bedrock with Nova Micro analyzes that extracted information for possible anomalies.**
>
> **I also worked with the deterministic Python risk-scoring logic. Instead of allowing the LLM to make the complete business decision, the application combines predefined business rules with AI findings to generate a heuristic risk score.**
>
> **For the data layer, I worked with Amazon S3 for document and extracted-text storage and DynamoDB for invoice results, job status, and application state.**
>
> **The AWS infrastructure is defined using CDK, with separate stacks for storage, authentication, processing, APIs, and the frontend. I also worked with the deployment and operational side of the project, including GitHub Actions workflow definitions, IAM permissions, CloudWatch logging, and troubleshooting the serverless processing flow.**
>
> **I also analyzed several areas that would need improvement before a production release, especially idempotency for duplicate SQS events, stronger resource-level authorization, stricter validation of LLM output, better failure-state handling, testing, observability, and complete data-lifecycle management.**
>
> **So overall, my responsibility was not only integrating the AI model. It was understanding and working across the complete AWS-based invoice-processing pipeline—from authenticated document upload through OCR, Generative AI analysis, deterministic scoring, persistence, deployment, and operational troubleshooting.”**

### A shorter version for an HR/L1 interview

Don't give the full answer unless they want technical detail. You can say:

> **“I worked as an AWS Generative AI Engineer on the NovaMind AI Invoice Intelligence Platform. My responsibilities included building and understanding the serverless invoice-processing workflow using Lambda, S3, SQS and Step Functions, integrating Textract for invoice extraction and Bedrock Nova Micro for AI-assisted analysis, implementing Python-based risk-scoring logic, working with DynamoDB for application state, and supporting infrastructure, deployment, security, monitoring and troubleshooting using AWS CDK, IAM, GitHub Actions and CloudWatch.”**

### Be ready for the next question

The interviewer can take **any sentence** from that answer and challenge you:

```text
"You said you worked with SQS. Why was SQS required?"

"You mentioned Step Functions. Why not one Lambda?"

"How did you integrate Textract?"

"What exactly did you send to Nova Micro?"

"Why didn't the LLM calculate the score?"

"How did you secure invoices between users?"

"What happens when SQS delivers a duplicate?"

"What happens if Bedrock fails?"

"What exactly did you define using CDK?"

"What production problem did you personally troubleshoot?"
```

That's actually why our detailed learning work matters. **Anything you claim as a responsibility becomes fair game for follow-up questions.**

One particularly important point: don't say **“I designed and implemented everything end-to-end”** unless that accurately reflects your work. A technically strong answer that accurately describes your contribution is safer than claiming ownership you can't defend.


---

# Your question

**“Can you create answers for all the follow-up questions an interviewer may ask after I explain my roles and responsibilities for the NovaMind AI Invoice Intelligence Platform?”**

Yes. These are important because once you mention **SQS, Step Functions, Textract, Bedrock, risk scoring, Cognito, CDK, security, deployment, and troubleshooting**, the interviewer can drill into any of them. Below are word-by-word practice answers grounded in the project we analyzed. 

## Roles & Responsibilities — Follow-up Interview Q&A

### Q1. “You said you worked with SQS. Why was SQS required?”

> **“I used Amazon SQS to decouple invoice upload from invoice processing. Once an invoice is uploaded to S3, the processing does not need to happen synchronously in the user's request. SQS acts as a buffer between the S3 event and the processing layer. This improves reliability because temporary downstream delays do not require the user to upload the invoice again. One important consideration is that SQS provides at-least-once delivery, so duplicate messages are possible. That means idempotency is an important production requirement.”**

**Pressure follow-up: Why not call the processing Lambda directly from S3?**

> **“Direct S3-to-Lambda invocation would be simpler, but SQS provides a buffering and decoupling layer. If processing slows down or experiences temporary failures, messages can remain in the queue instead of tightly coupling ingestion to processing. The trade-off is that I need to handle retries, duplicate delivery, queue backlog and DLQ behavior.”**

---

### Q2. “Why did you use Step Functions instead of one Lambda?”

> **“Invoice processing contains multiple stages: Textract extraction, Bedrock analysis, deterministic risk scoring and result storage. Putting everything into one Lambda would tightly couple those responsibilities and make failure handling and troubleshooting more difficult. Step Functions makes the workflow explicit and allows me to identify which processing stage failed. In the current repository, the Express workflow has four main processing stages.”**

**Pressure follow-up: Why Express Step Functions?**

> **“This workflow is an application-processing workflow where executions are relatively short-lived. Express Workflows are suitable for high-volume, short-duration event-processing use cases. I would still validate workload characteristics, execution semantics and cost before selecting it for a production workload.”**

---

### Q3. “How did you integrate Amazon Textract?”

> **“The processing workflow invokes the OCR Lambda, which uses Amazon Textract AnalyzeExpense. Textract processes the invoice and returns expense-document information. The application parses fields such as invoice number, vendor, dates, subtotal, tax, total and line items, and it also collects OCR text. That extracted information becomes the input for the later AI-analysis stage.”**

**Pressure follow-up: Does Textract understand fraud?**

> **“No. I use Textract primarily for document extraction. It converts information in the invoice into structured fields and text. Semantic anomaly analysis happens later through Bedrock, and deterministic Python rules calculate the numeric review score.”**

---

### Q4. “What exactly do you send to Nova Micro?”

> **“I don't send the original invoice image directly to Nova Micro in the current implementation. After Textract processing, I construct a prompt containing structured invoice fields, line-item information and raw OCR text. That text-based information is sent to Amazon Nova Micro through Bedrock.”**

**Pressure follow-up: What do you expect back?**

> **“The prompt asks the model for structured anomaly information, including anomaly type, severity, description and affected field, along with a summary and confidence information. The application then attempts to parse that response as JSON.”**

---

### Q5. “Why did you choose Nova Micro?”

> **“For this project, Nova Micro is used for text-based invoice analysis through Amazon Bedrock. It fits the current architecture because the model receives extracted text rather than the original document image. However, I would not claim that Nova Micro is objectively the best model for this use case because the project does not currently contain a comprehensive model-comparison evaluation. For production, I would benchmark candidate models using representative invoices for quality, latency and cost.”**

That's a stronger answer than inventing a benchmark.

---

### Q6. “How do you validate the LLM response?”

> **“The current implementation mainly focuses on recovering and parsing JSON. It first attempts direct JSON parsing, then handles Markdown code fences, and can extract the JSON-looking portion of the response. If parsing still fails, the application uses a fallback result. However, I identified an important limitation: successful JSON parsing does not guarantee that the schema or business values are valid. For Production V2, I would add strict Pydantic or JSON-schema validation followed by business-level validation.”**

**Pressure follow-up: Give me an example.**

> **“For example, a response containing confidence equal to 500 might be syntactically valid JSON but invalid according to the application's expected range. Schema and business validation should reject or normalize that response rather than trusting it simply because JSON parsing succeeded.”**

---

### Q7. “Why doesn't the LLM calculate the final risk score?”

> **“I wanted the final numeric scoring logic to remain deterministic and explainable. Bedrock contributes semantic anomaly findings, but Python rules assign predefined weights to deterministic checks and AI findings. This means the same validated inputs produce the same scoring calculation, and I can explain why points were added rather than allowing the language model to independently generate the final number.”**

**Pressure follow-up: So is the score an 80% fraud probability if it is 80?**

> **“No. The score is a heuristic review score from zero to one hundred. It has not been statistically calibrated as a probability of fraud. An 80 means the invoice accumulated enough weighted findings to fall into the HIGH category; it does not mean there is an 80 percent probability of fraud.”**

---

### Q8. “How exactly is the risk score calculated?”

> **“The deterministic rules add weighted points for different findings. For example, a math discrepancy adds 40 points. Missing invoice number, receipt date, total or vendor each add 8. A short numeric invoice number adds 10, and repeated normalized item descriptions add 15. AI findings also contribute based on severity: HIGH adds 15, MEDIUM adds 7, and LOW or unrecognized severity adds 3. The score is capped at 100. Zero to 29 is LOW, 30 to 69 is MEDIUM, and 70 to 100 is HIGH.”**

**Pressure follow-up: Is that scoring perfect?**

> **“No. It is heuristic. One limitation is potential double counting. For example, a deterministic rule could detect a total discrepancy and Bedrock could identify the same issue as an AI anomaly. Production V2 should normalize and deduplicate correlated findings before calculating the final score.”**

---

### Q9. “How did you implement authentication?”

> **“The React frontend uses AWS Amplify with Amazon Cognito. After authentication, the frontend retrieves the user's session and includes the token in the Authorization header for API requests. API Gateway uses a Cognito authorizer to validate the identity. The backend then derives the tenant identity from the validated Cognito sub claim rather than trusting a tenant ID supplied by the browser.”**

---

### Q10. “How did you secure one user's invoices from another user?”

> **“The application derives tenant identity from the authenticated Cognito claims, and invoice records use tenant_id as part of their DynamoDB access pattern. Upload keys are also generated with tenant-aware prefixes rather than allowing the browser to freely choose arbitrary storage keys. However, I identified a resource-authorization weakness in one job-status path where ownership validation should be stronger. For production, every resource lookup should independently verify that the authenticated tenant owns the requested resource.”**

This answer is particularly useful because it shows you understand both the security control **and its limitation**.

---

### Q11. “What's the difference between authentication and authorization here?”

> **“Authentication answers who the user is. Cognito handles that. Authorization answers whether that authenticated user is allowed to access a particular invoice or processing job. A valid Cognito token alone does not mean the user should be allowed to access every resource, so application-level ownership checks are still required.”**

---

### Q12. “Why use presigned URLs?”

> **“The backend generates a short-lived presigned PUT URL after authenticating the user. The browser then uploads the document directly to the private S3 bucket. This avoids routing the document binary through API Gateway and Lambda, while still keeping the bucket private and limiting upload permission to a temporary signed operation.”**

**Pressure follow-up: Does a presigned URL make S3 public?**

> **“No. The bucket remains private. The presigned URL grants temporary permission for a specific operation according to the permissions of the identity that generated it.”**

---

### Q13. “What happens when SQS sends the same message twice?”

> **“Because SQS provides at-least-once delivery, duplicate delivery is possible. In the current design, complete atomic idempotency is an area I would strengthen. In Production V2, I would derive a stable idempotency key and use a DynamoDB conditional write to atomically claim the event before starting expensive Textract and Bedrock processing. If the claim already exists, the duplicate consumer would stop.”**

---

### Q14. “Does your DLQ catch all processing failures?”

> **“No. This is an important boundary in the architecture. The SQS-trigger Lambda starts Step Functions asynchronously. If that handoff succeeds, the Lambda can successfully finish and the SQS message is considered processed. If Textract or Bedrock fails later inside Step Functions, that does not automatically send the original SQS message to the SQS DLQ. Therefore, downstream workflow failures need separate Step Functions error handling, persisted failure states, monitoring and potentially a replay mechanism.”**

---

### Q15. “What happens if Bedrock fails?”

> **“The implementation includes retry and fallback behavior for some handled Bedrock failures. In those cases, processing can continue with fallback AI information, deterministic scoring can still execute, and the result may be stored. One limitation I identified is that the overall job can therefore become COMPLETED even when AI analysis was degraded. In Production V2, I would separate processing status from analysis-quality status, for example COMPLETED with FULL analysis versus COMPLETED with DEGRADED analysis or MANUAL_REVIEW_REQUIRED.”**

---

### Q16. “Why DynamoDB?”

> **“The application needs structured state with access patterns centered around tenant and invoice identifiers. The invoice table uses tenant_id as the partition key and invoice_id as the sort key. DynamoDB fits the serverless architecture and provides managed, low-latency key-based access without operating database servers.”**

**Pressure follow-up: Why also S3?**

> **“They solve different problems. S3 stores object data such as the original invoice and processed text, while DynamoDB stores structured application state such as invoice metadata, job status, findings and risk information.”**

---

### Q17. “How does the frontend know when processing is finished?”

> **“Processing is asynchronous, so the frontend polls the backend for status approximately every three seconds. Polling stops when the job reaches a terminal state such as COMPLETED or FAILED. One issue I identified is that the detail query may have previously returned an error while processing was incomplete and is not always invalidated when status becomes COMPLETED. I would explicitly invalidate and refetch the detail query at completion.”**

---

### Q18. “What did you implement with AWS CDK?”

> **“The infrastructure is organized into five CDK stacks: StorageStack, AuthStack, ProcessingStack, ApiStack and FrontendStack. Together they define the major storage, authentication, processing, API and frontend infrastructure. CDK synthesizes those definitions into CloudFormation templates, and CloudFormation provisions the AWS resources.”**

**Pressure follow-up: Are those five microservices?**

> **“No. CDK stacks are infrastructure organization and deployment boundaries. They should not be confused with application microservices.”**

---

### Q19. “How did you implement CI/CD?”

> **“The repository contains GitHub Actions workflow definitions for backend deployment, frontend deployment and pull-request checks. The AWS authentication design uses GitHub OIDC rather than embedding long-lived AWS access keys. However, I distinguish between having workflow definitions in the repository and proving that every current deployment succeeds. I would verify the current GitHub Actions execution history before making that operational claim.”**

---

### Q20. “How did you monitor the application?”

> **“CloudWatch provides the main logging and monitoring foundation, and the infrastructure also includes X-Ray configuration. When troubleshooting, I trace the request using the last proven successful stage rather than checking services randomly. I verify the S3 upload, then SQS delivery, trigger Lambda, Step Functions execution, individual processing stage, persistence and finally API/frontend retrieval.”**

---

### Q21. “Suppose an invoice is uploaded but never appears in the dashboard. How do you troubleshoot it?”

> **“First, I verify that the object exists in S3. Then I check whether the upload event reached SQS and whether there is a queue backlog or DLQ message. Next, I inspect the trigger Lambda logs and confirm that a Step Functions execution started. If it did, I inspect the execution history to identify whether Textract, Bedrock, scoring or storage failed. If backend processing completed successfully, I verify the DynamoDB record, API response and finally the frontend polling and query-cache behavior. This lets me troubleshoot using the last proven stage.”**

---

### Q22. “How did you test the project?”

> **“The repository contains unit-test coverage—the analysis identified 44 test functions—but I would not claim that all 44 currently pass because they were not executed during that analysis, and an OCR test import defect was identified. For stronger production confidence, I would add or strengthen integration tests, AWS service integration tests, end-to-end tests, security tests, load tests and AI-quality evaluation.”**

---

### Q23. “How would you test the AI part?”

> **“I would create a representative labeled invoice dataset with expected extracted fields and expected anomaly outcomes. Then I would evaluate OCR extraction quality separately from Bedrock analysis quality. For the AI stage, I would measure schema-valid response rate, false positives, false negatives, precision and recall where appropriate, fallback rate, latency and cost. I would also use the dataset for prompt-regression testing when prompts or models change.”**

---

### Q24. “Is this a RAG project?”

> **“No. This project does not implement retrieval-augmented generation. There is no embedding pipeline, vector database, semantic retrieval or external knowledge base. Bedrock analyzes information extracted from the currently uploaded invoice.”**

---

### Q25. “Is this an Agentic AI project?”

> **“No. Step Functions executes a predefined processing workflow. The LLM does not autonomously decide which tools to invoke or determine the next processing step, so I would not describe this particular project as Agentic AI.”**

This distinction will become especially important when you later discuss your **actual LangGraph Multi-Agent project**.

---

### Q26. “What was the most important design decision?”

> **“One important design decision was separating AI reasoning from deterministic business scoring. Textract handles extraction, Bedrock contributes semantic findings, and Python applies explicit scoring rules. That makes the final numeric score more explainable and prevents the language model from being the sole decision maker.”**

---

### Q27. “What is the biggest technical limitation?”

> **“There isn't only one. The highest-priority areas I would address before production include complete resource-level authorization, atomic idempotency, stricter AI-output validation and clearer degraded-analysis handling. I would prioritize security and correctness before adding more features.”**

---

### Q28. “What would you improve in Production V2?”

> **“I would first strengthen resource-level authorization and user-session cache isolation. Then I would implement atomic idempotency for duplicate events, stronger server-side document validation, OCR confidence and financial normalization, strict AI schema validation and finding deduplication. I would also improve workflow recovery, data lifecycle management, frontend state handling, automated integration testing, deployment verification, observability, load testing and measured cost monitoring.”**

---

### Q29. “Is the project production-ready?”

> **“I describe it as a production-oriented prototype rather than fully production-ready. The main serverless processing path is implemented, but production readiness also requires stronger authorization, idempotency, validation, testing, observability, failure recovery, load testing and operational evidence.”**

---

### Q30. “What exactly was your responsibility?”

Use this after the interviewer has drilled into the project:

> **“My responsibility was across the AWS Generative AI application flow rather than only the model integration. I worked with the authenticated upload flow, serverless backend, asynchronous processing architecture, Textract extraction, Bedrock integration, deterministic risk-scoring logic, persistence and infrastructure/deployment components. I also worked on understanding and troubleshooting the end-to-end processing path and identifying production improvements around security, reliability, validation and observability.”**

---

## The interview pattern you should learn

Don't try to memorize these 30 answers word-for-word forever. Learn this pattern:

```text id="5c73fu"
Interviewer asks about a technology
              ↓
1. WHAT is it?
              ↓
2. WHERE is it in my project?
              ↓
3. WHY did we use it?
              ↓
4. HOW does it work?
              ↓
5. What can FAIL?
              ↓
6. What is the LIMITATION?
              ↓
7. How would I improve it
   for PRODUCTION?
```

For example:

```text id="5gv9t5"
              SQS
               │
      ┌────────┼────────┐
      ▼        ▼        ▼
     WHY      HOW     FAILURE
 Decouple   S3→SQS   Duplicate
 processing   →λ      delivery
      │        │        │
      └────────┼────────┘
               ▼
          LIMITATION
       At-least-once
               │
               ▼
        PRODUCTION V2
      Atomic idempotency
```

If you can answer using that thinking pattern, you won't panic when the interviewer phrases a question differently.

And **this completes the missing Roles & Responsibilities section for Project 1**. We should carry this lesson into both flagship projects: their learning roadmaps should contain a dedicated **“My Role, Responsibilities & Ownership Defense”** section from the beginning, rather than adding it at the end.