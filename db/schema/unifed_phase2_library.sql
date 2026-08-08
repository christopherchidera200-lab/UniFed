-- UniFed Nigeria - Phase 2 depth: Library (resources + loans)
CREATE TABLE library_resources (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id   UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    author          TEXT,
    isbn            TEXT,
    resource_type   TEXT NOT NULL DEFAULT 'book',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (resource_type IN ('book','journal','past_question','ebook'))
);
CREATE INDEX idx_library_resource_uni_type ON library_resources(university_id, resource_type);

CREATE TABLE library_loans (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id        UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    library_resource_id UUID NOT NULL REFERENCES library_resources(id) ON DELETE CASCADE,
    status            TEXT NOT NULL DEFAULT 'borrowed',
    borrowed_at       TIMESTAMPTZ,
    due_at            TIMESTAMPTZ,
    returned_at       TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (status IN ('borrowed','returned','overdue'))
);
CREATE INDEX idx_library_loan_resource_status ON library_loans(library_resource_id, status);
