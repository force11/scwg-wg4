# frozen_string_literal: true

require 'google/apis/urlshortener_v1'
require 'digest/md5'
require 'json'
require 'yaml/store'
require 'uri'

require_relative '../mixins/google_api_support'
require_relative 'dates'

module LinkTo
  include GoogleApiSupport
  include Dates

  Urlshortener ||= Google::Apis::UrlshortenerV1

  def short(long_url)
    digest = Digest::MD5.hexdigest(long_url.to_s)
    url_object = store.transaction { store[digest] || generate_short_link(digest, long_url) }
    parsed_url_object = JSON.parse(url_object, symbolize_names: true)
    Urlshortener::Url.new(parsed_url_object).id
  end

  def link_to_other_timezones(agenda)
    meeting_time = agenda.fetch(:meeting_time)
    uri = URI.parse('https://www.timeanddate.com/worldclock/fixedtime.html')
    params = {
      msg: agenda.fetch(:title),
      iso: "#{meeting_time.strftime('%Y%m%dT%H%M')}"
    }
    uri.query = URI.encode_www_form(params)
    uri
  end

  private

  def generate_short_link(key, long_url)
    service = Urlshortener::UrlshortenerService.new
    service.client_options.application_name = @config[:google][:application_name]
    service.authorization = user_credentials_for(Urlshortener::AUTH_URLSHORTENER)
    res = service.insert_url(Urlshortener::Url.new(long_url: long_url))
    store[key] = res.to_json
  rescue => e
    warn("Unable to shorten '#{long_url}' due to the following error: #{e.message}")
    { id: long_url }.to_json
  end

  def store
    blk = lambda do
      short_urls_cache = @config[:cache][:short_urls]
      FileUtils.mkdir_p(File.dirname(short_urls_cache))
      YAML::Store.new(short_urls_cache)
    end
    @short_urls_store ||= blk.call
  end
end
