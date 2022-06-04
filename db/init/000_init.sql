CREATE TABLE IF NOT EXISTS users
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    /* This will be the id generated by firebase. */
    firebase_id TEXT NOT NULL,
    /* Username and avatar can be null. Defaults will be used. There is
     * no general requirement for the user to set these, but they must be
     * set before the user can add friends. */
    username TEXT,
    /* Reference to the id of the image on external storage provider. */
    avatar_reference_id TEXT,
    invited_by BIGINT REFERENCES users(id),
    /* UTC timestamp. */
    created_on timestamp
);
CREATE UNIQUE INDEX users_firebase_id on users(firebase_id);

/*
 * This is not a simmetric relationship. Friends must be added in
 * both directions.
 */
CREATE TABLE IF NOT EXISTS friends
(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    friend_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL
);
CREATE INDEX friends_user on friends(user_id);

CREATE TABLE IF NOT EXISTS account_invites (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    nonce TEXT NOT NULL,
    inviter BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    invitee_email TEXT NOT NULL,
    /* Timestamp the invite was sent at, UTC. */
    created timestamp NOT NULL DEFAULT now(),
    duration INTERVAL NOT NULL,
    used BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX account_invites_inviter on account_invites(inviter);
CREATE UNIQUE INDEX account_invites_nonce on account_invites(nonce);

CREATE TABLE IF NOT EXISTS tags
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    tag TEXT NOT NULL
);
CREATE UNIQUE INDEX tags_tag on tags(tag);

CREATE TABLE IF NOT EXISTS categories
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    category TEXT NOT NULL
);
CREATE UNIQUE INDEX categories_category on categories(category);

CREATE TABLE IF NOT EXISTS content_warnings
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    warning TEXT NOT NULL
);
CREATE UNIQUE INDEX content_warnings_warning on content_warnings(warning);

CREATE TABLE IF NOT EXISTS realms
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    /* The realm's UUID. Used in backend requests. */
    string_id TEXT NOT NULL,
    /* Textual id of the realm, e.g. "twisted-minds", "my-cool-space". Used as part of the URL. */
    slug TEXT NOT NULL
);
CREATE UNIQUE INDEX realms_string_id on realms(string_id);
CREATE UNIQUE INDEX realms_slug on realms(slug);

CREATE TABLE IF NOT EXISTS boards
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    /* The board's UUID. Used in backend requests. */
    string_id TEXT NOT NULL,
    /* Textual id of the board, e.g. "main", "anime", "memes". Used as part of the URL. */
    slug TEXT NOT NULL,
    tagline TEXT NOT NULL,
    /* Reference to the id of the image on external storage provider. */
    avatar_reference_id TEXT,
    parent_realm_id BIGINT REFERENCES realms(id) ON DELETE RESTRICT NOT NULL,
    settings JSONB NOT NULL
);
CREATE UNIQUE INDEX boards_string_id on boards(string_id);
CREATE INDEX boards_slug on boards(slug);

CREATE TABLE IF NOT EXISTS board_tags
(
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL,
    tag_id BIGINT REFERENCES tags(id) ON DELETE RESTRICT NOT NULL
);

CREATE TABLE IF NOT EXISTS tag_deny_list
(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    tag_id BIGINT REFERENCES tags(id) ON DELETE RESTRICT NOT NULL,
    /* If not null the tag is deny-listed only on the given board. */
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT
);
CREATE INDEX tag_denly_list_user_id on tag_deny_list(user_id);

CREATE TABLE IF NOT EXISTS board_watchers (
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL,
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    /* UTC timestamp. */
    last_access timestamp NOT NULL DEFAULT now(),
    notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX board_watchers_board on board_watchers(board_id);
CREATE INDEX board_watchers_user_id on board_watchers(user_id);

CREATE TABLE IF NOT EXISTS collections
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    string_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content_description TEXT NOT NULL,
    /**
     * Whisper Tags are textual tags that do not get indicized but act as an extra
     * space for comments.
     */
    whisper_tags TEXT[]
);
CREATE UNIQUE INDEX collections_string_id on collections(string_id);

CREATE TABLE IF NOT EXISTS collection_tags (
    collection_id BIGINT REFERENCES collections(id) ON DELETE RESTRICT NOT NULL,
    tag_id BIGINT REFERENCES tags(id) ON DELETE RESTRICT NOT NULL
);

CREATE TYPE view_types AS ENUM ('thread', 'gallery', 'timeline');
CREATE TABLE IF NOT EXISTS threads
(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    string_id TEXT NOT NULL,
    parent_board BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL,
    options JSONB NOT NULL DEFAULT '{}'::jsonb
    /* TODO: decide what to do with threads with deleted posts */
);
CREATE INDEX threads_string_id on threads(string_id);

CREATE TABLE IF NOT EXISTS thread_watchers (
    thread_id BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL,
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    /* UTC timestamp. */
    last_access timestamp NOT NULL DEFAULT now(),
    notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX thread_watchers_thread_id on thread_watchers(thread_id);
CREATE INDEX thread_watchers_user_id on thread_watchers(user_id);

/* TODO: decide whether to switch this to who the user is visible to rather than hidden from. */
CREATE TYPE anonymity_type AS ENUM ('everyone', 'strangers');
CREATE TYPE post_type AS ENUM ('text');

CREATE TABLE IF NOT EXISTS posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    string_id TEXT NOT NULL,
    parent_thread BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL,
    parent_post BIGINT REFERENCES posts(id) ON DELETE RESTRICT,
    author BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    /* UTC timestamp. */
    created timestamp NOT NULL DEFAULT now(),
    content TEXT NOT NULL,
    type post_type NOT NULL,
    /**
     * Whisper Tags are textual tags that do not get indicized but act as an extra
     * space for comments.
     */
    whisper_tags TEXT[],
    options JSONB NOT NULL DEFAULT '{}'::jsonb,
    /* Mark deleted rather than actually delete for moderation purposes. */
    is_deleted BOOLEAN DEFAULT false,
    anonymity_type anonymity_type NOT NULL
);
CREATE INDEX posts_string_id on posts(string_id);
CREATE INDEX posts_parent_thread on posts(parent_thread);
CREATE INDEX posts_author on posts(author);

CREATE TABLE IF NOT EXISTS post_tags (
    post_id BIGINT REFERENCES posts(id) ON DELETE RESTRICT NOT NULL,
    tag_id BIGINT REFERENCES tags(id) ON DELETE RESTRICT NOT NULL
);
CREATE INDEX post_tags_post_id on post_tags(post_id);
CREATE INDEX post_tags_tag_id on post_tags(tag_id);

CREATE TABLE IF NOT EXISTS post_categories (
    post_id BIGINT REFERENCES posts(id) ON DELETE RESTRICT NOT NULL,
    category_id BIGINT REFERENCES categories(id) ON DELETE RESTRICT NOT NULL
);
CREATE INDEX post_categories_post_id on post_categories(post_id);
CREATE INDEX post_categories_category_id on post_categories(category_id);

CREATE TABLE IF NOT EXISTS post_warnings (
    post_id BIGINT REFERENCES posts(id) ON DELETE RESTRICT NOT NULL,
    warning_id BIGINT REFERENCES content_warnings(id) ON DELETE RESTRICT NOT NULL
);
CREATE INDEX post_warnings_post_id on post_warnings(post_id);
CREATE INDEX post_warnings_category_id on post_warnings(warning_id);

CREATE TABLE IF NOT EXISTS post_audits (
    post_id BIGINT REFERENCES posts(id) ON DELETE RESTRICT NOT NULL,
    deleted_by BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    /* UTC timestamp. */
    deleted_time timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS comments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    string_id TEXT NOT NULL,
    parent_thread BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL,
    parent_post BIGINT REFERENCES posts(id) ON DELETE RESTRICT NOT NULL,
    parent_comment BIGINT REFERENCES comments(id) ON DELETE RESTRICT,
    chain_parent_comment BIGINT REFERENCES comments(id) ON DELETE RESTRICT,
    author BIGINT REFERENCES users(id) ON DELETE RESTRICT,
    /* UTC timestamp. */
    created timestamp NOT NULL DEFAULT now(),
    content TEXT NOT NULL,
    /* Reference to the id of the image on external storage provider. */
    image_reference_id TEXT,
    /* Mark deleted rather than actually delete for moderation purposes. */
    is_deleted BOOLEAN DEFAULT false,
    anonymity_type anonymity_type NOT NULL
);
CREATE INDEX comments_string_id on comments(string_id);
CREATE INDEX comments_parent_thread on comments(parent_thread);
CREATE INDEX comments_parent_post on comments(parent_post);
CREATE INDEX comments_author on comments(author);

CREATE TABLE IF NOT EXISTS comment_audits (
    comment_id BIGINT REFERENCES comments(id) ON DELETE RESTRICT NOT NULL,
    deleted_by BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    /* UTC timestamp. */
    deleted_time timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_board_last_visits(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL,
    last_visit_time timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX user_board_entry on user_board_last_visits(user_id, board_id);

CREATE TABLE IF NOT EXISTS user_thread_last_visits(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    thread_id BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL,
    last_visit_time timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX user_thread_entry on user_thread_last_visits(user_id, thread_id);

CREATE TABLE IF NOT EXISTS dismiss_notifications_requests(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    realm_id BIGINT REFERENCES realms(id) ON DELETE RESTRICT NOT NULL,
    dismiss_request_time timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX dismiss_notifications_request_user on dismiss_notifications_requests(user_id, realm_id);

CREATE TABLE IF NOT EXISTS dismiss_board_notifications_requests(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL,
    dismiss_request_time timestamp NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX dismiss_board_notifications_requests_entry on dismiss_board_notifications_requests(user_id, board_id);

CREATE TABLE IF NOT EXISTS user_muted_threads(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    thread_id BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL
);
CREATE UNIQUE INDEX user_muted_thread_entry on user_muted_threads(user_id, thread_id);

CREATE TABLE IF NOT EXISTS user_muted_boards(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL
);
CREATE UNIQUE INDEX user_muted_boards_entry on user_muted_boards(user_id, board_id);

CREATE TABLE IF NOT EXISTS user_starred_threads(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    thread_id BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL
);
CREATE UNIQUE INDEX user_starred_thread_entry on user_starred_threads(user_id, thread_id);

CREATE TABLE IF NOT EXISTS user_pinned_boards(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL
);
CREATE UNIQUE INDEX user_pinned_boards_entry on user_pinned_boards(user_id, board_id);

CREATE TABLE IF NOT EXISTS user_hidden_threads(
    user_id BIGINT REFERENCES users(id) ON DELETE RESTRICT NOT NULL,
    thread_id BIGINT REFERENCES threads(id) ON DELETE RESTRICT NOT NULL
);
CREATE UNIQUE INDEX user_hidden_thread_entry on user_hidden_threads(user_id, thread_id);

CREATE TYPE board_description_section_type AS ENUM ('text', 'category_filter');
CREATE TABLE IF NOT EXISTS board_description_sections(
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY NOT NULL,
    string_id TEXT NOT NULL,
    board_id BIGINT REFERENCES boards(id) ON DELETE RESTRICT NOT NULL,
    title TEXT,
    description TEXT,
    type board_description_section_type NOT NULL,
    index BIGINT NOT NULL
);
CREATE INDEX board_description_sections_board_id on board_description_sections(board_id);
CREATE UNIQUE INDEX board_description_sections_string_id on board_description_sections(string_id);

CREATE TABLE IF NOT EXISTS board_description_section_categories(
    section_id BIGINT REFERENCES board_description_sections(id) ON DELETE RESTRICT NOT NULL,
    category_id BIGINT REFERENCES categories(id) ON DELETE RESTRICT NOT NULL
);
