﻿# This started from https://blogs.msdn.microsoft.com/taylorb/2014/11/03/setting-guest-ip-addresses-from-the-host/


param ( 
    $vm = $null,
    $vmNetworkAdapter = $null #TODO implement this
)

if ($vm -eq $null)
{
    Write-Error "-vm is required"
    exit
}

#Get an instance of the management service, the Msvm Computer System and setting data
$Msvm_VirtualSystemManagementService = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService

# Get instance of VM
$Msvm_ComputerSystem = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "Name='$($vm.VMId)'"
$Msvm_VirtualSystemSettingData = $Msvm_ComputerSystem.GetRelated(
    "Msvm_VirtualSystemSettingData", 
    "Msvm_SettingsDefineState", 
    $null, 
    $null, 
    "SettingData", 
    "ManagedElement", 
    $false, 
    $null)

#Get an instance of the port setting data object and the related guest network configuration object
$Msvm_SyntheticEthernetPortSettingData = $Msvm_VirtualSystemSettingData.GetRelated("Msvm_SyntheticEthernetPortSettingData")
$Msvm_GuestNetworkAdapterConfigurations = $Msvm_SyntheticEthernetPortSettingData.GetRelated(
    "Msvm_GuestNetworkAdapterConfiguration", 
    "Msvm_SettingDataComponent", 
    $null, 
    $null, 
    "PartComponent", 
    "GroupComponent", 
    $false, 
    $null)
$Msvm_GuestNetworkAdapterConfiguration = ($Msvm_GuestNetworkAdapterConfigurations | % {$_})

#Set the IP address and related information
$Msvm_GuestNetworkAdapterConfiguration.DHCPEnabled = $false
$Msvm_GuestNetworkAdapterConfiguration.IPAddresses = @("192.168.0.10")
$Msvm_GuestNetworkAdapterConfiguration.Subnets = @("255.255.255.0")
$Msvm_GuestNetworkAdapterConfiguration.DefaultGateways = @("192.168.0.1")
$Msvm_GuestNetworkAdapterConfiguration.DNSServers = @("192.168.0.2", "192.168.0.3")

#Set the IP address
$Msvm_VirtualSystemManagementService.SetGuestNetworkAdapterConfiguration(
    $Msvm_ComputerSystem.Path, 
    $Msvm_GuestNetworkAdapterConfiguration.GetText(1))