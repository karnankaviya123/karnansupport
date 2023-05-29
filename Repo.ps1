#6f36m3gtwxgpmfhjxzyj6b57i2z4ocwsxdsvfq3n5okfp7j565hq

$personalAccessToken = "6f36m3gtwxgpmfhjxzyj6b57i2z4ocwsxdsvfq3n5okfp7j565hq"

base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)"))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$result = Invoke-RestMethod -Uri "https://dev.azure.com/karnankali1980/_apis/projects?api-version=6.0" -Method Get -Headers $headers

$projectNames = $result.value.name

Write-Host $result.count


for ($i=0 ; $i -le $result.count ; $i++)
{
    
        $project =  $projectNames[$i]
        Write-Host $project
        #git clone https://ccscandy.visualstudio.com/$project/_git/DevOps $project
}