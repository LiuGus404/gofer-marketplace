import { Octokit } from "@octokit/rest";
import { parse as parseYaml, stringify as stringifyYaml } from "yaml";
import type { GoferTask, GoferWorker, TaskStatus } from "./types.js";
import { parseIssueBody, extractStatus, buildIssueBody } from "./parsers.js";

export class GitHubClient {
  private octokit: Octokit;
  private owner: string;
  private repo: string;

  constructor(token: string, repoFullName: string) {
    this.octokit = new Octokit({ auth: token });
    const [owner, repo] = repoFullName.split("/");
    this.owner = owner;
    this.repo = repo;
  }

  // --- Tasks (Issues) ---

  async listTasks(filters: {
    status?: TaskStatus;
    type?: string;
    budget?: string;
    urgency?: string;
    limit?: number;
  } = {}): Promise<GoferTask[]> {
    const labels = ["task"];
    if (filters.status) labels.push(`status:${filters.status}`);
    else labels.push("status:open");
    if (filters.type) labels.push(`type:${filters.type}`);
    if (filters.budget) labels.push(`budget:${filters.budget}`);
    if (filters.urgency) labels.push(`urgency:${filters.urgency}`);

    const { data: issues } = await this.octokit.issues.listForRepo({
      owner: this.owner,
      repo: this.repo,
      labels: labels.join(","),
      state: "open",
      per_page: filters.limit || 20,
      sort: "created",
      direction: "desc",
    });

    return issues.map((issue) => this.issueToTask(issue));
  }

  async searchTasks(query: string, status?: TaskStatus): Promise<GoferTask[]> {
    const qualifiers = [`repo:${this.owner}/${this.repo}`, "label:task", `"${query}" in:title,body`];
    if (status) qualifiers.push(`label:status:${status}`);

    const { data } = await this.octokit.search.issuesAndPullRequests({
      q: qualifiers.join(" "),
      per_page: 20,
      sort: "created",
      order: "desc",
    });

    return data.items.map((issue) => this.issueToTask(issue));
  }

  async getTask(taskNumber: number): Promise<GoferTask> {
    const { data: issue } = await this.octokit.issues.get({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
    });

    return this.issueToTask(issue);
  }

  async createTask(fields: {
    title: string;
    type: string;
    budget: string;
    urgency: string;
    description: string;
    deliverables: string;
    requirements?: string;
    acceptorType?: string;
    contact?: string;
  }): Promise<GoferTask> {
    const body = buildIssueBody(fields);

    const { data: issue } = await this.octokit.issues.create({
      owner: this.owner,
      repo: this.repo,
      title: `[TASK] ${fields.title}`,
      body,
      labels: ["task", "status:open"],
    });

    return this.issueToTask(issue);
  }

  async acceptTask(taskNumber: number, message?: string, isAI: boolean = false): Promise<void> {
    const commentBody = message
      ? `[ACCEPT]${isAI ? " [AI]" : ""}\n\n${message}`
      : `[ACCEPT]${isAI ? " [AI]" : ""}`;

    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body: commentBody,
    });
  }

  async startTask(taskNumber: number): Promise<void> {
    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body: "[START] Beginning work on this task.",
    });
  }

  async submitResult(taskNumber: number, summary: string, urls?: string[]): Promise<void> {
    let body = `[SUBMIT]\n\n## Result\n\n${summary}`;
    if (urls && urls.length > 0) {
      body += `\n\n## Deliverables\n\n${urls.map((u) => `- ${u}`).join("\n")}`;
    }

    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body,
    });
  }

  async commentOnTask(taskNumber: number, message: string): Promise<void> {
    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body: message,
    });
  }

  async approveTask(taskNumber: number, rating?: number, review?: string): Promise<void> {
    let body = "[APPROVE] Task accepted.";
    if (rating) {
      body += `\n\n[RATE: ${rating}/5]`;
      if (review) body += ` ${review}`;
    }

    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body,
    });
  }

  async rejectTask(taskNumber: number, reason: string): Promise<void> {
    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body: `[REJECT]: ${reason}`,
    });
  }

  async cancelTask(taskNumber: number): Promise<void> {
    await this.octokit.issues.createComment({
      owner: this.owner,
      repo: this.repo,
      issue_number: taskNumber,
      body: "[CANCEL] Task cancelled by poster.",
    });
  }

  async getMyTasks(username: string, role: "poster" | "worker"): Promise<GoferTask[]> {
    if (role === "poster") {
      const { data: issues } = await this.octokit.issues.listForRepo({
        owner: this.owner,
        repo: this.repo,
        labels: "task",
        creator: username,
        state: "all",
        per_page: 30,
        sort: "updated",
        direction: "desc",
      });
      return issues.map((issue) => this.issueToTask(issue));
    }

    // For workers, search for issues where the user has commented with [ACCEPT]
    const { data } = await this.octokit.search.issuesAndPullRequests({
      q: `repo:${this.owner}/${this.repo} label:task commenter:${username} "[ACCEPT]" in:comments`,
      per_page: 30,
      sort: "updated",
      order: "desc",
    });

    return data.items.map((issue) => this.issueToTask(issue));
  }

  // --- Workers ---

  async listWorkers(filters: {
    capability?: string;
    workerType?: string;
  } = {}): Promise<GoferWorker[]> {
    try {
      const { data } = await this.octokit.repos.getContent({
        owner: this.owner,
        repo: this.repo,
        path: "workers",
      });

      if (!Array.isArray(data)) return [];

      const workers: GoferWorker[] = [];
      for (const file of data) {
        if (!file.name.endsWith(".yml") && !file.name.endsWith(".yaml")) continue;

        const { data: fileData } = await this.octokit.repos.getContent({
          owner: this.owner,
          repo: this.repo,
          path: file.path,
        });

        if ("content" in fileData && fileData.content) {
          const content = Buffer.from(fileData.content, "base64").toString("utf-8");
          const worker = parseYaml(content) as GoferWorker;

          if (filters.capability && !worker.capabilities.includes(filters.capability)) continue;
          if (filters.workerType && worker.worker_type !== filters.workerType) continue;

          workers.push(worker);
        }
      }

      return workers;
    } catch {
      return [];
    }
  }

  async registerWorker(worker: GoferWorker): Promise<void> {
    const content = stringifyYaml(worker);
    const path = `workers/${worker.github_username}.yml`;

    let sha: string | undefined;
    try {
      const { data: existing } = await this.octokit.repos.getContent({
        owner: this.owner,
        repo: this.repo,
        path,
      });
      if ("sha" in existing) sha = existing.sha;
    } catch {
      // File doesn't exist, that's fine
    }

    await this.octokit.repos.createOrUpdateFileContents({
      owner: this.owner,
      repo: this.repo,
      path,
      message: sha
        ? `Update worker profile: ${worker.github_username}`
        : `Register worker: ${worker.github_username}`,
      content: Buffer.from(content).toString("base64"),
      ...(sha ? { sha } : {}),
    });
  }

  async getWorker(username: string): Promise<GoferWorker | null> {
    try {
      const { data } = await this.octokit.repos.getContent({
        owner: this.owner,
        repo: this.repo,
        path: `workers/${username}.yml`,
      });

      if ("content" in data && data.content) {
        const content = Buffer.from(data.content, "base64").toString("utf-8");
        return parseYaml(content) as GoferWorker;
      }
    } catch {
      return null;
    }
    return null;
  }

  // --- Authenticated user ---

  async getAuthenticatedUser(): Promise<string> {
    const { data } = await this.octokit.users.getAuthenticated();
    return data.login;
  }

  // --- Internal ---

  private issueToTask(issue: any): GoferTask {
    const labels = (issue.labels || []).map((l: any) =>
      typeof l === "string" ? { name: l } : l
    );
    const parsed = parseIssueBody(issue.body || "");
    const status = extractStatus(labels);

    return {
      number: issue.number,
      title: (issue.title || "").replace(/^\[TASK\]\s*/, ""),
      type: parsed.type,
      budget: parsed.budget,
      urgency: parsed.urgency,
      status,
      description: parsed.description,
      deliverables: parsed.deliverables,
      requirements: parsed.requirements,
      acceptorType: parsed.acceptorType,
      contact: parsed.contact,
      poster: issue.user?.login || "unknown",
      worker: null, // Would need to fetch comments to determine
      createdAt: issue.created_at,
      updatedAt: issue.updated_at,
      comments: issue.comments || 0,
      url: issue.html_url,
    };
  }
}
