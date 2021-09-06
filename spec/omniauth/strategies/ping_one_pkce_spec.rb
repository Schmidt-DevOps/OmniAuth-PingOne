require 'omniauth/strategies/ping-one'
describe OmniAuth::Strategies::PingOne do
    let(:ping_one_service) {
        OmniAuth::Strategies::PingOne.new(
            "X",
            "Y",
            "Z",
            {
                :pkce => true,
                :client_options => { site: "https://site.example.com",
                                     redirect_uri: "https://you.example.com/auth/ping_one/callback",
                                     authorize_url: '/xxx/as/authorization.oauth2',
                                     token_url: '/xxx/as/token.oauth2',
                                     user_url: '/xxx/idp/userinfo.openid',
                },
                :scopes => %w[profile email openid]
            }
        )
    }
    subject { ping_one_service }

    context 'configured service with given params' do
        it "given params" do
            expect(subject.client.secret).to eq "Z" # Default client always has a secret
            expect(subject.auth_token_client.secret).to eq nil # Auth token client never has a secret in PKCE mode
            expect(subject.options.client_options.site).to eq "https://site.example.com"
            expect(subject.options.client_options.redirect_uri).to eq "https://you.example.com/auth/ping_one/callback"
            expect(subject.options.client_options.authorize_url).to eq '/xxx/as/authorization.oauth2'
            expect(subject.options.client_options.token_url).to eq '/xxx/as/token.oauth2'
            expect(subject.options.client_options.user_url).to eq '/xxx/idp/userinfo.openid'
        end
    end
end

