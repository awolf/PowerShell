
Write-Host "  _____ _          _   _______ _ _   _           "
Write-Host " |  __ (_)        | | |__   __(_) | | |          "
Write-Host " | |__) |__  _____| |    | |   _| |_| | ___  ___ "
Write-Host " |  ___/ \ \/ / _ \ |    | |  | | __| |/ _ \/ __|"
Write-Host " | |   | |>  <  __/ |    | |  | | |_| |  __/\__ \"
Write-Host " |_|   |_/_/\_\___|_|    |_|  |_|\__|_|\___||___/"                                               
Write-Host "                                                 "
Write-Host " Get page title for Pixel Analytics.             "

#Add-PSSnapin SqlServerCmdletSnapin100
#Add-PSSnapin SqlServerProviderSnapin100

$server = "server"
$database = "database"

Function Run-Query
{
 Param(
  [string]$query
 )
    Invoke-Sqlcmd `
        -Query $query `
        -ServerInstance "$server" `
        -Database $database `
        -SuppressProviderContextWarning
} 

Function Get-PagesNeedingTitles
{
    Run-Query "SELECT URL FROM [WebData].[dbo].[Requests] where pageTitle is null"
} 

Function Update-PageTitle
{
 Param(
  [int]$id,
  [string]$title
 )
    Run-Query "INSERT INTO [WebData].[dbo].[Requests] SET pageTitle = $($title) where Id = $($id)"
} 

Function main
{
    $pages = Get-PagesNeedingTitles

    $pages | Format-Table

    $wc = New-Object System.Net.WebClient

    $pages | ForEach-Object {
               
        $html = $wc.DownloadString($_.PageTitle)
        $html -match '<title>(.*)</title>' | Out-Null
        $title = $matches[1] # or empty string | ''
        
        Write-Host "Title: $title"
        Update-PageTitle($_.Id, $title)
    }
}

clear 

main




