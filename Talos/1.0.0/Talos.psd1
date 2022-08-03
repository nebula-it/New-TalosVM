@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'Talos.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# ID used to uniquely identify this module
GUID = 'f9a22f56-c5c7-46fe-bd5a-9ba71ad650fd'

# Author of this module
Author = 'Nebula'

# Description of the functionality provided by this module
Description = 'Powershell function to create new Talos VMs (https://www.talos.dev/).'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Functions to export from this module
FunctionsToExport = @( 
    'New-TalosVM'
)

}
