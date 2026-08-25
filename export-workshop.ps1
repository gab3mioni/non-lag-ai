#Requires -Version 5.1
<#
.SYNOPSIS
    Gera uma copia limpa do mod, pronta para upload no Steam Workshop.

.DESCRIPTION
    Copia apenas o conteudo do mod (common/, events/, gfx/, history/, interface/,
    localisation/, descriptor.mod, Thumbnail.png) para uma pasta de build,
    excluindo .git, docs/, tests/, .github/, steam/ e arquivos de repositorio.
    Tambem cria o arquivo .mod de registro no Paradox Launcher apontando para a build.

.PARAMETER OutPath
    Destino da pasta de build. Padrao:
    <Documentos>\Paradox Interactive\Hearts of Iron IV\mod\non-lag-ai-build

.EXAMPLE
    .\export-workshop.ps1
    .\export-workshop.ps1 -OutPath D:\builds\non-lag-ai-build
#>
[CmdletBinding()]
param(
    [string]$OutPath
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path (Join-Path $repo '.git') -PathType Container)) {
    Write-Warning "Nao encontrei .git em '$repo' - isto nao parece ser um clone do repositorio."
}

if (-not $OutPath) {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $OutPath = Join-Path $docs 'Paradox Interactive\Hearts of Iron IV\mod\non-lag-ai-build'
}

# Guarda de seguranca: a build nunca pode ficar dentro do repositorio
$repoFull = (Resolve-Path $repo).ProviderPath
$outFull  = [System.IO.Path]::GetFullPath($OutPath)
if ($outFull.StartsWith($repoFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutPath nao pode ficar dentro do repositorio: $outFull"
}

# Valida pastas obrigatorias antes de copiar
foreach ($d in @('common','events','gfx','history','interface','localisation')) {
    if (-not (Test-Path (Join-Path $repo $d))) {
        throw "Pasta obrigatoria ausente no repositorio: $d"
    }
}

New-Item -ItemType Directory -Force -Path $OutPath | Out-Null

# robocopy: codigos de saida 0-7 sao sucesso
$excludeDirs = @('.git','docs','tests','.github','steam','__pycache__') | ForEach-Object { Join-Path $repo $_ }
& robocopy $repo $OutPath /E /XD $excludeDirs /XF '*.md' '*.ps1' '*.sh' '*.py' '.gitignore' '.DS_Store' /NFL /NDL /NJH /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy falhou com codigo $LASTEXITCODE" }

if (-not (Test-Path (Join-Path $OutPath 'descriptor.mod'))) {
    throw "descriptor.mod nao foi copiado para a build."
}

# .mod externo para o Paradox Launcher enxergar a build (upload manual via GUI)
$descriptor = Get-Content (Join-Path $repo 'descriptor.mod') -Raw
$name       = [regex]::Match($descriptor, 'name="([^"]+)"').Groups[1].Value
$version    = [regex]::Match($descriptor, 'version="([^"]+)"').Groups[1].Value
$supported  = [regex]::Match($descriptor, 'supported_version="([^"]+)"').Groups[1].Value
if (-not $name)    { throw 'name ausente no descriptor.mod' }
if (-not $version) { $version = '0.0.0' }

$modFile = Join-Path (Split-Path -Parent $OutPath) 'non-lag-ai-build.mod'
$modContent = @"
version="$version"
tags={
	"Balance"
	"Gameplay"
	"Fixes"
}
name="$name [build]"
supported_version="$supported"
path="$($OutPath -replace '\\','/')"
"@
# UTF-8 sem BOM (BOM quebra o parser do launcher)
[System.IO.File]::WriteAllText($modFile, $modContent, (New-Object System.Text.UTF8Encoding($false)))

Write-Host '=== Build do Workshop gerada ===' -ForegroundColor Green
Write-Host "Conteudo : $OutPath"
Write-Host "Launcher : $modFile"
Write-Host ''
Write-Host 'Proximos passos:'
Write-Host '  Upload automatico:  .\upload-workshop.ps1 -SteamUser SEU_LOGIN_STEAM'
Write-Host '  Upload manual:      HOI4 > Launcher > Mods > Upload a mod > "'$name' [build]"'
exit 0
