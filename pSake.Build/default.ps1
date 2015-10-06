# setup a few variables/properties to simplify things and allow for overwriting
Properties {
    $testMessage = "Executed Test!"
    $compileMessage = "Executed Compile!"
    $cleanMessage = "Executed Clean!"

    $solutionDirectory = (Get-Item $solutionFile).DirectoryName
    $outputDirectory = "$solutionDirectory\.build"
    $tempOutputDirectory = "$outputDirectory\temp"
    $buildConfiguration = "Release"
    $buildPlatform = "Any CPU"
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

Task Clean -description "Remove temporary files" {
    Write-Host $cleanMessage
}

Task Compile -depends Init -description "Compile the code" `
    -requiredVariables solutionFile, buildConfiguration, buildPlatform, outputDirectory, tempOutputDirectory {
    Write-Host "Building solution $compileMessage"
    
    # wrap with Exec to capture the return error code
    Exec { 
        msbuild $solutionFile "/p:Configuration=$buildConfiguration;Platform=$buildPlatform;OutDir=$tempOutputDirectory"
    }
}

Task Test -depends Compile, Clean -description "Run unit tests" {
    Write-Host $testMessage
}