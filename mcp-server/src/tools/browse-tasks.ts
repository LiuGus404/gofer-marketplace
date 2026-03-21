import type { GitHubClient } from "../github-client.js";
import type { GoferTask, TaskStatus } from "../types.js";

export const browseTasks = {
  name: "browse_tasks",
  description: "Browse open tasks on the Gofer.ai marketplace. Returns a list of available tasks with optional filters.",
  inputSchema: {
    type: "object" as const,
    properties: {
      type: {
        type: "string",
        enum: ["research", "code", "writing", "design", "automation", "data-analysis", "web-scraping", "translation", "video", "audio", "seo", "testing", "data-entry", "api-integration", "chatbot", "social-media", "game-dev", "subscription", "other"],
        description: "Filter by task type",
      },
      budget: {
        type: "string",
        enum: ["free", "low", "mid", "high", "premium", "negotiable"],
        description: "Filter by budget range",
      },
      urgency: {
        type: "string",
        enum: ["low", "normal", "urgent", "asap"],
        description: "Filter by urgency",
      },
      status: {
        type: "string",
        enum: ["open", "claimed", "in-progress", "submitted", "completed", "disputed", "cancelled"],
        description: "Filter by status (default: open)",
      },
      limit: {
        type: "number",
        description: "Max number of tasks to return (default: 20)",
      },
    },
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const tasks = await client.listTasks({
      status: (args.status as TaskStatus) || undefined,
      type: args.type as string,
      budget: args.budget as string,
      urgency: args.urgency as string,
      limit: args.limit as number,
    });

    if (tasks.length === 0) {
      return "No tasks found matching your filters.";
    }

    return formatTaskList(tasks);
  },
};

function formatTaskList(tasks: GoferTask[]): string {
  const lines = [`Found ${tasks.length} task(s):\n`];

  for (const task of tasks) {
    lines.push(`---`);
    lines.push(`**#${task.number}** ${task.title}`);
    lines.push(`  Status: ${task.status} | Type: ${task.type || "—"} | Budget: ${task.budget || "—"} | Urgency: ${task.urgency || "—"}`);
    lines.push(`  Posted by: @${task.poster} | Comments: ${task.comments}`);
    lines.push(`  ${task.url}`);
  }

  return lines.join("\n");
}
