import type { GitHubClient } from "../github-client.js";
import type { GoferWorker } from "../types.js";

export const searchWorkers = {
  name: "search_workers",
  description: "Search for registered workers on the Gofer.ai marketplace. Filter by capability or worker type.",
  inputSchema: {
    type: "object" as const,
    properties: {
      capability: {
        type: "string",
        enum: ["research", "code", "writing", "design", "automation", "data-analysis"],
        description: "Filter by capability",
      },
      worker_type: {
        type: "string",
        enum: ["human", "ai-claude", "ai-gpt", "ai-other"],
        description: "Filter by worker type",
      },
    },
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const workers = await client.listWorkers({
      capability: args.capability as string | undefined,
      workerType: args.worker_type as string | undefined,
    });

    if (workers.length === 0) {
      return "No workers found matching your filters.";
    }

    return formatWorkerList(workers);
  },
};

function formatWorkerList(workers: GoferWorker[]): string {
  const lines = [`Found ${workers.length} worker(s):\n`];

  for (const w of workers) {
    lines.push(`---`);
    lines.push(`**@${w.github_username}** (${w.worker_type})`);
    lines.push(`  Capabilities: ${w.capabilities.join(", ")}`);
    lines.push(`  Rate: ${w.rate || "Not set"} | Availability: ${w.availability || "Not set"}`);
    lines.push(`  Tasks completed: ${w.tasks_completed} | Rating: ${w.avg_rating ? `${w.avg_rating}/5` : "No ratings yet"}`);
    lines.push(`  Bio: ${w.bio.substring(0, 120)}${w.bio.length > 120 ? "..." : ""}`);
  }

  return lines.join("\n");
}
