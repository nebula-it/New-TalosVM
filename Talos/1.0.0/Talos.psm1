function New-TalosVM {
  param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $VMNamePrefix,

    # Parameter help description
    [Parameter()]
    [Int64]
    $CPUCount = 2,

    # Parameter help description
    [Parameter()]
    [Int64]
    $StartupMemory = 4GB,

    # Parameter help description
    [Parameter(Mandatory)]
    [String]
    $SwitchName,

    # Parameter help description
    [Parameter()]
    [ValidateRange(1, 4096)]
    [Int]
    $VLAN,
      
    # Parameter help description
    [Parameter()]
    [Int64]
    $VHDSize = 10GB,

    # Parameter help description
    [Parameter()]
    [Int64]
    $StorageVHDSize,

    # Parameter help description
    [Parameter(Mandatory)]
    [string]
    $TalosISOPath,
      
    # Parameter help description
    [Parameter()]
    [string]
    $VMDestinationBasePath = 'D:\Virtual Machines\Talos VMs\',

    # Parameter help description
    [Parameter()]
    [Int64]
    $NumberOfVMs = 1
  )

  process {
    $results = @()
    for ($i = 1; $i -le $NumberOfVMs; $i++) {
      #Get the name for next VM to create
      $VMName = Get-NextVMNumber $VMNamePrefix
      $VMDestinationPath = Join-Path -Path $VMDestinationBasePath -ChildPath $VMName

      ## Start Region: Setup VM
      Write-Host "Setting up VM $VMName"
      if (!(Test-Path -Path "$VMDestinationPath\Virtual Hard Disks")) {
        New-Item -Path "$VMDestinationPath\Virtual Hard Disks" -ItemType Directory -Force | Out-Null
      }
      $VMProperties = @{
        Name               = $VMName
        MemoryStartupBytes = $StartupMemory
        Generation         = 2
        BootDevice         = "VHD"
        NewVHDPath         = "$VMDestinationPath\Virtual Hard Disks\$VMName.vhdx"              
        Path               = $VMDestinationBasePath
        NewVHDSizeBytes    = $VHDSize
        SwitchName         = $SwitchName
      }
      # $VMProperties

      $results += New-VM @VMProperties
      Write-Host "Done." -ForegroundColor Green
      ## End Region

      ## Start Region: Configure VM
      Write-Host "Configuring VM $VMName..."
      # Setup processor core count
      Set-VM -VMName $VMName -ProcessorCount $CPUCount
      # Add talos .iso as DVD
      Add-VMDvdDrive -VMName $VMName
      Set-VMDvdDrive -VMName $VMName -Path $TalosISOPath
      # Disable Secure boot and setup DVD as boot device
      Set-VMFirmware -VMName $VMName -EnableSecureBoot Off -FirstBootDevice (Get-VMDvdDrive -VMName $VMName)
      # Set VLAN on NIC if a VLAN is provided
      if ($null -ne $VLAN) {
        Set-VMNetworkAdapterVlan -VMName $VMName -VlanId $VLAN -Access
      }
      Write-Host "Done" -ForegroundColor Green
      ## End Region

      ## Start Region: Add second VHD
      # Check if -StorageVHDSize parameter was set, this will only proceed if that was non zero and not a null
      if (($null -ne $StorageVHDSize) -and ($StorageVHDSize -ne 0)) {
        Write-Host "Setting up Storage VHD for $VMName ..." 
        $StorageVHDPath = "$VMDestinationPath\Virtual Hard Disks\$VMName-Storage.vhdx"
        # Check and make sure Storage VHD does not exist already
        if (!(Test-Path -Path $StorageVHDPath)) {
          New-VHD -Path $StorageVHDPath -SizeBytes $StorageVHDSize | Out-Null
          Add-VMHardDiskDrive -VMName $VMName -Path $StorageVHDPath
        }
        else {
          Write-Host "VHD at $StorageVHDPath already exits! Please review and add storage VHD manually." -ForegroundColor Red
        }
      }
      ## End Region

      ## Start Region: Power on VM
      Start-VM -VMName $VMName
      ## End Region
      
    }
    if ($results.count -eq 1) {
      Write-Host "Created 1 VM: "
      $results

    }
    else {
      Write-Host "Created following $($results.Count) VMs: "
      $results | Format-Table
    }
    

  }
}

function Get-NextVMNumber {
  param($prefix)
  # Check if existing VM exist with same name if so it'll return suffix+1 ,e.g if test01 is a VM this will return test02
  if ((Get-VM -name "$prefix*").count -gt 0) {
    $prefix += (([int](get-vm -name "$prefix*" | Select-Object @{ Label = 'Number' ; Expression = { $_.VMName.Substring($prefix.length, 2) } } | Sort-Object number | Select-Object -Last 1).number) + 1).tostring().padleft(2, "0")
  }
  else {
    $prefix += "01"
  }
  return $prefix
}
