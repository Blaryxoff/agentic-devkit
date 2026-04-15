import fs from "node:fs/promises";
import path from "node:path";
import readline from "node:readline/promises";
import { chromium } from "playwright";

const STATE_TTL_MS = 30 * 60 * 1000;

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

async function isStateFresh(statePath) {
  try {
    const stat = await fs.stat(statePath);
    return Date.now() - stat.mtimeMs < STATE_TTL_MS;
  } catch {
    return false;
  }
}

export async function ensureStorageState(auth, baseUrl, statePath) {
  if (await isStateFresh(statePath)) {
    return statePath;
  }

  const resolved = await promptCredentials(auth);
  await performLogin(resolved, baseUrl, statePath);
  return statePath;
}

export async function promptCredentials(auth) {
  const email = auth.credentials?.email;
  const password = auth.credentials?.password;

  if (email && password) {
    return auth;
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stderr,
  });

  try {
    const promptEmail = email || await rl.question("Email: ");
    const promptPassword = password || await rl.question("Password: ");

    return {
      ...auth,
      credentials: {
        ...auth.credentials,
        email: promptEmail,
        password: promptPassword,
      },
    };
  } finally {
    rl.close();
  }
}

export async function performLogin(auth, baseUrl, statePath) {
  const loginUrl = new URL(auth.loginUrl, baseUrl).toString();
  const fields = auth.fields ?? {
    email: "[name=email]",
    password: "[name=password]",
  };
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
