-- UniFed Nigeria - Phase 2 depth: Notifications
CREATE TABLE notification_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    user_id       UUID REFERENCES identity_users(id) ON DELETE CASCADE,
    category      TEXT NOT NULL DEFAULT 'system',
    channel       TEXT NOT NULL DEFAULT 'in_app',
    title         TEXT NOT NULL,
    body          TEXT,
    status        TEXT NOT NULL DEFAULT 'unread',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (category IN ('academic','career','system','siwes','library')),
    CHECK (channel IN ('in_app','email','sms','push')),
    CHECK (status IN ('unread','read','archived'))
);
CREATE INDEX idx_notification_user_status ON notification_items(user_id, status);
