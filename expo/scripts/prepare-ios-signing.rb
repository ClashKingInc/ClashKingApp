require 'spaceship'
require 'openssl'
require 'securerandom'
require 'base64'
require 'open3'
require 'cfpropertylist'
require 'json'

# Dedicated, explicitly requested credential repair. Existing Apple certificates
# and profiles are retained; all replacement profiles are validated before any
# release secret changes. Private material stays in memory on the ephemeral runner.

def plist(bytes)
  xml = OpenSSL::PKCS7.new(bytes).data
  CFPropertyList.native_types(CFPropertyList::List.new(data: xml).value)
end

begin
  repo = ENV.fetch('GITHUB_REPOSITORY')
  raise 'Unexpected repository' unless repo == 'ClashKingInc/ClashKingApp'
  stage = 'transfer key validation'
  recipient = OpenSSL::PKey.read(File.read('expo/scripts/signing-transfer-public.pem'))
  raise 'Transfer key must be public RSA' unless recipient.is_a?(OpenSSL::PKey::RSA) && !recipient.private?
  stage = 'Apple authentication'
  Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV.fetch('API_KEY_ID'), issuer_id: ENV.fetch('API_ISSUER_ID'),
    key: ENV.fetch('API_PRIVATE_KEY'), in_house: false
  )
  raise 'Expected app is inaccessible' unless Spaceship::ConnectAPI::App.find('com.clashking.apps')
  team = 'MZYXD43RX5'
  bundles = {
    'IOS_PROVISIONING_PROFILE_BASE64' => 'com.clashking.apps',
    'IOS_WIDGET_PROVISIONING_PROFILE_BASE64' => 'com.clashking.apps.warwidget',
    'IOS_NOTIFICATION_SERVICE_PROVISIONING_PROFILE_BASE64' => 'com.clashking.apps.notificationservice'
  }
  ids = bundles.transform_values do |identifier|
    bundle = Spaceship::ConnectAPI::BundleId.find(identifier)
    if !bundle && identifier.end_with?('.notificationservice')
      bundle = Spaceship::ConnectAPI::BundleId.create(name: 'ClashKing Notification Service', identifier: identifier, platform: 'IOS')
    end
    raise 'Required Apple bundle identifier is missing' unless bundle
    bundle.id
  end
  key = OpenSSL::PKey::RSA.new(2048)
  csr = OpenSSL::X509::Request.new
  csr.version = 0
  csr.subject = OpenSSL::X509::Name.parse('/CN=ClashKing Production CI')
  csr.public_key = key.public_key
  csr.sign(key, OpenSSL::Digest::SHA256.new)
  stage = 'certificate creation'
  record = Spaceship::ConnectAPI::Certificate.create(certificate_type: 'DISTRIBUTION', csr_content: csr.to_pem)
  certificate = OpenSSL::X509::Certificate.new(Base64.decode64(record.certificate_content))
  raise 'Issued certificate does not match the generated key' unless certificate.check_private_key(key)
  raise 'Issued certificate belongs to another team' unless certificate.subject.to_a.any? { |n,v| n == 'OU' && v == team }
  raise 'Issued certificate is expired' unless certificate.not_after > Time.now
  values = {}
  stage = 'profile creation and validation'
  ids.each do |secret, bundle_id|
    profile = Spaceship::ConnectAPI::Profile.create(
      name: "ClashKing CI #{bundles.fetch(secret)} #{ENV.fetch('GITHUB_RUN_ID')}",
      profile_type: 'IOS_APP_STORE', bundle_id_id: bundle_id, certificate_ids: [record.id]
    )
    bytes = Base64.decode64(profile.profile_content)
    data = plist(bytes)
    entitlements = data.fetch('Entitlements')
    raise 'Profile identifier mismatch' unless entitlements['application-identifier'] == "#{team}.#{bundles.fetch(secret)}"
    raise 'Profile is not for App Store distribution' if entitlements['get-task-allow'] || data['ProvisionedDevices']
    raise 'Profile does not contain the new certificate' unless data.fetch('DeveloperCertificates').any? { |der| der == certificate.to_der }
    raise 'Profile expired' unless data.fetch('ExpirationDate') > Time.now
    unless secret.include?('NOTIFICATION_SERVICE')
      raise 'Required shared app group missing' unless Array(entitlements['com.apple.security.application-groups']).include?('group.com.clashking.apps')
    end
    if secret == 'IOS_PROVISIONING_PROFILE_BASE64'
      raise 'Production push entitlement missing' unless entitlements['aps-environment'] == 'production'
      raise 'Associated domains entitlement missing' unless entitlements.key?('com.apple.developer.associated-domains')
    end
    values[secret] = Base64.strict_encode64(bytes)
  end
  password = SecureRandom.hex(32)
  archive = OpenSSL::PKCS12.create(password, 'ClashKing Production', key, certificate).to_der
  raise 'P12 roundtrip failed' unless OpenSSL::PKCS12.new(archive, password).certificate.to_der == certificate.to_der
  values['IOS_CERTIFICATE_PASSWORD'] = password
  values['IOS_CERTIFICATE_BASE64'] = Base64.strict_encode64(archive)
  stage = 'encrypted credential export'
  # Only this machine holds the transfer private key. The Actions artifact is
  # encrypted, and GitHub repository write credentials are not sent to CI.
  aes = OpenSSL::Cipher.new('aes-256-gcm').encrypt
  aes_key = aes.random_key
  iv = aes.random_iv
  aes.auth_data = ''
  encrypted = aes.update(JSON.generate(values)) + aes.final
  sealed_key = recipient.encrypt(aes_key, { 'rsa_padding_mode' => 'oaep', 'rsa_oaep_md' => 'sha256' })
  File.write('signing-encrypted.json', JSON.generate({
    key: Base64.strict_encode64(sealed_key), iv: Base64.strict_encode64(iv),
    ciphertext: Base64.strict_encode64(encrypted), tag: Base64.strict_encode64(aes.auth_tag)
  }))
  puts "Prepared and encrypted a new distribution identity expiring #{certificate.not_after.utc.strftime('%Y-%m-%d')} and three validated App Store profiles."
  puts 'Existing Apple certificates/profiles retained. No app built, uploaded or submitted by this job.'
rescue StandardError => error
  # Do not serialize API objects, PEM, PKCS12, passwords, or HTTP responses.
  warn "Signing repair stopped during #{stage} (#{error.class}). No secret values are logged."
  exit 1
end
