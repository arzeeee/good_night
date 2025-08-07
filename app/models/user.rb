class User < ApplicationRecord
  validates :name, presence: true
  validates :name, format: { with: /\A[a-zA-Z0-9]+\z/, message: "can only contain letters and numbers" }

  has_many :active_followings, class_name: "Following", 
           foreign_key: "follower_id", 
           dependent: :delete_all
  
  has_many :passive_followings, class_name: "Following", 
           foreign_key: "following_id", 
           dependent: :delete_all
  
  has_many :following, through: :active_followings, source: :following
  has_many :followers, through: :passive_followings, source: :follower

  has_many :clock_ins, dependent: :destroy

  def assign_user(name)
    return User.find_or_create_by(name: name)
  end

  def follow(other_user)
    if other_user.is_a?(String)
      other_user = User.find_or_create_by(name: other_user)
    end
    following << other_user unless self == other_user
  end

  def unfollow(other_user)
    if other_user.is_a?(String)
      other_user = User.find_by(name: other_user)
      return unless other_user
    end
    following.delete(other_user)
  end

  def following?(other_user)
    if other_user.is_a?(String)
      other_user = User.find_by(name: other_user)
      return false unless other_user
    end
    following.include?(other_user)
  end
end
