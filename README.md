# LocalTask

A self-contained Kanban task management system built for **humans and AI coding agents** to collaborate on software projects. Think Asana, but with first-class MCP and API integrations so tools like Claude Code, Codex, and other agents can read, create, and update tasks programmatically.

Everything runs locally with zero external dependencies -- no Redis, no Postgres, no cloud services.

## Features

- **Kanban Board** -- Drag-and-drop task management with customizable per-project status columns
- **AI Agent Integration** -- MCP server (STDIO + HTTP/SSE) with 12 tools for Claude Code and other agents
- **Agent Registration** -- Create agents in the UI and download MCP config files for Claude Code and Claude Desktop
- **Agent Hooks** -- Notifications (polling + webhooks) when tasks are assigned, statuses change, or agents are @mentioned
- **REST API** -- Bearer token auth, rate limiting, agent identification via headers
- **Admin Panel** -- System dashboard, user management, agent discovery, webhook monitoring, system health
- **Audit Trail** -- Field-level change tracking on tasks (title, priority, description, due date, assignee, agent)
- **Soft Delete** -- Tasks are archived instead of destroyed, recoverable by admins
- **Real-time Updates** -- Turbo Streams via Solid Cable for live board sync across browser tabs
- **Multi-user** -- Registration, login, password reset, admin roles
- **Per-project Statuses** -- Default columns (Planning, Backlog, In Progress, With Agent, Tested, Done) -- fully customizable
- **Task Dependencies** -- Block/relate tasks to each other
- **File Attachments** -- Images and files on tasks and comments via Active Storage
- **Docker Ready** -- Production Dockerfile and docker-compose included

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Rails 8.1 |
| Ruby | 4.0.1 |
| Database | SQLite (WAL mode) |
| Frontend | Tailwind CSS, Hotwire (Turbo + Stimulus) |
| Background Jobs | Solid Queue |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| MCP Server | fast-mcp (~> 1.6) |
| File Uploads | Active Storage |
| Drag & Drop | acts_as_list + Stimulus |
| Auth | Rails 8 built-in authentication generator |

## Quick Start

### Prerequisites

- Ruby 4.0.1
- SQLite 3.x
- Docker (optional)

### Local Development

```bash
# Clone the repo
git clone git@github.com:kebabmane/localTask.git
cd localTask

# Install dependencies
bundle install

# Setup database and seed data
bin/rails db:prepare
bin/rails db:seed

# Start the dev server (Rails + Tailwind watcher)
bin/dev
```

Open http://localhost:3000 and log in:

- **Email:** `admin@localtask.dev`
- **Password:** `password`

The seed also creates a sample project ("LocalTask Development" with prefix `LT`) and prints an API token to the console.

### Docker

```bash
# Production
RAILS_MASTER_KEY=$(cat config/master.key) docker compose up --build

# Development (mounts source code, runs bin/dev)
docker compose -f docker-compose.dev.yml up --build
```

The app will be available at http://localhost:3000.

## MCP Integration (Claude Code)

LocalTask exposes an MCP server with **12 tools** and **1 resource template** so AI agents can manage tasks and receive notifications.

### Setup for Claude Code

The project includes a `.mcp.json` at the root. When you open the project in Claude Code, the MCP server is auto-discovered. No extra configuration needed.

```json
{
  "mcpServers": {
    "local-task": {
      "command": "ruby",
      "args": ["bin/mcp_server"]
    }
  }
}
```

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `ListProjectsTool` | List all projects with task counts and statuses |
| `ListTasksTool` | List/filter tasks by project, status, priority, or agent |
| `GetTaskTool` | Get full task detail including comments and dependencies |
| `CreateTaskTool` | Create a task (accepts project prefix, e.g. "LT") |
| `UpdateTaskTool` | Update task fields (title, description, priority, due date) |
| `UpdateTaskStatusTool` | Move a task between statuses (e.g. "In Progress" to "Done") |
| `AddCommentTool` | Add a comment to a task (supports agent_identifier) |
| `SearchTasksTool` | Full-text search across task titles and descriptions |
| `GetAgentNotificationsTool` | Poll for unread notifications (task assignments, status changes, @mentions) |
| `RegisterWebhookTool` | Register a webhook URL to receive push notifications |
| `ListWebhooksTool` | List all registered webhooks for an agent |
| `DeleteWebhookTool` | Remove a webhook registration |

### MCP Resource Template

| Resource | URI | Description |
|----------|-----|-------------|
| Project Board | `localtask://projects/{project_id}/board` | Full Kanban board state as JSON |

### Transports

- **STDIO** -- `bin/mcp_server` (for Claude Code, launched as subprocess)
- **HTTP/SSE** -- Mounted at `/mcp` on the Rails app (for other agents)
  - SSE: `GET http://localhost:3000/mcp/sse`
  - Messages: `POST http://localhost:3000/mcp/messages`

## Agent Hooks

Agents can be notified about events via **polling** (MCP tools) or **webhooks** (push).

### Notification Events

| Event | Trigger |
|-------|---------|
| `task_assigned` | A task's `agent_identifier` is set to this agent |
| `status_changed` | Any task involving this agent changes status |
| `mentioned` | This agent is @mentioned in a comment (e.g. `@claude-code`) |

### @Mentions

Comments support two mention types:

- **Agent mentions:** `@claude-code` -- notifies the named agent
- **Task references:** `@LT-3` -- cross-references another task and notifies agents on that task

### Polling (MCP)

```
GetAgentNotificationsTool(agent_identifier: "claude-code", mark_as_read: true)
```

Returns unread notifications with event type, message, task reference, and payload.

### Webhooks

Register a webhook URL and LocalTask will POST JSON payloads for each event:

```
RegisterWebhookTool(agent_identifier: "claude-code", url: "https://example.com/hooks")
```

Webhook payloads include HMAC-SHA256 signatures (via `X-Webhook-Signature` header) when a secret is provided. Webhooks auto-deactivate after 10 consecutive failures.

## Audit Trail

All changes to task fields are automatically tracked as system comments in the activity timeline:

| Field | Example Message |
|-------|----------------|
| Title | `Title changed from "Old" to "New"` |
| Priority | `Priority changed from high to critical` |
| Due Date | `Due date set to 2026-03-15` / `Due date removed` |
| Assignee | `Assigned to Jane Smith` / `Unassigned` |
| Agent | `Agent changed from claude-code to devin` |
| Description | `Description updated` |
| Status | `Status changed from In Progress to Done` |

Tasks use **soft delete** -- deleting a task sets `deleted_at` instead of destroying the record. Soft-deleted tasks are hidden from normal queries but can be recovered.

## Admin Panel

Available at `/admin` for users with the `admin` role. The panel has six tabs:

| Tab | Description |
|-----|-------------|
| **Overview** | Dashboard with stat cards, recent tasks, active agents, recent users |
| **Users** | User management with search, role editing (admin/user), detail views |
| **Agents** | Discovered agents with task counts, webhooks, notifications, activity history |
| **API Tokens** | All tokens across users with filter (All/Active/Revoked) and revoke |
| **Webhooks** | Webhook management with toggle active/inactive, reset failures, delete |
| **System** | Ruby/Rails version, SQLite stats, table row counts, Solid Queue status, memory |

Agents are **discovered automatically** by scanning `agent_identifier` across tasks, comments, webhooks, and notifications -- no explicit registration needed.

## Agent Registration & MCP Config

Available at `/agents` for all logged-in users. Register AI agents and download pre-built MCP configuration files.

### Creating an Agent

1. Navigate to `/agents` and click "Create Agent"
2. Enter a name (e.g., "Claude Code Agent") -- an identifier is auto-generated (e.g., `claude-code-agent`)
3. On creation, an API token is auto-generated and shown once
4. The agent detail page provides downloadable config files and usage instructions

### Config Downloads

Each agent provides three config formats:

| Format | File | Use Case |
|--------|------|----------|
| **Claude Code** | `.mcp.json` | Place in project root -- Claude Code auto-discovers it |
| **Claude Desktop** | `claude_desktop_config.json` | Merge into Claude Desktop's config file |
| **STDIO** | `.mcp.json` | Local development (requires Ruby + project clone) |

**Claude Code / Claude Desktop** (HTTP/SSE transport):
```json
{
  "mcpServers": {
    "local-task": {
      "url": "http://localhost:3000/mcp/sse"
    }
  }
}
```

**STDIO transport** (for local development):
```json
{
  "mcpServers": {
    "local-task": {
      "command": "ruby",
      "args": ["/path/to/localTask/bin/mcp_server"]
    }
  }
}
```

The agent detail page also shows REST API usage examples with the correct `agent_identifier` and `X-Agent-Identifier` header.

## REST API

All API endpoints are under `/api/v1/` and require a Bearer token.

### Authentication

Generate a token from the web UI at `/api_tokens`, or use the one printed by `bin/rails db:seed`.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/v1/projects
```

**Rate limit:** 120 requests per minute per token.

**Agent identification:** Set `X-Agent-Identifier` and `X-Agent-Session-Id` headers to tag tasks and comments with the agent that created them.

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/projects` | List all projects |
| `GET` | `/api/v1/projects/:id` | Project detail with statuses |
| `POST` | `/api/v1/projects` | Create a project |
| `PATCH` | `/api/v1/projects/:id` | Update a project |
| `GET` | `/api/v1/projects/:id/tasks` | List tasks (filter: `status`, `priority`, `agent`) |
| `GET` | `/api/v1/projects/:id/tasks/:id` | Task detail with comments |
| `POST` | `/api/v1/projects/:id/tasks` | Create a task |
| `PATCH` | `/api/v1/projects/:id/tasks/:id` | Update a task |
| `DELETE` | `/api/v1/projects/:id/tasks/:id` | Soft-delete a task |
| `PATCH` | `/api/v1/projects/:id/tasks/:id/status` | Move task to new status |
| `GET` | `/api/v1/projects/:id/tasks/:id/comments` | List comments |
| `POST` | `/api/v1/projects/:id/tasks/:id/comments` | Add a comment |
| `GET` | `/api/v1/projects/:id/statuses` | List project statuses |
| `GET` | `/api/v1/me` | Current user profile |
| `GET` | `/api/v1/agent_notifications` | List agent notifications (filter: `agent`, `unread`) |
| `PATCH` | `/api/v1/agent_notifications/:id/mark_read` | Mark notification as read |
| `POST` | `/api/v1/agent_notifications/mark_all_read` | Mark all read for an agent |
| `GET` | `/api/v1/agent_webhooks` | List webhooks (filter: `agent`) |
| `POST` | `/api/v1/agent_webhooks` | Register a webhook |
| `PATCH` | `/api/v1/agent_webhooks/:id` | Update a webhook |
| `DELETE` | `/api/v1/agent_webhooks/:id` | Delete a webhook |

### Example: Create a task from an agent

```bash
curl -X POST http://localhost:3000/api/v1/projects/1/tasks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Agent-Identifier: claude-code" \
  -d '{"title": "Fix login bug", "priority": "high", "description": "Users report 500 on login"}'
```

## Data Model

```
User (1) ----< Project (1) ----< TaskStatus (ordered, per-project)
                    |                    |
                    +----< Task >--------+
                             |
                             +----< Comment ----< Mention
                             +----< AgentNotification
                             +----< TaskDependency (self-join)
                             +----< ActiveStorage::Attachment

User (1) ----< ApiToken ----? Agent (optional link)
User (1) ----< Agent
AgentWebhook (standalone, keyed by agent_identifier)
```

### Default Statuses (per project)

| Status | Color | Notes |
|--------|-------|-------|
| Planning | Purple | |
| Backlog | Gray | Default for new tasks |
| In Progress | Blue | |
| With Agent | Amber | For tasks assigned to AI agents |
| Tested | Green | |
| Done | Green | Marks task as closed |

Statuses are fully customizable per project -- add, rename, reorder, or delete.

### Task Priorities

`low` | `medium` | `high` | `critical`

### Task IDs

Each task gets a human-readable display ID based on the project prefix: `LT-1`, `LT-2`, etc.

### Comment Types

| Type | Description |
|------|-------------|
| `comment` | Regular user or agent comment |
| `status_change` | Auto-generated when task status changes |
| `system` | Auto-generated audit trail for field changes |

## Project Structure

```
app/
  controllers/
    admin/             # Admin panel (7 controllers)
    api/v1/            # REST API controllers
    agents_controller.rb   # Agent registration + config downloads
    boards_controller.rb
    tasks_controller.rb
    ...
  models/
    task.rb            # Core model with broadcasts, soft delete, audit trail
    project.rb         # Auto-creates default statuses
    api_token.rb       # Bearer token auth with bcrypt
    agent.rb           # Registered agents with linked API tokens
    agent_notification.rb  # Polling notifications for agents
    agent_webhook.rb   # Push webhook registrations
    mention.rb         # @agent and @TASK-ID mentions
    ...
  tools/               # MCP tools (12 total)
  resources/           # MCP resources
  services/
    notification_service.rb  # Central notification coordinator
    mention_parser.rb        # @mention parsing (agents + task refs)
  serializers/         # Plain Ruby JSON serializers
  jobs/
    webhook_delivery_job.rb  # Async webhook delivery with retries
  views/
    admin/             # Admin panel views (11 templates)
    agents/            # Agent registration + config download
    boards/            # Kanban board views
    tasks/             # Task forms and detail panel
    ...
  javascript/
    controllers/
      kanban_controller.js     # HTML5 drag-and-drop
      slideover_controller.js  # Task detail panel
      flash_controller.js      # Auto-dismiss notifications
bin/
  mcp_server           # STDIO MCP entry point
config/
  initializers/
    fast_mcp.rb        # HTTP/SSE MCP mount at /mcp
```

## Development

```bash
# Run the dev server
bin/dev

# Run tests
bin/rails test

# Run linter
bin/rubocop

# Rails console
bin/rails console

# Test the MCP server manually
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}' | ruby bin/mcp_server
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `RAILS_MASTER_KEY` | Production only | Decrypts `config/credentials.yml.enc` |
| `RAILS_SERVE_STATIC_FILES` | Docker | Set to `true` in production |
| `RAILS_LOG_TO_STDOUT` | Docker | Set to `true` for container logging |

## License

This project is private.
