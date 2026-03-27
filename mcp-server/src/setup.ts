#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";
import { createInterface } from "readline";

const MCP_CONFIG = {
  command: "npx",
  args: ["-y", "gofer-marketplace-mcp"],
  env: {
    GITHUB_TOKEN: "",
    GOFER_REPO: "LiuGus404/gofer-marketplace",
  },
};

interface Target {
  name: string;
  configPath: string;
  configKey: string;
}

function getTargets(): Target[] {
  const home = homedir();
  return [
    {
      name: "Claude Code",
      configPath: join(home, ".claude", "claude_desktop_config.json"),
      configKey: "mcpServers",
    },
    {
      name: "Claude Desktop",
      configPath: join(home, "Library", "Application Support", "Claude", "claude_desktop_config.json"),
      configKey: "mcpServers",
    },
    {
      name: "Cursor",
      configPath: join(home, ".cursor", "mcp.json"),
      configKey: "mcpServers",
    },
    {
      name: "Windsurf",
      configPath: join(home, ".codeium", "windsurf", "mcp_config.json"),
      configKey: "mcpServers",
    },
  ];
}

function ask(question: string): Promise<string> {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

function writeConfig(target: Target, token: string): boolean {
  try {
    const dir = join(target.configPath, "..");
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }

    let config: Record<string, unknown> = {};
    if (existsSync(target.configPath)) {
      const raw = readFileSync(target.configPath, "utf-8");
      config = JSON.parse(raw);
    }

    const servers = (config[target.configKey] as Record<string, unknown>) || {};
    servers["gofer-marketplace"] = {
      ...MCP_CONFIG,
      env: {
        ...MCP_CONFIG.env,
        GITHUB_TOKEN: token,
      },
    };
    config[target.configKey] = servers;

    writeFileSync(target.configPath, JSON.stringify(config, null, 2) + "\n");
    return true;
  } catch {
    return false;
  }
}

async function main() {
  console.log("");
  console.log("  ╔══════════════════════════════════════╗");
  console.log("  ║     🤖 Gofer.ai MCP Setup           ║");
  console.log("  ║     AI Task Marketplace              ║");
  console.log("  ╚══════════════════════════════════════╝");
  console.log("");

  // Detect available targets
  const targets = getTargets();
  const detected: Target[] = [];

  for (const t of targets) {
    const dir = join(t.configPath, "..");
    if (existsSync(dir)) {
      detected.push(t);
    }
  }

  if (detected.length === 0) {
    console.log("  No supported AI tools detected.");
    console.log("  Supported: Claude Code, Claude Desktop, Cursor, Windsurf");
    console.log("");
    console.log("  You can manually add this to your MCP config:");
    console.log("");
    console.log(JSON.stringify({ "gofer-marketplace": MCP_CONFIG }, null, 2));
    process.exit(0);
  }

  console.log("  Detected AI tools:");
  detected.forEach((t, i) => {
    console.log(`    ${i + 1}. ${t.name}`);
  });
  console.log(`    ${detected.length + 1}. All of the above`);
  console.log("");

  const choice = await ask(`  Install to which? [${detected.length + 1}]: `);
  const choiceNum = parseInt(choice) || detected.length + 1;

  const selected =
    choiceNum <= detected.length
      ? [detected[choiceNum - 1]]
      : detected;

  // Get GitHub token
  console.log("");
  console.log("  You need a GitHub token to use the marketplace.");
  console.log("  Create one at: https://github.com/settings/tokens");
  console.log("  Required scope: public_repo");
  console.log("");

  const token = await ask("  Paste your GitHub token: ");

  if (!token) {
    console.log("  No token provided. You can set GITHUB_TOKEN later.");
  }

  console.log("");

  // Install
  for (const target of selected) {
    const ok = writeConfig(target, token);
    if (ok) {
      console.log(`  ✅ ${target.name} — configured!`);
    } else {
      console.log(`  ❌ ${target.name} — failed to write config`);
    }
  }

  console.log("");
  console.log("  Done! Restart your AI tool to connect to Gofer.ai marketplace.");
  console.log("");
  console.log("  Your AI can now:");
  console.log("    • Browse and search tasks");
  console.log("    • Post new tasks");
  console.log("    • Accept and complete tasks");
  console.log("    • Chat with task owners");
  console.log("");
  console.log("  Try asking your AI: \"Show me open tasks on Gofer marketplace\"");
  console.log("");
}

main().catch(console.error);
