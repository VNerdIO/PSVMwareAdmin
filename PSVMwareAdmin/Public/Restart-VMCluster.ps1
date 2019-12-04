<#
    .SYNOPSIS
		Restarts VMware Cluster hosts one at a time for a FullyAutomated DRS Cluster (fails if DRS isn't fully automated).

    .DESCRIPTION
		Reboots connected hosts one at a time validating that they: 
			1) Enter maintenance mode successfully
			2) Reboots
			3) Host comes back from a reboot
			4) Takes host out of Maintenance once it reconnects
		If the $c.ExtensionData.OverallStatus isn't "green" it will not
		
    .EXAMPLE
		Restart-VMCluster -Cluster "CLUSTER1"

		Restart-VMCluster -Cluster "CLUSTER1" -Timeout 500 -SkipHealthCheck

	.PARAMETER $Cluster
		Mandatory parameter specifying the cluster to execute the host reboots in.

	.PARAMETER $Timeout
		Optional parameter, default is 900 (15 minutes). The defailt wait time is 15 minutes between entering maintenance mode, rebooting, exiting maintenance mode. The timer restarts at each new transition.

	.PARAMETER $SkipHealthCheck
		Optional parameter to skip the basic health check (Cluster -eq green) and proceed with host reboots.
    
    .OUTPUTS
		Throws exception if timer exceeds $Timeout or if action fails.

    .NOTES

    .LINK
#>
Function Restart-VMCluster{
	[CmdletBinding()]
	Param([string]
		  [Parameter(Mandatory=$true)]
		  $Cluster,
		  [int]
		  [Parameter(Mandatory=$false)]
		  $Timeout = 900,
		  [switch]
		  [Parameter(Mandatory=$false)]
		  $SkipHealthCheck)
	
	begin{
		$VMCluster = Get-Cluster -Name "$Cluster"
		$VMCluterStatus = $VMCluster.ExtensionData.OverallStatus
		$VMHosts = $VMCluster | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}

		# Don't proceed unless we can evacuate the hosts
		if($VMCluster.DrsEnabled -ne "True" -AND $VMCluster.DrsAutomationLevel -ne "FullyAutomated"){
			throw "DRS is not enabled or not set to FullyAutomated."
		}

		if($VMCluterStatus -eq "green" -AND !$SkipHealthCheck){
			throw "$($VMCluster.Name) is $VMCluterStatus"
		}
	}
	process{
		Write-Verbose "Healthchecks passed (or skipped), restarting hosts."
		foreach($VMHost IN $VMHosts){
			# Put host in maintenance mode
			try{
				$timer = [Diagnostics.Stopwatch]::StartNew()
				while(($timer.Elapsed.TotalSeconds -lt $Timeout) -AND ((Get-VMHost $VMHost.Name).ConnectionState -ne "Connected")){
					Write-Verbose "Making sure $VMHost is connected."
					Start-Sleep -Seconds 10
				}
				$timer.Stop()
				
				if ($timer.Elapsed.TotalSeconds -ge $Timeout) {
					throw "$VMHost is not connected."
				} else {
					Write-Verbose "Putting $VMHost in maintenance mode."
					Set-VMHost -VMHost $VMHost -State "Maintenance" -Confirm:$false
				}
				}
			catch{
				Write-Error -Message $_.Exception.Message
			}

			# Wait until host is in maintenance mode then reboot
			try{
				$timer = [Diagnostics.Stopwatch]::StartNew()
				while(($timer.Elapsed.TotalSeconds -lt $Timeout) -AND ((Get-VMHost $VMHost.Name).State -ne "Maintenance")){
					Write-Verbose "Waiting for $VMHost to enter maintenance mode."
					Start-Sleep -Seconds 60
				}
				$timer.Stop()
				
				if ($timer.Elapsed.TotalSeconds -ge $Timeout) {
					throw "$VMHost is not entering maintenance mode as expected."
				} else {
					Write-Verbose "Restarting $VMHost"
					Restart-VMHost $VMHost -Evacuate -Confirm:$false
				}
			}
			catch{
				Write-Error -Message $_.Exception.Message
			}

			# Wait until host is disconnected
			try{
				$timer = [Diagnostics.Stopwatch]::StartNew()
				while(($timer.Elapsed.TotalSeconds -lt $Timeout) -AND ((Get-VMHost $VMHost.Name).ConnectionState -ne "NotResponding")){
					Write-Verbose "Waiting for $VMHost to initiate reboot."
					Start-Sleep -Seconds 10
				}
				$timer.Stop()
				
				if ($timer.Elapsed.TotalSeconds -ge $Timeout) {
						throw "$VMHost is not connected."
				} else {
						Write-Verbose "$VMHost is rebooting"
				}
			}
			catch{
				Write-Error -Message $_.Exception.Message
			}

			# Wait until host is connected, take host out of maintenance mode
			try{
				$timer = [Diagnostics.Stopwatch]::StartNew()
				while(($timer.Elapsed.TotalSeconds -lt $Timeout) -AND ((Get-VMHost $VMHost.Name).ConnectionState -ne "Maintenance")){
					Write-Verbose "Waiting for $VMHost to come back from a reboot."
					Start-Sleep -Seconds 60
				}
				$timer.Stop()
				
				if ($timer.Elapsed.TotalSeconds -ge $Timeout) {
						throw "$VMHost is not connected."
				} else {
						Write-Verbose "Connecting $VMHost"
						Set-VMHost -VMHost $VMHost -State "Connected" -Confirm:$false
				}
			}
			catch{
				Write-Error -Message $_.Exception.Message
			}
		}
	}
	end{}
}

