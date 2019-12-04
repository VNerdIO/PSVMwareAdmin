#Remove-Module -Name $Env:BHProjectName -Force -ErrorAction "SilentlyContinue"
#Import-Module -Name $Env:BHModulePath -Force

InModuleScope PSVMwareAdmin {

	Describe "PSVMwareAdmin Module - Restart-VMCluster" -Tag "Low" {
        Mock Get-Cluster { }
        Function Get-Cluster { }

        Mock Get-VMHost { }
        Function Get-VMHost { [CmdletBinding()] param([Parameter(ValueFromPipeline = $true)] $Name) }

        Mock Set-VMHost { }
        Function Set-VMHost { }

        Mock Restart-VMHost { }
        Function Restart-VMHost { }
    }

    $Params = @{
        'Cluster' = "FAKECLUSTER1235"
    }

    Context "Verifying the function succeeds" {

        Mock Get-Cluster { 
            [pscustomobject]@{
                "Name"                  = "CLUSTER-06";
                "DrsEnabled"            = "True";
                "DrsAutomationLevel"    = "FullyAutomated";
            }
        }
        Mock Get-VMHost { 
            [pscustomobject]@{
                "Name"              = "host1.vmware.local"
                "ConnectionState"   = "Connected"
                "PowerState"        = "PoweredOn"
                "State"             = "Connected"
            }
        }
        Mock Set-VMHost { Write-Output $true }
        Mock Restart-VMHost { Write-Output $true }

        It "The function succeeds" {
            Restart-VMCluster @Params | Should Be $true
        }

    }

}