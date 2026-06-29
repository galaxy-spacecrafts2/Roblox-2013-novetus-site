# Remove all Compile entries for .Designer.cs and App_GlobalResources missing files
$csprojPath = "C:\Roblox-2013-novetus-site\RobloxWebSite\Roblox.Website.csproj"
[xml]$xml = Get-Content $csprojPath

# Get the first ItemGroup (where Compile items are)
$itemGroups = $xml.GetElementsByTagName("ItemGroup")

# Find and remove problematic Compile entries
foreach ($itemGroup in $itemGroups) {
	$compiles = $itemGroup.GetElementsByTagName("Compile")
	$toRemove = @()

	foreach ($compile in $compiles) {
		$include = $compile.GetAttribute("Include")

		# Remove Designer.cs files that don't exist
		if ($include -like "*Designer.cs" -and $include -notlike "Properties\*") {
			$fullPath = "C:\Roblox-2013-novetus-site\RobloxWebSite\$include"
			if (!(Test-Path $fullPath)) {
				$toRemove += $compile
			}
		}
	}

	# Remove the entries
	foreach ($compile in $toRemove) {
		$itemGroup.RemoveChild($compile) | Out-Null
	}
}

$xml.Save($csprojPath)
Write-Host "Updated $csprojPath - removed missing Designer.cs references"
