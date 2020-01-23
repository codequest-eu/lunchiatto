# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Api::CompaniesController, type: :controller do
  let(:company) { create :company }
  let(:user) { create :user }

  describe 'GET show' do
    it 'requires authentication' do
      get :show, id: company.id
      expect(response).to redirect_to(root_path)
    end

    it 'refutes non-member' do
      show_company
      expect(response).to have_http_status(401)
    end

    context 'as company member' do
      before do
        user.company = company
        user.save!
      end
      it 'refutes' do
        show_company
        expect(response).to have_http_status(401)
      end
    end

    context 'as company admin' do
      before do
        user.company = company
        user.company_admin = true
        user.save!
      end
      it 'is a success' do
        show_company
        expect(response).to have_http_status(200)
      end
      it 'returns company' do
        show_company
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['name']).to eq(company.name)
      end
    end

    def show_company
      sign_in user
      get :show, id: company.id
    end
  end

  describe 'PUT update' do
    it 'requires authentication' do
      put :update, id: company.id, name: 'The new name'
      expect(response).to redirect_to(root_path)
    end

    it 'refutes non-member' do
      put_company
      expect(response).to have_http_status(401)
    end

    context 'as company member' do
      before do
        user.company = company
        user.save!
      end
      it 'refutes' do
        put_company
        expect(response).to have_http_status(401)
      end
    end

    context 'as company admin' do
      before do
        user.company = company
        user.company_admin = true
        user.save!
      end
      it 'is a success' do
        put_company
        expect(response).to have_http_status(200)
      end
      it 'returns company' do
        put_company
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['name']).to eq('The new name')
      end
      it 'returns errors' do
        put_company(name: '')
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    def put_company(name: 'The new name')
      sign_in user
      put :update, id: company.id, name: name
    end
  end
end
