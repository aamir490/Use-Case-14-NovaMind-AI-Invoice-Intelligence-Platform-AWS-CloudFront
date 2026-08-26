# fix-layer.ps1 — Builds and attaches the shared Lambda layer to all 3 API Lambdas
# Run from the project root directory

$root     = $PSScriptRoot
$srcPy    = "$root\backend\lambdas\shared"
$layerOut = "$root\backend\lambdas\shared-layer-v2"
$zipPath  = "$env:TEMP\shared-layer-v2.zip"
$testPayload = "$env:TEMP\test-payload.json"
$lambdaOut   = "$env:TEMP\lambda-out.json"

# ── 1. Build correct layer structure ────────────────────────────────────────
Write-Host "Building layer structure..."

if (Test-Path $layerOut) { Remove-Item $layerOut -Recurse -Force }

$pkgDir  = "$layerOut\python\shared"
$depsDir = "$layerOut\python"
New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null

Copy-Item "$srcPy\*.py" $pkgDir -Force
Write-Host "  Copied .py files to python\shared\"

pip install pydantic boto3 -t $depsDir --quiet --upgrade
Write-Host "  pip install done"

# ── 2. Verify structure ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "Structure check:"
Write-Host "  python\shared\db.py       : $(Test-Path "$pkgDir\db.py")"
Write-Host "  python\shared\models.py   : $(Test-Path "$pkgDir\models.py")"
Write-Host "  python\shared\__init__.py : $(Test-Path "$pkgDir\__init__.py")"
Write-Host "  python\pydantic\          : $(Test-Path "$depsDir\pydantic")"

# ── 3. Zip it ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Creating zip..."
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $layerOut, $zipPath,
    [System.IO.Compression.CompressionLevel]::Optimal, $false
)
Write-Host "  Size: $([math]::Round((Get-Item $zipPath).Length/1MB,2)) MB"

# ── 4. Publish new layer version ─────────────────────────────────────────────
Write-Host ""
Write-Host "Publishing layer..."
$result = aws lambda publish-layer-version `
    --layer-name invoice-api-shared-dev `
    --description "Shared package at python/shared/ + pydantic deps" `
    --compatible-runtimes python3.12 `
    --zip-file "fileb://$zipPath" | ConvertFrom-Json

$newArn = $result.LayerVersionArn
Write-Host "  New ARN: $newArn"

# ── 5. Attach to all 3 API Lambdas ───────────────────────────────────────────
Write-Host ""
Write-Host "Updating Lambda functions..."
foreach ($fn in @("invoice-api-upload-dev","invoice-api-invoices-dev","invoice-api-analytics-dev")) {
    aws lambda update-function-configuration --function-name $fn --layers $newArn | Out-Null
    aws lambda wait function-updated --function-name $fn
    Write-Host "  $fn updated"
}

# ── 6. Smoke test ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Smoke testing upload Lambda..."
$payload = '{"httpMethod":"POST","path":"/invoices/upload-url","headers":{"origin":"http://localhost:5173"},"requestContext":{"authorizer":{"claims":{"sub":"test-tenant-001"}}},"body":"{\"filename\":\"test.png\",\"content_type\":\"image/png\"}"}'
[System.IO.File]::WriteAllText($testPayload, $payload)

aws lambda invoke `
    --function-name invoice-api-upload-dev `
    --payload "fileb://$testPayload" `
    --cli-binary-format raw-in-base64-out `
    $lambdaOut | Out-Null

$response = Get-Content $lambdaOut
Write-Host "Response: $response"
