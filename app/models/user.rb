class User < ApplicationRecord
  validates :name, presence: true
  validates :name, format: { with: /\A[a-zA-Z0-9]+\z/, message: "can only contain letters and numbers" }
end
