require "net/http"
require "json"

class HueService
  BRIDGE_IP = ENV.fetch("HUE_BRIDGE_IP", "192.168.1.100")
  API_KEY   = ENV.fetch("HUE_API_KEY", "demo-key")
  LIGHT_ID  = ENV.fetch("HUE_LIGHT_ID", "1")

  def self.illuminate(brightness: 100, color: "warm")
    bri = (brightness.to_f / 100 * 254).to_i.clamp(1, 254)
    hue = color == "cool" ? 46920 : 8000

    put_state(on: true, bri: bri, hue: hue, sat: 200)
  end

  def self.turn_off
    put_state(on: false)
  end

  def self.set_color_hex(hex)
    hex = hex.delete_prefix("#")
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)

    rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
    max = [rf, gf, bf].max
    min = [rf, gf, bf].min
    delta = max - min

    h = if delta == 0 then 0
    elsif max == rf then 60 * (((gf - bf) / delta) % 6)
    elsif max == gf then 60 * (((bf - rf) / delta) + 2)
    else                  60 * (((rf - gf) / delta) + 4)
    end

    s = max == 0 ? 0 : delta / max
    hue = (h / 360.0 * 65535).to_i.clamp(0, 65535)
    sat = (s * 254).to_i.clamp(0, 254)
    bri = (max * 254).to_i.clamp(1, 254)

    put_state(on: true, hue: hue, sat: sat, bri: bri)
  end

  def self.set_color(color_name)
    hue_map = {
      "red"    => 0,
      "yellow" => 12750,
      "warm"   => 8000,
      "green"  => 25500,
      "blue"   => 46920,
      "purple" => 56100,
      "pink"   => 62000
    }
    hue = hue_map[color_name] || 8000
    put_state(on: true, hue: hue, sat: 254, bri: 200)
  end

  def self.put_state(state)
    if ENV["HUE_MOCK"] == "true"
      Rails.logger.info "[HueMock] PUT /lights/#{LIGHT_ID}/state #{state.to_json}"
      return { success: true, mock: true, state: state }
    end

    uri = URI("https://#{BRIDGE_IP}/api/#{API_KEY}/lights/#{LIGHT_ID}/state")
    Rails.logger.info "[Hue] PUT #{uri} #{state.to_json}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.open_timeout = 3
    req = Net::HTTP::Put.new(uri.path, "Content-Type" => "application/json")
    req.body = state.to_json
    res = http.request(req)

    Rails.logger.info "[Hue] Response #{res.code} #{res.body}"
    JSON.parse(res.body)
  rescue => e
    Rails.logger.error "[Hue] Error: #{e.class} #{e.message}"
    { error: e.message }
  end
end
