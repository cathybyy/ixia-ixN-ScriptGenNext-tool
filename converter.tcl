proc GetPortLocation { connectionInfo } {
	return VPORT
}

proc GetAttribute { handle attr } {
puts "<PROC GetAttribute> handle:$handle attribute:$attr"
	return [ ixNet getA $handle $attr ]
}

proc GetProfileName { trafficItemName } {
puts "<PROC GetProfileName> trafficItemName:$trafficItemName"
	return $trafficItemName.profile
}

proc GetProfileType { type } {
puts "<PROC GetProfileType> type:$type"
# auto,continuous,custom,fixedDuration,fixedFrameCount,fixedIterationCount
	switch $type {
		continuous {
			return "Constant"
		}
		fixedFrameCount {
			return "Burst"
		}
	}
}

proc GetTrafficLoadUnit { loadType } {
puts "<PROC GetTrafficLoadUnit> loadType:$loadType"
# bitsPerSecond,framesPerSecond,interPacketGap,percentLineRate
	switch $loadType {
		percentLineRate {
			return percent
		}
		framesPerSecond {
			return fps
		}
	}
}

proc GetTrafficNameByStack { stack } {

	set ce [ ixNet getP $stack ]
	set tra [ ixNet getP $ce ]
	return [ ixNet getA $tra -name ]
}

proc GetPduNameByStack { stack } {
	return [GetTrafficNameByStack $stack].[ixNet getA $stack -templateName].[GetObjectIndex $stack stack]
}

proc GetVlanMultipleTag { stack } {
	
	set ce [ ixNet getP $stack ]
	set vlanCount [ixNet getF $ce stack -displayName VLAN]
	if { $vlanCount > 1 } {
		return Multiple
	} else {
		return Single
	}
}

proc GetObjectIndex { obj child } {
	set parent [ ixNet getP $obj ]
	set childList [ ixNet getL $parent $child ]
	
	return [ lsearch $childList $obj ]
}

proc GetTrafficPdu { tra } {
	set pduList [ list ]
	set ce [ lindex [ ixNet getL $tra configElement ] 0 ]
	set stackList [ ixNet getL $ce stack ]
	foreach stack $stackList {
		lappend pduList [ GetPduNameByStack $stack ]
	}
	
	return $pduList
}

proc GetFieldType { type } {
	if { $type == "singleValue" } {
		return "fixed"
	} else {
		return $type
	}
}

proc GetFieldValue { field } {
	set type [ ixNet getA $field -valueType ]
	return [ GetFieldValueByType $field $type ]
}

proc GetFieldValueByType { field type } {
	if { $type == "singleValue" } {
		ixNet getA $field -singleValue
	} else {
		ixNet getA $field -startValue
	}
}

proc GetL2StackName { configElement } {
	set ethStack [ ixNet getF $configElement stack -displayName {Ethernet II} ]
	set vlanStack [ ixNet getF $configElement stack -displayName VLAN ]
	set mplsStack [ ixNet getF $configElement stack -displayName MPLS ]
	if { $ethStack != "" } {
		if { $vlanStack != "" } {
			if { $mplsStack != "" } {
				return Ethernet_Vlan_Mpls
			} else {
				return Ethernet_Vlan			
			}	
		} else {
			if { $mplsStack != "" } {
				return Ethernet_Mpls
			} else {
				return Ethernet
			}
		}
	} else {
		return ""
	}
}

proc GetL3StackName { configElement } {
	set ipv4Stack [ ixNet getF $configElement stack -templateName ipv4-template.xml ]
	set ipv6Stack [ ixNet getF $configElement stack -templateName ipv6-template.xml ]
	set arpStack [ ixNet getF $configElement stack -displayName {Ethernet ARP} ]
	if { $ipv4Stack != "" } {
		return IPv4
	} elseif { $ipv6Stack != "" } {
		return IPv6
	} elseif { $arpStack != "" } {
		return ARP
	}
	
	return ""
}

proc GetL4StackName { configElement } {
# ICMP | TCP | UDP | IGMP
	set tcpStack [ ixNet getF $configElement stack -templateName tcp-template.xml ]
	set udpStack [ ixNet getF $configElement stack -templateName udp-template.xml ]
	set igmpStack [ ixNet getF $configElement stack -templateName igmp-template.xml ]
	set icmpStack ""
	foreach stack [ixNet getL $configElement stack] {
		if { [ regexp -nocase icmp [ ixNet getA $stack -templateName ] ] } {
			set icmpStack $stack
			break
		}
	}

	if { $tcpStack != "" } {
		return TCP
	} elseif { $udpStack != "" } {
		return UDP
	} elseif { $igmpStack != "" } {
		return IGMP
	} elseif { $icmpStack != "" } {
		return ICMP
	}
	
	return ""
}

proc GetArpOperationCode { arp_oc } {
	
	switch $arp_oc {
		1 {
			return arpRequest
		}
		2 {
			return arpReply
		}
	}
}

proc GetIcmpMsgType { ce } {

	set icmpStack ""
	foreach stack [ ixNet getL $ce stack ] {
		if { [ regexp -nocase icmp [ ixNet getA $stack -templateName ] ] } {
			set icmpStack $stack
			break
		}

	}
	
	if { $icmpStack != "" } {
		set field [ ixNet getF $icmpStack field -name msg_type ]
		if { $field != "" } {
			return [ ixNet getA $field -singleValue ]
		} else {
			set field [ ixNet getF $icmpStack field -name type ]
			return [ ixNet getA $field -singleValue ]
		}
	} else {
		return ""
	}
}

proc GetIcmpCode { ce } {

	set icmpStack ""
	foreach stack [ ixNet getL $ce stack ] {
		if { [ regexp -nocase icmp [ ixNet getA $stack -templateName ] ] } {
			set icmpStack $stack
			break
		}

	}
	
	if { $icmpStack != "" } {
	
		if { [ ixNet getF $icmpStack field -name Code ] == "" &&
			[ ixNet getF $icmpStack field -name code ] == "" } {
			set codeList [ list ]
			lappend codeList [ ixNet getF $icmpStack field -name val1 ]
			lappend codeList [ ixNet getF $icmpStack field -name val2 ]
			lappend codeList [ ixNet getF $icmpStack field -name val3 ]
			lappend codeList [ ixNet getF $icmpStack field -name val4 ]
			lappend codeList [ ixNet getF $icmpStack field -name val5 ]
			lappend codeList [ ixNet getF $icmpStack field -name val6 ]
			
			foreach field $codeList {
				if { [ ixNet getA $field -activeFieldChoice ] } {
					return [ ixNet getA $field -singleValue ]
				} else {
				return ""
				}
			}
		} else {
			set field [ ixNet getF $icmpStack field -name Code ]
			if { $field == "" } {
				set field [ ixNet getF $icmpStack field -name code ]
			}
			return [ ixNet getA $field -singleValue ]
		}

	} else {
		return ""
	}
}

proc IsTrafficStarted {} {
	set tra [ ixNet getRoot ]/traffic
	if { [ ixNet getA $tra -state ] == "started" } {
		return 1
	} else {
		return 0
	}
}

proc GetAllTrafficName {} {
	set root [ ixNet getRoot ]
	set traName [ list ]
	foreach tra [ ixNet getL $root/traffic trafficItem ] {
		lappend traName stream.[ ixNet getA $tra -name ] 
	}
	return $traName
}

proc GetNeighborRangeVport {handle} {
	set parent [ixNet getP [ixNet getP [ixNet getP $handle]]]
	
	return [ixNet getA $parent -name]
}

proc GetBgpRouterName {handle} {
	set index [GetObjectIndex $handle neighborRange]
	set index [expr ($index+1)]
	set port [GetNeighborRangeVport $handle]
	set bgpRouterName $port.bgpRouter.$index
	return $bgpRouterName
}

proc GetBgpRouterName_2 {handle} {
	set index [GetObjectIndex [ixNet getP $handle] neighborRange]
	set index [expr ($index+1)]
	set newhandle [ixNet getP $handle]
	set port [GetNeighborRangeVport $newhandle]
	set bgpRouterName $port.bgpRouter.$index
	return $bgpRouterName
}

proc GetBgpRouterType {interfaces} {
	if {$interfaces == {::ixNet::OBJ-null}} {
		return {Interface is unassigned!}
	} else {
		set type_1 [ixNet getL $interfaces ipv4]
		set type_2 [ixNet getL $interfaces ipv6]
		if {$type_1 != ""} {
			return "BgpV4Router"
		}
		if {$type_2 != ""} {
			return "BgpV6Router"
		}
	}
}

proc GetBgpPeerType {type} {
	switch $type {
		internal {
			return "IBGP"
		}
		external {
			return "EBGP"
		}
	}
}
	
proc GetFlagMd5 {authentication} {
	switch $authentication {
		null {
			return "false"
		}
		md5 {
			return "true"
		}
	}
}
	
proc GetActiveStatus {status} {
	switch $status {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetRouteBlockName {handle} {
	set index [GetObjectIndex $handle routeRange]
	set index [expr ($index+1)]
	#set portName [ixNet getA [ixNet getP [ixNet getP [ixNet getP [ixNet getP $handle]]]] -name]
	set BgpRouteName [GetBgpRouterName_2 $handle]
	set RouteBlockName ${BgpRouteName}.Block.$index
	return $RouteBlockName
}

proc GetAddressFamily {type} {
	switch $type {
		ipv4 { 
			return "IPv4"
		}
		ipv6 {
			return "IPv6"
		}
	}
}

proc GetAsSegments {asSegments} {
	puts "GetAsSegments $asSegments"
	if {$asSegments == ""} {
		return ""} else {
			foreach segment $asSegments {
				if {[lindex $segment 0] == "true"} {
					set mode [lindex $segment 1]
					set value [lindex $segment 2]
					switch $mode {
						asSet {
							set mode 1
						}
						asSequence {
							set mode 2
						}
						asConfedSequence {
							set mode 3
						}
						asConfedSet {
							set mode 4
						}
					}
					set as_list [list $mode]
					foreach path $value {
						lappend as_list $path
					}
					lappend result $as_list
				} else {
					set as_list ""
					lappend result $as_list
				}
			}
			set result_list [list $result]
			return $result_list
		}
}

proc GetOriginProtocol {originProtocol} {
	switch $originProtocol {
		igp {
			return "0"
		}
		egp {
			return "1"
		}
		incomplete {
			return "2"
		}
	}
}
			
proc Int2Hex { byte { len 8 } } {
    set hex [ format %x $byte ]
    set hexlen [ string length $hex ]
    if { $hexlen < $len } {
        set hex [ string repeat 0 [ expr $len - $hexlen ] ]$hex
    } elseif { $hexlen > $len } {
        set hex [ string range $hex [ expr $hexlen - $len ] end ]
    }
    return $hex
}
		
proc Hex2Int { byte } {
       
		set hex [format %s $byte]
		#puts $hex
        set hexlen [ string length $hex ]
		#puts $hexlen
		set newInt 0
		for { set i 0 } {$i < $hexlen} { incr i } {
		    set elenum [string index $hex $i]
			
		    switch $elenum {
			A -
			a { set elenum 10}
			B -
			b { set elenum 11}
			C -
			c { set elenum 12}
			D -
			d { set elenum 13}
			E -
			e { set elenum 14}
			F -
			f { set elenum 15}
			}
			set intele [format %d $elenum]
		    set newInt [expr $newInt *16 + $intele]
		
        }
        return $newInt
}

proc Hex2IP { byte } {
	set A [string range $byte 0 1]
	set B [string range $byte 2 3]
	set C [string range $byte 4 5]
	set D [string range $byte 6 7]
	return [Hex2Int $A].[Hex2Int $B].[Hex2Int $C].[Hex2Int $D]
}

proc GetClusterList {value} {

	set value [Int2Hex $value]
	set value [Hex2IP $value]
	return $value
}


proc GetRouterVport {handle} {
	set parent [ixNet getP [ixNet getP [ixNet getP $handle]]]
	
	return [ixNet getA $parent -name]
}

proc GetIsisRouterName {handle} {
	set index [GetObjectIndex $handle router]
	set index [expr ($index+1)]
	set port [GetRouterVport $handle]
	set isisRouterName $port.isisRouter$index
	return $isisRouterName
}

proc GetIsisRouterName_2 {handle} {
	set index [GetObjectIndex [ixNet getP $handle] router]
	set index [expr ($index+1)]
	set newhandle [ixNet getP $handle]
	set port [GetRouterVport $newhandle]
	set isisRouterName $port.isisRouter$index
	return $isisRouterName
}

proc GetIsisAddressType { value } {

   if { [ regexp -nocase {(\d+)\.(\d+)\.(\d+)\.(\d+)} $value ip a b c d ] } {
        return "IPv4"
    } else {
        return "IPv6"
    }
}

proc GetIsisRouterIpv4Addr {value} {
	if { [ regexp -nocase {(\d+)\.(\d+)\.(\d+)\.(\d+)} $value ip a b c d ] } {
        return $value
    } else {
        return ""
    }
}

proc GetIsisRouterIpv6Addr {value} {
	if { [ regexp -nocase {(\d+)\.(\d+)\.(\d+)\.(\d+)} $value ip a b c d ] } {
        return ""
    } else {
        return $value
    }
}

proc PrefixlenToSubnetV4 {value} {
    if {$value >= 0 && $value <=8} {
            set first	[expr 256 - [expr int([expr {pow(2,[expr 8 - $value])}]) ]  ]
            return $first.0.0.0
    } elseif {$value >8 && $value <=16} {
            set second	[expr 256 - [expr int([expr {pow(2,[expr 16 - $value])}]) ]  ]
            return 255.$second.0.0 
    } elseif {$value > 16 && $value <=24} {
            set third	[expr 256 - [expr int([expr {pow(2,[expr 24 - $value])}]) ]  ]
            return 255.255.$third.0 
    } elseif {$value > 24 && $value <=32} {
            set fourth	[expr 256 - [expr int([expr {pow(2,[expr 32 - $value])}]) ]  ]
            return 255.255.255.$fourth 
    } else {
            return "NAN"
    }            
}

proc SubnetToPrefixlenV4 {value} {
	if { [ regexp -nocase {(\d+)\.(\d+)\.(\d+)\.(\d+)} $value ip a b c d ] } {
		for {set c 0 } {$c <=32} {incr c} {
            if {[PrefixlenToSubnetV4 $c] ==  "$value"} {
                    return $c
				}
			}
		} else {
			return ""
		}
}

proc SubnetToPrefixlenV6 {value} {
	if { [ regexp -nocase {(\d+)\.(\d+)\.(\d+)\.(\d+)} $value ip a b c d ] } {
		return ""
		} else {
			set hexList [ split $value ":" ]
			set prefixlen 0
			foreach hex $hexList {
				if {$hex == "FFFF"} {
					set prefixlen [expr ($prefixlen+16)]
				} else {
					for {set i 0} {$i<4} {incr i} {
					set a [string index $hex $i]
						switch $a {
							F {
								set prefixlen [expr ($prefixlen+4)]
							}
							E {
								set prefixlen [expr ($prefixlen+3)]
								return $prefixlen
							}
							C {
								set prefixlen [expr ($prefixlen+2)]
								return $prefixlen
							}
							8 {
								set prefixlen [expr ($prefixlen+1)]
								return $prefixlen
							}
							0 {
								return $prefixlen
							}
						}
					}			
				}
			}
			return $prefixlen
		}
}

proc DeleSpace {value} {
	set len [ string length $value ]
    for { set index 0 } { $index < $len } { incr index } {
        if { [ string index $value $index ] == " " } {
			set value [ string replace $value $index $index "" ] 
        }
    }
	return $value
}

proc GetAreaId {list} {
	set areaId [DeleSpace [lindex $list 0]]
	return $areaId
}

proc GetAreaId1 {list} {
	set areaId1 [DeleSpace [lindex $list 1]]
	return $areaId1
}

proc GetAreaId2 {list} {
	set areaId2 [DeleSpace [lindex $list 2]]
	return $areaId2
}

proc GetIsisRouterEnabled {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetIsisRoutingLevel {level} {
	switch $level {
		level1 {
			return "L1"
		}
		level2 {
			return "L2"
		}
		level1Level2 {
			return "{L1L2}"
		}
	}
}

proc GetAuthType {linktype areatype domaintype} {
	if {$linktype == "none" && $areatype == "none" && $domaintype == "none"} {
		return "NO_AUTHENTICATION"
	} else {
		set list ""
		if {$linktype != "none"} {
			lappend list "LINK_AUTHENTICATION"
		}
		if {$areatype != "none"} {
			lappend list "AREA_AUTHENTICATION"
		}
		if {$domaintype != "none"} {
			lappend list "DOMAIN_AUTHENTICATION"
		}
		return $list
	}
}

proc GetGatewayAddr {value ip} {
	set iptype [GetIsisAddressType $ip]
	switch $iptype {
		IPv4 {
			set iptype ipv4
		}
		IPv6 {
			set iptype ipv6
		}
	}
	set gateway [ixNet getA [ixNet getL $value $iptype] -gateway]
	return $gateway
}

proc GetIsisRouteBlockName {handle} {
	set obj [GetIsisRouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle routeRange]+1)]
	set routeBlockName $obj.IsisBlock$index
	return $routeBlockName
}

proc GetNetworkRangeType {rows cols} {
	puts $rows
	puts $cols
	if {$rows == 1 && $cols == 1} {
		return "router"
	} else {
		return "grid"
	}
}

proc GetIsisTopRouterName {handle} {
	set obj [GetIsisRouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle networkRange]+1)]
	set topRouterName $obj.IsisTopRouter$index
	return $topRouterName
}

proc GetIsisTopGridName {handle} {
	set obj [GetIsisRouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle networkRange]+1)]
	set topGridName $obj.IsisTopGrid$index
	return $topGridName
}

proc GetStartingRouterId {value} {
	set ips ""
	set ip ""
	foreach a $value {
		set ip [lindex $a 1]
		lappend ips $ip
	}
	return $ips
}

proc GetTopGridAddrFamily {value} {
	set type ""
	foreach a $value {
		lappend type [lindex $a 0]
	}
	set b [lsearch $type ipv4]
	set c [lsearch $type ipv6]
	if {$b != -1 && $c != -1} {
		return "Both"
	} 
	if {$b != -1 && $c == -1} {
		return "IPv4"
	}
	if {$b == -1 && $c != -1} {
		return "IPv6"
	}
}

proc GetOspfv2RouterName {handle} {
	set index [GetObjectIndex $handle router]
	set index [expr ($index+1)]
	set port [GetRouterVport $handle]
	set ospfv2RouterName $port.Ospfv2Router$index
	return $ospfv2RouterName
}

proc GetOspfv2RouterName_2 {handle} {
	set index [GetObjectIndex [ixNet getP $handle] router]
	set index [expr ($index+1)]
	set newhandle [ixNet getP $handle]
	set port [GetRouterVport $newhandle]
	set ospfv2RouterName $port.Ospfv2Router$index
	return $ospfv2RouterName
}

proc GetOspfv2NetworkType {type} {
	switch $type {
		pointToPoint {
			return "P2P"
		}
		broadcast {
			return "BroadCast"
		}
		pointToMultipoint {
			return "P2MP"
		}
	}
}

proc GetResartReason {value1 value2 value3 value4} {
	set reason ""
	if {$value1 == "ture"} {
		lappend reason "unkown"
	}
	if {$value2 == "true"} {
		lappend reason "softrestart"
	}
	if {$value3 == "true"} {
		lappend reason "softupdate"
	}
	if {$value3 == "true"} {
		lappend reason "switchtoredurantcontrolprocessor"
	}
	return $reason
}

proc GetAuthenticationType {type} {
	switch $type {
		null {
			return "none"
		}
		password {
			return "simple"
		}
		md5 {
			return "MD5"
		}
	}
}

proc GetOspfv2RouterBlockName {handle} {
	set obj [GetOspfv2RouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle routeRange]+1)]
	set routeBlockName $obj.Block$index
	return $routeBlockName
}

proc GetFlagNssa {value} {
	if {$value == "nssa"} {
		return "true"
	} else {
		return "false"
	}
}

proc GetOspfv2RouteRangeType {type} {
	switch $type {
		externalType1 {
			return "type_1"
		}
		externalType2 {
			return "type_2"
		}
	}
}

proc GetOspfv2RouteRangeActive {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetOspfv2TopGridName {handle} {
	set obj [GetOspfv2RouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle interface]+1)]
	set gridName $obj.Grid$index
	return $gridName
}

proc GetOspfv2TopGridStartingRID {rows cows} {
	return 1.1.$rows.$cows
}

proc GetOspfv3RouterName {handle} {
	set index [GetObjectIndex $handle router]
	set index [expr ($index+1)]
	set port [GetRouterVport $handle]
	set ospfv3RouterName $port.Ospfv3Router$index
	return $ospfv3RouterName
}

proc GetOspfv3RouterName_2 {handle} {
	set index [GetObjectIndex [ixNet getP $handle] router]
	set index [expr ($index+1)]
	set newhandle [ixNet getP $handle]
	set port [GetRouterVport $newhandle]
	set ospfv3RouterName $port.Ospfv3Router$index
	return $ospfv3RouterName
}

proc GetOspfv3IpAddr {value} {
	set handle [ixNet getL $value ipv6]
	foreach a $handle {
		set ip [ixNet getA $a -ip]
		return $ip
	}
}

proc GetOspfv3IpPrefixLen {value} {
	set handle [ixNet getL $value ipv6]
	foreach a $handle {
		set prefixlen [ixNet getA $a -prefixLength]
		return $prefixlen
	}
}

proc GetOspfv3NetworkType {type} {
	switch $type {
		pointToPoint {
			return "P2P"
		}
		broadcast {
			return "BroadCast"
		}
		pointToMultipoint {
			return "P2MP"
		}
	}
}

proc GetOspfv3RouterOptions {value} {
	switch $value {
		18 {
			return "Dc-Bit"
		}
		19 {
			return "R-Bit"
		}
		20 {
			return "N-Bit"
		}
		22 {
			return "E-Bit"
		}
		23 {
			return "v6-Bit"
		}
	}
	return ""
}

proc GetOspfv3RouterBlockName {handle} {
	set obj [GetOspfv3RouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle routeRange]+1)]
	set routeBlockName $obj.Block$index
	return $routeBlockName
}

proc GetOspfv3FlagNssa {value} {
	if {$value == "sameArea"} {
		return "true"
	} else {
		return "false"
	}
}

proc GetOspfv3RouteRangeType {type} {
	switch $type {
		asExternal1 {
			return "type_1"
		}
		asExternal2 {
			return "type_2"
		}
	}
}

proc GetOspfv3RouteRangeActive {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetOspfv3TopGridName {handle} {
	set obj [GetOspfv3RouterName_2 $handle]
	set index [expr ([GetObjectIndex $handle networkRange]+1)]
	set gridName $obj.Grid$index
	return $gridName
}

proc GetOspfv3TopGridStartingRID {rows cows} {
	return 1.1.$rows.$cows
}

proc GetOspfv2LinkName {handle} {
	set index [GetObjectIndex [ixNet getP $handle] router]
	set index [expr ($index+1)]
	set router router$index
	set obj [expr ([GetObjectIndex $handle routeRange]+1)]
	set block block$obj
	set linkname ospfv2link.$router$block
}

proc GetOspfv3LinkName {handle} {
	set index [GetObjectIndex [ixNet getP $handle] router]
	set index [expr ($index+1)]
	set router router$index
	set obj [expr ([GetObjectIndex $handle routeRange]+1)]
	set block block$obj
	set linkname ospfv3link.$router$block
}

proc GetVport {handle} {
	regexp {.*vport:([0-9]+).*} $handle a b c
	set index [expr ($b-1)]
	set root [ixNet getRoot]
	set vportlist [ixNet getL $root vport]
	set vport [lindex $vportlist $index]
	return [ixNet getA $vport -name]
}

proc GetAccessHostName {handle} {
	set hostname [ixNet getA [ixNet getP [ixNet getP $handle]] -name]
	return $hostname
}

proc GetDhcpFlagBroadcast {value} {
	switch $value {
		true {
			return 1
		}
		false {
			return 0
		}
	}
}

proc GetDhcpNumRetry {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set num [ixNet getA $dhcpGlobals -dhcp4NumRetry]
	return $num
}

proc GetDhcpRouterEnabled {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetDhcpSetupTimer {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set timer [ixNet getA $dhcpGlobals -setupRateMax]
	return $timer
}

proc GetDhcpRetransmitTimer {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set timer [ixNet getA $dhcpGlobals -dhcp4ResponseTimeout]
	return $timer
}

proc GetDhcpRetransmitNum {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set num [ixNet getA $dhcpGlobals -dhcp4NumRetry]
	return $num
}

proc GetDhcpReleaseTimer {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set timer [ixNet getA $dhcpGlobals -teardownRateMax]
	return $timer
}

proc GetDhcpClientMac {handle} {
	set index [GetObjectIndex $handle dhcpRange]
	set list [ixNet getL [ixNet getP $handle] macRange]
	set mac [ixNet getA [lindex $list $index] -mac]
	return $mac
}

proc GetDhcpClientMacModifier {handle} {
	set index [GetObjectIndex $handle dhcpRange]
	set list [ixNet getL [ixNet getP $handle] macRange]
	set step [ixNet getA [lindex $list $index] -incrementBy]
	return $step
}

proc GetDhcpRelayAgentEnabled {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetDhcpv6EmulationMode {mode} {
	switch $mode {
		IANA {
			return "IPv6"
		}
		IAPD {
			return "PD"
		}
		IANA+IAPD {
			return "IPv6PD"
		}
	}
}

proc GetDhcpv6RenewMessage {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set value [ixNet getA $dhcpGlobals -renewOnLinkUp]
	return $value
}

proc GetDhcpv6RebindMessage {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set value1 [ixNet getA $dhcpGlobals -dhcp6RebTimeout]
	set value2 [ixNet getA $dhcpGlobals -dhcp6RebMaxRt]
	if {$value1 == 0 && $value2 == 0} {
		return "false"
		} else {
		return "true"
		}
}

proc GetDhcpv6RapidCommit {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetDhcpv6DUIDType {type} {
	if {$type == "DUID-EN" | $type == "DUID-LL" | $type == "DUID-LLT"} {
		switch $type {
			DUID-EN {
				return "EN"
			}
			DUID-LLT {
				return "LLT"
			}
			DUID-LL {
				return "LL"
			}
		}
	} else {
		return "custom"
	}
}

proc GetDhcpv6DADEnabled {handle} {
	set obj [ixNet getP [ixNet getP [ixNet getP [ixNet getP $handle]]]]
	return [ixNet getA $obj/options -dadEnabled]
}

proc GetDhcpv6DADTransmits {handle} {
	set obj [ixNet getP [ixNet getP [ixNet getP [ixNet getP $handle]]]]
	return [ixNet getA $obj/options -dadTransmits]
}

proc GetDhcpv6CustomOptionNum {list} {
	return [llength $list]
}

proc GetDhcpv6OptionValue {list} {
	set newlist ""
	foreach value $list {
		regexp {([0-9]+).*} $value a b
		lappend newlist $b
	}
	set value ""
	lappend value $newlist
	return $value
}

proc GetDhcpv6Active {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetDhcpv4ServerActive {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetDhcpv6ServerLeaseTime {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpServerGlobals [ixNet getL $globals/protocolStack dhcpServerGlobals]
	set value [ixNet getA $dhcpServerGlobals -defaultLeaseTime]
	return $value
}

proc GetDhcpv6ReconfigureAccept {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set dhcpGlobals [ixNet getL $globals/protocolStack dhcpGlobals]
	set value [ixNet getA $dhcpGlobals -acceptPartialConfig]
	return $value
}

proc GetPPPoERouterEnabled {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}

proc GetPPPoEConnectRate {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set pppoxGlobals [ixNet getL $globals/protocolStack pppoxGlobals]
	set value [ixNet getA $pppoxGlobals -setupRateInitial]
	return $value
}

proc GetPPPoEDisconnectRate {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set pppoxGlobals [ixNet getL $globals/protocolStack pppoxGlobals]
	set value [ixNet getA $pppoxGlobals -teardownRateInitial]
	return $value
}

proc GetPPPoEOutstanding {handle} {
	set root [ixNet getRoot]
	set globals [ixNet getL $root globals]
	set pppoxGlobals [ixNet getL $globals/protocolStack pppoxGlobals]
	set value [ixNet getA $pppoxGlobals -maxOutstandingRequests]
	return $value
}

proc GetPPPoEEncapsulation {value} {
	switch $value {
		untaggedEthernet {
			return "untag"
		}
		singleTaggedEthernet {
			return "single"
		}
		na {
			return "NA"
		}
	}
}

proc GetIPCPEnabled {options} {
	if {$options == "supplyAddress" | $options == "supplyAddresses"} {
		return "True"
	} else {
		return "Flase"
	}
}

proc GetPPPoEAuthType {type} {
	switch $type {
		chap {
			return "CHAPResponder"
		}
		pap {
			return "PAPSender"
		}
		papOrChap {
			return "PAPSenderOrCHAPResponder"
		}
	}
}

proc GetSourceMacAddr {parent} {
	set macRange [ixNet getL $parent macRange]
	return [ixNet getA $macRange -mac]
}

proc GetPoolName {parent} {
	set macRange [ixNet getL $parent macRange]
	return [ixNet getA $macRange -name]
}

proc GetAuthenticationRole {role} {
	switch $role {
		chap {
			return "CHAP"
		}
		none {
			return "SUT"
		}
		pap {
			return "PAP"
		}
	}
}

proc GetActived {value} {
	switch $value {
		true {
			return "enable"
		}
		false {
			return "disable"
		}
	}
}