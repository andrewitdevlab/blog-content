<#
    .Synopsis
        PowerShell cmdlet used to display the Windows Defender Application Control (WDAC) status on a Windows 10/11 device
    
    .DESCRIPTION
        PowerShell cmdlet used to display the Windows Defender Application Control (WDAC) status on a Windows 10/11 device including
        - the enforcement status for user and kernel mode (i.e. enforcement, off or audit)
        - any Active polices found on the device.  Including the Policy GUID and the date/time the policy was created and last updated on the device

    .EXAMPLE
        Get-WdacStatus.ps1

	   .NOTES
	        Author:  Andrew Silcock
	        Version: 1.0
          Created: 03-May-2022
          Updated: 03-May-2022

    .LINK
        https://github.com/andrewitdevlab/blog-content/Windows Defender/Scripts/Get-WdacStatus.ps1
#>

$ComputerInfo = Get-ComputerInfo -Property "DeviceGuardCodeIntegrityPolicyEnforcementStatus", "DeviceGuardUserModeCodeIntegrityPolicyEnforcementStatus"
"WDAC device policy mode"
"-------------"
$ComputerInfo | Format-List

"WDAC policies"
"-------------"
$PolicyFiles = Get-ChildItem -Path "C:\Windows\System32\CodeIntegrity\CiPolicies\Active" -Filter "*.cip"
foreach ($PolicyFile in $PolicyFiles) 
{
    "WDAC Policy GUID: {0}" -f $PolicyFile.Name.Substring(1, $PolicyFile.Name.Length - 6)
    "`tWDAC Policy Creation: {0}" -f $PolicyFile.CreationTime
    "`tWDAC Policy Updated:  {0}" -f $PolicyFile.LastWriteTime
    ""
}
