# Publicação no Steam Workshop

Runbook para publicar e atualizar o **Non Lag AI** no Workshop, com scripts para
**macOS/Linux** (`.sh`) e **Windows** (`.ps1`).

> **Item registrado:** [Workshop 3789983756](https://steamcommunity.com/sharedfiles/filedetails/?id=3789983756).
> O fluxo mantém visibilidade oculta por padrão até a decisão de publicação.

- **Comando único (macOS/Linux)**: `./upload-workshop.sh` — roda o export, gera o VDF e
  chama o steamcmd (o `export-workshop.sh` continua disponível para a [Rota B](#rota-b--paradox-launcher-gui))
- Espelho Windows: `upload-workshop.ps1` (+ `export-workshop.ps1`)
- Alternativa manual (Paradox Launcher): seção [Rota B](#rota-b--paradox-launcher-gui)

## Pré-requisitos (uma vez por máquina)

1. **Steam** instalada e logada na conta que será dona do mod.
   - A conta precisa ser *ilimitada* (ter gastado ≥ US$5 na Steam) — contas limitadas não publicam no Workshop.
   - HOI4 precisa estar na conta.
2. **steamcmd** instalado (só para a Rota A):
   - **macOS:** `brew install steamcmd` (o script também procura `~/steamcmd/steamcmd.sh`, `/opt/homebrew/bin/steamcmd` e `/usr/local/bin/steamcmd`, ou aceite `--steamcmd CAMINHO`)
   - **Windows:** baixe `https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip`, extraia para `C:\steamcmd\`
     e rode `C:\steamcmd\steamcmd.exe` uma vez (auto-atualização, saia com `quit`).
     O script também procura em `C:\Program Files\steamcmd\` e `%LOCALAPPDATA%\steamcmd\`, ou aceite `-SteamCmdPath`.
3. Clone do repositório:
   ```bash
   git clone https://github.com/gab3mioni/non-lag-ai.git
   cd non-lag-ai
   ```

## Rota A — steamcmd (recomendada)

### Primeira publicação (reserva do ID, item oculto)

Do diretório do clone:

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .\upload-workshop.ps1 -SteamUser SEU_LOGIN_STEAM -NewItem
```

```bash
# macOS/Linux: --new-item e obrigatorio apenas na primeira publicacao.
./upload-workshop.sh --new-item --visibility 2 SEU_LOGIN_STEAM
```

O que o script faz:

1. Roda `export-workshop.ps1` → cria a build limpa em
   `Documentos\Paradox Interactive\Hearts of Iron IV\mod\non-lag-ai-build`
   (sem `.git`, documentação, testes ou scripts; somente o mod, `descriptor.mod` e `Thumbnail.png`).
2. Gera `steam\build.vdf` (appid 394360, visibilidade **oculta**, preview = `Thumbnail.png`).
3. Roda o steamcmd — **você digita a senha e o código do Steam Guard quando pedido**.
4. Publica o item e tenta capturar o **PublishedFileId** (salvo em `steam\workshop.item`).

> Se o script não conseguir capturar o ID automaticamente, pegue na página do item
> (Steam → seu perfil → *Workshop items*) ou no log `C:\steamcmd\logs\workshop_log.txt`
> e grave com:
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\upload-workshop.ps1 -SetId O_ID_AQUI
> ```

### Configuração única da página do item

Abra `https://steamcommunity.com/sharedfiles/filedetails/?id=O_ID_AQUI` (logado como dono):

1. **Edit** → preencha a descrição e os créditos dos projetos upstream.
2. Confirme a **imagem de preview** (`Thumbnail.png`).
3. Ajuste **tags** (Balance / Gameplay / Fixes) e visibilidade.
4. Mantenha **oculto** até o lançamento; mude para **pública** no dia.

### Registrar o ID

O upload tenta atualizar `steam/workshop.item` automaticamente. Se isso não ocorrer,
registre o ID manualmente:

```bash
./upload-workshop.sh --set-id O_ID_AQUI
```

```powershell
powershell -ExecutionPolicy Bypass -File .\upload-workshop.ps1 -SetId O_ID_AQUI
```

`steam/workshop.item` guarda o ID dos próximos uploads e deve permanecer versionado.

## Rota B — Paradox Launcher (GUI)

1. Rode o export:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\export-workshop.ps1
   ```
2. Abra o HOI4 pela Steam → **Paradox Launcher → Mods → Upload a mod**.
3. Selecione **Non Lag AI [build]** (o `.mod` de registro é criado pelo export).
4. Marque visibilidade **oculta/hidden** se o diálogo perguntar, e faça o **Upload**.
5. Pegue o ID na URL da página do item criado e siga os mesmos passos de
   [configuração da página](#configuração-única-da-página-do-item).

## Atualizando o mod (novas versões)

1. Atualize `version="X.Y.Z"` no `descriptor.mod`.
2. Registre as mudanças da versão na documentação do projeto.
3. Publique a nova versão com um único comando (o `changenote` do VDF usa a
   versão do descriptor):
   - **macOS/Linux:** `./upload-workshop.sh`
     - Primeira vez nesta máquina: `./upload-workshop.sh --save-login SEU_LOGIN_STEAM`
       (grava o login em `steam/steamuser`, gitignored; sem login salvo o script pergunta).
     - O upload **sempre atualiza o ID registrado** em `steam/workshop.item` — se não
       houver ID o script aborta em vez de criar item duplicado.
   - **Windows:** `powershell -ExecutionPolicy Bypass -File .\upload-workshop.ps1 -SteamUser SEU_LOGIN_STEAM`
4. O item mantém o mesmo ID; assinantes recebem a atualização automaticamente.

## Solução de problemas

- **steamcmd pede Steam Guard toda vez**: normal nas primeiras execuções; após autorizar o
  dispositivo ele cacheia a sessão (`+login` sem senha passa a funcionar).
- **"Success" mas a página não aparece**: itens ocultos só são visíveis para o dono —
  cheque na aba *Workshop items* do seu perfil.
- **"Erro 16 / falha de login"**: rode `steamcmd` manualmente uma vez, faça login
  interativo e saia; depois rode o script.
- **"nenhum PublishedFileId registrado"**: guarda anti-duplicata do
  `upload-workshop.sh` — ele só atualiza o item de `steam/workshop.item`. Grave o
  ID com `./upload-workshop.sh --set-id O_ID_DO_ITEM` (ou use `--new-item` apenas
  para criar um item novo de propósito).
- **Upload muito grande**: confirme que o export excluiu `.git`, `docs`, `tests` e scripts.
- **Publicação pública**: confirme previamente a autorização e os créditos exigidos pelos
  autores do Sheep's Mod e BetterNavyAI. O fluxo usa visibilidade oculta por padrão.
- **Mod não aparece no jogo após assinar**: reinicie o HOI4; campanhas abertas não
  recarregam conteúdo novo.
