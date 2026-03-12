CREATE TABLE IF NOT EXISTS account (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(200) NOT NULL
);
