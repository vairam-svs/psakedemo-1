Include ".\helpers.ps1"

# setup a few variables/properties to simplify things and allow for overwriting
Properties {
    $testMessage = "Executed Test!"
    $compileMessage = "Executed Compile!"
    $cleanMessage = "Executed Clean!"

    $solutionDirectory = (Get-Item $solutionFile).DirectoryName
    $outputDirectory = "$solutionDirectory\.build"
    $tempOutputDirectory = "$outputDirectory\temp"
 
    $publishedNUnitTestsDirectory = "$tempOutputDirectory\_PublishedNUnitTests"
    $publishedxUnitTestsDirectory = "$tempOutputDirectory\_PublishedxUnitTests"
    $publishedMSTestTestsDirectory = "$tempOutputDirectory\_PublishedMSTestTests"

    $testResultsDirectory = "$outputDirectory\TestResults"
    $NUnitTestResultsDirectory = "$testResultsDirectory\NUnit"
    $xUnitTestResultsDirectory = "$testResultsDirectory\xUnit"
    $MSTestTestResultsDirectory = "$testResultsDirectory\MSTest"
        
    $buildConfiguration = "Release"
    $buildPlatform = "Any CPU"

    $packagesPath = "$solutionDirectory\packages"
    $NUnitExe = (Find-PackagePath $packagesPath "NUnit.Runners" ) + "\Tools\nunit-console-x86.exe"
    $xUnitExe = (Find-PackagePath $packagesPath "xUnit.Runner.Console" ) + "\Tools\xunit.console.exe"
    $vsTestExe = (Get-ChildItem ("C:\Program Files (x86)\Microsoft Visual Studio*\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe")).FullName | Sort-Object $_ | select -last 1
}

FormatTaskName "`r`n`r`n---------- Executing {0} Task ----------"

Task default -depends Test

Task Init `
    -description "Initializes the build by removing previous artifacts and creating output directories" `
    -requiredVariables outputDirectory, tempOutputDirectory {
    
    Assert -conditionToCheck ("Debug", "Release" -contains $buildConfiguration) `
           -failureMessage "Invalid build configuration '$buildConfiguration'. valid values are 'Debug' or 'Release'"

    Assert -conditionToCheck ("x86", "x64", "Any CPU" -contains $buildPlatform) `
           -failureMessage "Invalid build platform '$buildPlatform'. valid values are 'x86', 'x64', 'Any CPU'"

    # Check that all tools are available
    Write-Host "Checking that all required tools are available"
 
    Assert (Test-Path $NUnitExe) "NUnit Console could not be found"
    Assert (Test-Path $xUnitExe) "xUnit Console could not be found"

    # remove previous build directories
    if(Test-Path $outputDirectory) {
        Write-Host "Removing output directory located at $outputDirectory"
        Remove-Item $outputDirectory -Force -Recurse
    }  

    Write-Host "Creating output directory located at $outputDirectory"
    New-Item $outputDirectory -ItemType Directory | Out-Null

    Write-Host "Creating temp directory located at $tempOutputDirectory"
    New-Item $tempOutputDirectory -ItemType Directory | Out-Null
}


Task Compile -depends Init -description "Compile the code" `
    -requiredVariables solutionFile, buildConfiguration, buildPlatform, outputDirectory, tempOutputDirectory {
    Write-Host "Building solution $compileMessage"
    
    # wrap with Exec to capture the return error code
    Exec { 
        msbuild $solutionFile "/p:Configuration=$buildConfiguration;Platform=$buildPlatform;OutDir=$tempOutputDirectory"
    }
}

# test runner tasks
task TestNUnit `
    -depends Compile `
    -description "Run NUnit tests" `
    -precondition { return Test-Path $publishedNUnitTestsDirectory } `
    -requiredVariable publishedNUnitTestsDirectory, NUnitTestResultsDirectory `
{
    $testAssemblies = Prepare-Tests -testRunnerName "NUnit" `
                                    -publishedTestsDirectory $publishedNUnitTestsDirectory `
                                    -testResultsDirectory $NUnitTestResultsDirectory

    Exec { &$nunitExe $testAssemblies /xml:$NUnitTestResultsDirectory\NUnit.xml /nologo /noshadow }
}

task TestXUnit `
    -depends Compile `
    -description "Run xUnit tests" `
    -precondition { return Test-Path $publishedxUnitTestsDirectory } `
    -requiredVariable publishedxUnitTestsDirectory, xUnitTestResultsDirectory `
{
    $testAssemblies = Prepare-Tests -testRunnerName "xUnit" `
                                    -publishedTestsDirectory $publishedxUnitTestsDirectory `
                                    -testResultsDirectory $xUnitTestResultsDirectory

    Exec { &$xUnitExe $testAssemblies -xml $xUnitTestResultsDirectory\xUnit.xml -nologo -noshadow }
}

task TestMSTest `
    -depends Compile `
    -description "Run MSTest tests" `
    -precondition { return Test-Path $publishedMSTestTestsDirectory } `
    -requiredVariable publishedMSTestTestsDirectory, MSTestTestResultsDirectory `
{
    $testAssemblies = Prepare-Tests -testRunnerName "MSTest" `
                                    -publishedTestsDirectory $publishedMSTestTestsDirectory `
                                    -testResultsDirectory $MSTestTestResultsDirectory

    # vstest console doesn't have any option to change the output directory
    # so we need to change the working directory
    Push-Location $MSTestTestResultsDirectory
    Exec { &$vsTestExe $testAssemblies /Logger:trx }
    Pop-Location

    # move the .trx file back to $MSTestTestResultsDirectory
    Move-Item -path $MSTestTestResultsDirectory\TestResults\*.trx -destination $MSTestTestResultsDirectory\MSTest.trx

    Remove-Item $MSTestTestResultsDirectory\TestResults
}


#------------------------------
Task Test `
    -depends Compile, TestNUnit, TestXUnit, TestMSTest, Clean `
    -description "Run unit tests" {
    Write-Host $testMessage
}

Task Clean -description "Remove temporary files" {
    Write-Host $cleanMessage
}
