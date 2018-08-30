Import-Module failoverClusters
(Get-Cluster).sameSubnetThreshold = 10
(Get-Cluster).crossSubnetThreshold = 20

# After AG listener is created. IMPORTANT $AGlistener is the clustername for the network name inside the Availablity Group cluster resource
$AGlistener = "SQLAG01_SQLLN01"

Get-ClusterResource $AGlistener | Set-ClusterParameter registerAllProvidersIP 0
Get-ClusterResource $AGlistener | Set-ClusterParameter hostRecordTTL 300
Stop-ClusterResource $AGlistener
Start-ClusterResource $AGlistener

