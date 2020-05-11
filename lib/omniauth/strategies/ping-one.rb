require 'omniauth-oauth2'

# https://sso.connect.pingidentity.com/a57ad48e-710d-40e1-aac5-c620a4e63a54/.well-known/openid-configuration
module OmniAuth
    module Strategies
        class PingOne < OmniAuth::Strategies::OAuth2
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
                super.tap do |params|
                    params[:scope] = options[:scopes].join(' ')
                    Rails.logger.debug "XXX-379 raw_info3:" + @raw_info.to_s
                end
            end

            uid { raw_info['sub'] }

            def email
                Rails.logger.debug "XXX-379 raw_info1:" + @raw_info.to_s
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
                access_token_response = access_token.get(options[:client_options][:user_url])
                Rails.logger.debug "XXX-379 raw_info4a:" + access_token_response.body.to_s
                Rails.logger.debug "XXX-379 raw_info4b:" + access_token_response.headers.to_s
                @raw_info ||= access_token_response.parsed

                # This is required for debugging. Remove later. XXX-379
                Rails.logger.debug "XXX-379 raw_info2:" + @raw_info.to_s

                @raw_info
            end
        end
    end
end

OmniAuth.config.add_camelization 'ping-one', 'PingOne'