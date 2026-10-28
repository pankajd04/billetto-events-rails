# Billetto Events — Ruby on Rails Assignment

## Overview

A Ruby on Rails application that fetches public events from the Billetto API, stores event data in PostgreSQL, and allows authenticated users to upvote or downvote events.

The application uses Clerk for authentication and Rails Event Store to publish vote-related domain events.

## Features

- Fetch and import events from the Billetto public API.
- Store event details in the database.
- Display event titles, descriptions, images, dates, and event links.
- Authenticate users through Clerk.
- Allow authenticated users to upvote and downvote events.
- Store votes with the event ID, Clerk user ID, and vote direction.
- Allow one current vote per user per event.
- Update an existing vote when a user changes their vote direction.
- Display upvote and downvote counts from saved vote records.
- Publish `EventUpvoted` and `EventDownvoted` events through Rails Event Store.
- Include automated tests using RSpec.

## Technology Stack

- Ruby
- Ruby on Rails
- PostgreSQL
- RSpec
- Clerk authentication
- Rails Event Store
- Billetto public Events API
- dotenv-rails for local environment variables

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
git clone YOUR_GITHUB_REPOSITORY_URL
cd test_assignment
```

Replace `YOUR_GITHUB_REPOSITORY_URL` with the actual repository URL.

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

The seed file creates demonstration events for testing the event listing, voting, and vote counts.

The sample events use demonstration URLs and are not real Billetto listings.

Running the seed command again should not create duplicate sample events when the seed implementation uses `find_or_create_by!` with the sample external IDs.

## Fetch Real Events from Billetto

To import real events, configure your own Billetto API key-pair.

### 1. Set the API key

In the project's `.env` file, set:

```dotenv
BILLETTO_API_KEYPAIR=your_actual_billetto_api_key_pair
```

Use a valid key-pair with access to the Billetto API.

### 2. Run the importer

From the project root, run:

```bash
bin/rails runner "Billetto::Importer.new.call"
```

The importer is intended to fetch events from Billetto and persist them in the local database.

This command should be verified against the current importer implementation before use. If the importer exposes a different method, use the method supported by the code.

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

Authenticated voting should use the user ID obtained from the validated Clerk session on the server. Do not trust a user ID supplied by the browser.

For local development, configure the Clerk application with the correct development domain and return URL.

## Voting

Each vote belongs to an event and stores:

- Event ID
- Clerk user ID
- Direction (`upvote` or `downvote`)

A user can have only one current vote per event. Changing the vote direction updates the existing vote record.

Upvote and downvote totals are calculated from persisted vote records. This allows the displayed totals to remain correct after a page refresh.

## Rails Event Store

The application defines two domain event types:

- `EventUpvoted`
- `EventDownvoted`

These events are published through Rails Event Store when a vote is recorded or its direction changes.

In development, the event store browser is available at:

http://localhost:3000/res

The event browser can be used to inspect published events and their payloads.

## Running Tests

Run the complete RSpec suite:

```bash
bundle exec rspec
```

The latest recorded test run completed with:

- 17 examples
- 0 failures
- 4 pending examples

The tests cover Event model validations, Vote model validations, vote direction changes, and rejection of unauthenticated voting requests.

Pending specs should be reviewed and replaced with meaningful tests where appropriate.

## Design Decisions

### Persisting events locally

Billetto event data is stored locally so event listings can be displayed from the database instead of fetching the API response for every page request.

### Vote persistence

Votes are stored as database records rather than maintaining separate manually updated counters. This allows counts to be derived from the current saved vote direction.

### Domain events

Rails Event Store records vote-related events. Event payloads should contain enough information to understand vote transitions, including the previous and new directions when applicable.

### Local development

Sample data provides a quick way to explore the application without requiring Billetto API credentials. Developers can optionally configure their own credentials to import real events.

## Future Improvements

- Add integration tests for authenticated voting.
- Add automated tests for Rails Event Store publishing and vote transitions.
- Add database-level unique constraints for event and user vote pairs.
- Ensure vote persistence and event publishing remain consistent if either operation fails.
- Add error handling and retry behavior for Billetto API failures.
- Add automated tests for the event import workflow.
- Improve monitoring and logging for production deployments.

## Security

- Never commit `.env` or real credentials to source control.
- Use environment variables for API keys and secrets.
- Keep Clerk authentication checks enabled for voting endpoints.
- Derive the Clerk user ID from a validated server-side session.
- Do not expose secret keys in logs, screenshots, or public repositories.

## Notes

This project was created as a technical assignment. API availability, credentials, and local environment configuration may affect the ability to import real events or authenticate users.

Review the setup instructions and configure your own credentials before running integrations that require external services.