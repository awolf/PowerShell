##############################################################################
##
## SharePointModule.ps1
## Commands that reads data from the SharePoint Web Services
##
## 
## by Adam J Wolf
##
##############################################################################

$DebugPreference = "SilentlyContinue" #"Continue"

$rootUrl = "The root URL"

$userGroupProxy = New-WebServiceProxy `
                    -Uri "$($rootUrl)/_vti_bin/UserGroup.asmx?WSDL" `
                    -Namespace SpWs `
                    -UseDefaultCredential 

$websProxy = New-WebServiceProxy `
                    -Uri "$($rootUrl)/_vti_bin/Webs.asmx?WSDL" `
                    -Namespace SpWs `
                    -UseDefaultCredential 

$listsProxy = New-WebServiceProxy `
                    -Uri "$($rootUrl)/_vti_bin/lists.asmx?WSDL" `
                    -Namespace SpWs `
                    -UseDefaultCredential 


function Main
{
    $siteCollections = Get-SiteCollectionsList
    $siteCollections | Export-Csv "c:\temp\SiteCollections.txt" -Force -NoTypeInformation 

    foreach ($site in $siteCollections)
    {
        $subwebs = $site | Get-SubWebs 
        $subwebs | % { $_ | Add-member -membertype noteproperty -name SiteCollection -value "$($_.Url)"}
        $subwebs | Export-Csv "c:\temp\SubWebs.txt" -Force -NoTypeInformation -Append

        ForEach ($web in $subwebs)
        {
            Write-Host $web.Url

            #$groups = Get-GroupCollectionFromWeb($web.Url) 
            #Write-Groups $groups $web.Url 

            #Get-OwnerGroups($web.Url)

            $lists = Get-ListCollectionFromWeb $web.Url
            Write-Lists $lists $web.Url 
    
        }
    }
}


Function Get-WebsAndOwners
{
    $siteCollections = Get-SiteCollectionsList
    $siteCollections | Export-Csv "c:\temp\SiteCollections.txt" -Force -NoTypeInformation 

    $subwebs = $siteCollections | Where-Object {$_.Path -like "*/dssg*"} | Get-SubWebs
    $subwebs | Export-Csv "c:\temp\SubWebs.txt" -Force -NoTypeInformation

    ForEach ($web in $subwebs)
    {
        Write-Host $web.Url

        $web | Get-OwnerGroups
        
    }
}


## Gets the sub websites from a SparePoint Site collection
Function Get-OwnerGroups
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [string] $Url
)

    process
    {
        $groups = Get-GroupCollectionFromWeb($Url) | Where-Object {$_.Name -like '*owner*'}
        
        Write-Groups $groups $Url -file "c:\temp\OwnerGroups.txt"

        ForEach($group in $groups)
        {
           
            Write-Host "Group: $($group.Name)"
                
            $groupMembers = Get-UserCollectionFromGroup $Url $group.Name
            
            Write-GroupMembers $groupMembers $web.Url $group.Name -file "c:\temp\OwnersGroupMemebers.txt"            
          
        }
    }
}


function Write-GroupMembers
{
param(
    [Parameter( Mandatory = $true)]
    [object[]] $members,
    [Parameter( Mandatory = $true)]
    [string] $url,
    [Parameter( Mandatory = $true)]
    [string] $name,
    [Parameter( Mandatory = $false)]
    [string] $file = "C:\temp\GroupMemebers.txt"
)
    ForEach ($member in $members)
    {
        $member | Add-member -membertype noteproperty -name WebUrl -value "$($url)"
        $member | Add-member -membertype noteproperty -name GroupName -value "$($name)"
    }

    $members | Export-Csv $file -Force -NoTypeInformation -Append   

}


function Write-Groups
{
param(
    [Parameter( Mandatory = $true)]
    [object[]] $groups,
    [Parameter( Mandatory = $true)]
    [string] $url,
    [Parameter( Mandatory = $false)]
    [string] $file = "C:\temp\Groups.txt"
)
    $groups | % { $_ | Add-member -membertype noteproperty -name WebUrl -value "$($url)"}
    $groups | Export-Csv $file -Force -NoTypeInformation -Append   
}


function Write-Lists
{
param(
    [Parameter( Mandatory = $true)]
    [object[]] $lists,
    [Parameter( Mandatory = $true)]
    [string] $url,
    [Parameter( Mandatory = $false)]
    [string] $file = "C:\temp\Lists.txt"
)
    $lists | % { $_ | Add-member -membertype noteproperty -name WebUrl -value "$($web.Url)"}
    $lists | Export-Csv $file -Force -NoTypeInformation -Append   
}


## gets the sub websites from a SparePoint Site collection
Function Get-SubWebs
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [string] $Path
)

    process
    {
        $websProxy.Url = "$($Path)/_vti_bin/Webs.asmx"

        $response = $websProxy.GetAllSubWebCollection()

        $response.Web
    }
}


## Gets the user collection from a sub website
Function Get-UserCollectionFromWeb
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0)]
    [string] $Url
)

    process
    {
        $userGroupProxy.Url =  "$($Url)/_vti_bin/UserGroup.asmx"
        
        $users = $userGroupProxy.GetUserCollectionFromWeb()

        $users.Users.ChildNodes
    }
}

Function Get-GroupCollectionFromWeb
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0)]
    [string] $Url
)

    $userGroupProxy.Url =  "$($Url)/_vti_bin/UserGroup.asmx"

    $result = $userGroupProxy.GetGroupCollectionFromWeb()

    $result.Groups.ChildNodes
}

Function Get-UserCollectionFromGroup
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0)]
    [string] $Url,
    [Parameter(
        Mandatory = $true,
        Position = 1)]
    [string] $Name
)

    $userGroupProxy.Url = "$($Url)/_vti_bin/UserGroup.asmx"

    $result = $userGroupProxy.GetUserCollectionFromGroup($Name)
    
    $result.Users.ChildNodes
}

Function Get-ListCollectionFromWeb
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0)]
    [string] $Url
)

    $listsProxy.Url = "$($Url)/_vti_bin/lists.asmx"
                   
    $result = $listsProxy.GetListCollection()
    
    $result.List
}

Function Get-ListItems
{
param(
    [Parameter(
        Mandatory = $true,
        Position = 0)]
    [string] $Url,
    [Parameter(
        Mandatory = $true,
        Position = 1)]
    [string] $ListId
)
    
    $xmlDoc = new-object System.Xml.XmlDocument            
    $query = $xmlDoc.CreateElement("Query")            
    $viewFields = $xmlDoc.CreateElement("ViewFields")            
    $queryOptions = $xmlDoc.CreateElement("QueryOptions")            
    $query.set_InnerXml("FieldRef Name='Link'")             
    $rowLimit = "1000"            
    
    $listsProxy.Url = "$($Url)/_vti_bin/lists.asmx"
    
    $result = $listsProxy.GetListItems($ListId, $null, $query, $viewFields, $rowLimit, $queryOptions, "")
        
    $result.Data.row | % { Write-Output $_ }
}


## Gets the list of site collections from the SharePoint RBPortal Site Collections list
Function Get-SiteCollectionsList
{

    $uri = "Site Collection List"            
    $listGuid = "{list guid}"
    $viewGuid = "{view guid}"      

    $xmlDoc = new-object System.Xml.XmlDocument            
    $query = $xmlDoc.CreateElement("Query")            
    $viewFields = $xmlDoc.CreateElement("ViewFields")            
    $queryOptions = $xmlDoc.CreateElement("QueryOptions")            
    $query.set_InnerXml("FieldRef Name='Link'")             
    $rowLimit = "1000"                          

    Write-Host "Getting List of sites."            
    
    $listsProxy.Url =  $uri

    $list = $listsProxy.GetListItems($listGuid, $viewGuid, $query, $viewFields, $rowLimit, $queryOptions, "")

    $list.data.row | ForEach-Object {

        $value = "" | Select-Object -Property Path,SiteName

        $value.Path = $_.ows_Site_x0020_Collection_x0020_Link.Split(',')[0]
        $value.SiteName = $_.ows_Title
        Write-Output $value
    }
}


Clear
Main
