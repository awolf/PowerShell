$server = "Server Name"
$database = "Database Name"


Write-Host "   _____                              _____  _____          "
Write-Host "  / ____|                            / ____|/ ____|   /\    "
Write-Host " | (___   ___ _ __ __ _ _ __   ___  | (___ | |       /  \   "
Write-Host "  \___ \ / __| '__/ _` | '_ \ / _ \  \___ \| |      / /\ \  "
Write-Host "  ____) | (__| | | (_| | |_) |  __/  ____) | |____ / ____ \ "
Write-Host " |_____/ \___|_|  \__,_| .__/ \___| |_____/ \_____/_/    \_\"
Write-Host "                       | |                                  "
Write-Host "                       |_|                                  "


Function Run-Query
{
  
 Param(
  [string]$server,
  [string]$database,
  [string]$query
 )

    Invoke-Sqlcmd `
        -Query $query `
        -ServerInstance "$server" `
        -Database $database `
        -SuppressProviderContextWarning
} 


Function Get-SiteCollectionsList
{

    $uri = "http://URL holding list of all site collections to parse"            
    $listGuid = "{GUID for the list}"
    $viewGuid = "{Guid for the view}"      

    $xmlDoc = new-object System.Xml.XmlDocument            
    $query = $xmlDoc.CreateElement("Query")            
    $viewFields = $xmlDoc.CreateElement("ViewFields")            
    $queryOptions = $xmlDoc.CreateElement("QueryOptions")            
    $query.set_InnerXml("FieldRef Name='Link'")             
    $rowLimit = "1000"            
            
    $list = $null             
    $service = $null              

    Write-Host "Getting List of sites."            
    $service = New-WebServiceProxy -Uri $uri  -Namespace SpWs -UseDefaultCredential 
    $list = $service.GetListItems($listGuid, $viewGuid, $query, $viewFields, $rowLimit, $queryOptions, "")

    $list.data.row | ForEach-Object {

        $value = "" | Select-Object -Property Path,SiteName

        $value.Path = $_.ows_Site_x0020_Collection_x0020_Link.Split(',')[0]
        $value.SiteName = $_.ows_Title
        Write-Output $value
    }
}

Function Get-SiteCollectionsAdmins
{
 Param(
    [string] $url
)
    $url = $url + "/_vti_bin/UserGroup.asmx?WSDL"

    $service = New-WebServiceProxy -Uri  $url  -Namespace SpWs -UseDefaultCredential 
    $users = $service.GetAllUserCollectionFromWeb()

    Write-Host "User Count --> " $users.Users.ChildNodes.Count

    $admins = $users.Users.ChildNodes | Where-Object {$_.IsSiteAdmin –eq "True"}
    $admins 
}


Function Main
{

    Run-Query $server $database "DELETE FROM [dbo].[ImportSCA]"

    $list = Get-SiteCollectionsList
    $list | Format-Table

    $list | ForEach-Object {

        $siteName = $_.SiteName
        $path = $_.Path

        Write-Host 
        Write-Host "======================================================"
        Write-Host "SiteName: " $_.SiteName
        Write-Host "Url  --> " $_.Path
    
        Get-SiteCollectionsAdmins $_.Path | ForEach-Object {

            Write-Host "Name: " $_.Name
        
            $query = "
                INSERT INTO ImportSCA (SiteName,SiteUrl,Name,LoginName,Email) 
                Values ('$siteName', '$path', '" + $_.Name + "', '" + $_.LoginName + "', '" + $_.Email + "' )"
        
            Run-Query $server $database $query
        }
    
        Write-Host 
        Write-Host 
    }
}

clear

Main
