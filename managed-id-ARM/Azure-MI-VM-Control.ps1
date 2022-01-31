Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $resourcegroup,    
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $mi_principal_id, 
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $vmname, 
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
    [String] 
    $action
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect to Azure with user-assigned managed identity
# Don't do what Microsoft say - they use Client_Id here but it needs to be
# the managed_identity_principal_id
$AzureContext = (Connect-AzAccount -Identity -AccountId $mi_principal_id).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Account ID of current context: " $AzureContext.Account.Id

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $vmname -Status -DefaultProfile $AzureContext).Statuses[1].Code

Write-Output "`r`n Beginning $vmname VM status: $status `r`n"


if($action -eq "Stop") 
{ 
    Write-Output "Stopping VM: $vmname";
    Stop-AzVM -Name $vmname -ResourceGroupName $resourcegroup -DefaultProfile $AzureContext -Force
} 
else 
{ 
    Write-Output "Starting VM: $vmname";
    Start-AzVM -Name $vmname -ResourceGroupName $resourcegroup -DefaultProfile $AzureContext
}

# Get new state of VM
$status = (Get-AzVM -ResourceGroupName $resourcegroup -Name $vmname -Status -DefaultProfile $AzureContext).Statuses[1].Code  

Write-Output "`r`n Ending $vmname VM status: $status `r`n `r`n"
