# Windows 11 Laptop Diagnostic Collector
# Uses built-in Windows PowerShell commands. Does not collect passwords or full product keys.
# Run in Windows PowerShell; "Run as administrator" is recommended for more complete results.

$ErrorActionPreference = "SilentlyContinue"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = Join-Path $env:USERPROFILE "Desktop\Laptop_Diagnostic_$stamp"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$report = Join-Path $outDir "Laptop_Diagnostic_Report.txt"

function Add-Section([string]$Title) {
    "`r`n" + ("=" * 72) + "`r`n$Title`r`n" + ("=" * 72) | Out-File -FilePath $report -Append -Encoding utf8
}
function Add-Text($Value) {
    ($Value | Out-String -Width 220) | Out-File -FilePath $report -Append -Encoding utf8
}

"Windows Laptop Diagnostic Report" | Out-File -FilePath $report -Encoding utf8
"Generated: $(Get-Date)" | Out-File -FilePath $report -Append -Encoding utf8
"Note: Review this report before sharing; it may contain your Windows username, device name, installed apps, and network adapter details." | Out-File -FilePath $report -Append -Encoding utf8

Add-Section "WINDOWS / DEVICE"
Add-Text (Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, InstallDate, LastBootUpTime, WindowsDirectory)
Add-Text (Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, SystemFamily, SystemType, TotalPhysicalMemory, NumberOfLogicalProcessors, HypervisorPresent)
Add-Text (Get-CimInstance Win32_ComputerSystemProduct | Select-Object Vendor, Name, Version)
Add-Text (Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate)
Add-Text (Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, Version)

Add-Section "CPU"
Add-Text (Get-CimInstance Win32_Processor | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed, LoadPercentage)

Add-Section "RAM MODULES"
Add-Text (Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, @{N='CapacityGB';E={[math]::Round($_.Capacity/1GB,2)}}, Speed, ConfiguredClockSpeed, SMBIOSMemoryType, FormFactor)
Add-Text (Get-CimInstance Win32_ComputerSystem | Select-Object @{N='TotalRAM_GB';E={[math]::Round($_.TotalPhysicalMemory/1GB,2)}})

Add-Section "GRAPHICS / DISPLAY"
Add-Text (Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, DriverDate, VideoProcessor, AdapterRAM, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate)
Add-Text (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID | ForEach-Object {
    [pscustomobject]@{
        Manufacturer = (($($_.ManufacturerName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_})) -join '')
        ProductCode = (($($_.ProductCodeID | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_})) -join '')
        FriendlyName = (($($_.UserFriendlyName | Where-Object {$_ -ne 0} | ForEach-Object {[char]$_})) -join '')
        Active = $_.Active
    }
})

Add-Section "DISKS / STORAGE"
Add-Text (Get-CimInstance Win32_DiskDrive | Select-Object Model, InterfaceType, MediaType, FirmwareRevision, @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}}, Status)
Add-Text (Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, OperationalStatus, @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}})
Add-Text (Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel, FileSystem, HealthStatus, @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}}, @{N='FreeGB';E={[math]::Round($_.SizeRemaining/1GB,2)}})

Add-Section "BATTERY"
Add-Text (Get-CimInstance Win32_Battery | Select-Object Name, BatteryStatus, EstimatedChargeRemaining, EstimatedRunTime, DesignVoltage)
try {
    $batteryPath = Join-Path $outDir "Battery_Report.html"
    & powercfg /batteryreport /output $batteryPath | Out-Null
    "Battery report saved to: $batteryPath" | Out-File -FilePath $report -Append -Encoding utf8
} catch {}

Add-Section "BATTERY / POWER SETTINGS"
Add-Text (& powercfg /getactivescheme)

Add-Section "NETWORK ADAPTERS (NO SAVED PASSWORDS)"
Add-Text (Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress, DriverInformation)

Add-Section "BLUETOOTH"
Add-Text (Get-PnpDevice -Class Bluetooth | Select-Object Status, FriendlyName, InstanceId)

Add-Section "DEVICE MANAGER ERRORS"
Add-Text (Get-CimInstance Win32_PnPEntity | Where-Object {$_.ConfigManagerErrorCode -ne 0} | Select-Object Name, PNPClass, ConfigManagerErrorCode, Status)

Add-Section "WINDOWS SECURITY"
try {
    Add-Text (Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, BehaviorMonitorEnabled, IoavProtectionEnabled, NISEnabled, AntivirusSignatureLastUpdated, AMServiceEnabled)
} catch { "Windows Defender status unavailable in this session." }
try { Add-Text (Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction) } catch {}
try { Add-Text (Get-Tpm | Select-Object TpmPresent, TpmReady, TpmEnabled, TpmActivated) } catch {}
try { Add-Text ("Secure Boot enabled: " + (Confirm-SecureBootUEFI)) } catch { Add-Text "Secure Boot status unavailable (may be unsupported or require elevated permissions)." }

Add-Section "WINDOWS ACTIVATION (NO FULL PRODUCT KEY)"
try {
    Add-Text (Get-CimInstance SoftwareLicensingProduct | Where-Object {$_.PartialProductKey -and $_.Name -like '*Windows*'} | Select-Object Name, Description, LicenseStatus, PartialProductKey, GracePeriodRemaining)
} catch {}
Add-Text "For a clear Windows activation page, open Settings > System > Activation."
Add-Text "This script does not retrieve or display a full Windows product key."

Add-Section "MICROSOFT OFFICE LICENSING CLUES"
$officePaths = @(
    "$env:ProgramFiles\Microsoft Office\root\Office16\OSPP.VBS",
    "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\OSPP.VBS",
    "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
    "$env:ProgramFiles(x86)\Microsoft Office\Office16\OSPP.VBS"
) | Where-Object { Test-Path $_ }
if ($officePaths) {
    "Office licensing script found at: $($officePaths -join '; ')" | Out-File -FilePath $report -Append -Encoding utf8
    foreach ($p in $officePaths) {
        Add-Text (& cscript.exe //nologo $p /dstatus)
    }
} else {
    "Office licensing script not found in common locations. This does not prove Office is absent; Microsoft 365 apps may use another licensing method."
}
Add-Text "Do not share any full product keys. If an Office output includes an account email, redact it before sharing."

Add-Section "INSTALLED APPLICATIONS"
$apps = @()
$uninstallPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($path in $uninstallPaths) {
    $apps += Get-ItemProperty $path | Where-Object {$_.DisplayName} | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
}
Add-Text ($apps | Sort-Object DisplayName -Unique)

Add-Section "STARTUP APPLICATIONS"
Add-Text (Get-CimInstance Win32_StartupCommand | Select-Object Name, Location, Command, User)

Add-Section "RECENT SYSTEM ERRORS (LAST 7 DAYS; LIMITED SAMPLE)"
try {
    $since = (Get-Date).AddDays(-7)
    Add-Text (Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2,3; StartTime=$since} -MaxEvents 80 |
        Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message)
} catch { "System event log could not be read." }

Add-Section "SYSTEM FILE CHECK GUIDANCE"
Add-Text "Not run automatically: DISM and SFC can take time and may require administrator permissions."
Add-Text "If we find signs of Windows corruption, we can run: DISM /Online /Cleanup-Image /RestoreHealth and then sfc /scannow."

Add-Section "END OF REPORT"
Add-Text "Please review the report and redact your Windows username, device name, email addresses, MAC addresses, and any sensitive paths before uploading."
Write-Host ""
Write-Host "Diagnostic collection finished." -ForegroundColor Green
Write-Host "Report folder: $outDir"
Write-Host "Main report: $report"
Write-Host "Battery report (if created): $outDir\Battery_Report.html"
Write-Host ""
Write-Host "Review the report before sharing it. It may include device/software details and identifying information."
