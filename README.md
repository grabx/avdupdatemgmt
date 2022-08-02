# Azure Virtual Desktop Update Management Automation

Updating Azure Virtual Desktop Session Host VMs via Update Management can be a bit complicated when using Scaling Plans since VMs can be down when an Update Schedule is run by Azure Automation. This causes asynchronous states for each Session Host in a Host Pool.

This Automation Runbook helps you automate the Scaling Plan Settings and Drain Mode of all Session Hosts of your Host Pools.

It is assumed that you use Azure Automation Update Management with an Azure Query based on Tag values on your Azure VMs.

You will need to create 2 Schedules for each Update Management Update Schedule. 1 Schedule will be run before the Update Management Schedule and the second one will be run after the Update Schedule is over. Link each Schedule to this Automation Runbook and set the parameters accordingly. Please take a look at the [script.ps1](script.ps1) file to get a grasp of the available parameters and what they do.

You will also need to assign a Role of "Contributor" to the Hostpools, Session Hosts and VMs you want to manage with this Runbook. Use the Automation Accounts Managed Identity as the principal since it will be the one running the actions.
