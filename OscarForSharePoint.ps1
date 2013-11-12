clear
Write-Host "-------------------------------------------------"
Write-Host "   ____                              " 
Write-Host "  / __ \                             " 
Write-Host " | |  | |  ___    ___    __ _   _ __ " 
Write-Host " | |  | | / __|  / __|  / _` | | '__|" 
Write-Host " | |__| | \__ \ | (__  | (_| | | |   " 
Write-Host "  \____/  |___/  \___|  \__,_| |_|   " 
Write-Host ""
Write-Host "  Cleaning up the recycle bins" 
Write-Host "-------------------------------------------------"

$cred = Get-Credential
$uri = "List of site collections"            
$listGuid = "{list guid}"
$viewGuid = "{view guid}"      

$xmlDoc = new-object System.Xml.XmlDocument            
$query = $xmlDoc.CreateElement("Query")            
$viewFields = $xmlDoc.CreateElement("ViewFields")            
$queryOptions = $xmlDoc.CreateElement("QueryOptions")            
$query.set_InnerXml("FieldRef Name='RootSiteCollectionURL'")             
$rowLimit = "100"            
            
$list = $null             
$service = $null              

Write-Host "Creating Proxy."            
$service = New-WebServiceProxy -Uri $uri  -Namespace SpWs -UseDefaultCredential 
Write-Host "Proxy Complete."

Write-Host "Geting List of sites to clean."
$list = $service.GetListItems($listGuid, $viewGuid, $query, $viewFields, $rowLimit, $queryOptions, "")             
Write-Host "List Complete."


Write-Host "Starting the cleaning."
$list.data.row | ForEach-Object {

    $path = $_.ows_SiteCollectionPath
    $url = $path + "/_layouts/AdminRecycleBin.aspx"
    
    Write-Host "Cleaning " $url -ForegroundColor Yellow
        
    $page = Invoke-WebRequest -URI $url -UseDefaultCredential -SessionVariable sp

    $page.forms["usrpage"].Fields["actionID"] = "Empty"

    $finished = Invoke-WebRequest $url -WebSession $sp -Body $page.forms["usrpage"] -Method Post 

}
Write-Host "Cleaning Completed." 
