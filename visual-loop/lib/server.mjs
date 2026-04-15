import { execaCommand } from "execa";

const DEFAULT_PING_TIMEOUT_MS = 1500;

function buildProbeUrls(url) {
  try {
    const parsed = new URL(url);
    const urls = new Set([parsed.toString()]);

    if (parsed.hostname === "localhost") {
      parsed.hostname = "127.0.0.1";
      urls.add(parsed.toString());
    } else if (parsed.hostname === "127.0.0.1") {
      parsed.hostname = "localhost";
      urls.add(parsed.toString());
    }

    return [...urls];
  } catch {
    return [url];
  }
}

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

async function canReachAnyUrl(urls) {
  for (const url of urls) {
    if (await canReachUrl(url)) {
      return true;
    }
  }
  return false;
}

async function waitForAnyUrl(urls, timeoutMs) {
  const startedAt = Date.now();
  while (Date.now() - startedAt <= timeoutMs) {
    if (await canReachAnyUrl(urls)) {
      return true;
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  return false;
}

export async function ensureServer(config, { cwd } = {}) {
  const server = config.server ?? {};
  const readyUrl = server.readyUrl ?? config.baseUrl;

  if (!readyUrl) {
    return null;
  }

  const probeUrls = buildProbeUrls(readyUrl);
  const available = await canReachAnyUrl(probeUrls);
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
    cwd,
  });

  const startupTimeoutMs = server.startupTimeoutMs ?? 120000;
  const isReady = await waitForAnyUrl(probeUrls, startupTimeoutMs);
  if (!isReady) {
    child.kill("SIGTERM", {
      forceKillAfterTimeout: 5000,
    });
    throw new Error(`Server did not become ready at ${readyUrl}`);
  }

  return child;
}
