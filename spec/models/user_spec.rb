require 'rails_helper'

RSpec.describe User, type: :model do
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
end
