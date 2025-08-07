class UnfollowUserJob
  include Sidekiq::Job

  def perform(follower_name, following_name)
    return { success: false, error: "Follower #{follower_name} not found" } if follower_name.blank?
    return { success: false, error: "Following user #{following_name} not found" } if following_name.blank?
    
    follower = User.find_by(name: follower_name)
    return { success: false, error: "Follower #{follower_name} not found" } unless follower

    following_user = User.find_by(name: following_name)
    return { success: false, error: "Following user #{following_name} not found" } unless following_user

    # Check if currently following
    existing_follow = Following.find_by(follower: follower, following: following_user)
    unless existing_follow
      return { success: false, error: "#{follower_name} is not following #{following_name}" }
    end

    existing_follow.destroy!
    { 
      success: true, 
      message: "#{follower_name} has unfollowed #{following_name}"
    }
  rescue => e
    { success: false, error: e.message }
  end
end
