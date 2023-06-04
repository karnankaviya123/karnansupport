
<#
    .SYNOPSIS
    Creates Landing Zone

    .DESCRIPTION
    Creates Landing zone. Includes Validations / Sanity Checks against Azure

    .PARAMETER lzconfigPath
    Mandatory. The lzconfig.json with the fundamental deployment configuration (e.g. Project & Stage)

    .PARAMETER updateMode
    Optional. If true, the deployment is considered to be a Landing Zones Update, in opposite to the Landing Zone Creation.
    This is currently used for two things:
    1) Do not deploy VNet and Hub Connection (Temporary - workaround to avoid destroying subnets on re-deployment)

    .EXAMPLE
    ./tools/Scripts/New-LandingZone.ps1 -lzconfigPath:"lzconfig.json" -WhatIf:$true
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string] $lzconfigPath,

    [Parameter(Mandatory = $false)]
    [boolean] $updateMode = $false
)

#region helper functions
<#
.SYNOPSIS
Check the provided list of address prefixes regarding their structure and availability

.DESCRIPTION
Check the provided list of address prefixes regarding their structure and availability

.PARAMETER AddressPrefixes
Mandatory. The address prefixes to check

.PARAMETER newVnetRGName
Mandatory. The name of the rg of the VNET to be created

.PARAMETER newVnetName
Mandatory. The name of the VNET to be created

.EXAMPLE
Confirm-VNETAddressPrefix -AddressPrefixes @('192.167.153.1/24')
#>
function Confirm-VNETAddressPrefix {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $AddressPrefixes,

        [Parameter(Mandatory = $false)]
        [string] $newVnetRGName,

        [Parameter(Mandatory = $false)]
        [string] $newVnetName,

        [Parameter(Mandatory = $false)]
        [string] $existingSubscriptionId
    )

    $foundErrors = 0
    # List of excluded VNETs which do not follow "Cloud dedicated" network range 10.227.0.0/16 - 10.228.0.0/17.
    $excludedVNETNames = [System.Collections.ArrayList]@("vnet-acd-inf-csadm","soc_prd_test-vnet")

    # Warning: Only works with subscriptions the principal has READ access to
    Write-Verbose "Fetch all existing VNETs the principal has access to"
    $vNetGraphQuery = 'resources
    | where type == "microsoft.network/virtualnetworks"
    | project name, id, properties.addressSpace.addressPrefixes'
    $existingVNETs = Search-AzGraph -Query $vNetGraphQuery -First 1000
    ## Validate
    # Address space
    foreach ($addressPrefix in $AddressPrefixes) {

        # Check format
        if ($addressPrefix -notmatch '^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\/[0-9]{1,2}$') {
            Write-Error ('Address space [{0}] of virtual network [{1}] is not valid' -f $addressPrefix, $newVnetName) -ErrorAction 'Continue'
            $foundErrors++
        }
        
        # Check if IP range can be used in Azure infrastructure
        # Due to non-standard IP ranges in existing Landing Zones exceptions have been added.
        # Exceptions are not affecting new Landing Zones - only existing ones.
        If ($excludedVNETNames -contains $newVnetName) {
            Write-Verbose "Skipping IP address range verification [$newVnetRGName|$newVnetName] of subscription [$existingSubscriptionId] as it was found in exclusions list." -Verbose
        }
        elseif ($addressPrefix.Split("/")[0] -notmatch '^10\.(227\.0\.([1-9]|[1-9]\d|[12]\d\d)|227\.([1-9]|[1-9]\d|[12]\d\d)\.([1-9]?\d|[12]\d\d)|228\.127\.([1-9]?\d|1\d\d|2[0-4]\d|25[0-4])|228\.([1-9]?\d|1[01]\d|12[0-6])\.([1-9]?\d|[12]\d\d))$') {
            Write-Error ('Address space [{0}] of virtual network [{1}] cannot be used in Azure infrastructure' -f $addressPrefix, $newVnetName) -ErrorAction 'Continue'
            $foundErrors++
        }

        # Check if already used - Overlaps are ignored for now
        if ((-not [String]::IsNullOrEmpty($existingSubscriptionId)) -and $existingVNETs.id -contains ('/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/virtualNetworks/{2}' -f $existingSubscriptionId, $newVnetRGName, $newVnetName)) {
            Write-Verbose "Allowing VNET [$newVnetRGName|$newVnetName] of subscription [$existingSubscriptionId] as it is the one we deploy." -Verbose
        }
        else {
            foreach ($existingVNET in $existingVNETs) {
                if ($existingVNET.properties_AddressSpace_AddressPrefixes -contains $addressPrefix) {
                    Write-Error ('Address space [{0}] for virtual network [{1}|{2}] is already used by virtual network [{3}]' -f $addressPrefix, $newVnetRGName, $newVnetName, $existingVNET.Id) -ErrorAction 'Continue'
                    $foundErrors++
                }
            }     
        }
    }

    if ($foundErrors -gt 0) {
        throw "Found [{$foundErrors}] issues with the configured virtual networks. Please examine raised errors."
    }

    Write-Verbose "Address prefix [$addressPrefix] is valid"
}

<#
.SYNOPSIS
Gets next available name for storage account

.DESCRIPTION
Gets next available name for storage account basing on subscription name parameters. By default storage account number is 001, this function will increment it if required.

.PARAMETER project
Required. Name of project. Required to build storage account name

.PARAMETER subscriptionName
Required. Name of subscription where storage account will be deployed

.PARAMETER stage
Required. Stage of subscription. Required to build storage account name

.EXAMPLE
Get-AvailableStorageAccountName -Project "lztstcorp" -Stage "dev" -SubscriptionName "sub-lztstcorp-dev"

#>
function Get-AvailableStorageAccountName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $project,

        [Parameter(Mandatory = $true)]
        [string] $subscriptionName,

        [Parameter(Mandatory = $true)]
        [string] $stage
    )

    [string]$number = "1"
    [string]$storageAccountName = "st"+$project+$stage+"tfs"+$number.PadLeft(3,'0')
    $subscriptionId = (Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction 'Ignore').id
    $uri = "https://management.azure.com/subscriptions/{0}/providers/Microsoft.Storage/checkNameAvailability?api-version=2022-09-01" -f $subscriptionId
    $connection = Get-AzAccessToken -ResourceTypeName ResourceManager
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $connection.Token
    }
    $body = @{
        "name" = $storageAccountName
        "type" = "Microsoft.Storage/storageAccounts"
    } | ConvertTo-Json
    $sAGraphQuery = 'resources
        | where type == "microsoft.storage/storageaccounts"
        | where name == "{0}"
        | project name, resourceGroup, subscriptionId' -f $storageAccountName

    # Checking if Storage account already exists in target subscription
    # If it exists the same name will be used
    # Else script will find next available storage account name
    $graphQueryResult.resourceGroup = Search-AzGraph -Query $sAGraphQuery -First 1000 -Verbose
    #check storage accounts exists in the subscription and resourcegroup
    $resourceGroups = Get-AzResourceGroup
    foreach ($resourceGroup in $resourceGroups) {
      $deployments = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroup.ResourceGroupName
        foreach ($deploymentName in $deployments) {   
            if ($deploymentName.DeploymentName -like "mine*") {
                $resource = Get-AzResource  | Where-Object ResourceType -EQ "Microsoft.Storage/storageAccounts"
                foreach($resources in $resource){
                if($resources.Name -like "mine*"){
                Write-Host "$($deploymentName.DeploymentName) is deployed in $($deploymentName.ResourceGroupName) group on $($deploymentName.Timestamp) and moved to $($resources.ResourceGroupName)"
                }
             }               
            }
        }
    }
    #check storage accounts exists in the subscription and resourcegroup

    if ($graphQueryResult.subscriptionId -ne $subscriptionId) {
        # Check name availability in Azure
        $restMethodResponse = Invoke-RestMethod -Body $body -Method Post -Headers $authHeader -Uri $uri -Verbose

        # If name is not available find next available name
        if (-not $restMethodResponse.name) {
            # Search for next available SA name while $checkNameAttempt is less than 5 (check names between 002 and 005)
            $checkNameAttempt = 1
            do {
                $checkNameAttempt++
                $number = $checkNameAttempt.ToString()
                [string]$storageAccountName = "st"+$project+$stage+"tfs"+$number.PadLeft(3,'0')
                $body = @{
                    "name" = $storageAccountName
                    "type" = "Microsoft.Storage/storageAccounts"
                } | ConvertTo-Json

                $restMethodResponse = Invoke-RestMethod -Body $body -Method Post -Headers $authHeader -Uri $uri -Verbose
                if ($restMethodResponse.name) {
                    break
                }
            } while ($checkNameAttempt -lt 5)
        }
    }
    # Return storage account name
    return $storageAccountName
}
#endregion

#Read Config
$Config = Get-Content -Raw -Path $lzconfigPath | ConvertFrom-Json -Depth 99 -AsHashtable

$project = $Config.project.ToLower()
$stage = $Config.stage.ToLower()
$context = $Config.context.ToLower()
$number = $Config.number

#Add ccoe_lz_version tag to deployment parameters
$Config.Tag.Add("ccoe_lz_version","LZv"+$Config.LZVersion)

Write-Verbose "Processing Config: " -Verbose
Write-Verbose ($Config | ConvertTo-Json) -Verbose

#Build Subscription Name
if ($updateMode) {
    $SubscriptionName = Split-Path -Path (Split-Path -Path $lzconfigPath -Parent) -Leaf # using the name of the folder containing the lzconfig.jaon
}
else {
    $SubscriptionName = "sub-" + $project + "-" + $stage

    if ($context -ne '<none>') {
      $subscriptionName = $subscriptionName+"-"+$context
    }

    if ($Config.number -ne '<none>') {
      $number = $Config.number.PadLeft(3,'0')
      $subscriptionName = $subscriptionName+"-"+$number
    }

    Write-Verbose ("Generated subscription name in LZ Resource deployment: {0}" -f $subscriptionName ) -Verbose
}



#region Sanity Checks

# Subscription validation
# -----------------------
# Check if Sub already exists and get ID if
$ExistingSubscriptionId = (Get-AzSubscription -SubscriptionName $SubscriptionName -ErrorAction 'Ignore').id
if (-not $ExistingSubscriptionId) {
    $ExistingSubscriptionId = (Get-AzSubscriptionAlias -AliasName $SubscriptionName -WhatIf:$false -ErrorAction 'Ignore').id
}
if (-not $ExistingSubscriptionId) {
    $ExistingSubscriptionId = (Get-AzSubscriptionAlias -AliasName "alias-$SubscriptionName" -WhatIf:$false -ErrorAction 'Ignore').id
}
if ($ExistingSubscriptionId) {
    Write-Verbose "Found subscription [$SubscriptionName], Subscription Id: [$ExistingSubscriptionId]" -Verbose
}
else {
    throw "Subscription [$SubscriptionName] not found in the Management Group [$($Config.MgmtGrId)]"
}

# Address Prefix validation
# -------------------------
$confirmInputObject = @{
    AddressPrefixes = $Config.vnetAddressPrefix
    Verbose         = $true 
    ErrorAction     = 'Stop'
}
if (-not [String]::IsNullOrEmpty($ExistingSubscriptionId)) {
    $confirmInputObject += @{
        newVnetRGName          = $Config.ResourceNames.rgVnet.ToLower()
        newVnetName            = $Config.ResourceNames.vnetName.ToLower()
        existingSubscriptionId = $ExistingSubscriptionId
    }
}

If (($Config.vnetAddressPrefix -ne '<none>') -and (($Config.MgmtGrId -eq 'mg-corp') -or ($Config.MgmtGrId -eq 'dev-mg-corp'))) {
    $null = Confirm-VNETAddressPrefix @confirmInputObject
}

# Storage account validation
# -----------------------

$Config.ResourceNames.saName = Get-AvailableStorageAccountName -Stage $stage -Project $project -SubscriptionName $subscriptionName

#endregion Sanity Checks

# Deploy template for LZ
# ----------------------

If (($Config.MgmtGrId -eq 'mg-corp') -or ($Config.MgmtGrId -eq 'dev-mg-corp')) {
    $TemplateParameterObject = @{
        parentMgId              = $Config.MgmtGrId
        project                 = $project
        stage                   = $stage
        context                 = $context
        number                  = $number
        VNETAddressPrefix       = $Config.vnetAddressPrefix
        DNSServers              = $Config.vnetDNSServers
        Tags                    = $config.Tag
        skipVNet                = $updateMode
        resourceNames           = $Config.ResourceNames
    }
}
else {
    # remove parameter values before deployment
    $Config.ResourceNames.rgVnet = ''
    $Config.ResourceNames.vnetName= ''

    $TemplateParameterObject = @{
        parentMgId              = $Config.MgmtGrId
        project                 = $project
        stage                   = $stage
        context                 = $context
        number                  = $number
        VNETAddressPrefix       = ''
        DNSServers              = $Config.vnetDNSServers
        Tags                    = $config.Tag
        skipVNet                = $updateMode
        resourceNames           = $Config.ResourceNames
    }

}

$DeploymentParams = @{
    DeploymentName          = "LZ-$(-join (Get-Date -Format yyyyMMddTHHMMssffffZ)[0..63])"
    TemplateFile            = "$PSScriptRoot/../.bicep/deployLZResources.bicep"
    location                = "westeurope"
    TemplateParameterObject = $TemplateParameterObject 
    Verbose                 = $true
}

Write-Verbose "Invoke deployment with" -Verbose
Write-Verbose ($DeploymentParams | ConvertTo-Json | Out-String) -Verbose

Test-AzSubscriptionDeployment @DeploymentParams 

if ($PSCmdlet.ShouldProcess("Subscription-level deployment for subscription [$SubscriptionName]", "Invoke")) {
    $res = New-AzSubscriptionDeployment @DeploymentParams
    Write-Verbose ($res.Outputs | ConvertTo-Json -Depth 10 | Out-String) -Verbose
}
else {
    New-AzSubscriptionDeployment @DeploymentParams -WhatIf
}