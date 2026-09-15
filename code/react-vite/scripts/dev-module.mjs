// Starts Vite's dev server, prints what the browser receives for one module, and stops the server:
// node scripts/dev-module.mjs src/App.tsx (no leading slash: Git Bash on Windows would turn it into a path)
import { createServer } from 'vite';

const url = `/${process.argv[2] ?? ''}`;
const server = await createServer({ server: { port: 5199, strictPort: true }, logLevel: 'silent' });
await server.listen();
try {
  const response = await fetch(`http://localhost:5199${url}`);
  console.log(`GET ${url} -> ${response.status} ${response.headers.get('content-type')}`);
  console.log(await response.text());
  await server.environments.client.waitForRequestsIdle(); // closing while the dependency optimizer runs never settles
} finally {
  await server.close();
}
