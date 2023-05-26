<#
.SYNOPSIS
Gets What-If status

.DESCRIPTION
Gets What-If status based on input parameters

.PARAMETER validateOnly
Mandatory. "WhatIf" value set in pipeline

.PARAMETER pipelineLZVersion
Optional. LZ version from pipeline

.PARAMETER sourceBranch
Optional. Source Branch name

.PARAMETER deploymentLock
Optional. Deployment Lock value from lzconfig.json

.EXAMPLE
Get-WhatIfStatus -validateOnly "true"

Returns What-If value (true or false)
#>
function Get-WhatIfStatus {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $validateOnly,

        [Parameter(Mandatory = $false)]
        [version] $pipelineLZVersion,

        [Parameter(Mandatory = $false)]
        [string] $sourceBranch,

        [Parameter(Mandatory = $false)]
        [string] $deploymentLock,

        [Parameter(Mandatory = $false)]
        [string] $subscriptionName
    )
    Write-Host $subscriptionName $sourceBranch 
    $subName = @("sub-lztstcorp-dev", "sub-lztstonline-dev", "sub-lztstcorp-build", "sub-lztstonline-build")

    # initial WhatIf status
    $WhatIfStatus = $true

    # force WhatIf deployment when pipeline is not running from 'versions' or 'main' branch
    If ($sourceBranch.StartsWith('refs/heads/versions/')) {
        $BranchVersion = New-Object System.Version($sourceBranch -replace "refs/heads/versions/")
        if($pipelineLZVersion -eq $BranchVersion) { 
            Write-Verbose ("Pipeline is running from Version Branch {0}" -f $BranchVersion) -Verbose
            $WhatIfStatus = $false
        }
    }
    elseif($sourceBranch -eq "refs/heads/main") { 
        $WhatIfStatus = $false 
      }else
      {
    $subFlag = $subName -Contains $subscriptionName   

    if($subFlag -eq 'true'){
        $WhatIfStatus = $false

        }      
    }

    # overwrite WhatIfStatus if Deployment Lock or Simulation is enabled
    if ($validateOnly -eq 'true') { $WhatIfStatus = $true }
    if ($deploymentLock -eq 'true') { $WhatIfStatus = $true }

    # return output value
    return $WhatIfStatus
}