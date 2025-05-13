# PowerShell script to generate a self-contained HTML catalog with refined design

$htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Drive Catalog</title>
<style>
    body {
        font-family: Arial, sans-serif;
        background-color: #f4f4f9;
        margin: 0;
        padding: 20px;
    }
    .container {
        background-color: #fff;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        max-width: 800px;
        margin: auto;
    }
    h1 {
        text-align: center;
        color: #333;
    }
    .info {
        display: flex;
        justify-content: space-between;
        margin-bottom: 20px;
        color: #555;
    }
    .folder-structure {
        font-size: 14px;
        color: #333;
    }
    .folder {
        margin-left: 20px;
        position: relative;
    }
    .folder::before {
        content: '';
        position: absolute;
        top: 0;
        left: -20px;
        width: 1px;
        height: 100%;
        background-color: #ddd;
    }
    .folder:last-child::before {
        height: 50%;
    }
    .file {
        margin-left: 40px;
        position: relative;
    }
    .file::before {
        content: '';
        position: absolute;
        top: 0;
        left: -20px;
        width: 1px;
        height: 100%;
        background-color: #ddd;
    }
    .file:last-child::before {
        height: 50%;
    }
    .file-info {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 5px;
    }
</style>
</head>
<body>
<div class="container">
<h1>Drive Catalog</h1>
<div class="info">
    <div><strong>Total Size:</strong> {TOTAL_SIZE}</div>
    <div><strong>Total Files:</strong> {TOTAL_FILES}</div>
    <div><strong>Created On:</strong> {CREATED_DATE}</div>
</div>
<div class="folder-structure">
    {CONTENT}
</div>
</div>
</body>
</html>
"@

function Format-FileSize {
    param ([long]$size)
    $sizes = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($size -ge 1024 -and $index -lt ($sizes.Count - 1)) {
        $size = $size / 1024
        $index++
    }
    return "{0:N2} {1}" -f $size, $sizes[$index]
}

function Get-FolderStructure {
    param (
        [string]$path,
        [int]$level = 0
    )
    $structure = ""
    $indent = "    " * $level
    Get-ChildItem -Path $path | Sort-Object Name | ForEach-Object {
        if ($_.PSIsContainer) {
            $structure += "$indent<div class='folder'>📁 $($_.Name)"
            $structure += Get-FolderStructure -path $_.FullName -level ($level + 1)
            $structure += "$indent</div>"
        } else {
            $size = Format-FileSize -size $_.Length
            $ext = $_.Extension.TrimStart('.')
            $structure += "$indent<div class='file'>"
            $structure += "$indent    <div class='file-info'><span>$($_.Name)</span><span>$size</span></div>"
            if ($ext) {
                $structure += "$indent    <div class='file-info'><span>.$ext</span></div>"
            }
            $structure += "$indent</div>"
        }
    }
    return $structure
}

# Get the source directory
$sourcePath = "D:\TV" # Change this to your directory path

# Calculate total size and files
$totalSize = 0
$totalFiles = 0
Get-ChildItem -Path $sourcePath -Recurse -File | ForEach-Object {
    $totalSize += $_.Length
    $totalFiles++
}

# Generate the structure
$structure = Get-FolderStructure -path $sourcePath

# Replace placeholders in the template
$html = $htmlTemplate.Replace("{CONTENT}", $structure)
$html = $html.Replace("{TOTAL_SIZE}", (Format-FileSize $totalSize))
$html = $html.Replace("{TOTAL_FILES}", $totalFiles)
$html = $html.Replace("{CREATED_DATE}", (Get-Date -Format "yyyy-MM-dd"))

# Save the file
$outputPath = ".\DriveArchive_$(Get-Date -Format 'yyyy-MM-dd').html"
$html | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "Catalog has been created at: $outputPath"