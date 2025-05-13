# PowerShell script to generate a self-contained HTML catalog

$htmlTemplate = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drive Catalog</title>
    <style>
        body {
            font-family: system-ui, -apple-system, sans-serif;
            line-height: 1.5;
            margin: 0;
            padding: 16px;
            background: #f0f2f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .header {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: #f8fafc;
            padding: 16px;
            border-radius: 6px;
            border: 1px solid #e2e8f0;
        }
        .stat-title {
            color: #64748b;
            font-size: 14px;
            margin-bottom: 4px;
        }
        .stat-value {
            font-size: 20px;
            font-weight: 600;
            color: #0f172a;
        }
        .folder {
            margin: 8px 0;
            padding-left: 20px;
        }
        .folder-header {
            cursor: pointer;
            padding: 8px;
            background: #f8fafc;
            border-radius: 4px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .folder-header:hover {
            background: #f1f5f9;
        }
        .folder-name {
            font-weight: 500;
        }
        .folder-content {
            margin-left: 20px;
            display: none;
        }
        .file {
            display: flex;
            align-items: center;
            padding: 4px 8px;
            gap: 8px;
            border-radius: 4px;
        }
        .file:hover {
            background: #f8fafc;
        }
        .file-size {
            color: #64748b;
            font-size: 14px;
            min-width: 70px;
        }
        .file-name {
            flex-grow: 1;
        }
        .extension {
            color: #64748b;
            font-size: 14px;
            padding: 2px 6px;
            background: #f1f5f9;
            border-radius: 4px;
        }
        .search {
            width: 100%;
            padding: 8px 16px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 16px;
        }
        .search:focus {
            outline: none;
            border-color: #93c5fd;
            box-shadow: 0 0 0 3px rgba(147,197,253,0.1);
        }
        .toggle-all {
            margin-bottom: 16px;
            padding: 8px 16px;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            cursor: pointer;
        }
        .toggle-all:hover {
            background: #f1f5f9;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Drive Catalog</h1>
            <input type="text" class="search" placeholder="Search files and folders...">
            <button class="toggle-all">Toggle All Folders</button>
        </div>
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
        <div id="file-tree">
            {CONTENT}
        </div>
    </div>
    <script>
        // Toggle folder visibility
        document.querySelectorAll('.folder-header').forEach(header => {
            header.addEventListener('click', () => {
                const content = header.nextElementSibling;
                content.style.display = content.style.display === 'none' ? 'block' : 'none';
            });
        });

        // Search functionality
        const search = document.querySelector('.search');
        search.addEventListener('input', (e) => {
            const searchTerm = e.target.value.toLowerCase();
            document.querySelectorAll('.folder, .file').forEach(item => {
                const text = item.textContent.toLowerCase();
                const isMatch = text.includes(searchTerm);
                item.style.display = isMatch ? '' : 'none';
                
                // Show parent folders of matching items
                if (isMatch) {
                    let parent = item.parentElement;
                    while (parent && parent.classList.contains('folder-content')) {
                        parent.style.display = 'block';
                        parent = parent.parentElement;
                    }
                }
            });
        });

        // Toggle all folders
        let allFoldersOpen = false;
        document.querySelector('.toggle-all').addEventListener('click', () => {
            allFoldersOpen = !allFoldersOpen;
            document.querySelectorAll('.folder-content').forEach(folder => {
                folder.style.display = allFoldersOpen ? 'block' : 'none';
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
            $structure += "$indent<div class='folder'>`n"
            $structure += "$indent    <div class='folder-header'>`n"
            $structure += "$indent        <span class='folder-name'>📁 $($_.Name)</span>`n"
            $structure += "$indent    </div>`n"
            $structure += "$indent    <div class='folder-content'>`n"
            $structure += Get-FolderStructure -path $_.FullName -level ($level + 2)
            $structure += "$indent    </div>`n"
            $structure += "$indent</div>`n"
        } else {
            $size = Format-FileSize -size $_.Length
            $ext = $_.Extension.TrimStart('.')
            $structure += "$indent<div class='file'>`n"
            $structure += "$indent    <span class='file-size'>$size</span>`n"
            $structure += "$indent    <span class='file-name'>$($_.Name)</span>`n"
            if ($ext) {
                $structure += "$indent    <span class='extension'>$ext</span>`n"
            }
            $structure += "$indent</div>`n"
        }
    }
    
    return $structure
}

# Get the source directory
$sourcePath = "E:\" # Change this to your directory path

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