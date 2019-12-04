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
Function Get-OldSnapshots{
	[CmdletBinding()]
	Param([int]
		  [Parameter(Mandatory=$true)]
		  $HowOld,
          [string[]]
          [Parameter(Mandatory=$false)]
		  $Exclude)
	
	begin{
        try{
            $Snapshots = Get-VM | Get-Snapshot | Where-Object {$_.Created -lt (Get-Date).AddDays(-$HowOld)}
        }
        catch{
            Write-Error -Message $_.Exception.Message
        }
	}
	process{
        if($Exclude){
            $Snapshots = $Snapshots | Where-Object {$Exclude -notcontains $_.VM}
        }
        
        $Snapshots
	}
	end{}
}

