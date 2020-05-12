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
                raw_info['email']
            end

            info do
                {
                    :email => email,
                    :name => raw_info['name'],
                }
            end

            def raw_info
                access_token.options[:mode] = :header
                @raw_info ||= access_token.get(options[:client_options][:user_url]).parsed

                # This is required for debugging. Remove later. XXX-379
                Rails.logger.debug "XXX-379 raw_info:" + @raw_info.to_s

                @raw_info
            end

            protected

            # Wrap 'redirect_uri' in auth_token_params rather than token_params. Some Ping ID instances would
            # otherwise reject the request.
            def build_access_token
                verifier = request.params["code"]
                client.auth_code.get_token(verifier, token_params.to_hash(:symbolize_keys => true), { :redirect_uri => callback_url }.merge(deep_symbolize(options.auth_token_params)))
            end
        end
    end
end

OmniAuth.config.add_camelization 'ping-one', 'PingOne'