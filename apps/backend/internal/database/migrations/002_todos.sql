-- Write your migrate up statements here

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE todo_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#6b7280'
);

CREATE INDEX idx_todo_categories_user_id ON todo_categories (user_id);
CREATE UNIQUE INDEX todo_categories_unique_name ON todo_categories (name);

CREATE TRIGGER set_updated_at_todo_categories
    BEFORE UPDATE ON todo_categories
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();

CREATE TABLE todos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    priority TEXT NOT NULL DEFAULT 'medium',
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    parent_todo_id UUID REFERENCES todos(id) ON DELETE SET NULL,
    category_id UUID REFERENCES todo_categories(id) ON DELETE SET NULL,
    metadata JSONB,
    sort_order SERIAL
);

CREATE INDEX idx_todos_user_id ON todos (user_id);
CREATE INDEX idx_todos_category_id ON todos (category_id);
CREATE INDEX idx_todos_parent_todo_id ON todos (parent_todo_id);
CREATE INDEX idx_todos_status ON todos (status);
CREATE INDEX idx_todos_priority ON todos (priority);
CREATE INDEX idx_todos_due_date ON todos (due_date);

CREATE TRIGGER set_updated_at_todos
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();


CREATE TABLE todo_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    todo_id UUID REFERENCES todos(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    comment TEXT NOT NULL
);

CREATE INDEX idx_todo_comments_todo_id ON todo_comments (todo_id);
CREATE INDEX idx_todo_comments_user_id ON todo_comments (user_id);

CREATE TRIGGER set_updated_at_todo_comments
    BEFORE UPDATE ON todo_comments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE todos
    ADD CONSTRAINT no_self_parent
    CHECK (id != parent_todo_id);

CREATE INDEX idx_todos_hierarchy ON todos (parent_todo_id, sort_order); 

CREATE INDEX idx_todos_user_status_priority ON todos (user_id, status, priority);

---- create above / drop below ----

DROP INDEX IF EXISTS idx_todos_user_status_priority;
DROP INDEX IF EXISTS idx_todos_hierarchy;
DROP TABLE IF EXISTS todo_comments;
DROP TABLE IF EXISTS todos;
DROP TABLE IF EXISTS todo_categories;
DROP EXTENSION IF EXISTS pgcrypto;
