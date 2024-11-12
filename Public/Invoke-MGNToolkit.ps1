<#
.SYNOPSIS
    Run multiple checks for common tasks to help troubleshoot MGN issues.
.DESCRIPTION
    This is tha main function to go through checks related to MGN issues. Each check will be on a separate function. For more information visit - https://github.com/awslabs/mgn-toolkit
.EXAMPLE
	PS C:\> Invoke-MGNToolkit
.INPUTS
	Region = Optional. Used to specify the desired region. By default the module will run in us-east-1.
	SpeedTestIP = Optional. The Ipaddress of the speed test server. by default Get-Bandwidth is not invoked.
	WriteOpsTimer = Optional. The number of seconds to calculate IOPS. By default WriteOpsTimer is 20 seconds.
	MgnVpceId = Optional. If you are using a VPC Endpoint for MGN, you can specify the Endpoint ID + Suffix for the Endpoint connectivity test. Please enter the VPC Endpoint Id and suffix from the DNS names.
	S3VpceId = Optional. If you are using a VPC Endpoint for S3, you can specify the Endpoint ID + Suffix for the Endpoint connectivity test. Please enter the VPC Endpoint Id and suffix from the DNS names.
	ChecksType = Optional. Prerequisite or PostMigration or Replication. By default the module will run all checks.
.OUTPUTS

#>
function Invoke-MGNToolkit {
	[CmdletBinding()]
	param (
		[String]$Region = "us-east-1",
		[IPAddress]$SpeedTestIP,
		[String]$WriteOpsTimer = 20,
		[String]$MgnVpceId,
		[String]$S3VpceId,
		[ValidateScript({
		$set = "Prerequisite", "PostMigration", "Replication", "ALL"
		if ($_ -in $set) { return $true } # OK
        throw "'$_' is not a valid ChecksType. Please try one of the following: '$($set -join ',')'"
		})]
		[String]$ChecksType = "ALL"
	)

	#Set the default file path and logs location, all errors should function as STOP errors for logging purposes
	begin {
		Write-Output "Checking prerequisites before executing the MGN Toolkit..."
		$psmajorversion = $PsVersionTable.PSVersion.Major
		$osmajorversion = ([System.Environment]::OSVersion.Version).Major
		$osminorversion = ([System.Environment]::OSVersion.Version).Minor
		$admincheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

		# Check if the current user has administrator privileges.
		if ($admincheck -eq $False) {
			Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again. Please check the ReadMe for the prerequisite requirements."
			Break
		}
		else {
			Write-Log -Message "Code is running as administrator..." -ConsoleOutput
		}
		# Check if OS version is 6.1(2008R2) or above
		if ($osmajorversion -lt 6) {
			Write-Warning "Server Version is NOT compatible with this module. Please check the ReadMe for the prerequisite requirements."
			Break
		}
		elseif ($osmajorversion -eq 6 -and $osminorversion -lt 1) {
			Write-Warning "Server Version is NOT compatible with this module. Please check the ReadMe for the prerequisite requirements."
			Break
		}
		else {
			Write-Log "Server Version $osmajorversion.$osminorversion is compatible with this module..." -ConsoleOutput
		}

		# Check if PS major version is 3 or above
		if ($psmajorversion -lt 3) {
			Write-Warning "The PowerShell Version $psmajorversion is NOT comptabile with this module. Please check the ReadMe for the prerequisite requirements."
			Break
		}
		else {
			Write-Log -Message "The PowerShell Version $psmajorversion is compatible with this module - Executing script" -ConsoleOutput
		}

		#Prefix for the file names
		$FileNamePrefix = "MGNToolkit_"
		#Name the log and Outputs files based on the timestamp
		$TimeStamp = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
		#The directory of this function
		$SourceDirectory = $PSScriptRoot
		#The parent directory of the module
		$ParentDirectory = (get-item $SourceDirectory).parent.fullname
		#Logs directory
		$LogsDirectory = ("$ParentDirectory\logs\" -replace ("util\\", ""))
		#Create logs directory if it does not exist
		if (-not (Test-Path $LogsDirectory)) {
			Write-Log -Message "Creating logs directory - $LogsDirectory" -ConsoleOutput
			New-item -Path $LogsDirectory -ItemType Directory | Out-Null
		}
		else {
			Write-Log -Message "Logs directory exists - $LogsDirectory" -ConsoleOutput
		}
		#Logs file name
		$LogsDestination = $LogsDirectory + $FileNamePrefix + $TimeStamp + ".log"
		Write-Log -Message "Starting....."
		Write-Log -Message "The timestamp is the local system time"
		Write-Log -Message "Start time"
		$startTime = Get-Date
		Write-Log -Message $startTime
		#Outputs directory
		$OutputsDirectory = ("$ParentDirectory\Outputs\" -replace ("util\\", ""))
		#Create the Outputs directory if it does not exist
		if (-not (Test-Path $OutputsDirectory)) {
			Write-Log -Message "Creating Outputs directory - $OutputsDirectory"
			New-item -Path $OutputsDirectory -ItemType Directory | Out-Null
		}
		else {
			Write-Log -Message "Outputs directory exists - $OutputsDirectory"
		}
		$tempDirectory = ("$ParentDirectory\temp\" -replace ("util\\", ""))
		if (-not (Test-Path $tempDirectory)) {
			Write-Log -Message "Creating temp directory - $tempDirectory"
			New-item -Path $tempDirectory -ItemType Directory | Out-Null
		}
		else {
			Write-Log -Message "temp directory exists - $tempDirectory"
		}
		#Outputs file name
		$OutputsDestination = $OutputsDirectory + $FileNamePrefix + $TimeStamp + ".txt"
		$csvDestination = $OutputsDirectory + $FileNamePrefix + $TimeStamp + ".csv"
		Write-Log -Message "Logs available at $LogsDestination" -All
		Write-Log -Message "Outputs available at $OutputsDestination" -All

		Write-Output "Running all the tests can take a few minutes..."
		#Set the output object
		$prerequisiteOutput = New-Object -TypeName "System.Collections.ArrayList"
		$postMigrationOutput = New-Object -TypeName "System.Collections.ArrayList"
		$replicationOutput = New-Object -TypeName "System.Collections.ArrayList"
	}

	process {

		Write-Output @"
    __  ___ ______ _   __   ______               __ __    _  __
   /  |/  // ____// | / /  /_  __/____   ____   / // /__ (_)/ /_
  / /|_/ // / __ /  |/ /    / /  / __ \ / __ \ / // //_// // __/
 / /  / // /_/ // /|  /    / /  / /_/ // /_/ // // ,<  / // /_
/_/  /_/ \____//_/ |_/    /_/   \____/ \____//_//_/|_|/_/ \__/
"@

		Write-Log -Message "Checking the source machine product type, (1)Work Station(2)Domain Controller(3)Server"
		$productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType
		Write-Log -Message "The source machine product type is $productType"

		switch ($ChecksType) {
			{$_ -eq "Prerequisite" -Or $_ -eq "ALL"} {
				(Get-AntivirusEnabled) | Out-Null
				(Get-BitLockerStatus) | Out-Null
				(Get-BootDiskSpace) | Out-Null
				(Get-DotNETFramework) | Out-Null
				(Get-FreeRAM) | Out-Null
				(Get-TrustedRootCertificate) | Out-Null
				(Get-SCandNET) | Out-Null
				(Get-WMIServiceStatus) | Out-Null
				(Get-ProxySetting) | Out-Null
				(Test-EndpointsNetworkAccess -region $Region -mgnVpceId $MgnVpceId -s3VpceId $S3VpceId) | Out-Null
				Write-Output "============"
				Write-Output "Prerequisite"
				Write-Output "============"
				$prerequisiteOutput | ForEach-Object { [PSCustomObject]$_ } | Format-Table -Wrap
			}
			{$_ -eq "PostMigration" -Or $_ -eq "ALL"} {
				(Get-DomainControllerStatus) | Out-Null
				(Get-BootMode) | Out-Null
				(Get-Authenticationmethod) | Out-Null
				(Get-NetworkInterfaceandIPCount) | Out-Null
				Write-Output "=============="
				Write-Output "Post Migration"
				Write-Output "=============="
				$postMigrationOutput | ForEach-Object { [PSCustomObject]$_ } | Format-Table -Wrap
			}
			{$_ -eq "Replication" -Or $_ -eq "ALL"} {
				if ($SpeedTestIP) {
					Write-Output "Please follow the following documentation to create the Speed Test instance before proceeding with the Bandwidth Test: https://docs.aws.amazon.com/mgn/latest/ug/Replication-Related-FAQ.html#perform-connectivity-bandwidth-test"
					(Get-Bandwidth -SpeedTestIP $SpeedTestIP) | Out-Null
				}
				if ($WriteOpsTimer) {
					(Get-DiskActivity -WriteOpsTimer $WriteOpsTimer) | Out-Null
				}
				Write-Output "==========="
				Write-Output "Replication"
				Write-Output "==========="
				$replicationOutput | ForEach-Object { [PSCustomObject]$_ } | Format-Table -Wrap
			}
			default {
				Write-Output "Unknown checks type"
			}
		}

		$prerequisiteOutput + $postMigrationOutput + $replicationOutput | ForEach-Object { [PSCustomObject]$_ } | Format-List | Out-File -FilePath $OutputsDestination
		$prerequisiteOutput + $postMigrationOutput + $replicationOutput | Select-Object -Property Check, Value, Action | Export-Csv -Path $csvDestination -NoTypeInformation
	}
	end {
		Write-Log -Message "___________________________________________________________________"
		Write-Log -Message "Cleaning up....."
		Write-Log -Message "Deleting the temp directory - $tempDirectory"
		Remove-Item -Path "$ParentDirectory\temp" -Recurse
		Write-Log -Message "End time"
		$endTime = Get-Date
		Write-Log -Message $endTime
		Write-Log -Message "The END!!!"
	}
}