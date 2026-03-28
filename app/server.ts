import express from "express";
import { createServer } from "http";
import { Server } from "socket.io";
import { createServer as createViteServer } from "vite";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";
import * as pty from "node-pty";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const httpServer = createServer(app);
  const io = new Server(httpServer, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  const PORT = 3000;

  io.on("connection", (socket) => {
    console.log("Client connected:", socket.id);

    // Create an init file that sources bootstrap + defines custom commands
    const bootstrapPath = path.join(process.cwd(), "shell", "core", "bootstrap.sh");
    const initFilePath = path.join("/tmp", `.cloudshell_rc_${socket.id}`);
    const rcContent = `
# Source user's bashrc if it exists
if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

# Source the bootstrap script
if [ -f "${bootstrapPath}" ]; then
  source "${bootstrapPath}"
fi

# Define custom commands that send OSC 0 (title change) to the terminal
function edit() {
  if [ -z "$1" ]; then
    echo "edit: missing filename"
  else
    local abs_path=\$(readlink -m "\$1")
    echo -ne "\\033]0;EDIT:\$abs_path\\007"
  fi
}
function docs() {
  echo -ne "\\033]0;DOCS:\\007"
}
`;
    fs.writeFileSync(initFilePath, rcContent);

    // Determine which shell to use: hellish if available, otherwise bash
    const shellCmd = fs.existsSync("/usr/bin/hellish") ? "hellish" : "bash";
    const shellArgs = shellCmd === "bash" ? ["--init-file", initFilePath, "-i"] : [];

    // Spawn a real PTY using node-pty
    let ptyAlive = true;
    let ptyProcess: pty.IPty;
    try {
      ptyProcess = pty.spawn(shellCmd, shellArgs, {
        name: "xterm-256color",
        cols: 80,
        rows: 24,
        cwd: process.cwd(),
        env: { ...process.env, TERM: "xterm-256color" } as Record<string, string>,
      });
    } catch (err: any) {
      socket.emit("output", `\r\n[Failed to start shell: ${err.message}]\r\n`);
      socket.disconnect(true);
      return;
    }

    ptyProcess.onData((data: string) => {
      if (socket.connected) socket.emit("output", data);
    });

    // Emit PTY info (TTY slave path + PID) to the client
    try {
      const ttyPath = fs.readlinkSync(`/proc/${ptyProcess.pid}/fd/0`);
      socket.emit("pty-info", { pid: ptyProcess.pid, tty: ttyPath });
    } catch {
      socket.emit("pty-info", { pid: ptyProcess.pid, tty: `pts/${ptyProcess.pid}` });
    }

    ptyProcess.onExit(() => {
      ptyAlive = false;
      if (socket.connected) {
        socket.emit("output", "\r\n[Session ended]\r\n");
        socket.emit("session-ended");
        socket.disconnect(true);
      }
    });

    // Catch underlying process errors (EPIPE, etc.) so they don't crash the server
    try {
      const underlying = (ptyProcess as any)._process ?? (ptyProcess as any).process;
      if (underlying?.stdin) {
        underlying.stdin.on('error', () => { ptyAlive = false; });
      }
    } catch { /* no access to internals — that's fine */ }

    socket.on("input", (data: string) => {
      if (!ptyAlive) return;
      try {
        ptyProcess.write(data);
      } catch {
        ptyAlive = false;
      }
    });

    socket.on("resize", (size: { cols: number; rows: number }) => {
      if (!ptyAlive) return;
      try {
        ptyProcess.resize(size.cols, size.rows);
      } catch {
        ptyAlive = false;
      }
    });

    socket.on("request-edit", (filename: string) => {
      try {
        let content = "";
        if (fs.existsSync(filename)) {
          content = fs.readFileSync(filename, "utf-8");
        }
        socket.emit("editor-open", { filename, content });
      } catch (err: any) {
        socket.emit("output", `\r\nError opening file: ${err.message}\r\n`);
      }
    });

    socket.on("save-file", ({ filename, content }: { filename: string; content: string }) => {
      try {
        fs.writeFileSync(filename, content);
        socket.emit("output", `\r\nSaved ${filename}\r\n`);
      } catch (err: any) {
        socket.emit("output", `\r\nError saving file: ${err.message}\r\n`);
      }
    });

    socket.on("disconnect", () => {
      ptyAlive = false;
      try { ptyProcess.kill(); } catch {}
      try { fs.unlinkSync(initFilePath); } catch {}
    });
  });

  // Prevent uncaught EPIPE errors from crashing the server
  process.on('uncaughtException', (err) => {
    if ((err as any).code === 'EPIPE' || (err as any).code === 'EIO') {
      console.warn('[Server] Caught EPIPE/EIO — a terminal process was likely killed');
      return;
    }
    console.error('[Server] Uncaught exception:', err);
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: {
        middlewareMode: true,
        hmr: { server: httpServer },
      },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  httpServer.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`[Server] Port ${PORT} is already in use.`);
      console.error('[Server] Kill existing processes or use a different port.');
      // Try the next port automatically
      const altPort = PORT + 1;
      console.log(`[Server] Trying fallback port ${altPort}...`);
      httpServer.listen(altPort, "0.0.0.0", () => {
        console.log(`Server running on http://localhost:${altPort}`);
      });
    } else {
      console.error('[Server] HTTP server error:', err);
      process.exit(1);
    }
  });

  httpServer.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
