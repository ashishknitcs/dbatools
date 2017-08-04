Function Change-DBASqlServiceStartupMode {
<#
    .SYNOPSIS
    Internal function. Implements the method that changes startup mode of the SQL Server service.

    .DESCRIPTION
    Accepts objects from Get-DBASqlService and performs a corresponding action.


    .PARAMETER ServiceCollection
    A collection of services from Get-DBASqlService.
    
    .PARAMETER Mode
    Startup mode of the service: Automatic, Manual or Disabled.
    
    .NOTES
    Author: Kirill Kravtsov ( @nvarscar )

    dbatools PowerShell module (https://dbatools.io)
    Copyright (C) 2017 Chrissy LeMaire
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param(
		[ValidateScript({ 
	  	$supportedModes = @("Automatic","Manual","Disabled")
	  	if ($_ -notin $supportedModes) { throw ("Use one of the following values: {0}" -f ($supportedModes -join ' | ')) }
	  	else { $true }
	  })]
			[string]$Mode,
		[parameter(ValueFromPipeline = $true, Mandatory = $true)]
			[object[]]$ServiceCollection
	)
	begin {
		$callStack = Get-PSCallStack
		if ($callStack.Length -gt 1) {
			$callerName = $callStack[1].Command
		}
		else {
			$callerName = $callStack[0].Command
		}
		$ProcessArray = @()
	}
	process {
		#Get all the objects from the pipeline before proceeding
		$ProcessArray += $ServiceCollection
	}
	end {
		$ProcessArray = $ProcessArray | Where-Object {(!$InstanceName -or $_.InstanceName -in $InstanceName) -and (!$Type -or $_.type -in $Type)}
		foreach ($service in $ProcessArray) {
			#Get WMI object
			$Wmi = Get-WmiObject Win32_Service -ComputerName $service.ComputerName -filter "name='$($service.ServiceName)'"
			if ($Pscmdlet.ShouldProcess($Wmi, "Changing the Start Mode to $Mode")) {
				$x = $Wmi.ChangeStartMode($Mode)
				if ($x.ReturnValue -ne 0) {	
					Write-Message -Level Warning -Silent $Silent -FunctionName $callerName -Message ("The attempt to $action the service $($job.ServiceName) on $($job.ComputerName) returned the following message: " + (Get-DBASQLServiceErrorMessage $x.ReturnValue))
				}
			}
		}
	}
}