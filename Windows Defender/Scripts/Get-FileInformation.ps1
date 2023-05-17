<#
.SYNOPSIS
    Script to be used to analyse a file's detail to assist with troubleshooting of Windows Defender Application Control (WDAC) policies
.DESCRIPTION
    The following information is output by the script:
    - file version infrormation
    - file hash
    - file signing status
    - file signing certification information
    - FSUtil Extended attributes 

.PARAMETER FilePath
    The complete path of the file to analyse

.PARAMETER FileHashAlgorithm
    The hash algorithm when hashing the file (one of "SHA1","SHA256","SHA384","SHA512","MACTripleDES","MD5","RIPEMD160")    

.EXAMPLE
    PS> .\Get-FileInformation.ps1 -FilePath C:\Windows\System32\authui.dll -FileHashAlgorithm SHA1
    Get the file information for the specified file, and generating a File Hash using SHA1

.NOTES
    Author:  Andrew Silcock (andrew@itdevlab.au)
    Created: 5 Apr 2022
    Updated: 5 Apr 2022
    Version: 1.1

#Description:Get WDAC related file information for the specified file path
#Parameters Description:-FilePath and -FileHashAlgorithm
#>
param
(
    [parameter(Mandatory=$true)]
    [string] $FilePath,
    [parameter(Mandatory=$false)]
    [ValidateSet("SHA1","SHA256","SHA384","SHA512","MACTripleDES","MD5","RIPEMD160")]
    [string] $FileHashAlgorithm="SHA1"
)
"Analysing the file {0}" -f $FilePath
""
# Get file signature information
$SignatureInfo = Get-AuthenticodeSignature -FilePath $FilePath

# Get file item - containing version information
$FileVersionInfo = Get-Item -Path $FilePath

# Get the file hash
$FileHashInfo = Get-FileHash -Path $FilePath -Algorithm $FileHashAlgorithm

# Output results to screen
#
"File information"
"------------------"
"`tFile version:    {0}" -f $FileVersionInfo.VersionInfo.FileVersion
"`tProduct version: {0}" -f $FileVersionInfo.VersionInfo.ProductVersion
"`tFile hash:       [{0}] {1}"  -f $FileHashInfo.Algorithm, $FileHashInfo.Hash
""
"File signing status"
"------------------"
"`t{0} - {1}"  -f $SignatureInfo.Status, $SignatureInfo.StatusMessage
"`tOS Binary: {0}"  -f $SignatureInfo.IsOSBinary
""
"Signer Certificate"
"------------------"
"`tSubject:    {0}" -f $SignatureInfo.SignerCertificate.Subject
"`tIssuer:     {0}" -f $SignatureInfo.SignerCertificate.Issuer
"`tNot before: {0}" -f $SignatureInfo.SignerCertificate.NotBefore
"`tNot after:  {0}" -f $SignatureInfo.SignerCertificate.NotAfter
"`tThumbprint: {0}" -f $SignatureInfo.SignerCertificate.Thumbprint
""
"Timestamper Certificate"
"------------------"
"`tSubject:    {0}" -f $SignatureInfo.TimeStamperCertificate.Subject
"`tIssuer:     {0}" -f $SignatureInfo.TimeStamperCertificate.Issuer
"`tNot before: {0}" -f $SignatureInfo.TimeStamperCertificate.NotBefore
"`tNot after:  {0}" -f $SignatureInfo.TimeStamperCertificate.NotAfter
"`tThumbprint: {0}" -f $SignatureInfo.TimeStamperCertificate.Thumbprint
""
"File extended attributes"
"------------------"
$Output = & fsutil file queryea $FilePath
$Output
