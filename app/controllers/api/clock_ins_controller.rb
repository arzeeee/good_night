class Api::ClockInsController < Api::BaseController
  before_action :find_or_create_user, only: [:clock_in, :clock_out, :user_clock_ins]
  before_action :find_users_for_follow, only: [:follow_user, :unfollow_user]

  # POST /api/clock_in
  def clock_in
    existing_clock_in = @user.clock_ins.where(clock_out_time: nil).first
    
    if existing_clock_in
      render json: { 
        message: "User already clocked in", 
        user: @user.name,
        clock_in_time: existing_clock_in.clock_in_time 
      }, status: :unprocessable_entity
    else
      clock_in = @user.clock_ins.create!(clock_in_time: Time.current)
      render json: { 
        message: "Successfully clocked in", 
        user: @user.name,
        clock_in_time: clock_in.clock_in_time 
      }, status: :created
    end
  end

  # POST /api/clock_out
  def clock_out
    active_clock_in = @user.clock_ins.where(clock_out_time: nil).first
    
    if active_clock_in.nil?
      render json: { 
        message: "User already clocked out", 
        user: @user.name 
      }, status: :unprocessable_entity
    else
      active_clock_in.update!(clock_out_time: Time.current)
      render json: { 
        message: "Successfully clocked out", 
        user: @user.name,
        clock_out_time: active_clock_in.clock_out_time,
        duration_seconds: active_clock_in.duration_seconds 
      }, status: :ok
    end
  end

  # GET /api/user_clock_ins
  def user_clock_ins
    one_week_ago = 1.week.ago
    clock_ins = @user.clock_ins
                     .where(created_at: one_week_ago..Time.current)
                     .order(:created_at)

    if clock_ins.empty?
      render json: { 
        message: "User has no clock in time", 
        user: @user.name,
        clock_ins: [] 
      }
    else
      clock_ins_data = clock_ins.map do |clock_in|
        {
          clock_in_time: clock_in.clock_in_time,
          clock_out_time: clock_in.clock_out_time,
          duration_seconds: clock_in.clocked_out? ? clock_in.duration_seconds : 0
        }
      end

      render json: { 
        user: @user.name,
        clock_ins: clock_ins_data 
      }
    end
  end

  # POST /api/follow_user
  def follow_user
    follower = @follower_user
    following = @following_user

    if following.nil?
      render json: { 
        message: "#{params[:following_name]} does not exist" 
      }, status: :not_found
    elsif follower.following?(following)
      render json: { 
        message: "#{follower.name} is already following #{following.name}" 
      }, status: :unprocessable_entity
    else
      follower.follow(following)
      render json: { 
        message: "#{follower.name} is now following #{following.name}" 
      }, status: :created
    end
  end

  # POST /api/unfollow_user
  def unfollow_user
    follower = @follower_user
    following = @following_user

    if following.nil?
      render json: { 
        message: "#{params[:following_name]} does not exist" 
      }, status: :not_found
    elsif !follower.following?(following)
      render json: { 
        message: "#{follower.name} is not following #{following.name}" 
      }, status: :unprocessable_entity
    else
      follower.unfollow(following)
      render json: { 
        message: "#{follower.name} has unfollowed #{following.name}" 
      }, status: :ok
    end
  end

  # GET /api/followings_clock_ins
  def followings_clock_ins
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    
    user = User.find_or_create_by(name: params[:user])
    one_week_ago = 1.week.ago

    # Get all followings' clock_ins from last week, sorted by duration_seconds
    followings_clock_ins = ClockIn.joins(user: :passive_followings)
                                  .where(followings: { follower_id: user.id })
                                  .where(clock_ins: { created_at: one_week_ago..Time.current })
                                  .where.not(clock_ins: { clock_out_time: nil })
                                  .order(duration_seconds: :desc)
                                  .limit(per_page)
                                  .offset((page - 1) * per_page)

    clock_ins_data = followings_clock_ins.map do |clock_in|
      {
        user_name: clock_in.user.name,
        clock_in_time: clock_in.clock_in_time,
        clock_out_time: clock_in.clock_out_time,
        duration_seconds: clock_in.duration_seconds
      }
    end

    total_count = ClockIn.joins(user: :passive_followings)
                         .where(followings: { follower_id: user.id })
                         .where(clock_ins: { created_at: one_week_ago..Time.current })
                         .where.not(clock_ins: { clock_out_time: nil })
                         .count

    render json: { 
      user: user.name,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: (total_count.to_f / per_page).ceil,
      followings_clock_ins: clock_ins_data 
    }
  end

  private

  def find_or_create_user
    if params[:user].blank?
      render json: { message: "user is missing" }, status: :bad_request and return
    end
    @user = User.find_or_create_by!(name: params[:user])
  end

  def find_users_for_follow
    @follower_user = User.find_or_create_by(name: params[:follower_name])
    @following_user = User.find_by(name: params[:following_name])
  end
end
