// Starts Vite's dev server on a copy of the application, connects to it as the browser's HMR client does,
// edits App.tsx, and prints the messages the server sends: node scripts/hmr.mjs
import { cpSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createServer } from 'vite';

const root = 'out/hmr';
rmSync(root, { recursive: true, force: true });
for (const file of ['index.html', 'src']) cpSync(file, `${root}/${file}`, { recursive: true });

const server = await createServer({ root, configFile: 'vite.config.ts', server: { port: 5199, strictPort: true }, logLevel: 'silent' });
await server.listen();

const messages = [];
const socket = new WebSocket('ws://localhost:5199/', 'vite-hmr');
socket.addEventListener('message', (event) => messages.push(JSON.parse(event.data)));
await new Promise((resolve) => socket.addEventListener('open', resolve));

// The browser loads the page and its modules, which puts App.tsx in the module graph
for (const url of ['/', '/src/main.tsx', '/src/App.tsx']) await (await fetch(`http://localhost:5199${url}`)).text();
// Let the dependency optimizer finish: closing the server while it runs never settles (see the journal)
await server.environments.client.waitForRequestsIdle();

// Edit the component, as you would in the editor, and wait for the update
const app = `${root}/src/App.tsx`;
writeFileSync(app, readFileSync(app, 'utf8').replace('React (Vite) course', 'React (Vite) course, edited'));
const deadline = Date.now() + 10_000;
while (!messages.some((m) => m.type === 'update') && Date.now() < deadline) await new Promise((r) => setTimeout(r, 50));

for (const message of messages) console.log(JSON.stringify(message, null, 2));
socket.close();
await server.close();
process.exit(0);
