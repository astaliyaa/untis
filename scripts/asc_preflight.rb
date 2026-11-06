#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Checks the App Store Connect API key before the (slow) build starts and makes
# sure the bundle identifier exists in the developer account.
#
#   ruby scripts/asc_preflight.rb KEY.p8 KEY_ID ISSUER_ID BUNDLE_ID "App Name" REQUIRE_APP(true|false)
#
# Exit 1 only for problems that would certainly break the release (key refused,
# missing permissions, missing App Store Connect app when uploading). Anything
# unexpected is reported as a warning and the build continues.

require 'openssl'
require 'json'
require 'base64'
require 'net/http'
require 'uri'

key_path, key_id, issuer_id, bundle_id, app_name, require_app = ARGV
abort 'usage: asc_preflight.rb KEY.p8 KEY_ID ISSUER_ID BUNDLE_ID APP_NAME REQUIRE_APP' if require_app.nil?
require_app = require_app == 'true'

def b64url(data)
  Base64.urlsafe_encode64(data, padding: false)
end

def make_jwt(key_path, key_id, issuer_id)
  key = OpenSSL::PKey.read(File.read(key_path))
  now = Time.now.to_i
  header = { alg: 'ES256', kid: key_id, typ: 'JWT' }
  payload = { iss: issuer_id, iat: now - 30, exp: now + 15 * 60, aud: 'appstoreconnect-v1' }
  signing_input = "#{b64url(header.to_json)}.#{b64url(payload.to_json)}"
  der = key.sign(OpenSSL::Digest.new('SHA256'), signing_input)
  # JWS wants the raw 64-byte r||s form, OpenSSL returns DER.
  raw = OpenSSL::ASN1.decode(der).value.map { |int| int.value.to_s(2).rjust(32, "\x00".b) }.join
  "#{signing_input}.#{b64url(raw)}"
end

def gh(kind, message)
  puts "::#{kind}::#{message}"
end

def summary(line)
  path = ENV['GITHUB_STEP_SUMMARY']
  File.open(path, 'a') { |f| f.puts(line) } if path && !path.empty?
end

def request(method, path, token, body = nil)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  req = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"
  if body
    req['Content-Type'] = 'application/json'
    req.body = JSON.generate(body)
  end
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 20, read_timeout: 60) do |http|
    http.request(req)
  end
  parsed = begin
    JSON.parse(res.body.to_s)
  rescue JSON::ParserError
    {}
  end
  [res.code.to_i, parsed]
end

def error_detail(json)
  Array(json['errors']).map { |e| [e['title'], e['detail']].compact.join(': ') }.join(' | ')
end

def q(value)
  URI.encode_www_form_component(value)
end

begin
  token = make_jwt(key_path, key_id, issuer_id)
rescue StandardError => e
  gh('error', "ASC_KEY_P8 could not be read as a private key (#{e.class}). Paste the whole AuthKey_XXXX.p8 file, including the BEGIN/END lines.")
  exit 1
end

begin
  # 1. Bundle ID (App ID) in Certificates, Identifiers & Profiles
  code, json = request(:get, "/v1/bundleIds?filter%5Bidentifier%5D=#{q(bundle_id)}&limit=200", token)
  case code
  when 200
    exact = Array(json['data']).find { |d| d.dig('attributes', 'identifier') == bundle_id }
    if exact
      puts "App ID #{bundle_id} is registered."
    else
      body = { data: { type: 'bundleIds',
                       attributes: { identifier: bundle_id, name: app_name.gsub(/[^A-Za-z0-9 ]/, ' ').strip, platform: 'IOS' } } }
      c2, j2 = request(:post, '/v1/bundleIds', token, body)
      if c2 == 201
        puts "Registered App ID #{bundle_id}."
        summary("- Registered App ID `#{bundle_id}` in your developer account.")
      else
        gh('warning', "Could not register App ID #{bundle_id} (HTTP #{c2}: #{error_detail(j2)}). Xcode will try during export.")
      end
    end
  when 401
    gh('error', "App Store Connect refused the API key (401). Check ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_P8 belong together and the key is not revoked. #{error_detail(json)}")
    exit 1
  when 403
    gh('error', "The API key may not manage identifiers/certificates (403). Create a Team key with the Admin role – cloud signing needs it. #{error_detail(json)}")
    exit 1
  else
    gh('warning', "Unexpected answer listing bundle IDs (HTTP #{code}: #{error_detail(json)}). Continuing.")
  end

  # 2. App record in App Store Connect (needed for TestFlight uploads)
  code, json = request(:get, "/v1/apps?filter%5BbundleId%5D=#{q(bundle_id)}&limit=10", token)
  if code == 200
    app = Array(json['data']).find { |d| d.dig('attributes', 'bundleId') == bundle_id }
    if app
      puts "App Store Connect app: #{app.dig('attributes', 'name')} (#{bundle_id})."
      summary("- App Store Connect app: **#{app.dig('attributes', 'name')}** (`#{bundle_id}`)")
    else
      msg = "No app with bundle ID #{bundle_id} exists in App Store Connect yet. Create it once: " \
            'appstoreconnect.apple.com → Apps → + → New App → platform iOS, any name, ' \
            "Bundle ID \"#{bundle_id}\", any SKU. Then run this workflow again."
      summary("- ⚠️ #{msg}")
      if require_app
        gh('error', msg)
        exit 1
      else
        gh('warning', msg)
      end
    end
  else
    gh('warning', "Could not look up the App Store Connect app (HTTP #{code}: #{error_detail(json)}). Continuing.")
  end
rescue StandardError => e
  gh('warning', "Preflight check skipped: #{e.class}: #{e.message}")
end
