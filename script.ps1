param(
	[Parameter(mandatory=$true)]
	[string]$scalingPlan,
	[Parameter(mandatory=$true)]
	[string]$scalingPlanRG,
	[Parameter(mandatory=$true)]
	[string]$hostPoolRG,
	[Parameter()]
	[String]$subscription = "your-subscription-name-here",
	[Parameter(mandatory=$true)]
	[String[]]$hostPools,
	[Parameter(mandatory=$true)]
	[bool]$scalingPlanEnabled,
	[Parameter(mandatory=$true)]
	[bool]$startVMs,
	[Parameter(mandatory=$true)]
	[string]$patchWindow
)

<#

	Before patching set $scalingPlanEnabled to $false and $startVMs to $true to let VMs running before patch window

	After patching is over set $scalingPlanEnabled back to $true and set $startVMs to $false

#>



# Login to Azure
Connect-AzAccount -Identity
# Select subscription scope
Select-AzSubscription $subscription

# Exist if no hostPools provided
if ($hostPools.Count -eq 0) {
	throw "No hostPool(s) provided."
}


# Get HostPoolReferences for the selected scalingplan
$hpRef = Get-AzWvdScalingPlan -Name $scalingPlan -ResourceGroupName $scalingPlanRG | select *
# Iterate through all hostpoolreferences
foreach ($ref in $hpRef.HostPoolReference) {
	# If hostpool is in provided hostPool array, change scaling plan enabled to the selected setting
	if ($ref.HostPoolArmPath.split("/")[-1] -in $hostPools) {
		$ref.ScalingPlanEnabled = $scalingPlanEnabled
	}
}
# Update scaling plan settings. This will enable or disable autoscale for the selected hostpools using the provided scale plan. 
Update-AzWvdScalingPlan -Name $scalingPlan -ResourceGroupName $scalingPlanRG -HostPoolReference $hpRef.HostPoolReference

# Iterate through each hostpool and start all hosts.
# Additionally enable drainmode using the same variable used for enabling/disabling the scalingPlan.
foreach ($hp in $hostPools) {
	Get-AzWvdSessionHost -HostPoolName $hp -ResourceGroupName $hostPoolRG | select * | % {
		if ($startVMs) {
			Start-AzVM -Id $_.ResourceId
		}
		$vm = Get-AZVM -ResourceId $_.ResourceId
		if ($vm.Tags['vm-update'] -eq $patchWindow) {
			Update-AzWvdSessionHost -ResourceGroupName $hostPoolRG -HostPoolName $hp -Name $_.Name.split("/")[-1] -AllowNewSession:$scalingPlanEnabled
		}
	}
}