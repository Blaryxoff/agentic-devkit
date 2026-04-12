import { execaCommand } from "execa";

const DEFAULT_PING_TIMEOUT_MS = 1500;

async function canReachUrl(url) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), DEFAULT_PING_TIMEOUT_MS);
    const response = await fetch(url, {
      method: "GET",
      signal: controller.signal,
    });
    clearTimeout(timeout);
    return response.ok || response.status < 500;
  } catch {
    return false;
  }
}

async function waitForUrl(url, timeoutMs) {
  const startedAt = Date.now();
  while (Date.now() - startedAt <= timeoutMs) {
    if (await canReachUrl(url)) {
      return true;
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  return false;
}

export async function ensureServer(config) {
  const server = config.server ?? {};
  const readyUrl = server.readyUrl ?? config.baseUrl;

  if (!readyUrl) {
    return null;
  }

  const available = await canReachUrl(readyUrl);
  if (available && server.reuseIfAvailable !== false) {
    return null;
  }

  if (!server.command) {
    throw new Error(
      `Server is not reachable at ${readyUrl} and no server.command is configured.`,
    );
  }

  const child = execaCommand(server.command, {
    shell: true,
    stdio: "inherit",
  });

  const startupTimeoutMs = server.startupTimeoutMs ?? 120000;
  const isReady = await waitForUrl(readyUrl, startupTimeoutMs);
  if (!isReady) {
    child.kill("SIGTERM", {
      forceKillAfterTimeout: 5000,
    });
    throw new Error(`Server did not become ready at ${readyUrl}`);
  }

  return child;
}
