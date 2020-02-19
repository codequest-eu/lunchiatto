# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DishPolicy do
  let(:company) { create :company }
  let(:user) { create :user, company: company }
  let(:other_user) { create :other_user, company: company }
  let(:order) { create :order, user: user, company: company }
  let(:dish) { create :dish, order: order }
  let!(:user_dish) { create :user_dish, user: user, dish: dish }
  let(:other_dish) { create :dish, order: order }
  let!(:other_user_dish) do
    create :user_dish, user: other_user, dish: other_dish
  end
  subject { described_class.new(user, dish) }

  describe '#create?' do
    it 'returns true' do
      expect(subject.create?).to be_truthy
    end
  end

  describe '#show?' do
    it 'returns true' do
      expect(subject.show?).to be_truthy
    end
  end

  describe '#update?' do
    describe 'order in progress' do
      it "returns true when user's" do
        expect(subject.update?).to be_truthy
      end
      it "returns false when other user's" do
        policy = described_class.new other_user, dish
        expect(policy.update?).to be_falsey
      end
    end
    describe 'order ordered' do
      before do
        order.ordered!
      end
      it "returns false when user's" do
        policy = described_class.new other_user, other_dish
        expect(policy.update?).to be_falsey
      end
      it "returns false when other user's" do
        policy = described_class.new other_user, dish
        expect(policy.update?).to be_falsey
      end
      it 'returns true when edited by orderer' do
        policy = described_class.new user, other_dish
        expect(policy.update?).to be_truthy
      end
    end
    describe 'order delivered' do
      before do
        order.delivered!
      end
      it "returns false when user's" do
        expect(subject.update?).to be_falsey
      end
      it "returns false when other user's" do
        policy = described_class.new other_user, dish
        expect(policy.update?).to be_falsey
      end
    end
  end

  describe '#destroy?' do
    let(:other_policy) { described_class.new other_user, dish }
    describe 'order in progress' do
      it 'is true for the user' do
        expect(subject.destroy?).to be_truthy
      end
      it 'is false for the other user' do
        expect(other_policy.destroy?).to be_falsey
      end
    end
    describe 'order ordered' do
      before do
        order.ordered!
      end
      it 'is false for the user' do
        expect(subject.destroy?).to be_falsey
      end
      it 'is false for the other user' do
        expect(other_policy.destroy?).to be_falsey
      end
    end
    describe 'order delivered' do
      before do
        order.delivered!
      end
      it 'is false for the user' do
        expect(subject.destroy?).to be_falsey
      end
      it 'is false for the other user' do
        expect(other_policy.destroy?).to be_falsey
      end
    end
  end

  describe '#copy?' do
    let(:other_policy) { described_class.new other_user, dish }
    describe 'order in progress' do
      it 'is true for the user' do
        expect(subject.copy?).to be_truthy
      end
      it 'is true for the other user' do
        expect(other_policy.copy?).to be_truthy
      end
    end
    describe 'order ordered' do
      before do
        order.ordered!
      end
      it 'is false for the user' do
        expect(subject.copy?).to be_falsey
      end
      it 'is false for the other user' do
        expect(other_policy.copy?).to be_falsey
      end
    end
    describe 'order delivered' do
      before do
        order.delivered!
      end
      it 'is false for the user' do
        expect(subject.copy?).to be_falsey
      end
      it 'is false for the other user' do
        expect(other_policy.copy?).to be_falsey
      end
    end
  end
end
