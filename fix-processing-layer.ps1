# fix-processing-layer.ps1 — Attaches the shared layer to all 5 processing Lambdas
# Must run AFTER fix-layer.ps1 (reuses the zip it creates)
# Run from the project root directory

$zipPath = "$env:TEMP\shared-layer-v2.zip"

if (-not (Test-Path $zipPath)) {
    Write-Host "ERROR: $zipPath not found. Run fix-layer.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Publishing layer for processing stack..."
$json = aws lambda publish-layer-version `
    --layer-name invoice-shared-dev `
    --description "Shared layer python/shared/ + pydantic deps" `
    --compatible-runtimes python3.12 `
    --zip-file "fileb://$zipPath"
$result = $json | ConvertFrom-Json
$newArn = $result.LayerVersionArn
Write-Host "New ARN: $newArn"

$functions = "invoice-ocr-dev","invoice-ai-analysis-dev","invoice-risk-scoring-dev","invoice-store-results-dev","invoice-sqs-trigger-dev"

foreach ($fn in $functions) {
    Write-Host "Updating $fn ..."
    aws lambda update-function-configuration --function-name $fn --layers $newArn | Out-Null
    aws lambda wait function-updated --function-name $fn
    Write-Host "  done"
}

Write-Host "All processing Lambdas updated."
