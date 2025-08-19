Import-Module Pode -Global -MaximumVersion 2.99.99 -Force
Import-Module Pode.Web -Global -Force

$r1 = Get-Command -Module PSKeyBase

Start-PodeServer -ScriptBlock {

  [int]$Global:CryptoInfoLoaded  = 0
  [int]$Global:HomePageLoaded  = 0
  [int]$Global:psConsoleErrors = 0
  [int]$Global:KVExplorerErrors = 0
  [int]$Global:webCfgErrors = 0

  # functions

    function Import-webConfig {
      param([string]$node)
      $nodes = "//" + $node
      ($basePath,$dirChar) = Get-WebServerPath
      $cfgFile = $basePath + "data" + $dirChar + "FOKS-Explorer.xml"
      $cfgDB = new-object "System.Xml.XmlDocument"
      $cfgDB.Load($cfgFile)
      $cfgDB = $cfgDB.SelectNodes("$nodes")
      return $cfgDB
    }

    function Get-PlatformType {

      if ($IsWindows) {$Platform = "Win"} elseif ($IsLinux) { $Platform = "Linux"} elseif ($IsMacOS) {Platform = "MacOS"}

      return $Platform
    }

    function Get-WebServerPath {
      $basePath = Join-Path (Get-PodeServerPath) ''
      $dirChar = [IO.Path]::DirectorySeparatorChar
      return $basePath,$dirChar
    }

    function Test-Image {
      param([string]$dest,[string]$source)
      $r2 = $dest
      $PodeWebPath = $r2.Replace("Pode.Web.psm1","")
      ($basePath,$dirChar) = Get-WebServerPath
      $PodeWebImages = $PodeWebPath + 'Templates' + $dirChar + 'Public' + $dirChar + 'images'
      $PodeServerImages = $basePath + $dirchar + 'images'
      $f1 = $source
      $f2 = $f1.Replace('/pode.web/images/',"")
      $f3 = $PodeWebImages + $dirChar + $f2
      if (!(Test-Path $f3)) {
        $f4 = $PodeServerImages + $dirChar + $f2
        Copy-Item -Path $f4 -Destination $PodeWebImages -force
      }
    }

  #

  # Verify Pode.Web installed
    $r1 = Get-Module -Name Pode.Web
    if ([string]::IsNullOrEmpty($r1)) {
      return "  ERROR: Pode.Web is not installed"
    }
  #

  # add a simple endpoint
    $cfgDB = Import-webConfig "PodeWebCfg"
    Add-PodeEndpoint -Address $cfgDB.address -Port $cfgDB.port -Protocol $cfgDB.protocol
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging
  #

  # Add middleware verification
    # Add-PodeMiddleware -Name 'KeybaseOnly' -ScriptBlock {
    #     # if the user agent is not keybase, deny access
    #     if ($WebEvent.Request.UserAgent -ne 'keybase') {
    #         Write-Host $WebEvent.Request.UserAgent
    #         # forbidden
    #         Set-PodeResponseStatus -Code 403 -Description "Invalid UserAgent"
    #         # stop processing
    #         return $false
    #     }

    #     # create a new key on the event for the next middleware/route
    #     $WebEvent.Agent = $WebEvent.Request.UserAgent

    #     # continue processing other middleware
    #     return $true
    # }
  #

  # enable sessions and authentication
    if ($cfgDB.authenticate -ne "0") {
      [int]$myDuration = $cfgDB.duration
      $myDuration = $myDuration * 60
      Enable-PodeSessionMiddleware -Secret 'schwifty' -Duration $myDuration -Extend   # -Duration (10 * 60) = Ten minutes
    }
  #

  # set images and icons
    Test-Image $r1.Path $cfgDB.logo
    Test-Image $r1.Path $cfgDB.logo1
    Test-Image $r1.Path $cfgDB.background

    $myLogoFile = $cfgDB.logo
    $myLogoFile1 = $cfgDB.logo1
    $myBackGroundFile = $cfgDB.background
  #

  switch ($cfgDB.authenticate) {
    "1" { # KeyBase
      New-PodeAuthScheme -Form | Add-PodeAuth -Name Keybase -SuccessUseOrigin -ScriptBlock {
        param($username, $userpw)

        ($emsg,$smsg) = $userpw.Split(":")
        keybase verify -m $smsg -S $username --no-output *> dummy.log
        $r1 = Get-Content dummy.log

        if ($r1 -match "Verification error:") {
          return @{ Message = 'Invalid message signature' }
        }

        $p1 = keybase decrypt -m $emsg
        ($eKey,$nsKey,$tmKey) = Get-KVKeyValue
        # $pskObj = Get-PSKEntryValue -entryKey Pode9001 -team "cadayton,cadayton" -namespace Web
        $pskObj = Get-PSKEntryValue -entryKey $eKey -team $tmKey -namespace $nsKey
        $p2 = $pskObj.value

        if ($p1 -ne $p2) {
          return @{ Message = 'Invalid password entered' }
        } else {
          $newpw = Set-PSKPassPhrase -PWsize 40 -noprompt
          $r1 = Set-PSKEntryValue -entryKey $eKey -entryValue $newpw -namespace $nsKey -team $tmKey
        }

        $j2 = keybase id -j $username
        $j2 | Set-Content keybase.json
        $r1 = Get-Content keybase.json | ConvertFrom-Json
        $sigID = $r1.identifyKey.sigID

        $cfgDB = Import-webConfig "PodeWebCfg"
        $myAvatarFile =  $cfgDB.logo

        # password msg is signed by $username
        return @{
          User = @{
            ID = $sigID
            Name = $username
            Type = 'Human'
            Groups = @('Developer')
            AvatarUrl = $myAvatarFile
          }
        }
      }
    }
    "2" { # FOKS
       New-PodeAuthScheme -Form | Add-PodeAuth -Name Foks -SuccessUseOrigin -ScriptBlock {
        param($username, $userpw)

        $kvpath = "/apps/Foks-Explorer/" + $username + "/OTPW"
		    $rslt = Get-FoksKeyValue $kvpath -noprompt

        if ($rslt -eq $userpw) {
          $r1 = Edit-FoksKeyValue $kvpath SetRandomValue
          return @{
            User = @{
              ID = $r1
              Name = $username
              Type = 'Human'
              Groups = @('Developer')
              AvatarUrl = $myAvatarFile
            }
          }
        } else {
          return @{ Message = 'Invalid account or password entered' }
        }
       }
    }
    "3" { # HashiCorp Vault
      
    }
    Default { # None

    }
  }

  # set the use of templates, and set a login page

    Use-PodeWebTemplates -Title $cfgDB.title -Logo $myLogoFile -Theme Dark

    switch ($cfgDB.authenticate) {
      "1" {
        Set-PodeWebLoginPage -Authentication Keybase -Logo $myLogoFile1 -BackgroundImage $myBackGroundFile
      }
      "2" {
        Set-PodeWebLoginPage -Authentication FOKS -Logo $myLogoFile1 -BackgroundImage $myBackGroundFile
      }
      "3" {
        Set-PodeWebLoginPage -Authentication Vault -Logo $myLogoFile1 -BackgroundImage $myBackGroundFile
      }
      Default {

      }
    }

  #

  $div1 = New-PodeWebNavDivider

  $navDropdown = New-PodeWebNavDropdown -Name 'Foks' -Icon 'apps-box' -Items @(
    New-PodeWebNavLink -Name 'Foks Home' -Url 'https://foks.pub' -Icon 'search-web' -NewTab
    New-PodeWebNavDivider
    New-PodeWebNavDropdown -Name 'Foks References' -Icon 'powershell' -Items @(
        New-PodeWebNavLink -Name 'Foks.app' -Url 'https://w.foks.app' -Icon 'cloud-outline' -NewTab
        New-PodeWebNavLink -Name 'Git client-server' -Url 'https://github.com/foks-proj/go-foks' -Icon 'server-minus' -NewTab
        New-PodeWebNavLink -Name 'Foks Book' -Url 'https://foks-book.jms1.info/' -Icon 'book-open-variant' -NewTab
    )
  ) 

  $devReferences = New-PodeWebNavDropdown -Name 'Pode' -Icon 'file-document-multiple' -Items @(
    New-PodeWebNavLink -Name 'Pode Route Tutorials'     -Url 'https://badgerati.github.io/Pode/Tutorials/Routes/Examples/WebPages/' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'GitHub Pode.Web'          -Url 'https://github.com/Badgerati/Pode.Web' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Pode.Web v0.8.0'          -Url 'https://github.com/Badgerati/Pode.Web/releases/tag/v0.8.0' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Pode.Web Home'            -Url 'https://badgerati.github.io/Pode.Web/' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Pode.Web Basic Tutorials' -Url 'https://badgerati.github.io/Pode.Web/Tutorials/Basics/' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Pode.Web Examples'        -Url 'https://github.com/Badgerati/Pode.Web/tree/71d14aa2f11efa85f9cf3cf2f2f128177708a441/examples' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Gitter Pode'              -Url 'https://gitter.im/Badgerati/Pode#' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Discord Pode'             -Url 'https://discord.com/channels/887398607727255642/887400735099207680' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'Material Icons'           -Url 'https://pictogrammers.github.io/@mdi/font/5.4.55/' -Icon 'search-web' -NewTab
    New-PodeWebNavLink -Name 'CSS Tutorial'             -Url 'https://www.w3schools.com/css/default.asp' -Icon 'search-web' -NewTab
  )

  $donateReferences = New-PodeWebNavDropdown -Name 'Donate' -Icon 'gas-station-outline' -Items @(
    New-PodeWebNavLink -Name 'Lightning'       -Url 'https://getalby.com/p/cadayton' -Icon 'bitcoin' -NewTab
    New-PodeWebNavLink -Name 'BTCPay'          -Url 'https://btcpayserver.sytes.net' -Icon 'bitcoin' -NewTab
    New-PodeWebNavLink -Name '$PayPal'         -Url 'https://www.paypal.com/paypalme/CraigDayton' -Icon 'cash-usd' -NewTab
  )

  Set-PodeWebNavDefault -Items $navDropdown, $div1, $devReferences, $div1, $donateReferences
  
  $WinHome = New-PodeWebContainer -Content @(
    New-PodeWebIFrame -Name 'FOKS' -Url 'https://foks.pub/' -Title 'foks.pub' 
  )    

  if ($IsWindows) {
    $myTitle = $env:COMPUTERNAME
  } else {
    $myTitle = hostname
  }

  $myVersion = "0.0.2"

  $myTitle = "Demo of FOKS-Explorer on " + $myTitle + " ($myVersion)"

  Set-PodeWebHomePage -Title $myTitle -NoAuth -Layouts $WinHome -PassThru |
  Register-PodeWebPageEvent -Type Load -NoAuth -ScriptBlock {
    $Global:HomePageLoaded  = 1
  }

  Use-PodeWebPages
}