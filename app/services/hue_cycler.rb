class HueCycler
  COLORS = [
    { name: "warm",   hue: 8000,  sat: 200 },
    { name: "yellow", hue: 12750, sat: 220 },
    { name: "green",  hue: 25500, sat: 254 },
    { name: "blue",   hue: 46920, sat: 254 },
    { name: "purple", hue: 56100, sat: 254 },
    { name: "pink",   hue: 62000, sat: 220 },
    { name: "red",    hue: 0,     sat: 254 },
  ].freeze

  @thread        = nil
  @breath_thread = nil
  @running       = false
  @breathing     = false
  @mutex         = Mutex.new

  class << self
    def breathe(min_bri: 20, max_bri: 220, step_interval: 0.8, hue: 46920, sat: 200)
      stop_breathing if breathing?
      stop if running?

      @breathing = true
      transition = (step_interval * 10).to_i

      @breath_thread = Thread.new do
        bri   = min_bri
        delta = 25
        loop do
          break unless @breathing
          HueService.put_state(on: true, hue: hue, sat: sat, bri: bri, transitiontime: transition)
          sleep step_interval
          bri += delta
          delta = -delta if bri >= max_bri || bri <= min_bri
          bri = bri.clamp(min_bri, max_bri)
        end
      end
      true
    end

    def stop_breathing
      @mutex.synchronize do
        @breathing = false
        @breath_thread&.join(2)
        @breath_thread = nil
      end
      true
    end

    def breathing?
      @breathing && @breath_thread&.alive?
    end

    def start(interval: 5, brightness: 80)
      stop if running?

      @running = true
      bri = (brightness.to_f / 100 * 254).to_i.clamp(1, 254)
      transition = (interval * 10).to_i

      @thread = Thread.new do
        COLORS.cycle do
          break unless @running
          color = COLORS.sample
          HueService.put_state(
            on: true,
            hue: color[:hue],
            sat: color[:sat],
            bri: bri,
            transitiontime: transition
          )
          sleep interval
        end
      end
      true
    end

    def stop
      kill
      HueService.put_state(on: true, hue: 8000, sat: 200, bri: 200, transitiontime: 10)
      true
    end

    def kill
      @mutex.synchronize do
        @running = false
        @thread&.join(2)
        @thread = nil
      end
      true
    end

    def running?
      @running && @thread&.alive?
    end
  end
end
