import type { GitHubClient } from "../github-client.js";

export const submitResult = {
  name: "submit_result",
  description: "Submit completed work for a task on the Gofer.ai marketplace. The task poster will review and approve or reject.",
  inputSchema: {
    type: "object" as const,
    properties: {
      task_number: {
        type: "number",
        description: "The issue number of the task",
      },
      summary: {
        type: "string",
        description: "Summary of the completed work and results",
      },
      urls: {
        type: "array",
        items: { type: "string" },
        description: "Links to deliverables (gists, repos, files, etc.)",
      },
    },
    required: ["task_number", "summary"],
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const taskNumber = args.task_number as number;

    await client.submitResult(
      taskNumber,
      args.summary as string,
      args.urls as string[] | undefined
    );

    return `Result submitted for task #${taskNumber}.\n\nThe task poster will review your submission and either approve ([APPROVE]) or request changes ([REJECT]).`;
  },
};
