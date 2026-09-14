# encoding: UTF-8
# MHD Opening Engine v2.6 Live Wall Selection UI
# ملف واحد مستقل يعمل فوق MHD Room Builder v1 Stable
# - نفس منطق v2.1 لإعادة بناء الحائط كـ Shell واحد بفتحات داخلية
# - واجهة حديثة بنفس روح MHD Countertop Engine v3.1
# - معاينة ديناميكية تعرض طول الحائط، عرض/ارتفاع الفتحة، المسافة، واتجاه القياس

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

    if text.start_with?('OPEN_')
      return key(text, fallback_text)
    end

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

module MHD_Opening_Engine_V26_LIVE_WALL_SELECTION
  extend self

  MENU_DOOR   = MHDESIGN_UI_LANG.key("OPEN_MENU_DOOR", "إضافة باب")
  MENU_WINDOW = MHDESIGN_UI_LANG.key("OPEN_MENU_WINDOW", "إضافة شباك")
  MENU_CLEAR  = MHDESIGN_UI_LANG.key("OPEN_MENU_CLEAR", "حذف فتحات الحائط")

  DICT = "MHD_ROOM_BUILDER"
  OPENINGS_KEY = "OPENINGS_JSON"
  EPS_CM = 0.05
  LOGO_URL = 'https://mhdesign-eg.com/SKETCHUP/components/logo3.png'
  PREF_KEY = 'MHD_OPENING_ENGINE_V26_UI'

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
    a = zpt(inner_point(data, r[:x1]), r[:z1])
    b = zpt(inner_point(data, r[:x2]), r[:z1])
    c = zpt(inner_point(data, r[:x2]), r[:z2])
    d = zpt(inner_point(data, r[:x1]), r[:z2])
    [a, b, c, d]
  end

  def rect_outer_points(data, r)
    a = zpt(outer_point(data, r[:x1]), r[:z1])
    b = zpt(outer_point(data, r[:x2]), r[:z1])
    c = zpt(outer_point(data, r[:x2]), r[:z2])
    d = zpt(outer_point(data, r[:x1]), r[:z2])
    [a, b, c, d]
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
      MHDESIGN_UI_LANG.messagebox("الحائط ده مفيهوش بيانات كافية P1/P2/P3/P4. ابني الغرفة بنسخة الحوائط المستقرة الأول.")
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
<title>MHD Opening Engine</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Arial,Tahoma,sans-serif;background:#07131d;color:#eaf4f8;overflow:hidden}
::-webkit-scrollbar{width:8px}::-webkit-scrollbar-track{background:#07131d}::-webkit-scrollbar-thumb{background:#1d3444;border-radius:20px;border:2px solid #07131d}::-webkit-scrollbar-thumb:hover{background:#2b4a5f}
.app{height:100vh;display:flex;flex-direction:column;background:#07131d}
.hero{height:74px;padding:10px 12px;display:flex;align-items:center;gap:10px;background:linear-gradient(135deg,#07131d,#0c2230);border-bottom:1px solid #1c3342}
.logo{width:58px;height:58px;object-fit:contain;background:#081722;border:1px solid #1c3342;border-radius:10px;padding:5px;flex:0 0 auto}.head-text{flex:1;text-align:center;overflow:hidden}.title-main{font-size:20px;font-weight:900;color:#fff;white-space:nowrap}.subtitle{margin-top:6px;font-size:11px;line-height:1.5;color:#9fb6c5;height:32px;overflow:hidden}
.wrap{height:calc(100vh - 74px - 58px);overflow:auto;padding:10px;background:#07131d}.group{background:#0b1b27;border:1px solid #1c3342;border-radius:10px;margin-bottom:10px;overflow:hidden}.group-title{padding:9px 10px;background:#0f2433;color:#39a245;font-size:16px;font-weight:900;border-bottom:1px solid #1c3342;user-select:none}.group-body{padding:10px}
.preview-box{background:#07131d;border:1px solid #1c3342;border-radius:10px;padding:10px}.preview-svg{width:100%;height:230px;display:block;background:#06121b;border:1px solid #1c3342;border-radius:10px}.p-wall{fill:#0f2433;stroke:#4d6b7e;stroke-width:2}.p-open{fill:#07131d;stroke:#4de37a;stroke-width:3}.p-line{stroke:#8ad8ff;stroke-width:2;stroke-dasharray:4 4}.p-txt{fill:#eaf4f8;font-size:11px;font-weight:700;font-family:Arial,Tahoma}.p-txt-blue{fill:#8ad8ff}.p-txt-green{fill:#4de37a}.p-arrow{fill:#8ad8ff}.door-icon{stroke:#4de37a;stroke-width:6;fill:none;stroke-linecap:round;stroke-linejoin:round}.window-icon{stroke:#4de37a;stroke-width:6;fill:none;stroke-linecap:round;stroke-linejoin:round}
.field-row{display:grid;grid-template-columns:115px 1fr;gap:8px;align-items:center;margin-bottom:8px}.field-row:last-child{margin-bottom:0}label{font-size:13px;font-weight:900;color:#d8e8ef;text-align:right;line-height:1.3}input[type=number]{width:100%;height:31px;padding:4px 8px;border:none;border-radius:6px;background:#111f2a;color:#fff;font-size:13px;outline:1px solid #243d4f;text-align:center}input[type=number]:focus{outline:2px solid #39a245;background:#0d1b25}
.side-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}.side-btn{height:34px;background:#0b1b27;border:1px solid #243d4f;border-radius:8px;color:#eaf4f8;font-size:13px;font-weight:900;cursor:pointer}.side-btn:hover{border-color:#39a245}.side-btn.active{border-color:#39a245;background:#0f2433;box-shadow:0 0 0 1px #39a24566;color:#fff}.footer{height:58px;padding:8px 10px;border-top:1px solid #1c3342;background:#07131d;display:flex;gap:8px}button{height:40px;border-radius:10px;font-size:14px;font-weight:900;cursor:pointer;border:none}.ok{flex:2;background:#4de37a;color:#061923}.cancel{flex:1;background:#0b1b27;color:#fff;border:1px solid #243d4f}
</style>
</head>
<body>
<div class="app">
  <div class="hero">
    <img class="logo" src="#{LOGO_URL}">
    <div class="head-text"><div class="title-main">#{title}</div><div class="subtitle">تم تصميم هذه الأداة بواسطة MHDESIGN<br>Opening Engine v1.0</div></div>
  </div>
  <div class="wrap">
    <div class="group">
      <div class="group-title">▼ نوع الفتحة</div>
      <div class="group-body">
        <div class="preview-box">
          <svg class="preview-svg" viewBox="0 0 300 230">
            <defs>
              <marker id="arr" markerWidth="8" markerHeight="8" refX="4" refY="4" orient="auto"><path class="p-arrow" d="M0,0 L8,4 L0,8 Z"></path></marker>
            </defs>
            <rect id="wallRect" class="p-wall" x="34" y="34" width="232" height="145" rx="2"></rect>
            <rect id="openRect" class="p-open" x="110" y="80" width="55" height="99"></rect>
            <line id="dimWall" class="p-line" x1="34" y1="198" x2="266" y2="198" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtWall" class="p-txt p-txt-blue" x="150" y="214" text-anchor="middle">طول الحائط: #{wall_len} سم</text>
            <line id="dimWallHeight" class="p-line" x1="18" y1="34" x2="18" y2="179" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtWallHeight" class="p-txt p-txt-blue" x="10" y="106.5" transform="rotate(-90 10 106.5)" text-anchor="middle">ارتفاع الحائط: #{wall_h} سم</text>
            <line id="dimMeasure" class="p-line" x1="34" y1="24" x2="110" y2="24" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtMeasure" class="p-txt p-txt-blue" x="72" y="18" text-anchor="middle">المسافة</text>
            <line id="dimWidth" class="p-line" x1="110" y1="68" x2="165" y2="68" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtWidth" class="p-txt p-txt-green" x="137" y="62" text-anchor="middle">العرض</text>
            <line id="dimHeight" class="p-line" x1="280" y1="80" x2="280" y2="179" marker-start="url(#arr)" marker-end="url(#arr)"></line>
            <text id="txtHeight" class="p-txt p-txt-green" x="286" y="132" transform="rotate(90 286 132)" text-anchor="middle">الارتفاع</text>
            <line id="dimSill" class="p-line" x1="22" y1="179" x2="22" y2="179" marker-start="url(#arr)" marker-end="url(#arr)" style="display:none"></line>
            <text id="txtSill" class="p-txt p-txt-blue" x="16" y="155" transform="rotate(-90 16 155)" text-anchor="middle" style="display:none">الجلسة</text>
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
        <div class="field-row"><label>اتجاه القياس</label><div class="side-grid"><button type="button" class="side-btn #{side_right}" data-side="يمين" onclick="selectSide(this)">يمين</button><button type="button" class="side-btn #{side_left}" data-side="شمال" onclick="selectSide(this)">شمال</button></div></div>
      </div>
    </div>

  </div>
  <div class="footer"><button class="ok" onclick="submitData()">إنشاء</button><button class="cancel" onclick="sketchup.cancel()">إلغاء</button></div>
</div>
<script>
const TYPE = '#{type}';
let WALL_LEN = #{wall_len};
let WALL_H = #{wall_h};
let side = '#{values['side']}';
function n(id){ const el=document.getElementById(id); return el ? parseFloat(el.value||0) : 0; }
function clamp(v,min,max){ return Math.max(min, Math.min(max, v)); }
function selectSide(el){ document.querySelectorAll('.side-btn').forEach(x=>x.classList.remove('active')); el.classList.add('active'); side=el.dataset.side; updatePreview(); }
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
  // المعاينة بصرية: شمال يظهر يسار الحائط، ويمين يظهر يمين الحائط.
  let off = side==='شمال' ? measure : WALL_LEN - measure - w;
  off = clamp(off,0,Math.max(0,WALL_LEN-w));
  let openX = wallX + clamp(off * maxXScale, 0, wallW-openW);
  let openY = wallY + wallH - sillPx - openH;
  const txtWall=document.getElementById('txtWall'); txtWall.textContent=MHD_LT('طول الحائط: ') + WALL_LEN + ' ' + MHD_LT('سم');
  const txtWallHeight=document.getElementById('txtWallHeight'); txtWallHeight.textContent=MHD_LT('ارتفاع الحائط: ') + WALL_H + ' ' + MHD_LT('سم');
  const openRect = document.getElementById('openRect');
  openRect.setAttribute('x',openX); openRect.setAttribute('y',openY); openRect.setAttribute('width',openW); openRect.setAttribute('height',openH);
  const typeIcon = document.getElementById('typeIcon');
  if(TYPE==='door'){
    typeIcon.setAttribute('d',`M${openX+openW*.18} ${wallY+wallH} V${openY+8} H${openX+openW*.82} V${wallY+wallH} M${openX+openW*.67} ${openY+openH*.48} h1`);
  }else{
    typeIcon.setAttribute('d',`M${openX+5} ${openY+5} H${openX+openW-5} V${openY+openH-5} H${openX+5} Z M${openX+openW/2} ${openY+5} V${openY+openH-5} M${openX+5} ${openY+openH/2} H${openX+openW-5}`);
  }
  const dimM=document.getElementById('dimMeasure');
  let fromX = side==='شمال' ? wallX : wallX+wallW;
  let toX = side==='شمال' ? openX : openX+openW;
  dimM.setAttribute('x1',fromX); dimM.setAttribute('x2',toX); dimM.setAttribute('y1',24); dimM.setAttribute('y2',24);
  const txtM=document.getElementById('txtMeasure'); txtM.setAttribute('x',(fromX+toX)/2); txtM.textContent = MHD_LT('المسافة') + ' ' + measure + ' ' + MHD_LT('سم') + ' ' + MHD_LT('من') + ' ' + MHD_LT(side);
  const dimW=document.getElementById('dimWidth'); dimW.setAttribute('x1',openX); dimW.setAttribute('x2',openX+openW); dimW.setAttribute('y1',openY-10); dimW.setAttribute('y2',openY-10);
  const txtW=document.getElementById('txtWidth'); txtW.setAttribute('x',openX+openW/2); txtW.setAttribute('y',openY-16); txtW.textContent=MHD_LT('العرض') + ' ' + w + ' ' + MHD_LT('سم');
  const dimH=document.getElementById('dimHeight'); dimH.setAttribute('x1',openX+openW+14); dimH.setAttribute('x2',openX+openW+14); dimH.setAttribute('y1',openY); dimH.setAttribute('y2',openY+openH);
  const txtH=document.getElementById('txtHeight'); const hx=openX+openW+20, hy=openY+openH/2; txtH.setAttribute('x',hx); txtH.setAttribute('y',hy); txtH.setAttribute('transform',`rotate(90 ${hx} ${hy})`); txtH.textContent=MHD_LT('الارتفاع') + ' ' + h + ' ' + MHD_LT('سم');
  const dimS=document.getElementById('dimSill'), txtS=document.getElementById('txtSill');
  if(TYPE==='window'){
    dimS.style.display=''; txtS.style.display=''; dimS.setAttribute('x1',openX-12); dimS.setAttribute('x2',openX-12); dimS.setAttribute('y1',openY+openH); dimS.setAttribute('y2',wallY+wallH);
    const sx=openX-20, sy=(openY+openH+wallY+wallH)/2; txtS.setAttribute('x',sx); txtS.setAttribute('y',sy); txtS.setAttribute('transform',`rotate(-90 ${sx} ${sy})`); txtS.textContent=MHD_LT('الجلسة') + ' ' + sill + ' ' + MHD_LT('سم');
  }
}
function submitData(){
  const data={width_cm:n('width_cm'),height_cm:n('height_cm'),sill_cm:n('sill_cm'),measure_cm:n('measure_cm'),side:side};
  sketchup.submit(JSON.stringify(data));
}

// حماية شكلية داخل واجهة الأداة: منع قائمة الكليك يمين والسحب والتحديد.
document.addEventListener('contextmenu', function(e){ e.preventDefault(); });
document.addEventListener('dragstart', function(e){ e.preventDefault(); });
document.addEventListener('selectstart', function(e){
  const tag = (e.target && e.target.tagName || '').toLowerCase();
  if(tag !== 'input') e.preventDefault();
});

updatePreview();
</script>

<script>
(function(){
  const MHD_L10N = #{MHDESIGN_UI_LANG.payload_json};
  const TEXTS = MHD_L10N.texts || {};
  const MAP = MHD_L10N.source_map || {};

  function translateKey(key, fallback){
    const value = TEXTS[String(key || '')];
    return value == null || String(value).trim() === ''
      ? String(fallback == null ? key : fallback)
      : String(value);
  }

  function translateText(value){
    if(!value) return value || '';
    if(Object.prototype.hasOwnProperty.call(MAP, value)) return String(MAP[value]);

    let result = value;
    Object.keys(MAP)
      .sort((a,b)=>b.length-a.length)
      .forEach((key)=>{
        if(key) result = result.split(key).join(MAP[key]);
      });
    return result;
  }

  window.MHD_LT = translateText;
  document.documentElement.lang = MHD_L10N.locale || 'ar_EG';
  document.documentElement.dir = MHD_L10N.direction || 'rtl';

  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const nodes = [];
  while(walker.nextNode()) nodes.push(walker.currentNode);

  nodes.forEach((node)=>{
    const raw = node.nodeValue || '';
    if(!raw.trim()) return;
    const lead = (raw.match(/^\s*/) || [''])[0];
    const tail = (raw.match(/\s*$/) || [''])[0];
    const core = raw.slice(lead.length, raw.length-tail.length);
    node.nodeValue = lead + translateText(core) + tail;
  });

  document.querySelectorAll('[placeholder]').forEach((el)=>{
    el.placeholder = translateText(el.placeholder);
  });
  document.querySelectorAll('[title]').forEach((el)=>{
    el.title = translateText(el.title);
  });
})();
</script>

</body>
</html>
    HTML
  end

  def dialog_input(type)
    wall = selected_wall
    unless wall
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_SELECT_WALL", "حدد حائط الأول"))
      return
    end

    data = wall_data(wall)
    unless data
      MHDESIGN_UI_LANG.messagebox("الحائط ده مفيهوش بيانات كافية. ابني الغرفة بنسخة الحوائط المستقرة الأول.")
      return
    end

    values = saved_values(type)
    dlg = UI::HtmlDialog.new(
      dialog_title: type == 'window' ? MHDESIGN_UI_LANG.t('MHD Opening - Window') : MHDESIGN_UI_LANG.t('MHD Opening - Door'),
      preferences_key: PREF_KEY,
      scrollable: false,
      resizable: true,
      width: 330,
      height: 640,
      style: UI::HtmlDialog::STYLE_DIALOG
    )
    dlg.set_html(html_dialog_content(type, values, data))

    last_wall_pid = wall.persistent_id rescue wall.entityID
    timer_id = nil

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
      rescue
      end
    end

    stop_timer = proc do
      if timer_id
        UI.stop_timer(timer_id) rescue nil
        timer_id = nil
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
        MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_SELECT_TARGET_WALL", "حدد الحائط الذي تريد تنفيذ الفتحة عليه"))
        next
      end

      current_data = wall_data(current_wall)
      unless current_data
        MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_WALL_DATA_MISSING", "الحائط المحدد مفيهوش بيانات كافية."))
        next
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
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_WIDTH_HEIGHT_POSITIVE", "العرض والارتفاع لازم يكونوا أكبر من صفر"))
      return
    end
    if type == 'door' && height_cm >= wall_h_cm
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_DOOR_HEIGHT_LIMIT", "ارتفاع الباب لازم يكون أقل من ارتفاع الحائط"))
      return
    end
    if type == 'window' && sill_cm < 0
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_SILL_NONNEGATIVE", "ارتفاع جلسة الشباك لا يمكن يكون أقل من صفر"))
      return
    end
    if type == 'window' && sill_cm + height_cm >= wall_h_cm
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_WINDOW_HEIGHT_LIMIT", "ارتفاع الشباك + الجلسة لازم يكون أقل من ارتفاع الحائط"))
      return
    end
    if measure_cm < 0 || measure_cm + width_cm > wall_len_cm
      MHDESIGN_UI_LANG.messagebox("#{MHDESIGN_UI_LANG.key("OPEN_EXCEEDS_WALL", "عرض الفتحة والمسافة أكبر من طول الحائط")}\n\n#{MHDESIGN_UI_LANG.key("OPEN_WALL_LENGTH", "طول الحائط")}: #{wall_len_cm.round(1)} #{MHDESIGN_UI_LANG.key("OPEN_CM", "سم")}")
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

    model.start_operation("MHD Opening Engine v2.6 - Add #{type}", true)
    ok = add_opening_to_wall(wall, opening)
    if ok
      if type == 'window'
        set_attrs(wall, { "به شباك" => "نعم", "نسخة محرك الفتحات" => "v2.6" })
      else
        set_attrs(wall, { "به باب" => "نعم", "نسخة محرك الفتحات" => "v2.6" })
      end
    end
    model.commit_operation
    MHDESIGN_UI_LANG.messagebox(type == 'window' ? MHDESIGN_UI_LANG.key("OPEN_WINDOW_SUCCESS", "تم إضافة الشباك بنجاح") : MHDESIGN_UI_LANG.key("OPEN_DOOR_SUCCESS", "تم إضافة الباب بنجاح")) if ok
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
      MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_SELECT_WALL", "حدد حائط الأول"))
      return
    end
    return unless MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_CONFIRM_CLEAR", "هل تريد حذف كل فتحات هذا الحائط؟"), MB_YESNO) == IDYES
    model.start_operation("MHD Opening Engine v2.6 - Clear Openings", true)
    write_openings(wall, [])
    rebuild_wall(wall)
    set_attrs(wall, { "به باب" => "لا", "به شباك" => "لا", "نسخة محرك الفتحات" => "v2.6" })
    model.commit_operation
    MHDESIGN_UI_LANG.messagebox(MHDESIGN_UI_LANG.key("OPEN_CLEAR_SUCCESS", "تم حذف فتحات الحائط"))
  rescue => e
    model.abort_operation rescue nil
    MHDESIGN_UI_LANG.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
  end

  unless @context_menu_loaded
    UI.add_context_menu_handler do |menu|
      if selected_wall
        menu.add_separator
        menu.add_item(MENU_DOOR) { add_door }
        menu.add_item(MENU_WINDOW) { add_window }
        menu.add_separator
        menu.add_item(MENU_CLEAR) { clear_openings }
      end
    end
    @context_menu_loaded = true
  end
end

# ========الدمج========

module MHD_Final_Merge_Test
  extend self

  DC_DICT = "dynamic_attributes"
  TOLERANCE_CM = 0.2
  DIRECTION_DOT = 0.985

  MERGE_PREF_KEY = "MHD_FINAL_MERGE_UI"
  MERGE_LOGO_URL = "https://mhdesign-eg.com/SKETCHUP/components/logo3.png"
  DEFAULT_MERGED_NAME = MHDESIGN_UI_LANG.t("وحدة مدموجة")
  CONFIRMED_CHASSIS_THICKNESS_CM = 1.8

  MERGE_ALIGNMENT_TOLERANCE_CM = 1.0
  MERGE_CONTACT_TOLERANCE_CM = 1.0

  RULES = {
    drawer:      ["درج", "ادراج", "أدراج"],
    right_side:  ["جنب يمين", "جانب يمين"],
    left_side:   ["جنب شمال", "جانب شمال", "جنب يسار", "جانب يسار"],
    front_rail:  ["شداد امامي", "شداد أمامي"],
    back_rail:   ["شداد خلفي"],
    qorsa:       ["قرصة", "قرصه"],
    shelf:       ["رف", "ارفف", "أرفف"],
    base:        ["قاعده", "قاعدة"],
    back:        ["ضهر", "ظهر"],
    hinge:       ["مفصله عدله", "مفصلة عدلة"]
  }.freeze

  WIDTH_LABELS = ["عرض الشاسيه", "عرض الشاسي", "عرض الشاسه"].freeze
  DEPTH_LABELS = ["عمق الشاسيه", "عمق الشاسي", "عمق الشاسه"].freeze
  HEIGHT_LABELS = ["ارتفاع الشاسيه", "ارتفاع الشاسي", "ارتفاع الشاسه"].freeze
  COUNTER_LABELS = ["تخانة الكونتر", "تخانة الكونتر", "سمك الكونتر"].freeze
  GROOVE_DROP_LABELS = [
    "سقوط المفحار",
    "سقوط المفحار",
    "سقوط المفحار"
  ].freeze
  ASSEMBLY_LABELS = ["طريقة التجميع", "طريقه التجميع"].freeze

  DOOR_TYPE_LABELS = [
    "نوع الضلفه",
    "نوع الضلفة",
    "نوع الدرفه",
    "نوع الدرفة",
    "نوع الضلفه العلوية",
    "نوع الضلفة العلوية",
    "نوع الضلفه السفليه",
    "نوع الضلفة السفلية",
    "نوع الضلفه فوق",
    "نوع الضلفة فوق",
    "نوع الضلفه تحت",
    "نوع الضلفة تحت"
  ].freeze

  BACK_START_LABELS = [
    "بداية الشاسيه من الضهر",
    "بدايه الشاسيه من الضهر",
    "بداية الشاسيه من الظهر",
    "بدايه الشاسيه من الظهر",
    "بداية الضهر من الخلف",
    "بدايه الضهر من الخلف",
    "بداية الظهر من الخلف",
    "بدايه الظهر من الخلف"
  ].freeze

  BACK_THICKNESS_LABELS = [
    "تخانة الضهر",
    "تخانة الضهر",
    "سمك الضهر",
    "تخانة الظهر",
    "تخانة الظهر",
    "سمك الظهر"
  ].freeze

  Part = Struct.new(:entity, :world_tr, :name, keyword_init: true)

  def dc
    return nil unless defined?($dc_observers) && $dc_observers
    $dc_observers.get_latest_class
  rescue
    nil
  end

  def norm(text)
    text.to_s
        .tr("أإآٱ", "اااا")
        .tr("ةى", "هي")
        .gsub(/[ًٌٍَُِّْـ]/, "")
        .gsub(/\s+/, "")
        .downcase
  end

  def entity_name(entity)
    values = []
    values << entity.name.to_s if entity.respond_to?(:name)
    values << entity.definition.name.to_s if entity.respond_to?(:definition)
    values << entity.get_attribute(DC_DICT, "name", "").to_s if entity.respond_to?(:get_attribute)
    values.reject(&:empty?).join(" | ")
  rescue
    ""
  end

  def match?(name, rule)
    n = norm(name)

    if rule == :front_rail
      return n.include?(norm("شداد")) && n.include?(norm("امامي"))
    end

    RULES.fetch(rule, []).any? { |word| n.include?(norm(word)) }
  end

  def normalized_axis(vector)
    axis = vector.clone
    return nil if axis.length <= 0.000001
    axis.normalize!
    axis
  rescue
    nil
  end

  def projection(point, axis)
    point.x.to_f * axis.x.to_f +
      point.y.to_f * axis.y.to_f +
      point.z.to_f * axis.z.to_f
  end

  def bounds_range(entity, axis)
    bb = entity.bounds
    values = (0..7).map { |index| projection(bb.corner(index), axis) }
    [values.min, values.max]
  end

  def selected_units
    Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
  end

  def collect_parts(root)
    result = []

    walk = lambda do |entities, parent_world|
      entities.each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance) ||
                    entity.is_a?(Sketchup::Group)

        world = parent_world * entity.transformation

        result << Part.new(
          entity: entity,
          world_tr: world,
          name: entity_name(entity)
        )

        children =
          if entity.is_a?(Sketchup::Group)
            entity.entities
          else
            entity.definition.entities
          end

        walk.call(children, world)
      end
    end

    root_entities =
      root.is_a?(Sketchup::Group) ? root.entities : root.definition.entities

    walk.call(root_entities, root.transformation)
    result
  end

  def isolate_paths_to_rule!(root, rule)
    visited = {}

    walk = lambda do |container|
      entities =
        if container.is_a?(Sketchup::Group)
          container.entities
        elsif container.respond_to?(:definition)
          container.definition.entities
        else
          nil
        end

      return unless entities

      entities.to_a.each do |child|
        next unless child.is_a?(Sketchup::ComponentInstance) ||
                    child.is_a?(Sketchup::Group)

        child_key = child.respond_to?(:persistent_id) ? child.persistent_id : child.object_id
        next if visited[child_key]

        contains_target = subtree_contains_rule?(child, rule, {})
        next unless contains_target

        if child.is_a?(Sketchup::ComponentInstance) && child.respond_to?(:make_unique)
          child.make_unique
        end

        visited[child_key] = true
        walk.call(child)
      end
    end

    walk.call(root)
    true
  rescue => error
    puts "MHD Isolate Path Error: #{error.message}"
    false
  end

  def subtree_contains_rule?(entity, rule, visited)
    return false unless entity && entity.valid?
    return true if match?(entity_name(entity), rule)

    definition_key =
      if entity.is_a?(Sketchup::Group)
        entity.object_id
      elsif entity.respond_to?(:definition)
        entity.definition.object_id
      else
        entity.object_id
      end

    return false if visited[definition_key]
    visited[definition_key] = true

    entities =
      if entity.is_a?(Sketchup::Group)
        entity.entities
      elsif entity.respond_to?(:definition)
        entity.definition.entities
      end

    return false unless entities

    entities.any? do |child|
      next false unless child.is_a?(Sketchup::ComponentInstance) ||
                        child.is_a?(Sketchup::Group)
      subtree_contains_rule?(child, rule, visited.dup)
    end
  rescue
    false
  end

  def first_part(parts, rule)
    parts.find { |part| match?(part.name, rule) }
  end

  def has_direct_geometry?(part)
    entity = part.respond_to?(:entity) ? part.entity : part
    return false unless entity && entity.valid?

    entities =
      if entity.is_a?(Sketchup::Group)
        entity.entities
      elsif entity.respond_to?(:definition)
        entity.definition.entities
      end

    return false unless entities

    entities.any? do |child|
      child.is_a?(Sketchup::Face) || child.is_a?(Sketchup::Edge)
    end
  rescue
    false
  end

  def best_part(parts, rule)
    candidates = all_parts(parts, rule).select do |part|
      part.entity && part.entity.valid?
    end
    return nil if candidates.empty?

    candidates.each_with_index.max_by do |part, index|
      score = 0
      score += 100 if has_direct_geometry?(part)
      score += 20 if has_direct_lenx?(part)
      score + index.to_f / 1000.0
    end.first
  rescue
    first_part(parts, rule)
  end

  def has_direct_lenx?(part)
    entity = part.respond_to?(:entity) ? part.entity : part
    return false unless entity && entity.valid?

    instance_dict = entity.attribute_dictionary(DC_DICT, false)
    definition_dict =
      if entity.respond_to?(:definition)
        entity.definition.attribute_dictionary(DC_DICT, false)
      end

    dictionaries = [instance_dict, definition_dict].compact

    dictionaries.any? do |dict|
      keys = dict.keys.map { |key| key.to_s.downcase }
      keys.include?("lenx") ||
        keys.include?("_lenx_formula") ||
        keys.include?("_lenx_access")
    end
  rescue
    false
  end

  def all_parts(parts, rule)
    parts.select { |part| match?(part.name, rule) }
  end

  def main_base_part(parts)
    candidates = all_parts(parts, :base)
    return nil if candidates.empty?

    main_candidates = candidates.reject do |part|
      name = norm(part.name)

      name.include?(norm("قاعدة الدرج")) ||
        name.include?(norm("قاعده الدرج")) ||
        name.include?(norm("قاعدةدرج")) ||
        name.include?(norm("قاعدهدرج"))
    end

    pool = main_candidates.empty? ? candidates : main_candidates
    best_part(pool, :base)
  end

  def main_back_part(parts)
    candidates = all_parts(parts, :back)
    return nil if candidates.empty?

    main_candidates = candidates.reject do |part|
      name = norm(part.name)

      name.include?(norm("ضهر شاسيه الدرج")) ||
        name.include?(norm("ضهر شاسه الدرج")) ||
        name.include?(norm("ظهر شاسيه الدرج")) ||
        name.include?(norm("ظهر شاسه الدرج"))
    end

    pool = main_candidates.empty? ? candidates : main_candidates
    best_part(pool, :back)
  end

  def drawer_unit?(unit)
    return true if match?(entity_name(unit), :drawer)
    collect_parts(unit).any? { |part| match?(part.name, :drawer) }
  end

  def dc_keys(entity)
    dict = entity.definition.attribute_dictionary(DC_DICT, false)
    return [] unless dict

    keys = []
    dict.each_pair do |key, _value|
      key = key.to_s
      next unless key.start_with?("_") && key.end_with?("_access")
      keys << key.sub(/\A_/, "").sub(/_access\z/, "")
    end
    keys.uniq
  rescue
    []
  end

  def find_dc_value_cm(entity, labels)
    engine = dc
    return nil unless engine

    wanted = labels.map { |label| norm(label) }

    dc_keys(entity).each do |key|
      label = begin
        engine.get_attribute_formlabel(entity, key).to_s
      rescue
        key
      end

      normalized = norm(label)
      next unless wanted.any? { |item| normalized == item || normalized.include?(item) }

      units = begin
        engine.get_attribute_formulaunits(entity, key).to_s
      rescue
        ""
      end

      if units.empty?
        units = begin
          engine.get_attribute_units(entity, key).to_s
        rescue
          ""
        end
      end

      value = begin
        engine.get_attribute_value(entity, key).to_f
      rescue
        entity.get_attribute(DC_DICT, key, 0.0).to_f
      end

      return units.to_s.upcase == "CENTIMETERS" ? value * 2.54 : value
    end

    nil
  end

  def find_dc_text_value(entity, labels)
    engine = dc
    return nil unless engine

    wanted = labels.map { |label| norm(label) }

    dc_keys(entity).each do |key|
      label = begin
        engine.get_attribute_formlabel(entity, key).to_s
      rescue
        key
      end

      normalized = norm(label)
      next unless wanted.any? { |item| normalized == item || normalized.include?(item) }

      value = begin
        engine.get_attribute_value(entity, key).to_s
      rescue
        entity.get_attribute(DC_DICT, key, "").to_s
      end

      return value
    end

    nil
  rescue
    nil
  end

  def assembly_method_type(entity)
    value = find_dc_text_value(entity, ASSEMBLY_LABELS)
    normalized = norm(value)

    return :side_on_base if value.to_s.strip == "1" || value.to_f == 1.0
    return :full_side    if value.to_s.strip == "2" || value.to_f == 2.0

    return :side_on_base if normalized.include?(norm("جنب على القاعده"))
    return :side_on_base if normalized.include?(norm("جنب على القاعدة"))

    if normalized.include?(norm("جنب كامل")) &&
       (
         normalized.include?(norm("سحابي")) ||
         normalized.include?(norm("سماحي")) ||
         normalized.include?(norm("سباحي"))
       )
      return :full_side
    end

    nil
  end

  def door_type_entries(entity)
    engine = dc
    return [] unless engine

    wanted = DOOR_TYPE_LABELS.map { |label| norm(label) }
    entries = []

    dc_keys(entity).each do |key|
      label =
        begin
          engine.get_attribute_formlabel(entity, key).to_s
        rescue
          key.to_s
        end

      normalized_label = norm(label)

      next unless wanted.any? do |item|
        normalized_label == item ||
          normalized_label.include?(item) ||
          item.include?(normalized_label)
      end

      value =
        begin
          engine.get_attribute_value(entity, key)
        rescue
          entity.get_attribute(DC_DICT, key, nil)
        end

      entries << {
        key: key.to_s,
        label: label.to_s,
        value: value,
        value_text: value.to_s
      }
    end

    entries
  rescue => error
    puts "MHD Door Type Read Error: #{error.message}"
    []
  end

  def door_type_text(entity)
    entries = door_type_entries(entity)
    return "" if entries.empty?

    entries.map do |entry|
      "#{entry[:label]}=#{entry[:value_text]}"
    end.join(" | ")
  end

  def forbidden_vertical_upper_door_type?(entity)
    entries = door_type_entries(entity)

    entries.any? do |entry|
      raw = entry[:value]
      text = norm(entry[:value_text])

      numeric_value =
        begin
          Float(raw)
        rescue
          nil
        end

      numeric_forbidden =
        numeric_value &&
        (
          (numeric_value - 2.0).abs < 0.000001 ||
          (numeric_value - 5.0).abs < 0.000001
        )

      text_forbidden =
        (
          text.include?(norm("مقبض بلت ان بخلع")) ||
          text.include?(norm("بلت ان بخلع")) ||
          text.include?(norm("بلت إن بخلع")) ||
          text.include?(norm("ضلفه بشفه من الاسفل")) ||
          text.include?(norm("ضلفة بشفة من الأسفل")) ||
          (
            (
              text.include?(norm("شفه")) ||
              text.include?(norm("شفة"))
            ) &&
            (
              text.include?(norm("الاسفل")) ||
              text.include?(norm("الأسفل")) ||
              text.include?(norm("اسفل"))
            )
          )
        )

      numeric_forbidden || text_forbidden
    end
  rescue => error
    puts "MHD Door Type Validation Error: #{error.message}"
    false
  end


  def ranges_aligned_for_merge?(range_a, range_b, tolerance)
    (range_a[0].to_f - range_b[0].to_f).abs <= tolerance &&
      (range_a[1].to_f - range_b[1].to_f).abs <= tolerance
  end

  def ranges_touch_for_merge?(range_a, range_b, tolerance)
    [
      (range_a[1].to_f - range_b[0].to_f).abs,
      (range_b[1].to_f - range_a[0].to_f).abs
    ].min <= tolerance
  end

  def horizontal_layout_valid?(unit_a, unit_b)
    x_axis = normalized_axis(unit_a.transformation.xaxis)
    y_axis = normalized_axis(unit_a.transformation.yaxis)
    z_axis = normalized_axis(unit_a.transformation.zaxis)
    return false unless x_axis && y_axis && z_axis

    align_tolerance = MERGE_ALIGNMENT_TOLERANCE_CM.cm.to_f
    contact_tolerance = MERGE_CONTACT_TOLERANCE_CM.cm.to_f

    x_a = bounds_range(unit_a, x_axis)
    x_b = bounds_range(unit_b, x_axis)
    y_a = bounds_range(unit_a, y_axis)
    y_b = bounds_range(unit_b, y_axis)
    z_a = bounds_range(unit_a, z_axis)
    z_b = bounds_range(unit_b, z_axis)

    ranges_aligned_for_merge?(y_a, y_b, align_tolerance) &&
      ranges_aligned_for_merge?(z_a, z_b, align_tolerance) &&
      ranges_touch_for_merge?(x_a, x_b, contact_tolerance)
  rescue
    false
  end

  def vertical_layout_valid?(unit_a, unit_b)
    x_axis = normalized_axis(unit_a.transformation.xaxis)
    y_axis = normalized_axis(unit_a.transformation.yaxis)
    z_axis = normalized_axis(unit_a.transformation.zaxis)
    return false unless x_axis && y_axis && z_axis

    align_tolerance = MERGE_ALIGNMENT_TOLERANCE_CM.cm.to_f
    contact_tolerance = MERGE_CONTACT_TOLERANCE_CM.cm.to_f

    x_a = bounds_range(unit_a, x_axis)
    x_b = bounds_range(unit_b, x_axis)
    y_a = bounds_range(unit_a, y_axis)
    y_b = bounds_range(unit_b, y_axis)
    z_a = bounds_range(unit_a, z_axis)
    z_b = bounds_range(unit_b, z_axis)

    ranges_aligned_for_merge?(x_a, x_b, align_tolerance) &&
      ranges_aligned_for_merge?(y_a, y_b, align_tolerance) &&
      ranges_touch_for_merge?(z_a, z_b, contact_tolerance)
  rescue
    false
  end

  def row_info(unit_a, unit_b)
    x1 = normalized_axis(unit_a.transformation.xaxis)
    y1 = normalized_axis(unit_a.transformation.yaxis)
    z1 = normalized_axis(unit_a.transformation.zaxis)

    x2 = normalized_axis(unit_b.transformation.xaxis)
    y2 = normalized_axis(unit_b.transformation.yaxis)
    z2 = normalized_axis(unit_b.transformation.zaxis)

    return nil unless [x1, y1, z1, x2, y2, z2].all?
    return nil unless x1.dot(x2) >= DIRECTION_DOT
    return nil unless y1.dot(y2) >= DIRECTION_DOT
    return nil unless z1.dot(z2) >= DIRECTION_DOT

    range_a = bounds_range(unit_a, x1)
    range_b = bounds_range(unit_b, x1)

    left, right =
      range_a[0] <= range_b[0] ? [unit_a, unit_b] : [unit_b, unit_a]

    {
      axis: x1,
      left: left,
      right: right,
      full_min: [range_a[0], range_b[0]].min,
      full_max: [range_a[1], range_b[1]].max
    }
  end

  def make_unique!(part)
    entity = part.entity
    entity.make_unique if entity.respond_to?(:make_unique)
  rescue
  end

  def erase_part!(part)
    part.entity.erase! if part && part.entity.valid?
  end

  def rename_part!(part, new_name)
    return unless part && part.entity.valid?
    entity = part.entity
    entity.make_unique if entity.is_a?(Sketchup::ComponentInstance)
    entity.definition.name = new_name if entity.respond_to?(:definition)
  end

  def next_divider_number
    max = 0
    Sketchup.active_model.definitions.each do |definition|
      next unless norm(definition.name).include?(norm("قاطع"))
      if definition.name.to_s =~ /(\d+)/
        max = [max, Regexp.last_match(1).to_i].max
      end
    end
    max + 1
  end

  def axis_for_part(part, world_axis)
    axes = {
      x: normalized_axis(part.world_tr.xaxis),
      y: normalized_axis(part.world_tr.yaxis),
      z: normalized_axis(part.world_tr.zaxis)
    }

    axes.max_by { |_key, axis| axis ? axis.dot(world_axis).abs : -1.0 }
  end

  def local_bounds(entity)
    entity.is_a?(Sketchup::Group) ? entity.local_bounds : entity.definition.bounds
  end

  def extend_part_toward_unit!(part, world_axis, extension_sign, extension_amount)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if extension_amount.to_f <= 0.000001

    make_unique!(part)

    axis_key, axis_world = axis_for_part(part, world_axis)
    return false unless axis_key && axis_world

    bounds = local_bounds(entity)

    local_min, local_max =
      case axis_key
      when :x then [bounds.min.x, bounds.max.x]
      when :y then [bounds.min.y, bounds.max.y]
      when :z then [bounds.min.z, bounds.max.z]
      end

    local_length = (local_max - local_min).abs
    return false if local_length <= 0.000001

    parent_world = part.world_tr * entity.transformation.inverse

    local_min_point =
      case axis_key
      when :x then Geom::Point3d.new(local_min, 0, 0)
      when :y then Geom::Point3d.new(0, local_min, 0)
      when :z then Geom::Point3d.new(0, 0, local_min)
      end

    local_max_point =
      case axis_key
      when :x then Geom::Point3d.new(local_max, 0, 0)
      when :y then Geom::Point3d.new(0, local_max, 0)
      when :z then Geom::Point3d.new(0, 0, local_max)
      end

    world_min = parent_world * (entity.transformation * local_min_point)
    world_max = parent_world * (entity.transformation * local_max_point)

    proj_min = projection(world_min, world_axis)
    proj_max = projection(world_max, world_axis)

    target_is_max =
      if extension_sign.to_f >= 0.0
        proj_max >= proj_min
      else
        proj_max <= proj_min
      end

    anchor_value = target_is_max ? local_min : local_max

    anchor =
      case axis_key
      when :x then Geom::Point3d.new(anchor_value, 0, 0)
      when :y then Geom::Point3d.new(0, anchor_value, 0)
      when :z then Geom::Point3d.new(0, 0, anchor_value)
      end

    current_world_length =
      local_length *
      case axis_key
      when :x then part.world_tr.xaxis.length
      when :y then part.world_tr.yaxis.length
      when :z then part.world_tr.zaxis.length
      end

    return false if current_world_length <= 0.000001

    desired_world_length = current_world_length + extension_amount.to_f
    factor = desired_world_length / current_world_length

    sx = axis_key == :x ? factor : 1.0
    sy = axis_key == :y ? factor : 1.0
    sz = axis_key == :z ? factor : 1.0

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(anchor, sx, sy, sz)

    true
  rescue => error
    puts "MHD Merge extend error (#{part.name}): #{error.message}"
    false
  end

  def set_part_largest_dimension!(part, world_axis, extension_sign, target_length)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_length.to_f <= 0.000001

    make_unique!(part)

    bounds = local_bounds(entity)
    parent_world = part.world_tr * entity.transformation.inverse
    current_world = parent_world * entity.transformation

    dimensions = {
      x: bounds.width.to_f  * current_world.xaxis.length.to_f,
      y: bounds.height.to_f * current_world.yaxis.length.to_f,
      z: bounds.depth.to_f  * current_world.zaxis.length.to_f
    }

    axis_key, current_length =
      dimensions.max_by { |_key, value| value.to_f }

    current_length = current_length.to_f
    return false if current_length <= 0.000001

    local_min, local_max =
      case axis_key
      when :x then [bounds.min.x, bounds.max.x]
      when :y then [bounds.min.y, bounds.max.y]
      when :z then [bounds.min.z, bounds.max.z]
      end

    min_point =
      case axis_key
      when :x then Geom::Point3d.new(local_min, 0, 0)
      when :y then Geom::Point3d.new(0, local_min, 0)
      when :z then Geom::Point3d.new(0, 0, local_min)
      end

    max_point =
      case axis_key
      when :x then Geom::Point3d.new(local_max, 0, 0)
      when :y then Geom::Point3d.new(0, local_max, 0)
      when :z then Geom::Point3d.new(0, 0, local_max)
      end

    world_min = parent_world * (entity.transformation * min_point)
    world_max = parent_world * (entity.transformation * max_point)

    proj_min = projection(world_min, world_axis)
    proj_max = projection(world_max, world_axis)

    moving_is_max =
      if extension_sign.to_f >= 0.0
        proj_max >= proj_min
      else
        proj_max <= proj_min
      end

    anchor_value = moving_is_max ? local_min : local_max

    anchor =
      case axis_key
      when :x then Geom::Point3d.new(anchor_value, 0, 0)
      when :y then Geom::Point3d.new(0, anchor_value, 0)
      when :z then Geom::Point3d.new(0, 0, anchor_value)
      end

    factor = target_length.to_f / current_length

    sx = axis_key == :x ? factor : 1.0
    sy = axis_key == :y ? factor : 1.0
    sz = axis_key == :z ? factor : 1.0

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(anchor, sx, sy, sz)

    true
  rescue => error
    puts "MHD Set Part Length Error (#{part.name}): #{error.message}"
    false
  end

  def set_part_on_row_axis!(part, world_axis, extension_sign, target_length)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_length.to_f <= 0.000001

    make_unique!(part)

    axis_key, axis_world = axis_for_part(part, world_axis)
    return false unless axis_key && axis_world

    bounds = local_bounds(entity)

    local_min, local_max =
      case axis_key
      when :x then [bounds.min.x, bounds.max.x]
      when :y then [bounds.min.y, bounds.max.y]
      when :z then [bounds.min.z, bounds.max.z]
      end

    local_length = (local_max - local_min).abs
    return false if local_length <= 0.000001

    parent_world = part.world_tr * entity.transformation.inverse

    min_point =
      case axis_key
      when :x then Geom::Point3d.new(local_min, 0, 0)
      when :y then Geom::Point3d.new(0, local_min, 0)
      when :z then Geom::Point3d.new(0, 0, local_min)
      end

    max_point =
      case axis_key
      when :x then Geom::Point3d.new(local_max, 0, 0)
      when :y then Geom::Point3d.new(0, local_max, 0)
      when :z then Geom::Point3d.new(0, 0, local_max)
      end

    world_min = parent_world * (entity.transformation * min_point)
    world_max = parent_world * (entity.transformation * max_point)

    proj_min = projection(world_min, world_axis)
    proj_max = projection(world_max, world_axis)

    moving_is_max =
      if extension_sign.to_f >= 0.0
        proj_max >= proj_min
      else
        proj_max <= proj_min
      end

    anchor_value = moving_is_max ? local_min : local_max

    anchor =
      case axis_key
      when :x then Geom::Point3d.new(anchor_value, 0, 0)
      when :y then Geom::Point3d.new(0, anchor_value, 0)
      when :z then Geom::Point3d.new(0, 0, anchor_value)
      end

    current_world_length = (proj_max - proj_min).abs
    return false if current_world_length <= 0.000001

    factor = target_length.to_f / current_world_length

    sx = axis_key == :x ? factor : 1.0
    sy = axis_key == :y ? factor : 1.0
    sz = axis_key == :z ? factor : 1.0

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(anchor, sx, sy, sz)

    true
  rescue => error
    puts "MHD Set Base Row Axis Error (#{part.name}): #{error.message}"
    false
  end


  def part_length_on_world_axis(part, world_axis)
    entity = part.entity
    return nil unless entity && entity.valid?

    axis_key, axis_world = axis_for_part(part, world_axis)
    return nil unless axis_key && axis_world

    bounds = local_bounds(entity)
    local_min, local_max =
      case axis_key
      when :x then [bounds.min.x, bounds.max.x]
      when :y then [bounds.min.y, bounds.max.y]
      when :z then [bounds.min.z, bounds.max.z]
      end

    parent_world = part.world_tr * entity.transformation.inverse

    min_point =
      case axis_key
      when :x then Geom::Point3d.new(local_min, 0, 0)
      when :y then Geom::Point3d.new(0, local_min, 0)
      when :z then Geom::Point3d.new(0, 0, local_min)
      end

    max_point =
      case axis_key
      when :x then Geom::Point3d.new(local_max, 0, 0)
      when :y then Geom::Point3d.new(0, local_max, 0)
      when :z then Geom::Point3d.new(0, 0, local_max)
      end

    world_min = parent_world * (entity.transformation * min_point)
    world_max = parent_world * (entity.transformation * max_point)

    (projection(world_max, world_axis) - projection(world_min, world_axis)).abs
  rescue => error
    puts "MHD Shelf Length Read Error (#{part.name}): #{error.message}"
    nil
  end

  def set_rail_lenx!(part, target_length, world_axis, extension_sign)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_length.to_f <= 0.000001

    engine = dc
    return false unless engine

    parent_world =
      part.world_tr * entity.transformation.inverse

    old_length =
      begin
        engine.get_attribute_value(entity, "lenx").to_f
      rescue
        entity.get_attribute(DC_DICT, "lenx", 0.0).to_f
      end

    make_unique!(part)

    key = "lenx"

    value = target_length.to_f
    formula_value_cm = target_length.to_l.to_cm
    formula = formula_value_cm.to_s

    puts "MHD Rail LenX: #{part.name} => #{formula_value_cm.round(2)} cm"

    begin
      if engine.respond_to?(:set_attribute_formula)
        engine.set_attribute_formula(entity, key, formula)
      else
        entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      end
    rescue
      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
    end

    begin
      engine.set_attribute(entity, key, value)
    rescue
      entity.set_attribute(DC_DICT, key, value)
    end

    begin
      engine.set_forced_config_value(entity, key, value)
      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
      engine.clear_forced_config_values(entity)

      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
    rescue => refresh_error
      begin
        engine.clear_forced_config_values(entity)
      rescue
      end

      puts "MHD Rail LenX Refresh Error (#{part.name}): #{refresh_error.message}"
      return false
    end

    if extension_sign.to_f < 0.0
      delta = value - old_length

      if delta.abs > 0.000001
        world_move = Geom::Vector3d.new(
          -world_axis.x.to_f * delta,
          -world_axis.y.to_f * delta,
          -world_axis.z.to_f * delta
        )

        parent_move = world_move.transform(parent_world.inverse)

        entity.transform!(
          Geom::Transformation.translation(parent_move)
        )
      end
    end

    true
  rescue => error
    puts "MHD Rail LenX Error (#{part.name}): #{error.message}"
    false
  end

  def set_part_z_height!(part, target_height_cm, safe_no_redraw = false)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_height_cm.to_f <= 0.000001

    make_unique!(part)

    key = "lenz"
    value = target_height_cm.to_f.cm.to_f
    formula_value_cm = target_height_cm.to_f
    formula = formula_value_cm.to_s

    if safe_no_redraw
      bounds = local_bounds(entity)
      current_length =
        bounds.depth.to_f * entity.transformation.zaxis.length.to_f

      return false if current_length <= 0.000001

      puts "MHD Divider LenZ Drawer Safe: #{part.name} => #{formula_value_cm.round(2)} cm"

      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      entity.set_attribute(DC_DICT, key, value)
      entity.set_attribute(DC_DICT, "_last_#{key}", value)

      factor = value / current_length
      anchor = Geom::Point3d.new(0, 0, bounds.min.z)

      entity.transformation =
        entity.transformation *
        Geom::Transformation.scaling(anchor, 1.0, 1.0, factor)

      return true
    end

    engine = dc
    return false unless engine

    puts "MHD Divider LenZ: #{part.name} => #{formula_value_cm.round(2)} cm"

    begin
      if engine.respond_to?(:set_attribute_formula)
        engine.set_attribute_formula(entity, key, formula)
      else
        entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      end
    rescue
      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
    end

    begin
      engine.set_attribute(entity, key, value)
    rescue
      entity.set_attribute(DC_DICT, key, value)
    end

    begin
      engine.set_forced_config_value(entity, key, value)
      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
      engine.clear_forced_config_values(entity)

      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
    rescue => refresh_error
      begin
        engine.clear_forced_config_values(entity)
      rescue
      end

      puts "MHD Divider LenZ Refresh Error (#{part.name}): #{refresh_error.message}"
      return false
    end

    true
  rescue => error
    puts "MHD Divider LenZ Error (#{part.name}): #{error.message}"
    false
  end

  def set_part_y_depth!(part, target_depth_cm, safe_no_redraw = false)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_depth_cm.to_f <= 0.000001

    make_unique!(part)

    key = "leny"
    value = target_depth_cm.to_f.cm.to_f
    formula_value_cm = target_depth_cm.to_f
    formula = formula_value_cm.to_s

    if safe_no_redraw
      bounds = local_bounds(entity)
      current_length =
        bounds.height.to_f * entity.transformation.yaxis.length.to_f

      return false if current_length <= 0.000001

      puts "MHD Divider LenY Drawer Safe: #{part.name} => #{formula_value_cm.round(2)} cm"

      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      entity.set_attribute(DC_DICT, key, value)
      entity.set_attribute(DC_DICT, "_last_#{key}", value)

      factor = value / current_length
      anchor = Geom::Point3d.new(0, bounds.min.y, 0)

      entity.transformation =
        entity.transformation *
        Geom::Transformation.scaling(anchor, 1.0, factor, 1.0)

      return true
    end

    engine = dc
    return false unless engine

    puts "MHD Divider LenY: #{part.name} => #{formula_value_cm.round(2)} cm"

    begin
      if engine.respond_to?(:set_attribute_formula)
        engine.set_attribute_formula(entity, key, formula)
      else
        entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      end
    rescue
      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
    end

    begin
      engine.set_attribute(entity, key, value)
    rescue
      entity.set_attribute(DC_DICT, key, value)
    end

    begin
      engine.set_forced_config_value(entity, key, value)
      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
      engine.clear_forced_config_values(entity)

      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
    rescue => refresh_error
      begin
        engine.clear_forced_config_values(entity)
      rescue
      end

      puts "MHD Divider LenY Refresh Error (#{part.name}): #{refresh_error.message}"
      return false
    end

    true
  rescue => error
    puts "MHD Divider LenY Error (#{part.name}): #{error.message}"
    false
  end

  def set_base_safe!(part, target_length, target_x_cm, world_axis, extension_sign, geometry_shift_cm = nil)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_length.to_f <= 0.000001

    engine = dc

    current_x =
      begin
        engine ? engine.get_attribute_value(entity, "x").to_f : entity.get_attribute(DC_DICT, "x", 0.0).to_f
      rescue
        entity.get_attribute(DC_DICT, "x", 0.0).to_f
      end

    make_unique!(part)

    unless set_part_on_row_axis!(
      part,
      world_axis,
      extension_sign,
      target_length
    )
      return false
    end

    target_x = target_x_cm.to_f.cm.to_f

    delta_x =
      if geometry_shift_cm.nil?
        target_x - current_x
      else
        geometry_shift_cm.to_f.cm.to_f
      end

    if delta_x.abs > 0.000001
      move_vector = Geom::Vector3d.new(
        world_axis.x.to_f * delta_x,
        world_axis.y.to_f * delta_x,
        world_axis.z.to_f * delta_x
      )

      return false unless translate_part_in_world!(part, move_vector)
    end

    lenx_formula_cm = target_length.to_l.to_cm

    begin
      if engine && engine.respond_to?(:set_attribute_formula)
        engine.set_attribute_formula(entity, "lenx", lenx_formula_cm.to_s)
        engine.set_attribute_formula(entity, "x", target_x_cm.to_f.to_s)
      else
        entity.set_attribute(DC_DICT, "_lenx_formula", lenx_formula_cm.to_s)
        entity.set_attribute(DC_DICT, "_x_formula", target_x_cm.to_f.to_s)
      end
    rescue
      entity.set_attribute(DC_DICT, "_lenx_formula", lenx_formula_cm.to_s)
      entity.set_attribute(DC_DICT, "_x_formula", target_x_cm.to_f.to_s)
    end

    begin
      if engine
        engine.set_attribute(entity, "lenx", target_length.to_f)
        engine.set_attribute(entity, "x", target_x)
      else
        entity.set_attribute(DC_DICT, "lenx", target_length.to_f)
        entity.set_attribute(DC_DICT, "x", target_x)
      end
    rescue
      entity.set_attribute(DC_DICT, "lenx", target_length.to_f)
      entity.set_attribute(DC_DICT, "x", target_x)
    end

    puts "MHD Base Safe LenX: #{part.name} => #{lenx_formula_cm.round(2)} cm"
    puts "MHD Base Safe Position X: #{part.name} => #{target_x_cm.to_f.round(2)} cm"

    true
  rescue => error
    puts "MHD Base Safe Error (#{part.name}): #{error.message}"
    false
  end

  def set_back_safe!(
    part,
    target_lenx,
    target_lenz_cm,
    target_x_cm,
    target_z_cm,
    world_axis,
    extension_sign,
    geometry_x_shift_cm = nil
  )
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_lenx.to_f <= 0.000001
    return false if target_lenz_cm.to_f <= 0.000001

    engine = dc

    current_x =
      begin
        engine ? engine.get_attribute_value(entity, "x").to_f :
          entity.get_attribute(DC_DICT, "x", 0.0).to_f
      rescue
        entity.get_attribute(DC_DICT, "x", 0.0).to_f
      end

    current_z =
      begin
        engine ? engine.get_attribute_value(entity, "z").to_f :
          entity.get_attribute(DC_DICT, "z", 0.0).to_f
      rescue
        entity.get_attribute(DC_DICT, "z", 0.0).to_f
      end

    make_unique!(part)

    unless set_part_on_row_axis!(
      part,
      world_axis,
      extension_sign,
      target_lenx
    )
      return false
    end

    bounds = local_bounds(entity)
    current_height =
      bounds.depth.to_f * entity.transformation.zaxis.length.to_f

    return false if current_height <= 0.000001

    target_lenz = target_lenz_cm.to_f.cm.to_f
    height_factor = target_lenz / current_height
    z_anchor = Geom::Point3d.new(0, 0, bounds.min.z)

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(z_anchor, 1.0, 1.0, height_factor)

    target_x = target_x_cm.to_f.cm.to_f

    delta_x =
      if geometry_x_shift_cm.nil?
        target_x - current_x
      else
        geometry_x_shift_cm.to_f.cm.to_f
      end

    if delta_x.abs > 0.000001
      x_vector = Geom::Vector3d.new(
        world_axis.x.to_f * delta_x,
        world_axis.y.to_f * delta_x,
        world_axis.z.to_f * delta_x
      )

      return false unless translate_part_in_world!(part, x_vector)
    end

    target_z = target_z_cm.to_f.cm.to_f
    delta_z = target_z - current_z

    if delta_z.abs > 0.000001
      parent_world = part.world_tr * entity.transformation.inverse
      z_axis_world = normalized_axis(parent_world.zaxis)
      return false unless z_axis_world

      z_vector = Geom::Vector3d.new(
        z_axis_world.x.to_f * delta_z,
        z_axis_world.y.to_f * delta_z,
        z_axis_world.z.to_f * delta_z
      )

      return false unless translate_part_in_world!(part, z_vector)
    end

    lenx_cm = target_lenx.to_l.to_cm
    formulas = {
      "lenx" => lenx_cm.to_s,
      "lenz" => target_lenz_cm.to_f.to_s,
      "x"    => target_x_cm.to_f.to_s,
      "z"    => target_z_cm.to_f.to_s
    }

    values = {
      "lenx" => target_lenx.to_f,
      "lenz" => target_lenz,
      "x"    => target_x,
      "z"    => target_z
    }

    formulas.each do |key, formula|
      begin
        if engine && engine.respond_to?(:set_attribute_formula)
          engine.set_attribute_formula(entity, key, formula)
        else
          entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
        end
      rescue
        entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      end
    end

    values.each do |key, value|
      begin
        if engine
          engine.set_attribute(entity, key, value)
        else
          entity.set_attribute(DC_DICT, key, value)
        end
      rescue
        entity.set_attribute(DC_DICT, key, value)
      end

      entity.set_attribute(DC_DICT, "_last_#{key}", value)
    end

    puts "MHD Back Safe LenX: #{part.name} => #{lenx_cm.round(2)} cm"
    puts "MHD Back Safe LenZ: #{part.name} => #{target_lenz_cm.to_f.round(2)} cm"
    puts "MHD Back Safe Position X: #{part.name} => #{target_x_cm.to_f.round(2)} cm"
    puts "MHD Back Safe Position Z: #{part.name} => #{target_z_cm.to_f.round(2)} cm"

    true
  rescue => error
    puts "MHD Back Safe Error (#{part.name}): #{error.message}"
    false
  end

  def add_part_position_z!(part, amount_cm)
    entity = part.entity
    return false unless entity && entity.valid?
    return true if amount_cm.to_f.abs <= 0.000001

    engine = dc
    return false unless engine

    make_unique!(part)

    key = "z"
    old_value = begin
      engine.get_attribute_value(entity, key).to_f
    rescue
      entity.get_attribute(DC_DICT, key, 0.0).to_f
    end

    target_value = old_value + amount_cm.to_f.cm.to_f
    target_cm = target_value.to_l.to_cm
    formula = target_cm.to_s

    puts "MHD Divider Position Z: #{part.name} => #{target_cm.round(2)} cm"

    begin
      if engine.respond_to?(:set_attribute_formula)
        engine.set_attribute_formula(entity, key, formula)
      else
        entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
      end
    rescue
      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
    end

    begin
      engine.set_attribute(entity, key, target_value)
    rescue
      entity.set_attribute(DC_DICT, key, target_value)
    end

    begin
      engine.set_forced_config_value(entity, key, target_value)
      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
      engine.clear_forced_config_values(entity)

      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
    rescue => refresh_error
      begin
        engine.clear_forced_config_values(entity)
      rescue
      end

      puts "MHD Divider Position Z Refresh Error (#{part.name}): #{refresh_error.message}"
      return false
    end

    true
  rescue => error
    puts "MHD Divider Position Z Error (#{part.name}): #{error.message}"
    false
  end

  def shorten_from_back!(part, world_depth_axis, amount_cm)
    entity = part.entity
    return false unless entity && entity.valid?

    amount = amount_cm.to_f.cm.to_f
    return true if amount <= 0.000001

    make_unique!(part)

    axis_key, axis_world = axis_for_part(part, world_depth_axis)
    return false unless axis_key && axis_world

    bounds = local_bounds(entity)

    local_min, local_max =
      case axis_key
      when :x then [bounds.min.x, bounds.max.x]
      when :y then [bounds.min.y, bounds.max.y]
      when :z then [bounds.min.z, bounds.max.z]
      end

    local_length = (local_max - local_min).abs
    return false if local_length <= 0.000001

    parent_world = part.world_tr * entity.transformation.inverse

    min_point =
      case axis_key
      when :x then Geom::Point3d.new(local_min, 0, 0)
      when :y then Geom::Point3d.new(0, local_min, 0)
      when :z then Geom::Point3d.new(0, 0, local_min)
      end

    max_point =
      case axis_key
      when :x then Geom::Point3d.new(local_max, 0, 0)
      when :y then Geom::Point3d.new(0, local_max, 0)
      when :z then Geom::Point3d.new(0, 0, local_max)
      end

    world_min = parent_world * (entity.transformation * min_point)
    world_max = parent_world * (entity.transformation * max_point)

    proj_min = projection(world_min, world_depth_axis)
    proj_max = projection(world_max, world_depth_axis)

    back_is_max = proj_max >= proj_min
    anchor_value = back_is_max ? local_min : local_max

    current_world_length = (proj_max - proj_min).abs
    return false if current_world_length <= amount

    factor = (current_world_length - amount) / current_world_length

    anchor =
      case axis_key
      when :x then Geom::Point3d.new(anchor_value, 0, 0)
      when :y then Geom::Point3d.new(0, anchor_value, 0)
      when :z then Geom::Point3d.new(0, 0, anchor_value)
      end

    sx = axis_key == :x ? factor : 1.0
    sy = axis_key == :y ? factor : 1.0
    sz = axis_key == :z ? factor : 1.0

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(anchor, sx, sy, sz)

    true
  rescue => error
    puts "MHD Divider Depth Error (#{part.name}): #{error.message}"
    false
  end

  def translate_part_in_world!(part, world_vector)
    entity = part.entity
    return false unless entity && entity.valid?

    make_unique!(part)

    parent_world = part.world_tr * entity.transformation.inverse
    parent_vector = world_vector.transform(parent_world.inverse)

    entity.transform!(Geom::Transformation.translation(parent_vector))
    true
  rescue => error
    puts "MHD Part Translation Error (#{part.name}): #{error.message}"
    false
  end

  def html_escape(text)
    text.to_s
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub('"', "&quot;")
        .gsub("'", "&#39;")
  end

  def saved_merged_unit_name
    value = Sketchup.read_default(
      MERGE_PREF_KEY,
      "merged_unit_name",
      DEFAULT_MERGED_NAME
    ).to_s.strip

    value.empty? ? DEFAULT_MERGED_NAME : value
  rescue
    DEFAULT_MERGED_NAME
  end

  def save_merged_unit_name(value)
    Sketchup.write_default(
      MERGE_PREF_KEY,
      "merged_unit_name",
      value.to_s
    )
  rescue
  end

  def merge_dialog_html(default_name)
    safe_name = html_escape(default_name)

    <<~HTML
      <!DOCTYPE html>
      <html lang="#{MHDESIGN_UI_LANG.current}" dir="#{MHDESIGN_UI_LANG.direction}">
      <head>
        <meta charset="UTF-8">
        <title>MHDESIGN - دمج الوحدات</title>
        <style>
          *{box-sizing:border-box}
          body{
            margin:0;
            font-family:Arial,Tahoma,sans-serif;
            background:#07131d;
            color:#eaf4f8;
            overflow:hidden;
          }
          ::-webkit-scrollbar{width:8px}
          ::-webkit-scrollbar-track{background:#07131d}
          ::-webkit-scrollbar-thumb{
            background:#1d3444;
            border-radius:20px;
            border:2px solid #07131d;
          }
          .app{
            height:100vh;
            display:flex;
            flex-direction:column;
            background:#07131d;
          }
          .hero{
            height:78px;
            padding:10px 12px;
            display:flex;
            align-items:center;
            gap:10px;
            background:linear-gradient(135deg,#07131d,#0c2230);
            border-bottom:1px solid #1c3342;
          }
          .logo{
            width:58px;
            height:58px;
            object-fit:contain;
            background:#081722;
            border:1px solid #1c3342;
            border-radius:10px;
            padding:5px;
            flex:0 0 auto;
          }
          .head-text{flex:1;text-align:center;overflow:hidden}
          .title-main{
            font-size:19px;
            font-weight:900;
            color:#fff;
            white-space:nowrap;
          }
          .subtitle{
            margin-top:6px;
            font-size:11px;
            line-height:1.5;
            color:#9fb6c5;
          }
          .wrap{
            height:calc(100vh - 78px - 62px);
            overflow:auto;
            padding:10px;
          }
          .group{
            background:#0b1b27;
            border:1px solid #1c3342;
            border-radius:10px;
            margin-bottom:10px;
            overflow:hidden;
          }
          .group-title{
            padding:9px 10px;
            background:#0f2433;
            color:#4de37a;
            font-size:15px;
            font-weight:900;
            border-bottom:1px solid #1c3342;
          }
          .group-body{padding:10px}
          .field-row{
            display:grid;
            grid-template-columns:112px 1fr;
            gap:8px;
            align-items:center;
            margin-bottom:8px;
          }
          .field-row:last-child{margin-bottom:0}
          label{
            font-size:13px;
            font-weight:900;
            color:#d8e8ef;
            line-height:1.4;
          }
          input[type=text],select{
            width:100%;
            height:34px;
            padding:5px 9px;
            border:none;
            border-radius:7px;
            background:#111f2a;
            color:#fff;
            font-size:13px;
            outline:1px solid #243d4f;
            text-align:center;
          }
          input[type=text]:focus,select:focus{
            outline:2px solid #39a245;
            background:#0d1b25;
          }
          select{cursor:pointer}
          .confirm-box{
            min-height:42px;
            background:#111f2a;
            border:1px solid #243d4f;
            border-radius:8px;
            padding:7px 9px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap:8px;
            cursor:pointer;
            user-select:none;
          }
          .confirm-box:hover{border-color:#39a245}
          .confirm-text{
            display:flex;
            flex-direction:column;
            gap:3px;
          }
          .confirm-title{
            font-size:13px;
            font-weight:900;
            color:#fff;
          }
          .confirm-value{
            font-size:12px;
            color:#9fb6c5;
          }
          .switch{
            width:42px;
            height:23px;
            border-radius:20px;
            background:#314b5c;
            padding:3px;
            transition:.18s;
            flex:0 0 auto;
          }
          .switch-dot{
            width:17px;
            height:17px;
            border-radius:50%;
            background:#d4e2e8;
            transition:.18s;
          }
          .confirm-box.on .switch{background:#39a245}
          .confirm-box.on .switch-dot{transform:translateX(-19px);background:#fff}
          .note{
            background:#091923;
            border:1px solid #193245;
            border-radius:8px;
            color:#9fb6c5;
            font-size:11px;
            line-height:1.7;
            padding:8px 9px;
          }
          .error{
            display:none;
            margin-top:8px;
            padding:7px 9px;
            border-radius:7px;
            background:#3a171b;
            border:1px solid #7a2a31;
            color:#ffd9dc;
            font-size:12px;
            line-height:1.5;
          }
          .footer{
            height:62px;
            padding:9px 10px;
            border-top:1px solid #1c3342;
            display:flex;
            gap:8px;
          }
          button{
            height:42px;
            border-radius:10px;
            font-size:14px;
            font-weight:900;
            cursor:pointer;
            border:none;
          }
          .ok{flex:2;background:#4de37a;color:#061923}
          .cancel{
            flex:1;
            background:#0b1b27;
            color:#fff;
            border:1px solid #243d4f;
          }
        </style>
      </head>
      <body>
        <div class="app">
          <div class="hero">
            <img class="logo" src="#{MERGE_LOGO_URL}">
            <div class="head-text">
              <div class="title-main">دمج الوحدات</div>
              <div class="subtitle">
                إنشاء وحدة واحدة جاهزة للتصنيع<br>
                MHDESIGN Merge Engine
              </div>
            </div>
          </div>

          <div class="wrap">
            <div class="group">
              <div class="group-title">▼ بيانات الوحدة الجديدة</div>
              <div class="group-body">
                <div class="field-row">
                  <label for="unit_name">اسم الوحدة</label>
                  <input
                    id="unit_name"
                    type="text"
                    maxlength="80"
                    value="#{safe_name}"
                    placeholder="مثال: وحدة حوض مدموجة"
                  >
                </div>
                <div class="field-row">
                  <label for="merge_type">نوع الدمج</label>
                  <select id="merge_type">
                    <option value="horizontal">أفقي — الوحدات جنب بعض</option>
                    <option value="vertical">رأسي — الوحدات فوق بعض</option>
                  </select>
                </div>
              </div>
            </div>

            <div class="group">
              <div class="group-title">▼ تأكيد المقاسات</div>
              <div class="group-body">
                <div
                  id="thickness_confirm"
                  class="confirm-box"
                  onclick="toggleConfirm()"
                >
                  <div class="confirm-text">
                    <div class="confirm-title">تأكيد تخانة الشاسيه</div>
                    <div class="confirm-value">
                      #{CONFIRMED_CHASSIS_THICKNESS_CM} سم
                    </div>
                  </div>
                  <div class="switch"><div class="switch-dot"></div></div>
                </div>

                <div id="error_box" class="error"></div>
              </div>
            </div>

          </div>

          <div class="footer">
            <button class="ok" onclick="submitMerge()">تنفيذ الدمج</button>
            <button class="cancel" onclick="sketchup.cancel()">إلغاء</button>
          </div>
        </div>

        <script>
          document.addEventListener('contextmenu', function(event){
            event.preventDefault();
          });

          document.addEventListener('dragstart', function(event){
            event.preventDefault();
          });

          function toggleConfirm(){
            document
              .getElementById('thickness_confirm')
              .classList
              .toggle('on');

            document.getElementById('error_box').style.display = 'none';
          }

          function showError(message){
            const box = document.getElementById('error_box');
            box.textContent = message;
            box.style.display = 'block';
          }

          function submitMerge(){
            const unitName =
              document.getElementById('unit_name').value.trim();

            const confirmed =
              document
                .getElementById('thickness_confirm')
                .classList
                .contains('on');

            if(!unitName){
              showError('اكتب اسم الوحدة أولاً.');
              return;
            }

            if(!confirmed){
              showError(
                'يجب تأكيد أن تخانة الشاسيه #{CONFIRMED_CHASSIS_THICKNESS_CM} سم.'
              );
              return;
            }

            const mergeType =
              document.getElementById('merge_type').value;

            sketchup.submit(JSON.stringify({
              unit_name: unitName,
              merge_type: mergeType,
              chassis_thickness_confirmed: true
            }));
          }
        </script>
      
<script>
(function(){
  const MHD_L10N = #{MHDESIGN_UI_LANG.payload_json};
  const TEXTS = MHD_L10N.texts || {};
  const MAP = MHD_L10N.source_map || {};

  function translateKey(key, fallback){
    const value = TEXTS[String(key || '')];
    return value == null || String(value).trim() === ''
      ? String(fallback == null ? key : fallback)
      : String(value);
  }

  function translateText(value){
    if(!value) return value || '';
    if(Object.prototype.hasOwnProperty.call(MAP, value)) return String(MAP[value]);

    let result = value;
    Object.keys(MAP)
      .sort((a,b)=>b.length-a.length)
      .forEach((key)=>{
        if(key) result = result.split(key).join(MAP[key]);
      });
    return result;
  }

  window.MHD_LT = translateText;
  document.documentElement.lang = MHD_L10N.locale || 'ar_EG';
  document.documentElement.dir = MHD_L10N.direction || 'rtl';

  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const nodes = [];
  while(walker.nextNode()) nodes.push(walker.currentNode);

  nodes.forEach((node)=>{
    const raw = node.nodeValue || '';
    if(!raw.trim()) return;
    const lead = (raw.match(/^\s*/) || [''])[0];
    const tail = (raw.match(/\s*$/) || [''])[0];
    const core = raw.slice(lead.length, raw.length-tail.length);
    node.nodeValue = lead + translateText(core) + tail;
  });

  document.querySelectorAll('[placeholder]').forEach((el)=>{
    el.placeholder = translateText(el.placeholder);
  });
  document.querySelectorAll('[title]').forEach((el)=>{
    el.title = translateText(el.title);
  });
})();
</script>

</body>
      </html>
    HTML
  end

  def show_merge_dialog(units)
    dialog = UI::HtmlDialog.new(
      dialog_title: MHDESIGN_UI_LANG.t("MHDESIGN - دمج الوحدات"),
      preferences_key: MERGE_PREF_KEY,
      scrollable: false,
      resizable: true,
      width: 360,
      height: 540,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    dialog.set_html(
      merge_dialog_html(saved_merged_unit_name)
    )

    dialog.add_action_callback("cancel") do
      dialog.close
    end

    dialog.add_action_callback("submit") do |_context, json|
      begin
        data = JSON.parse(json.to_s)
        unit_name = data["unit_name"].to_s.strip
        confirmed = data["chassis_thickness_confirmed"] == true

        if unit_name.empty?
          MHDESIGN_UI_LANG.messagebox("اكتب اسم الوحدة أولاً.")
          next
        end

        unless confirmed
          MHDESIGN_UI_LANG.messagebox(
            "يجب تأكيد تخانة الشاسيه #{CONFIRMED_CHASSIS_THICKNESS_CM} سم."
          )
          next
        end

        save_merged_unit_name(unit_name)
        dialog.close

        merge_type = data["merge_type"].to_s
        merge_type = "horizontal" unless %w[horizontal vertical].include?(merge_type)

        run(
          {
            "unit_name" => unit_name,
            "merge_type" => merge_type,
            "chassis_thickness_confirmed" => true
          },
          units
        )
      rescue => error
        MHDESIGN_UI_LANG.messagebox(
          "تعذر قراءة بيانات واجهة الدمج:\n#{error.message}"
        )
      end
    end

    dialog.show
    nil
  end

  def replace_unit_name_in_parentheses(text, unit_name)
    text.to_s.gsub(/\(([^()]*)\)/) do
      "(#{unit_name})"
    end
  end

  def remove_unique_hash_suffix(text)
    text.to_s
        .gsub(/\s*#\s*\d+\b/, "")
        .gsub(/\s+/, " ")
        .strip
  end

  def rename_merged_parts!(root, unit_name)
    visited = {}

    walk = lambda do |entity|
      return unless entity && entity.valid?

      if entity.is_a?(Sketchup::ComponentInstance) &&
         entity.respond_to?(:make_unique)
        entity.make_unique
      end

      entity_key =
        entity.respond_to?(:persistent_id) ?
          entity.persistent_id :
          entity.object_id

      return if visited[entity_key]
      visited[entity_key] = true

      if entity.respond_to?(:name)
        old_instance_name = entity.name.to_s
        new_instance_name =
          remove_unique_hash_suffix(
            replace_unit_name_in_parentheses(
              old_instance_name,
              unit_name
            )
          )

        entity.name = new_instance_name
      end

      if entity.is_a?(Sketchup::ComponentInstance)
        definition = entity.definition
        old_definition_name = definition.name.to_s
        new_definition_name =
          remove_unique_hash_suffix(
            replace_unit_name_in_parentheses(
              old_definition_name,
              unit_name
            )
          )

        definition.name = new_definition_name
      end

      effective_name =
        remove_unique_hash_suffix(
          if entity.respond_to?(:name) && !entity.name.to_s.empty?
            entity.name.to_s
          elsif entity.respond_to?(:definition)
            entity.definition.name.to_s
          else
            unit_name.to_s
          end
        )

      if entity.respond_to?(:set_attribute)
        entity.set_attribute(
          DC_DICT,
          "name",
          effective_name
        )
      end

      if entity.is_a?(Sketchup::ComponentInstance)
        entity.definition.set_attribute(
          DC_DICT,
          "name",
          entity.definition.name.to_s
        )
      end

      children =
        if entity.is_a?(Sketchup::Group)
          entity.entities
        elsif entity.respond_to?(:definition)
          entity.definition.entities
        end

      return unless children

      children.to_a.each do |child|
        next unless child.is_a?(Sketchup::ComponentInstance) ||
                    child.is_a?(Sketchup::Group)

        walk.call(child)
      end
    end

    walk.call(root)
    true
  rescue => error
    puts "MHD Rename Merged Parts Error: #{error.message}"
    false
  end

  def create_merged_dynamic_component!(
    model,
    primary,
    secondary,
    unit_name
  )
    entities = model.active_entities

    unless primary.valid? && secondary.valid?
      raise "تعذر إنشاء الوحدة المدموجة لأن إحدى الوحدتين لم تعد صالحة."
    end

    group = entities.add_group([primary, secondary])
    clean_unit_name = remove_unique_hash_suffix(unit_name)
    group.name = clean_unit_name

    merged = group.to_component
    merged.name = clean_unit_name
    merged.definition.name = clean_unit_name

    merged.definition.set_attribute(DC_DICT, "_formatversion", 1.0)
    merged.definition.set_attribute(DC_DICT, "_hasbehaviors", 1.0)
    merged.definition.set_attribute(DC_DICT, "_lengthunits", "CENTIMETERS")
    merged.definition.set_attribute(DC_DICT, "name", clean_unit_name)

    merged.set_attribute(DC_DICT, "_formatversion", 1.0)
    merged.set_attribute(DC_DICT, "_hasbehaviors", 1.0)
    merged.set_attribute(DC_DICT, "name", clean_unit_name)

    merged.set_attribute(
      "MHD_MERGE",
      "unit_name",
      clean_unit_name
    )
    merged.set_attribute(
      "MHD_MERGE",
      "chassis_thickness_cm",
      CONFIRMED_CHASSIS_THICKNESS_CM
    )
    merged.set_attribute(
      "MHD_MERGE",
      "created_at",
      Time.now.strftime("%Y-%m-%d %H:%M")
    )

    rename_merged_parts!(merged, clean_unit_name)

    model.selection.clear
    model.selection.add(merged)

    puts "MHD Merged Dynamic Component: #{clean_unit_name}"
    merged
  end


  def column_info(unit_a, unit_b)
    x1 = normalized_axis(unit_a.transformation.xaxis)
    y1 = normalized_axis(unit_a.transformation.yaxis)
    z1 = normalized_axis(unit_a.transformation.zaxis)

    x2 = normalized_axis(unit_b.transformation.xaxis)
    y2 = normalized_axis(unit_b.transformation.yaxis)
    z2 = normalized_axis(unit_b.transformation.zaxis)

    return nil unless [x1, y1, z1, x2, y2, z2].all?
    return nil unless x1.dot(x2) >= DIRECTION_DOT
    return nil unless y1.dot(y2) >= DIRECTION_DOT
    return nil unless z1.dot(z2) >= DIRECTION_DOT

    range_a = bounds_range(unit_a, z1)
    range_b = bounds_range(unit_b, z1)

    lower, upper =
      range_a[0] <= range_b[0] ? [unit_a, unit_b] : [unit_b, unit_a]

    {
      axis: z1,
      lower: lower,
      upper: upper,
      range_a: range_a,
      range_b: range_b
    }
  rescue
    nil
  end

  def validate_vertical_units(unit_a, unit_b)
    width_a = find_dc_value_cm(unit_a, WIDTH_LABELS)
    width_b = find_dc_value_cm(unit_b, WIDTH_LABELS)
    depth_a = find_dc_value_cm(unit_a, DEPTH_LABELS)
    depth_b = find_dc_value_cm(unit_b, DEPTH_LABELS)

    errors = []

    if width_a && width_b && (width_a - width_b).abs > TOLERANCE_CM
      errors << "العرض مختلف: #{width_a.round(2)} / #{width_b.round(2)} سم"
    end

    if depth_a && depth_b && (depth_a - depth_b).abs > TOLERANCE_CM
      errors << "العمق مختلف: #{depth_a.round(2)} / #{depth_b.round(2)} سم"
    end

    errors
  end

  def extend_upper_side_down!(
    part,
    target_height_cm,
    lower_height_cm
  )
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_height_cm.to_f <= 0.000001

    engine = dc

    old_z =
      begin
        engine ? engine.get_attribute_value(entity, "z").to_f :
          entity.get_attribute(DC_DICT, "z", 0.0).to_f
      rescue
        entity.get_attribute(DC_DICT, "z", 0.0).to_f
      end

    make_unique!(part)

    bounds = local_bounds(entity)
    current_height =
      bounds.depth.to_f * entity.transformation.zaxis.length.to_f

    return false if current_height <= 0.000001

    target_height = target_height_cm.to_f.cm.to_f
    factor = target_height / current_height

    anchor = Geom::Point3d.new(0, 0, bounds.max.z)

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(anchor, 1.0, 1.0, factor)

    target_z = old_z - lower_height_cm.to_f.cm.to_f

    entity.set_attribute(DC_DICT, "_lenz_formula", target_height_cm.to_f.to_s)
    entity.set_attribute(DC_DICT, "lenz", target_height)
    entity.set_attribute(DC_DICT, "_last_lenz", target_height)

    entity.set_attribute(
      DC_DICT,
      "_z_formula",
      target_z.to_l.to_cm.to_s
    )
    entity.set_attribute(DC_DICT, "z", target_z)
    entity.set_attribute(DC_DICT, "_last_z", target_z)

    puts "MHD Vertical Side LenZ: #{part.name} => #{target_height_cm.to_f.round(2)} cm"
    puts "MHD Vertical Side Position Z: #{part.name} => #{target_z.to_l.to_cm.round(2)} cm"

    true
  rescue => error
    puts "MHD Vertical Side Error (#{part.name}): #{error.message}"
    false
  end

  def set_vertical_back_safe!(
    part,
    target_lenx_cm,
    target_lenz_cm,
    target_x_cm,
    target_z_cm,
    lower_height_cm,
    world_x_axis
  )
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_lenx_cm.to_f <= 0.000001
    return false if target_lenz_cm.to_f <= 0.000001

    engine = dc

    current_x =
      begin
        engine ? engine.get_attribute_value(entity, "x").to_f :
          entity.get_attribute(DC_DICT, "x", 0.0).to_f
      rescue
        entity.get_attribute(DC_DICT, "x", 0.0).to_f
      end

    current_z =
      begin
        engine ? engine.get_attribute_value(entity, "z").to_f :
          entity.get_attribute(DC_DICT, "z", 0.0).to_f
      rescue
        entity.get_attribute(DC_DICT, "z", 0.0).to_f
      end

    make_unique!(part)

    target_lenx = target_lenx_cm.to_f.cm.to_f

    unless set_part_on_row_axis!(
      part,
      world_x_axis,
      1.0,
      target_lenx
    )
      return false
    end

    bounds = local_bounds(entity)
    current_height =
      bounds.depth.to_f * entity.transformation.zaxis.length.to_f

    return false if current_height <= 0.000001

    target_lenz = target_lenz_cm.to_f.cm.to_f
    height_factor = target_lenz / current_height

    z_anchor = Geom::Point3d.new(0, 0, bounds.max.z)

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(
        z_anchor,
        1.0,
        1.0,
        height_factor
      )

    target_x = target_x_cm.to_f.cm.to_f
    delta_x = target_x - current_x

    if delta_x.abs > 0.000001
      x_vector = Geom::Vector3d.new(
        world_x_axis.x.to_f * delta_x,
        world_x_axis.y.to_f * delta_x,
        world_x_axis.z.to_f * delta_x
      )

      return false unless translate_part_in_world!(part, x_vector)
    end

    target_z =
      target_z_cm.to_f.cm.to_f -
      lower_height_cm.to_f.cm.to_f

    delta_z = target_z - current_z

    if delta_z.abs > 0.000001
      parent_world = part.world_tr * entity.transformation.inverse
      z_axis_world = normalized_axis(parent_world.zaxis)
      return false unless z_axis_world

      z_vector = Geom::Vector3d.new(
        z_axis_world.x.to_f * delta_z,
        z_axis_world.y.to_f * delta_z,
        z_axis_world.z.to_f * delta_z
      )

      return false unless translate_part_in_world!(part, z_vector)
    end

    formulas = {
      "lenx" => target_lenx_cm.to_f.to_s,
      "lenz" => target_lenz_cm.to_f.to_s,
      "x"    => target_x_cm.to_f.to_s,
      "z"    => target_z.to_l.to_cm.to_s
    }

    values = {
      "lenx" => target_lenx,
      "lenz" => target_lenz,
      "x"    => target_x,
      "z"    => target_z
    }

    formulas.each do |key, formula|
      entity.set_attribute(DC_DICT, "_#{key}_formula", formula)
    end

    values.each do |key, value|
      entity.set_attribute(DC_DICT, key, value)
      entity.set_attribute(DC_DICT, "_last_#{key}", value)
    end

    puts "MHD Vertical Back LenX: #{part.name} => #{target_lenx_cm.to_f.round(2)} cm"
    puts "MHD Vertical Back LenZ: #{part.name} => #{target_lenz_cm.to_f.round(2)} cm"
    puts "MHD Vertical Back Position X: #{part.name} => #{target_x_cm.to_f.round(2)} cm"
    puts "MHD Vertical Back Position Z: #{part.name} => #{target_z.to_l.to_cm.round(2)} cm"

    true
  rescue => error
    puts "MHD Vertical Back Error (#{part.name}): #{error.message}"
    false
  end

  def set_vertical_lower_side_height!(part, target_height_cm)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_height_cm.to_f <= 0.000001

    make_unique!(part)

    bounds = local_bounds(entity)
    local_height = bounds.depth.to_f
    return false if local_height <= 0.000001

    current_world_height =
      local_height * part.world_tr.zaxis.length.to_f

    return false if current_world_height <= 0.000001

    target_world_height = target_height_cm.to_f.cm.to_f
    factor = target_world_height / current_world_height

    anchor = Geom::Point3d.new(0, 0, bounds.min.z)

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(anchor, 1.0, 1.0, factor)

    entity.set_attribute(
      DC_DICT,
      "_lenz_formula",
      target_height_cm.to_f.to_s
    )
    entity.set_attribute(
      DC_DICT,
      "lenz",
      target_world_height
    )
    entity.set_attribute(
      DC_DICT,
      "_last_lenz",
      target_world_height
    )

    updated_world_height =
      local_height *
      (part.world_tr.zaxis.length.to_f * factor)

    puts "MHD Vertical Lower Side LenZ: #{part.name} => #{target_height_cm.to_f.round(2)} cm"
    puts "MHD Vertical Lower Side Visual Height: #{part.name} => #{updated_world_height.to_l.to_cm.round(2)} cm"

    true
  rescue => error
    puts "MHD Vertical Lower Side Error (#{part.name}): #{error.message}"
    false
  end

  def set_vertical_back_dimensions!(
    part,
    target_lenx_cm,
    target_lenz_cm,
    target_x_cm,
    target_z_cm,
    world_x_axis,
    safe_no_redraw = false
  )
    if safe_no_redraw
      return set_back_safe!(
        part,
        target_lenx_cm.to_f.cm.to_f,
        target_lenz_cm,
        target_x_cm,
        target_z_cm,
        world_x_axis,
        1.0,
        nil
      )
    end

    entity = part.entity
    return false unless entity && entity.valid?

    engine = dc
    return false unless engine

    make_unique!(part)

    cm_values = {
      "lenx" => target_lenx_cm.to_f,
      "lenz" => target_lenz_cm.to_f,
      "x"    => target_x_cm.to_f,
      "z"    => target_z_cm.to_f
    }

    inch_values = {
      "lenx" => target_lenx_cm.to_f.cm.to_f,
      "lenz" => target_lenz_cm.to_f.cm.to_f,
      "x"    => target_x_cm.to_f.cm.to_f,
      "z"    => target_z_cm.to_f.cm.to_f
    }

    cm_values.each do |key, value_cm|
      begin
        if engine.respond_to?(:set_attribute_formula)
          engine.set_attribute_formula(entity, key, value_cm.to_s)
        else
          entity.set_attribute(DC_DICT, "_#{key}_formula", value_cm.to_s)
        end
      rescue
        entity.set_attribute(DC_DICT, "_#{key}_formula", value_cm.to_s)
      end

      begin
        engine.set_attribute(entity, key, inch_values[key])
      rescue
        entity.set_attribute(DC_DICT, key, inch_values[key])
      end
    end

    begin
      inch_values.each do |key, value|
        engine.set_forced_config_value(entity, key, value)
      end

      engine.run_all_formulas(entity)
      engine.redraw(entity, false, false)
      engine.update_last_sizes(entity)
    ensure
      begin
        engine.clear_forced_config_values(entity)
      rescue
      end
    end

    puts "MHD Vertical Back DC LenX: #{part.name} => #{target_lenx_cm.to_f.round(2)} cm"
    puts "MHD Vertical Back DC LenZ: #{part.name} => #{target_lenz_cm.to_f.round(2)} cm"
    puts "MHD Vertical Back DC Position X: #{part.name} => #{target_x_cm.to_f.round(2)} cm"
    puts "MHD Vertical Back DC Position Z: #{part.name} => #{target_z_cm.to_f.round(2)} cm"

    true
  rescue => error
    puts "MHD Vertical Back DC Error (#{part.name}): #{error.message}"
    false
  end

  def set_vertical_divider_depth_visual!(part, target_depth_cm)
    entity = part.entity
    return false unless entity && entity.valid?
    return false if target_depth_cm.to_f <= 0.000001

    make_unique!(part)

    bounds = local_bounds(entity)
    local_depth = bounds.height.to_f
    return false if local_depth <= 0.000001

    current_world_depth =
      local_depth * part.world_tr.yaxis.length.to_f

    return false if current_world_depth <= 0.000001

    target_world_depth = target_depth_cm.to_f.cm.to_f
    factor = target_world_depth / current_world_depth

    anchor = Geom::Point3d.new(0, bounds.min.y, 0)

    entity.transformation =
      entity.transformation *
      Geom::Transformation.scaling(
        anchor,
        1.0,
        factor,
        1.0
      )

    entity.set_attribute(
      DC_DICT,
      "_leny_formula",
      target_depth_cm.to_f.to_s
    )
    entity.set_attribute(
      DC_DICT,
      "leny",
      target_world_depth
    )
    entity.set_attribute(
      DC_DICT,
      "_last_leny",
      target_world_depth
    )

    updated_visual_depth =
      current_world_depth * factor

    puts "MHD Vertical Divider LenY: #{part.name} => #{target_depth_cm.to_f.round(2)} cm"
    puts "MHD Vertical Divider Visual Depth: #{part.name} => #{updated_visual_depth.to_l.to_cm.round(2)} cm"

    true
  rescue => error
    puts "MHD Vertical Divider Depth Error (#{part.name}): #{error.message}"
    false
  end

  def run_vertical_merge(options, units)
    unit_a, unit_b = units

    errors = validate_vertical_units(unit_a, unit_b)
    unless errors.empty?
      MHDESIGN_UI_LANG.messagebox(
        "لا يمكن تنفيذ الدمج الرأسي:\n\n#{errors.join("\n")}"
      )
      return
    end

    column = column_info(unit_a, unit_b)
    unless column
      MHDESIGN_UI_LANG.messagebox(
        "الوحدتان ليستا فوق بعض أو اتجاهاتهما مختلفة."
      )
      return
    end

    lower = column[:lower]
    upper = column[:upper]

    unless vertical_layout_valid?(unit_a, unit_b)
      MHDESIGN_UI_LANG.messagebox(
        "لا يمكن تنفيذ الدمج الرأسي.\n\n"         "يجب أن تكون الوحدتان فوق بعض مباشرة، وعلى نفس خط العرض والعمق."
      )
      return
    end

    upper_assembly_type = assembly_method_type(upper)

    unless upper_assembly_type == :full_side
      MHDESIGN_UI_LANG.messagebox(
        "لا يمكن تنفيذ الدمج الرأسي.\n\n"         "غيّر طريقة تجميع الوحدة العلوية إلى: جنب كامل (سحابي)، ثم أعد المحاولة."
      )
      return
    end

    if forbidden_vertical_upper_door_type?(upper)
      MHDESIGN_UI_LANG.messagebox(
        "لا يمكن تنفيذ الدمج الرأسي بهذه الوحدة العلوية.

" \
        "نوع الضلفة غير مسموح به:
" \
        "• ضلفة بمقبض بلت إن بخلع
" \
        "• ضلفة بشفة من الأسفل"
      )
      return
    end

    unit_name = options["unit_name"].to_s.strip

    lower_height_cm = find_dc_value_cm(lower, HEIGHT_LABELS)
    upper_height_cm = find_dc_value_cm(upper, HEIGHT_LABELS)
    lower_width_cm  = find_dc_value_cm(lower, WIDTH_LABELS)

    unless lower_height_cm && lower_height_cm > 0.0 &&
           upper_height_cm && upper_height_cm > 0.0
      MHDESIGN_UI_LANG.messagebox("تعذر قراءة ارتفاع الوحدتين.")
      return
    end

    unless lower_width_cm && lower_width_cm > 0.0
      MHDESIGN_UI_LANG.messagebox("تعذر قراءة عرض الوحدة السفلية.")
      return
    end

    counter_cm = find_dc_value_cm(lower, COUNTER_LABELS)

    chassis_depth_cm = find_dc_value_cm(lower, DEPTH_LABELS)
    back_start_cm = find_dc_value_cm(lower, BACK_START_LABELS).to_f
    back_thickness_cm = find_dc_value_cm(lower, BACK_THICKNESS_LABELS).to_f

    unless counter_cm && counter_cm > 0.0
      counter_cm = CONFIRMED_CHASSIS_THICKNESS_CM.to_f
      puts "MHD Counter Thickness Fallback: #{counter_cm.round(2)} cm"
    end

    unless chassis_depth_cm && chassis_depth_cm > 0.0
      MHDESIGN_UI_LANG.messagebox(
        "تعذر قراءة عمق الشاسيه لحساب عمق القاطع."
      )
      return
    end

    assembly_type = assembly_method_type(lower)
    lower_is_drawer = drawer_unit?(lower)

    unless assembly_type
      MHDESIGN_UI_LANG.messagebox(
        "تعذر قراءة طريقة التجميع من الوحدة السفلية."
      )
      return
    end

    model = Sketchup.active_model
    model.start_operation(
      "MHDESIGN Vertical Cabinet Merge",
      true
    )

    begin
      lower.make_unique if lower.respond_to?(:make_unique)
      upper.make_unique if upper.respond_to?(:make_unique)

      [:right_side, :left_side, :back].each do |rule|
        isolate_paths_to_rule!(lower, rule)
      end

      [:right_side, :left_side, :base, :back].each do |rule|
        isolate_paths_to_rule!(upper, rule)
      end

      lower_parts = collect_parts(lower)
      upper_parts = collect_parts(upper)

      lower_right = best_part(lower_parts, :right_side)
      lower_left  = best_part(lower_parts, :left_side)
      lower_back  = main_back_part(lower_parts)

      lower_rails = [
        all_parts(lower_parts, :front_rail),
        all_parts(lower_parts, :back_rail)
      ].flatten.compact.uniq

      lower_qorsa = all_parts(lower_parts, :qorsa).compact.uniq

      upper_right = best_part(upper_parts, :right_side)
      upper_left  = best_part(upper_parts, :left_side)
      upper_base  = main_base_part(upper_parts)
      upper_back  = main_back_part(upper_parts)

      required = {
        lower_right: lower_right,
        lower_left: lower_left,
        lower_back: lower_back,
        upper_right: upper_right,
        upper_left: upper_left,
        upper_base: upper_base,
        upper_back: upper_back
      }

      missing = required.select { |_key, value| value.nil? }.keys

      if lower_rails.empty? && lower_qorsa.empty?
        missing << :lower_rails_or_qorsa
      end

      unless missing.empty?
        raise "لم يتم العثور على قطع الدمج الرأسي:\n#{missing.join("\n")}"
      end

      total_height_cm =
        lower_height_cm.to_f +
        upper_height_cm.to_f

      side_target_height_cm =
        case assembly_type
        when :full_side
          total_height_cm
        when :side_on_base
          total_height_cm - counter_cm.to_f
        end

      if side_target_height_cm <= 0.000001
        raise "ارتفاع الجنب النهائي غير صالح."
      end

      puts
      puts "============= MHD VERTICAL MERGE PREVIEW ============="
      puts "الوحدة الأساسية السفلية: #{entity_name(lower)}"
      puts "الوحدة العلوية: #{entity_name(upper)}"
      puts "طريقة تجميع الوحدة العلوية: جنب كامل (سحابي)"
      puts "نوع ضلفة الوحدة العلوية: #{door_type_text(upper).empty? ? 'غير محدد' : door_type_text(upper)}"
      puts "طريقة التجميع: #{assembly_type == :full_side ? 'جنب كامل (سحابي)' : 'جنب على القاعدة'}"
      puts "تحديث الجوانب والضهر: #{lower_is_drawer ? 'آمن بدون Redraw لوحدة الأدراج' : 'Dynamic Component مباشر'}"
      puts "جنب سفلي يمين: #{lower_right.name}"
      puts "جنب سفلي شمال: #{lower_left.name}"
      puts "ضهر سفلي: #{lower_back.name}"
      puts "شدادات سفلية: #{lower_rails.empty? ? 'غير موجود' : lower_rails.map(&:name).join(' || ')}"
      puts "قرصة سفلية: #{lower_qorsa.empty? ? 'غير موجود' : lower_qorsa.map(&:name).join(' || ')}"
      puts "قاعدة علوية/قاطع: #{upper_base.name}"
      puts "عمق القاطع النهائي: #{(chassis_depth_cm.to_f - back_start_cm.to_f - back_thickness_cm.to_f).round(2)} سم"
      puts "ارتفاع الجوانب النهائي: #{side_target_height_cm.round(2)} سم"
      puts "======================================================"

      [
        upper_right,
        upper_left,
        upper_back
      ].compact.uniq.each do |part|
        erase_part!(part)
      end

      [
        lower_rails,
        lower_qorsa
      ].flatten.compact.uniq.each do |part|
        erase_part!(part)
      end

      divider_depth_cm =
        chassis_depth_cm.to_f -
        back_start_cm.to_f -
        back_thickness_cm.to_f

      if divider_depth_cm <= 0.000001
        raise "عمق القاطع النهائي غير صالح."
      end

      unless set_part_y_depth!(
        upper_base,
        divider_depth_cm,
        false
      )
        raise "تعذر ضبط LenY الفعلي لقاطع الدمج الرأسي."
      end

      upper_parts_after_divider_redraw = collect_parts(upper)
      refreshed_upper_base =
        main_base_part(upper_parts_after_divider_redraw) ||
        best_part(upper_parts_after_divider_redraw, :base)

      unless refreshed_upper_base &&
             refreshed_upper_base.entity &&
             refreshed_upper_base.entity.valid?
        raise "تعذر إعادة العثور على قاعدة الوحدة العلوية بعد ضبط LenY."
      end

      rename_part!(
        refreshed_upper_base,
        "قاطع (#{unit_name})"
      )

      upper_base = refreshed_upper_base

      puts "MHD Vertical Divider DC LenY Applied: #{upper_base.name} => #{divider_depth_cm.round(2)} cm"

      [lower_right, lower_left].each do |side|
        unless set_part_z_height!(
          side,
          side_target_height_cm,
          lower_is_drawer
        )
          raise "تعذر ضبط ارتفاع الجنب السفلي: #{side.name}"
        end
      end

      groove_drop_cm =
        find_dc_value_cm(lower, GROOVE_DROP_LABELS).to_f

      back_offset_cm =
        counter_cm.to_f -
        groove_drop_cm

      back_lenx_cm =
        lower_width_cm.to_f -
        (counter_cm.to_f * 2.0) +
        (groove_drop_cm * 2.0)

      back_lenz_cm =
        total_height_cm -
        (counter_cm.to_f * 2.0) +
        (groove_drop_cm * 2.0)

      if back_lenx_cm <= 0.000001 ||
         back_lenz_cm <= 0.000001
        raise "مقاس الضهر النهائي غير صالح."
      end

      world_x_axis =
        normalized_axis(lower.transformation.xaxis)

      raise "تعذر تحديد محور X للوحدة السفلية." unless world_x_axis

      unless set_vertical_back_dimensions!(
        lower_back,
        back_lenx_cm,
        back_lenz_cm,
        back_offset_cm,
        back_offset_cm,
        world_x_axis,
        lower_is_drawer
      )
        raise "تعذر ضبط ضهر الدمج الرأسي."
      end

      merged_component =
        create_merged_dynamic_component!(
          model,
          lower,
          upper,
          unit_name
        )

      merged_component.set_attribute(
        "MHD_MERGE",
        "merge_type",
        "vertical"
      )

      merged_component.set_attribute(
        "MHD_MERGE",
        "primary_unit",
        "lower"
      )

      merged_component.set_attribute(
        "MHD_MERGE",
        "total_height_cm",
        total_height_cm
      )

      merged_component.set_attribute(
        "MHD_MERGE",
        "side_height_cm",
        side_target_height_cm
      )

      model.commit_operation
      model.active_view.invalidate

      MHDESIGN_UI_LANG.messagebox(
        "تم إنشاء الدمج الرأسي بنجاح.\n\n" \
        "اسم الوحدة: #{unit_name}\n" \
        "إجمالي الارتفاع: #{total_height_cm.round(2)} سم"
      )
    rescue => error
      model.abort_operation rescue nil
      puts error.full_message
      MHDESIGN_UI_LANG.messagebox(
        "حدث خطأ أثناء الدمج الرأسي:\n#{error.message}"
      )
    end
  end

  def validate_units(unit_a, unit_b)
    depth_a = find_dc_value_cm(unit_a, DEPTH_LABELS)
    depth_b = find_dc_value_cm(unit_b, DEPTH_LABELS)
    height_a = find_dc_value_cm(unit_a, HEIGHT_LABELS)
    height_b = find_dc_value_cm(unit_b, HEIGHT_LABELS)

    errors = []

    if depth_a && depth_b && (depth_a - depth_b).abs > TOLERANCE_CM
      errors << "العمق مختلف: #{depth_a.round(2)} / #{depth_b.round(2)} سم"
    end

    if height_a && height_b && (height_a - height_b).abs > TOLERANCE_CM
      errors << "الارتفاع مختلف: #{height_a.round(2)} / #{height_b.round(2)} سم"
    end

    errors
  end

  def run(options = nil, units_override = nil)
    units = units_override || selected_units

    unless units.length == 2
      MHDESIGN_UI_LANG.messagebox("حدد وحدتين Dynamic Component فقط.")
      return
    end

    if options.nil?
      show_merge_dialog(units)
      return
    end

    unit_name = options["unit_name"].to_s.strip
    chassis_confirmed =
      options["chassis_thickness_confirmed"] == true
    merge_type = options["merge_type"].to_s
    merge_type = "horizontal" unless %w[horizontal vertical].include?(merge_type)

    if unit_name.empty?
      MHDESIGN_UI_LANG.messagebox("اكتب اسم الوحدة أولاً.")
      return
    end

    unless chassis_confirmed
      MHDESIGN_UI_LANG.messagebox(
        "يجب تأكيد تخانة الشاسيه #{CONFIRMED_CHASSIS_THICKNESS_CM} سم."
      )
      return
    end

    if merge_type == "vertical"
      run_vertical_merge(options, units)
      return
    end

    unit_a, unit_b = units

    errors = validate_units(unit_a, unit_b)
    unless errors.empty?
      MHDESIGN_UI_LANG.messagebox("لا يمكن الدمج:\n\n#{errors.join("\n")}")
      return
    end

    row = row_info(unit_a, unit_b)
    unless row
      MHDESIGN_UI_LANG.messagebox("الوحدتان ليستا في نفس الاتجاه.")
      return
    end

    unless horizontal_layout_valid?(unit_a, unit_b)
      MHDESIGN_UI_LANG.messagebox(
        "لا يمكن تنفيذ الدمج الأفقي.\n\n"         "يجب أن تكون الوحدتان جنب بعض مباشرة وعلى نفس الصف."
      )
      return
    end

    width_a_cm = find_dc_value_cm(unit_a, WIDTH_LABELS)
    width_b_cm = find_dc_value_cm(unit_b, WIDTH_LABELS)

    unit_a_is_drawer = drawer_unit?(unit_a)
    unit_b_is_drawer = drawer_unit?(unit_b)

    primary_reason = nil

    primary =
      if unit_a_is_drawer != unit_b_is_drawer
        primary_reason = "وحدة الأدراج لها الأولوية"
        unit_a_is_drawer ? unit_a : unit_b
      elsif width_a_cm && width_b_cm &&
            (width_a_cm - width_b_cm).abs > TOLERANCE_CM
        primary_reason = "الوحدة الأكبر عرضًا"
        width_a_cm > width_b_cm ? unit_a : unit_b
      else
        primary_reason = "تساوي العرض أو تعذر قراءته؛ الوحدة اليسرى"
        row[:left]
      end

    secondary = primary == unit_a ? unit_b : unit_a
    secondary_is_right = secondary == row[:right]

    primary_is_drawer = drawer_unit?(primary)

    primary_parts = collect_parts(primary)
    secondary_parts = collect_parts(secondary)

    divider_rule = secondary_is_right ? :right_side : :left_side
    secondary_inner_rule = secondary_is_right ? :left_side : :right_side

    parts = {
      divider: best_part(primary_parts, divider_rule),

      primary_front: all_parts(primary_parts, :front_rail),
      primary_back_rail: all_parts(primary_parts, :back_rail),
      primary_qorsa: all_parts(primary_parts, :qorsa),

      primary_base: main_base_part(primary_parts),
      primary_back: main_back_part(primary_parts),

      secondary_inner: [best_part(secondary_parts, secondary_inner_rule)].compact,
      secondary_front: all_parts(secondary_parts, :front_rail),
      secondary_back_rail: all_parts(secondary_parts, :back_rail),
      secondary_qorsa: all_parts(secondary_parts, :qorsa),
      secondary_shelves: all_parts(secondary_parts, :shelf),
      secondary_base: [main_base_part(secondary_parts)].compact,
      secondary_back: [main_back_part(secondary_parts)].compact
    }

    puts
    puts "================ MHD MERGE PREVIEW ================"
    puts "الوحدة الأساسية: #{entity_name(primary)}"
    puts "سبب اختيار الأساسية: #{primary_reason}"
    puts "تحديث القاطع: #{primary_is_drawer ? 'آمن بدون Redraw لوحدة الأدراج' : 'Dynamic Component عادي'}"
    puts "الوحدة الثانوية: #{entity_name(secondary)}"
    puts "الثانوية جهة: #{secondary_is_right ? 'اليمين' : 'الشمال'}"
    parts.each do |key, value|
      if value.is_a?(Array)
        names = value.map(&:name)
        puts "#{key}: #{names.empty? ? 'غير موجود' : names.join(' || ')}"
      else
        puts "#{key}: #{value ? value.name : 'غير موجود'}"
      end
    end
    puts "المفصلات العادية: #{all_parts(secondary_parts, :hinge).length}"
    puts "قاعدة الشاسيه المعتمدة: #{parts[:primary_base]&.name || 'غير موجود'}"
    puts "ضهر الشاسيه المعتمد: #{parts[:primary_back]&.name || 'غير موجود'}"
    puts "==================================================="

    required_keys = [
      :divider, :primary_base, :primary_back,
      :secondary_inner, :secondary_base, :secondary_back
    ]

    missing = required_keys.select do |key|
      value = parts[key]
      value.nil? || (value.is_a?(Array) && value.empty?)
    end

    primary_rails = [parts[:primary_front], parts[:primary_back_rail]].flatten.compact
    secondary_rails = [parts[:secondary_front], parts[:secondary_back_rail]].flatten.compact

    primary_has_rails = !primary_rails.empty?
    secondary_has_rails = !secondary_rails.empty?
    primary_has_qorsa = !parts[:primary_qorsa].empty?
    secondary_has_qorsa = !parts[:secondary_qorsa].empty?

    unless primary_has_rails || primary_has_qorsa
      missing << :primary_rails_or_qorsa
    end

    unless secondary_has_rails || secondary_has_qorsa
      missing << :secondary_rails_or_qorsa
    end

    unless missing.empty?
      MHDESIGN_UI_LANG.messagebox(
        "لم يتم العثور على بعض القطع:\n\n#{missing.join("\n")}\n\nراجع Ruby Console."
      )
      return
    end

    counter_cm = find_dc_value_cm(primary, COUNTER_LABELS)

    unless counter_cm && counter_cm > 0
      counter_cm = CONFIRMED_CHASSIS_THICKNESS_CM.to_f
      puts "MHD Counter Thickness Fallback: #{counter_cm.round(2)} cm"
    end


    model = Sketchup.active_model
    model.start_operation("MHDESIGN Final Cabinet Merge", true)

    begin
      primary.make_unique if primary.respond_to?(:make_unique)
      secondary.make_unique if secondary.respond_to?(:make_unique)

      unless isolate_paths_to_rule!(primary, divider_rule)
        raise "تعذر فصل مسار القاطع داخل الوحدة الأساسية."
      end

      unless isolate_paths_to_rule!(secondary, secondary_inner_rule)
        raise "تعذر فصل مسار الجنب الداخلي داخل الوحدة الثانوية."
      end

      primary_parts = collect_parts(primary)
      secondary_parts = collect_parts(secondary)

      parts = {
        divider: best_part(primary_parts, divider_rule),
        primary_front: all_parts(primary_parts, :front_rail),
        primary_back_rail: all_parts(primary_parts, :back_rail),
        primary_qorsa: all_parts(primary_parts, :qorsa),
        primary_base: main_base_part(primary_parts),
        primary_back: main_back_part(primary_parts),
        secondary_inner: [best_part(secondary_parts, secondary_inner_rule)].compact,
        secondary_front: all_parts(secondary_parts, :front_rail),
        secondary_back_rail: all_parts(secondary_parts, :back_rail),
        secondary_qorsa: all_parts(secondary_parts, :qorsa),
        secondary_shelves: all_parts(secondary_parts, :shelf),
        secondary_base: [main_base_part(secondary_parts)].compact,
        secondary_back: [main_back_part(secondary_parts)].compact
      }

      protected_divider = parts[:divider]
      unless protected_divider && protected_divider.entity && protected_divider.entity.valid?
        raise "تعذر تثبيت الجنب الداخلي للوحدة الأساسية قبل الحذف."
      end

      protected_divider_pid =
        if protected_divider.entity.respond_to?(:persistent_id)
          protected_divider.entity.persistent_id
        end

      puts "MHD Protected Divider: #{protected_divider.name} | PID=#{protected_divider_pid}"

      protected_divider_row_position =
        projection(protected_divider.world_tr.origin, row[:axis])

      [
        parts[:secondary_inner],
        parts[:secondary_front],
        parts[:secondary_back_rail],
        parts[:secondary_qorsa],
        parts[:secondary_base],
        parts[:secondary_back]
      ].flatten.compact.uniq.each do |part|
        next unless part.entity && part.entity.valid?

        part_pid =
          if part.entity.respond_to?(:persistent_id)
            part.entity.persistent_id
          end

        next if protected_divider_pid && part_pid == protected_divider_pid
        erase_part!(part)
      end

      collect_parts(secondary).select do |part|
        match?(part.name, :front_rail)
      end.each do |part|
        next unless part.entity && part.entity.valid?

        part_pid =
          if part.entity.respond_to?(:persistent_id)
            part.entity.persistent_id
          end

        next if protected_divider_pid && part_pid == protected_divider_pid
        erase_part!(part)
      end

      width_a_cm = find_dc_value_cm(unit_a, WIDTH_LABELS)
      width_b_cm = find_dc_value_cm(unit_b, WIDTH_LABELS)

      total_width =
        if width_a_cm && width_b_cm
          (width_a_cm + width_b_cm).cm.to_f
        else
          row[:full_max] - row[:full_min]
        end

      counter_thickness = counter_cm.cm.to_f
      extension_sign = secondary_is_right ? 1.0 : -1.0

      shelf_extension_sign = secondary_is_right ? -1.0 : 1.0

      parts[:secondary_shelves].each do |part|
        shelf_entity = part.entity
        next unless shelf_entity && shelf_entity.valid?

        current_shelf_length = part_length_on_world_axis(part, row[:axis])

        unless current_shelf_length && current_shelf_length > 0.000001
          raise "تعذر قراءة العرض الهندسي للرف: #{part.name}"
        end

        target_shelf_length = current_shelf_length + counter_thickness

        unless set_part_on_row_axis!(
          part,
          row[:axis],
          shelf_extension_sign,
          target_shelf_length
        )
          raise "تعذر زيادة عرض الرف هندسيًا: #{part.name}"
        end

        puts "MHD Shelf Geometry: #{part.name} => #{target_shelf_length.to_l.to_cm.round(2)} cm"
      end

      assembly_type = assembly_method_type(primary)

      unless assembly_type
        raise "تعذر قراءة طريقة التجميع من الوحدة الأساسية."
      end

      rail_length = total_width - (counter_thickness * 2.0)

      base_length =
        case assembly_type
        when :side_on_base
          total_width
        when :full_side
          total_width - (counter_thickness * 2.0)
        end

      if rail_length <= 0.000001 || base_length <= 0.000001
        raise "المقاس النهائي للقاعدة أو الشدادات غير صالح."
      end

      rail_targets = [
        parts[:primary_front],
        parts[:primary_back_rail]
      ].flatten.compact.uniq

      qorsa_lenx_targets = parts[:primary_qorsa]
        .compact
        .uniq
        .select { |part| has_direct_lenx?(part) }

      lenx_targets = (rail_targets + qorsa_lenx_targets).uniq

      if lenx_targets.empty?
        raise "لم يتم العثور على شداد أو قطعة قرصة تحمل LenX مباشرة."
      end

      lenx_targets.each do |part|
        unless set_rail_lenx!(
          part,
          rail_length,
          row[:axis],
          extension_sign
        )
          part_type = match?(part.name, :qorsa) ? "القرصة" : "الشداد"
          raise "تعذر تحديث LenX للـ#{part_type}: #{part.name}"
        end
      end

      secondary_width_cm = find_dc_value_cm(secondary, WIDTH_LABELS)

      unless secondary_width_cm && secondary_width_cm > 0.000001
        secondary_range_for_base = bounds_range(secondary, row[:axis])
        secondary_width_cm =
          (secondary_range_for_base[1] - secondary_range_for_base[0]).to_l.to_cm
      end

      base_position_x_cm =
        if secondary_is_right
          assembly_type == :full_side ? counter_cm : 0.0
        else
          left_offset_cm = -secondary_width_cm.to_f
          assembly_type == :full_side ? (left_offset_cm + counter_cm) : left_offset_cm
        end

      base_geometry_shift_cm =
        if secondary_is_right
          nil
        else
          assembly_type == :full_side ? counter_cm : 0.0
        end

      unless set_base_safe!(
        parts[:primary_base],
        base_length,
        base_position_x_cm,
        row[:axis],
        extension_sign,
        base_geometry_shift_cm
      )
        raise "تعذر تحديث القاعدة حسب طريقة التجميع واتجاه الوحدتين."
      end

      groove_drop_cm = find_dc_value_cm(primary, GROOVE_DROP_LABELS).to_f
      chassis_height_for_back_cm = find_dc_value_cm(primary, HEIGHT_LABELS)

      unless chassis_height_for_back_cm && chassis_height_for_back_cm > 0.000001
        raise "تعذر قراءة ارتفاع الشاسيه لحساب ارتفاع الضهر."
      end

      back_lenx =
        total_width -
        (counter_thickness * 2.0) +
        (groove_drop_cm.cm.to_f * 2.0)

      back_lenz_cm =
        chassis_height_for_back_cm.to_f -
        (counter_cm.to_f * 2.0) +
        (groove_drop_cm * 2.0)

      back_offset_cm = counter_cm.to_f - groove_drop_cm

      back_x_cm =
        if secondary_is_right
          back_offset_cm
        else
          back_offset_cm - secondary_width_cm.to_f
        end

      back_z_cm = back_offset_cm

      back_geometry_x_shift_cm =
        secondary_is_right ? nil : 0.0

      if back_lenx <= 0.000001 || back_lenz_cm <= 0.000001
        raise "المقاس النهائي للضهر غير صالح."
      end

      unless set_back_safe!(
        parts[:primary_back],
        back_lenx,
        back_lenz_cm,
        back_x_cm,
        back_z_cm,
        row[:axis],
        extension_sign,
        back_geometry_x_shift_cm
      )
        raise "تعذر تحديث الضهر حسب المعادلات الجديدة."
      end

      fresh_primary_parts = collect_parts(primary)
      divider_part = best_part(fresh_primary_parts, divider_rule)

      unless divider_part && divider_part.entity && divider_part.entity.valid?
        raise "تعذر العثور على الجنب الداخلي الفعلي لتحويله إلى قاطع بعد تحديث الوحدة."
      end

      puts "MHD Divider Fresh Target: #{divider_part.name}"

      chassis_height_cm = find_dc_value_cm(primary, HEIGHT_LABELS)

      unless chassis_height_cm && chassis_height_cm > 0.0
        raise "تعذر قراءة ارتفاع الشاسيه من الوحدة الأساسية."
      end

      divider_target_height_cm = chassis_height_cm - (counter_cm * 2.0)

      if divider_target_height_cm <= 0.000001
        raise "ناتج ارتفاع القاطع غير صالح: ارتفاع الشاسيه - تخانة الكونتر × 2."
      end

      unless set_part_z_height!(divider_part, divider_target_height_cm, primary_is_drawer)
        raise "تعذر كتابة ارتفاع القاطع في LenZ بالقيمة المطلوبة."
      end

      chassis_depth_cm = find_dc_value_cm(primary, DEPTH_LABELS)

      unless chassis_depth_cm && chassis_depth_cm > 0.0
        raise "تعذر قراءة عمق الشاسيه من الوحدة الأساسية."
      end

      back_start_cm     = find_dc_value_cm(primary, BACK_START_LABELS).to_f
      back_thickness_cm = find_dc_value_cm(primary, BACK_THICKNESS_LABELS).to_f
      divider_target_depth_cm = chassis_depth_cm - (back_start_cm + back_thickness_cm)

      if divider_target_depth_cm <= 0.000001
        raise "ناتج عمق القاطع غير صالح: عمق الشاسيه - بداية الضهر من الخلف - تخانة الضهر."
      end

      unless set_part_y_depth!(divider_part, divider_target_depth_cm, primary_is_drawer)
        raise "تعذر كتابة عمق القاطع في LenY بالقيمة المطلوبة."
      end

      if assembly_type == :full_side
        unless add_part_position_z!(divider_part, counter_cm)
          raise "تعذر رفع Position Z للقاطع بقيمة تخانة الكونتر."
        end
      end

      unless secondary_is_right
        refreshed_divider = best_part(collect_parts(primary), divider_rule)

        unless refreshed_divider &&
               refreshed_divider.entity &&
               refreshed_divider.entity.valid?
          raise "تعذر إعادة العثور على القاطع لتثبيت موضعه على محور X."
        end

        current_row_position =
          projection(refreshed_divider.world_tr.origin, row[:axis])

        row_delta =
          protected_divider_row_position.to_f - current_row_position.to_f

        if row_delta.abs > 0.000001
          correction_vector = Geom::Vector3d.new(
            row[:axis].x.to_f * row_delta,
            row[:axis].y.to_f * row_delta,
            row[:axis].z.to_f * row_delta
          )

          unless translate_part_in_world!(refreshed_divider, correction_vector)
            raise "تعذر تثبيت القاطع في موضعه الأصلي على محور X."
          end
        end

        divider_part = refreshed_divider

        puts "MHD Divider X Restored: #{divider_part.name} | delta=#{row_delta.to_l.to_cm.round(2)} cm"
      end

      rename_part!(divider_part, "قاطع (#{next_divider_number})")

      all_parts(secondary_parts, :hinge).each do |hinge|
        rename_part!(hinge, "مفصلة نص ركبة")
      end

      merged_component = create_merged_dynamic_component!(
        model,
        primary,
        secondary,
        unit_name
      )

      merged_component.set_attribute(
        "MHD_MERGE",
        "merge_type",
        "horizontal"
      )

      model.commit_operation
      model.active_view.invalidate

      MHDESIGN_UI_LANG.messagebox(
        "تم إنشاء الوحدة المدموجة بنجاح.\n\n"         "اسم الوحدة: #{unit_name}\n"         "تم وضع الوحدتين داخل Dynamic Component واحد."
      )
    rescue => error
      model.abort_operation rescue nil
      puts error.full_message
      MHDESIGN_UI_LANG.messagebox("حدث خطأ أثناء الدمج:\n#{error.message}")
    end
  end

  unless file_loaded?(__FILE__)
    UI.add_context_menu_handler do |menu|
      next unless selected_units.length == 2

      menu.add_separator
      menu.add_item(MHDESIGN_UI_LANG.t("MHDESIGN - دمج نهائي للوحدتين")) {
        run
      }
    end

    file_loaded(__FILE__)
  end
end

puts "MHD Final Merge Test loaded."
puts "حدد وحدتين ثم كليك يمين > MHDESIGN - دمج نهائي للوحدتين"
#==========================المعاينه================================
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

    if text.start_with?('SURVEY_')
      return key(text, fallback_text)
    end

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

module MHD_WALL_SURVEY_V1
  extend self
  def tr(key, fallback = nil)
    MHDESIGN_UI_LANG.key(key, fallback)
  rescue
    fallback.nil? ? key.to_s : fallback.to_s
  end
  def trf(key,fallback,values={});tr(key,fallback)%values;rescue;fallback.to_s%values;end
  def language_direction;MHDESIGN_UI_LANG.direction;rescue;'rtl';end

  DICT = 'MHD_ROOM_BUILDER'
  OPENINGS_KEY = 'OPENINGS_JSON'
  ITEMS_KEY = 'SURVEY_ITEMS_JSON'
  PREF_KEY = 'MHD_WALL_SURVEY_V1_UI'
  EPS_CM = 0.05
  LOGO_URL = 'https://mhdesign-eg.com/SKETCHUP/components/logo3.png'

  def menu_draw;tr('SURVEY_MENU_DRAW','رسم المعاينة');end
  def menu_clear;tr('SURVEY_MENU_CLEAR','حذف عناصر المعاينة من الحائط');end

  MODEL_BASE_URL = 'https://mhdesign-eg.com/SKETCHUP/survey_models'
  MODEL_REV = '2'

  TYPES = {
    'door'        => { name: 'باب',             kind: 'opening', width: 90, height: 220, level: 0 },
    'window'      => { name: 'شباك',            kind: 'opening', width: 120, height: 120, level: 90 },
    'socket'      => { name: 'وش كهرباء',       kind: 'model_recess', width: 8, height: 8, level: 110, depth: 2, shape: 'rect', measure_mode: 'outside', level_mode: 'bottom' },
    'switch'      => { name: 'مفتاح كهرباء',    kind: 'model',   width: 8, height: 12, level: 110, measure_mode: 'outside', level_mode: 'bottom' },
    'water_valve' => { name: 'محبس مياه',       kind: 'model',   width: 10, height: 10, level: 60, measure_mode: 'outside', level_mode: 'bottom' },
    'drain'       => { name: 'مخرج صرف',        kind: 'recess',  width: 4, height: 4, level: 45, depth: 5, shape: 'circle', measure_mode: 'outside', level_mode: 'bottom' },
    'feed_box'    => { name: 'علبة تغذية',       kind: 'box_assembly', width: 30, height: 30, level: 45, depth: 5, shape: 'rect', measure_mode: 'outside', level_mode: 'bottom', custom_size: true, custom_depth: true },
    'gas_pipe'    => { name: 'مخرج ماسورة غاز', kind: 'model',   width: 8, height: 8, level: 60, measure_mode: 'outside', level_mode: 'bottom' },
    'gas_valve'   => { name: 'محبس غاز',        kind: 'model',   width: 14, height: 14, level: 110, measure_mode: 'outside', level_mode: 'bottom' },
    'gas_meter'   => { name: 'عداد غاز',        kind: 'model',   width: 35, height: 45, level: 150, level_mode: 'bottom' }
  }.freeze
  TYPE_KEYS={'door'=>'SURVEY_ITEM_DOOR','window'=>'SURVEY_ITEM_WINDOW','socket'=>'SURVEY_ITEM_SOCKET','switch'=>'SURVEY_ITEM_SWITCH','water_valve'=>'SURVEY_ITEM_WATER_VALVE','drain'=>'SURVEY_ITEM_DRAIN','feed_box'=>'SURVEY_ITEM_FEED_BOX','gas_pipe'=>'SURVEY_ITEM_GAS_PIPE','gas_valve'=>'SURVEY_ITEM_GAS_VALVE','gas_meter'=>'SURVEY_ITEM_GAS_METER'}.freeze
  def type_name(type);spec=TYPES[type.to_s];spec ? tr(TYPE_KEYS[type.to_s],spec[:name]) : type.to_s;end

  REMOTE_MODELS = {
    'socket' => 'socket.skp',
    'switch' => 'light_switch.skp',
    'water_valve' => 'water_valve.skp',
    'gas_valve' => 'gass_valve.skp',
    'gas_meter' => 'gas_meter.skp'
  }.freeze

  def uuid
    defined?(SecureRandom) ? SecureRandom.uuid : "#{Time.now.to_i}-#{rand(999_999)}"
  end

  def get_attr(entity, key)
    entity.get_attribute(DICT, key)
  end

  def set_attrs(entity, data)
    data.each { |key, value| entity.set_attribute(DICT, key, value) }
  end

  def selected_wall
    Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).find do |entity|
      get_attr(entity, 'النوع') == 'حائط'
    end
  end

  def s_to_pt(value)
    xyz = value.to_s.split('|').map(&:to_f)
    return nil if xyz.length < 3
    Geom::Point3d.new(xyz[0], xyz[1], xyz[2])
  end

  def wall_data(wall)
    p1 = s_to_pt(get_attr(wall, 'P1'))
    p2 = s_to_pt(get_attr(wall, 'P2'))
    p3 = s_to_pt(get_attr(wall, 'P3'))
    p4 = s_to_pt(get_attr(wall, 'P4'))
    return nil unless p1 && p2 && p3 && p4

    wall_h_cm = get_attr(wall, 'الارتفاع سم').to_f
    wall_len_cm = get_attr(wall, 'طول الحائط سم').to_f
    wall_len_cm = p1.distance(p2).to_cm if wall_len_cm <= 0
    direction = p1.vector_to(p2)
    return nil if direction.length <= 0
    direction.normalize!

    mid_inner = Geom::Point3d.new((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0, (p1.z + p2.z) / 2.0)
    mid_outer = Geom::Point3d.new((p4.x + p3.x) / 2.0, (p4.y + p3.y) / 2.0, (p4.z + p3.z) / 2.0)
    raw_out = mid_inner.vector_to(mid_outer)
    return nil if raw_out.length <= 0

    wall_t = raw_out.length
    out_vec = direction.cross(Z_AXIS)
    out_vec.normalize!
    test_a = mid_inner.offset(out_vec, wall_t)
    test_b = mid_inner.offset(out_vec.reverse, wall_t)
    out_vec.reverse! if test_a.distance(mid_outer) > test_b.distance(mid_outer)
    out_vec.length = wall_t

    {
      p1: p1, p2: p2, p3: p3, p4: p4,
      dir: direction, out_vec: out_vec,
      wall_h_cm: wall_h_cm, wall_len_cm: wall_len_cm, wall_t: wall_t
    }
  end

  def parse_array(wall, key)
    raw = get_attr(wall, key).to_s
    raw.strip.empty? ? [] : JSON.parse(raw)
  rescue
    []
  end

  def read_openings(wall)
    parse_array(wall, OPENINGS_KEY)
  end

  def read_items(wall)
    parse_array(wall, ITEMS_KEY)
  end

  def write_openings(wall, value)
    wall.set_attribute(DICT, OPENINGS_KEY, JSON.generate(value))
  end

  def write_items(wall, value)
    wall.set_attribute(DICT, ITEMS_KEY, JSON.generate(value))
  end

  # يحافظ على نفس منطق يمين/شمال المستخدم في أداة الباب والشباك الحالية.
  def resolve_offset(measure_cm, width_cm, side, wall_len_cm)
    side == 'شمال' ? wall_len_cm - measure_cm - width_cm : measure_cm
  end

  # measure_mode:
  #   'outside' => المسافة = الفراغ فقط. العنصر خارج المقاس.
  #   'inside'  => المسافة = الفراغ + عرض العنصر. العنصر داخل المقاس.
  def resolve_item_offset(measure_cm, width_cm, side, wall_len_cm, measure_mode)
    case measure_mode.to_s
    when 'inside'
      side == 'شمال' ? wall_len_cm - measure_cm : measure_cm - width_cm
    else
      side == 'شمال' ? wall_len_cm - measure_cm - width_cm : measure_cm
    end
  end

  # يحسب أسفل العنصر (Bottom Z) بالسنتيمتر حسب measure_mode:
  #   'outside' => level_cm = المسافة من الأرض لأسفل العنصر. (خارج المقاس)
  #   'inside'  => level_cm = المسافة من الأرض لأعلى العنصر. (داخل المقاس)
  # level_mode = 'center' معناها level_cm هو مركز العنصر دائمًا.
  def resolve_item_bottom_cm(level_cm, height_cm, level_mode, measure_mode)
    lvl = level_cm.to_f
    h = height_cm.to_f
    if level_mode.to_s == 'bottom'
      if measure_mode.to_s == 'inside'
        lvl - h
      else
        lvl
      end
    else
      lvl - h / 2.0
    end
  end

  def inner_point(data, x_cm)
    data[:p1].offset(data[:dir], x_cm.cm)
  end

  def outer_point(data, x_cm)
    length = data[:wall_len_cm]
    return data[:p4] if x_cm <= 0.001
    return data[:p3] if (length - x_cm).abs <= 0.001
    inner_point(data, x_cm).offset(data[:out_vec])
  end

  def zpt(point, z_cm)
    point.offset(Z_AXIS, z_cm.cm)
  end

  def reverse_vector(vector)
    result = Geom::Vector3d.new(vector.x, vector.y, vector.z)
    result.reverse!
    result
  end

  def clean_face(face)
    return unless face && face.valid?
    face.material = nil
    face.back_material = nil
    face
  end

  def orient_face(face, target_normal)
    face.reverse! if face && face.valid? && target_normal && face.normal.dot(target_normal) < 0
    face
  end

  def add_face_clean(entities, points, target_normal = nil)
    face = entities.add_face(points)
    clean_face(face)
    orient_face(face, target_normal)
    clean_face(face)
  rescue
    nil
  end

  def opening_rects(data, openings)
    openings.map do |op|
      x1 = op['offset_cm'].to_f
      x2 = x1 + op['width_cm'].to_f
      z1 = op['type'] == 'door' ? EPS_CM : op['sill_cm'].to_f
      z2 = z1 + op['height_cm'].to_f
      z1 = [[z1, EPS_CM].max, data[:wall_h_cm] - EPS_CM].min
      z2 = [[z2, EPS_CM].max, data[:wall_h_cm] - EPS_CM].min
      next if x2 <= x1 || z2 <= z1
      { op: op, x1: x1, x2: x2, z1: z1, z2: z2 }
    end.compact
  end

  def rect_inner_points(data, rect)
    [
      zpt(inner_point(data, rect[:x1]), rect[:z1]),
      zpt(inner_point(data, rect[:x2]), rect[:z1]),
      zpt(inner_point(data, rect[:x2]), rect[:z2]),
      zpt(inner_point(data, rect[:x1]), rect[:z2])
    ]
  end

  def rect_outer_points(data, rect)
    [
      zpt(outer_point(data, rect[:x1]), rect[:z1]),
      zpt(outer_point(data, rect[:x2]), rect[:z1]),
      zpt(outer_point(data, rect[:x2]), rect[:z2]),
      zpt(outer_point(data, rect[:x1]), rect[:z2])
    ]
  end

  def add_face_with_holes(entities, outer_points, holes, target_normal = nil)
    face = add_face_clean(entities, outer_points, target_normal)
    return nil unless face && face.valid?
    holes.each do |loop_points|
      hole = entities.add_face(loop_points)
      hole.erase! if hole && hole.valid?
    rescue
      nil
    end
    orient_face(face, target_normal)
    clean_face(face)
  end

  def recess_inner_points(data, recess, segments = 20)
    center_x = recess['offset_cm'].to_f + recess['width_cm'].to_f / 2.0
    bottom_z = resolve_item_bottom_cm(
      recess['level_cm'],
      recess['height_cm'],
      recess['level_mode'],
      recess['measure_mode']
    )
    center_z = bottom_z + recess['height_cm'].to_f / 2.0

    if recess['shape'].to_s == 'rect'
      half_width = recess['width_cm'].to_f / 2.0
      half_height = recess['height_cm'].to_f / 2.0
      return [
        zpt(inner_point(data, center_x - half_width), center_z - half_height),
        zpt(inner_point(data, center_x + half_width), center_z - half_height),
        zpt(inner_point(data, center_x + half_width), center_z + half_height),
        zpt(inner_point(data, center_x - half_width), center_z + half_height)
      ]
    end

    radius = recess['width_cm'].to_f / 2.0
    (0...segments).map do |index|
      angle = 2.0 * Math::PI * index / segments
      x_cm = center_x + Math.cos(angle) * radius
      z_cm = center_z + Math.sin(angle) * radius
      zpt(inner_point(data, x_cm), z_cm)
    end
  end

  def recess_back_points(data, recess, segments = 20)
    depth_cm = [recess['depth_cm'].to_f, data[:wall_t].to_cm - EPS_CM].min
    depth_vector = Geom::Vector3d.new(data[:out_vec].x, data[:out_vec].y, data[:out_vec].z)
    depth_vector.normalize!
    depth_vector.length = depth_cm.cm
    recess_inner_points(data, recess, segments).map { |point| point.offset(depth_vector) }
  end

  def feed_box_drain_points(data, recess, depth_cm, segments = 20)
    center_x = recess['offset_cm'].to_f + recess['width_cm'].to_f / 2.0
    bottom_z = resolve_item_bottom_cm(
      recess['level_cm'],
      recess['height_cm'],
      recess['level_mode'],
      recess['measure_mode']
    )
    center_z = bottom_z + recess['height_cm'].to_f * 0.30
    radius = 2.0
    depth_vector = Geom::Vector3d.new(data[:out_vec].x, data[:out_vec].y, data[:out_vec].z)
    depth_vector.normalize!
    depth_vector.length = depth_cm.cm
    (0...segments).map do |index|
      angle = 2.0 * Math::PI * index / segments
      point = zpt(inner_point(data, center_x + Math.cos(angle) * radius), center_z + Math.sin(angle) * radius)
      point.offset(depth_vector)
    end
  end

  def build_recess_cavity(entities, data, recess)
    inner = recess_inner_points(data, recess)
    back = recess_back_points(data, recess)
    inner.length.times do |index|
      following = (index + 1) % inner.length
      add_face_clean(entities, [inner[index], inner[following], back[following], back[index]])
    end
    unless recess['type'].to_s == 'feed_box'
      add_face_clean(entities, back.reverse, reverse_vector(data[:out_vec]))
      return
    end

    box_depth = [recess['depth_cm'].to_f, data[:wall_t].to_cm - EPS_CM].min
    drain_start = feed_box_drain_points(data, recess, box_depth)
    add_face_with_holes(entities, back.reverse, [drain_start], reverse_vector(data[:out_vec]))
    remaining = [data[:wall_t].to_cm - box_depth - EPS_CM, 0.0].max
    drain_depth = [5.0, remaining].min
    return if drain_depth <= EPS_CM
    drain_back = feed_box_drain_points(data, recess, box_depth + drain_depth)
    drain_start.length.times do |index|
      following = (index + 1) % drain_start.length
      add_face_clean(entities, [drain_start[index], drain_start[following], drain_back[following], drain_back[index]])
    end
    add_face_clean(entities, drain_back.reverse, reverse_vector(data[:out_vec]))
  end

  def build_wall_shell(entities, data, rects, recesses = [])
    height = data[:wall_h_cm]
    outward = data[:out_vec]
    inward = reverse_vector(data[:out_vec])
    down = reverse_vector(Z_AXIS)

    inner = [zpt(data[:p1], 0), zpt(data[:p2], 0), zpt(data[:p2], height), zpt(data[:p1], height)]
    outer = [zpt(data[:p4], 0), zpt(data[:p3], 0), zpt(data[:p3], height), zpt(data[:p4], height)]
    inner_holes = rects.map { |r| rect_inner_points(data, r) }
    inner_holes.concat(recesses.map { |recess| recess_inner_points(data, recess) })
    add_face_with_holes(entities, inner, inner_holes, inward)
    add_face_with_holes(entities, outer, rects.map { |r| rect_outer_points(data, r) }, outward)
    add_face_clean(entities, [zpt(data[:p1], height), zpt(data[:p2], height), zpt(data[:p3], height), zpt(data[:p4], height)], Z_AXIS)

    doors = rects.select { |r| r[:op]['type'] == 'door' }.map { |r| [r[:x1], r[:x2]] }
    xs = [0.0, data[:wall_len_cm]]
    doors.each { |a, b| xs << a << b }
    xs.map! { |x| [[x, 0.0].max, data[:wall_len_cm]].min.round(4) }
    xs.uniq.sort.each_cons(2) do |x1, x2|
      next if x2 <= x1 + 0.001
      next if doors.any? { |a, b| x1 >= a - 0.001 && x2 <= b + 0.001 }
      add_face_clean(entities, [inner_point(data, x1), inner_point(data, x2), outer_point(data, x2), outer_point(data, x1)], down)
    end

    add_face_clean(entities, [zpt(data[:p1], 0), zpt(data[:p4], 0), zpt(data[:p4], height), zpt(data[:p1], height)])
    add_face_clean(entities, [zpt(data[:p2], 0), zpt(data[:p3], 0), zpt(data[:p3], height), zpt(data[:p2], height)])

    rects.each do |rect|
      ia, ib, ic, id = rect_inner_points(data, rect)
      oa, ob, oc, od = rect_outer_points(data, rect)
      add_face_clean(entities, [ia, id, od, oa], reverse_vector(data[:dir]))
      add_face_clean(entities, [ib, ic, oc, ob], data[:dir])
      add_face_clean(entities, [id, ic, oc, od], Z_AXIS)
      add_face_clean(entities, [ia, ib, ob, oa], down)
    end


    recesses.each { |recess| build_recess_cavity(entities, data, recess) }
  end

  def rebuild_wall(wall, openings, recesses = [])
    data = wall_data(wall)
    return false unless data
    definition = wall.definition
    definition.entities.to_a.each { |entity| entity.erase! if entity.valid? }
    build_wall_shell(definition.entities, data, opening_rects(data, openings), recesses)
    definition.entities.grep(Sketchup::Edge).each do |edge|
      next unless edge.valid? && edge.faces.length == 2
      next unless edge.faces[0].normal.parallel?(edge.faces[1].normal)
      edge.soft = edge.smooth = edge.hidden = true
    end
    write_openings(wall, openings)
    true
  end

  def wall_key(wall)
    (wall.persistent_id rescue wall.entityID).to_s
  end

  def model_entities_for(wall)
    wall.definition.entities
  end

  def remove_survey_models(wall)
    key = wall_key(wall)
    model_entities_for(wall).grep(Sketchup::ComponentInstance).each do |instance|
      next unless instance.get_attribute(DICT, 'SURVEY_MODEL') == 'نعم'
      next unless instance.get_attribute(DICT, 'SURVEY_WALL_ID').to_s == key
      instance.erase! if instance.valid?
    end
  end

  def material(model, name, color)
    mat = model.materials[name] || model.materials.add(name)
    mat.color = color
    mat
  end

  def add_box(entities, x1, y1, z1, x2, y2, z2, mat = nil)
    points = [
      Geom::Point3d.new(x1, y1, z1), Geom::Point3d.new(x2, y1, z1),
      Geom::Point3d.new(x2, y2, z1), Geom::Point3d.new(x1, y2, z1)
    ]
    face = entities.add_face(points)
    return unless face
    face.reverse! if face.normal.z < 0
    face.material = mat if mat
    face.pushpull(z2 - z1)
    entities.grep(Sketchup::Face).each { |f| f.material = mat if mat && f.material.nil? }
  end

  def add_cylinder_y(entities, center_x, center_z, radius, depth, mat, segments = 18)
    add_box(
      entities,
      center_x - radius, 0, center_z - radius,
      center_x + radius, depth, center_z + radius,
      mat
    )
  end

  def download_remote_model(type)
    filename = REMOTE_MODELS[type]
    raise trf('SURVEY_ERR_MODEL_URL','رابط موديل %{item} غير محدد',item:type_name(type)) unless filename

    cache_dir = File.join(Dir.tmpdir, 'mhd_wall_survey_remote_models')
    Dir.mkdir(cache_dir) unless File.directory?(cache_dir)
    cache_path = File.join(cache_dir, "#{type}_v#{MODEL_REV}.skp")
    return cache_path if File.file?(cache_path) && File.size(cache_path) > 100

    url = "#{MODEL_BASE_URL}/#{filename}?v=#{MODEL_REV}"
    download_http_file(url, cache_path)
    cache_path
  end

  def download_http_file(url, destination, redirects_left = 5)
    raise 'عدد تحويلات رابط الموديل أكبر من المسموح' if redirects_left < 0
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 15
    http.read_timeout = 90
    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'MHD-Wall-Survey/1.9 SketchUp'
    response = http.request(request)

    case response
    when Net::HTTPSuccess
      body = response.body.to_s
      raise 'ملف الموديل الذي تم تحميله فارغ أو غير صحيح' if body.bytesize <= 100
      temporary = "#{destination}.download"
      File.open(temporary, 'wb') { |file| file.write(body) }
      File.delete(destination) if File.file?(destination)
      File.rename(temporary, destination)
      destination
    when Net::HTTPRedirection
      location = response['location'].to_s
      raise 'السيرفر حوّل رابط الموديل بدون عنوان جديد' if location.empty?
      download_http_file(URI.join(url, location).to_s, destination, redirects_left - 1)
    else
      raise "فشل تحميل الموديل من السيرفر (HTTP #{response.code})"
    end
  rescue => error
    temporary = "#{destination}.download"
    File.delete(temporary) if File.file?(temporary)
    raise error
  end

  def definition_for(type)
    model = Sketchup.active_model
    if REMOTE_MODELS.key?(type)
      @remote_definitions ||= {}
      cache_key = [model.object_id, type]
      cached = @remote_definitions[cache_key]
      return cached if cached && cached.valid?

      asset_path = download_remote_model(type)
      definition = model.definitions.load(asset_path)
      raise trf('SURVEY_ERR_MODEL_LOAD','تعذر تحميل موديل %{item}',item:type_name(type)) unless definition && definition.valid?
      definition.name = "MHD_SURVEY_REMOTE_#{type.upcase}_V#{MODEL_REV}"
      @remote_definitions[cache_key] = definition
      return definition
    end

    name = "MHD_SURVEY_#{type.upcase}_V13"
    existing = model.definitions[name]
    return existing if existing
    definition = model.definitions.add(name)
    e = definition.entities
    white = material(model, 'MHD Survey White', Sketchup::Color.new(235, 238, 240))
    dark = material(model, 'MHD Survey Dark', Sketchup::Color.new(40, 48, 54))
    blue = material(model, 'MHD Survey Water', Sketchup::Color.new(44, 136, 220))
    yellow = material(model, 'MHD Survey Gas', Sketchup::Color.new(235, 184, 35))
    red = material(model, 'MHD Survey Valve', Sketchup::Color.new(190, 55, 45))

    case type
    when 'socket'
      add_box(e, -4.cm, 0, -4.cm, 4.cm, 1.2.cm, 4.cm, white)
      add_cylinder_y(e, -1.5.cm, 0.6.cm, 0.45.cm, 1.45.cm, dark, 12)
      add_cylinder_y(e, 1.5.cm, 0.6.cm, 0.45.cm, 1.45.cm, dark, 12)
    when 'switch'
      add_box(e, -4.cm, 0, -6.cm, 4.cm, 1.2.cm, 6.cm, white)
      add_box(e, -2.7.cm, 1.2.cm, -3.8.cm, 2.7.cm, 1.8.cm, 3.8.cm, dark)
    when 'water_valve'
      add_cylinder_y(e, 0, 0, 2.2.cm, 6.cm, blue, 20)
      add_box(e, -4.5.cm, 5.4.cm, -0.6.cm, 4.5.cm, 6.6.cm, 0.6.cm, red)
      add_box(e, -0.6.cm, 5.4.cm, -4.5.cm, 0.6.cm, 6.6.cm, 4.5.cm, red)
    when 'drain'
      add_cylinder_y(e, 0, 0, 4.cm, 3.cm, dark, 24)
      add_cylinder_y(e, 0, 0, 2.8.cm, 3.5.cm, white, 24)
    when 'gas_pipe'
      add_cylinder_y(e, 0, 0, 2.2.cm, 8.cm, yellow, 20)
    when 'gas_valve'
      add_cylinder_y(e, 0, 0, 2.2.cm, 7.cm, yellow, 20)
      add_box(e, -5.cm, 6.3.cm, -0.7.cm, 5.cm, 7.7.cm, 0.7.cm, red)
    when 'gas_meter'
      add_box(e, -17.5.cm, 0, -22.5.cm, 17.5.cm, 10.cm, 22.5.cm, yellow)
      add_box(e, -10.cm, 10.cm, -7.cm, 10.cm, 11.cm, 7.cm, white)
      add_box(e, -7.cm, 11.cm, -3.cm, 7.cm, 11.5.cm, 3.cm, dark)
    end
    definition
  end

  def create_survey_model(wall, item, data)
    type = item['type'].to_s
    definition = definition_for(type)
    width = item['width_cm'].to_f

    # نستخدم measure_mode المحفوظ مع العنصر (outside/inside) لحساب الموضع الأفقي والرأسي.
    effective_measure_mode = item['measure_mode'].to_s
    effective_measure_mode = 'outside' unless %w[outside inside].include?(effective_measure_mode)

    # الوضع الأفقي (X)
    offset = resolve_item_offset(
      item['measure_cm'].to_f,
      width,
      item['side'].to_s,
      data[:wall_len_cm],
      effective_measure_mode
    )

    # الوضع الرأسي (Z) — أسفل العنصر بالسنتيمتر
    target_bottom_cm = resolve_item_bottom_cm(
      item['level_cm'].to_f,
      item['height_cm'].to_f,
      TYPES[type][:level_mode] || 'bottom',
      effective_measure_mode
    )

    x_center = offset + width / 2.0
    base_point = inner_point(data, x_center)

    # نضع أولاً العنصر عند الموضع الأفقي الصحيح ثم نصحح Z لاحقًا حسب bounds الفعلي.
    point = zpt(base_point, 0)

    if type == 'socket'
      embed_vector = Geom::Vector3d.new(data[:out_vec].x, data[:out_vec].y, data[:out_vec].z)
      embed_vector.normalize!
      embed_vector.length = 2.cm
      point = point.offset(embed_vector)
    end

    flipped_model = %w[socket switch water_valve gas_valve gas_meter].include?(type)
    if flipped_model
      x_axis = reverse_vector(data[:dir])
      y_axis = Geom::Vector3d.new(data[:out_vec].x, data[:out_vec].y, data[:out_vec].z)
    else
      x_axis = Geom::Vector3d.new(data[:dir].x, data[:dir].y, data[:dir].z)
      y_axis = reverse_vector(data[:out_vec])
    end
    y_axis.normalize!
    wall_axes = Geom::Transformation.axes(point, x_axis, y_axis, Z_AXIS)

    bounds = definition.bounds
    center = bounds.center
    anchor_y = flipped_model ? -bounds.max.y : -bounds.min.y
    local_anchor = Geom::Transformation.translation(
      Geom::Vector3d.new(-center.x, anchor_y, -center.z)
    )
    transformation = wall_axes * local_anchor
    instance = model_entities_for(wall).add_instance(definition, transformation)

    # تصحيح الوضع الرأسي: نضع أسفل الموديل الفعلي على target_bottom_cm.
    if TYPES[type][:level_mode].to_s != 'center'
      target_bottom_z = data[:p1].z + target_bottom_cm.cm
      actual_bottom_z = instance.bounds.min.z
      delta_z = target_bottom_z - actual_bottom_z
      instance.transform!(Geom::Transformation.translation([0, 0, delta_z])) if delta_z.abs > 0.001
    else
      # level_mode = 'center': نضع مركز الموديل على level_cm (بغض النظر عن outside/inside)
      target_center_z = data[:p1].z + item['level_cm'].to_f.cm
      actual_center_z = instance.bounds.center.z
      delta_z = target_center_z - actual_center_z
      instance.transform!(Geom::Transformation.translation([0, 0, delta_z])) if delta_z.abs > 0.001
    end

    # تصحيح الوضع الأفقي حسب measure_mode (خارج المقاس أو داخل المقاس).
    actual_bounds = instance.bounds
    projections = (0..7).map do |index|
      data[:p1].vector_to(actual_bounds.corner(index)).dot(data[:dir])
    end

    if effective_measure_mode == 'inside'
      # العنصر بالكامل داخل المسافة.
      # الحرف البعيد عن الحيط على المسافة مباشرة.
      if item['side'].to_s == 'شمال'
        target_edge = (data[:wall_len_cm] - item['measure_cm'].to_f).cm
        horizontal_delta = target_edge - projections.min
      else
        target_edge = item['measure_cm'].to_f.cm
        horizontal_delta = target_edge - projections.max
      end
    else
      # العنصر خارج المسافة (الوضع الافتراضي).
      # الحرف القريب من الحيط على المسافة مباشرة.
      if item['side'].to_s == 'شمال'
        target_edge = (data[:wall_len_cm] - item['measure_cm'].to_f).cm
        horizontal_delta = target_edge - projections.max
      else
        target_edge = item['measure_cm'].to_f.cm
        horizontal_delta = target_edge - projections.min
      end
    end

    if horizontal_delta.abs > 0.001
      move_vector = Geom::Vector3d.new(
        data[:dir].x * horizontal_delta,
        data[:dir].y * horizontal_delta,
        data[:dir].z * horizontal_delta
      )
      instance.transform!(Geom::Transformation.translation(move_vector))
    end

    instance.name = type_name(type)
    set_attrs(instance, {
      'SURVEY_MODEL' => 'نعم', 'SURVEY_WALL_ID' => wall_key(wall),
      'SURVEY_UUID' => item['uuid'], 'SURVEY_TYPE' => type,
      'المسافة سم' => item['measure_cm'].to_f,
      'الاتجاه' => item['side'].to_s,
      'طريقة القياس' => effective_measure_mode,
      'الارتفاع سم' => item['level_cm'].to_f
    })
    instance
  end

  def create_feed_box_models(wall, item, data)
    definition = definition_for('water_valve')
    bounds = definition.bounds
    offset = item['offset_cm'].to_f
    width = item['width_cm'].to_f
    bottom_cm = resolve_item_bottom_cm(
      item['level_cm'],
      item['height_cm'],
      item['level_mode'],
      item['measure_mode']
    )
    height = item['height_cm'].to_f
    depth = [item['depth_cm'].to_f, data[:wall_t].to_cm - EPS_CM].min
    depth_vector = Geom::Vector3d.new(data[:out_vec].x, data[:out_vec].y, data[:out_vec].z)
    depth_vector.normalize!
    depth_vector.length = depth.cm

    [1.0 / 3.0, 2.0 / 3.0].each_with_index do |ratio, index|
      base_point = inner_point(data, offset + width * ratio).offset(depth_vector)
      point = zpt(base_point, bottom_cm + height * 0.68)
      x_axis = reverse_vector(data[:dir])
      y_axis = Geom::Vector3d.new(data[:out_vec].x, data[:out_vec].y, data[:out_vec].z)
      y_axis.normalize!
      axes = Geom::Transformation.axes(point, x_axis, y_axis, Z_AXIS)
      center = bounds.center
      local_anchor = Geom::Transformation.translation(
        Geom::Vector3d.new(-center.x, -bounds.max.y, -center.z)
      )
      instance = model_entities_for(wall).add_instance(definition, axes * local_anchor)
      instance.name = "#{tr('SURVEY_FEED_BOX_VALVE','محبس علبة التغذية')} #{index + 1}"
      set_attrs(instance, {
        'SURVEY_MODEL' => 'نعم', 'SURVEY_WALL_ID' => wall_key(wall),
        'SURVEY_UUID' => "#{item['uuid']}-valve-#{index + 1}",
        'SURVEY_TYPE' => 'feed_box_valve', 'عمق العلبة سم' => depth
      })
    end
  end

  def validate_payload(wall, payload)
    data = wall_data(wall)
    raise tr('SURVEY_ERR_WALL_DATA','بيانات الحائط غير مكتملة') unless data
    openings = []
    models = []
    recesses = []
    collision_items = []
    Array(payload).each do |raw|
      type = raw['type'].to_s
      spec = TYPES[type]
      raise tr('SURVEY_ERR_UNKNOWN_ITEM','يوجد عنصر غير معروف') unless spec
      item = raw.dup
      item['uuid'] = uuid if item['uuid'].to_s.empty?
      item['name'] = type_name(type)
      item['side'] = item['side'].to_s == 'شمال' ? 'شمال' : 'يمين'
      item['measure_cm'] = item['measure_cm'].to_f
      item['width_cm'] = item['width_cm'].to_f
      item['height_cm'] = item['height_cm'].to_f
      item['level_cm'] = item['level_cm'].to_f
      raise trf('SURVEY_ERR_SIZE','مقاسات %{item} غير صحيحة',item:type_name(type)) if item['width_cm'] <= 0 || item['height_cm'] <= 0

      # نحترم measure_mode لو جاي من الواجهة (outside/inside)، وإلا نستخدم القيمة الافتراضية للنوع.
      incoming_mode = raw['measure_mode'].to_s
      if %w[outside inside].include?(incoming_mode)
        measure_mode = incoming_mode
      else
        measure_mode = spec[:measure_mode].to_s == 'inside' ? 'inside' : 'outside'
      end

      level_mode = spec[:level_mode].to_s == 'bottom' ? 'bottom' : 'center'
      item['measure_mode'] = measure_mode
      item['level_mode'] = level_mode
      item['geometry_rev'] = 'v26'
      offset_cm = resolve_item_offset(item['measure_cm'], item['width_cm'], item['side'], data[:wall_len_cm], measure_mode)
      item['offset_cm'] = offset_cm
      raise trf('SURVEY_ERR_DISTANCE','مسافة %{item} غير صحيحة',item:type_name(type)) if item['measure_cm'] < 0 || offset_cm < -0.001 || offset_cm + item['width_cm'] > data[:wall_len_cm] + 0.001
      raise trf('SURVEY_ERR_HEIGHT','ارتفاع %{item} خارج الحائط',item:type_name(type)) if item['level_cm'] < 0

      # حساب أسفل العنصر (Z) حسب الوضع والاتجاه
      item_bottom_cm = resolve_item_bottom_cm(
        item['level_cm'], item['height_cm'], level_mode, measure_mode
      )
      item_top_cm = item_bottom_cm + item['height_cm']

      if spec[:kind] == 'opening'
        sill = type == 'window' ? item['level_cm'] : 0.0
        raise trf('SURVEY_ERR_HEIGHT','ارتفاع %{item} خارج الحائط',item:type_name(type)) if sill + item['height_cm'] >= data[:wall_h_cm]
        openings << {
          'uuid' => item['uuid'], 'type' => type, 'name' => type_name(type),
          'width_cm' => item['width_cm'], 'height_cm' => item['height_cm'],
          'sill_cm' => sill, 'measure_cm' => item['measure_cm'], 'side' => item['side'],
          'offset_cm' => offset_cm
        }
      elsif %w[recess model_recess box_assembly].include?(spec[:kind].to_s)
        if spec[:kind].to_s == 'box_assembly' && (item['width_cm'] < 20 || item['height_cm'] < 20)
          raise tr('SURVEY_ERR_FEED_BOX_MIN','أقل مقاس لعلبة التغذية هو 20 × 20 سم')
        end
        raise trf('SURVEY_ERR_HEIGHT','ارتفاع %{item} خارج الحائط',item:type_name(type)) if item_bottom_cm < 0 || item_top_cm > data[:wall_h_cm]
        item['depth_cm'] = spec[:custom_depth] ? raw['depth_cm'].to_f : spec[:depth].to_f
        raise trf('SURVEY_ERR_DEPTH','عمق %{item} غير صحيح',item:type_name(type)) if item['depth_cm'] <= 0 || item['depth_cm'] >= data[:wall_t].to_cm
        item['shape'] = spec[:shape].to_s
        item['offset_cm'] = offset_cm
        recesses << item
        models << item if %w[model_recess box_assembly].include?(spec[:kind].to_s)
      else
        if level_mode == 'bottom'
          raise trf('SURVEY_ERR_HEIGHT','ارتفاع %{item} خارج الحائط',item:type_name(type)) if item_bottom_cm < 0 || item_top_cm > data[:wall_h_cm]
        else
          half_height = item['height_cm'] / 2.0
          raise trf('SURVEY_ERR_HEIGHT','ارتفاع %{item} خارج الحائط',item:type_name(type)) if item['level_cm'] - half_height < 0 || item['level_cm'] + half_height > data[:wall_h_cm]
        end
        models << item
      end

      current_box = {
        x1: offset_cm, x2: offset_cm + item['width_cm'],
        z1: item_bottom_cm, z2: item_top_cm
      }
      collision_items.each do |previous|
        previous_box = previous[:box]
        horizontal = current_box[:x1] < previous_box[:x2] - 0.001 && current_box[:x2] > previous_box[:x1] + 0.001
        vertical = current_box[:z1] < previous_box[:z2] - 0.001 && current_box[:z2] > previous_box[:z1] + 0.001
        if horizontal && vertical
          raise trf('SURVEY_ERR_OVERLAP','يوجد تداخل بين %{first} و%{second}',first:type_name(type),second:previous[:name])
        end
      end
      collision_items << {name:type_name(type),box:current_box}
    end
    [openings, models, recesses, data]
  end

  def opening_signature(opening)
    [
      opening['type'].to_s,
      opening['width_cm'].to_f.round(4),
      opening['height_cm'].to_f.round(4),
      opening['sill_cm'].to_f.round(4),
      opening['measure_cm'].to_f.round(4),
      opening['side'].to_s
    ]
  end

  def openings_changed?(wall, new_openings)
    old_signatures = read_openings(wall).map { |opening| opening_signature(opening) }.sort_by(&:to_s)
    new_signatures = new_openings.map { |opening| opening_signature(opening) }.sort_by(&:to_s)
    old_signatures != new_signatures
  end

  def recess_signature(recess)
    [
      recess['type'].to_s,
      recess['width_cm'].to_f.round(4),
      recess['depth_cm'].to_f.round(4),
      recess['height_cm'].to_f.round(4),
      recess['shape'].to_s,
      recess['level_cm'].to_f.round(4),
      recess['measure_cm'].to_f.round(4),
      recess['side'].to_s,
      recess['measure_mode'].to_s,
      recess['level_mode'].to_s,
      recess['geometry_rev'].to_s
    ]
  end

  def recesses_changed?(wall, new_recesses)
    stored_items = read_items(wall)
    return true if stored_items.any? { |item| item['type'].to_s == 'water_feed' }
    old_recesses = stored_items.select do |item|
      %w[recess model_recess box_assembly].include?(TYPES.dig(item['type'].to_s, :kind).to_s)
    end
    old_signatures = old_recesses.map { |item| recess_signature(item) }.sort_by(&:to_s)
    new_signatures = new_recesses.map { |item| recess_signature(item) }.sort_by(&:to_s)
    old_signatures != new_signatures
  end

  def apply_design(wall, payload)
    model = Sketchup.active_model
    openings, models, recesses, data = validate_payload(wall, payload)
    model.start_operation('MHD رسم المعاينة', true)

    if openings_changed?(wall, openings) || recesses_changed?(wall, recesses)
      raise tr('SURVEY_ERR_REBUILD','تعذر إعادة بناء فتحات الحائط') unless rebuild_wall(wall, openings, recesses)
      data = wall_data(wall)
      raise tr('SURVEY_ERR_WALL_AFTER_REBUILD','تعذر قراءة بيانات الحائط بعد إنشاء الفتحات') unless data
    else
      write_openings(wall, openings)
    end

    remove_survey_models(wall)
    models.each do |item|
      item['type'].to_s == 'feed_box' ? create_feed_box_models(wall, item, data) : create_survey_model(wall, item, data)
    end
    write_items(wall, (models + recesses).uniq { |item| item['uuid'].to_s })
    set_attrs(wall, {
      'به باب' => openings.any? { |o| o['type'] == 'door' } ? 'نعم' : 'لا',
      'به شباك' => openings.any? { |o| o['type'] == 'window' } ? 'نعم' : 'لا',
      'نسخة محرك الفتحات' => 'Wall Survey v2.9'
    })
    model.commit_operation
    true
  rescue => error
    model.abort_operation rescue nil
    details = Array(error.backtrace).first(6).join("\n")
    UI.messagebox("#{tr('SURVEY_ERR_EXECUTE','تعذر تنفيذ المعاينة')}:\n#{error.message}\n\n#{details}")
    false
  end

  def initial_items(wall)
    result = read_openings(wall).map do |op|
      {
        'uuid' => op['uuid'] || uuid,
        'type' => op['type'],
        'name' => type_name(op['type']),
        'width_cm' => op['width_cm'].to_f,
        'height_cm' => op['height_cm'].to_f,
        'level_cm' => op['type'] == 'window' ? op['sill_cm'].to_f : 0,
        'measure_cm' => op['measure_cm'].to_f,
        'side' => op['side'].to_s == 'شمال' ? 'شمال' : 'يمين',
        'measure_mode' => 'outside'
      }
    end
    result.concat(read_items(wall).select { |item| TYPES.key?(item['type'].to_s) })
    result
  end

  def types_json
    TYPES.each_with_object({}){|(type,spec),h|h[type]=spec.merge(kind:spec[:kind].to_s,name:type_name(type))}.to_json
  end
  def ui_texts
    keys={title:['SURVEY_TITLE','رسم المعاينة'],subtitle:['SURVEY_SUBTITLE','رتّب كل محتويات وش الحائط ثم اضغط موافق'],wall_preview:['SURVEY_WALL_PREVIEW','معاينة الحائط'],cm:['SURVEY_CM','سم'],direction_hint:['SURVEY_DIRECTION_HINT',''],add_item:['SURVEY_ADD_ITEM','إضافة عنصر'],measure_direction:['SURVEY_MEASURE_DIRECTION','اتجاه القياس'],right:['SURVEY_RIGHT','يمين'],left:['SURVEY_LEFT','شمال'],distance_cm:['SURVEY_DISTANCE_CM','المسافة سم'],level_ground:['SURVEY_LEVEL_GROUND','الارتفاع من الأرض'],width_cm:['SURVEY_WIDTH_CM','العرض سم'],height_cm:['SURVEY_HEIGHT_CM','الارتفاع سم'],depth_cm:['SURVEY_DEPTH_CM','عمق الدخول سم'],add_to_wall:['SURVEY_ADD_TO_WALL','إضافة إلى الحائط'],added_items:['SURVEY_ADDED_ITEMS','العناصر المضافة'],apply:['SURVEY_APPLY','موافق وتنفيذ على الحائط'],cancel:['SURVEY_CANCEL','إلغاء'],overlap_title:['SURVEY_OVERLAP_TITLE','يوجد تداخل'],ok:['SURVEY_OK','موافق'],window_sill:['SURVEY_WINDOW_SILL','جلسة الشباك سم'],door_level:['SURVEY_DOOR_LEVEL','منسوب الباب'],item_bottom:['SURVEY_ITEM_BOTTOM','ارتفاع أسفل العنصر'],item_center:['SURVEY_ITEM_CENTER','ارتفاع مركز العنصر'],save_edit:['SURVEY_SAVE_EDIT','حفظ التعديل'],check_sizes:['SURVEY_CHECK_SIZES','راجع المقاسات المدخلة'],outside_wall:['SURVEY_OUTSIDE_WALL','العنصر يتجاوز حدود الحائط'],check_depth:['SURVEY_CHECK_DEPTH','راجع عمق الدخول'],outside_height:['SURVEY_OUTSIDE_HEIGHT','العنصر يتجاوز ارتفاع الحائط'],overlap_add:['SURVEY_OVERLAP_ADD','لا يمكن إضافة %{item} لأنه متداخل مع %{other}. غيّر المسافة أو الارتفاع ثم حاول مرة أخرى.'],no_items:['SURVEY_NO_ITEMS','لم تتم إضافة عناصر بعد'],height_word:['SURVEY_HEIGHT_WORD','ارتفاع'],depth_word:['SURVEY_DEPTH_WORD','عمق'],edit:['SURVEY_EDIT','تعديل'],delete:['SURVEY_DELETE','حذف'],wall_length:['SURVEY_WALL_LENGTH','طول الحائط'],wall_height:['SURVEY_WALL_HEIGHT','ارتفاع'],overlap_apply:['SURVEY_OVERLAP_APPLY','لا يمكن التنفيذ لوجود تداخل بين %{first} و%{second}.'],measure_mode:['SURVEY_MEASURE_MODE','طريقة القياس'],measure_outside:['SURVEY_MEASURE_OUTSIDE','العنصر خارج المقاس'],measure_inside:['SURVEY_MEASURE_INSIDE','العنصر داخل المقاس']}
    keys.transform_values{|p|tr(p[0],p[1])}
  end

  def html(data, items)
    wall_len = data[:wall_len_cm].round(1)
    wall_h = data[:wall_h_cm].round(1)
    u=ui_texts
    direction=language_direction
    <<-HTML
<!DOCTYPE html><html lang="#{defined?(MHDESIGN::Language) ? MHDESIGN::Language.current : 'ar_EG'}" dir="#{direction}"><head><meta charset="UTF-8"><title>#{u[:title]}</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#07131d;color:#eaf4f8;font-family:Tahoma,Arial,sans-serif;overflow:hidden}
.app{height:100vh;display:flex;flex-direction:column}.head{height:70px;display:flex;align-items:center;padding:8px 14px;background:linear-gradient(135deg,#07131d,#0d2635);border-bottom:1px solid #203948}.logo{width:54px;height:54px;object-fit:contain;border:1px solid #203948;border-radius:9px;padding:4px}.title{flex:1;text-align:center;font-size:21px;font-weight:900}.sub{display:block;color:#8fa9b9;font-size:11px;margin-top:4px}
.main{flex:1;min-height:0;display:grid;grid-template-columns:minmax(440px,1.5fr) minmax(300px,.8fr);gap:10px;padding:10px}.panel{background:#0b1b27;border:1px solid #203948;border-radius:10px;overflow:hidden;min-height:0}.panel-title{height:40px;padding:10px 12px;background:#0f2533;color:#4de37a;font-weight:900}.canvas-wrap{height:calc(100% - 40px);padding:12px;display:flex;flex-direction:column}.canvas{width:100%;flex:1;min-height:300px;background:#06121b;border:1px solid #203948;border-radius:8px}.hint{text-align:center;color:#91aaba;font-size:11px;margin-top:7px}
.editor{height:calc(100% - 40px);overflow:auto;padding:10px 10px 28px}.types{display:grid;grid-template-columns:repeat(3,1fr);gap:6px}.type{min-height:48px;padding:5px;background:#102735;border:1px solid #294557;color:#eaf4f8;border-radius:8px;font-weight:800;cursor:pointer}.type.active{border-color:#4de37a;background:#153727;color:#fff}.fields{margin-top:10px;border-top:1px solid #203948;padding-top:10px}.row{display:grid;grid-template-columns:105px 1fr;gap:8px;align-items:center;margin-bottom:7px}.row label{font-size:12px;font-weight:800}.row input{height:32px;background:#0a1720;color:#fff;border:1px solid #294557;border-radius:6px;text-align:center;outline:none}.row input:focus{border-color:#4de37a}.side{display:grid;grid-template-columns:1fr 1fr;gap:6px}.side button{height:32px;background:#102735;border:1px solid #294557;color:#fff;border-radius:6px;font-weight:800;cursor:pointer}.side button.active{border-color:#4de37a;background:#17412a}
.add{width:100%;height:38px;background:#4de37a;color:#062016;border:0;border-radius:8px;font-weight:900;cursor:pointer}.items{margin-top:10px;border-top:1px solid #203948;padding-top:8px}.item{display:flex;gap:5px;align-items:center;background:#0e2230;border:1px solid #203948;border-radius:7px;padding:6px;margin-bottom:5px}.item-name{flex:1;font-size:12px;font-weight:800}.item small{display:block;color:#9eb5c2;margin-top:3px}.mini{height:28px;border:0;border-radius:5px;padding:0 8px;cursor:pointer;font-weight:800}.edit{background:#276b8c;color:#fff}.del{background:#7f3030;color:#fff}.foot{height:58px;border-top:1px solid #203948;padding:8px 12px;display:flex;gap:8px}.ok{flex:2;background:#4de37a;color:#061d13;border:0;border-radius:9px;font-weight:900;font-size:15px}.cancel{flex:1;background:#102735;color:#fff;border:1px solid #294557;border-radius:9px;font-weight:900}::-webkit-scrollbar{width:8px}::-webkit-scrollbar-thumb{background:#294557;border-radius:8px}
.wall{fill:#102735;stroke:#6c8999;stroke-width:2}.open{fill:#06121b;stroke:#4de37a;stroke-width:2}.symbol{fill:#eaf4f8;stroke:#4de37a;stroke-width:2}.selected{stroke:#ffd54f!important;stroke-width:4!important}.dim{fill:#8ad8ff;font-size:11px;font-weight:bold}.name{fill:#fff;font-size:10px;font-weight:bold}
.notice-overlay{position:fixed;inset:0;z-index:9999;display:none;align-items:center;justify-content:center;background:rgba(2,10,16,.72);padding:20px}.notice-overlay.show{display:flex}.notice-box{width:min(390px,92vw);background:#102735;border:1px solid #e85b5b;border-radius:12px;padding:18px;text-align:center;box-shadow:0 18px 55px rgba(0,0,0,.5)}.notice-icon{width:48px;height:48px;line-height:45px;margin:0 auto 10px;border:2px solid #ff6868;border-radius:50%;color:#ff6868;font-size:29px;font-weight:900}.notice-title{font-size:18px;font-weight:900;color:#fff;margin-bottom:7px}.notice-text{font-size:13px;line-height:1.8;color:#c9dbe5}.notice-close{width:100%;height:38px;margin-top:14px;border:0;border-radius:8px;background:#e85b5b;color:#fff;font-weight:900;cursor:pointer}
@media(max-width:760px){.main{grid-template-columns:1fr;overflow:auto}.panel:first-child{min-height:330px}.editor{height:auto;overflow:visible;padding-bottom:28px}}
</style></head><body>
<div class="app"><div class="head"><img class="logo" src="#{LOGO_URL}"><div class="title">#{u[:title]}<span class="sub">#{u[:subtitle]}</span></div></div>
<div class="main">
 <div class="panel"><div class="panel-title">#{u[:wall_preview]} — #{wall_len} × #{wall_h} #{u[:cm]}</div><div class="canvas-wrap"><svg id="canvas" class="canvas" viewBox="0 0 700 430"></svg><div class="hint">#{u[:direction_hint]}</div></div></div>
 <div class="panel"><div class="panel-title">#{u[:add_item]}</div><div class="editor">
  <div id="types" class="types"></div>
  <div class="fields">
   <div class="row"><label>#{u[:measure_direction]}</label><div class="side"><button id="rightBtn" onclick="setSide('يمين')">#{u[:right]}</button><button id="leftBtn" onclick="setSide('شمال')">#{u[:left]}</button></div></div>
   <div class="row" id="measureModeRow"><label>#{u[:measure_mode]}</label><div class="side"><button id="outsideBtn" onclick="setMeasureMode('outside')">#{u[:measure_outside]}</button><button id="insideBtn" onclick="setMeasureMode('inside')">#{u[:measure_inside]}</button></div></div>
   <div class="row"><label>#{u[:distance_cm]}</label><input id="measure" type="number" step="0.1" min="0"></div>
   <div class="row"><label id="levelLabel">#{u[:level_ground]}</label><input id="level" type="number" step="0.1" min="0"></div>
   <div class="row" id="widthRow"><label>#{u[:width_cm]}</label><input id="width" type="number" step="0.1" min="0.1"></div>
   <div class="row" id="heightRow"><label>#{u[:height_cm]}</label><input id="height" type="number" step="0.1" min="0.1"></div>
   <div class="row" id="depthRow"><label>#{u[:depth_cm]}</label><input id="depth" type="number" step="0.1" min="0.1"></div>
   <button class="add" id="addBtn" onclick="saveItem()">#{u[:add_to_wall]}</button>
  </div>
  <div class="items"><b>#{u[:added_items]}</b><div id="list"></div></div>
 </div></div>
</div><div class="foot"><button class="ok" onclick="applyAll()">#{u[:apply]}</button><button class="cancel" onclick="sketchup.cancel()">#{u[:cancel]}</button></div></div>
<div id="noticeOverlay" class="notice-overlay"><div class="notice-box"><div class="notice-icon">!</div><div class="notice-title">#{u[:overlap_title]}</div><div id="noticeText" class="notice-text"></div><button class="notice-close" onclick="closeNotice()">#{u[:ok]}</button></div></div>
<script>
const SPECS=#{types_json}; const TX=#{JSON.generate(u)}; const WALL_LEN=#{wall_len}; const WALL_H=#{wall_h};
let items=#{JSON.generate(items)}; let currentType='door', side='يمين', editIndex=-1, measureMode='outside';
items.forEach(it=>{if(SPECS[it.type])it.name=SPECS[it.type].name;});
const $=id=>document.getElementById(id); const num=id=>parseFloat($(id).value||0);
function esc(v){return String(v||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
function makeTypes(){ $('types').innerHTML=Object.keys(SPECS).map(k=>`<button class="type ${k===currentType?'active':''}" onclick="chooseType('${k}')">${esc(SPECS[k].name)}</button>`).join(''); }

function setMeasureMode(v){
  measureMode = (v === 'inside') ? 'inside' : 'outside';
  $('outsideBtn').classList.toggle('active', measureMode === 'outside');
  $('insideBtn').classList.toggle('active', measureMode === 'inside');
  draw();
}

function chooseType(type, keep){ currentType=type; const s=SPECS[type]; if(!keep){$('width').value=s.width;$('height').value=s.height;$('depth').value=s.depth||0;$('level').value=s.level;$('measure').value=50;editIndex=-1;
   measureMode = (s.measure_mode === 'inside') ? 'inside' : 'outside';
 }
 // الباب والشباك عندهم قياس من الحرف دائماً، نخفي الخيار
 $('measureModeRow').style.display = (s.kind === 'opening') ? 'none' : '';
 setMeasureMode(measureMode);
 $('levelLabel').textContent=type==='window'?TX.window_sill:(type==='door'?TX.door_level:(s.level_mode==='bottom'?TX.item_bottom:TX.item_center));
 $('level').disabled=type==='door'; if(type==='door')$('level').value=0;
 const editableSize=s.kind==='opening'||s.custom_size; $('widthRow').style.display=editableSize?'':'none'; $('heightRow').style.display=editableSize?'':'none'; $('depthRow').style.display=s.custom_depth?'':'none';
 $('addBtn').textContent=editIndex>=0?TX.save_edit:TX.add_to_wall; makeTypes(); setSide(side); draw(); }
function setSide(v){side=v;$('rightBtn').classList.toggle('active',v==='يمين');$('leftBtn').classList.toggle('active',v==='شمال');draw();}

// حساب بداية العنصر على محور X بناءً على:
// - side: يمين => نقطة البداية من x=0، شمال => نقطة البداية من x=wall_len والعنصر بيتحرك شمالاً
// - measure_mode:
//     outside => 50 = فراغ فقط، العنصر بيبدأ عند 50 وينتهي 50+width
//     inside  => 50 = فراغ + width، العنصر بيبدأ عند 50-width وينتهي 50
function itemOffset(it,s){
  const mm = it.measure_mode || s.measure_mode || 'outside';
  if(mm === 'inside'){
    return it.side === 'شمال'
      ? WALL_LEN - it.measure_cm
      : it.measure_cm - it.width_cm;
  }
  return it.side === 'شمال'
    ? WALL_LEN - it.measure_cm - it.width_cm
    : it.measure_cm;
}

// حساب أسفل العنصر على محور Z بناءً على:
// - level_mode = 'bottom':
//     outside => level_cm = المسافة من الأرض لأسفل العنصر
//     inside  => level_cm = المسافة من الأرض لأعلى العنصر
// - level_mode = 'center': level_cm = مركز العنصر دائمًا
function itemBottom(it, s){
  const mode = it.measure_mode || s.measure_mode || 'outside';
  const lvlMode = s.level_mode || 'bottom';
  if(lvlMode === 'bottom'){
    return mode === 'inside' ? it.level_cm - it.height_cm : it.level_cm;
  }
  return it.level_cm - it.height_cm / 2;
}

function itemBox(it){const s=SPECS[it.type],x=itemOffset(it,s),bottom=itemBottom(it,s);return{x1:x,x2:x+it.width_cm,z1:bottom,z2:bottom+it.height_cm};}
function boxesOverlap(a,b){return a.x1<b.x2-.001&&a.x2>b.x1+.001&&a.z1<b.z2-.001&&a.z2>b.z1+.001;}
function findOverlap(item,ignoreIndex){const box=itemBox(item);for(let i=0;i<items.length;i++){if(i===ignoreIndex)continue;if(boxesOverlap(box,itemBox(items[i])))return items[i];}return null;}
function showNotice(message){$('noticeText').textContent=message;$('noticeOverlay').classList.add('show');}
function closeNotice(){$('noticeOverlay').classList.remove('show');}
function saveItem(){
  const s=SPECS[currentType];
  const customSize=s.kind==='opening'||s.custom_size;
  const item={
    uuid: editIndex>=0?items[editIndex].uuid:String(Date.now())+Math.random(),
    type: currentType,
    name: s.name,
    side,
    measure_cm: num('measure'),
    level_cm: num('level'),
    width_cm: customSize?num('width'):s.width,
    height_cm: customSize?num('height'):s.height,
    depth_cm: s.custom_depth?num('depth'):(s.depth||0),
    measure_mode: (s.kind === 'opening') ? 'outside' : measureMode
  };
  const offset=itemOffset(item,s);
  if(item.measure_cm<0||item.width_cm<=0||item.height_cm<=0){alert(TX.check_sizes);return;}
  if(offset<0||offset+item.width_cm>WALL_LEN){alert(TX.outside_wall);return;}
  if(s.custom_depth&&item.depth_cm<=0){alert(TX.check_depth);return;}
  const bottom=itemBottom(item,s), top=bottom+item.height_cm;
  if(bottom<0||top>WALL_H){alert(TX.outside_height);return;}
  const overlap=findOverlap(item,editIndex);
  if(overlap){showNotice(TX.overlap_add.replace('%{item}',item.name).replace('%{other}',overlap.name));return;}
  if(editIndex>=0)items[editIndex]=item;else items.push(item);
  editIndex=-1; chooseType(currentType); renderList(); draw();
}
function editItem(i){
  const it=items[i];
  editIndex=i;
  side=it.side;
  measureMode = it.measure_mode || SPECS[it.type].measure_mode || 'outside';
  $('measure').value=it.measure_cm;
  $('level').value=it.level_cm;
  $('width').value=it.width_cm;
  $('height').value=it.height_cm;
  $('depth').value=it.depth_cm||0;
  chooseType(it.type,true);
}
function deleteItem(i){items.splice(i,1);if(editIndex===i)editIndex=-1;renderList();draw();}
function renderList(){if(!items.length){$('list').innerHTML=`<div class="hint">${esc(TX.no_items)}</div>`;return;}$('list').innerHTML=items.map((it,i)=>`<div class="item"><div class="item-name">${esc(it.name)}<small>${it.side==='يمين'?esc(TX.right):esc(TX.left)}: ${it.measure_cm} ${esc(TX.cm)} — ${esc(TX.height_word)}: ${it.level_cm} ${esc(TX.cm)}${it.type==='feed_box'?` — ${it.width_cm}×${it.height_cm} — ${esc(TX.depth_word)} ${it.depth_cm} ${esc(TX.cm)}`:''}</small></div><button class="mini edit" onclick="editItem(${i})">${esc(TX.edit)}</button><button class="mini del" onclick="deleteItem(${i})">${esc(TX.delete)}</button></div>`).join('');}
// نفس اتجاه الرسم المرئي المستخدم في نافذة الباب والشباك الأصلية.
function xOffset(it){const s=SPECS[it.type];const mm=it.measure_mode||s.measure_mode||'outside';if(mm==='inside')return it.side==='شمال'?it.measure_cm:WALL_LEN-it.measure_cm;return it.side==='شمال'?it.measure_cm:WALL_LEN-it.measure_cm-it.width_cm;}
function draw(){const sx=610/Math.max(WALL_LEN,1),sy=330/Math.max(WALL_H,1),wx=45,wy=35,wh=330;let out=`<rect class="wall" x="${wx}" y="${wy}" width="610" height="330"/><text class="dim" x="350" y="395" text-anchor="middle">${esc(TX.wall_length)}: ${WALL_LEN} ${esc(TX.cm)}</text><text class="dim" x="12" y="200" transform="rotate(-90 12 200)" text-anchor="middle">${esc(TX.wall_height)}: ${WALL_H} ${esc(TX.cm)}</text>`;
 items.forEach((it,i)=>{const spec=SPECS[it.type],x=wx+xOffset(it)*sx,w=Math.max(10,it.width_cm*sx),h=Math.max(10,it.height_cm*sy),bottom=itemBottom(it,spec),y=wy+wh-(bottom+it.height_cm)*sy,cls=(spec.kind==='opening'?'open':'symbol')+(i===editIndex?' selected':'');
 if(SPECS[it.type].kind==='opening')out+=`<rect class="${cls}" x="${x}" y="${y}" width="${w}" height="${h}"/>`;
 else if(it.type==='feed_box'){const vr=Math.max(4,Math.min(w,h)*.08),dr=Math.max(4,Math.min(w,h)*.07);out+=`<rect class="${cls}" x="${x}" y="${y}" width="${w}" height="${h}"/><circle class="symbol" cx="${x+w/3}" cy="${y+h*.32}" r="${vr}"/><circle class="symbol" cx="${x+w*2/3}" cy="${y+h*.32}" r="${vr}"/><circle class="open" cx="${x+w/2}" cy="${y+h*.70}" r="${dr}"/>`;}
 else out+=`<circle class="${cls}" cx="${x+w/2}" cy="${y+h/2}" r="${Math.max(6,Math.min(w,h)/2)}"/>`;
 out+=`<text class="name" x="${x+w/2}" y="${Math.max(15,y-5)}" text-anchor="middle">${esc(it.name)}</text><text class="dim" x="${x+w/2}" y="${Math.min(425,y+h+14)}" text-anchor="middle">${it.measure_cm} / ${it.level_cm}</text>`;});$('canvas').innerHTML=out;}
function applyAll(){for(let i=0;i<items.length;i++){for(let j=i+1;j<items.length;j++){if(boxesOverlap(itemBox(items[i]),itemBox(items[j]))){showNotice(TX.overlap_apply.replace('%{first}',items[i].name).replace('%{second}',items[j].name));return;}}}sketchup.apply(JSON.stringify(items));}
document.addEventListener('contextmenu',e=>e.preventDefault());document.addEventListener('dragstart',e=>e.preventDefault());
chooseType('door');renderList();draw();
</script></body></html>
    HTML
  end

  class WallSelectionObserver < Sketchup::SelectionObserver
    def onSelectionAdded(_selection, _entity)
      MHD_WALL_SURVEY_V1.schedule_wall_refresh
    end

    def onSelectionRemoved(_selection, _entity)
      MHD_WALL_SURVEY_V1.schedule_wall_refresh
    end

    def onSelectionBulkChange(_selection)
      MHD_WALL_SURVEY_V1.schedule_wall_refresh
    end

    def onSelectionCleared(_selection)
      MHD_WALL_SURVEY_V1.schedule_wall_refresh
    end
  end

  def wall_identity(wall)
    (wall.persistent_id rescue wall.entityID).to_s
  end

  def schedule_wall_refresh
    return unless @dialog
    return if @wall_refresh_pending
    @wall_refresh_pending = true
    UI.start_timer(0.08, false) do
      @wall_refresh_pending = false
      refresh_dialog_from_selection
    end
  end

  def refresh_dialog_from_selection(force = false)
    return unless @dialog
    wall = selected_wall
    return unless wall && wall.valid?
    identity = wall_identity(wall)
    return if !force && identity == @current_wall_id
    data = wall_data(wall)
    return unless data
    @current_wall = wall
    @current_wall_id = identity
    @dialog.set_html(html(data, initial_items(wall)))
  rescue => error
    UI.messagebox("#{tr('SURVEY_ERR_REFRESH','تعذر تحديث معاينة الحائط')}:\n#{error.message}")
  end

  def attach_selection_observer
    @selection_observer ||= WallSelectionObserver.new
    Sketchup.active_model.selection.add_observer(@selection_observer)
  rescue
    nil
  end

  def detach_selection_observer
    Sketchup.active_model.selection.remove_observer(@selection_observer) if @selection_observer
  rescue
    nil
  end

  def show_dialog
    wall = selected_wall
    unless wall
      UI.messagebox(tr('SURVEY_SELECT_WALL','حدد حائط أولاً'))
      return
    end
    data = wall_data(wall)
    unless data
      UI.messagebox(tr('SURVEY_ERR_SELECTED_WALL_DATA','الحائط المحدد لا يحتوي على بيانات بناء الحوائط المطلوبة'))
      return
    end

    if @dialog
      refresh_dialog_from_selection(true)
      @dialog.bring_to_front rescue nil
      return
    end

    @dialog = UI::HtmlDialog.new(
      dialog_title: "MHDESIGN - #{tr('SURVEY_TITLE','رسم المعاينة')}", preferences_key: PREF_KEY,
      scrollable: false, resizable: true, width: 980, height: 700,
      style: UI::HtmlDialog::STYLE_DIALOG
    )
    @current_wall = wall
    @current_wall_id = wall_identity(wall)
    @dialog.set_html(html(data, initial_items(wall)))
    @dialog.add_action_callback('cancel') { @dialog.close if @dialog }
    @dialog.add_action_callback('apply') do |_context, json|
      payload = JSON.parse(json)
      target_wall = @current_wall
      raise tr('SURVEY_ERR_CURRENT_WALL','الحائط الحالي لم يعد متاحًا') unless target_wall && target_wall.valid?
      if apply_design(target_wall, payload)
        updated_data = wall_data(target_wall)
        @dialog.set_html(html(updated_data, initial_items(target_wall))) if @dialog && updated_data
      end
    rescue => error
      UI.messagebox("#{tr('SURVEY_ERR_DIALOG_DATA','خطأ في بيانات النافذة')}:\n#{error.message}")
    end
    @dialog.set_on_closed do
      detach_selection_observer
      @dialog = nil
      @current_wall = nil
      @current_wall_id = nil
      @wall_refresh_pending = false
    end
    attach_selection_observer
    @dialog.show
  end

  def clear_survey
    wall = selected_wall
    return UI.messagebox(tr('SURVEY_SELECT_WALL','حدد حائط أولاً')) unless wall
    return unless UI.messagebox(tr('SURVEY_CONFIRM_CLEAR','هل تريد حذف عناصر المعاينة والفتحات من الحائط المحدد؟'), MB_YESNO) == IDYES
    apply_design(wall, [])
  end

  unless @context_menu_loaded
    UI.add_context_menu_handler do |menu|
      next unless selected_wall
      menu.add_separator
      menu.add_item(menu_draw) { show_dialog }
      menu.add_item(menu_clear) { clear_survey }
    end
    @context_menu_loaded = true
  end
end
