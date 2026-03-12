CREATE TABLE IF NOT EXISTS tenant (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(200) NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT NOW()
);
