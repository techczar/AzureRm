#############################################################
### Author:Sanjoy Saha ######################################
### This script has been provided as-is and the author does #
### bear any responsibility #################################


#Login to Azure Account
Login-AzureRmAccount

#Get Information about all the storage accounts
$SA = Get-AzureRmStorageAccount

#Get the VHDs in all the Storage accounts
$UMD = $SA | Get-AzureStorageContainer | Get-AzureStorageBlob | Where {$_.Name -like '*.vhd'}

#Filter out all the unlocked VHDs
$UMVHDS = $UMD | Where {$_.ICloudBlob.Properties.LeaseStatus -eq "Unlocked"}

#Get all the Managed Disks
$MVHDS = Get-AzureRmDisk

#Filter Managed Disks which do not have any Owner i.e Orphaned
$MVHD = $MVHDS | Where {$_.OwnerId -eq $null}

#Get all the objects with No Parent
$RmDiskInfo = foreach ($UMVHD in $UMVHDS) {
 
    $StorageAccountName = if ($UMVHD.ICloudBlob.Parent.Uri.Host -match '([a-z0-9A-Z]*)(?=\.blob\.core\.windows\.net)') {$Matches[0]}
 
    $StorageAccount = $SA | Where { $_.StorageAccountName -eq $StorageAccountName }
 
    $Property = [ordered]@{
 
        AbsoluteUri = $UMVHD.ICloudBlob.Uri.AbsoluteUri;
        LeaseStatus = $UMVHD.ICloudBlob.Properties.LeaseStatus;
        LeaseState = $UMVHD.ICloudBlob.Properties.LeaseState;
        StorageType = $StorageAccount.Sku.Name;
        StorageAccountName = $StorageAccountName;
        ResourceGroupName = $StorageAccount.ResourceGroupName
 
    }
 
    New-Object -TypeName PSObject -Property $Property
 
}

#Export Unamanged Disks to a CSV
$RmDiskInfo | Export-Csv -Path '.\UnusedUnmanagedVHDs.csv' -NoTypeInformation


#Export Managed Disks to a CSV
$MVHD | Export-Csv -Path '.\UnusedManagedVHDs.csv' -NoTypeInformation

#Delete Unmanaged Disks
$UMVHDS | Remove-AzureStorageBlob

#Delete Managed Disks
$MVHD | Remove-AzureRmDisk


