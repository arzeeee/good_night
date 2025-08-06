class Following < ApplicationRecord
  self.primary_key = [:follower_id, :following_id]
  
  belongs_to :follower, class_name: 'User', foreign_key: 'follower_id'
  belongs_to :following, class_name: 'User', foreign_key: 'following_id'

  validates :follower_id, presence: true
  validates :following_id, presence: true
  validates :follower_id, uniqueness: { scope: :following_id, message: "You are already following this user" }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    errors.add(:following_id, "cannot follow yourself") if follower_id == following_id
  end
end
