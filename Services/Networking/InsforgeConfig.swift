import Foundation

/// Configuration for the Insforge cloud backend.
///
/// Replace the two constants below with the values from your Insforge project
/// dashboard:
///   - Base URL  e.g. https://xxxxxxxx.us-east.insforge.app
///   - Anon Key  the public anon key for browser/mobile clients
///
/// Required tables in your Insforge project (PostgREST autogen):
///
///   wallets
///     id              uuid  primary key default gen_random_uuid()
///     owner_user_id   uuid  not null
///     name            text  not null
///     initial_balance numeric default 0
///     balance         numeric default 0
///     color_hex       text  not null
///     created_at      timestamptz default now()
///
///   categories
///     id              uuid  primary key default gen_random_uuid()
///     owner_user_id   uuid  nullable           -- null = system category
///     name            text  not null
///     icon_name       text  not null
///     color_hex       text  not null
///     scope           text  not null           -- INCOME | EXPENSE | ALL
///     is_system       bool  default false
///     created_at      timestamptz default now()
///
///   transactions
///     id              uuid  primary key default gen_random_uuid()
///     owner_user_id   uuid  not null
///     wallet_id       uuid  not null
///     category_id     uuid  not null
///     amount          numeric not null
///     type            text  not null           -- INCOME | EXPENSE
///     date            timestamptz not null
///     note            text  nullable
///     created_at      timestamptz default now()
///
/// Add RLS so authenticated users only see rows where owner_user_id = auth.uid().
enum InsforgeConfig {
    static let baseURLString = "https://v2n4vphb.ap-southeast.insforge.app"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3OC0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJlbWFpbCI6ImFub25AaW5zZm9yZ2UuY29tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3OTY1OTZ9.jFIB8MjkjHVeBxgJ_ygqbpNaHka7-SO3rEOUMV1qEc4"

    static var baseURL: URL { URL(string: baseURLString)! }
}
