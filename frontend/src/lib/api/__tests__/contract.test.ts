/**
 * FRONTEND/BACKEND CONTRACT TEST
 *
 * The TypeScript interfaces in `types.ts` are hand-written mirrors of the
 * backend's Pydantic models. Hand-written mirrors rot. This suite pins them to
 * a snapshot of the real OpenAPI document generated from `app.main:app`, so any
 * backend schema change that the frontend has not absorbed fails here instead of
 * shipping as a runtime `undefined`.
 *
 * Regenerate the snapshot after an intentional backend change:
 *   cd backend && python -c "import json;from app.main import app;\
 *     print(json.dumps(app.openapi(), indent=2, sort_keys=True))" \
 *     > ../frontend/src/lib/api/__tests__/openapi.snapshot.json
 */
import { describe, expect, it } from 'vitest';
import spec from './openapi.snapshot.json';
import { COLLECTOR_STATUSES, RISK_BANDS, SEVERITIES, TARGET_TYPES } from '../types';

interface SchemaObject {
  properties?: Record<string, unknown>;
  required?: string[];
  enum?: string[];
}

const schemas = (spec as { components: { schemas: Record<string, SchemaObject> } }).components
  .schemas;

/** Property names the frontend expects on a given backend schema. */
const EXPECTED_PROPERTIES: Record<string, string[]> = {
  Finding: ['collector', 'title', 'severity', 'data', 'source', 'legal_basis'],
  CollectorResult: ['collector', 'status', 'duration_ms', 'findings', 'error', 'cached'],
  RiskScore: ['score', 'band', 'rationale'],
  InvestigationRequest: ['target', 'target_type', 'collectors'],
  InvestigationResponse: [
    'investigation_id',
    'target',
    'target_type',
    'created_at',
    'duration_ms',
    'results',
    'risk',
    'findings_count',
  ],
  InvestigationSummary: [
    'investigation_id',
    'target',
    'target_type',
    'created_at',
    'risk_score',
    'findings_count',
  ],
  HealthResponse: ['status', 'environment', 'version', 'collectors'],
};

describe('OpenAPI schema coverage', () => {
  it.each(Object.keys(EXPECTED_PROPERTIES))('%s exists in the backend spec', (name) => {
    expect(schemas[name]).toBeDefined();
  });

  it.each(Object.entries(EXPECTED_PROPERTIES))(
    '%s exposes exactly the properties the frontend models',
    (name, expectedProps) => {
      const actual = Object.keys(schemas[name]?.properties ?? {}).sort();
      expect(actual).toEqual([...expectedProps].sort());
    },
  );
});

describe('Enum parity', () => {
  it('TargetType matches the backend', () => {
    expect([...TARGET_TYPES].sort()).toEqual([...(schemas.TargetType?.enum ?? [])].sort());
  });

  it('Severity matches the backend', () => {
    expect([...SEVERITIES].sort()).toEqual([...(schemas.Severity?.enum ?? [])].sort());
  });

  it('CollectorStatus matches the backend', () => {
    expect([...COLLECTOR_STATUSES].sort()).toEqual(
      [...(schemas.CollectorStatus?.enum ?? [])].sort(),
    );
  });

  it('RiskBand matches the literal union on RiskScore.band', () => {
    // `band` is a Literal[...] in Pydantic, which serialises to an inline enum
    // on the property rather than a named component schema.
    const band = schemas.RiskScore?.properties?.band as { enum?: string[] } | undefined;
    expect([...RISK_BANDS].sort()).toEqual([...(band?.enum ?? [])].sort());
  });
});

describe('Endpoint coverage', () => {
  const paths = (spec as { paths: Record<string, Record<string, unknown>> }).paths;

  it.each([
    ['/health', 'get'],
    ['/collectors', 'get'],
    ['/investigations', 'post'],
    ['/investigations', 'get'],
    ['/investigations/{investigation_id}', 'get'],
  ])('%s supports %s, matching the api client', (path, method) => {
    expect(paths[path]?.[method]).toBeDefined();
  });
});

describe('Legal perimeter', () => {
  it('keeps legal_basis a REQUIRED field on every Finding', () => {
    // This is the architectural guarantee that makes CloudIntel defensible:
    // a source that cannot state why it is lawful cannot produce a finding.
    expect(schemas.Finding?.required).toContain('legal_basis');
    expect(schemas.Finding?.required).toContain('source');
  });
});
