
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
      $output = Invoke-Expression "$Command 2>&1"
      if ($LASTEXITCODE -ne 0) {
          Write-Host "Error: $ErrorMessage" -ForegroundColor Red
          Write-Host "Comando que falló: $Command" -ForegroundColor Yellow
          Write-Host "Detalles del error:" -ForegroundColor Red
          Write-Host $output -ForegroundColor Red
          
          # Verificar tipos específicos de errores
          if ($output -match "no upstream branch") {
              Write-Host "`nSolución: La rama actual no tiene upstream. Intenta:" -ForegroundColor Yellow
              Write-Host "git push --set-upstream origin $(git branch --show-current)" -ForegroundColor Cyan
              $setUpstream = Read-Host "¿Deseas configurar el upstream ahora? (S/N)"
              if ($setUpstream -eq 'S' -or $setUpstream -eq 's') {
                  $upstreamCommand = "git push --set-upstream origin $(git branch --show-current)"
                  Invoke-Expression $upstreamCommand
                  return $?
              }
          }
          elseif ($output -match "Permission denied") {
              Write-Host "`nError de permisos. Verifica:" -ForegroundColor Yellow
              Write-Host "1. Tus credenciales de Git están configuradas correctamente" -ForegroundColor Cyan
              Write-Host "2. Tienes permisos en el repositorio remoto" -ForegroundColor Cyan
          }
          elseif ($output -match "Your push would publish a private email address") {
              Write-Host "`nError: GitHub está protegiendo tu correo electrónico privado" -ForegroundColor Red
              Write-Host "`nPuedes resolver esto de dos formas:" -ForegroundColor Yellow
              Write-Host "1. Configurar un correo noreply de GitHub:" -ForegroundColor Cyan
              Write-Host "   git config --global user.email 'tu-usuario@users.noreply.github.com'" -ForegroundColor White
              Write-Host "`n2. Ajustar la configuración de privacidad en GitHub:" -ForegroundColor Cyan
              Write-Host "   - Visita: https://github.com/settings/emails" -ForegroundColor White
              Write-Host "   - Modifica las opciones de privacidad de correo" -ForegroundColor White
              
              $option = Read-Host "`n¿Deseas configurar un correo noreply ahora? (S/N)"
              if ($option -eq 'S' -or $option -eq 's') {
                  $currentUser = git config user.name
                  $noreplyEmail = "$currentUser@users.noreply.github.com"
                  Write-Host "`nConfigurando correo noreply: $noreplyEmail" -ForegroundColor Cyan
                  git config user.email $noreplyEmail
                  Write-Host "Correo configurado. Intentando push nuevamente..." -ForegroundColor Green
                  return Test-GitCommand "git push" "Error al realizar push después de configurar correo"
              }
          }
          elseif ($output -match "failed to push some refs") {
              Write-Host "`nEl push falló. Intentando obtener más información..." -ForegroundColor Yellow
              Write-Host "`nEstado actual de la rama:" -ForegroundColor Cyan
              git status
              Write-Host "`nDiferencias con el remoto:" -ForegroundColor Cyan
              git diff origin/$(git branch --show-current)
          }
          return $false
      }
      return $true
  }
  catch {
      Write-Host "Error: $ErrorMessage" -ForegroundColor Red
      Write-Host "Excepción: $_" -ForegroundColor Red
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

# Mostrar información del estado actual
Write-Host "`nInformación del repositorio:" -ForegroundColor Cyan
Write-Host "Rama actual: $(git branch --show-current)" -ForegroundColor White
Write-Host "Remoto configurado: $(git remote -v)" -ForegroundColor White

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
              # Verificar el estado antes del push
              Write-Host "`nVerificando estado del repositorio antes del push..." -ForegroundColor Cyan
              git status
              
              # Realizar fetch para verificar cambios remotos
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

              # Intentar push con más información
              Write-Host "`nIntentando push..." -ForegroundColor Cyan
              if (-not (Test-GitCommand "git push" "Error al realizar push")) {
                  Write-Host "`nIntentando push con -v para más detalles..." -ForegroundColor Yellow
                  Test-GitCommand "git push -v" "Error al realizar push (verbose)"
                  
                  # Mostrar opciones de recuperación
                  Write-Host "`nOpciones disponibles:" -ForegroundColor Yellow
                  Write-Host "1. Intentar git push --force (CUIDADO: puede sobrescribir cambios remotos)" -ForegroundColor Red
                  Write-Host "2. Hacer git pull --rebase y reintentar" -ForegroundColor Cyan
                  Write-Host "3. Verificar configuración del remoto" -ForegroundColor Cyan
                  $option = Read-Host "`nSelecciona una opción (1-3) o presiona Enter para cancelar"
                  
                  switch ($option) {
                      "1" { Test-GitCommand "git push --force" "Error al realizar force push" }
                      "2" { 
                          if (Test-GitCommand "git pull --rebase" "Error al realizar pull --rebase") {
                              Test-GitCommand "git push" "Error al realizar push después del rebase"
                          }
                      }
                      "3" { 
                          Write-Host "`nConfiguración actual del remoto:" -ForegroundColor Cyan
                          git remote -v
                      }
                  }
              } else {
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
