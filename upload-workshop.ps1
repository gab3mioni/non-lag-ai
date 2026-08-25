#Requires -Version 5.1
<#
.SYNOPSIS
    Publica (ou atualiza) o mod no Steam Workshop via steamcmd.

.DESCRIPTION
    Primeira execucao com steam\workshop.item ausente (ou publishedfileid=0):
    cria o item NO Workshop com visibilidade OCULTA (reserva do ID).
    Execucoes seguintes atualizam o mesmo item (o ID nunca muda).

    O script roda export-workshop.ps1 antes do upload (use -SkipExport para pular),
    gera steam\build.vdf e chama o steamcmd. Senha e Steam Guard sao pedidos
    interativamente pelo proprio steamcmd.

.PARAMETER SteamUser
    Login da conta Steam que sera dona do mod (pedira senha e Steam Guard).

.PARAMETER SteamCmdPath
    Caminho do steamcmd.exe. Auto-detecta C:\steamcmd, %ProgramFiles%\steamcmd
    e %LOCALAPPDATA%\steamcmd.

.PARAMETER SetId
    Nao faz upload: apenas grava o PublishedFileId em steam\workshop.item.
    Use quando souber o ID (pagina do item ou C:\steamcmd\logs\workshop_log.txt).

.PARAMETER SkipExport
    Pula o export-workshop.ps1 (usa a build ja existente).

.PARAMETER NewItem
    Autoriza explicitamente a criacao do primeiro item quando o ID registrado e 0.

.PARAMETER Visibility
    0 = publico, 1 = amigos, 2 = oculto (padrao: 2).

.EXAMPLE
    .\upload-workshop.ps1 -SteamUser meu_login -NewItem
    .\upload-workshop.ps1 -SteamUser meu_login -Visibility 0
    .\upload-workshop.ps1 -SetId 1234567890
#>
[CmdletBinding()]
param(
    [string]$SteamUser,
    [string]$SteamCmdPath,
    [string]$SetId,
    [switch]$SkipExport,
    [switch]$NewItem,
    [ValidateSet('0','1','2')]
    [string]$Visibility = '2'
)

$ErrorActionPreference = 'Stop'
$repo     = Split-Path -Parent $MyInvocation.MyCommand.Path
$appId    = '394360'  # Hearts of Iron IV
$title    = 'Non Lag AI'
$itemFile = Join-Path $repo 'steam\workshop.item'

# --- Apenas gravar o ID? ---
if ($SetId) {
    if ($SetId -notmatch '^\d+$') { throw "SetId deve ser numerico: $SetId" }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $itemFile) | Out-Null
    [System.IO.File]::WriteAllText($itemFile, "publishedfileid=$SetId", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "PublishedFileId gravado em steam/workshop.item: $SetId"
    Write-Host "URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$SetId"
    exit 0
}

# --- 1) Build limpa ---
if (-not $SkipExport) {
    & (Join-Path $repo 'export-workshop.ps1')
}

# --- 2) Localizar steamcmd ---
if (-not $SteamCmdPath) {
    $candidates = @(
        'C:\steamcmd\steamcmd.exe',
        (Join-Path $env:ProgramFiles 'steamcmd\steamcmd.exe'),
        (Join-Path $env:LOCALAPPDATA 'steamcmd\steamcmd.exe')
    )
    $SteamCmdPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $SteamCmdPath) {
        throw @'
steamcmd.exe nao encontrado.
Instale em C:\steamcmd:
  1. Baixe https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
  2. Extraia o conteudo em C:\steamcmd\
  3. Rode C:\steamcmd\steamcmd.exe uma vez (auto-atualizacao) e saia com: quit
Ou informe o caminho com -SteamCmdPath.
'@
    }
}

# --- 3) Pasta de conteudo (mesmo padrao do export) ---
$docs = [Environment]::GetFolderPath('MyDocuments')
$content = Join-Path $docs 'Paradox Interactive\Hearts of Iron IV\mod\non-lag-ai-build'
if (-not (Test-Path (Join-Path $content 'descriptor.mod'))) {
    throw "Build nao encontrada em: $content`nRode .\export-workshop.ps1 primeiro (ou sem -SkipExport)."
}

# --- 4) PublishedFileId atual ---
$publishedFileId = '0'
if (Test-Path $itemFile) {
    $m = [regex]::Match((Get-Content $itemFile -Raw), 'publishedfileid=(\d+)')
    if ($m.Success) { $publishedFileId = $m.Groups[1].Value }
}
if ($publishedFileId -eq '0' -and -not $NewItem) {
    throw @'
Nenhum PublishedFileId registrado em steam\workshop.item.
Use -NewItem apenas para criar o primeiro item ou -SetId para registrar um item existente.
'@
}

$descriptor = Get-Content (Join-Path $content 'descriptor.mod') -Raw
$version    = [regex]::Match($descriptor, 'version="([^"]+)"').Groups[1].Value
if (-not $version) { $version = '0.0.0' }

# --- 5) Gerar VDF ---
$vdf        = Join-Path $repo 'steam\build.vdf'
$contentFwd = $content -replace '\\','/'
$previewFwd = (Join-Path $repo 'Thumbnail.png') -replace '\\','/'
$vdfContent = @"
"workshopitem"
{
	"appid"				"$appId"
	"publishedfileid"	"$publishedFileId"
	"contentfolder"		"$contentFwd"
	"previewfile"		"$previewFwd"
	"title"				"$title"
	"visibility"		"$Visibility"
	"changenote"		"v$version"
}
"@
[System.IO.File]::WriteAllText($vdf, $vdfContent, (New-Object System.Text.UTF8Encoding($false)))

if ($publishedFileId -eq '0') {
    Write-Host '>> Primeira publicacao: um NOVO item oculto sera criado no Workshop.' -ForegroundColor Yellow
} else {
    Write-Host ">> Atualizando o item $publishedFileId (v$version)." -ForegroundColor Yellow
}

# --- 6) Login + publish (interativo: senha e Steam Guard no console) ---
if (-not $SteamUser) { $SteamUser = Read-Host 'Login da Steam' }
Write-Host 'Iniciando steamcmd (pedira senha e, se necessario, codigo do Steam Guard)...' -ForegroundColor Cyan
& $SteamCmdPath +login $SteamUser +workshop_build_item ($vdf -replace '\\','/') +quit
$steamExit = $LASTEXITCODE

# --- 7) Tentar capturar o ID do log do steamcmd ---
$wsLog = Join-Path (Split-Path -Parent $SteamCmdPath) 'logs\workshop_log.txt'
if ($steamExit -eq 0 -and $publishedFileId -eq '0' -and (Test-Path $wsLog)) {
    $logTail = (Get-Content $wsLog -Tail 50) -join "`n"
    $idMatch = [regex]::Match($logTail, '(?:Success|Publish\w*)[^\r\n]*?(\d{9,12})')
    if (-not $idMatch.Success) {
        $idMatch = [regex]::Match($logTail, '\b(\d{9,12})\b')
    }
    if ($idMatch.Success) {
        $newId = $idMatch.Groups[1].Value
        [System.IO.File]::WriteAllText($itemFile, "publishedfileid=$newId", (New-Object System.Text.UTF8Encoding($false)))
        $publishedFileId = $newId
    }
}

Write-Host ''
if ($steamExit -ne 0) {
    Write-Warning "steamcmd encerrou com codigo $steamExit - confira o log acima."
    exit $steamExit
}

Write-Host '=== Upload concluido ===' -ForegroundColor Green
if ($publishedFileId -ne '0') {
    Write-Host "PublishedFileId: $publishedFileId"
    Write-Host "URL: https://steamcommunity.com/sharedfiles/filedetails/?id=$publishedFileId"
} else {
    Write-Warning 'Nao foi possivel capturar o ID automaticamente.'
    Write-Host 'Pegue o ID na pagina do item (Steam > perfil > Workshop items) ou em:'
    Write-Host "  $wsLog"
    Write-Host 'Depois grave com: .\upload-workshop.ps1 -SetId O_ID_AQUI'
}
exit 0
