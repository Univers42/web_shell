/**
 * Inferno Terminal — Electron Main Process
 *
 * Uses the generic libcss/desktop scaffold.
 * Just configure and go.
 */
const path = require('path');
const { createMainProcess } = require('../src/lib/libcss/desktop/createMainProcess.cjs');

createMainProcess({
  name: 'Inferno Terminal',
  appId: 'com.inferno.terminal',

  // Tell the scaffold where we are
  _callerDir: __dirname,
  _projectRoot: path.resolve(__dirname, '..'),

  server: {
    port: 3000,
    args: ['server.ts'],
    readySignal: 'Server running',
    killStalePort: true,
    startupTimeout: 15000,
  },

  window: {
    width: 1200,
    height: 800,
    frame: false,
    backgroundColor: '#050505',
    icon: path.join(__dirname, 'icon.svg'),
  },

  preload: path.join(__dirname, 'preload.cjs'),
  devtools: true,
  fullscreenShortcut: true,
});
