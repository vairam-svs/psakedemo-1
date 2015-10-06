cls

# '[p]sake' is the same as 'psake' but $Error is not polluted
Remove-Module [p]sake

# replace the hardcoded version # with a wildcard
##Import-Module ..\packages\psake.*\tools\psake.psm1

# future proof psake by getting the latest installed version
$psakeModule = (Get-ChildItem(".\packages\psake.*\tools\psake.psm1"))

Import-Module $psakeModule

Invoke-psake -buildFile .\pSake.Build\default.ps1 `
             -taskList Test `
             -framework 4.5.1 `
             -properties @{ 
                 "buildConfiguration" = "Release" 
                 "buildPlatform" = "Any CPU" } `
             -parameters @{ "solutionFile" = "..\pSake.sln" }

Write-Host "Build exit code: " $LASTEXITCODE

# propagating the exit code so that builds actually fail when there is a problem
Exit $LASTEXITCODE
