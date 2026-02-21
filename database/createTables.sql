DROP TRIGGER IF EXISTS trg_order_users_in_chats ON chats;

DROP TRIGGER IF EXISTS trg_order_users_in_matches ON matches;

DROP FUNCTION IF EXISTS order_users_in_pair ();

DROP TABLE IF EXISTS "matches" CASCADE;

DROP TABLE IF EXISTS opinions CASCADE;

DROP TABLE IF EXISTS skips CASCADE;

DROP TABLE IF EXISTS messages CASCADE;

DROP TABLE IF EXISTS chats CASCADE;

DROP TABLE IF EXISTS users CASCADE;

Drop Table IF EXISTS refresh_tokens CASCADE;

DROP TABLE IF EXISTS device_tokens CASCADE;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    gender VARCHAR(255),
    birthday DATE,
    profile_url VARCHAR(255),
    images_url VARCHAR(255) [],
    bio VARCHAR(500),
    country VARCHAR(2),
    onboarded BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    email_verification_passcode VARCHAR(6),
    email_passcode_created_at TIMESTAMPTZ
);

CREATE TABLE device_tokens (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id) on delete cascade,
    device_token VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    UNIQUE (user_id, device_id)
);

CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY, -- unique identifier
    user_id INT NOT NULL REFERENCES users (id) on delete cascade,
    token VARCHAR(255) NOT NULL UNIQUE, -- refresh token
    expires_at TIMESTAMP NOT NULL -- token expiration
);

CREATE TABLE skips (
    id SERIAL PRIMARY KEY,
    skipped int not null REFERENCES users (id) on delete cascade,
    skipper int not null REFERENCES users (id) on delete cascade,
    CONSTRAINT unique_skip UNIQUE (skipped, skipper),
    check (skipped <> skipper)
);

CREATE TABLE chats (
    id PRIMARY KEY,
    user1_id INT NOT NULL REFERENCES users (id),
    user2_id INT NOT NULL REFERENCES users (id),
    CHECK (user1_id <> user2_id)
);

CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    chat_id INT NOT NULL REFERENCES chats (id) on delete cascade,
    sender_id INT NOT NULL REFERENCES users (id),
    receiver_id INT NOT NULL REFERENCES users (id),
    content VARCHAR(500) NOT NULL,
    time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE opinions (
    id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES users (id) on delete CASCADE,
    receiver_id INT NOT NULL REFERENCES users (id) on delete CASCADE,
    opinion VARCHAR(500) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (sender_id <> receiver_id),
    UNIQUE (sender_id, receiver_id)
);

CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    user1_id INT NOT NULL REFERENCES users (id),
    user2_id INT NOT NULL REFERENCES users (id),
    CHECK (user1_id <> user2_id)
);


CREATE INDEX idx_chats_user1 ON chats (user1_id);

CREATE INDEX idx_chats_user2 ON chats (user2_id);

CREATE INDEX idx_messages_chat ON messages (chat_id);

CREATE INDEX idx_messages_sender ON messages (sender_id);

CREATE INDEX idx_messages_time ON messages (time);

CREATE INDEX idx_opinions_sender ON opinions (sender_id);

CREATE INDEX idx_opinions_receiver ON opinions (receiver_id);

CREATE INDEX idx_matches_user1 ON matches (user1_id);

CREATE INDEX idx_matches_user2 ON matches (user2_id);

CREATE UNIQUE INDEX unique_chat_users ON chats (
    LEAST(user1_id, user2_id),
    GREATEST(user1_id, user2_id)
);

CREATE UNIQUE INDEX unique_match_users ON matches (
    LEAST(user1_id, user2_id),
    GREATEST(user1_id, user2_id)
);
