<#
  .Synopsis
    Checks the Write Disk Activity on the source server to determine if it is sufficient with the bandwidth results.
  .Description
    This function will check the performance counters for the disks to calculate if the disk activity will cause any issues with replication speed.
  .Example
    Check-DiskActivity -WriteOpsTimer 30
  .OUTPUTS
    Set-PSObjectResponse -Check "$check" -Status "$value" -Action "$Action"
#>
Function Get-DiskActivity {
  param (
    # Seconds for how long to run the disk write activity check for
    [String]$WriteOpsTimer
  )
  if (!($WriteOpsTimer)) {
    $WriteOpsTimer = Read-Host -Prompt 'Enter the amount of Seconds to check for Disk Write Activity'
  }
  $PhysicalDisk_per_language = @{
    "es-ES"  = "\Disco físico(_Total)\Bytes de escritura en disco/s"
    "it-IT"  = "\Disco fisico(_Total)\Byte scritti su disco/sec"
    "fr-FR"  = "\Disque physique(_Total)\Écritures disque, octets/s"
    "pt-BR"  = "\PhysicalDisk(_Total)\Bytes de gravação de disco/s"
    "pt-PT"  = "\Disco físico(_Total)\Bytes escritos em disco/seg"
    "de-DE"  = "\Physikalischer Datenträger(_Total)\Bytes geschrieben/s"
    "sv-SE"  = "\Fysisk disk(_Total)\Disk - skrivna byte/s"
    "tr-TR"  = "\FizikselDisk(_Total)\Disk Yazma Bayt/sn"
    "hu-HU"  = "\Fizikai lemez(_Total)\Írási sebesség (bájt/s)"
    "nl-NL"  = "\Fysieke schijf(_Total)\Geschreven bytes per seconde"
    "pl-PL"  = "\Dysk fizyczny(_Total)\Bajty zapisu dysku/s"
    "cs-CZ"  = "\Fyzický disk(_Total)\Bajty zapisování na disk/s"
    "ru-RU"  = "\Физический диск(_Total)\Скорость записи на диск (байт/с)"
    "others" = "\PhysicalDisk(_Total)\Disk Write Bytes/sec"
  }

  $check = "Disk Write Activity Average"
  $check2 = "Disk Write Activity Maximum"
  Write-Log -Message "___________________________________________________________________"
  Write-Log -Message "New check....."
  Write-Log -Message "$check"
  Write-Log -Message "$check2"

  try {
    ## Check Write Activity for intervals set in inputs ##
    Write-Log -Message "Collecting write activity for $WriteOpsTimer seconds..."
    ## Gets the System-locale setting
    $Locale = Get-WinSystemLocale
    Write-Log -Message "The output of ""Get-WinSystemLocale"""
    Write-Log -Message $Locale
    if (-not $PhysicalDisk_per_language.ContainsKey($Locale.Name)) {
      $PhysicalDisk_Performance_Counter = $PhysicalDisk_per_language["others"]
    }
    else {
      $PhysicalDisk_Performance_Counter = $PhysicalDisk_per_language[$Locale.Name]
    }
    Write-Log -Message "The performance counter string is: $PhysicalDisk_Performance_Counter"
    $totalwrites = (Get-Counter -Counter $PhysicalDisk_Performance_Counter -SampleInterval 1 -MaxSamples $WriteOpsTimer).CounterSamples.CookedValue
    Write-Log -Message "Listing the output of the PhysicalDisk(_Total)\Disk Write Bytes/sec counter:"
    Write-Log -Message $totalwrites
    $averagebytes = $totalwrites | Measure-Object -Average | Select-Object -ExpandProperty Average
    $maxbytes = $totalwrites | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    $averageMbps = [math]::Round($averagebytes * 8 / [Math]::Pow(1000, 2), 4)
    $maxMbits = [math]::Round($maxbytes * 8 / [Math]::Pow(1000, 2), 4)
    Write-Log -Message @"
Average (Mbps) = $averageMbps Mbps
Maximum (Mbits) = $maxMbits Mbps
"@

    $value = "[YELLOW]"
    $value2 = "[YELLOW]"
    Write-Log -Message "The results for the Disk Activity check: $value" -LogLevel "WARN"
    $Action = "The average for Disk Write Activity was $averageMbps Mbps. Compare this result with the Upload results from the Check-Bandwidth function to ensure it is sufficient."
    Write-Log -Message $Action -LogLevel "WARN"
    $Action2 = "The Max for Disk Write Activity was $maxMbits Mbps. Ensure your Staging Area disk settings will be sufficient if there are frequent maximum spikes of this value, to avoid Replication Backlog"
    Write-Log -Message $Action2 -LogLevel "WARN"
  }
  catch {
    Write-Log -Message "Failed..." -LogLevel "ERROR"
    $Action = "An error occurred when running Get-DiskActivity."
    Write-Log -Message $Action -LogLevel "ERROR"
    Write-Log -Message "$($_)" -LogLevel "ERROR"
    $value = "[RED]"
    Write-Log -Message "The check ""$check"" output is $value" -LogLevel "ERROR"
  }
  $replicationOutput.Add((Set-PSObjectResponse -Check "$check" -Status "$value" -Action "$Action"))
  $replicationOutput.Add((Set-PSObjectResponse -Check "$check2" -Status "$value2" -Action "$Action2"))
}
