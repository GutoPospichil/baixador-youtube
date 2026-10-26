import os
import re
import sys
import glob
import json
import shutil
import subprocess
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

APP_TITLE = "Baixador de Vídeos do YouTube"
CONFIG_DIR = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "BaixadorYouTube")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")


def app_directory():
    """Pasta onde o app está (funciona também quando compilado com PyInstaller)."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))


def _first_existing(candidates):
    for path in candidates:
        if path and os.path.isfile(path):
            return path
    return None


def find_yt_dlp():
    """Localiza o yt-dlp no sistema (pasta do app, PATH, WinGet, pip)."""
    exe = "yt-dlp.exe" if os.name == "nt" else "yt-dlp"
    candidates = [os.path.join(app_directory(), exe), shutil.which("yt-dlp")]

    local = os.environ.get("LOCALAPPDATA", "")
    roaming = os.environ.get("APPDATA", "")

    if local:
        candidates.append(os.path.join(local, "Microsoft", "WinGet", "Links", "yt-dlp.exe"))
        candidates += sorted(glob.glob(os.path.join(
            local, "Microsoft", "WinGet", "Packages", "yt-dlp*", "yt-dlp.exe")))
        candidates += sorted(glob.glob(os.path.join(
            local, "Programs", "Python", "Python*", "Scripts", "yt-dlp.exe")))
    if roaming:
        candidates += sorted(glob.glob(os.path.join(
            roaming, "Python", "Python*", "Scripts", "yt-dlp.exe")))

    candidates += [
        os.path.expanduser("~/.local/bin/yt-dlp"),
        "/usr/local/bin/yt-dlp",
        "/usr/bin/yt-dlp",
    ]
    return _first_existing(candidates)


def find_ffmpeg():
    """Localiza o ffmpeg (necessário para juntar vídeo + áudio e converter MP3)."""
    exe = "ffmpeg.exe" if os.name == "nt" else "ffmpeg"
    candidates = [os.path.join(app_directory(), exe), shutil.which("ffmpeg")]

    local = os.environ.get("LOCALAPPDATA", "")
    if local:
        candidates.append(os.path.join(local, "Microsoft", "WinGet", "Links", "ffmpeg.exe"))
        candidates += sorted(glob.glob(os.path.join(
            local, "Microsoft", "WinGet", "Packages", "Gyan.FFmpeg*", "**", "bin", "ffmpeg.exe"),
            recursive=True))

    candidates += [r"C:\ffmpeg\bin\ffmpeg.exe", "/usr/bin/ffmpeg", "/usr/local/bin/ffmpeg"]
    return _first_existing(candidates)


class DownloaderApp:
    def __init__(self, root):
        self.root = root
        self.root.title(APP_TITLE)
        self.root.resizable(False, False)

        self.bg = "#f4f5f7"
        self.primary = "#2563eb"
        self.text = "#1f2937"
        self.muted = "#6b7280"

        self.root.configure(bg=self.bg)
        self.style = ttk.Style()
        try:
            self.style.theme_use("clam")
        except tk.TclError:
            pass

        self.process = None
        self.is_downloading = False
        self.cancelled = False

        self.quality_options = {
            "Melhor qualidade disponível (MP4)": ["-f", "bv*+ba/b", "--merge-output-format", "mp4"],
            "1080p Full HD (MP4)": ["-f", "bv*[height<=1080]+ba/b", "--merge-output-format", "mp4"],
            "720p HD (MP4)": ["-f", "bv*[height<=720]+ba/b", "--merge-output-format", "mp4"],
            "480p (MP4)": ["-f", "bv*[height<=480]+ba/b", "--merge-output-format", "mp4"],
            "Apenas áudio (MP3)": ["-x", "--audio-format", "mp3"],
        }

        self._build_ui()
        self._load_config()
        self._center_window()

    # ---------------------------------------------------------------- interface
    def _build_ui(self):
        main = tk.Frame(self.root, bg=self.bg, padx=22, pady=18)
        main.pack(fill="both", expand=True)

        tk.Label(main, text=APP_TITLE, font=("Segoe UI", 15, "bold"),
                 bg=self.bg, fg=self.text).pack(anchor="w", pady=(0, 14))

        # Link do vídeo
        tk.Label(main, text="Link do vídeo:", font=("Segoe UI", 9, "bold"),
                 bg=self.bg, fg=self.text).pack(anchor="w", pady=(0, 4))

        url_row = tk.Frame(main, bg=self.bg)
        url_row.pack(fill="x", pady=(0, 12))

        self.url_entry = ttk.Entry(url_row, font=("Segoe UI", 10))
        self.url_entry.pack(side="left", fill="x", expand=True, ipady=3)
        self.url_entry.bind("<Return>", lambda _event: self.start_download())

        tk.Button(url_row, text="Colar", font=("Segoe UI", 9), command=self.paste_url,
                  bg="#e5e7eb", activebackground="#d1d5db", relief="flat",
                  cursor="hand2", padx=12, pady=4).pack(side="right", padx=(8, 0))

        # Pasta de destino
        tk.Label(main, text="Salvar na pasta:", font=("Segoe UI", 9, "bold"),
                 bg=self.bg, fg=self.text).pack(anchor="w", pady=(0, 4))

        path_row = tk.Frame(main, bg=self.bg)
        path_row.pack(fill="x", pady=(0, 12))

        self.path_entry = ttk.Entry(path_row, font=("Segoe UI", 10))
        self.path_entry.pack(side="left", fill="x", expand=True, ipady=3)

        tk.Button(path_row, text="Procurar...", font=("Segoe UI", 9), command=self.browse_folder,
                  bg="#e5e7eb", activebackground="#d1d5db", relief="flat",
                  cursor="hand2", padx=12, pady=4).pack(side="right", padx=(8, 0))

        # Qualidade
        tk.Label(main, text="Qualidade / formato:", font=("Segoe UI", 9, "bold"),
                 bg=self.bg, fg=self.text).pack(anchor="w", pady=(0, 4))

        self.quality_combo = ttk.Combobox(main, values=list(self.quality_options.keys()),
                                          state="readonly", font=("Segoe UI", 10))
        self.quality_combo.current(0)
        self.quality_combo.pack(fill="x", ipady=2)

        # Barra de progresso
        self.progress_var = tk.DoubleVar(value=0.0)
        ttk.Progressbar(main, variable=self.progress_var, maximum=100).pack(fill="x", pady=(16, 6))

        self.status_label = tk.Label(main, text="Pronto para baixar", font=("Segoe UI", 9),
                                     bg=self.bg, fg=self.muted, anchor="w", justify="left")
        self.status_label.pack(fill="x", pady=(0, 14))

        # Botões
        buttons = tk.Frame(main, bg=self.bg)
        buttons.pack(fill="x")

        self.download_btn = tk.Button(buttons, text="BAIXAR VÍDEO", font=("Segoe UI", 11, "bold"),
                                      bg=self.primary, fg="white", activebackground="#1d4ed8",
                                      activeforeground="white", relief="flat", cursor="hand2",
                                      command=self.start_download, pady=8)
        self.download_btn.pack(side="left", fill="x", expand=True)

        self.cancel_btn = tk.Button(buttons, text="Cancelar", font=("Segoe UI", 10),
                                    bg="#e5e7eb", activebackground="#d1d5db", relief="flat",
                                    cursor="hand2", command=self.cancel_download,
                                    state="disabled", padx=14, pady=8)
        self.cancel_btn.pack(side="right", padx=(8, 0))

    def _center_window(self):
        self.root.update_idletasks()
        width = max(560, self.root.winfo_reqwidth())
        height = self.root.winfo_reqheight()
        x = (self.root.winfo_screenwidth() - width) // 2
        y = (self.root.winfo_screenheight() - height) // 2

        # deixa espaço para a barra de tarefas
        y = max(0, y - 20)
        self.root.geometry(f"{width}x{height}+{x}+{y}")

    # ---------------------------------------------------------------- configuração
    def _default_folder(self):
        if os.path.exists("D:\\"):
            return "D:\\Videos Volei"
        return os.path.join(os.path.expanduser("~"), "Downloads")

    def _load_config(self):
        folder = self._default_folder()
        quality = 0
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as fh:
                config = json.load(fh)
            folder = config.get("save_path") or folder
            quality_label = config.get("quality")
            if quality_label in self.quality_options:
                quality = list(self.quality_options).index(quality_label)
        except (OSError, ValueError):
            pass

        self.path_entry.insert(0, folder)
        self.quality_combo.current(quality)

    def _save_config(self):
        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            with open(CONFIG_FILE, "w", encoding="utf-8") as fh:
                json.dump({"save_path": self.path_entry.get().strip(),
                           "quality": self.quality_combo.get()}, fh, ensure_ascii=False, indent=2)
        except OSError:
            pass

    # ---------------------------------------------------------------- ações
    def paste_url(self):
        try:
            text = self.root.clipboard_get().strip()
        except tk.TclError:
            return
        if text:
            self.url_entry.delete(0, tk.END)
            self.url_entry.insert(0, text)

    def browse_folder(self):
        folder = filedialog.askdirectory(title="Escolha a pasta para salvar os vídeos")
        if folder:
            self.path_entry.delete(0, tk.END)
            self.path_entry.insert(0, os.path.normpath(folder))

    def _set_status(self, text, progress=None):
        self.status_label.config(text=text)
        if progress is not None:
            self.progress_var.set(max(0.0, min(100.0, progress)))

    def start_download(self):
        if self.is_downloading:
            return

        url = self.url_entry.get().strip()
        folder = self.path_entry.get().strip()

        if not url:
            messagebox.showwarning("Aviso", "Cole o link do vídeo do YouTube.")
            return

        if not folder:
            messagebox.showwarning("Aviso", "Escolha a pasta onde o vídeo será salvo.")
            return

        if not os.path.isdir(folder):
            try:
                os.makedirs(folder, exist_ok=True)
            except OSError as exc:
                messagebox.showerror("Erro", f"Não foi possível criar a pasta de destino:\n{exc}")
                return

        if find_yt_dlp() is None:
            messagebox.showerror(
                "yt-dlp não encontrado",
                "O yt-dlp não foi encontrado no computador.\n\n"
                "Instale com um dos comandos abaixo (Prompt de Comando):\n\n"
                "  winget install yt-dlp.yt-dlp\n\n"
                "Ou baixe o arquivo yt-dlp.exe em:\n"
                "https://github.com/yt-dlp/yt-dlp/releases/latest\n"
                "e coloque na mesma pasta deste programa."
            )
            return

        self._save_config()
        self.is_downloading = True
        self.cancelled = False
        self.download_btn.config(state="disabled", bg="#93c5fd", text="BAIXANDO...")
        self.cancel_btn.config(state="normal")
        self._set_status("Preparando download...", 0)

        threading.Thread(target=self._run_download, args=(url, folder), daemon=True).start()

    def cancel_download(self):
        if self.process and self.process.poll() is None:
            self.cancelled = True
            self._set_status("Cancelando...")
            try:
                self.process.terminate()
            except OSError:
                pass

    # ---------------------------------------------------------------- download
    def _run_download(self, url, folder):
        yt_dlp = find_yt_dlp()
        ffmpeg = find_ffmpeg()

        args = list(self.quality_options.get(self.quality_combo.get(),
                                             self.quality_options["Melhor qualidade disponível (MP4)"]))
        output_template = os.path.join(folder, "%(title)s.%(ext)s")

        cmd = [
            yt_dlp,
            "--newline",
            "--no-mtime",
            "--no-playlist",
            "--continue",
            "--windows-filenames",
            *args,
            "-o", output_template,
        ]
        if ffmpeg:
            cmd += ["--ffmpeg-location", ffmpeg]
        cmd.append(url)

        startupinfo = None
        if os.name == "nt":
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = subprocess.SW_HIDE

        progress_re = re.compile(
            r"\[download\]\s+(\d+(?:\.\d+)?)%\s+of\s+~?\s*([^\s]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)")
        done_re = re.compile(r"\[download\]\s+100%")
        stage_re = re.compile(r"\[download\] Destination:.*?\.(?:f\d+\.)?(\w+)$")
        audio_stage_re = re.compile(r"\[ExtractAudio\]")

        stage = "Baixando"
        last = 0.0

        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
                startupinfo=startupinfo,
            )

            for line in self.process.stdout:
                line = line.strip()

                if line.startswith("[download] Destination:"):
                    stage = "Baixando"
                    continue

                match = progress_re.search(line)
                if match:
                    pct = float(match.group(1))
                    size, speed, eta = match.group(2), match.group(3), match.group(4)
                    last = pct if pct >= 1.0 else last
                    self.root.after(0, self._set_status,
                                    f"{stage}: {pct:.1f}% de {size} — {speed} — faltam {eta}", pct)
                    continue

                if done_re.search(line):
                    self.root.after(0, self._set_status, f"{stage}: 100% concluído", 100)
                    continue

                if "[Merger]" in line or "[VideoConvertor]" in line:
                    self.root.after(0, self._set_status, "Juntando vídeo e áudio...", 99)
                    continue

                if audio_stage_re.search(line):
                    self.root.after(0, self._set_status, "Convertendo para MP3...", 99)
                    continue

                if line.startswith("ERROR:"):
                    self._error_message = line[6:].strip()

            returncode = self.process.wait()

            if self.cancelled:
                self.root.after(0, self._set_status, "Download cancelado.", 0)
            elif returncode == 0:
                self.root.after(0, self._set_status, "Download concluído com sucesso!", 100)
                self.root.after(0, lambda: self.url_entry.delete(0, tk.END))
                self.root.after(0, lambda: messagebox.showinfo(
                    "Concluído", f"Vídeo salvo em:\n{folder}"))
            else:
                detail = getattr(self, "_error_message", "")
                self.root.after(0, self._set_status, "Falha no download.", 0)
                self.root.after(0, lambda: messagebox.showerror(
                    "Erro", "Não foi possível baixar o vídeo.\n\n"
                            "Verifique o link e sua conexão."
                            + (f"\n\nDetalhe: {detail}" if detail else "")))

        except Exception as exc:  # noqa: BLE001
            self.root.after(0, self._set_status, f"Erro: {exc}", 0)
            self.root.after(0, lambda: messagebox.showerror(
                "Erro inesperado", f"Ocorreu um erro:\n{exc}"))
        finally:
            self.root.after(0, self._reset_ui)

    def _reset_ui(self):
        self.is_downloading = False
        self.process = None
        self.download_btn.config(state="normal", bg=self.primary, text="BAIXAR VÍDEO")
        self.cancel_btn.config(state="disabled")


if __name__ == "__main__":
    root = tk.Tk()
    DownloaderApp(root)
    root.mainloop()
