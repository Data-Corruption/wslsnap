# wslsnap.ps1

$snapshotFolder = Join-Path -Path $PSScriptRoot -ChildPath "snapshots"
$wslFolder = "C:\WSL"
$arguments = $args

function Invoke-Command($command) {
  try { return Invoke-Expression $command }
  catch { throw "Failed to execute command: $command. Error: $_" }
}

function Get-RegisteredDistributionName() {
  $output = Invoke-Command "wsl -l -v"
  # If $output is an array, join it into a single string for easier processing
  $output = if ($output -is [array]) { $output -join " " } else { $output }
  # only keep alphanumeric characters, whitespace, newlines, and asterisks
  $output = $output -replace '[^\w\s\n*]', ''
  # split the output into tokens and return the token after the asterisk
  $tokens = $output -split '\s+'
  for ($i = 0; $i -lt $tokens.Length; $i++) {
    if ($tokens[$i] -eq '*') {
      if ($i -lt $tokens.Length - 1) {
        return $tokens[$i + 1]
      }
    }
  }
}

function Get-NameArg() {
  if ($arguments.Count -lt 2) {
    throw "Please provide a snapshot name."
  }
  return $arguments[1]
}

function Get-Snapshots {
  $snapshots = Get-ChildItem -Path $snapshotFolder -Filter "*.tar"
  if ($snapshots) {
    Write-Host "Available snapshots:"
    $snapshots | ForEach-Object { Write-Host $_.BaseName }
  }
  else {
    Write-Host "No snapshots found."
  }
}

function New-Snapshot() {
  $name = Get-NameArg
  $snapshotPath = Join-Path -Path $snapshotFolder -ChildPath "$name.tar"
  $registeredDistro = Get-RegisteredDistributionName

  if ($registeredDistro) {
    Write-Host "Creating snapshot '$name' for distribution '$registeredDistro'..."
    Invoke-Command "wsl --export $registeredDistro $snapshotPath"
    Write-Host "Snapshot created successfully."
  }
  else {
    Write-Warning "No registered WSL distribution found."
  }
}

function Remove-Snapshot() {
  $name = Get-NameArg
  $snapshotPath = Join-Path -Path $snapshotFolder -ChildPath "$name.tar"

  if (Test-Path $snapshotPath) {
    Remove-Item $snapshotPath
    Write-Host "Snapshot '$name' removed successfully."
  }
  else {
    Write-Warning "Snapshot '$name' not found."
  }
} 

function Restore-Snapshot() {
  $name = Get-NameArg
  $snapshotPath = Join-Path -Path $snapshotFolder -ChildPath "$name.tar"

  if (-NOT (Test-Path $snapshotPath)) {
    throw "Snapshot '$name' not found."
  }

  # if a distribution is already registered, ask the user if they want to create a snapshot before overwriting it
  $registeredDistro = Get-RegisteredDistributionName
  $registeredDistroPath = Join-Path -Path $wslFolder -ChildPath $registeredDistro
  if ($registeredDistro) {
    $response = Read-Host "Do you want to create a snapshot of the current state before restoring? (y/n)"
    if ($response -eq "y") {
      $newName = Read-Host "Enter a name for the new snapshot"
      if (-NOT $newName) {
        throw "Snapshot name cannot be empty."
      }
      $newSnapshotPath = Join-Path -Path $snapshotFolder -ChildPath "$newName.tar"
      Write-Host "Creating snapshot '$newName' for distribution '$registeredDistro'..."
      Invoke-Command "wsl --export $registeredDistro $newSnapshotPath"
      Write-Host "Snapshot created successfully."
    }
    #unregister current distribution
    Write-Host "Unregistering distribution '$registeredDistro'..."
    Invoke-Command "wsl --unregister $registeredDistro"
    Write-Host "Distribution unregistered successfully."
  }
  else {
    # get a name for the new wsl registration
    $registeredDistro = Read-Host "Enter a name for the restored distribution"
    if (-NOT $registeredDistro) {
      throw "Distribution name cannot be empty."
    }
  }

  # register snapshot distribution
  Write-Host "Restoring snapshot '$name'..."
  Invoke-Command "wsl --import $registeredDistro $registeredDistroPath $snapshotPath --version 2"
  Write-Host "Snapshot restored successfully."
}

function Write-Usage {
  Write-Host "Usage: wslsnap <command> [<snapshot-name>]"
  Write-Host "Commands:"
  Write-Host "  list           List available snapshots"
  Write-Host "  create         Create a new snapshot"
  Write-Host "  restore        Restore a snapshot"
  Write-Host "  remove         Remove a snapshot"
}

# ==== Main ===================================================================

try {
  # check if running as Administrator
  if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    throw "Please run this script as an Administrator."
  }

  # create snapshot folder if it doesn't exist
  if (-NOT (Test-Path $snapshotFolder)) {
    New-Item -ItemType Directory -Path $snapshotFolder | Out-Null
  }

  # if no arguments provided, show usage
  if ($args.Count -eq 0) {
    Write-Usage
    exit
  }

  # process command
  switch ($args[0]) {
    "list" { Get-Snapshots }
    "create" { New-Snapshot }
    "restore" { Restore-Snapshot }
    "remove" { Remove-Snapshot }
    default {
      Write-Warning "Invalid command: $($args[0])"
      Write-Usage
    }
  }
}
catch {
  Write-Error "An error occurred: $_"
}