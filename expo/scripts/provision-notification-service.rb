require 'open3'
require 'openssl'
require 'spaceship'
require 'sigh'

# Reuse the distribution certificate imported by the workflow. Never create or
# revoke a signing certificate while provisioning the new Expo extension.
pem, status = Open3.capture2('security', 'find-certificate', '-a', '-p', 'build.keychain')
raise 'Cannot read the release keychain' unless status.success?
certificates = pem.scan(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m)
                  .map { |value| OpenSSL::X509::Certificate.new(value) }
                  .select do |certificate|
  certificate.subject.to_a.any? { |name, value| name == 'CN' && value.include?('Distribution') }
end
raise 'Expected one imported distribution certificate' unless certificates.length == 1

api_key = {
  key_id: ENV.fetch('API_KEY_ID'),
  issuer_id: ENV.fetch('API_ISSUER_ID'),
  key: ENV.fetch('API_PRIVATE_KEY'),
  in_house: false,
}
Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(**api_key)
serial = certificates.first.serial.to_s(16).upcase
certificate = Spaceship::ConnectAPI::Certificate.all(filter: { serialNumber: serial }).first
raise 'Imported distribution certificate was not found in the Apple team' unless certificate

identifier = ENV.fetch('NOTIFICATION_BUNDLE_ID')
unless Spaceship::ConnectAPI::BundleId.find(identifier)
  Spaceship::ConnectAPI::BundleId.create(
    name: 'ClashKing Notification Service', identifier: identifier, platform: 'IOS'
  )
end

Sigh.config = FastlaneCore::Configuration.create(Sigh::Options.available_options, {
  api_key: api_key,
  app_identifier: identifier,
  cert_id: certificate.id,
  provisioning_name: 'ClashKing Notification Service App Store',
  filename: 'notification.mobileprovision',
  output_path: Dir.pwd,
  skip_install: true,
})
Sigh::Manager.start
raise 'Notification profile was not downloaded' unless File.size?('notification.mobileprovision')
