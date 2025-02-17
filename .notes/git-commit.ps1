
[string] $path_build    = "D:\azdo\arquitech\carbon"

Set-Location $path_build

Write-Host "///// Git Commit //////////////////////////////" -f DarkCyan

# Script para detectar cambios y hacer commit en Git
# Función para verificar y manejar errores
function Test-GitCommand {
  param (
      [string]$Command,
      [string]$ErrorMessage
  )
  
  try {
      $output = Invoke-Expression $Command 2>&1
      if ($LASTEXITCODE -ne 0) {
          Write-Host "Error: $ErrorMessage" -ForegroundColor Red
          Write-Host "Detalles: $output" -ForegroundColor Red
          return $false
      }
      return $true
  }
  catch {
      Write-Host "Error: $ErrorMessage" -ForegroundColor Red
      Write-Host "Detalles: $_" -ForegroundColor Red
      return $false
  }
}

# Obtener la ruta actual del directorio
$currentPath = Get-Location

# Verificar si es un repositorio Git
if (-not (Test-Path -Path "$currentPath\.git")) {
  Write-Host "Error: El directorio actual no es un repositorio Git." -ForegroundColor Red
  exit 1
}

# Verificar conexión con el repositorio remoto
$remoteCheck = Test-GitCommand "git remote -v" "No se puede acceder al repositorio remoto"
if (-not $remoteCheck) {
  Write-Host "Advertencia: Continuar solo con operaciones locales" -ForegroundColor Yellow
}

# Realizar pull antes de cualquier operación
if ($remoteCheck) {
  Write-Host "`nRealizando pull para sincronizar con el repositorio remoto..." -ForegroundColor Cyan
  $pullSuccess = Test-GitCommand "git pull" "Error al realizar pull"
  if (-not $pullSuccess) {
      $confirmation = Read-Host "¿Deseas continuar de todos modos? (S/N)"
      if ($confirmation -ne 'S' -and $confirmation -ne 's') {
          exit 1
      }
  }
}

# Obtener los archivos modificados
$modifiedFiles = git status --porcelain

if ($modifiedFiles) {
  Write-Host "`nArchivos modificados encontrados:" -ForegroundColor Yellow
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
      # Verificar si hay conflictos
      $conflicts = git diff --name-only --diff-filter=U
      if ($conflicts) {
          Write-Host "`nError: Hay conflictos que deben resolverse primero:" -ForegroundColor Red
          $conflicts | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
          exit 1
      }

      # Añadir todos los cambios
      if (-not (Test-GitCommand "git add ." "Error al añadir los archivos")) {
          exit 1
      }

      # Solicitar mensaje de commit
      $commitMessage = Read-Host "Introduce el mensaje para el commit"
      
      # Realizar el commit
      if (-not (Test-GitCommand "git commit -m `"$commitMessage`"" "Error al realizar el commit")) {
          exit 1
      }

      Write-Host "`nCommit realizado exitosamente." -ForegroundColor Green

      # Preguntar si desea hacer push
      if ($remoteCheck) {
          $pushConfirmation = Read-Host "`n¿Deseas hacer push de los cambios? (S/N)"
          if ($pushConfirmation -eq 'S' -or $pushConfirmation -eq 's') {
              # Verificar si hay cambios en el remoto antes de push
              if (Test-GitCommand "git fetch" "Error al verificar cambios remotos") {
                  $behindCount = git rev-list HEAD..origin/$(git branch --show-current) --count
                  if ($behindCount -gt 0) {
                      Write-Host "`nAdvertencia: Hay cambios en el repositorio remoto." -ForegroundColor Yellow
                      Write-Host "Se recomienda hacer pull antes de push." -ForegroundColor Yellow
                      $forcePush = Read-Host "¿Deseas hacer pull antes de push? (S/N)"
                      if ($forcePush -eq 'S' -or $forcePush -eq 's') {
                          if (-not (Test-GitCommand "git pull" "Error al realizar pull")) {
                              exit 1
                          }
                      }
                  }
              }

              # Realizar push
              if (Test-GitCommand "git push" "Error al realizar push") {
                  Write-Host "`nPush realizado exitosamente." -ForegroundColor Green
              }
          }
      }
      
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
