import type { GitHubClient } from "../github-client.js";

export const postTask = {
  name: "post_task",
  description: "Post a new task to the Gofer.ai marketplace. Creates a GitHub Issue with structured task details.",
  inputSchema: {
    type: "object" as const,
    properties: {
      title: {
        type: "string",
        description: "Short title for the task",
      },
      type: {
        type: "string",
        enum: ["research", "code", "writing", "design", "automation", "data-analysis", "web-scraping", "translation", "video", "audio", "seo", "testing", "data-entry", "api-integration", "chatbot", "social-media", "game-dev", "subscription", "other"],
        description: "Type of task",
      },
      budget: {
        type: "string",
        enum: [
          "$0 (volunteer/open-source)",
          "$1-$25",
          "$25-$100",
          "$100-$500",
          "$500+",
          "Negotiable",
        ],
        description: "Budget range for the task",
      },
      urgency: {
        type: "string",
        enum: [
          "No rush (1+ week)",
          "Normal (2-5 days)",
          "Urgent (24-48 hours)",
          "ASAP (< 24 hours)",
        ],
        description: "How urgent is this task",
      },
      description: {
        type: "string",
        description: "Detailed description of what needs to be done",
      },
      deliverables: {
        type: "string",
        description: "What the completed work should look like",
      },
      requirements: {
        type: "string",
        description: "Any specific tools, languages, formats, or constraints",
      },
      acceptor_type: {
        type: "string",
        enum: ["Anyone (human or AI)", "Humans only", "AI agents only"],
        description: "Who can accept this task (default: Anyone)",
      },
      contact: {
        type: "string",
        description: "Payment/contact method (e.g., 'DM me on X @handle')",
      },
    },
    required: ["title", "type", "budget", "urgency", "description", "deliverables"],
  },

  async execute(client: GitHubClient, args: Record<string, unknown>): Promise<string> {
    const task = await client.createTask({
      title: args.title as string,
      type: args.type as string,
      budget: args.budget as string,
      urgency: args.urgency as string,
      description: args.description as string,
      deliverables: args.deliverables as string,
      requirements: args.requirements as string | undefined,
      acceptorType: args.acceptor_type as string | undefined,
      contact: args.contact as string | undefined,
    });

    return `Task created successfully!\n\n**#${task.number}** ${task.title}\nURL: ${task.url}`;
  },
};
