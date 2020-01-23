# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CompanySerializer do
  let(:company) { create(:company) }
  let!(:first_user) { create(:user, company: company, name: 'Zbigniew') }
  let!(:second_user) { create(:other_user, company: company, name: 'Antoni') }
  let!(:third_user) { create(:another_user, company: company, name: 'Nieaktywny') }

  context 'users' do
    subject { described_class.new company }

    it 'sorts users by name' do
      expect(first_user).to eq(subject.users[1])
      expect(second_user).to eq(subject.users[0])
    end

    it 'displays only active users' do
      expect(company.users.count).to eq(3)
      expect(subject.users.count).to eq(2)
      expect(subject.users).not_to include(third_user)
    end
  end
end
