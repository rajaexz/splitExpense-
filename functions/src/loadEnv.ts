import * as path from "path";
import * as dotenv from "dotenv";

// Must be imported before any code that reads process.env.GEMINI_API_KEY (emulator loads functions/.env).
dotenv.config({ path: path.resolve(__dirname, "../.env") });
