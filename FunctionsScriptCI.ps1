Function EnableEndToEndTests()
{
    Write-Host "E2E tests enabled" -ForegroundColor Yellow
    Get-ChildItem Env: | Where-Object {$_.Name -like 'AZFC_*'} | ForEach-Object {[Environment]::SetEnvironmentVariable($_.Name.SubString(5), $_.Value )}
}

Function ShouldEnableEndToEnd()
{
     #$buildconfig = Get-Content BuildConfig.json | ConvertFrom-Json
     $buildconfig = ConvertFrom-Json (Invoke-WebRequest -Uri https://raw.githubusercontent.com/fabiocav/build-scripts/master/BuildConfig.json).Content
     $pruri = "https://api.github.com/repos/azure/azure-webjobs-sdk-script/issues/"+$env:APPVEYOR_PULL_REQUEST_NUMBER
     $pr = ConvertFrom-Json (Invoke-WebRequest -Uri $pruri).Content

     # First, check if the author is one of our known users
     # We should eventually get the users from the appropriate team directly from GH, but will need credentials with access
     Write-Host "PR author: " -ForegroundColor Cyan -NoNewline
     Write-Host $pr.user.login -ForegroundColor Green
     if ($buildconfig.EndToEndTestUsers.Contains($pr.user.login))
     {
       Write-Host "Full CI triggered by user: " -ForegroundColor Cyan -NoNewline
       Write-Host $pr.user.login -ForegroundColor Green
       return $true
     }
     else
     {
        Write-Host "Checking PR labels..." -ForegroundColor Green
        # Check if the PR has a build label
        
        $prlabels = $pr.labels | ForEach-Object {$_.name}

        $labelMatches = Compare-Object -ExcludeDifferent -IncludeEqual $prlabels $buildconfig.EndToEndTestLabels | ForEach-Object {$_.InputObject}
        
        if ($labelMatches)
        {
            Write-Host "Full CI triggered by PR label(s): " -ForegroundColor Cyan -NoNewline
            Write-Host ($labelMatches -join ", ")  -ForegroundColor Green


        }
     }

     return $false
}

# Set path to include PHP, Python and F#
$env:Path="c:\tools\php;c:\python35;C:\Program Files (x86)\Microsoft SDKs\F#\4.0\Framework\v4.0;"+$env:Path

# If this is a PR, check if we're supposed to run E2E tests
if ($env:APPVEYOR_PULL_REQUEST_NUMBER)
{
    Write-Host "Building Pull Request #"$env:APPVEYOR_PULL_REQUEST_NUMBER -ForegroundColor Gray
    
    if (ShouldEnableEndToEnd)
    {
        EnableEndToEndTests
    }
}
else
{
    Write-Host "Building Branch Commit" -ForegroundColor Gray
    EnableEndToEndTests
}
