$ADSearcher = new-object DirectoryServices.DirectorySearcher("(&(SAMAccountName=thesamaccountname))")
$Users = $ADSearcher.FindOne()
 
if($Users -ne $null)
{
	[adsi]$TheUser = "$($Users.Path)"
	$Thumbnail = $TheUser.ThumbnailPhoto.Value
	[System.IO.File]::WriteAllBytes("c:\code\thesamaccountname.png",$Thumbnail)	
}
