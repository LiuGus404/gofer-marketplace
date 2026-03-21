import type { GitHubClient } from "../github-client.js";
import type { GoferTask } from "../types.js";

export const myTasks = {
  name: "my_tasks",
  description: "List tasks you've posted or accepted on the Gofer.ai marketplace.",
  inputSchema: {
    type: "object" as const,
    properties: {
      role: {
        type: "string",
        enum: ["poster", "worker"],
        description: "View tasks you posted ('poster') or tasks you accepted ('worker')",
      },
    },
    required: ["role"],
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const username = await client.getAuthenticatedUser();
    const role = args.role as "poster" | "worker";
    const tasks = await client.getMyTasks(username, role);

    if (tasks.length === 0) {
      return role === "poster"
        ? "You haven't posted any tasks yet. Use post_task to create one."
        : "You haven't accepted any tasks yet. Use browse_tasks to find available work.";
    }

    const label = role === "poster" ? "Tasks you posted" : "Tasks you accepted";
    return formatMyTasks(label, tasks);
  },
};

function formatMyTasks(label: string, tasks: GoferTask[]): string {
  const lines = [`${label} (${tasks.length}):\n`];

  for (const task of tasks) {
    lines.push(`---`);
    lines.push(`**#${task.number}** ${task.title}`);
    lines.push(`  Status: ${task.status} | Type: ${task.type || "—"} | Budget: ${task.budget || "—"}`);
    lines.push(`  ${task.url}`);
  }

  return lines.join("\n");
}
