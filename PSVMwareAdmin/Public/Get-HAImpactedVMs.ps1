<#
    .SYNOPSIS
		Gets old snapshots

    .DESCRIPTION
		Gets snapshots that are $HowOld or older
		
    .EXAMPLE
        # Get snapshots that are older than 3 days
		Get-OldSnapshots -HowOld 3

        # Get snapshots that are older than 5 days while excluding snapshots for VMs named in $Exclude
        $Exclude = "VM1","VM2"
        Get-OldSnapshots -HowOld 5 -Exclude $Exclude

	.PARAMETER $HowOld
		Mandatory parameter specifying the cluster to execute the host reboots in.
    
    .PARAMETER $Exclude

    .OUTPUTS
		Throws exception if timer exceeds $Timeout or if action fails.

    .NOTES

    .LINK
#>
Function Get-HAImpactedVMs{
	[CmdletBinding()]
	Param([int]
		  [Parameter(Mandatory=$false)]
		  $HowOld = 1)
	
	begin{
        try{
            $Date = Get-Date
            $HAVMrestartold = $HowOld
        }
        catch{
            Write-Error -Message $_.Exception.Message
        }
	}
	process{
        try{
            $Messages = Get-VIEvent -maxsamples 100000 -Start ($Date).AddDays(-$HAVMrestartold) -type warning | Where {$_.FullFormattedMessage -match "restarted"} |select CreatedTime,FullFormattedMessage |sort CreatedTime -Descending
            ($Messages.FullFormattedMessage -replace "( on host )\S{1,}( in cluster DR)","").replace("vSphere HA restarted virtual machine ","")
        }
        catch{
            Write-Error -Message $_.Exception.Message
        }
	}
	end{}
}

