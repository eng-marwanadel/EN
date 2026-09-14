# encoding: UTF-8
# MHD Opening Engine v3.0 - Smart Wall Content Analyzer
# ================================================================
# ⚡ الميزات الجديدة:
#  - تحليل ذكي لكل محتوى الحائط (وحدات سفلية + علوية + أجهزة + فتحات)
#  - حساب تلقائي للفاضل على الحيط بدقة السنتيمتر
#  - كشف فوري للتجاوز مع قيمة الزيادة بالضبط
#  - تمييز تلقائي: وحدات / بوتجاز / فرن / حوض / شباك / باب
#  - معاينة حيّة تتحدث تلقائيًا مع أي تغيير
# ================================================================

require 'sketchup.rb'
require 'json'
begin
  require 'securerandom'
rescue LoadError
end

# ==================== MHDESIGN UI LANGUAGE BRIDGE ====================
module MHDESIGN_UI_LANG
  extend self

  def current
    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.current
    else
      Sketchup.read_default('MHDESIGN', 'language_code', 'ar_EG').to_s
    end
  rescue
    'ar_EG'
  end

  def direction
    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.direction
    else
      current.start_with?('ar') ? 'rtl' : 'ltr'
    end
  rescue
    'rtl'
  end

  def key(key_name, fallback = nil)
    fallback_text = fallback.nil? ? key_name.to_s : fallback.to_s
    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.t(key_name.to_s, fallback_text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? key_name.to_s : fallback.to_s
  end

  def source_map
    return {} unless defined?(MHDESIGN::Language)
    payload = MHDESIGN::Language.ui_payload
    payload[:source_map] || payload['source_map'] || {}
  rescue
    {}
  end

  def texts
    return {} unless defined?(MHDESIGN::Language)
    payload = MHDESIGN::Language.ui_payload
    payload[:texts] || payload['texts'] || {}
  rescue
    {}
  end

  def t(value, fallback = nil)
    text = value.to_s
    fallback_text = fallback.nil? ? text : fallback.to_s
    return fallback_text if text.empty?
    return key(text, fallback_text) if text.start_with?('OPEN_')
    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.translate_source(text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? value.to_s : fallback.to_s
  end

  def messagebox(message, *args)
    UI.messagebox(t(message), *args)
  end

  def payload_json
    {
      locale: current,
      direction: direction,
      texts: texts,
      source_map: source_map
    }.to_json
  rescue
    '{"locale":"ar_EG","direction":"rtl","texts":{},"source_map":{}}'
  end
end
# ====================================================================

module MHD_Opening_Engine_V30_SMART
  extend self

  MENU_DOOR   = MHDESIGN_UI_LANG.key("OPEN_MENU_DOOR",   "إضافة باب")
  MENU_WINDOW = MHDESIGN_UI_LANG.key("OPEN_MENU_WINDOW", "إضافة شباك")
  MENU_CLEAR  = MHDESIGN_UI_LANG.key("OPEN_MENU_CLEAR",  "حذف فتحات الحائط")
  MENU_REPORT = MHDESIGN_UI_LANG.key("OPEN_MENU_REPORT", "تقرير قياس الحيط")

  DICT = "MHD_ROOM_BUILDER"
  OPENINGS_KEY = "OPENINGS_JSON"
  EPS_CM = 0.05
  LOGO_URL = 'https://mhdesign-eg.com/SKETCHUP/components/logo3.png'
  PREF_KEY = 'MHD_OPENING_ENGINE_V30_UI'

  # ================================================================
  # ============== SMART WALL CONTENT ANALYZER =====================
  # ================================================================
  module SmartWallContent
    extend self

    BASE_KEYWORDS = [
      "قاعده", "قاعدة", "شاسيه سفلي", "شاسي سفلي", "شاسه سفلي",
      "وحده سفلي", "وحدة سفلي", "وحده سفليه", "وحدة سفلية",
      "ادراج", "أدراج", "درج",
      "بوتجاز", "فرن", "حوض", "شفاط", "ثلاجه", "ثلاجة",
      "ميكروويف", "غساله", "غسالة", "ماكينه قهوه", "ماكينة قهوة"
    ].freeze

    UPPER_KEYWORDS = [
      "علوي", "علوى", "علويه", "علوية",
      "وحده علوي", "وحدة علوي", "وحده علويه", "وحدة علوية",
      "شاسيه علوي", "شاسي علوي", "شاسه علوي",
      "دولاب علوي", "دواليب علوي", "دولاب علوى",
      "خزانه علوي", "خزانة علوي"
    ].freeze

    APPLIANCE_KEYWORDS = [
      "بوتجاز", "فرن", "ثلاجه", "ثلاجة", "حوض",
      "شفاط", "ميكروويف", "غساله", "غسالة",
      "ماكينه قهوه", "ماكينة قهوة", "ميكرويف"
    ].freeze

    DOOR_KEYWORDS   = ["باب", "ضلفه", "ضلفة"].freeze
    WINDOW_KEYWORDS = ["شباك", "نافذه", "نافذة"].freeze

    def norm(text)
      text.to_s
          .tr("أإآٱ", "اااا")
          .tr("ةى", "هي")
          .gsub(/[ًٌٍَُِّْـ]/, "")
          .downcase
          .gsub(/\s+/, "")
    end

    def entity_display_name(entity)
      parts = []
      parts << entity.name.to_s if entity.respond_to?(:name) && !entity.name.to_s.strip.empty?
      if entity.respond_to?(:definition) && entity.definition
        dname = entity.definition.name.to_s
        parts << dname unless dname.strip.empty?
      end
      begin
        dc_name = entity.get_attribute("dynamic_attributes", "name").to_s
        parts << dc_name unless dc_name.strip.empty?
      rescue
      end
      parts.uniq.join(" | ")
    end

    def appliance?(entity)
      n = norm(entity_display_name(entity))
      APPLIANCE_KEYWORDS.any? { |kw| n.include?(norm(kw)) }
    end

    def classify_zone(entity, bb, wall)
      name_norm = norm(entity_display_name(entity))

      return :base  if BASE_KEYWORDS.any?  { |kw| name_norm.include?(norm(kw)) }
      return :upper if UPPER_KEYWORDS.any? { |kw| name_norm.include?(norm(kw)) }

      wall_base_z = wall[:p1].z
      z_min_cm = (bb.min.z - wall_base_z).to_cm
      z_max_cm = (bb.max.z - wall_base_z).to_cm

      if z_min_cm < 90 && z_max_cm < 230
        :base
      elsif z_min_cm >= 90
        :upper
      else
        :base
      end
    rescue
      :base
    end

    def unit_wall_info(entity, wall)
      return nil unless entity.valid?
      bb = entity.bounds
      return nil if bb.width <= 0 && bb.height <= 0 && bb.depth <= 0

      p1 = wall[:p1]
      dir = wall[:dir]
      wall_len = wall[:wall_len_cm]

      corners = (0..7).map { |i| bb.corner(i) }
      projections = corners.map { |c| p1.vector_to(c).dot(dir).to_cm }
      x_min_cm = projections.min
      x_max_cm = projections.max

      return nil if x_max_cm < 0.5 || x_min_cm > wall_len - 0.5

      out_normal = wall[:out_vec].clone
      out_normal.normalize!
      center = bb.center
      depth_vec = p1.vector_to(center)
      depth_cm = depth_vec.dot(out_normal).to_cm

      return nil if depth_cm > 120
      return nil if depth_cm < -8

      width_cm = x_max_cm - x_min_cm
      return nil if width_cm < 2

      z_min_cm = (bb.min.z - p1.z).to_cm
      z_max_cm = (bb.max.z - p1.z).to_cm
      return nil if z_max_cm < 1

      zone = classify_zone(entity, bb, wall)

      {
        name: entity_display_name(entity),
        offset_cm: x_min_cm.clamp(0.0, wall_len).round(2),
        end_cm: x_max_cm.clamp(0.0, wall_len).round(2),
        width_cm: width_cm.round(2),
        zone: zone,
        depth_cm: depth_cm.round(2),
        bottom_cm: z_min_cm.round(2),
        top_cm: z_max_cm.round(2),
        is_appliance: appliance?(entity)
      }
    rescue
      nil
    end

    def merge_ranges(ranges)
      return [] if ranges.empty?
      sorted = ranges.sort_by { |r| r[0] }
      merged = [sorted[0].dup]
      sorted[1..-1].each do |r|
        last = merged.last
        if r[0] <= last[1] + 0.5
          last[1] = [last[1], r[1]].max
        else
          merged << r.dup
        end
      end
      merged
    end

    def analyze(wall, wall_data)
      return nil unless wall_data

      model = Sketchup.active_model
      units = []
      openings = []

      model.active_entities.each do |ent|
        next unless ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group)
        next unless ent.valid?
        next if ent == wall
        info = unit_wall_info(ent, wall_data)
        units << info if info
      end

      begin
        raw = wall.get_attribute(DICT, OPENINGS_KEY).to_s
        if !raw.strip.empty?
          parsed = JSON.parse(raw) rescue []
          parsed.each do |op|
            x1 = op["offset_cm"].to_f
            w  = op["width_cm"].to_f
            openings << {
              type: op["type"].to_s,
              name: op["type"].to_s == "door" ? "باب" : "شباك",
              offset_cm: x1.round(2),
              end_cm: (x1 + w).round(2),
              width_cm: w.round(2),
              height_cm: op["height_cm"].to_f.round(2),
              sill_cm: op["sill_cm"].to_f.round(2)
            }
          end
        end
      rescue
      end

      base_units  = units.select { |u| u[:zone] == :base }
      upper_units = units.select { |u| u[:zone] == :upper }

      door_ranges   = openings.select { |o| o[:type] == "door" }.map   { |o| [o[:offset_cm], o[:end_cm]] }
      window_ranges = openings.select { |o| o[:type] == "window" }.map { |o| [o[:offset_cm], o[:end_cm]] }

      all_base_ranges  = merge_ranges(base_units.map  { |u| [u[:offset_cm], u[:end_cm]] } + door_ranges + window_ranges)
      all_upper_ranges = merge_ranges(upper_units.map { |u| [u[:offset_cm], u[:end_cm]] } + window_ranges)

      base_occupied_cm  = all_base_ranges.sum  { |r| r[1] - r[0] }
      upper_occupied_cm = all_upper_ranges.sum { |r| r[1] - r[0] }

      wall_len = wall_data[:wall_len_cm]

      base_remain  = wall_len - base_occupied_cm
      upper_remain = wall_len - upper_occupied_cm

      base_overflow  = base_occupied_cm  > wall_len + 0.1
      upper_overflow = upper_occupied_cm > wall_len + 0.1

      {
        wall_length_cm: wall_len.round(2),
        wall_height_cm: wall_data[:wall_h_cm].round(2),
        base_units: base_units,
        upper_units: upper_units,
        openings: openings,
        base_used_cm: base_occupied_cm.round(2),
        upper_used_cm: upper_occupied_cm.round(2),
        base_remaining_cm: base_remain.round(2),
        upper_remaining_cm: upper_remain.round(2),
        base_overflow: base_overflow,
        upper_overflow: upper_overflow,
        base_overflow_cm: base_overflow ? (base_occupied_cm - wall_len).round(2) : 0.0,
        upper_overflow_cm: upper_overflow ? (upper_occupied_cm - wall_len).round(2) : 0.0,
        base_ranges: all_base_ranges,
        upper_ranges: all_upper_ranges
      }
    rescue => e
      puts "MHD SmartWallContent analyze error: #{e.message}"
      nil
    end
  end
  # ================================================================
  # ================================================================

  def uuid
    defined?(SecureRandom) ? SecureRandom.uuid : "#{Time.now.to_i}-#{rand(999999)}"
  end

  def get_attr(entity, key)
    entity.get_attribute(DICT, key)
  end

  def set_attrs(entity, data)
    data.each { |k, v| entity.set_attribute(DICT, k, v) }
  end

  def selected_wall
    Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).find do |e|
      get_attr(e, "النوع") == "حائط"
    end
  end

  def s_to_pt(str)
    a = str.to_s.split("|").map(&:to_f)
    return nil if a.length < 3
    Geom::Point3d.new(a[0], a[1], a[2])
  end

  def clean_face(face)
    return unless face && face.valid?
    face.material = nil
    face.back_material = nil
    face
  end

  def reverse_vector(v)
    r = Geom::Vector3d.new(v.x, v.y, v.z)
    r.reverse!
    r
  end

  def orient_face(face, target_normal)
    return face unless face && face.valid? && target_normal
    face.reverse! if face.normal.dot(target_normal) < 0
    face
  end

  def add_face_clean(ents, pts, target_normal = nil)
    face = ents.add_face(pts)
    clean_face(face)
    orient_face(face, target_normal)
    clean_face(face)
    face
  rescue
    nil
  end

  def erase_definition_geometry(definition)
    definition.entities.to_a.each { |e| e.erase! if e.valid? }
  end

  def remove_all_face_materials(definition)
    definition.entities.grep(Sketchup::Face).each do |f|
      f.material = nil
      f.back_material = nil
    end
  end

  def soften_coplanar_edges(definition)
    definition.entities.grep(Sketchup::Edge).each do |edge|
      next unless edge.valid?
      faces = edge.faces
      next unless faces.length == 2
      if faces[0].normal.parallel?(faces[1].normal)
        edge.soft = true
        edge.smooth = true
        edge.hidden = true
      end
    end
  end

  def read_openings(wall)
    raw = get_attr(wall, OPENINGS_KEY).to_s
    return [] if raw.strip.empty?
    JSON.parse(raw)
  rescue
    []
  end

  def write_openings(wall, openings)
    wall.set_attribute(DICT, OPENINGS_KEY, JSON.generate(openings))
  end

  def wall_data(wall)
    p1 = s_to_pt(get_attr(wall, "P1"))
    p2 = s_to_pt(get_attr(wall, "P2"))
    p3 = s_to_pt(get_attr(wall, "P3"))
    p4 = s_to_pt(get_attr(wall, "P4"))
    return nil unless p1 && p2 && p3 && p4

    wall_h_cm = get_attr(wall, "الارتفاع سم").to_f
    wall_len_cm = get_attr(wall, "طول الحائط سم").to_f
    wall_len_cm = p1.distance(p2).to_cm if wall_len_cm <= 0

    dir = p1.vector_to(p2)
    return nil if dir.length <= 0
    dir.normalize!

    mid_inner = Geom::Point3d.new((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0, (p1.z + p2.z) / 2.0)
    mid_outer = Geom::Point3d.new((p4.x + p3.x) / 2.0, (p4.y + p3.y) / 2.0, (p4.z + p3.z) / 2.0)
    raw_out = mid_inner.vector_to(mid_outer)
    return nil if raw_out.length <= 0

    wall_t = raw_out.length
    out_vec = dir.cross(Z_AXIS)
    out_vec.normalize!

    test_a = mid_inner.offset(out_vec, wall_t)
    test_b = mid_inner.offset(out_vec.reverse, wall_t)
    out_vec.reverse! if test_a.distance(mid_outer) > test_b.distance(mid_outer)
    out_vec.length = wall_t

    {
      p1: p1, p2: p2, p3: p3, p4: p4,
      dir: dir, out_vec: out_vec,
      wall_h_cm: wall_h_cm,
      wall_len_cm: wall_len_cm,
      wall_t: wall_t
    }
  end

  def inner_point(data, x_cm)
    data[:p1].offset(data[:dir], x_cm.cm)
  end

  def outer_point(data, x_cm)
    len = data[:wall_len_cm]
    if x_cm <= 0.001
      data[:p4]
    elsif (len - x_cm).abs <= 0.001
      data[:p3]
    else
      inner_point(data, x_cm).offset(data[:out_vec])
    end
  end

  def zpt(p, z_cm)
    p.offset(Z_AXIS, z_cm.cm)
  end

  def opening_rects(data, openings)
    wall_h = data[:wall_h_cm]
    openings.map do |op|
      x1 = op["offset_cm"].to_f
      x2 = x1 + op["width_cm"].to_f
      if op["type"] == "door"
        z1 = EPS_CM
        z2 = op["height_cm"].to_f
      else
        z1 = op["sill_cm"].to_f
        z2 = z1 + op["height_cm"].to_f
      end
      z1 = [[z1, EPS_CM].max, wall_h - EPS_CM].min
      z2 = [[z2, EPS_CM].max, wall_h - EPS_CM].min
      next if x2 <= x1 || z2 <= z1
      { op: op, x1: x1, x2: x2, z1: z1, z2: z2 }
    end.compact
  end

  def rect_inner_points(data, r)
    [
      zpt(inner_point(data, r[:x1]), r[:z1]),
      zpt(inner_point(data, r[:x2]), r[:z1]),
      zpt(inner_point(data, r[:x2]), r[:z2]),
      zpt(inner_point(data, r[:x1]), r[:z2])
    ]
  end

  def rect_outer_points(data, r)
    [
      zpt(outer_point(data, r[:x1]), r[:z1]),
      zpt(outer_point(data, r[:x2]), r[:z1]),
      zpt(outer_point(data, r[:x2]), r[:z2]),
      zpt(outer_point(data, r[:x1]), r[:z2])
    ]
  end

  def add_face_with_holes(ents, outer_pts, hole_loops, target_normal = nil)
    face = add_face_clean(ents, outer_pts, target_normal)
    return nil unless face && face.valid?
    hole_loops.each do |loop_pts|
      hface = ents.add_face(loop_pts)
      hface.erase! if hface && hface.valid?
    rescue
    end
    orient_face(face, target_normal)
    clean_face(face)
    face
  end

  def build_wall_shell(ents, data, rects)
    wall_h = data[:wall_h_cm]
    outward_normal = data[:out_vec]
    inward_normal = reverse_vector(data[:out_vec])
    down_normal = reverse_vector(Z_AXIS)

    inner_outer = [zpt(data[:p1], 0), zpt(data[:p2], 0), zpt(data[:p2], wall_h), zpt(data[:p1], wall_h)]
    add_face_with_holes(ents, inner_outer, rects.map { |r| rect_inner_points(data, r) }, inward_normal)

    outer_outer = [zpt(data[:p4], 0), zpt(data[:p3], 0), zpt(data[:p3], wall_h), zpt(data[:p4], wall_h)]
    add_face_with_holes(ents, outer_outer, rects.map { |r| rect_outer_points(data, r) }, outward_normal)

    add_face_clean(ents, [zpt(data[:p1], wall_h), zpt(data[:p2], wall_h), zpt(data[:p3], wall_h), zpt(data[:p4], wall_h)], Z_AXIS)

    door_ranges = rects.select { |r| r[:op]["type"] == "door" }.map { |r| [r[:x1], r[:x2]] }
    xs = [0.0, data[:wall_len_cm]]
    door_ranges.each { |a, b| xs << a << b }
    xs = xs.map { |x| [[x, 0.0].max, data[:wall_len_cm]].min.round(4) }.uniq.sort

    xs.each_cons(2) do |x1, x2|
      next if x2 <= x1 + 0.001
      inside_door = door_ranges.any? { |a, b| x1 >= a - 0.001 && x2 <= b + 0.001 }
      next if inside_door
      add_face_clean(ents, [inner_point(data, x1), inner_point(data, x2), outer_point(data, x2), outer_point(data, x1)], down_normal)
    end

    add_face_clean(ents, [zpt(data[:p1], 0), zpt(data[:p4], 0), zpt(data[:p4], wall_h), zpt(data[:p1], wall_h)])
    add_face_clean(ents, [zpt(data[:p2], 0), zpt(data[:p3], 0), zpt(data[:p3], wall_h), zpt(data[:p2], wall_h)])

    rects.each do |r|
      ia, ib, ic, id = rect_inner_points(data, r)
      oa, ob, oc, od = rect_outer_points(data, r)
      add_face_clean(ents, [ia, id, od, oa], reverse_vector(data[:dir]))
      add_face_clean(ents, [ib, ic, oc, ob], data[:dir])
      add_face_clean(ents, [id, ic, oc, od], Z_AXIS)
      add_face_clean(ents, [ia, ib, ob, oa], down_normal)
    end
  end

  def sanitize_openings(openings, data)
    wall_len_cm = data[:wall_len_cm]
    wall_h_cm = data[:wall_h_cm]
    openings.map do |op|
      o = op.dup
      o["offset_cm"] = o["offset_cm"].to_f
      o["width_cm"]  = o["width_cm"].to_f
      o["height_cm"] = o["height_cm"].to_f
      o["sill_cm"]   = o["type"] == "window" ? o["sill_cm"].to_f : 0.0
      o
    end.select do |o|
      o["width_cm"] > 0 && o["height_cm"] > 0 &&
        o["offset_cm"] >= 0 &&
        o["offset_cm"] + o["width_cm"] <= wall_len_cm + 0.001 &&
        o["sill_cm"] >= 0 &&
        o["sill_cm"] + o["height_cm"] < wall_h_cm
    end.sort_by { |o| [o["offset_cm"], o["sill_cm"]] }
  end

  def rebuild_wall(wall)
    data = wall_data(wall)
    unless data
      MHDESIGN_UI_LANG.messagebox("الحائط ده مفيهوش بيانات كافية P1/P2/P3/P4.")
      return false
    end
    openings = sanitize_openings(read_openings(wall), data)
    rects = opening_rects(data, openings)
    wall_def = wall.definition
    erase_definition_geometry(wall_def)
    build_wall_shell(wall_def.entities, data, rects)
    remove_all_face_materials(wall_def)
    soften_coplanar_edges(wall_def)
    write_openings(wall, openings)
    true
  end

  def resolve_offset(measure_cm, width_cm, side, wall_len_cm)
    side == "شمال" ? wall_len_cm - measure_cm - width_cm : measure_cm
  end

  def add_opening_to_wall(wall, opening)
    openings = read_openings(wall)
    openings << opening
    write_openings(wall, openings)
    rebuild_wall(wall)
  end

  def read_pref(key, default)
    Sketchup.read_default(PREF_KEY, key, default)
  end

  def write_pref(key, value)
    Sketchup.write_default(PREF_KEY, key, value)
  end

  def saved_values(type)
    prefix = type == 'window' ? 'window_' : 'door_'
    if type == 'window'
      {
        'width_cm' => read_pref(prefix + 'width_cm', 120).to_f,
        'height_cm' => read_pref(prefix + 'height_cm', 120).to_f,
        'sill_cm' => read_pref(prefix + 'sill_cm', 90).to_f,
        'measure_cm' => read_pref(prefix + 'measure_cm', 50).to_f,
        'side' => read_pref(prefix + 'side', 'يمين').to_s
      }
    else
      {
        'width_cm' => read_pref(prefix + 'width_cm', 90).to_f,
        'height_cm' => read_pref(prefix + 'height_cm', 220).to_f,
        'sill_cm' => 0.0,
        'measure_cm' => read_pref(prefix + 'measure_cm', 50).to_f,
        'side' => read_pref(prefix + 'side', 'يمين').to_s
      }
    end
  end

  def save_values(type, data)
    prefix = type == 'window' ? 'window_' : 'door_'
    %w[width_cm height_cm measure_cm side].each { |k| write_pref(prefix + k, data[k]) if data.key?(k) }
    write_pref(prefix + 'sill_cm', data['sill_cm']) if type == 'window' && data.key?('sill_cm')
  end

  def smart_wall_snapshot(wall = nil)
    target = wall || selected_wall
    return nil unless target
    data = wall_data(target)
    return nil unless data
    SmartWallContent.analyze(target, data)
  end

  # ==================== HTML DIALOG ====================
  def html_dialog_content(type, values, data)
    is_window = type == 'window'
    title = is_window ? MHDESIGN_UI_LANG.key("OPEN_DIALOG_WINDOW", "إضافة شباك") : MHDESIGN_UI_LANG.key("OPEN_DIALOG_DOOR", "إضافة باب")
    type_label = is_window ? MHDESIGN_UI_LANG.key("OPEN_WINDOW", "شباك") : MHDESIGN_UI_LANG.key("OPEN_DOOR", "باب")
    icon_class = is_window ? 'window-icon' : 'door-icon'
    side_right = values['side'] == 'يمين' ? 'active' : ''
    side_left = values['side'] == 'شمال' ? 'active' : ''
    sill_style = is_window ? '' : 'display:none'
    wall_len = data[:wall_len_cm].round(1)
    wall_h = data[:wall_h_cm].round(1)

    <<-HTML
<!DOCTYPE html>
<html lang="#{MHDESIGN_UI_LANG.current}" dir="#{MHDESIGN_UI_LANG.direction}">
<head>
<meta charset="UTF-8">
<title>MHD Opening Engine v3.0</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,Tahoma,sans-serif;background:#07131d;color:#eaf4f8;overflow:hidden}
::-webkit-scrollbar{width:8px}::-webkit-scrollbar-track{background:#07131d}::-webkit-scrollbar-thumb{background:#1d3444;border-radius:20px;border:2px solid #07131d}::-webkit-scrollbar-thumb:hover{background:#2b4a5f}
.app{height:100vh;display:flex;flex-direction:column;background:#07131d}
.hero{height:74px;padding:10px 12px;display:flex;align-items:center;gap:10px;background:linear-gradient(135deg,#07131d,#0c2230);border-bottom:1px solid #1c3342}
.logo{width:58px;height:58px;object-fit:contain;background:#081722;border:1px solid #1c3342;border-radius:10px;padding:5px;flex:0 0 auto}
.head-text{flex:1;text-align:center;overflow:hidden}
.title-main{font-size:20px;font-weight:900;color:#fff;white-space:nowrap}
.subtitle{margin-top:6px;font-size:11px;line-height:1.5;color:#9fb6c5;height:32px;overflow:hidden}
.wrap{height:calc(100vh - 74px - 58px);overflow:auto;padding:10px;background:#07131d}
.group{background:#0b1b27;border:1px solid #1c3342;border-radius:10px;margin-bottom:10px;overflow:hidden}
.group-title{padding:9px 10px;background:#0f2433;color:#39a245;font-size:15px;font-weight:900;border-bottom:1px solid #1c3342;user-select:none}
.group-body{padding:10px}
.preview-box{background:#07131d;border:1px solid #1c3342;border-radius:10px;padding:10px}
.preview-svg{width:100%;height:230px;display:block;background:#06121b;border:1px solid #1c3342;border-radius:10px}
.p-wall{fill:#0f2433;stroke:#4d6b7e;stroke-width:2}
.p-open{fill:#07131d;stroke:#4de37a;stroke-width:3}
.p-line{stroke:#8ad8ff;stroke-width:2;stroke-dasharray:4 4}
.p-txt{fill:#eaf4f8;font-size:11px;font-weight:700;font-family:Arial,Tahoma}
.p-txt-blue{fill:#8ad8ff}
.p-txt-green{fill:#4de37a}
.p-arrow{fill:#8ad8ff}
.door-icon{stroke:#4de37a;stroke-width:6;fill:none;stroke-linecap:round;stroke-linejoin:round}
.window-icon{stroke:#4de37a;stroke-width:6;fill:none;stroke-linecap:round;stroke-linejoin:round}
.field-row{display:grid;grid-template-columns:115px 1fr;gap:8px;align-items:center;margin-bottom:8px}
.field-row:last-child{margin-bottom:0}
label{font-size:13px;font-weight:900;color:#d8e8ef;text-align:right;line-height:1.3}
input[type=number]{width:100%;height:31px;padding:4px 8px;border:none;border-radius:6px;background:#111f2a;color:#fff;font-size:13px;outline:1px solid #243d4f;text-align:center}
input[type=number]:focus{outline:2px solid #39a245;background:#0d1b25}
.side-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.side-btn{height:34px;background:#0b1b27;border:1px solid #243d4f;border-radius:8px;color:#eaf4f8;font-size:13px;font-weight:900;cursor:pointer}
.side-btn:hover{border-color:#39a245}
.side-btn.active{border-color:#39a245;background:#0f2433;box-shadow:0 0 0 1px #39a24566;color:#fff}
.footer{height:58px;padding:8px 10px;border-top:1px solid #1c3342;background:#07131d;display:flex;gap:8px}
button{height:40px;border-radius:10px;font-size:14px;font-weight:900;cursor:pointer;border:none}
.ok{flex:2;background:#4de37a;color:#061923}
.ok:disabled{background:#2a3d33;color:#6a7a72;cursor:not-allowed}
.cancel{flex:1;background:#0b1b27;color:#fff;border:1px solid #243d4f}

/* ============ SMART PANEL ============ */
.sm-row{display:flex;justify-content:space-between;align-items:center;padding:7px 10px;border-bottom:1px solid #1c3342;font-size:13px}
.sm-row:last-child{border-bottom:none}
.sm-label{font-weight:800;color:#a8c1cf}
.sm-value{font-weight:900;color:#fff}
.sm-bar{height:16px;background:#0a1a24;border:1px solid #203948;border-radius:8px;overflow:hidden;margin:5px 0 9px;position:relative}
.sm-fill{height:100%;background:linear-gradient(90deg,#39a245,#4de37a);transition:width .25s ease}
.sm-fill.over{background:linear-gradient(90deg,#c62828,#ef5350)}
.sm-fill.warn{background:linear-gradient(90deg,#ef6c00,#ffb74d)}
.sm-fill.upper{background:linear-gradient(90deg,#1565c0,#42a5f5)}
.sm-warn{background:#3a171b;border:1px solid #7a2a31;color:#ffd9dc;padding:10px 12px;border-radius:8px;font-size:12.5px;line-height:1.8;margin-top:8px}
.sm-ok{background:#0f2a1c;border:1px solid #2a6b45;color:#b9f2c8;padding:10px 12px;border-radius:8px;font-size:12.5px;line-height:1.8;margin-top:8px}
.sm-units{font-size:11px;color:#9fb6c5;margin-top:6px;line-height:1.75}
.sm-units b{color:#eaf4f8}
.sm-zone{margin-bottom:14px}
.sm-zone:last-child{margin-bottom:0}
.sm-zone-title{font-size:13.5px;font-weight:900;color:#4de37a;margin-bottom:6px;display:flex;justify-content:space-between;align-items:center}
.sm-zone-title.upper{color:#42a5f5}
.sm-badge{display:inline-block;padding:2px 7px;border-radius:5px;font-size:10px;font-weight:800;margin-inline-start:6px}
.sm-badge.appliance{background:#4a2a00;color:#ffcf80;border:1px solid #8a5a1f}
</style>
</head>
<body>
<div class="app">
  <div class="hero">
    <img class="logo" src="#{LOGO_URL}">
    <div class="head-text">
      <div class="title-main">#{title}</div>
      <div class="subtitle">MHDESIGN Smart Wall Engine v3.0<br>تحليل ذكي كامل لمحتوى الحائط</div>
    </div>
  </div>

  <div class="wrap">

    <!-- ============ SMART PANEL ============ -->
    <div class="group" id="smartPanel">
      <div class="group-title">▼ تحليل الحيط الذكي</div>
      <div class="group-body">
        <div id="smartBody">
          <div class="sm-units">جاري التحليل...</div>
        </div>
      </div>
    </div>
    <!-- ================================== -->

    <div class="group">
      <div class="group-title">▼ نوع الفتحة</div>
      <div class="group-body">
        <div class="preview-box">
          <svg class="preview-svg" viewBox="0 0 300 230">
            <defs>
              <marker id="arr" markerWidth="8" markerHeight="8" refX="4" refY="4" orient="auto">
                <path class="p-arrow" d="M0,0 L8,4 L0,8 Z"></path>
              </marker>
            </defs>
            <rect id="wallRect" class="p-wall" x="34" y="34" width="232" height="145" rx="2"></rect>
            <rect id="openRect" class="p-open" x="110" y="80" width="55" height="99"></rect>
            <line id="dimWall" class="p-line" x1="34" y1="198" x2="266" y2="198" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtWall" class="p-txt p-txt-blue" x="150" y="214" text-anchor="middle">طول الحائط: #{wall_len} سم</text>
            <line id="dimWallHeight" class="p-line" x1="18" y1="34" x2="18" y2="179" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtWallHeight" class="p-txt p-txt-blue" x="10" y="106.5" transform="rotate(-90 10 106.5)" text-anchor="middle">ارتفاع: #{wall_h} سم</text>
            <line id="dimMeasure" class="p-line" x1="34" y1="24" x2="110" y2="24" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtMeasure" class="p-txt p-txt-blue" x="72" y="18" text-anchor="middle">المسافة</text>
            <line id="dimWidth" class="p-line" x1="110" y1="68" x2="165" y2="68" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtWidth" class="p-txt p-txt-green" x="137" y="62" text-anchor="middle">العرض</text>
            <path id="typeIcon" class="#{icon_class}" d="M126 179 V94 H174 V179 M164 134 h1"></path>
          </svg>
        </div>
      </div>
    </div>

    <div class="group">
      <div class="group-title">▼ المقاسات</div>
      <div class="group-body">
        <div class="field-row"><label>عرض #{type_label} سم</label><input id="width_cm" type="number" step="0.1" value="#{values['width_cm']}" oninput="updatePreview()"></div>
        <div class="field-row"><label>ارتفاع #{type_label} سم</label><input id="height_cm" type="number" step="0.1" value="#{values['height_cm']}" oninput="updatePreview()"></div>
        <div class="field-row" style="#{sill_style}"><label>جلسة الشباك سم</label><input id="sill_cm" type="number" step="0.1" value="#{values['sill_cm']}" oninput="updatePreview()"></div>
        <div class="field-row"><label>المسافة سم</label><input id="measure_cm" type="number" step="0.1" value="#{values['measure_cm']}" oninput="updatePreview()"></div>
        <div class="field-row">
          <label>اتجاه القياس</label>
          <div class="side-grid">
            <button type="button" class="side-btn #{side_right}" data-side="يمين" onclick="selectSide(this)">يمين</button>
            <button type="button" class="side-btn #{side_left}" data-side="شمال" onclick="selectSide(this)">شمال</button>
          </div>
        </div>
      </div>
    </div>

  </div>

  <div class="footer">
    <button class="ok" id="okBtn" onclick="submitData()">إنشاء</button>
    <button class="cancel" onclick="sketchup.cancel()">إلغاء</button>
  </div>
</div>

<script>
const TYPE = '#{type}';
let WALL_LEN = #{wall_len};
let WALL_H = #{wall_h};
let side = '#{values['side']}';
let smartSnapshot = null;

function n(id){ const el=document.getElementById(id); return el ? parseFloat(el.value||0) : 0; }
function clamp(v,min,max){ return Math.max(min, Math.min(max, v)); }
function selectSide(el){
  document.querySelectorAll('.side-btn').forEach(x=>x.classList.remove('active'));
  el.classList.add('active');
  side=el.dataset.side;
  updatePreview();
}
function setWallData(len, height){
  WALL_LEN = parseFloat(len || 0);
  WALL_H = parseFloat(height || 0);
  updatePreview();
}
function updatePreview(){
  const w = Math.max(1,n('width_cm'));
  const h = Math.max(1,n('height_cm'));
  const sill = TYPE==='window' ? Math.max(0,n('sill_cm')) : 0;
  const measure = Math.max(0,n('measure_cm'));
  const wallX=34, wallY=34, wallW=232, wallH=145;
  const maxXScale = wallW / Math.max(WALL_LEN,1);
  const maxYScale = wallH / Math.max(WALL_H,1);
  let openW = clamp(w * maxXScale, 14, wallW);
  let openH = clamp(h * maxYScale, 18, wallH);
  let sillPx = clamp(sill * maxYScale, 0, wallH - openH);
  let off = side==='شمال' ? measure : WALL_LEN - measure - w;
  off = clamp(off,0,Math.max(0,WALL_LEN-w));
  let openX = wallX + clamp(off * maxXScale, 0, wallW-openW);
  let openY = wallY + wallH - sillPx - openH;
  const txtWall=document.getElementById('txtWall');
  if(txtWall) txtWall.textContent='طول الحائط: ' + WALL_LEN + ' سم';
  const txtWallHeight=document.getElementById('txtWallHeight');
  if(txtWallHeight) txtWallHeight.textContent='ارتفاع: ' + WALL_H + ' سم';
  const openRect = document.getElementById('openRect');
  if(openRect){
    openRect.setAttribute('x',openX);
    openRect.setAttribute('y',openY);
    openRect.setAttribute('width',openW);
    openRect.setAttribute('height',openH);
  }
  const typeIcon = document.getElementById('typeIcon');
  if(typeIcon){
    if(TYPE==='door'){
      typeIcon.setAttribute('d',`M${openX+openW*.18} ${wallY+wallH} V${openY+8} H${openX+openW*.82} V${wallY+wallH} M${openX+openW*.67} ${openY+openH*.48} h1`);
    }else{
      typeIcon.setAttribute('d',`M${openX+5} ${openY+5} H${openX+openW-5} V${openY+openH-5} H${openX+5} Z M${openX+openW/2} ${openY+5} V${openY+openH-5} M${openX+5} ${openY+openH/2} H${openX+openW-5}`);
    }
  }
  const dimM=document.getElementById('dimMeasure');
  const txtM=document.getElementById('txtMeasure');
  if(dimM && txtM){
    let fromX = side==='شمال' ? wallX : wallX+wallW;
    let toX = side==='شمال' ? openX : openX+openW;
    dimM.setAttribute('x1',fromX);
    dimM.setAttribute('x2',toX);
    dimM.setAttribute('y1',24);
    dimM.setAttribute('y2',24);
    txtM.setAttribute('x',(fromX+toX)/2);
    txtM.textContent = 'المسافة ' + measure + ' سم من ' + side;
  }
  const dimW=document.getElementById('dimWidth');
  const txtW=document.getElementById('txtWidth');
  if(dimW && txtW){
    dimW.setAttribute('x1',openX);
    dimW.setAttribute('x2',openX+openW);
    dimW.setAttribute('y1',openY-10);
    dimW.setAttribute('y2',openY-10);
    txtW.setAttribute('x',openX+openW/2);
    txtW.setAttribute('y',openY-16);
    txtW.textContent='العرض ' + w + ' سم';
  }
}

// ==================== SMART WALL RENDER ====================
function renderSmartWall(snapshot){
  smartSnapshot = snapshot;
  const body = document.getElementById('smartBody');
  const okBtn = document.getElementById('okBtn');
  if(!body) return;

  if(!snapshot){
    body.innerHTML = '<div class="sm-units">لا توجد بيانات حائط كافية للتحليل.</div>';
    if(okBtn){ okBtn.disabled = false; }
    return;
  }

  const L = snapshot.wall_length_cm;
  function pct(v){ return Math.min(100, Math.max(0, (v / L) * 100)); }

  // حساب عرض الفتحة الحالية الجاري إدخالها
  const currentOpeningWidth = Math.max(0, parseFloat(document.getElementById('width_cm').value || 0));
  const currentSill = (TYPE === 'window') ? Math.max(0, parseFloat(document.getElementById('sill_cm').value || 0)) : 0;
  const currentMeasure = Math.max(0, parseFloat(document.getElementById('measure_cm').value || 0));

  // نحدد على مين تأثير الفتحة الحالية
  let currentAffectsBase = true;
  let currentAffectsUpper = false;

  if(TYPE === 'window'){
    // شباك: يأثر على الاتنين
    currentAffectsBase = true;
    currentAffectsUpper = true;
  } else if(TYPE === 'door'){
    // باب: بس السفلي
    currentAffectsBase = true;
    currentAffectsUpper = false;
  }

  function zoneBlock(title, usedBase, remainBase, overflowBase, overflowBaseCm, units, openingDelta, zoneCls){
    const used = usedBase + (openingDelta > 0 ? openingDelta : 0);
    const remain = L - used;
    const overflow = used > L + 0.1;
    const overflowCm = overflow ? (used - L) : 0;

    const usedPct = pct(used);
    let fillCls = 'sm-fill';
    if(zoneCls === 'upper') fillCls += ' upper';
    if(overflow) fillCls = 'sm-fill over';
    else if(usedPct > 90) fillCls = 'sm-fill warn';

    let html = `<div class="sm-zone">
      <div class="sm-zone-title ${zoneCls === 'upper' ? 'upper' : ''}">
        <span>${title}</span>
        <span>${used.toFixed(1)} / ${L.toFixed(1)} سم</span>
      </div>
      <div class="sm-bar"><div class="${fillCls}" style="width:${usedPct}%"></div></div>
      <div class="sm-row">
        <span class="sm-label">${overflow ? 'الزيادة' : 'الفاضل'}</span>
        <span class="sm-value" style="color:${overflow ? '#ff8a80' : '#7ee39c'}">
          ${overflow ? ('+ ' + overflowCm.toFixed(1) + ' سم تجاوز!') : (remain.toFixed(1) + ' سم')}
        </span>
      </div>`;

    if(units && units.length){
      html += '<div class="sm-units"><b>العناصر الحالية:</b><br>' +
        units.map(u => {
          const tag = u.is_appliance ? ' <span class="sm-badge appliance">جهاز</span>' : '';
          return `• ${u.name}${tag} — ${u.width_cm} سم (${u.offset_cm}→${u.end_cm})`;
        }).join('<br>') + '</div>';
    } else {
      html += '<div class="sm-units">لا توجد عناصر مسجّلة على هذا الجزء من الحيط.</div>';
    }

    if(openingDelta > 0){
      html += `<div class="sm-units" style="color:#8ad8ff">
        ➕ الفتحة الحالية تضيف: <b>${openingDelta.toFixed(1)} سم</b> على هذا الجزء.
      </div>`;
    }

    if(overflow){
      html += `<div class="sm-warn">
        ⚠️ تجاوزت الحيط بمقدار <b>${overflowCm.toFixed(1)} سم</b>.<br>
        <b>الحل:</b> قلّل المقاس بمقدار <b>${overflowCm.toFixed(1)} سم</b> أو غيّر ترتيب العناصر.
      </div>`;
    } else {
      html += `<div class="sm-ok">✅ مقاس ${title} سليم — الفاضل <b>${remain.toFixed(1)} سم</b>.</div>`;
    }

    html += '</div>';
    return { html: html, overflow: overflow, overflowCm: overflowCm };
  }

  let out = '';
  let baseOverflowFlag = false;
  let upperOverflowFlag = false;

  // السفلي
  const baseResult = zoneBlock(
    'السفلي',
    snapshot.base_used_cm,
    snapshot.base_remaining_cm,
    snapshot.base_overflow,
    snapshot.base_overflow_cm,
    snapshot.base_units,
    currentAffectsBase ? currentOpeningWidth : 0,
    'base'
  );
  out += baseResult.html;
  baseOverflowFlag = baseResult.overflow;

  // العلوي
  const upperResult = zoneBlock(
    'العلوي',
    snapshot.upper_used_cm,
    snapshot.upper_remaining_cm,
    snapshot.upper_overflow,
    snapshot.upper_overflow_cm,
    snapshot.upper_units,
    currentAffectsUpper ? currentOpeningWidth : 0,
    'upper'
  );
  out += upperResult.html;
  upperOverflowFlag = upperResult.overflow;

  // الفتحات الحالية
  if(snapshot.openings && snapshot.openings.length){
    out += '<div class="sm-units" style="border-top:1px solid #1c3342;padding-top:8px;margin-top:8px">' +
      '<b>الفتحات المسجّلة:</b><br>' +
      snapshot.openings.map(o =>
        `• ${o.name} — ${o.width_cm} سم (${o.offset_cm}→${o.end_cm})`
      ).join('<br>') + '</div>';
  }

  body.innerHTML = out;

  // لو في overflow في الجزء اللي بتأثر عليه الفتحة، نعطّل الزرار
  const blocksCurrent = (currentAffectsBase && baseOverflowFlag) || (currentAffectsUpper && upperOverflowFlag);
  if(okBtn){
    if(blocksCurrent){
      okBtn.disabled = true;
      okBtn.textContent = '⛔ تجاوز المقاس';
    } else {
      okBtn.disabled = false;
      okBtn.textContent = 'إنشاء';
    }
  }
}
// =====================================================

function submitData(){
  if(smartSnapshot){
    const L = smartSnapshot.wall_length_cm;
    const w = Math.max(0, parseFloat(document.getElementById('width_cm').value || 0));
    const baseUsed = smartSnapshot.base_used_cm + ((TYPE === 'window' || TYPE === 'door') ? w : 0);
    const upperUsed = smartSnapshot.upper_used_cm + ((TYPE === 'window') ? w : 0);
    if(baseUsed > L + 0.1){
      alert('⛔ لا يمكن الإنشاء: الوحدات السفلية تجاوزت طول الحيط بمقدار ' + (baseUsed - L).toFixed(1) + ' سم.');
      return;
    }
    if(upperUsed > L + 0.1){
      alert('⛔ لا يمكن الإنشاء: الوحدات العلوية تجاوزت طول الحيط بمقدار ' + (upperUsed - L).toFixed(1) + ' سم.');
      return;
    }
  }

  const data = {
    width_cm: n('width_cm'),
    height_cm: n('height_cm'),
    sill_cm: n('sill_cm'),
    measure_cm: n('measure_cm'),
    side: side
  };
  sketchup.submit(JSON.stringify(data));
}

document.addEventListener('contextmenu', function(e){ e.preventDefault(); });
document.addEventListener('dragstart', function(e){ e.preventDefault(); });
document.addEventListener('selectstart', function(e){
  const tag = (e.target && e.target.tagName || '').toLowerCase();
  if(tag !== 'input') e.preventDefault();
});

updatePreview();
</script>
</body>
</html>
    HTML
  end

  # ==================== DIALOG INPUT ====================
  def dialog_input(type)
    wall = selected_wall
    unless wall
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_SELECT_WALL", "حدد حائط الأول"))
      return
    end

    data = wall_data(wall)
    unless data
      MHDESIGN_UI_LANG.messagebox("الحائط ده مفيهوش بيانات كافية.")
      return
    end

    values = saved_values(type)
    dlg = UI::HtmlDialog.new(
      dialog_title: type == 'window' ? "MHD Opening - Window" : "MHD Opening - Door",
      preferences_key: PREF_KEY,
      scrollable: false,
      resizable: true,
      width: 360,
      height: 720,
      style: UI::HtmlDialog::STYLE_DIALOG
    )
    dlg.set_html(html_dialog_content(type, values, data))

    last_wall_pid = wall.persistent_id rescue wall.entityID
    timer_id = nil

    # ===== بث التحليل الذكي للحائط كل 0.6 ثانية =====
    smart_timer = UI.start_timer(0.6, true) do
      begin
        current_wall = selected_wall
        next unless current_wall && current_wall.valid?
        snap = smart_wall_snapshot(current_wall)
        dlg.execute_script("renderSmartWall(#{snap ? snap.to_json : 'null'});")
      rescue
      end
    end

    # ===== تحديث الحائط عند تغيير التحديد =====
    timer_id = UI.start_timer(0.25, true) do
      begin
        current_wall = selected_wall
        next unless current_wall && current_wall.valid?

        current_pid = current_wall.persistent_id rescue current_wall.entityID
        next if current_pid == last_wall_pid

        current_data = wall_data(current_wall)
        next unless current_data

        last_wall_pid = current_pid
        len = current_data[:wall_len_cm].round(1)
        hgt = current_data[:wall_h_cm].round(1)
        dlg.execute_script("setWallData(#{len}, #{hgt});")

        # حدّث التحليل الذكي فورًا
        snap = smart_wall_snapshot(current_wall)
        dlg.execute_script("renderSmartWall(#{snap ? snap.to_json : 'null'});")
      rescue
      end
    end

    # أول snapshot فوري
    begin
      snap_initial = smart_wall_snapshot(wall)
      dlg.execute_script("renderSmartWall(#{snap_initial ? snap_initial.to_json : 'null'});") rescue nil
    rescue
    end

    stop_timer = proc do
      if timer_id
        UI.stop_timer(timer_id) rescue nil
        timer_id = nil
      end
      if smart_timer
        UI.stop_timer(smart_timer) rescue nil
        smart_timer = nil
      end
    end

    dlg.set_on_closed { stop_timer.call }

    dlg.add_action_callback('cancel') do
      stop_timer.call
      dlg.close
    end

    dlg.add_action_callback('submit') do |_, json|
      input = JSON.parse(json)
      save_values(type, input)

      current_wall = selected_wall
      unless current_wall && current_wall.valid?
        MHDESIGN_UI_LANG.messagebox("حدد الحائط الذي تريد تنفيذ الفتحة عليه")
        next
      end

      current_data = wall_data(current_wall)
      unless current_data
        MHDESIGN_UI_LANG.messagebox("الحائط المحدد مفيهوش بيانات كافية.")
        next
      end

      # ===== فحص أخير قبل التنفيذ =====
      snap = smart_wall_snapshot(current_wall)
      if snap
        w = input['width_cm'].to_f
        affects_base = (type == 'window' || type == 'door')
        affects_upper = (type == 'window')
        base_after = snap[:base_used_cm] + (affects_base ? w : 0)
        upper_after = snap[:upper_used_cm] + (affects_upper ? w : 0)
        L = snap[:wall_length_cm]

        if base_after > L + 0.1
          MHDESIGN_UI_LANG.messagebox("⛔ لا يمكن تنفيذ الفتحة.\n\nالوحدات السفلية + الفتحة تجاوزت طول الحيط بمقدار #{(base_after - L).round(1)} سم.")
          next
        end
        if upper_after > L + 0.1
          MHDESIGN_UI_LANG.messagebox("⛔ لا يمكن تنفيذ الفتحة.\n\nالوحدات العلوية + الفتحة تجاوزت طول الحيط بمقدار #{(upper_after - L).round(1)} سم.")
          next
        end
      end

      stop_timer.call
      dlg.close
      create_opening(type, current_wall, input)
    rescue => e
      MHDESIGN_UI_LANG.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
    end

    dlg.show
    nil
  end

  def create_opening(type, wall, input)
    model = Sketchup.active_model
    data = wall_data(wall)
    return MHDESIGN_UI_LANG.messagebox("الحائط ده مفيهوش بيانات كافية.") unless data

    width_cm   = input['width_cm'].to_f
    height_cm  = input['height_cm'].to_f
    sill_cm    = type == 'window' ? input['sill_cm'].to_f : 0.0
    measure_cm = input['measure_cm'].to_f
    side       = input['side'].to_s == 'شمال' ? 'شمال' : 'يمين'

    wall_len_cm = data[:wall_len_cm]
    wall_h_cm   = data[:wall_h_cm]

    if width_cm <= 0 || height_cm <= 0
      MHDESIGN_UI_LANG.messagebox("العرض والارتفاع لازم يكونوا أكبر من صفر")
      return
    end
    if type == 'door' && height_cm >= wall_h_cm
      MHDESIGN_UI_LANG.messagebox("ارتفاع الباب لازم يكون أقل من ارتفاع الحائط")
      return
    end
    if type == 'window' && sill_cm < 0
      MHDESIGN_UI_LANG.messagebox("ارتفاع جلسة الشباك لا يمكن يكون أقل من صفر")
      return
    end
    if type == 'window' && sill_cm + height_cm >= wall_h_cm
      MHDESIGN_UI_LANG.messagebox("ارتفاع الشباك + الجلسة لازم يكون أقل من ارتفاع الحائط")
      return
    end
    if measure_cm < 0 || measure_cm + width_cm > wall_len_cm
      MHDESIGN_UI_LANG.messagebox("عرض الفتحة والمسافة أكبر من طول الحائط\n\nطول الحائط: #{wall_len_cm.round(1)} سم")
      return
    end

    offset_cm = resolve_offset(measure_cm, width_cm, side, wall_len_cm)
    opening = {
      'uuid' => uuid,
      'type' => type == 'window' ? 'window' : 'door',
      'name' => type == 'window' ? 'شباك' : 'باب',
      'width_cm' => width_cm,
      'height_cm' => height_cm,
      'sill_cm' => sill_cm,
      'offset_cm' => offset_cm,
      'measure_cm' => measure_cm,
      'side' => side
    }

    model.start_operation("MHD Opening Engine v3.0 - Add #{type}", true)
    ok = add_opening_to_wall(wall, opening)
    if ok
      if type == 'window'
        set_attrs(wall, { "به شباك" => "نعم", "نسخة محرك الفتحات" => "v3.0" })
      else
        set_attrs(wall, { "به باب" => "نعم", "نسخة محرك الفتحات" => "v3.0" })
      end
    end
    model.commit_operation
    MHDESIGN_UI_LANG.messagebox(type == 'window' ? "تم إضافة الشباك بنجاح" : "تم إضافة الباب بنجاح") if ok
  rescue => e
    model.abort_operation rescue nil
    MHDESIGN_UI_LANG.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
  end

  def add_door
    dialog_input('door')
  end

  def add_window
    dialog_input('window')
  end

  def clear_openings
    model = Sketchup.active_model
    wall = selected_wall
    unless wall
      MHDESIGN_UI_LANG.messagebox("حدد حائط الأول")
      return
    end
    return unless MHDESIGN_UI_LANG.messagebox("هل تريد حذف كل فتحات هذا الحائط؟", MB_YESNO) == IDYES
    model.start_operation("MHD Opening Engine v3.0 - Clear Openings", true)
    write_openings(wall, [])
    rebuild_wall(wall)
    set_attrs(wall, { "به باب" => "لا", "به شباك" => "لا", "نسخة محرك الفتحات" => "v3.0" })
    model.commit_operation
    MHDESIGN_UI_LANG.messagebox("تم حذف فتحات الحائط")
  rescue => e
    model.abort_operation rescue nil
    MHDESIGN_UI_LANG.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
  end

  # ==================== تقرير سريع من القائمة ====================
  def show_smart_report
    wall = selected_wall
    unless wall
      MHDESIGN_UI_LANG.messagebox("حدد حائط الأول")
      return
    end
    snap = smart_wall_snapshot(wall)
    unless snap
      MHDESIGN_UI_LANG.messagebox("لا توجد بيانات كافية.")
      return
    end

    L = snap[:wall_length_cm]
    msg = "📐 تقرير قياس الحيط\n"
    msg << "━━━━━━━━━━━━━━━━━━━━\n"
    msg << "طول الحيط: #{L} سم\n\n"

    msg << "🔽 السفلي:\n"
    msg << "  المستخدم: #{snap[:base_used_cm]} سم\n"
    if snap[:base_overflow]
      msg << "  ⚠️ الزيادة: #{snap[:base_overflow_cm]} سم\n"
    else
      msg << "  ✅ الفاضل: #{snap[:base_remaining_cm]} سم\n"
    end
    if snap[:base_units].any?
      snap[:base_units].each do |u|
        tag = u[:is_appliance] ? " [جهاز]" : ""
        msg << "   • #{u[:name]}#{tag} — #{u[:width_cm]} سم\n"
      end
    end
    msg << "\n"

    msg << "🔼 العلوي:\n"
    msg << "  المستخدم: #{snap[:upper_used_cm]} سم\n"
    if snap[:upper_overflow]
      msg << "  ⚠️ الزيادة: #{snap[:upper_overflow_cm]} سم\n"
    else
      msg << "  ✅ الفاضل: #{snap[:upper_remaining_cm]} سم\n"
    end
    if snap[:upper_units].any?
      snap[:upper_units].each do |u|
        msg << "   • #{u[:name]} — #{u[:width_cm]} سم\n"
      end
    end

    if snap[:openings].any?
      msg << "\n🚪 الفتحات:\n"
      snap[:openings].each do |o|
        msg << "   • #{o[:name]} — #{o[:width_cm]} سم (#{o[:offset_cm]}→#{o[:end_cm]})\n"
      end
    end

    MHDESIGN_UI_LANG.messagebox(msg)
  end

  unless @context_menu_loaded
    UI.add_context_menu_handler do |menu|
      if selected_wall
        menu.add_separator
        menu.add_item(MENU_DOOR)   { add_door }
        menu.add_item(MENU_WINDOW) { add_window }
        menu.add_separator
        menu.add_item(MENU_REPORT) { show_smart_report }
        menu.add_separator
        menu.add_item(MENU_CLEAR)  { clear_openings }
      end
    end
    @context_menu_loaded = true
  end
end

puts "MHD Opening Engine v3.0 - Smart Wall Analyzer loaded."
puts "افتح قائمة الكليك يمين على أي حيط لاستخدام الأدوات."
