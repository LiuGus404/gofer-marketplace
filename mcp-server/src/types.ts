export type TaskType =
  | "research" | "code" | "writing" | "design" | "automation" | "data-analysis"
  | "web-scraping" | "translation" | "video" | "audio" | "seo" | "testing"
  | "data-entry" | "api-integration" | "chatbot" | "social-media"
  | "game-dev" | "subscription" | "other";

export type TaskStatus = "open" | "claimed" | "in-progress" | "submitted" | "completed" | "disputed" | "cancelled";

export type BudgetRange = "free" | "low" | "mid" | "high" | "premium" | "negotiable";

export type Urgency = "low" | "normal" | "urgent" | "asap";

export type AcceptorType = "anyone" | "human-only" | "ai-only";

export type WorkerType = "human" | "ai-claude" | "ai-gpt" | "ai-other";

export interface GoferTask {
  number: number;
  title: string;
  type: TaskType | null;
  budget: BudgetRange | null;
  urgency: Urgency | null;
  status: TaskStatus;
  description: string;
  deliverables: string;
  requirements: string | null;
  acceptorType: AcceptorType | null;
  contact: string | null;
  poster: string;
  worker: string | null;
  createdAt: string;
  updatedAt: string;
  comments: number;
  url: string;
}

export interface GoferWorker {
  github_username: string;
  worker_type: WorkerType;
  capabilities: string[];
  bio: string;
  rate: string | null;
  availability: string | null;
  registered_at: string;
  tasks_completed: number;
  avg_rating: number | null;
  reputation_score: number;
  status: "active" | "inactive";
}

// Maps for converting between display values and label values
export const BUDGET_DISPLAY_TO_LABEL: Record<string, BudgetRange> = {
  "$0 (volunteer/open-source)": "free",
  "$1-$25": "low",
  "$25-$100": "mid",
  "$100-$500": "high",
  "$500+": "premium",
  "Negotiable": "negotiable",
};

export const BUDGET_LABEL_TO_DISPLAY: Record<BudgetRange, string> = {
  free: "$0 (volunteer/open-source)",
  low: "$1-$25",
  mid: "$25-$100",
  high: "$100-$500",
  premium: "$500+",
  negotiable: "Negotiable",
};

export const URGENCY_DISPLAY_TO_LABEL: Record<string, Urgency> = {
  "No rush (1+ week)": "low",
  "Normal (2-5 days)": "normal",
  "Urgent (24-48 hours)": "urgent",
  "ASAP (< 24 hours)": "asap",
};

export const URGENCY_LABEL_TO_DISPLAY: Record<Urgency, string> = {
  low: "No rush (1+ week)",
  normal: "Normal (2-5 days)",
  urgent: "Urgent (24-48 hours)",
  asap: "ASAP (< 24 hours)",
};

export const ACCEPT_DISPLAY_TO_LABEL: Record<string, AcceptorType> = {
  "Anyone (human or AI)": "anyone",
  "Humans only": "human-only",
  "AI agents only": "ai-only",
};
