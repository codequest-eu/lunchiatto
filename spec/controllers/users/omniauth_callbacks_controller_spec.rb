# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  describe 'GET google_oauth2' do
    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
    end
    context 'with success' do
      context 'finds user by uid' do
        before do
          request.env['omniauth.auth'] =
            OmniAuth.config.mock_auth[:google_oauth2_codequest]
          User.create(email: 'test@codequest.com',
                      provider: 'google_oauth2',
                      uid: '123545')
        end

        it 'redirects to new_company_path if user has no company' do
          get :google_oauth2
          expect(response).to redirect_to(new_company_url)
        end
      end

      context 'finds user by email' do
        before do
          request.env['omniauth.auth'] =
            OmniAuth.config.mock_auth[:google_oauth2_codequest]
          User.create(email: 'test@codequest.com',
                      provider: 'different_provider',
                      uid: 'different_uid')
        end

        it 'redirects to new_company_path and updates user' do
          get :google_oauth2
          expect(response).to redirect_to(new_company_url)
          user = User.last
          expect(user.uid).to eq '123545'
          expect(user.provider).to eq 'google_oauth2'
        end
      end
    end
    context 'works for non-codequest users' do
      before do
        request.env['omniauth.auth'] =
          OmniAuth.config.mock_auth[:google_oauth2_non_codequest]
        User.create(email: 'test@email.com',
                    provider: 'google_oauth2',
                    uid: '123545')
      end

      it 'redirects to new_company_path if user has no company' do
        get :google_oauth2
        expect(response).to redirect_to(new_company_url)
      end
    end
    context 'when user does not exist' do
      before do
        request.env['omniauth.auth'] =
          OmniAuth.config.mock_auth[:google_oauth2_codequest]
      end
      it 'redirects to index' do
        get :google_oauth2
        expect(response).to redirect_to(root_path)
      end
    end
    context 'when user is invited' do
      let(:company) { create :company }
      before do
        request.env['omniauth.auth'] =
          OmniAuth.config.mock_auth[:google_oauth2_codequest]
      end
      context 'and not authorized' do
        let!(:invitation) do
          create :invitation, company: company, email: 'test@codequest.com'
        end
        it 'redirects' do
          get :google_oauth2
          expect(response).to redirect_to(root_url)
        end
        it 'does not create a user' do
          expect do
            get :google_oauth2
          end.to change(User, :count).by(0)
        end
        it 'does not delete the invitation' do
          expect do
            get :google_oauth2
          end.to change(Invitation, :count).by(0)
        end
      end
      context 'and authorized' do
        let!(:invitation) do
          create :invitation, company: company,
                              email: 'test@codequest.com',
                              authorized: true
        end
        it 'redirects' do
          get :google_oauth2
          expect(response).to redirect_to(new_company_url)
        end
        it 'creates user' do
          expect do
            get :google_oauth2
          end.to change(User, :count).by(1)
        end
        it 'deletes the invitation' do
          expect do
            get :google_oauth2
          end.to change(Invitation, :count).by(-1)
        end
      end
    end
  end
end
