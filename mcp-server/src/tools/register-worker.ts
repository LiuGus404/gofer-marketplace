import type { GitHubClient } from "../github-client.js";
import type { GoferWorker, WorkerType } from "../types.js";

export const registerWorker = {
  name: "register_worker",
  description: "Register yourself or your AI agent as a worker on the Gofer.ai marketplace. This creates a worker profile in the marketplace.",
  inputSchema: {
    type: "object" as const,
    properties: {
      worker_type: {
        type: "string",
        enum: ["human", "ai-claude", "ai-gpt", "ai-other"],
        description: "Type of worker",
      },
      capabilities: {
        type: "array",
        items: {
          type: "string",
          enum: ["research", "code", "writing", "design", "automation", "data-analysis"],
        },
        description: "List of capabilities",
      },
      bio: {
        type: "string",
        description: "Description of skills, experience, or AI specialization",
      },
      rate: {
        type: "string",
        description: "Pricing (e.g., '$15/hr', '$10/task', 'Free for open-source')",
      },
      availability: {
        type: "string",
        description: "Availability (e.g., '24/7', 'Weekdays 9-5 EST')",
      },
      portfolio: {
        type: "array",
        items: { type: "string" },
        description: "Links to past work (GitHub repos, websites, demos, etc.)",
      },
    },
    required: ["worker_type", "capabilities", "bio"],
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const username = await client.getAuthenticatedUser();

    const worker: GoferWorker = {
      github_username: username,
      worker_type: args.worker_type as WorkerType,
      capabilities: args.capabilities as string[],
      bio: args.bio as string,
      rate: (args.rate as string) || null,
      availability: (args.availability as string) || null,
      portfolio: (args.portfolio as string[]) || null,
      registered_at: new Date().toISOString().split("T")[0],
      tasks_completed: 0,
      avg_rating: null,
      reputation_score: 0,
      status: "active",
    };

    // Check if already registered
    const existing = await client.getWorker(username);
    if (existing) {
      // Preserve stats from existing profile
      worker.tasks_completed = existing.tasks_completed;
      worker.avg_rating = existing.avg_rating;
      worker.reputation_score = existing.reputation_score;
      worker.registered_at = existing.registered_at;
    }

    await client.registerWorker(worker);

    return existing
      ? `Worker profile updated for @${username}.\n\nCapabilities: ${worker.capabilities.join(", ")}\nRate: ${worker.rate || "Not set"}\nAvailability: ${worker.availability || "Not set"}`
      : `Welcome to Gofer.ai, @${username}!\n\nYou are now registered as a ${worker.worker_type} worker.\nCapabilities: ${worker.capabilities.join(", ")}\nRate: ${worker.rate || "Not set"}\nAvailability: ${worker.availability || "Not set"}\n\nUse browse_tasks to find available work.`;
  },
};
