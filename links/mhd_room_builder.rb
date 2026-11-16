# encoding: UTF-8

# Local artwork and visual tokens from the MHDESIGN Dressing workspace.
unless defined?(MHDESIGN_ResponsiveHeaderUI::CSS)
  module MHDESIGN_ResponsiveHeaderUI
    CSS = <<~'CSS'.freeze
      :root {
        --ref-bg: #0B111A;
        --ref-panel: #1A2633;
        --ref-section: #253443;
        --ref-input: #101923;
        --ref-border: #405467;
        --ref-text: #F4F7FA;
        --ref-muted: #A6B5C3;
        --ref-accent: #08C9C3;
        --ref-header: linear-gradient(110deg, #0A111A 0%, #142536 55%, #087F83 100%);
        --ref-panel-gradient: linear-gradient(145deg, #293A4B 0%, #1A2633 45%, #111B27 100%);
        --ref-action: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
      }
      .hero.mhd-ref-header, .head.mhd-ref-header, .topbar.mhd-ref-header, .mhd-tool-header.mhd-ref-header, .mhd-ref-header {
        position: relative; isolation: isolate; display: grid; flex: none;
        grid-template-columns: minmax(0, 1fr) minmax(0, 2.35fr) minmax(0, 1fr);
        align-items: center; direction: ltr; gap: 8px; height: auto;
        min-height: clamp(66px, 6.35vw, 100px); padding: 8px clamp(10px, 3.25vw, 49px);
        background: var(--ref-header); border-color: var(--ref-border); overflow: hidden;
      }
      .mhd-ref-header .mhd-ref-brand { min-width: 0; display: flex; align-items: center; z-index: 1; }
      .mhd-ref-brand .mhd-ref-logo { display: block; width: clamp(90px, 19vw, 270px); max-width: 100%; height: auto; max-height: 74px; object-fit: contain; color: transparent; }
      .mhd-ref-header .mhd-ref-art {
        position: absolute; inset: 0 0 0 auto; z-index: -1; width: min(35%, 500px); pointer-events: none;
        background: linear-gradient(145deg, transparent 42%, #006e6840 42%, #07c9c382 49%, transparent 52%, transparent 72%, #079d9630 72%);
      }
      .mhd-ref-art svg { position: absolute; right: 5%; bottom: -6px; width: 118px; height: min(110px, 105%); color: #36C9C2; opacity: .58; }
      .mhd-ref-header > :is(.title, .head-text, .heroText, .heading, .mhd-ref-heading) {
        min-width: 0; position: relative; z-index: 1; text-align: center; direction: ltr;
      }
      html[dir="rtl"] .mhd-ref-header > :is(.title, .head-text, .heroText, .heading, .mhd-ref-heading) { direction: rtl; }
      .mhd-ref-header :is(.title, .title-main, h1, h3) {
        margin: 0; color: var(--ref-text); font-size: clamp(18px, 2.1vw, 33px);
        line-height: 1.25; font-weight: 800; white-space: normal; overflow-wrap: anywhere;
      }
      .mhd-ref-header :is(.subtitle, .sub, .desc, p) {
        height: auto; margin: 4px 0 0; color: var(--ref-text); font-size: clamp(10px, 1.2vw, 16px);
        line-height: 1.35; white-space: normal; overflow-wrap: anywhere;
      }
      .mhd-ref-brand picture { display: block; min-width: 0; width: 100%; }
      @media (max-width: 620px) {
        .hero.mhd-ref-header, .head.mhd-ref-header, .topbar.mhd-ref-header, .mhd-tool-header.mhd-ref-header, .mhd-ref-header {
          grid-template-columns: clamp(42px, 15vw, 74px) minmax(0, 1fr) clamp(42px, 15vw, 74px);
          gap: 8px; min-height: 62px; padding: 6px 8px;
          background:
            linear-gradient(145deg, transparent 33%, #006e6830 48%, #07c9c362 54%, transparent 62%),
            linear-gradient(110deg, #0A111A 0%, #142536 42%, #087F83 100%);
        }
        .mhd-ref-brand .mhd-ref-logo { width: 100%; height: auto; max-height: none; }
        .mhd-ref-header .mhd-ref-art { width: 56px; background: none; }
        .mhd-ref-art svg { width: 52px; height: 52px; bottom: -4px; opacity: .42; }
        .mhd-ref-header :is(.title, .title-main, h1, h3) { font-size: clamp(13px, 4.1vw, 17px); }
        .mhd-ref-header :is(.subtitle, .sub, .desc, p) { margin-top: 3px; font-size: 10px; }
        .mhd-compact-brand-name { display: none; }
      }
    CSS
    BRAND = <<~'HTML'.freeze
      <div class="mhd-ref-brand"><picture><source media="(max-width: 620px)" srcset="https://mhdesign-eg.com/SKETCHUP022/skp/mhdesign-logo-v.png" width="1162" height="1030"><img class="mhd-ref-logo" alt="MHDESIGN" width="1600" height="533" src="https://raw.githubusercontent.com/eng-marwanadel/EN/refs/heads/main/links/Teal-MRDesign-Monogram-Logo-1.png"></picture></div>
      <div class="mhd-ref-art" aria-hidden="true"><svg class="workspace-icon " aria-hidden="true" focusable="false" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="17" rx="1"/><path d="M12 3v17M9 10v3m6-3v3M6 20v2m12-2v2"/></svg></div>
      <script>
        document.addEventListener('DOMContentLoaded', function () {
          const headings = document.querySelectorAll('.mhd-ref-header > :is(.title, .head-text, .heroText, .heading, .mhd-ref-heading)');
          const brand = /(?:\s*[|·•–—-]\s*)?\bMHDESIGN\b(?:\s*[|·•–—-]\s*)?/gi;
          function markBrand(heading) {
            const walker = document.createTreeWalker(heading, NodeFilter.SHOW_TEXT);
            const nodes = [];
            for (let node = walker.nextNode(); node; node = walker.nextNode()) {
              if (!node.parentElement.closest('.mhd-compact-brand-name') && /\bMHDESIGN\b/i.test(node.data)) nodes.push(node);
            }
            nodes.forEach(function (node) {
              const fragment = document.createDocumentFragment();
              let end = 0;
              node.data.replace(brand, function (name, index) {
                fragment.append(node.data.slice(end, index));
                const span = document.createElement('span');
                span.className = 'mhd-compact-brand-name';
                span.textContent = name;
                fragment.append(span);
                end = index + name.length;
                return name;
              });
              fragment.append(node.data.slice(end));
              node.replaceWith(fragment);
            });
          }
          headings.forEach(function (heading) {
            markBrand(heading);
            new MutationObserver(function () { markBrand(heading); }).observe(heading, {
              subtree: true, childList: true, characterData: true
            });
          });
        });
      </script>
    HTML
  end
end
# MHD Room Builder v3.3 - Multilingual Visual Ceiling Gallery
# SketchUp Ruby Plugin
# واجهة بنفس روح MHD Countertop Engine v3.1

require 'sketchup.rb'
require File.join(__dir__, 'MHDESIGN_Language') unless defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:for_tool)
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
  LOGO_URL = 'https://raw.githubusercontent.com/eng-marwanadel/EN/refs/heads/main/links/logo3.png'

  # -------------------------
  # Helpers
  # -------------------------
  def ts(text)
    source = text.to_s
    return source unless defined?(MHDESIGN::Language) && MHDESIGN::Language.for_tool('room_builder').respond_to?(:load_dictionary)
    data = MHDESIGN::Language.for_tool('room_builder').load_dictionary
    map = data['room_builder']
    return source unless map.is_a?(Hash)
    exact = map[source]
    return exact.to_s unless exact.nil? || exact.to_s.empty?
    source
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

  # Offset a horizontal polygon. Positive distance moves inward, negative outward.
  # The room outline is normalized counter-clockwise before this helper is used.
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

      # CCW polygon: left side of every edge is the room interior.
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

  # Generates a real alpha-gradient texture: bright at the ceiling and fading
  # continuously to transparent. This replaces the old stepped geometry.
  def gradient_texture_path(hex, intensity)
    value = hex.to_s.delete('#')
    value = 'ffd27a' unless value.match?(/\A[0-9a-fA-F]{6}\z/)
    strength = [[intensity.to_f, 0.0].max, 100.0].min
    # v2 suffix forces regeneration instead of reusing the earlier inverted file.
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
      # SketchUp UV-V starts at the image bottom. The last PNG row must therefore
      # be the bright row so the light is strongest at the ceiling, not below.
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
    # Never overwrite the selected color with white. Tinting also makes the
    # chosen color authoritative across SketchUp 2024, 2025 and 2026.
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
      # Avoid V=1.0: SketchUp wraps the texture there and repeats the bright
      # first sample as a thin line. 0.996 lands on the transparent guard row.
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
      # The glow is a visual wash, so its boundary must never render as geometry.
      face.edges.each do |edge|
        edge.hidden = true
        edge.soft = true
        edge.smooth = true
      end
    end

    # بعض الحواف المشتركة لا تُنشأ نهائياً إلا بعد إضافة القطعة المجاورة.
    # لذلك نخفي وننعّم جميع حواف تأثير الإضاءة مرة أخرى بعد اكتمال المستطيلات،
    # حتى لا يظهر خط أسود عند التقاء قطع التدرج في الأركان.
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

  # Used by the hidden-hand cove only. The light travels horizontally across
  # the top of the hand: from the LED line toward the room center.
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

    # أخفِ الحواف المشتركة بعد اكتمال كل قطع الإضاءة الأفقية؛ فقد يعيد
    # SketchUp إنشاء حافة الالتقاء عند إضافة المستطيل المجاور.
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
  :root {
    --mhd-app: #0B111A;
    --mhd-panel: #111F2C;
    --mhd-card: #172633;
    --mhd-input: #101923;
    --mhd-hover: #253443;
    --mhd-border: #34495B;
    --mhd-text: #F4F7FA;
    --mhd-muted: #A6B5C3;
    --mhd-accent: #08C9C3;
    --mhd-bright: #27E5DC;
    --mhd-ink: #04191C;
    --mhd-header: linear-gradient(110deg, #07111B 0%, #102332 60%, #075C62 100%);
    --mhd-primary: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
    --mhd-active: linear-gradient(135deg, #063C44 0%, #087D80 100%);
    --mhd-section: linear-gradient(145deg, #1D3040 0%, #111E2B 100%);
    --mhd-font: Cairo, Tajawal, "Segoe UI", Tahoma, sans-serif;
  }
  *{box-sizing:border-box}
  body{
    margin:0;
    font-family:Arial,Tahoma,sans-serif;
    background:var(--mhd-app);
    color:var(--mhd-text);
    overflow:hidden;
    direction:#{ui_direction};
  }
  ::-webkit-scrollbar{width:8px}
  ::-webkit-scrollbar-track{background:var(--mhd-app)}
  ::-webkit-scrollbar-thumb{background:var(--mhd-border);border-radius:20px;border:2px solid var(--mhd-app)}
  ::-webkit-scrollbar-thumb:hover{background:var(--mhd-hover)}
  .app{height:100vh;display:flex;flex-direction:column;background:var(--mhd-app)}
  .hero{
    height:74px;
    padding:10px 12px;
    display:flex;
    align-items:center;
    gap:10px;
    background:var(--mhd-header);
    border-bottom:1px solid var(--mhd-border);
  }
  .logo{
    width:58px;height:58px;object-fit:contain;background:var(--mhd-panel);
    border:1px solid var(--mhd-border);border-radius:10px;padding:5px;flex:0 0 auto;
  }
  .head-text{flex:1;overflow:hidden;text-align:center}
  .title-main{font-size:20px;font-weight:900;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.2}
  .subtitle{margin-top:6px;font-size:11px;line-height:1.5;color:var(--mhd-muted);height:32px;overflow:hidden}
  .wrap{height:calc(100vh - 74px - 58px);overflow:auto;padding:10px;background:var(--mhd-app)}
  .group{background:var(--mhd-card);border:1px solid var(--mhd-border);border-radius:10px;margin-bottom:10px;overflow:hidden}
  .group-title{padding:9px 10px;background:var(--mhd-panel);color:var(--mhd-accent);font-size:16px;font-weight:900;border-bottom:1px solid var(--mhd-border);user-select:none}
  .group-body{padding:8px 8px 10px}
  .field-row{display:grid;grid-template-columns:105px 1fr;gap:8px;align-items:center;margin-bottom:7px}
  .field-row:last-child{margin-bottom:0}
  label{font-size:13px;font-weight:900;color:var(--mhd-text);text-align:#{label_align};line-height:1.3}
  input[type=text],input[type=number],select{
    width:100%;height:30px;padding:4px 8px;border:none;border-radius:6px;
    background:var(--mhd-input);color:#fff;font-size:13px;outline:1px solid var(--mhd-border);text-align:center;
  }
  input[type=text]:focus,input[type=number]:focus,select:focus{outline:2px solid var(--mhd-accent);background:var(--mhd-input)}
  select{cursor:pointer}
  input[type=color]{width:100%;height:30px;padding:2px;border:1px solid var(--mhd-border);border-radius:6px;background:var(--mhd-input)}
  .switch-row{display:grid;grid-template-columns:105px 1fr;gap:8px;align-items:center;margin-bottom:7px}
  .toggle{
    height:30px;background:var(--mhd-input);border-radius:6px;outline:1px solid var(--mhd-border);
    display:flex;align-items:center;justify-content:space-between;padding:0 8px;
    cursor:pointer;user-select:none;color:#fff;font-size:12px;
  }
  .toggle:focus,.toggle:hover{outline:2px solid var(--mhd-accent);background:var(--mhd-input)}
  .toggle .dot{width:16px;height:16px;border-radius:50%;background:#355467;border:1px solid #57798a}
  .toggle.on .dot{background:var(--mhd-accent);border-color:var(--mhd-accent)}
  .collapsible{cursor:pointer;display:flex;align-items:center;justify-content:space-between}
  .collapsible .arrow{font-size:12px;transition:.2s}
  .group.closed .group-body{display:none}
  .group.closed .arrow{transform:rotate(90deg)}
  .conditional{display:none}
  .conditional.active{display:block}
  .patterns-scroll{display:flex;gap:8px;overflow-x:auto;overflow-y:hidden;padding:2px 2px 9px;scroll-behavior:smooth}
  .patterns-scroll::-webkit-scrollbar{height:8px}
  .patterns-scroll::-webkit-scrollbar-track{background:var(--mhd-app);border-radius:20px}
  .patterns-scroll::-webkit-scrollbar-thumb{background:var(--mhd-border);border-radius:20px;border:2px solid var(--mhd-app)}
  .pattern-card{flex:0 0 112px;background:var(--mhd-card);border:1px solid var(--mhd-border);border-radius:10px;padding:6px;cursor:pointer;text-align:center;transition:.15s;user-select:none}
  .pattern-card:hover{border-color:var(--mhd-accent);transform:translateY(-1px)}
  .pattern-card.active{border-color:var(--mhd-accent);box-shadow:0 0 0 1px rgba(8,201,195,.22);background:var(--mhd-panel)}
  .pattern-img{height:68px;border-radius:7px;background-size:cover;background-position:center;background-repeat:no-repeat;background-color:#182836;border:1px solid var(--mhd-border)}
  .pattern-name{font-size:11px;font-weight:900;color:var(--mhd-text);line-height:1.3;margin-top:6px;min-height:29px;display:flex;align-items:center;justify-content:center}
  .hint{font-size:11px;color:var(--mhd-muted);line-height:1.55;padding:4px 2px 0}
  .footer{height:58px;padding:8px 10px;border-top:1px solid var(--mhd-border);background:var(--mhd-app);display:flex;gap:8px}
  button{height:40px;border-radius:10px;font-size:14px;font-weight:900;cursor:pointer;border:none}
  .ok{flex:2;background:var(--mhd-bright);color:var(--mhd-ink)}
  .cancel{flex:1;background:var(--mhd-card);color:#fff;border:1px solid var(--mhd-border)}

  body { font-family: var(--mhd-font); color-scheme: dark; }
  button, input, select { font-family: inherit; min-width: 0; }
  button:focus-visible, [tabindex]:focus-visible { outline: 2px solid var(--mhd-bright); outline-offset: 2px; }
  .app > .hero, body > .hero { flex: none; height: auto; min-height: 74px; padding-inline: 12px; }
  .hero .logo, .head .logo {
    flex: 0 0 auto; width: 48px; height: 48px; padding: 4px;
    border-color: var(--mhd-border); background: var(--mhd-input);
  }
  .hero .head-text, .head .title { min-width: 0; }
  .hero .title-main, .hero .title, .head .title {
    font-size: clamp(16px, 4.8vw, 22px); line-height: 1.2; white-space: normal; overflow-wrap: anywhere;
  }
  .hero .subtitle, .hero .desc { height: auto; color: var(--mhd-muted); overflow-wrap: anywhere; }
  .wrap { padding: 12px; }
  .app > .wrap { flex: 1 1 0; height: auto; min-height: 0; }
  .group, .wall-block { border-radius: 12px; }
  .group-title, .gt, .panel-title {
    background: var(--mhd-section); color: var(--mhd-bright); border-bottom: 1px solid var(--mhd-border);
  }
  .field-row, .switch-row, .ignore-different-row {
    grid-template-columns: minmax(82px, 36%) minmax(0, 1fr);
  }
  .field-row > *, .switch-row > *, .ignore-different-row > * { min-width: 0; }
  .field-row label, .switch-row label { overflow-wrap: anywhere; }
  .footer, .foot { flex: none; height: auto; min-height: 56px; background: var(--mhd-panel); align-items: stretch; }
  .footer button, .foot button { min-width: 0; height: auto; min-height: 38px; padding: 5px 8px; overflow-wrap: anywhere; }
  .ok, .primary, .generate, .create, .add, .swap-units-btn {
    background: var(--mhd-primary); color: var(--mhd-ink);
  }
  .ok:hover, .primary:hover, .generate:hover:not(:disabled), .create:hover, .add:hover, .swap-units-btn:hover:not(:disabled) {
    background: var(--mhd-bright);
  }
  .cancel, .back, .pdf, .secondary, .edit {
    color: var(--mhd-text); background: var(--mhd-input); border: 1px solid var(--mhd-border);
  }
  .cancel:hover, .back:hover, .pdf:hover:not(:disabled), .secondary:hover, .edit:hover {
    background: var(--mhd-hover);
  }
  .shape.active, .side-btn.active, .mat-card.active, .pattern-card.active,
  .row-direction-btn.active, .type.active, .side button.active {
    color: var(--mhd-text); background: var(--mhd-active); border-color: var(--mhd-accent);
    box-shadow: none;
  }
  .mhd-tool-header {
    --mhd-tool-header-gradient: linear-gradient(110deg, #07111B 0%, #102635 58%, #075D63 100%);
    --mhd-tool-header-accent: #12D1CB;
    --mhd-tool-header-muted: #A8BED0;
  }
  .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
    position: relative; flex: none; display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 2.6fr) minmax(0, 1fr);
    align-items: center; gap: 12px; height: auto; min-height: 92px; padding: 10px 18px;
    overflow: hidden; direction: ltr; background: var(--mhd-tool-header-gradient);
    border-bottom: 1px solid var(--mhd-border);
  }
  .mhd-tool-header .brand {
    position: relative; z-index: 1; display: flex; align-items: center; gap: 8px;
    color: var(--mhd-text); letter-spacing: .07em;
  }
  .mhd-tool-header .brand .logo { display: block; flex: none; width: 36px; height: 36px; object-fit: contain; }
  .mhd-tool-header .brand .logo[hidden] { display: none; }
  .mhd-tool-header .brandName { font-size: 13px; }
  .mhd-tool-header .head-text, .mhd-tool-header > .title {
    position: relative; z-index: 1; min-width: 0; text-align: center; direction: ltr;
  }
  html[dir="rtl"] .mhd-tool-header .head-text, html[dir="rtl"] .mhd-tool-header > .title { direction: rtl; }
  .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 24px; font-weight: 800; line-height: 1.25; overflow-wrap: anywhere; }
  .mhd-tool-header .subtitle, .mhd-tool-header .desc {
    display: block; margin-top: 4px; color: var(--mhd-tool-header-muted);
    font-size: 12px; line-height: 1.35; font-weight: 400; overflow-wrap: anywhere;
  }
  .mhd-tool-header .cabinetDrawing {
    position: absolute; right: 10px; bottom: -8px; width: 130px; height: 82px;
    color: var(--mhd-tool-header-accent); opacity: .32; pointer-events: none;
  }
  @media (max-width: 620px) {
    .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
      grid-template-columns: 48px minmax(0, 1fr) 48px; gap: 8px;
      min-height: 72px; padding: 8px 10px;
    }
    .mhd-tool-header .brand { flex-direction: column; gap: 2px; }
    .mhd-tool-header .brand .logo { width: 30px; height: 30px; }
    .mhd-tool-header .brandName { font-size: 8px; letter-spacing: .03em; }
    .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 20px; }
    .mhd-tool-header .subtitle, .mhd-tool-header .desc { font-size: 11px; }
    .mhd-tool-header .cabinetDrawing { right: 4px; width: 70px; height: 52px; opacity: .18; }
  }
#{MHDESIGN_ResponsiveHeaderUI::CSS}
:root {
  --mhd-app: var(--ref-bg); --mhd-panel: var(--ref-panel); --mhd-card: var(--ref-panel);
  --mhd-input: var(--ref-input); --mhd-hover: var(--ref-section); --mhd-border: var(--ref-border);
  --mhd-text: var(--ref-text); --mhd-muted: var(--ref-muted); --mhd-accent: var(--ref-accent);
}
.group-title, .group[data-group] .group-title, .panel-title, .gt {
  background: var(--ref-section); color: var(--ref-text); border-color: var(--ref-border);
}
.ok, .add, .generate, .create, .swap-units-btn {
  background: var(--ref-action); color: var(--ref-bg);
}
</style>
</head>
<body>
<div class="app">
  <div class="hero mhd-tool-header mhd-ref-header">
    #{MHDESIGN_ResponsiveHeaderUI::BRAND}
    <div class="head-text">
      <div class="title-main">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_BUILD_MENU')}</div>
      <div class="subtitle">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_TOOL_CREDIT')}<br>Room Builder V3.3</div>
    </div>
  <!-- Dressing reference header artwork is included in BRAND. --></div>

  <div class="wrap">
    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DATA')}</div>
      <div class="group-body">
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_NAME')}</label><input id="room_name" type="text" value="#{v['room_name']}"></div>
      </div>
    </div>

    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DIMENSIONS')}</div>
      <div class="group-body">
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_WALL_HEIGHT')}</label><input id="wall_h" type="number" step="0.1" value="#{v['wall_h']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_WALL_THICKNESS')}</label><input id="wall_t" type="number" step="0.1" value="#{v['wall_t']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_FLOOR_THICKNESS')}</label><input id="floor_t" type="number" step="0.1" value="#{v['floor_t']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CEILING_THICKNESS')}</label><input id="ceil_t" type="number" step="0.1" value="#{v['ceil_t']}"></div>
      </div>
    </div>

    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_EXTRA_ELEMENTS')}</div>
      <div class="group-body">
        <div class="switch-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CREATE_FLOOR')}</label><div id="create_floor" class="toggle #{floor_on}" onclick="toggle(this)"><span>#{floor_txt}</span><b class="dot"></b></div></div>
        <div class="switch-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CREATE_CEILING')}</label><div id="create_ceiling" class="toggle #{ceil_on}" onclick="toggle(this)"><span>#{ceil_txt}</span><b class="dot"></b></div></div>
      </div>
    </div>

    <div id="ceiling_group" class="group">
      <div class="group-title collapsible" onclick="collapseGroup(this)"><span>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CEILING_OPTIONS')}</span><span class="arrow">▼</span></div>
      <div class="group-body">
        <input id="ceiling_pattern" type="hidden" value="#{v['ceiling_pattern']}">
        <div class="patterns-scroll">
          <div class="pattern-card #{v['ceiling_pattern']=='flat' ? 'active' : ''}" data-pattern="flat" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/1.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_FLAT')}</div></div>
          <div class="pattern-card #{v['ceiling_pattern']=='perimeter' ? 'active' : ''}" data-pattern="perimeter" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/2.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_PERIMETER')}</div></div>
          <div class="pattern-card #{v['ceiling_pattern']=='center' ? 'active' : ''}" data-pattern="center" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/3.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_CENTER')}</div></div>
          <div class="pattern-card #{v['ceiling_pattern']=='center_hidden_led' ? 'active' : ''}" data-pattern="center_hidden_led" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/4.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_CENTER_LED')}</div></div>
          <div class="pattern-card #{v['ceiling_pattern']=='double_hidden_led' ? 'active' : ''}" data-pattern="double_hidden_led" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/5.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_COMBINED')}</div></div>
          <div class="pattern-card #{v['ceiling_pattern']=='strips' ? 'active' : ''}" data-pattern="strips" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/7.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_STRIPS')}</div></div>
          <div class="pattern-card #{v['ceiling_pattern']=='hidden_cove' ? 'active' : ''}" data-pattern="hidden_cove" onclick="selectCeilingPattern(this)"><div class="pattern-img" style="background-image:url('https://mhdesign-eg.com/SKETCHUP022/wall/6.png')"></div><div class="pattern-name">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PATTERN_COVE')}</div></div>
        </div>
        <div id="drop_reference_row" class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DROP_REFERENCE')}</label>
          <select id="drop_reference">
            <option value="below_wall" #{v['drop_reference']=='below_wall' ? 'selected' : ''}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DROP_BELOW_WALL')}</option>
            <option value="wall_is_finish" #{v['drop_reference']=='wall_is_finish' ? 'selected' : ''}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DROP_WALL_FINISH')}</option>
          </select>
        </div>
        <div id="drop_reference_hint" class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DROP_HINT')}</div>

        <div id="opts_flat" class="conditional">
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_FLAT_HINT')}</div>
        </div>

        <div id="opts_perimeter" class="conditional">
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_FRAME_WIDTH')}</label><input id="perimeter_width" type="number" step="0.1" value="#{v['perimeter_width']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_FRAME_DROP')}</label><input id="perimeter_drop" type="number" step="0.1" value="#{v['perimeter_drop']}"></div>
        </div>

        <div id="opts_center" class="conditional">
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CENTER_INSET')}</label><input id="center_inset" type="number" step="0.1" value="#{v['center_inset']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CENTER_DROP')}</label><input id="center_drop" type="number" step="0.1" value="#{v['center_drop']}"></div>
        </div>

        <div id="opts_center_hidden_led" class="conditional">
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_ISLAND_INSET')}</label><input id="center_led_inset" type="number" step="0.1" value="#{v['center_led_inset']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DROP_AMOUNT')}</label><input id="center_led_drop" type="number" step="0.1" value="#{v['center_led_drop']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_ISLAND_THICKNESS')}</label><input id="center_led_thickness" type="number" step="0.1" value="#{v['center_led_thickness']}"></div>
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CENTER_LED_HINT')}</div>
        </div>

        <div id="opts_double_hidden_led" class="conditional">
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_PERIMETER_COVE')}</div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_COVE_WIDTH')}</label><input id="combo_cove_width" type="number" step="0.1" value="#{v['combo_cove_width']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_COVE_DROP')}</label><input id="combo_cove_drop" type="number" step="0.1" value="#{v['combo_cove_drop']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_HAND_PROJECTION')}</label><input id="combo_cove_lip_width" type="number" step="0.1" value="#{v['combo_cove_lip_width']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_HAND_THICKNESS')}</label><input id="combo_cove_lip_height" type="number" step="0.1" value="#{v['combo_cove_lip_height']}"></div>
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CENTER_ISLAND')}</div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_ISLAND_INSET')}</label><input id="combo_center_inset" type="number" step="0.1" value="#{v['combo_center_inset']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_ISLAND_DROP')}</label><input id="combo_center_drop" type="number" step="0.1" value="#{v['combo_center_drop']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_ISLAND_THICKNESS')}</label><input id="combo_center_thickness" type="number" step="0.1" value="#{v['combo_center_thickness']}"></div>
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_COMBINED_HINT')}</div>
        </div>

        <div id="opts_strips" class="conditional">
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_STRIP_DIRECTION')}</label><select id="strip_direction"><option value="longitudinal" #{longitudinal_value?(v['strip_direction']) ? 'selected' : ''}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LONGITUDINAL')}</option><option value="transverse" #{longitudinal_value?(v['strip_direction']) ? '' : 'selected'}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_TRANSVERSE')}</option></select></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_STRIP_COUNT')}</label><input id="strip_count" type="number" min="1" max="20" step="1" value="#{v['strip_count']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_STRIP_WIDTH')}</label><input id="strip_width" type="number" step="0.1" value="#{v['strip_width']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_STRIP_GAP')}</label><input id="strip_gap" type="number" step="0.1" value="#{v['strip_gap']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_STRIP_DROP')}</label><input id="strip_drop" type="number" step="0.1" value="#{v['strip_drop']}"></div>
        </div>

        <div id="opts_hidden_cove" class="conditional">
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_COVE_WIDTH')}</label><input id="cove_inset" type="number" step="0.1" value="#{v['cove_inset']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_DROP_AMOUNT_ALT')}</label><input id="cove_drop" type="number" step="0.1" value="#{v['cove_drop']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_HAND_PROJECTION')}</label><input id="cove_lip_width" type="number" step="0.1" value="#{v['cove_lip_width']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_HAND_THICKNESS')}</label><input id="cove_lip_height" type="number" step="0.1" value="#{v['cove_lip_height']}"></div>
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_COVE_HINT')}</div>
        </div>
      </div>
    </div>

    <div id="light_group" class="group">
      <div class="group-title collapsible" onclick="collapseGroup(this)"><span>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LIGHT_EFFECT')}</span><span class="arrow">▼</span></div>
      <div class="group-body">
        <div class="switch-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LIGHT_ENABLE')}</label><div id="light_enabled" class="toggle #{light_on}" onclick="toggle(this);updateLight()"><span>#{light_txt}</span><b class="dot"></b></div></div>
        <div id="light_options">
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LIGHT_METHOD')}</label><select id="light_mode"><option value="groove" #{v['light_mode']=='groove' ? 'selected' : ''}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_GROOVE_ONLY')}</option><option value="effect" #{v['light_mode']=='effect' ? 'selected' : ''}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_EFFECT_ONLY')}</option><option value="both" #{v['light_mode']=='both' ? 'selected' : ''}>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_GROOVE_EFFECT')}</option></select></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LIGHT_INSET')}</label><input id="light_inset" type="number" step="0.1" value="#{v['light_inset']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_GROOVE_WIDTH')}</label><input id="light_width" type="number" step="0.1" value="#{v['light_width']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_GROOVE_DEPTH')}</label><input id="light_depth" type="number" step="0.1" value="#{v['light_depth']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_START_MARGIN')}</label><input id="light_margin" type="number" step="0.1" value="#{v['light_margin']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_EFFECT_COLOR')}</label><input id="light_color" type="color" value="#{v['light_color']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LIGHT_INTENSITY')}</label><input id="glow_intensity" type="number" min="0" max="100" step="1" value="#{v['glow_intensity']}"></div>
          <div class="field-row"><label>#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_GLOW_SIZE')}</label><input id="glow_size" type="number" min="0" step="0.5" value="#{v['glow_size']}"></div>
          <div class="hint">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_LIGHT_HINT')}</div>
        </div>
      </div>
    </div>

  </div>

  <div class="footer">
    <button class="ok" onclick="submitData()">#{MHDESIGN::Language.for_tool('room_builder').html('ROOM_CREATE')}</button>
    <button class="cancel" onclick="sketchup.cancel()">#{MHDESIGN::Language.for_tool('room_builder').html('COMMON_CANCEL')}</button>
  </div>
</div>

<script>

// Visual UI protection: disable the context menu and element dragging.
document.addEventListener('contextmenu', function(event){
  event.preventDefault();
});
document.addEventListener('dragstart', function(event){
  event.preventDefault();
});
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
    wall_h: val('wall_h'),
    wall_t: val('wall_t'),
    floor_t: val('floor_t'),
    ceil_t: val('ceil_t'),
    create_floor: yesNo('create_floor'),
    create_ceiling: yesNo('create_ceiling'),
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

    dlg.add_action_callback('cancel') do
      dlg.close
    end

    dlg.add_action_callback('submit') do |_, json|
      data = JSON.parse(json)
      save_values(data)
      dlg.close
      build_from_data(data)
    rescue => e
      UI.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
    end

    dlg.show
    nil
  end

  # -------------------------
  # Build Room
  # -------------------------
  def build_ceiling(model, room_ents, room_name, room_uuid, outer_pts, room_pts,
                    wall_h, ceil_t, ceil_t_cm, data)
    pattern = data['ceiling_pattern'].to_s
    pattern = 'flat' unless %w[flat perimeter center center_hidden_led double_hidden_led strips hidden_cove].include?(pattern)
    common = {
      'Room_UUID' => room_uuid, 'النوع' => 'سقف', 'اسم الغرفة' => room_name,
      'نمط السقف' => pattern, 'السمك سم' => ceil_t_cm
    }
    # One parent component and one tag control the complete ceiling. Every
    # generated piece remains a nested component on Layer0 inside it.
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
    # below_wall: wall_h is the structural ceiling level.
    # wall_is_finish: wall_h is the clear height below the decorative drop.
    base_z = (pattern != 'flat' && drop_reference == 'wall_is_finish') ? wall_h + selected_drop : wall_h
    common['طريقة حساب السقوط'] = drop_reference

    # The structural/top slab is always retained. Decorative dropped parts are
    # separate components so they can be hidden, re-materialed or deleted.
    add_poly_component(model, room_ents, ts('السقف الأساسي'), nil,
                       outer_pts, base_z, ceil_t, common.merge('الجزء' => 'أساسي'))

    light_reference = { kind: :perimeter, source_pts: room_pts,
                        distance: data['light_inset'].to_f.cm,
                        underside_z: base_z, strips: [] }

    case pattern
    when 'perimeter'
      width = [data['perimeter_width'].to_f.cm, 1.cm].max
      drop = selected_drop
      # The visible width starts at the INNER wall face (room_pts), not at the
      # outside of the wall slab (outer_pts).
      inner = offset_polygon(room_pts, width)
      if polygon_usable?(inner)
        add_ring_component(model, room_ents, ts('السقف الساقط المحيطي'),
                           nil, outer_pts, inner,
                           base_z - drop, drop, common.merge(
                             'الجزء' => 'إطار محيطي', 'عرض الإطار سم' => data['perimeter_width'].to_f,
                             'مقدار النزول سم' => data['perimeter_drop'].to_f))
        # The LED follows the inner edge of the dropped frame.
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

        # The visible floating island. Its thin outer shelf hides the LED from below.
        add_poly_component(model, room_ents, ts('جزيرة السقف الساقطة'), nil,
                           island, panel_bottom_z, panel_thickness,
                           common.merge('الجزء' => 'جزيرة ساقطة بليد مخفي',
                                        'الارتداد سم' => data['center_led_inset'].to_f,
                                        'مقدار النزول سم' => data['center_led_drop'].to_f,
                                        'سمك لوح الجزيرة سم' => data['center_led_thickness'].to_f))

        # A smaller concealed core connects the island to the structural ceiling,
        # leaving a clear recess around the perimeter for the hidden LED.
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

        # 1) The real hidden-cove body: a dropped perimeter box attached to walls.
        add_ring_component(model, room_ents, ts('صندوق بيت النور المحيطي'), nil,
                           outer_pts, box_inner, box_bottom_z, drop,
                           common.merge('الجزء' => 'صندوق بيت نور محيطي',
                                        'عرض بيت النور سم' => data['cove_inset'].to_f,
                                        'مقدار النزول سم' => data['cove_drop'].to_f))

        # 2) A thin horizontal hand projects inward from the lower inner edge.
        # The LED sits on top of it and is hidden from the room view.
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
    # The old horizontal colored solid has been removed completely. Only one
    # continuous vertical alpha-gradient remains, with no bands or black edges.
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

    room_group = model.active_entities.add_group
    room_group.name = room_name
    room_group.layer = tag(model, room_name)

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

    model.commit_operation
    UI.messagebox(ts('تم بناء الغرفة بنجاح'))
  rescue => e
    model.abort_operation rescue nil
    UI.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
  end

  def build
    dialog_input
  end

  unless file_loaded?(__FILE__)
    UI.add_context_menu_handler do |menu|
      if selected_face
        menu.add_separator
        menu.add_item(ts(MENU_BUILD)) { build }
      end
    end

    file_loaded(__FILE__)
  end
end
# ==================== MHDESIGN SHOP DRAWING LANGUAGE BRIDGE ====================
module MHDESIGN_SHOP_LANG
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
      MHDESIGN::Language.for_tool('shop_drawing').t(key_name.to_s, fallback_text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? key_name.to_s : fallback.to_s
  end

  def source_map
    return {} unless defined?(MHDESIGN::Language)
    payload = MHDESIGN::Language.for_tool('shop_drawing').ui_payload
    payload[:source_map] || payload['source_map'] || {}
  rescue
    {}
  end

  def texts
    return {} unless defined?(MHDESIGN::Language)
    payload = MHDESIGN::Language.for_tool('shop_drawing').ui_payload
    payload[:texts] || payload['texts'] || {}
  rescue
    {}
  end

  def t(value, fallback = nil)
    text = value.to_s
    fallback_text = fallback.nil? ? text : fallback.to_s
    return fallback_text if text.empty?

    if text.start_with?('SHOP_')
      return key(text, fallback_text)
    end

    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('shop_drawing').translate_source(text)
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
# ==============================================================================

module MHDESIGN
  module InteractiveShopDrawing
    extend self

    DIALOG_TITLE   = MHDESIGN_SHOP_LANG.key('SHOP_DIALOG_TITLE', 'MHDESIGN - Shop Drawing').freeze
    MENU_TITLE     = MHDESIGN_SHOP_LANG.key('SHOP_MENU_TITLE', 'إنشاء الشوب دروينج').freeze
    LOGO_URL       = 'https://raw.githubusercontent.com/eng-marwanadel/EN/refs/heads/main/links/logo3.png'.freeze
    PREF_KEY       = 'MHDESIGN_SHOP_DRAWING'.freeze
    DICT           = 'MHD_SHOP_DRAWING'.freeze
    SCENE_PREFIX   = 'MHD SHOP'.freeze
    BASE_SCENE_NAME = MHDESIGN_SHOP_LANG.key('SHOP_BASE_SCENE_NAME', 'MHD SHOP 00 - المشهد الأساسي').freeze
    ANNO_PREFIX    = '__MHD_SHOP_ANNOTATIONS__'.freeze
    TAG_PREFIX     = 'MHD SHOP ANNO'.freeze
    SECTION_PREFIX = '__MHD_SHOP_SECTION__'.freeze
    SECTION_TAG_PREFIX = 'MHD SHOP SECTION'.freeze
    CM             = 1.0 / 2.54
    SECTION_CUT_DEPTH = 80.0 * CM

    @dialog = nil
    @levels_count = 3
    @current_level = 1
    @levels = {}
    @sections_count = 0
    @current_section = 1
    @sections = {}
    @selection_mode = :level
    @wall_group_ref = nil
    @wall_select_mode = false
    @selection_timer = nil
    @run_token = nil
    @busy = false
    @model_observer = nil
    @edit_group = nil
    @dialog_mode = nil
    @edit_group_pid = nil
    @pdf_parent_directory = nil
    @pdf_project_directory = nil
    @pdf_exported_scenes = []
    @pdf_export_timer = nil
    @pdf_export_state = nil

    # --------------------------------------------------------
    # Entry point
    # --------------------------------------------------------
    def run
      model = Sketchup.active_model
      return MHDESIGN_SHOP_LANG.messagebox(MHDESIGN_SHOP_LANG.key('SHOP_NO_MODEL', 'لا يوجد موديل مفتوح.')) unless model

      @edit_group = selected_annotation_group(model)
      reset_session unless @edit_group
      install_model_observer(model)
      show_dialog
    end

    def selected_annotation_group(model = Sketchup.active_model)
      return nil unless model

      model.selection.to_a.find do |entity|
        entity.is_a?(Sketchup::Group) &&
          entity.valid? &&
          entity.get_attribute(DICT, 'annotation_group', false) == true
      end
    rescue
      nil
    end

    def reset_session
      @levels_count = Sketchup.read_default(PREF_KEY, 'levels_count', 3).to_i
      @levels_count = 3 unless (1..10).include?(@levels_count)
      @current_level = 1
      @levels = {}
      @sections_count = Sketchup.read_default(PREF_KEY, 'sections_count', 0).to_i
      @sections_count = 0 unless (0..4).include?(@sections_count)
      @current_section = 1
      @sections = {}
      @selection_mode = :level
    end

    # --------------------------------------------------------
    # Dialog
    # --------------------------------------------------------
    def show_dialog
      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      edit_mode = @edit_group && @edit_group.valid?
      @dialog_mode = edit_mode ? :edit : :create
      @edit_group_pid = edit_mode ? safe_persistent_id(@edit_group) : nil

      @dialog = UI::HtmlDialog.new(
        dialog_title: edit_mode ?
          MHDESIGN_SHOP_LANG.key('SHOP_EDIT_DIALOG_TITLE', 'MHDESIGN - تعديل الشوب دروينج') :
          DIALOG_TITLE,
        preferences_key: 'MHDESIGN_InteractiveShopDrawing',
        scrollable: false,
        resizable: true,
        width: edit_mode ? 350 : 350,
        height: edit_mode ? 530 : 745,
        left: 80,
        top: 100,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      @dialog.set_html(edit_mode ? edit_dialog_html(@edit_group) : dialog_html)
      attach_callbacks
      @dialog.set_on_closed { stop_selection_timer }
      @dialog.show
      # HtmlDialog preferences may restore the large PDF report size from a previous run.
      # Force the normal tool pages back to their compact dimensions after the window is visible.
      UI.start_timer(0.05, false) do
        begin
          @dialog.set_size(350, edit_mode ? 530 : 745) if @dialog && @dialog.visible? && @dialog.respond_to?(:set_size)
        rescue
        end
      end
      start_selection_timer
    end

    def edit_dialog_html(group)
      level = group.get_attribute(DICT, 'level', '?')
      dim_count = group.entities.grep(Sketchup::DimensionLinear).length
      text_count = group.entities.grep(Sketchup::Text).count do |item|
        item.get_attribute(DICT, 'annotation_type', '') == 'unit_name'
      end

      dimension_color = group.get_attribute(DICT, 'dimension_color', 'black').to_s
      label_color = group.get_attribute(DICT, 'label_color', 'black').to_s

      <<~HTML
      <!DOCTYPE html>
      <html lang="#{MHDESIGN_SHOP_LANG.current}" dir="#{MHDESIGN_SHOP_LANG.direction}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{MHDESIGN_SHOP_LANG.key('SHOP_EDIT_TITLE', 'تعديل ألوان الشوب دروينج')}</title>
        <style>
  :root {
    --mhd-app: #0B111A;
    --mhd-panel: #111F2C;
    --mhd-card: #172633;
    --mhd-input: #101923;
    --mhd-hover: #253443;
    --mhd-border: #34495B;
    --mhd-text: #F4F7FA;
    --mhd-muted: #A6B5C3;
    --mhd-accent: #08C9C3;
    --mhd-bright: #27E5DC;
    --mhd-ink: #04191C;
    --mhd-header: linear-gradient(110deg, #07111B 0%, #102332 60%, #075C62 100%);
    --mhd-primary: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
    --mhd-active: linear-gradient(135deg, #063C44 0%, #087D80 100%);
    --mhd-section: linear-gradient(145deg, #1D3040 0%, #111E2B 100%);
    --mhd-font: Cairo, Tajawal, "Segoe UI", Tahoma, sans-serif;
  }
          *{box-sizing:border-box}
          body{margin:0;font-family:Arial,Tahoma,sans-serif;background:var(--mhd-app);color:var(--mhd-text);overflow:hidden}
          .app{height:100vh;display:flex;flex-direction:column}
          .hero{height:74px;padding:10px 12px;display:flex;align-items:center;gap:10px;background:var(--mhd-header);border-bottom:1px solid var(--mhd-border)}
          .logo{width:58px;height:58px;object-fit:contain;background:var(--mhd-panel);border:1px solid var(--mhd-border);border-radius:10px;padding:5px}
          .head-text{flex:1;text-align:center;overflow:hidden}
          .title-main{font-size:18px;font-weight:900;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
          .subtitle{margin-top:5px;font-size:11px;color:var(--mhd-muted);line-height:1.5}
          .wrap{height:calc(100vh - 74px - 58px);overflow:auto;padding:10px}
          .group{background:var(--mhd-card);border:1px solid var(--mhd-border);border-radius:10px;margin-bottom:10px;overflow:visible}
          .group-title{padding:10px;background:var(--mhd-panel);color:var(--mhd-accent);font-size:16px;font-weight:900;border-bottom:1px solid var(--mhd-border);border-radius:10px 10px 0 0}
          .group-body{padding:12px}
          .field-row{display:grid;grid-template-columns:105px 1fr;gap:8px;align-items:center}
          label{font-size:13px;font-weight:900;color:var(--mhd-text)}
          .color-select{position:relative}
          .color-button{width:100%;height:38px;border-radius:8px;border:1px solid var(--mhd-border);background:var(--mhd-input);display:flex;align-items:center;justify-content:space-between;padding:5px 9px;cursor:pointer}
          .color-button:hover,.color-button.open{border-color:var(--mhd-accent);box-shadow:0 0 0 1px var(--mhd-accent)}
          .selected-swatch{width:56px;height:24px;border-radius:5px;border:2px solid rgba(255,255,255,.38);box-shadow:inset 0 0 0 1px rgba(0,0,0,.35)}
          .arrow{color:var(--mhd-muted);font-size:13px}
          .palette{position:absolute;top:43px;right:0;left:0;z-index:100;background:var(--mhd-panel);border:1px solid var(--mhd-border);border-radius:9px;padding:9px;display:none;grid-template-columns:repeat(4,1fr);gap:9px;box-shadow:0 12px 28px rgba(0,0,0,.45)}
          html[dir='ltr'] .palette{right:0;left:0}
          .palette.open{display:grid}
          .swatch{height:34px;border-radius:7px;border:2px solid rgba(255,255,255,.28);cursor:pointer;box-shadow:inset 0 0 0 1px rgba(0,0,0,.25)}
          .swatch:hover,.swatch.active{border-color:#fff;transform:scale(1.05)}
          .status{font-size:12px;color:var(--mhd-bright);text-align:center;min-height:18px;margin-top:7px}
          .footer{height:58px;padding:8px 10px;border-top:1px solid var(--mhd-border);display:flex;gap:8px}
          button.action{height:40px;border-radius:10px;font-size:14px;font-weight:900;cursor:pointer;border:none}
          .ok{flex:2;background:var(--mhd-bright);color:var(--mhd-ink)}
          .cancel{flex:1;background:var(--mhd-card);color:#fff;border:1px solid var(--mhd-border)!important}

  body { font-family: var(--mhd-font); color-scheme: dark; }
  button, input, select { font-family: inherit; min-width: 0; }
  button:focus-visible, [tabindex]:focus-visible { outline: 2px solid var(--mhd-bright); outline-offset: 2px; }
  .app > .hero, body > .hero { flex: none; height: auto; min-height: 74px; padding-inline: 12px; }
  .hero .logo, .head .logo {
    flex: 0 0 auto; width: 48px; height: 48px; padding: 4px;
    border-color: var(--mhd-border); background: var(--mhd-input);
  }
  .hero .head-text, .head .title { min-width: 0; }
  .hero .title-main, .hero .title, .head .title {
    font-size: clamp(16px, 4.8vw, 22px); line-height: 1.2; white-space: normal; overflow-wrap: anywhere;
  }
  .hero .subtitle, .hero .desc { height: auto; color: var(--mhd-muted); overflow-wrap: anywhere; }
  .wrap { padding: 12px; }
  .app > .wrap { flex: 1 1 0; height: auto; min-height: 0; }
  .group, .wall-block { border-radius: 12px; }
  .group-title, .gt, .panel-title {
    background: var(--mhd-section); color: var(--mhd-bright); border-bottom: 1px solid var(--mhd-border);
  }
  .field-row, .switch-row, .ignore-different-row {
    grid-template-columns: minmax(82px, 36%) minmax(0, 1fr);
  }
  .field-row > *, .switch-row > *, .ignore-different-row > * { min-width: 0; }
  .field-row label, .switch-row label { overflow-wrap: anywhere; }
  .footer, .foot { flex: none; height: auto; min-height: 56px; background: var(--mhd-panel); align-items: stretch; }
  .footer button, .foot button { min-width: 0; height: auto; min-height: 38px; padding: 5px 8px; overflow-wrap: anywhere; }
  .ok, .primary, .generate, .create, .add, .swap-units-btn {
    background: var(--mhd-primary); color: var(--mhd-ink);
  }
  .ok:hover, .primary:hover, .generate:hover:not(:disabled), .create:hover, .add:hover, .swap-units-btn:hover:not(:disabled) {
    background: var(--mhd-bright);
  }
  .cancel, .back, .pdf, .secondary, .edit {
    color: var(--mhd-text); background: var(--mhd-input); border: 1px solid var(--mhd-border);
  }
  .cancel:hover, .back:hover, .pdf:hover:not(:disabled), .secondary:hover, .edit:hover {
    background: var(--mhd-hover);
  }
  .shape.active, .side-btn.active, .mat-card.active, .pattern-card.active,
  .row-direction-btn.active, .type.active, .side button.active {
    color: var(--mhd-text); background: var(--mhd-active); border-color: var(--mhd-accent);
    box-shadow: none;
  }
          .mhd-tool-header {
            --mhd-tool-header-gradient: linear-gradient(110deg, #07111B 0%, #102635 58%, #075D63 100%);
            --mhd-tool-header-accent: #12D1CB;
            --mhd-tool-header-muted: #A8BED0;
          }
          .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
            position: relative; flex: none; display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 2.6fr) minmax(0, 1fr);
            align-items: center; gap: 12px; height: auto; min-height: 92px; padding: 10px 18px;
            overflow: hidden; direction: ltr; background: var(--mhd-tool-header-gradient);
            border-bottom: 1px solid var(--mhd-border);
          }
          .mhd-tool-header .brand {
            position: relative; z-index: 1; display: flex; align-items: center; gap: 8px;
            color: var(--mhd-text); letter-spacing: .07em;
          }
          .mhd-tool-header .brand .logo { display: block; flex: none; width: 36px; height: 36px; object-fit: contain; }
          .mhd-tool-header .brand .logo[hidden] { display: none; }
          .mhd-tool-header .brandName { font-size: 13px; }
          .mhd-tool-header .head-text, .mhd-tool-header > .title {
            position: relative; z-index: 1; min-width: 0; text-align: center; direction: ltr;
          }
          html[dir="rtl"] .mhd-tool-header .head-text, html[dir="rtl"] .mhd-tool-header > .title { direction: rtl; }
          .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 24px; font-weight: 800; line-height: 1.25; overflow-wrap: anywhere; }
          .mhd-tool-header .subtitle, .mhd-tool-header .desc {
            display: block; margin-top: 4px; color: var(--mhd-tool-header-muted);
            font-size: 12px; line-height: 1.35; font-weight: 400; overflow-wrap: anywhere;
          }
          .mhd-tool-header .cabinetDrawing {
            position: absolute; right: 10px; bottom: -8px; width: 130px; height: 82px;
            color: var(--mhd-tool-header-accent); opacity: .32; pointer-events: none;
          }
          @media (max-width: 620px) {
            .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
              grid-template-columns: 48px minmax(0, 1fr) 48px; gap: 8px;
              min-height: 72px; padding: 8px 10px;
            }
            .mhd-tool-header .brand { flex-direction: column; gap: 2px; }
            .mhd-tool-header .brand .logo { width: 30px; height: 30px; }
            .mhd-tool-header .brandName { font-size: 8px; letter-spacing: .03em; }
            .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 20px; }
            .mhd-tool-header .subtitle, .mhd-tool-header .desc { font-size: 11px; }
            .mhd-tool-header .cabinetDrawing { right: 4px; width: 70px; height: 52px; opacity: .18; }
          }
        #{MHDESIGN_ResponsiveHeaderUI::CSS}
:root {
  --mhd-app: var(--ref-bg); --mhd-panel: var(--ref-panel); --mhd-card: var(--ref-panel);
  --mhd-input: var(--ref-input); --mhd-hover: var(--ref-section); --mhd-border: var(--ref-border);
  --mhd-text: var(--ref-text); --mhd-muted: var(--ref-muted); --mhd-accent: var(--ref-accent);
}
.group-title, .group[data-group] .group-title, .panel-title, .gt {
  background: var(--ref-section); color: var(--ref-text); border-color: var(--ref-border);
}
.ok, .add, .generate, .create, .swap-units-btn {
  background: var(--ref-action); color: var(--ref-bg);
}
        </style>
      </head>
      <body oncontextmenu="return false;">
        <div class="app">
          <div class="hero mhd-tool-header mhd-ref-header">
            #{MHDESIGN_ResponsiveHeaderUI::BRAND}
            <div class="head-text">
              <div class="title-main">#{MHDESIGN_SHOP_LANG.key('SHOP_EDIT_TITLE', 'تعديل ألوان الشوب دروينج')}</div>
              <div class="subtitle">
                #{MHDESIGN_SHOP_LANG.key('SHOP_EDIT_SELECTED_LEVEL', 'المستوى المحدد')}: #{level}<br>
                #{dim_count} #{MHDESIGN_SHOP_LANG.key('SHOP_DIMENSIONS', 'مقاسات')} — #{text_count} #{MHDESIGN_SHOP_LANG.key('SHOP_LABELS', 'مسميات')}
              </div>
            </div>
          <!-- Dressing reference header artwork is included in BRAND. --></div>

          <div class="wrap">
            <div class="group">
              <div class="group-title">▼ #{MHDESIGN_SHOP_LANG.key('SHOP_DIMENSIONS', 'المقاسات')}</div>
              <div class="group-body">
                <div class="field-row">
                  <label>#{MHDESIGN_SHOP_LANG.key('SHOP_FONT_COLOR', 'لون الخط')}</label>
                  #{visual_color_dropdown('dimension_color', dimension_color)}
                </div>
              </div>
            </div>

            <div class="group">
              <div class="group-title">▼ #{MHDESIGN_SHOP_LANG.key('SHOP_LABELS', 'المسميات')}</div>
              <div class="group-body">
                <div class="field-row">
                  <label>#{MHDESIGN_SHOP_LANG.key('SHOP_FONT_COLOR', 'لون الخط')}</label>
                  #{visual_color_dropdown('label_color', label_color)}
                </div>
              </div>
            </div>

            <div id="status" class="status"></div>
          </div>

          <div class="footer">
            <button class="action ok" onclick="applyStyle()">#{MHDESIGN_SHOP_LANG.key('SHOP_APPLY', 'تطبيق')}</button>
            <button class="action cancel" onclick="sketchup.close_editor()">#{MHDESIGN_SHOP_LANG.key('SHOP_CLOSE', 'إغلاق')}</button>
          </div>
        </div>

        <script>
          const selectedColors = {
            dimension_color: #{dimension_color.to_json},
            label_color: #{label_color.to_json}
          };

          function togglePalette(id){
            const palette = document.getElementById(id + '_palette');
            const button = document.getElementById(id + '_button');
            document.querySelectorAll('.palette').forEach(p=>{ if(p!==palette) p.classList.remove('open'); });
            document.querySelectorAll('.color-button').forEach(b=>{ if(b!==button) b.classList.remove('open'); });
            palette.classList.toggle('open');
            button.classList.toggle('open');
          }

          function chooseColor(id, value, hex){
            selectedColors[id] = value;
            document.getElementById(id + '_selected').style.background = hex;
            document.getElementById(id + '_palette').classList.remove('open');
            document.getElementById(id + '_button').classList.remove('open');
            document.querySelectorAll('#' + id + '_palette .swatch').forEach(el=>{
              el.classList.toggle('active', el.dataset.value === value);
            });
          }

          document.addEventListener('click', function(event){
            if(!event.target.closest('.color-select')){
              document.querySelectorAll('.palette,.color-button').forEach(el=>el.classList.remove('open'));
            }
          });

          function applyStyle(){
            sketchup.apply_selected_group_style(JSON.stringify({
              dimension_color: selectedColors.dimension_color,
              label_color: selectedColors.label_color
            }));
          }

          function setStatus(text, ok){
            const el = document.getElementById('status');
            el.style.color = ok ? '#4de37a' : '#ff8c8c';
            el.textContent = text || '';
          }
        </script>
      </body>
      </html>
      HTML
    end

    def visual_color_dropdown(id, selected)
      colors = editor_colors
      selected_entry = colors.find { |item| item[0] == selected.to_s } || colors.first
      swatches = colors.map do |value, hex, translated_title|
        active = value == selected_entry[0] ? ' active' : ''
        %(<button type="button" class="swatch#{active}" data-value="#{value}" title="#{translated_title}" style="background:#{hex}" onclick="chooseColor('#{id}','#{value}','#{hex}')"></button>)
      end.join

      <<~HTML
      <div class="color-select">
        <button type="button" class="color-button" id="#{id}_button" onclick="togglePalette('#{id}')">
          <span class="selected-swatch" id="#{id}_selected" style="background:#{selected_entry[1]}"></span>
          <span class="arrow">▼</span>
        </button>
        <div class="palette" id="#{id}_palette">#{swatches}</div>
      </div>
      HTML
    end

    def editor_colors
      [
        ['black',  '#000000', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_BLACK', 'أسود')],
        ['dark_gray', '#404040', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_DARK_GRAY', 'رمادي داكن')],
        ['gray',   '#808080', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_GRAY', 'رمادي')],
        ['white',  '#FFFFFF', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_WHITE', 'أبيض')],
        ['red',    '#E53935', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_RED', 'أحمر')],
        ['blue',   '#1976D2', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_BLUE', 'أزرق')],
        ['green',  '#2EAD5B', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_GREEN', 'أخضر')],
        ['yellow', '#F4C430', MHDESIGN_SHOP_LANG.key('SHOP_COLOR_YELLOW', 'أصفر')]
      ]
    end

    def dialog_html
      level_options = (1..6).map do |n|
        selected = n == @levels_count ? 'selected' : ''
        "<option value='#{n}' #{selected}>#{n}</option>"
      end.join

      section_options = (0..4).map do |n|
        selected = n == @sections_count ? 'selected' : ''
        "<option value='#{n}' #{selected}>#{n}</option>"
      end.join

      <<~HTML
      <!DOCTYPE html>
      <html lang="#{MHDESIGN_SHOP_LANG.current}" dir="#{MHDESIGN_SHOP_LANG.direction}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{MHDESIGN::Language.for_tool('shop_drawing').html(DIALOG_TITLE)}</title>
        <style>
  :root {
    --mhd-app: #0B111A;
    --mhd-panel: #111F2C;
    --mhd-card: #172633;
    --mhd-input: #101923;
    --mhd-hover: #253443;
    --mhd-border: #34495B;
    --mhd-text: #F4F7FA;
    --mhd-muted: #A6B5C3;
    --mhd-accent: #08C9C3;
    --mhd-bright: #27E5DC;
    --mhd-ink: #04191C;
    --mhd-header: linear-gradient(110deg, #07111B 0%, #102332 60%, #075C62 100%);
    --mhd-primary: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
    --mhd-active: linear-gradient(135deg, #063C44 0%, #087D80 100%);
    --mhd-section: linear-gradient(145deg, #1D3040 0%, #111E2B 100%);
    --mhd-font: Cairo, Tajawal, "Segoe UI", Tahoma, sans-serif;
  }
          *{box-sizing:border-box}
          body{
            margin:0;
            font-family:Arial,Tahoma,sans-serif;
            background:var(--mhd-app);
            color:var(--mhd-text);
            overflow:hidden;
          }
          ::-webkit-scrollbar{width:8px}
          ::-webkit-scrollbar-track{background:var(--mhd-app)}
          ::-webkit-scrollbar-thumb{
            background:var(--mhd-border);
            border-radius:20px;
            border:2px solid var(--mhd-app);
          }
          ::-webkit-scrollbar-thumb:hover{background:var(--mhd-hover)}
          .app{
            height:100vh;
            display:flex;
            flex-direction:column;
            background:var(--mhd-app);
          }
          .hero{
            height:74px;
            padding:10px 12px;
            display:flex;
            align-items:center;
            gap:10px;
            background:var(--mhd-header);
            border-bottom:1px solid var(--mhd-border);
          }
          .logo{
            width:58px;
            height:58px;
            object-fit:contain;
            background:var(--mhd-panel);
            border:1px solid var(--mhd-border);
            border-radius:10px;
            padding:5px;
            flex:0 0 auto;
          }
          .head-text{flex:1;overflow:hidden;text-align:center}
          .title-main{
            font-size:19px;
            font-weight:900;
            color:#fff;
            white-space:nowrap;
            overflow:hidden;
            text-overflow:ellipsis;
            line-height:1.2;
          }
          .subtitle{
            margin-top:6px;
            font-size:11px;
            line-height:1.5;
            color:var(--mhd-muted);
            height:32px;
            overflow:hidden;
          }
          .wrap{
            height:calc(100vh - 74px - 58px);
            overflow:auto;
            padding:10px;
            background:var(--mhd-app);
          }
          .group{
            background:var(--mhd-card);
            border:1px solid var(--mhd-border);
            border-radius:10px;
            margin-bottom:10px;
            overflow:hidden;
          }
          .group-title{
            padding:9px 10px;
            background:var(--mhd-panel);
            color:var(--mhd-accent);
            font-size:15px;
            font-weight:900;
            border-bottom:1px solid var(--mhd-border);
            user-select:none;
          }
          .group-body{padding:9px 9px 10px}
          .field-row{
            display:grid;
            grid-template-columns:115px 1fr;
            gap:8px;
            align-items:center;
            margin-bottom:7px;
          }
          label{
            font-size:13px;
            font-weight:900;
            color:var(--mhd-text);
            text-align:start;
            line-height:1.3;
          }
          select{
            width:100%;
            height:32px;
            padding:4px 8px;
            border:none;
            border-radius:6px;
            background:var(--mhd-input);
            color:#fff;
            font-size:13px;
            outline:1px solid var(--mhd-border);
            text-align:center;
          }
          select:focus{outline:2px solid var(--mhd-accent);background:var(--mhd-input)}
          .step-title{
            font-size:15px;
            font-weight:900;
            color:#fff;
            margin-bottom:7px;
          }
          .hint{
            color:var(--mhd-muted);
            font-size:12px;
            line-height:1.7;
          }
          .counter{
            height:38px;
            display:flex;
            justify-content:space-between;
            align-items:center;
            background:var(--mhd-input);
            border-radius:6px;
            outline:1px solid var(--mhd-border);
            padding:0 10px;
            margin:9px 0;
            font-size:13px;
            font-weight:900;
          }
          .counter strong{font-size:20px;color:var(--mhd-bright)}
          .btn{
            width:100%;
            height:36px;
            border-radius:8px;
            font-size:13px;
            font-weight:900;
            cursor:pointer;
            border:none;
            margin-top:7px;
          }
          .primary{background:var(--mhd-bright);color:var(--mhd-ink)}
          .secondary{background:var(--mhd-input);color:#fff;border:1px solid var(--mhd-border)}
          .danger{background:#5f2530;color:#fff;border:1px solid #85414f}
          .option{
            display:flex;
            align-items:center;
            gap:8px;
            min-height:30px;
            color:var(--mhd-text);
            font-size:12px;
            font-weight:700;
            margin-bottom:4px;
          }
          .option input{accent-color:var(--mhd-accent)}
          .level-row{
            display:flex;
            justify-content:space-between;
            align-items:center;
            border-bottom:1px solid var(--mhd-border);
            padding:7px 1px;
            font-size:12px;
          }
          .level-row:last-child{border-bottom:none}
          .section-panel{display:none}
          .section-panel.active{display:block}
          .locked{opacity:.42;pointer-events:none;filter:grayscale(.25)}
          .wall-block{background:var(--mhd-card);border:1px solid var(--mhd-border);border-radius:10px;margin-bottom:10px;padding:10px}
          .wall-select{margin:0;height:42px}
          .wall-status{margin:7px 0 0;text-align:center;font-size:12px;font-weight:900;color:#78909d}
          .wall-status.ready{color:var(--mhd-bright)}
          .mini-note{font-size:11px;color:var(--mhd-muted);line-height:1.6;margin-top:6px}
          .saved{color:var(--mhd-bright);font-weight:900}
          .pending{color:#78909d}
          .footer{
            height:58px;
            padding:8px 10px;
            border-top:1px solid var(--mhd-border);
            background:var(--mhd-app);
            display:flex;
            gap:8px;
          }
          .footer button{
            height:40px;
            border-radius:10px;
            font-size:14px;
            font-weight:900;
            cursor:pointer;
            border:none;
          }
          .generate{flex:2;background:var(--mhd-bright);color:var(--mhd-ink)}
          .pdf{flex:1.35;background:#2196f3;color:#fff}
          .pdf:disabled{opacity:.42;cursor:default}
          .generate:disabled{opacity:.42;cursor:default}
          .close{flex:1;background:var(--mhd-card);color:#fff;border:1px solid var(--mhd-border)!important}

  body { font-family: var(--mhd-font); color-scheme: dark; }
  button, input, select { font-family: inherit; min-width: 0; }
  button:focus-visible, [tabindex]:focus-visible { outline: 2px solid var(--mhd-bright); outline-offset: 2px; }
  .app > .hero, body > .hero { flex: none; height: auto; min-height: 74px; padding-inline: 12px; }
  .hero .logo, .head .logo {
    flex: 0 0 auto; width: 48px; height: 48px; padding: 4px;
    border-color: var(--mhd-border); background: var(--mhd-input);
  }
  .hero .head-text, .head .title { min-width: 0; }
  .hero .title-main, .hero .title, .head .title {
    font-size: clamp(16px, 4.8vw, 22px); line-height: 1.2; white-space: normal; overflow-wrap: anywhere;
  }
  .hero .subtitle, .hero .desc { height: auto; color: var(--mhd-muted); overflow-wrap: anywhere; }
  .wrap { padding: 12px; }
  .app > .wrap { flex: 1 1 0; height: auto; min-height: 0; }
  .group, .wall-block { border-radius: 12px; }
  .group-title, .gt, .panel-title {
    background: var(--mhd-section); color: var(--mhd-bright); border-bottom: 1px solid var(--mhd-border);
  }
  .field-row, .switch-row, .ignore-different-row {
    grid-template-columns: minmax(82px, 36%) minmax(0, 1fr);
  }
  .field-row > *, .switch-row > *, .ignore-different-row > * { min-width: 0; }
  .field-row label, .switch-row label { overflow-wrap: anywhere; }
  .footer, .foot { flex: none; height: auto; min-height: 56px; background: var(--mhd-panel); align-items: stretch; }
  .footer button, .foot button { min-width: 0; height: auto; min-height: 38px; padding: 5px 8px; overflow-wrap: anywhere; }
  .ok, .primary, .generate, .create, .add, .swap-units-btn {
    background: var(--mhd-primary); color: var(--mhd-ink);
  }
  .ok:hover, .primary:hover, .generate:hover:not(:disabled), .create:hover, .add:hover, .swap-units-btn:hover:not(:disabled) {
    background: var(--mhd-bright);
  }
  .cancel, .back, .pdf, .secondary, .edit {
    color: var(--mhd-text); background: var(--mhd-input); border: 1px solid var(--mhd-border);
  }
  .cancel:hover, .back:hover, .pdf:hover:not(:disabled), .secondary:hover, .edit:hover {
    background: var(--mhd-hover);
  }
  .shape.active, .side-btn.active, .mat-card.active, .pattern-card.active,
  .row-direction-btn.active, .type.active, .side button.active {
    color: var(--mhd-text); background: var(--mhd-active); border-color: var(--mhd-accent);
    box-shadow: none;
  }
          .mhd-tool-header {
            --mhd-tool-header-gradient: linear-gradient(110deg, #07111B 0%, #102635 58%, #075D63 100%);
            --mhd-tool-header-accent: #12D1CB;
            --mhd-tool-header-muted: #A8BED0;
          }
          .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
            position: relative; flex: none; display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 2.6fr) minmax(0, 1fr);
            align-items: center; gap: 12px; height: auto; min-height: 92px; padding: 10px 18px;
            overflow: hidden; direction: ltr; background: var(--mhd-tool-header-gradient);
            border-bottom: 1px solid var(--mhd-border);
          }
          .mhd-tool-header .brand {
            position: relative; z-index: 1; display: flex; align-items: center; gap: 8px;
            color: var(--mhd-text); letter-spacing: .07em;
          }
          .mhd-tool-header .brand .logo { display: block; flex: none; width: 36px; height: 36px; object-fit: contain; }
          .mhd-tool-header .brand .logo[hidden] { display: none; }
          .mhd-tool-header .brandName { font-size: 13px; }
          .mhd-tool-header .head-text, .mhd-tool-header > .title {
            position: relative; z-index: 1; min-width: 0; text-align: center; direction: ltr;
          }
          html[dir="rtl"] .mhd-tool-header .head-text, html[dir="rtl"] .mhd-tool-header > .title { direction: rtl; }
          .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 24px; font-weight: 800; line-height: 1.25; overflow-wrap: anywhere; }
          .mhd-tool-header .subtitle, .mhd-tool-header .desc {
            display: block; margin-top: 4px; color: var(--mhd-tool-header-muted);
            font-size: 12px; line-height: 1.35; font-weight: 400; overflow-wrap: anywhere;
          }
          .mhd-tool-header .cabinetDrawing {
            position: absolute; right: 10px; bottom: -8px; width: 130px; height: 82px;
            color: var(--mhd-tool-header-accent); opacity: .32; pointer-events: none;
          }
          @media (max-width: 620px) {
            .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
              grid-template-columns: 48px minmax(0, 1fr) 48px; gap: 8px;
              min-height: 72px; padding: 8px 10px;
            }
            .mhd-tool-header .brand { flex-direction: column; gap: 2px; }
            .mhd-tool-header .brand .logo { width: 30px; height: 30px; }
            .mhd-tool-header .brandName { font-size: 8px; letter-spacing: .03em; }
            .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 20px; }
            .mhd-tool-header .subtitle, .mhd-tool-header .desc { font-size: 11px; }
            .mhd-tool-header .cabinetDrawing { right: 4px; width: 70px; height: 52px; opacity: .18; }
          }
        #{MHDESIGN_ResponsiveHeaderUI::CSS}
:root {
  --mhd-app: var(--ref-bg); --mhd-panel: var(--ref-panel); --mhd-card: var(--ref-panel);
  --mhd-input: var(--ref-input); --mhd-hover: var(--ref-section); --mhd-border: var(--ref-border);
  --mhd-text: var(--ref-text); --mhd-muted: var(--ref-muted); --mhd-accent: var(--ref-accent);
}
.group-title, .group[data-group] .group-title, .panel-title, .gt {
  background: var(--ref-section); color: var(--ref-text); border-color: var(--ref-border);
}
.ok, .add, .generate, .create, .swap-units-btn {
  background: var(--ref-action); color: var(--ref-bg);
}
        </style>
      </head>
      <body oncontextmenu="return false;">
      <div class="app">
        <div class="hero mhd-tool-header mhd-ref-header">
          #{MHDESIGN_ResponsiveHeaderUI::BRAND}
          <div class="head-text">
            <div class="title-main">#{MHDESIGN_SHOP_LANG.key('SHOP_TITLE', 'إنشاء الشوب دروينج')}</div>
            <div class="subtitle">#{MHDESIGN_SHOP_LANG.key('SHOP_SUBTITLE', 'تم تصميم هذه الأداة بواسطة MHDESIGN')}<br>Shop Drawing Generator V2.1 PDF</div>
          </div>
        <!-- Dressing reference header artwork is included in BRAND. --></div>

        <div class="wrap">
          <div class="wall-block">
            <button id="wallSelectButton" class="btn primary wall-select" onclick="startWallSelection()">#{MHDESIGN_SHOP_LANG.key('SHOP_SELECT_WALL_GROUP', 'تحديد جروب الحائط')}</button>
            <div id="wallStatus" class="wall-status">#{MHDESIGN_SHOP_LANG.key('SHOP_WALL_NOT_SELECTED', 'لم يتم تحديد جروب الحائط')}</div>
          </div>

          <div id="levelsGroup" class="group locked">
            <div class="group-title">▼ #{MHDESIGN_SHOP_LANG.key('SHOP_LEVEL_SELECTION', 'تحديد المستويات')}</div>
            <div class="group-body">
              <div class="field-row">
                <label>#{MHDESIGN_SHOP_LANG.key('SHOP_LEVEL_COUNT', 'عدد مستويات المطبخ')}</label>
                <select id="levelsCount" onchange="changeLevelsCount()">#{level_options}</select>
              </div>
              <div class="step-title" id="stepTitle">#{MHDESIGN_SHOP_LANG.key('SHOP_LEVEL', 'المستوى')} 1 #{MHDESIGN_SHOP_LANG.key('SHOP_FROM', 'من')} #{@levels_count}</div>
              <div class="hint" id="stepHint">
                #{MHDESIGN_SHOP_LANG.key('SHOP_CURRENT_LEVEL_HINT', 'حدد الوحدات التي تريد ظهورها في المستوى الحالي، ثم اضغط حفظ المستوى.')}
              </div>

              <div class="counter">
                <span>#{MHDESIGN_SHOP_LANG.key('SHOP_SELECTED_UNITS', 'الوحدات المحددة')}</span>
                <strong id="selectionCount">0</strong>
              </div>

              <button class="btn primary" onclick="saveCurrentLevel()">#{MHDESIGN_SHOP_LANG.key('SHOP_SAVE_CURRENT_LEVEL', 'حفظ المستوى الحالي')}</button>
              <button class="btn secondary" onclick="reloadCurrentLevel()">#{MHDESIGN_SHOP_LANG.key('SHOP_RESELECT_CURRENT_LEVEL', 'إعادة تحديد المستوى الحالي')}</button>
              <button class="btn secondary" onclick="clearSelection()">#{MHDESIGN_SHOP_LANG.key('SHOP_CLEAR_CURRENT_SELECTION', 'إلغاء التحديد الحالي')}</button>

              <div class="mini-note" style="margin-top:12px;font-weight:900;color:#d8e8ef">
                #{MHDESIGN_SHOP_LANG.key('SHOP_REGISTERED_LEVELS', 'المستويات المسجلة')}
              </div>
              <div id="levelsList" style="margin-top:5px"></div>
              <button class="btn danger" onclick="resetAll()">#{MHDESIGN_SHOP_LANG.key('SHOP_RESET_LEVELS', 'مسح التسجيل والبدء من جديد')}</button>
            </div>
          </div>

          <div id="levelOptionsGroup" class="group locked">
            <div class="group-title">▼ #{MHDESIGN_SHOP_LANG.key('SHOP_LEVEL_SCENE_OPTIONS', 'خيارات مشاهد المستويات')}</div>
            <div class="group-body">
              <label class="option"><input type="checkbox" id="levelMakeDimensions" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_ADD_DIMENSIONS', 'إضافة مقاسات الوحدات')}</span></label>
              <label class="option"><input type="checkbox" id="levelMakeDescriptions" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_ADD_NAMES', 'إضافة أسماء الوحدات')}</span></label>
              <label class="option"><input type="checkbox" id="levelTopView" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_TOP_CAMERA', 'ضبط الكاميرا العلوية')}</span></label>
              <label class="option"><input type="checkbox" id="levelHideUnregistered" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_HIDE_UNREGISTERED', 'إخفاء الوحدات غير المسجلة')}</span></label>
            </div>
          </div>

          <div id="sectionsGroup" class="group locked">
            <div class="group-title">▼ #{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_SELECTION', 'تحديد واجهات السكشن')}</div>
            <div class="group-body">
              <div class="field-row">
                <label>#{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_COUNT', 'عدد واجهات السكشن')}</label>
                <select id="sectionsCount" onchange="changeSectionsCount()">#{section_options}</select>
              </div>

              <div id="sectionPanel" class="section-panel">
                <div class="step-title" id="sectionStepTitle">#{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_FACE', 'الوجه')} 1</div>
                <div class="hint">#{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_HINT_AUTO', 'حدد الوحدات والحوائط التي تريد ظهورها في هذا الوجه، وستحدد الأداة اتجاه السكشن تلقائيًا حسب اتجاه أغلبية الوحدات.')}</div>

                <div class="field-row">
                  <label>#{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_DEPTH', 'عمق السكشن')}</label>
                  <select id="sectionDepth">
                    <option value="40">40 #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}</option>
                    <option value="60">60 #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}</option>
                    <option value="80" selected>80 #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}</option>
                    <option value="100">100 #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}</option>
                    <option value="120">120 #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}</option>
                  </select>
                </div>

                <div class="counter">
                  <span>#{MHDESIGN_SHOP_LANG.key('SHOP_SELECTED_SECTION_OBJECTS', 'العناصر المحددة للوجه')}</span>
                  <strong id="sectionSelectionCount">0</strong>
                </div>

                <button id="saveSectionButton" class="btn primary" onclick="saveCurrentSection()">#{MHDESIGN_SHOP_LANG.key('SHOP_SAVE_SECTION', 'حفظ الوجه الحالي')}</button>
                <button id="reloadSectionButton" class="btn secondary" onclick="reloadCurrentSection()">#{MHDESIGN_SHOP_LANG.key('SHOP_RESELECT_SECTION', 'إعادة تحديد الوجه الحالي')}</button>
                <div class="mini-note">#{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_ZERO_NOTE', 'اختيار صفر يعني عدم إنشاء أي مشاهد سكشن.')}</div>
                <div id="sectionsList" style="margin-top:8px"></div>
              </div>
            </div>
          </div>

          <div id="sectionOptionsGroup" class="group locked">
            <div class="group-title">▼ #{MHDESIGN_SHOP_LANG.key('SHOP_SECTION_SCENE_OPTIONS', 'خيارات مشاهد الأوجه')}</div>
            <div class="group-body">
              <label class="option"><input type="checkbox" id="sectionMakeDimensions" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_ADD_DIMENSIONS', 'إضافة مقاسات الوحدات')}</span></label>
              <label class="option"><input type="checkbox" id="sectionMakeDescriptions" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_ADD_NAMES', 'إضافة أسماء الوحدات')}</span></label>
              <label class="option"><input type="checkbox" id="sectionHideUnregistered" checked><span>#{MHDESIGN_SHOP_LANG.key('SHOP_HIDE_UNREGISTERED', 'إخفاء العناصر غير المسجلة')}</span></label>
            </div>
          </div>

        </div>

        <div class="footer">
          <button id="generateButton" class="generate" onclick="generateScenes()" disabled>
            #{MHDESIGN_SHOP_LANG.key('SHOP_CREATE_SCENES', 'إنشاء المشاهد')}
          </button>
          <button id="pdfButton" class="pdf" onclick="openPdfSetup()" #{mhd_shop_export_pages.empty? ? 'disabled' : ''}>#{MHDESIGN_SHOP_LANG.key('SHOP_CREATE_PDF', 'إنشاء PDF')}</button>
          <button class="close" onclick="sketchup.close_dialog()">#{MHDESIGN_SHOP_LANG.key('SHOP_CLOSE', 'إغلاق')}</button>
        </div>
      </div>

      <script>
        document.addEventListener('contextmenu', function(event){ event.preventDefault(); });
        document.addEventListener('dragstart', function(event){ event.preventDefault(); });

        let wallReady = false;
        let levelsCount = #{@levels_count};
        let currentLevel = 1;
        let savedLevels = {};
        let sectionsCount = #{@sections_count};
        let currentSection = 1;
        let savedSections = {};
        let selectionMode = 'level';
        const SHOP_I18N = #{ {
          level: MHDESIGN_SHOP_LANG.key('SHOP_LEVEL', 'المستوى'),
          from: MHDESIGN_SHOP_LANG.key('SHOP_FROM', 'من'),
          unit: MHDESIGN_SHOP_LANG.key('SHOP_UNIT', 'وحدة'),
          not_registered: MHDESIGN_SHOP_LANG.key('SHOP_NOT_REGISTERED', 'غير مسجل'),
          hint_1: MHDESIGN_SHOP_LANG.key('SHOP_HINT_1', 'حدد وحدات المستوى الأول، مثل الوحدات السفلية والدواليب الطويلة.'),
          hint_2: MHDESIGN_SHOP_LANG.key('SHOP_HINT_2', 'حدد وحدات المستوى الثاني، مثل الوحدات العلوية الأولى والدواليب الطويلة.'),
          hint_3: MHDESIGN_SHOP_LANG.key('SHOP_HINT_3', 'حدد وحدات المستوى الثالث، مثل الوحدات العلوية الثانية والدواليب الطويلة.'),
          hint_generic: MHDESIGN_SHOP_LANG.key('SHOP_HINT_GENERIC', 'حدد وحدات المستوى %s.'),
          section_face: MHDESIGN_SHOP_LANG.key('SHOP_SECTION_FACE', 'الوجه'),
          object: MHDESIGN_SHOP_LANG.key('SHOP_OBJECT', 'عنصر')
        }.to_json};

        function sketchupCall(name, payload = null) {
          if (payload === null) {
            window.sketchup[name]();
          } else {
            window.sketchup[name](JSON.stringify(payload));
          }
        }

        function startWallSelection(){ sketchupCall('start_wall_selection'); }

        function wallSelectionState(ready, name){
          wallReady = !!ready;
          const status = document.getElementById('wallStatus');
          status.classList.toggle('ready', wallReady);
          status.textContent = wallReady ? ('✓ ' + (name || '#{MHDESIGN_SHOP_LANG.key('SHOP_WALL_SELECTED', 'تم تسجيل جروب الحائط')}')) : '#{MHDESIGN_SHOP_LANG.key('SHOP_WALL_NOT_SELECTED', 'لم يتم تحديد جروب الحائط')}';
          document.getElementById('wallSelectButton').textContent = wallReady ? '#{MHDESIGN_SHOP_LANG.key('SHOP_RESELECT_WALL_GROUP', 'إعادة تحديد جروب الحائط')}' : '#{MHDESIGN_SHOP_LANG.key('SHOP_SELECT_WALL_GROUP', 'تحديد جروب الحائط')}';
          ['levelsGroup','sectionsGroup','levelOptionsGroup','sectionOptionsGroup'].forEach(id=>document.getElementById(id).classList.toggle('locked', !wallReady));
          updateUI();
        }

        function changeLevelsCount() {
          levelsCount = parseInt(document.getElementById('levelsCount').value);
          currentLevel = 1;
          savedLevels = {};
          updateUI();
          sketchupCall('set_levels_count', { count: levelsCount });
        }

        function levelsComplete() {
          return Object.keys(savedLevels).length === levelsCount;
        }

        function changeSectionsCount() {
          sectionsCount = parseInt(document.getElementById('sectionsCount').value);
          currentSection = 1;
          savedSections = {};
          const nextMode = (sectionsCount > 0 && levelsComplete()) ? 'section' : 'level';
          setSelectionMode(nextMode);
          updateUI();
          sketchupCall('set_sections_count', { count: sectionsCount });
        }

        function setSelectionMode(mode) {
          const sectionAllowed = mode === 'section' && sectionsCount > 0 && levelsComplete();
          selectionMode = sectionAllowed ? 'section' : 'level';
          if (selectionMode === 'section') {
            updateSelectionCount(0);
          } else {
            document.getElementById('sectionSelectionCount').textContent = '0';
          }
          sketchupCall('set_selection_mode', { mode: selectionMode });
        }

        function saveCurrentSection(){
          if (!wallReady || !levelsComplete()) return;
          setSelectionMode('section');
          sketchupCall('save_current_section', {
            section: currentSection,
            depth_cm: parseFloat(document.getElementById('sectionDepth').value)
          });
        }
        function reloadCurrentSection(){
          if (!wallReady || !levelsComplete()) return;
          setSelectionMode('section');
          sketchupCall('reload_current_section', { section: currentSection });
        }

        function saveCurrentLevel(){
          if (!wallReady) return;
          setSelectionMode('level');
          sketchupCall('save_current_level', { level: currentLevel });
        }
        function reloadCurrentLevel(){
          if (!wallReady) return;
          setSelectionMode('level');
          sketchupCall('reload_current_level', { level: currentLevel });
        }
        function clearSelection(){ sketchupCall('clear_selection'); }

        function openPdfSetup(){ sketchupCall('open_pdf_setup'); }

        function setPdfAvailable(available) {
          const button = document.getElementById('pdfButton');
          if (button) button.disabled = !available;
        }

        function generateScenes() {
          const options = {
            level_make_dimensions: document.getElementById('levelMakeDimensions').checked,
            level_make_descriptions: document.getElementById('levelMakeDescriptions').checked,
            level_top_view: document.getElementById('levelTopView').checked,
            level_hide_unregistered: document.getElementById('levelHideUnregistered').checked,
            section_make_dimensions: document.getElementById('sectionMakeDimensions').checked,
            section_make_descriptions: document.getElementById('sectionMakeDescriptions').checked,
            section_hide_unregistered: document.getElementById('sectionHideUnregistered').checked,
            sections_count: sectionsCount
          };
          sketchupCall('generate_scenes', options);
        }

        function resetAll() {
          savedLevels = {};
          currentLevel = 1;
          savedSections = {};
          currentSection = 1;
          selectionMode = 'level';
          sketchupCall('reset_all');
          updateUI();
        }

        function scrollToSectionsGroup() {
          const group = document.getElementById('sectionsGroup');
          const wrap = document.querySelector('.wrap');
          if (!group || !wrap || sectionsCount <= 0) return;

          requestAnimationFrame(function(){
            const groupTop = group.offsetTop;
            const target = Math.max(0, groupTop - 10);
            if (typeof wrap.scrollTo === 'function') {
              wrap.scrollTo({ top: target, behavior: 'smooth' });
            } else {
              wrap.scrollTop = target;
            }
          });
        }

        function updateSelectionCount(count) {
          document.getElementById('selectionCount').textContent = count;
        }

        function levelSaved(level, count) {
          savedLevels[level] = count;
          if (level < levelsCount) currentLevel = level + 1;

          if (levelsComplete()) {
            updateSelectionCount(0);
            if (sectionsCount > 0) {
              setSelectionMode('section');
            } else {
              selectionMode = 'level';
              sketchupCall('set_selection_mode', { mode: 'level' });
            }
          } else {
            setSelectionMode('level');
          }
          updateUI();

          if (levelsComplete() && sectionsCount > 0) {
            scrollToSectionsGroup();
          }
        }

        function levelReloaded(level, count) {
          currentLevel = level;
          updateSelectionCount(count);
          updateUI();
        }

        function sectionSaved(section, count, depthCm) {
          savedSections[section] = {count: count, depth_cm: depthCm};
          if (section < sectionsCount) currentSection = section + 1;
          document.getElementById('sectionSelectionCount').textContent = '0';
          updateUI();
        }

        function sectionReloaded(section, count, depthCm) {
          currentSection = section;
          selectionMode = 'section';
          document.getElementById('sectionDepth').value = String(depthCm || 80);
          document.getElementById('sectionSelectionCount').textContent = count;
          setSelectionMode('section');
          updateUI();
        }

        function updateUI() {
          document.getElementById('stepTitle').textContent =
            SHOP_I18N.level + ' ' + currentLevel + ' ' + SHOP_I18N.from + ' ' + levelsCount;

          const examples = {
            1: SHOP_I18N.hint_1,
            2: SHOP_I18N.hint_2,
            3: SHOP_I18N.hint_3
          };

          document.getElementById('stepHint').textContent =
            examples[currentLevel] || SHOP_I18N.hint_generic.replace('%s', currentLevel);

          const list = document.getElementById('levelsList');
          list.innerHTML = '';

          for (let i = 1; i <= levelsCount; i++) {
            const row = document.createElement('div');
            row.className = 'level-row';

            const name = document.createElement('span');
            name.textContent = SHOP_I18N.level + ' ' + i;

            const status = document.createElement('span');
            if (savedLevels[i] !== undefined) {
              status.className = 'saved';
              status.textContent = savedLevels[i] + ' ' + SHOP_I18N.unit;
            } else {
              status.className = 'pending';
              status.textContent = SHOP_I18N.not_registered;
            }

            row.appendChild(name);
            row.appendChild(status);
            list.appendChild(row);
          }

          const sectionPanel = document.getElementById('sectionPanel');
          sectionPanel.classList.toggle('active', sectionsCount > 0);
          document.getElementById('sectionStepTitle').textContent =
            SHOP_I18N.section_face + ' ' + currentSection + ' ' + SHOP_I18N.from + ' ' + sectionsCount;

          const sectionList = document.getElementById('sectionsList');
          sectionList.innerHTML = '';
          for (let i = 1; i <= sectionsCount; i++) {
            const row = document.createElement('div');
            row.className = 'level-row';
            const name = document.createElement('span');
            name.textContent = SHOP_I18N.section_face + ' ' + i;
            const status = document.createElement('span');
            if (savedSections[i]) {
              status.className = 'saved';
              status.textContent = savedSections[i].count + ' ' + SHOP_I18N.object;
            } else {
              status.className = 'pending';
              status.textContent = SHOP_I18N.not_registered;
            }
            row.appendChild(name); row.appendChild(status); sectionList.appendChild(row);
          }

          if (savedSections[currentSection]) {
            document.getElementById('sectionDepth').value = String(savedSections[currentSection].depth_cm);
          }

          const levelsReady = levelsComplete();
          const sectionsReady = sectionsCount === 0 || Object.keys(savedSections).length === sectionsCount;

          const saveSectionButton = document.getElementById('saveSectionButton');
          const reloadSectionButton = document.getElementById('reloadSectionButton');
          if (saveSectionButton) saveSectionButton.disabled = !levelsReady;
          if (reloadSectionButton) reloadSectionButton.disabled = !levelsReady;

          if (levelsReady) {
            updateSelectionCount(0);
          }
          if (!levelsReady || sectionsCount === 0) {
            document.getElementById('sectionSelectionCount').textContent = '0';
          }

          document.getElementById('sectionOptionsGroup').style.display = sectionsCount > 0 ? '' : 'none';
          document.getElementById('generateButton').disabled = !(wallReady && levelsReady && sectionsReady);
        }

        function resetFromRuby() {
          savedLevels = {};
          currentLevel = 1;
          savedSections = {};
          currentSection = 1;
          selectionMode = 'level';
          wallSelectionState(false, '');
          updateSelectionCount(0);
          document.getElementById('sectionSelectionCount').textContent = '0';
          updateUI();
        }

        function showMessage(message){ console.log(message); }
      </script>

      <script>
        document.documentElement.lang = #{MHDESIGN_SHOP_LANG.current.to_json};
        document.documentElement.dir = #{MHDESIGN_SHOP_LANG.direction.to_json};
        wallSelectionState(false, '');
        updateUI();
      </script>
      </body>
      </html>
      HTML
    end

    # --------------------------------------------------------
    # Callbacks
    # --------------------------------------------------------
    def attach_callbacks
      @dialog.add_action_callback('close_editor') do |_ctx|
        @dialog.close
      end

      @dialog.add_action_callback('apply_selected_group_style') do |_ctx, payload|
        begin
          data = JSON.parse(payload)
          result = apply_selected_group_style(data)
          @dialog.execute_script(
            "setStatus(#{result[:message].to_json}, #{result[:ok] ? 'true' : 'false'});"
          )
        rescue => error
          puts error.full_message
          @dialog.execute_script(
            "setStatus(#{error.message.to_json}, false);"
          )
        end
      end


      @dialog.add_action_callback('start_wall_selection') do |_ctx|
        @wall_select_mode = true
        @selection_mode = :wall
        Sketchup.active_model.selection.clear
      end

      @dialog.add_action_callback('set_levels_count') do |_ctx, payload|
        data = JSON.parse(payload)
        @levels_count = data['count'].to_i
        @current_level = 1
        @levels = {}
        Sketchup.write_default(PREF_KEY, 'levels_count', @levels_count)
        Sketchup.active_model.selection.clear
      end

      @dialog.add_action_callback('set_sections_count') do |_ctx, payload|
        data = JSON.parse(payload)
        @sections_count = [[data['count'].to_i, 0].max, 4].min
        @current_section = 1
        @sections = {}
        @selection_mode = :level if @sections_count == 0
        Sketchup.write_default(PREF_KEY, 'sections_count', @sections_count)
        Sketchup.active_model.selection.clear
      end

      @dialog.add_action_callback('set_selection_mode') do |_ctx, payload|
        data = JSON.parse(payload)
        levels_ready = @levels.length == @levels_count
        @selection_mode = (
          data['mode'].to_s == 'section' &&
          @sections_count > 0 &&
          levels_ready
        ) ? :section : :level
      end

      @dialog.add_action_callback('save_current_section') do |_ctx, payload|
        data = JSON.parse(payload)
        save_section(data['section'].to_i, data['depth_cm'].to_f)
      end

      @dialog.add_action_callback('reload_current_section') do |_ctx, payload|
        data = JSON.parse(payload)
        reload_section_selection(data['section'].to_i)
      end

      @dialog.add_action_callback('save_current_level') do |_ctx, payload|
        data = JSON.parse(payload)
        level = data['level'].to_i
        save_level(level)
      end

      @dialog.add_action_callback('reload_current_level') do |_ctx, payload|
        data = JSON.parse(payload)
        level = data['level'].to_i
        reload_level_selection(level)
      end

      @dialog.add_action_callback('clear_selection') do |_ctx|
        Sketchup.active_model.selection.clear
      end

      @dialog.add_action_callback('close_dialog') do |_ctx|
        @dialog.close if @dialog
      end

      @dialog.add_action_callback('reset_all') do |_ctx|
        @levels = {}
        @current_level = 1
        @sections = {}
        @current_section = 1
        @selection_mode = :level
        @wall_group_ref = nil
        @wall_select_mode = false
        Sketchup.active_model.selection.clear
      end

      @dialog.add_action_callback('open_pdf_setup') do |_ctx|
        open_pdf_setup_page
      end

      @dialog.add_action_callback('choose_pdf_directory') do |_ctx|
        choose_pdf_parent_directory
      end

      @dialog.add_action_callback('create_pdf_project') do |_ctx, payload|
        begin
          data = JSON.parse(payload)
          create_pdf_project(data['filename'].to_s)
        rescue => error
          puts error.full_message
          pdf_execute("setPdfStatus(#{error.message.to_json}, false);")
        end
      end

      @dialog.add_action_callback('back_to_shop_main') do |_ctx|
        @dialog_mode = :create
        @dialog.set_html(dialog_html)
        @dialog.set_size(350, 745) if @dialog.respond_to?(:set_size)
        UI.start_timer(0.05, false) do
          @dialog.set_size(350, 745) if @dialog && @dialog.visible? && @dialog.respond_to?(:set_size)
        rescue
        end
        start_selection_timer
      end

      @dialog.add_action_callback('save_report_html') do |_ctx, payload|
        begin
          data = JSON.parse(payload)
          save_edited_report(data['html'].to_s)
          pdf_execute("setReportStatus(#{report_i18n[:saved_changes].to_json}, true);")
        rescue => error
          pdf_execute("setReportStatus(#{error.message.to_json}, false);")
        end
      end

      @dialog.add_action_callback('choose_report_image') do |_ctx, payload|
        begin
          data = JSON.parse(payload.to_s)
          choose_report_image(data['target_id'].to_s, data['mode'].to_s)
        rescue => error
          puts error.full_message
          pdf_execute("setReportStatus(#{error.message.to_json}, false);")
        end
      end

      @dialog.add_action_callback('generate_scenes') do |_ctx, payload|
        options = JSON.parse(payload)
        generate_scenes(options)
      end
    end

    def apply_selected_group_style(data)
      group = @edit_group
      unless group && group.valid? &&
             group.get_attribute(DICT, 'annotation_group', false) == true
        return {
          ok: false,
          message: MHDESIGN_SHOP_LANG.key(
            'SHOP_EDIT_GROUP_LOST',
            'الجروب المحدد لم يعد موجودًا.'
          )
        }
      end

      model = Sketchup.active_model
      dimensions = group.entities.grep(Sketchup::DimensionLinear)
      labels = group.entities.grep(Sketchup::Text).select do |item|
        item.get_attribute(DICT, 'annotation_type', '') == 'unit_name'
      end

      dim_name = data['dimension_color'].to_s
      label_name = data['label_color'].to_s
      dim_color = color_from_name(dim_name)
      label_color = color_from_name(label_name)

      model.start_operation('MHD Shop Drawing Colors', true)

      dimensions.each do |dimension|
        next unless dimension.valid?
        dimension.material = dim_color
      end

      labels.each do |label|
        next unless label.valid?
        label.material = label_color
      end

      group.set_attribute(DICT, 'dimension_color', dim_name)
      group.set_attribute(DICT, 'label_color', label_name)

      model.commit_operation
      model.active_view.invalidate

      {
        ok: true,
        message: MHDESIGN_SHOP_LANG.key(
          'SHOP_COLORS_APPLIED',
          'تم تطبيق الألوان على المستوى المحدد.'
        )
      }
    rescue => error
      model.abort_operation rescue nil
      {
        ok: false,
        message: error.message
      }
    end

    def color_from_name(name)
      case name.to_s
      when 'white'     then Sketchup::Color.new(255, 255, 255)
      when 'red'       then Sketchup::Color.new(229, 57, 53)
      when 'blue'      then Sketchup::Color.new(25, 118, 210)
      when 'green'     then Sketchup::Color.new(46, 173, 91)
      when 'yellow'    then Sketchup::Color.new(244, 196, 48)
      when 'gray'      then Sketchup::Color.new(128, 128, 128)
      when 'dark_gray' then Sketchup::Color.new(64, 64, 64)
      else                  Sketchup::Color.new(0, 0, 0)
      end
    end

    def safe_persistent_id(entity)
      return nil unless entity && entity.valid?
      entity.respond_to?(:persistent_id) ? entity.persistent_id : entity.entityID
    rescue
      nil
    end

    def refresh_dialog_mode
      return unless @dialog && @dialog.visible?
      return if @dialog_mode == :pdf_setup || @dialog_mode == :pdf_report

      selected_group = selected_annotation_group
      selected_pid = safe_persistent_id(selected_group)
      target_mode = selected_group ? :edit : :create

      changed = target_mode != @dialog_mode ||
                (target_mode == :edit && selected_pid != @edit_group_pid)
      return unless changed

      @edit_group = selected_group
      @edit_group_pid = selected_pid
      @dialog_mode = target_mode

      if target_mode == :edit
        @dialog.set_html(edit_dialog_html(@edit_group))
        @dialog.set_size(350, 455) if @dialog.respond_to?(:set_size)
      else
        @dialog.set_html(dialog_html)
        @dialog.set_size(350, 745) if @dialog.respond_to?(:set_size)
      end
    rescue => error
      puts "Live mode warning: #{error.message}"
    end

    # --------------------------------------------------------
    # Selection monitoring
    # --------------------------------------------------------
    def start_selection_timer
      stop_selection_timer
      @selection_timer = UI.start_timer(0.25, true) do
        next unless @dialog && @dialog.visible?

        refresh_dialog_mode

        if @dialog_mode == :create
          pdf_available = !mhd_shop_export_pages.empty?
          @dialog.execute_script("setPdfAvailable(#{pdf_available ? 'true' : 'false'});") rescue nil
          if @wall_select_mode
            candidate = Sketchup.active_model.selection.to_a.find { |entity| unit_entity?(entity) }
            if candidate && candidate.valid?
              @wall_group_ref = entity_reference(candidate)
              @wall_select_mode = false
              @selection_mode = :level
              Sketchup.active_model.selection.clear
              wall_name = entity_name(candidate)
              wall_name = MHDESIGN_SHOP_LANG.key('SHOP_WALL_SELECTED', 'تم تسجيل جروب الحائط') if wall_name.to_s.strip.empty?
              @dialog.execute_script("wallSelectionState(true, #{wall_name.to_json});")
            end
            next
          end

          count = valid_selected_entities.length
          levels_ready = @levels.length == @levels_count

          if levels_ready && @sections_count > 0 && @selection_mode == :section
            @dialog.execute_script(
              "updateSelectionCount(0); document.getElementById('sectionSelectionCount').textContent = #{count};"
            )
          elsif !levels_ready
            @dialog.execute_script(
              "updateSelectionCount(#{count}); document.getElementById('sectionSelectionCount').textContent = 0;"
            )
          else
            @dialog.execute_script(
              "updateSelectionCount(0); document.getElementById('sectionSelectionCount').textContent = 0;"
            )
          end
        end
      rescue => error
        puts "Selection timer warning: #{error.message}"
      end
    end

    def stop_selection_timer
      return unless @selection_timer

      UI.stop_timer(@selection_timer)
      @selection_timer = nil
    rescue
      @selection_timer = nil
    end

    def wall_group_entity(model = Sketchup.active_model)
      resolve_entity_reference(model, @wall_group_ref)
    rescue
      nil
    end

    def with_wall_group(entities, model = Sketchup.active_model)
      result = Array(entities).compact.select { |entity| entity.respond_to?(:valid?) && entity.valid? }
      wall = wall_group_entity(model)
      result << wall if wall && wall.valid?
      result.uniq
    end

    def valid_selected_entities
      Sketchup.active_model.selection.to_a.select { |entity| unit_entity?(entity) }
    end

    def unit_entity?(entity)
      entity.is_a?(Sketchup::ComponentInstance) ||
        entity.is_a?(Sketchup::Group)
    end

    # العنصر يدخل المشهد بمجرد كونه Group أو Component، لكن إضافة البيانات
    # تتم فقط لو كان وحدة مطبخ ديناميكية أو حائطًا مبنيًا بأداة MHD Room Builder.
    def kitchen_unit?(entity)
      return false unless unit_entity?(entity)

      begin
        dict = entity.attribute_dictionary('dynamic_attributes', false)
        return true if dict && dict.length > 0
      rescue
      end

      if entity.is_a?(Sketchup::ComponentInstance)
        begin
          dict = entity.definition.attribute_dictionary('dynamic_attributes', false)
          return true if dict && dict.length > 0
        rescue
        end
      end

      false
    end

    def room_builder_wall?(entity)
      return false unless unit_entity?(entity)

      type = entity.get_attribute('MHD_ROOM_BUILDER', 'النوع').to_s
      type = entity.get_attribute('MHD_ROOM_BUILDER', 'type').to_s if type.empty?
      normalized = normalize(type)

      normalized == normalize('حائط') || normalized == 'wall'
    rescue
      false
    end

    def annotation_kind(entity)
      return :kitchen_unit if kitchen_unit?(entity)
      return :room_wall if room_builder_wall?(entity)
      :scene_only
    rescue
      :scene_only
    end

    class ShopDrawingModelObserver < Sketchup::ModelObserver
      def initialize(owner)
        @owner = owner
      end

      def onTransactionUndo(model)
        @owner.handle_model_history_change(model)
      rescue
      end

      def onTransactionRedo(model)
        @owner.handle_model_history_change(model)
      rescue
      end

      def onEraseAll(model)
        @owner.handle_model_history_change(model)
      rescue
      end
    end

    def install_model_observer(model)
      return if @model_observer

      @model_observer = ShopDrawingModelObserver.new(self)
      model.add_observer(@model_observer)
    rescue => error
      puts "Shop Drawing observer warning: #{error.message}"
    end

    def handle_model_history_change(model)
      return if @busy

      @levels = {}
      @current_level = 1
      @sections = {}
      @current_section = 1
      @selection_mode = :level
      model.selection.clear rescue nil

      if @dialog && @dialog.visible?
        @dialog.execute_script('resetFromRuby();') rescue nil
      end

      puts MHDESIGN_SHOP_LANG.key(
        'SHOP_HISTORY_RESET',
        'تم مسح تسجيل المستويات بعد التراجع أو الإعادة. أعد تحديد المستويات.'
      )
    rescue => error
      puts "Shop Drawing history warning: #{error.message}"
    end

    # --------------------------------------------------------
    # Save levels
    # --------------------------------------------------------
    def save_level(level)
      model = Sketchup.active_model
      entities = valid_selected_entities

      if entities.empty?
        puts MHDESIGN_SHOP_LANG.key('SHOP_SELECT_AT_LEAST_ONE', 'حدد وحدة واحدة على الأقل قبل حفظ المستوى.')
        return
      end

      @levels[level] = entities.map { |entity| entity_reference(entity) }.compact
      @current_level = [level + 1, @levels_count].min
      @selection_mode = (@levels.length == @levels_count && @sections_count > 0) ? :section : :level

      model.selection.clear

      @dialog.execute_script(
        "levelSaved(#{level}, #{entities.length}); updateSelectionCount(0);"
      )
    end

    def reload_level_selection(level)
      model = Sketchup.active_model
      refs = @levels[level] || []

      model.selection.clear
      entities = refs.filter_map { |ref| resolve_entity_reference(model, ref) }
      model.selection.add(entities) unless entities.empty?

      @current_level = level

      @dialog.execute_script(
        "levelReloaded(#{level}, #{entities.length});"
      )
    end

    def save_section(section_number, depth_cm)
      model = Sketchup.active_model
      entities = valid_selected_entities
      if entities.empty?
        puts MHDESIGN_SHOP_LANG.key('SHOP_SELECT_SECTION_OBJECTS', 'حدد عنصرًا واحدًا على الأقل قبل حفظ وجه السكشن.')
        return
      end

      depth_cm = 80.0 unless depth_cm > 0.0
      detected_axis = detect_section_axis(entities)

      @sections[section_number] = {
        'entities' => entities.map { |entity| entity_reference(entity) }.compact,
        'direction' => detected_axis.to_s,
        'depth_cm' => depth_cm
      }
      @current_section = [section_number + 1, @sections_count].min
      model.selection.clear
      @dialog.execute_script("sectionSaved(#{section_number}, #{entities.length}, #{depth_cm});")
    end

    def reload_section_selection(section_number)
      model = Sketchup.active_model
      data = @sections[section_number] || {}
      refs = data['entities'] || []
      model.selection.clear
      entities = refs.filter_map { |ref| resolve_entity_reference(model, ref) }
      model.selection.add(entities) unless entities.empty?
      @current_section = section_number
      @selection_mode = :section
      depth_cm = data['depth_cm'] || 80.0
      @dialog.execute_script("sectionReloaded(#{section_number}, #{entities.length}, #{depth_cm});")
    end

    # يحدد اتجاه الوجه تلقائيًا من اتجاه واجهة أغلبية وحدات المطبخ المحددة.
    # الواجهة المحلية للوحدة تعتبر -Y، ثم تتحول إلى محاور الموديل الرئيسية.
    # الحوائط والجروبات العادية لا تدخل في التصويت ما دام هناك وحدات مطبخ.
    def detect_section_axis(entities)
      candidates = entities.select { |entity| kitchen_unit?(entity) }
      candidates = entities.select { |entity| unit_entity?(entity) && !room_builder_wall?(entity) } if candidates.empty?
      return :front if candidates.empty?

      votes = Hash.new { |hash, key| hash[key] = { count: 0, span: 0.0, first: candidates.length + 1 } }

      candidates.each_with_index do |entity, index|
        local_box, transformation = local_bounds_and_transform(entity)
        next unless local_box && transformation

        front_vector = Geom::Vector3d.new(0, -1, 0).transform(transformation)
        next if front_vector.length <= 0.0001

        axis = dominant_axis_from_front_vector(front_vector)
        info = votes[axis]
        info[:count] += 1
        info[:span] += local_box.width.to_f.abs
        info[:first] = [info[:first], index].min
      rescue => error
        puts "Automatic face direction warning: #{error.message}"
      end

      return :front if votes.empty?

      # الأولوية: عدد الوحدات، ثم مجموع عروضها، ثم أول اتجاه ظهر في التحديد.
      votes.max_by do |_axis, info|
        [info[:count], info[:span], -info[:first]]
      end.first
    rescue => error
      puts "Automatic section direction warning: #{error.message}"
      :front
    end

    def dominant_axis_from_front_vector(vector)
      if vector.x.abs >= vector.y.abs
        vector.x >= 0 ? :right : :left
      else
        vector.y >= 0 ? :back : :front
      end
    end

    def entities_for_section(model, section_number)
      data = @sections[section_number] || {}
      (data['entities'] || []).filter_map { |ref| resolve_entity_reference(model, ref) }
        .select { |entity| entity.valid? && unit_entity?(entity) }.uniq
    end

    # --------------------------------------------------------
    # Generate scenes
    # --------------------------------------------------------
    def generate_scenes(options)
      return if @busy

      model = Sketchup.active_model
      wall = wall_group_entity(model)
      unless wall && wall.valid?
        @busy = false
        start_selection_timer
        return
      end
      @busy = true
      stop_selection_timer

      missing = (1..@levels_count).reject { |level| @levels.key?(level) }
      unless missing.empty?
        puts MHDESIGN_SHOP_LANG.key('SHOP_MISSING_LEVELS', 'هناك مستويات لم يتم تسجيلها بعد.')
        @busy = false
        start_selection_timer
        return
      end

      missing_sections = @sections_count > 0 ? (1..@sections_count).reject { |number| @sections.key?(number) } : []
      unless missing_sections.empty?
        puts MHDESIGN_SHOP_LANG.key('SHOP_MISSING_SECTIONS', 'هناك واجهات سكشن لم يتم تسجيلها بعد.')
        @busy = false
        start_selection_timer
        return
      end

      invalid_levels = (1..@levels_count).select { |level| entities_for_level(model, level).empty? }
      unless invalid_levels.empty?
        invalid_levels.each { |level| @levels.delete(level) }
        @dialog.execute_script('resetFromRuby();') rescue nil
        puts MHDESIGN_SHOP_LANG.key(
          'SHOP_INVALID_SELECTION_AFTER_UNDO',
          'بعض التحديدات لم تعد صالحة بعد التراجع. أعد تسجيل المستويات.'
        )
        @busy = false
        start_selection_timer
        return
      end

      @run_token = Time.now.strftime('%Y%m%d%H%M%S') + "_#{rand(1000)}"

      model.start_operation('MHD Interactive Shop Drawing', true)

      begin
        cleanup_previous_output(model)

        # إنشاء مشهد أساسي قبل إخفاء أي شيء.
        # يحفظ حالة المشروع كاملة والكاميرا الحالية للرجوع إليها بعد انتهاء الإنشاء.
        base_scene = create_base_scene(model)

        registered_entities = all_registered_entities(model)
        all_candidate_entities = (options['level_hide_unregistered'] || options['section_hide_unregistered'] || @sections_count > 0) ?
          all_top_level_units(model) :
          registered_entities

        # مهم: ننشئ كل مجموعات المقاسات وكل الـTags أولًا،
        # ثم نحفظ المشاهد في خطوة ثانية.
        # بهذا كل Scene تعرف باقي Tags من البداية ولا تختفي مقاسات مستوى بعينه.
        annotation_groups = {}

        (1..@levels_count).each do |level|
          visible_entities = with_wall_group(entities_for_level(model, level), model)
          level_options = {
            'make_dimensions' => options['level_make_dimensions'],
            'make_descriptions' => options['level_make_descriptions']
          }
          annotation_groups[level] = create_annotations(model, visible_entities, level, level_options)
        end

        (1..@levels_count).each do |level|
          visible_entities = with_wall_group(entities_for_level(model, level), model)

          set_visibility(all_candidate_entities, visible_entities)
          set_annotation_groups_visibility(annotation_groups, level)
          set_annotation_tag_visibility(model, level)

          set_top_camera(model, visible_entities) if options['level_top_view']

          create_or_update_scene(
            model,
            format('%s %02d - %s %d', SCENE_PREFIX, level, MHDESIGN_SHOP_LANG.key('SHOP_LEVEL', 'المستوى'), level)
          )
        end

        # إنشاء واجهات السكشن التي سجلها المستخدم فقط.
        if @sections_count > 0
          create_registered_section_scenes(model, all_candidate_entities, annotation_groups, options)

          # مهم: Tags وجروبات بيانات الأوجه يتم إنشاؤها بعد إنشاء مشاهد المستويات.
          # لذلك نعيد تحديث مشاهد المستويات مرة أخيرة بعد اكتمال إنشاء الأوجه،
          # مع إخفاء كل بيانات الأوجه وكل Section Planes داخل مشاهد المستويات.
          refresh_level_scenes_after_sections(
            model,
            all_candidate_entities,
            annotation_groups,
            options
          )
        end

        # تحديث المشهد الأساسي بعد إنشاء Tags المقاسات الجديدة:
        # كل المشروع ظاهر، وكل Tags المقاسات مخفية، مع الحفاظ على كاميرته الأصلية.
        update_base_scene_clean(model, base_scene, all_candidate_entities)

        # الرجوع إلى المشهد الأساسي النظيف.
        model.pages.selected_page = base_scene if base_scene

        model.commit_operation

        @dialog.execute_script("setPdfAvailable(true);") rescue nil
        puts MHDESIGN_SHOP_LANG.key('SHOP_SUCCESS', 'تم إنشاء مشاهد الشوب دروينج بأمان.')
      rescue => error
        model.abort_operation rescue nil
        puts error.full_message
        puts error.message
      ensure
        @busy = false
        start_selection_timer if @dialog && @dialog.visible?
      end
    end

    def entities_for_level(model, level)
      refs = @levels[level] || []
      refs.filter_map { |ref| resolve_entity_reference(model, ref) }
          .select { |entity| entity.valid? && unit_entity?(entity) }
          .uniq
    end

    def all_registered_entities(model)
      @levels.values.flatten.filter_map do |ref|
        resolve_entity_reference(model, ref)
      end.select { |entity| entity.valid? && unit_entity?(entity) }.then { |items| with_wall_group(items, model) }.uniq
    end

    def all_top_level_units(model)
      model.entities.to_a.select do |entity|
        unit_entity?(entity) &&
          !entity.get_attribute(DICT, 'annotation_group', false) &&
          !safe_entity_name(entity).start_with?(ANNO_PREFIX)
      end
    end

    def entity_reference(entity)
      return nil unless entity && entity.valid?

      persistent_id = entity.respond_to?(:persistent_id) ? entity.persistent_id : nil
      {
        'persistent_id' => persistent_id,
        'entity_id' => entity.entityID
      }
    rescue
      nil
    end

    def resolve_entity_reference(model, reference)
      return nil unless reference

      if reference.is_a?(Hash)
        persistent_id = reference['persistent_id'] || reference[:persistent_id]
        entity_id = reference['entity_id'] || reference[:entity_id]
      else
        persistent_id = nil
        entity_id = reference
      end

      entity = nil

      if persistent_id && persistent_id.to_i > 0 && model.respond_to?(:find_entity_by_persistent_id)
        entity = model.find_entity_by_persistent_id(persistent_id.to_i)
      end

      if (!entity || !entity.valid?) && entity_id
        entity = model.find_entity_by_id(entity_id.to_i)
      end

      entity && entity.valid? ? entity : nil
    rescue
      nil
    end

    def set_visibility(all_entities, visible_entities)
      visible_ids = visible_entities.map(&:entityID)

      all_entities.each do |entity|
        next unless entity&.valid?
        entity.hidden = !visible_ids.include?(entity.entityID)
      end
    end

    # --------------------------------------------------------
    # Cleanup
    # --------------------------------------------------------
    def cleanup_previous_output(model)
      # مهم جدًا:
      # لا نحذف Pages أو Tags أو Groups هنا، لأن الحذف بعد Undo/Redo
      # قد يترك SketchUp في حالة Native غير مستقرة ويسبب إغلاق البرنامج.
      #
      # بدل الحذف، نخفي أي بيانات قديمة ونترك المشاهد الحالية ليتم تحديثها.

      model.entities.to_a.each do |entity|
        next unless entity.respond_to?(:valid?) && entity.valid?

        begin
          if entity.get_attribute(DICT, 'annotation_group', false) ||
             entity.get_attribute(DICT, 'section_plane', false) ||
             safe_entity_name(entity).start_with?(ANNO_PREFIX) ||
             safe_entity_name(entity).start_with?(SECTION_PREFIX)
            entity.hidden = true if entity.respond_to?(:hidden=)
            entity.set_attribute(DICT, 'obsolete_annotation', true)
          end
        rescue => error
          puts "Safe cleanup entity warning: #{error.message}"
        end
      end

      model.layers.to_a.each do |tag|
        begin
          tag.visible = false if tag.name.to_s.start_with?(TAG_PREFIX) ||
                               tag.name.to_s.start_with?(SECTION_TAG_PREFIX)
        rescue => error
          puts "Safe cleanup tag warning: #{error.message}"
        end
      end

      # لا نستخدم:
      # model.pages.erase
      # model.layers.remove
      # entity.erase!
      # أثناء إعادة الإنشاء بعد Undo.
      true
    end

    # --------------------------------------------------------
    # Annotations
    # --------------------------------------------------------
    def create_annotations(model, units, level, options)
      return nil if units.empty?

      make_dimensions = options['make_dimensions'] == true
      make_names = options['make_descriptions'] == true
      return nil unless make_dimensions || make_names

      # نفصل العناصر التي تدخل المشهد فقط عن العناصر المسموح بإضافة بيانات لها.
      kitchen_units = units.select { |entity| annotation_kind(entity) == :kitchen_unit }
      room_walls = units.select { |entity| annotation_kind(entity) == :room_wall }
      annotatable = kitchen_units + room_walls

      # لو المستوى يحتوي فقط على حوائط/جروبات عادية، يدخل المشهد بدون أي بيانات.
      return nil if annotatable.empty?

      group = model.entities.add_group
      group.name = "#{ANNO_PREFIX}_LEVEL_#{level}"
      group.set_attribute(DICT, 'annotation_group', true)
      group.set_attribute(DICT, 'level', level)

      tag = annotation_tag(model, level)
      group.layer = tag

      entities = group.entities
      bounds = combined_bounds(units)
      return group unless bounds

      dimension_offset = [bounds.diagonal * 0.025, 12.0 * CM].max

      # الأسماء تخص وحدات المطبخ فقط، ولا تُضاف للحوائط.
      label_layout = make_names ? build_unit_name_layout(kitchen_units) : {}

      kitchen_units.each_with_index do |unit, index|
        begin
          if make_dimensions
            add_unit_dimensions(entities, unit, bounds, dimension_offset, index)
          end

          if make_names
            add_unit_name_label(
              entities,
              unit,
              label_layout[unit.entityID] || {}
            )
          end
        rescue => error
          puts "Kitchen annotation warning: #{entity_name(unit)} - #{error.message}"
        end
      end

      # حائط أداة MHD Room Builder يأخذ المقاسات فقط.
      room_walls.each_with_index do |wall, index|
        begin
          add_unit_dimensions(
            entities,
            wall,
            bounds,
            dimension_offset,
            kitchen_units.length + index
          ) if make_dimensions
        rescue => error
          puts "Room wall dimension warning: #{entity_name(wall)} - #{error.message}"
        end
      end

      scene_only_count = units.length - annotatable.length
      puts "Level #{level}: #{kitchen_units.length} kitchen units, #{room_walls.length} MHD walls, #{scene_only_count} scene-only objects."
      group
    end

    def add_unit_dimensions(entities, unit, project_bounds, offset, index)
      local_box, tr = local_bounds_and_transform(unit)
      return unless local_box && tr

      # نقاط الوحدة حسب محاورها المحلية، ثم تحويلها إلى إحداثيات الموديل.
      z_local = local_box.max.z + (1.2 * CM)

      x_min = local_box.min.x
      x_max = local_box.max.x
      y_min = local_box.min.y
      y_max = local_box.max.y

      width_local = x_max - x_min
      depth_local = y_max - y_min

      # محورا الوحدة الحقيقيان داخل الموديل.
      x_axis = Geom::Vector3d.new(1, 0, 0).transform(tr)
      y_axis = Geom::Vector3d.new(0, 1, 0).transform(tr)

      x_axis.length = 1.0 if x_axis.length > 0
      y_axis.length = 1.0 if y_axis.length > 0

      # --------------------------------------------------
      # عرض الوحدة: خط داخل الوحدة مع إرجاعه للخلف قليلًا
      # --------------------------------------------------
      if width_local.abs > 1.0 * CM
        p1_local = Geom::Point3d.new(x_min, y_min, z_local)
        p2_local = Geom::Point3d.new(x_max, y_min, z_local)

        p1 = p1_local.transform(tr)
        p2 = p2_local.transform(tr)

        # إبقاء مقاس العرض داخل الوحدة وتحريكه بعد المنتصف ناحية الضهر.
        # 0.50 = السنتر، و0.65 = خلف السنتر قليلًا بدون الخروج من الوحدة.
        width_offset = y_axis.clone
        width_offset.length = depth_local.abs * 0.65

        dimension = entities.add_dimension_linear(p1, p2, width_offset)
        dimension.text = format_cm(width_local.abs) if dimension.respond_to?(:text=)
        dimension.set_attribute(DICT, 'dimension_type', 'width')
        dimension.set_attribute(DICT, 'source_entity_id', unit.entityID)
      end

      # --------------------------------------------------
      # عمق الوحدة: خط داخل منتصف العرض
      # --------------------------------------------------
      if depth_local.abs > 1.0 * CM
        p3_local = Geom::Point3d.new(x_min, y_min, z_local)
        p4_local = Geom::Point3d.new(x_min, y_max, z_local)

        p3 = p3_local.transform(tr)
        p4 = p4_local.transform(tr)

        # نحرك مقاس العمق ناحية يمين الوحدة بدل السنتر
        # لتجنب تداخل نص العرض والعمق عند نقطة المنتصف.
        depth_offset = x_axis.clone
        depth_offset.length = width_local.abs * 0.78

        dimension = entities.add_dimension_linear(p3, p4, depth_offset)
        dimension.text = format_cm(depth_local.abs) if dimension.respond_to?(:text=)
        dimension.set_attribute(DICT, 'dimension_type', 'depth')
        dimension.set_attribute(DICT, 'source_entity_id', unit.entityID)
      end
    rescue => error
      puts "Dimension warning: #{entity_name(unit)} - #{error.message}"
    end

    def local_bounds_and_transform(entity)
      if entity.is_a?(Sketchup::ComponentInstance)
        [entity.definition.bounds, entity.transformation]
      elsif entity.is_a?(Sketchup::Group)
        [entity.entities.bounds, entity.transformation]
      else
        [nil, nil]
      end
    end

    # اسم الوحدة بنفس منطق كود تقرير الوحدات:
    # dynamic_attributes["name"] ثم اسم الـDefinition كحل احتياطي.
    def shop_unit_name(unit)
      name = nil

      begin
        dict = unit.attribute_dictionary('dynamic_attributes', false)
        name = dict['name'] if dict
      rescue
        name = nil
      end

      if name.to_s.strip.empty?
        if unit.is_a?(Sketchup::ComponentInstance)
          name = MHDESIGN::Language.original_definition_name(unit.definition)
        elsif unit.is_a?(Sketchup::Group)
          name = unit.name
        end
      end

      MHDESIGN_SHOP_LANG.t(clean_unit_name(name))
    end

    def clean_unit_name(value)
      value.to_s
           .encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
           .gsub(/[\u0000-\u001F]/, ' ')
           .gsub(/\s+/, ' ')
           .strip
    rescue
      value.to_s.strip
    end

    # يبني توزيعًا ذكيًا للأسماء على مسارات منفصلة لكل اتجاه حائط.
    def build_unit_name_layout(units)
      groups = Hash.new { |hash, key| hash[key] = [] }

      units.each do |unit|
        local_box, tr = local_bounds_and_transform(unit)
        next unless local_box && tr

        text = shop_unit_name(unit)
        next if text.empty?

        x_center = (local_box.min.x + local_box.max.x) * 0.5
        y_front  = local_box.min.y
        z_top    = local_box.max.z + (1.5 * CM)

        anchor = Geom::Point3d.new(x_center, y_front, z_top).transform(tr)

        front = Geom::Vector3d.new(0, -1, 0).transform(tr)
        tangent = Geom::Vector3d.new(1, 0, 0).transform(tr)
        next if front.length == 0 || tangent.length == 0

        front.length = 1.0
        tangent.length = 1.0

        wall_key =
          if front.x.abs >= front.y.abs
            front.x >= 0 ? :east : :west
          else
            front.y >= 0 ? :north : :south
          end

        # ترتيب الوحدات على امتداد الحائط.
        coord =
          if tangent.x.abs >= tangent.y.abs
            anchor.x
          else
            anchor.y
          end

        # تقدير مساحة الاسم المطلوبة؛ الهدف فصل النصوص قبل إنشائها.
        estimated_span = [text.length * 1.15 * CM, 30.0 * CM].max

        groups[wall_key] << {
          unit: unit,
          anchor: anchor,
          front: front,
          tangent: tangent,
          coord: coord,
          text: text,
          span: estimated_span
        }
      end

      layout = {}

      groups.each_value do |items|
        items.sort_by! { |item| item[:coord] }

        # آخر نهاية مستخدمة في كل مسار.
        lane_ends = []

        items.each do |item|
          start_coord = item[:coord] - (item[:span] * 0.5)
          end_coord   = item[:coord] + (item[:span] * 0.5)
          gap = 14.0 * CM

          lane = lane_ends.index { |last_end| start_coord > last_end + gap }

          if lane.nil?
            lane = lane_ends.length
            lane_ends << end_coord
          else
            lane_ends[lane] = end_coord
          end

          # لا نسمح بعدد لا نهائي من الصفوف.
          # بعد 4 صفوف نوزع الاسم أفقيًا داخل الصف الرابع.
          lane = 3 if lane > 3

          layout[item[:unit].entityID] = {
            lane: lane,
            front: item[:front],
            tangent: item[:tangent],
            text: item[:text]
          }
        end
      end

      layout
    end

    def add_unit_name_label(entities, unit, layout)
      local_box, tr = local_bounds_and_transform(unit)
      return unless local_box && tr

      text = layout[:text].to_s
      text = shop_unit_name(unit) if text.empty?
      return if text.empty?

      x_center = (local_box.min.x + local_box.max.x) * 0.5
      y_front  = local_box.min.y
      z_top    = local_box.max.z + (1.5 * CM)

      anchor_local = Geom::Point3d.new(x_center, y_front, z_top)
      anchor = anchor_local.transform(tr)

      front_vector = layout[:front] || Geom::Vector3d.new(0, -1, 0).transform(tr)
      tangent_vector = layout[:tangent] || Geom::Vector3d.new(1, 0, 0).transform(tr)
      return if front_vector.length == 0

      lane = layout[:lane].to_i

      # الصف الأول أبعد عن الوحدة، وكل صف بعده بمسافة أكبر.
      front_vector = front_vector.clone
      front_vector.length = (28.0 + lane * 17.0) * CM

      # زحزحة صغيرة بالتبادل داخل كل مسار لتقليل التطابق التام.
      if tangent_vector.length > 0
        tangent_vector = tangent_vector.clone
        tangent_vector.length = (lane.odd? ? 7.0 : -7.0) * CM
      end

      leader_vector = front_vector + tangent_vector

      label = entities.add_text(text, anchor, leader_vector)
      label.set_attribute(DICT, 'annotation_type', 'unit_name')
      label.set_attribute(DICT, 'source_entity_id', unit.entityID)
      label.set_attribute(DICT, 'label_lane', lane)
    rescue => error
      puts "Unit name warning: #{entity_name(unit)} - #{error.message}"
    end

    def add_unit_description(entities, unit, offset, index)
      box = unit.bounds
      center = box.center

      anchor = Geom::Point3d.new(
        center.x,
        center.y,
        box.max.z + 3.0 * CM
      )

      side = index.even? ? 1.0 : -1.0

      target_point = Geom::Point3d.new(
        center.x + side * offset,
        center.y + offset * (0.45 + ((index % 3) * 0.22)),
        box.max.z + 3.0 * CM
      )

      # SketchUp يحتاج Vector للـLeader وليس Point ثالثة.
      leader_vector = target_point - anchor

      label = entities.add_text(
        build_description(unit),
        anchor,
        leader_vector
      )

      label.set_attribute(DICT, 'source_entity_id', unit.entityID)
    rescue => error
      puts "Text warning: #{entity_name(unit)} - #{error.message}"
    end

    def build_description(unit)
      explicit = description_from_attributes(unit)
      name = entity_name(unit)
      name = MHDESIGN_SHOP_LANG.key('SHOP_DEFAULT_KITCHEN_UNIT', 'وحدة مطبخ') if name.empty?

      box = unit.bounds
      width = box.width.to_f / CM
      depth = box.depth.to_f / CM
      height = box.height.to_f / CM

      [
        explicit || name,
        "#{MHDESIGN_SHOP_LANG.key('SHOP_WIDTH', 'عرض')} #{format_number(width)} #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}",
        "#{MHDESIGN_SHOP_LANG.key('SHOP_DEPTH', 'عمق')} #{format_number(depth)} #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}",
        "#{MHDESIGN_SHOP_LANG.key('SHOP_HEIGHT', 'ارتفاع')} #{format_number(height)} #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}"
      ].join("\n")
    end

    def description_from_attributes(unit)
      keys = [
        'وصف الوحدة',
        'الوصف',
        'description',
        'unit_description',
        'نوع الوحدة',
        'نوع_الوحدة',
        'unit_type',
        'cabinet_type'
      ]

      keys.each do |wanted_key|
        value = read_attribute_anywhere(unit, wanted_key)
        return value.to_s.strip unless value.to_s.strip.empty?
      end

      nil
    end

    def read_attribute_anywhere(entity, wanted_key)
      normalized_wanted = normalize(wanted_key)
      dictionaries = []

      if entity.attribute_dictionaries
        dictionaries += entity.attribute_dictionaries.to_a
      end

      if entity.is_a?(Sketchup::ComponentInstance)
        definition = entity.definition
        if definition.attribute_dictionaries
          dictionaries += definition.attribute_dictionaries.to_a
        end
      end

      dictionaries.each do |dictionary|
        dictionary.each_pair do |key, value|
          return value if normalize(key) == normalized_wanted
        end
      end

      nil
    end

    def normalize(text)
      text.to_s
          .downcase
          .gsub(/[أإآ]/, 'ا')
          .gsub(/ة/, 'ه')
          .gsub(/ى/, 'ي')
          .gsub(/[^\p{Arabic}a-z0-9]+/u, ' ')
          .strip
    end

    def safe_entity_name(entity)
      return '' unless entity
      return entity.name.to_s if entity.respond_to?(:name)
      ''
    rescue
      ''
    end

    def entity_name(entity)
      names = []
      names << entity.name.to_s if entity.respond_to?(:name)

      if entity.is_a?(Sketchup::ComponentInstance)
        names << MHDESIGN::Language.original_definition_name(entity.definition).to_s
      end

      names.reject(&:empty?).join(' ').strip
    end

    def add_scene_title(entities, bounds, level)
      point = Geom::Point3d.new(
        bounds.center.x,
        bounds.center.y,
        bounds.max.z + [bounds.diagonal * 0.08, 30.0 * CM].max
      )

      entities.add_text(
        "#{MHDESIGN_SHOP_LANG.key('SHOP_LEVEL', 'المستوى')} #{level}\n#{MHDESIGN_SHOP_LANG.key('SHOP_DRAWING_TITLE', 'MHDESIGN SHOP DRAWING')}",
        point
      )
    end

    def set_annotation_groups_visibility(groups, active_level)
      groups.each do |level, group|
        next unless group&.valid?
        group.hidden = (level != active_level)
      end
    end

    def annotation_tag(model, level)
      token = @run_token.to_s.empty? ? 'CURRENT' : @run_token.to_s
      name = "#{TAG_PREFIX} #{token} #{format('%02d', level)}"
      model.layers[name] || model.layers.add(name)
    end

    def set_annotation_tag_visibility(model, active_level)
      current_token = @run_token.to_s

      model.layers.to_a.each do |tag|
        next unless tag.name.to_s.start_with?(TAG_PREFIX)

        begin
          # Tags القديمة تظل مخفية دائمًا.
          if !current_token.empty? && tag.name.to_s.include?(" #{current_token} ")
            level_number = tag.name.to_s.split.last.to_i
            tag.visible = (level_number == active_level)
          else
            tag.visible = false
          end
        rescue => error
          puts "Tag visibility warning: #{error.message}"
        end
      end
    end

    def create_base_scene(model)
      deactivate_section_plane(model)
      # المشهد الأساسي دائمًا Perspective عادي مع الاحتفاظ باتجاه الكاميرا الحالي.
      begin
        base_camera = model.active_view.camera
        base_camera.perspective = true if base_camera.respond_to?(:perspective=)
        model.active_view.camera = base_camera
      rescue => error
        puts "Base camera warning: #{error.message}"
      end

      # إظهار كل العناصر الرئيسية قبل حفظ المشهد الأساسي.
      model.entities.to_a.each do |entity|
        next unless entity.respond_to?(:valid?) && entity.valid?
        next if entity.get_attribute(DICT, 'annotation_group', false)
        next if entity.get_attribute(DICT, 'section_plane', false)
        next if safe_entity_name(entity).start_with?(ANNO_PREFIX)
        next if safe_entity_name(entity).start_with?(SECTION_PREFIX)
        entity.hidden = false if entity.respond_to?(:hidden=)
      end

      # إخفاء Tags الشروحات والمقاسات في المشهد الأساسي.
      model.layers.to_a.each do |tag|
        tag.visible = false if tag.name.start_with?(TAG_PREFIX) ||
                             tag.name.start_with?(SECTION_TAG_PREFIX)
      end

      page = model.pages[BASE_SCENE_NAME] || model.pages.add(BASE_SCENE_NAME)

      model.active_view.invalidate rescue nil

      begin
        flags =
          Sketchup::Page::FLAG_USE_CAMERA |
          Sketchup::Page::FLAG_USE_HIDDEN |
          Sketchup::Page::FLAG_USE_HIDDEN_GEOMETRY |
          Sketchup::Page::FLAG_USE_LAYER_VISIBILITY |
          Sketchup::Page::FLAG_USE_SECTION_PLANES |
          Sketchup::Page::FLAG_USE_RENDERING_OPTIONS |
          Sketchup::Page::FLAG_USE_SHADOWINFO

        page.update(flags)
      rescue
        page.update
      end

      page
    end

    def update_base_scene_clean(model, base_scene, all_candidate_entities)
      return unless base_scene

      # إظهار المشروع كاملًا في المشهد الأساسي.
      all_candidate_entities.each do |entity|
        entity.hidden = false if entity&.valid?
      end

      model.entities.to_a.each do |entity|
        next unless entity.respond_to?(:valid?) && entity.valid?
        next if entity.get_attribute(DICT, 'annotation_group', false)
        next if entity.get_attribute(DICT, 'section_plane', false)
        next if safe_entity_name(entity).start_with?(ANNO_PREFIX)
        next if safe_entity_name(entity).start_with?(SECTION_PREFIX)
        entity.hidden = false if entity.respond_to?(:hidden=)
      end

      # إخفاء كل Tags المقاسات والأوصاف في المشهد الأساسي.
      model.layers.to_a.each do |tag|
        tag.visible = false if tag.name.start_with?(TAG_PREFIX) ||
                             tag.name.start_with?(SECTION_TAG_PREFIX)
      end

      deactivate_section_plane(model)

      # رجوع الكاميرا في المشهد الأساسي إلى Perspective عادي.
      begin
        base_camera = model.active_view.camera
        base_camera.perspective = true if base_camera.respond_to?(:perspective=)
        model.active_view.camera = base_camera
      rescue => error
        puts "Base perspective warning: #{error.message}"
      end

      # تحديث المشهد الأساسي شامل الكاميرا والرؤية.
      begin
        flags =
          Sketchup::Page::FLAG_USE_CAMERA |
          Sketchup::Page::FLAG_USE_HIDDEN |
          Sketchup::Page::FLAG_USE_HIDDEN_GEOMETRY |
          Sketchup::Page::FLAG_USE_LAYER_VISIBILITY |
          Sketchup::Page::FLAG_USE_SECTION_PLANES |
          Sketchup::Page::FLAG_USE_RENDERING_OPTIONS |
          Sketchup::Page::FLAG_USE_SHADOWINFO

        base_scene.update(flags)
      rescue
        base_scene.update
      end
    end

    # --------------------------------------------------------
    # Camera and scenes
    # --------------------------------------------------------
    # إنشاء أربعة مشاهد واجهات/سكشن طبقًا لمحاور الموديل الرئيسية.
    # Front  : الكاميرا من Y السالب نحو المطبخ.
    # Back   : الكاميرا من Y الموجب نحو المطبخ.
    # Left   : الكاميرا من X السالب نحو المطبخ.
    # Right  : الكاميرا من X الموجب نحو المطبخ.
    def create_registered_section_scenes(model, all_candidate_entities, annotation_groups, options)
      annotation_groups.each_value do |group|
        group.hidden = true if group && group.valid?
      end
      hide_all_annotation_tags(model)

      section_planes = {}
      section_annotation_groups = {}
      (1..@sections_count).each do |number|
        data = @sections[number] || {}
        visible_entities = with_wall_group(entities_for_section(model, number), model)
        next if visible_entities.empty?
        bounds = combined_bounds(visible_entities)
        next unless bounds

        axis = detect_section_axis(visible_entities)
        data['direction'] = axis.to_s
        depth_cm = (data['depth_cm'] || 80.0).to_f
        plane = create_section_plane_for_view(model, bounds, axis, depth_cm, number)
        section_planes[number] = plane if plane
        if options['section_make_dimensions'] || options['section_make_descriptions']
          section_annotation_groups[number] = create_section_annotations(
            model,
            entities_for_section(model, number),
            number,
            axis,
            depth_cm,
            options,
            bounds
          )
        end
      end

      (1..@sections_count).each do |number|
        data = @sections[number] || {}
        visible_entities = with_wall_group(entities_for_section(model, number), model)
        next if visible_entities.empty?
        bounds = combined_bounds(visible_entities)
        next unless bounds

        axis = detect_section_axis(visible_entities)
        data['direction'] = axis.to_s
        depth_cm = (data['depth_cm'] || 80.0).to_f
        set_visibility(all_candidate_entities, visible_entities)
        set_numbered_section_planes_visibility(section_planes, number)

        # عزل بيانات كل وجه تمامًا عن باقي الأوجه والمستويات.
        # نخفي كل Tags الشروحات أولًا، ثم نظهر جروب الوجه الحالي فقط.
        hide_all_annotation_tags(model)
        set_numbered_annotation_groups_visibility(section_annotation_groups, number)

        activate_section_plane(model, section_planes[number])
        set_elevation_camera(model, bounds, axis)

        # منع اختفاء النصوص وخطوط المقاسات عند النظر للواجهة بشكل عمودي تمامًا.
        # نحرك جروب بيانات الوجه الحالي 2 مم فقط ناحية الكاميرا الفعلية.
        # الحركة في عمق الكاميرا لا تغيّر مكان البيانات بصريًا في Parallel Projection،
        # لكنها تفصلها عن سطح الوحدة/الحائط وتمنع Z-fighting.
        move_section_annotations_toward_camera(
          section_annotation_groups[number],
          model,
          2.0
        )

        create_or_update_scene(
          model,
          format('%s %02d - %s %d', SCENE_PREFIX, 9 + number, MHDESIGN_SHOP_LANG.key('SHOP_SECTION_FACE', 'الوجه'), number)
        )
      end

      deactivate_section_plane(model)
    rescue => error
      puts "Registered sections warning: #{error.message}"
      puts error.backtrace.join("\n") if error.backtrace
    end

    # يحرك بيانات وجه السكشن مسافة صغيرة ناحية الكاميرا لمنع Z-fighting.
    # distance_mm بالملليمتر، والحركة تتم مرة واحدة فقط لكل جروب.
    # هذا التعديل خاص ببيانات الأوجه ولا يلمس بيانات المستويات.
    def move_section_annotations_toward_camera(group, model, distance_mm = 2.0)
      return unless group && group.valid?
      return if group.get_attribute(DICT, 'camera_nudge_applied', false) == true

      camera = model.active_view.camera
      return unless camera

      # camera.direction يتجه من عين الكاميرا إلى الموديل،
      # لذلك الاتجاه العكسي هو الاتجاه ناحية الكاميرا.
      toward_camera = camera.direction.clone
      return if toward_camera.length.to_f <= 0

      toward_camera.reverse!
      toward_camera.length = distance_mm.to_f.mm

      transformation = Geom::Transformation.translation(toward_camera)
      group.transform!(transformation)
      group.set_attribute(DICT, 'camera_nudge_applied', true)
      group.set_attribute(DICT, 'camera_nudge_mm', distance_mm.to_f)
      group.set_attribute(DICT, 'annotation_scope', 'section')
      group
    rescue => error
      puts "Section camera nudge warning: #{error.message}"
      nil
    end

    # يعيد تثبيت حالة مشاهد المستويات بعد إنشاء Tags وجروبات الأوجه.
    # السبب: أي Tag جديد ينشأ بعد حفظ Scene قد يظهر داخل المشاهد القديمة افتراضيًا.
    # هذه الدالة لا تغيّر منطق مقاسات المستويات؛ فقط تعيد حفظ الرؤية الصحيحة.
    def refresh_level_scenes_after_sections(model, all_candidate_entities, level_annotation_groups, options)
      deactivate_section_plane(model)

      # إخفاء كل Section Planes وTags الخاصة بها داخل مشاهد المستويات.
      model.entities.to_a.each do |entity|
        next unless entity.respond_to?(:valid?) && entity.valid?
        next unless entity.get_attribute(DICT, 'section_plane', false)
        entity.hidden = true if entity.respond_to?(:hidden=)
      rescue
      end

      model.layers.to_a.each do |tag|
        tag.visible = false if tag.name.to_s.start_with?(SECTION_TAG_PREFIX)
      rescue
      end

      # إخفاء كل جروبات بيانات الأوجه صراحةً.
      model.entities.to_a.each do |entity|
        next unless entity.is_a?(Sketchup::Group) && entity.valid?
        next unless entity.get_attribute(DICT, 'annotation_group', false)
        next unless entity.get_attribute(DICT, 'annotation_scope', '').to_s == 'section'
        entity.hidden = true
        entity.layer.visible = false if entity.layer
      rescue
      end

      (1..@levels_count).each do |level|
        visible_entities = with_wall_group(entities_for_level(model, level), model)

        set_visibility(all_candidate_entities, visible_entities)
        set_annotation_groups_visibility(level_annotation_groups, level)

        # يخفي كل Tags الأوجه (101..104) وباقي المستويات،
        # ويُظهر Tag المستوى الحالي فقط.
        set_annotation_tag_visibility(model, level)

        set_top_camera(model, visible_entities) if options['level_top_view']

        create_or_update_scene(
          model,
          format('%s %02d - %s %d', SCENE_PREFIX, level, MHDESIGN_SHOP_LANG.key('SHOP_LEVEL', 'المستوى'), level)
        )
      end
    rescue => error
      puts "Refresh level scenes warning: #{error.message}"
      puts error.backtrace.join("\n") if error.backtrace
    end

    def set_numbered_annotation_groups_visibility(groups, active_number)
      groups.each do |number, group|
        next unless group && group.valid?
        group.hidden = (number != active_number)
        group.layer.visible = (number == active_number) if group.layer
      rescue
      end
    end

    def create_section_annotations(model, units, number, axis, depth_cm, options, view_bounds = nil)
      units = units.select { |entity| kitchen_unit?(entity) }
      return nil if units.empty?

      make_dimensions = options['section_make_dimensions'] == true
      make_names = options['section_make_descriptions'] == true
      return nil unless make_dimensions || make_names

      group = model.entities.add_group
      group.name = "#{ANNO_PREFIX}_SECTION_#{number}"
      group.set_attribute(DICT, 'annotation_group', true)
      group.set_attribute(DICT, 'annotation_scope', 'section')
      group.set_attribute(DICT, 'section_number', number)

      # Tag مستقل لكل وجه، ولا يُستخدم مع مقاسات المستويات.
      tag = annotation_tag(model, 100 + number)
      group.layer = tag

      face_bounds = combined_bounds(units)
      return group unless face_bounds

      # حدود جروب الحائط/المشهد هي الإطار النهائي المسموح للمقاسات داخله.
      # لو لم تصل الحدود من مشهد الوجه، نستخدم حدود الوحدات كحل احتياطي.
      layout_bounds = view_bounds || face_bounds

      units.each_with_index do |unit, index|
        begin
          box = unit.bounds
          lane_offset = (10.0 + (index % 4) * 4.0) * CM

          if make_dimensions
            add_section_unit_width_dimension(
              group.entities,
              unit,
              box,
              layout_bounds,
              axis,
              lane_offset
            )

            add_section_unit_height_dimension(
              group.entities,
              unit,
              box,
              layout_bounds,
              axis,
              lane_offset
            )
          end

          if make_names
            add_section_unit_name(
              group.entities,
              unit,
              box,
              axis,
              index
            )
          end
        rescue => error
          puts "Section annotation warning: #{entity_name(unit)} - #{error.message}"
        end
      end

      # لا نحرك جروب بيانات الوجه بالكامل بعد الإنشاء.
      # كل مقاس واسم يتم إنشاؤه مباشرة على وش الوحدة المحلي:
      # العرض عند Y = 0، والارتفاع/الأسماء أمام الوش بقيمة Y سالبة بسيطة.
      group
    end

    # مقاسات العرض الخاصة بالأوجه فقط.
    # يختار الخط أعلى أو أسفل الوحدة حسب المساحة المتاحة، مع إبقائه داخل حدود الحائط.
    def add_section_unit_width_dimension(entities, unit, box, layout_bounds, axis, offset)
      # العرض في الأوجه يُرسم على وش الوحدة المحلي مباشرة عند Y = 0.
      # لا نستخدم box.center.y لأنه قد يضع المقاس داخل الوحدة أو خلف الحائط.
      local_box, tr = local_bounds_and_transform(unit)
      return unless local_box && tr

      margin = 4.0 * CM
      min_offset = 3.0 * CM
      max_z_world = layout_bounds.max.z - margin
      min_z_world = layout_bounds.min.z + margin

      space_below = box.min.z - min_z_world
      space_above = max_z_world - box.max.z
      place_above = space_above > space_below
      desired = [offset.to_f, min_offset].max

      base_z_local = place_above ? local_box.max.z : local_box.min.z
      offset_z_local = place_above ? desired : -desired

      # مرجع العرض: وش الوحدة = Y صفر.
      p1_local = Geom::Point3d.new(local_box.min.x, 0.0, base_z_local)
      p2_local = Geom::Point3d.new(local_box.max.x, 0.0, base_z_local)
      p1 = p1_local.transform(tr)
      p2 = p2_local.transform(tr)

      offset_vector = Geom::Vector3d.new(0, 0, offset_z_local).transform(tr)
      fallback_value = p1.distance(p2)
      value = section_unit_dimension_value(unit, 'lenx', fallback_value)

      dimension = entities.add_dimension_linear(p1, p2, offset_vector)
      dimension.text = format_cm(value) if dimension.respond_to?(:text=)
      dimension.set_attribute(DICT, 'annotation_type', 'section_width')
      dimension.set_attribute(DICT, 'annotation_scope', 'section')
      dimension.set_attribute(DICT, 'source_entity_id', unit.entityID)
      dimension.set_attribute(DICT, 'local_front_y_cm', 0.0)
      dimension
    end

    # مقاسات الارتفاع الخاصة بالأوجه فقط.
    # خط الارتفاع يوضع على وش الوحدة ناحية كاميرا الوجه، وليس ناحية الحائط/الضهر.
    # الارتفاع مأخوذ من الحدود الكاملة للوحدة من أقل نقطة إلى أعلى نقطة،
    # لذلك يشمل الرجول وأي أجزاء تابعة للوحدة ولا يعتمد على LenZ الخاص بالشاسيه فقط.
    def add_section_unit_height_dimension(entities, unit, box, layout_bounds, axis, offset)
      # ------------------------------------------------------------
      # منطق الأوجه فقط:
      # - وش الوحدة في المحاور المحلية هو Y = 0.
      # - مقاس الارتفاع يتمركز تمامًا في منتصف الوحدة على محور X.
      # - خط المقاس يخرج أمام الوحدة فقط على محور Y السالب.
      # - القياس من أقل Z إلى أعلى Z في كامل الوحدة، لذلك يشمل الرجول.
      # - لا يوجد اختيار يمين أو شمال في مقاس ارتفاع الأوجه.
      # ------------------------------------------------------------
      local_box, tr = local_bounds_and_transform(unit)
      return unless local_box && tr

      z0 = local_box.min.z
      z1 = local_box.max.z
      height = z1 - z0
      return if height.to_f <= 0

      x_center = (local_box.min.x + local_box.max.x) * 0.5

      # نقطتا القياس في منتصف الوحدة X وعلى وش الوحدة Y = 0.
      p1_local = Geom::Point3d.new(x_center, 0.0, z0)
      p2_local = Geom::Point3d.new(x_center, 0.0, z1)
      p1 = p1_local.transform(tr)
      p2 = p2_local.transform(tr)

      # اتجاه أمام الوحدة هو محور Y المحلي السالب.
      # نطبّع المتجه بعد التحويل ثم نفرض طولًا فعليًا ثابتًا 5 سم،
      # حتى لا تتأثر المسافة بأي Scale موجود على الوحدة.
      offset_vector = Geom::Vector3d.new(0, -1, 0).transform(tr)
      return if offset_vector.length.to_f <= 0
      offset_vector.length = 5.0 * CM

      dimension = entities.add_dimension_linear(p1, p2, offset_vector)
      dimension.text = format_cm(height) if dimension.respond_to?(:text=)
      dimension.set_attribute(DICT, 'annotation_type', 'section_height')
      dimension.set_attribute(DICT, 'annotation_scope', 'section')
      dimension.set_attribute(DICT, 'source_entity_id', unit.entityID)
      dimension.set_attribute(DICT, 'height_includes_legs', true)
      dimension.set_attribute(DICT, 'height_on_front_face', true)
      dimension.set_attribute(DICT, 'height_centered_on_local_x', true)
      dimension.set_attribute(DICT, 'local_front_y_cm', -5.0)
      dimension.set_attribute(DICT, 'actual_front_offset_cm', 5.0)
      dimension
    end

    def add_section_unit_name(entities, unit, box, axis, index)
      text = shop_unit_name(unit)
      return if text.to_s.strip.empty?

      local_box, tr = local_bounds_and_transform(unit)
      return unless local_box && tr

      # الاسم يُنشأ أمام وش الوحدة مباشرة، ولا نعتمد على center.y العالمي.
      # Y سالب = قدام الوحدة، طبقًا لمحاور مكتبة MHDESIGN.
      y_front = -1.0 * CM
      x_center = (local_box.min.x + local_box.max.x) * 0.5
      z_top = local_box.max.z
      lane = index % 3

      anchor_local = Geom::Point3d.new(x_center, y_front, z_top)
      anchor = anchor_local.transform(tr)

      leader_local = Geom::Vector3d.new(0, -8.0 * CM, (10.0 + lane * 7.0) * CM)
      leader_world = leader_local.transform(tr)

      label = entities.add_text(text, anchor, leader_world)
      label.set_attribute(DICT, 'annotation_type', 'unit_name')
      label.set_attribute(DICT, 'annotation_scope', 'section')
      label.set_attribute(DICT, 'source_entity_id', unit.entityID)
      label.set_attribute(DICT, 'local_front_y_cm', -1.0)
      label
    end

    # قراءة المقاس الحقيقي من Dynamic Attributes أولًا.
    # قيم LenX / LenY / LenZ داخل SketchUp تكون بالبوصة، مثل Length API.
    def section_unit_dimension_value(unit, key, fallback)
      value = read_dynamic_length_value(unit, key)
      value = fallback if !value || value.to_f <= 0
      value.to_f
    rescue
      fallback.to_f
    end

    def read_dynamic_length_value(unit, key)
      wanted = key.to_s.downcase
      sources = [unit]
      sources << unit.definition if unit.is_a?(Sketchup::ComponentInstance)

      sources.each do |source|
        dictionary = source.attribute_dictionary('dynamic_attributes', false)
        next unless dictionary

        dictionary.each_pair do |attribute_key, value|
          next unless attribute_key.to_s.downcase == wanted
          number = value.to_f
          return number if number > 0
        end
      end

      nil
    rescue
      nil
    end

    # نقل بيانات الوجه مسافة صغيرة فقط إلى الجهة التي يحتفظ بها السكشن.
    # النسخة السابقة كانت تنقل الجروب بمسافة تساوي حجم المشروع بالكامل،
    # ولذلك كانت المقاسات تبدو بعيدة جدًا خلف المطبخ عند الرجوع للمشهد الأساسي
    # أو عند النظر بزاوية. هنا نضع الجروب بعد مستوى القطع مباشرة بهامش صغير.
    def move_section_annotations_to_kept_side(group, bounds, axis, requested_depth_cm)
      # متروكة للتوافق فقط. لا يتم تحريك جروب بيانات الأوجه بالكامل.
      # التحريك الجماعي كان سبب انتقال المقاسات والأسماء خلف الحائط.
      group
    end

    def section_direction_title(axis)
      case axis.to_sym
      when :back then MHDESIGN_SHOP_LANG.key('SHOP_BACK', 'رجوع')
      when :left then MHDESIGN_SHOP_LANG.key('SHOP_LEFT', 'يسار')
      when :right then MHDESIGN_SHOP_LANG.key('SHOP_RIGHT', 'يمين')
      else MHDESIGN_SHOP_LANG.key('SHOP_FRONT', 'أمام')
      end
    end

    def create_section_plane_for_view(model, bounds, axis, requested_depth_cm = 80.0, section_number = nil)
      center = bounds.center

      # عمق القطع المطلوب من كل جانب.
      # يتم تقليله تلقائيًا إذا كان المشروع أصغر من 160 سم في الاتجاه المقابل،
      # حتى لا يمر السكشن إلى ما بعد منتصف المطبخ.
      axis_span = [:front, :back].include?(axis) ? bounds.depth : bounds.width
      requested_depth = [requested_depth_cm.to_f, 1.0].max * CM
      cut_depth = [requested_depth, axis_span * 0.45].min

      case axis
      when :front
        point = Geom::Point3d.new(center.x, bounds.min.y + cut_depth, center.z)
        normal = Geom::Vector3d.new(0, 1, 0)
      when :back
        point = Geom::Point3d.new(center.x, bounds.max.y - cut_depth, center.z)
        normal = Geom::Vector3d.new(0, -1, 0)
      when :left
        point = Geom::Point3d.new(bounds.min.x + cut_depth, center.y, center.z)
        normal = Geom::Vector3d.new(1, 0, 0)
      when :right
        point = Geom::Point3d.new(bounds.max.x - cut_depth, center.y, center.z)
        normal = Geom::Vector3d.new(-1, 0, 0)
      else
        return nil
      end

      plane = model.entities.add_section_plane(point, normal)
      plane.name = "#{SECTION_PREFIX}_#{section_number || axis.to_s.upcase}_#{@run_token}" if plane.respond_to?(:name=)
      plane.set_attribute(DICT, 'section_plane', true)
      plane.set_attribute(DICT, 'section_axis', axis.to_s)
      plane.set_attribute(DICT, 'cut_depth_cm', requested_depth_cm.to_f)
      plane.set_attribute(DICT, 'section_number', section_number) if section_number
      plane.layer = section_tag(model, section_number || axis)
      plane.hidden = false if plane.respond_to?(:hidden=)
      plane
    rescue => error
      puts "Section plane #{axis} warning: #{error.message}"
      nil
    end

    def section_tag(model, axis)
      token = @run_token.to_s.empty? ? 'CURRENT' : @run_token.to_s
      name = "#{SECTION_TAG_PREFIX} #{token} #{axis.to_s.upcase}"
      model.layers[name] || model.layers.add(name)
    end

    def set_numbered_section_planes_visibility(section_planes, active_number)
      section_planes.each do |number, plane|
        next unless plane && plane.valid?
        plane.hidden = (number != active_number) if plane.respond_to?(:hidden=)
        begin
          plane.layer.visible = (number == active_number) if plane.layer
        rescue
        end
      end
    end

    def set_section_planes_visibility(section_planes, active_axis)
      section_planes.each do |axis, plane|
        next unless plane && plane.valid?
        plane.hidden = (axis != active_axis) if plane.respond_to?(:hidden=)
        begin
          plane.layer.visible = (axis == active_axis) if plane.layer
        rescue
        end
      end
    end

    def activate_section_plane(model, plane)
      return unless plane && plane.valid?
      begin
        model.entities.active_section_plane = plane
      rescue => error
        puts "Activate section warning: #{error.message}"
      end

      begin
        model.rendering_options['DisplaySectionCuts'] = true
        model.rendering_options['DisplaySectionPlanes'] = false
      rescue
      end
    end

    def deactivate_section_plane(model)
      begin
        model.entities.active_section_plane = nil
      rescue
      end
      begin
        model.rendering_options['DisplaySectionCuts'] = false
        model.rendering_options['DisplaySectionPlanes'] = false
      rescue
      end
      model.layers.to_a.each do |tag|
        tag.visible = false if tag.name.to_s.start_with?(SECTION_TAG_PREFIX)
      end
    end

    def hide_all_annotation_tags(model)
      model.layers.to_a.each do |tag|
        tag.visible = false if tag.name.to_s.start_with?(TAG_PREFIX)
      end
    end

    def set_elevation_camera(model, bounds, axis)
      center = bounds.center
      span = [bounds.width, bounds.depth, bounds.height].max
      distance = [span * 3.2, 300.0 * CM].max

      case axis
      when :front
        eye = Geom::Point3d.new(center.x, bounds.min.y - distance, center.z)
        up = Geom::Vector3d.new(0, 0, 1)
      when :back
        eye = Geom::Point3d.new(center.x, bounds.max.y + distance, center.z)
        up = Geom::Vector3d.new(0, 0, 1)
      when :left
        eye = Geom::Point3d.new(bounds.min.x - distance, center.y, center.z)
        up = Geom::Vector3d.new(0, 0, 1)
      when :right
        eye = Geom::Point3d.new(bounds.max.x + distance, center.y, center.z)
        up = Geom::Vector3d.new(0, 0, 1)
      else
        return
      end

      # لفة بسيطة جدًا حول محور Z تمنع تطابق الكاميرا 100% مع مستوى السكشن.
      # النتيجة تظل واجهة شبه مستقيمة وParallel Projection، لكن النصوص
      # وخطوط المقاسات لا تختفي بصريًا عند التطابق الكامل مع الأسطح.
      slight_angle = 0.5.degrees
      rotation = Geom::Transformation.rotation(
        center,
        Geom::Vector3d.new(0, 0, 1),
        slight_angle
      )
      eye = eye.transform(rotation)

      camera = Sketchup::Camera.new(eye, center, up)
      camera.perspective = false if camera.respond_to?(:perspective=)
      model.active_view.camera = camera
      model.active_view.zoom_extents

      active_camera = model.active_view.camera
      active_camera.perspective = false if active_camera.respond_to?(:perspective=)
      model.active_view.camera = active_camera
    end

    def set_top_camera(model, visible_units)
      bounds = combined_bounds(visible_units)
      return unless bounds

      center = bounds.center
      distance = [
        bounds.width,
        bounds.depth,
        bounds.height
      ].max * 3.2

      distance = 300.0 * CM if distance < 300.0 * CM

      eye = Geom::Point3d.new(
        center.x,
        center.y,
        bounds.max.z + distance
      )

      target = Geom::Point3d.new(
        center.x,
        center.y,
        center.z
      )

      # اتجاه الأعلى في الشاشة يكون محور Y الموجب.
      up = Geom::Vector3d.new(0, 1, 0)

      # true = Perspective في بعض إصدارات API، لذلك ننشئ الكاميرا
      # ثم نجبرها صراحةً على Parallel Projection.
      camera = Sketchup::Camera.new(eye, target, up)
      camera.perspective = false if camera.respond_to?(:perspective=)

      model.active_view.camera = camera
      model.active_view.zoom_extents

      # تأكيد إضافي أن الكاميرا Orthographic / Parallel Projection.
      active_camera = model.active_view.camera
      active_camera.perspective = false if active_camera.respond_to?(:perspective=)
      model.active_view.camera = active_camera
    end

    def create_or_update_scene(model, scene_name)
      page = model.pages[scene_name] || model.pages.add(scene_name)

      # لا ننتقل إلى المشهد قبل تحديثه، لأن الانتقال قد يعيد
      # حالة رؤية قديمة ويخفي مقاسات المستوى الحالي.

      begin
        flags =
          Sketchup::Page::FLAG_USE_CAMERA |
          Sketchup::Page::FLAG_USE_HIDDEN |
          Sketchup::Page::FLAG_USE_HIDDEN_GEOMETRY |
          Sketchup::Page::FLAG_USE_LAYER_VISIBILITY |
          Sketchup::Page::FLAG_USE_SECTION_PLANES |
          Sketchup::Page::FLAG_USE_RENDERING_OPTIONS |
          Sketchup::Page::FLAG_USE_SHADOWINFO

        page.update(flags)
      rescue
        page.update
      end

      page
    end

    # --------------------------------------------------------
    # PDF Project Export
    # --------------------------------------------------------
    def mhd_shop_export_pages(model = Sketchup.active_model)
      return [] unless model
      model.pages.to_a.select do |page|
        name = page.name.to_s
        name.start_with?(SCENE_PREFIX) &&
          name != BASE_SCENE_NAME &&
          name !~ /MHD SHOP\s*00/i
      end.sort_by do |page|
        name = page.name.to_s
        number = name[/MHD SHOP\s+(\d+)/i, 1]
        [number ? number.to_i : 9999, name]
      end
    rescue
      []
    end

    def open_pdf_setup_page
      if mhd_shop_export_pages.empty?
        return
      end
      stop_selection_timer
      @dialog_mode = :pdf_setup
      @dialog.set_html(pdf_setup_html)
      @dialog.set_size(350, 745) if @dialog.respond_to?(:set_size)
    end

    def report_i18n
      {
        pdf_setup_title: MHDESIGN_SHOP_LANG.key('SHOP_PDF_SETUP_TITLE', 'إنشاء ملف المشروع PDF'),
        file_name: MHDESIGN_SHOP_LANG.key('SHOP_PDF_FILE_NAME', 'اسم الملف'),
        file_name_hint: MHDESIGN_SHOP_LANG.key('SHOP_PDF_FILE_NAME_HINT', 'اكتب اسم المشروع أو العميل'),
        default_project_name: MHDESIGN_SHOP_LANG.key('SHOP_PDF_DEFAULT_PROJECT_NAME', 'تشغيل مطبخ'),
        save_location: MHDESIGN_SHOP_LANG.key('SHOP_PDF_SAVE_LOCATION', 'مكان الحفظ'),
        no_save_location: MHDESIGN_SHOP_LANG.key('SHOP_PDF_NO_SAVE_LOCATION', 'لم يتم اختيار مكان الحفظ'),
        choose_save_location: MHDESIGN_SHOP_LANG.key('SHOP_PDF_CHOOSE_SAVE_LOCATION', 'تحديد مكان الحفظ'),
        save_location_note: MHDESIGN_SHOP_LANG.key('SHOP_PDF_SAVE_LOCATION_NOTE', 'سيتم إنشاء فولدر جديد باسم الملف داخل المكان الذي تختاره، ثم تصدير صور كل مشاهد MHD SHOP بداخله.'),
        create_file: MHDESIGN_SHOP_LANG.key('SHOP_PDF_CREATE_FILE', 'إنشاء الملف'),
        back: MHDESIGN_SHOP_LANG.key('SHOP_BACK', 'رجوع'),
        enter_file_name: MHDESIGN_SHOP_LANG.key('SHOP_PDF_ENTER_FILE_NAME', 'اكتب اسم الملف أولًا'),
        exporting_report: MHDESIGN_SHOP_LANG.key('SHOP_PDF_EXPORTING_REPORT', 'جاري تصدير المشاهد وإنشاء التقرير...'),
        choose_directory_title: MHDESIGN_SHOP_LANG.key('SHOP_PDF_CHOOSE_DIRECTORY_TITLE', 'اختر مكان حفظ ملف المشروع'),
        choose_location_first: MHDESIGN_SHOP_LANG.key('SHOP_PDF_CHOOSE_LOCATION_FIRST', 'اختر مكان الحفظ أولًا'),
        no_export_scenes: MHDESIGN_SHOP_LANG.key('SHOP_PDF_NO_EXPORT_SCENES', 'لا توجد مشاهد MHD SHOP قابلة للتصدير'),
        export_running: MHDESIGN_SHOP_LANG.key('SHOP_PDF_EXPORT_RUNNING', 'هناك عملية تصدير جارية بالفعل'),
        preparing_first_scene: MHDESIGN_SHOP_LANG.key('SHOP_PDF_PREPARING_FIRST_SCENE', 'جاري تجهيز المشهد الأول...'),
        preparing_scene: MHDESIGN_SHOP_LANG.key('SHOP_PDF_PREPARING_SCENE', 'جاري تجهيز المشهد: %s'),
        export_scene_failed: MHDESIGN_SHOP_LANG.key('SHOP_PDF_EXPORT_SCENE_FAILED', 'تعذر تصدير المشهد: %s'),
        saved_changes: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_SAVED_CHANGES', 'تم حفظ التعديلات'),
        saving: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_SAVING', 'جاري الحفظ...'),
        image_added: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_IMAGE_ADDED', 'تمت إضافة الصورة'),
        report_image_alt: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_IMAGE_ALT', 'صورة التقرير'),
        extra_page: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_EXTRA_PAGE', 'صفحة إضافية'),
        choose_image: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CHOOSE_IMAGE', 'اختيار صورة'),
        change_image: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CHANGE_IMAGE', 'تغيير الصورة'),
        add_page: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ADD_PAGE', 'إضافة صفحة'),
        delete_page: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DELETE_PAGE', 'حذف الصفحة'),
        zoom_in: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ZOOM_IN', 'تكبير +'),
        zoom_out: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ZOOM_OUT', 'تصغير −'),
        fit: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_FIT', 'ملاءمة'),
        crop_move: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CROP_MOVE', 'قص وتحريك'),
        reset: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_RESET', 'إعادة ضبط'),
        drag_crop_hint: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DRAG_CROP_HINT', 'اسحب الصورة داخل الإطار لتحديد الجزء الظاهر'),
        choose_image_hint: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CHOOSE_IMAGE_HINT', 'اضغط «اختيار صورة» لإضافة رندر أو صورة من جهازك'),
        print_pdf: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_PRINT_PDF', 'طباعة PDF'),
        save_changes: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_SAVE_CHANGES', 'حفظ التعديلات'),
        back_to_tool: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_BACK_TO_TOOL', 'رجوع للأداة'),
        font_type: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_FONT_TYPE', 'نوع الخط'),
        font_size: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_FONT_SIZE', 'حجم الخط'),
        bold: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_BOLD', 'عريض'),
        italic: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ITALIC', 'مائل'),
        underline: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_UNDERLINE', 'تحته خط'),
        text_color: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_TEXT_COLOR', 'لون الخط'),
        highlight: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_HIGHLIGHT', 'تظليل'),
        align_right: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ALIGN_RIGHT', 'يمين'),
        align_center: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ALIGN_CENTER', 'وسط'),
        align_left: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ALIGN_LEFT', 'يسار'),
        bullet_list: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_BULLET_LIST', '• قائمة'),
        clear_format: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CLEAR_FORMAT', 'مسح'),
        template: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_TEMPLATE', 'القالب:'),
        kitchen_project: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_KITCHEN_PROJECT', 'تشغيل مطبخ'),
        client_name: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CLIENT_NAME', 'اسم العميل'),
        designer_name: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DESIGNER_NAME', 'اسم المصمم'),
        date: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DATE', 'التاريخ'),
        kitchen_data: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_KITCHEN_DATA', 'بيانات تشغيل المطبخ'),
        accessories: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ACCESSORIES', 'الإكسسوارات'),
        accessory_dish_rack: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ACCESSORY_DISH_RACK', 'مطبقية هيدروليك 70 سم'),
        accessory_aventos: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ACCESSORY_AVENTOS', 'ميكانزم أفينتوس'),
        accessory_oil_trolley: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ACCESSORY_OIL_TROLLEY', 'ترولي زيت'),
        add_row: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ADD_ROW', 'إضافة صف تحت الصف المحدد'),
        decrease_height: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DECREASE_HEIGHT', 'تقليل الارتفاع'),
        increase_height: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_INCREASE_HEIGHT', 'زيادة الارتفاع'),
        delete_row: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DELETE_ROW', 'حذف الصف'),
        new_title: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_NEW_TITLE', 'عنوان جديد'),
        enter_details: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ENTER_DETAILS', 'اكتب التفاصيل هنا'),
        enter_data: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_ENTER_DATA', 'اكتب البيانات هنا'),
        choose_report_image_title: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_CHOOSE_IMAGE_TITLE', 'اختر صورة للتقرير'),
        project_folder_missing: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_PROJECT_FOLDER_MISSING', 'لم يتم إنشاء فولدر المشروع'),
        inner_material: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_INNER_MATERIAL', 'الخامة الداخلية'),
        decor_inner_material: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DECOR_INNER_MATERIAL', 'الخامة الداخلية للديكور'),
        outer_material: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_OUTER_MATERIAL', 'الخامة الخارجية'),
        base_units_size: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_BASE_UNITS_SIZE', 'مقاس الوحدات السفلية'),
        upper_units_level_1: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_UPPER_UNITS_LEVEL_1', 'الوحدات العلوية المستوى الأول'),
        upper_units_level_2: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_UPPER_UNITS_LEVEL_2', 'الوحدات العلوية المستوى الثاني'),
        lighting: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_LIGHTING', 'الإضاءة'),
        glass_doors: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_GLASS_DOORS', 'ضلف زجاج'),
        inner_material_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_INNER_MATERIAL_VALUE', 'كونتر سلايد 18 مم'),
        decor_inner_material_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_DECOR_INNER_MATERIAL_VALUE', 'NLAM 5090'),
        outer_material_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_OUTER_MATERIAL_VALUE', 'UV LAC 25170'),
        base_units_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_BASE_UNITS_VALUE', ("الوحدات السفلية عمق 58 سم + 1.8 سم الضلفة<br>" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_41DFE448907E') + "<br><strong class=\"red\">" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_A83FF08C4775') + "</strong>")),
        upper_units_level_1_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_UPPER_UNITS_LEVEL_1_VALUE', ("الوحدات العلوية عمق 30 سم + 1.8 سم الضلفة<br>" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_C310044C540F') + "<br><strong class=\"red\">" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_5885EAA71B72') + "</strong>")),
        upper_units_level_2_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_UPPER_UNITS_LEVEL_2_VALUE', ("الوحدات العلوية عمق 58 سم + ضلف زجاج فريم معدن أسود<br>" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_78E83F761D28'))),
        lighting_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_LIGHTING_VALUE', 'يوجد إضاءة حفر أسفل الوحدات العلوية وداخل وحدات الديكور'),
        glass_doors_value: MHDESIGN_SHOP_LANG.key('SHOP_REPORT_GLASS_DOORS_VALUE', ("الضلف الزجاج فريم معدن أسود<br>" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_E06FC1D946B3') + "<br>" + MHDESIGN::Language.for_tool('shop_drawing').html('TEXT_082436BE81F4')))
      }
    end

    def pdf_setup_html
      current_path = @pdf_parent_directory.to_s
      t = report_i18n
      <<~HTML
      <!DOCTYPE html>
      <html lang="#{MHDESIGN_SHOP_LANG.current}" dir="#{MHDESIGN_SHOP_LANG.direction}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
  :root {
    --mhd-app: #0B111A;
    --mhd-panel: #111F2C;
    --mhd-card: #172633;
    --mhd-input: #101923;
    --mhd-hover: #253443;
    --mhd-border: #34495B;
    --mhd-text: #F4F7FA;
    --mhd-muted: #A6B5C3;
    --mhd-accent: #08C9C3;
    --mhd-bright: #27E5DC;
    --mhd-ink: #04191C;
    --mhd-header: linear-gradient(110deg, #07111B 0%, #102332 60%, #075C62 100%);
    --mhd-primary: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
    --mhd-active: linear-gradient(135deg, #063C44 0%, #087D80 100%);
    --mhd-section: linear-gradient(145deg, #1D3040 0%, #111E2B 100%);
    --mhd-font: Cairo, Tajawal, "Segoe UI", Tahoma, sans-serif;
  }
          *{box-sizing:border-box}
          html,body{height:100%}
          body{margin:0;background:var(--mhd-app);color:var(--mhd-text);font-family:Arial,Tahoma,sans-serif;overflow:hidden}
          ::-webkit-scrollbar{width:8px}
          ::-webkit-scrollbar-track{background:var(--mhd-app)}
          ::-webkit-scrollbar-thumb{background:var(--mhd-border);border-radius:20px;border:2px solid var(--mhd-app)}
          ::-webkit-scrollbar-thumb:hover{background:var(--mhd-hover)}
          .app{height:100vh;display:flex;flex-direction:column}.hero{height:78px;padding:10px 14px;display:flex;align-items:center;gap:12px;background:var(--mhd-header);border-bottom:1px solid var(--mhd-border)}
          .logo{width:58px;height:58px;object-fit:contain;background:var(--mhd-panel);border:1px solid var(--mhd-border);border-radius:10px;padding:5px}.title{font-size:20px;font-weight:900;text-align:center;flex:1}
          .wrap{flex:1;overflow:auto;padding:14px}.group{background:var(--mhd-card);border:1px solid var(--mhd-border);border-radius:12px;margin-bottom:12px;overflow:hidden}.gt{padding:11px;background:var(--mhd-panel);color:var(--mhd-bright);font-size:15px;font-weight:900}.gb{padding:13px}
          label{display:block;font-size:13px;font-weight:900;margin-bottom:7px}input{width:100%;height:40px;border:1px solid var(--mhd-border);border-radius:8px;background:var(--mhd-input);color:#fff;padding:0 11px;font-size:14px;outline:none}input:focus{border-color:var(--mhd-bright)}
          .path{min-height:48px;padding:10px;border:1px dashed var(--mhd-border);border-radius:8px;background:var(--mhd-input);color:#b9cbd5;word-break:break-all;font-size:12px;line-height:1.6}.btn{width:100%;height:40px;margin-top:9px;border:0;border-radius:9px;font-size:14px;font-weight:900;cursor:pointer}.choose{background:var(--mhd-hover);color:#fff;border:1px solid var(--mhd-border)}.note{font-size:11px;color:var(--mhd-muted);line-height:1.7;margin-top:8px}.status{text-align:center;min-height:20px;font-size:12px;margin-top:8px}
          .footer{height:62px;padding:10px;border-top:1px solid var(--mhd-border);display:flex;gap:9px}.create{flex:2;background:var(--mhd-bright);color:var(--mhd-ink);border:0;border-radius:10px;font-size:14px;font-weight:900}.back{flex:1;background:var(--mhd-card);color:#fff;border:1px solid var(--mhd-border);border-radius:10px;font-size:14px;font-weight:900}

  body { font-family: var(--mhd-font); color-scheme: dark; }
  button, input, select { font-family: inherit; min-width: 0; }
  button:focus-visible, [tabindex]:focus-visible { outline: 2px solid var(--mhd-bright); outline-offset: 2px; }
  .app > .hero, body > .hero { flex: none; height: auto; min-height: 74px; padding-inline: 12px; }
  .hero .logo, .head .logo {
    flex: 0 0 auto; width: 48px; height: 48px; padding: 4px;
    border-color: var(--mhd-border); background: var(--mhd-input);
  }
  .hero .head-text, .head .title { min-width: 0; }
  .hero .title-main, .hero .title, .head .title {
    font-size: clamp(16px, 4.8vw, 22px); line-height: 1.2; white-space: normal; overflow-wrap: anywhere;
  }
  .hero .subtitle, .hero .desc { height: auto; color: var(--mhd-muted); overflow-wrap: anywhere; }
  .wrap { padding: 12px; }
  .app > .wrap { flex: 1 1 0; height: auto; min-height: 0; }
  .group, .wall-block { border-radius: 12px; }
  .group-title, .gt, .panel-title {
    background: var(--mhd-section); color: var(--mhd-bright); border-bottom: 1px solid var(--mhd-border);
  }
  .field-row, .switch-row, .ignore-different-row {
    grid-template-columns: minmax(82px, 36%) minmax(0, 1fr);
  }
  .field-row > *, .switch-row > *, .ignore-different-row > * { min-width: 0; }
  .field-row label, .switch-row label { overflow-wrap: anywhere; }
  .footer, .foot { flex: none; height: auto; min-height: 56px; background: var(--mhd-panel); align-items: stretch; }
  .footer button, .foot button { min-width: 0; height: auto; min-height: 38px; padding: 5px 8px; overflow-wrap: anywhere; }
  .ok, .primary, .generate, .create, .add, .swap-units-btn {
    background: var(--mhd-primary); color: var(--mhd-ink);
  }
  .ok:hover, .primary:hover, .generate:hover:not(:disabled), .create:hover, .add:hover, .swap-units-btn:hover:not(:disabled) {
    background: var(--mhd-bright);
  }
  .cancel, .back, .pdf, .secondary, .edit {
    color: var(--mhd-text); background: var(--mhd-input); border: 1px solid var(--mhd-border);
  }
  .cancel:hover, .back:hover, .pdf:hover:not(:disabled), .secondary:hover, .edit:hover {
    background: var(--mhd-hover);
  }
  .shape.active, .side-btn.active, .mat-card.active, .pattern-card.active,
  .row-direction-btn.active, .type.active, .side button.active {
    color: var(--mhd-text); background: var(--mhd-active); border-color: var(--mhd-accent);
    box-shadow: none;
  }
          .mhd-tool-header {
            --mhd-tool-header-gradient: linear-gradient(110deg, #07111B 0%, #102635 58%, #075D63 100%);
            --mhd-tool-header-accent: #12D1CB;
            --mhd-tool-header-muted: #A8BED0;
          }
          .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
            position: relative; flex: none; display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 2.6fr) minmax(0, 1fr);
            align-items: center; gap: 12px; height: auto; min-height: 92px; padding: 10px 18px;
            overflow: hidden; direction: ltr; background: var(--mhd-tool-header-gradient);
            border-bottom: 1px solid var(--mhd-border);
          }
          .mhd-tool-header .brand {
            position: relative; z-index: 1; display: flex; align-items: center; gap: 8px;
            color: var(--mhd-text); letter-spacing: .07em;
          }
          .mhd-tool-header .brand .logo { display: block; flex: none; width: 36px; height: 36px; object-fit: contain; }
          .mhd-tool-header .brand .logo[hidden] { display: none; }
          .mhd-tool-header .brandName { font-size: 13px; }
          .mhd-tool-header .head-text, .mhd-tool-header > .title {
            position: relative; z-index: 1; min-width: 0; text-align: center; direction: ltr;
          }
          html[dir="rtl"] .mhd-tool-header .head-text, html[dir="rtl"] .mhd-tool-header > .title { direction: rtl; }
          .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 24px; font-weight: 800; line-height: 1.25; overflow-wrap: anywhere; }
          .mhd-tool-header .subtitle, .mhd-tool-header .desc {
            display: block; margin-top: 4px; color: var(--mhd-tool-header-muted);
            font-size: 12px; line-height: 1.35; font-weight: 400; overflow-wrap: anywhere;
          }
          .mhd-tool-header .cabinetDrawing {
            position: absolute; right: 10px; bottom: -8px; width: 130px; height: 82px;
            color: var(--mhd-tool-header-accent); opacity: .32; pointer-events: none;
          }
          @media (max-width: 620px) {
            .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
              grid-template-columns: 48px minmax(0, 1fr) 48px; gap: 8px;
              min-height: 72px; padding: 8px 10px;
            }
            .mhd-tool-header .brand { flex-direction: column; gap: 2px; }
            .mhd-tool-header .brand .logo { width: 30px; height: 30px; }
            .mhd-tool-header .brandName { font-size: 8px; letter-spacing: .03em; }
            .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 20px; }
            .mhd-tool-header .subtitle, .mhd-tool-header .desc { font-size: 11px; }
            .mhd-tool-header .cabinetDrawing { right: 4px; width: 70px; height: 52px; opacity: .18; }
          }
        #{MHDESIGN_ResponsiveHeaderUI::CSS}
:root {
  --mhd-app: var(--ref-bg); --mhd-panel: var(--ref-panel); --mhd-card: var(--ref-panel);
  --mhd-input: var(--ref-input); --mhd-hover: var(--ref-section); --mhd-border: var(--ref-border);
  --mhd-text: var(--ref-text); --mhd-muted: var(--ref-muted); --mhd-accent: var(--ref-accent);
}
.group-title, .group[data-group] .group-title, .panel-title, .gt {
  background: var(--ref-section); color: var(--ref-text); border-color: var(--ref-border);
}
.ok, .add, .generate, .create, .swap-units-btn {
  background: var(--ref-action); color: var(--ref-bg);
}
        </style>
      </head>
      <body oncontextmenu="return false">
        <div class="app">
          <div class="hero mhd-tool-header mhd-ref-header">#{MHDESIGN_ResponsiveHeaderUI::BRAND}<div class="title">#{CGI.escapeHTML(t[:pdf_setup_title])}</div><!-- Dressing reference header artwork is included in BRAND. --></div>
          <div class="wrap">
            <div class="group"><div class="gt">#{CGI.escapeHTML(t[:file_name])}</div><div class="gb"><label>#{CGI.escapeHTML(t[:file_name_hint])}</label><input id="filename" value="#{CGI.escapeHTML(t[:default_project_name])}" maxlength="120"></div></div>
            <div class="group"><div class="gt">#{CGI.escapeHTML(t[:save_location])}</div><div class="gb"><div id="selectedPath" class="path">#{current_path.empty? ? CGI.escapeHTML(t[:no_save_location]) : CGI.escapeHTML(current_path)}</div><button class="btn choose" onclick="sketchup.choose_pdf_directory()">#{CGI.escapeHTML(t[:choose_save_location])}</button><div class="note">#{CGI.escapeHTML(t[:save_location_note])}</div></div></div>
            <div id="status" class="status"></div>
          </div>
          <div class="footer"><button class="create" onclick="createProject()">#{CGI.escapeHTML(t[:create_file])}</button><button class="back" onclick="sketchup.back_to_shop_main()">#{CGI.escapeHTML(t[:back])}</button></div>
        </div>
        <script>
          function setSelectedPath(path){document.getElementById('selectedPath').textContent=path||#{t[:no_save_location].to_json}}
          function setPdfStatus(text,ok){const e=document.getElementById('status');e.textContent=text||'';e.style.color=ok?'#4de37a':'#ff8c8c'}
          function createProject(){const name=document.getElementById('filename').value.trim();if(!name){setPdfStatus(#{t[:enter_file_name].to_json},false);return}setPdfStatus(#{t[:exporting_report].to_json},true);sketchup.create_pdf_project(JSON.stringify({filename:name}))}
        </script>
      </body></html>
      HTML
    end

    def choose_pdf_parent_directory
      directory = UI.select_directory(title: report_i18n[:choose_directory_title])
      return unless directory && !directory.to_s.empty?
      @pdf_parent_directory = directory.to_s
      pdf_execute("setSelectedPath(#{@pdf_parent_directory.to_json});setPdfStatus('',true);")
    rescue => error
      pdf_execute("setPdfStatus(#{error.message.to_json},false);")
    end

    def safe_project_filename(value)
      name = value.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '').strip
      name = 'MHDESIGN Project' if name.empty?
      name.gsub(/[\\\/:*?\"<>|]/, '_').gsub(/\s+/, ' ').strip
    end

    def create_pdf_project(filename)
      raise report_i18n[:choose_location_first] if @pdf_parent_directory.to_s.empty?
      pages = mhd_shop_export_pages
      raise report_i18n[:no_export_scenes] if pages.empty?
      raise report_i18n[:export_running] if @pdf_export_state

      project_name = safe_project_filename(filename)
      project_dir = File.join(@pdf_parent_directory, project_name)
      images_dir = File.join(project_dir, 'images')
      FileUtils.mkdir_p(images_dir)

      model = Sketchup.active_model
      previous_page = model.pages.selected_page
      page_options = model.options['PageOptions'] rescue nil
      previous_transition_time = page_options['TransitionTime'] rescue nil
      previous_show_transition = page_options['ShowTransition'] rescue nil

      begin
        page_options['TransitionTime'] = 0.0 if page_options
        page_options['ShowTransition'] = false if page_options
      rescue
      end

      @pdf_project_directory = project_dir
      @pdf_exported_scenes = []
      @pdf_export_state = {
        model: model,
        pages: pages,
        index: 0,
        project_name: project_name,
        project_dir: project_dir,
        images_dir: images_dir,
        previous_page: previous_page,
        page_options: page_options,
        previous_transition_time: previous_transition_time,
        previous_show_transition: previous_show_transition,
        active_page: nil,
        activated_at: nil,
        stable_count: 0,
        last_camera_signature: nil
      }

      pdf_execute("setPdfStatus(#{report_i18n[:preparing_first_scene].to_json}, true);")
      start_pdf_export_timer
    rescue => error
      finish_pdf_export(error)
      raise error
    end

    def start_pdf_export_timer
      stop_pdf_export_timer
      @pdf_export_timer = UI.start_timer(0.20, true) do
        process_pdf_export_tick
      rescue => error
        finish_pdf_export(error)
      end
    end

    def stop_pdf_export_timer
      return unless @pdf_export_timer
      UI.stop_timer(@pdf_export_timer)
      @pdf_export_timer = nil
    rescue
      @pdf_export_timer = nil
    end

    def camera_signature(camera)
      return nil unless camera
      values = [camera.eye, camera.target, camera.up].flat_map { |point| [point.x, point.y, point.z] }
      values.map { |value| value.to_f.round(5) }
    rescue
      nil
    end

    def process_pdf_export_tick
      state = @pdf_export_state
      return unless state

      model = state[:model]
      view = model.active_view
      pages = state[:pages]

      if state[:index] >= pages.length
        finish_pdf_export(nil)
        return
      end

      page = pages[state[:index]]

      if state[:active_page] != page
        model.pages.selected_page = page
        view.invalidate rescue nil
        view.refresh rescue nil
        state[:active_page] = page
        state[:activated_at] = Time.now
        state[:stable_count] = 0
        state[:last_camera_signature] = nil
        pdf_execute("setPdfStatus(#{format(report_i18n[:preparing_scene], page.name.to_s).to_json}, true);")
        return
      end

      # لا نلتقط الصورة إلا بعد توقف الكاميرا فعليًا لعدة دورات متتالية.
      signature = camera_signature(view.camera)
      if signature && signature == state[:last_camera_signature]
        state[:stable_count] += 1
      else
        state[:stable_count] = 0
        state[:last_camera_signature] = signature
      end

      elapsed = Time.now - state[:activated_at]
      selected_ok = model.pages.selected_page == page
      stable = state[:stable_count] >= 4 && elapsed >= 1.0
      timeout = elapsed >= 6.0
      return unless selected_ok && (stable || timeout)

      # تحديث أخير بعد استقرار المشهد والسكشن والـTags.
      view.invalidate rescue nil
      view.refresh rescue nil

      index = state[:index]
      number = format('%02d', index + 1)
      slug = page.name.to_s.gsub(/[\\\/:*?\"<>|]/, '_').gsub(/\s+/, '_')
      image_name = "#{number}_#{slug}.png"
      image_path = File.join(state[:images_dir], image_name)
      options = {
        filename: image_path,
        width: 2400,
        height: 1600,
        antialias: true,
        transparent: false
      }

      ok = view.write_image(options)
      raise format(report_i18n[:export_scene_failed], page.name.to_s) unless ok

      state[:index] += 1
      @pdf_exported_scenes << {
        title: page.name.to_s,
        filename: image_name,
        path: image_path
      }
      state[:active_page] = nil
      state[:activated_at] = nil
      state[:stable_count] = 0
      state[:last_camera_signature] = nil
    end

    def finish_pdf_export(error = nil)
      state = @pdf_export_state
      stop_pdf_export_timer
      return unless state

      model = state[:model]
      begin
        model.pages.selected_page = state[:previous_page] if state[:previous_page]
        model.active_view.refresh rescue nil
      rescue
      end

      begin
        options = state[:page_options]
        options['TransitionTime'] = state[:previous_transition_time] unless state[:previous_transition_time].nil? if options
        options['ShowTransition'] = state[:previous_show_transition] unless state[:previous_show_transition].nil? if options
      rescue
      end

      @pdf_export_state = nil

      if error
        pdf_execute("setPdfStatus(#{error.message.to_json}, false);")
        puts error.full_message
        return
      end

      report_path = File.join(state[:project_dir], 'report.html')
      html = build_report_document(state[:project_name], @pdf_exported_scenes, true)
      File.write(report_path, html, mode: 'w:UTF-8')

      @dialog_mode = :pdf_report
      @dialog.set_file(report_path)
      @dialog.set_size(1100, 820) if @dialog.respond_to?(:set_size)
    rescue => final_error
      puts final_error.full_message
      pdf_execute("setPdfStatus(#{final_error.message.to_json}, false);")
    end

    def report_table_rows
      t = report_i18n
      [
        [t[:inner_material], t[:inner_material_value]],
        [t[:decor_inner_material], t[:decor_inner_material_value]],
        [t[:outer_material], t[:outer_material_value]],
        [t[:base_units_size], t[:base_units_value]],
        [t[:upper_units_level_1], t[:upper_units_level_1_value]],
        [t[:upper_units_level_2], t[:upper_units_level_2_value]],
        [t[:lighting], t[:lighting_value]],
        [t[:glass_doors], t[:glass_doors_value]]
      ]
    end

    def build_report_document(project_name, exported, interactive)
      t = report_i18n
      rows = report_table_rows.map do |label, value|
        "<tr><th contenteditable='#{interactive}'>#{CGI.escapeHTML(label)}</th><td contenteditable='#{interactive}'>#{value}</td></tr>"
      end.join

      scenes = exported.map.with_index do |item, index|
        relative_url = 'images/' + CGI.escape(item[:filename].to_s).gsub('+', '%20')
        title = CGI.escapeHTML(item[:title])
        controls = interactive ? <<~HTML : ''
          <div class="image-tools no-print">
            <button type="button" onclick="resizeImage(this,10)">#{CGI.escapeHTML(t[:zoom_in])}</button>
            <button type="button" onclick="resizeImage(this,-10)">#{CGI.escapeHTML(t[:zoom_out])}</button>
            <button type="button" onclick="fitImage(this)">#{CGI.escapeHTML(t[:fit])}</button>
            <button type="button" class="crop-toggle" onclick="toggleCrop(this)">#{CGI.escapeHTML(t[:crop_move])}</button>
            <button type="button" onclick="resetImage(this)">#{CGI.escapeHTML(t[:reset])}</button>
            <input type="range" min="35" max="250" value="94" oninput="setImageWidth(this,this.value)">
            <span class="image-size">94%</span>
            <span class="tool-separator"></span>
            <button type="button" class="image-action" onclick="choosePageImage(this,'replace')">#{CGI.escapeHTML(t[:change_image])}</button>
            <button type="button" class="image-action add-page" onclick="addBlankPage(this)">#{CGI.escapeHTML(t[:add_page])}</button>
          </div>
        HTML

        <<~HTML
          <section class="a4-page scene-page" id="report-page-#{index + 2}" data-page="#{index + 2}">
            <div class="page-accent"></div>
            <div class="page-head">
              <div class="scene-kicker">#{CGI.escapeHTML(t[:kitchen_project])}</div>
              <h2 contenteditable="#{interactive}">#{title}</h2>
              <div class="page-number">#{index + 2}</div>
            </div>
            #{controls}
            <div class="image-stage" data-x="0" data-y="0" data-scale="94">
              <img class="scene-image" src="#{relative_url}" alt="#{title}" style="width:94%">
              <div class="crop-hint no-print">#{CGI.escapeHTML(t[:drag_crop_hint])}</div>
            </div>
            <div class="page-footer"><span>MHDESIGN</span><span>Shop Drawing</span></div>
          </section>
        HTML
      end.join

      toolbar = interactive ? <<~HTML : ''
        <div class="editor-toolbar no-print" id="editorToolbar">
          <div class="mhd-tool-header mhd-ref-header">
            #{MHDESIGN_ResponsiveHeaderUI::BRAND}
            <div class="head-text"><div class="title-main">#{CGI.escapeHTML(project_name)}</div><div class="subtitle">#{CGI.escapeHTML(t[:kitchen_project])}</div></div>
            <!-- Dressing reference header artwork is included in BRAND. -->
          </div>
          <div class="toolbar-row">
            <div class="toolbar-actions">
              <button class="primary-action" onclick="window.print()">#{CGI.escapeHTML(t[:print_pdf])}</button>
              <button onclick="saveReport()">#{CGI.escapeHTML(t[:save_changes])}</button>
              <button onclick="sketchup.back_to_shop_main()">#{CGI.escapeHTML(t[:back_to_tool])}</button>
              <span id="reportStatus"></span>
            </div>

            <div class="format-bar">
              <select onchange="formatText('fontName',this.value)" title="#{CGI.escapeHTML(t[:font_type])}">
                <option value="Arial">Arial</option>
                <option value="Tahoma">Tahoma</option>
                <option value="Times New Roman">Times New Roman</option>
                <option value="Courier New">Courier New</option>
              </select>
              <select onchange="applyFontSize(this.value)" title="#{CGI.escapeHTML(t[:font_size])}">
                <option value="12">12</option><option value="14">14</option><option value="16" selected>16</option>
                <option value="18">18</option><option value="20">20</option><option value="24">24</option>
                <option value="28">28</option><option value="32">32</option><option value="40">40</option>
              </select>
              <button onclick="formatText('bold')" title="#{CGI.escapeHTML(t[:bold])}"><b>B</b></button>
              <button onclick="formatText('italic')" title="#{CGI.escapeHTML(t[:italic])}"><i>I</i></button>
              <button onclick="formatText('underline')" title="#{CGI.escapeHTML(t[:underline])}"><u>U</u></button>
              <label class="color-control" title="#{CGI.escapeHTML(t[:text_color])}">#{CGI.escapeHTML(t[:text_color])}<input type="color" value="#111111" oninput="formatText('foreColor',this.value)"></label>
              <label class="color-control" title="#{CGI.escapeHTML(t[:highlight])}">#{CGI.escapeHTML(t[:highlight])}<input type="color" value="#ffffff" oninput="formatText('hiliteColor',this.value)"></label>
              <button onclick="formatText('justifyRight')">#{CGI.escapeHTML(t[:align_right])}</button>
              <button onclick="formatText('justifyCenter')">#{CGI.escapeHTML(t[:align_center])}</button>
              <button onclick="formatText('justifyLeft')">#{CGI.escapeHTML(t[:align_left])}</button>
              <button onclick="formatText('insertUnorderedList')">#{CGI.escapeHTML(t[:bullet_list])}</button>
              <button onclick="formatText('removeFormat')">#{CGI.escapeHTML(t[:clear_format])}</button>
            </div>

            <div class="template-bar">
              <span class="template-label">#{CGI.escapeHTML(t[:template])}</span>
              <button class="template-button active" data-template="1" onclick="setTemplate(1,this)">1</button>
              <button class="template-button" data-template="2" onclick="setTemplate(2,this)">2</button>
              <button class="template-button" data-template="3" onclick="setTemplate(3,this)">3</button>
              <button class="template-button" data-template="4" onclick="setTemplate(4,this)">4</button>
            </div>
          </div>
        </div>
      HTML

      script = interactive ? <<~JS : ''
        <script>
          const REPORT_I18N = #{report_i18n.to_json};
          function setReportStatus(text, ok){
            const element = document.getElementById('reportStatus');
            if(!element) return;
            element.textContent = text || '';
            element.style.color = ok ? '#4de37a' : '#ff8c8c';
          }

          function saveReport(){
            setReportStatus(REPORT_I18N.saving, true);
            sketchup.save_report_html(JSON.stringify({html:document.documentElement.outerHTML}));
          }

          function formatText(command, value){
            document.execCommand(command, false, value || null);
          }

          function applyFontSize(size){
            document.execCommand('fontSize', false, '7');
            document.querySelectorAll('font[size="7"]').forEach(function(node){
              node.removeAttribute('size');
              node.style.fontSize = size + 'px';
            });
          }

          function setTemplate(number, button){
            number = Math.max(1, Math.min(4, parseInt(number || 1, 10)));
            document.body.classList.remove('template-1','template-2','template-3','template-4');
            document.body.classList.add('template-' + number);
            document.body.dataset.template = String(number);
            document.querySelectorAll('.template-button').forEach(function(item){
              item.classList.toggle('active', item.dataset.template === String(number));
            });
          }

          let pendingImageTarget = null;

          function ensurePageId(page){
            if(!page) return '';
            if(!page.id){
              page.id = 'report-page-user-' + Date.now() + '-' + Math.floor(Math.random()*100000);
            }
            return page.id;
          }

          function choosePageImage(control, mode){
            const page = control.closest('.scene-page');
            if(!page) return;
            const targetId = ensurePageId(page);
            pendingImageTarget = targetId;
            sketchup.choose_report_image(JSON.stringify({target_id:targetId, mode:mode || 'replace'}));
          }

          function reportImageChosen(targetId, relativeUrl, title, mode){
            const page = document.getElementById(targetId);
            if(!page) return;
            const stage = page.querySelector('.image-stage');
            if(!stage) return;
            let image = stage.querySelector('.scene-image');
            if(!image){
              image = document.createElement('img');
              image.className = 'scene-image';
              stage.insertBefore(image, stage.firstChild);
            }
            image.src = relativeUrl;
            image.alt = title || REPORT_I18N.report_image_alt;
            stage.classList.remove('empty-stage');
            stage.dataset.x='0'; stage.dataset.y='0'; stage.dataset.scale='94';
            const heading = page.querySelector('.page-head h2');
            if(heading && page.dataset.userPage === 'true' && title) heading.textContent = title;
            applyImageTransform(stage);
            const range = page.querySelector('.image-tools input[type="range"]');
            if(range){ range.value='94'; updateImageUi(range,94); }
            setReportStatus(REPORT_I18N.image_added, true);
          }

          function blankPageMarkup(pageId, pageNumber){
            return `
              <section class="a4-page scene-page user-page" id="${pageId}" data-page="${pageNumber}" data-user-page="true">
                <div class="page-accent"></div>
                <div class="page-head">
                  <div class="scene-kicker">#{CGI.escapeHTML(t[:kitchen_project])}</div>
                  <h2 contenteditable="true">${REPORT_I18N.extra_page}</h2>
                  <div class="page-number">${pageNumber}</div>
                </div>
                <div class="image-tools no-print">
                  <button type="button" onclick="resizeImage(this,10)">#{CGI.escapeHTML(t[:zoom_in])}</button>
                  <button type="button" onclick="resizeImage(this,-10)">#{CGI.escapeHTML(t[:zoom_out])}</button>
                  <button type="button" onclick="fitImage(this)">#{CGI.escapeHTML(t[:fit])}</button>
                  <button type="button" class="crop-toggle" onclick="toggleCrop(this)">#{CGI.escapeHTML(t[:crop_move])}</button>
                  <button type="button" onclick="resetImage(this)">#{CGI.escapeHTML(t[:reset])}</button>
                  <input type="range" min="35" max="250" value="94" oninput="setImageWidth(this,this.value)">
                  <span class="image-size">94%</span>
                  <span class="tool-separator"></span>
                  <button type="button" class="image-action" onclick="choosePageImage(this,'replace')">${REPORT_I18N.choose_image}</button>
                  <button type="button" class="image-action add-page" onclick="addBlankPage(this)">#{CGI.escapeHTML(t[:add_page])}</button>
                  <button type="button" class="image-action delete-page" onclick="deletePage(this)">${REPORT_I18N.delete_page}</button>
                </div>
                <div class="image-stage empty-stage" data-x="0" data-y="0" data-scale="94">
                  <div class="empty-message no-print">${REPORT_I18N.choose_image_hint}</div>
                  <div class="crop-hint no-print">#{CGI.escapeHTML(t[:drag_crop_hint])}</div>
                </div>
                <div class="page-footer"><span>MHDESIGN</span><span>Shop Drawing</span></div>
              </section>`;
          }

          function addBlankPage(control){
            const current = control.closest('.scene-page');
            if(!current) return;
            const id = 'report-page-user-' + Date.now() + '-' + Math.floor(Math.random()*100000);
            current.insertAdjacentHTML('afterend', blankPageMarkup(id, 0));
            renumberPages();
            const created = document.getElementById(id);
            if(created) created.scrollIntoView({behavior:'smooth', block:'start'});
          }

          function deletePage(control){
            const page = control.closest('.scene-page');
            if(!page || page.dataset.userPage !== 'true') return;
            page.remove();
            renumberPages();
          }

          function renumberPages(){
            document.querySelectorAll('.a4-page').forEach(function(page,index){
              page.dataset.page = String(index+1);
              const badge = page.querySelector('.page-number');
              if(badge) badge.textContent = String(index+1);
            });
          }

          function stageFromControl(control){
            const page = control.closest('.scene-page');
            return page ? page.querySelector('.image-stage') : null;
          }

          function imageFromControl(control){
            const stage = stageFromControl(control);
            return stage ? stage.querySelector('.scene-image') : null;
          }

          function applyImageTransform(stage){
            if(!stage) return;
            const image = stage.querySelector('.scene-image');
            if(!image) return;
            const x = parseFloat(stage.dataset.x || '0');
            const y = parseFloat(stage.dataset.y || '0');
            const scale = Math.max(35, Math.min(250, parseInt(stage.dataset.scale || '94',10)));
            image.style.width = scale + '%';
            image.style.transform = 'translate(-50%,-50%) translate(' + x + 'px,' + y + 'px)';
          }

          function updateImageUi(control, value){
            const tools = control.closest('.image-tools');
            if(!tools) return;
            const range = tools.querySelector('input[type="range"]');
            const label = tools.querySelector('.image-size');
            if(range) range.value = value;
            if(label) label.textContent = value + '%';
          }

          function setImageWidth(control, value){
            const stage = stageFromControl(control);
            if(!stage) return;
            value = Math.max(35, Math.min(250, parseInt(value || 94, 10)));
            stage.dataset.scale = String(value);
            applyImageTransform(stage);
            updateImageUi(control, value);
          }

          function resizeImage(control, delta){
            const stage = stageFromControl(control);
            if(!stage) return;
            const current = parseInt(stage.dataset.scale || '94', 10);
            setImageWidth(control, current + delta);
          }

          function fitImage(control){
            const stage = stageFromControl(control);
            if(!stage) return;
            stage.dataset.x='0';stage.dataset.y='0';
            setImageWidth(control,94);
          }

          function resetImage(control){
            const stage = stageFromControl(control);
            if(!stage) return;
            stage.dataset.x='0';stage.dataset.y='0';stage.dataset.scale='94';
            stage.classList.remove('crop-active','dragging');
            const toggle=control.closest('.image-tools').querySelector('.crop-toggle');
            if(toggle) toggle.classList.remove('active');
            applyImageTransform(stage);
            updateImageUi(control,94);
          }

          function toggleCrop(control){
            const stage=stageFromControl(control); if(!stage) return;
            const active=stage.classList.toggle('crop-active');
            control.classList.toggle('active',active);
          }

          let dragState=null;
          document.addEventListener('pointerdown',function(event){
            const stage=event.target.closest('.image-stage.crop-active');
            if(!stage) return;
            event.preventDefault();
            dragState={stage:stage,startX:event.clientX,startY:event.clientY,baseX:parseFloat(stage.dataset.x||'0'),baseY:parseFloat(stage.dataset.y||'0')};
            stage.classList.add('dragging');
            try{stage.setPointerCapture(event.pointerId)}catch(e){}
          });
          document.addEventListener('pointermove',function(event){
            if(!dragState) return;
            dragState.stage.dataset.x=String(dragState.baseX+(event.clientX-dragState.startX));
            dragState.stage.dataset.y=String(dragState.baseY+(event.clientY-dragState.startY));
            applyImageTransform(dragState.stage);
          });
          function endImageDrag(event){
            if(!dragState) return;
            dragState.stage.classList.remove('dragging');
            dragState=null;
          }
          document.addEventListener('pointerup',endImageDrag);
          document.addEventListener('pointercancel',endImageDrag);

          let activeReportRow = null;

          function selectReportRow(row){
            if(!row || !row.closest('.report-table')) return;
            document.querySelectorAll('.report-table tr.row-selected').forEach(function(item){item.classList.remove('row-selected');});
            activeReportRow = row;
            row.classList.add('row-selected');
            const wrap = row.closest('.table-editor-wrap');
            if(wrap) wrap.classList.add('active');
            const height = Math.max(28, Math.round(row.getBoundingClientRect().height || 46));
            const range = document.getElementById('rowHeightRange');
            const label = document.getElementById('rowHeightLabel');
            if(range) range.value = Math.min(160,height);
            if(label) label.textContent = height + ' px';
          }

          document.addEventListener('focusin', function(event){
            const row = event.target.closest('.report-table tr');
            if(row) selectReportRow(row);
          });
          document.addEventListener('click', function(event){
            const row = event.target.closest('.report-table tr');
            if(row) selectReportRow(row);
          });

          function setActiveRowHeight(value){
            if(!activeReportRow) return;
            value = Math.max(28, Math.min(160, parseInt(value || 46,10)));
            activeReportRow.style.height = value + 'px';
            activeReportRow.querySelectorAll('th,td').forEach(function(cell){cell.style.height = value + 'px';});
            const range = document.getElementById('rowHeightRange');
            const label = document.getElementById('rowHeightLabel');
            if(range) range.value = value;
            if(label) label.textContent = value + ' px';
          }

          function changeRowHeight(delta){
            if(!activeReportRow) return;
            const current = Math.max(28, Math.round(activeReportRow.getBoundingClientRect().height || 46));
            setActiveRowHeight(current + delta);
          }

          function addRowBelow(){
            const table = document.getElementById('mainReportTable');
            if(!table) return;
            let reference = activeReportRow;
            if(!reference || !table.contains(reference)) reference = table.rows[table.rows.length - 1];
            const row = document.createElement('tr');
            const oneCell = reference && reference.cells.length === 1 && parseInt(reference.cells[0].getAttribute('colspan') || '1',10) >= 2;
            if(oneCell){
              const cell = document.createElement('td');
              cell.colSpan = 2;
              cell.contentEditable = 'true';
              cell.textContent = REPORT_I18N.enter_data;
              row.appendChild(cell);
            }else{
              const labelCell = document.createElement('th');
              labelCell.contentEditable = 'true';
              labelCell.textContent = REPORT_I18N.new_title;
              const valueCell = document.createElement('td');
              valueCell.contentEditable = 'true';
              valueCell.textContent = REPORT_I18N.enter_details;
              row.appendChild(labelCell);
              row.appendChild(valueCell);
            }
            reference.insertAdjacentElement('afterend', row);
            selectReportRow(row);
            setActiveRowHeight(46);
            const first = row.querySelector('[contenteditable="true"]');
            if(first){first.focus(); document.execCommand('selectAll',false,null);}
          }

          function deleteActiveRow(){
            if(!activeReportRow) return;
            const table = activeReportRow.closest('.report-table');
            if(!table || table.rows.length <= 1) return;
            const next = activeReportRow.nextElementSibling || activeReportRow.previousElementSibling;
            activeReportRow.remove();
            activeReportRow = null;
            if(next) selectReportRow(next);
          }

          document.addEventListener('DOMContentLoaded', function(){
            renumberPages();
            const stored = parseInt(document.body.dataset.template || '1', 10);
            setTemplate(stored);
            document.querySelectorAll('.image-stage').forEach(function(stage){applyImageTransform(stage);});
          });
        </script>
      JS

      <<~HTML
      <!DOCTYPE html>
      <html lang="#{MHDESIGN_SHOP_LANG.current}" dir="#{MHDESIGN_SHOP_LANG.direction}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>#{CGI.escapeHTML(project_name)}</title>
        <style>
  :root {
    --mhd-app: #0B111A;
    --mhd-panel: #111F2C;
    --mhd-card: #172633;
    --mhd-input: #101923;
    --mhd-hover: #253443;
    --mhd-border: #34495B;
    --mhd-text: #F4F7FA;
    --mhd-muted: #A6B5C3;
    --mhd-accent: #08C9C3;
    --mhd-bright: #27E5DC;
    --mhd-ink: #04191C;
    --mhd-header: linear-gradient(110deg, #07111B 0%, #102332 60%, #075C62 100%);
    --mhd-primary: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
    --mhd-active: linear-gradient(135deg, #063C44 0%, #087D80 100%);
    --mhd-section: linear-gradient(145deg, #1D3040 0%, #111E2B 100%);
    --mhd-font: Cairo, Tajawal, "Segoe UI", Tahoma, sans-serif;
  }
          *{box-sizing:border-box}
          html,body{min-height:100%;margin:0;overflow:auto}
          body{background:#d9dde1;color:#101820;font-family:Arial,Tahoma,sans-serif;--accent:#17384d;--accent2:#dce9f6;--accent3:#88939a;--paper:#ffffff;--line:#24333d;--soft:#f6f9fb;--title:#ffffff}

          .editor-toolbar{position:sticky;top:0;z-index:100;background:#07131d;border-bottom:1px solid #1c3342;box-shadow:0 4px 14px rgba(0,0,0,.24)}
          .toolbar-row{display:grid;grid-template-columns:minmax(280px,auto) minmax(460px,1fr) minmax(210px,auto);align-items:center;gap:12px;padding:8px 12px;direction:rtl}
          .toolbar-actions,.template-bar,.format-bar{display:flex;align-items:center;gap:7px;flex-wrap:wrap}
          .toolbar-actions{justify-content:flex-start}
          .format-bar{justify-content:center}
          .template-bar{justify-content:flex-end;direction:rtl}
          .editor-toolbar button,.editor-toolbar select{height:34px;border:1px solid #2e4658;border-radius:7px;background:#fff;color:#07131d;padding:0 11px;font-weight:800;cursor:pointer}
          .editor-toolbar .primary-action{background:#4de37a;border-color:#4de37a}
          .editor-toolbar button:hover,.editor-toolbar select:hover{filter:brightness(.96)}
          .editor-toolbar #reportStatus{font-size:12px;font-weight:800}
          .template-label{font-size:12px;color:#d8e8ef;font-weight:900}
          .template-button.active{background:#4de37a!important;border-color:#4de37a!important;color:#061923!important}
          .format-bar{background:#0b1b27}
          .format-bar button,.format-bar select{height:31px;font-size:12px}
          .color-control{height:31px;display:flex;align-items:center;gap:5px;background:#fff;color:#07131d;border-radius:7px;padding:0 8px;font-size:12px;font-weight:800}
          .color-control input{width:25px;height:22px;border:0;padding:0;background:transparent}

          .document{padding:14px 0 40px}
          .a4-page{width:210mm;height:297mm;min-height:297mm;margin:0 auto 14px;background:var(--paper);box-shadow:0 4px 18px rgba(0,0,0,.22);position:relative;overflow:hidden;page-break-after:always}
          .cover-page{padding:10mm 11mm 12mm}
          .brand-head{display:flex;align-items:center;justify-content:center;border-bottom:3px solid var(--accent);padding-bottom:6mm;margin-bottom:6mm}
          .brand-project{font-size:24px;font-weight:900;text-align:center;width:100%;color:var(--accent)}

          .report-table{width:100%;border-collapse:collapse;table-layout:fixed;font-size:13px}
          .report-table th,.report-table td{border:1.5px solid var(--line);padding:6px 7px;text-align:center;vertical-align:middle;line-height:1.45}
          .report-table th{width:27%;background:var(--accent2);font-weight:900;color:var(--accent)}
          .report-table td{background:var(--paper)}
          .table-editor-wrap{position:relative}
          .table-row-controls{display:none;align-items:center;justify-content:center;gap:7px;margin:7px auto 0;padding:7px;border:1px solid #c6d1d8;border-radius:9px;background:rgba(255,255,255,.94);box-shadow:0 3px 10px rgba(0,0,0,.10);width:max-content;max-width:100%;direction:rtl}
          .table-editor-wrap.active .table-row-controls{display:flex}
          .table-row-controls button{height:30px;border:1px solid #b7c5ce;border-radius:7px;background:#f3f7f9;color:#17384d;font-weight:900;cursor:pointer;padding:0 10px}
          .table-row-controls .add-row{width:34px;padding:0;background:#4de37a;border-color:#4de37a;color:#061923;font-size:20px;line-height:1}
          .table-row-controls .delete-row{background:#fdecec;border-color:#df9a9a;color:#7b1d1d}
          .table-row-controls input[type='range']{width:150px;accent-color:#17384d}
          .table-row-controls .row-height-label{font-size:11px;font-weight:900;color:#526773;min-width:48px;text-align:center}
          .report-table tr.row-selected>th,.report-table tr.row-selected>td{outline:2px solid #2196f3;outline-offset:-2px}
          .main-title{background:var(--accent3)!important;color:var(--title)!important;font-size:20px!important;padding:8px!important}
          .section-title{background:var(--accent3)!important;color:var(--title)!important;font-size:17px!important}
          .red{color:#d60000}
          .accessory{font-size:16px;font-weight:900}
          .project-meta{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:3mm;margin:0 0 5mm;direction:rtl}
          .meta-card{display:flex;flex-direction:column;justify-content:center;align-items:stretch;border:1px solid #b8c5ce;border-radius:7px;padding:2.5mm 3mm;background:var(--soft);min-height:15mm}
          .meta-label{font-size:9px;color:#5e6f79;text-align:right;margin-bottom:1mm}.meta-value{font-size:12px;font-weight:800;min-height:16px;text-align:right;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}

          .scene-page{padding:9mm 10mm 10mm;display:flex;flex-direction:column}
          .page-accent{height:4mm;background:var(--accent);margin:-9mm -10mm 6mm}
          .page-head{display:grid;grid-template-columns:1fr auto;align-items:center;border-bottom:2px solid var(--accent);padding-bottom:4mm;margin-bottom:4mm;min-height:20mm;position:relative}
          .scene-kicker{grid-column:1 / -1;text-align:center;font-size:9px;letter-spacing:1.4px;color:var(--accent3);font-weight:900}
          .page-head h2{text-align:center;font-size:20px;margin:1mm 0 0;color:var(--accent)}
          .page-number{grid-row:1 / 3;grid-column:2;width:30px;height:30px;border-radius:50%;background:var(--accent);color:var(--title);display:flex;align-items:center;justify-content:center;font-weight:900}
          .image-tools{display:flex;align-items:center;justify-content:center;gap:7px;margin-bottom:4mm;flex-wrap:wrap}
          .image-tools button{height:31px;border:1px solid #c1ccd3;border-radius:7px;background:#f4f7f9;font-weight:800;cursor:pointer}
          .image-tools button.active{background:#17384d;color:#fff;border-color:#17384d}
          .image-tools input[type="range"]{width:180px}
          .tool-separator{width:1px;height:24px;background:#c6d0d6;margin:0 2px}
          .image-action{background:#e8f3fb!important;border-color:#86b7d8!important;color:#14384d!important}
          .add-page{background:#e8f8ee!important;border-color:#8fcba4!important;color:#14572c!important}
          .delete-page{background:#fdecec!important;border-color:#df9a9a!important;color:#7b1d1d!important}
          .empty-stage{display:flex;align-items:center;justify-content:center}
          .empty-message{max-width:70%;text-align:center;color:#60717b;font-size:16px;font-weight:800;line-height:1.8;border:2px dashed #b9c7cf;border-radius:12px;padding:18px 24px;background:rgba(255,255,255,.68)}
          .image-size{font-size:12px;font-weight:900;min-width:42px}
          .image-stage{flex:1;min-height:0;position:relative;overflow:hidden;border:1px solid #d0d7dc;background:var(--soft);cursor:default;touch-action:none;user-select:none}
          .image-stage.crop-active{cursor:grab}
          .image-stage.crop-active.dragging{cursor:grabbing}
          .scene-image{position:absolute;left:50%;top:50%;display:block;max-width:none;max-height:none;width:94%;height:auto;transform:translate(-50%,-50%) translate(0px,0px);transform-origin:center center;transition:none;pointer-events:none}
          .crop-hint{position:absolute;left:8px;bottom:7px;background:rgba(7,19,29,.78);color:#fff;padding:4px 7px;border-radius:5px;font-size:10px;opacity:0;transition:opacity .15s;pointer-events:none}
          .image-stage.crop-active .crop-hint{opacity:1}
          .page-footer{height:9mm;margin-top:4mm;border-top:1px solid #c8d2d9;color:#60717b;font-size:9px;display:flex;align-items:flex-end;justify-content:space-between}

          [contenteditable='true']{cursor:text}
          [contenteditable='true']:focus{outline:2px solid #2196f3;outline-offset:1px;background:#f2fbff}

          /* قالب 1 — رسمي أزرق رمادي */
          body.template-1{--accent:#17384d;--accent2:#dce9f6;--accent3:#88939a;--paper:#fff;--line:#24333d;--soft:#f6f9fb;--title:#fff}

          /* قالب 2 — هوية MHD الداكنة والخضراء */
          body.template-2{--accent:#07131d;--accent2:#dff8e6;--accent3:#174b31;--paper:#fff;--line:#173c2b;--soft:#f1faf4;--title:#fff}
          body.template-2 .brand-head{border-bottom-width:5px}
          body.template-2 .main-title,body.template-2 .section-title{background:linear-gradient(90deg,#07131d,#174b31)!important}

          /* قالب 3 — أبيض مينيمال */
          body.template-3{--accent:#111;--accent2:#f4f4f4;--accent3:#111;--paper:#fff;--line:#aaa;--soft:#fff;--title:#fff}
          body.template-3 .a4-page{box-shadow:0 2px 10px rgba(0,0,0,.14)}
          body.template-3 .brand-head{border-bottom:1px solid #111}
          body.template-3 .page-accent{height:1.5mm;background:#111}
          body.template-3 .report-table th,body.template-3 .report-table td{border-width:1px}

          /* قالب 4 — هندسي نحاسي */
          body.template-4{--accent:#5a3a25;--accent2:#f2e7dc;--accent3:#a96f3d;--paper:#fffdf9;--line:#6b4d39;--soft:#fbf4ec;--title:#fff}
          body.template-4 .a4-page{border-right:5mm solid #a96f3d}
          body.template-4 .brand-head{border-bottom:3px solid #a96f3d}
          body.template-4 .main-title,body.template-4 .section-title{background:linear-gradient(90deg,#5a3a25,#a96f3d)!important}
          body.template-4 .page-accent{background:linear-gradient(90deg,#5a3a25,#a96f3d)}

          @media screen and (max-width:1250px){
            .toolbar-row{grid-template-columns:1fr;direction:rtl}
            .toolbar-actions,.format-bar,.template-bar{justify-content:center}
          }

          @media screen and (max-width:1000px){
            .a4-page{transform-origin:top center;zoom:.74}
            .document{padding-top:10px}
          }

          @media print{
            @page{size:A4 portrait;margin:0}

            html,body{
              width:210mm!important;
              min-width:210mm!important;
              height:auto!important;
              min-height:0!important;
              margin:0!important;
              padding:0!important;
              background:#fff!important;
              overflow:visible!important;
              zoom:1!important;
              transform:none!important;
              -webkit-print-color-adjust:exact!important;
              print-color-adjust:exact!important;
            }

            .no-print{display:none!important}
            .report-table tr.row-selected>th,.report-table tr.row-selected>td{outline:none!important}
            .document{
              width:210mm!important;
              margin:0!important;
              padding:0!important;
              zoom:1!important;
              transform:none!important;
            }

            .a4-page{
              width:210mm!important;
              min-width:210mm!important;
              max-width:210mm!important;
              height:297mm!important;
              min-height:297mm!important;
              max-height:297mm!important;
              margin:0!important;
              padding:0;
              box-shadow:none!important;
              overflow:hidden!important;
              zoom:1!important;
              transform:none!important;
              transform-origin:initial!important;
              page-break-before:auto;
              page-break-after:always;
              break-after:page;
              page-break-inside:avoid;
              break-inside:avoid-page;
            }

            .cover-page{padding:10mm 11mm 12mm!important}
            .scene-page{padding:9mm 10mm 10mm!important;page-break-inside:avoid!important;break-inside:avoid-page!important}
            .image-stage{overflow:hidden!important}
            .scene-image{max-width:none!important;max-height:none!important}
            .a4-page:last-child{page-break-after:auto!important;break-after:auto!important}
          }

  @media screen {
    .editor-toolbar {
      font-family: var(--mhd-font); color: var(--mhd-text);
      background: var(--mhd-header); border-color: var(--mhd-border);
    }
    .editor-toolbar .toolbar-row {
      grid-template-columns: repeat(auto-fit, minmax(min(100%, 280px), 1fr));
      gap: 8px;
    }
    .editor-toolbar .toolbar-actions, .editor-toolbar .template-bar, .editor-toolbar .format-bar { justify-content: flex-start; }
    .editor-toolbar .format-bar { padding: 4px; border-radius: 8px; background: var(--mhd-panel); }
    .editor-toolbar button, .editor-toolbar select, .editor-toolbar .color-control {
      background: var(--mhd-input); color: var(--mhd-text); border: 1px solid var(--mhd-border);
    }
    .editor-toolbar button:hover, .editor-toolbar select:hover { border-color: var(--mhd-bright); }
    .editor-toolbar .primary-action, .editor-toolbar .template-button.active {
      background: var(--mhd-primary) !important; color: var(--mhd-ink) !important; border-color: var(--mhd-accent) !important;
    }
    .table-editor-wrap .table-row-controls { color: var(--mhd-text); background: var(--mhd-panel); border-color: var(--mhd-border); }
    .table-row-controls button { color: var(--mhd-text); background: var(--mhd-input); border-color: var(--mhd-border); }
    .table-row-controls .add-row { background: var(--mhd-primary); color: var(--mhd-ink); border-color: var(--mhd-accent); }
    .table-row-controls .row-height-label { color: var(--mhd-muted); }
    .table-row-controls input[type='range'] { accent-color: var(--mhd-accent); }
  }
          @media screen {
            .mhd-tool-header {
              --mhd-tool-header-gradient: linear-gradient(110deg, #07111B 0%, #102635 58%, #075D63 100%);
              --mhd-tool-header-accent: #12D1CB;
              --mhd-tool-header-muted: #A8BED0;
            }
            .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
              position: relative; flex: none; display: grid;
              grid-template-columns: minmax(0, 1fr) minmax(0, 2.6fr) minmax(0, 1fr);
              align-items: center; gap: 12px; height: auto; min-height: 92px; padding: 10px 18px;
              overflow: hidden; direction: ltr; background: var(--mhd-tool-header-gradient);
              border-bottom: 1px solid var(--mhd-border);
            }
            .mhd-tool-header .brand {
              position: relative; z-index: 1; display: flex; align-items: center; gap: 8px;
              color: var(--mhd-text); letter-spacing: .07em;
            }
            .mhd-tool-header .brand .logo { display: block; flex: none; width: 36px; height: 36px; object-fit: contain; }
            .mhd-tool-header .brand .logo[hidden] { display: none; }
            .mhd-tool-header .brandName { font-size: 13px; }
            .mhd-tool-header .head-text, .mhd-tool-header > .title {
              position: relative; z-index: 1; min-width: 0; text-align: center; direction: ltr;
            }
            html[dir="rtl"] .mhd-tool-header .head-text, html[dir="rtl"] .mhd-tool-header > .title { direction: rtl; }
            .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 24px; font-weight: 800; line-height: 1.25; overflow-wrap: anywhere; }
            .mhd-tool-header .subtitle, .mhd-tool-header .desc {
              display: block; margin-top: 4px; color: var(--mhd-tool-header-muted);
              font-size: 12px; line-height: 1.35; font-weight: 400; overflow-wrap: anywhere;
            }
            .mhd-tool-header .cabinetDrawing {
              position: absolute; right: 10px; bottom: -8px; width: 130px; height: 82px;
              color: var(--mhd-tool-header-accent); opacity: .32; pointer-events: none;
            }
            @media (max-width: 620px) {
              .hero.mhd-tool-header, .mhd-tool-header:not(.hero) {
                grid-template-columns: 48px minmax(0, 1fr) 48px; gap: 8px;
                min-height: 72px; padding: 8px 10px;
              }
              .mhd-tool-header .brand { flex-direction: column; gap: 2px; }
              .mhd-tool-header .brand .logo { width: 30px; height: 30px; }
              .mhd-tool-header .brandName { font-size: 8px; letter-spacing: .03em; }
              .mhd-tool-header .title-main, .mhd-tool-header > .title { font-size: 20px; }
              .mhd-tool-header .subtitle, .mhd-tool-header .desc { font-size: 11px; }
              .mhd-tool-header .cabinetDrawing { right: 4px; width: 70px; height: 52px; opacity: .18; }
            }
          }
        @media screen {
#{MHDESIGN_ResponsiveHeaderUI::CSS}
}
        </style>
      </head>
      <body class="template-1" data-template="1">
        #{toolbar}
        <main class="document">
          <section class="a4-page cover-page" data-page="1">
            <div class="brand-head">
              <div class="brand-project" contenteditable="#{interactive}">#{CGI.escapeHTML(t[:kitchen_project])} #{CGI.escapeHTML(project_name)}</div>
            </div>
            <div class="project-meta">
              <div class="meta-card"><div class="meta-label">#{CGI.escapeHTML(t[:client_name])}</div><div class="meta-value" contenteditable="#{interactive}">#{CGI.escapeHTML(project_name)}</div></div>
              <div class="meta-card"><div class="meta-label">#{CGI.escapeHTML(t[:designer_name])}</div><div class="meta-value" contenteditable="#{interactive}">MHDESIGN</div></div>
              <div class="meta-card"><div class="meta-label">#{CGI.escapeHTML(t[:date])}</div><div class="meta-value" contenteditable="#{interactive}">#{Time.now.strftime('%Y-%m-%d')}</div></div>
            </div>
            <div class="table-editor-wrap" id="mainTableEditor">
              <table class="report-table" id="mainReportTable">
                <tr><th colspan="2" class="main-title" contenteditable="#{interactive}">#{CGI.escapeHTML(t[:kitchen_data])}</th></tr>
                #{rows}
                <tr><th colspan="2" class="section-title" contenteditable="#{interactive}">#{CGI.escapeHTML(t[:accessories])}</th></tr>
                <tr><td colspan="2" class="accessory" contenteditable="#{interactive}">#{CGI.escapeHTML(t[:accessory_dish_rack])}</td></tr>
                <tr><td colspan="2" class="accessory" contenteditable="#{interactive}">#{CGI.escapeHTML(t[:accessory_aventos])}</td></tr>
                <tr><td colspan="2" class="accessory" contenteditable="#{interactive}">#{CGI.escapeHTML(t[:accessory_oil_trolley])}</td></tr>
              </table>
              #{interactive ? <<~CONTROLS : ''}
                <div class="table-row-controls no-print">
                  <button type="button" class="add-row" onclick="addRowBelow()" title="#{CGI.escapeHTML(t[:add_row])}">+</button>
                  <button type="button" onclick="changeRowHeight(-6)">#{CGI.escapeHTML(t[:decrease_height])}</button>
                  <input id="rowHeightRange" type="range" min="28" max="160" value="46" oninput="setActiveRowHeight(this.value)">
                  <span id="rowHeightLabel" class="row-height-label">46 px</span>
                  <button type="button" onclick="changeRowHeight(6)">#{CGI.escapeHTML(t[:increase_height])}</button>
                  <button type="button" class="delete-row" onclick="deleteActiveRow()">#{CGI.escapeHTML(t[:delete_row])}</button>
                </div>
              CONTROLS
            </div>
            <div class="page-footer"><span>MHDESIGN</span><span>Kitchen Production Report</span></div>
          </section>
          #{scenes}
        </main>
        #{script}
      </body>
      </html>
      HTML
    end

    def choose_report_image(target_id, mode = 'replace')
      raise report_i18n[:project_folder_missing] if @pdf_project_directory.to_s.empty?

      source = UI.openpanel(
        report_i18n[:choose_report_image_title],
        nil,
        'Images|*.png;*.jpg;*.jpeg;*.webp;*.bmp||'
      )
      return if source.to_s.empty?

      images_dir = File.join(@pdf_project_directory, 'images')
      FileUtils.mkdir_p(images_dir)

      extension = File.extname(source).downcase
      extension = '.png' if extension.empty?
      safe_base = File.basename(source, File.extname(source))
                      .encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
                      .gsub(/[^0-9A-Za-z؀-ۿ_-]+/, '_')
                      .gsub(/_+/, '_')
                      .sub(/\A_+|_+\z/, '')
      safe_base = 'report_image' if safe_base.empty?
      filename = format('user_%s_%s%s', Time.now.strftime('%Y%m%d_%H%M%S'), safe_base, extension)
      destination = File.join(images_dir, filename)
      counter = 1
      while File.exist?(destination)
        filename = format('user_%s_%s_%d%s', Time.now.strftime('%Y%m%d_%H%M%S'), safe_base, counter, extension)
        destination = File.join(images_dir, filename)
        counter += 1
      end

      FileUtils.cp(source, destination)
      relative_url = 'images/' + CGI.escape(filename).gsub('+', '%20')
      title = File.basename(source, File.extname(source))
      pdf_execute(
        "reportImageChosen(#{target_id.to_json}, #{relative_url.to_json}, #{title.to_json}, #{mode.to_json});"
      )
    end

    def save_edited_report(html)
      raise report_i18n[:project_folder_missing] if @pdf_project_directory.to_s.empty?
      File.write(File.join(@pdf_project_directory, 'report.html'), html.to_s, mode: 'w:UTF-8')
    end

    def pdf_execute(script)
      @dialog.execute_script(script) if @dialog && @dialog.visible?
    rescue
      nil
    end

    # --------------------------------------------------------
    # Helpers
    # --------------------------------------------------------
    def combined_bounds(entities)
      valid = entities.select { |entity| entity&.valid? }
      return nil if valid.empty?

      bounds = Geom::BoundingBox.new
      valid.each { |entity| bounds.add(entity.bounds) }
      bounds
    end

    def format_cm(length_in_inches)
      "#{format_number(length_in_inches.to_f / CM)} #{MHDESIGN_SHOP_LANG.key('SHOP_CM_SUFFIX', 'سم')}"
    end

    def format_number(number)
      rounded = number.round(1)
      rounded == rounded.to_i ?
        rounded.to_i.to_s :
        format('%.1f', rounded)
    end
  end
end


module MHDESIGN
  module InteractiveShopDrawing
    extend self

    def register_context_menu
      return if @context_menu_registered

      UI.add_context_menu_handler do |menu|
        menu.add_separator
        menu.add_item(MENU_TITLE) { run }
      end

      @context_menu_registered = true
    end

    register_context_menu
  end
end