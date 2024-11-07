<#
  .Synopsis
    Check the free disk space on the boot volume.
  .Description
    Check the free disk space on the boot volume. Required 2GB of disk space.
  .Example
    Get-BootDiskSpace
  .INPUTS
	  NA
  .OUTPUTS
    Set-PSObjectResponse -Check "$check" -Status "$value" -Action "$Action"
#>

Function Get-BootDiskSpace {
  $check = "Boot Disk Free Space"
  Write-Log -Message "___________________________________________________________________"
  Write-Log -Message "New check....."
  Write-Log -Message "$check"

  Write-Log -Message "Check if there is at least 2GB of free space on the boot volume."

  try {
    $bootDriveLeter = (Get-Partition | Where-Object { $_.IsBoot -eq $TRUE }).DriveLetter
    $bootDriveSizeRemaining = (Get-Volume | Where-Object { $_.DriveLetter -eq $bootDriveLeter }).SizeRemaining
    $bootDriverSizeGB = $bootDriveSizeRemaining / 1073741824
    $bootDriverFree = [math]::Round($bootDriverSizeGB, 3)

    Write-Log -Message "Size of the free disk on the boot drive $($bootDriveLeter) is: $bootDriverFree"

    if ($bootDriverFree -gt 2) {
      $value = "[GREEN]"
      Write-Log -Message "The output of the ""$check"" check is $value"
      $Action = "No action required. There is $bootDriverFree GB free space on $($bootDriveLeter) drive."
      Write-Log -Message $Action
    }
    else {
      $value = "[RED]"
      Write-Log -Message "The output of the ""$check"" check is $value" -LogLevel "ERROR"
      $Action = "The source machine has $bootDriverFree GB of free space. Verify that at least 2 GB of free disk space on the $bootDriverName drive https://docs.aws.amazon.com/mgn/latest/ug/installation-requirements.html#general-requirements2."
      Write-Log -Message $Action -LogLevel "ERROR"
    }
  }
  catch {
    Write-Log -Message "Failed..." -LogLevel "ERROR"
    $Action = "An error occurred when running Get-BootDiskSpace."
    Write-Log -Message $Action -LogLevel "ERROR"
    Write-Log -Message "$($_)" -LogLevel "ERROR"
    $value = "[RED]"
    Write-Log -Message "The check ""$check"" output is $value" -LogLevel "ERROR"
  }
  $prerequisiteOutput.Add((Set-PSObjectResponse -Check "$check" -Status "$value" -Action "$Action"))
}