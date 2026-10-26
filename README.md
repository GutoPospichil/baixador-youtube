# Baixador de Vídeos do YouTube

Interface gráfica simples e leve (Python + Tkinter) para baixar vídeos do YouTube
usando o [yt-dlp](https://github.com/yt-dlp/yt-dlp). Roda em uma janela própria,
sem console, e mostra barra de progresso, velocidade e tempo restante.

> Uso destinado a conteúdo próprio, livre ou de domínio público.
> Respeite os Termos de Serviço do YouTube e os direitos autorais.

## Baixar pronto para usar

Se você só quer usar o programa (sem instalar Python), baixe o executável em
[**Releases**](https://github.com/GutoPospichil/baixador-youtube/releases/latest).

O executável ainda precisa do `yt-dlp` e do `ffmpeg` instalados — use o
`instalar-dependencias.bat` ou veja [Requisitos](#requisitos).

## Funcionalidades

- Baixa vídeos do YouTube colando o link
- Escolha da pasta de destino (com seletor de pastas)
- Qualidade: melhor disponível, 1080p, 720p, 480p ou somente áudio (MP3)
- Barra de progresso com porcentagem, velocidade e ETA
- Botão de cancelar
- Execução silenciosa (nenhuma janela de console)
- Lembra a última pasta e qualidade usadas
- Atalho de teclado: `Enter` no campo do link inicia o download

## Requisitos

| Item | Versão | Observação |
|------|--------|------------|
| Windows | 10/11 | Tkinter já vem com o Python oficial |
| Python | 3.9+ | Marque **Add Python to PATH** na instalação |
| yt-dlp | atual | Motor de download |
| ffmpeg | atual | Necessário para juntar vídeo+áudio e gerar MP3 |

### Instalar dependências

Opção 1 — automática (recomendada):

1. Instale o Python: <https://www.python.org/downloads/>
2. Dê dois cliques em **`instalar-dependencias.bat`**

Opção 2 — manual (Prompt de Comando / PowerShell):

```powershell
winget install yt-dlp.yt-dlp -e
winget install Gyan.FFmpeg -e
```

Opção 3 — sem winget:

1. Baixe `yt-dlp.exe` em <https://github.com/yt-dlp/yt-dlp/releases/latest>
2. Baixe o ffmpeg em <https://www.gyan.dev/ffmpeg/builds/> (build *release essentials*)
3. Coloque `yt-dlp.exe` e `ffmpeg.exe` na **mesma pasta** deste projeto

O programa procura as ferramentas na pasta do projeto, no `PATH`, no WinGet e na
pasta `Scripts` do Python — então qualquer uma das opções acima funciona.

## Como usar

1. Abra o programa:
   - executável: `BaixadorYouTube.exe`, ou
   - código-fonte: dois cliques em **`run.vbs`** (abre sem console)
2. Cole o link do vídeo (botão **Colar**)
3. Escolha a pasta de destino e a qualidade
4. Clique em **BAIXAR VÍDEO**

O arquivo final fica na pasta escolhida, com o título do vídeo como nome.

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
run.vbs                   Abre o app sem console
instalar-dependencias.bat Instala yt-dlp e ffmpeg via winget
build-exe.bat             Gera o executável com PyInstaller
requirements.txt          Dependência opcional (yt-dlp via pip)
```

## Solução de problemas

**"yt-dlp não encontrado"**
Instale com `winget install yt-dlp.yt-dlp -e` ou coloque `yt-dlp.exe` na pasta do app.

**Erro de SSL ao instalar pelo pip (`CERTIFICATE_VERIFY_FAILED`)**
Costuma ser proxy/antivírus interceptando HTTPS. Use o winget ou baixe o
`yt-dlp.exe` direto do GitHub (opções 2 e 3 acima).

**Áudio/vídeo não junta, ou MP3 falha**
Falta o ffmpeg. Instale com `winget install Gyan.FFmpeg -e`.

**Vídeo baixa em resolução menor que o esperado**
Alguns vídeos só oferecem alta resolução com áudio separado; o app já baixa e
mescla automaticamente quando o ffmpeg está disponível.

**Antivírus/SmartScreen bloqueia o .exe**
Acontece com executáveis gerados por PyInstaller sem assinatura digital.
Use o `run.vbs` com Python instalado ou adicione uma exceção.

## Licença

MIT — veja [LICENSE](LICENSE).
