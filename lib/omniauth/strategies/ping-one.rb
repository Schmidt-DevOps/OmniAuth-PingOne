require 'omniauth-oauth2'

# https://sso.connect.pingidentity.com/.well-known/openid-configuration
module OmniAuth
    module Strategies
        class PingOne < OmniAuth::Strategies::OAuth2
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
                super.tap do |params|
                    params[:scope] = options[:scopes].join(' ')
                end
            end

            uid { raw_info['sub'] }

            def email
                raw_info['email'] || raw_info['mail']
            end

            info do
                {
                    :email => email,
                    :name => raw_info['name'],
                }
            end

            def raw_info
                Rails.logger.debug "KRP365TEMP " + options.to_json
                access_token.options[:mode] = :header
                @raw_info ||= access_token.get(options[:client_options][:user_url]).parsed
                Rails.logger.debug "KRP365TEMP raw_info " + @raw_info.to_json
                @raw_info
            end

            protected

            # Wrap 'redirect_uri' in auth_token_params rather than token_params. Some Ping ID instances
            # may otherwise reject the request.
            def build_access_token
                verifier = request.params["code"]
                tp_hash = token_params.to_hash(:symbolize_keys => true)
                p = { :redirect_uri => callback_url }.merge(deep_symbolize(options.auth_token_params))
                Rails.logger.debug "KRP365TEMP verifier " + verifier.to_json
                Rails.logger.debug "KRP365TEMP tp_hash " + tp_hash.to_json
                Rails.logger.debug "KRP365TEMP p " + p.to_json
                Rails.logger.debug "KRP365TEMP auth_code " + @auth_code.to_json
                client.auth_code.get_token(verifier, tp_hash, p)
            end
        end
    end
end

OmniAuth.config.add_camelization 'ping-one', 'PingOne'