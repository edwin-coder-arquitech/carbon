
[string] $path_build    = "D:\azdo\arquitech\carbon"

Set-Location $path_build

Write-Host "///// Git Commit //////////////////////////////" -f DarkCyan

# Script para detectar cambios y hacer commit en Git
# Obtener la ruta actual del directorio
$currentPath = Get-Location

# Verificar si es un repositorio Git
if (-not (Test-Path -Path "$currentPath\.git")) {
    Write-Host "Error: El directorio actual no es un repositorio Git." -ForegroundColor Red
    exit 1
}

# Obtener los archivos modificados
$modifiedFiles = git status --porcelain

if ($modifiedFiles) {
    Write-Host "Archivos modificados encontrados:" -ForegroundColor Yellow
    $modifiedFiles | ForEach-Object {
        $status = $_.Substring(0, 2)
        $file = $_.Substring(3)
        
        switch ($status.Trim()) {
            'M' { Write-Host "  Modificado: $file" -ForegroundColor Yellow }
            'A' { Write-Host "  Añadido: $file" -ForegroundColor Green }
            'D' { Write-Host "  Eliminado: $file" -ForegroundColor Red }
            '??' { Write-Host "  Sin seguimiento: $file" -ForegroundColor Gray }
            default { Write-Host "  $status $file" }
        }
    }

    # Preguntar al usuario si desea continuar
    $confirmation = Read-Host "`n¿Deseas hacer commit de estos cambios? (S/N)"
    if ($confirmation -eq 'S' -or $confirmation -eq 's') {
        # Añadir todos los cambios
        git add .

        # Solicitar mensaje de commit
        $commitMessage = Read-Host "Introduce el mensaje para el commit"
        
        # Realizar el commit
        git commit -m $commitMessage

        Write-Host "`nCommit realizado exitosamente." -ForegroundColor Green
        
        # Mostrar el último commit
        Write-Host "`nÚltimo commit:" -ForegroundColor Cyan
        git log -1
    }
    else {
        Write-Host "`nOperación cancelada." -ForegroundColor Yellow
    }
}
else {
    Write-Host "No se encontraron cambios en el repositorio." -ForegroundColor Green
}
