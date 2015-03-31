#===========================================================================
#Title            :ixia2.tcl
#Description      :ixia2
#---------------------------------------------------------------------------
#Author           :XXX.XXX
#Created          :2014-09-01
#Modified Person  :XXXXXXXXXX
#Last modified    :2014-09-01
#===========================================================================
variable chassis1
variable port1
variable port2

 
$port1 CreateStaEngine \
	-StaEngineName stats.port1 \
	-StaType Statistics  
$port2 CreateStaEngine \
	-StaEngineName stats.port2 \
	-StaType Statistics  
$port1 CreateTraffic -TrafficName port1traffic1  
port1traffic1 CreateProfile \
	-Name profile.port1traffic1 \
	-Type Constant \
	-TrafficLoad 10.000000 \
	-TrafficLoadUnit percent  
port1traffic1 CreateProfile \
	-Name profile.port1traffic2 \
	-Type Constant \
	-TrafficLoad 100.000000 \
	-TrafficLoadUnit fps  
port1traffic1 CreateProfile \
	-Name profile.port1traffic3 \
	-Type Constant \
	-TrafficLoad 20.000000 \
	-TrafficLoadUnit percent  
port1traffic1 CreateStream \
	-StreamName stream.port1traffic1 \
	-ProfileName profile.port1traffic1 \
	-framelen 1500 \
	-L2 Ethernet_Vlan \
	-EthDst 00:00:00:00:00:11 \
	-EthDstMode fixed \
	-EthDstCount 1 \
	-EthSrc 00:00:00:00:00:22 \
	-EthSrcMode increment \
	-EthSrcCount 100 \
	-EthSrcStep 00:00:00:00:00:01 \
	-EthType 0x8100 \
	-EthTypeMode fixed \
	-EthTypeCount 1 \
	-VlanId 100 \
	-VlanIdMode fixed \
	-VlanIdCount 1 \
	-VlanUserPriority 0 \
	-VlanCfi 0 \
	-VlanType 0xffff      
port1traffic1 CreateStream \
	-StreamName stream.port1traffic2 \
	-ProfileName profile.port1traffic2 \
	-framelen 1500 \
	-L2 Ethernet \
	-EthDst 00:00:00:00:00:11 \
	-EthDstMode fixed \
	-EthDstCount 1 \
	-EthSrc 00:00:00:00:00:22 \
	-EthSrcMode fixed \
	-EthSrcCount 1 \
	-EthType 0x800 \
	-EthTypeMode fixed \
	-EthTypeCount 1 \
	-L3 IPv4 \
	-IpSrcAddr 1.1.1.1 \
	-IpSrcAddrMode fixed \
	-IpSrcAddrCount 1 \
	-IpSrcMask 255.255.255.0 \
	-IpDstAddr 2.2.2.2 \
	-IpDstAddrMode increment \
	-IpDstAddrCount 100 \
	-IpDstAddrStep 0.0.0.1 \
	-IpDstMask 255.255.255.0     
port1traffic1 CreateStream \
	-StreamName stream.port1traffic3 \
	-ProfileName profile.port1traffic3 \
	-framelen 1500 \
	-L2 Ethernet \
	-EthDst 00:00:00:00:00:00 \
	-EthDstMode fixed \
	-EthDstCount 1 \
	-EthSrc 00:00:00:00:00:00 \
	-EthSrcMode fixed \
	-EthSrcCount 1 \
	-EthType 0x800 \
	-EthTypeMode fixed \
	-EthTypeCount 1 \
	-L3 IPv4 \
	-IpSrcAddr 1.1.1.1 \
	-IpSrcAddrMode fixed \
	-IpSrcAddrCount 1 \
	-IpSrcMask 255.255.255.0 \
	-IpDstAddr 2.2.2.2 \
	-IpDstAddrMode increment \
	-IpDstAddrCount 100 \
	-IpDstAddrStep 0.0.0.1 \
	-IpDstMask 255.255.255.0 \
	-L4 TCP \
	-TcpSrcPort 60 \
	-TcpSrcPortMode fixed \
	-TcpSrcPortCount 1 \
	-TcpDstPort 80 \
	-TcpDstPortMode fixed \
	-TcpDstPortCount 1    
$chassis1 StartTraffic 
after 10000 
$chassis1 StopTraffic 
set stats_txFrame.port1traffic1 {} 
set stats_txFrame.port1traffic2 {} 
set stats_txFrame.port1traffic3 {} 
set stats_rxFrame.port1traffic1 {} 
set stats_rxFrame.port1traffic2 {} 
set stats_rxFrame.port1traffic3 {} 
stats.port1 GetStreamStats \
    -name stream.port1traffic1 \
	-TxFrames stats_txFrame.port1traffic1 \
	-RxFrames stats_rxFrame.port1traffic1  
stats.port1 GetStreamStats \
    -name stream.port1traffic2 \
	-TxFrames stats_txFrame.port1traffic2 \
	-RxFrames stats_rxFrame.port1traffic2  
stats.port1 GetStreamStats \
    -name stream.port1traffic3 \
	-TxFrames stats_txFrame.port1traffic3 \
	-RxFrames stats_rxFrame.port1traffic3  

MZtePut  " 流stream.port1traffic1 发送数据报文个数为：${stats_txFrame.port1traffic1}， 接收数据报文个数为：${stats_rxFrame.port1traffic1}"
MZtePut  " 流stream.port1traffic2 发送数据报文个数为：${stats_txFrame.port1traffic2}， 接收数据报文个数为：${stats_rxFrame.port1traffic2}"
MZtePut  " 流stream.port1traffic3 发送数据报文个数为：${stats_txFrame.port1traffic3}， 接收数据报文个数为：${stats_rxFrame.port1traffic3}"

after 600000


