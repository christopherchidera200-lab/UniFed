-- UniFed Nigeria - Phase 2: Transcript Issuance audit log
-- Records each official transcript issuance (token hash) for verifiability.

CREATE TABLE transcript_issuances (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    token_hash  TEXT NOT NULL UNIQUE,         -- SHA-256 of the signed transcript
    issued_to   TEXT NOT NULL,                 -- verifier / requester identity
    purpose     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_transcript_issuance_student ON transcript_issuances(student_id);
