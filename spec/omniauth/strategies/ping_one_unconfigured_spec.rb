require 'omniauth/strategies/ping-one'
describe OmniAuth::Strategies::PingOne do
    let(:ping_one_service_unconfigured) { OmniAuth::Strategies::PingOne.new({ }) }
    subject { ping_one_service_unconfigured }

    context 'unconfigured service with defaults' do
        it "with defaults" do
            expect(subject.options.client_options.site).to eq "https://not-set.invalid"
            expect(subject.options.client_options.redirect_uri).to eq "https://not-set.invalid"
            expect(subject.options.client_options.authorize_url).to eq '/sso/as/authorization.oauth2'
            expect(subject.options.client_options.token_url).to eq '/sso/as/token.oauth2'
            expect(subject.options.client_options.user_url).to eq '/sso/idp/userinfo.openid'
        end
    end
end

