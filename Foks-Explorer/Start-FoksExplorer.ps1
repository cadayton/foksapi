#	function Start-FoksExplorer {
	function Confirm-FoksNotLocked {
		$fokscli = "foks kv ls /"
		$r1 = Invoke-Expression $fokscli 2> Start-FoksExplorer.log
		if ($null -eq $r1) {
			$r1 = Get-Content Start-FoksExplorer.log
		}
		if (Test-Path Start-FoksExplorer.log) {
			Remove-Item Start-FoksExplorer.log
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
			return $true
		} else {
			return $true
		}
	}

	Clear-Host
	Write-Host "Checking if FOKS is Locked " -ForegroundColor Yellow
	if (Confirm-FoksNotLocked) {
		Write-Host "Retrieving one-time password for Foks-Explorer" -ForegroundColor Yellow
		# Write-Host 'Executing: ' -NoNewline
		# Write-Host 'Get-FoksKeyValue' -ForegroundColor Yellow
		$kvpath = "/apps/Foks-Explorer/" + $env:USERNAME + "/OTPW"
		Get-FoksKeyValue $kvpath
		try {
			$r1 = Invoke-WebRequest -uri http://localhost:23007
			Write-Host "Foks-Explorer Web Status: " -NoNewline -ForegroundColor Green
			Write-Host $r1.StatusDescription
		}
		catch {
			Write-Host "Starting Foks-Explorer Web Interface: " -NoNewline -ForegroundColor Green
			Write-Host 'foks-explorer.ps1' -ForegroundColor Yellow
			foks-explorer.ps1
		}
	} else {
		Write-Host "Error: unable to unlock FOKS" -ForegroundColor Yellow
	}
#}