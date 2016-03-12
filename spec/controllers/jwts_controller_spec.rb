require_relative '../spec_helper'

describe JwtsController do
  describe "#generate" do
    include_context "JWT setup"

    let(:token_user){ user(active_user: true) }

    it "requires being logged in" do
      post 'create'
      expect(response).to be_redirect
      expect(response.status).to eq(302)
    end

    context "with valid user session" do

      before(:each){ user_session(token_user) }

      it "generates a base64 encoded token for a user session with env var secrets" do
        post 'create', format: 'json'
        un_csrfd_body = response.body.gsub("while(1);", "")
        utf8_token_string = JSON.parse(un_csrfd_body)['token']
        decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
        decrypted_token_body = Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
        expect(decrypted_token_body[:sub]).to eq(token_user.global_id)
      end

      it "has the users domain in the token" do
        post 'create', format: 'json'
        un_csrfd_body = response.body.gsub("while(1);", "")
        utf8_token_string = JSON.parse(un_csrfd_body)['token']
        decoded_crypted_token = Canvas::Security.base64_decode(utf8_token_string)
        decrypted_token_body = Canvas::Security.decrypt_services_jwt(decoded_crypted_token)
        expect(decrypted_token_body[:domain]).to eq("test.host")
      end
    end

    it "doesn't allow using a token to gen a token" do
      token = Canvas::Security::ServicesJwt.generate({ sub: token_user.global_id })
      get 'create', {format: 'json'}, {'Authorization' => "Bearer #{token}"}
      expect(response.status).to_not eq(200)
    end

  end
end
