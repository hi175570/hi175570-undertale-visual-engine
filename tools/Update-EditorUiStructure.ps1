param([string]$Document = "docs/EDITOR_UI_STRUCTURE.md")

# Keep the documented entry point. The old hand-maintained capability matrix
# omitted newer conditional fields; the replacement reads current GML metadata.
$ErrorActionPreference = 'Stop'
$generator = Join-Path $PSScriptRoot 'Refresh-EditorUiTree.cjs'
& node $generator --document ([IO.Path]::GetFullPath($Document))
if ($LASTEXITCODE -ne 0) { throw "UI tree generation failed: $LASTEXITCODE" }
