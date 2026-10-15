$ErrorActionPreference = 'Stop'
python (Join-Path $PSScriptRoot 'validate-site.py')
if ($LASTEXITCODE -ne 0) { throw 'Multilingual site validation failed.' }
