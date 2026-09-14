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
# $root   = "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"
# $srcPy  = "$root\backend\lambdas\shared"
# $outDir = "$root\backend\lambdas\shared-layer-v2\python\shared"

# New-Item -ItemType Directory -Path $outDir -Force | Out-Null
# Copy-Item "$srcPy\*.py" $outDir -Force
# pip install pydantic>=2.0.0 boto3>=1.34.0 -t "$root\backend\lambdas\shared-layer-v2\python" --quiet --upgrade
# Write-Host "Layer built successfully."

$root   = "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"
$srcPy  = "$root\backend\lambdas\shared"
$outDir = "$root\backend\lambdas\shared-layer-v2\python\shared"

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

Copy-Item "$srcPy\*.py" $outDir -Force

pip install "pydantic>=2.0.0" "boto3>=1.34.0" -t "$root\backend\lambdas\shared-layer-v2\python" --quiet --upgrade

Write-Host "Layer built successfully."
```

### Then verify:

```powershell
Test-Path $root

# output :- true
```


### Now verify the layer:

```powershell
Test-Path "$root\backend\lambdas\shared-layer-v2\python"
Get-ChildItem "$root\backend\lambdas\shared-layer-v2\python" | Select-Object Name
Get-ChildItem "$root\backend\lambdas\shared-layer-v2\python\shared" -Filter *.py

Test-Path "backend\lambdas\shared-layer-v2\python\shared\db.py"
Test-Path "backend\lambdas\shared-layer-v2\python\pydantic"
```
Both must say `True`. If not, re-run the block above.

---

## PART 5 — DEPLOY INFRASTRUCTURE

### 5a — Go into infrastructure folder

```powershell
## current project root location : E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL

Test-Path ".\infrastructure"
# output - If it exists, you should get::  True

# You can also inspect it:
Get-Item ".\infrastructure"

cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure"
```

### 5b — Install CDK packages (first time only)

```powershell
# If you are now inside the project's infrastructure folder, first verify that package.json exists:
Test-Path ".\package.json"
# output :- TRUE

# then run:
npm ci
```

### 5c — Compile TypeScript

```powershell
# Yes. If npm ci completed successfully and you're still inside the infrastructure folder, you can run:
npm run build


# What this does ?

# npm run build executes the build script defined in package.json. 
# For an AWS infrastructure project, this may compile TypeScript/CDK code or prepare deployment artifacts.

# Next, verify the build output
Get-ChildItem
```

Must finish with no errors.

### 5d — Bootstrap CDK (one-time only — skip if already done)

```powershell
# Yes. Since you're already in the infrastructure folder and the TypeScript build succeeded, you can run these two commands together, but I recommend verifying the AWS account first.

# 1. Get the current AWS account
$ACCOUNT = aws sts get-caller-identity --query Account --output text
$ACCOUNT
# You should get: 637423369471


# 2. Bootstrap CDK in us-east-1
# If the account is correct, run:
npx cdk bootstrap aws://$ACCOUNT/us-east-1

# mix
$ACCOUNT = aws sts get-caller-identity --query Account --output text
npx cdk bootstrap aws://$ACCOUNT/us-east-1
```

###  OUTPUT :- Yes — CDK bootstrap was successful. ✅
```powershell 

PS E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure> $ACCOUNT = aws sts get-caller-identity --query Account --output text
PS E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure> npx cdk bootstrap aws://$ACCOUNT/us-east-1
 ⏳  Bootstrapping environment aws://637423369471/us-east-1...
(node:12492) Warning: NodeVersionSupportWarning: The AWS SDK for JavaScript (v3)
versions published after the first week of January 2027
will require node >=22. You are running node v20.13.1.

To continue receiving updates to AWS services, bug fixes,
and security updates please upgrade to node >=22.

More information can be found at: https://a.co/c895JFp
(Use `node --trace-warnings ...` to show where the warning was created)
Trusted accounts for deployment: (none)
Trusted accounts for lookup: (none)
Using default execution policy of 'arn:aws:iam::aws:policy/AdministratorAccess'. Pass '--cloudformation-execution-policies' to customize.
CDKToolkit: creating CloudFormation changeset...
CDKToolkit |  0/12 | 9:28:32 am | REVIEW_IN_PROGRESS      | AWS::CloudFormation::Stack | CDKToolkit User Initiated
CDKToolkit |  0/12 | 9:28:40 am | CREATE_IN_PROGRESS      | AWS::CloudFormation::Stack | CDKToolkit User Initiated
CDKToolkit |  0/12 | 9:28:42 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | CloudFormationExecutionRole 
CDKToolkit |  0/12 | 9:28:42 am | CREATE_IN_PROGRESS      | AWS::ECR::Repository       | ContainerAssetsRepository 
CDKToolkit |  0/12 | 9:28:42 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | LookupRole 
CDKToolkit |  0/12 | 9:28:42 am | CREATE_IN_PROGRESS      | AWS::SSM::Parameter        | CdkBootstrapVersion 
CDKToolkit |  0/12 | 9:28:42 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | FilePublishingRole 
CDKToolkit |  0/12 | 9:28:42 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | ImagePublishingRole 
CDKToolkit |  0/12 | 9:28:42 am | IMPORT_IN_PROGRESS      | AWS::S3::Bucket            | StagingBucket Resource import started.
CDKToolkit |  0/12 | 9:28:43 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | FilePublishingRole Resource creation Initiated
CDKToolkit |  0/12 | 9:28:43 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | CloudFormationExecutionRole Resource creation Initiated
CDKToolkit |  0/12 | 9:28:43 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | LookupRole Resource creation Initiated
CDKToolkit |  0/12 | 9:28:43 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | ImagePublishingRole Resource creation Initiated
CDKToolkit |  0/12 | 9:28:43 am | CREATE_IN_PROGRESS      | AWS::SSM::Parameter        | CdkBootstrapVersion Resource creation Initiated
CDKToolkit |  0/12 | 9:28:43 am | CREATE_IN_PROGRESS      | AWS::ECR::Repository       | ContainerAssetsRepository Resource creation Initiated
CDKToolkit |  0/12 | 9:28:44 am | IMPORT_IN_PROGRESS      | AWS::S3::Bucket            | StagingBucket 
CDKToolkit |  1/12 | 9:28:44 am | IMPORT_COMPLETE         | AWS::S3::Bucket            | StagingBucket Resource import completed.
CDKToolkit |  2/12 | 9:28:44 am | CREATE_COMPLETE         | AWS::ECR::Repository       | ContainerAssetsRepository 
CDKToolkit |  3/12 | 9:28:44 am | CREATE_COMPLETE         | AWS::SSM::Parameter        | CdkBootstrapVersion 
CDKToolkit |  3/12 | 9:28:45 am | UPDATE_IN_PROGRESS      | AWS::S3::Bucket            | StagingBucket Apply stack-level tags to imported resource if applicable.
CDKToolkit |  4/12 | 9:29:01 am | CREATE_COMPLETE         | AWS::IAM::Role             | CloudFormationExecutionRole 
CDKToolkit |  5/12 | 9:29:01 am | CREATE_COMPLETE         | AWS::IAM::Role             | FilePublishingRole 
CDKToolkit |  6/12 | 9:29:01 am | CREATE_COMPLETE         | AWS::IAM::Role             | ImagePublishingRole 
CDKToolkit |  7/12 | 9:29:01 am | CREATE_COMPLETE         | AWS::IAM::Role             | LookupRole 
CDKToolkit |  7/12 | 9:29:02 am | CREATE_IN_PROGRESS      | AWS::IAM::Policy           | ImagePublishingRoleDefaultPolicy 
CDKToolkit |  7/12 | 9:29:02 am | CREATE_IN_PROGRESS      | AWS::IAM::Policy           | ImagePublishingRoleDefaultPolicy Resource creation Initiated
CDKToolkit |  6/12 | 9:29:08 am | UPDATE_COMPLETE         | AWS::S3::Bucket            | StagingBucket 
CDKToolkit |  6/12 | 9:29:09 am | CREATE_IN_PROGRESS      | AWS::IAM::Policy           | FilePublishingRoleDefaultPolicy 
CDKToolkit |  6/12 | 9:29:09 am | CREATE_IN_PROGRESS      | AWS::S3::BucketPolicy      | StagingBucketPolicy 
CDKToolkit |  6/12 | 9:29:09 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | DeploymentActionRole 
CDKToolkit |  6/12 | 9:29:10 am | CREATE_IN_PROGRESS      | AWS::IAM::Policy           | FilePublishingRoleDefaultPolicy Resource creation Initiated
CDKToolkit |  6/12 | 9:29:10 am | CREATE_IN_PROGRESS      | AWS::S3::BucketPolicy      | StagingBucketPolicy Resource creation Initiated
CDKToolkit |  6/12 | 9:29:10 am | CREATE_IN_PROGRESS      | AWS::IAM::Role             | DeploymentActionRole Resource creation Initiated
CDKToolkit |  7/12 | 9:29:10 am | CREATE_COMPLETE         | AWS::S3::BucketPolicy      | StagingBucketPolicy 
CDKToolkit |  8/12 | 9:29:18 am | CREATE_COMPLETE         | AWS::IAM::Policy           | ImagePublishingRoleDefaultPolicy 
CDKToolkit |  9/12 | 9:29:25 am | CREATE_COMPLETE         | AWS::IAM::Policy           | FilePublishingRoleDefaultPolicy 
CDKToolkit | 10/12 | 9:29:28 am | CREATE_COMPLETE         | AWS::IAM::Role             | DeploymentActionRole 
CDKToolkit | 11/12 | 9:29:29 am | CREATE_COMPLETE         | AWS::CloudFormation::Stack | CDKToolkit 
✅  Environment aws://637423369471/us-east-1 bootstrapped.
****************************************************
*** Newer version of CDK is available [2.1141.0] ***
*** Upgrade recommended (npm install -g aws-cdk) ***
****************************************************
PS E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure> 
```

## You can verify the CDK bootstrap in simple ways.

```powershell
# 1. Verify CDK bootstrap
npx cdk bootstrap --show-template | Select-Object -First 1

npx cdk doctor


# 2. Verify the CloudFormation stack
aws cloudformation describe-stacks --stack-name CDKToolkit --region us-east-1 --query "Stacks[0].StackStatus" --output text

# output :- CREATE_COMPLETE 
```

### 5e — Deploy Storage and Auth

```powershell

# I recommend verifying that CDK recognizes both stacks:
npx cdk list --context env=dev --verbose

# Yes. Since your CDK bootstrap succeeded, this is the deployment command for the two CDK stacks:
npx cdk deploy InvoiceStorage-dev InvoiceAuth-dev --context env=dev --require-approval never
# ⚠️ This will create/update real AWS resources in your account 637423369471, region us-east-1.
```

### Yes 👍 You can verify from another PowerShell terminal while the CDK deployment is running.
- Keep the current terminal running the deployment. Open a new PowerShell/Kiro terminal.

Takes ~3 minutes. Verify:
```powershell
## Check CloudFormation deployment status

aws cloudformation list-stacks --region us-east-1 `
  --stack-status-filter CREATE_IN_PROGRESS UPDATE_IN_PROGRESS CREATE_COMPLETE UPDATE_COMPLETE `
  --query "StackSummaries[?contains(StackName, 'Invoice')].[StackName,StackStatus]" `
  --output table
                                                                                                         
# |               ListStacks                |
# +---------------------+-------------------+
# |  InvoiceAuth-dev    |  CREATE_COMPLETE  |
# |  InvoiceStorage-dev |  CREATE_COMPLETE  |
# +---------------------+-------------------+

## Check the two specific stacks
aws cloudformation describe-stacks --stack-name InvoiceStorage-dev --region us-east-1 --query "Stacks[0].StackStatus" --output text
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --region us-east-1 --query "Stacks[0].StackStatus" --output text

# output :- CREATE_COMPLETE 

aws cloudformation describe-stacks --stack-name InvoiceStorage-dev --query "Stacks[0].StackStatus" --output text
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].StackStatus" --output text
```
Both must say `CREATE_COMPLETE`


## Excellent — both CDK stacks deployed successfully. ✅

<!-- - Deployment result
Stack	Status	        Resources
InvoiceStorage-dev	  ✅ CREATE_COMPLETE	22/22
InvoiceAuth-dev	     ✅ CREATE_COMPLETE	4/4 -->


### 5f — Deploy Processing and API

```powershell
# Yes. Since InvoiceStorage-dev and InvoiceAuth-dev are both CREATE_COMPLETE, this is the logical next deployment:

npx cdk deploy InvoiceProcessing-dev InvoiceApi-dev --context env=dev --require-approval never
```
- Keep this terminal running until both stacks finish.

Takes ~5 minutes. Verify:
```powershell
## These commands are for checking whether the two deployed CloudFormation/CDK stacks are successful. They are read-only commands — they don't create, update, or delete anything.

# 1. InvoiceProcessing-dev
aws cloudformation describe-stacks --stack-name InvoiceProcessing-dev --query "Stacks[0].[StackName,StackStatus]" --output table

# |  InvoiceProcessing-dev  |
# |  CREATE_COMPLETE        |
# +-------------------------+

# 2. InvoiceApi-dev
aws cloudformation describe-stacks --stack-name InvoiceApi-dev --query "Stacks[0].[StackName,StackStatus]" --output table

# |  InvoiceApi-dev   |
# |  CREATE_COMPLETE  |
# +-------------------+

# Or check both stacks with one command
aws cloudformation list-stacks --region us-east-1 `
  --query "StackSummaries[?StackName=='InvoiceProcessing-dev' || StackName=='InvoiceApi-dev'].[StackName,StackStatus]" `
  --output table

# Yes — this is normal CloudFormation behavior and does not mean your current stacks were deleted. 👍

# Terminal 2 — Monitor

aws cloudformation list-stacks --region us-east-1 `
  --stack-status-filter CREATE_IN_PROGRESS UPDATE_IN_PROGRESS CREATE_COMPLETE UPDATE_COMPLETE `
  --query "StackSummaries[?contains(StackName, 'Invoice')].[StackName,StackStatus]" `
  --output table

## output :-                                                                                                   
# |                  ListStacks                   |
# +------------------------+----------------------+
# |  InvoiceProcessing-dev |  CREATE_IN_PROGRESS  |
# |  InvoiceAuth-dev       |  CREATE_COMPLETE     |
# |  InvoiceStorage-dev    |  CREATE_COMPLETE     |
# +------------------------+----------------------+

                                                                                                         
# |                 ListStacks                 |
# +------------------------+-------------------+
# |  InvoiceApi-dev        |  CREATE_COMPLETE  |
# |  InvoiceProcessing-dev |  CREATE_COMPLETE  |
# |  InvoiceAuth-dev       |  CREATE_COMPLETE  |
# |  InvoiceStorage-dev    |  CREATE_COMPLETE  |
# +------------------------+-------------------+

# Excellent! 🎉 The deployment is fully successful.

# All 4 CDK stacks are now:

# InvoiceStorage-dev     CREATE_COMPLETE ✅
# InvoiceAuth-dev        CREATE_COMPLETE ✅
# InvoiceProcessing-dev  CREATE_COMPLETE ✅
# InvoiceApi-dev         CREATE_COMPLETE ✅

# So the core infrastructure for your OCR + Foundation Model + NoSQL application is now deployed successfully in:

---

## PART 6 — ATTACH THE LAMBDA LAYER

### 6a — Go back to project root

```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL"

# You are now at the project root, and:

Test-Path ".\fix-layer.ps1"

# output :- True

# [optional] I recommend first checking what the script will do:
Get-Content ".\fix-layer.ps1"
```

### 6b — Attach layer to API Lambdas

```powershell
# is used to run the fix-layer.ps1 PowerShell script, which should attach your previously built Lambda layer to the API Lambda functions.

powershell -ExecutionPolicy Bypass -File fix-layer.ps1
```

```text
# output :- 

Last line must show `"statusCode": 201`
If it shows `No module named 'shared'` → redo Part 4 then run this again.
```
- Excellent. ✅ fix-layer.ps1 completed successfully.


### 6c — Attach layer to Processing Lambdas

```powershell
# Before running — quick check
Test-Path ".\fix-processing-layer.ps1"

# Run this from the project root where fix-processing-layer.ps1 exists:
powershell -ExecutionPolicy Bypass -File fix-processing-layer.ps1
```

- Must end with `All processing Lambdas updated.`

---

## PART 7 — SET UP THE FRONTEND

### 7a — Get your fresh values from AWS

- it only retrieves the fresh values from your deployed AWS stacks. It does not change anything.

- Run these one by one from your current PowerShell terminal:

```powershell
# 1. Get API URL
# API URL (copy this — remove the trailing slash)
aws cloudformation describe-stacks --stack-name InvoiceApi-dev --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text
# output :- https://6q3r3zl8dg.execute-api.us-east-1.amazonaws.com/v1/   
# Copy the result and remove the trailing / if there is one.

# 2. Get Cognito User Pool ID
# Cognito User Pool ID
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text
# output :- us-east-1_kHfx7ccql

# 3. Get Cognito Client ID
# Cognito Client ID
aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text
# output :- 2ebghd29tds2stmmkfu35t2jn0
```

```text
# output : --------------------------------
# E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\frontend\.env.local

API URL:       https://6q3r3zl8dg.execute-api.us-east-1.amazonaws.com/v1
User Pool ID:  us-east-1_kHfx7ccql
Client ID:     2ebghd29tds2stmmkfu35t2jn0
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

- creates a Cognito login user for testing the frontend.
- It changes your Cognito User Pool, this is an actual AWS change.
- I recommend running it **one command at a time**.

### 1. Get the User Pool ID

```powershell
$POOL_ID = aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text

# Since PowerShell showed no error, $POOL_ID should now contain your Cognito User Pool ID.
```

Verify: let's verify it before creating the user:

```powershell
Write-Host "Pool ID: $POOL_ID"
```

It should be:

```text
us-east-1_kHfx7ccql
```

### 2. Create the test user

```powershell
aws cognito-idp admin-create-user --user-pool-id $POOL_ID --username "demo@example.com" --temporary-password "Temp@1234!" --message-action SUPPRESS
```

### 3. Set the permanent password

```powershell
aws cognito-idp admin-set-user-password --user-pool-id $POOL_ID --username "demo@example.com" --password "Invoice@Demo2026!" --permanent
```

### 4. Confirm the user exists

```powershell
aws cognito-idp admin-get-user --user-pool-id $POOL_ID --username "demo@example.com" --query "[Username,UserStatus,Enabled]" --output table

## Perfect ✅ Your Cognito test user is ready.

# |              AdminGetUser              |
# +----------------------------------------+
# |  d4d8f418-00b1-70e4-29d8-44e54282d2d3  |
# |  CONFIRMED                             |
# |  True                                  |
# +----------------------------------------+
```

You want to see something like:

```text
Username            UserStatus    Enabled
--------            ----------    -------
demo@example.com    CONFIRMED     True
```

### Login credentials

* **Username:** `demo@example.com`
* **Password:** `Invoice@Demo2026!`

⚠️ Since this is a real Cognito password, don't commit it to GitHub or put it in frontend source/config files.



<!-- ```powershell
$POOL_ID = aws cloudformation describe-stacks --stack-name InvoiceAuth-dev --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text

aws cognito-idp admin-create-user --user-pool-id $POOL_ID --username "demo@example.com" --temporary-password "Temp@1234!" --message-action SUPPRESS

aws cognito-idp admin-set-user-password --user-pool-id $POOL_ID --username "demo@example.com" --password "Invoice@Demo2026!" --permanent

Write-Host "User ready: demo@example.com / Invoice@Demo2026!"
``` -->

If you get `UsernameExistsException` that is fine — already created.

---

## PART 8 — RUN THE APP LOCALLY

### 8a — Start the frontend
- These are the correct commands to start your frontend locally.
```powershell
# 1. Go to the frontend folder
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\frontend"

# 2. Start the frontend
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

Test-Path ".\watch-pipeline.ps1"

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
