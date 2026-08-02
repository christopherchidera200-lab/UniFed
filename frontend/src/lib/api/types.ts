/**
 * Wire contract for the CloudIntel API.
 *
 * These types are a hand-maintained mirror of the Pydantic models in
 * `backend/app/schemas.py`. They are verified against the live OpenAPI document
 * by `src/lib/api/__tests__/contract.test.ts`, so drift fails CI rather than
 * surfacing as a runtime bug.
 */

export const TARGET_TYPES = ['domain', 'ip', 'email', 'username'] as const;
export type TargetType = (typeof TARGET_TYPES)[number];

export const SEVERITIES = ['info', 'low', 'medium', 'high'] as const;
export type Severity = (typeof SEVERITIES)[number];

export const COLLECTOR_STATUSES = ['ok', 'empty', 'timeout', 'error', 'skipped'] as const;
export type CollectorStatus = (typeof COLLECTOR_STATUSES)[number];

export const RISK_BANDS = ['low', 'moderate', 'elevated', 'high'] as const;
export type RiskBand = (typeof RISK_BANDS)[number];

/** One atomic, attributable fact discovered about a target. */
export interface Finding {
  collector: string;
  title: string;
  severity: Severity;
  data: Record<string, unknown>;
  /** Human-readable provenance, e.g. 'DNS (authoritative)'. */
  source: string;
  /** Why collecting this is lawful. Required by the CloudIntel legal perimeter. */
  legal_basis: string;
}

export interface CollectorResult {
  collector: string;
  status: CollectorStatus;
  duration_ms: number;
  findings: Finding[];
  error: string | null;
  cached: boolean;
}

export interface RiskScore {
  /** 0 = no signal, 100 = maximum concern. */
  score: number;
  band: RiskBand;
  rationale: string[];
}

export interface InvestigationRequest {
  target: string;
  target_type: TargetType;
  /** Subset of collectors to run. Omit or null to run all applicable. */
  collectors?: string[] | null;
}

export interface Investigation {
  investigation_id: string;
  target: string;
  target_type: TargetType;
  created_at: string;
  duration_ms: number;
  results: CollectorResult[];
  risk: RiskScore;
  findings_count: number;
}

export interface InvestigationSummary {
  investigation_id: string;
  target: string;
  target_type: TargetType;
  created_at: string;
  risk_score: number;
  findings_count: number;
}

/** Source-catalogue entry from GET /collectors. */
export interface CollectorInfo {
  name: string;
  description: string;
  supported_types: TargetType[];
  legal_basis: string;
  requires_api_key: boolean;
}

export interface HealthResponse {
  status: 'ok' | 'degraded';
  environment: string;
  version: string;
  collectors: string[];
}

/** Error envelope emitted by the backend's CloudIntelError handler. */
export interface ApiErrorBody {
  error: string;
  message: string;
}
