require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user, name: "JohnDoe") }
  let(:other_user) { create(:user, name: "JaneDoe") }
  let(:third_user) { create(:user, name: "JameelaDoe") }

  describe 'validations' do
    context 'with valid names' do
      it 'saves user with valid alphanumeric name' do
        user = User.new(name: "john123")
        expect(user).to be_valid
        expect(user.save).to be true
      end

      it 'saves user with only letters' do
        user = User.new(name: "john")
        expect(user).to be_valid
        expect(user.save).to be true
      end

      it 'saves user with only numbers' do
        user = User.new(name: "123")
        expect(user).to be_valid
        expect(user.save).to be true
      end
    end

    context 'with invalid names' do
      it 'does not save user without name' do
        user = User.new
        expect(user).not_to be_valid
        expect(user.save).to be false
        expect(user.errors[:name]).to include("can't be blank")
      end

      it 'does not save user with empty name' do
        user = User.new(name: "")
        expect(user).not_to be_valid
        expect(user.save).to be false
        expect(user.errors[:name]).to include("can't be blank")
      end

      it 'does not save user with name containing spaces' do
        user = User.new(name: "john doe")
        expect(user).not_to be_valid
        expect(user.save).to be false
        expect(user.errors[:name]).to include("can only contain letters and numbers")
      end

      it 'does not save user with name containing special characters' do
        user = User.new(name: "john@doe")
        expect(user).not_to be_valid
        expect(user.save).to be false
        expect(user.errors[:name]).to include("can only contain letters and numbers")
      end

      it 'does not save user with name containing emoji' do
        user = User.new(name: "john😊doe")
        expect(user).not_to be_valid
        expect(user.save).to be false
        expect(user.errors[:name]).to include("can only contain letters and numbers")
      end
    end
  end

  describe 'associations' do
    it 'has many active_followings' do
      association = described_class.reflect_on_association(:active_followings)
      expect(association.macro).to eq :has_many
      expect(association.options[:class_name]).to eq 'Following'
      expect(association.options[:foreign_key]).to eq 'follower_id'
      expect(association.options[:dependent]).to eq :delete_all
    end

    it 'has many passive_followings' do
      association = described_class.reflect_on_association(:passive_followings)
      expect(association.macro).to eq :has_many
      expect(association.options[:class_name]).to eq 'Following'
      expect(association.options[:foreign_key]).to eq 'following_id'
      expect(association.options[:dependent]).to eq :delete_all
    end

    it 'has many following through active_followings' do
      association = described_class.reflect_on_association(:following)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :active_followings
      expect(association.options[:source]).to eq :following
    end

    it 'has many followers through passive_followings' do
      association = described_class.reflect_on_association(:followers)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :passive_followings
      expect(association.options[:source]).to eq :follower
    end
  end

  describe 'following functionality' do
    describe '#follow' do
      it 'allows a user to follow another user' do
        expect {
          user.follow(other_user.name)
        }.to change(user.following, :count).by(1)
        
        expect(user.following).to include(other_user)
      end

      it 'does not allow a user to follow themselves' do
        expect {
          user.follow(user.name)
        }.not_to change(user.following, :count)
        
        expect(user.following).not_to include(user)
      end

        it 'does not create duplicate following relationships' do
        user.follow(other_user.name)
        expect {
            user.follow(other_user.name)
        }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Follower You are already following this user")
        end
    end

    describe '#unfollow' do
      it 'allows a user to unfollow another user' do
        user.follow(other_user.name)
        
        expect {
          user.unfollow(other_user.name)
        }.to change(user.following, :count).by(-1)
        
        expect(user.following).not_to include(other_user)
      end

      it 'does nothing if user is not following the other user' do
        expect {
          user.unfollow(other_user.name)
        }.not_to change(user.following, :count)
      end
    end

    describe '#following?' do
      it 'returns true when user is following another user' do
        user.follow(other_user.name)
        expect(user.following?(other_user.name)).to be true
      end

      it 'returns false when user is not following another user' do
        expect(user.following?(other_user.name)).to be false
      end

      it 'returns false when checking if user is following themselves' do
        expect(user.following?(user.name)).to be false
      end
    end

    describe 'follower relationships' do
      it 'correctly identifies followers' do
        other_user.follow(user.name)
        third_user.follow(user.name)
        
        expect(user.followers).to include(other_user, third_user)
        expect(user.followers.count).to eq(2)
      end

      it 'correctly identifies following' do
        user.follow(other_user.name)
        user.follow(third_user.name)
        
        expect(user.following).to include(other_user, third_user)
        expect(user.following.count).to eq(2)
      end
    end

    describe 'dependent destroy' do
      it 'destroys following relationships when user is destroyed' do
        user.follow(other_user.name)
        other_user.follow(third_user.name)
        
        expect {
          user.destroy
        }.to change(Following, :count).by(-1)
      end

      it 'destroys follower relationships when user is destroyed' do
        other_user.follow(user.name)
        third_user.follow(user.name)
        
        expect {
          user.destroy
        }.to change(Following, :count).by(-2)
      end
    end
  end
end
