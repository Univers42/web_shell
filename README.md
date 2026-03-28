# Cloud Terminal

A full-featured web-based terminal emulator built with React, xterm.js, and node-pty — designed as a composable component within the **Prismatica (libcss)** design system.

---

## Purpose

The goal was to build a real, production-quality terminal that runs in the browser — not a simulated shell or a REPL toy, but a proper PTY-backed bash session with full interactivity (tab completion, history, ncurses, vim, etc.).

The project was developed in two phases:

1. **Prototype** (`cloud-terminal/`): A standalone React app proving the concept — xterm.js on the frontend, node-pty on the backend, connected via socket.io WebSockets.
2. **Design System Integration** (`app/`): A complete rebuild of the terminal UI as a set of composable libcss components following BEM methodology, custom property theming, and the library's component architecture patterns.

## What We Built

### Architecture

```
Browser (React + xterm.js)
    ↕  socket.io WebSocket
Server (Express + node-pty)
    ↕  PTY (pseudo-terminal)
bash (real shell session)
```

### Backend — `server.ts`

- **Express** HTTP server with **Vite** dev middleware (HMR in development, static build in production)
- **socket.io** WebSocket server — one PTY session per connected client
- **node-pty** spawns a real `bash` process with `xterm-256color` capabilities
- Custom init file per session sources `bootstrap.sh` for shell configuration
- Supports `input`, `resize`, `request-edit`, and `save-file` socket events
- Clean PTY teardown on disconnect

### Frontend — libcss `CloudTerminal` Component

A single `<CloudTerminal />` invocation renders the entire terminal experience. Internally it composes:

| Component | Role |
|---|---|
| `TerminalBackground` | Atmospheric gradient orbs + noise texture overlay |
| `TerminalNavRail` | Left icon navigation bar (terminal, editor, docs views) |
| `TerminalHeader` | Top bar — title, connection status indicator, clear/fullscreen actions |
| `TerminalChrome` | macOS-style chrome bar with decorative dots, session label, encryption badge |
| `TerminalViewport` | xterm.js mount container with optional CRT scanline effect |
| `TerminalStatusBar` | Bottom bar — PTY info, encoding, session ID |
| `TerminalEditor` | File editor overlay with syntax area, save/close, line count |
| `TerminalDocs` | Documentation viewer overlay |
| `useXterm` | React hook managing xterm.js + FitAddon + socket.io lifecycle |

### Shell — `bootstrap.sh`

Every PTY session is initialized with:

- History persistence (10,000 entries, deduplication)
- Shell quality-of-life (`autocd`, `cdspell`, `globstar`)
- Color support (dircolors, colored `ls`/`grep` aliases)
- Git-aware prompt showing branch name and dirty state
- Welcome banner with session metadata

### Styling

All CSS follows BEM with a `ct-` (cloud-terminal) namespace. Theming is driven by CSS custom properties (`--ct-bg`, `--ct-accent`, `--ct-surface`, etc.) bridged from the libcss design tokens, so dark/light themes cascade automatically.

## Project Structure

```
web_shell/
├── cloud-terminal/          # Original standalone prototype (kept for reference)
│   ├── server.ts
│   ├── src/App.tsx
│   └── shell/core/bootstrap.sh
│
├── app/                     # Production build — libcss integration
│   ├── server.ts            # Express + socket.io + node-pty + Vite
│   ├── index.html
│   ├── src/
│   │   ├── App.tsx          # Single <CloudTerminal /> invocation
│   │   ├── main.tsx
│   │   └── lib/libcss/components/cloud-terminal/
│   │       ├── CloudTerminal.tsx        # Main composable component
│   │       ├── CloudTerminal.types.ts   # All TypeScript interfaces
│   │       ├── CloudTerminal.constants.ts
│   │       ├── CloudTerminal.css        # ~600 lines BEM CSS
│   │       ├── useXterm.ts              # xterm.js + socket.io hook
│   │       ├── TerminalHeader.tsx
│   │       ├── TerminalChrome.tsx
│   │       ├── TerminalViewport.tsx
│   │       ├── TerminalStatusBar.tsx
│   │       ├── TerminalNavRail.tsx
│   │       ├── TerminalEditor.tsx
│   │       ├── TerminalDocs.tsx
│   │       ├── TerminalBackground.tsx
│   │       └── index.ts
│   └── shell/core/bootstrap.sh
│
└── README.md
```

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js, TypeScript |
| Frontend | React 19, Vite 6 |
| Terminal | xterm.js v6 (`@xterm/xterm`), `@xterm/addon-fit` |
| PTY | `node-pty` — real pseudo-terminal |
| Transport | socket.io (WebSocket with fallback) |
| Server | Express 4 |
| Design System | libcss / Prismatica (BEM, CSS custom properties, `cn()` utility) |

## Getting Started

```bash
cd app
npm install
npm run dev
```

Server starts at **http://localhost:3000**. Open in a browser to get a full terminal session.

## What Works

- Real PTY — full bash with tab completion, history, signal handling
- Live resize — terminal adapts to window/container size changes
- Git-aware prompt with dirty state detection
- Integrated file editor — `edit <file>` opens an in-browser editor overlay
- Docs viewer panel
- Connection status indicator (live/connecting/disconnected)
- Fullscreen toggle
- Buffer clear
- Clean session teardown (PTY killed, temp files cleaned on disconnect)
- Zero TypeScript errors across the entire component suite
- Fully composable — `<CloudTerminal />` is a single drop-in component

## License

Private.
