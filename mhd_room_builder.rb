# =========================================================
# MHD SAFE ARCHITECTURAL INTEGRATION PATCH v4.3
# ---------------------------------------------------------
# إصلاحات v4.3:
# 1) إجبار الـTop Face للأرضية إن يكون اتجاهها UP (حل مشكلة اللون الغامق)
# 2) إعادة بناء الـOpenings بشكل موثوق بعد كل عملية شطرة
# 3) الحفاظ على Front + Back Material للأرضية
# 4) Undo واحد لكل عملية
# =========================================================

module MHD_RoomBuilder_SafeIntegration_V41
  extend self

  DICT = 'MHD_ROOM_BUILDER'
  OPENINGS_KEY = 'OPENINGS_JSON'

  def safe_uuid
    if defined?(SecureRandom)
      SecureRandom.uuid
    else
      "#{Time.now.to_i}-#{rand(999999)}"
    end
  end

  def opening_engine_available?
    defined?(MHD_Opening_Engine_V26_LIVE_WALL_SELECTION) &&
      MHD_Opening_Engine_V26_LIVE_WALL_SELECTION.respond_to?(:read_openings) &&
      MHD_Opening_Engine_V26_LIVE_WALL_SELECTION.respond_to?(:rebuild_wall)
  rescue
    false
  end

  def wall_components(room_group)
    room_group.entities.to_a.select do |e|
      e.valid? &&
        e.is_a?(Sketchup::ComponentInstance) &&
        e.get_attribute(DICT, 'النوع').to_s == 'حائط'
    end
  end

  # ========== Capture Wall State ==========
  def capture_wall_state(room_group)
    result = {}

    wall_components(room_group).each do |wall|
      number = wall.get_attribute(DICT, 'رقم الحائط').to_i
      next if number <= 0

      openings = []
      raw = wall.get_attribute(DICT, OPENINGS_KEY)
      if raw
        begin
          parsed = JSON.parse(raw.to_s)
          openings = parsed.is_a?(Array) ? parsed : []
        rescue
          openings = []
        end
      end

      result[number] = {
        'wall_uuid' => wall.get_attribute(DICT, 'UUID').to_s,
        'openings' => openings,
        'old_length_cm' => wall.get_attribute(DICT, 'طول الحائط سم').to_f
      }
    end

    result
  rescue
    {}
  end

  def normalize_openings_for_new_length(openings, old_length_cm, new_length_cm)
    return [] unless openings.is_a?(Array)

    old_len = old_length_cm.to_f
    new_len = new_length_cm.to_f
    return openings.map(&:dup) if old_len <= 0.001 || new_len <= 0.001

    openings.map do |raw|
      op = raw.is_a?(Hash) ? raw.dup : {}
      width = op['width_cm'].to_f
      next nil if width <= 0.0 || width >= new_len

      old_offset = op['offset_cm'].to_f
      ratio = old_len > 0.001 ? (old_offset / old_len) : 0.0

      new_offset = ratio * new_len
      max_offset = [new_len - width, 0.0].max
      new_offset = [[new_offset, 0.0].max, max_offset].min

      op['offset_cm'] = new_offset.round(4)
      op
    end.compact
  rescue
    []
  end

  # ========== Restore Wall State (UUIDs + Openings + rebuild) ==========
  def restore_wall_state(room_group, state)
    return false unless state.is_a?(Hash)

    if opening_engine_available?
      # أولاً: نحدّث UUID و openings على كل حائط
      wall_components(room_group).each do |wall|
        number = wall.get_attribute(DICT, 'رقم الحائط').to_i
        saved = state[number]
        next unless saved

        old_uuid = saved['wall_uuid'].to_s
        wall.set_attribute(DICT, 'UUID', old_uuid.empty? ? safe_uuid : old_uuid)

        new_length = wall.get_attribute(DICT, 'طول الحائط سم').to_f
        openings = normalize_openings_for_new_length(
          saved['openings'],
          saved['old_length_cm'],
          new_length
        )
        wall.set_attribute(DICT, OPENINGS_KEY, JSON.generate(openings))
      end

      # ثانياً: نعيد بناء كل حائط عنده فتحات
      wall_components(room_group).each do |wall|
        number = wall.get_attribute(DICT, 'رقم الحائط').to_i
        saved = state[number]
        next unless saved

        openings = begin
          JSON.parse(wall.get_attribute(DICT, OPENINGS_KEY).to_s)
        rescue
          []
        end
        next if openings.empty?

        begin
          MHD_Opening_Engine_V26_LIVE_WALL_SELECTION.rebuild_wall(wall)
        rescue => e
          wall.set_attribute(DICT, 'Opening_Integration_Error', e.message.to_s)
        end
      end
    else
      # Fallback: نحفظ UUIDs و openings بس
      wall_components(room_group).each do |wall|
        number = wall.get_attribute(DICT, 'رقم الحائط').to_i
        saved = state[number]
        next unless saved

        old_uuid = saved['wall_uuid'].to_s
        wall.set_attribute(DICT, 'UUID', old_uuid.empty? ? safe_uuid : old_uuid)

        new_length = wall.get_attribute(DICT, 'طول الحائط سم').to_f
        openings = normalize_openings_for_new_length(
          saved['openings'],
          saved['old_length_cm'],
          new_length
        )
        wall.set_attribute(DICT, OPENINGS_KEY, JSON.generate(openings))
      end
    end

    true
  rescue
    false
  end

  # ========== Fix Floor Face Orientation ==========
  def fix_floor_face_orientation(floor_def, floor_t)
    return unless floor_def && floor_def.respond_to?(:entities)
    floor_def.entities.grep(Sketchup::Face).each do |face|
      next unless face.valid?
      next unless face.normal.z.abs > 0.9  # horizontal face only
      # Top face: should have normal.z > 0
      # Bottom face: should have normal.z < 0
      z_center = (face.bounds.min.z + face.bounds.max.z) / 2.0
      if z_center > -floor_t / 2.0
        # Top face - normal must be UP
        face.reverse! if face.normal.z < 0
      else
        # Bottom face - normal must be DOWN
        face.reverse! if face.normal.z > 0
      end
    end
  rescue
    nil
  end

  # ========== Rebuild Room Floor (patched - orientation-safe) ==========
  def rebuild_room_floor_with_fix(room_group, outward_pts, floor_t, floor_t_cm, room_name, room_uuid, mat_info)
    model = Sketchup.active_model

    delete_room_parts(room_group, 'أرضية')
    return if floor_t.to_f <= 0 || !outward_pts || outward_pts.length < 3

    pts = outward_pts.map { |p| Geom::Point3d.new(p.x, p.y, 0) }
    return unless polygon_usable?(pts)

    stamp = Time.now.to_i
    floor_def = model.definitions.add("#{room_name}_أرضية_#{stamp}_#{rand(99999)}")
    floor_face = floor_def.entities.add_face(pts)
    return unless floor_face
    floor_face.reverse! if floor_face.normal.z < 0
    floor_face.pushpull(-floor_t)

    # ✅ الإصلاح الأساسي: تأكيد اتجاه الأوجه الأفقية
    fix_floor_face_orientation(floor_def, floor_t)

    # تطبيق المواد
    if mat_info.is_a?(Hash) && (mat_info['has_front'] || mat_info['has_back'])
      front_mat = mat_info['has_front'] ? model.materials[mat_info['front_name']] : nil
      back_mat  = mat_info['has_back']  ? model.materials[mat_info['back_name']]  : nil
      back_mat ||= front_mat if front_mat

      floor_def.entities.grep(Sketchup::Face).each do |face|
        begin
          face.material = front_mat if front_mat
          face.back_material = back_mat if back_mat
        rescue
        end
      end
    end

    floor_def.entities.grep(Sketchup::Edge).each do |edge|
      begin
        edge.hidden = true if edge.respond_to?(:hidden=)
        edge.soft = true if edge.respond_to?(:soft=)
        edge.smooth = true if edge.respond_to?(:smooth=)
      rescue
      end
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

  # ========== Hook: synchronize_room_geometry ==========
  def synchronize_room_geometry(room_group, pts, room_data)
    wall_state = capture_wall_state(room_group)
    floor_mat_info = capture_floor_material_info(room_group)

    # تخزين معلومات الأرضية على الـroom_group عشان الـrebuild يستخدمها
    @pending_floor_mat_info ||= {}
    uuid_v = room_group.get_attribute(DICT, 'UUID').to_s
    @pending_floor_mat_info[uuid_v] = floor_mat_info

    result = super(room_group, pts, room_data)

    restore_wall_state(room_group, wall_state)
    result
  rescue => e
    raise e
  end

  # Override rebuild_room_floor عشان يستخدم النسخة المُصلَحة
  def rebuild_room_floor(room_group, outward_pts, floor_t, floor_t_cm, room_name, room_uuid, mat_info = nil)
    uuid_v = room_group.get_attribute(DICT, 'UUID').to_s
    saved_mat_info = (@pending_floor_mat_info || {})[uuid_v]
    mat_info ||= saved_mat_info || capture_floor_material_info(room_group)
    rebuild_room_floor_with_fix(room_group, outward_pts, floor_t, floor_t_cm, room_name, room_uuid, mat_info)
  end

  # ========== Apply Shatra (real geometry modification) ==========
  def apply_shatra_calibration(room_group, corner_idx, data, mode = :apply)
    return false unless room_group && room_group.valid?

    a = data['a_cm'].to_f
    b = data['b_cm'].to_f
    diag = data['diagonal_cm'].to_f
    angle = shatra_angle_from_sides(a, b, diag)

    unless angle
      UI.messagebox(
        "❌ مقاسات الشطرة غير هندسية.\n" \
        "لازم القطر يكون أكبر من |#{a} - #{b}| وأصغر من #{a + b}."
      )
      return false
    end

    pts = room_pts_from_group(room_group)
    unless pts && pts.length >= 3
      UI.messagebox('❌ لا يمكن قراءة نقاط الغرفة.')
      return false
    end

    existing_shatra = shatra_for_corner(room_group, corner_idx)
    target_uuid = data['uuid'].to_s
    target_uuid = existing_shatra['uuid'].to_s if target_uuid.empty? && existing_shatra

    prev_i = (corner_idx - 1) % pts.length
    next_i = (corner_idx + 1) % pts.length

    original_pts_for_corner =
      if existing_shatra && existing_shatra['original_corner_pts'].is_a?(Array)
        existing_shatra['original_corner_pts']
      else
        [
          [pts[prev_i].x.to_f, pts[prev_i].y.to_f, pts[prev_i].z.to_f],
          [pts[corner_idx].x.to_f, pts[corner_idx].y.to_f, pts[corner_idx].z.to_f],
          [pts[next_i].x.to_f, pts[next_i].y.to_f, pts[next_i].z.to_f]
        ]
      end

    new_pts = shatra_adjust_corner_points(pts, corner_idx, angle)
    unless new_pts && polygon_valid_for_wall_edit?(new_pts)
      UI.messagebox('❌ القياسات ستنتج شكلاً هندسياً غير صالح.')
      return false
    end

    model = Sketchup.active_model
    room_data = build_data_from_group(room_group) || {}
    room_data = room_data.dup
    old_pts = pts.map(&:clone)

    if mode == :preview && !has_preview_state?(room_group)
      preview_snapshot(room_group)
    end

    op_name = (mode == :preview) ? 'MHD Shatra Preview' : 'MHD Shatra Apply'
    model.start_operation(op_name, true)
    begin
      remove_legacy_source_floor_geometry(old_pts)
      synchronize_room_geometry(room_group, new_pts, room_data)

      shatras = shatras_from_room(room_group)
      shatras.reject! do |s|
        s['corner_index'].to_i == corner_idx.to_i ||
          (!target_uuid.empty? && s['uuid'].to_s == target_uuid)
      end
      shatras << {
        'uuid' => (target_uuid.empty? ? safe_uuid : target_uuid),
        'corner_index' => corner_idx.to_i,
        'a_cm' => a,
        'b_cm' => b,
        'diagonal_cm' => diag,
        'angle_deg' => angle,
        'original_corner_pts' => original_pts_for_corner
      }
      save_shatras(room_group, shatras)
      rebuild_all_shatras(room_group)

      model.commit_operation
      model.active_view.invalidate

      if mode == :apply
        clear_preview_state(room_group) rescue nil
        UI.messagebox("✅ تم تطبيق الشطرة بنجاح\n\n#{shatra_result_text(a, b, diag, angle)}")
      end
      true
    rescue => e
      model.abort_operation rescue nil
      UI.messagebox("❌ خطأ أثناء تطبيق الشطرة:\n#{e.message}")
      false
    ensure
      # تنظيف
      uuid_v = room_group.get_attribute(DICT, 'UUID').to_s
      (@pending_floor_mat_info || {}).delete(uuid_v) if @pending_floor_mat_info
    end
  end

  # ========== Delete Shatra ==========
  def delete_shatra(room_group, shatra_uuid)
    return false unless room_group && room_group.valid?

    uuid_to_delete = shatra_uuid.to_s
    shatras = shatras_from_room(room_group)
    target = shatras.find { |s| s['uuid'].to_s == uuid_to_delete }
    return false unless target

    corner_idx = target['corner_index'].to_i
    original_pts = target['original_corner_pts']

    model = Sketchup.active_model
    model.start_operation('MHD Delete Shatra', true)
    begin
      if original_pts.is_a?(Array) && original_pts.length == 3
        pts = room_pts_from_group(room_group)
        if pts && pts.length >= 3
          n = pts.length
          prev_i = (corner_idx - 1) % n
          next_i = (corner_idx + 1) % n

          pts[prev_i]     = Geom::Point3d.new(original_pts[0][0].to_f, original_pts[0][1].to_f, original_pts[0][2].to_f)
          pts[corner_idx] = Geom::Point3d.new(original_pts[1][0].to_f, original_pts[1][1].to_f, original_pts[1][2].to_f)
          pts[next_i]     = Geom::Point3d.new(original_pts[2][0].to_f, original_pts[2][1].to_f, original_pts[2][2].to_f)

          room_data = build_data_from_group(room_group) || {}
          old_pts = room_pts_from_group(room_group).map(&:clone)
          remove_legacy_source_floor_geometry(old_pts)
          synchronize_room_geometry(room_group, pts, room_data)
        end
      end

      remaining = shatras.reject { |s| s['uuid'].to_s == uuid_to_delete }
      save_shatras(room_group, remaining)
      rebuild_all_shatras(room_group)

      model.commit_operation
      model.active_view.invalidate
      UI.messagebox('✅ تم حذف الشطرة وإرجاع الحوائط لحالتها الأصلية')
      true
    rescue => e
      model.abort_operation rescue nil
      UI.messagebox("❌ خطأ أثناء حذف الشطرة:\n#{e.message}")
      false
    end
  end
end

# تثبيت الـPatch فوق الـEngine الأصلي
MHD_RoomBuilder_Context.singleton_class.prepend(MHD_RoomBuilder_SafeIntegration_V41)
