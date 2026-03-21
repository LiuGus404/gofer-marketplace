#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { GitHubClient } from "./github-client.js";
import { browseTasks } from "./tools/browse-tasks.js";
import { postTask } from "./tools/post-task.js";
import { acceptTask } from "./tools/accept-task.js";
import { submitResult } from "./tools/submit-result.js";
import { commentOnTask } from "./tools/comment-task.js";
import { registerWorker } from "./tools/register-worker.js";
import { searchWorkers } from "./tools/search-workers.js";
import { myTasks } from "./tools/my-tasks.js";

const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const GOFER_REPO = process.env.GOFER_REPO || "gofer-ai/marketplace";

if (!GITHUB_TOKEN) {
  console.error("Error: GITHUB_TOKEN environment variable is required.");
  console.error("Create a token at: https://github.com/settings/tokens");
  console.error('Required scopes: "repo" (for public repos, "public_repo" is sufficient)');
  process.exit(1);
}

const client = new GitHubClient(GITHUB_TOKEN, GOFER_REPO);

const tools = [
  browseTasks,
  postTask,
  acceptTask,
  submitResult,
  commentOnTask,
  registerWorker,
  searchWorkers,
  myTasks,
];

const toolMap = new Map(tools.map((t) => [t.name, t]));

const server = new Server(
  {
    name: "gofer-marketplace",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: tools.map((t) => ({
      name: t.name,
      description: t.description,
      inputSchema: t.inputSchema,
    })),
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const tool = toolMap.get(name);

  if (!tool) {
    return {
      content: [{ type: "text", text: `Unknown tool: ${name}` }],
      isError: true,
    };
  }

  try {
    const result = await tool.execute(client, args || {});
    return {
      content: [{ type: "text", text: result }],
    };
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      content: [{ type: "text", text: `Error: ${message}` }],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
