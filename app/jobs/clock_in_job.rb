class ClockInJob
  include Sidekiq::Job

  def perform(user_name)
    return { success: false, error: "User #{user_name} not found" } if user_name.blank?
    
    user = User.find_by(name: user_name)
    return { success: false, error: "User #{user_name} not found" } unless user

    # Check if user is already clocked in
    current_clock_in = user.clock_ins.find_by(clock_out_time: nil)
    if current_clock_in
      return { success: false, error: "User #{user_name} is already clocked in" }
    end

    clock_in = user.clock_ins.create!(clock_in_time: Time.current)
    { 
      success: true, 
      message: "Successfully clocked in #{user_name}",
      clock_in_id: clock_in.id 
    }
  rescue => e
    { success: false, error: e.message }
  end
end