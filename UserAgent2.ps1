Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100

Clear

Write-Host "  _    _                                          _   "
Write-Host " | |  | |                   /\                   | |  "
Write-Host " | |  | |___  ___ _ __     /  \   __ _  ___ _ __ | |_ "
Write-Host " | |  | / __|/ _ \ '__|   / /\ \ / _` |/ _ \ '_ \| __|"
Write-Host " | |__| \__ \  __/ |     / ____ \ (_| |  __/ | | | |_ "
Write-Host "  \____/|___/\___|_|    /_/    \_\__, |\___|_| |_|\__|"
Write-Host "                                  __/ |               "
Write-Host "                                 |___/      2.0       "


$server = "server"
$database = "database"

$agents = Invoke-Sqlcmd `
            -Query "SELECT [UserAgentId], [UserAgentString], [Browser], [OperatingSystem] FROM [WebData].[dbo].[UserAgent] WHERE Browser is null" `
            -ServerInstance "$server" `
            -Database $database `
            -SuppressProviderContextWarning

$agents | Format-Table

$agents | ForEach-Object {

    $userAgentString = $_.UserAgentString
    $os = ""
    $browser = ""

    $a = $userAgentString.Replace(" (", ",")
    $a = $a.Replace(")", ",")
    $a = $a.Replace("; ", ",")
    $a = $a.Replace("/", " ")
    $parts = $a.Split(',')

 
    # Get the browser
    if ($parts -contains "Trident 3.0") { $browser = "Internet Explorer 7.0"}
    if ($parts -contains "Trident 4.0") { $browser = "Internet Explorer 8.0"}
    if ($parts -contains "Trident 5.0") { $browser = "Internet Explorer 9.0"}
    if ($parts -contains "Trident 6.0") { $browser = "Internet Explorer 10.0"}

    if ($browser -eq "" -and $parts -contains "MSIE 6.0") { $browser = "Internet Explorer 6.0"}

    if ($browser -eq "" -and $parts -contains "MSIE 7.0") { $browser = "Internet Explorer 7.0"}

    #Get Chrome - The Chrome browser useragent string has a Safari tag.
    if ($browser -eq "" -and $userAgentString.Contains("Chrome")) 
    {
        $userAgentString.Split(' ') | foreach {
            if ( $_ -match '^Chrome') 
            {
                $browser = $_.Replace("/"," ")
            }
        }
    }

    if ($browser -eq "" ) 
    {
        $userAgentString.Split(' ') | foreach {
            if ( $_ -match '^Firefox' -or $_ -match '^Safari' ) 
            {
                $browser = $_.Replace("/"," ")
            }
        }
    }
        
    #Get the OS
    if ($parts -contains "Windows NT 5.1") { $os = "Windows XP"}
    if ($parts -contains "Windows NT 5.2") { $os = "Windows Server 2003"}
    if ($parts -contains "Windows NT 6.0") { $os = "Windows Vista"}
    if ($parts -contains "Windows NT 6.1") { $os = "Windows 7"}
    if ($parts -contains "Windows NT 6.2") { $os = "Windows 8"}
    
    if ($userAgentString.Contains("Mac OS X")) {$os = "OS X" }
    if ($userAgentString.Contains("iPad")) {$os = "iPhone OS" }
    
    if ( $browser -ne $null -and $os -ne $null)
    {

        $query = "UPDATE [dbo].[UserAgent]
                    SET [Browser] = '" + $browser + "',
                        [OperatingSystem] = '" + $os +"'
                    WHERE UserAgentId = " + $_.UserAgentId
            
        Write-Host $query

        Invoke-Sqlcmd `
            -Query $query `
            -ServerInstance "$server" `
            -Database $database `
            -SuppressProviderContextWarning
    }
}
