###############################################################################
## Start Powershell Cmdlets
###############################################################################

###############################################################################
# Get-PaActiveRoute

function Get-PaActiveRoute {
    [CmdletBinding()]
    Param (
    )

    $Command = "<show><routing><route></route></routing></show>"

    $ResponseData = Invoke-PaOperation $Command
    $Global:test = $ResponseData
    
    $Flags = @{ 'A' = 'active'
                '?' = 'loose'
                'C' = 'connect'
                'H' = 'host'
                'S' = 'static'
                '~' = 'internal'
                'R' = 'rip'
                'O' = 'ospf'
                'B' = 'bgp'
                'Oi' = 'ospf intra-area'
                'Oo' = 'ospf inter-area'
                'O1' = 'ospf ext-type-1'
                'O2' = 'ospf ext-type-2'
                'E' = 'ecmp' }


    $ResponseTable = @()

    foreach ($r in $ResponseData.entry) {
        $ResponseObject                = New-Object PowerAlto.ActiveRoute
        $EntryFlags = $r.flags.trim().split()
        $RealFlags = @()
        Foreach ($e in $EntryFlags) {
            $RealFlags += $Flags.get_item($e)
        }

        $ResponseObject.VirtualRouter  = $r.'virtual-router'
        $ResponseObject.Destination    = $r.destination
        $ResponseObject.NextHop        = $r.nexthop
        $ResponseObject.Metric         = $r.metric
        $ResponseObject.Flags          = $RealFlags
        $ResponseObject.Age            = $r.age
        $ResponseObject.Interface      = $r.interface

        $ResponseTable                += $ResponseObject
    }

    return $ResponseTable
}

###############################################################################
# Get-PaAddressGroupObject

function Get-PaAddressGroupObject {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $InfoObject   = New-Object PowerAlto.AddressGroupObject
    $Xpath        = $InfoObject.BaseXPath
    $RootNodeName = 'address-group'

    if ($Name) { $Xpath += "/entry[@name='$Name']" }
    Write-Debug "xpath: $Xpath"

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    Write-Debug "action: $Action"
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."

    if ($ResponseData.$RootNodeName) { $ResponseData = $ResponseData.$RootNodeName.entry } `
                                else { $ResponseData = $ResponseData.entry         }

    $ResponseTable = @()
    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.AddressGroupObject
        Write-Verbose "Creating new AddressGroupObject"
        
        $ResponseObject.Name = $r.name
        Write-Verbose "Setting Address Group Name $($r.name)"
        
        if ($r.dynamic) {
            $ResponseObject.Type = 'dynamic'
            $ResponseObject.Filter = $r.dynamic.filter.trim()
        }

        if ($r.static) {
            $ResponseObject.Type = 'static'
            $ResponseObject.Members = HelperGetPropertyMembers $r static
        }

        $ResponseObject.Tags = HelperGetPropertyMembers $r tag
        $ResponseObject.Description = $r.description


        $ResponseTable += $ResponseObject
        Write-Verbose "Adding object to array"
    }

    #############################################
    # Lookup dynamic members

    $DynamicGroups = $ResponseTable | ? { $_.Type -eq 'dynamic' }
    if ($DynamicGroups) {
        $Addresses = Get-PaAddressObject
        foreach ($d in $DynamicGroups) {
            $Expression = HelperConvertFilterToPosh $d.Filter Addresses Tags
            Write-Verbose $d.Filter
            Write-Verbose $Expression
            $Members = @(iex $Expression)
            $d.Members = $Members.Name
        }
    }
    
    return $ResponseTable
}

###############################################################################
# Get-PaAddressObject

function Get-PaAddressObject {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $Xpath = "/config/devices/entry/vsys/entry/address"

    if ($Name) { $Xpath += "/entry[@name='$Name']" }

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."
    Write-Debug $ResponseData

    if ($ResponseData.address) { $ResponseData = $ResponseData.address.entry } `
                       else { $ResponseData = $ResponseData.entry             }

    $ResponseTable = @()
    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.AddressObject
        Write-Verbose "Creating new AddressObject"
        
        $ResponseObject.Name = $r.name
        Write-Verbose "Setting Address Name $($r.name)"
        
        if ($r.'ip-netmask') {
        #    $ResponseObject.AddressType = 'ip-netmask'
            $ResponseObject.Address = $r.'ip-netmask'
            Write-Verbose "Setting Address: ip-netmask/$($r.'ip-netmask')"
        }

        if ($r.'ip-range') {
        #    $ResponseObject.AddressType = 'ip-range'
            $ResponseObject.Address = $r.'ip-range'
            Write-Verbose "Setting Address: ip-range/$($r.'ip-range')"
        }

        if ($r.fqdn) {
        #    $ResponseObject.AddressType = 'fqdn'
            $ResponseObject.Address = $r.fqdn
            Write-Verbose "Setting Address: fqdn/$($r.fqdn)"
        }

        $ResponseObject.Tags = HelperGetPropertyMembers $r tag
        $ResponseObject.Description = $r.description


        $ResponseTable += $ResponseObject
        Write-Verbose "Adding object to array"
    }
    
    return $ResponseTable
}

###############################################################################
# Get-PaApplicationGroupObject

function Get-PaApplicationGroupObject {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $InfoObject   = New-Object PowerAlto.ApplicationGroupObject
    $Xpath        = $InfoObject.BaseXPath
    $RootNodeName = 'application-group'

    if ($Name) { $Xpath += "/entry[@name='$Name']" }
    Write-Debug "xpath: $Xpath"

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    Write-Debug "action: $Action"
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."

    if ($ResponseData.$RootNodeName) { $ResponseData = $ResponseData.$RootNodeName.entry } `
                                else { $ResponseData = $ResponseData.entry         }

    $ResponseTable = @()
    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.ApplicationGroupObject
        Write-Verbose "Creating new ApplicationGroupObject"
        
        $ResponseObject.Name = $r.name
        Write-Verbose "Setting Application Group Name $($r.name)"
        
        $ResponseObject.Members = $r.Member

        $ResponseTable += $ResponseObject
        Write-Verbose "Adding object to array"
    }
    
    return $ResponseTable
}

###############################################################################
# Get-PaConfig

function Get-PaConfig {
	Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Xpath = "/config",

        [Parameter(Mandatory=$False,Position=1)]
        [ValidateSet("get","show")]
        [string]$Action = "show"
    )

    HelperCheckPaConnection

    $QueryTable = @{ type   = "config"
                     xpath  = $Xpath
                     action = $Action  }
    
    $QueryString = HelperCreateQueryString $QueryTable
    $Url         = $global:PaDeviceObject.UrlBuilder($QueryString)
    $Response    = $global:PaDeviceObject.HttpQuery($url)
    $global:test2 = $Response

    return HelperCheckPaError $Response
}

###############################################################################
# Get-PaContentUpgrades

function Get-PaContentUpgrades {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet,

        [Parameter(Mandatory=$False)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory=$False)]
        [switch]$WaitForCompletion,

        [Parameter(Mandatory=$True,ParameterSetName="av")]
        [switch]$Antivirus,

        [Parameter(Mandatory=$True,ParameterSetName="app")]
        [switch]$AppsAndThreats
    )
    

    if ($Antivirus) {
        $Command = "<request><anti-virus><upgrade><download><latest></latest></download></upgrade></anti-virus></request>"
    }
    if ($AppsAndThreats) {
        $Command = "<request><content><upgrade><download><latest></latest></download></upgrade></content></request>"
    }

    if ($ShowProgress) { $WaitForCompletion = $true }

    $ResponseData = Invoke-PaOperation $Command
    $global:test = $ResponseData
    $Job = $ResponseData.job

    $JobParams = @{ 'Id' = $Job
                    'CheckInterval' = 5 }
    if ($ShowProgress)      { $JobParams += @{ 'ShowProgress' = $true } }
    if ($WaitForCompletion) { $JobParams += @{ 'WaitForCompletion' = $true } }

    $JobStatus = Get-PaJob @JobParams
    if ($JobStatus.Result -eq 'Fail') {
        Throw $JobStatus.Details
    } else {
        if (!($Quiet)) {
            return $JobStatus.Details
        }
    }
    
}

###############################################################################
# Get-PaCustomUrlCategory

function Get-PaCustomUrlCategory {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $InfoObject   = New-Object PowerAlto.CustomUrlCategory
    $Xpath        = $InfoObject.BaseXPath
    $RootNodeName = 'custom-url-category'

    if ($Name) { $Xpath += "/entry[@name='$Name']" }
    Write-Debug "xpath: $Xpath"

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    Write-Debug "action: $Action"
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."

    if ($ResponseData.$RootNodeName) { $ResponseData = $ResponseData.$RootNodeName.entry } `
                                else { $ResponseData = $ResponseData.entry         }

    $ResponseTable = @()
    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.CustomUrlCategory
        Write-Verbose "Creating new CustomUrlCategory Object"
        
        $ResponseObject.Name = $r.name
        Write-Verbose "Setting URL Category Name $($r.name)"
        
        $ResponseObject.Members = HelperGetPropertyMembers $r list
        $ResponseObject.Description = $r.description

        $ResponseTable += $ResponseObject
        Write-Verbose "Adding object to array"
    }
    
    return $ResponseTable
}

###############################################################################
# Get-PaDevice

function Get-PaDevice {
    [CmdletBinding()]
	<#
	.SYNOPSIS
		Establishes initial connection to Palo Alto API.
		
	.DESCRIPTION
		The Get-PaDevice cmdlet establishes and validates connection parameters to allow further communications to the Palo Alto API. The cmdlet needs at least two parameters:
		 - The device IP address or FQDN
		 - A valid API key
		
		
		The cmdlet returns an object containing details of the connection, but this can be discarded or saved as desired; the returned object is not necessary to provide to further calls to the API.
	
	.EXAMPLE
		Get-PaDevice "pa.example.com" "LUFRPT1PR2JtSDl5M2tjTktBeTkyaGZMTURTTU9BZm89OFA0Rk1WMS8zZGtKN0F"
		
		Connects to PRTG using the default port (443) over SSL (HTTPS) using the username "jsmith" and the passhash 1234567890.
		
	.EXAMPLE
		Get-PrtgServer "prtg.company.com" "jsmith" 1234567890 -HttpOnly
		
		Connects to PRTG using the default port (80) over SSL (HTTP) using the username "jsmith" and the passhash 1234567890.
		
	.EXAMPLE
		Get-PrtgServer -Server "monitoring.domain.local" -UserName "prtgadmin" -PassHash 1234567890 -Port 8080 -HttpOnly
		
		Connects to PRTG using port 8080 over HTTP using the username "prtgadmin" and the passhash 1234567890.
		
	.PARAMETER Server
		Fully-qualified domain name for the PRTG server. Don't include the protocol part ("https://" or "http://").
		
	.PARAMETER UserName
		PRTG username to use for authentication to the API.
		
	.PARAMETER PassHash
		PassHash for the PRTG username. This can be retrieved from the PRTG user's "My Account" page.
	
	.PARAMETER Port
		The port that PRTG is running on. This defaults to port 443 over HTTPS, and port 80 over HTTP.
	
	.PARAMETER HttpOnly
		When specified, configures the API connection to run over HTTP rather than the default HTTPS.
		
	.PARAMETER Quiet
		When specified, the cmdlet returns nothing on success.
	#>

	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[ValidatePattern("\d+\.\d+\.\d+\.\d+|(\w\.)+\w")]
		[string]$Device,

        [Parameter(ParameterSetName="keyonly",Mandatory=$True,Position=1)]
        [string]$ApiKey,

        [Parameter(ParameterSetName="credential",Mandatory=$True,Position=1)]
        [pscredential]$PaCred,

		[Parameter(Mandatory=$False,Position=2)]
		[int]$Port = $null,

		[Parameter(Mandatory=$False)]
		[alias('http')]
		[switch]$HttpOnly,
		
		[Parameter(Mandatory=$False)]
		[alias('q')]
		[switch]$Quiet
	)

    BEGIN {

		if ($HttpOnly) {
			$Protocol = "http"
			if (!$Port) { $Port = 80 }
		} else {
			$Protocol = "https"
			if (!$Port) { $Port = 443 }
			
			$global:PaDeviceObject = New-Object Poweralto.PaDevice
			
			$global:PaDeviceObject.Protocol = $Protocol
			$global:PaDeviceObject.Port     = $Port
			$global:PaDeviceObject.Device   = $Device

            if ($ApiKey) {
                $global:PaDeviceObject.ApiKey = $ApiKey
            } else {
                $UserName = $PaCred.UserName
                $Password = $PaCred.getnetworkcredential().password
            }
			
			$global:PaDeviceObject.OverrideValidation()
		}
    }

    PROCESS {
        
        if (!($ApiKey)) {
            $QueryStringTable = @{ type     = "keygen"
                                   user     = $UserName
                                   password = $Password }

            $QueryString = HelperCreateQueryString $QueryStringTable
			Write-Debug $QueryString
		    $url         = $global:PaDeviceObject.UrlBuilder($QueryString)

		    try   { $QueryObject = $global:PaDeviceObject.HttpQuery($url) } `
            catch {	throw $_.Exception.Message	           }

            $Data                  = HelperCheckPaError $QueryObject
            $global:PaDeviceObject.ApiKey = $Data.key
        }
        
        $QueryStringTable = @{ type = "op"
                               cmd  = "<show><system><info></info></system></show>" }

        $QueryString = HelperCreateQueryString $QueryStringTable
        Write-Debug "QueryString: $QueryString"
		$url         = $global:PaDeviceObject.UrlBuilder($QueryString)
        Write-Debug "URL: $Url"

		try   { $QueryObject = $global:PaDeviceObject.HttpQuery($url) } `
        catch {	throw $_.Exception.Message       	           }

        $Data = HelperCheckPaError $QueryObject
		$Data = $Data.system

        $global:PaDeviceObject.Name            = $Data.hostname
        $global:PaDeviceObject.Model           = $Data.model
        $global:PaDeviceObject.Serial          = $Data.serial
        $global:PaDeviceObject.OsVersion       = $Data.'sw-version'
        $global:PaDeviceObject.GpAgent         = $Data.'global-protect-client-package-version'
        $global:PaDeviceObject.AppVersion      = $Data.'app-version'
        $global:PaDeviceObject.ThreatVersion   = $Data.'threat-version'
        $global:PaDeviceObject.WildFireVersion = $Data.'wildfire-version'
        $global:PaDeviceObject.UrlVersion      = $Data.'url-filtering-version'

        #$global:PaDeviceObject = $PaDeviceObject

		
		if (!$Quiet) {
			return $global:PaDeviceObject | Select-Object @{n='Connection';e={$_.ApiUrl}},Name,OsVersion
		}
    }
}

###############################################################################
# Get-PaDiskSpace

function Get-PaDiskSpace {
    [CmdletBinding()]
    Param (
    )

    $Command = "<show><system><disk-space></disk-space></system></show>"

    $ResponseData = Invoke-PaOperation $Command
    $Global:test = $ResponseData

    $ResponseSplit = $ResponseData.'#cdata-section'.Split("`r`n")
    
    $OutputRx = [regex] '(?msx)
                         (?<filesystem>[a-z0-9\/]+)\ +
                         (?<size>[0-9\.A-Z]+)\ +
                         (?<used>[0-9\.A-Z]+)\ +
                         (?<available>[0-9\.A-Z]+)\ +
                         (?<percent>\d+%)\ +
                         (?<mount>[\/a-z]+)
                         '
    $ReturnObjects = @()

    foreach ($r in $ResponseSplit) {
        $Match = $OutputRx.Match($r)
        if ($Match.Success) {
            $ReturnObject             = "" | Select FileSystem,Size,Used,Available,PercentUsed,MountPoint
            $ReturnObject.FileSystem  = $Match.Groups['filesystem'].Value
            $ReturnObject.Size        = $Match.Groups['size'].Value
            $ReturnObject.Used        = $Match.Groups['used'].Value
            $ReturnObject.Available   = $Match.Groups['available'].Value
            $ReturnObject.PercentUsed = $Match.Groups['percent'].Value
            $ReturnObject.MountPoint  = $Match.Groups['mount'].Value
            
            $ReturnObjects += $ReturnObject
        }
    }

    return $ReturnObjects
}

###############################################################################
# Get-PaInterfaceConfig

function Get-PaInterfaceConfig {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False,Position=0)]
        #[ValidatePattern("\w+|(\w\.)+\w")]
        [string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Ethernet,

        [Parameter(Mandatory=$False)]
        [switch]$Loopback,

        [Parameter(Mandatory=$False)]
        [switch]$Vlan,

        [Parameter(Mandatory=$False)]
        [switch]$Tunnel,
        
        [Parameter(Mandatory=$False)]
        [switch]$Aggregate,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    if ($Ethernet -or $Loopback -or $Vlan -or $Tunnel) {
        $TypeSpecified = $True
    }

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    
    $ElementName = "network/interface"
    $Xpath = "/config/devices/entry/$ElementName"
    $InterfaceTypeRx = [regex] '(?<type>loopback|vlan|tunnel|ethernet|ae)(?<num>\d+\/\d+|\.\d+|\d+)?(?<sub>\.\d+)?'

    if ($Name) {
        $InterfaceMatch = $InterfaceTypeRx.Match($Name)
        $InterfaceType  = $InterfaceMatch.Groups['type'].Value

        Write-Verbose $InterfaceMatch.Value

        switch ($InterfaceType) {
            { ($_ -eq "loopback") -or
              ($_ -eq "vlan") -or
              ($_ -eq "tunnel") } {
                if ($InterfaceMatch.Groups['num'].Success) {
                    $Xpath += "/$InterfaceType/units/entry[@name='$Name']"
                } else {
                    $Xpath += "/$Name"
                }
            }
            ethernet {
                $Xpath += "/$InterfaceType/entry[@name='$($InterfaceMatch.Groups['type'].Value)$($InterfaceMatch.Groups['num'].Value)']"
                if ($InterfaceMatch.Groups['sub'].Success) {
                    $Xpath += "/layer3/units/entry[@name='$Name']"
                }
            }
            default {
                $Xpath += "/$InterfaceType/entry[@name='$Name']"
            }
        }
    }

    Write-Verbose $Xpath

    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."
    $Global:test = $ResponseData

    function ProcessInterface ($entry) {
        $interfaceObject                = New-Object PowerAlto.InterfaceConfig
        $interfaceObject.Name           = $entry.name
        $interfaceObject.AggregateGroup = $entry.'aggregate-group'
        $interfaceObject.Comment        = $entry.comment
        $InterfaceObject.AdminSpeed     = $Entry.'link-speed'
        $InterfaceObject.AdminDuplex    = $Entry.'link-duplex'
        $InterfaceObject.AdminState     = $Entry.'link-state'

        if ($entry.layer3 -or ($entry.firstchild.name -eq 'tap')) {
            $interfaceObject.MgmtProfile    = $entry.layer3.'interface-management-profile'
            $interfaceObject.NetflowProfile = $entry.layer3.'netflow-profile'
            $interfaceObject.IpAddress      = $entry.layer3.ip.entry.name

            if ($entry.layer3) {
                $interfaceObject.Type = 'layer3'
            } elseif ($entry.firstchild.name -eq 'tap') {
                $interfaceObject.Type = 'tap'
            }

            if ($entry.layer3.'untagged-sub-interface' -eq 'yes') {
                $interfaceObject.UntaggedSub = $true
            }

            if ($entry.layer3.'dhcp-client'.enable -eq 'yes') {
                $interfaceObject.IsDhcp = $true

                if ($entry.layer3.'dhcp-client'.'create-default-route' -eq 'yes') {
                    $interfaceObject.CreateDefaultRoute = $true
                }
            }
        } elseif ($entry.ip.entry.name) {
            $interfaceObject.MgmtProfile = $entry.'interface-management-profile'
            $interfaceObject.IpAddress   = $entry.ip.entry.name
            $interfaceObject.Tag         = $entry.tag

            switch ($entry.name) {
                { $_ -match 'ethernet' } {
                    $interfaceObject.Type = 'subinterface'
                }
            }
        }

        return $interfaceObject
    }


    ###############################################################################
    # Process Response

    if ($Name) {
        if ($ResponseData.entry) {
            ProcessInterface $ResponseData.entry
        } else {
            ProcessInterface $ResponseData.$Name
        }

        return $InterfaceObject
    } else {
        $InterfaceObjects = @()

        ###############################################################################
        # Ethernet Interfaces

        if ($Ethernet -or (!($TypeSpecified))) {
            Write-Verbose '## Ethernet Interfaces ##'
            foreach ($e in $ResponseData.interface.ethernet.entry) {
                if (($e.layer3) -or `
                    ($e.firstchild.name -eq 'tap') -or `
                    ($e.'aggregate-group')) {

                    Write-Verbose $e.name
                    $InterfaceObjects += ProcessInterface $e
                    if ($e.layer3.units) {
                        foreach ($u in $e.layer3.units.entry) {
                            Write-Verbose $u.name
                            $InterfaceObjects += ProcessInterface $u
                        }
                    }
                }
            }
        }

        ###############################################################################
        # Aggregate Interfaces

        if ($Ethernet -or (!($TypeSpecified))) {
            Write-Verbose '## Ethernet Interfaces ##'
            foreach ($e in $ResponseData.interface.'aggregate-ethernet'.entry) {
                if ($e.layer3) {

                    Write-Verbose $e.name
                    $InterfaceObjects += ProcessInterface $e
                    if ($e.layer3.units) {
                        foreach ($u in $e.layer3.units.entry) {
                            Write-Verbose $u.name
                            $InterfaceObjects += ProcessInterface $u
                        }
                    }
                }
            }
        }

        ###############################################################################
        # Loopback Interfaces

        if ($Loopback -or (!($TypeSpecified))) {
            Write-Verbose '## Loopback Interfaces ##'
            foreach ($e in $ResponseData.interface.loopback) {
                Write-Verbose 'loopback'
                $InterfaceObjects += ProcessInterface $e
                if ($e.units) {
                    foreach ($u in $e.units.entry) {
                        Write-Verbose $u.name
                        $InterfaceObjects += ProcessInterface $u
                    }
                }
            }
        }

        ###############################################################################
        # Vlan Interfaces

        if ($Vlan -or (!($TypeSpecified))) {
            Write-Verbose '## Vlan Interfaces ##'
            foreach ($e in $ResponseData.interface.vlan) {
                $InterfaceObjects += ProcessInterface $e
                Write-Verbose 'vlan'
                if ($e.units) {
                    foreach ($u in $e.units.entry) {
                        Write-Verbose $u.name
                        $InterfaceObjects += ProcessInterface $u
                    }
                }
            }
        }

        ###############################################################################
        # Tunnel Interfaces

        if ($Tunnel -or (!($TypeSpecified))) {
            Write-Verbose '## Tunnel Interfaces ##'
            foreach ($e in $ResponseData.interface.tunnel) {
                Write-Verbose "tunnel"
                $InterfaceObjects += ProcessInterface $e
                if ($e.units) {
                    foreach ($u in $e.units.entry) {
                        Write-Verbose $u.name
                        $InterfaceObjects += ProcessInterface $u
                    }
                }
            }
        }
        
        return $InterfaceObjects
    }
}

###############################################################################
# Get-PaInterfaceCounter

function Get-PaInterfaceCounter {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [ValidatePattern('^(ethernet\d+\/\d+(\.\d+)?|(loopback|tunnel|vlan|ae\d)(\.\d+)?)$')]
        [string]$Name
    )

    if ($Ethernet -or $Loopback -or $Vlan -or $Tunnel) {
        $TypeSpecified = $True
    }

    if ($Name) {
        $Command = "<show><counter><interface>$Name</interface></counter></show>"
    } else {
        $Command = "<show><counter><interface>all</interface></counter></show>"
    }

    $ResponseData = Invoke-PaOperation $Command
    $Global:test = $ResponseData

    function ProcessInterface ($entry) {
        $interfaceObject = New-Object PowerAlto.InterfaceStatus
        
        #tunnel:      .ifnet.entry
        #loopback:    .ifnet.entry
        #subinterface .ifnet.entry
        #vlan:        .hw.entry
        #ae:          .hw.entry
        #ethernet:    .hw.entry



        if ($entry.hw.entry) {
            Write-Verbose "hw found"

            $interfaceObject.InBytes  = $entry.hw.entry.ibytes
            $interfaceObject.OutBytes = $entry.hw.entry.obytes
            $interfaceObject.InDrops  = $entry.hw.entry.idrops
            $interfaceObject.InErrors = $entry.hw.entry.ierrors
        } else {
            Write-Verbose "hw not found"

            $interfaceObject.InBytes  = $entry.ifnet.entry.ibytes
            $interfaceObject.OutBytes = $entry.ifnet.entry.obytes
            $interfaceObject.InDrops  = $entry.ifnet.entry.idrops
            $interfaceObject.InErrors = $entry.ifnet.entry.ierrors
        }

        $interfaceObject.Name          = $entry.ifnet.entry.name
        
        return $interfaceObject
    }

    return ProcessInterface $ResponseData
}

###############################################################################
# Get-PaInterfaceStatus

function Get-PaInterfaceStatus {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [ValidatePattern('^(ethernet\d+\/\d+(\.\d+)?|(loopback|tunnel|vlan)(\.\d+)?)$')]
        [string]$Name
    )

    if ($Ethernet -or $Loopback -or $Vlan -or $Tunnel) {
        $TypeSpecified = $True
    }

    if ($Name) {
        $Command = "<show><interface>$Name</interface></show>"
    } else {
        $Command = "<show><interface>all</interface></show>"
    }

    $ResponseData = Invoke-PaOperation $Command
    $Global:test = $ResponseData

    function ProcessInterface ($entry,$hw) {
        $interfaceObject = New-Object PowerAlto.InterfaceStatus
        
        if ($hw) {
            Write-Verbose "hw found"
            $interfaceObject.MacAddress = $hw.mac
            $interfaceObject.Speed      = $hw.speed
            $interfaceObject.Duplex     = $hw.duplex

            $interfaceObject.InBytes  = $entry.counters.hw.entry.ibytes
            $interfaceObject.OutBytes = $entry.counters.hw.entry.obytes
            $interfaceObject.InDrops  = $entry.counters.hw.entry.idrops
            $interfaceObject.InErrors = $entry.counters.hw.entry.ierrors
        } else {
            $interfaceObject.InBytes  = $entry.counters.ifnet.entry.ibytes
            $interfaceObject.OutBytes = $entry.counters.ifnet.entry.obytes
            $interfaceObject.InDrops  = $entry.counters.ifnet.entry.idrops
            $interfaceObject.InErrors = $entry.counters.ifnet.entry.ierrors
        }

        $interfaceObject.Name          = $entry.name
        $interfaceObject.Vsys          = $entry.vsys
        $interfaceObject.Mtu           = $entry.mtu
        $interfaceObject.VirtualRouter = $entry.vr
        $interfaceObject.Mode          = $entry.mode
        $interfaceObject.Zone          = $entry.zone
        $interfaceObject.Tag           = $entry.tag

        if ($entry.'dyn-addr'.member) {
            $interfaceObject.IpAddress = @($entry.'dyn-addr'.member)
        } elseif ($entry.addr.member) {
            $interfaceObject.IpAddress = @($entry.addr.member)
        }
        
        return $interfaceObject
    }

    return ProcessInterface $ResponseData.ifnet $ResponseData.hw
}

###############################################################################
# Get-PaJob

function Get-PaJob {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False,Position=0)]
        [int]$Id,

        [Parameter(Mandatory=$False)]
        [switch]$ShowProgress,

        [Parameter(Mandatory=$False)]
        [switch]$WaitForCompletion,

        [Parameter(Mandatory=$False)]
        [int]$CheckInterval = 15
    )

    $CmdletName = $MyInvocation.MyCommand.Name

    if ($Id) {
        $Command = "<show><jobs><id>$Id</id></jobs></show>"
    } else {
        $Command = "<show><jobs><all></all></jobs></show>"
    }

    if ($ShowProgress) { $WaitForCompletion = $true }

    $ResponseData = Invoke-PaOperation $Command
    $Global:test = $ResponseData

    function ProcessEntry ($Entry) {
        $NewJob = New-Object PowerAlto.Job
        $NewJob.Id = $Entry.id
        $NewJob.TimeEnqueued = $Entry.tenq
        $NewJob.User = $Entry.user
        $NewJob.Type = $Entry.type
        $NewJob.Status = $Entry.status
        $NewJob.Result = $Entry.result
        $NewJob.TimeCompleted = $Entry.tfin
        if ($Entry.details.line.newjob) {
            $NewJob.Details = $Entry.details.line.newjob.newmsg
            $NewJob.NextJob = [int]($Entry.details.line.newjob.nextjob)
        } else {
            $NewJob.Details = $Entry.details.line
        }
        $NewJob.Warnings = $Entry.warnings.line

        if ($Entry.stoppable -eq 'yes') {
            $NewJob.Stoppable = $true
        } else {
            $NewJob.Stoppable = $False
        }

        if ($Entry.progress -match '^\d+$') {
            $NewJob.Progress = $Entry.progress
        } elseif ($Entry.Status -eq 'FIN') {
            $NewJob.Progress = 100
        }

        return $NewJob
    }

    $ReturnObjects = @()

    if ($WaitForCompletion) {
        $ActiveJob = ProcessEntry $ResponseData.job
        if ($ShowProgress) {
            $ProgressParams = @{'Activity'         = $ActiveJob.Type
                                'CurrentOperation' = "Checking status in $CheckInterval seconds..."
                                'Status'           = "$($ActiveJob.Progress)% complete"
                                'Id'               = $ActiveJob.Id
                                'PercentComplete'  = $ActiveJob.Progress}
            Write-Progress @ProgressParams
        }

        while ($ActiveJob.Progress -ne 100) {

            $i = 0
            while ($i -lt $CheckInterval) {
                Start-Sleep -s 1
                $i ++
                if ($ShowProgress) {
                    $ProgressParams.Set_Item("CurrentOperation","Checking Status in $($CheckInterval - $i) seconds...")
                    Write-Progress @ProgressParams
                }
            }
            
            $CurrentOperation = "Checking status now"
            HelperWriteCustomVerbose $CmdletName $CurrentOperation
            if ($ShowProgress) {
                $ProgressParams.Set_Item("CurrentOperation",$CurrentOperation)
                Write-Progress @ProgressParams
            }
             
            $UpdateJob = Invoke-PaOperation $Command
            $ActiveJob = ProcessEntry $UpdateJob.Job
            $Status    = "$($ActiveJob.Progress)% complete"
            HelperWriteCustomVerbose $CmdletName $Status

            if ($ShowProgress) {
                $ProgressParams.Set_Item("PercentComplete",$ActiveJob.Progress)
                $ProgressParams.Set_Item('Status',"$($ActiveJob.Progress)% complete")
                Write-Progress @ProgressParams
            }
        }
        $ReturnObjects += $ActiveJob
    } else {
        foreach ($j in $ResponseData.job) {
            $ReturnObjects += ProcessEntry $j
        }
    }

    return $ReturnObjects
}

###############################################################################
# Get-PaLicense

function Get-PaLicense {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Fetch,

        [Parameter(Mandatory=$False)]
        [switch]$Quiet

    )

    $Command = "<request><license><fetch></fetch></license></request>"

    $ResponseData = Invoke-PaOperation $Command

    if ($Quiet) {
        return $true
    } else {
        return $ResponseData.licenses.entry
    }
}

###############################################################################
# Get-PaNatPolicy

function Get-PaNatPolicy {
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $InfoObject   = New-Object PowerAlto.NatPolicy
    $Xpath        = $InfoObject.BaseXPath
    $RootNodeName = 'rules'

    if ($Name) { $Xpath += "/entry[@name='$Name']" }
    Write-Debug "xpath: $Xpath"

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    Write-Debug "action: $Action"
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."

    if ($ResponseData.$RootNodeName) { $ResponseData = $ResponseData.$RootNodeName.entry } `
                                else { $ResponseData = $ResponseData.entry         }

    $ResponseTable = @()

    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.NatPolicy
        Write-Verbose "Creating new NatPolicy"
        
        $ResponseObject.Name        = $r.name
        $ResponseObject.Tags        = HelperGetPropertyMembers $r tag
        $ResponseObject.Description = $r.description
        $ResponseObject.NatType     = $r.'nat-type'

        $ResponseObject.SourceZone           = HelperGetPropertyMembers $r from
        $ResponseObject.DestinationZone      = HelperGetPropertyMembers $r to
        $ResponseObject.Service              = $r.service
        $ResponseObject.DestinationInterface = $r.'to-interface'
        $ResponseObject.SourceAddress        = HelperGetPropertyMembers $r source
        $ResponseObject.DestinationAddress   = HelperGetPropertyMembers $r destination

        $SourceTranslation = $r.'source-translation'
        if ($SourceTranslation.'static-ip') {
            $ResponseObject.SourceTranslationType = "StaticIp"

            if ($SourceTranslation.'static-ip'.'bi-directional' -eq 'yes') {
                $ResponseObject.IsBidirectional = $true
            } else {
                $ResponseObject.IsBidirectional = $false
            }

            if ($SourceTranslation.'static-ip'.'translated-address') {
                $ResponseObject.SourceTranslatedAddressType = "TranslatedAddress"
                $ResponseObject.SourceTranslatedAddress = $SourceTranslation.'static-ip'.'translated-address'
            }
        } elseif ($SourceTranslation.'dynamic-ip-and-port') {
            $ResponseObject.SourceTranslationType = 'DynamicIpAndPort'
            if ($SourceTranslation.'dynamic-ip-and-port'.'interface-address') {
                $ResponseObject.SourceTranslatedAddressType = 'InterfaceAddress'
                $ResponseObject.SourceTranslatedInterface = $SourceTranslation.'dynamic-ip-and-port'.'interface-address'.interface
                $ResponseObject.SourceTranslatedAddress = $SourceTranslation.'dynamic-ip-and-port'.'interface-address'.ip
            }
        }

        $ResponseTable += $ResponseObject

        <#
        DestinationAddressTranslation :
        DestinationTranslatedPort     :
        #>

    }
    return $ResponseTable

}

###############################################################################
# Get-PaQosPolicy

function Get-PaQosPolicy {
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $InfoObject   = New-Object PowerAlto.QosPolicy
    $Xpath        = $InfoObject.BaseXPath
    $RootNodeName = 'rules'

    if ($Name) { $Xpath += "/entry[@name='$Name']" }
    Write-Debug "xpath: $Xpath"

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    Write-Debug "action: $Action"
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."

    if ($ResponseData.$RootNodeName) { $ResponseData = $ResponseData.$RootNodeName.entry } `
                                else { $ResponseData = $ResponseData.entry         }

    $ResponseTable = @()

    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.QosPolicy
        
        $ResponseObject.Name        = $r.name
        $ResponseObject.Tags        = HelperGetPropertyMembers $r tag
        $ResponseObject.Description = $r.description
        

        $ResponseObject.SourceZone    = HelperGetPropertyMembers $r from
        $ResponseObject.SourceAddress = HelperGetPropertyMembers $r source
        $ResponseObject.SourceUser    = HelperGetPropertyMembers $r source-user
        if ($r.'negate-source' -eq 'yes') {
            $ResponseObject.SourceNegate = $true
        }

        $ResponseObject.DestinationZone      = HelperGetPropertyMembers $r to
        $ResponseObject.DestinationAddress   = HelperGetPropertyMembers $r destination
        if ($r.'negate-destination' -eq 'yes') {
            $ResponseObject.DestinationNegate = $true
        }

        $ResponseObject.UrlCategory = HelperGetPropertyMembers $r category
        $ResponseObject.Application = HelperGetPropertyMembers $r application
        $ResponseObject.Service     = HelperGetPropertyMembers $r service

        $ResponseObject.Class = $r.action.class
        
        $ResponseTable += $ResponseObject

        <#
        Schedule           : none
        #>

    }
    return $ResponseTable

}

###############################################################################
# Get-PaSecurityRule

function Get-PaSecurityRule {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $Xpath = "/config/devices/entry/vsys/entry/rulebase/security/rules"

    if ($Name) { $Xpath += "/entry[@name='$Name']" }

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    
    $RuleData = Get-PaConfig -Xpath $Xpath -Action $Action

    if ($RuleData.rules) { $RuleData = $RuleData.rules.entry } `
                    else { $RuleData = $RuleData.entry       }
        

    $RuleTable = @()
    foreach ($r in $RuleData) {
        $RuleObject = New-Object PowerAlto.SecurityRule

        # General
        $RuleObject.Name        = $r.Name
        $RuleObject.Description = $r.Description
        $RuleObject.Tags        = HelperGetPropertyMembers $r tag

        # Source
        $RuleObject.SourceZone    = HelperGetPropertyMembers $r from
        $RuleObject.SourceAddress = HelperGetPropertyMembers $r source
        if ($r.'negate-source' -eq 'yes') { $RuleObject.SourceNegate = $true }

        # User
        $RuleObject.SourceUser = HelperGetPropertyMembers $r source-user
        $RuleObject.HipProfile = HelperGetPropertyMembers $r hip-profiles

        # Destination
        $RuleObject.DestinationZone    = HelperGetPropertyMembers $r to
        $RuleObject.DestinationAddress = HelperGetPropertyMembers $r destination
        if ($r.'negate-destination' -eq 'yes') { $RuleObject.DestinationNegate = $true }

        # Application
        $RuleObject.Application = HelperGetPropertyMembers $r application

        # Service / Url Category
        $RuleObject.UrlCategory = HelperGetPropertyMembers $r category
        $RuleObject.Service     = HelperGetPropertyMembers $r service

        # Action Setting
        if ($r.action -eq 'allow') { $RuleObject.Allow = $true } `
                              else { $RuleObject.Allow = $false }

        # Profile Setting
        $ProfileSetting = $r.'profile-setting'
        if ($ProfileSetting.profiles) {
            $RuleObject.AntivirusProfile     = $ProfileSetting.profiles.virus.member
            $RuleObject.AntiSpywareProfile   = $ProfileSetting.profiles.spyware.member
            $RuleObject.VulnerabilityProfile = $ProfileSetting.profiles.vulnerability.member
            $RuleObject.UrlFilteringProfile  = $ProfileSetting.profiles.'url-filtering'.member
            $RuleObject.FileBlockingProfile  = $ProfileSetting.profiles.'file-blocking'.member
            $RuleObject.DataFilteringProfile = $ProfileSetting.profiles.'data-filtering'.member
        } elseif ($ProfileSetting.group) {
            if ($ProfileSetting.group.member) { $RuleObject.ProfileGroup = $ProfileSetting.group.member }
        }

        # Log Setting
        if ($r.'log-start' -eq 'yes') { $RuleObject.LogAtSessionStart = $true }
        if ($r.'log-end' -eq 'yes')   { $RuleObject.LogAtSessionEnd = $true   }
        $RuleObject.LogForwarding = $r.'log-setting'

        # QoS Settings
        $QosSetting = $r.qos.marking
        if ($QosSetting.'ip-precedence') {
            $RuleObject.QosType    = "ip-precedence"
            $RuleObject.QosMarking = $QosSetting.'ip-precedence'
        } elseif ($QosSetting.'ip-dscp') {
            $RuleObject.QosType    = "ip-dscp"
            $RuleObject.QosMarking = $QosSetting.'ip-dscp'
        }

        # Other Settings
        $RuleObject.Schedule = $r.schedule
        if ($r.option.'disable-server-response-inspection' -eq 'yes') { $RuleObject.DisableSRI = $true }
        if ($r.disabled -eq 'yes') { $RuleObject.Disabled = $true }

        $RuleTable += $RuleObject
    }

    return $RuleTable

}

###############################################################################
# Get-PaService

function Get-PaService {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False,Position=0)]
        [string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $ElementName = "service"
    $Xpath = "/config/devices/entry/vsys/entry/$ElementName"

    if ($Name) { $Xpath += "/entry[@name='$Name']" }

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."
    Write-Debug $ResponseData

    if ($ResponseData.$ElementName) { $ResponseData = $ResponseData.$ElementName.entry } `
                               else { $ResponseData = $ResponseData.entry             }

    $ResponseTable = @()
    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.Service
        Write-Verbose "Creating new Service object"
        
        $ResponseObject.Name = $r.name
        Write-Verbose "Setting Service Name $($r.name)"
        
        $Protocol = ($r.protocol | gm -Type Property).Name

        $ResponseObject.Protocol        = $Protocol
        $ResponseObject.DestinationPort = $r.protocol.$Protocol.port

        if ($r.protocol.$Protocol.'source-port') { $ResponseObject.SourcePort      = $r.protocol.$Protocol.'source-port' }

        $ResponseObject.Tags            = HelperGetPropertyMembers $r tag
        $ResponseObject.Description     = $r.description


        $ResponseTable += $ResponseObject
        Write-Verbose "Adding object to array"
    }
    
    return $ResponseTable
}

###############################################################################
# Get-PaServiceGroup

function Get-PaServiceGroup {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $InfoObject   = New-Object PowerAlto.ServiceGroup
    $Xpath        = $InfoObject.BaseXPath
    $RootNodeName = 'service-group'

    if ($Name) { $Xpath += "/entry[@name='$Name']" }
    Write-Debug "xpath: $Xpath"

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    Write-Debug "action: $Action"
    
    $ResponseData = Get-PaConfig -Xpath $Xpath -Action $Action

    Write-Verbose "Pulling configuration information from $($global:PaDeviceObject.Name)."

    if ($ResponseData.$RootNodeName) { $ResponseData = $ResponseData.$RootNodeName.entry } `
                                else { $ResponseData = $ResponseData.entry         }

    $ResponseTable = @()
    foreach ($r in $ResponseData) {
        $ResponseObject = New-Object PowerAlto.ServiceGroup
        Write-Verbose "Creating new ServiceGroup"
        
        $ResponseObject.Name = $r.name
        Write-Verbose "Setting ServiceGroup Name $($r.name)"
        
        
        
        $ResponseObject.Members = HelperGetPropertyMembers $r members

        $ResponseObject.Tags = HelperGetPropertyMembers $r tag

        $ResponseTable += $ResponseObject
        Write-Verbose "Adding object to array"
    }
    
    return $ResponseTable
}

###############################################################################
# Get-PaSoftwareInfo

function Get-PaSoftwareInfo {
    [CmdletBinding()]

    $ReturnObject = $False

    $Command = "<request><system><software><info></info></software></system></request>"

    $ResponseData = Invoke-PaOperation $Command
    $global:Test  = $ResponseData
    
    return $ResponseData.'sw-updates'.versions.entry
}

###############################################################################
# Get-PaSoftwareUpgrades

function Get-PaSoftwareUpgrades {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet,

        [Parameter(Mandatory=$False)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory=$False)]
        [switch]$WaitForCompletion,

        [Parameter(Mandatory=$True,ParameterSetName="latest")]
        [switch]$Latest,

        [Parameter(Mandatory=$True,ParameterSetName="nextstep")]
        [switch]$NextStep,

        [Parameter(Mandatory=$True,ParameterSetName="version")]
        [string]$Version
    )
    
    $CmdletName = $MyInvocation.MyCommand.Name

    $AvailableSoftware = Get-PaSoftwareInfo
    $CurrentVersion    = $Global:PaDeviceObject.OsVersion

    if ($Latest)  { $DesiredEntry = $AvailableSoftware[0] }
    if ($Version) { $DesiredEntry = $AvailableSoftware | ? { $_.Version -eq $Version } }
    
    if ($NextStep) {
        $MajorReleases       = $AvailableSoftware | Select @{Name = 'MajorRelease'; Expression = {$_.Version.SubString(0,3)}} -Unique
        $CurrentMajorRelease = $CurrentVersion.Substring(0,3)
        $CurrentIndex        = [array]::IndexOf($MajorReleases.MajorRelease,$CurrentMajorRelease)
        HelperWriteCustomVerbose $CmdletName "CurrentIndex: $CurrentIndex"
        if ($CurrentIndex -gt 0) {
            $DesiredIndex        = $CurrentIndex - 1
        } else {
            $DesiredIndex = $CurrentIndex
        }
        $DesiredMajorRlease  = [string]($MajorReleases[$DesiredIndex].MajorRelease)
        $DesiredVersion      = $DesiredMajorRlease + '.0'
        
        if ($CurrentMajorRelease -eq $DesiredMajorRlease) {
            HelperWriteCustomVerbose $CmdletName "CurrentMajorRelease ($CurrentVersion) matches DesiredMajorRelase ($DesiredMajorRlease)"
            $DesiredEntry = $AvailableSoftware[0]
        } else {
            $DesiredEntry = $AvailableSoftware | ? { $_.Version -eq $DesiredVersion }
        }
    }

    Write-Debug "CurrentVersion is $CurrentVersion, Downloading $($DesiredEntry.Version)"

    
    if ($DesiredEntry.Downloaded -eq 'no') {
        $Command = "<request><system><software><download><version>$($DesiredEntry.Version)</version></download></software></system></request>"

        $ResponseData = Invoke-PaOperation $Command
        $global:test  = $ResponseData
        $Job          = $ResponseData.job
    
        $JobParams = @{ 'Id' = $Job
                        'CheckInterval' = 5 }
    
        if ($ShowProgress)      {
            $JobParams += @{ 'ShowProgress' = $true } 
            $WaitForCompletion = $true
        }

        if ($WaitForCompletion) { $JobParams += @{ 'WaitForCompletion' = $true } }

        $JobStatus = Get-PaJob @JobParams
        if ($JobStatus.Result -eq 'Fail') {
            Throw $JobStatus.Details
        }
        return $JobStatus
    } else {
        return $DesiredEntry.Version + " already downloaded"
    }
    
}

###############################################################################
# Get-PaTag

function Get-PaTag {
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $PaObject = New-Object PowerAlto.Tag
    $Xpath    = $PaObject.XPath

    if ($Name) { $Xpath += "/entry[@name='$Name']" }

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    
    $ConfigData = Get-PaConfig -Xpath $Xpath -Action $Action

    if ($ConfigData.tag) { $ConfigData = $ConfigData.tag }

    $ColorCodes = @{"red"         = "color1"
                    "green"       = "color2"
                    "blue"        = "color3"
                    "yellow"      = "color4"
                    "copper"      = "color5"
                    "orange"      = "color6"
                    "purple"      = "color7"
                    "gray"        = "color8"
                    "light green" = "color9"
                    "cyan"        = "color10"
                    "light gray"  = "color11"
                    "blue gray"   = "color12"
                    "lime"        = "color13"
                    "black"       = "color14"
                    "gold"        = "color15"
                    "brown"       = "color16" }

    $ColorCodesEnum = $ColorCodes.GetEnumerator()

    $ReturnObject = @()
    foreach ($c in $ConfigData.entry) {
        $NewPaObject           = New-Object PowerAlto.Tag
        $ReturnObject         += $NewPaObject
        $NewPaObject.Name      = $c.Name
        $NewPaObject.Comments  = $c.Comments

        if ($c.Color) {
            $Color = $ColorCodesEnum | ? { $_.Value -eq $c.Color }
            $NewPaObject.Color = $Color.Name
        }

    }

    return $ReturnObject

}

###############################################################################
# Get-PaZone

function Get-PaZone {
    Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Name,

        [Parameter(Mandatory=$False)]
        [switch]$Candidate
    )

    $Xpath = "/config/devices/entry/vsys/entry/zone"

    if ($Name) { $Xpath += "/entry[@name='$Name']" }

    if ($Candidate) { $Action = "get"; Throw "not supported yet"  } `
               else { $Action = "show" }
    
    $ZoneData = Get-PaConfig -Xpath $Xpath -Action $Action

    if ($ZoneData.zone) { $ZoneData = $ZoneData.zone.entry } `
                   else { $ZoneData = $ZoneData.entry      }
        

    $ZoneTable = @()
    foreach ($z in $ZoneData) {
        $ZoneObject = New-Object PowerAlto.Zone

        $ZoneObject.Name                  = $z.name
        $ZoneObject.LogSetting            = $z.network.'log-setting'
        $ZoneObject.ZoneProtectionProfile = $z.network.'zone-protection-profile'
        $ZoneObject.UserIdAclInclude      = $z.'user-acl'.'include-list'.member
        $ZoneObject.UserIdAclExclude      = $z.'user-acl'.'exclude-list'.member

        if ($z.'enable-user-identification') {
            $ZoneObject.EnableUserId = $true
        }


        $IsLayer3 = $z.network.layer3
        if ($IsLayer3) {
            $ZoneObject.ZoneType = "layer3"
            $ZoneObject.Interfaces = $IsLayer3.member
        }

        $ZoneTable += $ZoneObject
    }

    return $ZoneTable

}

###############################################################################
# Invoke-PaContentCheck

function Invoke-PaContentCheck {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet,

        [Parameter(Mandatory=$False)]
        [switch]$Antivirus,

        [Parameter(Mandatory=$False)]
        [switch]$AppsAndThreats,

        [Parameter(Mandatory=$False)]
        [switch]$All = $true
    )

    if ($Antivirus -or $AppsAndThreats) {
        $All = $False
    }
    $ReturnObject = $False

    if ($AppsAndThreats -or $All) {
        $Command = "<request><content><upgrade><check></check></upgrade></content></request>"

        $ResponseData = Invoke-PaOperation $Command

        

        $AvailableUpdates = $ResponseData.'content-updates'.entry
        if ($AvailableUpdates.current -eq 'no') {
            if ($Quiet) {
                $ReturnObject = $true
            } else {
                $ReturnObject = @($AvailableUpdates)
            }
        }
    }

    if ($Antivirus -or $All) {
        $Command = "<request><anti-virus><upgrade><check></check></upgrade></anti-virus></request>"

        $ResponseData = Invoke-PaOperation $Command

        $AvailableUpdates = $ResponseData.'content-updates'.entry
        if ($AvailableUpdates.current -eq 'no') {
            if ($Quiet) {
                $ReturnObject = $true
            } else {
                if ($ReturnObject.Gettype().BaseType.Name -eq "array") {
                    $ReturnObject += @($AvailableUpdates)
                } else {
                    $ReturnObject = @($AvailableUpdates)
                }
            }
        }
    }

    return $ReturnObject
}

###############################################################################
# Invoke-PaContentInstall

function Invoke-PaContentInstall {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet,

        [Parameter(Mandatory=$False)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory=$False)]
        [switch]$WaitForCompletion,

        [Parameter(Mandatory=$True,ParameterSetName="av")]
        [switch]$Antivirus,

        [Parameter(Mandatory=$True,ParameterSetName="app")]
        [switch]$AppsAndThreats
    )

    if ($Antivirus) {
        $Command = "<request><anti-virus><upgrade><install><version>latest</version></install></upgrade></anti-virus></request>"
    }
    if ($AppsAndThreats) {
        $Command = "<request><content><upgrade><install><version>latest</version></install></upgrade></content></request>"
    }

    if ($ShowProgress) { $WaitForCompletion = $true }

    $ResponseData = Invoke-PaOperation $Command
    $global:test = $ResponseData
    $Job = $ResponseData.job

    $JobParams = @{ 'Id' = $Job
                    'CheckInterval' = 5 }

    if ($ShowProgress)      { $JobParams += @{ 'ShowProgress' = $true } }
    if ($WaitForCompletion) { $JobParams += @{ 'WaitForCompletion' = $true } }

    $JobStatus = Get-PaJob @JobParams
    if ($JobStatus.NextJob) {
        $JobParams.Set_Item('Id',$JobStatus.NextJob)
        $JobStatus = Get-PaJob @JobParams
    }
    $global:test2 = $JobStatus
    if ($JobStatus.Result -eq 'Fail') {
        Throw $JobStatus.Details
    }
}

###############################################################################
# Invoke-PaOperation

function Invoke-PaOperation {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False,Position=0)]
		[string]$Command
    )

    HelperCheckPaConnection

    $QueryTable = @{ type = "op"
                     cmd  = $Command }
    
    $QueryString = HelperCreateQueryString $QueryTable
    $Url         = $global:PaDeviceObject.UrlBuilder($QueryString)
    $Response    = $global:PaDeviceObject.HttpQuery($url)

    return HelperCheckPaError $Response
}

###############################################################################
# Invoke-PaSoftwareCheck

function Invoke-PaSoftwareCheck {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet
    )

    $ReturnObject = $False

    $Command = "<request><system><software><check></check></software></system></request>"

    $ResponseData = Invoke-PaOperation $Command
    $global:Test = $ResponseData
        

    $AvailableUpdates = $ResponseData.'sw-updates'.versions.entry
    if ($AvailableUpdates[0].Version -ne $Global:PaDeviceObject.OsVersion) {
        $ReturnObject = $true
    }

    return $ReturnObject
}

###############################################################################
# Invoke-PaSoftwareInstall

function Invoke-PaSoftwareInstall {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet,

        [Parameter(Mandatory=$False)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory=$False)]
        [switch]$WaitForCompletion,

        [Parameter(Mandatory=$True,ParameterSetName="latest")]
        [switch]$Latest,

        [Parameter(Mandatory=$True,ParameterSetName="nextstep")]
        [switch]$NextStep,

        [Parameter(Mandatory=$True,ParameterSetName="version")]
        [string]$Version
    )

    $CmdletName = $MyInvocation.MyCommand.Name

    $AvailableSoftware = Get-PaSoftwareInfo
    $CurrentVersion    = $Global:PaDeviceObject.OsVersion

    if ($Latest)  { $DesiredEntry = $AvailableSoftware[0] }
    if ($Version) { $DesiredEntry = $AvailableSoftware | ? { $_.Version -eq $Version } }
    
    if ($NextStep) {
        $MajorReleases       = $AvailableSoftware | Select @{Name = 'MajorRelease'; Expression = {$_.Version.SubString(0,3)}} -Unique
        $CurrentMajorRelease = $CurrentVersion.Substring(0,3)
        $CurrentIndex        = [array]::IndexOf($MajorReleases.MajorRelease,$CurrentMajorRelease)
        HelperWriteCustomVerbose $CmdletName "CurrentIndex: $CurrentIndex"
        if ($CurrentIndex -gt 0) {
            $DesiredIndex        = $CurrentIndex - 1
        } else {
            $DesiredIndex = $CurrentIndex
        }
        $DesiredMajorRlease  = [string]($MajorReleases[$DesiredIndex].MajorRelease)
        $DesiredVersion      = $DesiredMajorRlease + '.0'
        
        if ($CurrentMajorRelease -eq $DesiredMajorRlease) {
            HelperWriteCustomVerbose $CmdletName "CurrentMajorRelease ($CurrentVersion) matches DesiredMajorRelase ($DesiredMajorRlease)"
            $DesiredEntry = $AvailableSoftware[0]
        } else {
            $DesiredEntry = $AvailableSoftware | ? { $_.Version -eq $DesiredVersion }
        }
    }

    write-Debug "CurrentVersion is $CurrentVersion, Installing $($DesiredEntry.Version)"

    
    if ($DesiredEntry.Current -eq 'no') {
        if ($DesiredEntry.Downloaded -eq 'no') {
            Throw $DesiredEntry.Downloaded + "Not downloaded, please use Get-PaSoftwareUpgrades"
        } else {
            $Command = "<request><system><software><install><version>$($DesiredEntry.Version)</version></install></software></system></request>"

            $ResponseData = Invoke-PaOperation $Command
            $global:test  = $ResponseData
            $Job          = $ResponseData.job
    
            $JobParams = @{ 'Id' = $Job
                            'CheckInterval' = 5 }
    
            if ($ShowProgress)      {
                $JobParams += @{ 'ShowProgress' = $true } 
                $WaitForCompletion = $true
            }

            if ($WaitForCompletion) { $JobParams += @{ 'WaitForCompletion' = $true } }

            $JobStatus = Get-PaJob @JobParams
            if ($JobStatus.Result -eq 'Fail') {
                Throw $JobStatus.Details
            }
            return $JobStatus
        }
    } else {
        return $DesiredEntry.Version + " already installed"
    }
}

###############################################################################
# New-PaSecurityRule

function New-PaSecurityRule {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [ValidatePattern('^[a-zA-Z0-9\-_\.]{1,31}$')]
        [string]$Name,

        [Parameter(Mandatory=$false,Position=1)]
        [ValidateSet("universal","intrazone","interzone")]
        [string]$RuleType = "universal",

        [Parameter(Mandatory=$false,Position=2)]
        [ValidateLength(1,255)]
        [string]$Description,

        [Parameter(Mandatory=$false,Position=3)]
        [array]$Tags,

        [Parameter(Mandatory=$false)]
        [switch]$Disabled
    )

    $NewRule             = New-Object PowerAlto.SecurityRule
    $NewRule.Name        = $Name
    $NewRule.RuleType    = $RuleType
    $NewRule.Description = $Description
    $NewRule.Tags        = $Tags
    $NewRule.Disabled    = $Disabled

    return $NewRule
}

###############################################################################
# Restart-PaDevice

function Restart-PaDevice {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)]
        [switch]$Quiet,

        [Parameter(Mandatory=$False)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory=$False)]
        [switch]$WaitForCompletion
    )

    $CmdletName = $MyInvocation.MyCommand.Name

    $Device = $global:PaDeviceObject.Device
    $ApiKey = $global:PaDeviceObject.ApiKey

    $TimerStart = Get-Date

    HelperWriteCustomVerbose $CmdletName "Issuing restart command"
    $Command      = "<request><restart><system></system></restart></request>"
    $ResponseData = Invoke-PaOperation $Command
    HelperWriteCustomVerbose $CmdletName "Restart command issued"
    
    $global:PaDeviceObject = $null

    $ProgressParams = @{'Activity'         = "Waiting for device to reboot"
                        'CurrentOperation' = "Checking status in $CheckInterval seconds..."}
    
    $JobParams = @{ 'Id' = 1
                    'CheckInterval' = 5 }

    if ($ShowProgress) {
        $JobParams         += @{ 'ShowProgress' = $true } 
        $WaitForCompletion  = $true
    }

    if ($WaitForCompletion) {
        $JobParams += @{ 'WaitForCompletion' = $true }

        $CheckInterval   = 15
        $InitialInterval = 60
        $i = 0

        while ($i -lt ($InitialInterval - $CheckInterval)) {
            Start-Sleep -s 1
            $i ++
            if ($ShowProgress) {
                $ProgressParams.Set_Item("CurrentOperation","Checking Status in $($InitialInterval - $i) seconds...")
                Write-Progress @ProgressParams
            }
        }

        if ($ShowProgress) {
            $ProgressParams.Set_Item("CurrentOperation","Trying to reconnect...")
            Write-Progress @ProgressParams
        }
    

        $IsUp = $False
        HelperWriteCustomVerbose $CmdletName "Starting check loop"
        while (!($IsUp)) {
            try {
                $i = 0
                while ($i -lt $CheckInterval) {
                    Start-Sleep -s 1
                    $i ++
                    if ($ShowProgress) {
                        $ProgressParams.Set_Item("CurrentOperation","Checking Status in $($CheckInterval - $i) seconds...")
                        Write-Progress @ProgressParams
                    }
                }

                if ($ShowProgress) {
                    $ProgressParams.Set_Item("CurrentOperation","Trying to reconnect...")
                    Write-Progress @ProgressParams
                }
                $TimerStop     = Get-Date
                $ExecutionTime = [math]::Truncate(($TimerStop - $TimerStart).TotalSeconds)
                HelperWriteCustomVerbose $CmdletName "$ExecutionTime seconds elapsed, trying to connect"

                $Reconnect = Get-PaDevice -Device $Device -ApiKey $ApiKey
            
                HelperWriteCustomVerbose $CmdletName "Connection succeeeded"
                $IsUp = $true
            } catch {
                $IsUp = $False
                switch ($_.Exception.Message) {
                    {$_ -match 'System.Web.HttpException'} {
                        HelperWriteCustomVerbose $CmdletName "Device is not up yet"
                    }
                    default {
                        Throw $_.Exception.Message
                    }
                }
            }
        }

        $ProgressParams.Set_Item("Completed",$true)
        Write-Progress @ProgressParams
    
        #####################################################################################
        # Wait for autocommit job to complete



        $JobStatus = Get-PaJob @JobParams
        if ($JobStatus.NextJob) {
            $JobParams.Set_Item('Id',$JobStatus.NextJob)
            $JobStatus = Get-PaJob @JobParams
        }
        $global:test2 = $JobStatus
        if ($JobStatus.Result -eq 'Fail') {
            Throw $JobStatus.Details
        }
    }
}

###############################################################################
# Set-PaConfig

function Set-PaConfig {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [string]$Xpath = "/config",

        [Parameter(Mandatory=$True,Position=1)]
        [ValidateSet("set")]
        [string]$Action,

        [Parameter(Mandatory=$True,Position=2)]
        [string]$Element
    )

    HelperCheckPaConnection

    $QueryTable = @{ type    = "config"
                     xpath   = $Xpath
                     action  = $Action
                     element = $Element }
    
    Write-Debug "xpath: $Xpath"
    Write-Debug "action: $Action"
    Write-Debug "element: $Element"

    $QueryString = HelperCreateQueryString $QueryTable
    Write-Debug $QueryString
    $Url         = $PaDeviceObject.UrlBuilder($QueryString)
    Write-Debug $Url
    $Response    = HelperHttpQuery $Url -AsXML

    return HelperCheckPaError $Response
}

###############################################################################
# Set-PaRuleApplication

function Set-PaRuleApplication {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="security",ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$Rule,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName="security")]
        [array]$Application = "any",

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    $Rule.Application = $Application

    if ($PassThru) {
        return $Rule
    }
}

###############################################################################
# Set-PaRuleDestination

function Set-PaRuleDestination {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="security",ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$Rule,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName="security")]
        [array]$Zone = "any",

        [Parameter(Mandatory=$false,Position=2,ParameterSetName="security")]
        [array]$Address = "any",

        [Parameter(Mandatory=$false,Position=3,ParameterSetName="security")]
        [switch]$Negate,

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    $Rule.DestinationZone    = $Zone
    $Rule.DestinationAddress = $Address
    $Rule.DestinationNegate  = $Negate

    if ($PassThru) {
        return $Rule
    }
}

###############################################################################
# Set-PaRuleServiceUrl

function Set-PaRuleServiceUrl {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="security",ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$Rule,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName="security")]
        [array]$Service,

        [Parameter(Mandatory=$false,Position=2,ParameterSetName="security")]
        [array]$UrlCategory,

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    if ($Service)     { $Rule.Service = $Service }
    if ($UrlCategory) { $Rule.UrlCategory = $UrlCategory }

    if ($PassThru) {
        return $Rule
    }
}

###############################################################################
# Set-PaRuleSource

function Set-PaRuleSource {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="security",ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$Rule,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName="security")]
        [array]$Zone = "any",

        [Parameter(Mandatory=$false,Position=2,ParameterSetName="security")]
        [array]$Address = "any",

        [Parameter(Mandatory=$false,Position=3,ParameterSetName="security")]
        [switch]$Negate,

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    $Rule.SourceZone    = $Zone
    $Rule.SourceAddress = $Address
    $Rule.SourceNegate  = $Negate

    if ($PassThru) {
        return $Rule
    }
}

###############################################################################
# Set-PaRuleUser

function Set-PaRuleUser {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="security",ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$Rule,

        [Parameter(Mandatory=$false,Position=1,ParameterSetName="security")]
        [array]$User = "any",

        [Parameter(Mandatory=$false,Position=2,ParameterSetName="security")]
        [array]$HipProfile = "any",

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    $Rule.SourceUser = $User
    $Rule.HipProfile = $HipProfile

    if ($PassThru) {
        return $Rule
    }
}

###############################################################################
# Set-PaSecurityRule

function Set-PaSecurityRule {
    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName='Object',Mandatory=$True,ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$SecurityRule,

        [Parameter(Mandatory=$false)]
        [switch]$NoValidation,

        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    $Action = "set"
    $Xpath  = $SecurityRule.XPath

    if ($NoValidation) {
        $ResponseData = Set-PaConfig -Xpath $Xpath -Action $Action -Element $SecurityRule.PrintPlainXml()
    } else {
        $Rules     = Get-PaSecurityRule
        $Tags      = Get-PaTag
        $Zones     = Get-PaZone
        $Addresses = Get-PaAddressObject

        # Check for rules with this name
        $RuleLookup = $Rules | ? { $_.Name -eq $SecurityRule.Name }
        if ($RuleLookup -and !($Force)) {
            Write-Verbose "Checking for existing Security Policy with Name $($SecurityRule.Name)"
            Throw "Security Policy with the name $($SecurityRule.Name) already exists, use -Force to overwrite"
        }

        # Check for Tags
        foreach ($t in $SecurityRule.Tags) {
            Write-Verbose "Checking for tag `"$t`""
            $TagLookup = $Tags | ? { $_.Name -eq $t }
            if (!($TagLookup)) {
                Throw "Tag `"$t`" does not exist."
            }
        }

        # Check for Zones
        foreach ($z in $SecurityRule.SourceZone) {
            Write-Verbose "Checking for Source Zone `"$z`""
            $ZoneLookup = $Zones | ? { $_.Name -eq $z }
            if (!($ZoneLookup)) {
                Throw "Source Zone `"$z`" does not exist."
            }
        }

        foreach ($z in $SecurityRule.DestinationZone) {
            Write-Verbose "Checking for Destination Zone `"$z`""
            $ZoneLookup = $Zones | ? { $_.Name -eq $z }
            if (!($ZoneLookup)) {
                Throw "Destination Zone `"$z`" does not exist."
            }
        }

        # Check for Addresses
        $IpRx = [regex] '(\d+\.){3}\d+(\/\d+)?'
        foreach ($a in $SecurityRule.SourceAddress) {
            $IpMatch = $IpRx.Match($a)
            if (!($IpMatch.Success) -and ($a -ne 'any')) {
                Write-Verbose "Checking for Source Address `"$a`""
                $AddressLookup = $Addresses | ? { $_.name -eq $a }
                if (!($AddressLookup)) {
                    Throw "Source Address `"$a`" does not exist."
                }
            }
        }

        foreach ($a in $SecurityRule.DestinationAddress) {
            $IpMatch = $IpRx.Match($a)
            if (!($IpMatch.Success) -and ($a -ne 'any')) {
                Write-Verbose "Checking for Destination Address `"$a`""
                $AddressLookup = $Addresses | ? { $_.name -eq $a }
                if (!($AddressLookup)) {
                    Throw "Destination Address `"$a`" does not exist."
                }
            }
        }

        $ResponseData = Set-PaConfig -Xpath $Xpath -Action $Action -Element $SecurityRule.PrintPlainXml()
    }

    return $ResponseData
}

###############################################################################
# Set-PaSecurityRuleActions

function Set-PaSecurityRuleActions {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$True)]
        [PowerAlto.SecurityRule]$Rule,

        #################################################################

        [Parameter(Mandatory=$true,Position=1,ParameterSetName="Action")]
        [ValidateSet("allow","deny")]
        [array]$Action,

        #################################################################
        
        [Parameter(Mandatory=$false,ParameterSetName="Log")]
        [switch]$LogStart,

        [Parameter(Mandatory=$false,ParameterSetName="Log")]
        [switch]$LogEnd,

        [Parameter(Mandatory=$false,ParameterSetName="Log")]
        [string]$LogForwarding,

        #################################################################

        [Parameter(Mandatory=$True,ParameterSetName="ProfileGroup")]
        [string]$ProfileGroup,

        #################################################################

        [Parameter(Mandatory=$False,ParameterSetName="Profiles")]
        [string]$Antivirus,

        [Parameter(Mandatory=$False,ParameterSetName="Profiles")]
        [string]$VulnerabilityProtection,

        [Parameter(Mandatory=$False,ParameterSetName="Profiles")]
        [string]$AntiSpyware,

        [Parameter(Mandatory=$False,ParameterSetName="Profiles")]
        [string]$UrlFiltering,

        [Parameter(Mandatory=$False,ParameterSetName="Profiles")]
        [string]$FileBlocking,

        [Parameter(Mandatory=$False,ParameterSetName="Profiles")]
        [string]$DataFiltering,

        #################################################################

        [Parameter(Mandatory=$False,ParameterSetName="Schedule")]
        [string]$Schedule,

        #################################################################

        [Parameter(Mandatory=$False,ParameterSetName="Dscp")]
        [ValidateSet("af11","af12","af13","af21","af22","af23","af31",
                     "af32","af33","af41","af42","af43")]
        [string]$DscpMarking,

        #################################################################

        [Parameter(Mandatory=$False,ParameterSetName="IpPrecedence")]
        [ValidateSet("af11","af12","af13","af21","af22","af23","af31",
                     "af32","af33","af41","af42","af43","cs0","cs1",
                     "cs2","cs3","cs4","cs5","cs6","cs7","ef")]
        [string]$IpPrecedence,

        #################################################################
        
        [Parameter(Mandatory=$false,ParameterSetName="SRI")]
        [switch]$DisableSRI,

        #################################################################

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    if ($Action) {
        if ($Action -eq "allow") { $Rule.Allow = $true } 
                            else { $Rule.Allow = $false }
    }

    if ($LogStart)      { $Rule.LogAtSessionStart = $true }
    if ($LogEnd)        { $Rule.LogAtSessionEnd   = $true }
    if ($LogForwarding) { $Rule.LogForwarding     = $LogForwarding }

    if ($ProfileGroup)  { $Rule.ProfileGroup = $ProfileGroup }

    if ($Antivirus)                { $Rule.AntivirusProfile     = $Antivirus }
    if ($VulnerabilityProtection)  { $Rule.VulnerabilityProfile = $VulnerabilityProtection }
    if ($AntiSpyware)              { $Rule.AntiSpywareProfile   = $AntiSpyware }
    if ($UrlFiltering)             { $Rule.UrlFilteringProfile  = $UrlFiltering }
    if ($FileBlocking)             { $Rule.FileBlockingProfile  = $FileBlocking }
    if ($DataFiltering)            { $Rule.DataFilteringProfile = $DataFiltering }

    if ($Schedule) { $Rule.Schedule = $Schedule }

    if ($DscpMarking) {
        $Rule.QosType    = 'ip-dscp'
        $Rule.QosMarking = $DscpMarking
    }

    if ($IpPrecedence) {
        $Rule.QosType    = 'ip-precedence'
        $Rule.QosMarking = $IpPrecedence
    }

    if ($DisableSRI) { $Rule.DisableSRI = $true }

    if ($PassThru) {
        return $Rule
    }
}

###############################################################################
## Start Helper Functions
###############################################################################

###############################################################################
# HelperCheckPaConnection

function HelperCheckPaConnection {
    if (!($Global:PaDeviceObject)) {
        Throw "Not connected to any Palo Alto Devices."
    }
}

###############################################################################
# HelperCheckPaError

function HelperCheckPaError {
    [CmdletBinding()]
	Param (
	    [Parameter(Mandatory=$True,Position=0)]
	    $Response
    )

    $CmdletName = $MyInvocation.MyCommand.Name

    $Status = $Response.data.response.status
    HelperWriteCustomVerbose $CmdletName "Status returned: $Status"

    if ($Response.data.response.result.error) {
        $ErrorMessage = $Response.data.response.result.error
    }

    if ($Status -eq "error") {
        if ($Response.data.response.msg.line -eq "Command succeeded with no output") {
            HelperWriteCustomVerbose $CmdletName $Response.data.response.msg.line
            #placeholder for stupid restart api call
        } elseif ($Response.data.response.code) {
            $ErrorMessage  = "Error Code $($Response.data.response.code): "
            $ErrorMessage += $Response.data.response.result.msg
        } elseif ($Response.data.response.msg.line) {
            Write-Verbose "Line is: $($Response.data.response.msg.line)"
            $ErrorMessage = $Response.data.response.msg.line
        } elseif ($Response.error) {
            $ErrorMessage = $Response.error
        } else {
            Write-Verbose "Message: $($Response.data.response.msg.line)"
            $ErrorMessage = $Response.data.response.msg
        }
    }
    if ($ErrorMessage) {
        Throw "$ErrorMessage`."
    } else {
        return $Response.data.response.result
    }
}

###############################################################################
# HelperConvertFilterToPosh

function HelperConvertFilterToPosh {
    [CmdletBinding()]
    Param (
		[Parameter(Mandatory=$True,Position=0)]
		[string]$Filter,

        [Parameter(Mandatory=$True,Position=1)]
        [string]$VariableName,

        [Parameter(Mandatory=$True,Position=2)]
        [string]$Property
    )

    $FilterSplit = $Filter.Split()

    $MatchString = "`$$VariableName | ? { "
    foreach ($f in $FilterSplit) {
        switch ($f) {
            { $_ -match '^(and|or)$' } { $MatchString += " -$f " }
                               default { $MatchString += "( `$_.$Property -contains $f )" }
        }
    }
    $MatchString += " }"

    return $MatchString
}

###############################################################################
# HelperCreateQueryString

function HelperCreateQueryString {
    Param (
        [Parameter(Mandatory=$True,Position=0)]
		[hashtable]$QueryTable
    )

    $QueryString = [System.Web.httputility]::ParseQueryString("")

    foreach ($Pair in $QueryTable.GetEnumerator()) {
	    $QueryString[$($Pair.Name)] = $($Pair.Value)
    }

    return $QueryString.ToString()
}

###############################################################################
# HelperGetPropertyMembers

function HelperGetPropertyMembers {
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        $XmlObject,

        [Parameter(Mandatory=$True,Position=1)]
        [string]$XmlProperty
    )

    $ReturnObject = @()
    
    if ($XmlObject.$XmlProperty) {
        foreach ($x in $XmlObject.$XmlProperty.member) { $ReturnObject += $x }
    }

    return $ReturnObject
}

###############################################################################
# HelperHttpQuery

function HelperHTTPQuery {
	Param (
		[Parameter(Mandatory=$True,Position=0)]
		[string]$URL,

		[Parameter(Mandatory=$False)]
		[alias('xml')]
		[switch]$AsXML
	)

	try {
		$Response = $null
		$Request = [System.Net.HttpWebRequest]::Create($URL)
		$Response = $Request.GetResponse()
		if ($Response) {
			$StatusCode = $Response.StatusCode.value__
			$DetailedError = $Response.GetResponseHeader("X-Detailed-Error")
		}
	}
	catch {
		$ErrorMessage = $Error[0].Exception.ErrorRecord.Exception.Message
		$Matched = ($ErrorMessage -match '[0-9]{3}')
		if ($Matched) {
			throw ('HTTP status code was {0} ({1})' -f $HttpStatusCode, $matches[0])
		}
		else {
			throw $ErrorMessage
		}

		#$Response = $Error[0].Exception.InnerException.Response
		#$Response.GetResponseHeader("X-Detailed-Error")
	}

	if ($Response.StatusCode -eq "OK") {
		$Stream    = $Response.GetResponseStream()
		$Reader    = New-Object IO.StreamReader($Stream)
		$FullPage  = $Reader.ReadToEnd()

		if ($AsXML) {
			$Data = [xml]$FullPage
            if ($Global:PaDeviceObject) { $Global:PaDeviceObject.LastXmlResult = $Data }
		} else {
			$Data = $FullPage
		}

		$Global:LastResponse = $Data

		$Reader.Close()
		$Stream.Close()
		$Response.Close()
	} else {
		Throw "Error Accessing Page $FullPage"
	}

	$ReturnObject = "" | Select-Object StatusCode,DetailedError,Data
	$ReturnObject.StatusCode = $StatusCode
	$ReturnObject.DetailedError = $DetailedError
	$ReturnObject.Data = $Data
    
    

	return $ReturnObject
}

###############################################################################
# HelperWriteCustomVerbose

function HelperWriteCustomVerbose {
    [CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True,Position=0)]
	    [string]$Cmdlet,

	    [Parameter(Mandatory=$True,Position=1)]
	    [string]$Message
    )
    Write-Verbose "$Cmdlet`: $Message"
}

###############################################################################
## Export Cmdlets
###############################################################################

Export-ModuleMember *-*
