$cred = Get-Credential -UserName "svc-rvtools@vsphere.local" -Message "Enter vCenter Service Account Password"

.\Invoke-VcfHclAssessment.ps1 `
    -vCenterServer "vcenter.corp.local" `
    -Credential $cred `
    -OutputDirectory "C:\VCF_Audits"