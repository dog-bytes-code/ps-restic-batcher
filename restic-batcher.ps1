param (
    [switch]$init = $false,
    [switch]$backup = $false,
    [switch]$list = $false,
    [switch]$set = $false,
    [string]$SelectedRepository = $null,
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

function Get-Repos {
    param (
        [pscustomobject]$backupItems
    )

    foreach ($backupItem in $backupItems) {
        Write-Output $backupItem.targetRepository
    }
}

function Initialize-Repos {
    param (
        [pscustomobject]$backupItems
    )
        
    foreach ($backupItem in $backupItems) {
        # Set repo password 
        $securePassword = ConvertTo-SecureString -String $backupItem.repositoryPassword -AsPlainText -Force
        $Env:RESTIC_PASSWORD=$securePassword
        $fullPath = Join-Path -Path $backupItem.targetRepositoryPath -ChildPath $backupItem.targetRepository
        TestAndCreateFolder -Path $fullPath
        $Env:RESTIC_REPOSITORY = $fullPath
        Write-Output "Initializing repo at: $fullPath"
        restic init
    }
}

function Backup-To-Repos {
    param (
        [pscustomobject]$backupItems
    )
    
    foreach ($backupItem in $backupItems) {
        # Set repo password 
        $securePassword = ConvertTo-SecureString -String $backupItem.repositoryPassword -AsPlainText -Force
        $Env:RESTIC_PASSWORD=$securePassword
        $fullPath = Join-Path -Path $backupItem.targetRepositoryPath -ChildPath $backupItem.targetRepository
        $Env:RESTIC_REPOSITORY = $fullPath
        restic backup $backupItem.sourcePath
    }
}

function Set-Backup-Item {
    param (
        $backupItems,
        [string]$selectedRepository
    )

    foreach ($backupItem in $backupItems) {
        if ($backupItem.targetRepository -eq $selectedRepository) {
            $securePassword = ConvertTo-SecureString -String $backupItem.repositoryPassword -AsPlainText -Force
            $Env:RESTIC_PASSWORD=$securePassword
            $fullPath = Join-Path -Path $backupItem.targetRepositoryPath -ChildPath $backupItem.targetRepository
            $Env:RESTIC_REPOSITORY = $fullPath
        }
    }
}

function Main {

    if ($init) {
        $jsonContent = Get-Content -Path $JsonFile | ConvertFrom-Json
        Initialize-Repos -BackupItems $jsonContent.backupItems
    }
    if ($set) {
        $jsonContent = Get-Content -Path $JsonFile | ConvertFrom-Json
        Set-Backup-Item -BackupItems $jsonContent.backupItems -SelectedRepository $SelectedRepository
    }
    if ($backup) {
        $jsonContent = Get-Content -Path $JsonFile | ConvertFrom-Json
        Backup-To-Repos -BackupItems $jsonContent.backupItems
    }
    if ($list) {
        $jsonContent = Get-Content -Path $JsonFile | ConvertFrom-Json
        Get-Repos -BackupItems $jsonContent.backupItems
    }
    if (-Not $init -And -Not $backup -And -Not $list -And -Not $set) {
        
        Write-Output(' ')
        Write-Output('No option specified.')
        Write-Output('Usage: restic-batcher.ps1 [-init|-backup|-list|-set] [-SelectedRepository repo-name] [-JsonFile /full/path/to/file]')
        Write-Output('Options:')
        Write-Output('  -init: Uses `restic init` to Initialize each repository defined in the JSON description file.')
        Write-Output('  -backup: Uses `restic backup` to update the backup of each repository defined in the JSON description file.')
        Write-Output('  -list: Lists the names of the repositories defined in the JSON description file.')
        Write-Output('  -set: Sets the local environment to the repository specified in -SelectedRepository.')
        exit
    }
}

# Run Main script logic
Main
