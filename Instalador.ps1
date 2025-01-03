﻿# Show Menu
function Show-Menu {
    Clear-Host
    Write-Host "---------------------------" -ForegroundColor Cyan
    Write-Host "  Escolha uma opção:        " -ForegroundColor Cyan
    Write-Host "---------------------------" -ForegroundColor Cyan
    Write-Host "1. Instalar programas" -ForegroundColor Yellow
    Write-Host "2. Executar o Windows Defender (Verificação Completa)" -ForegroundColor Yellow
    Write-Host "3. Executar o Windows Defender (Verificação Rápida)" -ForegroundColor Yellow
    Write-Host "4. Atualização do Windows (Verificação Windows Update)" -ForegroundColor Yellow
    Write-Host "5. Sair" -ForegroundColor Yellow
    Write-Host "---------------------------" -ForegroundColor Cyan
}

# Check installed programs
function Is-ProgramInstalled {
    param([string]$programName)
    $program = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$programName*" }
    return $program -ne $null
}

# Install programs
function Install-Programs {
    Write-Host "Iniciando instalação dos programas..." -ForegroundColor Green

    # Install Chocolatey
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    } catch {
        Write-Host "Erro ao instalar o Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # Check main programs to install
    $programs = @("winrar", "googlechrome", "firefox", "vlc", "adobereader", "jre8", "zoom")
    
    foreach ($program in $programs) {
        if (Is-ProgramInstalled -programName $program) {
            Write-Host "$program já está instalado." -ForegroundColor Yellow
        } else {
            try {
                Write-Host "Instalando $program..." -ForegroundColor Green
                choco install $program -y
                Write-Host "$program instalado com sucesso!" -ForegroundColor Green
            } 
            catch {
                Write-Host "Erro ao instalar $program : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Full scan Defender
function Run-FullScan {
    Write-Host "Iniciando verificação completa do Windows Defender..." -ForegroundColor Green
    try {
        Start-MpScan -ScanType FullScan #initialize Windows Scan

        Write-Host "Verificação completa finalizada!" -ForegroundColor Green
    } 
    catch {
        Write-Host "Erro ao executar verificação completa do Windows Defender: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Quick scan Defender
function Run-QuickScan {
    Write-Host "Iniciando verificação rápida do Windows Defender..." -ForegroundColor Green
    try {
        Start-MpScan -ScanType QuickScan #initialize Windows Scan

        Write-Host "Verificação rápida finalizada!" -ForegroundColor Green
    } 
    catch {
        Write-Host "Erro ao executar verificação rápida do Windows Defender: $($_.Exception.Message)" -ForegroundColor Red
    }
}


# Admin check function
function Verificar-Administrador {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        Write-Host "Este script requer permissões administrativas. Reiniciando com privilégios elevados..." -ForegroundColor Yellow

        # Admin PS path
        $scriptPath = $PSCommandPath

        # Relaunch PS
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
}

# Check if we are using Admin privilege
Verificar-Administrador

function Windows-Update {
    try {
        Write-Host "Verificando atualização do Windows..." -ForegroundColor Yellow

        # Checking if PSWindowsUpdate is installed
        if(!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "PSWindowsUpdate não encontrado. Instalando módulo..." -ForegroundColor Cyan
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
        }

        #import module
        Import-Module PSWindowsUpdate


        #Show available updates
        $update = Get-WindowsUpdate
        
        if($update) {
            Write-Host "As seguintes atualizações estão disponíveis:" -ForegroundColor Cyan
            $update | Format-Table -AutoSize


        # User's confirmation
        $confirm = Read-Host "Deseja instalar todas as atualizações? O COMPUTADOR VAI REINICIALIZAR, SALVAR TODOS OS ARQUIVOS ANTES DE PROSSEGUIR!! (S/N):  "
        if($confirm -eq "S") {
            Write-Host "Instalando atualizações. Isso pode levar alguns minutos."
             Install-WindowsUpdate -AcceptAll -ForceInstall -AutoReboot
            Write-Host "Atualizações instaladas com sucesso!" -ForegroundColor Green
        }
        else {
            Write-Host "Instalação não realizada" -ForegroundColor Red
        }
        else {
         Write-Host "Nenhuma atualização disponível no momento." -ForegroundColor Green
        }
    }
}
catch {
        Write-Host "Erro ao verificar ou instalar atualizações: $($_.Exception.Message)" -ForegroundColor Red
    }
}
# Selection menu
do {
    Show-Menu
    $option = Read-Host "Escolha uma opção (1-5)"

    switch ($option) {
        "1" {
            Install-Programs
            Read-Host "Pressione Enter para continuar..."  # User's Pause to check
        }
        "2" {
            Run-FullScan
            Read-Host "Pressione Enter para continuar..."  # User's Pause to check
        }
        "3" {
            Run-QuickScan
            Read-Host "Pressione Enter para continuar..."  # User's Pause to check
        }
         "4" {
            Windows-Update
            Write-Host "Atualizar Software" -ForegroundColor Red
        }
         "5" {
            
            Write-Host "Saindo... Até logo!" -ForegroundColor Red
        }
        default {
            Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
        }
    }
    Pause

} while ($option -ne "4")
