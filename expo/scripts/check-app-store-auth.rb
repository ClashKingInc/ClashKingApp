require 'openssl'
require 'spaceship'
require 'json'

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
  app = Spaceship::ConnectAPI::App.find('com.clashking.apps')
  abort 'The Apple API key cannot access com.clashking.apps.' unless app
  puts "ClashKing App Store Connect app ID: #{app.id}"
  # Read only metadata. Report presence/counts, never review contacts, account
  # passwords, signing material or image contents in CI diagnostics.
  versions = app.get_app_store_versions(
    filter: { platform: 'IOS' }, includes: 'appStoreReviewDetail', limit: 5
  )
  presence = ->(value) { !value.to_s.strip.empty? }
  metadata = versions.map do |version|
    review = version.app_store_review_detail
    {
      version: version.version_string,
      state: version.app_store_state,
      copyright_present: presence.call(version.copyright),
      review_contact_complete: review && [review.contact_first_name, review.contact_last_name, review.contact_phone, review.contact_email].all?(&presence),
      review_sign_in_required: review&.demo_account_required,
      review_account_complete: review && [review.demo_account_name, review.demo_account_password].all?(&presence),
      localizations: version.get_app_store_version_localizations.map do |locale|
        {
          locale: locale.locale,
          description_present: presence.call(locale.description),
          support_url_present: presence.call(locale.support_url),
          screenshot_sets: locale.get_app_screenshot_sets.map do |set|
            { display_type: set.screenshot_display_type, image_count: (set.app_screenshots || []).length }
          end,
        }
      end,
    }
  end
  info = app.fetch_latest_app_info
  privacy = info ? info.get_app_info_localizations.map do |locale|
    { locale: locale.locale, privacy_policy_url_present: presence.call(locale.privacy_policy_url) }
  end : []
  puts "Read-only App Store metadata: #{JSON.generate({ versions: metadata, privacy: privacy })}"
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
