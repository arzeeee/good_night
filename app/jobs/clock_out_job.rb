class ClockOutJob
  include Sidekiq::Job

  def perform(user_name)
    return { success: false, error: "User #{user_name} not found" } if user_name.blank?
    
    user = User.find_by(name: user_name)
    return { success: false, error: "User #{user_name} not found" } unless user

    # Find the current clock in
    current_clock_in = user.clock_ins.find_by(clock_out_time: nil)
    if current_clock_in.nil?
      return { success: false, error: "User #{user_name} is not currently clocked in" }
    end

    current_clock_in.update!(clock_out_time: Time.current)
    { 
      success: true, 
      message: "Successfully clocked out #{user_name}",
      clock_in_id: current_clock_in.id 
    }
  rescue => e
    { success: false, error: e.message }
  end
end