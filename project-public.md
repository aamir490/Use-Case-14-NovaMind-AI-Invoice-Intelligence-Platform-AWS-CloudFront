# NovaMind Ai Invoice Intelligence Platform
## CloudFront Public Deployment Guide

> **Aamir** | [GitHub](https://github.com/aamir490) | [LinkedIn](https://www.linkedin.com/in/aamir-imran)

---

## READ THIS FIRST

**Use this file ONLY after completing `steps-final-v2.md` Parts 1–9 (localhost working).**

Order is:
```
1. steps-final-v2.md  Parts 1–9   → localhost working
2. This file          Steps 1–4   → CloudFront live
```

---

## STEP 1 — Build the Frontend

```powershell
# crtl + c

> invoice-intelligence-frontend@1.0.0 dev
> vite


  VITE v5.4.21  ready in 1586 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
Terminate batch job (Y/N)? 
```


```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\frontend"

# Yes. If you are currently inside the frontend folder, run:
npm run build
# This will create a production build of your frontend and check for build-time errors.
```

- Must finish with `✓ built in XX.XXs` — no errors.

---

## STEP 2 — Deploy Frontend Stack

```powershell
# Yes 👍 This is the frontend AWS deployment step.
# Before deploying, make sure you are in the infrastructure folder:

cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure"

npx cdk deploy InvoiceFrontend-dev --context env=dev --require-approval never

# It deploys the InvoiceFrontend-dev CDK stack

### output :- 
# ✅  InvoiceFrontend-dev

# ✨  Deployment time: 261.13s

# Outputs:
# InvoiceFrontend-dev.ApiSharedLayerArn = arn:aws:lambda:us-east-1:637423369471:layer:invoice-api-shared-dev:15
# InvoiceFrontend-dev.ApiUrlPassthrough = https://6q3r3zl8dg.execute-api.us-east-1.amazonaws.com/v1/
# InvoiceFrontend-dev.CloudFrontUrl = https://d1wa89k92b34ma.cloudfront.net
# InvoiceFrontend-dev.DistributionId = E1DB5MJQJ6C3MU
# InvoiceFrontend-dev.FrontendBucketName = invoice-frontend-hosting-dev-637423369471
# Stack ARN:
# arn:aws:cloudformation:us-east-1:637423369471:stack/InvoiceFrontend-dev/7be778e0-b022-11f1-83cf-12bf9b0f9551

# ✨  Total time: 1317.18s
```

Takes ~5 minutes.

---

## STEP 3 — Get Your CloudFront URL

```powershell
## Open a second PowerShell terminal and check the CloudFormation stack:
aws cloudformation describe-stacks --stack-name InvoiceFrontend-dev --region us-east-1 --query "Stacks[0].[StackName,StackStatus]" --output table
                                                                                                                               
# |    DescribeStacks     |
# +-----------------------+
# |  InvoiceFrontend-dev  |
# |  CREATE_IN_PROGRESS   |
# +-----------------------+

# |  InvoiceFrontend-dev  |
# |  CREATE_COMPLETE      |
# +-----------------------+


# First get your actual CloudFront URL
# 👍 STEP 3 is a read-only command to get your deployed frontend's CloudFront URL.

aws cloudformation describe-stacks --stack-name InvoiceFrontend-dev --query "Stacks[0].Outputs[?OutputKey=='CloudFrontUrl'].OutputValue" --output text

# output :- You should get something similar to:  https://dxxxxxxxxxxxx.cloudfront.net -> https://d1wa89k92b34ma.cloudfront.net  

```

- Copy the URL — looks like `https://XXXXXXXXXXXX.cloudfront.net`  https://d1wa89k92b34ma.cloudfront.net  

---

## STEP 4 — Add CloudFront URL to CORS and Redeploy API

- Yes. Step 4 updates the API's CORS configuration so your CloudFront frontend is allowed to call the API.

- Replace `https://XXXXXXXXXXXX.cloudfront.net` with your real URL from Step 3:

```powershell

## 2. Deploy the API with that URL
npx cdk deploy InvoiceApi-dev `
    --context env=dev `
    --context frontendUrl=https://XXXXXXXXXXXX.cloudfront.net `
    --require-approval never
```
# like this :- 
```powershell
# Yes ✅ That is the correct PowerShell command for updating the API CORS with your CloudFront URL.

npx cdk deploy InvoiceApi-dev `
    --context env=dev `
    --context frontendUrl=https://d1wa89k92b34ma.cloudfront.net `
    --require-approval never
```

- Takes ~3 minutes.

```powershell
# Check current deployment status in another terminal
aws cloudformation describe-stacks --stack-name InvoiceApi-dev --region us-east-1 --query "Stacks[0].[StackName,StackStatus]" --output table

# |  DescribeStacks   |
# +-------------------+
# |  InvoiceApi-dev   |
# |  UPDATE_COMPLETE  |
# +-------------------+
```
---

## STEP 5 — Verify It Works

- Open your CloudFront URL in an incognito browser window.

- https://d1wa89k92b34ma.cloudfront.net  

- Log in with `demo@example.com` / `Invoice@Demo2026!`
- Upload an invoice from the `invoices\` folder
- Should process in 15–30 seconds with risk score and AI analysis

If you see CORS error — wait 2 minutes for CloudFront cache to clear, then retry.

---

## STEP 6 — Invalidate CloudFront Cache (if old version shows)

```powershell
$DIST_ID = aws cloudformation describe-stacks --stack-name InvoiceFrontend-dev `
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" --output text

aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
Write-Host "Cache cleared. Wait ~1 minute then refresh."
```

---

## OPTIONAL — Make CloudFront Global

Currently serves fast from US/Canada/Europe only. To serve globally:

Open `infrastructure\lib\frontend-stack.ts`, find:
```typescript
priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
```
Change to:
```typescript
priceClass: cloudfront.PriceClass.PRICE_CLASS_ALL,
```
Then redeploy:
```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure"
npm run build
npx cdk deploy InvoiceFrontend-dev --context env=dev --require-approval never
```

---

## OPTIONAL — Add a Custom Domain

Replace the CloudFront URL with your own domain like `novamind.yourdomain.com`.

### a — Request a free SSL certificate (must be in us-east-1)

```powershell
aws acm request-certificate `
    --domain-name "yourdomain.com" `
    --subject-alternative-names "*.yourdomain.com" `
    --validation-method DNS `
    --region us-east-1
```

Go to AWS Console → Certificate Manager → validate via DNS → wait for **Issued**.

### b — Add to CDK

Open `infrastructure\lib\frontend-stack.ts` and add to the distribution:

```typescript
import * as acm from 'aws-cdk-lib/aws-certificatemanager';

const certificate = acm.Certificate.fromCertificateArn(
  this, 'Cert', 'arn:aws:acm:us-east-1:637423369471:certificate/YOUR_ARN'
);

// In the Distribution config add:
domainNames: ['yourdomain.com'],
certificate: certificate,
```

### c — Add domain to CORS

Open `infrastructure\lib\api-stack.ts` and add it to the CDK context pass:

```powershell
npx cdk deploy InvoiceApi-dev `
    --context env=dev `
    --context frontendUrl=https://yourdomain.com `
    --require-approval never
```

---

## TROUBLESHOOTING

| Problem | Fix |
|---------|-----|
| CORS error on CloudFront | Run Step 4 with the correct CloudFront URL |
| Old version still showing | Run Step 6 (invalidate cache) |
| Upload fails on CloudFront but works on localhost | Step 4 not run yet — CloudFront URL not in CORS |
| Login works but API calls fail | Check the API URL in `.env.local` has no trailing slash, rebuild frontend, redeploy |

---

## Quick Reference

> **Note:** These values change every time you destroy and redeploy. Always get fresh values from CloudFormation.

```powershell
# Get all current values at once
aws cloudformation describe-stacks --stack-name InvoiceApi-dev --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text
aws cloudformation describe-stacks --stack-name InvoiceFrontend-dev --query "Stacks[0].Outputs[?OutputKey=='CloudFrontUrl'].OutputValue" --output text
```

| What | Value |
|------|-------|
| AWS Region | us-east-1 |
| AWS Account | 637423369471 |
| Test login | demo@example.com / Invoice@Demo2026! |
| DynamoDB table | invoices-dev |
| Pipeline logs | /aws/states/invoice-pipeline-dev |

---

> **Created by [Aamir](https://github.com/aamir490)**
> GitHub: https://github.com/aamir490
> LinkedIn: https://www.linkedin.com/in/aamir-imran
