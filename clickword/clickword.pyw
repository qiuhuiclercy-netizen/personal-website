#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ClickWord - 系统级 AI 划词解释工具"""

import sys, os, json, threading, time, webbrowser, urllib.parse, traceback
import ctypes
import tkinter as tk
from tkinter import font as tkfont, messagebox

# ─── 依赖检查 ────────────────────────────────────────────────────────────────
_missing = []
try:
    import win32clipboard, win32con, win32gui
except ImportError:
    _missing.append("pywin32")
try:
    import pynput.mouse as _mm, pynput.keyboard as _km
except ImportError:
    _missing.append("pynput")
try:
    from openai import OpenAI as _OAI
except ImportError:
    _missing.append("openai")
try:
    import pystray as _ps
    from PIL import Image as _Img, ImageDraw as _IDraw, ImageFont as _IFont
except ImportError:
    _missing.append("pystray pillow")

if _missing:
    r = tk.Tk(); r.withdraw()
    messagebox.showerror("ClickWord 缺少依赖",
        f"请先运行 install.bat：\npip install {' '.join(_missing)}")
    sys.exit(1)

mouse_mod, keyboard_mod, OpenAI = _mm, _km, _OAI
pystray, Image, ImageDraw, ImageFont = _ps, _Img, _IDraw, _IFont

# ─── 配置 ─────────────────────────────────────────────────────────────────────
APP_DIR     = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(APP_DIR, "config.json")
_DEFAULT = {
    "api_key": "", "api_base": "https://api.deepseek.com",
    "model": "deepseek-chat",
    "double_click_interval": 0.35, "cooldown": 0.8, "max_word_length": 300,
}

def load_config():
    cfg = _DEFAULT.copy()
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f: cfg.update(json.load(f))
        except: pass
    return cfg

def save_config(cfg):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)

# ─── 颜色 & 字体 ───────────────────────────────────────────────────────────────
OUTER   = "#cdd5e0"   # 外框色（产生阴影感）
CARD    = "#ffffff"   # 卡片白
TITLE_C = "#1e293b"   # 标题深色
BODY_C  = "#475569"   # 正文中灰
SUB_C   = "#94a3b8"   # 次要/关闭按钮
ACCENT  = "#6366f1"   # 紫蓝强调
SEP_C   = "#f1f5f9"   # 分割线
LINK_BG = "#eff6ff"
LINK_FG = "#3b82f6"
COPY_BG = "#f8fafc"
FONT    = "Microsoft YaHei UI"

def _round_window(hwnd, w, h, r=20):
    """用 Win32 API 给窗口裁剪圆角"""
    try:
        rgn = win32gui.CreateRoundRectRgn(0, 0, w + 1, h + 1, r * 2, r * 2)
        win32gui.SetWindowRgn(hwnd, rgn, True)
    except Exception:
        pass

# ─── 初次设置 ─────────────────────────────────────────────────────────────────
def show_setup_dialog():
    result = {"api_key": None}
    dlg = tk.Tk()
    dlg.title("ClickWord - 初次设置")
    dlg.geometry("480x290")
    dlg.configure(bg="#f8fafc")
    dlg.resizable(False, False)
    dlg.eval("tk::PlaceWindow . center")

    tk.Label(dlg, text="欢迎使用 ClickWord",
             font=tkfont.Font(family=FONT, size=16, weight="bold"),
             fg=ACCENT, bg="#f8fafc").pack(pady=(32, 4))
    tk.Label(dlg, text="请输入你的 DeepSeek API Key 以启用 AI 解释",
             font=tkfont.Font(family=FONT, size=10), fg=SUB_C, bg="#f8fafc").pack(pady=(0, 18))

    ef = tk.Frame(dlg, bg="#f8fafc"); ef.pack(fill=tk.X, padx=50)
    entry = tk.Entry(ef, font=tkfont.Font(family=FONT, size=11),
                     bg=CARD, fg=TITLE_C, insertbackground=ACCENT,
                     relief="solid", bd=1, show="*")
    entry.pack(fill=tk.X, ipady=9)

    tk.Label(dlg, text="获取 Key：platform.deepseek.com/api_keys",
             font=tkfont.Font(family=FONT, size=9), fg=SUB_C, bg="#f8fafc").pack(pady=(8, 22))

    bf = tk.Frame(dlg, bg="#f8fafc"); bf.pack()
    def confirm():
        k = entry.get().strip()
        if not k: messagebox.showwarning("提示", "请输入 API Key", parent=dlg); return
        result["api_key"] = k; dlg.destroy()

    tk.Button(bf, text="开始使用", font=tkfont.Font(family=FONT, size=11),
              bg=ACCENT, fg="white", relief="flat", padx=22, pady=7,
              cursor="hand2", command=confirm).pack(side=tk.LEFT, padx=8)
    tk.Button(bf, text="取消", font=tkfont.Font(family=FONT, size=11),
              bg=SEP_C, fg=BODY_C, relief="flat", padx=22, pady=7,
              cursor="hand2", command=dlg.destroy).pack(side=tk.LEFT)

    entry.focus_set()
    dlg.bind("<Return>", lambda e: confirm())
    dlg.protocol("WM_DELETE_WINDOW", dlg.destroy)
    dlg.mainloop()
    return result

# ─── 剪贴板 ───────────────────────────────────────────────────────────────────
class CB:
    @staticmethod
    def get():
        try:
            win32clipboard.OpenClipboard()
            try: return win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT) or ""
            except: return ""
            finally: win32clipboard.CloseClipboard()
        except: return ""

    @staticmethod
    def set(text):
        try:
            win32clipboard.OpenClipboard(); win32clipboard.EmptyClipboard()
            if text: win32clipboard.SetClipboardData(win32con.CF_UNICODETEXT, text)
            win32clipboard.CloseClipboard()
        except:
            try: win32clipboard.CloseClipboard()
            except: pass

# ─── 主应用 ────────────────────────────────────────────────────────────────────
class App:
    def __init__(self, cfg):
        self.cfg = cfg
        self.client  = OpenAI(api_key=cfg["api_key"], base_url=cfg["api_base"])
        self.last_click  = 0.0
        self.last_lookup = 0.0
        self.busy    = False
        self.popup   = None
        self.expl_var = None
        self.pbounds  = None

        self.root = tk.Tk(); self.root.withdraw(); self.root.title("ClickWord")
        self._start_listener(); self._setup_tray()

    # ── 鼠标监听 ──────────────────────────────────────────────────────────────
    def _start_listener(self):
        self._ml = mouse_mod.Listener(on_click=self._on_click)
        self._ml.daemon = True; self._ml.start()

    def _on_click(self, x, y, button, pressed):
        if button != mouse_mod.Button.left or not pressed: return
        if self.popup:
            if self.pbounds:
                px, py, pw, ph = self.pbounds
                if not (px <= x <= px+pw and py <= y <= py+ph):
                    self.root.after(0, self._close); self.last_click = 0
            return
        now = time.time()
        if now - self.last_click < self.cfg["double_click_interval"]:
            self.last_click = 0
            if not self.busy and now - self.last_lookup > self.cfg["cooldown"]:
                self.last_lookup = now
                threading.Thread(target=self._dbl, args=(x, y), daemon=True).start()
        else:
            self.last_click = now

    def _dbl(self, x, y):
        time.sleep(0.13)
        old = CB.get()
        kb = keyboard_mod.Controller()
        with kb.pressed(keyboard_mod.Key.ctrl):
            kb.press("c"); kb.release("c")
        time.sleep(0.12)
        word = CB.get()
        if old and old != word:
            time.sleep(0.05); CB.set(old)
        word = (word or "").strip()
        if not word or word == old or len(word) > self.cfg["max_word_length"]: return
        self.busy = True
        self.root.after(0, lambda: self._show(word, x, y))

    # ── 弹窗（Win32 圆角 + 白色卡片）─────────────────────────────────────────
    def _show(self, word, x, y):
        self._close()

        p = tk.Toplevel(self.root)
        p.withdraw()
        p.overrideredirect(True)
        p.attributes("-topmost", True)
        p.configure(bg=OUTER)          # 外框色 → 圆角裁剪后形成边框效果
        self.popup = p

        # 白色内卡（与外框之间 2px 产生细边框）
        card = tk.Frame(p, bg=CARD, padx=20, pady=16)
        card.pack(padx=2, pady=2, fill=tk.BOTH, expand=True)

        ft = tkfont.Font(family=FONT, size=13, weight="bold")
        fb = tkfont.Font(family=FONT, size=10)
        fs = tkfont.Font(family=FONT, size=9)

        # 标题 + 关闭按钮
        hdr = tk.Frame(card, bg=CARD); hdr.pack(fill=tk.X, pady=(0, 8))
        disp = word[:52] + "…" if len(word) > 52 else word
        tk.Label(hdr, text=disp, font=ft, fg=ACCENT, bg=CARD, anchor="w"
                 ).pack(side=tk.LEFT, fill=tk.X, expand=True)
        cl = tk.Label(hdr, text="×", font=tkfont.Font(family=FONT, size=14),
                      fg=SUB_C, bg=CARD, cursor="hand2")
        cl.pack(side=tk.RIGHT)
        cl.bind("<Button-1>", lambda e: self._close())

        # 分割线
        tk.Frame(card, height=1, bg=SEP_C).pack(fill=tk.X, pady=(0, 10))

        # 解释文字
        self.expl_var = tk.StringVar(value="正在查询…")
        tk.Label(card, textvariable=self.expl_var, font=fb, fg=BODY_C, bg=CARD,
                 wraplength=400, justify=tk.LEFT, anchor="w"
                 ).pack(fill=tk.X, pady=(0, 14))

        # 操作按钮
        row = tk.Frame(card, bg=CARD); row.pack(fill=tk.X)
        def mkbtn(text, fg, bg, cmd):
            b = tk.Label(row, text=text, font=fs, fg=fg, bg=bg, padx=10, pady=4, cursor="hand2")
            b.pack(side=tk.LEFT, padx=(0, 6))
            b.bind("<Button-1>", lambda e: cmd())
            b.bind("<Enter>",  lambda e, _b=b: _b.config(fg=ACCENT))
            b.bind("<Leave>",  lambda e, _b=b, _f=fg: _b.config(fg=_f))

        mkbtn("复制", SUB_C, COPY_BG, self._copy)
        q = urllib.parse.quote(word)
        mkbtn("百度",   LINK_FG, LINK_BG, lambda: webbrowser.open(f"https://www.baidu.com/s?wd={q}"))
        mkbtn("维基",   LINK_FG, LINK_BG, lambda: webbrowser.open(f"https://zh.wikipedia.org/w/index.php?search={q}"))
        mkbtn("Google", LINK_FG, LINK_BG, lambda: webbrowser.open(f"https://www.google.com/search?q={q}"))

        # ── 定位 & 圆角 ──
        p.update_idletasks()
        W = max(p.winfo_reqwidth(), 460)
        H = p.winfo_reqheight()

        sw = self.root.winfo_screenwidth(); sh = self.root.winfo_screenheight()
        px = max(10, min(x + 14, sw - W - 14))
        py = y + 30
        if py + H > sh - 60: py = max(10, y - H - 10)

        p.geometry(f"{W}x{H}+{px}+{py}")
        self.pbounds = (px, py, W, H)
        p.deiconify()
        p.update_idletasks()

        # 应用 Win32 圆角
        _round_window(p.winfo_id(), W, H, r=14)

        p.bind("<Escape>", lambda e: self._close())
        threading.Thread(target=self._ai, args=(word,), daemon=True).start()

    def _copy(self):
        if self.expl_var:
            t = self.expl_var.get()
            if t and "查询" not in t: CB.set(t)

    def _ai(self, word):
        try:
            r = self.client.chat.completions.create(
                model=self.cfg["model"],
                messages=[{"role": "user", "content": (
                    f'请对以下内容给出简洁解释（2-3句话，不超过100字）：\n\n"{word}"\n\n'
                    '要求：直接解释，不重复词语本身；英文→中文释义和例句；'
                    '中文→详细说明；专业术语→通俗解释；人名地名→简短介绍；'
                    '整段文字→核心要点总结。'
                )}],
                max_tokens=200, temperature=0.3
            )
            text = r.choices[0].message.content.strip()
        except Exception as e:
            text = f"⚠ 查询失败：{str(e)[:80]}"
        self.root.after(0, lambda: self._upd(text))
        self.busy = False

    def _upd(self, text):
        if self.expl_var and self.popup:
            try: self.expl_var.set(text); self.popup.update_idletasks()
            except: pass

    def _close(self):
        self.busy = False
        if self.popup:
            try: self.popup.destroy()
            except: pass
        self.popup = None; self.pbounds = None; self.expl_var = None

    # ── 系统托盘 ──────────────────────────────────────────────────────────────
    def _make_icon(self):
        img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.ellipse([2, 2, 62, 62], fill=(99, 102, 241, 230))
        try:
            fnt = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 34)
            bb = d.textbbox((0, 0), "W", font=fnt)
            d.text(((64-bb[2]+bb[0])//2, (64-bb[3]+bb[1])//2 - 1),
                   "W", fill=(255, 255, 255), font=fnt)
        except:
            d.rectangle([20, 22, 44, 42], fill=(255, 255, 255))
        return img

    def _setup_tray(self):
        menu = pystray.Menu(
            pystray.MenuItem("ClickWord  运行中", None, enabled=False),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("退出", self._quit),
        )
        self.tray = pystray.Icon("ClickWord", self._make_icon(), "ClickWord - 双击查词", menu)

    def _quit(self, *_):
        self._ml.stop(); self.tray.stop(); self.root.quit()

    def run(self):
        threading.Thread(target=self.tray.run, daemon=True).start()
        self.root.mainloop()

# ─── 入口 ─────────────────────────────────────────────────────────────────────
def main():
    cfg = load_config()
    if not cfg.get("api_key"):
        res = show_setup_dialog()
        if not res.get("api_key"): sys.exit(0)
        cfg["api_key"] = res["api_key"]; save_config(cfg)
    try:
        App(cfg).run()
    except Exception as e:
        r = tk.Tk(); r.withdraw()
        messagebox.showerror("ClickWord 错误", f"{e}\n\n{traceback.format_exc()[:500]}")
        sys.exit(1)

if __name__ == "__main__":
    main()
