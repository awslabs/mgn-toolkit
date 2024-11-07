<#
  .Synopsis
    The number of network interfaces attached and IPv4 count.
  .Description
    The number of physical network interfaces attached. Then cound the number of IPv4 on the host. The function will count IPv4 IPv4 that are preferred "https://learn.microsoft.com/en-us/powershell/module/nettcpip/set-netipaddress?view=windowsserver2022-ps#-addressstate".
  .Example
    Get-NetworkInterfaceandIPCount
  .INPUTS
	  NA
  .OUTPUTS
    New-PSObjectResponse -Check "$check" -Status "$value" -Action "$Action"
#>
Function Get-NetworkInterfaceandIPCount {

  $check = "Network interface and IP count"
  Write-Log -Message "___________________________________________________________________"
  Write-Log -Message "New check....."
  Write-Log -Message "$check"

  try {
    $physicalNetworkInterface = Get-NetAdapter -physical
    $physicalNetworkInterfaceCount = $physicalNetworkInterface.count

    Write-Log -Message "The output of ""Get-NetAdapter -physical"""
    Write-Log -Message $physicalNetworkInterface
    Write-Log -Message "The count of physical network interface is: $($physicalNetworkInterfaceCount)"

    $ipv4 = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred
    Write-Log -Message "The output of ""Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred"" is"
    Write-Log -Message $ipv4

    $dhcpIpCount = 0
    $manualIpCount = 0

    foreach ($ip in $ipv4) {
      if ($ip.AddressFamily -eq "IPv4" -and $ip.PrefixOrigin -eq "Dhcp" -and $ip.AddressState -eq "Preferred") {
        $dhcpIpCount += 1
        Write-Log -Message "DHCP IP $($ip.IPAddress)"
      }
      elseif ($ip.AddressFamily -eq "IPv4" -and $ip.PrefixOrigin -eq "Manual" -and $ip.AddressState -eq "Preferred") {
        $manualIpCount += 1
        Write-Log -Message "Manual IP $($ip.IPAddress)"
      }
    }

    Write-Log "There are $dhcpIpCount DHCP IPv4 addresses."
    Write-Log "There are $manualIpCount manual IPv4 addresses."
    $totalIpCount = $dhcpIpCount + $manualIpCount

    if ($physicalNetworkInterfaceCount -eq 1 -and $totalIpCount -eq 1) {
      $value = "[GREEN]"
      Write-Log -Message "The output of the ""$check"" check is $value"
      $Action = "No action required. There is 1 physical network interface and 1 IP address."
      Write-Log -Message $Action
    }
    else {
      $value = "[YELLOW]"
      Write-Log -Message "The output of the ""$check"" check is $value" -LogLevel "WARN"
      $Action = "There are $($physicalNetworkInterfaceCount) physical network interface(s) attached and $totalIpCount IPv4 address(es) on the host. Only one interface with its primary IP can be used during migration."
      Write-Log -Message $Action -LogLevel "WARN"
    }
  }
  catch {
    Write-Log -Message "Failed..." -LogLevel "ERROR"
    $Action = "An error occurred when running Get-NetAdapter or Get-NetIPAddress."
    Write-Log -Message $Action -LogLevel "ERROR"
    Write-Log -Message "$($_)" -LogLevel "ERROR"
    $value = "[RED]"
    Write-Log -Message "The check ""$check"" output is $value" -LogLevel "ERROR"
  }
  $postMigrationOutput.Add((Set-PSObjectResponse -Check "$check" -Status "$value" -Action "$Action"))
}