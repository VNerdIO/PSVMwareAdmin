<#
    .SYNOPSIS

    .DESCRIPTION
		
    .EXAMPLE

    .PARAMETER $OutputDir

    .OUTPUTS

    .NOTES

    .LINK
#>
Function New-RightsizeReport{
	[CmdletBinding()]
	Param([string]
          [Parameter(Mandatory=$true)]
          $OutputDir,
          [string]
          [Parameter(Mandatory=$false)]
		  $Cluster,
          [string]
          [Parameter(Mandatory=$false)]
		  $VM)
	
	begin{
        # Confirm connection to VCenter

        # Confirm Cluster ot VM are specified
        if(!$Cluster -AND !$VM){
            Write-Error "Please specify a Cluster or VM to evaluate"
        }
	}
	process{
        # If a cluster is specified process all VMs on that cluster
        if($Cluster){

        } elseif ($VM){

        }
	}
	end{}
}

