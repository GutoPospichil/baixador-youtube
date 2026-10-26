# Baixador de Vídeos do YouTube

Interface gráfica simples e leve (Python + Tkinter) para baixar vídeos do YouTube
usando o [yt-dlp](https://github.com/yt-dlp/yt-dlp). Roda em uma janela própria,
sem console, e mostra barra de progresso, velocidade e tempo restante.

> Uso destinado a conteúdo próprio, livre ou de domínio público.
> Respeite os Termos de Serviço do YouTube e os direitos autorais.

## Funcionalidades

- Baixa vídeos do YouTube colando o link
- Escolha da pasta de destino (com seletor de pastas)
- Qualidade: melhor disponível, 1080p, 720p, 480p ou somente áudio (MP3)
- Barra de progresso com porcentagem, velocidade e ETA
- Botão de cancelar
- Execução silenciosa (nenhuma janela de console)
- Lembra a última pasta e qualidade usadas
- Atalho de teclado: `Enter` no campo do link inicia o download

## Instalação

### Opção 1 — Instalador (recomendado)

1. Baixe o arquivo **`BaixadorYouTube-Setup.zip`** em
   [**Releases**](https://github.com/GutoPospichil/baixador-youtube/releases/latest)
2. Extraia o zip em qualquer pasta
3. Execute **`Instalar.bat`**

O instalador faz tudo automaticamente:

- instala o programa em `%LOCALAPPDATA%\Programas\BaixadorYouTube`
- instala o **yt-dlp** e o **ffmpeg** (via winget; se o winget não existir,
  baixa os arquivos direto do site oficial)
- cria atalhos na Área de Trabalho e no Menu Iniciar
- registra a desinstalação em **Configurações → Aplicativos**

Não precisa de Python nem de permissão de administrador.

### Opção 2 — Executável direto

1. Baixe **`BaixadorYouTube.exe`** em
   [**Releases**](https://github.com/GutoPospichil/baixador-youtube/releases/latest)
2. Instale as dependências com o `instalar-dependencias.bat` (ou veja
   [Requisitos](#requisitos))
3. Abra o `.exe`

### Opção 3 — Código-fonte

Requer Python instalado. Depois de instalar as dependências
(veja [Requisitos](#requisitos)), dê dois cliques em **`run.vbs`** —
o programa abre sem janela de console.

Também é possível rodar manualmente:

```powershell
pythonw app.py
```

## Requisitos

| Item | Versão | Observação |
|------|--------|------------|
| Windows | 10/11 | Tkinter já vem com o Python oficial |
| Python | 3.9+ | Só para a opção 3 (código-fonte) |
| yt-dlp | atual | Motor de download |
| ffmpeg | atual | Necessário para juntar vídeo+áudio e gerar MP3 |

### Instalar dependências manualmente

Automático (recomendado):

```powershell
winget install yt-dlp.yt-dlp -e
winget install Gyan.FFmpeg -e
```

Ou rode o **`instalar-dependencias.bat`**.

Sem winget:

1. Baixe `yt-dlp.exe` em <https://github.com/yt-dlp/yt-dlp/releases/latest>
2. Baixe o ffmpeg em <https://www.gyan.dev/ffmpeg/builds/> (build *release essentials*)
3. Coloque `yt-dlp.exe` e `ffmpeg.exe` na **mesma pasta** do programa

O aplicativo procura as ferramentas na pasta do programa, no `PATH`, no WinGet e
na pasta `Scripts` do Python — então qualquer uma das opções acima funciona.

## Como usar

1. Abra o programa (atalho na Área de Trabalho, Menu Iniciar ou o `.exe`)
2. Cole o link do vídeo (botão **Colar**)
3. Escolha a pasta de destino e a qualidade
4. Clique em **BAIXAR VÍDEO**

O arquivo final fica na pasta escolhida, com o título do vídeo como nome.

## Desinstalar

**Configurações → Aplicativos → Aplicativos instalados →
Baixador de Vídeos do YouTube → Desinstalar.**

Ou execute o `Desinstalar.bat` na pasta de instalação
(`%LOCALAPPDATA%\Programas\BaixadorYouTube`).

O yt-dlp e o ffmpeg **não** são removidos, pois podem ser usados por outros
programas.

## Gerar um executável (.exe)

Se quiser distribuir sem exigir Python instalado:

```bat
build-exe.bat
```

O executável será criado em `dist\BaixadorYouTube.exe`.
O `yt-dlp` e o `ffmpeg` continuam sendo necessários — coloque os dois `.exe`
na mesma pasta do executável ou instale pelo `instalar-dependencias.bat`.

## Estrutura do projeto

```
app.py                    Interface e lógica de download
Instalar.bat              Inicia o instalador (duplo clique)
Instalar.ps1              Instalador: copia o app, instala dependências,
                          cria atalhos e registra a desinstalação
Desinstalar.bat           Inicia o desinstalador
Desinstalar.ps1           Remove atalhos, registro e arquivos
run.vbs                   Executa sem instalar (modo código-fonte)
instalar-dependencias.bat Instala yt-dlp e ffmpeg via winget (manual)
build-exe.bat             Gera o executável com PyInstaller
requirements.txt          Dependência opcional (yt-dlp via pip)
```

## Solução de problemas

**"yt-dlp não encontrado"**
Instale com `winget install yt-dlp.yt-dlp -e` ou coloque `yt-dlp.exe` na pasta do app.

**Erro de SSL ao instalar pelo pip (`CERTIFICATE_VERIFY_FAILED`)**
Costuma ser proxy/antivírus interceptando HTTPS. Use o instalador, o winget ou
baixe o `yt-dlp.exe` direto do GitHub.

**Áudio/vídeo não junta, ou MP3 falha**
Falta o ffmpeg. Instale com `winget install Gyan.FFmpeg -e`.

**Vídeo baixa em resolução menor que o esperado**
Alguns vídeos só oferecem alta resolução com áudio separado; o app já baixa e
mescla automaticamente quando o ffmpeg está disponível.

**Antivírus/SmartScreen bloqueia o instalador ou o .exe**
Acontece com executáveis gerados por PyInstaller sem assinatura digital.
Use a opção 3 (`run.vbs` com Python instalado) ou adicione uma exceção.

## Licença

MIT — veja [LICENSE](LICENSE).
