# Billetto Events — Ruby on Rails Assignment

## Overview

A Ruby on Rails application that fetches public events from the Billetto API, stores event data in PostgreSQL, and allows authenticated users to upvote or downvote events.

The application uses Clerk for authentication, Arkency Command Bus to dispatch voting commands, and Rails Event Store to publish vote-related domain events.

## Features

- Fetch and import events from the Billetto public API.
- Store event details in PostgreSQL.
- Display event titles, descriptions, images, dates, and event links.
- Authenticate users through Clerk.
- Allow authenticated users to upvote and downvote events.
- Store votes with the event ID, Clerk user ID, and vote direction.
- Allow one current vote per user per event.
- Update an existing vote when a user changes their vote direction.
- Dispatch voting commands through Arkency Command Bus.
- Process voting operations through a dedicated command handler.
- Publish `EventUpvoted` and `EventDownvoted` domain events through Rails Event Store.
- Update vote-count projections through an event subscriber.
- Prevent duplicate event processing using processed event records.
- Use database locking to handle concurrent voting operations.
- Include automated tests using RSpec.

## Technology Stack

- Ruby
- Ruby on Rails
- PostgreSQL
- RSpec
- Clerk authentication
- Rails Event Store
- Arkency Command Bus
- Billetto public Events API
- `dotenv-rails` for local environment variables

## Prerequisites

Install the following before setting up the application:

- Ruby version compatible with the project's Gemfile
- Bundler
- PostgreSQL
- Git

A Billetto API key-pair is required to import real events. Clerk credentials are required to configure authentication.

## Installation and Setup

### 1. Clone the repository

```bash
git clone https://github.com/pankajd04/billetto-events-rails.git
cd billetto-events-rails
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Configure environment variables

Create a `.env` file in the project root:

```dotenv
BILLETTO_API_KEYPAIR=your_billetto_api_key_pair
CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key
CLERK_SECRET_KEY=your_clerk_secret_key
CLERK_SIGN_IN_URL=your_clerk_sign_in_url
```

Replace the placeholders with your own credentials.

Do not commit `.env` or expose API keys and secret keys in the repository. Use `.env.example` to document the required variable names without real credentials.

### 4. Configure PostgreSQL

Check `config/database.yml` and configure the database connection for your local PostgreSQL installation.

Create the database and run migrations:

```bash
bin/rails db:create
bin/rails db:migrate
```

### 5. Start the application

```bash
bin/rails server
```

Open the application at:

http://localhost:3000

## Sample Events

Sample events can be loaded without Billetto API credentials.

Run:

```bash
bin/rails db:seed
```

The seed file creates three demonstration events for testing the event listing and voting flow.

The sample events use demonstration URLs and are not real Billetto listings.

The seed implementation uses `Event.find_or_create_by!` with fixed sample external IDs, so running the seed command again does not create duplicate sample events. Existing sample records are not automatically updated if their seed attributes change.

## Fetch Real Events from Billetto

To import real events, configure your own Billetto API key-pair.

### 1. Set the API key

In the project's `.env` file, set:

```dotenv
BILLETTO_API_KEYPAIR=your_actual_billetto_api_key_pair
```

Use a valid key-pair with access to the Billetto API.

### 2. Run the importer

Use the importer command supported by the current implementation. For example, if `Billetto::Importer` defines a `call` method:

```bash
bin/rails runner "Billetto::Importer.new.call"
```

Verify the importer class and method in the project before running this command.

### 3. Verify the imported data

Display the number of events:

```bash
bin/rails runner "puts Event.count"
```

Display event titles:

```bash
bin/rails runner "puts Event.pluck(:title)"
```

Importing real events requires valid API credentials and API access. If credentials are unavailable, use the sample events instead.

## Clerk Authentication

The application uses Clerk to authenticate users.

Configure the following variables:

- `CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `CLERK_SIGN_IN_URL`

Voting requests require an authenticated Clerk session. The Clerk user ID is obtained from the server-side Clerk session rather than being accepted from a browser-supplied user ID.

For local development, configure the Clerk application with the correct development domain and return URL.

## Voting

Each vote belongs to an event and stores:

- Event ID
- Clerk user ID
- Direction (`upvote` or `downvote`)

A user can have only one current vote per event. Changing the vote direction updates the existing vote record.

The database has a unique index on `(event_id, clerk_user_id)` to enforce this rule.

## Command Bus

The application uses Arkency Command Bus to separate voting requests from the voting business logic.

The voting flow is:

1. `VotesController` receives the voting request.
2. The controller creates a `CreateVote` command.
3. The command is dispatched through the Command Bus.
4. `CreateVoteHandler` processes the command.
5. The handler validates the vote direction and updates the vote record.
6. The handler publishes the appropriate domain event through Rails Event Store.

This keeps the controller focused on handling the request and moves the voting operation into a dedicated handler.

## Rails Event Store

The application defines two domain event types:

- `EventUpvoted`
- `EventDownvoted`

These events are published through Rails Event Store when a vote is created or its direction changes. The event payload includes the event ID, Clerk user ID, previous direction, and new direction.

The application registers the `EventVoteCountSubscriber` for both event types. It also registers the following Rails Event Store linking subscribers:

- `LinkByEventType`
- `LinkByCorrelationId`
- `LinkByCausationId`

In development, the event browser is available at:

http://localhost:3000/res

## Vote Count Projection

The application maintains an `EventVoteCount` table with upvote and downvote totals for each event.

The `EventVoteCountSubscriber` updates these totals when voting domain events are published. When a user changes their vote direction, the subscriber decreases the previous direction count and increases the new direction count.

The projection is maintained separately from the individual vote records. The event listing should use this projection if the goal is to display the precomputed totals without calculating counts from all vote records on each request.

## Idempotency

The application uses a `ProcessedEvent` table to track processed domain events.

A unique database index on `event_id` prevents the same event from being processed more than once. The processed-event record and the vote-count projection update are performed within the same database transaction.

This protects the projection from counting the same event more than once when the subscriber receives a duplicate delivery.

## Concurrency Handling

The `CreateVoteHandler` locks the event record while processing a vote using Active Record row-level locking.

This serializes voting operations for the same event and helps prevent duplicate votes when concurrent requests are received through the handler.

The votes table also has a unique database index on `(event_id, clerk_user_id)` as a database-level safeguard.

## Running Tests

Run the complete RSpec suite:

```bash
bundle exec rspec
```

Latest recorded test results:

- 38 examples
- 0 failures
- 4 pending

The test suite covers:

- Event and Vote model validations.
- Vote creation and direction changes.
- Command Bus dispatching from the voting controller.
- Rails Event Store event publishing.
- Vote rollback when event publishing fails.
- Vote-count projection updates.
- Duplicate event processing.
- Concurrent voting operations.
- Unauthenticated voting requests.

The four pending examples are generated placeholder specs for helper and view files.

## Design Decisions

### Persisting events locally

Billetto event data is stored locally so event listings can be displayed from the database instead of fetching the API response for every page request.

### Vote persistence

Votes are stored as database records rather than relying only on manually updated counters. This preserves the current vote direction for each user and event.

### Command handling

The controller dispatches a command, and a dedicated handler performs the voting operation. This separates HTTP request handling from business logic.

### Domain events and projections

Rails Event Store records vote-related domain events. A subscriber updates the `EventVoteCount` projection based on those events.

### Transaction handling

The vote update and event publication are performed within the handler's database transaction. The subscriber updates its processed-event record and projection within a transaction as well. This is a database-local design and should not be treated as a guarantee of atomicity across separate databases or external services.

### Local development

Sample data provides a way to explore the application without requiring Billetto API credentials. Developers can optionally configure their own credentials to import real events.

## Future Improvements

- Add asynchronous processing for event subscribers.
- Add retry and dead-letter handling for failed event processing.
- Add automated tests for Billetto API failure scenarios.
- Improve monitoring and logging for production deployments.
- Evaluate finer-grained locking or other concurrency strategies for higher voting throughput.
- Add performance tests for high-volume voting operations.

## Security

- Never commit `.env` or real credentials to source control.
- Use environment variables for API keys and secrets.
- Keep Clerk authentication checks enabled for voting endpoints.
- Derive the Clerk user ID from the server-side Clerk session.
- Do not expose secret keys in logs, screenshots, or public repositories.

## Notes

This project was created as a technical assignment. API availability, credentials, and local environment configuration may affect the ability to import real events or authenticate users.

Review the setup instructions and configure your own credentials before running integrations that require external services.
