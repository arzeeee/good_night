require 'rails_helper'

RSpec.describe Following, type: :model do
  let(:follower) { create(:user, name: "JohnDoe") }
  let(:following_user) { create(:user, name: "JaneDoe") }

  describe 'associations' do
    it 'belongs to follower' do
      association = described_class.reflect_on_association(:follower)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq 'User'
      expect(association.options[:foreign_key]).to eq 'follower_id'
    end

    it 'belongs to following' do
      association = described_class.reflect_on_association(:following)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:class_name]).to eq 'User'
      expect(association.options[:foreign_key]).to eq 'following_id'
    end
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid with valid follower and following users' do
        following = Following.new(follower: follower, following: following_user)
        expect(following).to be_valid
      end
    end

    context 'presence validations' do
      it 'requires follower_id' do
        following = Following.new(following: following_user)
        expect(following).not_to be_valid
        expect(following.errors[:follower_id]).to include("can't be blank")
      end

      it 'requires following_id' do
        following = Following.new(follower: follower)
        expect(following).not_to be_valid
        expect(following.errors[:following_id]).to include("can't be blank")
      end
    end

    context 'uniqueness validation' do
      it 'prevents duplicate following relationships' do
        Following.create!(follower: follower, following: following_user)
        duplicate_following = Following.new(follower: follower, following: following_user)
        
        expect(duplicate_following).not_to be_valid
        expect(duplicate_following.errors[:follower_id]).to include("You are already following this user")
      end

      it 'allows different users to follow the same user' do
        another_follower = create(:user, name: "bob789")
        Following.create!(follower: follower, following: following_user)
        
        different_following = Following.new(follower: another_follower, following: following_user)
        expect(different_following).to be_valid
      end

      it 'allows the same user to follow different users' do
        another_following_user = create(:user, name: "charlie101")
        Following.create!(follower: follower, following: following_user)
        
        different_following = Following.new(follower: follower, following: another_following_user)
        expect(different_following).to be_valid
      end
    end

    context 'self-follow validation' do
      it 'prevents a user from following themselves' do
        self_following = Following.new(follower: follower, following: follower)
        expect(self_following).not_to be_valid
        expect(self_following.errors[:following_id]).to include("cannot follow yourself")
      end
    end
  end

  describe 'database operations' do
    it 'can create a following relationship' do
      expect {
        Following.create!(follower: follower, following: following_user)
      }.to change(Following, :count).by(1)
    end

    it 'can delete a following relationship' do
      Following.create!(follower: follower, following: following_user)
      
      expect {
        Following.where(follower_id: follower.id, following_id: following_user.id).delete_all
      }.to change(Following, :count).by(-1)
    end

    it 'cascades deletion when follower is deleted' do
      Following.create!(follower: follower, following: following_user)
      
      expect {
        follower.destroy
      }.to change(Following, :count).by(-1)
    end

    it 'cascades deletion when following user is deleted' do
      Following.create!(follower: follower, following: following_user)
      
      expect {
        following_user.destroy
      }.to change(Following, :count).by(-1)
    end
  end
end
