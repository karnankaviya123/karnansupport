$subscriptionId = "your sub ID"
$accname = "your storage account name"
$resourceGroupName = "your rg name"
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

# Function to check if the storage account exists using REST API
$storageEndpoint = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts?api-version=2022-09-01"
$response= Invoke-RestMethod -Uri $storageEndpoint -Method Get -Headers $authHeader -ErrorAction SilentlyContinue
#$response.value


# Check if the storage account already exists

foreach($responses in $response){
if ($responses.value.name -eq $accname ) {
    Write-Host "The storage account $($accname) already exists"
} 
else {
    # Create a new storage account using REST API
    Write-Host "creating $($accName) storage account" -ForegroundColor Green
    $createEndpoint = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$($accname)?api-version=2022-09-01"

    $createPayload = @{
        "location" = "East US"
        "kind" = "StorageV2"
        "sku" = @{
            "name" = "Standard_LRS"
        }
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $createEndpoint -Method PUT -Headers $authHeader -Body $createPayload

}
}
        Write-Host "$($accName) storage account has been created successfully"
