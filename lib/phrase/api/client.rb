# -*- encoding : utf-8 -*-

require 'cgi'
require 'net/http'
require 'net/https'
require 'phrase'
require 'phrase/api'

class Phrase::Api::Client
  
  METHOD_GET = :get
  METHOD_POST = :post
  METHOD_PUT = :put
  
  attr_reader :auth_token
  
  def initialize(auth_token)
    raise "No auth token specified!" if (auth_token.nil? or auth_token.blank?)
    @auth_token = auth_token
  end
  
  def fetch_locales
    result = perform_api_request("/locales", :get)
    parsed(result).map do |locale| 
      {id: locale['id'], name: locale['name'], code: locale['code'], is_default: locale['is_default']}
    end
  end
  
  def fetch_blacklisted_keys
    result = perform_api_request("/blacklisted_keys", :get)
    blacklisted_keys = []
    parsed(result).map do |blacklisted_key| 
      blacklisted_keys << blacklisted_key['name']
    end
    blacklisted_keys
  end
  
  def translate(key)
    raise "You must specify a key" if key.nil? or key.blank?
    keys = {}
    result = parsed(perform_api_request("/translation_keys/translate", :get, {:key => key}))
    keys = extract_structured_object(result["translate"]) if result["translate"]
    keys
  end
  
  def find_keys_by_name(key_names=[])
    parsed(perform_api_request("/translation_keys", :get, {:key_names => key_names}))
  end
  
  def create_locale(name)
    raise "You must specify a name" if name.nil? or name.blank?
    
    begin
      perform_api_request("/locales", :post, {
        "locale[name]" => name
      })
    rescue Phrase::Api::Exceptions::ServerError => e
      raise "Locale #{name} could not be created (Maybe it already exists)"
    end
    true
  end
  
  def make_locale_default(name)
    raise "You must specify a name" if name.nil? or name.blank?
    
    begin
      perform_api_request("/locales/#{name}/make_default", :put)
    rescue Phrase::Api::Exceptions::ServerError => e
      raise "Locale #{name} could not be made the default locale"
    end
    true
  end
  
  def download_translations_for_locale(name, format)
    raise "You must specify a name" if name.nil? or name.blank?
    raise "You must specify a format" if format.nil? or format.blank?
    
    begin
      content = perform_api_request("/translations/download.#{format}", :get, {'locale' => name})
      return content
    rescue Phrase::Api::Exceptions::ServerError => e
      raise "Translations #{name} could not be downloaded"
    end
  end
  
  def upload(filename, file_content, tags=[], locale=nil)
    begin
      params = {
        "filename" => filename,
        "file_content" => file_content,
        "tags[]" => tags
      }
      params["locale_name"] = locale unless locale.nil?
      perform_api_request("/translation_keys/upload", :post, params)
    rescue Phrase::Api::Exceptions::ServerError => e
      raise "File #{filename} could not be uploaded"
    end
    true
  end
  
private
  def extract_structured_object(translation)
    if translation.is_a?(Hash)
      symbolize_keys(translation)
    else
      translation
    end
  end

  def symbolize_keys(hash)
    hash.symbolize_keys!
    hash.each do |key, value|
      if value.is_a?(Hash)
        hash[key] = symbolize_keys(value)
      end
    end
    hash
  end

  def display_api_error(response)
    error_message = api_error_message(response)
    $stderr.puts error_message
  end

  def api_error_message(response)
    message = ""
    begin
      error = parsed(response.body)["error"]
      if error.class == String
        message = error
      else
        message = parsed(response.body)["message"]
      end
    rescue JSON::ParserError
    end
    message = "Unknown Error" if message.blank?
    "Error: #{message} (#{response.code})"
  end

  def perform_api_request(endpoint, method=METHOD_GET, params={})
    request = case method
      when METHOD_GET
        get_request(endpoint, params)
      when METHOD_POST
        post_request(endpoint, params)
      when METHOD_PUT
        put_request(endpoint, params)
      else
        raise "Invalid Request Method: #{method}"
    end
    response = http_client.request(request)
    code = response.code.to_i
    if (code == 200)
      return response.body
    else
      error_message = api_error_message(response)
      raise Phrase::Api::Exceptions::Unauthorized.new(error_message) if (code == 401)
      raise Phrase::Api::Exceptions::ServerError.new(error_message)
    end
  end
  
  def get_request(endpoint, params={})
    params.merge!('auth_token' => @auth_token)
    request = Net::HTTP::Get.new("#{api_path_for(endpoint)}?#{query_for_params(params)}")
    request
  end
  
  def post_request(endpoint, params={})
    request = Net::HTTP::Post.new("#{api_path_for(endpoint)}")
    params.merge!({
      'auth_token' => @auth_token
    })
    set_form_data(request, params)
    request
  end
  
  def put_request(endpoint, params={})
    request = Net::HTTP::Put.new("#{api_path_for(endpoint)}")
    params.merge!({
      'auth_token' => @auth_token
    })
    set_form_data(request, params)
    request
  end
  
  def api_path_for(endpoint)
    "#{Phrase::Api::Config.api_path_prefix}#{endpoint}"
  end
  
  def http_client
    client = Net::HTTP.new(Phrase::Api::Config.api_host, Phrase::Api::Config.api_port)
    client.use_ssl = true if Phrase::Api::Config.api_use_ssl?
    client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    client.ca_file = File.join(File.dirname(__FILE__), "..", "..", "cacert.pem")
    client
  end
  
  # Support for arrays in POST data
  # http://blog.assimov.net/blog/2010/06/01/postput-arrays-with-ruby-nethttp-set_form_data/
  def set_form_data(request, params, separator='&')
    request.body = params.map do |key, value| 
      if value.instance_of?(Array)
        value.map {|value_item| "#{escaped(key.to_s)}=#{escaped(value_item.to_s)}"}.join(separator)
      else
        "#{escaped(key.to_s)}=#{escaped(value.to_s)}"
      end
    end.join(separator)
    request.content_type = 'application/x-www-form-urlencoded'
  end
  
  def parsed(raw_data)
    JSON.parse(raw_data)
  end
  
  def escaped(value) 
    CGI::escape(value)
  end

  def query_for_params(params)
    Phrase::Api::QueryParams.encode(params)
  end
end
