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

            # Ping rejects access token requests with client secret when the client is in gung-ho PKCE mode, so we do not set it.
            def access_token_client
                return client unless options.pkce
                ::OAuth2::Client.new(options.client_id, nil, deep_symbolize(options.client_options))
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
                access_token.options[:mode] = :header
                @raw_info ||= access_token.get(options[:client_options][:user_url]).parsed
                @raw_info
            end

            protected

            # Wrap 'redirect_uri' in auth_token_params rather than token_params. Some Ping ID instances
            # may otherwise reject the request.
            def build_access_token
                verifier = request.params["code"]
                access_token_client.auth_code.get_token(
                    verifier,
                    token_params.to_hash(:symbolize_keys => true),
                    { :redirect_uri => callback_url }.merge(deep_symbolize(options.auth_token_params))
                )
            end
        end
    end
end

OmniAuth.config.add_camelization 'ping-one', 'PingOne'
