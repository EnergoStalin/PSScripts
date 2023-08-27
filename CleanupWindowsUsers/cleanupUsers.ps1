#Requires -Version 5.1

param(
  [String]$Path="data",
  [String]$NamesFile=".\names.txt",
  [String]$LogFile=".\log$(Get-Date -Format "yyyyMMdHHmmss").txt",
  [String]$LogDirectory=".\logs",
  [switch]$WhatIf
)

$ExtraArgs = @{}
if ($WhatIf) {
    $ExtraArgs["WhatIf"] = $true
}

$Root = $(Get-Item -Path $Path)
$OldDirectory = $(Join-Path -Path $Root -ChildPath "old")

Remove-Item @ExtraArgs -ErrorAction SilentlyContinue -Path "$LogFile"
New-Item @ExtraArgs -ErrorAction SilentlyContinue -Type Directory -Path "$OldDirectory"
New-Item @ExtraArgs -ErrorAction SilentlyContinue -Type Directory -Path "$LogDirectory"

function Strip-Path {
  param (
    [String]$Root,
    [String]$Target
  )
  $Target.Replace("$Root\", "")
}

function Append-Log {
  param (
    [String]$Operation="info",
    [switch]$StripPathsToRelative=$true,
    [switch]$DuplicateToStdout,
    [String]$Message
  )
  if($StripPathsToRelative) {
    $Message = $(Strip-Path -Root $Root.parent.FullName -Target $Message)
  }
  $Message = "[$(Get-Date -Format "HH:mm:ss.ms")][$Operation] $Message"
  if($DuplicateToStdout) {
    Write-Host $Message
  }
  Out-File @ExtraArgs -Append -FilePath "$LogDirectory\$LogFile" -Encoding UTF8 -InputObject $Message
}

function Get-SearchPath {
  param (
    [String]$Prefix
  )
  $(Join-Path -Path $Prefix -ChildPath "desktop" | Join-Path -ChildPath "*"),`
  $(Join-Path -Path $Prefix -ChildPath "home" | Join-Path -ChildPath "*"),`
  $(Join-Path -Path $Prefix -ChildPath "profiles" | Join-Path -ChildPath "*")
}

foreach($line in Get-Content -Path $NamesFile -Encoding UTF8) {
  $dirsToMove = $(Get-ChildItem -Path $(Get-SearchPath -Prefix $Root.FullName) | `
    Where-Object { $("$line","$line.v2","$line.v6").Contains($_.Name)  })

  foreach($dir in $dirsToMove) {
    $newPath = $(Join-Path -Path $OldDirectory -ChildPath $dir.parent.Name | Join-Path -ChildPath $dir.Name)
    Append-Log -Operation "move" -Message "$dir -> $newPath"
    New-Item @ExtraArgs -ErrorAction SilentlyContinue -Type Directory -Path $(Split-Path -Path $newPath -Parent)
    Move-Item @ExtraArgs -Path $dir -Destination $newPath
  }

  $olderThanDate = (Get-Date).AddMonths(-6)
  $dirsToDelete = $(Get-ChildItem -Path $OldDirectory -Recurse -Directory | Where-Object { $_.LastWriteTime -lt $olderThanDate })
  foreach($dir in $dirsToDelete) {
    Append-Log -Operation "delete" -Message "$dir"
    Remove-Item @ExtraArgs -Recurse -Force
  }
}