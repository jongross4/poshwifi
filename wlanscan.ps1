# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=
#          Name: wlanscan
#        Author: Kris Cieslak (defaultset.blogspot.com)
#          Date: 2010-04-03
#   Description: Simple script that uses netsh to show wireless networks.
#
#    Parameters: wireless interface name (optional,but recommended if you have
#                more than one card)
#        Result: $ActiveNetworks
# Usage example: wlanscan WiFi
#
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-
param(
$ifname = "",
$testInput = ""
)

class NetworkListEntry
{
    [string]$SSID
    [string]$NetType
    [string]$Auth
    [string]$Encryption
    [string]$BSSID
    [float]$Signal
    [string]$Radiotype
    [int]$Channel

}

function CloneEntry
{
    param([NetworkListEntry]$in)
    $obj = New-Object -TypeName NetworkListEntry
    $obj.SSID = $in.SSID
    $obj.NetType = $in.NetType
    $obj.Auth = $in.Auth
    $obj.Encryption = $in.Encryption
    $obj.BSSID = $in.BSSID
    $obj.Signal = $in.Signal
    $obj.Radiotype = $in.Radiotype
    $obj.Channel = $in.Channel
    $obj
}

# Windows Vista/2008/7
if  (6 -gt (gwmi win32_operatingsystem).Version.Split(".")[0]) {
	throw "This script works on Windows Vista or higher."
}
if ((gsv "wlansvc").Status -ne "Running" ) {
	throw "WLAN AutoConfig service must be running."
}
$ActiveNetworks = @();
$CurrentIfName = "";	
$n = -1;
$iftest = $false;

if ($testInput)
{
    $output = get-content $testInput
}
else
{
    $output = netsh wlan show network mode=bssid
}
$line = 0
$ssidcount=0
while ($line -lt $output.length) {
	$currentline = $output[$line];
    #Write-Host "Parsing " $currentline
	if ($currentline -match "Interface") {
		$CurrentIfName = [regex]::match($currentline.Replace("Interface name : ","")
			                            ,"\w{1,}").ToString();
	    if (($CurrentIfName.ToLower() -eq $ifname.ToLower()) -or ($ifname.length -eq 0)) {
		    $iftest=$true;
		} else { $iftest=$false }
	}
	
	$buf = [regex]::replace($currentline,"[ ]","");
	if ([regex]::IsMatch($buf,"^SSID\d{1,}(.)*") -and $iftest) {
	   	#$item = "" | Select-Object SSID,NetType,Auth,Encryption,BSSID,Signal,Radiotype,Channel;
        
        $item = New-Object -TypeName NetworkListEntry
		$item.SSID = [regex]::Replace($buf,"^SSID\d{1,}:","");
		$ActiveNetworks+=$item;
        $n = $ActiveNetworks.Length - 1
		$ssidcount = 0;
	}
  	if ([regex]::IsMatch($buf,"Networktype") -and $iftest) {
	   	$ActiveNetworks[$n].NetType=$buf.Replace("Networktype:","");
	}
	if ([regex]::IsMatch($buf,"Authentication") -and $iftest) {
	   	$ActiveNetworks[$n].Auth=$buf.Replace("Authentication:","");
	}
	if ([regex]::IsMatch($buf,"Encryption") -and $iftest) {
	   	$ActiveNetworks[$n].Encryption=$buf.Replace("Encryption:","");
	}
    if ([regex]::IsMatch($buf,"BSSID\d") -and $iftest) {
		if ($ssidcount -gt 0) { # if already have one BSSID for this SSID, copy the previous one
			$ActiveNetworks += CloneEntry($ActiveNetworks[$n])
			$n += 1;
		}
		$ActiveNetworks[$n].BSSID=[regex]::Replace($buf,"BSSID\d{1,}:","");
		$ssidcount += 1;
	}
	if ([regex]::IsMatch($buf,"Signal") -and $iftest) {
	   	$ActiveNetworks[$n].Signal=[int]::Parse([regex]::Match($buf.Replace("Signal:",""), "\d+")) / 100;
	}
	if ([regex]::IsMatch($buf,"Radiotype") -and $iftest) {
	   	$ActiveNetworks[$n].Radiotype=$buf.Replace("Radiotype:","");
	}
	if ([regex]::IsMatch($buf,"Channel") -and $iftest) {
	  	$ActiveNetworks[$n].Channel=$buf.Replace("Channel:","");
	}
	$line += 1;
}
$ActiveNetworks
