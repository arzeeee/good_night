class Api::ClockInsController < Api::BaseController
  before_action :validate_user_param, only: [:clock_in, :clock_out, :user_clock_ins]
  before_action :validate_follow_params, only: [:follow_user, :unfollow_user]

  # POST /api/clock_in
  def clock_in
    job_id = ClockInJob.perform_async(params[:user])
    render json: { 
      status: "accepted",
      message: "Clock in job started",
      job_id: job_id
    }, status: :accepted
  end

  # POST /api/clock_out
  def clock_out
    job_id = ClockOutJob.perform_async(params[:user])
    render json: { 
      status: "accepted",
      message: "Clock out job started",
      job_id: job_id
    }, status: :accepted
  end

  # GET /api/user_clock_ins
  def user_clock_ins
    user = User.find_or_create_by(name: params[:user])
    one_week_ago = 1.week.ago
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    
    clock_ins = user.clock_ins
            .where(created_at: one_week_ago..Time.current)
            .order(:created_at)
            .limit(per_page)
            .offset((page - 1) * per_page)

    if clock_ins.empty?
      render json: { 
        message: "User has no clock in time", 
        user: user.name,
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
        user: user.name,
        clock_ins: clock_ins_data 
      }
    end
  end

  # POST /api/follow_user
  def follow_user
    job_id = FollowUserJob.perform_async(params[:follower_name], params[:following_name])
    render json: { 
      status: "accepted",
      message: "Follow user job started",
      job_id: job_id
    }, status: :accepted
  end

  # POST /api/unfollow_user
  def unfollow_user
    job_id = UnfollowUserJob.perform_async(params[:follower_name], params[:following_name])
    render json: { 
      status: "accepted",
      message: "Unfollow user job started",
      job_id: job_id
    }, status: :accepted
  end

  # GET /api/followings_clock_ins
  def followings_clock_ins
    if params[:user].blank?
      render json: { error: "User parameter is required" }, status: :bad_request and return
    end
    
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

  # GET /api/job_status/:job_id
  def job_status
    job_id = params[:job_id]
    
    # For now, return a simple status since we don't have Sidekiq::Status
    render json: {
      job_id: job_id,
      status: "completed",
      message: "Job status retrieved"
    }
  end

  private

  def validate_user_param
    if params[:user].blank?
      render json: { error: "User parameter is required" }, status: :bad_request and return
    end
  end

  def validate_follow_params
    if params[:follower_name].blank? || params[:following_name].blank?
      render json: { error: "Follower name and following name are required" }, status: :bad_request and return
    end
  end
end
