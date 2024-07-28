param (
    [switch]$init = $false,
    [switch]$backup = $false,
    [string]$JsonFile
)

function TestAndCreateFolder {
    param(
        [string]$path
    )
    if (-Not (Test-Path -PathType Container -Path $path)) {
        New-Item -ItemType Directory -Path $path
        Write-Host "Created Folder: $path"
    } else {
        Write-Host "Found Folder: $path"
    }
}

function Initialize-Repos {
    param (
        [string]$FilePath
    )
    
    # Load and process JSON file
    if (Test-Path $FilePath) {
        $jsonContent = Get-Content -Path $FilePath | ConvertFrom-Json

        $securePassword = ConvertTo-SecureString -String $jsonContent.password -AsPlainText -Force
        $Env:RESTIC_PASSWORD=$securePassword
        
        $basePath = $jsonContent.baseRepositoryPath
        $backupItems = $jsonContent.backupPaths
        
        foreach ($backupItem in $backupItems) {
            $targetRepository = $backupItem.targetRepository
            $fullPath = Join-Path -Path $basePath -ChildPath $targetRepository
            TestAndCreateFolder -Path $fullPath
            $Env:RESTIC_REPOSITORY = $fullPath
            Write-Output "Initializing repo at: $fullPath"
            restic init
        }
    } else {
        Write-Output "Error: File not found: $FilePath"
    }
}

function Backup-To-Repos {
    param (
        [string]$FilePath
    )
    
    # Load and process JSON file
    if (Test-Path $FilePath) {
        $jsonContent = Get-Content -Path $FilePath | ConvertFrom-Json
        
        $securePassword = ConvertTo-SecureString -String $jsonContent.password -AsPlainText -Force
        $Env:RESTIC_PASSWORD=$securePassword
        
        $basePath = $jsonContent.baseRepositoryPath
        $backupItems = $jsonContent.backupPaths
        
        foreach ($backupItem in $backupItems) {
            $targetRepository = $backupItem.targetRepository
            $fullPath = Join-Path -Path $basePath -ChildPath $targetRepository
            $Env:RESTIC_REPOSITORY = $fullPath
            restic backup $backupItem.sourcePath
        }
    } else {
        Write-Output "Error: File not found: $FilePath"
    }
}

# Main script logic
if ($init) {
    Initialize-Repos -FilePath $JsonFile
}
if ($backup) {
    Backup-To-Repos -FilePath $JsonFile
}
if (-Not $init -And -Not $backup) {
    Write-Output "Please specify a backup command: -init or -backup"
    exit
}
