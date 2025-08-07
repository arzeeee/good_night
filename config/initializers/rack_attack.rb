# Configuration for Rack::Attack
class Rack::Attack

  if Rails.env.test?
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  else
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
  end

  throttle('api/ip', limit: 5, period: 1.minute) do |req|
    if req.path.start_with?('/api/')
      req.ip
    end
  end

  self.throttled_responder = lambda do |env|
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => '60'
      },
      [{ 
        error: 'Rate limit exceeded',
        message: 'Too many requests. Maximum 5 requests per minute allowed.',
        retry_after_seconds: 60
      }.to_json]
    ]
  end

  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    if req.env['rack.attack.throttle_data']
      Rails.logger.warn "[Rack::Attack] Throttled request from #{req.ip} to #{req.path} (#{payload[:name]})"
    end
  end

end
