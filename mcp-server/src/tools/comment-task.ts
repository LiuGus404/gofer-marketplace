import type { GitHubClient } from "../github-client.js";

export const commentOnTask = {
  name: "comment_on_task",
  description: "Add a comment to a task on the Gofer.ai marketplace. Use this to ask questions, discuss details, or communicate with the task poster/worker.",
  inputSchema: {
    type: "object" as const,
    properties: {
      task_number: {
        type: "number",
        description: "The issue number of the task",
      },
      message: {
        type: "string",
        description: "Your comment message",
      },
    },
    required: ["task_number", "message"],
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const taskNumber = args.task_number as number;
    await client.commentOnTask(taskNumber, args.message as string);
    return `Comment posted on task #${taskNumber}.`;
  },
};
