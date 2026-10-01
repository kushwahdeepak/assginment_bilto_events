====================================================================================================

# Billetto Events & Voting Platform

This is a Ruby on Rails application built for the Billetto Engineer Test. The application fetches public event data from the Billetto API, displays the events, allows logged-in users to cast votes (upvote/downvote) recorded in Rails Event Store, and manages authentication using Clerk.com.

---

## Development Approach & Timeboxing

I am currently working full-time and managing ongoing project deliverables alongside personal responsibilities. Because of this, I completed this task using a **timeboxed approach** whenever I found free time over 3 days (working around 1.5 to 2 hours per session, totaling ~6+ hours).

##Versions

- Ruby Version: `3.0.5`
- Rails Version: `7.1.5.1`
- Database:PostgreSQL
- Event Store: `rails_event_store` (used to log user votes as domain events)
- Authentication: `Clerk.com` SDK
- Testing: RSpec

- Ruby 3.0.5 & Rails 7.1.5.1: Modern, stable, and production-tested versions compatible with current Rails Event Store gems.
- Rails Event Store: Matches Billetto's core architecture requirements for event-driven voting tracking.
- Clerk.com: Provides secure, fast user authentication without bloating the local database.

## PROJECT SETUP GUIDE
   First, clone the repository using git clone [https://github.com/kushwahdeepak/assginment_bilto_events.git](https://github.com/kushwahdeepak/assginment_bilto_events.git) and navigate into the folder with cd assginment_bilto_events. 
   
   Next, install the required gems by running bundle install. Configure your database in config/database.yml, 
   then open your Rails secrets by typing bin/rails credentials:edit and add your 
   credentials: BILLETTO_API_KEY (Billetto API key),
   BILLETTO_API_SECRET (Billetto API secret), 
   BILLETTO_API_URL ([https://api.billetto.com/v2](https://api.billetto.com/v2)), 
   CLERK_PUBLISHABLE_KEY (Public Clerk key for ClerkJS), 
   CLERK_SECRET_KEY (Secret Clerk key for session tokens), and RAILS_ENV (development). 
   
   You can get the Billetto API key pair from Billetto Organiser Universe under Integrate > Developers. After configuring secrets, 
   
   set up your database and run migrations with bin/rails db:prepare (or manually run bin/rails db:create, 
   bin/rails g rails_event_store:active_record:migration, and bin/rails db:migrate). 
   
   To import event data, run bin/rails runner 'BillettoApi::IngestEvents.call' or execute BillettoIngestionService.new.call inside bin/rails console. The importer fetches events from [https://billetto.dk/api/v3/public/events?limit=100](https://billetto.dk/api/v3/public/events?limit=100), handles pagination and nested formats, validates data through the Event model, writes records safely in transactions, and skips invalid entries without failing the import process. 
   
   Finally, launch your local Rails server using bin/rails server and open http://localhost:3000 in your web browser.

## Application Routes & Endpoints

GET /events (EventsController#index): Displays paginated event listings with vote totals.

GET /events/:id (EventsController#show): Shows detailed information for a specific event.

GET /events.json (EventsController#index): Returns event listing in JSON format with pagination metadata.

GET /events/:id.json (EventsController#show): Returns individual event details in JSON format.

POST /events/:event_id/votes (VotesController#create): Casts an upvote or downvote (requires Clerk authorization token).

## Event-driven design

`EventsDomain::Upvote` and `EventsDomain::Downvote` are validated commands registered with the application command bus. The vote controller dispatches commands through that bus so command execution and the synchronous `ReadModels::VoteProjector` run inside the database transaction. `EventUpvoted` and `EventDownvoted` retain both event and Clerk user IDs and are published to event- and user-specific streams.

Rails Event Store uses its Active Record repository. Its event tables are created by the existing Rails Event Store migration. The `event_stats` table has one row per event and database-backed non-null counters. To rebuild the vote read model, replay the vote event types from the event store through `ReadModels::VoteProjector`; do so with writes paused or into a separate read-model table to avoid mixing replayed counts with live projections.


##Architecture & Features

### 1. API Ingestion (`app/services/billetto_ingestion_service.rb`)
- Fetches public event data from `api.billetto.com`.
- Validates required fields (e.g., event title, date) and handles duplicate records safely.

### 2. Rails Event Store & Voting
- Votes are not simple database counter updates; they are published as immutable domain facts (`EventUpvoted` / `EventDownvoted`).
- Each vote event stores the `user_id` (from Clerk) and `event_id` for complete auditability.
- Aggregate vote counts are calculated dynamically by reading the event stream (`Event$#{event_id}`).
---

## Testing
Run the test suite using RSpec:
bundle exec rspec

## Authentication & API Usage
User authentication is managed via Clerk.com.
- For web access: Sign in using the Clerk authentication UI on the frontend.
- For API access: Send the Clerk session token in the `Authorization` header when making POST requests to vote:
  `Authorization: Bearer <your_clerk_jwt_token>`
