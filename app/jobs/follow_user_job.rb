class FollowUserJob
  include Sidekiq::Job

  def perform(follower_name, following_name)
    return { success: false, error: "Follower #{follower_name} not found" } if follower_name.blank?
    return { success: false, error: "Following user #{following_name} not found" } if following_name.blank?
    
    # Check if trying to follow self
    if follower_name == following_name
      return { success: false, error: "User cannot follow themselves" }
    end

    follower = User.find_by(name: follower_name)
    return { success: false, error: "Follower #{follower_name} not found" } unless follower

    following_user = User.find_by(name: following_name)
    return { success: false, error: "Following user #{following_name} not found" } unless following_user

    # Check if already following
    existing_follow = Following.find_by(follower: follower, following: following_user)
    if existing_follow
      return { success: false, error: "#{follower_name} is already following #{following_name}" }
    end

    Following.create!(follower: follower, following: following_user)
    { 
      success: true, 
      message: "#{follower_name} is now following #{following_name}"
    }
  rescue => e
    { success: false, error: e.message }
  end
end
