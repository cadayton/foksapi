$r1 = Get-Command -Module PSFoks -ErrorAction SilentlyContinue
$r1 = Get-Process -name foks -ErrorAction SilentlyContinue

if (!($null -eq $r1)) {

  $addModal = New-PodeWebModal -Name 'Add FOKS KV Store entry' -Id 'kvmodal_add' -AsForm -Content @(
    New-PodeWebTextbox -Name 'KeyPath'   -Id 'KeyPath_add'   -CssStyle @{ Color = 'Green'; 'font-size' = '20px';} |
      Register-PodeWebEvent -Type Change -ScriptBlock {
        # Show-PodeWebToast -Message "Key field has a change event: $($WebEvent.Data['Key'])"
        # if (!($WebEvent.Data.KeyPath.Length -ge 3 -and $WebEvent.Data.KeyPath.Length -le 32)) {
        #   $Global:KVExplorerErrors++
        #   Show-PodeWebToast -Message "Key field size must be 3 to 32 characters" -Duration 20000 -Title 'Error' -Icon 'alert-circle'
        # }
      }
    New-PodeWebTextbox -Name 'KeyValue'  -Id 'KeyValue_add'  -Type Password -PrependIcon Lock -CssStyle @{ Color = 'Yellow'; 'font-size' = '20px';} |
      Register-PodeWebEvent -Type Change -ScriptBlock {
        # Show-PodeWebToast -Message "KeyValue element has a change event: $($WebEvent.Data['KeyValue'])"
        if ($WebEvent.Data.KeyValue.Length -le 0) {
          $Global:KVExplorerErrors++
          Show-PodeWebToast -Message "KeyValue is a required field" -Duration 20000 -Title 'Error' -Icon 'alert-circle'
        }
      }
  ) -ScriptBlock {  # called after submit button clicked
    Hide-PodeWebModal
    if ($Global:KVExplorerErrors -gt 0) {
      Show-PodeWebToast -Message "Errors in input data so entry not added" -Duration 20000 -Title 'Error' -Icon 'alert-circle'
      $Global:KVExplorerErrors = 0
    } else {
      $keyPath   = $($WebEvent.Data.KeyPath)
      $keyValue  = $($WebEvent.Data.KeyValue)
      $kvobj     = Add-FoksKeyValue $keyPath $keyValue
      #if ($kvObj.gettype().Name -eq 'String') { # error result
      if ($null -ne $kvobj) {
        Show-PodeWebToast -Message $kvObj -Duration 20000 -Title 'Error' -Icon "alert-circle"
      } else {
        Show-PodeWebToast -Message "Entry: $keyPath" -Duration 5000 -Title 'Key Path added' -Icon 'key-change'
      }
    }
  }

  $editModal = New-PodeWebModal -Name 'Edit' -Id 'kvmodal_edit' -AsForm -Content @(
    New-PodeWebTextbox -Name 'KeyPath'       -Id 'KeyPath'       -ReadOnly -CssStyle @{ Color = 'White'; 'font-size' = '20px';}
    New-PodeWebTextbox -Name 'KeyValue'  -Id 'KeyValue'  -Type Password -PrependIcon Lock -CssStyle @{ Color = 'Blue'; 'font-size' = '20px';} |
      Register-PodeWebEvent -Type Change -ScriptBlock {
        # Show-PodeWebToast -Message "Value element has a change event: $($WebEvent.Data['KeyValue'])"
        # if ($WebEvent.Data.KeyValue.Length -le 8) {
        #   $Global:KVExplorerErrors++
        #   Show-PodeWebToast -Message "Key Value size must be 8 or more characters" -Duration 20000
        # }
      }
  ) -ScriptBlock { # called after submit button clicked
    Hide-PodeWebModal
    if ($Global:KVExplorerErrors -gt 0) {
      Show-PodeWebToast -Message "Errors in input data so edit aborted" -Duration 20000
      $Global:KVExplorerErrors = 0
    } else {
      #$entryKeys = $WebEvent.Data.Value
      #($ns,$nsPseudo,$key,$keyPseudo) = $entryKeys.Split(' ')
      $KeyPath = $($WebEvent.Data.KeyPath)
      $entryValue = $($WebEvent.Data.KeyValue)
      $kvObj = Edit-FoksKeyValue $KeyPath $entryValue
      # $kvObj = Set-PSKEntryValue -entryKey $key -entryValue $entryValue -team $null -namespace $ns
      # if ($kvObj.gettype().Name -eq 'String') { # error result
      if ($null -ne $kvObj) {
        Show-PodeWebToast -Message $kvObj -Duration 5000 -Title 'Error' -Icon 'information-outline'
      } else {
        Show-PodeWebToast -Message "Entry: $KeyPath " -Duration 20000 -Title 'Key value updated' -Icon 'key-change'
      }
    }
  }

  $deleteModal = New-PodeWebModal -Name 'Delete' -Id 'kvmodal_delete' -AsForm -Content @(
    New-PodeWebAlert -Type Info -Value 'Are you sure you want to delete?'
    New-PodeWebText -Id 'EntryKey' -CssStyle @{ Color = 'White'; 'font-size' = '20px';}
    New-PodeWebText -Id 'EntryKeyValue' -Style Bold -CssStyle @{ Color = 'Red'; 'font-size' = '20px';}
  ) -ScriptBlock { # called after submit button clicked
    Hide-PodeWebModal
    $KeyPath = $WebEvent.Data.Value
    $r1 = Remove-FoksKeyValue $KeyPath
    Sync-PodeWebTable -Name 'FOKS-Explorer'
    Show-PodeWebToast -Message "$KeyPath $r1" -Duration 5000  -Icon 'trash-can-outline'
  }

  $table = New-PodeWebTable -Name 'FOKS-Explorer' -DataColumn FoksKeyPaths -NoRefresh -Filter -Click -SimpleSort -PageSize 10 -Paginate -CssStyle @{'Font-Size' = '20px'} -ScriptBlock {

    $showBtn   = New-PodeWebButton -Name 'Copy to Clipboard' -Icon 'play-circle' -IconOnly -ScriptBlock {
      $KeyPath = $WebEvent.Data.Value
      #($ns,$nsPseudo,$key,$keyPseudo) = $entryKeys.Split(' ')
      $kvObj = Get-FoksKeyValue $KeyPath
      # $kvObj = Get-PSKEntryValue -entryKey $key -team $null -namespace $ns
      # if ($kvObj.gettype().Name -eq 'String') { # error result
      if ($null -ne $kvObj) {
        Show-PodeWebToast -Message $kvObj -Duration 5000 -Title 'Error' -Icon 'information-outline'
      } else {
        # $value = $kvObj.value
        # Set-Clipboard -Value $value
        Show-PodeWebToast -Message "Value of Key copied to Clipboard" -Duration 5000 -Title 'Clipboard' -Icon 'clipboard-edit-outline'
      }
    }

    $editBtn   = New-PodeWebButton -Name 'Edit' -Icon 'square-edit-outline' -IconOnly -ScriptBlock {
      $KeyPath = $WebEvent.Data.Value
      # ($ns,$nsPseudo,$key,$keyPseudo) = $entryKeys.Split(' ')
      # Show-PodeWebToast -Message "Edit Button not implemented for $conName"
      # $kvObj = Get-PSKEntryValue -entryKey $key -team $null -namespace $ns
      # if ($kvObj.gettype().Name -eq 'String') { # error result
      #   Show-PodeWebToast -Message $kvObj -Duration 5000 -Title 'Error' -Icon 'information-outline'
      # } else {
      #   $value = $kvObj.value
      # }
      $value = "SetRandomValue"
      Show-PodeWebModal -Id 'kvmodal_edit' -DataValue $WebEvent.Data.Value -Actions @( # called before Modal presented
        Update-PodeWebTextbox -Id 'KeyPath'     -Value $KeyPath
        Update-PodeWebTextbox -Id 'KeyValue'    -Value $value
      )
    }

    $deleteBtn = New-PodeWebButton -Name 'Delete' -Icon 'trash-can-outline' -IconOnly -ScriptBlock {
      $KeyPath = $WebEvent.Data.Value
      Show-PodeWebModal -Id 'kvmodal_delete' -DataValue $WebEvent.Data.Value -Actions @( # called before Modal presented
        Update-PodeWebText -Id 'EntryKey' -Value 'KeyPath: '
        Update-PodeWebText -Id 'EntryKeyValue' -Value $KeyPath
      )
    }

    # load KeyPaths
      $selObj = Get-FoksModKeyPaths
    #

    # apply filter if present
      $filter = $WebEvent.Data.Filter
      if (![string]::IsNullOrWhiteSpace($filter)) {
        # $filter = "*$($filter)*"
        # $selObj = @($selObj | Where-Object { ($_.psobject.properties.value -ilike $filter).length -gt 0 })
        $selObj = @($selObj -imatch  $filter)
      }
    #

    # apply paging
      $totalCount = $selObj.Length
      $pageIndex = [int]$WebEvent.Data.PageIndex
      $pageSize = [int]$WebEvent.Data.PageSize
      $selObj = $selObj[(($pageIndex - 1) * $pageSize) .. (($pageIndex * $pageSize) - 1)]
    #

    $selObj | ForEach-Object {
      [ordered]@{
        FoksKeyPaths = $_
        Actions   = @($showBtn,$editBtn,$deleteBtn)
      }
    } | Update-PodeWebTable -Name 'FOKS-Explorer' -PageIndex $pageIndex -TotalItemCount $totalCount

  }

  $table | Add-PodeWebTableButton -Name 'Add Entry' -Icon 'card-plus-outline' -ScriptBlock {
    $Global:KVExplorerErrors = 0
    Show-PodeWebModal -Id 'kvmodal_add' -Actions @( # called before Modal presented
      # $passPhrase = Set-FoksPassPhrase -noprompt
      # if ($passPhrase -notmatch 'Error:') {
      #   Update-PodeWebTextbox -Id 'KeyValue_add' -Value $passPhrase
      # } else {
      #   Show-PodeWebToast -Message "$passPhrase" -Duration 20000  -Title 'Error' -Icon 'alert-circle'
      # }
      Update-PodeWebTextbox -Id 'KeyValue_add' -Value "SetRandomValue"
    )
  }

  $ctTable = New-PodeWebContainer -Content $table

  Add-PodeWebPage -Name FOKS-Explorer -Icon 'table' -Group 'Tools' -Layouts $addModal,$editModal,$deleteModal,$ctTable -ScriptBlock {
    $KeyPath =  $WebEvent.Query['Value']
    if ([string]::IsNullOrWhiteSpace($KeyPath)) {
      return
    }
    New-PodeWebCard -Name "$($KeyPath) Details" -Content @(
      New-PodeWebCodeBlock -Value $KeyPath -NoHighlight -CssStyle @{ Color = 'Yellow'; 'font-size' = '20px';}
    )
  }

} else {
  Add-PodeWebPage -Name FOKS-Explorer -Icon 'table' -Group 'Tools' -Layouts @(
    New-PodeWebHero -Title 'Welcome!' -Message 'This page supports the Foks-Explorer features in the PSFoks module' -Content @(
      New-PodeWebText -Value 'Click on the button for instructions on how to install the PSKeyBase module' -InParagraph -Alignment Center
      New-PodeWebParagraph -Alignment Center -Elements @(
        New-PodeWebButton -Name 'FOKS-Explorer' -Icon Link -Url 'https://cadayton.keybase.pub/PSGallery/Modules/PSKeyBase/PSKeyBase.html' -NewTab
      )
    )
  )
}