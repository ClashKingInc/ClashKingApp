require 'openssl'
require 'spaceship'

# Fail before installing dependencies when Apple rejects the release identity.
# Only read Apple resources; profile creation remains in the signing step.
begin
  fields = %w[API_KEY_ID API_ISSUER_ID API_PRIVATE_KEY]
  missing = fields.select { |name| ENV.fetch(name, '').strip.empty? }
  abort "Missing App Store Connect credentials: #{missing.join(', ')}" unless missing.empty?

  key = OpenSSL::PKey.read(ENV.fetch('API_PRIVATE_KEY'))
  abort 'App Store Connect private key must be an EC private key.' unless key.is_a?(OpenSSL::PKey::EC) && key.private?

  Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV.fetch('API_KEY_ID'),
    issuer_id: ENV.fetch('API_ISSUER_ID'),
    key: ENV.fetch('API_PRIVATE_KEY'),
    in_house: false,
  )
  Spaceship::ConnectAPI::App.all(limit: 1)
  if ENV.fetch('NOTIFICATION_PROFILE_BASE64', '').strip.empty?
    Spaceship::ConnectAPI::Certificate.all(limit: 1)
  end
  puts 'Apple accepted the API credentials for the required read-only release checks.'
rescue OpenSSL::PKey::PKeyError
  abort 'App Store Connect private key could not be parsed. Use the complete matching .p8 contents.'
rescue StandardError => error
  # Never print the key, generated JWT, or raw HTTP response in CI diagnostics.
  abort "Apple credential preflight failed (#{error.class}). Check that the key ID, issuer ID and private key match an active team key with the required access."
end
