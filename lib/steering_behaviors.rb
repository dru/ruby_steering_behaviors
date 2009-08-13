class SteeringBehaviors
  attr_reader :behaviors
  
  # For debugging
  attr_reader :force, :predicted, :distance_to_target, :look_ahead_time
  
  def initialize(vehicle)
    @vehicle = vehicle
    @force = Vector2d.new
    @behaviors = Hash.new

    initialize_debug_vars
  end

  def initialize_debug_vars
    @to_debug = Hash.new
  end

  def seek(target_pos)
    desired_velocity = (target_pos - @vehicle.pos).normalize * @vehicle.max_speed
    return desired_velocity - @vehicle.vel
  end

  def flee(target_pos)
    desired_velocity = (@vehicle.pos - target_pos).normalize * @vehicle.max_speed
    return desired_velocity - @vehicle.vel
  end

  def arrive(target_pos, deceleration = :normal)
    dec_opts = {
      :fast => 0.5,
      :normal => 1,
      :slow => 2
    }
    to_target = target_pos - @vehicle.pos
    @distance_to_target = to_target.length

    if @distance_to_target > 0
      deceleration_tweaker = 1.2
      speed = @distance_to_target / (deceleration_tweaker*dec_opts[deceleration])
      speed = [speed, @vehicle.max_speed].min
      desired_velocity = to_target * speed / @distance_to_target
      return desired_velocity - @vehicle.vel
    end
    return Vector2d.new(0,0)
  end

  def pursuit(evader)
    to_evader = evader.pos - @vehicle.pos
    relative_heading = @vehicle.heading.dot(evader.heading)

    if to_evader.dot(@vehicle.heading) > 0 && relative_heading < -0.95
      @predicted = nil
      @look_ahead_time = nil
      return seek(evader.pos)
    end
    
    @look_ahead_time = (to_evader / (@vehicle.max_speed + evader.vel.length)).length
    @predicted = evader.pos + evader.vel * @look_ahead_time
    return seek(@predicted)
  end

  def calculate
    @force.zero!
    if @behaviors[:seek]
      @force = seek(@vehicle.target) if @vehicle.target
    end

    if @behaviors[:flee]
      @force = flee(@vehicle.target) if @vehicle.target
    end

    if @behaviors[:arrive]
      @force = arrive(@vehicle.target, :fast) if @vehicle.target
    end

    if @behaviors[:pursuit]
      @force = pursuit(@vehicle.evader) if @vehicle.evader
    end
    
    return @force
  end

  def debug(var, f_string, m_name = nil)
    res = send(var)
    if res && m_name
      Render.list_item("#{format(f_string, send(var).send(m_name))}  @#{var} #{send(var)}")
    elsif res
      Render.list_item("@#{var} #{format(f_string, send(var))}")
    end
  end
end
