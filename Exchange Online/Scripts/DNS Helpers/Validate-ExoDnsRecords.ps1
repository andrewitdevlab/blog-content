<#
    .Synopsis
        PowerShell script to analyse correctness of Exchange Online DNS records.
    
    .DESCRIPTION
        PowerShell script to analyse correctness of Exchange Online DNS records.  It analyses the following records:
            - That a valid Exchange Online protection MX record exists for the domain, with a preference of 0
            - That a valid CNAME exists for autodiscover.outlook.com
            - That a valid SPF record exists with an include for 'include:spf.protection.outlook.com', or that there is an SPF redirect.
            - That valid selector1 and selector2 records exist for DKIM with a validly formatted CNAME name host.

        Documentation relating to all pre-requisite DNS records is located at https://docs.microsoft.com/en-us/microsoft-365/enterprise/external-domain-name-system-records?view=o365-worldwide
    
    .EXAMPLE
        .\Validate-ExoDnsRecords.ps1 -DomainName itdevlab.au
	   
    .NOTES
	      Author:  Andrew Silcock
	      Version: 1.1
          Created: 17-Aug-2022
          Updated: 17-Aug-2022
    .LINK
        https://github.com/andrewitdevlab/blog-content/Exchange Online/Scripts/DNS Helpers/Validate-ExoDnsRecords.ps1
#>
param
(
    [parameter(Mandatory=$true)]
    [string] $DomainName
)

function Validate-MxRecord
{
    param
    (
        [parameter(Mandatory=$true)]
        [string] $DomainName
    )
    $MicrosoftDomainFormat = $DomainName.Replace('.','-')
    $MsftNameExchangeSuffix = "mail.protection.outlook.com"
    $ExpectedNameExchange = ("{0}.{1}" -f $MicrosoftDomainFormat, $MsftNameExchangeSuffix)
    $ExpectedPreference = 0

    $MxRecords = Resolve-DnsName -Name $DomainName -Type MX

    #$MxRecords


    $ExoOtherMxRecords = $MxRecords | Where-Object { $_.NameExchange -like ('*{0}' -f $MsftNameExchangeSuffix) -and $_.NameExchange -ne ('{0}' -f $ExpectedNameExchange)}
    $ExpectedMxRecords = $MxRecords | Where-Object { $_.NameExchange -eq ('{0}' -f $ExpectedNameExchange) }

    if ($ExpectedMxRecords)
    {
        Write-Host ("The expected MX record '{0}' for Exchange Online was found" -f $ExpectedNameExchange ) -ForegroundColor Green

        switch ($ExpectedMxRecords.Preference)
        {
            0 
            { 
                Write-Host "`tThe preference of the record is 0 as expected" -ForegroundColor Green
            }
            default 
            { 
                Write-Warning ("`tThe preference of the MX record is not 0 as expected.  A preference of '{0}' was found" -f $ExpectedMxRecords.Preference )
            }

        }
    }
    elseif ($ExoOtherMxRecords)
    {
       Write-Warning "MX records were found for Exchange Online, however not the domain that was expected.  Refer to the Microsoft 365 setup in the Microsoft Admin portal for details for setting up your domain" 
    }
    elseif ($MxRecords -and !$ExoOtherMxRecords -and !$ExpectedMxRecords)
    {
        Write-Warning "MX records were found, however none were for Exchange Online."
    }
    else
    {
        Write-Warning "No MX records were found for the domain"
    }
}

function Validate-Autodiscover
{
    param
    (
        [parameter(Mandatory=$true)]
        [string] $DomainName
    )

    $ExpectedCname = ("autodiscover.{0}" -f $DomainName)

    $AutoDiscoverRecord = Resolve-DnsName -Name $ExpectedCname -Type CNAME

    if ($AutoDiscoverRecord -and $AutoDiscoverRecord.NameHost -eq "autodiscover.outlook.com")
    {
        Write-Host ("The expected auto discover record for Exchange Online was found") -ForegroundColor Green    
    }
    elseif ($AutoDiscoverRecord)
    {
        Write-Host ("An autodiscover record was found, however it has the wrong NameHost") -ForegroundColor Green    
    }
    else
    {
        Write-Host ("No autodiscover record was found") -ForegroundColor Red   
    }
}

function Validate-SpfRecord
{
    param
    (
        [parameter(Mandatory=$true)]
        [string] $DomainName
    )

    # The expected include for Exchange Online
    $ExpectedSpfEntry = " include:spf.protection.outlook.com "

    $SpfRecord = Resolve-DnsName -Name $DomainName -Type TXT | Where-Object { $_.Strings -like 'v=spf1*'}

    if ($SpfRecord.GetType().Name -ne 'DnsRecord_TXT')
    {
        Write-Host ("Multiple SPF records were found, ensure there is only a single SPF record") -ForegroundColor Red           
    }
    else
    {
        $SpfFilter = ("*{0}*" -f $ExpectedSpfEntry)
        if (($SpfRecord.Strings -join "") -like $SpfFilter)
        {
            Write-Host ("The SPF record contains the expected include entry{0}" -f $ExpectedSpfEntry) -ForegroundColor Green            
        }
        elseif (($SpfRecord.Strings -join "") -like "*redirect=*")
        {
            Write-Host ("The SPF record is a re-direct, please ensure the solution managing the SPF record includes the expected entry{0} " -f $ExpectedSpfEntry) -ForegroundColor Yellow            
        }
        else
        {
            Write-Host ("Multiple SPF records were found, ensure there is only a single SPF record") -ForegroundColor Red
        }
    }
}

function Validate-DkimRecords
{
    param
    (
        [parameter(Mandatory=$true)]
        [string] $DomainName
    )

    $DkimSelectors = @("selector1","selector2")

    foreach ($DkimSelector in $DkimSelectors)
    {
        $SelectorDnsEntry = Resolve-DnsName -Name ("{0}._domainkey.{1}" -f $DkimSelector, $DomainName) -Type CNAME
        
        if ($SelectorDnsEntry)
        {
            $SelectorPrefix = "{0}-{1}" -f $DkimSelector, $DomainName.Replace(".","-")
            $Filter = ("{0}._domainkey.*.onmicrosoft.com" -f $SelectorPrefix)

            if ($SelectorDnsEntry.NameHost -like $Filter)
            {
                 Write-Host ("The DKIM record for {0} is valid" -f $DkimSelector) -ForegroundColor Green 
            }
            else
            {
                 Write-Host ("The DKIM record for {0} is not in the expected format" -f $DkimSelector) -ForegroundColor Red 
            }
        }
        else
        {
            Write-Host ("The DKIM record for {0} was not found" -f $DkimSelector) -ForegroundColor Red 
        }
    }

}

"Validating the DNS records for '{0}'" -f $DomainName
"----------------------------------------------"
""
"MX record anaylsis"
"----------------------------------------------"
Validate-MxRecord -DomainName $DomainName

""
"Autodiscover record anaylsis"
"----------------------------------------------"
Validate-Autodiscover -DomainName $DomainName

""
"SPF record anaylsis"
"----------------------------------------------"
Validate-SpfRecord -DomainName $DomainName

""
"DKIM record anaylsis"
"----------------------------------------------"
Validate-DkimRecords -DomainName $DomainName
