Function Get-VMVirtualDiskPerformance{
	param($Server,$DaysAgo,[switch]$WorkHours)
	
	$DaysAgo = if($DaysAgo -gt 0){ $DaysAgo * -1} else { $DaysAgo }
	$vm = Get-VM "$Server"
	$Report = @()
	$Disks = $vm | Get-HardDisk
	$DiskMatrix = $Disks | Select-Object @{n="id";e={"scsi"+($_.ExtensionData.ControllerKey -replace "100","") +":"+ $_.ExtensionData.UnitNumber}},Name,Filename,@{n="CapacityGB";e={[math]::round($_.CapacityGB,1)}}
	$Paths = $vm.Guest.Disks | Select-Object Path,@{n="CapacityGB";e={[math]::round($_.CapacityGB)}},@{n="FreeSpaceGB";e={[math]::round($_.FreeSpaceGB)}}

	if($WorkHours){
		$AvgReadLatency = $vm | Get-Stat -Stat virtualDisk.totalReadLatency.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5 | Where-Object {(Get-Date($_.Timestamp) -Format HH) -ge 8 -OR (Get-Date($_.Timestamp) -Format HH) -le 17}
		$AvgWriteLatency = $vm | Get-Stat -Stat virtualDisk.totalWriteLatency.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5 | Where-Object {(Get-Date($_.Timestamp) -Format HH) -ge 8 -OR (Get-Date($_.Timestamp) -Format HH) -le 17}
		$AvgRead = $vm | Get-Stat -Stat virtualDisk.read.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5 | Where-Object {(Get-Date($_.Timestamp) -Format HH) -ge 8 -OR (Get-Date($_.Timestamp) -Format HH) -le 17}
		$AvgWrite = $vm | Get-Stat -Stat virtualDisk.write.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5 | Where-Object {(Get-Date($_.Timestamp) -Format HH) -ge 8 -OR (Get-Date($_.Timestamp) -Format HH) -le 17}
	} else {
		$AvgReadLatency = $vm | Get-Stat -Stat virtualDisk.totalReadLatency.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5
		$AvgWriteLatency = $vm | Get-Stat -Stat virtualDisk.totalWriteLatency.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5
		$AvgRead = $vm | Get-Stat -Stat virtualDisk.read.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5
		$AvgWrite = $vm | Get-Stat -Stat virtualDisk.write.average -Start (Get-Date).AddDays($DaysAgo) -IntervalMins 5
	}

	$Instances = ($AvgReadLatency | Select-Object -Unique Instance).Instance

	foreach($Instance IN $Instances){
		$arl = [math]::round(($AvgReadLatency | Where-Object {$_.Instance -eq "$Instance"} | Where-Object {$_.Value -lt 1000000} | Measure-Object -Average Value).Average,1)
		$awl = [math]::round(($AvgWriteLatency | Where-Object {$_.Instance -eq "$Instance"} | Where-Object {$_.Value -lt 1000000} | Measure-Object -Average Value).Average,1)
		$ar = [math]::round(($AvgRead | Where-Object {$_.Instance -eq "$Instance"} | Where-Object {$_.Value -lt 1000000} | Measure-Object -Average Value).Average,1)
		$aw = [math]::round(($AvgWrite | Where-Object {$_.Instance -eq "$Instance"} | Where-Object {$_.Value -lt 1000000} | Measure-Object -Average Value).Average,1)
		$Info = $DiskMatrix | Where-Object {$_.id -eq $Instance}
		
		$Report += [pscustomobject]@{
			"Name" = $Info.Name
			"Path" = ($Paths | Where-Object {$_.CapacityGB -eq [math]::round($Info.CapacityGB)} | Select-Object Path).Path -Join ","
            "Instance" = $Instance
			"AvgReadLatency" = $arl
			"AvgWriteLatency" = $awl
			"AverageRead" = $ar
			"AverageWrite" = $aw
			"Filename" = $Info.Filename
			"CapacityGB" = $Info.CapacityGB
			"FreeSpaceGB" = ($Paths | Where-Object {$_.CapacityGB -eq [math]::round($Info.CapacityGB)} | Select-Object FreeSpaceGB).FreeSpaceGB -Join ","
		}
	}
	
	$Report
}