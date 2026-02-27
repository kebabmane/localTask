# LocalTask

A self-contained Kanban task management system built for **humans and AI coding agents** to collaborate on software projects. Think Asana, but with first-class MCP and API integrations so tools like Claude Code, Codex, and other agents can read, create, and update tasks programmatically.

Everything runs locally with zero external dependencies -- no Redis, no Postgres, no cloud services.

## Features

- **Kanban Board** -- Drag-and-drop task management with customizable per-project status columns
- **AI Agent Integration** -- MCP server (STDIO + HTTP/SSE) with 8 tools for Claude Code and other agents
- **REST API** -- Bearer token auth, rate limiting, agent identification via headers
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

LocalTask exposes an MCP server with **8 tools** and **1 resource template** so AI agents can manage tasks directly.

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

### MCP Resource Template

| Resource | URI | Description |
|----------|-----|-------------|
| Project Board | `localtask://projects/{project_id}/board` | Full Kanban board state as JSON |

### Transports

- **STDIO** -- `bin/mcp_server` (for Claude Code, launched as subprocess)
- **HTTP/SSE** -- Mounted at `/mcp` on the Rails app (for other agents)
  - SSE: `GET http://localhost:3000/mcp/sse`
  - Messages: `POST http://localhost:3000/mcp/messages`

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
| `DELETE` | `/api/v1/projects/:id/tasks/:id` | Delete a task |
| `PATCH` | `/api/v1/projects/:id/tasks/:id/status` | Move task to new status |
| `GET` | `/api/v1/projects/:id/tasks/:id/comments` | List comments |
| `POST` | `/api/v1/projects/:id/tasks/:id/comments` | Add a comment |
| `GET` | `/api/v1/projects/:id/statuses` | List project statuses |
| `GET` | `/api/v1/me` | Current user profile |

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
                             +----< Comment
                             +----< TaskDependency (self-join)
                             +----< ActiveStorage::Attachment

User (1) ----< ApiToken
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

## Project Structure

```
app/
  controllers/
    api/v1/          # REST API controllers
    boards_controller.rb
    tasks_controller.rb
    ...
  models/
    task.rb          # Core model with broadcasts, dependencies, acts_as_list
    project.rb       # Auto-creates default statuses
    api_token.rb     # Bearer token auth with bcrypt
    ...
  tools/             # MCP tools (8 total)
  resources/         # MCP resources
  serializers/       # Plain Ruby JSON serializers
  views/
    boards/          # Kanban board views
    tasks/           # Task forms and detail panel
    ...
  javascript/
    controllers/
      kanban_controller.js     # HTML5 drag-and-drop
      slideover_controller.js  # Task detail panel
      flash_controller.js      # Auto-dismiss notifications
bin/
  mcp_server         # STDIO MCP entry point
config/
  initializers/
    fast_mcp.rb      # HTTP/SSE MCP mount at /mcp
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
