$htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drive Catalog</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #f9fafb;
            color: #333;
            margin: 0;
            padding: 16px;
        }
        .container {
            max-width: 1100px;
            margin: auto;
            background: white;
            padding: 24px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            font-size: 24px;
            margin-bottom: 10px;
        }
        .stats {
            display: flex;
            justify-content: space-between;
            background: #eef2ff;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .stat-card {
            text-align: center;
            flex: 1;
        }
        .stat-title {
            font-size: 14px;
            color: #555;
        }
        .stat-value {
            font-size: 18px;
            font-weight: bold;
            color: #333;
        }
        .search {
            width: 100%;
            padding: 10px;
            font-size: 16px;
            border: 1px solid #ddd;
            border-radius: 6px;
            margin-bottom: 16px;
        }
        .folder {
            margin: 8px 0;
        }
        .folder-header {
            display: flex;
            align-items: center;
            background: #e2e8f0;
            padding: 10px;
            cursor: pointer;
            border-radius: 6px;
            transition: background 0.3s;
        }
        .folder-header:hover {
            background: #cbd5e1;
        }
        .folder-icon {
            font-size: 18px;
            margin-right: 8px;
        }
        .folder-content {
            padding-left: 20px;
            display: none;
        }
        .file {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 6px 10px;
            border-radius: 4px;
            transition: background 0.3s;
        }
        .file:hover {
            background: #f1f5f9;
        }
        .file-name {
            flex-grow: 1;
            text-decoration: none;
            color: #2563eb;
        }
        .file-size {
            font-size: 14px;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Drive Catalog</h1>
        <input type="text" class="search" placeholder="Search files and folders...">
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-title">Total Size</div>
                <div class="stat-value">{TOTAL_SIZE}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">Total Files</div>
                <div class="stat-value">{TOTAL_FILES}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">Created On</div>
                <div class="stat-value">{CREATED_DATE}</div>
            </div>
        </div>
        
        <div id="file-tree">{CONTENT}</div>
    </div>

    <script>
        // Folder Toggle
        document.querySelectorAll('.folder-header').forEach(header => {
            header.addEventListener('click', () => {
                const content = header.nextElementSibling;
                content.style.display = (content.style.display === 'block') ? 'none' : 'block';
            });
        });

        // Search functionality
        document.querySelector('.search').addEventListener('input', function () {
            let query = this.value.toLowerCase();
            document.querySelectorAll('.file, .folder-header').forEach(item => {
                let match = item.textContent.toLowerCase().includes(query);
                item.style.display = match ? '' : 'none';
            });
        });
    </script>
</body>
</html>
"@

function Format-FileSize {
    param ([long]$size)
    $sizes = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($size -ge 1024 -and $index -lt ($sizes.Count - 1)) {
        $size /= 1024
        $index++
    }
    return "{0:N2} {1}" -f $size, $sizes[$index]
}

function Get-FolderStructure {
    param ([string]$path, [int]$level = 0)
    
    $structure = ""
    Get-ChildItem -Path $path | Sort-Object Name | ForEach-Object {
        if ($_.PSIsContainer) {
            $structure += "<div class='folder'>"
            $structure += "<div class='folder-header'><span class='folder-icon'>📂</span><span>$($_.Name)</span></div>"
            $structure += "<div class='folder-content'>" + (Get-FolderStructure -path $_.FullName -level ($level + 1)) + "</div>"
            $structure += "</div>"
        } else {
            $size = Format-FileSize -size $_.Length
            $ext = $_.Extension.TrimStart('.')
            $structure += "<div class='file'>"
            $structure += "<a class='file-name' href='file://$($_.FullName.Replace('\', '/'))' target='_blank'>$($_.Name)</a>"
            $structure += "<span class='file-size'>$size</span>"
            $structure += "</div>"
        }
    }
    
    return $structure
}

# Get the source directory
$sourcePath = "E:\TV\K-Drama"  # Change to your drive path

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
$html = $htmlTemplate -replace "{CONTENT}", $structure
$html = $html -replace "{TOTAL_SIZE}", (Format-FileSize $totalSize)
$html = $html -replace "{TOTAL_FILES}", $totalFiles
$html = $html -replace "{CREATED_DATE}", (Get-Date -Format "yyyy-MM-dd")

# Save the file
$outputPath = ".\DriveCatalog_$(Get-Date -Format 'yyyy-MM-dd').html"
$html | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "Catalog created at: $outputPath"
