#!/usr/bin/env pwsh

param (
    [string]$template,
    [string]$name,
    [string]$giturl,
    [string]$dir,
    [string]$title,
    [string]$desc,
    [string]$port,
    [string]$pkg,
    [string]$version,
    [string]$jdk,
    [string]$mvn,
    [string]$coverage
)

# Template Git Repos
$java8Console="https://github.com/tamckenna/java8-console-template.git"
$java8RestAPI="https://github.com/tamckenna/java8-restapi-template.git"

$initialDir="$PWD"
function recursiveDeleteDirectory($path){ Remove-Item -Recurse -Force -ErrorAction Ignore -Path $path }
function switchToWindowsSlashes($path){ return $path.replace('/', '\') }

######################################################################
# Base Project Input/Configuration
######################################################################

# Specify Template if haven't already
if($giturl) { $template="custom" }
if(!$template){
    $defaultValue=$template
    $prompt = Read-Host "Specify template type [Options: java8-console, java8-restapi, restapi, or console]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $template=$prompt
}

if($template -eq "custom"){ }
elseif($template -eq "java8-restapi"){ $giturl=$java8RestAPI }
elseif ($template -eq "java-restapi") { $giturl=$java8RestAPI }
elseif ($template -eq "java8-rest") { $giturl=$java8RestAPI }
elseif ($template -eq "java-rest") { $giturl=$java8RestAPI }
elseif ($template -eq "java-console") { $giturl=$java8Console }
elseif ($template -eq "java8-console") { $giturl=$java8Console }
elseif ($template -eq "console") { $giturl=$java8Console }
elseif ($template -eq "restapi") { $giturl=$java8RestAPI }
elseif ($template -eq "rest") { $giturl=$java8RestAPI }
else{ $giturl=$java8Console }

# Default Base Project Values
$defaultProjectName="application-template"
$defaultProjectTitle="Application Template"
$defaultProjectDescription="An application template"
$defaultProjectPort="8080"

# Specify Project/Artifact Name
$newProjectName=$name
if(!$newProjectName){
    $defaultValue="application-template"
    $prompt = Read-Host "Project/Artifact Name [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectName=$prompt
}

# Specify Template Git Repo URL
$templateGitUrl = $gitUrl
if(! $template -eq "custom"){
    $defaultValue = $templateGitUrl
    $prompt = Read-Host "Template Git Repo URL [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $templateGitUrl=$prompt
}

# Target Directory to setup project
$targetDir=$dir
if(!$targetDir){
    $defaultValue="${HOME}/Desktop"
    if($IsWindows){ $defaultValue = (switchToWindowsSlashes -path $defaultValue) }
    $prompt = Read-Host "Directory to create '$newProjectName' inside of [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $targetDir=$prompt
}

# Expand '$' variables to explicit path
$targetDir=$ExecutionContext.InvokeCommand.ExpandString("$targetDir")

# Specify Project Title
$newProjectTitle=$title
if(!$newProjectTitle){
    $defaultValue="Application Template Title"
    $prompt = Read-Host "Project Title [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectTitle=$prompt
}

# Specify Project Description
$newProjectDescription=$desc
if(!$newProjectDescription){
    $defaultValue="An application template description"
    $prompt = Read-Host "Project Description [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectDescription=$prompt
}

# If not console or library specify port
if($template.Contains("console")){ }
elseif($template.Contains("library")){ }
else{
    $newProjectPort=$port
    if(!$newProjectPort){
        $defaultValue=$defaultProjectPort
        $prompt = Read-Host "Application Port [$($defaultValue)]"
        $prompt = ($defaultValue,$prompt)[[bool]$prompt]
        $newProjectPort=$prompt
    }
}

######################################################################
# Java Specific Input/Configuration
######################################################################

# Default Java Specific Values
$defaultPkgName="com.example"
$defaultPkgPath=$defaultPkgName.Replace(".", "/")
$defaultProjectVersion="0.0.0"
$defaultProjectJavaVersion="1.8"
$defaultProjectCodeCoverage="75"
$defaultProjectCustomMavenRepoUrl="http://localhost:8081/repository/maven-releases"

# Specify Project Group/Package for project
$newPkgName=$pkg
if(!$newPkgName){
    $defaultValue=$defaultPkgName
    $prompt = Read-Host "Project Package Name [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newPkgName=$prompt
}

# Specify Project/Artifact Version
$newProjectVersion=$version
if(!$newProjectVersion){
    $defaultValue="1.0.0"
    $prompt = Read-Host "Project/Artifact Version [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectVersion=$prompt
}

# Specify Java Version
$newProjectJavaVersion=$jdk
if(!$newProjectJavaVersion){
    $defaultValue="8"
    $prompt = Read-Host "Java JDK Version [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectJavaVersion=$prompt
}

# Specify Custom Maven Repo URL
$newProjectCustomMavenRepoUrl=$mvn
if(!$newProjectCustomMavenRepoUrl){
    $defaultValue=$defaultProjectCustomMavenRepoUrl
    $prompt = Read-Host "Custom Maven Repo URL [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectCustomMavenRepoUrl=$prompt
}

# Specify Code Coverage Requirement
$newProjectCodeCoverage=$coverage
if(!$newProjectCodeCoverage){
    $defaultValue="75"
    $prompt = Read-Host "Code Coverage % Required [$($defaultValue)]"
    $prompt = ($defaultValue,$prompt)[[bool]$prompt]
    $newProjectCodeCoverage=$prompt
}

######################################################################
# Confirm Input and Execute
######################################################################

# Cleanup inputs
$newProjectName=$newProjectName.ToLower()
$newPkgName=$newPkgName.ToLower().Replace("-", "_").Replace(" ", "_").Replace("/", ".").Replace('\', '.')
$newProjectCodeCoverage=$newProjectCodeCoverage -Replace "[^0-9]", ""
$newProjectJavaVersion=$newProjectJavaVersion -Replace "[^0-9.]", ""

# Generate Project Directory Path
$newProjectDir="${targetDir}/${newProjectName}"
if($IsWindows){ $newProjectDir = (switchToWindowsSlashes -path $newProjectDir) }

# Verify that new Project Directory does not already exist
if(Test-Path $newProjectDir -PathType Container){
    echo "The directory ${newProjectDir} already exists!"
    exit
}

# Verify Git repository exists if local
if($templateGitUrl.Contains("http")){ }
elseif($templateGitUrl.Contains("ssh")){ }
elseif($templateGitUrl.Contains("@")){ }
else{
    if(! (Test-Path $templateGitUrl -PathType Container)){
        echo "The local Git repository ${templateGitUrl} does not exist!"
        exit
    }
}

# Print Inputs
echo ""
#echo "Template: ${template}"
echo "Name: ${newProjectName}"
echo "Template Git Repo: ${templateGitUrl}"
echo "Project Directory: ${newProjectDir}"
echo "Project Title: ${newProjectTitle}"
echo "Project Description: ${newProjectDescription}"
echo "Project Port: ${newProjectPort}"
echo "Project Package: ${newPkgName}"
echo "Project Version: ${newProjectVersion}"
echo "JDK Version: ${newProjectJavaVersion}"
echo "Custom Maven Repo URL: ${newProjectCustomMavenRepoUrl}"
echo "Code Coverage % Required: ${newProjectCodeCoverage}"

# Confirm Input
echo ""
echo "Project will be created at: ${targetDir}/${newProjectName}"
echo ""
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" 
echo ""

# Fix Java 8/9 Specification
if($newProjectJavaVersion -eq "8"){ $newProjectJavaVersion="1.8" }
elseif ($newProjectJavaVersion -eq "9"){ $newProjectJavaVersion="1.9" }

# Make Sure Parent Directory Exists
New-Item -ItemType Directory -Force -Path $newProjectDir | Out-Null
recursiveDeleteDirectory -path $newProjectDir
#New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

# Clone template repository
git clone $templateGitUrl $newProjectDir | Out-Null

# Quit if local directory is not created
if(! (Test-Path $newProjectDir -PathType Container)){
    echo "Cloning down ${templateGitUrl} into ${newProjectDir} has failed!"
    exit
}

cd $newProjectDir

# Configure input package/project variables
$newPkgPath=$newPkgName.Replace(".", "/")

function replaceInFile($targetFile, $find, $replace) {
    (Get-Content $targetFile).replace("$find", "$replace") | Set-Content $targetFile
}

# Configure gradle.properties file
$targetFile="gradle.properties"
replaceInFile -targetFile $targetFile -find $defaultPkgName -replace $newPkgName
replaceInFile -targetFile $targetFile -find $defaultProjectName -replace $newProjectName
replaceInFile -targetFile $targetFile -find $defaultProjectVersion -replace $newProjectVersion
replaceInFile -targetFile $targetFile -find $defaultProjectJavaVersion -replace $newProjectJavaVersion
replaceInFile -targetFile $targetFile -find $defaultProjectCodeCoverage -replace $newProjectCodeCoverage
replaceInFile -targetFile $targetFile -find $defaultProjectCustomMavenRepoUrl -replace $newProjectCustomMavenRepoUrl

# Configure readme.md
$targetFile="readme.md"
replaceInFile -targetFile $targetFile -find $defaultPkgName -replace $newPkgName
replaceInFile -targetFile $targetFile -find $defaultPkgPath -replace $newPkgPath
replaceInFile -targetFile $targetFile -find $defaultProjectName -replace $newProjectName
replaceInFile -targetFile $targetFile -find $defaultProjectTitle -replace $newProjectTitle
replaceInFile -targetFile $targetFile -find $defaultProjectDescription -replace $newProjectDescription
replaceInFile -targetFile $targetFile -find "port: __${defaultProjectPort}__" -replace "port: __${newProjectPort}__"

# Configure devcontainer.json
$targetFile=".devcontainer/devcontainer.json"
replaceInFile -targetFile $targetFile -find """forwardPorts"": [${defaultProjectPort}]" -replace """forwardPorts"": [${newProjectPort}]"

# Configure *.java file inside src/main/java
$targetPath="src/main/java"
Get-ChildItem –Path $targetPath -Recurse -Filter *.java | Foreach-Object { replaceInFile -targetFile $_ -find $defaultPkgName -replace $newPkgName }

# Configure *.java file inside src/test/java
$targetPath="src/test/java"
Get-ChildItem –Path $targetPath -Recurse -Filter *.java | Foreach-Object { replaceInFile -targetFile $_ -find $defaultPkgName -replace $newPkgName }

# Configure application.properties
$targetFile="src/main/resources/application.properties"
replaceInFile -targetFile $targetFile -find $defaultProjectName -replace $newProjectName
replaceInFile -targetFile $targetFile -find "server.port=${defaultProjectPort}" -replace "server.port=${newProjectPort}"

# Move main Java classes file to correct directory
$newMainPkgPath="src/main/java/${newPkgPath}"
$defaultMainPkgPath="src/main/java/${defaultPkgPath}"
Move-Item $defaultMainPkgPath "tmp-main"
if(!(Test-Path $newMainPkgPath)) { New-Item -Path $newMainPkgPath -Force | Out-Null }
recursiveDeleteDirectory -path $newMainPkgPath
Move-Item "tmp-main" $newMainPkgPath

# Move test Java classes file to correct directory
$newTestPkgPath="src/test/java/${newPkgPath}"
$defaultTestPkgPath="src/test/java/${defaultPkgPath}"
Move-Item $defaultTestPkgPath "tmp-test"
if(!(Test-Path $newTestPkgPath)) { New-Item -Path $newTestPkgPath -Force | Out-Null }
recursiveDeleteDirectory -path $newTestPkgPath
Move-Item "tmp-test" $newTestPkgPath

# Remove template git repo and create a new local repo
recursiveDeleteDirectory -path ".git/"
git init | Out-Null
git add .  | Out-Null
git commit -m "Initial Commit"  | Out-Null

cd $initialDir