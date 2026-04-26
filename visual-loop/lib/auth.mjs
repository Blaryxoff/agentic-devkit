import fs from "node:fs/promises";
import path from "node:path";
import readline from "node:readline/promises";
import { chromium } from "playwright";

export function resolveAuth(globalAuth, pageAuth) {
  if (pageAuth === false) {
    return null;
  }
  if (pageAuth && typeof pageAuth === "object") {
    return { ...globalAuth, ...pageAuth };
  }
  return globalAuth ?? null;
}

export function authStatePath(visualDir) {
  return path.join(visualDir, ".auth-state.json");
}

export async function clearStorageState(statePath) {
  await fs.unlink(statePath).catch(() => {});
}

async function stateExists(statePath) {
  try {
    await fs.stat(statePath);
    return true;
  } catch {
    return false;
  }
}

function getToken(auth) {
  return auth?.credentials?.token || null;
}

function getNestedValue(obj, dotPath) {
  return dotPath.split(".").reduce((acc, key) => acc?.[key], obj);
}

/**
 * Ensure auth is ready and return { statePath, extraHTTPHeaders }.
 *
 * Resolution order:
 *   1. credentials.token set in config → use it directly (bearer/cookie/localStorage)
 *   2. Auth state file exists → reuse
 *   3. loginMode "api" → POST credentials as JSON, extract JWT from response
 *   4. credentials.email + password set → browser form login
 *   5. Fallback → interactive prompt: user pastes token from DevTools
 */
export async function ensureStorageState(auth, baseUrl, statePath) {
  const token = getToken(auth);

  if (token) {
    const tokenType = auth.tokenType ?? "bearer";
    if (tokenType === "bearer") {
      return { statePath: null, extraHTTPHeaders: { Authorization: `Bearer ${token}` } };
    }
    await buildTokenStorageState(token, tokenType, auth, baseUrl, statePath);
    return { statePath, extraHTTPHeaders: {} };
  }

  if (await stateExists(statePath)) {
    return { statePath, extraHTTPHeaders: {} };
  }

  const loginMode = auth.loginMode ?? "auto";

  if (loginMode === "api") {
    const resolved = await promptCredentials(auth);
    await performApiLogin(resolved, baseUrl, statePath);
    return { statePath, extraHTTPHeaders: {} };
  }

  const hasFormCredentials =
    auth.credentials?.email && auth.credentials?.password;

  if (loginMode === "form" || (loginMode === "auto" && hasFormCredentials)) {
    const resolved = await promptCredentials(auth);
    await performLogin(resolved, baseUrl, statePath);
    return { statePath, extraHTTPHeaders: {} };
  }

  // Fallback: ask which auth method to use
  await promptAuthMethod(auth, baseUrl, statePath);
  return { statePath, extraHTTPHeaders: {} };
}

// ─── Interactive auth method prompt ───────────────────────────────────────

async function promptAuthMethod(auth, baseUrl, statePath) {
  process.stderr.write(
    [
      "",
      "┌─────────────────────────────────────────────────────┐",
      "│  Visual Loop — Auth required                        │",
      "│                                                     │",
      "│  How would you like to authenticate?                │",
      "│    1  Email + password (form login)                 │",
      "│    2  Paste token from browser DevTools             │",
      "└─────────────────────────────────────────────────────┘",
      "",
    ].join("\n"),
  );

  const rl = readline.createInterface({ input: process.stdin, output: process.stderr });

  try {
    const choice = (await rl.question("Choice [1/2]: ")).trim();

    if (choice === "1") {
      const email = auth.credentials?.email || (await rl.question("Email: "));
      const password = auth.credentials?.password || (await rl.question("Password: "));
      const resolved = { ...auth, credentials: { ...auth.credentials, email, password } };
      await performLogin(resolved, baseUrl, statePath);
    } else {
      const storageKey = auth.tokenStorageKey ?? "access_token";

      process.stderr.write(
        [
          "",
          "  1. Open DevTools → Application → Local Storage",
          `  2. Copy the value of: ${storageKey}`,
          "",
        ].join("\n"),
      );

      const token = (await rl.question("Token: ")).trim();
      if (!token) {
        throw new Error("No token provided. Cannot proceed without auth.");
      }

      const parsed = new URL(baseUrl);
      const state = {
        cookies: auth.tokenCookie ? [cookieEntry(auth.tokenCookie, token, parsed)] : [],
        origins: [localStorageEntry(parsed.origin, storageKey, token)],
      };

      await writeStorageState(statePath, state);
      console.log(`Auth saved to ${path.relative(process.cwd(), statePath)}`);
    }
  } finally {
    rl.close();
  }
}

// ─── API login ─────────────────────────────────────────────────────────────

async function performApiLogin(auth, baseUrl, statePath) {
  const loginUrl = new URL(auth.loginUrl, baseUrl).toString();
  const { email, password } = auth.credentials;

  const res = await fetch(loginUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`API login failed: ${res.status} ${res.statusText}${text ? `\n${text}` : ""}`);
  }

  const body = await res.json();
  const tokenPath = auth.tokenPath ?? "accessToken";
  const token = getNestedValue(body, tokenPath);

  if (!token) {
    throw new Error(
      `Token not found at path "${tokenPath}" in login response. Got: ${JSON.stringify(body)}`,
    );
  }

  const parsed = new URL(baseUrl);
  const storageKey = auth.tokenStorageKey ?? "access_token";

  const state = {
    cookies: auth.tokenCookie ? [cookieEntry(auth.tokenCookie, token, parsed)] : [],
    origins: [localStorageEntry(parsed.origin, storageKey, token)],
  };

  await writeStorageState(statePath, state);
  console.log(`API login successful. Auth cached at ${path.relative(process.cwd(), statePath)}`);
}

// ─── Manual token injection ────────────────────────────────────────────────

async function buildTokenStorageState(token, tokenType, auth, baseUrl, statePath) {
  const parsed = new URL(baseUrl);
  let state;

  if (tokenType === "cookie") {
    state = {
      cookies: [cookieEntry(auth.tokenCookie ?? "token", token, parsed)],
      origins: [],
    };
  } else if (tokenType === "localStorage") {
    state = {
      cookies: [],
      origins: [localStorageEntry(parsed.origin, auth.tokenStorageKey ?? "access_token", token)],
    };
  } else {
    throw new Error(`Unknown tokenType: "${tokenType}". Expected "bearer", "cookie", or "localStorage".`);
  }

  await writeStorageState(statePath, state);
}

// ─── Form login ────────────────────────────────────────────────────────────

export async function promptCredentials(auth) {
  if (auth.credentials?.token) return auth;

  const email = auth.credentials?.email;
  const password = auth.credentials?.password;
  if (email && password) return auth;

  const rl = readline.createInterface({ input: process.stdin, output: process.stderr });
  try {
    const promptEmail = email || (await rl.question("Email: "));
    const promptPassword = password || (await rl.question("Password: "));
    return {
      ...auth,
      credentials: { ...auth.credentials, email: promptEmail, password: promptPassword },
    };
  } finally {
    rl.close();
  }
}

export async function performLogin(auth, baseUrl, statePath) {
  const loginUrl = new URL(auth.loginUrl, baseUrl).toString();
  const fields = auth.fields ?? { email: "[name=email]", password: "[name=password]" };
  const submitSelector = auth.submit ?? "button[type=submit]";
  const waitSelector = auth.waitAfterLogin ?? null;
  const { email, password } = auth.credentials;

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    await page.goto(loginUrl, { waitUntil: "domcontentloaded", timeout: 30000 });
    await page.fill(fields.email, email);
    await page.fill(fields.password, password);
    await page.click(submitSelector);

    if (waitSelector) {
      await page.waitForSelector(waitSelector, { timeout: 15000 });
    } else {
      await page.waitForURL((url) => url.toString() !== loginUrl, { timeout: 15000 });
    }

    await fs.mkdir(path.dirname(statePath), { recursive: true });
    const state = await context.storageState();
    await fs.writeFile(statePath, JSON.stringify(state, null, 2), "utf8");
    console.log(`Logged in. Saved auth state to ${path.relative(process.cwd(), statePath)}`);
  } finally {
    await context.close();
    await browser.close();
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

function cookieEntry(name, value, parsedUrl) {
  return {
    name,
    value,
    domain: parsedUrl.hostname,
    path: "/",
    expires: -1,
    httpOnly: false,
    secure: parsedUrl.protocol === "https:",
    sameSite: "Lax",
  };
}

function localStorageEntry(origin, key, value) {
  return { origin, localStorage: [{ name: key, value }] };
}

async function writeStorageState(statePath, state) {
  await fs.mkdir(path.dirname(statePath), { recursive: true });
  await fs.writeFile(statePath, JSON.stringify(state, null, 2), "utf8");
}
