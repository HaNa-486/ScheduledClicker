$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$outputDirectory = Join-Path $projectRoot 'dist'
$testDirectory = Join-Path $projectRoot '.artifacts\tests'

if (-not (Test-Path -LiteralPath $compiler)) {
    throw '找不到 Windows 內建的 .NET Framework C# 編譯器。'
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $testDirectory | Out-Null

& $compiler /nologo /target:winexe /platform:anycpu /optimize+ /win32manifest:"$projectRoot\ScheduledClicker\app.manifest" /out:"$outputDirectory\ScheduledClicker.exe" /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "$projectRoot\ScheduledClicker\AssemblyInfo.cs" "$projectRoot\ScheduledClicker\Program.cs" "$projectRoot\ScheduledClicker\SchedulerCore.cs"
if ($LASTEXITCODE -ne 0) { throw '應用程式建置失敗。' }

& $compiler /nologo /target:exe /platform:anycpu /optimize+ /out:"$testDirectory\SchedulerCoreTests.exe" /reference:System.dll /reference:System.Drawing.dll "$projectRoot\Tests\SchedulerCoreTests.cs" "$projectRoot\ScheduledClicker\SchedulerCore.cs"
if ($LASTEXITCODE -ne 0) { throw '測試程式建置失敗。' }

& $compiler /nologo /target:exe /platform:anycpu /optimize+ /out:"$testDirectory\MouseIntegrationTest.exe" /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "$projectRoot\Tests\MouseIntegrationTest.cs" "$projectRoot\ScheduledClicker\SchedulerCore.cs"
if ($LASTEXITCODE -ne 0) { throw '整合測試程式建置失敗。' }

Write-Host "建置完成：$outputDirectory\ScheduledClicker.exe"
