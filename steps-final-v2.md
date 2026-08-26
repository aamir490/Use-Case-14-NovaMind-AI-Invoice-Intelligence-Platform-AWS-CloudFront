# NovaMind Ai Invoice Intelligence Platform — My Deployment Guide

> Written for: **Aamir** | Machine: **Windows laptop** | Terminal: **Kiro PowerShell**
> Code is at: `E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL`

---

## IMPORTANT — Before You Start

You already have the code, Node.js, Python, AWS CLI, and credentials on your laptop.
You do NOT need to install anything or clone from GitHub.

---

## PART 1 — CHECK YOUR MACHINE IS READY

```powershell
node --version        # must show v20.x.x
python --version      # must show 3.12.x
aws --version         # must show aws-cli/2.x.x
aws sts get-caller-identity   # must show Account: 637423369471
```

---

## PART 2 — ENABLE BEDROCK MODEL ACCESS

Do this once in AWS Console. Skip if already done.

1. AWS Console → search **Bedrock** → open it
2. Left sidebar → **Model access** → **Manage model access**
3. Tick **Amazon Nova Micro** → **Save changes**
4. Wait for **Access granted**

**Skip this and AI analysis will fail silently.**

---

## PART 3 — GO TO YOUR PROJECT FOLDER

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"
```

Every command runs from this folder unless told otherwise.

---

## PART 4 — BUILD THE LAMBDA LAYER

Run this every time you deploy fresh. Paste the whole block at once:

```powershell
$root   = "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"
$srcPy  = "$root\backend\lambdas\shared"
$outDir = "$root\backend\lambdas\shared-layer-v2\python\shared"

New-Item -ItemType Directory -Path $outDir -Force | Out-Null
Copy-Item "$srcPy\*.py" $outDir -Force
pip install pydantic>=2.0.0 boto3>=1.34.0 -t "$root\backend\lambdas\shared-layer-v2\python" --quiet --upgrade
Write-Host "Layer built successfully."
```

Verify:
```powershell
Test-Path "backend\lambdas\shared-layer-v2\python\shared\db.py"
Test-Path "backend\lambdas\shared-layer-v2\python\pydantic"
```
Both must say `True`. If not, re-run the block above.

---

## PART 5 — DEPLOY INFRASTRUCTURE

### 5a — Go into infrastructure folder

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure"
```

### 5b — Install CDK packages (first time only)

```powershell
npm ci
```

### 5c — Compile TypeScript

```powershell
npm run build
```

Must finish with no errors.

### 5d — Bootstrap CDK (one-time only — skip if already done)

```powershell
$ACCOUNT = aws sts get-caller-identity --query Account --output text
npx cdk bootstrap aws://$ACCOUNT/us-east-1
```

### 5e — Deploy Storage and Auth

```powershell
npx cdk deploy InvoiceStorage-dev InvoiceAuth-dev --context env=dev --require-approval never
```

Takes ~3 minutes. Verify:
```powershell
aws cloudformation describe-stacks --stack-name InvoiceStorage-dev --query "Stacks[0].StackStatus" --output text
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].StackStatus" --output text
```
Both must say `CREATE_COMPLETE`

### 5f — Deploy Processing and API

```powershell
npx cdk deploy InvoiceProcessing-dev InvoiceApi-dev --context env=dev --require-approval never
```

Takes ~5 minutes. Verify:
```powershell
aws cloudformation describe-stacks --stack-name InvoiceProcessing-dev --query "Stacks[0].StackStatus" --output text
aws cloudformation describe-stacks --stack-name InvoiceApi-dev --query "Stacks[0].StackStatus" --output text
```
Both must say `CREATE_COMPLETE`

---

## PART 6 — ATTACH THE LAMBDA LAYER

### 6a — Go back to project root

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"
```

### 6b — Attach layer to API Lambdas

```powershell
powershell -ExecutionPolicy Bypass -File fix-layer.ps1
```

Last line must show `"statusCode": 201`
If it shows `No module named 'shared'` → redo Part 4 then run this again.

### 6c — Attach layer to Processing Lambdas

```powershell
powershell -ExecutionPolicy Bypass -File fix-processing-layer.ps1
```

Must end with `All processing Lambdas updated.`

---

## PART 7 — SET UP THE FRONTEND

### 7a — Get your fresh values from AWS

```powershell
# API URL (copy this — remove the trailing slash)
aws cloudformation describe-stacks --stack-name InvoiceApi-dev --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text

# Cognito User Pool ID
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text

# Cognito Client ID
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text
```

### 7b — Update frontend\.env.local

Open `frontend\.env.local` and set the values you just got.
**Remove the trailing slash from the URL — it must end in `/v1` not `/v1/`**

```
VITE_API_URL=https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com/v1
VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
VITE_COGNITO_USER_POOL_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
```

### 7c — Create a login user

```powershell
$POOL_ID = aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text

aws cognito-idp admin-create-user --user-pool-id $POOL_ID --username "demo@example.com" --temporary-password "Temp@1234!" --message-action SUPPRESS

aws cognito-idp admin-set-user-password --user-pool-id $POOL_ID --username "demo@example.com" --password "Invoice@Demo2026!" --permanent

Write-Host "User ready: demo@example.com / Invoice@Demo2026!"
```

If you get `UsernameExistsException` that is fine — already created.

---

## PART 8 — RUN THE APP LOCALLY

### 8a — Start the frontend

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\frontend"
npm run dev
```

Open browser: **http://localhost:5173**

### 8b — Log in

Email: `demo@example.com` | Password: `Invoice@Demo2026!`

### 8c — Upload an invoice

1. Click **Invoices** → **Upload Invoice**
2. Pick any file from the `invoices\` folder
3. Wait 15–30 seconds → invoice detail page loads with risk score and AI analysis

### 8d — Verify pipeline worked

```powershell
aws dynamodb scan --table-name invoices-dev --query "Count" --output text
```
Should show `1` or more.

---

## PART 9 — WATCH THE PIPELINE (Optional)

Open a second PowerShell terminal while uploading:

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"
powershell -ExecutionPolicy Bypass -File watch-pipeline.ps1
```

---

## PART 10 — DEPLOY TO CLOUDFRONT (Public URL)

After localhost works, follow `project-public.md` to go live on CloudFront.

Quick summary of the steps in that file:

1. `npm run build` in frontend/
2. `npx cdk deploy InvoiceFrontend-dev --context env=dev --require-approval never`
3. Get CloudFront URL from CloudFormation outputs
4. Redeploy API with the CloudFront URL:
   ```powershell
   npx cdk deploy InvoiceApi-dev --context env=dev --context frontendUrl=https://XXXX.cloudfront.net --require-approval never
   ```

---

## PART 11 — DESTROY EVERYTHING

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure"
npx cdk destroy --all --context env=dev --force
```

Verify gone:
```powershell
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query "StackSummaries[?contains(StackName,'Invoice')].StackName" --output table
```
Should return empty.

---

## TROUBLESHOOTING

| Problem | Fix |
|---------|-----|
| "Network Error" on upload | Trailing slash in `.env.local` API URL — remove it, restart `npm run dev` |
| Frontend on port 5175 instead of 5173 | Kill whatever is on 5173: `netstat -ano \| findstr :5173` then `taskkill /PID XXXX /F` |
| "502 Bad Gateway" | Layer not attached — redo Part 4 then Part 6 |
| Invoice stuck on "Processing" | Bedrock not enabled — do Part 2 |
| "UserAlreadyAuthenticatedException" | Already logged in — refresh the page |
| "Amplify not configured" | Check `frontend\.env.local` has all 3 values |
| `npx cdk` fails | Must be in `infrastructure\` folder |
| `No module named 'shared'` | Redo Part 4 then Part 6 in order |

---

## QUICK REFERENCE

| What | Value |
|------|-------|
| Project folder | `E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL` |
| AWS Region | `us-east-1` |
| AWS Account | `637423369471` |
| CDK flag | `--context env=dev` |
| Local URL | `http://localhost:5173` |
| Test login | `demo@example.com` / `Invoice@Demo2026!` |
| DynamoDB table | `invoices-dev` |
| Pipeline logs | `/aws/states/invoice-pipeline-dev` |

> **Note:** API URL, Cognito Pool ID, and CloudFront URL change every time you destroy and redeploy.
> Always get fresh values from CloudFormation outputs (Part 7a) after each deploy.
