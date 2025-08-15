# Non-Exported Functions

  function Convert-Size {
    [cmdletbinding()]            
    param(            
        [validateset("Bytes","KB","MB","GB","TB")]            
        [string]$From,            
        [validateset("Bytes","KB","MB","GB","TB")]            
        [string]$To,            
        [Parameter(Mandatory=$true)]            
        [double]$Value,            
        [int]$Precision = 4
    )            
    switch($From) {            
        "Bytes" {$value = $Value }            
        "KB" {$value = $Value * 1024 }            
        "MB" {$value = $Value * 1024 * 1024}            
        "GB" {$value = $Value * 1024 * 1024 * 1024}            
        "TB" {$value = $Value * 1024 * 1024 * 1024 * 1024}            
    }            
                
    switch ($To) {            
        "Bytes" {return $value}            
        "KB" {$Value = $Value/1KB}            
        "MB" {$Value = $Value/1MB}            
        "GB" {$Value = $Value/1GB}            
        "TB" {$Value = $Value/1TB}            
                
    }            
                
    return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)

  }

  function Get-FoksRootPaths {
    param([string]$keypath)

    $fokscli = "foks kv ls" + " $keypath"
    $r1 = Invoke-Expression $fokscli 2> foksmod.log
    return $r1
  }

  function Get-ModKeyPaths {
    param([Object[]]$kvary,[String]$dopath)

    for ($i = 0; $i -le ($kvary.length - 1); $i++) { 
      $ni = Get-FoksRootPaths $kvary[$i]
      if ($null -eq $ni) { # $ni - can be a null value
        $script:allPaths += $kvary[$i]
      } else { # ni is an array object
        $ipath = $kvary[$i]
        Get-ModKeyPaths $ni $ipath 
      }
    }
  }

  function Test-FoksKeyValue {
    param([string]$keypath)

    [bool]$findrslt = $false

    $fokscli = "foks kv get" + " $keypath"
    $r1 = Invoke-Expression $fokscli 2> foksmod.log
    if ($null -ne $r1) {
      $findrslt = $true
    }
    if (Test-Path foksmod.log) {
      Remove-Item foksmod.log
    }
    return $findrslt
  }

  function Set-FoksKeyValue {

    # Set-FoksKeyValue

      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$true,
          HelpMessage = "Enter Key/Value path",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvPath,
        [Parameter(Position=1,
          Mandatory=$true,
          HelpMessage = "Enter Value",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvalue,
        [Parameter(Position=2,
          Mandatory=$true,
          HelpMessage = "Create or Update",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$updatetype
      )

    #

    $fokscli = "foks kv put  $kvpath $kvalue --mkdir-p --force"

    $r1 = Invoke-Expression $fokscli 2> foksmod.log
    if (Test-Path foksmod.log) {
      $r1 = Get-Content foksmod.log
      Remove-Item foksmod.log
    }
    return $r1

  }

#

# Initialize

  $Script:returnText = $null

  if ($PSVersionTable.PSVersion.Major -lt 7) {
    return "  Sorry only supporting PowerShell 7 or higher"
  }

  $pathChar = [IO.Path]::DirectorySeparatorChar # deal with different OSes

#

# Foks Key Value Functions

  <#
    .SYNOPSIS
      Get the current key/value paths in Foks

    .DESCRIPTION
      Get the current key/value paths in Foks

    .OUTPUTS
      Return string array object of key/value paths.

    .EXAMPLE
      $rslt = Get-FoksKeyPaths

      Uses the default starting path of "/" and
      $rslt is a string array containing one path per index.
      or
      $rslt is a string containing the error result.

    .EXAMPLE
      $rslt = Get-FoksKeyPaths /bookmarks/dev
      
      Non-default starting path is referenced.
      
  #>
  function Get-FoksModKeyPaths {

    # Get-FoksKeyPaths Params

      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$false,
          HelpMessage = "root KV path",
          ValueFromPipeline)]
        [string]$kvpath = "/"
      )
    #

    $script:allPaths = @()

    $r1 = Get-FoksRootPaths $kvpath

    if ($r1 -match "Error:") {
      return $r1
    }
      
    if ($null -eq $r1) {
      return "Error: Unexpected input returned from Get-FoksRootPaths"
    }

    Get-ModKeyPaths $r1 $kvpath

    if (Test-Path foksmod.log) {
      Remove-Item foksmod.log
    }

    return $script:allPaths

  }
  Export-ModuleMember -Function Get-FoksModKeyPaths

  <#
    .SYNOPSIS
      Retrieves Foks key/value path and copies the value to the clipboard. 
    .DESCRIPTION
      Retrieves Foks key/value path and copies the value to the clipboard.
      
    .PARAMETER kvpath
      Foks key/value path. This parameter is required.

    .OUTPUTS
      On success, the value of the key/value path is copied to the clipboard.

      On failure, returns a string containing the error message.
      
    .EXAMPLE
      $rslt = Get-FoksKeyValue /web/mywebsite
        
  #>
  function Get-FoksKeyValue {

    # Get-FoksKeyValue Params

      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$true,
          HelpMessage = "Enter Key/value path",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvpath
      )

    #

    $fokscli = "foks kv get" + " $kvpath"
    $r1 = Invoke-Expression $fokscli 2> foksmod.log
    if ($null -ne $r1) { # got the value
      if (Test-Path foksmod.log) {
        Remove-Item foksmod.log
      }
      Set-Clipboard -Value $r1
      return $null
    } else { # error happened
      if (Test-Path foksmod.log) {
        $r1 = Get-Content foksmod.log
        Remove-Item foksmod.log
      }
      return $r1
    } 
  }
  Export-ModuleMember -Function Get-FoksKeyValue

  <#
    .SYNOPSIS
      Creates a new FOKS key/value instance.

    .DESCRIPTION
      Creates a new FOKS key/value instance.
      
    .PARAMETER kvpath
      The key/value path to be created where the last item in
      the path is the key. This parameter is required.

      If "/web/mywebsite/url" is passed then "url" is the key
      that will be associated with the value passed.

    .PARAMETER kvalue
      The string value associated with the $kvpath. This parameter is required.

      If kvalue is "SetRandomValue", then a random 20 char string will be assigned
      to the value.

    .OUTPUTS
      returns $null on success or "Error: xxx" on failure

    .EXAMPLE
      Add-FoksKeyValue /webapp/robot-api/password SetRandomValue

      A new key "password" at the path of "/webapp/robot-api" is created and
      assigned a random 20 char string value.

  #>
  function Add-FoksKeyValue {

    # Add-FoksKeyValue

      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$true,
          HelpMessage = "Enter Key/Value path",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvPath,
        [Parameter(Position=1,
          Mandatory=$true,
          HelpMessage = "Enter Value",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvalue
      )

    #

    if (Test-FoksKeyValue $kvpath) {
      return "Error: KeyValue entry already exists"
    }

    if ($kvalue -eq "SetRandomValue") {
      $kvalue = Set-FoksPassPhrase -noprompt
      $kvalue = "'" + $kvalue + "'"
    } else {
      if ($kvalue.Contains(" ")) {
        $kvalue = "'" + $kvalue + "'"
      }
    }

    $r1 = Set-FoksKeyValue $kvpath $kvalue "Create"

    return $r1

  }
  Export-ModuleMember -Function Add-FoksKeyValue

  <#
    .SYNOPSIS
      Updates an existing FOKS key/value instance.

    .DESCRIPTION
      Updates an existing FOKS key/value instance.
      
    .PARAMETER kvpath
      The key/value path to be created where the last item in
      the path is the key. This parameter is required.

      If "/web/mywebsite/url" is passed then "url" is the key
      that will be associated with the value passed.

    .PARAMETER kvalue
      The string value associated with the $kvpath. This parameter is required.

      If kvalue is "SetRandomValue", then a random 20 char string will be assigned
      to the value.

    .OUTPUTS
      returns $null on success or "Error: xxx" on failure

    .EXAMPLE
      Edit-FoksKeyValue /webapp/robot-api/password SetRandomValue

      The existing key "password" at the path of "/webapp/robot-api" is updated with
      a random 20 char string value.

  #>
  function Edit-FoksKeyValue {

    # Edit-FoksKeyValue

      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$true,
          HelpMessage = "Enter Key/Value path",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvPath,
        [Parameter(Position=1,
          Mandatory=$true,
          HelpMessage = "Enter Value",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvalue
      )

    #

    if (!(Test-FoksKeyValue $kvpath)) {
      return "Error: $kvpath not found"
    }

    if ($kvalue -eq "SetRandomValue") {
      $kvalue = Set-FoksPassPhrase -noprompt
      $kvalue = "'" + $kvalue + "'"
    } else {
      if ($kvalue.Contains(" ")) {
        $kvalue = "'" + $kvalue + "'"
      }
    }

    $r1 = Set-FoksKeyValue $kvpath $kvalue "Update"

    return $r1
  }
  Export-ModuleMember -Function Edit-FoksKeyValue

  <#
    .SYNOPSIS
      Removes a key from the FOKS kv store.

    .DESCRIPTION
      Removes a key from the FOKS kv store.
      
    .PARAMETER kvpath
      The key/value path to the key to be removed where the last item in
      the path is the key. This parameter is required.

      If "/web/mywebsite/url" is passed then "url" is the key
      that will removed.

    .OUTPUTS
      returns $null on success or "Error: xxx" on failure
      
    .EXAMPLE
      Remove-FoksKeyValue /web/mywebsite/url

      Assuming there are no errors, then the key "url" at the path of "/web/mywebsite"
      is deleted.
        
  #>
  function Remove-FoksKeyValue {

    # Remove-FoksKeyValue

      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$true,
          HelpMessage = "Enter KeyValue path",
          ValueFromPipeline)]
          [ValidateNotNullorEmpty()]
        [string]$kvpath
      )

    #

    if (!(Test-FoksKeyValue $kvpath)) {
      return "Error: $kvpath not found"
    }

    $fokscli = "foks kv rm " + " $kvpath"

    $r1 = Invoke-Expression $fokscli 2> foksmod.log

    if (Test-Path foksmod.log) {
      $r1 = Get-Content foksmod.log
      Remove-Item foksmod.log
    }
    return $r1
  }
  Export-ModuleMember -Function Remove-FoksKeyValue

#

# Non-Foks Functions
  function Set-FoksPassPhrase {
    <#
      .SYNOPSIS
        Generate random passphrase

      .DESCRIPTION
        This script will generate a weighted, randomized passphrase. 

        By default the minimum password size is 20 characters in length with
        an even distribution of upper, lower, and numeric and special
        characters.

        The minimum size is 20 characters and the maximum size is 76.  The size must be evenly
        divisible by 4.
      .PARAMETER PWsize/sz
        Desired number of characters in the passphrase
      .EXAMPLE
        Set-FoksPassPhrase

        The generated passphrase is copied to the clipboard.
      .EXAMPLE
        Set-FoksPassPhrase -noprompt

        The generated passphrase is returned to the caller.
      .EXAMPLE
        $token = Set-FoksPassPhrase -sz 76 -noprompt

        $token contains 76 random characters.
      .NOTES
        Author: unknown copied off the internet
          1.0.1  07/08/2021 : cadayton : return generated passphrase
          1.0.0  07/10/2018 : cadayton : Restructure script
      .LINK
        https://cadayton.onrender.com/modules/PSKeyBase/PSKeyBase.html
    #>
    
    # Set-FoksPassPhrase Params
      [cmdletbinding()]
      Param(
        [Parameter(Position=0,
          Mandatory=$false,
          HelpMessage = "token Length",
          ValueFromPipeline=$True)]
          [alias("sz","pwlength")]
          [ValidateRange(1,76)]
          [int]$PWsize = 20,
        [Parameter(Position=2)]
          [switch]$noprompt
      )
    #

    if (!($noprompt)) {
      Clear-Host;
      Write-Host "Generating randomized password" -ForegroundColor Blue
      Read-Host "Press Enter to continue"  | Out-Null
    }

    if (($PWsize % 4) -ne 0 -or $PWsize -lt 20 -or $PWsize -gt 1024) {
      $err = "Error: Token size must be 20 to 1024 characters and evenly divisible by 4."
      if (!($noprompt)) {
        Write-Host $err -ForegroundColor Yellow
        return $err
      } else {
        return $err
      }
    } else {
      [int]$charSet = $PWsize / 4;
      $LWsize = $charSet  # Number of lower case characters
      $UPsize = $charSet  # Number of Upper case characters
      $NMsize = $charSet  # Number of numeric characters
      $SPsize = $charSet  # Number of special characters

      $s1=(-join ('gmxeustahfwkzrvndcyb'.ToCharArray() | Get-Random -Count $LWsize))
      $s2=(-join ('HXULRMTNGSEVPWAFCZKBDY'.ToCharArray() | Get-Random -Count $UPsize))
      $s3=(-join ('7950281346'.ToCharArray() | Get-Random -Count $NMsize))
      $s4=(-join ("{|}/>(<&*!@;+#[]\~.):?%$".ToCharArray() | Get-Random -Count $SPsize))
      $str=$s1+$s2+$s3+$s4
      if (!($noprompt)) {
        -join ($str.ToCharArray() | Get-Random -Count $PWsize) | Set-Clipboard
        Write-Host "The password has been copied to the clipboard." -ForegroundColor Magenta
      } else {
        $genPW = -join ($str.ToCharArray() | Get-Random -Count $PWsize);
        return $genPW
      }
    }
  }
  Export-ModuleMember -Function Set-FoksPassPhrase

  function Clear-FoksConsole {
    <#
      .SYNOPSIS
        Remove PSReadline console log and exit console session.
      .DESCRIPTION
        PSReadline console log is removed and console session is exited.
      .PARAMETER prompt
        Specify this switch to allow console output to be generated.
      .PARAMETER noExit
        Specify this switch to not exit the current session
      .EXAMPLE
        KB-Bye -prompt

        The PSReadLine console history file is removed and the
        current session is exited.
      .EXAMPLE
        KB-Bye -prompt -noExit

        Same as prior example but the session is not exited.
    #>

    param([switch]$prompt,[switch]$noExit)

    $conHistory = (Get-PSReadlineOption).HistorySavePath
    if (Test-Path -Path $conHistory) {
      if ($prompt) { Write-Host "Removing $conHistory" }
      Remove-Item -Path $conHistory;
    } else {
      if ($prompt) { Write-Host "Notfound $conHistory" } else { return "Notfound $conHistory" }
    }
    if (!($noExit)) { 
      if ($prompt) {
        Write-Host "  Existing in 3 seconds" -ForegroundColor Green
        Start-Sleep -Seconds 3
      }
      exit
    }
  }
  New-Alias -Name Foks-Bye -Value Clear-FoksConsole
  Export-ModuleMember -Function Clear-FoksConsole -Alias Foks-Bye

  function Get-FoksConsole {
    <#
      .SYNOPSIS
        Retrieve the PSReadline console log records.
      .DESCRIPTION
        Retrieve the PSReadline console log records.
      .PARAMETER prompt
        Console log records are displayed on the console.
      .EXAMPLE
        KB-ConsoleLog -prompt

        The PSReadLine console history file is displayed on the console.
      .EXAMPLE
        PS1> $r1 = KB-ConsoleLog

        Same as prior example but console log date is returned to the caller.
    #>

    param([switch]$prompt)

    $conHistory = (Get-PSReadlineOption).HistorySavePath
    if (Test-Path -Path $conHistory) {
      if ($prompt) {
        Write-Host "  Retrieving console history from " -NoNewline -ForegroundColor Green
        Write-Host $conHistory -ForegroundColor Yellow
      }
      $r1 = Get-Content -Path $conHistory -Raw
      if ($prompt) { Write-Host $r1 } else { return $r1 }
    } elseif ($prompt) {
      Write-Host "  NOTFOUND " -NoNewline -ForegroundColor Red
      Write-Host $conHistory
    } else { return "Notfound $conHistory" }
  }
  New-Alias -Name Foks-ConsoleLog -Value Get-FoksConsole
  Export-ModuleMember -Function Get-FoksConsole -Alias Foks-ConsoleLog
#