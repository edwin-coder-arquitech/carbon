# 
[string] $path_build    = "C:\azdo\arquitech\carbon\packages" # $PSScriptRoot
[string] $path_build    = "D:\azdo\arquitech\carbon\packages"

Set-Location $path_build

Write-Host "///// Public Package //////////////////////////////" -f DarkCyan

# Mode                 LastWriteTime         Length Name
# ----                 -------------         ------ ----
# d----            25/02/15    08:27                carbon-components
# d----            25/02/15    08:27                carbon-components-react
# d----            25/02/15    08:34                cli
# d----            25/02/15    08:27                cli-reporter
# d----            25/02/15    08:27                colors
# d----            25/02/15    08:27                elements
# d----            25/02/15    08:27                feature-flags
# d----            25/02/15    08:27                grid
# d----            25/02/15    08:34                icon-build-helpers
# d----            25/02/15    08:34                icon-helpers
# d----            25/02/15    08:27                icons
# d----            25/02/15    08:27                icons-react
# d----            25/02/15    08:27                icons-vue
# d----            25/02/15    08:27                layout
# d----            25/02/15    08:27                motion
# d----            25/02/15    08:27                pictograms
# d----            25/02/15    08:27                pictograms-react
# d----            25/02/15    08:34                react
# d----            25/02/15    08:27                scss-generator
# d----            25/02/15    08:27                styles
# d----            25/02/15    08:27                test-utils
# d----            25/02/15    08:34                themes
# d----            25/02/15    08:27                type
# d----            25/02/15    08:34                upgrade
# d----            25/02/15    08:34                utilities
# d----            25/02/15    08:34                utilities-react
# d----            25/02/15    08:34                web-components

[array] $arrayPackages = @(
    "carbon-components",
    "carbon-components-react",
    "cli",
    "cli-reporter",
    "colors",
    "elements",
    "feature-flags",
    "grid",
    "icon-build-helpers",
    "icon-helpers",
    "icons",
    "icons-react",
    "icons-vue",
    "layout",
    "motion",
    "pictograms",
    "pictograms-react",
    "react",
    "scss-generator",
    "styles",
    "test-utils",
    "themes",
    "type",
    "upgrade",
    "utilities",
    "utilities-react",
    "web-components"
)

$counter =1

foreach ($package in $arrayPackages) {

  Write-Host "`n## $counter $package" -f DarkYellow

  $time_check    = $(Get-Date -Format "yyMMdd.HHmmss")

  Write-Host "check $time_check `n" -f DarkGray

  cd "$path_build\$package"

  npm publish --provenance=false --access public

  $counter++
}

cd ..
