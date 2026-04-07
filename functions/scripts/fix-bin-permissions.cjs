#!/usr/bin/env node
/**
 * npm sometimes installs shims in node_modules/.bin without execute bit (EACCES on spawn).
 * Firebase emulator runs `firebase-functions` from .bin — must be executable.
 */
const fs = require("fs");
const path = require("path");

const bin = path.join(__dirname, "..", "node_modules", ".bin");
if (!fs.existsSync(bin)) {
  process.exit(0);
}
for (const name of fs.readdirSync(bin)) {
  const p = path.join(bin, name);
  try {
    fs.chmodSync(p, 0o755);
  } catch (_) {
    /* ignore */
  }
}
