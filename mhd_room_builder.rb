# encoding: UTF-8
# MHD Room Builder v4.0 - Smart Edit Engine
# SketchUp Ruby Plugin

require 'sketchup.rb'
require 'json'
require 'tmpdir'
require 'zlib'
begin
require File.join(__dir__, 'language', 'language_engine')
rescue LoadError
end
begin
require 'securerandom'
rescue LoadError
end

module MHD_RoomBuilder_Context
extend self

MENU_BUILD = 'بناء الحوائط'
DICT = 'MHD_ROOM_BUILDER'
PREF_KEY = 'MHD_ROOM_BUILDER_UI'
LOGO_URL = 'https://mhdesign-eg.com/SKETCHUP/components/logo3.png'

# -------------------------
# Helpers
# -------------------------
def ts(text)
source = text.to_s
return source unless defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:load_dictionary)
data = MHDESIGN::Language.load_dictionary
map = data['room_builder']
return source unless map.is_a?(Hash)
exact = map[source]
return exact.to_s unless exact.nil? || exact.to_s.empty?
result = source.dup
map.keys.sort_by { |key| -key.to_s.length }.each do |key|
next if key.to_s.empty?
result = result.gsub(key.to_s, map[key].to_s)
end
result
rescue
text.to_s
end

def ui_direction
if defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:direction)
MHDESIGN::Language.direction
else
'rtl'
end
rescue
'rtl'
end

def ui_locale
if defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:current)
MHDESIGN::Language.current
else
'ar_EG'
end
rescue
'ar_EG'
end

def enabled_value?(value)
%w[yes true on 1 نعم].include?(value.to_s.strip.downcase)
end

def longitudinal_value?(value)
%w[longitudinal طولي].include?(value.to_s.strip.downcase)
end

def tag(model, name)
name = name.to_s
name = 'MHD' if name.strip.empty?
model.layers[name] || model.layers.add(name)
end

def uuid
defined?(SecureRandom) ? SecureRandom.uuid : "#{Time.now.to_i}-#{rand(999999)}"
end

def set_attrs(entity, data)
data.each { |k, v| entity.set_attribute(DICT, k, v) }
end

def get_attr(entity, key)
entity.get_attribute(DICT, key)
end

def selected_face
Sketchup.active_model.selection.grep(Sketchup::Face).first
end

def pt_to_s(p)
[p.x.to_f, p.y.to_f, p.z.to_f].join('|')
end

def signed_area_xy(pts)
area = 0.0
pts.each_with_index do |p, i|
q = pts[(i + 1) % pts.length]
area += (p.x * q.y) - (q.x * p.y)
end
area / 2.0
end

def line_intersection_2d(p1, d1, p2, d2)
Geom.intersect_line_line([p1, d1], [p2, d2])
end

def add_prism(ents, p1, p2, p3, p4, z_offset, height)
return if height <= 0
a = p1.offset(Z_AXIS, z_offset)
b = p2.offset(Z_AXIS, z_offset)
c = p3.offset(Z_AXIS, z_offset)
d = p4.offset(Z_AXIS, z_offset)
face = ents.add_face(a, b, c, d)
return unless face
face.reverse! if face.normal.z < 0
face.pushpull(height)
end

def read_pref(key, default)
Sketchup.read_default(PREF_KEY, key, default)
end

def write_pref(key, value)
Sketchup.write_default(PREF_KEY, key, value)
end

def saved_values
{
'room_name' => read_pref('room_name', ts('المطبخ')).to_s,
'wall_h'    => read_pref('wall_h', 280).to_f,
'wall_t'    => read_pref('wall_t', 12).to_f,
'floor_t'   => read_pref('floor_t', 10).to_f,
'ceil_t'    => read_pref('ceil_t', 10).to_f,
'create_floor' => read_pref('create_floor', 'نعم').to_s,
'create_ceiling' => read_pref('create_ceiling', 'نعم').to_s,
'ceiling_pattern' => read_pref('ceiling_pattern', 'flat').to_s,
'perimeter_width' => read_pref('perimeter_width', 45).to_f,
'perimeter_drop' => read_pref('perimeter_drop', 18).to_f,
'center_inset' => read_pref('center_inset', 45).to_f,
'center_drop' => read_pref('center_drop', 18).to_f,
'center_led_inset' => read_pref('center_led_inset', 45).to_f,
'center_led_drop' => read_pref('center_led_drop', 18).to_f,
'center_led_thickness' => read_pref('center_led_thickness', 3).to_f,
'combo_cove_width' => read_pref('combo_cove_width', 35).to_f,
'combo_cove_drop' => read_pref('combo_cove_drop', 18).to_f,
'combo_cove_lip_width' => read_pref('combo_cove_lip_width', 6).to_f,
'combo_cove_lip_height' => read_pref('combo_cove_lip_height', 2).to_f,
'combo_center_inset' => read_pref('combo_center_inset', 75).to_f,
'combo_center_drop' => read_pref('combo_center_drop', 18).to_f,
'combo_center_thickness' => read_pref('combo_center_thickness', 3).to_f,
'strip_direction' => longitudinal_value?(read_pref('strip_direction', 'longitudinal')) ? 'longitudinal' : 'transverse',
'strip_count' => read_pref('strip_count', 2).to_i,
'strip_width' => read_pref('strip_width', 35).to_f,
'strip_gap' => read_pref('strip_gap', 50).to_f,
'strip_drop' => read_pref('strip_drop', 15).to_f,
'cove_inset' => read_pref('cove_inset', 35).to_f,
'cove_drop' => read_pref('cove_drop', 18).to_f,
'cove_lip_width' => read_pref('cove_lip_width', 6).to_f,
'cove_lip_height' => read_pref('cove_hand_thickness', 2).to_f,
'drop_reference' => read_pref('drop_reference', 'below_wall').to_s,
'light_enabled' => read_pref('light_enabled', 'لا').to_s,
'light_mode' => read_pref('light_mode', 'both').to_s,
'light_inset' => read_pref('light_inset', 8).to_f,
'light_width' => read_pref('light_width', 2).to_f,
'light_depth' => read_pref('light_depth', 0.5).to_f,
'light_margin' => read_pref('light_margin', 0).to_f,
'light_color' => read_pref('light_color', '#ffd27a').to_s,
'glow_intensity' => read_pref('glow_intensity', 70).to_f,
'glow_size' => read_pref('glow_size', 15).to_f
}
end

def offset_polygon(pts, distance)
return nil if pts.nil? || pts.length < 3
result = []
count = pts.length
count.times do |i|
prev_pt = pts[(i - 1) % count]
curr_pt = pts[i]
next_pt = pts[(i + 1) % count]
d1 = prev_pt.vector_to(curr_pt)
d2 = curr_pt.vector_to(next_pt)
return nil if d1.length < 0.1.mm || d2.length < 0.1.mm
d1.normalize!
d2.normalize!
n1 = Z_AXIS.cross(d1)
n2 = Z_AXIS.cross(d2)
n1.normalize!
n2.normalize!
n1.length = distance
n2.length = distance
l1 = prev_pt.offset(n1)
l2 = curr_pt.offset(n2)
intersection = line_intersection_2d(l1, d1, l2, d2)
intersection ||= curr_pt.offset(n2)
result << intersection
end
result
rescue
nil
end

def polygon_usable?(pts)
return false if pts.nil? || pts.length < 3
signed_area_xy(pts).abs > 1.cm * 1.cm
end

def add_poly_component(model, parent_ents, name, layer_name, pts, z, height, attrs = {}, material = nil)
return nil unless polygon_usable?(pts) && height > 0
definition = model.definitions.add("#{name}_#{Time.now.to_i}_#{rand(99999)}")
raised = pts.map { |p| Geom::Point3d.new(p.x, p.y, z) }
face = definition.entities.add_face(raised)
return nil unless face
face.reverse! if face.normal.z < 0
face.pushpull(height)
definition.entities.grep(Sketchup::Face).each { |f| f.material = material if material }
instance = parent_ents.add_instance(definition, Geom::Transformation.new)
instance.name = name
instance.layer = layer_name.to_s.empty? ? model.layers[0] : tag(model, layer_name)
set_attrs(instance, attrs.merge('UUID' => uuid))
instance
end

def add_ring_component(model, parent_ents, name, layer_name, outer_pts, inner_pts, z, height, attrs = {}, material = nil)
return nil unless polygon_usable?(outer_pts) && polygon_usable?(inner_pts) && height > 0
definition = model.definitions.add("#{name}_#{Time.now.to_i}_#{rand(99999)}")
outer = outer_pts.map { |p| Geom::Point3d.new(p.x, p.y, z) }
inner = inner_pts.map { |p| Geom::Point3d.new(p.x, p.y, z) }
outer_face = definition.entities.add_face(outer)
return nil unless outer_face
outer_face.reverse! if outer_face.normal.z < 0
inner_face = definition.entities.add_face(inner)
inner_face.erase! if inner_face && inner_face.valid?
ring_face = definition.entities.grep(Sketchup::Face).find { |f| f.valid? && f.normal.z.abs > 0.9 }
return nil unless ring_face
ring_face.reverse! if ring_face.normal.z < 0
ring_face.pushpull(height)
definition.entities.grep(Sketchup::Face).each { |f| f.material = material if material }
instance = parent_ents.add_instance(definition, Geom::Transformation.new)
instance.name = name
instance.layer = layer_name.to_s.empty? ? model.layers[0] : tag(model, layer_name)
set_attrs(instance, attrs.merge('UUID' => uuid))
instance
end

def led_material(model, hex, dark = false)
name = dark ? 'MHD LED Groove' : "MHD LED #{hex}"
mat = model.materials[name] || model.materials.add(name)
if dark
mat.color = Sketchup::Color.new(25, 28, 30)
else
value = hex.to_s.delete('#')
value = 'ffd27a' unless value.match?(/\A[0-9a-fA-F]{6}\z/)
mat.color = Sketchup::Color.new(value[0,2].to_i(16), value[2,2].to_i(16), value[4,2].to_i(16))
mat.alpha = 0.92
end
mat
end

def png_chunk(type, data)
[data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
end

def gradient_texture_path(hex, intensity)
value = hex.to_s.delete('#')
value = 'ffd27a' unless value.match?(/\A[0-9a-fA-F]{6}\z/)
strength = [[intensity.to_f, 0.0].max, 100.0].min
path = File.join(Dir.tmpdir, "mhd_ceiling_glow_v4_#{value}_#{strength.round}.png")
return path if File.exist?(path)
r = value[0,2].to_i(16)
g = value[2,2].to_i(16)
b = value[4,2].to_i(16)
width = 4
height = 256
raw = ''.b
height.times do |y|
t = y.to_f / (height - 1)
alpha = y < 6 ? 0 : (255.0 * strength / 100.0 * (t ** 2.25)).round
raw << "\x00".b
width.times { raw << [r, g, b, alpha].pack('C4') }
end
png = "\x89PNG\r\n\x1a\n".b
png << png_chunk('IHDR', [width, height, 8, 6, 0, 0, 0].pack('NNCCCCC'))
png << png_chunk('IDAT', Zlib::Deflate.deflate(raw, Zlib::BEST_COMPRESSION))
png << png_chunk('IEND', ''.b)
File.binwrite(path, png)
path
rescue
nil
end

def gradient_material(model, hex, intensity)
value = hex.to_s.delete('#')
value = 'ffd27a' unless value.match?(/\A[0-9a-fA-F]{6}\z/)
name = "MHD Smooth Glow V4 #{value} #{intensity.to_f.round}"
mat = model.materials[name] || model.materials.add(name)
path = gradient_texture_path(value, intensity)
mat.texture = path if path && File.exist?(path)
selected_color = Sketchup::Color.new(
value[0,2].to_i(16), value[2,2].to_i(16), value[4,2].to_i(16)
)
mat.color = selected_color
if defined?(Sketchup::Material::COLORIZE_TINT) && mat.respond_to?(:colorize_type=)
mat.colorize_type = Sketchup::Material::COLORIZE_TINT
end
mat.alpha = 1.0
mat
end

def add_vertical_gradient_glow(model, parent_ents, room_name, path_pts,
source_z, glow_size, color, intensity, attrs,
direction = :down)
return nil unless polygon_usable?(path_pts) && glow_size > 0 && intensity > 0
material = gradient_material(model, color, intensity)
return nil unless material && material.texture
definition = model.definitions.add("تأثير_إضاءة_ناعم_#{Time.now.to_i}_#{rand(99999)}")
count = path_pts.length
count.times do |i|
a = path_pts[i]
b = path_pts[(i + 1) % count]
next if a.distance(b) < 1.mm
start_z = direction == :up ? source_z + 0.3.mm : source_z - 0.3.mm
finish_z = direction == :up ? source_z + glow_size : source_z - glow_size
p1 = Geom::Point3d.new(a.x, a.y, start_z)
p2 = Geom::Point3d.new(b.x, b.y, start_z)
p3 = Geom::Point3d.new(b.x, b.y, finish_z)
p4 = Geom::Point3d.new(a.x, a.y, finish_z)
face = definition.entities.add_face(p1, p2, p3, p4)
next unless face
uv1 = Geom::Point3d.new(0, 0, 1)
uv2 = Geom::Point3d.new(1, 0, 1)
uv3 = Geom::Point3d.new(1, 0.996, 1)
uv4 = Geom::Point3d.new(0, 0.996, 1)
mapping = [p1, uv1, p2, uv2, p3, uv3, p4, uv4]
begin
face.position_material(material, mapping, true)
face.position_material(material, mapping, false)
rescue
face.material = material
face.back_material = material
end
face.edges.each do |edge|
edge.hidden = true
edge.soft = true
edge.smooth = true
end
end
definition.entities.grep(Sketchup::Edge).each do |edge|
edge.hidden = true
edge.soft = true
edge.smooth = true
end
instance = parent_ents.add_instance(definition, Geom::Transformation.new)
instance.name = ts('تأثير الإضاءة المتدرج')
instance.layer = model.layers[0]
set_attrs(instance, attrs.merge('UUID' => uuid, 'النوع' => 'تأثير إضاءة متدرج'))
instance
end

def add_horizontal_gradient_glow(model, parent_ents, room_name, source_pts,
z, glow_size, color, intensity, attrs,
spread_direction = :inward)
return nil unless polygon_usable?(source_pts) && glow_size > 0 && intensity > 0
offset_distance = spread_direction == :outward ? -glow_size : glow_size
fade_pts = offset_polygon(source_pts, offset_distance)
return nil unless polygon_usable?(fade_pts) && fade_pts.length == source_pts.length
material = gradient_material(model, color, intensity)
return nil unless material && material.texture
definition = model.definitions.add("تأثير_يد_مخفي_أفقي_#{Time.now.to_i}_#{rand(99999)}")
count = source_pts.length
count.times do |i|
a = source_pts[i]
b = source_pts[(i + 1) % count]
c = fade_pts[(i + 1) % count]
d = fade_pts[i]
p1 = Geom::Point3d.new(a.x, a.y, z + 0.4.mm)
p2 = Geom::Point3d.new(b.x, b.y, z + 0.4.mm)
p3 = Geom::Point3d.new(c.x, c.y, z + 0.4.mm)
p4 = Geom::Point3d.new(d.x, d.y, z + 0.4.mm)
face = definition.entities.add_face(p1, p2, p3, p4)
next unless face
mapping = [
p1, Geom::Point3d.new(0, 0, 1),
p2, Geom::Point3d.new(1, 0, 1),
p3, Geom::Point3d.new(1, 0.996, 1),
p4, Geom::Point3d.new(0, 0.996, 1)
]
begin
face.position_material(material, mapping, true)
face.position_material(material, mapping, false)
rescue
face.material = material
face.back_material = material
end
face.edges.each do |edge|
edge.hidden = true
edge.soft = true
edge.smooth = true
end
end
definition.entities.grep(Sketchup::Edge).each do |edge|
edge.hidden = true
edge.soft = true
edge.smooth = true
end
instance = parent_ents.add_instance(definition, Geom::Transformation.new)
instance.name = ts('تأثير إضاءة اليد الأفقي')
instance.layer = model.layers[0]
set_attrs(instance, attrs.merge('UUID' => uuid, 'النوع' => 'إضاءة يد مخفية أفقية'))
instance
end

def rect_points(min_x, min_y, max_x, max_y, z = 0)
[Geom::Point3d.new(min_x,min_y,z), Geom::Point3d.new(max_x,min_y,z),
Geom::Point3d.new(max_x,max_y,z), Geom::Point3d.new(min_x,max_y,z)]
end

def save_values(data)
%w[room_name wall_h wall_t floor_t ceil_t create_floor create_ceiling ceiling_pattern
perimeter_width perimeter_drop center_inset center_drop
center_led_inset center_led_drop center_led_thickness strip_direction strip_count
combo_cove_width combo_cove_drop combo_cove_lip_width combo_cove_lip_height
combo_center_inset combo_center_drop combo_center_thickness
strip_width strip_gap strip_drop cove_inset cove_drop cove_lip_width cove_lip_height
drop_reference light_enabled light_mode light_inset light_width
light_depth light_margin light_color glow_intensity glow_size].each do |k|
write_pref(k, data[k]) if data.key?(k)
end
write_pref('cove_hand_thickness', data['cove_lip_height']) if data.key?('cove_lip_height')
end

# =========================================================
# SMART ROOM EDIT ENGINE V5
# =========================================================
def save_room_pts(room_group, pts)
data = pts.map { |p| [p.x.to_f, p.y.to_f, p.z.to_f] }
room_group.set_attribute(DICT, 'room_pts_json', data.to_json)
end

def room_pts_from_group(room_group)
json = room_group.get_attribute(DICT, 'room_pts_json').to_s
return nil if json.empty?
data = JSON.parse(json) rescue nil
return nil unless data.is_a?(Array) && data.length >= 3
data.map { |a| Geom::Point3d.new(a[0].to_f, a[1].to_f, a[2].to_f) }
rescue
nil
end

def save_build_data(room_group, data)
# لا تمسح بيانات الكمرات عند حفظ بيانات الغرفة؛ الكمرات مرتبطة ديناميكياً بالغرفة.
room_group.set_attribute(DICT, 'build_data_json', data.to_json)
end

def build_data_from_group(room_group)
json = room_group.get_attribute(DICT, 'build_data_json').to_s
return nil if json.empty?
d = JSON.parse(json) rescue nil
d.is_a?(Hash) ? d : nil
rescue
nil
end

def compute_outward_pts(pts, wall_t)
count = pts.length
outward = []
count.times do |i|
p_prev = pts[(i - 1) % count]
p_curr = pts[i]
p_next = pts[(i + 1) % count]
d_prev = p_prev.vector_to(p_curr)
d_curr = p_curr.vector_to(p_next)
d_prev.normalize!
d_curr.normalize!
out_prev = d_prev.cross(Z_AXIS)
out_curr = d_curr.cross(Z_AXIS)
out_prev.normalize!
out_curr.normalize!
out_prev.length = wall_t
out_curr.length = wall_t
a1 = p_prev.offset(out_prev)
b1 = p_curr.offset(out_curr)
inter = line_intersection_2d(a1, d_prev, b1, d_curr)
inter ||= p_curr.offset(out_curr)
outward << inter
end
outward
end

def delete_room_parts(room_group, type)
room_group.entities.to_a.each do |e|
next unless e.valid?
next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
next unless e.get_attribute(DICT, 'النوع').to_s == type.to_s
e.erase!
end
end

def ceiling_settings_differ?(old_d, new_d)
keys = %w[
ceiling_pattern drop_reference
perimeter_width perimeter_drop
center_inset center_drop
center_led_inset center_led_drop center_led_thickness
combo_cove_width combo_cove_drop combo_cove_lip_width combo_cove_lip_height
combo_center_inset combo_center_drop combo_center_thickness
strip_direction strip_count strip_width strip_gap strip_drop
cove_inset cove_drop cove_lip_width cove_lip_height
]
keys.any? { |k| old_d[k].to_s != new_d[k].to_s }
end

def light_settings_differ?(old_d, new_d)
keys = %w[
light_enabled light_mode light_inset light_width light_depth
light_margin light_color glow_intensity glow_size
]
keys.any? { |k| old_d[k].to_s != new_d[k].to_s }
end

def resize_existing_walls(room_group, delta, new_wall_h_cm)
room_group.entities.to_a.each do |inst|
next unless inst.valid?
next unless inst.is_a?(Sketchup::ComponentInstance)
next unless inst.get_attribute(DICT, 'النوع').to_s == 'حائط'
definition = inst.definition
if definition.instances.length > 1
inst.make_unique
definition = inst.definition
end
top_face = definition.entities.grep(Sketchup::Face).find do |f|
f.valid? && f.normal.z > 0.9
end
next unless top_face
begin
top_face.pushpull(delta, false)
rescue
next
end
inst.set_attribute(DICT, 'الارتفاع سم', new_wall_h_cm)
end
end

def move_ceiling_by_delta(room_group, delta)
tr = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, delta))
room_group.entities.to_a.each do |inst|
next unless inst.valid?
next unless inst.is_a?(Sketchup::ComponentInstance)
next unless inst.get_attribute(DICT, 'النوع').to_s == 'سقف'
inst.transform!(tr)
end
end

def wall_overrides_from_room(room_group)
  raw = room_group.get_attribute(DICT, 'wall_overrides_json').to_s
  return {} if raw.empty?
  data = JSON.parse(raw) rescue {}
  return data if data.is_a?(Hash)
  {}
rescue
  {}
end

def save_wall_overrides(room_group, overrides)
  room_group.set_attribute(DICT, 'wall_overrides_json', (overrides || {}).to_json)
  true
rescue
  false
end

def wall_override_for(overrides, index)
  ov = (overrides || {})[index.to_i.to_s]
  ov = (overrides || {})[format('%02d', index.to_i + 1)] if ov.nil?
  ov.is_a?(Hash) ? ov : {}
rescue
  {}
end

def compute_outward_pts_per_wall(pts, default_wall_t_cm, overrides = {})
  count = pts.length
  edges = []
  count.times do |i|
    j = (i + 1) % count
    a = pts[i]
    b = pts[j]
    d = a.vector_to(b)
    raise 'حائط بطول غير صالح.' if d.length <= 0.1.mm
    d.normalize!
    normal = d.cross(Z_AXIS)
    normal.normalize!
    ov = wall_override_for(overrides, i)
    t_cm = ov['thickness_cm'].to_f
    t_cm = default_wall_t_cm.to_f if t_cm <= 0.1
    half = t_cm.cm / 2.0
    edges << { :a => a, :b => b, :dir => d, :normal => normal, :offset_a => a.offset(normal, half), :offset_b => b.offset(normal, half) }
  end
  outward = []
  count.times do |i|
    prev = edges[(i - 1) % count]
    curr = edges[i]
    inter = Geom.intersect_line_line([prev[:offset_b], prev[:dir]], [curr[:offset_a], curr[:dir]])
    inter ||= curr[:offset_a]
    outward << inter
  end
  outward
rescue
  compute_outward_pts(pts, default_wall_t_cm.to_f.cm)
end

def rebuild_room_walls(room_group, pts, outward_pts, wall_h, wall_t,
wall_h_cm, wall_t_cm, room_name, room_uuid, overrides = nil)
model = Sketchup.active_model
count = pts.length
stamp = Time.now.to_i
overrides = overrides.is_a?(Hash) ? overrides : wall_overrides_from_room(room_group)
delete_room_parts(room_group, 'حائط')
count.times do |i|
j = (i + 1) % count
ov = wall_override_for(overrides, i)
local_h_cm = ov['height_cm'].to_f
local_h_cm = wall_h_cm.to_f if local_h_cm <= 0.1
local_t_cm = ov['thickness_cm'].to_f
local_t_cm = wall_t_cm.to_f if local_t_cm <= 0.1
local_name = ov['name'].to_s.strip
local_name = "#{ts('حائط')} #{format('%02d', i + 1)}" if local_name.empty?
wall_def = model.definitions.add("#{room_name}_#{local_name}_#{stamp}_#{rand(9999)}")
add_prism(wall_def.entities, pts[i], pts[j], outward_pts[j], outward_pts[i], 0, local_h_cm.cm)
wall_inst = room_group.entities.add_instance(wall_def, Geom::Transformation.new)
wall_inst.name = local_name
wall_inst.layer = tag(model, "#{room_name} | #{local_name}")
set_attrs(wall_inst, {
'UUID' => uuid,
'Room_UUID' => room_uuid,
'النوع' => 'حائط',
'اسم الغرفة' => room_name,
'رقم الحائط' => i + 1,
'الاسم' => local_name,
'الارتفاع سم' => local_h_cm,
'السمك سم' => local_t_cm,
'طول الحائط سم' => pts[i].distance(pts[j]).to_cm.round(2),
'P1' => pt_to_s(pts[i]),
'P2' => pt_to_s(pts[j]),
'P3' => pt_to_s(outward_pts[j]),
'P4' => pt_to_s(outward_pts[i])
})
end
end

def rebuild_room_floor(room_group, outward_pts, floor_t, floor_t_cm, room_name, room_uuid)
  model = Sketchup.active_model
  delete_room_parts(room_group, 'أرضية')
  return if floor_t.to_f <= 0 || !outward_pts || outward_pts.length < 3

  # الأرضية دائماً تُبنى من Room Geometry الحالية فقط وعلى Z=0.
  pts = outward_pts.map { |p| Geom::Point3d.new(p.x, p.y, 0) }
  return unless polygon_usable?(pts)

  stamp = Time.now.to_i
  floor_def = model.definitions.add("#{room_name}_أرضية_#{stamp}_#{rand(99999)}")
  floor_face = floor_def.entities.add_face(pts)
  return unless floor_face
  floor_face.reverse! if floor_face.normal.z < 0
  floor_face.pushpull(-floor_t)

  # الأرضية بدون Material مخصص: تستخدم لون الـFace الطبيعي في SketchUp،
  # وبذلك لا تتحول للون أسود عند إعادة البناء أو عند تحديث الشطرة/الحائط.
  # نزيل أي Material قديم من كل الأوجه (Front + Back) حتى لا تنتقل خامة سوداء قديمة.
  floor_def.entities.grep(Sketchup::Face).each do |face|
    begin
      face.material = nil
      face.back_material = nil
      face.reverse! if face.normal.z < 0
    rescue
    end
  end

  # حواف الأرضية غير مرئية، مع إبقاء Geometry صالحة للتعديل.
  floor_def.entities.grep(Sketchup::Edge).each do |edge|
    begin
      edge.hidden = true if edge.respond_to?(:hidden=)
      edge.soft = true if edge.respond_to?(:soft=)
      edge.smooth = true if edge.respond_to?(:smooth=)
    rescue
    end
  end

  # تأكيد أن الـInstance نفسه لا يحمل Material يطغى على Geometry الفرعية.
  begin
    floor_inst_material_clear = floor_def.entities.grep(Sketchup::Face)
  rescue
    floor_inst_material_clear = []
  end

  floor_inst = room_group.entities.add_instance(floor_def, Geom::Transformation.new)
  floor_inst.name = ts('الأرضية')
  floor_inst.layer = tag(model, "#{room_name} | #{ts('الأرضية')}")
  set_attrs(floor_inst, {
    'UUID' => uuid,
    'Room_UUID' => room_uuid,
    'النوع' => 'أرضية',
    'اسم الغرفة' => room_name,
    'السمك سم' => floor_t_cm.to_f,
    'حدود الغرفة' => pts.map { |q| pt_to_s(q) }.to_json
  })
  floor_inst
end


def normalize_room_floor_appearance(room_group)
  return false unless room_group && room_group.valid?
  begin
    room_group.entities.grep(Sketchup::ComponentInstance).each do |inst|
      next unless inst.valid?
      next unless inst.get_attribute(DICT, 'النوع').to_s == 'أرضية'
      definition = inst.definition
      definition.entities.grep(Sketchup::Face).each do |face|
        face.material = nil
        face.back_material = nil
        face.reverse! if face.normal.z < 0
      end
      definition.entities.grep(Sketchup::Edge).each do |edge|
        edge.hidden = true if edge.respond_to?(:hidden=)
        edge.soft = true if edge.respond_to?(:soft=)
        edge.smooth = true if edge.respond_to?(:smooth=)
      end
    end
  rescue
  end
  true
rescue
  false
end

def apply_smart_room_update(room_group, new_data)
old_data = build_data_from_group(room_group) || {}
pts = room_pts_from_group(room_group)
if old_data.empty? || !pts || pts.length < 3
return rebuild_entire_room(room_group, new_data)
end
model = Sketchup.active_model
model.start_operation('MHD Smart Room Update', true)
begin
room_uuid = room_group.get_attribute(DICT, 'UUID').to_s
room_uuid = uuid if room_uuid.empty?
name_old = old_data['room_name'].to_s
name_new = new_data['room_name'].to_s
name_new = ts('الغرفة') if name_new.strip.empty?
wall_h_old = old_data['wall_h'].to_f
wall_h_new = new_data['wall_h'].to_f
wall_t_old = old_data['wall_t'].to_f
wall_t_new = new_data['wall_t'].to_f
floor_t_old = old_data['floor_t'].to_f
floor_t_new = new_data['floor_t'].to_f
ceil_t_old = old_data['ceil_t'].to_f
ceil_t_new = new_data['ceil_t'].to_f
floor_on_old   = enabled_value?(old_data['create_floor'])
floor_on_new   = enabled_value?(new_data['create_floor'])
ceiling_on_old = enabled_value?(old_data['create_ceiling'])
ceiling_on_new = enabled_value?(new_data['create_ceiling'])
name_changed     = name_old != name_new
wall_h_changed   = (wall_h_old - wall_h_new).abs > 0.001
wall_t_changed   = (wall_t_old - wall_t_new).abs > 0.001
floor_t_changed  = (floor_t_old - floor_t_new).abs > 0.001
floor_toggle     = floor_on_old != floor_on_new
floor_changed    = floor_t_changed || floor_toggle
ceiling_toggle   = ceiling_on_old != ceiling_on_new
ceiling_t_changed = (ceil_t_old - ceil_t_new).abs > 0.001
ceiling_visual   = ceiling_settings_differ?(old_data, new_data)
light_changed    = light_settings_differ?(old_data, new_data)
ceiling_needs_rebuild = ceiling_toggle || ceiling_t_changed || ceiling_visual || light_changed


  if name_changed
    begin
      room_group.name = name_new
      room_group.layer = tag(model, name_new)
    rescue
    end
    old_prefix = "#{name_old} | "
    room_group.entities.to_a.each do |e|
      next unless e.valid? && e.respond_to?(:layer)
      current_name = e.layer.name.to_s rescue ''
      if current_name.start_with?(old_prefix)
        suffix = current_name[old_prefix.length..-1]
        begin
          e.layer = tag(model, "#{name_new} | #{suffix}")
        rescue
        end
      end
    end
  end

  if wall_t_changed
    new_outward = compute_outward_pts_per_wall(pts, wall_t_new, wall_overrides_from_room(room_group))
    rebuild_room_walls(room_group, pts, new_outward,
                       wall_h_new.cm, wall_t_new.cm,
                       wall_h_new, wall_t_new, name_new, room_uuid)
    delete_room_parts(room_group, 'أرضية')
    rebuild_room_floor(room_group, new_outward, floor_t_new.cm,
                       floor_t_new, name_new, room_uuid) if floor_on_new && floor_t_new > 0
    delete_room_parts(room_group, 'سقف')
    if ceiling_on_new && ceil_t_new > 0
      build_ceiling(model, room_group.entities, name_new, room_uuid,
                    new_outward, pts,
                    wall_h_new.cm, ceil_t_new.cm, ceil_t_new, new_data)
    end
  else
    if wall_h_changed
      delta_h = (wall_h_new - wall_h_old).cm
      resize_existing_walls(room_group, delta_h, wall_h_new)
      move_ceiling_by_delta(room_group, delta_h) unless ceiling_needs_rebuild
    end
    if floor_changed
      current_outward = compute_outward_pts_per_wall(pts, wall_t_old, wall_overrides_from_room(room_group))
      if floor_on_new && floor_t_new > 0
        rebuild_room_floor(room_group, current_outward, floor_t_new.cm,
                           floor_t_new, name_new, room_uuid)
      else
        delete_room_parts(room_group, 'أرضية')
      end
    end
    if ceiling_needs_rebuild
      delete_room_parts(room_group, 'سقف')
      if ceiling_on_new && ceil_t_new > 0
        current_outward = compute_outward_pts_per_wall(pts, wall_t_old, wall_overrides_from_room(room_group))
        build_ceiling(model, room_group.entities, name_new, room_uuid,
                      current_outward, pts,
                      wall_h_new.cm, ceil_t_new.cm, ceil_t_new, new_data)
      end
    end
  end

  rebuild_all_beams(room_group)
  rebuild_all_shatras(room_group) if respond_to?(:rebuild_all_shatras)
  save_build_data(room_group, new_data)
  room_group.set_attribute(DICT, 'اسم الغرفة', name_new)
  room_group.set_attribute(DICT, 'ارتفاع الحائط سم', wall_h_new)
  room_group.set_attribute(DICT, 'سمك الحائط سم', wall_t_new)
  room_group.set_attribute(DICT, 'سمك الأرضية سم', floor_t_new)
  room_group.set_attribute(DICT, 'سمك السقف سم', ceil_t_new)
  room_group.set_attribute(DICT, 'إنشاء أرضية', floor_on_new ? 'نعم' : 'لا')
  room_group.set_attribute(DICT, 'إنشاء سقف', ceiling_on_new ? 'نعم' : 'لا')
  room_group.set_attribute(DICT, 'نمط السقف', new_data['ceiling_pattern'].to_s)
  room_group.set_attribute(DICT, 'تاريخ آخر تعديل', Time.now.strftime('%Y-%m-%d %H:%M'))

  model.commit_operation
  model.active_view.invalidate
  UI.messagebox("✅ #{ts('تم تعديل الغرفة بنجاح')}")
  true
rescue => e
  model.abort_operation rescue nil
  UI.messagebox("❌ #{ts('خطأ أثناء التعديل')}:\n#{e.message}")
  false
end


end

def rebuild_entire_room(room_group, new_data)
pts = room_pts_from_group(room_group)
unless pts
UI.messagebox("❌ لا يمكن قراءة محيط الغرفة الأصلي.")
return false
end
model = Sketchup.active_model
model.start_operation('MHD Rebuild Room', true)
begin
room_uuid = room_group.get_attribute(DICT, 'UUID').to_s
room_uuid = uuid if room_uuid.empty?
name = new_data['room_name'].to_s.strip
name = ts('الغرفة') if name.empty?
wall_h_cm  = new_data['wall_h'].to_f
wall_t_cm  = new_data['wall_t'].to_f
floor_t_cm = new_data['floor_t'].to_f
ceil_t_cm  = new_data['ceil_t'].to_f
floor_on   = enabled_value?(new_data['create_floor'])
ceiling_on = enabled_value?(new_data['create_ceiling'])
room_group.entities.clear!
outward = compute_outward_pts_per_wall(pts, wall_t_cm, wall_overrides)
rebuild_room_floor(room_group, outward, floor_t_cm.cm, floor_t_cm, name, room_uuid) if floor_on && floor_t_cm > 0
if ceiling_on && ceil_t_cm > 0
build_ceiling(model, room_group.entities, name, room_uuid,
outward, pts,
wall_h_cm.cm, ceil_t_cm.cm, ceil_t_cm, new_data)
end
rebuild_room_walls(room_group, pts, outward,
wall_h_cm.cm, wall_t_cm.cm,
wall_h_cm, wall_t_cm, name, room_uuid, wall_overrides)
rebuild_all_beams(room_group) if respond_to?(:rebuild_all_beams)
room_group.name = name
room_group.layer = tag(model, name)
save_build_data(room_group, new_data)
room_group.set_attribute(DICT, 'اسم الغرفة', name)
room_group.set_attribute(DICT, 'ارتفاع الحائط سم', wall_h_cm)
room_group.set_attribute(DICT, 'سمك الحائط سم', wall_t_cm)
room_group.set_attribute(DICT, 'سمك الأرضية سم', floor_t_cm)
room_group.set_attribute(DICT, 'سمك السقف سم', ceil_t_cm)
save_wall_overrides(room_group, wall_overrides)
model.commit_operation
model.active_view.invalidate
UI.messagebox("✅ #{ts('تم إعادة بناء الغرفة بنجاح')}")
true
rescue => e
model.abort_operation rescue nil
UI.messagebox("❌ #{e.message}")
false
end
end

def open_edit_room_dialog(room_group)
return unless room_group && room_group.valid?
saved = build_data_from_group(room_group)
unless saved && !saved.empty?
UI.messagebox("⚠️ لا توجد بيانات محفوظة لهذه الغرفة.")
return
end
merged = saved_values.merge(saved)
dlg = UI::HtmlDialog.new(
dialog_title: "#{ts('تعديل الغرفة')} - MRDESIGN",
preferences_key: PREF_KEY,
scrollable: false,
resizable: true,
width: 330,
height: 720,
style: UI::HtmlDialog::STYLE_DIALOG
)
html = html_dialog_content(merged)
html = html.gsub('>إنشاء<', ">#{ts('حفظ التعديلات')}<")
html = html.gsub('>إلغاء<', ">#{ts('إغلاق')}<")
dlg.set_html(html)
dlg.add_action_callback('cancel') { dlg.close }
dlg.add_action_callback('submit') do |_, json|
begin
data = JSON.parse(json)
save_values(data)
dlg.close
apply_smart_room_update(room_group, data)
rescue => e
UI.messagebox("Error:\n#{e.message}")
end
end
dlg.show
end

class RoomEditPickTool
def activate
Sketchup.status_text = ts('انقر على أي جزء من الغرفة لتعديل خصائصها')
end
def onLButtonDown(_flags, x, y, view)
ph = view.pick_helper
ph.do_pick(x, y)
ent = ph.best_picked
if ent
room = MHD_RoomBuilder_Context.find_room_group(ent)
if room
MHD_RoomBuilder_Context.open_edit_room_dialog(room)
else
UI.messagebox(ts('هذا العنصر ليس جزءاً من غرفة MHD'))
end
else
UI.messagebox(ts('لم يتم تحديد أي عنصر'))
end
end
def onCancel(_reason, _view)
Sketchup.active_model.select_tool(nil)
end
end

def activate_room_edit_picker
Sketchup.active_model.select_tool(RoomEditPickTool.new)
end

def find_room_group(entity)
return nil unless entity && entity.respond_to?(:valid?) && entity.valid?
if entity.is_a?(Sketchup::Group) &&
entity.get_attribute(DICT, 'النوع') == 'غرفة'
return entity
end
uuid_v = ''
current = entity
depth = 0
while current && depth < 20
begin
u = current.get_attribute(DICT, 'Room_UUID').to_s
uuid_v = u unless u.empty?
if current.is_a?(Sketchup::Group) &&
current.get_attribute(DICT, 'النوع') == 'غرفة'
return current
end
parent_ents = current.parent rescue nil
break unless parent_ents
container = parent_ents.parent rescue nil
break unless container
break if container.is_a?(Sketchup::Model)
current = container
depth += 1
rescue
break
end
end
return nil if uuid_v.empty?
find_group_by_uuid(Sketchup.active_model.entities, uuid_v)
rescue
nil
end

def find_group_by_uuid(entities, uuid_v)
entities.each do |e|
next unless e.is_a?(Sketchup::Group) && e.respond_to?(:valid?) && e.valid?
return e if e.get_attribute(DICT, 'UUID').to_s == uuid_v
nested = find_group_by_uuid(e.entities, uuid_v) rescue nil
return nested if nested
end
nil
end

# =========================================================
# MHD WALL ENGINE V1 - Parametric Dynamic Wall Edit
# =========================================================
def wall_points_from_room(room_group)
  room_pts_from_group(room_group)
end

def wall_record(room_group, wall_number)
  wall = find_wall_in_room(room_group, wall_number)
  return nil unless wall && wall.valid?
  p1s = wall.get_attribute(DICT, 'P1').to_s
  p2s = wall.get_attribute(DICT, 'P2').to_s
  p1 = p1s.split('|').map(&:to_f)
  p2 = p2s.split('|').map(&:to_f)
  return nil unless p1.length >= 3 && p2.length >= 3
  {
    'wall' => wall,
    'number' => wall.get_attribute(DICT, 'رقم الحائط').to_i,
    'name' => wall.get_attribute(DICT, 'الاسم').to_s,
    'length_cm' => wall.get_attribute(DICT, 'طول الحائط سم').to_f,
    'height_cm' => wall.get_attribute(DICT, 'الارتفاع سم').to_f,
    'thickness_cm' => wall.get_attribute(DICT, 'السمك سم').to_f,
    'p1' => Geom::Point3d.new(p1[0], p1[1], p1[2]),
    'p2' => Geom::Point3d.new(p2[0], p2[1], p2[2])
  }
rescue
  nil
end

def polygon_valid_for_wall_edit?(pts)
  return false unless pts.is_a?(Array) && pts.length >= 3
  signed_area_xy(pts).abs > 1.0
rescue
  false
end


def orthogonal_quadrilateral?(pts, tol_deg = 3.0)
  return false unless pts.is_a?(Array) && pts.length == 4
  4.times do |i|
    a = pts[i]
    b = pts[(i + 1) % 4]
    c = pts[(i + 2) % 4]
    u = a.vector_to(b)
    v = b.vector_to(c)
    return false if u.length <= 0.1.mm || v.length <= 0.1.mm
    u.normalize!
    v.normalize!
    dot = [[u.dot(v), -1.0].max, 1.0].min
    angle = Math.acos(dot) * 180.0 / Math::PI
    return false if (angle - 90.0).abs > tol_deg
  end
  true
rescue
  false
end

def build_smart_wall_edit_points(room_group, wall_number, new_length_cm, anchor, mode = 'auto')
  pts = room_pts_from_group(room_group)
  return nil unless pts && pts.length >= 3
  idx = wall_number.to_i - 1
  return nil if idx < 0 || idx >= pts.length

  # mode:
  # single = عدّل الحائط المحدد فقط ولا تحرك الحائط المقابل
  # opposite = حرّك الحائط المحدد ومعه المقابل للحفاظ على الاستقامة
  # auto = السلوك الذكي التقليدي للغرف المستطيلة، مع fallback للـ single عند الحاجة
  mode = mode.to_s

  if orthogonal_quadrilateral?(pts)
    j = (idx + 1) % 4
    opp_j = (idx + 2) % 4
    opp_i = (idx + 3) % 4
    p1 = pts[idx]
    p2 = pts[j]
    vec = p1.vector_to(p2)
    return nil if vec.length <= 0.1.mm
    dir = vec.clone
    dir.normalize!
    target = new_length_cm.to_f.cm
    return nil if target <= 0.1.cm
    old_len = vec.length
    delta = target - old_len

    result = pts.map { |p| p.clone }

    # المستخدم يريد تعديل الحائط نفسه فقط: لا نحرك الحائط المقابل.
    if mode == 'single'
      case anchor.to_s
      when 'end'
        result[idx] = p2.offset(dir.reverse, delta)
      when 'center'
        half = delta / 2.0
        result[idx] = p1.offset(dir.reverse, half)
        result[j]   = p2.offset(dir, half)
      else
        result[j] = p1.offset(dir, target)
      end
      return result
    end

    case anchor.to_s
    when 'end'
      move = dir.reverse
      result[idx] = p2.offset(move, delta)
      result[opp_i] = pts[opp_i].offset(move, delta)
    when 'center'
      half = delta / 2.0
      result[idx] = p1.offset(dir.reverse, half)
      result[j]   = p2.offset(dir, half)
      result[opp_i] = pts[opp_i].offset(dir.reverse, half)
      result[opp_j] = pts[opp_j].offset(dir, half)
    else
      result[j] = p1.offset(dir, target)
      move_vec = p2.vector_to(result[j])
      result[opp_j] = pts[opp_j].offset(move_vec)
    end
    return result
  end

  build_wall_edit_points(room_group, wall_number, new_length_cm, anchor)
rescue
  nil
end

def remove_legacy_source_floor_geometry(old_pts)
  model = Sketchup.active_model
  return unless old_pts && old_pts.length >= 3

  matches_loop = lambda do |face|
    verts = face.outer_loop.vertices.map(&:position)
    return false unless verts.length == old_pts.length
    n = old_pts.length
    n.times do |shift|
      ok = true
      n.times do |k|
        if verts[k].distance(old_pts[(k + shift) % n]) > 0.01.cm
          ok = false
          break
        end
      end
      return true if ok
    end
    false
  rescue
    false
  end

  model.entities.to_a.grep(Sketchup::Face).each do |face|
    next unless face.valid?
    next unless matches_loop.call(face)
    edges = face.edges.dup
    face.erase!
    edges.each do |edge|
      begin
        edge.erase! if edge.valid? && edge.faces.empty?
      rescue
      end
    end
  end
rescue
  nil
end

def shatra_classification(angle_deg)
  delta = angle_deg.to_f - 90.0
  if delta.abs <= 0.10
    { 'status' => 'قائمة 90°', 'type' => 'قائمة', 'deviation' => 0.0, 'direction' => 'لا يوجد شطف' }
  elsif delta > 0
    { 'status' => 'مشطولة', 'type' => 'مشطولة', 'deviation' => delta.abs, 'direction' => 'مفتوحة عن القائمة' }
  else
    { 'status' => 'مشطولة', 'type' => 'مشطولة', 'deviation' => delta.abs, 'direction' => 'مقفولة عن القائمة' }
  end
end

def shatra_result_text(a_cm, b_cm, diagonal_cm, angle_deg)
  cls = shatra_classification(angle_deg)
  right_diag = Math.sqrt(a_cm.to_f**2 + b_cm.to_f**2)
  diag_diff = diagonal_cm.to_f - right_diag
  ref = [a_cm.to_f, b_cm.to_f].min
  equivalent = Math.tan((cls['deviation'].to_f.abs) * Math::PI / 180.0) * ref
  "الحالة: #{cls['status']}\nالنوع: #{cls['type']}\nالزاوية: #{angle_deg.round(2)}°\nالانحراف عن 90°: #{cls['deviation'].round(2)}°\nالاتجاه: #{cls['direction']}\nالمقاس الأول: #{a_cm.to_f.round(2)} سم\nالمقاس الثاني: #{b_cm.to_f.round(2)} سم\nالقطر المقاس: #{diagonal_cm.to_f.round(2)} سم\nقطر القائمة لنفس المقاسين: #{right_diag.round(2)} سم\nفرق القطر: #{diag_diff.round(2)} سم\nالشطف المكافئ على #{ref.round(2)} سم: #{equivalent.round(2)} سم"
end

def current_corner_angle(pts, corner_idx)
  return nil unless pts && pts.length >= 3
  i = corner_idx.to_i
  return nil if i < 0 || i >= pts.length
  prev = pts[(i - 1) % pts.length]
  cur = pts[i]
  nxt = pts[(i + 1) % pts.length]
  u = cur.vector_to(prev)
  v = cur.vector_to(nxt)
  return nil if u.length <= 0.1.mm || v.length <= 0.1.mm
  u.normalize!
  v.normalize!
  dot = [[u.dot(v), -1.0].max, 1.0].min
  Math.acos(dot) * 180.0 / Math::PI
rescue
  nil
end

def build_wall_edit_points(room_group, wall_number, new_length_cm, anchor)
  pts = wall_points_from_room(room_group)
  return nil unless pts && pts.length >= 3
  idx = wall_number.to_i - 1
  return nil if idx < 0 || idx >= pts.length
  j = (idx + 1) % pts.length
  p1 = pts[idx]
  p2 = pts[j]
  vec = p1.vector_to(p2)
  return nil if vec.length <= 0.1.mm
  dir = vec.clone
  dir.normalize!
  target = new_length_cm.to_f.cm
  return nil if target <= 0.1.cm

  case anchor.to_s
  when 'end'
    pts[idx] = p2.offset(dir.reverse, target)
  when 'center'
    center = Geom::Point3d.new((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0, (p1.z + p2.z) / 2.0)
    half = target / 2.0
    pts[idx] = center.offset(dir.reverse, half)
    pts[j]   = center.offset(dir, half)
  else
    pts[j] = p1.offset(dir, target)
  end
  pts
rescue
  nil
end

def synchronize_room_geometry(room_group, pts, room_data)
  model = Sketchup.active_model
  room_uuid = room_group.get_attribute(DICT, 'UUID').to_s
  room_uuid = uuid if room_uuid.empty?
  data = room_data || {}
  name = data['room_name'].to_s.strip
  name = ts('الغرفة') if name.empty?
  wall_h_cm = data['wall_h'].to_f
  wall_t_cm = data['wall_t'].to_f
  floor_t_cm = data['floor_t'].to_f
  ceil_t_cm = data['ceil_t'].to_f
  floor_on = enabled_value?(data['create_floor'])
  ceiling_on = enabled_value?(data['create_ceiling'])
  wall_overrides = wall_overrides_from_room(room_group)

  raise 'نقاط الغرفة غير صالحة' unless pts.is_a?(Array) && pts.length >= 3 && polygon_valid_for_wall_edit?(pts)

  outward = compute_outward_pts_per_wall(pts, wall_t_cm, wall_overrides)
  raise 'تعذر حساب حدود الحوائط' unless outward && outward.length == pts.length

  # ترتيب التنفيذ مهم: نمسح العناصر المشتقة القديمة أولاً، ثم نبني كل شيء من pts الجديدة.
  delete_room_parts(room_group, 'حائط')
  delete_room_parts(room_group, 'أرضية')
  delete_room_parts(room_group, 'سقف')
  delete_room_beams(room_group) if respond_to?(:delete_room_beams)
  delete_room_shatras(room_group) if respond_to?(:delete_room_shatras)

  rebuild_room_walls(room_group, pts, outward, wall_h_cm.cm, wall_t_cm.cm,
                     wall_h_cm, wall_t_cm, name, room_uuid, wall_overrides)

  rebuild_room_floor(room_group, outward, floor_t_cm.cm, floor_t_cm, name, room_uuid) if floor_on && floor_t_cm > 0
  normalize_room_floor_appearance(room_group) if respond_to?(:normalize_room_floor_appearance)

  if ceiling_on && ceil_t_cm > 0
    build_ceiling(model, room_group.entities, name, room_uuid, outward, pts,
                  wall_h_cm.cm, ceil_t_cm.cm, ceil_t_cm, data)
  end

  save_room_pts(room_group, pts)
  save_build_data(room_group, data)
  room_group.set_attribute(DICT, 'اسم الغرفة', name)
  room_group.set_attribute(DICT, 'ارتفاع الحائط سم', wall_h_cm)
  room_group.set_attribute(DICT, 'سمك الحائط سم', wall_t_cm)
  room_group.set_attribute(DICT, 'سمك الأرضية سم', floor_t_cm)
  room_group.set_attribute(DICT, 'سمك السقف سم', ceil_t_cm)
  room_group.set_attribute(DICT, 'إنشاء أرضية', floor_on ? 'نعم' : 'لا')
  room_group.set_attribute(DICT, 'إنشاء سقف', ceiling_on ? 'نعم' : 'لا')
  save_wall_overrides(room_group, wall_overrides)

  rebuild_all_beams(room_group) if respond_to?(:rebuild_all_beams)
  rebuild_all_shatras(room_group) if respond_to?(:rebuild_all_shatras)
  model.active_view.invalidate
  true
end

def rebuild_room_after_wall_edit(room_group, pts, room_data)
  synchronize_room_geometry(room_group, pts, room_data)
rescue => e
  raise e
end

def apply_wall_edit(room_group, wall_number, data)
  return false unless room_group && room_group.valid?
  room_data = build_data_from_group(room_group)
  unless room_data && !room_data.empty?
    UI.messagebox(ts('لا توجد بيانات محفوظة للغرفة.'))
    return false
  end

  rec = wall_record(room_group, wall_number)
  unless rec
    UI.messagebox(ts('تعذر قراءة الحائط المحدد.'))
    return false
  end

  new_length = data['length_cm'].to_f
  new_height = data['height_cm'].to_f
  new_thickness = data['thickness_cm'].to_f
  anchor = data['anchor'].to_s
  edit_mode = data['edit_mode'].to_s
  edit_mode = 'auto' if edit_mode.empty?
  new_name = data['name'].to_s.strip
  new_name = rec['name'] if new_name.empty?

  if new_length <= 1.0
    UI.messagebox(ts('طول الحائط يجب أن يكون أكبر من 1 سم.'))
    return false
  end
  if new_height <= 1.0 || new_thickness <= 0.1
    UI.messagebox(ts('ارتفاع وسمك الحائط يجب أن يكونا أكبر من صفر.'))
    return false
  end

  room_data = room_data.dup

  old_pts = room_pts_from_group(room_group)
  overrides = wall_overrides_from_room(room_group)
  new_pts = build_smart_wall_edit_points(room_group, wall_number, new_length, anchor, edit_mode)
  unless new_pts && polygon_valid_for_wall_edit?(new_pts)
    UI.messagebox(ts('القيمة الجديدة أدت إلى شكل غرفة غير صالح. جرّب طولاً أكبر أو نقطة تثبيت مختلفة.'))
    return false
  end

  if enabled_value?(data['inherit_room_defaults'])
    overrides.delete(wall_number.to_i.to_s)
  else
    overrides[wall_number.to_i.to_s] = {
      'height_cm' => new_height,
      'thickness_cm' => new_thickness,
      'name' => new_name
    }
  end

  model = Sketchup.active_model
  model.start_operation('MHD Parametric Wall Edit', true)
  begin
    old_wall_name = rec['name']
    save_wall_overrides(room_group, overrides)
    remove_legacy_source_floor_geometry(old_pts)
    rebuild_room_after_wall_edit(room_group, new_pts, room_data)

    wall = find_wall_in_room(room_group, wall_number)
    if wall && wall.valid?
      wall.name = new_name
      wall.set_attribute(DICT, 'الاسم', new_name)
      room_name = room_data['room_name'].to_s
      wall.layer = tag(model, "#{room_name} | #{new_name}")
    end
    rename_beam_tags_for_room(room_group) if respond_to?(:rename_beam_tags_for_room)

    model.commit_operation
    UI.messagebox("✅ #{ts('تم تعديل الحائط ديناميكياً')}\\n#{ts('الطول')}: #{new_length.round(2)} سم")
    true
  rescue => e
    model.abort_operation rescue nil
    UI.messagebox("❌ #{ts('خطأ أثناء تعديل الحائط')}:\\n#{e.message}")
    false
  end
end

def wall_edit_dialog_values(rec)
  {
    'length_cm' => rec['length_cm'].round(2),
    'height_cm' => rec['height_cm'].round(2),
    'thickness_cm' => rec['thickness_cm'].round(2),
    'name' => rec['name'],
    'anchor' => 'start'
  }
end

def open_wall_dialog(target)
  room_group = find_room_group(target)
  unless room_group
    UI.messagebox(ts('لم يتم العثور على غرفة MHD لهذا الحائط.'))
    return
  end
  wall_number = target.get_attribute(DICT, 'رقم الحائط').to_i
  rec = wall_record(room_group, wall_number)
  unless rec
    UI.messagebox(ts('تعذر قراءة الحائط المحدد.'))
    return
  end

  v = wall_edit_dialog_values(rec)
  defaults = build_data_from_group(room_group) || {}
  room_data_default_height = defaults['wall_h'].to_f > 0.1 ? defaults['wall_h'].to_f : v['height_cm']
  room_data_default_thickness = defaults['wall_t'].to_f > 0.1 ? defaults['wall_t'].to_f : v['thickness_cm']
  current_overrides = wall_overrides_from_room(room_group)
  has_override = current_overrides.key?(wall_number.to_i.to_s)
  dlg = UI::HtmlDialog.new(
    dialog_title: "#{ts('تعديل الحائط')} - MHDESIGN",
    preferences_key: PREF_KEY + '_WALL_EDIT',
    scrollable: true,
    resizable: true,
    width: 410,
    height: 720,
    style: UI::HtmlDialog::STYLE_DIALOG
  )

  safe_name = v['name'].to_s.gsub('&','&amp;').gsub('"','&quot;').gsub('<','&lt;').gsub('>','&gt;')
  html = <<-HTML
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<style>
*{box-sizing:border-box}body{margin:0;background:#07131d;color:#eaf4f8;font-family:Arial,Tahoma,sans-serif;overflow:auto}
.app{padding:14px}.title{font-size:21px;font-weight:900;text-align:center;margin-bottom:5px}.sub{text-align:center;color:#8eabbc;font-size:12px;margin-bottom:14px}
.card{background:#0b1b27;border:1px solid #1c3342;border-radius:12px;padding:12px;margin-bottom:10px}.row{display:grid;grid-template-columns:135px 1fr;gap:8px;align-items:center;margin-bottom:9px}.row:last-child{margin-bottom:0}
label{font-weight:900;font-size:13px}input,select{width:100%;height:34px;background:#111f2a;color:#fff;border:1px solid #294457;border-radius:7px;padding:4px 8px;text-align:center;font-size:14px}input:focus,select:focus{outline:2px solid #39a245}
.length-wrap{display:grid;grid-template-columns:42px 1fr 42px;gap:5px;align-items:center}.step{height:34px;border:1px solid #294457;background:#0f2433;color:#fff;border-radius:7px;font-size:17px;font-weight:900;cursor:pointer}.range{width:100%;height:26px}.big{font-size:18px;font-weight:900;text-align:center;margin:4px 0 12px;color:#fff}.hint{font-size:11px;color:#8eabbc;line-height:1.55;margin-top:7px}.footer{display:flex;gap:8px;margin-top:12px}.btn{flex:1;height:42px;border:0;border-radius:9px;font-weight:900;font-size:14px;cursor:pointer}.save{background:#4de37a;color:#061923}.cancel{background:#0b1b27;color:#fff;border:1px solid #294457}
</style>
</head>
<body>
<div class="app">
<div class="title">🧱 تعديل الحائط ##{wall_number}</div>
<div class="sub">تعديل بارامتري للحائط مع تحديث الغرفة والعناصر المرتبطة</div>
<div class="card">
<div class="big"><span id="length_big">#{v['length_cm']}</span> سم</div>
<div class="row"><label>طول الحائط سم</label><div class="length-wrap"><button class="step" onclick="step(-1)">−</button><input id="length" type="number" step="0.1" min="1" value="#{v['length_cm']}" oninput="syncRange()"><button class="step" onclick="step(1)">+</button></div></div>
<input id="length_range" class="range" type="range" min="1" max="2000" step="1" value="#{v['length_cm']}" oninput="syncInput()">
<div class="hint">تقدر تزود أو تقلل طول الحائط، وتحدد نقطة التثبيت، وتختار هل التعديل يؤثر على الحائط المحدد فقط أم يحافظ على تماثل الغرفة.</div>
</div>
<div class="card">
<div class="row"><label>نقطة التثبيت</label><select id="anchor"><option value="start">تثبيت بداية الحائط</option><option value="end">تثبيت نهاية الحائط</option><option value="center">تثبيت المنتصف</option></select></div>
<div class="row"><label>نمط التعديل</label><select id="edit_mode"><option value="single">🎯 حائط واحد فقط — لا تحرك المقابل</option><option value="auto">🧠 ذكي — حافظ على استقامة الغرفة</option><option value="opposite">↔️ الحائط + المقابل معًا</option></select></div>
<div class="row"><label>ارتفاع الحائط سم</label><input id="height" type="number" step="0.1" min="1" value="#{v['height_cm']}"></div>
<div class="row"><label>سمك الحائط سم</label><input id="thickness" type="number" step="0.1" min="0.1" value="#{v['thickness_cm']}"></div>
<div class="row"><label>ربط الحائط</label><select id="inherit"><option value="no"#{has_override ? ' selected' : ''}>🔧 مستقل — احفظ مقاسات هذا الحائط</option><option value="yes"#{has_override ? '' : ' selected'}>🔗 مرتبط بالغرفة — يرث الإعدادات العامة</option></select></div>
<div class="row"><label>اسم الحائط</label><input id="name" type="text" value="#{safe_name}"></div>
</div>
<div class="card"><b>⚡ تحكم بارامتري كامل</b><div class="hint">هذا الحائط يحتفظ بطوله وارتفاعه وسمكه واسمه كبيانات مستقلة. عند تغييره يعاد بناء الحائط، الأرضية، السقف، الكمرات والشطرات من نفس Room Geometry.</div><div class="row"><label>إعادة لقيم الغرفة</label><button class="btn cancel" type="button" onclick="resetDefaults()">↺ إعادة الضبط</button></div></div>
<div class="footer"><button class="btn save" onclick="submitData()">💾 تطبيق التعديل</button><button class="btn cancel" onclick="sketchup.cancel()">إغلاق</button></div>
</div>
<script>
function updateBig(){document.getElementById('length_big').textContent=document.getElementById('length').value||0;}
function syncRange(){let n=parseFloat(document.getElementById('length').value||1);n=Math.max(1,Math.min(2000,n));document.getElementById('length_range').value=n;updateBig();}
function syncInput(){document.getElementById('length').value=document.getElementById('length_range').value;updateBig();}
function step(v){let n=parseFloat(document.getElementById('length').value||1);n=Math.max(1,n+v);document.getElementById('length').value=n;syncRange();}
function resetDefaults(){document.getElementById('height').value=#{room_data_default_height};document.getElementById('thickness').value=#{room_data_default_thickness};document.getElementById('name').value='';document.getElementById('inherit').value='yes';syncRange();}
function submitData(){
 let data={length_cm:parseFloat(document.getElementById('length').value),height_cm:parseFloat(document.getElementById('height').value),thickness_cm:parseFloat(document.getElementById('thickness').value),name:document.getElementById('name').value,inherit_room_defaults:document.getElementById('inherit').value,anchor:document.getElementById('anchor').value,edit_mode:document.getElementById('edit_mode').value};
 if(!Number.isFinite(data.length_cm)||!Number.isFinite(data.height_cm)||!Number.isFinite(data.thickness_cm)){alert('راجع المقاسات');return;}
 sketchup.submit(JSON.stringify(data));
}
updateBig();
</script>
</body></html>
  HTML
  dlg.set_html(html)
  dlg.add_action_callback('cancel') { dlg.close }
  dlg.add_action_callback('submit') do |_, json|
    begin
      data = JSON.parse(json)
      dlg.close
      apply_wall_edit(room_group, wall_number, data)
    rescue => e
      UI.messagebox("Error:\n#{e.message}")
    end
  end
  dlg.show
end

class WallEditPickTool
  def activate
    Sketchup.status_text = ts('انقر على أي حائط لتعديل طوله وارتفاعه وسمكه')
  end
  def onLButtonDown(_flags, x, y, view)
    ph = view.pick_helper
    ph.do_pick(x, y)
    ent = ph.best_picked
    if ent && ent.respond_to?(:get_attribute) && ent.get_attribute(DICT, 'النوع').to_s == 'حائط'
      open_wall_dialog(ent)
    else
      UI.messagebox(ts('اضغط على حائط من حوائط غرفة MHD.'))
    end
  end
  def onCancel(_reason, _view)
    Sketchup.active_model.select_tool(nil)
  end
end

def activate_wall_edit_picker
  Sketchup.active_model.select_tool(WallEditPickTool.new)
end




# =========================================================
# MHD WALL DRAW ENGINE V2 - Stable dynamic laser wall drawing
# =========================================================
def wall_draw_defaults
  d = saved_values rescue {}
  d = {} unless d.is_a?(Hash)
  {
    'room_name' => d['room_name'].to_s.strip.empty? ? ts('غرفة جديدة').to_s : d['room_name'].to_s.strip,
    'wall_h' => (d['wall_h'].to_f > 0 ? d['wall_h'].to_f : 280.0),
    'wall_t' => (d['wall_t'].to_f > 0 ? d['wall_t'].to_f : 10.0),
    'floor_t' => (d['floor_t'].to_f >= 0 ? d['floor_t'].to_f : 10.0),
    'ceil_t' => (d['ceil_t'].to_f >= 0 ? d['ceil_t'].to_f : 10.0),
    'create_floor' => d.key?('create_floor') ? d['create_floor'].to_s : 'yes',
    'create_ceiling' => d.key?('create_ceiling') ? d['create_ceiling'].to_s : 'no',
    'ceiling_pattern' => d['ceiling_pattern'].to_s.strip.empty? ? 'flat' : d['ceiling_pattern'].to_s,
    'drop_reference' => d['drop_reference'].to_s.strip.empty? ? 'below_wall' : d['drop_reference'].to_s
  }
rescue
  {
    'room_name' => ts('غرفة جديدة').to_s,
    'wall_h' => 280.0,
    'wall_t' => 10.0,
    'floor_t' => 10.0,
    'ceil_t' => 10.0,
    'create_floor' => 'yes',
    'create_ceiling' => 'no',
    'ceiling_pattern' => 'flat',
    'drop_reference' => 'below_wall'
  }
end

def wall_draw_setup_dialog
  d = wall_draw_defaults
  labels = [
    ts('اسم الغرفة').to_s, ts('ارتفاع الحائط سم').to_s, ts('سمك الحائط سم').to_s,
    ts('سمك الأرضية سم').to_s, ts('سمك السقف سم').to_s, ts('إنشاء أرضية؟').to_s, ts('إنشاء سقف؟').to_s
  ]
  values = [
    d['room_name'].to_s, d['wall_h'].to_f, d['wall_t'].to_f, d['floor_t'].to_f, d['ceil_t'].to_f,
    d['create_floor'].to_s, d['create_ceiling'].to_s
  ]
  title = ts('MHD - إعداد رسم الحوائط').to_s
  input = UI.inputbox(labels, values, nil, title)
  return nil unless input.is_a?(Array)
  room_name, wall_h, wall_t, floor_t, ceil_t, floor_on, ceiling_on = input
  wall_h = wall_h.to_f
  wall_t = wall_t.to_f
  floor_t = floor_t.to_f
  ceil_t = ceil_t.to_f
  return nil if room_name.to_s.strip.empty? || wall_h <= 0 || wall_t <= 0
  data = d.merge(
    'room_name' => room_name.to_s.strip,
    'wall_h' => wall_h,
    'wall_t' => wall_t,
    'floor_t' => floor_t,
    'ceil_t' => ceil_t,
    'create_floor' => enabled_value?(floor_on) ? 'yes' : floor_on.to_s,
    'create_ceiling' => enabled_value?(ceiling_on) ? 'yes' : ceiling_on.to_s
  )
  save_values(data) rescue nil
  data
rescue
  nil
end

def normalize_wall_draw_data(data)
  d = data.is_a?(Hash) ? data : {}
  room_name = d['room_name'].to_s.strip
  room_name = ts('غرفة جديدة').to_s if room_name.empty?
  {
    'room_name' => room_name,
    'wall_h' => (d['wall_h'].to_f > 0 ? d['wall_h'].to_f : 280.0),
    'wall_t' => (d['wall_t'].to_f > 0 ? d['wall_t'].to_f : 10.0),
    'floor_t' => [d['floor_t'].to_f, 0.0].max,
    'ceil_t' => [d['ceil_t'].to_f, 0.0].max,
    'create_floor' => d['create_floor'].to_s.empty? ? 'yes' : d['create_floor'].to_s,
    'create_ceiling' => d['create_ceiling'].to_s.empty? ? 'no' : d['create_ceiling'].to_s,
    'ceiling_pattern' => d['ceiling_pattern'].to_s.empty? ? 'flat' : d['ceiling_pattern'].to_s,
    'drop_reference' => d['drop_reference'].to_s.empty? ? 'below_wall' : d['drop_reference'].to_s
  }
end

def create_wall_draw_session(data)
  model = Sketchup.active_model
  return nil unless model && model.valid?
  data = normalize_wall_draw_data(data)
  group = begin
    model.entities.add_group
  rescue
    model.active_entities.add_group
  end
  room_name = data['room_name'].to_s.strip
  room_uuid = uuid.to_s
  group_name = "#{room_name} | #{ts('رسم حوائط مباشر').to_s}"
  group.name = group_name
  room_tag = tag(model, room_name.to_s)
  group.layer = room_tag if room_tag
  set_attrs(group, {
    'UUID' => room_uuid,
    'النوع' => 'رسم حوائط مباشر',
    'اسم الغرفة' => room_name,
    'ارتفاع الحائط سم' => data['wall_h'].to_f,
    'سمك الحائط سم' => data['wall_t'].to_f,
    'سمك الأرضية سم' => data['floor_t'].to_f,
    'سمك السقف سم' => data['ceil_t'].to_f,
    'إنشاء أرضية' => enabled_value?(data['create_floor']) ? 'نعم' : 'لا',
    'إنشاء سقف' => enabled_value?(data['create_ceiling']) ? 'نعم' : 'لا',
    'نمط السقف' => data['ceiling_pattern'].to_s,
    'طريقة حساب السقوط' => data['drop_reference'].to_s,
    'wall_draw_points' => [].to_json,
    'shatras_json' => [].to_json,
    'beams_json' => [].to_json,
    'wall_overrides_json' => {}.to_json
  })
  group
rescue => e
  raise "تعذر إنشاء جلسة الرسم: #{e.class}: #{e.message}"
end

def wall_draw_add_segment(group, p1, p2, height_cm, thickness_cm, number)
  model = Sketchup.active_model
  return nil unless model && model.valid? && group && group.valid? && p1 && p2
  vec = p1.vector_to(p2)
  return nil if vec.length <= 0.1.mm
  dir = vec.clone
  dir.normalize!
  perp = Geom::Vector3d.new(-dir.y, dir.x, 0)
  perp.normalize!
  half = thickness_cm.to_f.cm / 2.0
  q1 = p1.offset(perp, half)
  q2 = p2.offset(perp, half)
  q3 = p2.offset(perp.reverse, half)
  q4 = p1.offset(perp.reverse, half)

  # IMPORTANT: build a plain Group directly inside the session group.
  # Avoid add_instance/ComponentDefinition here because SketchUp can invalidate
  # a nested Group during interactive Tool operations in some edit contexts.
  wall_group = group.entities.add_group
  name = format('%s %02d', ts('حائط').to_s, number.to_i)
  wall_group.name = name.to_s

  face = wall_group.entities.add_face(q1, q2, q3, q4)
  raise 'تعذر إنشاء سطح الحائط.' unless face && face.valid?
  face.reverse! if face.normal.z < 0
  face.pushpull(height_cm.to_f.cm)

  room_name = group.get_attribute(DICT, 'اسم الغرفة').to_s.strip
  room_name = ts('غرفة جديدة').to_s if room_name.empty?
  begin
    layer_name = [room_name, name.to_s].join(' | ')
    layer_obj = tag(model, layer_name)
    wall_group.layer = layer_obj if layer_obj && wall_group.valid?
  rescue
  end

  set_attrs(wall_group, {
    'UUID' => uuid.to_s,
    'Room_UUID' => group.get_attribute(DICT, 'UUID').to_s,
    'النوع' => 'حائط',
    'اسم الغرفة' => room_name,
    'رقم الحائط' => number.to_i,
    'الاسم' => name.to_s,
    'الارتفاع سم' => height_cm.to_f,
    'السمك سم' => thickness_cm.to_f,
    'طول الحائط سم' => p1.distance(p2).to_cm.round(2),
    'P1' => pt_to_s(p1),
    'P2' => pt_to_s(p2),
    'رسم_تفاعلي' => 'نعم'
  })
  wall_group
rescue => e
  raise e
end

def wall_draw_temporary_cleanup(group)
  group.erase! if group && group.valid?
rescue
end

class WallDrawTool
  SNAP_DEGREES = 5.0

  def initialize(data)
    @data = MHD_RoomBuilder_Context.normalize_wall_draw_data(data)
    @group = nil
    @points = []
    @preview_point = nil
    @last_cursor_point = nil
    @typed_length_cm = nil
    @wall_number = 1
    @ip = Sketchup::InputPoint.new
    @active = false
    @snapped_angle = nil
    @snap_name = nil
    @snap_target = nil
    @snap_type = nil
    @snap_distance_cm = nil
  end

  def activate
    @active = true
    @group = nil
    set_status('🧱 اضغط كليك لتحديد نقطة البداية ثم ارسم الحوائط مباشرة. الحائط يُنشأ فعليًا عند كل كليك.')
    Sketchup.active_model.active_view.invalidate
  rescue => e
    @active = false
    UI.messagebox("خطأ في تفعيل أداة الرسم:\n#{e.class}: #{e.message}") rescue nil
  end

  def deactivate(_view)
    Sketchup.status_text = ''.to_s
  rescue
  end

  def enableVCB?
    true
  end

  def draw(view)
    return unless @active
    begin
      # Direct wall drawing preview — no laser.
      # Committed walls are real SketchUp groups; preview is only the next wall footprint.
      if @points.length >= 1 && (@preview_point || @last_cursor_point)
        p1 = @points[-1]
        p2 = @preview_point || @last_cursor_point
        dir = p1.vector_to(p2)
        if dir.length > 0.1.mm
          dir.normalize!
          perp = Geom::Vector3d.new(-dir.y, dir.x, 0)
          perp.normalize!
          half = (@data['wall_t'].to_f.cm / 2.0)
          a1 = p1.offset(perp, half)
          a2 = p1.offset(perp.reverse, half)
          b1 = p2.offset(perp, half)
          b2 = p2.offset(perp.reverse, half)

          # Clean wall-footprint preview instead of a laser.
          view.line_width = 3
          view.drawing_color = Sketchup::Color.new(255, 145, 0)
          view.draw(GL_LINE_LOOP, [a1, b1, b2, a2])

          # Vertical corners preview for a clear 3D construction feel.
          h = @data['wall_h'].to_f.cm
          z1 = a1.offset(Z_AXIS, h)
          z2 = b1.offset(Z_AXIS, h)
          z3 = b2.offset(Z_AXIS, h)
          z4 = a2.offset(Z_AXIS, h)
          view.line_width = 2
          view.drawing_color = Sketchup::Color.new(255, 180, 60)
          view.draw(GL_LINES, [a1, z1, b1, z2, b2, z3, a2, z4, z1, z2, z2, z3, z3, z4, z4, z1])

          # Dynamic dimension text only.
          offset = [@data['wall_t'].to_f.cm, 25.cm].max
          dim_a = p1.offset(perp, offset)
          dim_b = p2.offset(perp, offset)
          view.line_width = 2
          view.drawing_color = Sketchup::Color.new(255, 215, 0)
          view.draw(GL_LINES, [dim_a, dim_b])
          tick = 6.cm
          view.draw(GL_LINES, [dim_a.offset(perp.reverse, tick), dim_a.offset(perp, tick), dim_b.offset(perp.reverse, tick), dim_b.offset(perp, tick)])

          len_cm = p1.distance(p2).to_cm
          angle = segment_angle_deg(p1, p2)
          text = []
          text << "حائط #{format('%02d', @wall_number)}"
          text << "الطول: #{len_cm.round(1)} سم"
          text << "الزاوية: #{angle.round(1)}°"
          text << "سمك: #{@data['wall_t'].to_f.round(1)} سم"
          text << "ارتفاع: #{@data['wall_h'].to_f.round(1)} سم"
          text << "↯ #{@snap_name}" if @snap_name
          view.draw_text(dim_a.offset(Z_AXIS, 10.cm), text.join("\n"))
        end
      end

      # Clear point markers. Green = exact snap, cyan = alignment.
      if @points.any?
        view.draw_points([@points.first], 12, 1, Sketchup::Color.new(0, 220, 255))
        view.draw_points([@points[-1]], 11, 1, Sketchup::Color.new(255, 180, 0))
      elsif @last_cursor_point
        view.draw_points([@last_cursor_point], 12, 1, Sketchup::Color.new(0, 220, 255))
      end

      if @snap_target
        marker_color = (@snap_type.to_s == 'نقطة اتصال' || @snap_type.to_s == 'نقطة حائط') ? Sketchup::Color.new(0, 255, 90) : Sketchup::Color.new(0, 220, 255)
        view.draw_points([@snap_target], 16, 2, marker_color)
        view.draw_text(@snap_target.offset(Z_AXIS, 12.cm), "🧲 #{@snap_type}") if @snap_type
      end

      if @points.length >= 3 && @last_cursor_point && @last_cursor_point.distance(@points.first) <= 25.cm
        view.drawing_color = Sketchup::Color.new(0, 255, 120)
        view.line_width = 4
        view.draw(GL_LINES, [@points[-1], @points.first])
        view.draw_text(@points.first.offset(Z_AXIS, 18.cm), '⬤ اضغط هنا لإغلاق الغرفة')
      end
    rescue
      # Keep the direct drawing tool alive if a transient preview call fails.
    end
  end

  def onMouseMove(_flags, x, y, view)
    return unless @active
    @ip.pick(view, x, y)
    p = @ip.position
    return unless p
    p = Geom::Point3d.new(p.x, p.y, 0)
    @last_cursor_point = p
    if @points.empty?
      @preview_point = p
      set_status('انقر لتثبيت نقطة بداية الحائط.')
      view.invalidate
      return
    end
    start = @points[-1]
    cursor = apply_smart_snap(start, p)
    cursor = apply_point_and_axis_snap(start, cursor)
    if @typed_length_cm && @typed_length_cm > 0
      vec = start.vector_to(cursor)
      if vec.length > 0.1.mm
        vec.normalize!
        cursor = start.offset(vec, @typed_length_cm.cm)
      end
    end
    @preview_point = cursor
    update_status
    view.invalidate
  rescue => e
    Sketchup.status_text = "Wall Draw: #{e.class}: #{e.message}".to_s rescue nil
  end

  def onLButtonDown(_flags, x, y, view)
    return unless @active
    @ip.pick(view, x, y)
    p = @ip.position
    return unless p
    p = Geom::Point3d.new(p.x, p.y, 0)

    if @points.empty?
      ensure_session!
      @points << p
      @preview_point = p
      set_status('حائط 01: حرّك الماوس ثم اضغط كليك لتثبيت الحائط.')
      view.invalidate
      return
    end

    start = @points[-1]
    target = @preview_point || apply_smart_snap(start, p)
    target = apply_point_and_axis_snap(start, target)
    if @points.length >= 3 && target.distance(@points.first) <= 10.cm
      target = @points.first
      commit_segment(target, view)
      close_polygon(view)
      return
    end
    commit_segment(target, view)
  rescue => e
    UI.messagebox("خطأ أثناء رسم الحائط:\n#{e.class}: #{e.message}") rescue nil
  end

  def onUserText(text, view)
    return unless @active && !@points.empty?
    value = text.to_s.tr(',', '.').to_f
    return if value <= 0
    @typed_length_cm = value
    start = @points[-1]
    cursor = @last_cursor_point || @preview_point
    if start && cursor
      vec = start.vector_to(cursor)
      if vec.length > 0.1.mm
        vec.normalize!
        @preview_point = start.offset(vec, value.cm)
      end
    end
    update_status
    view.invalidate
  end

  def onKeyDown(key, _repeat, _flags, view)
    case key
    when 8
      undo_last(view)
    when 13
      commit_segment(@preview_point || @last_cursor_point, view) unless @points.empty? || !(@preview_point || @last_cursor_point)
    when 27
      cancel_session
    end
  end

  def onRButtonDown(_flags, _x, _y, _view)
    menu = UI::Menu.new
    menu.add_item('✅ إنهاء وإغلاق الغرفة') { close_polygon(nil) }
    menu.add_item('↩️ حذف آخر حائط') { undo_last(nil) }
    menu.add_separator
    menu.add_item('❌ إلغاء الرسم') { cancel_session }
    menu.show
  end

  def onCancel(_reason, _view)
    cancel_session
  end

  private

  def set_status(text)
    Sketchup.status_text = text.to_s
  rescue
  end

  def ensure_session!
    return @group if @group && @group.valid?
    @group = MHD_RoomBuilder_Context.create_wall_draw_session(@data)
    raise 'تعذر إنشاء جلسة رسم الحوائط.' unless @group && @group.valid?
    @group
  end

  def segment_angle_deg(p1, p2)
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    Math.atan2(dy, dx) * 180.0 / Math::PI
  rescue
    0.0
  end

  def apply_smart_snap(start, point)
    @snapped_angle = nil
    @snap_name = nil
    @snap_target = nil
    @snap_type = nil
    @snap_distance_cm = nil
    vec = start.vector_to(point)
    return point if vec.length <= 0.1.mm
    raw_angle = Math.atan2(vec.y, vec.x)
    raw_deg = (raw_angle * 180.0 / Math::PI) % 360.0
    candidates = (0..7).map { |i| i * 45.0 }
    nearest = candidates.min_by { |a| angular_diff(raw_deg, a) }
    diff = angular_diff(raw_deg, nearest)
    if diff <= SNAP_DEGREES
      len = vec.length
      rad = nearest * Math::PI / 180.0
      snapped = Geom::Point3d.new(start.x + Math.cos(rad) * len, start.y + Math.sin(rad) * len, 0)
      @snapped_angle = nearest
      @snap_name = nearest % 90.0 == 0 ? 'Snap 90°' : 'Snap 45°'
      snapped
    else
      point
    end
  rescue
    point
  end

  def apply_point_and_axis_snap(start, point)
    @snap_target = nil
    @snap_type = nil
    @snap_distance_cm = nil
    return point unless start && point

    # 1) Hard snap to known room points / endpoints.
    candidates = @points.dup
    if @group && @group.valid?
      begin
        @group.entities.to_a.each do |e|
          next unless e.valid?
          next unless e.respond_to?(:get_attribute)
          next unless e.get_attribute(MHD_RoomBuilder_Context::DICT, 'النوع').to_s == 'حائط'
          %w[P1 P2].each do |key|
            raw = e.get_attribute(MHD_RoomBuilder_Context::DICT, key).to_s
            next if raw.empty?
            arr = raw.split('|').map(&:to_f)
            candidates << Geom::Point3d.new(arr[0], arr[1], arr[2] || 0.0) if arr.length >= 2
          end
        end
      rescue
      end
    end

    snap_radius = 22.0.cm
    nearest = candidates.min_by { |c| c.distance(point) }
    if nearest && nearest.distance(point) <= snap_radius
      @snap_target = nearest
      @snap_type = 'نقطة اتصال'
      @snap_distance_cm = nearest.distance(point).to_cm
      @snap_name = 'Snap نقطة'
      return Geom::Point3d.new(nearest.x, nearest.y, 0)
    end

    # 2) Smart horizontal/vertical alignment against existing points.
    axis_threshold = 12.0.cm
    best = point
    best_d = Float::INFINITY
    best_type = nil
    @points.each do |q|
      dx = (point.x - q.x).abs
      dy = (point.y - q.y).abs
      if dx <= axis_threshold && dx < best_d
        best = Geom::Point3d.new(q.x, point.y, 0)
        best_d = dx
        best_type = 'محاذاة رأسية'
      end
      if dy <= axis_threshold && dy < best_d
        best = Geom::Point3d.new(point.x, q.y, 0)
        best_d = dy
        best_type = 'محاذاة أفقية'
      end
    end
    if best_type
      @snap_target = best
      @snap_type = best_type
      @snap_distance_cm = best_d.to_f.to_cm
      @snap_name = best_type
      return best
    end

    point
  rescue
    point
  end

  def angular_diff(a, b)
    d = (a - b).abs % 360.0
    d > 180.0 ? 360.0 - d : d
  end

  def update_status
    return if @points.empty?
    p = @preview_point || @last_cursor_point
    return unless p
    start = @points[-1]
    len = start.distance(p).to_cm
    angle = segment_angle_deg(start, p)
    msg = "#{MHD_RoomBuilder_Context.ts('حائط').to_s} #{format('%02d', @wall_number)} | #{MHD_RoomBuilder_Context.ts('الطول').to_s}: #{len.round(1)} سم | #{MHD_RoomBuilder_Context.ts('الزاوية').to_s}: #{angle.round(1)}°"
    msg += " | #{@snap_name}" if @snap_name
    msg += ' | اكتب المقاس ثم Enter'
    set_status(msg)
  end

  def commit_segment(target, view)
    return if @points.empty? || !target
    target = Geom::Point3d.new(target.x, target.y, 0)
    start = @points[-1]
    return if target.distance(start) <= 0.5.cm

    ensure_session!
    begin
      # Build a REAL wall immediately. The final room synchronization will rebuild
      # these walls from the same points, so live drawing and the parametric model
      # share one source of truth.
      wall = MHD_RoomBuilder_Context.wall_draw_add_segment(
        @group, start, target, @data['wall_h'].to_f, @data['wall_t'].to_f, @wall_number
      )
      raise 'تعذر إنشاء الحائط الفعلي.' unless wall && wall.valid?
    rescue => e
      UI.messagebox("تعذر إنشاء الحائط رقم #{@wall_number}:\n#{e.class}: #{e.message}") rescue nil
      return
    end

    @points << target
    @wall_number += 1
    @typed_length_cm = nil
    @preview_point = target
    @snap_target = target
    @snap_type = 'نقطة حائط'
    @snap_name = 'Snap نقطة'
    @snap_distance_cm = 0.0
    save_points
    set_status("✅ حائط #{@wall_number - 1} تم إنشاؤه فعليًا | حرّك الماوس لرسم الحائط التالي")
    view.invalidate if view
  end

  def save_points
    return unless @group && @group.valid?
    @group.set_attribute(MHD_RoomBuilder_Context::DICT, 'wall_draw_points', @points.map { |p| MHD_RoomBuilder_Context.pt_to_s(p) }.to_json)
  rescue
  end

  def close_polygon(view)
    return if @points.length < 3
    first = @points.first
    last = @points.last
    if last.distance(first) > 0.5.cm
      target = first
      commit_segment(target, view)
      @points[-1] = first if @points.length > 1 && @points[-1].distance(first) <= 0.5.cm
    end
    if MHD_RoomBuilder_Context.wall_draw_finalize_tool(self)
      @active = false
      Sketchup.active_model.select_tool(nil)
    end
    view.invalidate if view
  rescue => e
    UI.messagebox("خطأ عند إغلاق الغرفة:\n#{e.class}: #{e.message}") rescue nil
  end

  def undo_last(view)
    return if @points.empty?
    if @points.length == 1
      cancel_session
      return
    end
    if @group && @group.valid?
      walls = @group.entities.to_a.select do |e|
        e.valid? && e.respond_to?(:get_attribute) && e.get_attribute(MHD_RoomBuilder_Context::DICT, 'النوع').to_s == 'حائط'
      end
      last_wall = walls.max_by { |e| e.get_attribute(MHD_RoomBuilder_Context::DICT, 'رقم الحائط').to_i }
      last_wall.erase! if last_wall && last_wall.valid?
    end
    @points.pop
    @wall_number = [@wall_number - 1, 1].max
    @typed_length_cm = nil
    @preview_point = @points.last
    @snap_target = @points.last
    @snap_type = @points.last ? 'نقطة حائط' : nil
    @snap_name = @points.last ? 'Snap نقطة' : nil
    save_points
    update_status
    view.invalidate if view
  end

  def cancel_session
    MHD_RoomBuilder_Context.wall_draw_temporary_cleanup(@group)
    @group = nil
    @points = []
    @active = false
    Sketchup.active_model.select_tool(nil)
    set_status('')
  end
end


def wall_draw_finalize_tool(tool)
  return false unless tool
  group = tool.instance_variable_get(:@group)
  pts = tool.instance_variable_get(:@points)
  data = tool.instance_variable_get(:@data)
  return false unless group && group.valid? && pts.is_a?(Array) && pts.length >= 3

  model = Sketchup.active_model
  room_data = normalize_wall_draw_data(data)
  # Store the points and required room metadata before synchronization.
  group.set_attribute(DICT, 'wall_draw_points', pts.map { |p| pt_to_s(p) }.to_json)
  group.set_attribute(DICT, 'النوع', 'غرفة')
  group.set_attribute(DICT, 'اسم الغرفة', room_data['room_name'].to_s)
  group.set_attribute(DICT, 'UUID', group.get_attribute(DICT, 'UUID').to_s.empty? ? uuid.to_s : group.get_attribute(DICT, 'UUID').to_s)

  # The laser stores points only; permanent geometry is built once from the final polygon.
  group.set_attribute(DICT, 'النوع', 'غرفة')
  synchronize_room_geometry(group, pts, room_data)
  model.active_view.invalidate if model && model.valid?
  true
rescue => e
  UI.messagebox("خطأ عند اعتماد الغرفة من الليزر:\n#{e.class}: #{e.message}") rescue nil
  false
end

def activate_wall_draw_tool_direct
  model = Sketchup.active_model
  return false unless model && model.valid?
  begin
    data = normalize_wall_draw_data(wall_draw_defaults)
    tool = WallDrawTool.new(data)
    model.select_tool(tool)
    UI.start_timer(0.10, false) do
      begin
        Sketchup.status_text = '🧱 MHD | رسم الحوائط المباشر جاهز: اضغط كليك لنقطة البداية ثم ابدأ الرسم.'
        model.active_view.invalidate
      rescue
      end
    end
    true
  rescue => e
    UI.messagebox("خطأ في بدء رسم الحوائط:\n#{e.class}: #{e.message}\n\nالقيم الافتراضية لم يتم إنشاؤها أو تشغيل أداة SketchUp.") rescue nil
    false
  end
end

# مسار قديم للإعدادات محفوظ للتوافق الداخلي؛ الواجهة تستخدم الرسم المباشر فقط.
def activate_wall_draw_tool
  model = Sketchup.active_model
  return false unless model && model.valid?
  begin
    data = wall_draw_setup_dialog
    return false unless data.is_a?(Hash)
    data = normalize_wall_draw_data(data)
    tool = WallDrawTool.new(data)
    model.select_tool(tool)
    UI.start_timer(0.10, false) do
      begin
        Sketchup.status_text = '🧱 MHD | رسم الحوائط المباشر جاهز: اضغط كليك لنقطة البداية ثم ابدأ الرسم.'
        model.active_view.invalidate
      rescue
      end
    end
    true
  rescue => e
    UI.messagebox("خطأ في تشغيل أداة رسم الحوائط:\n#{e.class}: #{e.message}") rescue nil
    false
  end
end

# =========================================================
# MHD SHATRA ENGINE V1 - Smart wall-corner calibration
# =========================================================
def shatras_from_room(room_group)
  json = room_group.get_attribute(DICT, 'shatras_json').to_s
  return [] if json.empty?
  data = JSON.parse(json) rescue []
  data.is_a?(Array) ? data : []
end

def save_shatras(room_group, shatras)
  room_group.set_attribute(DICT, 'shatras_json', shatras.to_json)
end

def delete_room_shatras(room_group)
  room_group.entities.to_a.each do |e|
    next unless e.valid?
    next unless e.is_a?(Sketchup::Group)
    next unless e.get_attribute(DICT, 'النوع').to_s == 'شطرة حائط'
    e.erase!
  end
end

def shatra_corner_index(room_group, click_point)
  pts = room_pts_from_group(room_group)
  return nil unless pts && pts.length >= 3 && click_point
  idx = nil
  best = 1.0e99
  pts.each_with_index do |p, i|
    d = p.distance(click_point)
    if d < best
      best = d
      idx = i
    end
  end
  idx
rescue
  nil
end

def shatra_angle_from_sides(a_cm, b_cm, diagonal_cm)
  a = a_cm.to_f
  b = b_cm.to_f
  c = diagonal_cm.to_f
  return nil if a <= 0 || b <= 0 || c <= 0
  # قانون جيب التمام: الزاوية المحصورة بين الضلعين a و b.
  cosv = (a*a + b*b - c*c) / (2.0*a*b)
  return nil if cosv < -1.000001 || cosv > 1.000001
  cosv = [[cosv, -1.0].max, 1.0].min
  Math.acos(cosv) * 180.0 / Math::PI
end

def shatra_adjust_corner_points(pts, corner_idx, desired_angle_deg)
  return nil unless pts.is_a?(Array) && pts.length >= 3
  i = corner_idx.to_i
  n = pts.length
  return nil if i < 0 || i >= n
  prev_i = (i - 1) % n
  next_i = (i + 1) % n
  corner = pts[i]
  prev = pts[prev_i]
  nxt  = pts[next_i]

  u = corner.vector_to(prev)
  v = corner.vector_to(nxt)
  lu = u.length
  lv = v.length
  return nil if lu <= 0.1.mm || lv <= 0.1.mm

  u.normalize!
  v.normalize!
  current_angle = Math.acos([[u.dot(v), -1.0].max, 1.0].min)
  desired = desired_angle_deg.to_f * Math::PI / 180.0
  return nil if desired <= 0.001 || desired >= Math::PI - 0.001

  delta = desired - current_angle
  cross_z = u.cross(v).z.to_f
  sign = cross_z >= 0 ? 1.0 : -1.0

  # تعديل متناظر حول الزاوية: نحافظ على طول الحائطين ونغيّر الزاوية.
  r1 = Geom::Transformation.rotation(corner, Z_AXIS, -sign * delta / 2.0)
  r2 = Geom::Transformation.rotation(corner, Z_AXIS,  sign * delta / 2.0)
  new_u = u.transform(r1)
  new_v = v.transform(r2)

  result = pts.map { |p| p.clone }
  result[prev_i] = corner.offset(new_u, lu)
  result[next_i] = corner.offset(new_v, lv)
  result
rescue
  nil
end

def build_shatra_guide(room_group, shatra)
  pts = room_pts_from_group(room_group)
  return nil unless pts && pts.length >= 3

  i = shatra['corner_index'].to_i
  return nil if i < 0 || i >= pts.length
  prev_i = (i - 1) % pts.length
  next_i = (i + 1) % pts.length

  corner = pts[i]
  p_prev = pts[prev_i]
  p_next = pts[next_i]

  a_len = shatra['a_cm'].to_f.cm
  b_len = shatra['b_cm'].to_f.cm
  return nil if a_len <= 0 || b_len <= 0

  va = corner.vector_to(p_prev)
  vb = corner.vector_to(p_next)
  return nil if va.length <= 0.1.mm || vb.length <= 0.1.mm
  va.normalize!
  vb.normalize!

  # لو المسافة المطلوبة أكبر من الحائط، نوقفها عند نهاية الحائط.
  a_len = [a_len, corner.distance(p_prev)].min
  b_len = [b_len, corner.distance(p_next)].min

  pa = corner.offset(va, a_len)
  pb = corner.offset(vb, b_len)
  z = [corner.z, p_prev.z, p_next.z].max + 0.8.cm
  pa.z = z
  pb.z = z
  c = corner.clone
  c.z = z

  grp = room_group.entities.add_group
  grp.name = "شطرة | زاوية #{format('%.2f', shatra['angle_deg'].to_f)}°"
  grp.layer = tag(Sketchup.active_model, 'MHD | شطرة الحائط')

  e1 = grp.entities.add_line(c, pa)
  e2 = grp.entities.add_line(c, pb)
  diag = grp.entities.add_line(pa, pb)
  [e1, e2, diag].compact.each do |edge|
    begin
      edge.soft = true if edge.respond_to?(:soft=)
    rescue
    end
  end

  # علامات صغيرة عند طرفي القياسين لإظهار نقطة القياس بوضوح.
  tick = 1.5.cm
  [-1, 1].each do |side|
    # لا نستخدم ألواناً أو API غير مضمونة؛ الخطوط نفسها هي الدليل المرئي.
  end

  set_attrs(grp, {
    'UUID' => (shatra['uuid'].to_s.empty? ? uuid : shatra['uuid'].to_s),
    'Room_UUID' => room_group.get_attribute(DICT, 'UUID').to_s,
    'النوع' => 'شطرة حائط',
    'الزاوية درجة' => shatra['angle_deg'].to_f.round(3),
    'المقاس الأول سم' => shatra['a_cm'].to_f,
    'المقاس الثاني سم' => shatra['b_cm'].to_f,
    'القطر سم' => shatra['diagonal_cm'].to_f,
    'رقم الركن' => i + 1
  })
  grp
rescue
  nil
end

def rebuild_all_shatras(room_group)
  shatras = shatras_from_room(room_group)
  delete_room_shatras(room_group)
  return true if shatras.empty?
  shatras.each { |s| build_shatra_guide(room_group, s) }
  true
end

def apply_shatra_calibration(room_group, corner_idx, data)
  return false unless room_group && room_group.valid?
  a = data['a_cm'].to_f
  b = data['b_cm'].to_f
  diag = data['diagonal_cm'].to_f
  angle = shatra_angle_from_sides(a, b, diag)

  unless angle
    UI.messagebox("❌ مقاسات الشطرة غير هندسية.\nلازم القطر يكون أكبر من |#{a} - #{b}| وأصغر من #{a + b}.")
    return false
  end

  pts = room_pts_from_group(room_group)
  unless pts && pts.length >= 3
    UI.messagebox('❌ لا يمكن قراءة نقاط الغرفة.')
    return false
  end

  new_pts = shatra_adjust_corner_points(pts, corner_idx, angle)
  unless new_pts && polygon_valid_for_wall_edit?(new_pts)
    UI.messagebox('❌ التعديل سيؤدي إلى شكل غرفة غير صالح.')
    return false
  end

  model = Sketchup.active_model
  room_data = build_data_from_group(room_group) || {}
  room_data = room_data.dup
  old_pts = pts.map(&:clone)
  model.start_operation('MHD Smart Shatra Calibration', true)
  begin
    remove_legacy_source_floor_geometry(old_pts)
    # نبني كل Geometry مرة واحدة من النقاط الجديدة ثم نعيد رسم مرجع الشطرة.
    rebuild_room_after_wall_edit(room_group, new_pts, room_data)

    shatras = shatras_from_room(room_group)
    target_uuid = data['uuid'].to_s
    previous = shatras.find { |s| !target_uuid.empty? && s['uuid'].to_s == target_uuid }
    shatras.reject! { |s| s['corner_index'].to_i == corner_idx.to_i || (!target_uuid.empty? && s['uuid'].to_s == target_uuid) }
    shatras << {
      'uuid' => (target_uuid.empty? ? uuid : target_uuid),
      'corner_index' => corner_idx.to_i,
      'a_cm' => a,
      'b_cm' => b,
      'diagonal_cm' => diag,
      'angle_deg' => angle
    }
    save_shatras(room_group, shatras)
    rebuild_all_shatras(room_group)

    model.commit_operation
    model.active_view.invalidate
    UI.messagebox("✅ تم ضبط الشطرة بنجاح\n\n#{shatra_result_text(a, b, diag, angle)}")
    true
  rescue => e
    model.abort_operation rescue nil
    UI.messagebox("❌ خطأ أثناء ضبط الشطرة:\n#{e.message}")
    false
  end
end

def shatra_for_corner(room_group, corner_idx)
  shatras_from_room(room_group).find { |s| s['corner_index'].to_i == corner_idx.to_i }
end

def delete_shatra(room_group, shatra_uuid)
  return false unless room_group && room_group.valid?
  uuid_to_delete = shatra_uuid.to_s
  shatras = shatras_from_room(room_group)
  remaining = shatras.reject { |s| s['uuid'].to_s == uuid_to_delete }
  return false if remaining.length == shatras.length
  model = Sketchup.active_model
  model.start_operation('MHD Delete Shatra', true)
  begin
    save_shatras(room_group, remaining)
    rebuild_all_shatras(room_group)
    model.commit_operation
    model.active_view.invalidate
    UI.messagebox('✅ تم حذف الشطرة بنجاح')
    true
  rescue => e
    model.abort_operation rescue nil
    UI.messagebox("❌ خطأ أثناء حذف الشطرة:\n#{e.message}")
    false
  end
end

def open_shatra_dialog(room_group, corner_idx, existing = nil)
  pts = room_pts_from_group(room_group)
  return UI.messagebox('❌ لا توجد نقاط غرفة صالحة.') unless pts && pts.length >= 3

  existing ||= shatra_for_corner(room_group, corner_idx)
  current_angle = current_corner_angle(pts, corner_idx) || 90.0
  existing_info = existing ? shatra_result_text(existing['a_cm'], existing['b_cm'], existing['diagonal_cm'], existing['angle_deg'].to_f) : nil

  dlg = UI::HtmlDialog.new(
    dialog_title: 'شطرة الحائط — MHDESIGN',
    preferences_key: PREF_KEY + '_SHATRA',
    scrollable: true,
    resizable: true,
    width: 450,
    height: 700,
    style: UI::HtmlDialog::STYLE_DIALOG
  )

  a0 = existing ? existing['a_cm'].to_f : 60.0
  b0 = existing ? existing['b_cm'].to_f : 60.0
  c0 = existing ? existing['diagonal_cm'].to_f : 85.0
  uuid0 = existing ? existing['uuid'].to_s : ''
  safe_info = (existing_info || "لا توجد شطرة محفوظة على هذا الركن.\nالزاوية الهندسية الحالية للركن: #{current_angle.round(2)}°").gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;').gsub("\n", '<br>')

  html = <<-HTML
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<style>
*{box-sizing:border-box}html,body{margin:0;padding:0;background:#07131d;color:#eaf4f8;font-family:Arial,Tahoma,sans-serif;overflow:auto}
.app{padding:16px;min-height:100vh}.title{text-align:center;font-size:24px;font-weight:900}.sub{text-align:center;color:#8eabbc;font-size:12px;margin:5px 0 14px}
.card{background:#0b1b27;border:1px solid #1c3342;border-radius:14px;padding:14px;margin-bottom:12px;box-shadow:0 4px 18px rgba(0,0,0,.18)}
.row{display:grid;grid-template-columns:180px 1fr;gap:9px;align-items:center;margin-bottom:10px}label{font-weight:900;font-size:13px}
input{width:100%;height:40px;background:#111f2a;color:#fff;border:1px solid #294457;border-radius:9px;text-align:center;font-size:15px;padding:0 8px}
.result{background:#102b3b;border:1px solid #26495d;border-radius:11px;padding:13px;text-align:center;font-size:25px;font-weight:900}.state{font-size:14px;margin-top:8px;line-height:1.8}
.info{font-size:12px;color:#b4cbd7;line-height:1.8;background:#091923;border-radius:10px;padding:10px}.hint{font-size:11px;color:#8eabbc;line-height:1.7}
.footer{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:12px}.footer3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-top:8px}
button{height:44px;border:0;border-radius:9px;font-weight:900;font-size:13px;cursor:pointer}.save{background:#4de37a;color:#061923}.close{background:#0b1b27;color:#fff;border:1px solid #294457}.danger{background:#d9534f;color:#fff}.secondary{background:#123044;color:#fff;border:1px solid #294457}
.badge{display:inline-block;background:#17384a;color:#cfe9f6;padding:4px 10px;border-radius:999px;font-size:11px;margin-top:6px}
</style>
</head>
<body>
<div class="app">
  <div class="title">📐 شطرة الحائط</div>
  <div class="sub">شطرة ذكية مرتبطة مباشرة بالركن والحائط والغرفة</div>

  <div class="card">
    <div class="row"><label>المقاس الأول من الركن (سم)</label><input id="a" type="number" min="0.1" step="0.1" value="#{a0}"></div>
    <div class="row"><label>المقاس الثاني من الركن (سم)</label><input id="b" type="number" min="0.1" step="0.1" value="#{b0}"></div>
    <div class="row"><label>القطر بين النقطتين (سم)</label><input id="c" type="number" min="0.1" step="0.1" value="#{c0}"></div>
  </div>

  <div class="card">
    <div class="result">الزاوية: <span id="angle">—</span>°
      <div class="state"><span id="state">الحالة: —</span><br><span id="dev">الانحراف: —</span><br><span id="eq">الشطف المكافئ: —</span></div>
    </div>
  </div>

  <div class="card">
    <div class="badge">معلومات الشطرة الحالية</div>
    <div id="info" class="info">#{safe_info}</div>
  </div>

  <div class="card">
    <div class="hint">اكتب المقاسين والقطر، وسيتم حساب الزاوية تلقائياً. بعد التطبيق يتم إعادة بناء الحوائط والأرضية والسقف والكمرات والشطرات المرتبطة من نفس Room Geometry، بدون ترك Geometry قديمة.</div>
  </div>

  <div class="footer">
    <button class="save" onclick="applyIt()">📐 تطبيق الشطرة</button>
    <button class="close" onclick="sketchup.cancel()">إغلاق</button>
  </div>
  <div class="footer3">
    <button class="secondary" onclick="refreshInfo()">🔄 تحديث المعلومات</button>
    #{existing ? '<button class="danger" onclick="deleteIt()">🗑 حذف الشطرة</button><button class="secondary" onclick="sketchup.cancel()">✏️ إغلاق وحفظ لاحقاً</button>' : '<button class="secondary" onclick="sketchup.cancel()">✖ إلغاء</button><button class="secondary" onclick="sketchup.cancel()">ℹ️ معاينة فقط</button>'}
  </div>
</div>
<script>
function fmt(v){return Number(v).toFixed(2)}
function calc(){
 const a=parseFloat(document.getElementById('a').value),b=parseFloat(document.getElementById('b').value),c=parseFloat(document.getElementById('c').value);
 if(!(a>0&&b>0&&c>0)){document.getElementById('angle').textContent='—';return null}
 const x=(a*a+b*b-c*c)/(2*a*b);
 if(x<-1||x>1){document.getElementById('angle').textContent='غير صالح';document.getElementById('state').textContent='الحالة: قطر غير هندسي';return null}
 const deg=Math.acos(Math.max(-1,Math.min(1,x)))*180/Math.PI;
 const dev=Math.abs(deg-90); let state=dev<=0.10?'قائمة تقريباً 90°':'مشطولة '+(deg>90?'(مفتوحة)':'(مقفولة)');
 const eq=Math.tan(dev*Math.PI/180)*Math.min(a,b);
 const rd=Math.sqrt(a*a+b*b), diff=c-rd;
 document.getElementById('angle').textContent=fmt(deg);
 document.getElementById('state').textContent='الحالة: '+state;
 document.getElementById('dev').textContent='الانحراف عن 90°: '+fmt(dev)+'°';
 document.getElementById('eq').textContent='الشطف المكافئ على '+fmt(Math.min(a,b))+' سم: '+fmt(eq)+' سم';
 document.getElementById('info').innerHTML='المقاس الأول: '+fmt(a)+' سم<br>المقاس الثاني: '+fmt(b)+' سم<br>القطر: '+fmt(c)+' سم<br>قطر القائمة المقارن: '+fmt(rd)+' سم<br>فرق القطر: '+fmt(diff)+' سم';
 return {a_cm:a,b_cm:b,diagonal_cm:c};
}
['a','b','c'].forEach(id=>document.getElementById(id).addEventListener('input',calc));
function applyIt(){const d=calc();if(!d){alert('راجع المقاسات والقطر');return}sketchup.submit(JSON.stringify(d));}
function refreshInfo(){calc();}
function deleteIt(){sketchup.delete_shatra('#{uuid0}');}
calc();
</script>
</body></html>
  HTML

  dlg.set_html(html)
  dlg.add_action_callback('cancel') { dlg.close }
  dlg.add_action_callback('submit') do |_, json|
    begin
      data = JSON.parse(json)
      dlg.close
      data['uuid'] = uuid0 unless uuid0.to_s.empty?
      apply_shatra_calibration(room_group, corner_idx, data)
    rescue => e
      UI.messagebox("❌ #{e.message}")
    end
  end
  dlg.add_action_callback('delete_shatra') do |_, uid|
    dlg.close
    delete_shatra(room_group, uid)
  end
  dlg.show
end

class ShatraPickTool
  def activate
    Sketchup.status_text = MHD_RoomBuilder_Context.ts('شطرة الحائط: اضغط على شطرة موجودة لتعديلها/حذفها، أو على حائط لإضافة/قياس شطرة')
  end

  def onLButtonDown(_flags, x, y, view)
    ph = view.pick_helper
    ph.do_pick(x, y)
    ent = ph.best_picked

    # 1) لو ضغط المستخدم على شطرة موجودة: افتح بياناتها مباشرة.
    if ent && ent.respond_to?(:get_attribute)
      kind = ent.get_attribute(MHD_RoomBuilder_Context::DICT, 'النوع').to_s
      if kind == 'شطرة حائط'
        room = MHD_RoomBuilder_Context.find_room_group(ent)
        uid = ent.get_attribute(MHD_RoomBuilder_Context::DICT, 'UUID').to_s
        sh = room ? MHD_RoomBuilder_Context.shatras_from_room(room).find { |s| s['uuid'].to_s == uid } : nil
        if room && sh
          MHD_RoomBuilder_Context.open_shatra_dialog(room, sh['corner_index'].to_i, sh)
          return
        end
      end
    end

    # 2) أو اضغط على حائط/عنصر داخل غرفة.
    room = MHD_RoomBuilder_Context.find_room_group(ent)
    unless room
      UI.messagebox(MHD_RoomBuilder_Context.ts('اضغط على حائط أو شطرة داخل غرفة MHD.'))
      return
    end

    click_pt = begin
      view.inputpoint(x, y).position
    rescue
      (ent && ent.respond_to?(:bounds) ? ent.bounds.center : nil)
    end

    corner_idx = nil
    if ent && ent.respond_to?(:get_attribute) && ent.get_attribute(MHD_RoomBuilder_Context::DICT, 'النوع').to_s == 'حائط'
      p1s = ent.get_attribute(MHD_RoomBuilder_Context::DICT, 'P1').to_s.split('|').map(&:to_f)
      p2s = ent.get_attribute(MHD_RoomBuilder_Context::DICT, 'P2').to_s.split('|').map(&:to_f)
      if p1s.length >= 3 && p2s.length >= 3
        p1 = Geom::Point3d.new(*p1s[0,3]); p2 = Geom::Point3d.new(*p2s[0,3])
        cp = click_pt || ent.bounds.center
        picked_point = cp.distance(p1) <= cp.distance(p2) ? p1 : p2
        corner_idx = MHD_RoomBuilder_Context.shatra_corner_index(room, picked_point)
      end
    end
    corner_idx ||= MHD_RoomBuilder_Context.shatra_corner_index(room, click_pt || Geom::Point3d.new(0,0,0))
    unless corner_idx
      UI.messagebox('❌ تعذر تحديد ركن.')
      return
    end

    existing = MHD_RoomBuilder_Context.shatra_for_corner(room, corner_idx)
    MHD_RoomBuilder_Context.open_shatra_dialog(room, corner_idx, existing)
  rescue => e
    UI.messagebox("❌ خطأ في أداة الشطرة:\n#{e.message}")
  end

  def onCancel(_reason, _view)
    Sketchup.active_model.select_tool(nil)
  end
end

def activate_shatra_picker
  Sketchup.active_model.select_tool(ShatraPickTool.new)
end

# =========================================================
# MHD BEAM ENGINE V1 - Dynamic wall beams
# =========================================================
def beams_from_room(room_group)
  json = room_group.get_attribute(DICT, 'beams_json').to_s
  return [] if json.empty?
  data = JSON.parse(json) rescue []
  data.is_a?(Array) ? data : []
end

def save_beams(room_group, beams)
  room_group.set_attribute(DICT, 'beams_json', beams.to_json)
end

def wall_info(wall)
  return nil unless wall && wall.valid?
  p1s = wall.get_attribute(DICT, 'P1').to_s
  p2s = wall.get_attribute(DICT, 'P2').to_s
  a = p1s.split('|').map(&:to_f)
  b = p2s.split('|').map(&:to_f)
  return nil unless a.length >= 3 && b.length >= 3
  p1 = Geom::Point3d.new(a[0], a[1], a[2])
  p2 = Geom::Point3d.new(b[0], b[1], b[2])
  {
    'p1' => p1,
    'p2' => p2,
    'length_cm' => p1.distance(p2).to_cm,
    'wall_h_cm' => wall.get_attribute(DICT, 'الارتفاع سم').to_f,
    'wall_t_cm' => wall.get_attribute(DICT, 'السمك سم').to_f,
    'number' => wall.get_attribute(DICT, 'رقم الحائط').to_i,
    'name' => wall.name.to_s,
    'room_name' => wall.get_attribute(DICT, 'اسم الغرفة').to_s,
    'room_uuid' => wall.get_attribute(DICT, 'Room_UUID').to_s
  }
end

def find_wall_in_room(room_group, wall_number)
  room_group.entities.to_a.find do |e|
    e.valid? &&
      e.is_a?(Sketchup::ComponentInstance) &&
      e.get_attribute(DICT, 'النوع').to_s == 'حائط' &&
      e.get_attribute(DICT, 'رقم الحائط').to_i == wall_number.to_i
  end
end

def beam_specs_for_wall(room_group, wall_number)
  beams_from_room(room_group).select { |b| b['wall_number'].to_i == wall_number.to_i }
end

def next_beam_number(room_group, wall_number)
  nums = beam_specs_for_wall(room_group, wall_number).map { |b| b['number'].to_i }
  (nums.max || 0) + 1
end

def normalize_beam_spec(spec, wall, number = nil)
  info = wall_info(wall)
  return nil unless info
  {
    'uuid' => (spec['uuid'].to_s.empty? ? uuid : spec['uuid'].to_s),
    'wall_number' => info['number'],
    'wall_name' => info['name'],
    'room_uuid' => info['room_uuid'],
    'room_name' => info['room_name'],
    'number' => (number || spec['number']).to_i,
    'height_cm' => spec['height_cm'].to_f,
    'depth_cm' => spec['depth_cm'].to_f,
    'elevation_cm' => spec['elevation_cm'].to_f
  }
end

def delete_room_beams(room_group)
  room_group.entities.to_a.each do |e|
    next unless e.valid?
    next unless e.is_a?(Sketchup::ComponentInstance)
    next unless e.get_attribute(DICT, 'النوع').to_s == 'كمر'
    e.erase!
  end
end

def build_single_beam(model, room_group, wall, spec)
  info = wall_info(wall)
  return nil unless info

  height_cm = spec['height_cm'].to_f
  depth_cm = spec['depth_cm'].to_f
  elevation_cm = spec['elevation_cm'].to_f

  raise 'ارتفاع الكمر لازم يكون أكبر من صفر' if height_cm <= 0
  raise 'عمق الكمر لازم يكون أكبر من صفر' if depth_cm <= 0
  raise 'ارتفاع الكمر من الأرض لا يمكن أن يكون سالباً' if elevation_cm < 0
  if height_cm > info['wall_h_cm']
    height_cm = info['wall_h_cm']
    elevation_cm = 0.0
    spec['height_cm'] = height_cm
    spec['elevation_cm'] = elevation_cm
  elsif elevation_cm + height_cm > info['wall_h_cm']
    elevation_cm = [info['wall_h_cm'] - height_cm, 0.0].max
    spec['elevation_cm'] = elevation_cm
  end

  p1 = info['p1']
  p2 = info['p2']
  d = p1.vector_to(p2)
  length = d.length
  raise 'طول الحائط غير صالح لإنشاء الكمر' if length <= 0.1.mm
  d.normalize!
  n = d.cross(Z_AXIS)
  n.normalize!
  half_depth = depth_cm.cm / 2.0

  base_z = p1.z + elevation_cm.cm
  a = p1.offset(n, half_depth)
  b = p2.offset(n, half_depth)
  c = p2.offset(n, -half_depth)
  dpt = p1.offset(n, -half_depth)

  a.z = base_z
  b.z = base_z
  c.z = base_z
  dpt.z = base_z

  definition = model.definitions.add(
    "MHD_كمر_#{spec['number']}_حائط_#{info['number']}_#{Time.now.to_i}_#{rand(99999)}"
  )
  face = definition.entities.add_face(a, b, c, dpt)
  raise 'تعذر إنشاء سطح الكمر' unless face
  face.reverse! if face.normal.z < 0
  face.pushpull(height_cm.cm)

  beam_name = "كمر #{spec['number']} | #{info['name']}"
  beam_inst = room_group.entities.add_instance(definition, Geom::Transformation.new)
  beam_inst.name = beam_name
  beam_inst.layer = tag(model, beam_name)

  set_attrs(beam_inst, {
    'UUID' => spec['uuid'],
    'Room_UUID' => info['room_uuid'],
    'النوع' => 'كمر',
    'اسم الغرفة' => info['room_name'],
    'رقم الحائط' => info['number'],
    'الحائط' => info['name'],
    'رقم الكمر' => spec['number'],
    'الاسم' => beam_name,
    'ارتفاع الكمر سم' => height_cm,
    'عمق الكمر سم' => depth_cm,
    'ارتفاع من الأرض سم' => elevation_cm,
    'طول الكمر سم' => info['length_cm'].round(2),
    'Wall_P1' => pt_to_s(p1),
    'Wall_P2' => pt_to_s(p2)
  })
  beam_inst
end

def rebuild_all_beams(room_group)
  beams = beams_from_room(room_group)
  delete_room_beams(room_group)
  return true if beams.empty?

  model = Sketchup.active_model
  room_group.set_attribute(DICT, 'beams_json', beams.to_json)

  beams.group_by { |b| b['wall_number'].to_i }.each do |wall_number, wall_beams|
    wall = find_wall_in_room(room_group, wall_number)
    next unless wall && wall.valid?
    wall_beams.each do |spec|
      begin
        build_single_beam(model, room_group, wall, spec)
      rescue => e
        UI.messagebox("⚠️ لم يتم إنشاء #{spec['number']} للحائط #{wall_number}:\n#{e.message}")
      end
    end
  end
  true
end

def rename_beam_tags_for_room(room_group)
  beams = beams_from_room(room_group)
  return if beams.empty?
  beams.each do |spec|
    wall = find_wall_in_room(room_group, spec['wall_number'])
    next unless wall
    spec['wall_name'] = wall.name.to_s
    spec['room_name'] = wall.get_attribute(DICT, 'اسم الغرفة').to_s
  end
  save_beams(room_group, beams)
  rebuild_all_beams(room_group)
end

def beam_room_from_entity(entity)
  find_room_group(entity)
end

def open_beam_dialog(target, edit_uuid = nil)
  room_group = beam_room_from_entity(target)
  unless room_group
    UI.messagebox(ts('لم يتم العثور على غرفة MHD مرتبطة بهذا العنصر.'))
    return
  end

  is_beam = target.is_a?(Sketchup::ComponentInstance) &&
            target.get_attribute(DICT, 'النوع').to_s == 'كمر'

  wall = if is_beam
    find_wall_in_room(room_group, target.get_attribute(DICT, 'رقم الحائط').to_i)
  else
    target
  end

  unless wall && wall.valid? && wall.get_attribute(DICT, 'النوع').to_s == 'حائط'
    UI.messagebox(ts('حدد حائطاً صحيحاً لإضافة الكمر.'))
    return
  end

  info = wall_info(wall)
  beams = beams_from_room(room_group)
  current = nil

  if is_beam
    current = beams.find { |b| b['uuid'].to_s == target.get_attribute(DICT, 'UUID').to_s }
    current ||= {
      'uuid' => target.get_attribute(DICT, 'UUID').to_s,
      'wall_number' => info['number'],
      'number' => target.get_attribute(DICT, 'رقم الكمر').to_i,
      'height_cm' => target.get_attribute(DICT, 'ارتفاع الكمر سم').to_f,
      'depth_cm' => target.get_attribute(DICT, 'عمق الكمر سم').to_f,
      'elevation_cm' => target.get_attribute(DICT, 'ارتفاع من الأرض سم').to_f
    }
  end

  number = current ? current['number'].to_i : next_beam_number(room_group, info['number'])
  defaults = {
    'number' => number,
    'height_cm' => current ? current['height_cm'].to_f : 20.0,
    'depth_cm' => current ? current['depth_cm'].to_f : [info['wall_t_cm'], 20.0].max,
    'elevation_cm' => current ? current['elevation_cm'].to_f : [info['wall_h_cm'] - 20.0, 0.0].max
  }

  dlg = UI::HtmlDialog.new(
    dialog_title: is_beam ? "تعديل #{current ? "كمر #{number}" : 'الكمر'}" : "إضافة كمر | #{info['name']}",
    preferences_key: "#{PREF_KEY}_BEAM",
    scrollable: false,
    resizable: false,
    width: 380,
    height: 440,
    style: UI::HtmlDialog::STYLE_DIALOG
  )

  yes = JSON.generate(ts('نعم'))
  html = <<-HTML
<!DOCTYPE html>
<html lang="#{ui_locale}" dir="#{ui_direction}">
<head>
<meta charset="UTF-8">
<style>
*{box-sizing:border-box}
body{margin:0;background:#07131d;color:#eaf4f8;font-family:Arial,Tahoma,sans-serif;direction:#{ui_direction};overflow:hidden}
.app{padding:14px}
.head{background:#0c2230;border:1px solid #1c3342;border-radius:12px;padding:12px;margin-bottom:12px}
.title{font-size:19px;font-weight:900;color:#fff}
.info{font-size:12px;color:#9fb6c5;line-height:1.7;margin-top:5px}
.group{background:#0b1b27;border:1px solid #1c3342;border-radius:10px;padding:10px}
.row{display:grid;grid-template-columns:145px 1fr;gap:8px;align-items:center;margin-bottom:9px}
label{font-size:13px;font-weight:900;color:#d8e8ef}
input{width:100%;height:34px;border:0;border-radius:7px;background:#111f2a;color:#fff;outline:1px solid #243d4f;text-align:center;font-size:13px}
input:focus{outline:2px solid #39a245}
.hint{font-size:11px;color:#8eabbc;line-height:1.5;margin-top:4px}
.footer{display:flex;gap:8px;margin-top:12px}
button{height:42px;border:0;border-radius:9px;font-size:14px;font-weight:900;cursor:pointer}
.save{flex:2;background:#4de37a;color:#061923}
.close{flex:1;background:#0b1b27;color:#fff;border:1px solid #243d4f}
.delete{background:#7d2631;color:#fff;padding:0 14px;display:#{is_beam ? 'block' : 'none'}}
</style>
</head>
<body>
<div class="app">
  <div class="head">
    <div class="title">#{is_beam ? "⚙️ تعديل كمر #{number}" : '➕ إضافة كمر'}</div>
    <div class="info">الحائط: #{info['name']}<br>طول الحائط: #{info['length_cm'].round(2)} سم<br>ارتفاع الحائط: #{info['wall_h_cm'].round(2)} سم</div>
  </div>
  <div class="group">
    <div class="row"><label>ارتفاع الكمر سم</label><input id="height" type="number" min="0.1" step="0.1" value="#{defaults['height_cm']}"></div>
    <div class="row"><label>عمق الكمر سم</label><input id="depth" type="number" min="0.1" step="0.1" value="#{defaults['depth_cm']}"></div>
    <div class="row"><label>ارتفاع من الأرض سم</label><input id="elevation" type="number" min="0" step="0.1" value="#{defaults['elevation_cm']}"></div>
    <div class="hint">الكمر يمتد تلقائياً بطول الحائط بالكامل، ويُعاد بناؤه تلقائياً عند تعديل ارتفاع أو سمك الحائط.</div>
  </div>
  <div class="footer">
    <button class="save" onclick="submitData()">#{is_beam ? 'حفظ التعديل' : 'إضافة الكمر'}</button>
    <button class="delete" onclick="removeBeam()">حذف</button>
    <button class="close" onclick="sketchup.cancel()">إغلاق</button>
  </div>
</div>
<script>
function val(id){return document.getElementById(id).value}
function submitData(){
  const h=parseFloat(val('height')), d=parseFloat(val('depth')), z=parseFloat(val('elevation'));
  if(!(h>0) || !(d>0) || !(z>=0)){alert('راجع المقاسات');return}
  if(z+h>#{info['wall_h_cm'].to_f}+0.001){alert('ارتفاع الكمر + ارتفاعه من الأرض أكبر من ارتفاع الحائط');return}
  sketchup.submit(JSON.stringify({height_cm:h,depth_cm:d,elevation_cm:z}));
}
function removeBeam(){sketchup.removeBeam()}
</script>
</body>
</html>
HTML

  dlg.set_html(html)
  dlg.add_action_callback('cancel') { dlg.close }

  dlg.add_action_callback('submit') do |_, json|
    begin
      data = JSON.parse(json)
      h = data['height_cm'].to_f
      d = data['depth_cm'].to_f
      z = data['elevation_cm'].to_f
      if h <= 0 || d <= 0 || z < 0 || z + h > info['wall_h_cm'] + 0.001
        raise 'قيم الكمر غير صالحة بالنسبة لارتفاع الحائط.'
      end

      model = Sketchup.active_model
      model.start_operation(is_beam ? 'MHD Edit Beam' : 'MHD Add Beam', true)
      begin
        beams = beams_from_room(room_group)
        if is_beam
          idx = beams.index { |b| b['uuid'].to_s == target.get_attribute(DICT, 'UUID').to_s }
          idx ||= beams.index { |b| b['uuid'].to_s == current['uuid'].to_s } if current
          raise 'لم يتم العثور على بيانات الكمر.' unless idx
          beams[idx]['height_cm'] = h
          beams[idx]['depth_cm'] = d
          beams[idx]['elevation_cm'] = z
          beams[idx]['wall_number'] = info['number']
          beams[idx]['wall_name'] = info['name']
          beams[idx]['room_name'] = info['room_name']
          beams[idx]['room_uuid'] = info['room_uuid']
        else
          beams << {
            'uuid' => uuid,
            'wall_number' => info['number'],
            'wall_name' => info['name'],
            'room_uuid' => info['room_uuid'],
            'room_name' => info['room_name'],
            'number' => number,
            'height_cm' => h,
            'depth_cm' => d,
            'elevation_cm' => z
          }
        end
        save_beams(room_group, beams)
        rebuild_all_beams(room_group)
        model.commit_operation
        model.active_view.invalidate
        dlg.close
        UI.messagebox("✅ تم #{is_beam ? 'تعديل' : 'إضافة'} الكمر بنجاح")
      rescue => e
        model.abort_operation rescue nil
        UI.messagebox("❌ #{e.message}")
      end
    rescue => e
      UI.messagebox("❌ #{e.message}")
    end
  end

  dlg.add_action_callback('removeBeam') do
    begin
      model = Sketchup.active_model
      model.start_operation('MHD Delete Beam', true)
      beams = beams_from_room(room_group)
      uid = target.get_attribute(DICT, 'UUID').to_s
      beams.reject! { |b| b['uuid'].to_s == uid }
      beams_for_wall = beams.select { |b| b['wall_number'].to_i == info['number'] }
      beams_for_wall.sort_by! { |b| b['number'].to_i }
      beams_for_wall.each_with_index { |b, i| b['number'] = i + 1 }
      save_beams(room_group, beams)
      rebuild_all_beams(room_group)
      model.commit_operation
      model.active_view.invalidate
      dlg.close
      UI.messagebox('🗑️ تم حذف الكمر')
    rescue => e
      model.abort_operation rescue nil
      UI.messagebox("❌ #{e.message}")
    end
  end

  dlg.show
end

class BeamPickTool
  def activate
    Sketchup.status_text = MHD_RoomBuilder_Context.ts('انقر على حائط لإضافة كمر أو على كمر لتعديله')
  end

  def onLButtonDown(_flags, x, y, view)
    ph = view.pick_helper
    ph.do_pick(x, y)
    ent = ph.best_picked
    unless ent
      UI.messagebox(MHD_RoomBuilder_Context.ts('لم يتم تحديد أي عنصر'))
      return
    end

    room = MHD_RoomBuilder_Context.find_room_group(ent)
    unless room
      UI.messagebox(MHD_RoomBuilder_Context.ts('هذا العنصر ليس جزءاً من غرفة MHD'))
      return
    end

    type = ent.get_attribute(MHD_RoomBuilder_Context::DICT, 'النوع').to_s rescue ''
    if type == 'كمر'
      MHD_RoomBuilder_Context.open_beam_dialog(ent)
    elsif type == 'حائط'
      MHD_RoomBuilder_Context.open_beam_dialog(ent)
    else
      UI.messagebox(MHD_RoomBuilder_Context.ts('اضغط على حائط أو كمر داخل غرفة MHD'))
    end
  end

  def onCancel(_reason, _view)
    Sketchup.active_model.select_tool(nil)
  end
end

def activate_beam_picker
  Sketchup.active_model.select_tool(BeamPickTool.new)
end


# =========================================================
# END SMART ROOM EDIT ENGINE V5
# =========================================================

# -------------------------
# Modern HTML Dialog
# -------------------------
def html_dialog_content(values)
v = values
floor_on = enabled_value?(v['create_floor']) ? 'on' : ''
ceil_on  = enabled_value?(v['create_ceiling']) ? 'on' : ''
light_on = enabled_value?(v['light_enabled']) ? 'on' : ''
floor_txt = enabled_value?(v['create_floor']) ? ts('نعم') : ts('لا')
ceil_txt  = enabled_value?(v['create_ceiling']) ? ts('نعم') : ts('لا')
light_txt = enabled_value?(v['light_enabled']) ? ts('نعم') : ts('لا')
yes_label = JSON.generate(ts('نعم'))
no_label = JSON.generate(ts('لا'))
label_align = ui_direction == 'rtl' ? 'right' : 'left'


html = <<-HTML


<!DOCTYPE html>
<html lang="#{ui_locale}" dir="#{ui_direction}">
<head>
<meta charset="UTF-8">
<title>MHD Room Builder</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,Tahoma,sans-serif;background:#07131d;color:#eaf4f8;overflow:hidden;direction:#{ui_direction};}
::-webkit-scrollbar{width:8px}
::-webkit-scrollbar-track{background:#07131d}
::-webkit-scrollbar-thumb{background:#1d3444;border-radius:20px;border:2px solid #07131d}
.app{height:100vh;display:flex;flex-direction:column;background:#07131d}
.hero{height:74px;padding:10px 12px;display:flex;align-items:center;gap:10px;background:linear-gradient(135deg,#07131d,#0c2230);border-bottom:1px solid #1c3342;}
.logo{width:58px;height:58px;object-fit:contain;background:#081722;border:1px solid #1c3342;border-radius:10px;padding:5px;flex:0 0 auto;}
.head-text{flex:1;overflow:hidden;text-align:center}
.title-main{font-size:20px;font-weight:900;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.2}
.subtitle{margin-top:6px;font-size:11px;line-height:1.5;color:#9fb6c5;height:32px;overflow:hidden}
.wrap{height:calc(100vh - 74px - 58px);overflow:auto;padding:10px;background:#07131d}
.group{background:#0b1b27;border:1px solid #1c3342;border-radius:10px;margin-bottom:10px;overflow:hidden}
.group-title{padding:9px 10px;background:#0f2433;color:#39a245;font-size:16px;font-weight:900;border-bottom:1px solid #1c3342;user-select:none}
.group-body{padding:8px 8px 10px}
.field-row{display:grid;grid-template-columns:105px 1fr;gap:8px;align-items:center;margin-bottom:7px}
.field-row:last-child{margin-bottom:0}
label{font-size:13px;font-weight:900;color:#d8e8ef;text-align:#{label_align};line-height:1.3}
input[type=text],input[type=number],select{width:100%;height:30px;padding:4px 8px;border:none;border-radius:6px;background:#111f2a;color:#fff;font-size:13px;outline:1px solid #243d4f;text-align:center;}
input[type=text]:focus,input[type=number]:focus,select:focus{outline:2px solid #39a245;background:#0d1b25}
select{cursor:pointer}
input[type=color]{width:100%;height:30px;padding:2px;border:1px solid #243d4f;border-radius:6px;background:#111f2a}
.switch-row{display:grid;grid-template-columns:105px 1fr;gap:8px;align-items:center;margin-bottom:7px}
.toggle{height:30px;background:#111f2a;border-radius:6px;outline:1px solid #243d4f;display:flex;align-items:center;justify-content:space-between;padding:0 8px;cursor:pointer;user-select:none;color:#fff;font-size:12px;}
.toggle .dot{width:16px;height:16px;border-radius:50%;background:#355467;border:1px solid #57798a}
.toggle.on .dot{background:#39a245;border-color:#39a245}
.collapsible{cursor:pointer;display:flex;align-items:center;justify-content:space-between}
.collapsible .arrow{font-size:12px;transition:.2s}
.group.closed .group-body{display:none}
.group.closed .arrow{transform:rotate(90deg)}
.conditional{display:none}
.conditional.active{display:block}
.patterns-scroll{display:flex;gap:8px;overflow-x:auto;overflow-y:hidden;padding:2px 2px 9px;scroll-behavior:smooth}
.pattern-card{flex:0 0 112px;background:#0b1b27;border:1px solid #243d4f;border-radius:10px;padding:6px;cursor:pointer;text-align:center;transition:.15s;user-select:none}
.pattern-card.active{border-color:#39a245;box-shadow:0 0 0 1px #39a24566;background:#0f2433}
.pattern-img{height:68px;border-radius:7px;background-size:cover;background-position:center;background-repeat:no-repeat;background-color:#182836;border:1px solid #1c3342}
.pattern-name{font-size:11px;font-weight:900;color:#d8e8ef;line-height:1.3;margin-top:6px;min-height:29px;display:flex;align-items:center;justify-content:center}
.hint{font-size:11px;color:#8eabbc;line-height:1.55;padding:4px 2px 0}
.footer{height:58px;padding:8px 10px;border-top:1px solid #1c3342;background:#07131d;display:flex;gap:8px}
button{height:40px;border-radius:10px;font-size:14px;font-weight:900;cursor:pointer;border:none}
.ok{flex:2;background:#4de37a;color:#061923}
.cancel{flex:1;background:#0b1b27;color:#fff;border:1px solid #243d4f}
</style>
</head>
<body>
<div class="app">
<div class="hero">
<img class="logo" src="#{LOGO_URL}">
<div class="head-text">
<div class="title-main">بناء الحوائط</div>
<div class="subtitle">تم تصميم هذه الأداة بواسطة MHDESIGN<br>Room Builder V4.0</div>
</div>
</div>
<div class="wrap">
<div class="group">
<div class="group-title">▼ بيانات الغرفة</div>
<div class="group-body">
<div class="field-row"><label>اسم الغرفة</label><input id="room_name" type="text" value="#{v['room_name']}"></div>
</div>
</div>
<div class="group">
<div class="group-title">▼ المقاسات</div>
<div class="group-body">
<div class="field-row"><label>ارتفاع الحائط سم</label><input id="wall_h" type="number" step="0.1" value="#{v['wall_h']}"></div>
<div class="field-row"><label>سمك الحائط سم</label><input id="wall_t" type="number" step="0.1" value="#{v['wall_t']}"></div>
<div class="field-row"><label>سمك الأرضية سم</label><input id="floor_t" type="number" step="0.1" value="#{v['floor_t']}"></div>
<div class="field-row"><label>سمك السقف سم</label><input id="ceil_t" type="number" step="0.1" value="#{v['ceil_t']}"></div>
</div>
</div>
<div class="group">
<div class="group-title">▼ عناصر إضافية</div>
<div class="group-body">
<div class="switch-row"><label>إنشاء أرضية</label><div id="create_floor" class="toggle #{floor_on}" onclick="toggle(this)"><span>#{floor_txt}</span><b class="dot"></b></div></div>
<div class="switch-row"><label>إنشاء سقف</label><div id="create_ceiling" class="toggle #{ceil_on}" onclick="toggle(this)"><span>#{ceil_txt}</span><b class="dot"></b></div></div>
</div>
</div>
<div id="ceiling_group" class="group">
<div class="group-title collapsible" onclick="collapseGroup(this)"><span>خيارات السقف</span><span class="arrow">▼</span></div>
<div class="group-body">
<input id="ceiling_pattern" type="hidden" value="#{v['ceiling_pattern']}">
<div class="patterns-scroll">
<div class="pattern-card #{v['ceiling_pattern']=='flat' ? 'active' : ''}" data-pattern="flat" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/1.png')"></div><div class="pattern-name">سقف فلات</div></div>
<div class="pattern-card #{v['ceiling_pattern']=='perimeter' ? 'active' : ''}" data-pattern="perimeter" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/2.png')"></div><div class="pattern-name">ساقط محيطي</div></div>
<div class="pattern-card #{v['ceiling_pattern']=='center' ? 'active' : ''}" data-pattern="center" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/3.png')"></div><div class="pattern-name">ساقط من المنتصف</div></div>
<div class="pattern-card #{v['ceiling_pattern']=='center_hidden_led' ? 'active' : ''}" data-pattern="center_hidden_led" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/4.png')"></div><div class="pattern-name">منتصف + ليد مخفي</div></div>
<div class="pattern-card #{v['ceiling_pattern']=='double_hidden_led' ? 'active' : ''}" data-pattern="double_hidden_led" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/5.png')"></div><div class="pattern-name">بيت نور + منتصف مخفي</div></div>
<div class="pattern-card #{v['ceiling_pattern']=='strips' ? 'active' : ''}" data-pattern="strips" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/7.png')"></div><div class="pattern-name">شرائط طولية / عرضية</div></div>
<div class="pattern-card #{v['ceiling_pattern']=='hidden_cove' ? 'active' : ''}" data-pattern="hidden_cove" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/6.png')"></div><div class="pattern-name">بيت نور مخفي</div></div>
</div>
<div id="drop_reference_row" class="field-row"><label>حساب السقوط</label>
<select id="drop_reference">
<option value="below_wall" #{v['drop_reference']=='below_wall' ? 'selected' : ''}>أسفل ارتفاع الحائط</option>
<option value="wall_is_finish" #{v['drop_reference']=='wall_is_finish' ? 'selected' : ''}>ارتفاع الحائط بعد السقوط</option>
</select>
</div>
<div id="drop_reference_hint" class="hint">اختر هل قيمة ارتفاع الحائط تمثل السقف الأساسي أم الارتفاع الصافي أسفل الجزء الساقط.</div>


    <div id="opts_flat" class="conditional"><div class="hint">سقف كامل بمستوى واحد حسب ارتفاع الحائط وسمك السقف.</div></div>
    <div id="opts_perimeter" class="conditional">
      <div class="field-row"><label>عرض الإطار سم</label><input id="perimeter_width" type="number" step="0.1" value="#{v['perimeter_width']}"></div>
      <div class="field-row"><label>نزول الإطار سم</label><input id="perimeter_drop" type="number" step="0.1" value="#{v['perimeter_drop']}"></div>
    </div>
    <div id="opts_center" class="conditional">
      <div class="field-row"><label>ارتداد المنتصف سم</label><input id="center_inset" type="number" step="0.1" value="#{v['center_inset']}"></div>
      <div class="field-row"><label>نزول المنتصف سم</label><input id="center_drop" type="number" step="0.1" value="#{v['center_drop']}"></div>
    </div>
    <div id="opts_center_hidden_led" class="conditional">
      <div class="field-row"><label>ارتداد الجزيرة سم</label><input id="center_led_inset" type="number" step="0.1" value="#{v['center_led_inset']}"></div>
      <div class="field-row"><label>مقدار السقوط سم</label><input id="center_led_drop" type="number" step="0.1" value="#{v['center_led_drop']}"></div>
      <div class="field-row"><label>سمك لوح الجزيرة سم</label><input id="center_led_thickness" type="number" step="0.1" value="#{v['center_led_thickness']}"></div>
    </div>
    <div id="opts_double_hidden_led" class="conditional">
      <div class="field-row"><label>عرض بيت النور سم</label><input id="combo_cove_width" type="number" step="0.1" value="#{v['combo_cove_width']}"></div>
      <div class="field-row"><label>نزول بيت النور سم</label><input id="combo_cove_drop" type="number" step="0.1" value="#{v['combo_cove_drop']}"></div>
      <div class="field-row"><label>بروز اليد للداخل سم</label><input id="combo_cove_lip_width" type="number" step="0.1" value="#{v['combo_cove_lip_width']}"></div>
      <div class="field-row"><label>سمك اليد سم</label><input id="combo_cove_lip_height" type="number" step="0.1" value="#{v['combo_cove_lip_height']}"></div>
      <div class="field-row"><label>ارتداد الجزيرة سم</label><input id="combo_center_inset" type="number" step="0.1" value="#{v['combo_center_inset']}"></div>
      <div class="field-row"><label>نزول الجزيرة سم</label><input id="combo_center_drop" type="number" step="0.1" value="#{v['combo_center_drop']}"></div>
      <div class="field-row"><label>سمك لوح الجزيرة سم</label><input id="combo_center_thickness" type="number" step="0.1" value="#{v['combo_center_thickness']}"></div>
    </div>
    <div id="opts_strips" class="conditional">
      <div class="field-row"><label>اتجاه الشرائط</label><select id="strip_direction"><option value="longitudinal" #{longitudinal_value?(v['strip_direction']) ? 'selected' : ''}>طولي</option><option value="transverse" #{longitudinal_value?(v['strip_direction']) ? '' : 'selected'}>عرضي</option></select></div>
      <div class="field-row"><label>عدد الشرائط</label><input id="strip_count" type="number" min="1" max="20" step="1" value="#{v['strip_count']}"></div>
      <div class="field-row"><label>عرض الشريط سم</label><input id="strip_width" type="number" step="0.1" value="#{v['strip_width']}"></div>
      <div class="field-row"><label>المسافة بينهم سم</label><input id="strip_gap" type="number" step="0.1" value="#{v['strip_gap']}"></div>
      <div class="field-row"><label>نزول الشرائط سم</label><input id="strip_drop" type="number" step="0.1" value="#{v['strip_drop']}"></div>
    </div>
    <div id="opts_hidden_cove" class="conditional">
      <div class="field-row"><label>عرض بيت النور سم</label><input id="cove_inset" type="number" step="0.1" value="#{v['cove_inset']}"></div>
      <div class="field-row"><label>مقدار النزول سم</label><input id="cove_drop" type="number" step="0.1" value="#{v['cove_drop']}"></div>
      <div class="field-row"><label>بروز اليد للداخل سم</label><input id="cove_lip_width" type="number" step="0.1" value="#{v['cove_lip_width']}"></div>
      <div class="field-row"><label>سمك اليد سم</label><input id="cove_lip_height" type="number" step="0.1" value="#{v['cove_lip_height']}"></div>
    </div>
  </div>
</div>
<div id="light_group" class="group">
  <div class="group-title collapsible" onclick="collapseGroup(this)"><span>تأثير الإضاءة</span><span class="arrow">▼</span></div>
  <div class="group-body">
    <div class="switch-row"><label>تشغيل الإضاءة</label><div id="light_enabled" class="toggle #{light_on}" onclick="toggle(this);updateLight()"><span>#{light_txt}</span><b class="dot"></b></div></div>
    <div id="light_options">
      <div class="field-row"><label>طريقة التنفيذ</label><select id="light_mode"><option value="groove" #{v['light_mode']=='groove' ? 'selected' : ''}>مجرى فقط</option><option value="effect" #{v['light_mode']=='effect' ? 'selected' : ''}>تأثير فقط</option><option value="both" #{v['light_mode']=='both' ? 'selected' : ''}>مجرى + تأثير</option></select></div>
      <div class="field-row"><label>ارتداد الإضاءة سم</label><input id="light_inset" type="number" step="0.1" value="#{v['light_inset']}"></div>
      <div class="field-row"><label>عرض المجرى سم</label><input id="light_width" type="number" step="0.1" value="#{v['light_width']}"></div>
      <div class="field-row"><label>عمق المجرى سم</label><input id="light_depth" type="number" step="0.1" value="#{v['light_depth']}"></div>
      <div class="field-row"><label>هامش البداية سم</label><input id="light_margin" type="number" step="0.1" value="#{v['light_margin']}"></div>
      <div class="field-row"><label>لون التأثير</label><input id="light_color" type="color" value="#{v['light_color']}"></div>
      <div class="field-row"><label>شدة الإضاءة %</label><input id="glow_intensity" type="number" min="0" max="100" step="1" value="#{v['glow_intensity']}"></div>
      <div class="field-row"><label>حجم الانتشار سم</label><input id="glow_size" type="number" min="0" step="0.5" value="#{v['glow_size']}"></div>
    </div>
  </div>
</div>


</div>
<div class="footer">
<button class="ok" onclick="submitData()">إنشاء</button>
<button class="cancel" onclick="sketchup.cancel()">إلغاء</button>
</div>
</div>
<script>
document.addEventListener('contextmenu', function(e){e.preventDefault();});
document.addEventListener('dragstart', function(e){e.preventDefault();});
function toggle(el){
el.classList.toggle('on');
el.querySelector('span').textContent = el.classList.contains('on') ? #{yes_label} : #{no_label};
}
function collapseGroup(title){ title.parentElement.classList.toggle('closed'); }
function selectCeilingPattern(el){
document.querySelectorAll('.pattern-card').forEach(card => card.classList.remove('active'));
el.classList.add('active');
document.getElementById('ceiling_pattern').value = el.dataset.pattern;
updatePattern();
}
function updatePattern(){
const pattern = val('ceiling_pattern');
document.querySelectorAll('.conditional').forEach(el => el.classList.remove('active'));
const box = document.getElementById('opts_' + pattern);
if(box) box.classList.add('active');
const dropped = pattern !== 'flat';
document.getElementById('drop_reference_row').style.display = dropped ? 'grid' : 'none';
document.getElementById('drop_reference_hint').style.display = dropped ? 'block' : 'none';
}
function updateLight(){
const on = document.getElementById('light_enabled').classList.contains('on');
document.getElementById('light_options').style.display = on ? 'block' : 'none';
}
function setCeilingVisibility(){
const on = document.getElementById('create_ceiling').classList.contains('on');
document.getElementById('ceiling_group').style.display = on ? 'block' : 'none';
document.getElementById('light_group').style.display = on ? 'block' : 'none';
}
function val(id){ return document.getElementById(id).value; }
function yesNo(id){ return document.getElementById(id).classList.contains('on') ? 'yes' : 'no'; }
function submitData(){
const data = {
room_name: val('room_name'),
wall_h: val('wall_h'), wall_t: val('wall_t'),
floor_t: val('floor_t'), ceil_t: val('ceil_t'),
create_floor: yesNo('create_floor'), create_ceiling: yesNo('create_ceiling'),
ceiling_pattern: val('ceiling_pattern'),
perimeter_width: val('perimeter_width'), perimeter_drop: val('perimeter_drop'),
center_inset: val('center_inset'), center_drop: val('center_drop'),
center_led_inset: val('center_led_inset'), center_led_drop: val('center_led_drop'),
center_led_thickness: val('center_led_thickness'),
combo_cove_width: val('combo_cove_width'), combo_cove_drop: val('combo_cove_drop'),
combo_cove_lip_width: val('combo_cove_lip_width'), combo_cove_lip_height: val('combo_cove_lip_height'),
combo_center_inset: val('combo_center_inset'), combo_center_drop: val('combo_center_drop'),
combo_center_thickness: val('combo_center_thickness'),
strip_direction: val('strip_direction'), strip_count: val('strip_count'),
strip_width: val('strip_width'), strip_gap: val('strip_gap'), strip_drop: val('strip_drop'),
cove_inset: val('cove_inset'), cove_drop: val('cove_drop'),
cove_lip_width: val('cove_lip_width'), cove_lip_height: val('cove_lip_height'),
drop_reference: val('drop_reference'),
light_enabled: yesNo('light_enabled'), light_mode: val('light_mode'),
light_inset: val('light_inset'), light_width: val('light_width'),
light_depth: val('light_depth'), light_margin: val('light_margin'),
light_color: val('light_color'), glow_intensity: val('glow_intensity'),
glow_size: val('glow_size')
};
sketchup.submit(JSON.stringify(data));
}
document.getElementById('create_ceiling').addEventListener('click', function(){setTimeout(setCeilingVisibility,0)});
updatePattern(); updateLight(); setCeilingVisibility();
</script>
</body>
</html>
HTML
ts(html)
end

def dialog_input
unless selected_face
UI.messagebox(ts('حدد Face الأرضية الأول'))
return
end
dlg = UI::HtmlDialog.new(
dialog_title: ts('بناء الحوائط'),
preferences_key: PREF_KEY,
scrollable: false,
resizable: true,
width: 330,
height: 720,
style: UI::HtmlDialog::STYLE_DIALOG
)
dlg.set_html(html_dialog_content(saved_values))
dlg.add_action_callback('cancel') { dlg.close }
dlg.add_action_callback('submit') do |_, json|
data = JSON.parse(json)
save_values(data)
dlg.close
build_from_data(data)
rescue => e
UI.messagebox("Error:\n#{e.message}")
end
dlg.show
nil
end

# -------------------------
# Build Ceiling (unchanged)
# -------------------------
def build_ceiling(model, room_ents, room_name, room_uuid, outer_pts, room_pts,
wall_h, ceil_t, ceil_t_cm, data)
# ... [الكود الأصلي كما هو] ...
pattern = data['ceiling_pattern'].to_s
pattern = 'flat' unless %w[flat perimeter center center_hidden_led double_hidden_led strips hidden_cove].include?(pattern)
common = {
'Room_UUID' => room_uuid, 'النوع' => 'سقف', 'اسم الغرفة' => room_name,
'نمط السقف' => pattern, 'السمك سم' => ceil_t_cm
}
ceiling_def = model.definitions.add("#{room_name}_السقف_الكامل_#{Time.now.to_i}_#{rand(99999)}")
ceiling_inst = room_ents.add_instance(ceiling_def, Geom::Transformation.new)
ceiling_inst.name = ts('السقف')
ceiling_inst.layer = tag(model, "#{room_name} | #{ts('السقف')}")
set_attrs(ceiling_inst, common.merge('UUID' => uuid, 'الجزء' => 'السقف الكامل'))
room_ents = ceiling_def.entities


selected_drop = case pattern
                when 'perimeter' then [data['perimeter_drop'].to_f.cm, 0.5.cm].max
                when 'center' then [data['center_drop'].to_f.cm, 0.5.cm].max
                when 'center_hidden_led' then [data['center_led_drop'].to_f.cm, 1.cm].max
                when 'double_hidden_led'
                  [[data['combo_cove_drop'].to_f.cm, 1.cm].max,
                   [data['combo_center_drop'].to_f.cm, 1.cm].max].max
                when 'strips' then [data['strip_drop'].to_f.cm, 0.5.cm].max
                when 'hidden_cove' then [data['cove_drop'].to_f.cm, 0.5.cm].max
                else 0.0
                end
drop_reference = data['drop_reference'].to_s
drop_reference = 'below_wall' unless %w[below_wall wall_is_finish].include?(drop_reference)
base_z = (pattern != 'flat' && drop_reference == 'wall_is_finish') ? wall_h + selected_drop : wall_h
common['طريقة حساب السقوط'] = drop_reference

add_poly_component(model, room_ents, ts('السقف الأساسي'), nil,
                   outer_pts, base_z, ceil_t, common.merge('الجزء' => 'أساسي'))

light_reference = { kind: :perimeter, source_pts: room_pts,
                    distance: data['light_inset'].to_f.cm,
                    underside_z: base_z, strips: [] }

case pattern
when 'perimeter'
  width = [data['perimeter_width'].to_f.cm, 1.cm].max
  drop = selected_drop
  inner = offset_polygon(room_pts, width)
  if polygon_usable?(inner)
    add_ring_component(model, room_ents, ts('السقف الساقط المحيطي'),
                       nil, outer_pts, inner,
                       base_z - drop, drop, common.merge(
                         'الجزء' => 'إطار محيطي', 'عرض الإطار سم' => data['perimeter_width'].to_f,
                         'مقدار النزول سم' => data['perimeter_drop'].to_f))
    light_reference = { kind: :perimeter, source_pts: room_pts,
                        distance: [width - data['light_inset'].to_f.cm, 0.2.cm].max,
                        underside_z: base_z - drop, strips: [] }
  end
when 'center'
  inset = [data['center_inset'].to_f.cm, 1.cm].max
  drop = selected_drop
  center = offset_polygon(room_pts, inset)
  if polygon_usable?(center)
    add_poly_component(model, room_ents, ts('السقف الساقط الأوسط'),
                       nil, center,
                       base_z - drop, drop, common.merge(
                         'الجزء' => 'منتصف ساقط', 'الارتداد سم' => data['center_inset'].to_f,
                         'مقدار النزول سم' => data['center_drop'].to_f))
    light_reference = { kind: :perimeter, source_pts: room_pts,
                        distance: inset + data['light_inset'].to_f.cm,
                        underside_z: base_z - drop, strips: [] }
  end
when 'center_hidden_led'
  inset = [data['center_led_inset'].to_f.cm, 5.cm].max
  drop = selected_drop
  panel_thickness = [data['center_led_thickness'].to_f.cm, 0.5.cm].max
  panel_thickness = [panel_thickness, drop * 0.6].min
  island = offset_polygon(room_pts, inset)
  if polygon_usable?(island)
    panel_bottom_z = base_z - drop
    panel_top_z = panel_bottom_z + panel_thickness
    led_inset = [data['light_inset'].to_f.cm, 0.5.cm].max
    led_width = [data['light_width'].to_f.cm, 0.3.cm].max
    led_outer = offset_polygon(island, led_inset)
    led_inner = offset_polygon(island, led_inset + led_width)
    support = offset_polygon(island, led_inset + led_width + 2.cm)
    add_poly_component(model, room_ents, ts('جزيرة السقف الساقطة'), nil,
                       island, panel_bottom_z, panel_thickness,
                       common.merge('الجزء' => 'جزيرة ساقطة بليد مخفي',
                                    'الارتداد سم' => data['center_led_inset'].to_f,
                                    'مقدار النزول سم' => data['center_led_drop'].to_f,
                                    'سمك لوح الجزيرة سم' => data['center_led_thickness'].to_f))
    if polygon_usable?(support) && base_z > panel_top_z
      add_poly_component(model, room_ents, ts('قلب تثبيت الجزيرة'), nil,
                         support, panel_top_z, base_z - panel_top_z,
                         common.merge('الجزء' => 'قلب تثبيت مخفي'))
    end
    if polygon_usable?(led_outer) && polygon_usable?(led_inner)
      light_reference = { kind: :direct, outer: led_outer, inner: led_inner,
                          underside_z: panel_top_z,
                          glow_surface: :horizontal, glow_path: led_outer,
                          glow_spread: :outward, strips: [] }
    end
  end
when 'double_hidden_led'
  cove_width = [data['combo_cove_width'].to_f.cm, 5.cm].max
  cove_drop = [data['combo_cove_drop'].to_f.cm, 1.cm].max
  cove_hand_width = [data['combo_cove_lip_width'].to_f.cm, 1.cm].max
  cove_hand_thickness = [data['combo_cove_lip_height'].to_f.cm, 0.5.cm].max
  cove_hand_thickness = [cove_hand_thickness, cove_drop * 0.35].min
  box_inner = offset_polygon(room_pts, cove_width)
  hand_inner = offset_polygon(box_inner, cove_hand_width) if polygon_usable?(box_inner)
  references = []
  if polygon_usable?(box_inner) && polygon_usable?(hand_inner)
    box_bottom_z = base_z - cove_drop
    add_ring_component(model, room_ents, ts('صندوق بيت النور المدمج'), nil,
                       outer_pts, box_inner, box_bottom_z, cove_drop,
                       common.merge('الجزء' => 'بيت نور محيطي مدمج',
                                    'عرض بيت النور سم' => data['combo_cove_width'].to_f,
                                    'مقدار النزول سم' => data['combo_cove_drop'].to_f))
    add_ring_component(model, room_ents, ts('اليد المخفية المحيطية'), nil,
                       box_inner, hand_inner, box_bottom_z, cove_hand_thickness,
                       common.merge('الجزء' => 'يد إضاءة محيطية مخفية',
                                    'بروز اليد سم' => data['combo_cove_lip_width'].to_f,
                                    'سمك اليد سم' => data['combo_cove_lip_height'].to_f))
    led_width = [data['light_width'].to_f.cm, 0.3.cm].max
    cove_led_inner = offset_polygon(box_inner, led_width)
    if polygon_usable?(cove_led_inner)
      references << { kind: :direct, outer: box_inner, inner: cove_led_inner,
                      underside_z: box_bottom_z + cove_hand_thickness,
                      glow_surface: :horizontal, glow_path: box_inner,
                      glow_spread: :inward, strips: [] }
    end
  end
  island_inset = [data['combo_center_inset'].to_f.cm, cove_width + cove_hand_width + 5.cm].max
  island_drop = [data['combo_center_drop'].to_f.cm, 1.cm].max
  panel_thickness = [data['combo_center_thickness'].to_f.cm, 0.5.cm].max
  panel_thickness = [panel_thickness, island_drop * 0.6].min
  island = offset_polygon(room_pts, island_inset)
  if polygon_usable?(island)
    panel_bottom_z = base_z - island_drop
    panel_top_z = panel_bottom_z + panel_thickness
    led_inset = [data['light_inset'].to_f.cm, 0.5.cm].max
    led_width = [data['light_width'].to_f.cm, 0.3.cm].max
    island_led_outer = offset_polygon(island, led_inset)
    island_led_inner = offset_polygon(island, led_inset + led_width)
    support = offset_polygon(island, led_inset + led_width + 2.cm)
    add_poly_component(model, room_ents, ts('الجزيرة الساقطة المدمجة'), nil,
                       island, panel_bottom_z, panel_thickness,
                       common.merge('الجزء' => 'جزيرة وسط بليد مخفي',
                                    'الارتداد سم' => data['combo_center_inset'].to_f,
                                    'مقدار النزول سم' => data['combo_center_drop'].to_f,
                                    'سمك اللوح سم' => data['combo_center_thickness'].to_f))
    if polygon_usable?(support) && base_z > panel_top_z
      add_poly_component(model, room_ents, ts('قلب تثبيت الجزيرة المدمجة'), nil,
                         support, panel_top_z, base_z - panel_top_z,
                         common.merge('الجزء' => 'قلب تثبيت مخفي'))
    end
    if polygon_usable?(island_led_outer) && polygon_usable?(island_led_inner)
      references << { kind: :direct, outer: island_led_outer, inner: island_led_inner,
                      underside_z: panel_top_z,
                      glow_surface: :horizontal, glow_path: island_led_outer,
                      glow_spread: :outward, strips: [] }
    end
  end
  light_reference = references unless references.empty?
when 'strips'
  strips = ceiling_strip_polygons(room_pts, data)
  drop = selected_drop
  strips.each_with_index do |strip_pts, index|
    add_poly_component(model, room_ents, format(ts('شريط السقف %02d'), index + 1),
                       nil,
                       strip_pts, base_z - drop, drop,
                       common.merge('الجزء' => 'شريط', 'رقم الشريط' => index + 1,
                                    'مقدار النزول سم' => data['strip_drop'].to_f))
  end
  light_reference = { kind: :strips, underside_z: base_z - drop, strips: strips }
when 'hidden_cove'
  cove_width = [data['cove_inset'].to_f.cm, 5.cm].max
  drop = selected_drop
  hand_projection = [data['cove_lip_width'].to_f.cm, 1.cm].max
  hand_thickness = [data['cove_lip_height'].to_f.cm, 0.5.cm].max
  box_inner = offset_polygon(room_pts, cove_width)
  hand_inner = offset_polygon(box_inner, hand_projection) if polygon_usable?(box_inner)
  if polygon_usable?(box_inner) && polygon_usable?(hand_inner)
    box_bottom_z = base_z - drop
    add_ring_component(model, room_ents, ts('صندوق بيت النور المحيطي'), nil,
                       outer_pts, box_inner, box_bottom_z, drop,
                       common.merge('الجزء' => 'صندوق بيت نور محيطي',
                                    'عرض بيت النور سم' => data['cove_inset'].to_f,
                                    'مقدار النزول سم' => data['cove_drop'].to_f))
    add_ring_component(model, room_ents, ts('اليد المخفية'), nil,
                       box_inner, hand_inner, box_bottom_z,
                       [hand_thickness, drop * 0.35].min,
                       common.merge('الجزء' => 'يد إضاءة مخفية',
                                    'بروز اليد سم' => data['cove_lip_width'].to_f,
                                    'سمك اليد سم' => data['cove_lip_height'].to_f))
    led_width = [data['light_width'].to_f.cm, 0.3.cm].max
    led_inner = offset_polygon(box_inner, led_width)
    light_reference = { kind: :direct, outer: box_inner, inner: led_inner,
                        underside_z: box_bottom_z + [hand_thickness, drop * 0.35].min,
                        glow_surface: :horizontal, glow_path: box_inner,
                        strips: [] }
  end
end

if enabled_value?(data['light_enabled'])
  references = light_reference.is_a?(Array) ? light_reference : [light_reference]
  references.compact.each do |reference|
    build_ceiling_lighting(model, room_ents, room_name, room_uuid, outer_pts,
                           reference, data)
  end
end


end

def ceiling_strip_polygons(outer_pts, data)
xs = outer_pts.map(&:x); ys = outer_pts.map(&:y)
min_x, max_x = xs.minmax; min_y, max_y = ys.minmax
size_x = max_x - min_x; size_y = max_y - min_y
longitudinal_x = size_x >= size_y
run_x = longitudinal_value?(data['strip_direction']) ? longitudinal_x : !longitudinal_x
count = [[data['strip_count'].to_i, 1].max, 20].min
width = [data['strip_width'].to_f.cm, 1.cm].max
gap = [data['strip_gap'].to_f.cm, 0.cm].max
cross_size = run_x ? size_y : size_x
total = count * width + (count - 1) * gap
if total > cross_size
width = [(cross_size - (count - 1) * gap) / count, 1.cm].max
total = count * width + (count - 1) * gap
end
start = (run_x ? min_y : min_x) + (cross_size - total) / 2.0
Array.new(count) do |i|
a = start + i * (width + gap)
if run_x
rect_points(min_x, a, max_x, a + width)
else
rect_points(a, min_y, a + width, max_y)
end
end
end

def build_ceiling_lighting(model, room_ents, room_name, room_uuid, outer_pts, ref, data)
mode = data['light_mode'].to_s
mode = 'both' unless %w[groove effect both].include?(mode)
width = [data['light_width'].to_f.cm, 0.3.cm].max
depth = [data['light_depth'].to_f.cm, 0.1.cm].max
margin = [data['light_margin'].to_f.cm, 0.cm].max
color = data['light_color'].to_s
glow_intensity = [[data['glow_intensity'].to_f, 0.0].max, 100.0].min
glow_size = [data['glow_size'].to_f.cm, 0.0].max
groove_mat = led_material(model, color, true)
attrs = {
'Room_UUID' => room_uuid, 'اسم الغرفة' => room_name,
'عرض المجرى سم' => data['light_width'].to_f,
'عمق المجرى سم' => data['light_depth'].to_f,
'لون الإضاءة' => color,
'شدة الإضاءة %' => glow_intensity,
'حجم انتشار الإضاءة سم' => data['glow_size'].to_f
}
if ref[:kind] == :strips
ref[:strips].each_with_index do |poly, index|
xs = poly.map(&:x); ys = poly.map(&:y)
min_x,max_x = xs.minmax; min_y,max_y = ys.minmax
run_x = (max_x-min_x) >= (max_y-min_y)
if run_x
cy = (min_y+max_y)/2.0
led_poly = rect_points(min_x+margin, cy-width/2.0, max_x-margin, cy+width/2.0)
else
cx = (min_x+max_x)/2.0
led_poly = rect_points(cx-width/2.0, min_y+margin, cx+width/2.0, max_y-margin)
end
next unless polygon_usable?(led_poly)
add_light_parts(model, room_ents, room_name, index + 1, led_poly, nil,
ref[:underside_z], depth, mode, attrs, groove_mat,
color, glow_intensity, glow_size,
ref[:glow_direction] || :down,
ref[:glow_surface] || :vertical, ref[:glow_path],
ref[:glow_spread] || :inward)
end
elsif ref[:kind] == :direct
ring_outer = ref[:outer]
ring_inner = ref[:inner]
return unless polygon_usable?(ring_outer) && polygon_usable?(ring_inner)
add_light_parts(model, room_ents, room_name, 1, ring_outer, ring_inner,
ref[:underside_z], depth, mode, attrs, groove_mat,
color, glow_intensity, glow_size,
ref[:glow_direction] || :down,
ref[:glow_surface] || :vertical, ref[:glow_path],
ref[:glow_spread] || :inward)
else
d1 = [ref[:distance].to_f, 0.2.cm].max
d2 = d1 + width
source_pts = ref[:source_pts] || outer_pts
ring_outer = offset_polygon(source_pts, d1)
ring_inner = offset_polygon(source_pts, d2)
return unless polygon_usable?(ring_outer) && polygon_usable?(ring_inner)
add_light_parts(model, room_ents, room_name, 1, ring_outer, ring_inner,
ref[:underside_z], depth, mode, attrs, groove_mat,
color, glow_intensity, glow_size,
ref[:glow_direction] || :down,
ref[:glow_surface] || :vertical, ref[:glow_path],
ref[:glow_spread] || :inward)
end
end

def add_light_parts(model, room_ents, room_name, number, outer, inner, underside_z,
depth, mode, attrs, groove_mat,
color, glow_intensity, glow_size, glow_direction = :down,
glow_surface = :vertical, custom_glow_path = nil,
glow_spread = :inward)
if mode == 'groove' || mode == 'both'
name = number > 1 ? format(ts('مجرى إضاءة %02d'), number) : ts('مجرى الإضاءة')
if inner
add_ring_component(model, room_ents, name, nil,
outer, inner, underside_z - 0.2.mm, depth,
attrs.merge('النوع' => 'مجرى إضاءة'), groove_mat)
else
add_poly_component(model, room_ents, name, nil,
outer, underside_z - 0.2.mm, depth,
attrs.merge('النوع' => 'مجرى إضاءة'), groove_mat)
end
end
return unless mode == 'effect' || mode == 'both'
glow_path = custom_glow_path || inner || outer
if glow_surface == :horizontal
add_horizontal_gradient_glow(model, room_ents, room_name, glow_path,
underside_z, glow_size, color, glow_intensity, attrs,
glow_spread)
else
add_vertical_gradient_glow(model, room_ents, room_name, glow_path,
underside_z, glow_size, color, glow_intensity, attrs,
glow_direction)
end
end

def build_from_data(data)
model = Sketchup.active_model
face = selected_face
unless face
UI.messagebox(ts('حدد Face الأرضية الأول'))
return
end
room_name = data['room_name'].to_s.strip
room_name = ts('الغرفة') if room_name.empty?
wall_h_cm  = data['wall_h'].to_f
wall_t_cm  = data['wall_t'].to_f
floor_t_cm = data['floor_t'].to_f
ceil_t_cm  = data['ceil_t'].to_f
create_floor = enabled_value?(data['create_floor'])
create_ceiling = enabled_value?(data['create_ceiling'])
ceiling_pattern = data['ceiling_pattern'].to_s
if wall_h_cm <= 0 || wall_t_cm <= 0
UI.messagebox(ts('ارتفاع وسمك الحائط لازم يكونوا أكبر من صفر'))
return
end
wall_h  = wall_h_cm.cm
wall_t  = wall_t_cm.cm
floor_t = floor_t_cm.cm
ceil_t  = ceil_t_cm.cm
model.start_operation('MHD Room Builder', true)
pts = face.outer_loop.vertices.map { |v| v.position }
pts.reverse! if signed_area_xy(pts) < 0
count = pts.length
outward_pts = []
count.times do |i|
p_prev = pts[(i - 1) % count]
p_curr = pts[i]
p_next = pts[(i + 1) % count]
d_prev = p_prev.vector_to(p_curr)
d_curr = p_curr.vector_to(p_next)
d_prev.normalize!
d_curr.normalize!
out_prev = d_prev.cross(Z_AXIS)
out_curr = d_curr.cross(Z_AXIS)
out_prev.normalize!
out_curr.normalize!
out_prev.length = wall_t
out_curr.length = wall_t
a1 = p_prev.offset(out_prev)
b1 = p_curr.offset(out_curr)
inter = line_intersection_2d(a1, d_prev, b1, d_curr)
inter ||= p_curr.offset(out_curr)
outward_pts << inter
end
stamp = Time.now.to_i
room_uuid = uuid
room_group = begin
    model.entities.add_group
  rescue
    model.active_entities.add_group
  end
room_group.name = room_name
room_group.layer = tag(model, room_name)


# ✅ جديد: حفظ محيط الغرفة والبيانات الكاملة للتعديل الذكي
save_room_pts(room_group, pts)
save_build_data(room_group, data)

set_attrs(room_group, {
  'UUID' => room_uuid,
  'النوع' => 'غرفة',
  'اسم الغرفة' => room_name,
  'ارتفاع الحائط سم' => wall_h_cm,
  'سمك الحائط سم' => wall_t_cm,
  'سمك الأرضية سم' => floor_t_cm,
  'سمك السقف سم' => ceil_t_cm,
  'إنشاء أرضية' => create_floor ? 'نعم' : 'لا',
  'إنشاء سقف' => create_ceiling ? 'نعم' : 'لا',
  'نمط السقف' => ceiling_pattern,
  'طريقة حساب السقوط' => data['drop_reference'].to_s,
  'تاريخ الإنشاء' => Time.now.strftime('%Y-%m-%d %H:%M')
})
room_group.set_attribute(DICT, 'shatras_json', [].to_json)
room_group.set_attribute(DICT, 'beams_json', [].to_json)
room_ents = room_group.entities
if create_floor && floor_t > 0
  floor_def = model.definitions.add("#{room_name}_أرضية_#{stamp}")
  floor_face = floor_def.entities.add_face(outward_pts)
  if floor_face
    floor_face.reverse! if floor_face.normal.z < 0
    floor_face.pushpull(-floor_t)
    floor_inst = room_ents.add_instance(floor_def, Geom::Transformation.new)
    floor_inst.name = ts('الأرضية')
    floor_inst.layer = tag(model, "#{room_name} | #{ts('الأرضية')}")
    set_attrs(floor_inst, {
      'UUID' => uuid,
      'Room_UUID' => room_uuid,
      'النوع' => 'أرضية',
      'اسم الغرفة' => room_name,
      'السمك سم' => floor_t_cm
    })
  end
end
if create_ceiling && ceil_t > 0
  build_ceiling(model, room_ents, room_name, room_uuid, outward_pts,
                pts, wall_h, ceil_t, ceil_t_cm, data)
end
count.times do |i|
  j = (i + 1) % count
  wall_number = format('%02d', i + 1)
  wall_name = "#{ts('حائط')} #{wall_number}"
  p1 = pts[i]
  p2 = pts[j]
  p3 = outward_pts[j]
  p4 = outward_pts[i]
  wall_def = model.definitions.add("#{room_name}_#{wall_name}_#{stamp}")
  add_prism(wall_def.entities, p1, p2, p3, p4, 0, wall_h)
  wall_inst = room_ents.add_instance(wall_def, Geom::Transformation.new)
  wall_inst.name = wall_name
  wall_inst.layer = tag(model, "#{room_name} | #{wall_name}")
  set_attrs(wall_inst, {
    'UUID' => uuid,
    'Room_UUID' => room_uuid,
    'النوع' => 'حائط',
    'اسم الغرفة' => room_name,
    'رقم الحائط' => i + 1,
    'الاسم' => wall_name,
    'الارتفاع سم' => wall_h_cm,
    'السمك سم' => wall_t_cm,
    'طول الحائط سم' => p1.distance(p2).to_cm.round(2),
    'P1' => pt_to_s(p1),
    'P2' => pt_to_s(p2),
    'P3' => pt_to_s(p3),
    'P4' => pt_to_s(p4)
  })
end
remove_legacy_source_floor_geometry(pts)
model.commit_operation
UI.messagebox(ts('تم بناء الغرفة بنجاح'))


rescue => e
model.abort_operation rescue nil
UI.messagebox("Error:\n#{e.message}")
end

def build
dialog_input
end

unless file_loaded?(__FILE__)
UI.add_context_menu_handler do |menu|
model = Sketchup.active_model
selection = model.selection.to_a


  # بناء غرفة جديدة من Face محدد
  if selected_face
    menu.add_separator
    menu.add_item(ts(MENU_BUILD)) { build }
  end

  menu.add_separator
  menu.add_item(ts('🧱 بدء رسم الحوائط مباشرة')) { activate_wall_draw_tool_direct }

  # تعديل غرفة موجودة
  room_group = nil
  selection.each do |entity|
    room_group = find_room_group(entity)
    break if room_group
  end

  if room_group
    menu.add_separator
    menu.add_item(ts('⚙️ تعديل الغرفة')) { open_edit_room_dialog(room_group) }

    # كمر: يظهر عند تحديد حائط أو كمر
    wall_entity = selection.find do |entity|
      entity.respond_to?(:get_attribute) &&
        entity.get_attribute(DICT, 'النوع').to_s == 'حائط'
    end
    beam_entity = selection.find do |entity|
      entity.respond_to?(:get_attribute) &&
        entity.get_attribute(DICT, 'النوع').to_s == 'كمر'
    end

    if wall_entity
      menu.add_item(ts('✏️ تعديل الحائط ديناميكياً')) { open_wall_dialog(wall_entity) }
      menu.add_item(ts('➕ إضافة كمر للحائط')) { open_beam_dialog(wall_entity) }
      menu.add_item(ts('📐 شطرة الحائط')) { activate_shatra_picker }
    elsif beam_entity
      menu.add_item(ts('⚙️ تعديل الكمر')) { open_beam_dialog(beam_entity) }
    end
  end
end

# قائمة Plugins للأداة التفاعلية
UI.menu('Plugins').add_item(ts('MHD - بدء رسم الحوائط مباشرة')) do
  activate_wall_draw_tool_direct
end

UI.menu('Plugins').add_item(ts('MHD - تعديل غرفة (نقر تفاعلي)')) do
  activate_room_edit_picker
end

UI.menu('Plugins').add_item(ts('MHD - تعديل حائط ديناميكي (نقر تفاعلي)')) do
  activate_wall_edit_picker
end

UI.menu('Plugins').add_separator
UI.menu('Plugins').add_item(ts('MHD - إضافة/تعديل كمر (نقر تفاعلي)')) do
  activate_beam_picker
end

UI.menu('Plugins').add_item(ts('MHD - شطرة الحائط (ضبط الزوايا)')) do
  activate_shatra_picker
end

file_loaded(__FILE__)


end
end
