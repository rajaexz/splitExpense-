"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const path = require("path");
const dotenv = require("dotenv");
// Must be imported before any code that reads process.env.GEMINI_API_KEY (emulator loads functions/.env).
dotenv.config({ path: path.resolve(__dirname, "../.env") });
//# sourceMappingURL=loadEnv.js.map