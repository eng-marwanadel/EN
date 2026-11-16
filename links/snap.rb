module MHDESIGN

  class ClickSideSnapTool_CornerHandles
    SIDE_LEFT  = :left
    SIDE_RIGHT = :right
    SIDE_FRONT = :front
    SIDE_BACK  = :back

    NORMAL_HANDLE_SIZE_PX = 9
    HOVER_HANDLE_SIZE_PX  = 17
    HOVER_PICK_RADIUS_PX  = 30

    def activate
      @ip = Sketchup::InputPoint.new

      @hover_inst = nil
      @hover_handles = []
      @hover_handle_index = nil

      @moving = nil
      @moving_local_point = nil
      @point_mode = false

      @esc_once = false

      Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("1) اختار مربع زاوية أو اضغط على الوحدة المتحركة")
    end

    def deactivate(view)
      Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("")
    end

    def onCancel(reason, view)
      # لو فيه اختيار حالي -> أول ESC يعمل reset فقط
      if @moving || @point_mode
        reset_state
        @hover_inst = nil
        @hover_handles = []
        @hover_handle_index = nil

        @esc_once = true

        Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("تم إلغاء الاختيار. اضغط ESC مرة أخرى للخروج")
        view.invalidate if view
        return
      end

      # لو مفيش اختيار حالي
      # أول ESC يجهز للخروج
      unless @esc_once
        @esc_once = true
        Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("اضغط ESC مرة أخرى للخروج")
        view.invalidate if view
        return
      end

      # ثاني ESC يخرج من الأداة
      Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("")
      view.invalidate if view
      Sketchup.active_model.select_tool(nil)
    end

    def reset_state
      @moving = nil
      @moving_local_point = nil
      @point_mode = false
    end

    # ==========================================
    # INPUT / HOVER
    # ==========================================
    def onMouseMove(flags, x, y, view)
      @ip.pick(view, x, y)

      inst = pick_instance(view, x, y)

      if inst
        @hover_inst = inst
        @hover_handles = build_handles_for_instance(inst, view)
        hovered = nearest_handle_to_mouse(x, y, @hover_handles, HOVER_PICK_RADIUS_PX)
        @hover_handle_index = hovered ? hovered[:index] : nil
      else
        @hover_inst = nil
        @hover_handles = []
        @hover_handle_index = nil
      end

      view.invalidate
    end

    def draw(view)
      draw_handles(view, @hover_handles, @hover_handle_index)
    end

    # ==========================================
    # PICK TOP-LEVEL INSTANCE / GROUP
    # ==========================================
    def pick_instance(view, x, y)
      ph = view.pick_helper
      ph.do_pick(x, y)
      best = ph.best_picked
      return nil unless best

      path = nil
      begin
        path = ph.path_at(0)
      rescue
        path = nil
      end

      inst = nil

      if best.is_a?(Sketchup::ComponentInstance) || best.is_a?(Sketchup::Group)
        inst = best
      elsif path
        path.reverse_each do |e|
          if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
            inst = e
            break
          end
        end
      end

      inst
    end

    # ==========================================
    # VISIBILITY / BOUNDS
    # ==========================================
    def layer_visible?(ent)
      begin
        l = ent.layer
        return true if l.nil?
        l.visible?
      rescue
        true
      end
    end

    def entity_visible?(ent)
      return false if ent.deleted?
      return false if ent.hidden?
      return false unless layer_visible?(ent)
      true
    end

    def root_entities_of(inst)
      inst.is_a?(Sketchup::ComponentInstance) ? inst.definition.entities : inst.entities
    end

    def collect_visible_points(entities, tr_accum, pts)
      entities.each do |e|
        next unless entity_visible?(e)

        case e
        when Sketchup::Face
          e.vertices.each { |vx| pts << vx.position.transform(tr_accum) }
        when Sketchup::Edge
          pts << e.start.position.transform(tr_accum)
          pts << e.end.position.transform(tr_accum)
        when Sketchup::Group
          collect_visible_points(e.entities, tr_accum * e.transformation, pts)
        when Sketchup::ComponentInstance
          collect_visible_points(e.definition.entities, tr_accum * e.transformation, pts)
        end
      end
    end

    def visible_bounds_world(inst)
      pts = []
      collect_visible_points(root_entities_of(inst), inst.transformation, pts)

      return inst.bounds if pts.empty?

      bb = Geom::BoundingBox.new
      pts.each { |p| bb.add(p) }
      bb
    end

    def visible_bbox_corners(inst)
      bb = visible_bounds_world(inst)
      [
        bb.corner(0), bb.corner(1), bb.corner(2), bb.corner(3),
        bb.corner(4), bb.corner(5), bb.corner(6), bb.corner(7)
      ]
    end

    # ==========================================
    # HANDLE UI
    # ==========================================
    def build_handles_for_instance(inst, view)
      visible_bbox_corners(inst).each_with_index.map do |pt, idx|
        sp = view.screen_coords(pt)
        {
          index: idx,
          world_point: pt,
          screen_x: sp.x,
          screen_y: sp.y
        }
      end
    end

    def screen_distance(x1, y1, x2, y2)
      Math.sqrt((x1 - x2)**2 + (y1 - y2)**2)
    end

    def point_in_handle?(x, y, handle, size_px)
      half = size_px * 0.5
      x >= (handle[:screen_x] - half) &&
      x <= (handle[:screen_x] + half) &&
      y >= (handle[:screen_y] - half) &&
      y <= (handle[:screen_y] + half)
    end

    def nearest_handle_to_mouse(x, y, handles, radius_px)
      best = nil
      best_dist = nil

      handles.each do |h|
        dist = screen_distance(x, y, h[:screen_x], h[:screen_y])
        next if dist > radius_px

        if best_dist.nil? || dist < best_dist
          best_dist = dist
          best = h
        end
      end

      best
    end

    def pick_handle_at(x, y, handles, hover_index = nil)
      if !hover_index.nil?
        h = handles.find { |item| item[:index] == hover_index }
        return h if h && point_in_handle?(x, y, h, HOVER_HANDLE_SIZE_PX)
      end

      handles.find { |h| point_in_handle?(x, y, h, NORMAL_HANDLE_SIZE_PX) }
    end

    def draw_square_handle(view, sx, sy, size_px, hovered = false)
      half = size_px * 0.5

      p1 = Geom::Point3d.new(sx - half, sy - half, 0)
      p2 = Geom::Point3d.new(sx + half, sy - half, 0)
      p3 = Geom::Point3d.new(sx + half, sy + half, 0)
      p4 = Geom::Point3d.new(sx - half, sy + half, 0)

      view.drawing_color = hovered ? 'orange' : 'red'
      view.draw2d(GL_QUADS, [p1, p2, p3, p4])

      view.drawing_color = 'white'
      view.draw2d(GL_LINE_LOOP, [p1, p2, p3, p4])
    end

    def draw_handles(view, handles, hover_index = nil)
      return if handles.nil? || handles.empty?

      handles.each do |h|
        hovered = (!hover_index.nil? && h[:index] == hover_index)
        size = hovered ? HOVER_HANDLE_SIZE_PX : NORMAL_HANDLE_SIZE_PX
        draw_square_handle(view, h[:screen_x], h[:screen_y], size, hovered)
      end
    end

    # ==========================================
    # SIDE SNAP LOGIC
    # ==========================================
    def decide_side(target_bb, click_pt)
      dx_min = (click_pt.x - target_bb.min.x).abs
      dx_max = (target_bb.max.x - click_pt.x).abs
      dy_min = (click_pt.y - target_bb.min.y).abs
      dy_max = (target_bb.max.y - click_pt.y).abs

      [
        [SIDE_LEFT,  dx_min],
        [SIDE_RIGHT, dx_max],
        [SIDE_BACK,  dy_min],
        [SIDE_FRONT, dy_max]
      ].min_by { |_, v| v }[0]
    end

    def translation_for_side(bm, bt, side)
      dz = bt.min.z - bm.min.z

      case side
      when SIDE_RIGHT
        Geom::Vector3d.new(
          bt.max.x - bm.min.x,
          bt.center.y - bm.center.y,
          dz
        )
      when SIDE_LEFT
        Geom::Vector3d.new(
          bt.min.x - bm.max.x,
          bt.center.y - bm.center.y,
          dz
        )
      when SIDE_FRONT
        Geom::Vector3d.new(
          bt.center.x - bm.center.x,
          bt.max.y - bm.min.y,
          dz
        )
      else
        Geom::Vector3d.new(
          bt.center.x - bm.center.x,
          bt.min.y - bm.max.y,
          dz
        )
      end
    end

    # ==========================================
    # ROTATION
    # ==========================================
    def flat_vector(vec)
      v = Geom::Vector3d.new(vec.x, vec.y, 0)
      return nil if v.length == 0
      v.normalize
    rescue
      nil
    end

    def yaw_angle_deg_from_vector(vec)
      v = flat_vector(vec)
      return 0.0 unless v
      Math.atan2(v.y, v.x) * 180.0 / Math::PI
    end

    def normalize_deg(deg)
      d = deg % 360.0
      d += 360.0 if d < 0
      d
    end

    def normalize_signed_deg(deg)
      d = normalize_deg(deg)
      d -= 360.0 if d > 180.0
      d
    end

    def snap_angle_to_45(deg)
      candidates = [0, 45, 90, 135, 180, 225, 270, 315]
      candidates.min_by { |a| normalize_signed_deg(deg - a).abs }
    end

    def front_direction_world(inst)
      flat_vector(inst.transformation.yaxis)
    end

    # ==========================================
    # MHD ROOM BUILDER WALL SUPPORT
    # ==========================================
    def mhd_wall?(entity)
      return false unless entity.respond_to?(:get_attribute)
      entity.get_attribute('MHD_ROOM_BUILDER', 'النوع').to_s == 'حائط'
    rescue
      false
    end

    def parse_mhd_point(value)
      parts = value.to_s.split('|').map(&:to_f)
      return nil unless parts.length == 3
      Geom::Point3d.new(parts[0], parts[1], parts[2])
    rescue
      nil
    end

    # Returns the clicked MHD wall and its accumulated world transformation.
    # This also works while the wall is nested inside the Room Builder group.
    def picked_mhd_wall(view, x, y)
      ph = view.pick_helper
      ph.do_pick(x, y)

      [ph.count, 1].max.times do |index|
        path = ph.path_at(index) rescue nil
        next unless path

        accumulated = Geom::Transformation.new
        path.each do |entity|
          if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
            accumulated = accumulated * entity.transformation
            return [entity, accumulated] if mhd_wall?(entity)
          end
        end
      end
      nil
    rescue
      nil
    end

    def wall_line_world(wall, wall_tr)
      p1 = parse_mhd_point(wall.get_attribute('MHD_ROOM_BUILDER', 'P1'))
      p2 = parse_mhd_point(wall.get_attribute('MHD_ROOM_BUILDER', 'P2'))
      return nil unless p1 && p2

      a = p1.transform(wall_tr)
      b = p2.transform(wall_tr)
      direction = a.vector_to(b)
      return nil if direction.length < 0.1.mm
      direction.normalize!

      # Room Builder normalizes the floor outline CCW. Its interior is therefore
      # the left side of P1 -> P2, while wall thickness is built to the right.
      inward = Geom::Vector3d.new(0, 0, 1).cross(direction)
      inward.normalize!
      [a, b, direction, inward]
    rescue
      nil
    end

    def projection_on_axis(point, axis)
      point.x * axis.x + point.y * axis.y + point.z * axis.z
    end

    def closest_point_on_segment(point, a, b)
      ab = a.vector_to(b)
      length_sq = ab.dot(ab)
      return a if length_sq <= 0.0
      t = a.vector_to(point).dot(ab) / length_sq
      t = [[t, 0.0].max, 1.0].min
      Geom::Point3d.new(
        a.x + (ab.x * t),
        a.y + (ab.y * t),
        a.z + (ab.z * t)
      )
    end

    def align_front_to_vector!(inst, desired_front)
      current = front_direction_world(inst)
      desired = flat_vector(desired_front)
      raise MHDESIGN::Language.for_tool('snap').t('TEXT_DFE41AEE4C95') unless current && desired

      delta = normalize_signed_deg(
        yaw_angle_deg_from_vector(desired) - yaw_angle_deg_from_vector(current)
      )
      rotate_instance_about_center_z!(inst, delta)
    end

    def attach_moving_to_wall!(moving, wall, wall_tr, clicked_point)
      line = wall_line_world(wall, wall_tr)
      raise MHDESIGN::Language.for_tool('snap').t('TEXT_8EF3DF31FA70') unless line
      a, b, tangent, inward = line

      # In MHDESIGN units the local +Y axis points toward the back.
      # Point it toward the wall so the visible front faces the room.
      back_direction = Geom::Vector3d.new(-inward.x, -inward.y, 0)
      align_front_to_vector!(moving, back_direction)

      corners = visible_bbox_corners(moving)
      front_values = corners.map { |p| projection_on_axis(p, inward) }
      side_values  = corners.map { |p| projection_on_axis(p, tangent) }
      back_value   = front_values.min
      side_center  = (side_values.min + side_values.max) * 0.5

      anchor = closest_point_on_segment(clicked_point, a, b)
      target_front_value = projection_on_axis(anchor, inward)
      target_side_value  = projection_on_axis(anchor, tangent)

      normal_delta = target_front_value - back_value
      side_delta = target_side_value - side_center
      move_vec = Geom::Vector3d.new(
        (inward.x * normal_delta) + (tangent.x * side_delta),
        (inward.y * normal_delta) + (tangent.y * side_delta),
        0.0 # Keep the current level for base, wall and tall units.
      )

      moving.transform!(Geom::Transformation.translation(move_vec))
    end

    def rotate_instance_about_center_z!(inst, angle_deg)
      return if angle_deg.to_f.abs < 0.001

      bb = visible_bounds_world(inst)
      center = bb.center
      axis = Geom::Vector3d.new(0, 0, 1)
      tr = Geom::Transformation.rotation(center, axis, angle_deg.degrees)
      inst.transform!(tr)
    end

    def align_moving_orientation_to_target!(moving, target)
      moving_front = front_direction_world(moving)
      target_front = front_direction_world(target)

      return if moving_front.nil? || target_front.nil?

      moving_ang = yaw_angle_deg_from_vector(moving_front)
      target_ang = yaw_angle_deg_from_vector(target_front)

      delta = normalize_signed_deg(target_ang - moving_ang)
      snapped_delta = snap_angle_to_45(delta)

      rotate_instance_about_center_z!(moving, snapped_delta)
    end

    # ==========================================
    # MAIN CLICK
    # ==========================================
    def onLButtonDown(flags, x, y, view)
      @ip.pick(view, x, y)
      @esc_once = false

      inst = pick_instance(view, x, y)
      wall_pick = @moving ? picked_mhd_wall(view, x, y) : nil
      return unless inst || wall_pick

      handles = inst ? build_handles_for_instance(inst, view) : []
      hovered = nearest_handle_to_mouse(x, y, handles, HOVER_PICK_RADIUS_PX)
      hover_index = hovered ? hovered[:index] : nil
      clicked_handle = pick_handle_at(x, y, handles, hover_index)

      picked_world_point = begin
        @ip.position
      rescue
        nil
      end

      if @moving.nil?
        @moving = inst

        if clicked_handle
          @moving_local_point = clicked_handle[:world_point].transform(inst.transformation.inverse)
          @point_mode = true
          Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("2) اختار مربع الزاوية في الوحدة الهدف")
        else
          @moving_local_point = nil
          @point_mode = false
          Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("2) اختار وحدة هدف أو اضغط على الحائط لنقل الوحدة إليه")
        end

        view.invalidate
        return
      end

      moving = @moving
      target = inst

      if moving == target && wall_pick.nil?
        Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("اختار وحدة مختلفة.")
        return
      end

      model = Sketchup.active_model
      model.start_operation("Corner Handles Snap Tool", true)

      begin
        if wall_pick && !@point_mode
          wall, wall_tr = wall_pick
          raise MHDESIGN::Language.for_tool('snap').t('TEXT_38176C77FCE4') if picked_world_point.nil?
          attach_moving_to_wall!(moving, wall, wall_tr, picked_world_point)
        else
          raise MHDESIGN::Language.for_tool('snap').t('TEXT_B1792BAA9FC2') unless target
          align_moving_orientation_to_target!(moving, target)

          if @point_mode
            unless clicked_handle
              raise "#{MHDESIGN::Language.for_tool('snap').t('TEXT_4023E08B2FA4')}"
            end

            target_world_point = clicked_handle[:world_point]
            moving_world_point_after_rotate = @moving_local_point.transform(moving.transformation)

            move_vec = target_world_point - moving_world_point_after_rotate
            moving.transform!(Geom::Transformation.translation(move_vec))
          else
            raise "#{MHDESIGN::Language.for_tool('snap').t('TEXT_8E7AFBDE6219')}" if picked_world_point.nil?

            bt_before = visible_bounds_world(target)
            side = decide_side(bt_before, picked_world_point)

            bm = visible_bounds_world(moving)
            bt = visible_bounds_world(target)

            move_vec = translation_for_side(bm, bt, side)
            moving.transform!(Geom::Transformation.translation(move_vec))
          end
        end

        model.commit_operation
        Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("✅ تم اللصق")
      rescue => e
        model.abort_operation
        UI.messagebox("❌ #{e.message}")
      ensure
        reset_state
        view.invalidate
        Sketchup.status_text = MHDESIGN::Language.for_tool('snap').translate_source("1) اختار مربع زاوية أو اضغط على الوحدة المتحركة")
      end
    end
  end

  def self.activate_click_side_snap_tool
    Sketchup.active_model.select_tool(ClickSideSnapTool_CornerHandles.new)
  end

end

MHDESIGN.activate_click_side_snap_tool
