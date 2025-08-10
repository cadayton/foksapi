<#PSScriptInfo

  .VERSION 0.0.2
  .GUID 576c206c-3aee-4212-9841-f3308824b7c6
  .AUTHOR Craig Dayton
  .COMPANYNAME 
  .COPYRIGHT All rights reserved
  .TAGS 
  .LICENSEURI 
  .PROJECTURI
  .ICONURI 
  .EXTERNALMODULEDEPENDENCIES 
  .REQUIREDSCRIPTS 
  .EXTERNALSCRIPTDEPENDENCIES 
  .RELEASENOTES

#>

<#
  .SYNOPSIS
    A PowerShell script to provide a programmatic interface to https://foks.pub/

  .DESCRIPTION
    The primary focus is to provide programmatic access to the key/value store functionality
    implemented by FOKS. Currently, the foks command line interface is being used with the
    thought of migrating to a REST Api.

    Requirements:
      Installation of FOKS.
        https://foks.pub/#download

      Installation of PowerShell Core. 
        https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.5
      
      Testing and development is being done is an OS neutral manner on Linux.

      For Linux, gpaste utility must be installed to get the clipboard functionality to work.
      sudo apt install xclip xsel
      sudo apt install gpaste

      https://fostips.com/find-copy-paste-history-gnome/


    
  .INPUTS
    None.

  .OUTPUTS
    FoksPaths.txt created home directory and removed when FOKS is locked.

  .PARAMETER action
    Available operations that can be performed.

    KeyPaths       - Generate a list of current key/value pairs
    FindPaths      - List keys matching search expression
    Create         - Create a key/value pair
    Get            - Copy the value of a key/value pair to the clipboard
    Update         - Update a key/value pair with a new value
    Remove         - Remove a key/value pair
    Lock           - Require a passphrase to unlock FOKS
    Usage          - Display Server Usage Info
    passPhrase     - Set, Change, or Unlock the passphrase 
    SetRandomValue - Random 20 char passphrase created in the clipboard
    Usage          - Display Server Usage Info


  .PARAMETER $kvpath
    Default path: /
    
    When issuing kv commands, this is the default path.

    When issuing non-kv commands, this parameter depends on the command being issued.
  .Parameter $kvalue
    The value associated with the key.

    If the value has embedded spaces or characters that need to be escaped, then
    the value should be in single quotation marks.
  .Parameter $kvkey
      By default the last item name in the path is the key. If it is desired
      to have a different key name associate with the path, then the '-kvkey'
      can be used.
      
      FoksApi Create -kvpath /web/conventionofstates.com -kvkey password -kvalue mysecret

      FoksApi Create /web/conventionofstates.com/password mysecret

      Both commands will create the same key/value pair.
  .Parameter Info
    To get helpful output to the console add the -Info option to the command.

    This option is for us humans to use.
  .Parameter Raw
    A switch to redirect output sent to the clipboard to be sent to the console.
  .EXAMPLE
    Overview of creating the key/value entry.

    PS> FoksApi Create /myfirst/love dontkissandtell
    Created /myfirst/love/
 
  .EXAMPLE
    Retrieve a value from a key/value entry

    PS> FoksApi Get /myfirst/love

    Copy the value from the clipboard to revel your first love.

  .EXAMPLE
    Update the value of a key/value entry

    PS> FoksApi Update /myfirst/love Traci   
    Updated /myfirst/love/

    Lets update the value with a A 20 character randomized value

    PS> FoksApi Update /myfirst/love SetRandomValue
    Updated /myfirst/love/
  .EXAMPLE
    Once one has a large collection of key/value pairs, you need easy way to
    list your key/value entries.

    PS> FoksApi KeyPaths
    $HOME/FoksPaths.txt new file created

    The file generated is a dump of all the current key/value pairs.

    PS> FoksApi FindPaths
    The dumps all key/value paths to the console

    To search for specific paths
    PS> FoksApi FindPaths myfirst
    /myfirst/love

  .EXAMPLE
    Once one is no longer needing to use the FOKS system, it is wise to lock down
    FOKS with a passPhrase to keep it secure.

    PS> FoksApi Lock

    On each execution of FoksApi, it will check if FOKS is locked and prompt for a
    passphrase to unlock.

    See the readme file in the git repository for how to set a passphrase.

  .LINK
    foks://foks.app/t:foks_apps/foksapi

  .NOTES
    Version Date       Whom       Notes
    ======= ====       ========   =====================================================
    0.0.2   08-10-25   cadayton   Fixed typo in KeyPaths cmd and validates input too.
    0.0.1   08-07-25   cadayton   Initial Release
 

    Copyright (c) 2024 by Craig Dayton

#>

# Parameters 
  [cmdletbinding()]
  Param(
    [Parameter(Position=0,
      Mandatory=$false,
      HelpMessage = "Enter an action to perform",
      ValueFromPipeline=$True)]
      [ValidateNotNullorEmpty()]
      [ValidateLength(1,24)]
      [string]$action = "status",
    [Parameter(Position=1,
      Mandatory=$false,
      HelpMessage = "KV Secret Engine path",
      ValueFromPipeline=$True)]
      [string]$kvpath = "/",
    [Parameter(Position=2,
      Mandatory=$false,
      HelpMessage = "value assigned to new key",
      ValueFromPipeline=$True)]
      [string]$kvalue,
    [Parameter(Position=3,
      Mandatory=$false,
      HelpMessage = "name of key to be assoicated with kvalue",
      ValueFromPipeline=$True)]
      [string]$kvkey,
    [Parameter(Position=4,
      Mandatory=$false,
      HelpMessage = "Show Informative Output",
      ValueFromPipeline=$True)]
      [switch]$info,
    [Parameter(Position=5,
      Mandatory=$false,
      HelpMessage = "Don't use the clipboard",
      ValueFromPipeline=$True)]
      [switch]$Raw
  )

#

function Confirm-FoksInstalled {
  $r1 = Get-Command foks -ErrorAction SilentlyContinue

  if ($null -ne $r1) {
    if ($info) { Write-Host "foks is installed"}
    return $true
  } else {
    Write-Host "Foks is NOT installed"
    Write-Host "See https://foks.pub/#download for installation for installation" -ForegroundColor Green 
    return $false
  }
}

function Confirm-FoksRunning {
  try {
    Get-Process -Name "foks"
  }
  catch {
    Write-Host "Foks Agent " -NoNewline -ForegroundColor Cyan
    Write-Host "is not running" -ForegroundColor Red
    Write-Host "Would you like to start the Foks Agent? " -NoNewline -ForegroundColor Green
    $r1 = Read-Host "(Yes or No)?"
    if ($r1 -match "Y") {
      $fokscli = "foks ctl start"
      if ($info) {
        Write-Host "  Execution command: " -NoNewline
        Write-Host $fokscli -ForegroundColor Green
      }
      Write-Host "  Starting Foks Agent" -ForegroundColor Yellow
      Invoke-Expression $fokscli
      Start-Sleep -Seconds 5
      return $true
    } else {
      return $false
    }
  }

  return $true
}

function Confirm-FoksNotLocked {
  $fokscli = "foks kv ls /"
  $r1 = Invoke-Expression $fokscli 2> r1err.log
  if ($null -eq $r1) {
    $r1 = Get-Content r1err.log
    Remove-Item r1err.log
  }
  if ($r1 -match "Error:") {
    $errCount = 0
    While ($r1 -match "passphrase locked") {
      Write-Host "Foks is locked by a passphrase" -ForegroundColor DarkCyan
      Write-Host "Enter passphrase:"
      $fokscli = "foks passphrase unlock"
      $r1 = Invoke-Expression $fokscli
      $errCount++
      if ($null -eq $r1) { return $true}
      if ($errCount -ge 3) { return $false}
    }
    Write-Host $r1
    return $false
  } else {
    return $true
  }
}

function Confirm-PassPhraseSet {
  $fokscli = "foks secret-key-material info | ConvertFrom-Json"
  if ($info) {
    Write-Host "  Executing: " -NoNewline
    Write-Host $fokscli -ForegroundColor Yellow
  }
  $skmObj = Invoke-Expression $fokscli
  return $skmObj.T
  <#
    const (
          SecretKeyStorageType_PLAINTEXT          SecretKeyStorageType = 0
          SecretKeyStorageType_ENC_PASSPHRASE     SecretKeyStorageType = 1
          SecretKeyStorageType_ENC_MACOS_KEYCHAIN SecretKeyStorageType = 2
          SecretKeyStorageType_ENC_NOISE_FILE     SecretKeyStorageType = 3
          SecretKeyStorageType_ENC_KEYCHAIN       SecretKeyStorageType = 4
    )
  #>
}

function Get-FoksKeyPaths {
  param([string]$keypath)

  $fokscli = "foks kv ls" + " $keypath"
  # Write-Host $fokscli -ForegroundColor Cyan
  $r1 = Invoke-Expression $fokscli 2> x3.log
  # $r2 = Read-Host "Waiting..."
  return $r1
}

function Get-KeyPaths {
  param([Object[]]$kvary,[String]$dopath)

  for ($i = 0; $i -le ($kvary.length - 1); $i++) { 
    $ni = Get-FoksKeyPaths $kvary[$i]
    if ($null -eq $ni) { # $ni - can be a null value
      $Script:totalkeyPaths++
      if ($Info) {
        Write-Host $kvary[$i]
      } elseif (Test-Path $KeyPaths) {
        $kvary[$i] | Add-Content -Path $KeyPaths
      } else {
        $kvary[$i] | Set-Content -Path $KeyPaths
      }
    } else { # ni is an array object
      $ipath = $kvary[$i]
      Get-KeyPaths $ni $ipath 
    }
  }
}

function Show-FoksApiVersion {
  Write-Host "FoksApi (" -NoNewline -ForegroundColor Green
  Write-Host $myVersion -NoNewline -ForegroundColor Yellow
  Write-Host ")" -ForegroundColor Green
  Write-Host ""
}

function Set-Value {
  <#
    .SYNOPSIS
      Generate random keyvalue

    .DESCRIPTION
      This function will generate a weighted, randomized keyvalue. 

      By default the minimum size is 20 characters in length with
      an even distribution of upper, lower, and numeric and special
      characters.

      The minimum size is 20 characters and the maximum size is 76.  The size must be evenly
      divisible by 4.

    .EXAMPLE
      Set-Value

      The generated keyvalue is copied to the clipboard and returned to caller.

    .NOTES
      Author: unknown copied off the internet
        1.0.1  07/08/2021 : cadayton : return generated passphrase
        1.0.0  07/10/2018 : cadayton : Restructure script
    .LINK
      https://cadayton.onrender.com/modules/PSKeyBase/PSKeyBase.html
  #>

  [int]$PWsize = 20 # must be evenly divideable by 4

  [int]$charSet = $PWsize / 4;
  $LWsize = $charSet  # Number of lower case characters
  $UPsize = $charSet  # Number of Upper case characters
  $NMsize = $charSet  # Number of numeric characters
  $SPsize = $charSet  # Number of special characters

  $s1=(-join ('gmxeustahfwkzrvndcyb'.ToCharArray() | Get-Random -Count $LWsize))
  $s2=(-join ('HXULRMTNGSEVPWAFCZKBDY'.ToCharArray() | Get-Random -Count $UPsize))
  $s3=(-join ('7950281346'.ToCharArray() | Get-Random -Count $NMsize))
  $s4=(-join ("><&*!@;+#[]~.:?%".ToCharArray() | Get-Random -Count $SPsize))
  $str=$s1+$s2+$s3+$s4

  $genPW = (-join ($str.ToCharArray() | Get-Random -Count $PWsize))
  $genPW | Set-Clipboard
  return $genPW
}

function Set-KeyValueEntry {
  param([string]$chgtype)

  $fokscli = "foks kv put <kvpath>/<kvkey> <kvalue> --mkdir-p --force"
  if ($info) {
    Write-Host "  Executing: " -NoNewline
    Write-Host $fokscli -ForegroundColor Yellow
  }
  $fokscli = $fokscli.Replace("<kvpath>",$kvpath)
  $fokscli = $fokscli.Replace("<kvkey>",$kvkey)
  $fokscli = $fokscli.Replace("/ "," ")
  if ($kvalue.Contains(" ")) {
    $kvalue = "'" + $kvalue + "'"
  }
  if ($kvalue -eq "SetRandomValue") {
    $kvalue = Set-Value
    $kvalue = "'" + $kvalue + "'"
  }
  $fokscli = $fokscli.Replace("<kvalue>",$kvalue)
  $r1 = Invoke-Expression $fokscli 2> r1err.log
  if ($null -eq $r1) {
    $r1 = Get-Content r1err.log
    Remove-Item r1err.log
  }
  if ($null -eq $r1) {
    Write-Host "$chgtype $kvpath/$kvkey"
  } else {
    Write-Host $r1
  }
}

[string]$myVersion = "0.0.2"
[bool]$Script:ignoreError = $false

$pathChar = [IO.Path]::DirectorySeparatorChar # deal with different OSes
$KeyPaths = $HOME + $pathChar + "FoksPaths.txt"

if ($info) {
  Show-FoksApiVersion
}

# Validate Foks is installed
  if (!(Confirm-FoksInstalled)) { return $null }

# Validate Foks agent is running
  if (!(Confirm-FoksRunning)) { return $null }

# Validate Foks is not locked
  if (!(Confirm-FoksNotLocked)) { return $null }

switch ($action) {
  "KeyPaths" {
    $r1 = Get-FoksKeyPaths $kvpath

    if ($r1 -match "Error:") {
      return $r1
    } else {
      $Script:totalkeyPaths = 0
      if (!($Info)) {
        if (Test-Path $KeyPaths) {
          Remove-Item $KeyPaths
        }
      }
      if ($null -eq $r1) {
        return "Error: Unexpected input returned from Get-FoksKeyPaths"
      }
      Get-KeyPaths $r1 $kvpath
      Remove-Item x3.log
      if ($Info) {
        Write-Host ""
        Write-Host "Total Keys with a value: " -NoNewline -ForegroundColor Green
        Write-Host $Script:totalkeyPaths -ForegroundColor Yellow
      } else {
        Write-Host ""
        Write-Host $KeyPaths -NoNewline -ForegroundColor Green
        Write-Host " new file created" -ForegroundColor Yellow
      }
    }
  }
  "FindPaths" {
    if (Test-Path $KeyPaths) {
      $rslt = Get-Content $KeyPaths
      $r1 = $rslt | Select-String -Pattern $kvpath

      if ([String]::IsNullOrEmpty($r1)) {
        Write-Host "No paths found matching : " -NoNewline -ForegroundColor Yellow
        Write-Host $kvpath -ForegroundColor Green
      } else {
        for ($i=0; $i -le ($r1.length - 1); $i++) {
          Write-Host $r1[$i] -ForegroundColor Green
        }
      }
    } else {
      Write-Host $KeyPaths -NoNewline -ForegroundColor Green
      Write-Host " : Not found" -ForegroundColor Red
      Write-Host "FoksApi KeyPaths " -NoNewline -ForegroundColor Green
      Write-Host " will create the file" -ForegroundColor Yellow
    } 
  }
  "Lock" {
    $fokscli = "foks key lock"
    if (Confirm-PassPhraseSet -eq "1") {
      if ($info) {
        Write-Host "  Executing: " -NoNewline
        Write-Host $fokscli -ForegroundColor Yellow
      }
      $r1 = Invoke-Expression $fokscli
      # if not locked it returns null
      if (Test-Path $KeyPaths) {
        Remove-Item $KeyPaths
      }
    } else {
      Write-Host "  Set a passphrase before locking FOKS"
    }
  }
  "Create" {
    Set-KeyValueEntry "Created"
  }
  "Get" {
    $fokscli = "foks kv get <kvpath>/<kvkey>"
    $fokscli = $fokscli.Replace("<kvpath>",$kvpath)
    $fokscli = $fokscli.Replace("<kvkey>",$kvkey)
    $fokscli = $fokscli.TrimEnd("/")
    $r1 = Invoke-Expression $fokscli 2> r1err.log
    if ($null -eq $r1) {
      $r1 = Get-Content r1err.log
      Remove-Item r1err.log
      Write-Host $r1
      return $null
    }
    if ($info) {
      Write-Host "Value copied to the clipboard" -ForegroundColor Cyan
    }
    $r1 | Set-Clipboard
  }
  "Update" {
    # Verifying entry exists
    $fokscli = "foks kv get <kvpath>/<kvkey>"
    $fokscli = $fokscli.Replace("<kvpath>",$kvpath)
    $fokscli = $fokscli.Replace("<kvkey>",$kvkey)
    $fokscli = $fokscli.TrimEnd("/")
    $r1 = Invoke-Expression $fokscli 2> r1err.log
    if ($null -eq $r1) {
      $r1 = Get-Content r1err.log
      Remove-Item r1err.log
      Write-Host $r1
      return $null
    }

    Set-KeyValueEntry "Updated"
  }
  "Remove" {
    # Deleting the key/value entry
    $fokscli = "foks kv rm <kvpath>/<kvkey>"
    $fokscli = $fokscli.Replace("<kvpath>",$kvpath)
    $fokscli = $fokscli.Replace("<kvkey>",$kvkey)
    $foksCli = $fokscli.TrimEnd("/")
    $r1 = Invoke-Expression $fokscli 2> r1err.log
    if ($null -eq $r1) {
      $r1 = Get-Content r1err.log
      Remove-Item r1err.log
      Write-Host $r1
    }
  }
  "passPhrase" {
    switch ($kvpath) {
      "set" {
        return "Sorry Not Implemented do: foks passphrase set"
      }
      "change" {
        return "Sorry Not Implemented do: foks passphrase change"
      }
      Default {
        return "Each execution will unlock, if necessary"
      }
    }
  }
  "SetRandomValue" {
    $rslt = Set-Value
    if ($Info) {
      Write-Host "  Vault value copied to the clipboard" -ForegroundColor Green
    }
  }
  "Usage" {
    $fokscli = "foks kv get-usage"
    if ($info) {
      Write-Host "  Executing: " -NoNewline
      Write-Host $fokscli -ForegroundColor Yellow
    }
    Invoke-Expression $fokscli
  }
  Default {  
    Show-FoksApiVersion
    Write-Host "SUPPORTED ACTIONS ARE: " -ForegroundColor Cyan
    Write-Host "  FoksApi KeyPaths - " -NoNewline -ForegroundColor Yellow
    Write-Host "Generate a list of current key/value pairs"
    Write-Host "  FoksApi FindPaths <search> - " -NoNewline -ForegroundColor Yellow
    Write-Host "List keys matching search expression"
    Write-Host "  FoksApi Create - " -NoNewline -ForegroundColor Yellow
    Write-Host "Create a key/value pair"
    Write-Host "  FoksApi Get - " -NoNewline -ForegroundColor Yellow
    Write-Host "Copy the value of a key/value pair to the clipboard"
    Write-Host "  FoksApi Update - " -NoNewline -ForegroundColor Yellow
    Write-Host "Update a key/value pair with a new value"
    Write-Host "  FoksApi Remove - " -NoNewline -ForegroundColor Yellow
    Write-Host "Remove a key/value pair"
    Write-Host "  FoksApi Lock - " -NoNewline -ForegroundColor Yellow
    Write-Host "Require a passphrase to unlock FOKS"
    Write-Host "  FoksApi passPhrase - " -NoNewline -ForegroundColor Yellow
    Write-Host "Set, Change, or Unlock the passphrase "
    Write-Host "  FoksApi SetRandomValue - " -NoNewline -ForegroundColor Yellow
    Write-Host "Random 20 char passphrase created in the clipboard"
    Write-Host "  FoksApi Usage - " -NoNewline -ForegroundColor Yellow
    Write-Host "Display Server Usage Info"
  }
}