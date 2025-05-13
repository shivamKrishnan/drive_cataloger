# PowerShell script to generate a self-contained HTML catalog

# HTML Template as a here-string
$htmlTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drive Catalog Explorer</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-light: #3b82f6;
            --background: #f8fafc;
            --surface: #ffffff;
            --border: #e2e8f0;
            --text: #1e293b;
            --text-secondary: #64748b;
            --hover: #f1f5f9;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: system-ui, -apple-system, sans-serif;
            line-height: 1.6;
            color: var(--text);
            background: var(--background);
            min-height: 100vh;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }

        .header {
            background: var(--surface);
            border-radius: 12px;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .title {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 1.5rem;
        }

        .title h1 {
            font-size: 1.75rem;
            font-weight: 600;
            color: var(--text);
        }

        .search-container {
            position: relative;
            margin-bottom: 1rem;
        }

        .search-icon {
            position: absolute;
            left: 1rem;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
        }

        .search {
            width: 100%;
            padding: 0.75rem 1rem 0.75rem 2.5rem;
            border: 2px solid var(--border);
            border-radius: 8px;
            font-size: 1rem;
            transition: all 0.2s;
        }

        .search:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37,99,235,0.1);
        }

        .controls {
            display: flex;
            gap: 1rem;
            margin-bottom: 1rem;
        }

        .button {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 6px;
            font-size: 0.875rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .button-primary {
            background: var(--primary);
            color: white;
        }

        .button-primary:hover {
            background: var(--primary-light);
        }

        .button-secondary {
            background: var(--surface);
            border: 1px solid var(--border);
        }

        .button-secondary:hover {
            background: var(--hover);
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--surface);
            padding: 1.25rem;
            border-radius: 8px;
            border: 1px solid var(--border);
            transition: all 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }

        .stat-title {
            font-size: 0.875rem;
            color: var(--text-secondary);
            margin-bottom: 0.5rem;
        }

        .stat-value {
            font-size: 1.5rem;
            font-weight: 600;
            color: var(--text);
        }

        .file-explorer {
            background: var(--surface);
            border-radius: 12px;
            padding: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .folder {
            margin: 0.5rem 0;
        }

        .folder-header {
            display: flex;
            align-items: center;
            padding: 0.5rem;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .folder-header:hover {
            background: var(--hover);
        }

        .folder-name {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            font-weight: 500;
        }

        .folder-content {
            margin-left: 1.5rem;
            padding-left: 1rem;
            border-left: 1px solid var(--border);
        }

        .file {
            display: flex;
            align-items: center;
            padding: 0.5rem;
            border-radius: 6px;
            transition: all 0.2s;
        }

        .file:hover {
            background: var(--hover);
        }

        .file-size {
            min-width: 100px;
            color: var(--text-secondary);
            font-size: 0.875rem;
        }

        .file-name {
            flex-grow: 1;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .extension-badge {
            padding: 0.25rem 0.5rem;
            background: var(--background);
            border-radius: 4px;
            font-size: 0.75rem;
            color: var(--text-secondary);
            font-weight: 500;
        }

        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 1rem;
            padding: 0.5rem;
            background: var(--background);
            border-radius: 6px;
            overflow-x: auto;
            white-space: nowrap;
        }

        .breadcrumb-item {
            color: var(--text-secondary);
            text-decoration: none;
            font-size: 0.875rem;
        }

        .breadcrumb-item:hover {
            color: var(--primary);
        }

        .breadcrumb-separator {
            color: var(--text-secondary);
        }

        @media (max-width: 768px) {
            .container {
                padding: 1rem;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="title">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M3 3h18v18H3z"/>
                    <path d="M3 9h18"/>
                    <path d="M9 21V9"/>
                </svg>
                <h1>Drive Catalog Explorer</h1>
            </div>

            <div class="search-container">
                <svg class="search-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="11" cy="11" r="8"/>
                    <path d="m21 21-4.3-4.3"/>
                </svg>
                <input type="text" class="search" placeholder="Search files and folders...">
            </div>

            <div class="controls">
                <button class="button button-primary" id="expandAll">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M7 20h10"/>
                        <path d="M12 4v16"/>
                    </svg>
                    Expand All
                </button>
                <button class="button button-secondary" id="collapseAll">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M7 12h10"/>
                    </svg>
                    Collapse All
                </button>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-title">Total Size</div>
                <div class="stat-value">{TOTAL_SIZE}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">Total Files</div>
                <div class="stat-value">{TOTAL_FILES}</div>
            </div>
            <div class="stat-card">
                <div class="stat-title">Last Updated</div>
                <div class="stat-value">{CREATED_DATE}</div>
            </div>
        </div>

        <div class="file-explorer">
            <div class="breadcrumb">
                <a href="#" class="breadcrumb-item">Root</a>
            </div>
            <div id="file-tree">
                {CONTENT}
            </div>
        </div>
    </div>

    <script>
        // Toggle folder visibility
        document.querySelectorAll('.folder-header').forEach(header => {
            header.addEventListener('click', (e) => {
                e.stopPropagation();
                const content = header.nextElementSibling;
                content.style.display = content.style.display === 'none' ? 'block' : 'none';
                updateBreadcrumb(header);
            });
        });

        // Search functionality with debounce
        function debounce(func, wait) {
            let timeout;
            return function executedFunction(...args) {
                const later = () => {
                    clearTimeout(timeout);
                    func(...args);
                };
                clearTimeout(timeout);
                timeout = setTimeout(later, wait);
            };
        }

        const search = document.querySelector('.search');
        const searchFiles = debounce((searchTerm) => {
            searchTerm = searchTerm.toLowerCase();
            document.querySelectorAll('.folder, .file').forEach(item => {
                const text = item.textContent.toLowerCase();
                const isMatch = text.includes(searchTerm);
                
                if (item.classList.contains('file')) {
                    item.style.display = isMatch ? 'flex' : 'none';
                } else {
                    item.style.display = isMatch ? 'block' : 'none';
                }
                
                if (isMatch) {
                    let parent = item.parentElement;
                    while (parent && parent.classList.contains('folder-content')) {
                        parent.style.display = 'block';
                        parent = parent.parentElement;
                    }
                }
            });
        }, 300);

        search.addEventListener('input', (e) => searchFiles(e.target.value));

        // Expand/Collapse all functionality
        const expandAll = document.getElementById('expandAll');
        const collapseAll = document.getElementById('collapseAll');
        
        expandAll.addEventListener('click', () => {
            document.querySelectorAll('.folder-content').forEach(folder => {
                folder.style.display = 'block';
            });
        });
        
        collapseAll.addEventListener('click', () => {
            document.querySelectorAll('.folder-content').forEach(folder => {
                folder.style.display = 'none';
            });
        });

        // Breadcrumb functionality
        function updateBreadcrumb(element) {
            const breadcrumb = document.querySelector('.breadcrumb');
            const path = [];
            let current = element;
            
            while (current && !current.classList.contains('file-explorer')) {
                if (current.classList.contains('folder')) {
                    const name = current.querySelector('.folder-name').textContent.trim();
                    path.unshift(name);
                }
                current = current.parentElement;
            }
            
            breadcrumb.innerHTML = `
                <a href="#" class="breadcrumb-item">Root</a>
                ${path.map(name => `
                    <span class="breadcrumb-separator">/</span>
                    <a href="#" class="breadcrumb-item">${name}</a>
                `).join('')}
            `;
        }

        // Initialize
        document.querySelectorAll('.folder-content').forEach(folder => {
            folder.style.display = 'none';
        });
    </script>
</body>
</html>
'@

# Function to format file sizes
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

# Function to get file icon based on extension
function Get-FileIcon {
    param ([string]$extension)
    switch ($extension.ToLower()) {
        ".pdf" { return "📄" }
        ".doc" { return "📝" }
        ".docx" { return "📝" }
        ".xls" { return "📊" }
        ".xlsx" { return "📊" }
        ".jpg" { return "🖼️" }
        ".jpeg" { return "🖼️" }
        ".png" { return "🖼️" }
        ".gif" { return "🖼️" }
        ".mp3" { return "🎵" }
        ".mp4" { return "🎥" }
        ".zip" { return "📦" }
        ".rar" { return "📦" }
        default { return "📄" }
    }
}

# Function to generate folder structure HTML
function Get-FolderStructure {
    param (
        [string]$path,
        [int]$level = 0
    )
    
    $structure = ""
    $indent = "    " * $level
    
    # Use -LiteralPath to handle special characters in folder names
    Get-ChildItem -LiteralPath $path | Sort-Object Name | ForEach-Object {
        if ($_.PSIsContainer) {
            $structure += "$indent<div class='folder'>`n"
            $structure += "$indent    <div class='folder-header'>`n"
            $structure += "$indent        <div class='folder-name'>📁 $($_.Name)</div>`n"
            $structure += "$indent    </div>`n"
            $structure += "$indent    <div class='folder-content'>`n"
            $structure += Get-FolderStructure -path $_.FullName -level ($level + 2)
            $structure += "$indent    </div>`n"
            $structure += "$indent</div>`n"
        }
        else {
            $size = Format-FileSize -size $_.Length
            $ext = $_.Extension.TrimStart('.')
            $icon = Get-FileIcon -extension $_.Extension
            $structure += "$indent<div class='file'>`n"
            $structure += "$indent    <span class='file-size'>$size</span>`n"
            $structure += "$indent    <span class='file-name'>$icon $($_.Name)</span>`n"
            if ($ext) {
                $structure += "$indent    <span class='extension-badge'>$ext</span>`n"
            }
            $structure += "$indent</div>`n"
        }
    }
    
    return $structure
}

# Get the source directory (change this to your desired path)
$sourcePath = "E:\TV\K-Drama" # Change this path as needed

# Calculate total size and files
$totalSize = 0
$totalFiles = 0
Get-ChildItem -LiteralPath $sourcePath -Recurse -File | ForEach-Object {
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
$outputPath = ".\DriveCatalog_$(Get-Date -Format 'yyyy-MM-dd').html"
$html | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "Catalog has been created at: $outputPath"