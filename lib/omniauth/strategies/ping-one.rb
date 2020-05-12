require "oauth2"
require "omniauth"
require "securerandom"
require "socket" # for SocketError
require "timeout" # for Timeout::Error

# https://sso.connect.pingidentity.com/a57ad48e-710d-40e1-aac5-c620a4e63a54/.well-known/openid-configuration
module OmniAuth
    module Strategies
        class PingOne
            include OmniAuth::Strategy

            def self.inherited(subclass)
                Rails.logger.debug "XXX-379 raw_info_C 1 "
                OmniAuth::Strategy.included(subclass)
            end

            args %i[client_id client_secret]

            option :client_id, nil
            option :client_secret, nil
            option :client_options, {}
            option :authorize_params, {}
            option :authorize_options, [:scope, :state]
            option :token_params, {}
            option :token_options, []
            option :auth_token_params, {}
            option :provider_ignores_state, false

            attr_accessor :access_token

            def client
                Rails.logger.debug "XXX-379 raw_info_C 2 #{options.client_id} #{options.client_secret} #{options.client_options.to_json} "
                ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options))
            end

            credentials do
                hash = { "token" => access_token.token }
                hash["refresh_token"] = access_token.refresh_token if access_token.expires? && access_token.refresh_token
                hash["expires_at"] = access_token.expires_at if access_token.expires?
                hash["expires"] = access_token.expires?
                Rails.logger.debug "XXX-379 raw_info_C 3 #{hash.to_json} "
                hash
            end

            def request_phase
                Rails.logger.debug "XXX-379 raw_info_C 4 #{callback_url} #{authorize_params.to_json}"
                auth_params = { :redirect_uri => callback_url }.merge(authorize_params)
                Rails.logger.debug "XXX-379 auth_params #{auth_params.to_json}"
                redirect client.auth_code.authorize_url(auth_params)
            end

            def authorize_params_orig
                options.authorize_params[:state] = SecureRandom.hex(24)
                params = options.authorize_params.merge(options_for("authorize"))
                Rails.logger.debug "XXX-379 raw_info_C 5 #{params.to_json} "
                if OmniAuth.config.test_mode
                    @env ||= {}
                    @env["rack.session"] ||= {}
                end
                session["omniauth.state"] = params[:state]
                params
            end

            def token_params
                Rails.logger.debug "XXX-379 raw_info_C 6 "
                options.token_params.merge(options_for("token"))
            end

            def callback_phase # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
                Rails.logger.debug "XXX-379 raw_info_C 7 #{request.params.to_json}"
                error = request.params["error_reason"] || request.params["error"]
                if error
                    Rails.logger.debug "XXX-379 raw_info_D 4 #{request.params.to_json}"
                    fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
                elsif !options.provider_ignores_state && (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
                    Rails.logger.debug "XXX-379 raw_info_D 5 CSRF"
                    fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
                else
                    Rails.logger.debug "XXX-379 raw_info_D 6"
                    self.access_token = build_access_token
                    self.access_token = access_token.refresh! if access_token.expired?
                    super
                end
            rescue ::OAuth2::Error, CallbackError => e
                Rails.logger.debug "XXX-379 raw_info_D 3 #{e.to_json}"
                fail!(:invalid_credentials, e)
            rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
                Rails.logger.debug "XXX-379 raw_info_D 2 #{e.to_json}"
                fail!(:timeout, e)
            rescue ::SocketError => e
                Rails.logger.debug "XXX-379 raw_info_D 1 #{e.to_json}"
                fail!(:failed_to_connect, e)
            end


            # attr_reader :score
            #
            # def initialize
            #     super
            #     @score = 1
            # end
            #
            # def hit
            #     @score += 1
            # end

            option :client_options, {
                :site => 'https://not-set.invalid',
                :redirect_uri => 'https://not-set.invalid',
                :authorize_url => '/sso/as/authorization.oauth2',
                :token_url => '/sso/as/token.oauth2',
                :user_url => '/sso/idp/userinfo.openid'
            }
            option :scopes do
                %w[openid profile email]
            end

            def authorize_params
                Rails.logger.debug "XXX-379 raw_info_C 8"
                authorize_params_orig.tap do |params|
                    params[:scope] = options[:scopes].join(' ')
                end
            end

            uid { raw_info['sub'] }

            def email
                Rails.logger.debug "XXX-379 raw_info1:" + raw_info.to_json
                raw_info['email']
            end

            info do
                {
                    :email => email,
                    :name => raw_info['name'],
                }
            end

            def raw_info
                Rails.logger.debug "XXX-379 raw_infoB2 #{self.access_token.token}"
                access_token.options[:mode] = :header
                access_token_response = access_token.get(options[:client_options][:user_url])
                Rails.logger.debug "XXX-379 raw_info4a:" + access_token_response.body.to_s
                Rails.logger.debug "XXX-379 raw_info4b:" + access_token_response.headers.to_s
                @raw_info ||= access_token_response.parsed

                # This is required for debugging. Remove later. XXX-379
                Rails.logger.debug "XXX-379 raw_info2:" + @raw_info.to_s

                @raw_info
            end


            protected

            def build_access_token
                Rails.logger.debug "XXX-379 raw_info_C 8 #{request.params.to_json}"
                verifier = request.params["code"]
                a = {  }.merge(token_params.to_hash(:symbolize_keys => true))
                b = deep_symbolize(options.auth_token_params)
                Rails.logger.debug "XXX-379 auth_params10-A #{a.to_json}"
                Rails.logger.debug "XXX-379 auth_params10-B #{b.to_json}"
                client.auth_code.get_token(verifier, a, b)
            end

            def deep_symbolize(options)
                Rails.logger.debug "XXX-379 raw_info_C 9 #{options.to_json}"
                hash = {}
                options.each do |key, value|
                    hash[key.to_sym] = value.is_a?(Hash) ? deep_symbolize(value) : value
                end
                hash
            end

            def options_for(option)
                Rails.logger.debug "XXX-379 raw_info_C 10 #{option.to_json}"
                hash = {}
                options.send(:"#{option}_options").select { |key| options[key] }.each do |key|
                    hash[key.to_sym] = if options[key].respond_to?(:call)
                                           options[key].call(env)
                                       else
                                           options[key]
                                       end
                end
                hash
            end

            # An error that is indicated in the OAuth 2.0 callback.
            # This could be a `redirect_uri_mismatch` or other
            class CallbackError < StandardError
                attr_accessor :error, :error_reason, :error_uri

                def initialize(error, error_reason = nil, error_uri = nil)
                    Rails.logger.debug "XXX-379 raw_info_C 11 #{error} #{error_reason} #{error_uri}"

                    self.error = error
                    self.error_reason = error_reason
                    self.error_uri = error_uri
                end

                def message
                    [error, error_reason, error_uri].compact.join(" | ")
                end
            end
        end
    end
end

OmniAuth.config.add_camelization 'ping-one', 'PingOne'
OmniAuth.config.add_camelization "oauth2", "OAuth2"