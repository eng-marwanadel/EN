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
# MHD Countertop Engine v3.2 Robust Joints
# ملف واحد مستقل - إضافة رخام للوحدات المحددة
# - يعتمد على BoundingBox للوحدات المحددة
# - يقسم الوحدات تلقائيًا حسب اتجاه محاور أول/كل وحدة
# - كل قطعة Component منفصل: سطح الرخامة / وزرة خلفية / وزرة يمين / وزرة شمال
# - كل القطع داخل Group رئيسي باسم رخامة

require 'sketchup.rb'
require File.join(__dir__, 'MHDESIGN_Language') unless defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:for_tool)
require 'json'
require 'tmpdir'
require 'fileutils'
begin
  require 'open-uri'
rescue LoadError
end
begin
  require 'securerandom'
rescue LoadError
end



# ==================== MHDESIGN COUNTERTOP LANGUAGE BRIDGE ====================
module MHDESIGN_COUNTERTOP_LANG
  extend self

  SOURCE_KEY_MAP = {
    "إضافة رخام" => "CT_DIALOG_TITLE",
    "تم تصميم هذه الأداة بواسطة MHDESIGN" => "CT_SUBTITLE",
    "شكل الرخامة" => "CT_SHAPE",
    "مستقيم" => "CT_SHAPE_STRAIGHT",
    "حرف L" => "CT_SHAPE_L",
    "حرف U" => "CT_SHAPE_U",
    "مربع" => "CT_SHAPE_BOX",
    "خامة الرخامة" => "CT_MATERIAL",
    "المقاسات" => "CT_DIMENSIONS",
    "السماكة" => "CT_THICKNESS",
    "البروز الأمامي" => "CT_FRONT_OVERHANG",
    "البروز الخلفي" => "CT_BACK_OVERHANG",
    "بروز يمين" => "CT_RIGHT_OVERHANG",
    "بروز شمال" => "CT_LEFT_OVERHANG",
    "الوزرة" => "CT_BACKSPLASH",
    "وزرة خلفية" => "CT_BACK_BACKSPLASH_PIECE",
    "وزرة جانبية" => "CT_SIDE_BACKSPLASH",
    "ارتفاع الوزرة" => "CT_BACKSPLASH_HEIGHT",
    "سمك الوزرة" => "CT_BACKSPLASH_THICKNESS",
    "إنشاء" => "CT_CREATE",
    "إلغاء" => "CT_CANCEL",
    "نعم" => "CT_YES",
    "لا" => "CT_NO",
    "حدد الوحدات السفلية الأول" => "CT_SELECT_BASE_UNITS",
    "تم إنشاء الرخام بنجاح" => "CT_SUCCESS",
    "عدد الاتجاهات" => "CT_DIRECTION_COUNT",
    "رخامة" => "CT_COUNTERTOP",
    "سطح الرخامة" => "CT_COUNTERTOP_SURFACE",
    "وزرة شمال" => "CT_LEFT_BACKSPLASH_PIECE",
    "وزرة يمين" => "CT_RIGHT_BACKSPLASH_PIECE",
    "النوع" => "CT_TYPE",
    "نوع الرخام" => "CT_COUNTERTOP_TYPE",
    "عدد الوحدات" => "CT_UNIT_COUNT",
    "عمق موحد سم" => "CT_UNIFIED_DEPTH_CM",
    "الإصدار" => "CT_VERSION",
    "الدور" => "CT_ROLE",
    "سطح" => "CT_SURFACE",
    "الطول سم" => "CT_LENGTH_CM",
    "العرض سم" => "CT_WIDTH_CM",
    "السمك سم" => "CT_THICKNESS_CM",
    "الارتفاع سم" => "CT_HEIGHT_CM",
    "الخامة" => "CT_MATERIAL_ATTR",
    "ثابت" => "CT_FIXED",
    "اسم القطعة" => "CT_PIECE_NAME",
  }.freeze

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
      MHDESIGN::Language.for_tool('countertop').t(key_name.to_s, fallback_text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? key_name.to_s : fallback.to_s
  end

  def t(value, fallback = nil)
    text = value.to_s
    return text if text.empty?
    stable_key = SOURCE_KEY_MAP[text]
    return key(stable_key, fallback || text) if stable_key
    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('countertop').translate_source(text)
    else
      fallback.nil? ? text : fallback.to_s
    end
  rescue
    fallback.nil? ? value.to_s : fallback.to_s
  end

  def messagebox(message, *args)
    UI.messagebox(t(message), *args)
  end

  def payload_json
    payload = if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('countertop').ui_payload
    else
      { locale: current, direction: direction, texts: {}, source_map: {} }
    end

    {
      locale: payload[:locale] || payload['locale'] || current,
      direction: payload[:direction] || payload['direction'] || direction,
      texts: payload[:texts] || payload['texts'] || {},
      source_map: payload[:source_map] || payload['source_map'] || {},
      source_keys: SOURCE_KEY_MAP
    }.to_json
  rescue
    '{"locale":"ar_EG","direction":"rtl","texts":{},"source_map":{},"source_keys":{}}'
  end
end
# ============================================================================

module MHD_Countertop_Engine_V31_MATERIAL_GALLERY
  extend self

  MENU_TEXT = MHDESIGN_COUNTERTOP_LANG.t('إضافة رخام')
  DICT = 'MHD_COUNTERTOP_ENGINE'
  LOGO_URL = 'https://mhdesign-eg.com/SKETCHUP022/components/logo3.png'

  # خامات الرخام: غيّر روابط الصور لاحقًا أو زوّد خامات جديدة هنا فقط.
  MATERIALS = [
    { 'id' => 'carrara', 'name' => 'Carrara', 'image' => 'https://mhdesign-eg.com/SKETCHUP022/countertop_materials/carrara.jpg', 'color' => [235, 232, 210] },
    { 'id' => 'calacatta', 'name' => 'Calacatta', 'image' => 'https://mhdesign-eg.com/SKETCHUP022/countertop_materials/calacatta.jpg', 'color' => [240, 238, 226] },
    { 'id' => 'marquina', 'name' => 'Marquina', 'image' => 'https://mhdesign-eg.com/SKETCHUP022/countertop_materials/marquina.jpg', 'color' => [35, 35, 38] },
    { 'id' => 'black_galaxy', 'name' => 'Black Galaxy', 'image' => 'https://mhdesign-eg.com/SKETCHUP022/countertop_materials/black_galaxy.jpg', 'color' => [18, 18, 20] },
    { 'id' => 'emperador', 'name' => 'Emperador', 'image' => 'https://mhdesign-eg.com/SKETCHUP022/countertop_materials/emperador.jpg', 'color' => [92, 63, 45] },
    { 'id' => 'travertine', 'name' => 'Travertine', 'image' => 'https://mhdesign-eg.com/SKETCHUP022/countertop_materials/travertine.jpg', 'color' => [203, 182, 145] }
  ]

  # -------------------------
  # Helpers
  # -------------------------
  def uuid
    defined?(SecureRandom) ? SecureRandom.uuid : "#{Time.now.to_i}-#{rand(999999)}"
  end

  def tag(model, name)
    model.layers[name] || model.layers.add(name)
  end

  def material_info(material_id)
    MATERIALS.find { |m| m['id'].to_s == material_id.to_s } || MATERIALS.first
  end

  def safe_filename(name)
    name.to_s.gsub(/[^0-9A-Za-z_\-.]/, '_')
  end

  def local_material_texture_path(info)
    url = info['image'].to_s.strip
    return nil if url.empty?

    if url =~ /^https?:\/\//i
      dir = File.join(Dir.tmpdir, 'mhd_countertop_materials')
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      ext = File.extname(url.split('?').first)
      ext = '.jpg' if ext.empty?
      path = File.join(dir, "#{safe_filename(info['id'])}#{ext}")

      unless File.exist?(path) && File.size(path) > 0
        URI.open(url, 'rb') do |io|
          File.binwrite(path, io.read)
        end
      end

      return path if File.exist?(path) && File.size(path) > 0
      nil
    else
      File.exist?(url) ? url : nil
    end
  rescue
    nil
  end

  def countertop_material(model, material_id = nil)
    info = material_info(material_id)
    mat_name = "MHD_Countertop_#{info['id']}"
    mat = model.materials[mat_name] || model.materials.add(mat_name)

    texture_path = local_material_texture_path(info)
    if texture_path
      begin
        mat.texture = texture_path
      rescue
      end
    end

    if info['color'].is_a?(Array) && info['color'].length >= 3
      mat.color = Sketchup::Color.new(info['color'][0], info['color'][1], info['color'][2])
    else
      mat.color = Sketchup::Color.new(235, 232, 210)
    end

    mat
  end

  def apply_material_to_definition(definition, material)
    return unless definition && material
    definition.entities.grep(Sketchup::Face).each do |f|
      f.material = material
      f.back_material = material
    end
  end

  def set_attrs(entity, data)
    data.each { |k, v| entity.set_attribute(DICT, k, v) }
  end

  def selected_instances
    Sketchup.active_model.selection.grep(Sketchup::ComponentInstance) +
      Sketchup.active_model.selection.grep(Sketchup::Group)
  end

  def normalize_vec(v)
    vv = v.clone
    return nil if vv.length <= 0
    vv.normalize!
    vv
  end

  def axis_key(inst)
    # تجميع حسب اتجاه X/Y المحلي أفقيًا، مع تجاهل الاتجاه العكسي قدر الإمكان
    tr = inst.transformation
    x = normalize_vec(Geom::Vector3d.new(tr.xaxis.x, tr.xaxis.y, 0))
    y = normalize_vec(Geom::Vector3d.new(tr.yaxis.x, tr.yaxis.y, 0))
    return 'default' unless x && y

    # خلى الاتجاهات المعكوسة تعتبر نفس المجموعة
    x.reverse! if x.x < -0.001 || (x.x.abs < 0.001 && x.y < -0.001)
    y.reverse! if y.x < -0.001 || (y.x.abs < 0.001 && y.y < -0.001)

    "#{x.x.round(3)},#{x.y.round(3)}|#{y.x.round(3)},#{y.y.round(3)}"
  end

  def interval_gap_values(a1, a2, b1, b2)
    return 0.0 if [a2, b2].min >= [a1, b1].max
    b1 > a2 ? (b1 - a2) : (a1 - b2)
  end

  def split_parallel_axis_group(instances)
    # مهم للـ U Shape:
    # أحيانًا الضلعين اليمين والشمال يكونوا نفس اتجاه المحاور، فكانوا بيتجمعوا كاتجاه واحد.
    # هنا بنقسم نفس الاتجاه إلى صفوف منفصلة حسب مكانها على محور العمق المحلي.
    return [] if instances.empty?
    return [instances] if instances.length == 1

    ref = instances.first
    tr = ref.transformation
    xaxis = normalize_vec(Geom::Vector3d.new(tr.xaxis.x, tr.xaxis.y, 0)) || X_AXIS
    yaxis = normalize_vec(Geom::Vector3d.new(tr.yaxis.x, tr.yaxis.y, 0)) || Y_AXIS
    yaxis.reverse!
    origin = tr.origin

    items = instances.map do |inst|
      ys = world_corners(inst.bounds).map do |p|
        origin.vector_to(p).dot(yaxis)
      end
      { inst: inst, min_y: ys.min, max_y: ys.max, center_y: (ys.min + ys.max) / 2.0 }
    end.sort_by { |h| h[:center_y] }

    clusters = []
    tol = 10.cm

    items.each do |item|
      placed = false
      clusters.each do |cl|
        cmin = cl.map { |h| h[:min_y] }.min
        cmax = cl.map { |h| h[:max_y] }.max
        gap = interval_gap_values(cmin, cmax, item[:min_y], item[:max_y])
        if gap <= tol
          cl << item
          placed = true
          break
        end
      end
      clusters << [item] unless placed
    end

    clusters.map { |cl| cl.map { |h| h[:inst] } }
  end

  def grouped_by_axes(instances)
    groups = {}
    instances.each do |inst|
      groups[axis_key(inst)] ||= []
      groups[axis_key(inst)] << inst
    end

    # بعد التجميع حسب المحاور، نقسم الاتجاه الواحد لو فيه صفين منفصلين متوازيين.
    groups.values.flat_map { |grp| split_parallel_axis_group(grp) }
  end

  def world_corners(bb)
    pts = []
    8.times { |i| pts << bb.corner(i) }
    pts
  end

  def local_bounds_for_group(instances, xaxis, yaxis, origin)
    min_x = min_y = min_z = Float::INFINITY
    max_x = max_y = max_z = -Float::INFINITY

    instances.each do |inst|
      world_corners(inst.bounds).each do |p|
        v = origin.vector_to(p)
        lx = v.dot(xaxis)
        ly = v.dot(yaxis)
        lz = p.z

        min_x = [min_x, lx].min
        max_x = [max_x, lx].max
        min_y = [min_y, ly].min
        max_y = [max_y, ly].max
        min_z = [min_z, lz].min
        max_z = [max_z, lz].max
      end
    end

    {
      min_x: min_x, max_x: max_x,
      min_y: min_y, max_y: max_y,
      min_z: min_z, max_z: max_z
    }
  end


  def min_instance_depth_for_group(instances, xaxis, yaxis, origin)
    # أقل عمق حقيقي بين الوحدات داخل نفس الاتجاه.
    # مهم جدًا للمربع / 4 اتجاهات: لا نعتمد على BoundingBox المجموعة لأنه ممكن يكبر عند الركن.
    depths = []

    instances.each do |inst|
      ys = world_corners(inst.bounds).map do |p|
        origin.vector_to(p).dot(yaxis)
      end
      d = ys.max - ys.min
      depths << d.abs if d && d.abs > 0.1.cm
    end

    depths.empty? ? nil : depths.min
  end

  def pt(origin, xaxis, yaxis, lx, ly, z)
    p = origin.offset(xaxis, lx).offset(yaxis, ly)
    Geom::Point3d.new(p.x, p.y, z)
  end

  def add_box_component(parent_ents, model, name, tag_name, pts_bottom, height, attrs = {}, material = nil)
    return nil if height <= 0

    definition = model.definitions.add("#{name}_#{Time.now.to_i}_#{rand(9999)}")
    ents = definition.entities

    face = ents.add_face(pts_bottom)
    return nil unless face
    face.reverse! if face.normal.z < 0
    face.pushpull(height)

    inst = parent_ents.add_instance(definition, Geom::Transformation.new)
    inst.name = name
    inst.layer = tag(model, tag_name)

    apply_material_to_definition(definition, material || countertop_material(model))

    set_attrs(inst, attrs.merge({
      'UUID' => uuid,
      'اسم القطعة' => name
    }))

    inst
  end

  def rect_corners_world(origin, xaxis, yaxis, lx1, lx2, ly1, ly2, z)
    [
      pt(origin, xaxis, yaxis, lx1, ly1, z),
      pt(origin, xaxis, yaxis, lx2, ly1, z),
      pt(origin, xaxis, yaxis, lx2, ly2, z),
      pt(origin, xaxis, yaxis, lx1, ly2, z)
    ]
  end

  def project_point_to_local(origin, xaxis, yaxis, p)
    v = origin.vector_to(p)
    [v.dot(xaxis), v.dot(yaxis)]
  end

  def build_countertop_plan(instances, input, index)
    ref = instances.first
    tr = ref.transformation

    xaxis = normalize_vec(Geom::Vector3d.new(tr.xaxis.x, tr.xaxis.y, 0)) || X_AXIS
    yaxis = normalize_vec(Geom::Vector3d.new(tr.yaxis.x, tr.yaxis.y, 0)) || Y_AXIS

    # اتجاه مكتبة MHD: عكس Y المحلي يجعل الخلف/الأمام صحيحين حسب التجارب السابقة
    yaxis.reverse!

    origin = tr.origin
    bounds = local_bounds_for_group(instances, xaxis, yaxis, origin)
    z_top = bounds[:max_z]

    # عمق المجموعة المستخدم في الرخام يجب أن يعتمد على أقل عمق وحدة داخل الاتجاه،
    # وليس أكبر BoundingBox للمجموعة بالكامل، خصوصًا في المربع / 4 اتجاهات.
    natural_depth = min_instance_depth_for_group(instances, xaxis, yaxis, origin)
    natural_depth ||= (bounds[:max_y] - bounds[:min_y]).abs
    natural_depth += input[:front_oh].cm + input[:back_oh].cm

    lx1 = bounds[:min_x] - input[:left_oh].cm
    lx2 = bounds[:max_x] + input[:right_oh].cm
    ly1 = bounds[:min_y] - input[:back_oh].cm
    ly2 = ly1 + natural_depth

    {
      index: index,
      instances: instances,
      origin: origin,
      xaxis: xaxis,
      yaxis: yaxis,
      z_top: z_top,
      lx1: lx1,
      lx2: lx2,
      ly1: ly1,
      ly2: ly2,
      natural_depth: natural_depth
    }
  end

  def plan_area(plan)
    (plan[:lx2] - plan[:lx1]).abs * (plan[:ly2] - plan[:ly1]).abs
  end

  def rect_overlap_in_plan_space(plan, other)
    other_pts = rect_corners_world(
      other[:origin], other[:xaxis], other[:yaxis],
      other[:lx1], other[:lx2], other[:ly1], other[:ly2], other[:z_top]
    )

    xs = []
    ys = []
    other_pts.each do |p|
      lx, ly = project_point_to_local(plan[:origin], plan[:xaxis], plan[:yaxis], p)
      xs << lx
      ys << ly
    end

    ox1 = xs.min
    ox2 = xs.max
    oy1 = ys.min
    oy2 = ys.max

    ix1 = [plan[:lx1], ox1].max
    ix2 = [plan[:lx2], ox2].min
    iy1 = [plan[:ly1], oy1].max
    iy2 = [plan[:ly2], oy2].min

    return nil if ix2 <= ix1 + 0.1.cm
    return nil if iy2 <= iy1 + 0.1.cm

    { ix1: ix1, ix2: ix2, iy1: iy1, iy2: iy2 }
  end

  def trim_plan_against_previous!(plan, previous_plans, joint_overlap = 2.cm)
    # تقليم ذكي للتداخل في الركن: يمنع رخامتين فوق بعض في L/U
    # مع عمل overlap بسيط عند الالتقاء عشان ميبقاش فيه فراغ بين الرخامتين.
    previous_plans.each do |prev|
      ov = rect_overlap_in_plan_space(plan, prev)
      next unless ov

      # نعتبر الاتجاه الطويل هو X المحلي غالباً في وحدات المطبخ.
      left_dist  = (ov[:ix1] - plan[:lx1]).abs
      right_dist = (plan[:lx2] - ov[:ix2]).abs

      if left_dist < right_dist
        new_lx1 = ov[:ix2] - joint_overlap
        plan[:lx1] = [[new_lx1, plan[:lx1]].max, plan[:lx2] - 0.1.cm].min
        plan[:joint_overlap_applied] = true
      else
        new_lx2 = ov[:ix1] + joint_overlap
        plan[:lx2] = [[new_lx2, plan[:lx2]].min, plan[:lx1] + 0.1.cm].max
        plan[:joint_overlap_applied] = true
      end
    end
  end

  def normalize_depths_to_min!(plans)
    # توحيد العمق على أقل عمق حقيقي بين الوحدات، وليس أقل/أكبر BoundingBox للمجموعات.
    # تثبيت العمق يتم مرة مبكرة، وكل معالجات L/U/Box بعدها لا تغير ly1/ly2.
    return if plans.length < 2

    depths = plans.map do |pl|
      d = pl[:natural_depth] || (pl[:ly2] - pl[:ly1]).abs
      d.abs
    end.select { |d| d > 0.1.cm }
    return if depths.empty?

    min_depth = depths.min

    plans.each do |pl|
      # بنثبت جهة الخلف ly1 ونقصر جهة الأمام فقط.
      pl[:ly2] = pl[:ly1] + min_depth
      pl[:min_depth_applied] = true
      pl[:unified_depth_cm] = min_depth.to_cm.round(2)
    end
  end

  def rect_extents_in_plan_space(plan, other)
    other_pts = rect_corners_world(
      other[:origin], other[:xaxis], other[:yaxis],
      other[:lx1], other[:lx2], other[:ly1], other[:ly2], other[:z_top]
    )

    xs = []
    ys = []
    other_pts.each do |p|
      lx, ly = project_point_to_local(plan[:origin], plan[:xaxis], plan[:yaxis], p)
      xs << lx
      ys << ly
    end

    { ox1: xs.min, ox2: xs.max, oy1: ys.min, oy2: ys.max }
  end


  def interval_gap(a1, a2, b1, b2)
    # 0 لو فيه تداخل، غير كده المسافة بين المستطيلين على محور واحد
    return 0.0 if [a2, b2].min >= [a1, b1].max
    b1 > a2 ? (b1 - a2) : (a1 - b2)
  end

  def close_joint_gaps!(plans)
    # v1.6: تقفيل الالتقاء مع الحفاظ على أقل عمق.
    # لا نمد العمق Y نهائيًا. التعديل يكون على طول الرخامة X فقط.
    # المنطق: الرخامة الأصغر/الثانية هي التي تمتد ناحية الرخامة الأكبر، وليس العكس.
    return if plans.length < 2

    overlap = 0.7.cm       # دخول بسيط لضمان عدم ظهور فراغ
    min_gap = 0.05.cm
    snap_tol = 90.cm       # يسمح بقفل فراغ الركنة اليدوي بدون زيادة العمق

    plans.each do |pl|
      pl[:_area_for_snap] = plan_area(pl)
    end

    plans.each_with_index do |pl, i|
      plans.each_with_index do |other, j|
        next if i == j

        # نعدل الأصغر فقط، أو لو متساويين نعدل صاحب الترتيب الأكبر.
        next if pl[:_area_for_snap] > other[:_area_for_snap] + 0.1.cm
        next if (pl[:_area_for_snap] - other[:_area_for_snap]).abs <= 0.1.cm && i < j

        ex = rect_extents_in_plan_space(pl, other)

        # لازم يكون فيه تداخل أو قرب في العمق، لكن ممنوع نغير العمق نفسه.
        y_gap = interval_gap(pl[:ly1], pl[:ly2], ex[:oy1], ex[:oy2])
        next if y_gap > snap_tol

        # لو الرخامة الأكبر واقعة شمال/يسار الرخامة الحالية، مدّ الطرف الأيسر لها.
        gap_left = pl[:lx1] - ex[:ox2]
        if gap_left > min_gap && gap_left <= snap_tol
          pl[:lx1] = ex[:ox2] - overlap
          pl[:joint_snap_applied] = true
          next
        end

        # لو الرخامة الأكبر واقعة يمين الرخامة الحالية، مدّ الطرف الأيمن لها.
        gap_right = ex[:ox1] - pl[:lx2]
        if gap_right > min_gap && gap_right <= snap_tol
          pl[:lx2] = ex[:ox1] + overlap
          pl[:joint_snap_applied] = true
          next
        end
      end
    end

    plans.each { |pl| pl.delete(:_area_for_snap) }
  end


  def extend_plan_x_to_touch!(plan, other, overlap = 0.7.cm, snap_tol = 300.cm)
    # يمد طول plan فقط على محور X المحلي حتى يلامس other.
    # لا يغير عمق الرخامة Y نهائيًا.
    ex = rect_extents_in_plan_space(plan, other)

    # لو other موجود ناحية شمال/بداية plan
    gap_left = plan[:lx1] - ex[:ox2]
    if gap_left > 0.05.cm && gap_left <= snap_tol
      plan[:lx1] = ex[:ox2] - overlap
      plan[:u_joint_extended] = true
      return true
    end

    # لو other موجود ناحية يمين/نهاية plan
    gap_right = ex[:ox1] - plan[:lx2]
    if gap_right > 0.05.cm && gap_right <= snap_tol
      plan[:lx2] = ex[:ox1] + overlap
      plan[:u_joint_extended] = true
      return true
    end

    false
  end

  def u_contact_score(plan, other, tol = 120.cm)
    # تقييم هل plan قريب من other كطرف U أو L.
    # بنقيس القرب على محور X المحلي للـ plan فقط، لأن التمديد مسموح في الطول فقط.
    ex = rect_extents_in_plan_space(plan, other)
    gap_left  = plan[:lx1] - ex[:ox2]
    gap_right = ex[:ox1] - plan[:lx2]
    gap = [gap_left.abs, gap_right.abs].min

    # تداخل/قرب في العمق يساعدنا نعرف مين بيقابل مين.
    y_gap = interval_gap(plan[:ly1], plan[:ly2], ex[:oy1], ex[:oy2])

    return 0 if gap > tol && gap_left > 0 && gap_right > 0
    return 0 if y_gap > tol

    # نقاط أعلى للقطع القريبة أو المتداخلة
    score = 1
    score += 2 if gap <= 5.cm || gap_left <= 0 || gap_right <= 0
    score += 1 if y_gap <= 5.cm
    score
  end

  def apply_u_shape_support!(plans)
    # v1.8:
    # لو عندنا 3 اتجاهات، نعتبرها 3 مستقيمات:
    # ضلع وسط + ضلعين طرفيين.
    # الضلعان الطرفيان يتمدان في اتجاه الطول فقط حتى يلامسا الضلع الأوسط.
    # العمق يبقى موحد على أقل عمق ولا يتغير هنا.
    return false unless plans.length == 3

    # اختار الضلع الأوسط: الأكثر اتصالًا بالاتجاهين الآخرين.
    best = nil
    best_score = -1
    plans.each_with_index do |pl, i|
      score = 0
      plans.each_with_index do |other, j|
        next if i == j
        score += u_contact_score(pl, other)
      end

      # في حالة التعادل، الأكبر مساحة غالبًا هو الضلع الخلفي/الأوسط
      area = plan_area(pl)
      key = [score, area]
      if best.nil? || key[0] > best_score || (key[0] == best_score && area > plan_area(best))
        best = pl
        best_score = score
      end
    end

    middle = best || plans.max_by { |pl| plan_area(pl) }
    return false unless middle

    plans.each do |pl|
      next if pl.equal?(middle)
      extend_plan_x_to_touch!(pl, middle)
    end

    middle[:u_middle_piece] = true
    true
  end



  def close_all_joint_gaps_for_box!(plans)
    # v2.3: وضع المربع / 4 اتجاهات
    # يقفل التقاء كل رخامة مع القريبة منها بدون تغيير العمق إطلاقًا.
    # التعديل يكون في اتجاه الطول المحلي X فقط، عشان يفضل العمق موحد على أقل عمق.
    return if plans.length < 4

    overlap = 0.7.cm
    min_gap = 0.03.cm
    snap_tol = 180.cm
    y_tol = 120.cm

    # نكرر مرتين لأن تعديل خطة ممكن يخلي خطة تانية تقدر تلمسها بعد التعديل.
    2.times do
      changed = false

      plans.each_with_index do |pl, i|
        plans.each_with_index do |other, j|
          next if i == j

          ex = rect_extents_in_plan_space(pl, other)

          # ممنوع نعدل العمق Y؛ بس لازم يكون فيه قرب/تداخل في اتجاه العمق.
          y_gap = interval_gap(pl[:ly1], pl[:ly2], ex[:oy1], ex[:oy2])
          next if y_gap > y_tol

          # لو other ناحية بداية pl، مد بداية pl لحده.
          gap_left = pl[:lx1] - ex[:ox2]
          if gap_left > min_gap && gap_left <= snap_tol
            pl[:lx1] = ex[:ox2] - overlap
            pl[:box_joint_closed] = true
            changed = true
          end

          # لو other ناحية نهاية pl، مد نهاية pl لحده.
          gap_right = ex[:ox1] - pl[:lx2]
          if gap_right > min_gap && gap_right <= snap_tol
            pl[:lx2] = ex[:ox1] + overlap
            pl[:box_joint_closed] = true
            changed = true
          end
        end
      end

      break unless changed
    end
  end



  # ------------------------------------------------------------
  # Robust joint solver v3.2
  # يقفل التقاء الرخام هندسيًا بصرف النظر عن ترتيب التحديد أو طول الأضلاع.
  # لا يغيّر ly1 / ly2 إطلاقًا، لذلك يظل العمق مساويًا لأقل عمق محدد.
  # ------------------------------------------------------------
  def plans_parallel?(a, b, tolerance = 0.985)
    ax = normalize_vec(a[:xaxis])
    bx = normalize_vec(b[:xaxis])
    return false unless ax && bx
    ax.dot(bx).abs >= tolerance
  end

  def extend_nearest_x_end_to_other!(plan, other, overlap = 0.7.cm, snap_tol = 300.cm)
    ex = rect_extents_in_plan_space(plan, other)

    # المسافة المطلوبة من كل طرف حتى مستطيل الرخامة الأخرى.
    gap_left  = plan[:lx1] - ex[:ox2]
    gap_right = ex[:ox1] - plan[:lx2]

    candidates = []
    candidates << [:left, gap_left] if gap_left > 0.01.cm && gap_left <= snap_tol
    candidates << [:right, gap_right] if gap_right > 0.01.cm && gap_right <= snap_tol
    return false if candidates.empty?

    side, gap = candidates.min_by { |item| item[1] }

    if side == :left
      plan[:lx1] = ex[:ox2] - overlap
    else
      plan[:lx2] = ex[:ox1] + overlap
    end

    plan[:robust_joint_closed] = true
    plan[:robust_joint_gap_cm] = gap.to_cm.round(3)
    true
  end

  def joint_pair_candidate?(a, b, max_distance = 300.cm)
    return false if plans_parallel?(a, b)

    ex_ab = rect_extents_in_plan_space(a, b)
    ex_ba = rect_extents_in_plan_space(b, a)

    a_gap = [
      (a[:lx1] - ex_ab[:ox2]).abs,
      (ex_ab[:ox1] - a[:lx2]).abs
    ].min
    b_gap = [
      (b[:lx1] - ex_ba[:ox2]).abs,
      (ex_ba[:ox1] - b[:lx2]).abs
    ].min

    # يجب أن تكون نقطة التقابل قريبة من طرف في القطعتين، وليس منتصفهما.
    a_gap <= max_distance && b_gap <= max_distance
  end

  def robust_close_all_joints!(plans)
    return if plans.length < 2

    overlap = 0.7.cm
    snap_tol = 300.cm

    # تكرار الحل مهم لأن تمديد قطعة قد يجعل القطعة التالية قابلة للالتقاء بدقة أكبر.
    4.times do
      changed = false

      plans.each_with_index do |a, i|
        ((i + 1)...plans.length).each do |j|
          b = plans[j]
          next unless joint_pair_candidate?(a, b, snap_tol)

          changed = true if extend_nearest_x_end_to_other!(a, b, overlap, snap_tol)
          changed = true if extend_nearest_x_end_to_other!(b, a, overlap, snap_tol)
        end
      end

      break unless changed
    end
  end

  def range_overlap_len(a1, a2, b1, b2)
    [a2, b2].min - [a1, b1].max
  end

  def side_edge_touches_other?(plan, other, side, tol = 2.cm, min_overlap = 2.cm)
    # تحديد هل طرف الوزرة الجانبية يلامس رخامة أخرى أم لا.
    # لو لا يلامس: الوزرة الجانبية يجب أن تظهر.
    ex = rect_extents_in_plan_space(plan, other)

    y_overlap = range_overlap_len(plan[:ly1], plan[:ly2], ex[:oy1], ex[:oy2])
    return false if y_overlap <= min_overlap

    edge_x = side == :left ? plan[:lx1] : plan[:lx2]

    # المسافة بين خط طرف الرخامة والمستطيل الآخر في مساحة plan المحلية.
    x_dist = if edge_x < ex[:ox1]
      ex[:ox1] - edge_x
    elsif edge_x > ex[:ox2]
      edge_x - ex[:ox2]
    else
      0.0
    end

    x_dist <= tol
  end

  def mark_smart_side_backsplash!(plans)
    # الوزرة الجانبية الذكية:
    # كل قطعة رخام تقفل بوزرة جانبية في الأطراف الخارجية فقط.
    # يتم حذف الوزرة فقط عند نقطة التقاء حقيقية مع رخامة أخرى.
    plans.each do |pl|
      pl[:skip_left_backsplash] = false
      pl[:skip_right_backsplash] = false
    end

    plans.each_with_index do |pl, i|
      plans.each_with_index do |other, j|
        next if i == j

        pl[:skip_left_backsplash] = true if side_edge_touches_other?(pl, other, :left)
        pl[:skip_right_backsplash] = true if side_edge_touches_other?(pl, other, :right)
      end
    end
  end

  def create_countertop_from_plan(model, parent_ents, plan, input)
    marble_type = input[:marble_type]
    thickness   = input[:thickness].cm
    backsplash_h = input[:backsplash_h].cm
    backsplash_t = input[:backsplash_t].cm
    add_back     = input[:add_back]
    add_sides    = input[:add_sides]

    return nil if plan[:lx2] <= plan[:lx1] + 0.1.cm
    return nil if plan[:ly2] <= plan[:ly1] + 0.1.cm

    origin = plan[:origin]
    xaxis  = plan[:xaxis]
    yaxis  = plan[:yaxis]
    z_top  = plan[:z_top]
    lx1    = plan[:lx1]
    lx2    = plan[:lx2]
    ly1    = plan[:ly1]
    ly2    = plan[:ly2]
    index  = plan[:index]

    group_name = index == 1 ? MHDESIGN_COUNTERTOP_LANG.t('رخامة') : "#{MHDESIGN_COUNTERTOP_LANG.t('رخامة')} #{format('%02d', index)}"
    group = parent_ents.add_group
    group.name = group_name
    group.layer = tag(model, 'MHD | الرخام')
    gents = group.entities
    mat = countertop_material(model, input[:material_id])

    set_attrs(group, {
      'UUID' => uuid,
      'النوع' => 'رخامة',
      'نوع الرخام' => marble_type,
      'خامة الرخامة' => (input[:material_name] || material_info(input[:material_id])['name']),
      'عدد الوحدات' => plan[:instances].length,
      'عمق موحد سم' => (plan[:unified_depth_cm] || ((ly2 - ly1).abs).to_cm.round(2)),
      'الإصدار' => 'v3.2 Robust Joints'
    })

    top_pts = rect_corners_world(origin, xaxis, yaxis, lx1, lx2, ly1, ly2, z_top)

    add_box_component(
      gents, model,
      MHDESIGN_COUNTERTOP_LANG.t('سطح الرخامة'),
      'MHD | سطح الرخامة',
      top_pts,
      thickness,
      {
        'النوع' => 'رخامة',
        'الدور' => 'سطح',
        'الطول سم' => ((lx2 - lx1).abs).to_cm.round(2),
        'العرض سم' => ((ly2 - ly1).abs).to_cm.round(2),
        'السمك سم' => input[:thickness],
        'الخامة' => (input[:material_name] || material_info(input[:material_id])['name'])
      },
      mat
    )

    if add_back && backsplash_h > 0 && backsplash_t > 0
      z_b = z_top + thickness
      b1 = ly1
      b2 = ly1 + backsplash_t
      back_pts = rect_corners_world(origin, xaxis, yaxis, lx1, lx2, b1, b2, z_b)

      add_box_component(
        gents, model,
        MHDESIGN_COUNTERTOP_LANG.t('وزرة خلفية'),
        'MHD | وزرة خلفية',
        back_pts,
        backsplash_h,
        {
          'النوع' => 'رخامة',
          'الدور' => 'وزرة خلفية',
          'الطول سم' => ((lx2 - lx1).abs).to_cm.round(2),
          'العرض سم' => input[:backsplash_t],
          'الارتفاع سم' => input[:backsplash_h],
          'الخامة' => (input[:material_name] || material_info(input[:material_id])['name'])
        },
        mat
      )
    end

    if add_sides && backsplash_h > 0 && backsplash_t > 0
      z_b = z_top + thickness

      unless plan[:skip_left_backsplash]
        sx1 = lx1
        sx2 = lx1 + backsplash_t
        left_pts = rect_corners_world(origin, xaxis, yaxis, sx1, sx2, ly1, ly2, z_b)
        add_box_component(
          gents, model,
          MHDESIGN_COUNTERTOP_LANG.t('وزرة شمال'),
          'MHD | وزرة شمال',
          left_pts,
          backsplash_h,
          {
            'النوع' => 'رخامة',
            'الدور' => 'وزرة شمال',
            'الطول سم' => ((ly2 - ly1).abs).to_cm.round(2),
            'العرض سم' => input[:backsplash_t],
            'الارتفاع سم' => input[:backsplash_h],
            'الخامة' => (input[:material_name] || material_info(input[:material_id])['name'])
          },
          mat
        )
      end

      unless plan[:skip_right_backsplash]
        rx1 = lx2 - backsplash_t
        rx2 = lx2
        right_pts = rect_corners_world(origin, xaxis, yaxis, rx1, rx2, ly1, ly2, z_b)
        add_box_component(
          gents, model,
          MHDESIGN_COUNTERTOP_LANG.t('وزرة يمين'),
          'MHD | وزرة يمين',
          right_pts,
          backsplash_h,
          {
            'النوع' => 'رخامة',
            'الدور' => 'وزرة يمين',
            'الطول سم' => ((ly2 - ly1).abs).to_cm.round(2),
            'العرض سم' => input[:backsplash_t],
            'الارتفاع سم' => input[:backsplash_h],
            'الخامة' => (input[:material_name] || material_info(input[:material_id])['name'])
          },
          mat
        )
      end
    end

    group
  end



  # -------------------------
  # Modern HTML Dialog
  # -------------------------
  PREF_KEY = 'MHD_COUNTERTOP_ENGINE_V31_UI'

  def read_pref(key, default)
    Sketchup.read_default(PREF_KEY, key, default)
  end

  def write_pref(key, value)
    Sketchup.write_default(PREF_KEY, key, value)
  end

  def saved_values
    {
      'shape_mode'   => read_pref('shape_mode', 'auto'),
      'thickness'    => read_pref('thickness', 2).to_f,
      'front_oh'     => read_pref('front_oh', 2).to_f,
      'back_oh'      => read_pref('back_oh', 0).to_f,
      'right_oh'     => read_pref('right_oh', 2).to_f,
      'left_oh'      => read_pref('left_oh', 2).to_f,
      'backsplash_h' => read_pref('backsplash_h', 10).to_f,
      'backsplash_t' => read_pref('backsplash_t', 2).to_f,
      'add_back'     => read_pref('add_back', 'نعم').to_s,
      'add_sides'    => read_pref('add_sides', 'نعم').to_s,
      'material_id'  => read_pref('material_id', MATERIALS.first['id']).to_s
    }
  end

  def save_values(data)
    %w[shape_mode material_id thickness front_oh back_oh right_oh left_oh backsplash_h backsplash_t add_back add_sides].each do |k|
      write_pref(k, data[k]) if data.key?(k)
    end
  end

  def html_dialog_content(values)
    v = values
    checked = lambda { |mode| v['shape_mode'].to_s == mode ? 'active' : '' }
    selected_material_id = v['material_id'].to_s.empty? ? MATERIALS.first['id'] : v['material_id'].to_s
    back_yes = v['add_back'] == 'نعم' ? 'checked' : ''
    sides_yes = v['add_sides'] == 'نعم' ? 'checked' : ''
    material_cards = MATERIALS.map do |m|
      active = selected_material_id == m['id'].to_s ? 'active' : ''
      %Q{<div class="mat-card #{active}" data-material-id="#{m['id']}" onclick="selectMaterial(this)"><div class="mat-img" style="background-image:url('#{m['image']}')"></div><div class="mat-name">#{m['name']}</div></div>}
    end.join

    <<-HTML
<!DOCTYPE html>
<html lang="#{MHDESIGN_COUNTERTOP_LANG.current}" dir="#{MHDESIGN_COUNTERTOP_LANG.direction}">
<head>
<meta charset="UTF-8">
<title>MHD Countertop</title>
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
    font-size:20px;
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
    font-size:16px;
    font-weight:900;
    border-bottom:1px solid var(--mhd-border);
    user-select:none;
  }
  .group-body{padding:8px 8px 10px}

  .shape-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:7px}
  .shape{
    background:var(--mhd-card);
    border:1px solid var(--mhd-border);
    border-radius:10px;
    min-height:70px;
    padding:7px 4px;
    cursor:pointer;
    text-align:center;
    transition:.15s;
    color:var(--mhd-text);
  }
  .shape:hover{border-color:var(--mhd-accent)}
  .shape.active{
    border-color:var(--mhd-accent);
    box-shadow:0 0 0 1px rgba(8,201,195,.22);
    background:var(--mhd-panel);
  }
  .shape-name{font-size:11px;margin-top:4px;white-space:nowrap;color:var(--mhd-text)}
  svg{width:40px;height:34px;display:block;margin:0 auto}
  .line{stroke:#ffffff;stroke-width:6;fill:none;stroke-linecap:round;stroke-linejoin:round}
  .shape.active .line{stroke:var(--mhd-bright)}

  .materials-scroll{
    display:flex;
    gap:8px;
    overflow-x:auto;
    overflow-y:hidden;
    padding:2px 2px 8px;
    scroll-behavior:smooth;
  }
  .materials-scroll::-webkit-scrollbar{height:8px}
  .materials-scroll::-webkit-scrollbar-track{background:var(--mhd-app);border-radius:20px}
  .materials-scroll::-webkit-scrollbar-thumb{background:var(--mhd-border);border-radius:20px;border:2px solid var(--mhd-app)}
  .materials-scroll::-webkit-scrollbar-thumb:hover{background:var(--mhd-hover)}
  .mat-card{
    flex:0 0 88px;
    background:var(--mhd-card);
    border:1px solid var(--mhd-border);
    border-radius:10px;
    padding:6px;
    cursor:pointer;
    text-align:center;
    transition:.15s;
  }
  .mat-card:hover{border-color:var(--mhd-accent)}
  .mat-card.active{border-color:var(--mhd-accent);box-shadow:0 0 0 1px rgba(8,201,195,.22);background:var(--mhd-panel)}
  .mat-img{
    height:52px;
    border-radius:7px;
    background-size:cover;
    background-position:center;
    background-color:#182836;
    border:1px solid var(--mhd-border);
  }
  .mat-name{font-size:10px;margin-top:6px;color:var(--mhd-text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}

  .field-row{
    display:grid;
    grid-template-columns:105px 1fr;
    gap:8px;
    align-items:center;
    margin-bottom:7px;
  }
  .field-row:last-child{margin-bottom:0}
  label{
    font-size:13px;
    font-weight:900;
    color:var(--mhd-text);
    text-align:right;
    line-height:1.3;
  }
  input[type=number]{
    width:100%;
    height:30px;
    padding:4px 8px;
    border:none;
    border-radius:6px;
    background:var(--mhd-input);
    color:#fff;
    font-size:13px;
    outline:1px solid var(--mhd-border);
    text-align:center;
  }
  input[type=number]:focus{outline:2px solid var(--mhd-accent);background:var(--mhd-input)}

  .switch-row{
    display:grid;
    grid-template-columns:105px 1fr;
    gap:8px;
    align-items:center;
    margin-bottom:7px;
  }
  .toggle{
    height:30px;
    background:var(--mhd-input);
    border-radius:6px;
    outline:1px solid var(--mhd-border);
    display:flex;
    align-items:center;
    justify-content:space-between;
    padding:0 8px;
    cursor:pointer;
    user-select:none;
    color:#fff;
    font-size:12px;
  }
  .toggle:focus,.toggle:hover{outline:2px solid var(--mhd-accent);background:var(--mhd-input)}
  .toggle .dot{width:16px;height:16px;border-radius:50%;background:#355467;border:1px solid #57798a}
  .toggle.on .dot{background:var(--mhd-accent);border-color:var(--mhd-accent)}

  .footer{
    height:58px;
    padding:8px 10px;
    border-top:1px solid var(--mhd-border);
    background:var(--mhd-app);
    display:flex;
    gap:8px;
  }
  button{
    height:40px;
    border-radius:10px;
    font-size:14px;
    font-weight:900;
    cursor:pointer;
    border:none;
  }
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
  .shape-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
  .shape-name { white-space: normal; overflow-wrap: anywhere; }
  .mat-name { color: var(--mhd-text); }
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
      <div class="title-main">#{MHDESIGN::Language.for_tool('countertop').html('CT_DIALOG_TITLE')}</div>
      <div class="subtitle">#{MHDESIGN::Language.for_tool('countertop').html('ROOM_TOOL_CREDIT')}<br>Countertop Engine V1.0</div>
    </div>
  <!-- Dressing reference header artwork is included in BRAND. --></div>

  <div class="wrap">
    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('countertop').html('TEXT_73921B44C235')}</div>
      <div class="group-body">
        <div class="shape-grid">
          <div class="shape #{checked.call('straight')}" data-mode="straight" onclick="selectShape(this)">
            <svg viewBox="0 0 60 44"><path class="line" d="M8 22 H52"/></svg>
            <div class="shape-name">#{MHDESIGN::Language.for_tool('countertop').html('CT_SHAPE_STRAIGHT')}</div>
          </div>
          <div class="shape #{checked.call('l')}" data-mode="l" onclick="selectShape(this)">
            <svg viewBox="0 0 60 44"><path class="line" d="M10 10 V34 H50"/></svg>
            <div class="shape-name">#{MHDESIGN::Language.for_tool('countertop').html('CT_SHAPE_L')}</div>
          </div>
          <div class="shape #{checked.call('u')}" data-mode="u" onclick="selectShape(this)">
            <svg viewBox="0 0 60 44"><path class="line" d="M10 10 V34 H50 V10"/></svg>
            <div class="shape-name">#{MHDESIGN::Language.for_tool('countertop').html('CT_SHAPE_U')}</div>
          </div>
          <div class="shape #{checked.call('box')}" data-mode="box" onclick="selectShape(this)">
            <svg viewBox="0 0 60 44"><path class="line" d="M12 10 H48 V34 H12 Z"/></svg>
            <div class="shape-name">#{MHDESIGN::Language.for_tool('countertop').html('CT_SHAPE_BOX')}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('countertop').html('TEXT_DF894FAC574A')}</div>
      <div class="group-body">
        <div class="materials-scroll">
          #{material_cards}
        </div>
      </div>
    </div>

    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('countertop').html('ROOM_DIMENSIONS')}</div>
      <div class="group-body">
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_THICKNESS')}</label><input id="thickness" type="number" step="0.1" value="#{v['thickness']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_FRONT_OVERHANG')}</label><input id="front_oh" type="number" step="0.1" value="#{v['front_oh']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_BACK_OVERHANG')}</label><input id="back_oh" type="number" step="0.1" value="#{v['back_oh']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_RIGHT_OVERHANG')}</label><input id="right_oh" type="number" step="0.1" value="#{v['right_oh']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_LEFT_OVERHANG')}</label><input id="left_oh" type="number" step="0.1" value="#{v['left_oh']}"></div>
      </div>
    </div>

    <div class="group">
      <div class="group-title">#{MHDESIGN::Language.for_tool('countertop').html('TEXT_0C80BA2A66EE')}</div>
      <div class="group-body">
        <div class="switch-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_BACK_BACKSPLASH_PIECE')}</label><div id="add_back" class="toggle #{back_yes.empty? ? '' : 'on'}" onclick="toggle(this)"><span>#{MHDESIGN_COUNTERTOP_LANG.t(back_yes.empty? ? 'لا' : 'نعم')}</span><b class="dot"></b></div></div>
        <div class="switch-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_SIDE_BACKSPLASH')}</label><div id="add_sides" class="toggle #{sides_yes.empty? ? '' : 'on'}" onclick="toggle(this)"><span>#{MHDESIGN_COUNTERTOP_LANG.t(sides_yes.empty? ? 'لا' : 'نعم')}</span><b class="dot"></b></div></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_BACKSPLASH_HEIGHT')}</label><input id="backsplash_h" type="number" step="0.1" value="#{v['backsplash_h']}"></div>
        <div class="field-row"><label>#{MHDESIGN::Language.for_tool('countertop').html('CT_BACKSPLASH_THICKNESS')}</label><input id="backsplash_t" type="number" step="0.1" value="#{v['backsplash_t']}"></div>
      </div>
    </div>
  </div>

  <div class="footer">
    <button class="ok" onclick="submitData()">#{MHDESIGN::Language.for_tool('countertop').html('ROOM_CREATE')}</button>
    <button class="cancel" onclick="sketchup.cancel()">#{MHDESIGN::Language.for_tool('countertop').html('COMMON_CANCEL')}</button>
  </div>
</div>

<script>
const MHD_L10N = #{MHDESIGN_COUNTERTOP_LANG.payload_json};
const MHD_TEXTS = MHD_L10N.texts || {};
const MHD_MAP = MHD_L10N.source_map || {};
const MHD_SOURCE_KEYS = MHD_L10N.source_keys || {};

function mhdKey(key, fallback=""){
  const value = MHD_TEXTS[String(key || "")];
  return value == null || String(value).trim() === ""
    ? String(fallback || key || "")
    : String(value);
}

function mhdTranslate(value){value=String(value ?? "");return Object.prototype.hasOwnProperty.call(MHD_MAP,value)?String(MHD_MAP[value]):value;}

window.MHD_LT = mhdTranslate;
document.documentElement.lang = MHD_L10N.locale || "ar_EG";
document.documentElement.dir = MHD_L10N.direction || "rtl";




// حماية شكلية
document.addEventListener('contextmenu', function(e){e.preventDefault();});
document.addEventListener('dragstart', function(e){e.preventDefault();});
document.addEventListener('selectstart', function(e){e.preventDefault();});
window.oncontextmenu=function(){return false;};

let shapeMode = document.querySelector('.shape.active') ? document.querySelector('.shape.active').dataset.mode : 'box';
let materialId = document.querySelector('.mat-card.active') ? document.querySelector('.mat-card.active').dataset.materialId : '#{selected_material_id}';
function selectShape(el){
  document.querySelectorAll('.shape').forEach(x=>x.classList.remove('active'));
  el.classList.add('active');
  shapeMode = el.dataset.mode;
}
function selectMaterial(el){
  document.querySelectorAll('.mat-card').forEach(x=>x.classList.remove('active'));
  el.classList.add('active');
  materialId = el.dataset.materialId;
}
function toggle(el){
  el.classList.toggle('on');
  el.querySelector('span').textContent = el.classList.contains('on') ? mhdTranslate('نعم') : mhdTranslate('لا');
}
function val(id){ return document.getElementById(id).value; }
function yesNo(id){ return document.getElementById(id).classList.contains('on') ? 'نعم' : 'لا'; }
function submitData(){
  const data = {
    shape_mode: shapeMode,
    material_id: materialId,
    thickness: val('thickness'),
    front_oh: val('front_oh'),
    back_oh: val('back_oh'),
    right_oh: val('right_oh'),
    left_oh: val('left_oh'),
    backsplash_h: val('backsplash_h'),
    backsplash_t: val('backsplash_t'),
    add_back: yesNo('add_back'),
    add_sides: yesNo('add_sides')
  };
  sketchup.submit(JSON.stringify(data));
}
</script>
</body>
</html>
    HTML
  end

  def dialog_input
    values = saved_values
    dlg = UI::HtmlDialog.new(
      dialog_title: MHDESIGN_COUNTERTOP_LANG.t('MHD Countertop Engine'),
      preferences_key: PREF_KEY,
      scrollable: false,
      resizable: true,
      width: 330,
      height: 640,
      style: UI::HtmlDialog::STYLE_DIALOG
    )

    dlg.set_html(html_dialog_content(values))

    dlg.add_action_callback('cancel') do
      dlg.close
    end

    dlg.add_action_callback('submit') do |_, json|
      data = JSON.parse(json)
      save_values(data)
      dlg.close

      input = {
        marble_type: 'ثابت',
        shape_mode: data['shape_mode'].to_s,
        material_id: data['material_id'].to_s,
        material_name: material_info(data['material_id'])['name'],
        material_image: material_info(data['material_id'])['image'],
        thickness: data['thickness'].to_f,
        front_oh: data['front_oh'].to_f,
        back_oh: data['back_oh'].to_f,
        right_oh: data['right_oh'].to_f,
        left_oh: data['left_oh'].to_f,
        backsplash_h: data['backsplash_h'].to_f,
        backsplash_t: data['backsplash_t'].to_f,
        add_back: data['add_back'].to_s == 'نعم',
        add_sides: data['add_sides'].to_s == 'نعم',
        trim_corners: true,
        unify_min_depth: true,
        joint_overlap_cm: 2.0
      }
      create_countertop(input)
    rescue => e
      MHDESIGN_COUNTERTOP_LANG.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
    end

    dlg.show
    nil
  end

  def create_countertop(input)
    model = Sketchup.active_model
    instances = selected_instances

    if instances.empty?
      MHDESIGN_COUNTERTOP_LANG.messagebox(MHDESIGN::Language.for_tool('countertop').t('CT_SELECT_BASE_UNITS'))
      return
    end

    model.start_operation('MHD Countertop Engine v3.2', true)

    parent_ents = model.active_entities
    groups = grouped_by_axes(instances)

    plans = groups.each_with_index.map do |grp, i|
      build_countertop_plan(grp, input, i + 1)
    end

    plans.sort_by! { |pl| -plan_area(pl) }
    normalize_depths_to_min!(plans)

    # v3.2: كل الاتجاهات تظل مستقلة، ويتم إغلاق الالتقاء هندسيًا
    # دون الاعتماد على المساحة أو ترتيب اختيار الوحدات أو شكل U/L/Box.
    final_plans = plans
    robust_close_all_joints!(final_plans)

    # تأكيد أخير: ممنوع أي معالجة تغير العمق بعد توحيده.
    normalize_depths_to_min!(final_plans)

    mark_smart_side_backsplash!(final_plans) if input[:add_sides]

    final_plans.each_with_index do |pl, i|
      pl[:index] = i + 1
      pl[:shape_mode] = input[:shape_mode]
      create_countertop_from_plan(model, parent_ents, pl, input)
    end

    model.commit_operation
    MHDESIGN_COUNTERTOP_LANG.messagebox("تم إنشاء الرخام بنجاح\nعدد الاتجاهات: #{final_plans.length}")
  rescue => e
    model.abort_operation rescue nil
    MHDESIGN_COUNTERTOP_LANG.messagebox("Error:\n#{e.message}\n\n#{e.backtrace.first}")
  end

  def add_countertop
    if selected_instances.empty?
      MHDESIGN_COUNTERTOP_LANG.messagebox(MHDESIGN::Language.for_tool('countertop').t('CT_SELECT_BASE_UNITS'))
      return
    end
    dialog_input
  end

  unless @context_menu_loaded
    UI.add_context_menu_handler do |menu|
      unless selected_instances.empty?
        menu.add_separator
        menu.add_item(MENU_TEXT) { add_countertop }
      end
    end
    @context_menu_loaded = true
  end
end
