
### check CloudFormation directly

- Open a second PowerShell and run:
```powershell
aws cloudformation describe-stacks --region us-east-1 `
  --query "Stacks[?starts_with(StackName, 'Invoice') && (StackStatus=='CREATE_COMPLETE' || StackStatus=='UPDATE_COMPLETE')].[StackName,StackStatus]" `
  --output table
```
- output :- 
<!-- |               DescribeStacks               |
+------------------------+-------------------+
|  InvoiceFrontend-dev   |  CREATE_COMPLETE  |
|  InvoiceApi-dev        |  UPDATE_COMPLETE  |
|  InvoiceProcessing-dev |  CREATE_COMPLETE  |
|  InvoiceAuth-dev       |  CREATE_COMPLETE  |
|  InvoiceStorage-dev    |  CREATE_COMPLETE  |
+------------------------+-------------------+ -->


```powershell
aws s3api list-buckets --query "Buckets[?contains(Name, 'invoice-')].Name" --output table

```


## First, let's check whether your S3 buckets contain files, because those can affect cleanup:

```powershell
aws cloudformation describe-stacks --region us-east-1 `
  --query "Stacks[?starts_with(StackName, 'Invoice') && (StackStatus=='CREATE_COMPLETE' || StackStatus=='UPDATE_COMPLETE')].[StackName,StackStatus]" `
  --output table
```
                                                                                                           
<!-- |                 ListBuckets                 |
+---------------------------------------------+
|  invoice-frontend-dev-637423369471          |
|  invoice-frontend-hosting-dev-637423369471  |
|  invoice-processed-dev-637423369471         |
|  invoice-source-abc123                      |
|  invoice-uploads-dev-637423369471           |
+---------------------------------------------+ -->



```powershell
cd "E:\GenAi-Project-Cloudage\Trigger_OCR_Function_FM_NoSQL\new_project\Trigger_OCR_Function_FM_NoSQL\infrastructure"

npx cdk destroy InvoiceFrontend-dev InvoiceApi-dev InvoiceProcessing-dev InvoiceAuth-dev InvoiceStorage-dev --context env=dev

```




```powershell
aws cloudformation describe-stacks --region us-east-1 `
  --query "Stacks[?starts_with(StackName, 'Invoice') && (StackStatus=='CREATE_COMPLETE' || StackStatus=='UPDATE_COMPLETE')].[StackName,StackStatus]" `
  --output table

```




```powershell
aws cloudformation describe-stacks --region us-east-1 `
  --query "Stacks[?starts_with(StackName, 'Invoice') && (StackStatus=='CREATE_COMPLETE' || StackStatus=='UPDATE_COMPLETE')].[StackName,StackStatus]" `
  --output table

```




```powershell
aws cloudformation describe-stacks --region us-east-1 `
  --query "Stacks[?starts_with(StackName, 'Invoice') && (StackStatus=='CREATE_COMPLETE' || StackStatus=='UPDATE_COMPLETE')].[StackName,StackStatus]" `
  --output table

```