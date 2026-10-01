# frozen_string_literal: true
require "clerk/configuration"
require "clerk/sdk"

Clerk::Configuration.default.update(
  publishable_key: Rails.application.credentials.dig(
    :development,
    :CLERK_PUBLISHABLE_KEY
  ),
  secret_key: Rails.application.credentials.dig(
    :development,
    :CLERK_SECRET_KEY
  )
)