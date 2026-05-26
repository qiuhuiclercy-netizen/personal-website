#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ClickWord - 系统级 AI 划词解释工具
双击任意位置的单词，弹出 AI 解释
"""

import sys
import os
import json
import threading
import time
import webbrowser
import urllib.parse
import traceback
import tkinter as tk
from tkinter import font as tkfont, messagebox

# ─── 依赖检查 ────────────────────────────────────────────────────────────────

_missing = []

try:
    import win32clipboard
    import win32con
except ImportError:
    _missing.append("pywin32")

try:
    import pynput.mouse as _mouse_mod
    import pynput.keyboard as _keyboard_mod
except ImportError:
    _missing.append("pynput")

try:
    from openai import OpenAI as _OpenAI
except ImportError:
    _missing.append("openai")

try:
    import pystray as _pystray
    from PIL import Image as _Image, ImageDraw as _ImageDraw, ImageFont as _ImageFont
except ImportError:
    _missing.append("pystray pillow")

if _missing:
    _r = tk.Tk(); _r.withdraw()
    messagebox.showerror(
        "ClickWord - 缺少依赖",
        f"请先运行 install.bat 安装以下依赖：\n\n"
        f"pip install {' '.join(_missing)}"
    )
    sys.exit(1)

# 依赖全部通过后绑定名称
mouse_mod = _mouse_mod
keyboard_mod = _keyboard_mod
OpenAI = _OpenAI
pystray = _pystray
Image = _Image
ImageDraw = _ImageDraw
ImageFont = _ImageFont

# ─── 配置 ─────────────────────────────────────────────────────────────────────

APP_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(APP_DIR, "config.json")

_DEFAULT_CONFIG = {
    "api_key": "",
    "api_base": "https://api.deepseek.com",
    "model": "deepseek-chat",
    "double_click_interval": 0.35,
    "cooldown": 0.8,
    "max_word_length": 300,
}

THEME = {
    "bg":           "#1e1e2e",
    "text":         "#cdd6f4",
    "subtext":      "#a6adc8",
    "accent":       "#89b4fa",
    "secondary_bg": "#313244",
    "link":         "#89dceb",
    "close":        "#f38ba8",
    "border":       "#45475a",
}

FONT = "Microsoft YaHei UI"


def load_config():
    cfg = _DEFAULT_CONFIG.copy()
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                cfg.update(json.load(f))
        except Exception:
            pass
    return cfg


def save_config(cfg):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)


# ─── 初次设置对话框 ────────────────────────────────────────────────────────────

def show_setup_dialog():
    t = THEME
    result = {"api_key": None}

    dlg = tk.Tk()
    dlg.title("ClickWord - 初次设置")
    dlg.geometry("500x280")
    dlg.configure(bg=t["bg"])
    dlg.resizable(False, False)
    dlg.eval("tk::PlaceWindow . center")

    tk.Label(dlg, text="欢迎使用 ClickWord",
             font=tkfont.Font(family=FONT, size=15, weight="bold"),
             fg=t["accent"], bg=t["bg"]).pack(pady=(28, 4))

    tk.Label(dlg, text="请输入你的 DeepSeek API Key 以启用 AI 解释",
             font=tkfont.Font(family=FONT, size=10),
             fg=t["subtext"], bg=t["bg"]).pack(pady=(0, 18))

    ef = tk.Frame(dlg, bg=t["bg"])
    ef.pack(fill=tk.X, padx=50)
    entry = tk.Entry(ef,
                     font=tkfont.Font(family=FONT, size=11),
                     bg=t["secondary_bg"], fg=t["text"],
                     insertbackground=t["accent"],
                     relief="flat", show="*")
    entry.pack(fill=tk.X, ipady=8, padx=1)

    tk.Label(dlg, text="获取 Key：platform.deepseek.com/api_keys",
             font=tkfont.Font(family=FONT, size=9),
             fg=t["subtext"], bg=t["bg"]).pack(pady=(8, 20))

    bf = tk.Frame(dlg, bg=t["bg"])
    bf.pack()

    def confirm():
        key = entry.get().strip()
        if not key:
            messagebox.showwarning("提示", "请输入 API Key", parent=dlg)
            return
        result["api_key"] = key
        dlg.destroy()

    tk.Button(bf, text="开始使用",
              font=tkfont.Font(family=FONT, size=11),
              bg=t["accent"], fg=t["bg"],
              relief="flat", padx=22, pady=6, cursor="hand2",
              command=confirm).pack(side=tk.LEFT, padx=8)

    tk.Button(bf, text="取消",
              font=tkfont.Font(family=FONT, size=11),
              bg=t["secondary_bg"], fg=t["text"],
              relief="flat", padx=22, pady=6, cursor="hand2",
              command=dlg.destroy).pack(side=tk.LEFT)

    entry.focus_set()
    dlg.bind("<Return>", lambda e: confirm())
    dlg.protocol("WM_DELETE_WINDOW", dlg.destroy)
    dlg.mainloop()
    return result


# ─── 剪贴板工具 ───────────────────────────────────────────────────────────────

class Clipboard:
    @staticmethod
    def get() -> str:
        try:
            win32clipboard.OpenClipboard()
            try:
                return win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT) or ""
            except Exception:
                return ""
            finally:
                win32clipboard.CloseClipboard()
        except Exception:
            return ""

    @staticmethod
    def set(text: str):
        try:
            win32clipboard.OpenClipboard()
            win32clipboard.EmptyClipboard()
            if text:
                win32clipboard.SetClipboardData(win32con.CF_UNICODETEXT, text)
            win32clipboard.CloseClipboard()
        except Exception:
            try:
                win32clipboard.CloseClipboard()
            except Exception:
                pass


# ─── 主应用 ────────────────────────────────────────────────────────────────────

class ClickWordApp:
    def __init__(self, config: dict):
        self.config = config
        self.client = OpenAI(api_key=config["api_key"], base_url=config["api_base"])

        # 状态
        self.last_click_time: float = 0
        self.last_lookup_time: float = 0
        self.is_looking_up: bool = False
        self.popup: tk.Toplevel | None = None
        self.explanation_var: tk.StringVar | None = None
        self.popup_bounds: tuple | None = None  # (x, y, w, h)

        # tkinter 主窗口（隐藏）
        self.root = tk.Tk()
        self.root.withdraw()
        self.root.title("ClickWord")

        self._setup_listener()
        self._setup_tray()

    # ── 鼠标监听 ──────────────────────────────────────────────────────────────

    def _setup_listener(self):
        self.mouse_listener = mouse_mod.Listener(on_click=self._on_click)
        self.mouse_listener.daemon = True
        self.mouse_listener.start()

    def _on_click(self, x, y, button, pressed):
        if button != mouse_mod.Button.left or not pressed:
            return

        # 如果弹窗已打开：点击弹窗外则关闭
        if self.popup:
            if self.popup_bounds:
                px, py, pw, ph = self.popup_bounds
                if not (px <= x <= px + pw and py <= y <= py + ph):
                    self.root.after(0, self._close_popup)
                    self.last_click_time = 0
            return

        now = time.time()
        if now - self.last_click_time < self.config["double_click_interval"]:
            self.last_click_time = 0
            if not self.is_looking_up and (now - self.last_lookup_time) > self.config["cooldown"]:
                self.last_lookup_time = now
                threading.Thread(target=self._handle_double_click, args=(x, y), daemon=True).start()
        else:
            self.last_click_time = now

    def _handle_double_click(self, x: int, y: int):
        # 等待系统完成划词
        time.sleep(0.12)

        old_clip = Clipboard.get()

        # 模拟 Ctrl+C
        kb = keyboard_mod.Controller()
        with kb.pressed(keyboard_mod.Key.ctrl):
            kb.press("c")
            kb.release("c")
        time.sleep(0.1)

        word = Clipboard.get()

        # 恢复剪贴板
        if old_clip and old_clip != word:
            time.sleep(0.05)
            Clipboard.set(old_clip)

        word = (word or "").strip()
        if not word or word == old_clip or len(word) > self.config["max_word_length"]:
            return

        self.is_looking_up = True
        self.root.after(0, lambda: self._show_popup(word, x, y))

    # ── 弹窗 UI ───────────────────────────────────────────────────────────────

    def _show_popup(self, word: str, x: int, y: int):
        self._close_popup()
        t = THEME

        popup = tk.Toplevel(self.root)
        popup.overrideredirect(True)
        popup.attributes("-topmost", True)
        popup.attributes("-alpha", 0.97)
        popup.configure(bg=t["border"])  # 边框色
        self.popup = popup

        # 内容区（1px 边框效果）
        inner = tk.Frame(popup, bg=t["bg"])
        inner.pack(fill=tk.BOTH, expand=True, padx=1, pady=1)

        frame = tk.Frame(inner, bg=t["bg"], padx=16, pady=14)
        frame.pack(fill=tk.BOTH, expand=True)

        f_title = tkfont.Font(family=FONT, size=12, weight="bold")
        f_body  = tkfont.Font(family=FONT, size=10)
        f_small = tkfont.Font(family=FONT, size=9)

        # 标题行
        header = tk.Frame(frame, bg=t["bg"])
        header.pack(fill=tk.X, pady=(0, 6))

        display = word[:55] + "…" if len(word) > 55 else word
        tk.Label(header, text=display, font=f_title,
                 fg=t["accent"], bg=t["bg"], anchor="w"
                 ).pack(side=tk.LEFT, fill=tk.X, expand=True)

        close_btn = tk.Label(header, text="×",
                             font=tkfont.Font(family="Arial", size=13, weight="bold"),
                             fg=t["close"], bg=t["bg"], cursor="hand2", padx=3)
        close_btn.pack(side=tk.RIGHT)
        close_btn.bind("<Button-1>", lambda e: self._close_popup())

        # 分割线
        tk.Frame(frame, height=1, bg=t["border"]).pack(fill=tk.X, pady=(0, 10))

        # 解释文字
        self.explanation_var = tk.StringVar(value="AI 正在思考…")
        expl_label = tk.Label(frame, textvariable=self.explanation_var,
                              font=f_body, fg=t["text"], bg=t["bg"],
                              wraplength=420, justify=tk.LEFT, anchor="w")
        expl_label.pack(fill=tk.X, pady=(0, 12))

        # 操作按钮行
        actions = tk.Frame(frame, bg=t["bg"])
        actions.pack(fill=tk.X)

        def make_btn(parent, label, fg, cmd):
            b = tk.Label(parent, text=label, font=f_small,
                         fg=fg, bg=t["secondary_bg"],
                         padx=9, pady=3, cursor="hand2")
            b.pack(side=tk.LEFT, padx=(0, 5))
            b.bind("<Button-1>", lambda e: cmd())
            b.bind("<Enter>", lambda e, _b=b: _b.configure(fg="white"))
            b.bind("<Leave>", lambda e, _b=b, _fg=fg: _b.configure(fg=_fg))

        make_btn(actions, "复制", t["subtext"], self._copy_explanation)

        q = urllib.parse.quote(word)
        for label_text, url in [
            ("百度",   f"https://www.baidu.com/s?wd={q}"),
            ("维基",   f"https://zh.wikipedia.org/w/index.php?search={q}"),
            ("Google", f"https://www.google.com/search?q={q}"),
        ]:
            make_btn(actions, label_text, t["link"], lambda u=url: webbrowser.open(u))

        # 定位弹窗（避免超出屏幕）
        popup.update_idletasks()
        w = max(popup.winfo_reqwidth(), 460)
        h = popup.winfo_reqheight()
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()

        px = max(10, min(x + 14, sw - w - 14))
        py = y + 28
        if py + h > sh - 60:
            py = max(10, y - h - 10)

        popup.geometry(f"{w}x{h}+{px}+{py}")
        self.popup_bounds = (px, py, w, h)
        popup.bind("<Escape>", lambda e: self._close_popup())

        # 后台调用 AI
        threading.Thread(target=self._fetch_explanation, args=(word,), daemon=True).start()

    def _copy_explanation(self):
        if self.explanation_var:
            text = self.explanation_var.get()
            if text and "正在思考" not in text:
                Clipboard.set(text)

    def _fetch_explanation(self, word: str):
        try:
            prompt = (
                f'请对以下内容给出简洁解释（2-3句话，不超过100字）：\n\n"{word}"\n\n'
                "要求：直接解释，不重复词语本身；"
                "英文单词→给中文释义和例句；"
                "中文词→详细说明或背景；"
                "专业术语→用通俗语言解释；"
                "人名地名→简短介绍；"
                "整段文字→提炼核心要点。"
            )
            resp = self.client.chat.completions.create(
                model=self.config["model"],
                messages=[{"role": "user", "content": prompt}],
                max_tokens=200,
                temperature=0.3,
            )
            text = resp.choices[0].message.content.strip()
        except Exception as e:
            text = f"⚠ 查询失败：{str(e)[:100]}"

        self.root.after(0, lambda: self._update_explanation(text))
        self.is_looking_up = False

    def _update_explanation(self, text: str):
        if self.explanation_var and self.popup:
            try:
                self.explanation_var.set(text)
                self.popup.update_idletasks()
            except Exception:
                pass

    def _close_popup(self):
        self.is_looking_up = False
        if self.popup:
            try:
                self.popup.destroy()
            except Exception:
                pass
        self.popup = None
        self.popup_bounds = None
        self.explanation_var = None

    # ── 系统托盘 ──────────────────────────────────────────────────────────────

    def _create_icon_image(self):
        img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.ellipse([2, 2, 62, 62], fill=(137, 180, 250, 240))
        try:
            fnt = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 36)
            bbox = d.textbbox((0, 0), "W", font=fnt)
            fw, fh = bbox[2] - bbox[0], bbox[3] - bbox[1]
            d.text(((64 - fw) // 2, (64 - fh) // 2 - 2), "W",
                   fill=(30, 30, 46), font=fnt)
        except Exception:
            d.rectangle([20, 22, 44, 42], fill=(30, 30, 46))
        return img

    def _setup_tray(self):
        img = self._create_icon_image()
        menu = pystray.Menu(
            pystray.MenuItem("ClickWord  运行中", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("退出", self._quit),
        )
        self.tray = pystray.Icon("ClickWord", img, "ClickWord - 双击查词", menu)

    def _quit(self, *_):
        self.mouse_listener.stop()
        self.tray.stop()
        self.root.quit()

    # ── 启动 ──────────────────────────────────────────────────────────────────

    def run(self):
        threading.Thread(target=self.tray.run, daemon=True).start()
        self.root.mainloop()


# ─── 入口 ─────────────────────────────────────────────────────────────────────

def main():
    config = load_config()

    if not config.get("api_key"):
        result = show_setup_dialog()
        if not result.get("api_key"):
            sys.exit(0)
        config["api_key"] = result["api_key"]
        save_config(config)

    try:
        app = ClickWordApp(config)
        app.run()
    except Exception as e:
        r = tk.Tk(); r.withdraw()
        messagebox.showerror("ClickWord 错误",
                             f"启动失败：\n{e}\n\n{traceback.format_exc()[:600]}")
        sys.exit(1)


if __name__ == "__main__":
    main()
