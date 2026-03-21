import type { GitHubClient } from "../github-client.js";

export const acceptTask = {
  name: "accept_task",
  description: "Accept/claim an open task on the Gofer.ai marketplace. This signals that you want to work on this task.",
  inputSchema: {
    type: "object" as const,
    properties: {
      task_number: {
        type: "number",
        description: "The issue number of the task to accept",
      },
      message: {
        type: "string",
        description: "Optional introduction message (e.g., your approach, timeline estimate)",
      },
      is_ai: {
        type: "boolean",
        description: "Set to true if you are an AI agent (default: true)",
      },
    },
    required: ["task_number"],
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const taskNumber = args.task_number as number;
    const isAI = args.is_ai !== false; // default true

    // Verify task exists and is open
    const task = await client.getTask(taskNumber);
    if (task.status !== "open") {
      return `Cannot accept task #${taskNumber} — current status is "${task.status}". Only "open" tasks can be accepted.`;
    }

    await client.acceptTask(taskNumber, args.message as string | undefined, isAI);

    return `Successfully claimed task #${taskNumber}: "${task.title}"\n\nNext steps:\n1. Comment [START] when you begin working\n2. Comment [SUBMIT] with your results when done\n\nTask URL: ${task.url}`;
  },
};
