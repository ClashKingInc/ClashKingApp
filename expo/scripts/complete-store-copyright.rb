require 'spaceship'
begin
  Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV.fetch('API_KEY_ID'), issuer_id: ENV.fetch('API_ISSUER_ID'),
    key: ENV.fetch('API_PRIVATE_KEY'), in_house: false
  )
  app = Spaceship::ConnectAPI::App.find('com.clashking.apps')
  raise 'Expected app missing' unless app
  versions = app.get_app_store_versions(filter: { platform: 'IOS' }, limit: 10)
  version = versions.find { |item| ['1.0', '1.0.0'].include?(item.version_string) && item.app_store_state == 'PREPARE_FOR_SUBMISSION' }
  raise 'Expected editable first-release version missing' unless version
  # Match the existing public website copyright. Preserve any value already set
  # by the owner, and change no review account, screenshots or privacy answers.
  if version.copyright.to_s.strip.empty?
    version.update(attributes: { copyright: '2026 ClashKing' })
  end
  actual = app.get_app_store_versions(filter: { platform: 'IOS' }, limit: 10).find { |item| item.id == version.id }
  raise 'Copyright was not saved' if actual.copyright.to_s.strip.empty?
  puts "First-release copyright is configured. Version: #{actual.version_string}. No build submitted by this job."
rescue StandardError => error
  warn "Store metadata check failed (#{error.class}); no credentials or review information logged."
  exit 1
end
