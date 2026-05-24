# DESIGN.md

> 用大胆的色彩和弹性动效讲述一个有温度的创作者故事。

## 1. Visual Theme & Atmosphere

**Style**: 活泼创意 (Playful Creative)
**Keywords**: 大胆、有趣、年轻、弹性、多彩、手写、创意、活力
**Tone**: 充满个性的创作者气质 — NOT 严肃企业风、扁平无聊
**Feel**: 像打开一本涂鸦满满的手账，每翻一页都有惊喜

**Interaction Tier**: L2 流畅交互
**Dependencies**: IntersectionObserver (原生) + CSS 动画

## 2. Color Palette & Roles

```css
:root {
  /* Backgrounds */
  --bg: #FFF8F0;                          /* 暖奶油主背景 */
  --surface: #FFFFFF;                     /* 卡片/容器白色表面 */
  --surface-alt: #FFF0E8;                 /* 交替 section 浅橙 */
  --surface-hover: #FFF5EE;              /* 悬停态表面 */

  /* Borders */
  --border: #FFE0CC;                      /* 默认暖橙边框 */
  --border-hover: #FFB89A;               /* 悬停加深橙边框 */

  /* Text */
  --text: #2D2D2D;                        /* 主文字深灰 */
  --text-secondary: #666666;             /* 正文中灰 */
  --text-tertiary: #999999;              /* 辅助标签浅灰 */

  /* Accent */
  --accent: #FF3366;                      /* 主强调色——玫红 CTA */
  --accent-hover: #E6194F;              /* 玫红加深 hover */
  --accent-2: #FFD700;                   /* 辅助黄，标签/装饰 */
  --accent-3: #00CC88;                   /* 辅助绿，技能/成功态 */
  --accent-4: #7C3AED;                   /* 辅助紫，项目卡片点缀 */

  /* RGB variants for rgba() */
  --bg-rgb: 255, 248, 240;
  --accent-rgb: 255, 51, 102;
  --accent-2-rgb: 255, 215, 0;
  --accent-3-rgb: 0, 204, 136;

  /* Semantic */
  --success: #00CC88;
  --error: #FF3366;
  --warning: #FFD700;
}
```

**Color Rules:**
- 所有颜色通过 CSS 变量引用，禁止硬编码 hex
- 主强调色 `--accent` 仅用于 CTA 按钮、重要链接、当前状态
- 三个辅色分别对应不同类目（黄=标签/时间，绿=技能/成功，紫=项目/创意）
- 同一 section 内只出现一个强调色，避免视觉混乱

## 3. Typography Rules

**Font Stack:**
```css
@import url('https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&family=Nunito:wght@400;500;600;700&family=Caveat:wght@400;600&display=swap');
```

| Role | Font | Size | Weight | Line Height | Letter Spacing |
|------|------|------|--------|-------------|----------------|
| Hero H1 | Sora | clamp(2.8rem, 6vw, 5rem) | 800 | 1.1 | -0.02em |
| Section H2 | Sora | clamp(1.8rem, 3.5vw, 2.5rem) | 700 | 1.2 | -0.01em |
| H3 | Sora | 1.2rem | 600 | 1.3 | — |
| Body | Nunito | 1rem | 400 | 1.7 | — |
| Label/Tag | Nunito | 0.75rem | 700 | 1 | 0.05em |
| Accent/手写 | Caveat | 1.1rem | 600 | 1.4 | — |

**Typography Rules:**
- Heading weight ≥ 700，Hero H1 强制 800
- 中文内容行高 ≥ 1.7，字距 0.02em
- **NEVER use**: Arial, Georgia, system-ui 单独作为 heading 字体

**Text Decoration:**
- Hero H1: 渐变色文字（玫红 → 橙黄），体现活泼气质
- Section H2: 无渐变，用粗细对比建立层次

## 4. Component Stylings

### Buttons
```css
.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 28px;
  border-radius: 50px;
  font-family: 'Sora', sans-serif;
  font-size: 0.95rem;
  font-weight: 700;
  text-decoration: none;
  cursor: pointer;
  border: 2px solid transparent;
  transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1),
              box-shadow 0.2s ease,
              background 0.2s ease;
}
.btn-primary {
  background: var(--accent);
  color: #fff;
  box-shadow: 0 4px 14px rgba(var(--accent-rgb), 0.3);
}
.btn-primary:hover {
  transform: translateY(-2px) scale(1.02);
  box-shadow: 0 8px 24px rgba(var(--accent-rgb), 0.4);
  background: var(--accent-hover);
}
.btn-primary:active { transform: scale(0.96); box-shadow: none; }
.btn-primary:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; }
.btn-primary:disabled { opacity: 0.5; pointer-events: none; }
.btn-secondary {
  background: transparent;
  color: var(--accent);
  border-color: var(--accent);
}
.btn-secondary:hover { background: rgba(var(--accent-rgb), 0.06); transform: translateY(-1px); }
.btn-secondary:active { transform: scale(0.97); }
.btn-secondary:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; }
```

### Cards
```css
.card {
  background: var(--surface);
  border: 1.5px solid var(--border);
  border-radius: 20px;
  padding: 24px;
  transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1),
              box-shadow 0.3s ease,
              border-color 0.3s ease;
}
.card:hover {
  transform: translateY(-6px) rotate(0.5deg);
  box-shadow: 0 16px 40px rgba(var(--accent-rgb), 0.12);
  border-color: var(--border-hover);
}
.card:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.card-project::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 4px;
  background: linear-gradient(90deg, var(--accent), var(--accent-2));
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.3s ease;
}
.card-project:hover::before { transform: scaleX(1); }
```

### Navigation
```css
.nav {
  position: fixed; top: 0; width: 100%; z-index: 100;
  padding: 16px 0;
  background: transparent;
  transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1);
}
.nav.scrolled {
  padding: 10px 0;
  background: rgba(var(--bg-rgb), 0.88);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border);
  box-shadow: 0 2px 16px rgba(var(--accent-rgb), 0.06);
}
.nav-link {
  font-family: 'Sora', sans-serif; font-size: 0.875rem; font-weight: 600;
  color: var(--text-secondary); text-decoration: none;
  transition: color 0.2s ease; position: relative;
}
.nav-link::after {
  content: ''; position: absolute; bottom: -3px; left: 0;
  width: 0; height: 2px; background: var(--accent);
  transition: width 0.3s ease;
}
.nav-link:hover { color: var(--text); }
.nav-link:hover::after { width: 100%; }
```

### Tags / Badges
```css
.tag {
  display: inline-flex; align-items: center;
  padding: 4px 12px; border-radius: 50px;
  font-family: 'Nunito', sans-serif; font-size: 0.72rem;
  font-weight: 700; letter-spacing: 0.04em; text-transform: uppercase;
}
.tag-pink { background: rgba(var(--accent-rgb), 0.1); color: var(--accent); }
.tag-yellow { background: rgba(var(--accent-2-rgb), 0.15); color: #B8860B; }
.tag-green { background: rgba(var(--accent-3-rgb), 0.12); color: #00996A; }
.tag-purple { background: rgba(124,58,237,0.1); color: #7C3AED; }
```

## 5. Layout Principles

**Container:**
- Max width: 1100px
- Padding: 0 24px (mobile: 0 16px)

**Spacing Scale:**
- Section padding: 80px 0 (mobile: 56px 0)
- Component gap: 24px (cards), 16px (tags)
- Card internal padding: 24px

**Grid:**
```css
.grid-2 { display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; }
.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
```

## 6. Depth & Elevation

| Level | Treatment | Use |
|-------|-----------|-----|
| Flat | 无阴影，仅边框 | 标签、次级元素 |
| Subtle | `0 2px 8px rgba(var(--accent-rgb), 0.06)` | 默认卡片 |
| Elevated | `0 8px 24px rgba(var(--accent-rgb), 0.12)` | 卡片 hover |
| Float | `0 16px 40px rgba(var(--accent-rgb), 0.18)` | 弹窗 |
| Colored | `0 6px 20px rgba(var(--accent-rgb), 0.3)` | CTA 按钮 |

## 7. Animation & Interaction

**Motion Philosophy**: 弹性为主，每次交互都有轻微"弹跳"，让界面有生命感
**Tier**: L2

### Entrance Animation
```css
.reveal {
  opacity: 0; transform: translateY(32px);
  transition: opacity 0.7s cubic-bezier(0.16, 1, 0.3, 1),
              transform 0.7s cubic-bezier(0.16, 1, 0.3, 1);
}
.reveal.in-view { opacity: 1; transform: translateY(0); }
.reveal-scale {
  opacity: 0; transform: scale(0.88);
  transition: opacity 0.5s cubic-bezier(0.34, 1.56, 0.64, 1),
              transform 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.reveal-scale.in-view { opacity: 1; transform: scale(1); }
```

### Special Effects
- Hero H1 渐变流动：`background-position` 动画（极低 GPU 成本）
- Blob 背景：`border-radius` morphing + `filter: blur(60px)`（仅位置不动时使用）
- 滚动进度条：`transform: scaleX()` 不触发 layout

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
  .reveal, .reveal-scale { opacity: 1; transform: none; }
}
```

## 8. Do's and Don'ts

### Do
- 用大圆角（16-24px）让元素看起来"软萌"
- 每个 section 保持大量留白，让色彩元素"呼吸"
- 卡片 hover 时加轻微旋转（0.5deg），强化弹性感
- 用渐变色来强调最重要的标题，但每页只用一处
- 所有动画使用弹性曲线 `cubic-bezier(0.34, 1.56, 0.64, 1)`

### Don't
- ❌ 禁止使用 `#000000` 纯黑，用 `#2D2D2D` 代替
- ❌ 禁止硬编码 hex 颜色值
- ❌ 禁止同一区块同时出现三种以上强调色
- ❌ 禁止在 moving elements 上使用 `filter: blur()`
- ❌ 禁止 backdrop-filter blur 超过 14px
- ❌ 禁止卡片 gap 小于 16px
- ❌ 禁止在正文使用全大写英文
- ❌ 禁止纯色块作为图片占位

## 9. Responsive Behavior

**Breakpoints:**
| Name | Width | Key Changes |
|------|-------|-------------|
| Desktop | > 1024px | 三列网格、左右分栏 Hero |
| Tablet | 768px–1024px | 二列网格 |
| Mobile | < 768px | 单列、垂直堆叠、汉堡菜单 |

**Touch Targets:** minimum 44×44px
**Collapsing Strategy:** Grid 列数 3→2→1；Hero 左右分栏→垂直堆叠

```css
@media (max-width: 1024px) { .grid-3 { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 768px) {
  .grid-2, .grid-3 { grid-template-columns: 1fr; }
  .hero-layout { flex-direction: column; text-align: center; }
  .nav-links { display: none; }
  .container { padding: 0 16px; }
}
```
