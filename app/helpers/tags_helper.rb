module TagsHelper
  # "#RRGGBB" → "rgba(r,g,b,alpha)"
  def tag_rgba_bg(hex, alpha = 0.12)
    return "rgba(107,114,128,0.12)" if hex.blank? # slate-500 fallback
    hex = hex.delete("#")
    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    "rgba(#{r},#{g},#{b},#{alpha})"
  rescue
    "rgba(107,114,128,0.12)"
  end
end
