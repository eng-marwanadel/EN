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
require 'sketchup.rb'
require File.join(__dir__, 'MHDESIGN_Language') unless defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:for_tool)
require 'json'
require 'cgi'
require 'base64'
require 'fileutils'
require 'digest'
require 'uri'

module MHDESIGN
  module KitchenLevelsMaterials
    extend self

    PLUGIN_NAME = 'MHDESIGN Kitchen Levels & Materials'.freeze
    VERSION = '1.0.69'.freeze
    DC_DICT = 'dynamic_attributes'.freeze
    MODEL_DICT = 'MHDESIGN_KITCHEN_LEVELS'.freeze
    LEVELS_KEY = 'levels_json'.freeze
    UNIT_LEVEL_ID_KEY = 'unit_level_id'.freeze
    UNIT_LEVEL_NAME_KEY = 'unit_level_name'.freeze
    UNIT_LEVEL_ISOLATION_KEY = 'unit_level_geometry_isolation'.freeze
    PREF_KEY = 'materials_folder'.freeze
    LOGO_URL = 'https://raw.githubusercontent.com/eng-marwanadel/EN/refs/heads/main/links/logo3.png'.freeze
    SUPPORTED_IMAGES = %w[.jpg .jpeg .png .bmp .tif .tiff].freeze

    MATERIAL_TARGETS = {
      'door' => ['خامة الضلفه', 'خامة الضلفة', 'خامة الضلفه العلويه', 'خامة الضلفه السفليه'],
      'carcass' => ['خامة الشاسيه'],
      'back' => ['خامة الضهر', 'خامة الظهر'],
      'drawer' => [
        'خامة وش الدرج', 'خامة وجه الدرج', 'خامة واجهة الدرج',
        'خامة وش الأدراج', 'خامة وجه الأدراج', 'خامة واجهة الأدراج'
      ]
    }.freeze

    # أسماء خامات شريط الضلفة الثابتة.
    # لا يتم تغيير الاسم؛ يتم نسخ اللون والصورة والمقاس فقط.
    DOOR_BAND_MATERIAL_NAMES = [
      'شريط حرف لون علوي',
      'شريط حرف لون سفلي',
      'شريط حرف لون دولاب'
    ].freeze

    CHASSIS_BAND_MATERIAL_NAMES = [
      'شريط حرف ابيض'
    ].freeze

    @dialog = nil
    @material_cache = {}
    @expanded = false
    @level_watch_timer = nil
    @level_watch_signature = nil
    @level_watch_busy = false
    @level_model_observer = nil
    @level_observed_model = nil
    @level_reconcile_timer = nil
    @texture_rotate_tool = nil
    @presentation_mode_active = false
    @presentation_watch_timer = nil
    @presentation_hidden_entities = []
    @presentation_rendering_state = nil
    @presentation_camera_signature = nil
    @presentation_model = nil
    @presentation_world_bounds = {}
    @presentation_world_transforms = {}
    @presentation_countertop_back_bounds = {}
    @presentation_scene_cache = nil
    @presentation_last_facing_key = nil
    @presentation_paused_dialog_watchers = false
    @presentation_operation_open = false
    @presentation_awaiting_selection = false
    @presentation_scope_roots = []

    COLLAPSED_WIDTH = 520
    EXPANDED_WIDTH  = 980
    DIALOG_HEIGHT   = 720
    SIZE_PREF_PREFIX = 'dialog_size'.freeze
    ROOM_BUILDER_DICT = 'MHD_ROOM_BUILDER'.freeze
    COUNTERTOP_DICT = 'MHD_COUNTERTOP_ENGINE'.freeze
    PRESENTATION_TEMP_DICT = 'MHDESIGN_PRESENTATION_TEMP'.freeze
    PRESENTATION_HIDDEN_KEY = 'hidden_by_view_mode'.freeze

    # --------------------------- Helpers ---------------------------

    def dc
      return nil unless defined?($dc_observers) && $dc_observers
      $dc_observers.get_latest_class
    rescue
      nil
    end

    def normalize_ar(text)
      s = text.to_s.dup
      s = s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      s = s.gsub(/%u([0-9A-Fa-f]{4})/) { [$1.hex].pack('U') }
      s = CGI.unescape(s) rescue s
      s = s.gsub(/<[^>]*>/, ' ')
      s = s.tr('أإآٱ', 'اااا')
      s = s.tr('ةى', 'هي')
      s = s.gsub(/[ًٌٍَُِّْـ]/, '')
      s.gsub(/\s+/, '').downcase
    rescue
      text.to_s.downcase.gsub(/\s+/, '')
    end

    def entity_pid(ent)
      ent.respond_to?(:persistent_id) ? ent.persistent_id.to_i : ent.entityID.to_i
    rescue
      0
    end

    def selected_components
      Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
    rescue
      []
    end

    def html_escape(text)
      CGI.escapeHTML(text.to_s)
    end

    def js_json(obj)
      JSON.generate(obj).gsub('</', '<\\/')
    end

    def file_url(path)
      normalized = File.expand_path(path).tr('\\', '/')
      normalized = "/#{normalized}" if normalized =~ /\A[A-Za-z]:\//
      URI::DEFAULT_PARSER.escape("file://#{normalized}", /[^#{URI::PATTERN::UNRESERVED}\/\:\.\-]/)
    rescue
      "file:///#{File.expand_path(path).tr('\\', '/')}"
    end

    def current_model
      Sketchup.active_model
    end

    # --------------------------- Presentation mode ---------------------------

    def room_builder_type(entity)
      entity.get_attribute(ROOM_BUILDER_DICT, 'النوع').to_s.strip
    rescue
      ''
    end

    def room_builder_wall?(entity)
      room_builder_type(entity) == 'حائط'
    rescue
      false
    end

    def room_builder_room?(entity)
      room_builder_type(entity) == 'غرفة'
    rescue
      false
    end

    def room_builder_ceiling?(entity)
      room_builder_type(entity) == 'سقف'
    rescue
      false
    end

    # الحوائط التي تنشئها أداة بناء الغرفة ليست في model.entities مباشرة؛
    # بل Components داخل Group الغرفة. لذلك ندخل الحاويات ونقرأ العلامة
    # MHD_ROOM_BUILDER / النوع بدل تخمين الحائط من الشكل فقط.
    def presentation_transform_bounds(bounds, transformation)
      transformed = Geom::BoundingBox.new
      8.times { |index| transformed.add(bounds.corner(index).transform(transformation)) }
      transformed
    rescue
      bounds
    end

    def remember_presentation_bounds(entity, bounds)
      @presentation_world_bounds ||= {}
      @presentation_world_bounds[entity_pid(entity)] = bounds
      bounds
    rescue
      bounds
    end

    def remember_presentation_transform(entity, transformation)
      @presentation_world_transforms ||= {}
      @presentation_world_transforms[entity_pid(entity)] = transformation
      transformation
    rescue
      transformation
    end

    def presentation_entity_bounds(entity)
      cached = @presentation_world_bounds && @presentation_world_bounds[entity_pid(entity)]
      cached || entity.bounds
    rescue
      entity.bounds
    end

    def presentation_entity_transform(entity)
      cached = @presentation_world_transforms && @presentation_world_transforms[entity_pid(entity)]
      cached || entity.transformation
    rescue
      Geom::Transformation.new
    end

    def kitchen_library_unit?(entity)
      definition_name = MHDESIGN::Language.original_definition_name(entity.definition).to_s rescue ''
      instance_name = entity.name.to_s rescue ''
      token = "#{definition_name} #{instance_name}".downcase.gsub(/[^a-z0-9_]/, '')
      token.include?('base_unit') || token.include?('wall_unit') || token.include?('tall_unit')
    rescue
      false
    end

    def collect_room_builder_walls(entities, result = [], parent_transform = Geom::Transformation.new, depth = 0)
      return result if depth > 14
      Array(entities).each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
        next unless entity.valid?

        world_transform = parent_transform * entity.transformation
        remember_presentation_transform(entity, world_transform)

        if room_builder_wall?(entity)
          world_bounds = presentation_transform_bounds(entity.definition.bounds, world_transform)
          remember_presentation_bounds(entity, world_bounds)
          result << entity unless result.include?(entity)
          next
        end

        definition = entity.definition rescue nil
        next unless definition
        collect_room_builder_walls(definition.entities.to_a, result, world_transform, depth + 1)
      rescue
      end
      result
    rescue
      result || []
    end

    def collect_room_builder_ceilings(entities, result = [], depth = 0)
      return result if depth > 14
      Array(entities).each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
        next unless entity.valid?
        if room_builder_ceiling?(entity)
          result << entity unless result.include?(entity)
          next
        end
        definition = entity.definition rescue nil
        collect_room_builder_ceilings(definition.entities.to_a, result, depth + 1) if definition
      rescue
      end
      result
    rescue
      result || []
    end

    # وحدات المكتبة قد تكون داخل Group أو Component جامع. نلتقط الوحدة الأم
    # من اسم تعريفها المعروف، ولا ندخل داخلها حتى لا نعامل قطع الشاسيه كوحدات.
    def collect_kitchen_library_units(entities, result = [], parent_transform = Geom::Transformation.new, depth = 0)
      return result if depth > 14
      Array(entities).each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
        next unless entity.valid?
        next if room_builder_wall?(entity)

        world_transform = parent_transform * entity.transformation
        remember_presentation_transform(entity, world_transform)
        if kitchen_library_unit?(entity)
          world_bounds = presentation_transform_bounds(entity.definition.bounds, world_transform)
          remember_presentation_bounds(entity, world_bounds)
          result << entity unless result.include?(entity)
          next
        end

        definition = entity.definition rescue nil
        next unless definition
        collect_kitchen_library_units(definition.entities.to_a, result, world_transform, depth + 1)
      rescue
      end
      result
    rescue
      result || []
    end

    # كل اتجاه رخامة Group مستقل ومعلّم من أداة الرخام. نلتقط الـGroup الأم
    # فقط حتى تختفي الرخامة بسطحها ووزراتها كوحدة واحدة.
    def collect_countertops(entities, result = [], parent_transform = Geom::Transformation.new, depth = 0)
      return result if depth > 14
      Array(entities).each do |entity|
        next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
        next unless entity.valid?
        world_transform = parent_transform * entity.transformation
        remember_presentation_transform(entity, world_transform)
        if countertop_entity?(entity)
          world_bounds = presentation_transform_bounds(entity.definition.bounds, world_transform)
          remember_presentation_bounds(entity, world_bounds)
          result << entity unless result.include?(entity)
          next
        end
        definition = entity.definition rescue nil
        collect_countertops(definition.entities.to_a, result, world_transform, depth + 1) if definition
      rescue
      end
      result
    rescue
      result || []
    end

    # يجمع الوحدات والأجهزة الرئيسية، ويضيف إليها الحوائط الحقيقية الموجودة
    # داخل Group الغرفة. Group الغرفة نفسه لا يدخل ضمن العناصر المرشحة حتى
    # لا يؤدي إخفاؤه إلى اختفاء الأرضية والحوائط المقابلة كلها.
    def presentation_candidates(model = current_model, source_entities = nil)
      @presentation_world_bounds = {}
      @presentation_world_transforms = {}
      @presentation_countertop_back_bounds = {}
      source = Array(source_entities || model.entities.to_a)
      roots = source.select do |entity|
        (entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)) &&
          entity.valid? && !entity.hidden? && entity.layer.visible? &&
          !room_builder_room?(entity)
      end
      roots.each do |entity|
        remember_presentation_bounds(entity, entity.bounds)
        remember_presentation_transform(entity, entity.transformation)
      end
      walls = collect_room_builder_walls(source).select do |wall|
        wall.valid? && !wall.hidden? && wall.layer.visible?
      end
      units = collect_kitchen_library_units(source).select do |unit|
        unit.valid? && !unit.hidden? && unit.layer.visible?
      end
      countertops = collect_countertops(source).select do |countertop|
        countertop.valid? && !countertop.hidden? && countertop.layer.visible?
      end
      (roots + walls + units + countertops).uniq
    rescue
      []
    end

    def presentation_bounds(entities)
      bounds = Geom::BoundingBox.new
      entities.each { |entity| bounds.add(presentation_entity_bounds(entity)) if entity.valid? }
      bounds
    rescue
      nil
    end

    def presentation_camera_signature
      camera = current_model.active_view.camera
      eye = camera.eye
      direction = camera.direction
      [eye.x, eye.y, eye.z, direction.x, direction.y, direction.z].map { |v| v.to_f.round(3) }
    rescue
      nil
    end

    def save_presentation_rendering_state(model)
      options = model.rendering_options
      keys = %w[BackgroundColor DisplaySketchAxes DrawGround DrawHorizon]
      @presentation_rendering_state = {}
      keys.each do |key|
        @presentation_rendering_state[key] = options[key]
      rescue
      end
    end

    def apply_presentation_rendering(model)
      options = model.rendering_options
      options['BackgroundColor'] = Sketchup::Color.new(255, 255, 255)
      options['DisplaySketchAxes'] = false
      options['DrawGround'] = false
      options['DrawHorizon'] = false
      model.active_view.invalidate
    rescue => e
      puts "MHDESIGN Presentation Rendering Warning: #{e.message}"
    end

    def restore_presentation_rendering(model)
      return unless @presentation_rendering_state
      options = model.rendering_options
      @presentation_rendering_state.each do |key, value|
        options[key] = value
      rescue
      end
      model.active_view.invalidate
    rescue => e
      puts "MHDESIGN Restore Presentation Rendering Warning: #{e.message}"
    ensure
      @presentation_rendering_state = nil
    end

    def restore_presentation_hidden_entities
      Array(@presentation_hidden_entities).each do |entity|
        if entity && entity.valid?
          entity.hidden = false
          entity.delete_attribute(PRESENTATION_TEMP_DICT, PRESENTATION_HIDDEN_KEY) rescue nil
        end
      rescue
      end
      @presentation_hidden_entities = []
    end

    def recover_presentation_entities(entities, visited = {})
      recovered = 0
      Array(entities).each do |entity|
        next unless entity.respond_to?(:valid?) && entity.valid?
        marked = entity.get_attribute(PRESENTATION_TEMP_DICT, PRESENTATION_HIDDEN_KEY, false) rescue false
        if marked
          entity.hidden = false if entity.respond_to?(:hidden=)
          entity.delete_attribute(PRESENTATION_TEMP_DICT, PRESENTATION_HIDDEN_KEY) rescue nil
          recovered += 1
        end

        next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
        definition = entity.definition rescue nil
        next unless definition
        key = definition.object_id
        next if visited[key]
        visited[key] = true
        recovered += recover_presentation_entities(definition.entities.to_a, visited)
      rescue
      end
      recovered
    rescue
      0
    end

    # شبكة أمان لو توقف الملف أو أُغلق بشكل غير طبيعي: أي عنصر يحمل علامة
    # الإخفاء المؤقت يرجع عند فتح الأداة في المرة التالية.
    def recover_stale_presentation_state(model = current_model)
      marked_exists = false
      finder = lambda do |entities, visited|
        Array(entities).each do |entity|
          if (entity.get_attribute(PRESENTATION_TEMP_DICT, PRESENTATION_HIDDEN_KEY, false) rescue false)
            marked_exists = true
            break
          end
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          definition = entity.definition rescue nil
          next unless definition
          key = definition.object_id
          next if visited[key]
          visited[key] = true
          finder.call(definition.entities.to_a, visited)
          break if marked_exists
        end
      end
      finder.call(model.entities.to_a, {})
      return 0 unless marked_exists

      model.start_operation('MHDESIGN Recover Presentation View', true)
      count = recover_presentation_entities(model.entities.to_a, {})
      model.commit_operation
      model.active_view.invalidate
      count
    rescue => e
      model.abort_operation rescue nil
      puts "MHDESIGN Presentation Recovery Warning: #{e.message}"
      0
    end

    # الحائط المقصود عنصر رأسي طويل ورفيع. هذا يمنع اعتبار وحدات المطبخ
    # نفسها حوائط، حتى لو كانت وحدات طويلة أو مجموعة من الوحدات.
    def presentation_wall?(entity)
      return true if room_builder_wall?(entity)

      bounds = presentation_entity_bounds(entity)
      size_x = bounds.width.to_f
      size_y = bounds.depth.to_f
      size_z = bounds.height.to_f
      thickness = [size_x, size_y].min
      length = [size_x, size_y].max
      return false if size_z < 150.cm
      return false if length < 120.cm
      return false if thickness > 45.cm
      return false if thickness > 0.001 && (length / thickness) < 3.0

      true
    rescue
      false
    end

    def presentation_wall_axis(wall)
      bounds = presentation_entity_bounds(wall)
      bounds.width <= bounds.depth ? :x : :y
    rescue
      :x
    end

    def presentation_wall_candidates(entities)
      Array(entities).select { |entity| presentation_wall?(entity) }
    end

    # منطق Dollhouse: نعتمد على مكان الكاميرا حول صندوق الغرفة، لا على أول
    # شعاع يصطدم بحائط. المواجهة المباشرة تخفي جانبًا واحدًا، والوقوف عند
    # ركن يخفي الجانبين القريبين من الكاميرا معًا مثل الصور المرجعية.
    def presentation_facing_walls(walls, camera)
      walls = Array(walls)
      return [] if walls.empty?

      room_bounds = Geom::BoundingBox.new
      walls.each { |wall| room_bounds.add(presentation_entity_bounds(wall)) if wall && wall.valid? }
      center = room_bounds.center
      eye = camera.eye
      span_x = [room_bounds.width.to_f, 1.0].max
      span_y = [room_bounds.depth.to_f, 1.0].max
      offset_x = eye.x.to_f - center.x.to_f
      offset_y = eye.y.to_f - center.y.to_f

      # التطبيع يجعل القرار ثابتًا في المطابخ المستطيلة، فلا يطغى طول الغرفة
      # على اتجاه الكاميرا حولها.
      weight_x = offset_x.abs / span_x
      weight_y = offset_y.abs / span_y
      strongest = [weight_x, weight_y].max
      return [] if strongest < 0.01

      # الجانب الثاني يظهر عند الاقتراب من الركن. النسبة تمنع اهتزاز الاختيار
      # بسبب حركة صغيرة أثناء النظر شبه المباشر إلى أحد الحوائط.
      corner_ratio = 0.32
      use_x = weight_x >= strongest * corner_ratio
      use_y = weight_y >= strongest * corner_ratio
      selected = []

      if use_x
        x_walls = walls.select { |wall| presentation_wall_axis(wall) == :x }
        unless x_walls.empty?
          centers = x_walls.map { |wall| presentation_entity_bounds(wall).center.x.to_f }
          extreme = offset_x < 0.0 ? centers.min : centers.max
          tolerance = [35.cm.to_f, span_x * 0.08].max
          selected.concat(x_walls.select { |wall| (presentation_entity_bounds(wall).center.x.to_f - extreme).abs <= tolerance })
        end
      end

      if use_y
        y_walls = walls.select { |wall| presentation_wall_axis(wall) == :y }
        unless y_walls.empty?
          centers = y_walls.map { |wall| presentation_entity_bounds(wall).center.y.to_f }
          extreme = offset_y < 0.0 ? centers.min : centers.max
          tolerance = [35.cm.to_f, span_y * 0.08].max
          selected.concat(y_walls.select { |wall| (presentation_entity_bounds(wall).center.y.to_f - extreme).abs <= tolerance })
        end
      end

      selected.uniq
    rescue => e
      puts "MHDESIGN Facing Walls Warning: #{e.message}"
      []
    end

    def presentation_interval_gap(min_a, max_a, min_b, max_b)
      return min_b - max_a if max_a < min_b
      return min_a - max_b if max_b < min_a
      0.0
    end

    # محور Y في وحدات المكتبة هو محور العمق (من الظهر إلى الواجهة). لكي تكون
    # الوحدة بظهرها إلى الحائط يجب أن يكون محور العمق موازيًا لاتجاه عمود
    # الحائط. لو محور العرض هو المتجه للحائط فهذا يعني أنها ملامسة بجنبها،
    # وبالتالي تظل ظاهرة.
    def presentation_unit_back_faces_wall?(entity, wall)
      transformation = presentation_entity_transform(entity)
      depth_axis = transformation.yaxis
      horizontal_length = Math.sqrt((depth_axis.x.to_f ** 2) + (depth_axis.y.to_f ** 2))
      return true if horizontal_length < 0.0001

      wall_axis = presentation_wall_axis(wall)
      normal_component = wall_axis == :x ? depth_axis.x.to_f.abs : depth_axis.y.to_f.abs
      alignment = normal_component / horizontal_length
      alignment >= 0.75
    rescue
      true
    end

    # أداة الرخام تنشئ كل اتجاه كـGroup بهندسة عالمية، لذلك محاور الـGroup
    # لا تعبّر عن اتجاهه. البعد الأفقي الأقصر هو عمق الرخامة، ويجب أن يوازي
    # عمود الحائط حتى تكون الرخامة بظهرها إليه وليست ملامسة بجنبها.
    def presentation_countertop_back_faces_wall?(entity, wall)
      bounds = presentation_countertop_back_bounds(entity) || presentation_entity_bounds(entity)
      depth_axis = bounds.width.to_f <= bounds.depth.to_f ? :x : :y
      depth_axis == presentation_wall_axis(wall)
    rescue
      false
    end

    # الوزرة الخلفية هي المرجع الحقيقي لظهر قطعة الرخام. موقعها يحسم أي
    # حيطة تتبع لها القطعة حتى في المطابخ L/U ذات قطعتين أو أكثر.
    def presentation_countertop_back_bounds(entity)
      @presentation_countertop_back_bounds ||= {}
      key = entity_pid(entity)
      return @presentation_countertop_back_bounds[key] if @presentation_countertop_back_bounds.key?(key)

      parent_transform = presentation_entity_transform(entity)
      found = nil
      definition = entity.definition rescue nil
      if definition
        definition.entities.to_a.each do |child|
          next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
          role = child.get_attribute(COUNTERTOP_DICT, 'الدور').to_s.strip rescue ''
          next unless role == 'وزرة خلفية'
          child_transform = parent_transform * child.transformation
          found = presentation_transform_bounds(child.definition.bounds, child_transform)
          break
        rescue
        end
      end

      @presentation_countertop_back_bounds[key] = found
      found
    rescue
      nil
    end

    def presentation_attachment_bounds(entity)
      if countertop_entity?(entity)
        presentation_countertop_back_bounds(entity) || presentation_entity_bounds(entity)
      else
        presentation_entity_bounds(entity)
      end
    rescue
      presentation_entity_bounds(entity)
    end

    def presentation_back_faces_wall?(entity, wall)
      if countertop_entity?(entity)
        presentation_countertop_back_faces_wall?(entity, wall)
      else
        presentation_unit_back_faces_wall?(entity, wall)
      end
    rescue
      false
    end

    # يربط كل وحدة أو جهاز بأقرب حائط من ناحية الظهر. يجب أن يكون العنصر
    # داخل امتداد الحائط وألا يبتعد عنه بأكثر من عمق وحدة مطبخ كبير.
    def presentation_attached_entities(target_wall, walls, entities)
      wall_ids = Array(walls).map { |wall| entity_pid(wall) }
      assignments = {}

      Array(entities).each do |entity|
        next if wall_ids.include?(entity_pid(entity))
        bounds = presentation_entity_bounds(entity)
        best_wall = nil
        best_distance = nil

        Array(walls).each do |wall|
          wall_bounds = presentation_entity_bounds(wall)
          axis = presentation_wall_axis(wall)
          next unless presentation_back_faces_wall?(entity, wall)

          normal_gap = if axis == :x
                         presentation_interval_gap(bounds.min.x, bounds.max.x, wall_bounds.min.x, wall_bounds.max.x)
                       else
                         presentation_interval_gap(bounds.min.y, bounds.max.y, wall_bounds.min.y, wall_bounds.max.y)
                       end

          length_gap = if axis == :x
                         presentation_interval_gap(bounds.min.y, bounds.max.y, wall_bounds.min.y, wall_bounds.max.y)
                       else
                         presentation_interval_gap(bounds.min.x, bounds.max.x, wall_bounds.min.x, wall_bounds.max.x)
                       end

          max_normal_gap = countertop_entity?(entity) ? 220.cm : 110.cm
          next if normal_gap > max_normal_gap
          next if length_gap > 25.cm

          # الأفضلية لأقل مسافة عمودية عن سطح الحائط؛ فرق الطول يستخدم فقط
          # لكسر التعادل عند الأركان.
          score = normal_gap.to_f + (length_gap.to_f * 2.0)
          if best_distance.nil? || score < best_distance
            best_distance = score
            best_wall = wall
          end
        rescue
        end

        assignments[entity_pid(entity)] = best_wall if best_wall
      rescue
      end

      Array(entities).select do |entity|
        wall = assignments[entity_pid(entity)]
        wall && entity_pid(wall) == entity_pid(target_wall)
      end
    rescue
      []
    end

    # الرخام والحوض والفرش والأجهزة لا تحتاج شرط اتجاه الظهر؛ يكفي وجودها
    # داخل الشريحة القريبة من الحائط المواجه للكاميرا حتى لا تحجب العرض.
    def presentation_generic_near_wall(target_wall, entities)
      wall_bounds = presentation_entity_bounds(target_wall)
      axis = presentation_wall_axis(target_wall)
      Array(entities).select do |entity|
        bounds = presentation_attachment_bounds(entity)
        normal_gap = if axis == :x
                       presentation_interval_gap(bounds.min.x, bounds.max.x, wall_bounds.min.x, wall_bounds.max.x)
                     else
                       presentation_interval_gap(bounds.min.y, bounds.max.y, wall_bounds.min.y, wall_bounds.max.y)
                     end
        length_gap = if axis == :x
                       presentation_interval_gap(bounds.min.y, bounds.max.y, wall_bounds.min.y, wall_bounds.max.y)
                     else
                       presentation_interval_gap(bounds.min.x, bounds.max.x, wall_bounds.min.x, wall_bounds.max.x)
                     end
        normal_gap <= 140.cm && length_gap <= 25.cm
      rescue
        false
      end
    rescue
      []
    end

    # الفحص الثقيل للموديل والـGroups يتم مرة واحدة فقط عند تشغيل الوضع.
    # النتيجة تحتوي الحوائط والوحدات المرتبطة بكل حائط وجميع الـBounds
    # المحسوبة في إحداثيات الموديل.
    def build_presentation_scene_cache(model = current_model)
      source = Array(@presentation_scope_roots)
      entities = presentation_candidates(model, source)
      walls = presentation_wall_candidates(entities)
      attached_by_wall = {}
      wall_ids = walls.map { |wall| entity_pid(wall) }
      oriented = entities.select { |entity| kitchen_library_unit?(entity) || countertop_entity?(entity) }
      generic = entities.reject do |entity|
        wall_ids.include?(entity_pid(entity)) || kitchen_library_unit?(entity) || countertop_entity?(entity) ||
          room_builder_type(entity) != ''
      end
      generic_by_wall = {}
      walls.each do |wall|
        attached_by_wall[entity_pid(wall)] = presentation_attached_entities(wall, walls, oriented)
        generic_by_wall[entity_pid(wall)] = presentation_generic_near_wall(wall, generic)
      end

      selected_ids = source.map { |entity| entity_pid(entity) }
      outside = model.entities.to_a.select do |entity|
        entity.respond_to?(:hidden=) && entity.valid? && !entity.hidden? &&
          !selected_ids.include?(entity_pid(entity))
      end
      @presentation_scene_cache = {
        'entities' => entities,
        'walls' => walls,
        'attached_by_wall' => attached_by_wall,
        'generic_by_wall' => generic_by_wall,
        'always_hidden' => outside.uniq
      }
      @presentation_last_facing_key = nil
      @presentation_scene_cache
    rescue => e
      puts "MHDESIGN Presentation Cache Warning: #{e.message}"
      @presentation_scene_cache = { 'entities' => [], 'walls' => [], 'attached_by_wall' => {} }
    end

    # يطبّق الفرق فقط: العناصر التي لم تعد في ناحية الكاميرا تظهر، والعناصر
    # الجديدة فقط تختفي. لا نعيد إظهار وإخفاء نفس العناصر أثناء كل حركة.
    def apply_presentation_hidden_set(desired_entities)
      desired = Array(desired_entities).select { |entity| entity && entity.valid? }.uniq
      current = Array(@presentation_hidden_entities).select { |entity| entity && entity.valid? }.uniq
      desired_ids = desired.each_with_object({}) { |entity, hash| hash[entity_pid(entity)] = true }
      current_ids = current.each_with_object({}) { |entity, hash| hash[entity_pid(entity)] = true }

      current.each do |entity|
        unless desired_ids[entity_pid(entity)]
          entity.hidden = false
          entity.delete_attribute(PRESENTATION_TEMP_DICT, PRESENTATION_HIDDEN_KEY) rescue nil
        end
      rescue
      end

      desired.each do |entity|
        unless current_ids[entity_pid(entity)]
          entity.set_attribute(PRESENTATION_TEMP_DICT, PRESENTATION_HIDDEN_KEY, true) rescue nil
          entity.hidden = true
        end
      rescue
      end

      @presentation_hidden_entities = desired
      current_model.active_view.invalidate
    rescue => e
      puts "MHDESIGN Presentation Hidden Set Warning: #{e.message}"
    end

    # يخفي جانبًا واحدًا أو جانبين حسب مكان الكاميرا، ثم يخفي الوحدات
    # والأجهزة المرتبطة بكل حائط مختفٍ من ناحية الظهر.
    def refresh_presentation_cut(force = false)
      return unless @presentation_mode_active
      model = current_model
      return disable_presentation_mode(false) if @presentation_model && @presentation_model != model

      signature = presentation_camera_signature
      return if !force && signature && signature == @presentation_camera_signature
      @presentation_camera_signature = signature

      cache = @presentation_scene_cache || build_presentation_scene_cache(model)
      walls = Array(cache['walls'])
      return if walls.empty?
      facing_walls = presentation_facing_walls(walls, model.active_view.camera)
      facing_key = facing_walls.map { |wall| entity_pid(wall) }.sort.join('|')
      return if !force && facing_key == @presentation_last_facing_key
      @presentation_last_facing_key = facing_key

      hidden_entities = Array(cache['always_hidden']).dup
      hidden_entities.concat(facing_walls)
      facing_walls.each do |wall|
        hidden_entities.concat(Array(cache['attached_by_wall'][entity_pid(wall)]))
        hidden_entities.concat(Array(cache['generic_by_wall'][entity_pid(wall)]))
      end
      apply_presentation_hidden_set(hidden_entities)
    rescue => e
      puts "MHDESIGN Presentation Refresh Warning: #{e.message}"
    end

    def start_presentation_watcher
      stop_presentation_watcher
      # 0.40 ثانية تظل سريعة بصريًا عند الانتقال بين الجوانب، لكنها لا تقطع
      # سلاسة Orbit أربع مرات كل ثانية كما كان يحدث في الإصدار السابق.
      @presentation_watch_timer = UI.start_timer(0.40, true) do
        if @presentation_mode_active && (!@dialog || !@dialog.visible?)
          disable_presentation_mode(false)
        elsif @presentation_mode_active
          refresh_presentation_cut(false)
        end
      end
    rescue => e
      puts "MHDESIGN Presentation Watcher Warning: #{e.message}"
    end

    def stop_presentation_watcher
      if @presentation_watch_timer
        UI.stop_timer(@presentation_watch_timer) rescue nil
        @presentation_watch_timer = nil
      end
    end

    # كل تغييرات hidden المؤقتة تعيش داخل عملية واحدة لا يتم عمل Commit لها.
    # عند إلغاء وضع المشاهدة نعمل Abort، فتعود الحالة الأصلية ولا يُضاف أي
    # سجل إخفاء أو إظهار إلى Undo / Ctrl+Z.
    def begin_presentation_operation(model)
      return if @presentation_operation_open
      model.start_operation('MHDESIGN Temporary Presentation View', true)
      @presentation_operation_open = true
    rescue => e
      @presentation_operation_open = false
      raise e
    end

    def abort_presentation_operation(model)
      return false unless @presentation_operation_open
      model.abort_operation
      @presentation_operation_open = false
      @presentation_hidden_entities = []
      true
    rescue => e
      @presentation_operation_open = false
      puts "MHDESIGN Abort Presentation Operation Warning: #{e.message}"
      false
    end

    def countertop_entity?(entity)
      type = entity.get_attribute(COUNTERTOP_DICT, 'النوع').to_s.strip
      return true if type == 'رخامة'

      name = entity.name.to_s.downcase rescue ''
      definition_name = MHDESIGN::Language.original_definition_name(entity.definition).to_s.downcase rescue ''
      layer_name = entity.layer.name.to_s.downcase rescue ''
      identity = "#{name} #{definition_name} #{layer_name}"

      identity.include?('رخام') || identity.include?('countertop')
    rescue
      false
    end

    def request_presentation_selection
      return if @presentation_mode_active
      current_model.selection.clear
      @presentation_awaiting_selection = true
      @presentation_scope_roots = []
      Sketchup.send_action('selectSelectionTool:') rescue nil
      execute_js("setPresentationSelectionMode(true);")
      UI.messagebox(tr('حدد المطبخ بالكامل بكل محتوياته، ثم اضغط نفس الزر مرة ثانية للتشغيل.'))
    rescue => e
      @presentation_awaiting_selection = false
      UI.messagebox(tr("تعذر بدء تحديد المطبخ:\n#{e.message}"))
    end

    def confirm_presentation_selection
      selected = current_model.selection.to_a.select do |entity|
        entity.respond_to?(:hidden=) && entity.valid?
      end
      if selected.empty?
        UI.messagebox(tr('حدد المطبخ بالكامل أولاً، ثم اضغط زر التشغيل مرة ثانية.'))
        return
      end

      @presentation_scope_roots = selected
      @presentation_awaiting_selection = false
      current_model.selection.clear
      execute_js("setPresentationSelectionMode(false);")
      enable_presentation_mode
    rescue => e
      UI.messagebox(tr("تعذر اعتماد تحديد المطبخ:\n#{e.message}"))
    end

    def enable_presentation_mode
      return if @presentation_mode_active
      model = current_model
      @presentation_model = model
      @presentation_mode_active = true
      @presentation_camera_signature = nil

      # مراقب المستويات ومراقب حجم نافذة HTML غير مطلوبين أثناء العرض،
      # واستدعاءاتهم المتزامنة مع Orbit كانت تسبب تقطيعًا ملحوظًا للحركة.
      stop_level_watcher
      stop_size_watcher
      @presentation_paused_dialog_watchers = true

      save_presentation_rendering_state(model)
      apply_presentation_rendering(model)
      build_presentation_scene_cache(model)
      begin_presentation_operation(model)
      refresh_presentation_cut(true)
      start_presentation_watcher
      execute_js("setPresentationMode(true);")
    rescue => e
      @presentation_mode_active = false
      stop_presentation_watcher
      aborted = abort_presentation_operation(model) if model
      restore_presentation_hidden_entities unless aborted
      restore_presentation_rendering(model) if model
      if @presentation_paused_dialog_watchers && @dialog && @dialog.visible?
        start_size_watcher
        start_level_watcher
      end
      @presentation_paused_dialog_watchers = false
      UI.messagebox(tr("تعذر تشغيل وضع مشاهدة التصميم:\n#{e.message}"))
    end

    def disable_presentation_mode(update_dialog = true)
      return unless @presentation_mode_active || @presentation_rendering_state || @presentation_awaiting_selection
      model = @presentation_model || current_model
      @presentation_awaiting_selection = false
      @presentation_mode_active = false
      stop_presentation_watcher
      aborted = abort_presentation_operation(model) if model
      restore_presentation_hidden_entities unless aborted
      restore_presentation_rendering(model) if model
      @presentation_camera_signature = nil
      @presentation_scene_cache = nil
      @presentation_last_facing_key = nil
      @presentation_world_bounds = {}
      @presentation_world_transforms = {}
      @presentation_countertop_back_bounds = {}
      @presentation_model = nil
      @presentation_scope_roots = []

      if @presentation_paused_dialog_watchers && @dialog && @dialog.visible?
        start_size_watcher
        start_level_watcher
      end
      @presentation_paused_dialog_watchers = false

      model.active_view.invalidate if model
      execute_js("setPresentationSelectionMode(false);")
      execute_js("setPresentationMode(false);") if update_dialog
    rescue => e
      puts "MHDESIGN Disable Presentation Warning: #{e.message}"
    end

    def toggle_presentation_mode
      if @presentation_mode_active
        disable_presentation_mode
      elsif @presentation_awaiting_selection
        confirm_presentation_selection
      else
        request_presentation_selection
      end
    end

    # --------------------------- Language ---------------------------

    def language_engine
      return MHDESIGN::Language.for_tool('materials') if defined?(MHDESIGN::Language)
      nil
    rescue
      nil
    end

    def tr(text)
      engine = language_engine
      engine ? engine.translate_source(text.to_s) : text.to_s
    rescue
      text.to_s
    end

    def tr_key(key, fallback = nil)
      engine = language_engine
      engine ? engine.t(key.to_s, fallback) : (fallback || key).to_s
    rescue
      (fallback || key).to_s
    end

    def ui_direction
      engine = language_engine
      engine ? engine.direction : 'rtl'
    rescue
      'rtl'
    end

    def ui_locale
      engine = language_engine
      engine ? engine.current : 'ar_EG'
    rescue
      'ar_EG'
    end

    # --------------------------- Levels ---------------------------

    def default_levels
      []
    end

    def levels
      raw = current_model.get_attribute(MODEL_DICT, LEVELS_KEY, '')
      data = raw.to_s.empty? ? default_levels : JSON.parse(raw.to_s)
      data.is_a?(Array) ? data : default_levels
    rescue
      default_levels
    end

    def save_levels(data)
      current_model.set_attribute(MODEL_DICT, LEVELS_KEY, JSON.generate(data))
      data
    end

    def new_level_id
      "level_#{Time.now.to_i}_#{rand(1000..9999)}"
    end

    # يجمع كل ComponentInstance داخل الموديل، بما فيها الوحدات الموجودة
    # داخل Groups أو Components أخرى. لا ندخل نفس Definition أكثر من مرة.
    def all_model_component_instances
      result = []
      visited_definitions = {}

      walk = nil
      walk = lambda do |collection|
        collection.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)

          result << entity if entity.is_a?(Sketchup::ComponentInstance)

          definition = entity.definition
          next unless definition

          key = definition.object_id
          next if visited_definitions[key]

          visited_definitions[key] = true
          walk.call(definition.entities)
        end
      end

      walk.call(current_model.entities)
      result
    rescue => e
      puts "MHDESIGN All Instances Error: #{e.message}"
      []
    end

    def unit_level_id(entity)
      entity.get_attribute(MODEL_DICT, UNIT_LEVEL_ID_KEY, '').to_s
    rescue
      ''
    end

    def mark_unit_for_level(entity, level)
      return unless entity && entity.valid? && level

      previous_level_id = unit_level_id(entity)

      entity.set_attribute(MODEL_DICT, UNIT_LEVEL_ID_KEY, level['id'].to_s)
      entity.set_attribute(MODEL_DICT, UNIT_LEVEL_NAME_KEY, level['name'].to_s)

      if !previous_level_id.empty? && previous_level_id != level['id'].to_s
        entity.delete_attribute(MODEL_DICT, UNIT_LEVEL_ISOLATION_KEY)
      end
    rescue => e
      puts "MHDESIGN Mark Unit Error: #{e.message}"
    end

    def clear_unit_level_mark(entity, level_id = nil)
      return unless entity && entity.valid?

      current_id = unit_level_id(entity)
      return if level_id && current_id != level_id.to_s

      entity.delete_attribute(MODEL_DICT, UNIT_LEVEL_ID_KEY)
      entity.delete_attribute(MODEL_DICT, UNIT_LEVEL_NAME_KEY)
      entity.delete_attribute(MODEL_DICT, UNIT_LEVEL_ISOLATION_KEY)
    rescue => e
      puts "MHDESIGN Clear Unit Mark Error: #{e.message}"
    end

    # المصدر الأساسي لاسترجاع وحدات المستوى هو العلامة المحفوظة داخل كل وحدة.
    # persistent_id يظل موجودًا كنسخة احتياطية للتوافق مع الملفات القديمة.
    def find_level_entities(level)
      return [] unless level

      level_id = level['id'].to_s
      stored_pids = Array(level['unit_ids']).map(&:to_i)
      found = []
      found_keys = {}

      # أولاً: العلامة الداخلية المحفوظة داخل الوحدة.
      all_model_component_instances.each do |entity|
        next unless entity.valid?
        next unless unit_level_id(entity) == level_id

        key = entity_pid(entity)
        next if found_keys[key]

        found_keys[key] = true
        found << entity
      end

      # ثانيًا: دعم المستويات القديمة التي كانت تحفظ persistent_id فقط.
      stored_pids.each do |pid|
        entity = current_model.find_entity_by_persistent_id(pid) rescue nil
        next unless entity.is_a?(Sketchup::ComponentInstance) && entity.valid?

        key = entity_pid(entity)
        next if found_keys[key]

        mark_unit_for_level(entity, level)
        found_keys[key] = true
        found << entity
      end

      # تحديث قائمة الـIDs تلقائيًا لو SketchUp غيّر persistent_id بعد redraw.
      fresh_ids = found.map { |entity| entity_pid(entity) }.reject(&:zero?).uniq
      if fresh_ids != stored_pids
        level['unit_ids'] = fresh_ids
      end

      found
    rescue => e
      puts "MHDESIGN Find Level Entities Error: #{e.message}"
      []
    end

    def clean_levels!
      data = levels
      changed = false

      data.each do |level|
        before = Array(level['unit_ids']).map(&:to_i)
        entities = find_level_entities(level)
        after = entities.map { |entity| entity_pid(entity) }.reject(&:zero?).uniq

        if before != after
          level['unit_ids'] = after
          changed = true
        end
      end

      save_levels(data) if changed
      data
    rescue => e
      puts "MHDESIGN Clean Levels Error: #{e.message}"
      levels
    end

    def find_entities_by_pids(pids)
      wanted = Array(pids).map(&:to_i)
      return [] if wanted.empty?

      wanted.filter_map do |pid|
        entity = current_model.find_entity_by_persistent_id(pid) rescue nil
        entity if entity.is_a?(Sketchup::ComponentInstance) && entity.valid?
      end
    rescue
      []
    end

    def add_level(name)
      data = levels
      data << {
        'id' => new_level_id,
        'name' => name.to_s.strip.empty? ? "مستوى #{data.length + 1}" : name.to_s.strip,
        'unit_ids' => [],
        'last_target' => 'door'
      }
      save_levels(data)
      push_state
    end

    def rename_level(id, name)
      new_name = name.to_s.strip
      return if new_name.empty?

      data = levels
      item = data.find { |x| x['id'].to_s == id.to_s }
      return unless item

      old_level_name = item['name'].to_s
      old_band_name = level_band_material_name(old_level_name)
      new_band_name = level_band_material_name(new_name)

      current_model.start_operation('MHDESIGN Rename Level', true)

      band = exact_model_material(old_band_name)
      if band && normalize_ar(old_band_name) != normalize_ar(new_band_name)
        existing = exact_model_material(new_band_name)
        raise "#{MHDESIGN::Language.for_tool('materials').t('TEXT_6B4C3DA272D2')}#{new_band_name}." if existing && existing != band
        band.name = new_band_name
      end

      item['name'] = new_name

      # تحديث اسم المستوى المحفوظ داخل وحداته.
      find_level_entities(item).each do |entity|
        mark_unit_for_level(entity, item)
      end

      save_levels(data)

      current_model.commit_operation
      current_model.active_view.invalidate
      push_state
    rescue => e
      current_model.abort_operation rescue nil
      UI.messagebox(tr("تعذر تغيير اسم المستوى:\n#{e.message}"))
    end

    def delete_level(id)
      data = levels
      item = data.find { |x| x['id'].to_s == id.to_s }

      if item
        find_level_entities(item).each do |entity|
          clear_unit_level_mark(entity, id)
        end
      end

      save_levels(data.reject { |x| x['id'].to_s == id.to_s })
      push_state
    end

    # إعادة تعيين بيانات المستويات داخل ملف SketchUp المفتوح فقط.
    # لا يتم حذف أي وحدة أو خامة أو جزء من التصميم.
    def reset_levels
      model = current_model
      data = levels
      level_ids = data.map { |level| level['id'].to_s }.reject(&:empty?)

      model.start_operation('MHDESIGN Reset Kitchen Levels', true)

      all_model_component_instances.each do |entity|
        next unless entity && entity.valid?
        next unless level_ids.include?(unit_level_id(entity))

        clear_unit_level_mark(entity)
      end

      model.delete_attribute(MODEL_DICT, LEVELS_KEY)
      save_levels(default_levels)

      model.commit_operation
      model.active_view.invalidate

      push_state
      execute_js(tr("finishResetLevels(true, 'تمت إعادة تعيين مستويات هذا الملف.');"))
    rescue => e
      model.abort_operation rescue nil
      execute_js(tr("finishResetLevels(false, #{js_json("تعذر إعادة التعيين: #{e.message}")});"))
      UI.messagebox(tr("تعذر إعادة تعيين المستويات:\n#{e.message}"))
    end

    def assign_selection_to_level(id)
      selected = selected_components
      if selected.empty?
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_D5B044315E03'))
        return
      end

      data = levels
      item = data.find { |x| x['id'].to_s == id.to_s }
      return unless item

      current_model.start_operation('MHDESIGN Assign Level Units', true)

      # إزالة علامة المستوى من الوحدات القديمة التي لم تعد ضمن التحديد.
      selected_keys = selected.map { |entity| entity_pid(entity) }.to_h { |pid| [pid, true] }
      find_level_entities(item).each do |entity|
        clear_unit_level_mark(entity, id) unless selected_keys[entity_pid(entity)]
      end

      # الوحدة تكون تابعة لمستوى واحد فقط؛ التعيين الجديد يستبدل العلامة القديمة.
      selected.each do |entity|
        mark_unit_for_level(entity, item)
      end

      item['unit_ids'] = selected.map { |entity| entity_pid(entity) }.reject(&:zero?).uniq
      save_levels(data)

      current_model.commit_operation
      push_state
    rescue => e
      current_model.abort_operation rescue nil
      UI.messagebox(tr("تعذر حفظ وحدات المستوى:\n#{e.message}"))
    end

    def add_selection_to_level(id)
      selected = selected_components
      if selected.empty?
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_8E10F521EDCB'))
        return
      end

      data = levels
      item = data.find { |x| x['id'].to_s == id.to_s }
      return unless item

      current_model.start_operation('MHDESIGN Add Level Units', true)

      existing = find_level_entities(item)
      selected.each do |entity|
        mark_unit_for_level(entity, item)
      end

      combined = (existing + selected).select(&:valid?).uniq
      item['unit_ids'] = combined.map { |entity| entity_pid(entity) }.reject(&:zero?).uniq
      save_levels(data)

      current_model.commit_operation
      push_state
    rescue => e
      current_model.abort_operation rescue nil
      UI.messagebox(tr("تعذر إضافة وحدات المستوى:\n#{e.message}"))
    end

    def select_level_units(id)
      data = levels
      item = data.find { |x| x['id'].to_s == id.to_s }
      return unless item

      entities = find_level_entities(item)

      # حفظ أي IDs جديدة نتجت عن Dynamic Component redraw.
      item['unit_ids'] = entities.map { |entity| entity_pid(entity) }.reject(&:zero?).uniq
      save_levels(data)

      current_model.selection.clear
      current_model.selection.add(entities) unless entities.empty?
      current_model.active_view.invalidate

      if entities.empty?
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_46B11FA6D10D'))
      end

      push_state
    rescue => e
      UI.messagebox(tr("تعذر تحديد وحدات المستوى:\n#{e.message}"))
    end

    # --------------------------- Level geometry isolation ---------------------------
    #
    # خامات الـFaces محفوظة داخل Component Definition، وليس داخل الـInstance.
    # لذلك لو وحدات مستويين تستخدم نفس Definitions فإن تغيير شريط مستوى واحد
    # يغيّر المستوى الآخر أيضًا. قبل ربط شريط أي مستوى نعزل Definitions الخاصة
    # بوحداته بالكامل، بما فيها القطع المتداخلة، ثم نربط Faces هذا المستوى فقط.

    def component_or_group?(entity)
      entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
    rescue
      false
    end

    def definition_shared?(entity)
      return false unless entity && entity.valid? && entity.respond_to?(:definition)
      definition = entity.definition
      return false unless definition && definition.respond_to?(:instances)

      definition.instances.count { |instance| instance && instance.valid? } > 1
    rescue
      false
    end

    def make_entity_unique_safely!(entity)
      return entity unless entity && entity.valid?
      return entity unless entity.is_a?(Sketchup::ComponentInstance)
      return entity unless definition_shared?(entity)

      entity.make_unique
      entity
    rescue => e
      puts "MHDESIGN Make Unique Warning: #{e.message}"
      entity
    end

    def deep_make_unique_for_level!(root_entity, visited = {})
      return root_entity unless root_entity && root_entity.valid?
      return root_entity unless component_or_group?(root_entity)

      make_entity_unique_safely!(root_entity)

      definition = root_entity.definition rescue nil
      return root_entity unless definition

      visit_key = [entity_pid(root_entity), definition.object_id]
      return root_entity if visited[visit_key]
      visited[visit_key] = true

      definition.entities.to_a.each do |child|
        next unless component_or_group?(child)
        make_entity_unique_safely!(child)
        deep_make_unique_for_level!(child, visited)
      end

      root_entity
    rescue => e
      puts "MHDESIGN Deep Make Unique Error: #{e.message}"
      root_entity
    end

    def level_entity_isolated?(entity, level)
      return false unless entity && entity.valid? && level

      # العلامة مرتبطة بالمستوى فقط.
      # persistent_id قد يتغير بعد Dynamic Component redraw،
      # وكان ذلك يجبر الكود على Deep Make Unique من جديد في كل تغيير.
      saved = entity.get_attribute(
        MODEL_DICT,
        UNIT_LEVEL_ISOLATION_KEY,
        ''
      ).to_s

      saved == level['id'].to_s
    rescue
      false
    end

    def mark_level_entity_isolated!(entity, level)
      return unless entity && entity.valid? && level

      entity.set_attribute(
        MODEL_DICT,
        UNIT_LEVEL_ISOLATION_KEY,
        level['id'].to_s
      )
    rescue => e
      puts "MHDESIGN Isolation Mark Error: #{e.message}"
    end

    def ensure_level_geometry_unique!(_level, entities)
      # استعادة السلوك السريع القديم:
      # لا Deep Make Unique، لا نسخ Definitions، ولا إعادة فحص للموديل.
      Array(entities).select { |entity| entity && entity.valid? }
    rescue
      Array(entities)
    end

    def decode_text(str)
      s = str.to_s.gsub(/%u([0-9A-Fa-f]{4})/) { [$1.hex].pack('U') }
      CGI.unescape(s) rescue s
    end

    def clean_label(str)
      decode_text(str).gsub(/<[^>]*>/, '').strip
    end

    def dc_access_keys(ent)
      dict = ent.definition.attribute_dictionary(DC_DICT, false)
      return [] unless dict
      keys = []
      dict.each_pair do |key, _value|
        k = key.to_s
        next unless k.start_with?('_') && k.end_with?('_access')
        keys << k.sub(/^_/, '').sub(/_access$/, '')
      end
      keys.uniq
    rescue
      []
    end

    def drawer_face_material_label?(label)
      normalized_label = normalize_ar(label)

      normalized_label.include?(normalize_ar('خامة')) &&
        normalized_label.include?(normalize_ar('درج')) &&
        [normalize_ar('وش'), normalize_ar('وجه'), normalize_ar('واجهة')].any? do |word|
          normalized_label.include?(word)
        end
    rescue
      false
    end

    def dc_material_attributes(ent, target)
      d = dc
      return [] unless d

      wanted = Array(MATERIAL_TARGETS[target]).map { |x| normalize_ar(x) }
      found = []

      dc_access_keys(ent).each do |key|
        label = begin
          clean_label(d.get_attribute_formlabel(ent, key).to_s)
        rescue
          key
        end

        normalized_label = normalize_ar(label)
        matched = wanted.include?(normalized_label)

        # خامة وش الدرج قد تختلف تسميتها بين الوحدات القديمة والجديدة.
        drawer_match = drawer_face_material_label?(label)
        matched = true if target == 'drawer' && drawer_match

        # عند تغيير خامة الضلفة نغيّر معها خامة وش الدرج تلقائياً،
        # من غير ظهور خامة وش الدرج كاختيار مستقل في الواجهة.
        matched = true if target == 'door' && drawer_match

        found << { 'key' => key, 'label' => label, 'drawer_face' => drawer_match } if matched
      end

      if target == 'door'
        drawer_attrs = found.select { |x| x['drawer_face'] == true }
        door_attrs   = found.reject { |x| x['drawer_face'] == true }

        # نفضّل خاصية خامة الضلفة العامة، ولو غير موجودة نستخدم العلوية والسفلية.
        primary = door_attrs.select do |x|
          normalize_ar(x['label']) == normalize_ar('خامة الضلفه') ||
            normalize_ar(x['label']) == normalize_ar('خامة الضلفة')
        end
        door_attrs = primary unless primary.empty?

        return (door_attrs + drawer_attrs).uniq { |x| x['key'].to_s }
      end

      found.uniq { |x| x['key'].to_s }
    rescue
      []
    end

    def apply_dc_attribute(d, ent, key, value)
      text = value.to_s.strip
      formula_key = "_#{key}_formula"

      if text.start_with?('=')
        formula = text.sub(/\A=/, '')
        begin
          if d.respond_to?(:set_attribute_formula)
            d.set_attribute_formula(ent, key, formula)
          else
            ent.set_attribute(DC_DICT, formula_key, formula)
          end
        rescue
          ent.set_attribute(DC_DICT, formula_key, formula)
        end
        return
      end

      current_formula = ent.get_attribute(DC_DICT, formula_key, nil)
      if (current_formula.nil? || current_formula.to_s.strip.empty?) && ent.respond_to?(:definition)
        current_formula = ent.definition.get_attribute(DC_DICT, formula_key, nil)
      end

      if current_formula && !current_formula.to_s.strip.empty?
        escaped = text.gsub('\\', '\\\\').gsub('"', '\\"')
        fixed_formula = "\"#{escaped}\""
        begin
          if d.respond_to?(:set_attribute_formula)
            d.set_attribute_formula(ent, key, fixed_formula)
          else
            ent.set_attribute(DC_DICT, formula_key, fixed_formula)
          end
        rescue
          ent.set_attribute(DC_DICT, formula_key, fixed_formula)
        end
      else
        begin
          d.set_attribute(ent, key, text)
        rescue
          ent.set_attribute(DC_DICT, key, text)
        end
      end
    end

    # توحيد المسميات المتكررة التي تؤدي نفس الوظيفة.
    #
    # القيم التالية كلها تظهر وتُحفظ كقيمة واحدة:
    # - نفس خامة الضلفه
    # - بنفس خامة الضلفه
    # - نفس خامة الدرج
    # - بنفس خامة الدرج
    #
    # القيمة النهائية المعتمدة:
    #   بنفس خامة الضلفه
    def canonical_material_option_name(value)
      text = clean_material_name(decode_text(value.to_s))
      normalized = normalize_ar(text)

      same_material_aliases = [
        'نفس خامة الضلفه',
        'نفس خامة الضلفة',
        'بنفس خامة الضلفه',
        'بنفس خامة الضلفة',
        'نفس خامة الدرج',
        'بنفس خامة الدرج',
        'نفس خامة الادراج',
        'نفس خامة الأدراج',
        'بنفس خامة الادراج',
        'بنفس خامة الأدراج'
      ].map { |item| normalize_ar(item) }

      if same_material_aliases.include?(normalized)
        'بنفس خامة الضلفه'
      else
        text
      end
    rescue
      value.to_s.strip
    end

    def parse_dc_material_options(raw)
      return [] if raw.to_s.strip.empty? || raw.to_s.strip == '&'

      raw.to_s.split('&').filter_map do |item|
        next if item.to_s.strip.empty?
        decoded = decode_text(item)
        label, value = decoded.split('=', 2)
        label = (label || decoded).to_s.strip
        value = (value || label || decoded).to_s.strip
        next if label.empty? && value.empty?

        canonical_label = canonical_material_option_name(label.empty? ? value : label)
        canonical_value = canonical_material_option_name(value)

        # لو أي طرف من الأطراف من مجموعة "نفس الخامة"، نوحّد الاثنين
        # على نفس النص والقيمة حتى لا تظهر خيارات مكررة.
        if canonical_label == 'بنفس خامة الضلفه' ||
           canonical_value == 'بنفس خامة الضلفه'
          canonical_label = 'بنفس خامة الضلفه'
          canonical_value = 'بنفس خامة الضلفه'
        end

        { 'label' => canonical_label, 'value' => canonical_value }
      end
    rescue
      []
    end

    def material_name_choices(level_id, target)
      level = levels.find { |x| x['id'].to_s == level_id.to_s }
      return { 'options' => [], 'current' => '' } unless level

      entities = find_level_entities(level)
      d = dc
      return { 'options' => [], 'current' => '' } unless d

      options = []
      seen = {}
      currents = []

      entities.each do |ent|
        attrs = dc_material_attributes(ent, target)
        attrs = attrs.reject { |attr| attr['drawer_face'] == true } if target == 'door'

        attrs.each do |attr|
          current = canonical_material_option_name(
            current_dc_material_name(d, ent, attr['key'])
          )
          currents << current unless current.empty?

          raw = begin
            d.get_attribute_options(ent, attr['key']).to_s
          rescue
            ''
          end

          parse_dc_material_options(raw).each do |option|
            signature = "#{option['label']}|#{option['value']}"
            next if seen[signature]
            seen[signature] = true
            options << option
          end
        end
      end

      currents.uniq.each do |name|
        next if options.any? { |option| option['label'].to_s == name || option['value'].to_s == name }
        options << { 'label' => name, 'value' => name }
      end

      current = currents.uniq.length == 1 ? currents.first : ''
      { 'options' => options, 'current' => current }
    rescue => e
      puts "MHDESIGN Material Choices Error: #{e.message}"
      { 'options' => [], 'current' => '' }
    end

    def push_material_name_choices(level_id, target)
      payload = material_name_choices(level_id, target)
      execute_js("receiveMaterialChoices(#{js_json(payload)});")
    end

    # قراءة خامة الضلفة الفعلية مرة واحدة فقط من وحدات المستوى.
    # لا يوجد بحث داخل Faces ولا Traverse إضافي.
    def level_actual_door_material_name(entities)
      d = dc
      return '' unless d

      Array(entities).each do |entity|
        next unless entity && entity.valid?

        attrs = dc_material_attributes(entity, 'door')
        attrs = attrs.reject { |attr| attr['drawer_face'] == true }

        attrs.each do |attr|
          value = current_dc_material_name(d, entity, attr['key']).to_s.strip
          next if value.empty?
          next if canonical_material_option_name(value) == 'بنفس خامة الضلفه'

          return value
        end
      end

      ''
    rescue
      ''
    end

    def change_material_name(level_id, target, new_value)
      new_value = canonical_material_option_name(new_value)
      level = levels.find { |x| x['id'].to_s == level_id.to_s }

      unless level
        execute_js(tr("finishBusy(false, 'تعذر العثور على المستوى.');"))
        return
      end

      entities = find_level_entities(level)
      if entities.empty?
        execute_js(tr("finishBusy(false, 'المستوى لا يحتوي على وحدات صالحة.');"))
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_CDF5AE7226D8'))
        return
      end

      d = dc
      unless d
        execute_js(tr("finishBusy(false, 'Dynamic Components غير محمل.');"))
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_8D1A22F4D18F'))
        return
      end

      execute_js(tr("updateBusy('جاري قراءة وحدات المستوى...', 16);"))

      # عند اختيار "بنفس خامة الضلفه" للشاسيه نقرأ اسم خامة الضلفة
      # مرة واحدة فقط ثم نطبقه مباشرة على كل وحدات المستوى.
      applied_value = new_value
      if target == 'carcass' && new_value == 'بنفس خامة الضلفه'
        applied_value = level_actual_door_material_name(entities)

        if applied_value.to_s.strip.empty?
          execute_js(tr("finishBusy(false, 'تعذر قراءة خامة الضلفة من وحدات المستوى.');"))
          UI.messagebox(tr('تعذر قراءة خامة الضلفة من وحدات المستوى.'))
          return
        end
      end

      current_model.start_operation('MHDESIGN Change Material Name', true)
      touched = []

      execute_js(tr("updateBusy('جاري تغيير مسمى الخامة...', 34);"))

      entities.each do |ent|
        attrs = dc_material_attributes(ent, target)
        next if attrs.empty?

        attrs.each { |attr| apply_dc_attribute(d, ent, attr['key'], applied_value) }
        touched << ent
      end

      execute_js(tr("updateBusy('جاري إعادة رسم الوحدات...', 52);"))
      redraw_entities(touched)

      # اختيار المسمى من الـ Dropdown يمر الآن بنفس شاشة التجهيز
      # ونفس منطق خامات المستوى المستخدم عند اختيار صورة الخامة.
      if target == 'door'
        source_material = nil

        touched.each do |ent|
          source_material = find_original_material(ent, new_value)
          break if source_material
        end

        source_material ||= exact_model_material(new_value)

        if source_material
          band_name = level_band_material_name(level['name'])

          if exact_model_material(band_name)
            execute_js(tr("updateBusy('جاري تحديث شريط قطع المستوى...', 72);"))
          else
            execute_js(tr("updateBusy('جاري تحديث شريط قطع المستوى...', 64);"))
          end

          sync_level_band_material(level, source_material, touched)
        end

      elsif target == 'carcass'
        chassis_source = nil

        touched.each do |ent|
          chassis_source = find_original_material(ent, applied_value)
          break if chassis_source
        end

        chassis_source ||= exact_model_material(applied_value)

        if chassis_source
          band_name = level_chassis_band_material_name(level['name'])

          if exact_model_material(band_name)
            execute_js(tr("updateBusy('جاري تحديث خامة شاسيه المستوى...', 72);"))
          else
            execute_js(tr("updateBusy('جاري تحديث شريط الشاسيه...', 64);"))
          end

          # مهم: نفس خامة الشاسيه المستقلة الخاصة بالمستوى،
          # وليس المسار القديم المشترك بين جميع المستويات.
          sync_level_chassis_band_material(level, chassis_source, touched)
        end
      else
        execute_js(tr("updateBusy('جاري تحديث خامة الضهر...', 74);"))
      end

      execute_js(tr("updateBusy('جاري حفظ التعديلات...', 90);"))

      level['last_target'] = target
      save_levels(levels)

      current_model.commit_operation
      current_model.active_view.invalidate

      push_state
      push_material_name_choices(level_id, target)

      message = "تم تغيير مسمى الخامة في #{touched.length} وحدة"
      execute_js("finishBusy(true, #{js_json(message)});")
    rescue => e
      current_model.abort_operation rescue nil
      execute_js(tr("finishBusy(false, #{js_json("حدث خطأ أثناء تغيير مسمى الخامة: #{e.message}")});"))
      UI.messagebox(tr("حدث خطأ أثناء تغيير مسمى الخامة:\n#{e.message}"))
    end


    # --------------------------- Duplicate / rename materials ---------------------------

    def clean_material_name(name)
      name.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
          .gsub(/[\r\n\t]+/, ' ')
          .gsub(/\s+/, ' ')
          .strip
    rescue
      name.to_s.strip
    end

    def all_model_component_instances
      result = []
      visited_definitions = {}

      walker = lambda do |entities|
        entities.each do |entity|
          if entity.is_a?(Sketchup::ComponentInstance)
            result << entity unless result.include?(entity)

            definition = entity.definition
            next if visited_definitions[definition.object_id]

            visited_definitions[definition.object_id] = true
            walker.call(definition.entities)
          elsif entity.is_a?(Sketchup::Group)
            walker.call(entity.entities)
          end
        end
      end

      walker.call(current_model.entities)
      result
    rescue => e
      puts "MHDESIGN Component Scan Error: #{e.message}"
      current_model.entities.grep(Sketchup::ComponentInstance)
    end

    def dc_option_raw(ent, key)
      d = dc
      return '' unless d

      begin
        value = d.get_attribute_options(ent, key).to_s
        return value unless value.empty?
      rescue
      end

      ent.get_attribute(DC_DICT, "_#{key}_options", '').to_s.tap do |value|
        if value.empty? && ent.respond_to?(:definition)
          value.replace(ent.definition.get_attribute(DC_DICT, "_#{key}_options", '').to_s)
        end
      end
    rescue
      ''
    end

    def encode_dc_option_text(text)
      CGI.escape(text.to_s).gsub('+', '%20')
    rescue
      text.to_s
    end

    def write_dc_option_raw(ent, key, raw)
      attribute_key = "_#{key}_options"
      ent.definition.set_attribute(DC_DICT, attribute_key, raw.to_s)
      ent.set_attribute(DC_DICT, attribute_key, raw.to_s) if ent.get_attribute(DC_DICT, attribute_key, nil)
      true
    rescue => e
      puts "MHDESIGN Write Options Error: #{e.message}"
      false
    end

    def append_dc_material_option(ent, key, label, value = label)
      raw = dc_option_raw(ent, key)
      options = parse_dc_material_options(raw)

      exists = options.any? do |item|
        item['label'].to_s == label.to_s || item['value'].to_s == value.to_s
      end
      return false if exists

      encoded = "#{encode_dc_option_text(label)}=#{encode_dc_option_text(value)}"
      updated = raw.to_s.strip
      updated = updated.empty? || updated == '&' ? encoded : "#{updated.sub(/&+\z/, '')}&#{encoded}"
      write_dc_option_raw(ent, key, updated)
    rescue => e
      puts "MHDESIGN Append Option Error: #{e.message}"
      false
    end

    def rename_dc_material_option(ent, key, old_name, new_name)
      raw = dc_option_raw(ent, key)
      options = parse_dc_material_options(raw)
      return false if options.empty?

      changed = false
      rebuilt = options.map do |item|
        label = item['label'].to_s
        value = item['value'].to_s

        if label == old_name.to_s
          label = new_name.to_s
          changed = true
        end

        if value == old_name.to_s
          value = new_name.to_s
          changed = true
        end

        "#{encode_dc_option_text(label)}=#{encode_dc_option_text(value)}"
      end.join('&')

      write_dc_option_raw(ent, key, rebuilt) if changed
      changed
    rescue => e
      puts "MHDESIGN Rename Option Error: #{e.message}"
      false
    end

    # إنشاء Duplicate حقيقية للخامة.
    # في SketchUp 2026.2 وما بعده نستخدم Material#duplicate مباشرة.
    # في الإصدارات الأقدم نستخدم جسر SKM: Export ثم Import، حتى تنتقل
    # AttributeDictionaries الخاصة بـ OpenCutList وV-Ray وكل بيانات الخامة.
    def duplicate_model_material(source_name, new_name)
      source = exact_model_material(source_name)
      return [nil, 'لم يتم العثور على الخامة الأصلية داخل الموديل.'] unless source

      existing = exact_model_material(new_name)
      return [nil, 'يوجد بالفعل خامة بنفس الاسم الجديد.'] if existing

      materials = current_model.materials
      duplicate = nil

      # SketchUp 2026.2 أضاف Duplicate رسميًا للخامات.
      if source.respond_to?(:duplicate)
        begin
          duplicate = source.duplicate
          duplicate.name = new_name
          return [duplicate, nil]
        rescue => e
          puts "MHDESIGN Native Material Duplicate Warning: #{e.message}"
          begin
            materials.remove(duplicate) if duplicate && duplicate.valid?
          rescue
          end
          duplicate = nil
        end
      end

      temp_dir = File.join(
        Dir.tmpdir,
        "mhdesign_skm_duplicate_#{Process.pid}_#{Time.now.to_i}_#{rand(1_000_000)}"
      )
      FileUtils.mkdir_p(temp_dir)
      skm_path = File.join(temp_dir, 'material_copy.skm')

      original_name = source.name.to_s
      parked_name = materials.unique_name("__MHD_DUPLICATE_SOURCE_#{original_name}")
      source_parked = false

      begin
        # save_as يخرج ملف SKM كامل، بما في ذلك بيانات OpenCutList.
        saved = source.save_as(skm_path)
        raise MHDESIGN::Language.for_tool('materials').t('TEXT_E46DEDE04A71') unless saved && File.file?(skm_path)

        # Materials#load يعيد الخامة الموجودة إن كان الاسم متكررًا، لذلك نغيّر
        # اسم الأصل لحظيًا كي يجبر SketchUp على إنشاء Material جديدة من الـSKM.
        source.name = parked_name
        source_parked = true

        duplicate = materials.load(skm_path)
        raise MHDESIGN::Language.for_tool('materials').t('TEXT_253135BE4FB5') unless duplicate
        raise MHDESIGN::Language.for_tool('materials').t('TEXT_1E3B7F72794B') if duplicate == source

        duplicate.name = new_name

        # نعيد الأصل لاسمه الأول بعد أن أخذت النسخة اسمها الجديد.
        source.name = original_name
        source_parked = false

        [duplicate, nil]
      rescue => e
        begin
          materials.remove(duplicate) if duplicate && duplicate != source && duplicate.valid?
        rescue
        end

        begin
          source.name = original_name if source_parked && source && source.valid?
        rescue => restore_error
          puts "MHDESIGN Restore Source Material Name Error: #{restore_error.message}"
        end

        [nil, e.message]
      ensure
        begin
          source.name = original_name if source_parked && source && source.valid?
        rescue
        end

        begin
          FileUtils.rm_rf(temp_dir) if temp_dir && File.directory?(temp_dir)
        rescue
        end
      end
    end

    def duplicate_material_for_level(level_id, target, source_name, new_name)
      source_name = clean_material_name(source_name)
      new_name = clean_material_name(new_name)

      if source_name.empty? || new_name.empty?
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_5E1A225AFA29'))
        return
      end

      if normalize_ar(source_name) == normalize_ar(new_name)
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_B0B0E2DFDF11'))
        return
      end

      level = levels.find { |x| x['id'].to_s == level_id.to_s }
      return unless level

      entities = find_level_entities(level)
      if entities.empty?
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_CDF5AE7226D8'))
        return
      end

      d = dc
      unless d
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_8D1A22F4D18F'))
        return
      end

      execute_js(tr("updateBusy('جاري قراءة وحدات المستوى...', 16);"))
      current_model.start_operation('MHDESIGN Duplicate Material', true)

      execute_js(tr("updateBusy('جاري إنشاء نسخة الخامة...', 32);"))
      duplicate, error = duplicate_model_material(source_name, new_name)
      raise error if error
      raise MHDESIGN::Language.for_tool('materials').t('TEXT_3E5A247DCCE6') unless duplicate

      execute_js(tr("updateBusy('جاري تطبيق الاسم الجديد على الوحدات...', 48);"))
      touched = []

      entities.each do |ent|
        attrs = dc_material_attributes(ent, target)
        next if attrs.empty?

        attrs.each do |attr|
          apply_dc_attribute(d, ent, attr['key'], new_name)
          append_dc_material_option(ent, attr['key'], new_name, new_name)
        end

        touched << ent
      end

      execute_js(tr("updateBusy('جاري إعادة رسم الوحدات...', 64);"))
      redraw_entities(touched)

      execute_js(tr("updateBusy('جاري تجهيز شريط قطع المستوى...', 76);"))
      if target == 'door'
        sync_level_band_material(level, duplicate, touched)
      elsif target == 'carcass'
        sync_level_chassis_band_material(level, duplicate, touched)
      end

      level['last_target'] = target
      save_levels(levels)
      execute_js(tr("updateBusy('جاري حفظ التعديلات...', 92);"))
      current_model.commit_operation
      current_model.active_view.invalidate

      push_state
      push_material_name_choices(level_id, target)
      execute_js(tr("finishMaterialManagement(#{js_json(new_name)}, #{js_json("تم إنشاء خامة جديدة باسم #{new_name} وتطبيقها على #{touched.length} وحدة")});"))
    rescue => e
      current_model.abort_operation rescue nil
      execute_js("finishBusy(false, #{js_json("حدث خطأ أثناء إنشاء نسخة الخامة: #{e.message}")});")
      UI.messagebox(tr("حدث خطأ أثناء إنشاء نسخة الخامة:\n#{e.message}"))
    end

    def rename_model_material_and_attributes(level_id, target, old_name, new_name)
      old_name = clean_material_name(old_name)
      new_name = clean_material_name(new_name)

      level = levels.find { |item| item['id'].to_s == level_id.to_s }
      unless level
        UI.messagebox(tr('تعذر العثور على المستوى المطلوب.'))
        return
      end

      if old_name.empty? || new_name.empty?
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_E88E3DF55F52'))
        return
      end

      if normalize_ar(old_name) == normalize_ar(new_name)
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_440AF7F09782'))
        return
      end

      source = exact_model_material(old_name)
      unless source
        UI.messagebox(tr("لم يتم العثور على خامة باسم #{old_name} داخل الموديل."))
        return
      end

      if exact_model_material(new_name)
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_AB2B282C5D8D'))
        return
      end

      d = dc
      unless d
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_8D1A22F4D18F'))
        return
      end

      execute_js(tr("updateBusy('جاري قراءة الخامة والوحدات...', 16);"))
      current_model.start_operation('MHDESIGN Rename Material', true)

      execute_js(tr("updateBusy('جاري تغيير اسم الخامة...', 32);"))
      source.name = new_name

      execute_js(tr("updateBusy('جاري تحديث خصائص الوحدات...', 48);"))
      touched = []
      all_model_component_instances.each do |ent|
        next unless ent && ent.valid?

        changed_entity = false

        %w[door carcass back drawer].each do |scan_target|
          dc_material_attributes(ent, scan_target).each do |attr|
            current = current_dc_material_name(d, ent, attr['key'])

            if current.to_s == old_name
              apply_dc_attribute(d, ent, attr['key'], new_name)
              changed_entity = true
            end

            rename_dc_material_option(ent, attr['key'], old_name, new_name)
          end
        end

        touched << ent if changed_entity
      end

      execute_js(tr("updateBusy('جاري إعادة رسم الوحدات...', 66);"))
      redraw_entities(touched)

      execute_js(tr("updateBusy('جاري تحديث شريط قطع المستوى...', 78);"))
      level_entities = find_level_entities(level)

      if target == 'door'
        sync_level_band_material(level, source, level_entities)
      elsif target == 'carcass'
        sync_level_chassis_band_material(level, source, level_entities)
      end

      execute_js(tr("updateBusy('جاري حفظ التعديلات...', 92);"))
      current_model.commit_operation
      current_model.active_view.invalidate

      push_state
      push_material_name_choices(level_id, target)
      execute_js(tr("finishMaterialManagement(#{js_json(new_name)}, #{js_json("تم تغيير اسم الخامة من #{old_name} إلى #{new_name} وتحديث #{touched.length} وحدة")});"))
    rescue => e
      current_model.abort_operation rescue nil
      execute_js("finishBusy(false, #{js_json("حدث خطأ أثناء تغيير اسم الخامة: #{e.message}")});")
      UI.messagebox(tr("حدث خطأ أثناء تغيير اسم الخامة:\n#{e.message}"))
    end

    def redraw_entities(entities)
      d = dc
      return unless d
      entities.each do |ent|
        next unless ent && ent.valid?
        begin
          # redraw يقوم بتقييم معادلات الـDynamic Component.
          # تشغيل run_all_formulas قبله كان يكرر نفس الحمل مرتين.
          d.redraw(ent, false, false)
          d.update_last_sizes(ent) if d.respond_to?(:update_last_sizes)
        rescue => e
          puts "MHDESIGN Level Material Redraw: #{e.message}"
        end
      end
      begin
        d.refresh_dialogs
        d.refresh_configure_dialog
      rescue
      end
    end

    # --------------------------- Material library ---------------------------

    def materials_folder
      Sketchup.read_default(PLUGIN_NAME, PREF_KEY, '').to_s
    rescue
      ''
    end

    def choose_materials_folder
      folder = UI.select_directory(title: tr('اختيار مجلد مكتبة الخامات'), directory: materials_folder)
      return unless folder && File.directory?(folder)
      Sketchup.write_default(PLUGIN_NAME, PREF_KEY, folder)
      @material_cache.clear
      push_library
    end

    def setting_path(image_path)
      "#{image_path}.mhd.json"
    end

    def default_material_setting
      { 'width_cm' => 100.0, 'height_cm' => 100.0, 'rotation' => 0 }
    end

    def read_material_setting(image_path)
      path = setting_path(image_path)
      return default_material_setting unless File.file?(path)
      data = JSON.parse(File.read(path, encoding: 'UTF-8'))
      default_material_setting.merge(data)
    rescue
      default_material_setting
    end

    def save_material_setting(image_path, data)
      result = default_material_setting.merge(data || {})
      result['width_cm'] = [[result['width_cm'].to_f, 0.1].max, 100000.0].min
      result['height_cm'] = [[result['height_cm'].to_f, 0.1].max, 100000.0].min
      result['rotation'] = [0, 90, 180, 270].include?(result['rotation'].to_i) ? result['rotation'].to_i : 0
      File.write(setting_path(image_path), JSON.pretty_generate(result), mode: 'w:UTF-8')
      @material_cache.delete(image_path)
      result
    end

    def scan_library
      root = materials_folder
      return { 'root' => '', 'categories' => [] } unless File.directory?(root)

      categories = Dir.children(root).sort.filter_map do |folder_name|
        folder_path = File.join(root, folder_name)
        next unless File.directory?(folder_path)
        images = Dir.children(folder_path).sort.filter_map do |filename|
          path = File.join(folder_path, filename)
          next unless File.file?(path) && SUPPORTED_IMAGES.include?(File.extname(path).downcase)
          setting = read_material_setting(path)
          {
            'id' => Digest::SHA1.hexdigest(path),
            'name' => File.basename(filename, File.extname(filename)),
            'category' => folder_name,
            'path' => path,
            'url' => file_url(path),
            'width_cm' => setting['width_cm'],
            'height_cm' => setting['height_cm'],
            'rotation' => setting['rotation']
          }
        end
        next if images.empty?
        { 'name' => folder_name, 'images' => images }
      end
      { 'root' => root, 'categories' => categories }
    rescue => e
      puts "MHDESIGN Material Library Scan: #{e.message}"
      { 'root' => root.to_s, 'categories' => [] }
    end

    def find_library_item(image_path)
      scan_library['categories'].each do |cat|
        item = cat['images'].find { |img| File.expand_path(img['path']) == File.expand_path(image_path.to_s) }
        return item if item
      end
      nil
    rescue
      nil
    end

    # قراءة اسم الخامة الحالي من خاصية الـ Dynamic Component من غير تغييره.
    # مثال: تظل قيمة الخاصية UVLACK، ويتم تغيير صورة خامة UVLACK نفسها فقط.
    def current_dc_material_name(d, ent, key)
      value = begin
        d.get_attribute_value(ent, key)
      rescue
        ent.get_attribute(DC_DICT, key, '')
      end

      text = value.to_s.strip
      return canonical_material_option_name(text) unless text.empty?

      formula = ent.get_attribute(DC_DICT, "_#{key}_formula", nil)
      if (formula.nil? || formula.to_s.strip.empty?) && ent.respond_to?(:definition)
        formula = ent.definition.get_attribute(DC_DICT, "_#{key}_formula", nil)
      end

      canonical_material_option_name(
        formula.to_s
          .sub(/\A=/, '')
          .sub(/\A[\"']/, '')
          .sub(/[\"']\z/, '')
          .strip
      )
    rescue
      ''
    end

    def material_matches_name?(material, wanted_name)
      return false unless material
      wanted = normalize_ar(wanted_name)
      return false if wanted.empty?

      normalize_ar(material.name) == wanted ||
        normalize_ar(material.display_name) == wanted
    rescue
      false
    end

    # البحث عن الخامة الأصلية داخل خامات الموديل مع الحفاظ على اسمها كما هو.
    def exact_model_material(wanted_name)
      current_model.materials.find do |material|
        material_matches_name?(material, wanted_name)
      end
    rescue
      nil
    end

    # جمع الخامات المستخدمة داخل الوحدة للمساعدة في العثور على خامات الوحدات القديمة.
    def collect_used_materials(entities, result, visited)
      entities.each do |entity|
        if entity.respond_to?(:material) && entity.material
          result << entity.material unless result.include?(entity.material)
        end

        if entity.is_a?(Sketchup::Face)
          result << entity.material if entity.material && !result.include?(entity.material)
          result << entity.back_material if entity.back_material && !result.include?(entity.back_material)
        elsif entity.is_a?(Sketchup::ComponentInstance)
          definition = entity.definition
          next if visited[definition.object_id]
          visited[definition.object_id] = true
          collect_used_materials(definition.entities, result, visited)
        elsif entity.is_a?(Sketchup::Group)
          key = entity.entities.object_id
          next if visited[key]
          visited[key] = true
          collect_used_materials(entity.entities, result, visited)
        end
      end
    rescue => e
      puts "MHDESIGN Used Materials Scan: #{e.message}"
    end

    def materials_used_in_component(ent)
      result = []
      result << ent.material if ent.respond_to?(:material) && ent.material
      collect_used_materials(ent.definition.entities, result, {})
      result.compact.uniq
    rescue
      []
    end

    # البحث أولاً داخل الوحدة ثم داخل الموديل، مع اشتراط تطابق الاسم نفسه.
    def find_original_material(ent, wanted_name)
      used = materials_used_in_component(ent)
      found = used.find { |material| material_matches_name?(material, wanted_name) }
      found || exact_model_material(wanted_name)
    rescue
      exact_model_material(wanted_name)
    end

    # تغيير صورة ومقاس الخامة الأصلية فقط، بدون إنشاء Material جديد وبدون إعادة تسميتها.
    def update_original_material_appearance(material, item)
      return false unless material && item

      original_name = material.name.to_s
      original_display_name = material.display_name.to_s rescue original_name

      material.texture = item['path']

      setting = read_material_setting(item['path'])
      width = setting['width_cm'].to_f.cm
      height = setting['height_cm'].to_f.cm
      width, height = height, width if [90, 270].include?(setting['rotation'].to_i)

      material.texture.size = [width, height] if material.texture

      # احتياط إضافي: لا نسمح للكود بتغيير اسم الخامة تحت أي ظرف.
      begin
        material.name = original_name unless material.name.to_s == original_name
      rescue
      end

      puts "MHDESIGN updated material appearance: #{original_display_name}"
      true
    rescue => e
      puts "MHDESIGN Update Original Material Error: #{e.message}"
      false
    end

    def copy_material_appearance(source, target)
      return false unless source && target
      return false if source == target

      begin
        target.color = source.color
      rescue
      end

      begin
        target.alpha = source.alpha
      rescue
      end

      begin
        if source.respond_to?(:colorize_type) && target.respond_to?(:colorize_type=)
          target.colorize_type = source.colorize_type
        end
      rescue
      end

      source_texture = source.texture

      unless source_texture
        begin
          target.texture = nil
        rescue
        end
        return true
      end

      # نحفظ المقاس الحقيقي قبل نسخ الصورة؛ لأن width/height قد تكون أبعاد بكسل
      # في بعض إصدارات SketchUp، بينما size يعيد أبعاد الخامة داخل الموديل.
      texture_size = begin
        source_texture.respond_to?(:size) ? source_texture.size : nil
      rescue
        nil
      end

      texture_file = source_texture.filename.to_s
      temp_file = nil

      # الخامات المدمجة داخل ملف SKP كثيرًا ما ترجع filename فارغًا.
      # لذلك نستخرج الصورة مؤقتًا ثم نستخدمها لإنشاء Texture حقيقية للنسخة.
      if texture_file.empty? || !File.file?(texture_file)
        begin
          extension = File.extname(texture_file)
          extension = '.png' if extension.empty?
          temp_file = File.join(
            Dir.tmpdir,
            "mhdesign_material_duplicate_#{Process.pid}_#{Time.now.to_i}_#{rand(1_000_000)}#{extension}"
          )

          if source_texture.respond_to?(:write)
            source_texture.write(temp_file)
          elsif source.respond_to?(:write_thumbnail)
            source.write_thumbnail(temp_file, 512)
          end

          texture_file = temp_file if File.file?(temp_file)
        rescue => e
          puts "MHDESIGN Embedded Texture Export Warning: #{e.message}"
        end
      end

      if !texture_file.empty? && File.file?(texture_file)
        begin
          target.texture = texture_file

          if target.texture
            if texture_size && texture_size.respond_to?(:[]) && texture_size[0] && texture_size[1]
              target.texture.size = [texture_size[0], texture_size[1]]
            else
              begin
                target.texture.size = [source_texture.width, source_texture.height]
              rescue
              end
            end
          end
        rescue => e
          puts "MHDESIGN Texture Duplicate Warning: #{e.message}"
          return false
        ensure
          begin
            File.delete(temp_file) if temp_file && File.file?(temp_file)
          rescue
          end
        end
      else
        puts "MHDESIGN Texture Duplicate Warning: texture image could not be extracted"
        return false
      end

      true
    rescue => e
      puts "MHDESIGN Copy Material Appearance Error: #{e.message}"
      false
    end

    def band_material_name_matches?(material, wanted_name)
      return false unless material

      wanted = normalize_ar(wanted_name)
      return false if wanted.empty?

      normalize_ar(material.display_name) == wanted ||
        normalize_ar(material.name) == wanted
    rescue
      false
    end

    def door_band_material?(material)
      DOOR_BAND_MATERIAL_NAMES.any? do |name|
        band_material_name_matches?(material, name)
      end
    rescue
      false
    end

    def level_band_material_name(level_name)
      clean = clean_material_name(level_name)
      clean = 'المستوى' if clean.empty?
      "شريط حرف لون #{clean}"
    end

    def level_chassis_band_material_name(level_name)
      clean = clean_material_name(level_name)
      clean = 'المستوى' if clean.empty?
      "شريط شاسيه #{clean}"
    end

    # --------------------------- Fast name-based piece search ---------------------------
    #
    # بدل فحص خامة كل Definition وحساب مساحات الـFaces، نعتمد على أسماء القطع
    # المستخدمة بالفعل في كود التقارير. هذا أسرع كثيرًا، ويحافظ على منطق
    # "الجنب الظاهر" المنفصل كما هو بدون تغيير.

    def piece_definition_name(entity)
      return '' unless entity

      if entity.is_a?(Sketchup::ComponentInstance)
        MHDESIGN::Language.original_definition_name(entity.definition).to_s
      elsif entity.is_a?(Sketchup::Group)
        entity.name.to_s
      else
        ''
      end
    rescue
      ''
    end

    def canonical_piece_name(entity_or_name)
      raw =
        if entity_or_name.is_a?(String)
          entity_or_name
        else
          piece_definition_name(entity_or_name)
        end

      text = clean_material_name(raw)
      text = text.gsub(/\s*#\d+\s*$/, '')
      text = text.gsub(/\s*\(\s*/, '(')
      text = text.gsub(/\s*\)\s*/, ')')
      text = text.gsub(/\s+/, ' ')
      text = text.gsub(/\s+\(/, '(')
      normalize_ar(text)
    rescue
      normalize_ar(entity_or_name.to_s)
    end

    def report_piece_role(entity_or_name)
      name = canonical_piece_name(entity_or_name)

      # الجنب الظاهر يحتفظ بالنظام الذكي المستقل.
      return :visible_side if name.include?(normalize_ar('جنب ظاهر'))

      # قطع الضلفة حسب النظام الفعلي:
      # أي ضلفة، وش درج، وش تهوية، والفيلرات.
      return :door if name.include?(normalize_ar('ضلفه'))
      return :door if name.include?(normalize_ar('ضلفة'))
      return :door if name.include?(normalize_ar('وش درج'))
      return :door if name.include?(normalize_ar('وش تهويه'))
      return :door if name.include?(normalize_ar('وش تهوية'))
      return :door if name.include?(normalize_ar('فيلر'))

      has_chassis_word =
        name.include?(normalize_ar('شاسيه')) ||
        name.include?(normalize_ar('شاسه'))

      has_back_word =
        name.include?(normalize_ar('ضهر')) ||
        name.include?(normalize_ar('ظهر'))

      # مطابق لمنطق كود التقارير:
      # ضهر الشاسيه الداخلي يُعامل كقطعة شاسيه.
      return :chassis if has_chassis_word && has_back_word

      # الضهر الحقيقي وقاعدة الدرج لا يتبعان شريط الشاسيه.
      return :back if has_back_word
      return :back if name.include?(normalize_ar('قاعده الدرج'))
      return :back if name.include?(normalize_ar('قاعدة الدرج'))

      # نفس منطق التقرير تمامًا:
      # أي قطعة ليست ضلفة/ضهر/جنب ظاهر/فيلر تُعتبر من الشاسيه.
      # وده يشمل: الجنب، القاعدة، القرصة، الرف، الشداد، السدة،
      # مرايا، سدابة دعم، أجزاء الشاسيه، وأي مسمى جديد تابع للهيكل.
      :chassis
    rescue
      :chassis
    end

    def collect_band_faces_inside_piece(entity, assignments, visited_definitions)
      return unless entity && entity.valid?
      return unless entity.respond_to?(:definition) && entity.definition

      definition = entity.definition
      key = definition.object_id
      return if visited_definitions[key]

      visited_definitions[key] = true

      definition.entities.each do |child|
        if child.is_a?(Sketchup::Face)
          front = child.material
          back  = child.back_material

          assignments << [child, :front, front] if front && generic_edge_band_material?(front)
          assignments << [child, :back, back] if back && generic_edge_band_material?(back)
          next
        end

        next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)

        # داخل القطعة المستهدفة نجمع Faces الشريط من كل الطبقات الداخلية،
        # لكن لا ندخل داخل جنب ظاهر؛ له النظام الذكي المستقل الخاص به.
        next if report_piece_role(child) == :visible_side

        collect_band_faces_inside_piece(child, assignments, visited_definitions)
      end
    rescue => e
      puts "MHDESIGN Named Piece Band Faces Error: #{e.message}"
    end

    # بحث مباشر وسريع جدًا عن خامة شريط الشاسيه الثابتة.
    #
    # لا يصنّف أسماء القطع، ولا يحسب مساحات، ولا يبحث عن الخامة الغالبة.
    # يمر على كل Definition مرة واحدة فقط ويجمع الـFaces التي تحمل بالضبط:
    # "شريط حرف ابيض"
    def collect_fixed_chassis_band_assignments(entities)
      assignments = []
      visited_definitions = {}
      wanted_names = CHASSIS_BAND_MATERIAL_NAMES.map { |name| normalize_ar(name) }

      scan = nil
      scan = lambda do |collection|
        collection.each do |entity|
          next unless entity && entity.valid?

          if entity.is_a?(Sketchup::Face)
            front = entity.material
            back  = entity.back_material

            if front && wanted_names.include?(normalize_ar(front.name.to_s))
              assignments << [entity, :front, front]
            end

            if back && wanted_names.include?(normalize_ar(back.name.to_s))
              assignments << [entity, :back, back]
            end

            next
          end

          next unless component_or_group?(entity)
          definition = entity.definition rescue nil
          next unless definition

          key = definition.object_id
          next if visited_definitions[key]

          visited_definitions[key] = true
          scan.call(definition.entities)
        end
      end

      Array(entities).each do |root|
        next unless root && root.valid?

        if root.is_a?(Sketchup::Face)
          front = root.material
          back  = root.back_material

          if front && wanted_names.include?(normalize_ar(front.name.to_s))
            assignments << [root, :front, front]
          end

          if back && wanted_names.include?(normalize_ar(back.name.to_s))
            assignments << [root, :back, back]
          end

          next
        end

        next unless component_or_group?(root)
        definition = root.definition rescue nil
        next unless definition

        key = definition.object_id
        next if visited_definitions[key]

        visited_definitions[key] = true
        scan.call(definition.entities)
      end

      assignments
    rescue => e
      puts "MHDESIGN Fixed Chassis Band Search Error: #{e.message}"
      []
    end

    def collect_named_piece_band_assignments(entities, wanted_role)
      assignments = []
      visited_search_definitions = {}
      visited_piece_definitions = {}

      search = nil
      search = lambda do |collection|
        collection.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity && entity.valid?

          role = report_piece_role(entity)

          # الجنب الظاهر لا يدخل نهائيًا في البحث العادي.
          if role == :visible_side
            next
          end

          if role == wanted_role
            before_count = assignments.length

            collect_band_faces_inside_piece(
              entity,
              assignments,
              visited_piece_definitions
            )

            # لو الاسم يخص Wrapper وليس القطعة النهائية، نكمل داخله
            # حتى نصل إلى Faces الشريط الفعلية.
            if assignments.length == before_count
              definition = entity.definition rescue nil
              if definition
                key = definition.object_id
                unless visited_search_definitions[key]
                  visited_search_definitions[key] = true
                  search.call(definition.entities)
                end
              end
            end

            next
          end

          definition = entity.definition rescue nil
          next unless definition

          key = definition.object_id
          next if visited_search_definitions[key]

          visited_search_definitions[key] = true
          search.call(definition.entities)
        end
      end

      Array(entities).each do |unit|
        next unless unit && unit.valid?
        next unless unit.respond_to?(:definition) && unit.definition

        role = report_piece_role(unit)

        if role == wanted_role
          before_count = assignments.length

          collect_band_faces_inside_piece(
            unit,
            assignments,
            visited_piece_definitions
          )

          if assignments.length == before_count
            key = unit.definition.object_id
            unless visited_search_definitions[key]
              visited_search_definitions[key] = true
              search.call(unit.definition.entities)
            end
          end
        elsif role != :visible_side
          key = unit.definition.object_id
          unless visited_search_definitions[key]
            visited_search_definitions[key] = true
            search.call(unit.definition.entities)
          end
        end
      end

      assignments
    rescue => e
      puts "MHDESIGN Named Piece Band Scan Error: #{e.message}"
      []
    end

    # --------------------------- Material-based band search ---------------------------
    #
    # لا نعتمد هنا على أسماء القطع مثل:
    # ضلفة / وش درج / وش تهوية فرن.
    #
    # يتم فحص كل Definition فعلي يحتوي Faces، ثم:
    # 1) نحسب الخامة الأساسية من أكبر مساحة Faces غير الشريط.
    # 2) لو الخامة الأساسية تساوي الخامة التي غيّرها المستخدم،
    #    نجمع Faces الشريط الموجودة في نفس القطعة.
    # 3) الجنب الظاهر يُستثنى من هذا المرور؛ له منطقه الخاص بالأسفل.
    #
    # التعرف على خامة الشريط عام، ويقبل أي اسم يبدأ بـ "شريط حرف"،
    # وليس قائمة أسماء ثابتة لكل نوع شريط.

    def generic_edge_band_material?(material)
      return false unless material

      names = []
      names << material.display_name.to_s if material.respond_to?(:display_name)
      names << material.name.to_s if material.respond_to?(:name)

      names.any? do |name|
        normalized = normalize_ar(name)
        normalized.start_with?(normalize_ar('شريط حرف')) ||
          normalized.include?(normalize_ar('شريط حرف لون'))
      end
    rescue
      false
    end

    def direct_definition_material_profile(instance)
      definition = instance.definition
      return [nil, []] unless definition

      base_scores = Hash.new(0.0)
      band_assignments = []

      # خامة الـInstance نفسها لها أولوية قوية لو كانت خامة عادية.
      if instance.respond_to?(:material) &&
         instance.material &&
         !generic_edge_band_material?(instance.material)
        base_scores[instance.material] += 1_000_000_000.0
      end

      definition.entities.each do |entity|
        next unless entity.is_a?(Sketchup::Face)

        area = entity.area.to_f
        area = 1.0 if area <= 0.0

        front = entity.material
        back  = entity.back_material

        if front
          if generic_edge_band_material?(front)
            band_assignments << [entity, :front, front]
          else
            base_scores[front] += area
          end
        end

        if back
          if generic_edge_band_material?(back)
            band_assignments << [entity, :back, back]
          else
            base_scores[back] += area
          end
        end
      end

      base_material = base_scores.max_by { |_material, score| score }&.first
      [base_material, band_assignments]
    rescue => e
      puts "MHDESIGN Definition Material Profile Error: #{e.message}"
      [nil, []]
    end

    def collect_material_matched_band_assignments(entities, source_material, exclude_visible_side = true)
      return [] unless source_material

      assignments = []
      visited_definitions = {}

      scan = nil
      scan = lambda do |collection|
        collection.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)

          definition = entity.definition
          next unless definition

          definition_key = definition.object_id

          unless visited_definitions[definition_key]
            visited_definitions[definition_key] = true

            is_visible_side =
              exclude_visible_side &&
              visible_side_definition?(definition, entity)

            unless is_visible_side
              base_material, local_assignments = direct_definition_material_profile(entity)

              if same_material_identity?(base_material, source_material)
                assignments.concat(local_assignments)
              end
            end

            # نستمر داخل كل القطع Nested، لأن كل Definition يُقيّم منفصلًا
            # حسب خامته الفعلية، وليس حسب اسم الأب.
            scan.call(definition.entities)
          end
        end
      end

      Array(entities).each do |unit|
        next unless unit && unit.valid?
        next unless unit.respond_to?(:definition) && unit.definition

        unit_key = unit.definition.object_id

        unless visited_definitions[unit_key]
          visited_definitions[unit_key] = true

          is_visible_side =
            exclude_visible_side &&
            visible_side_definition?(unit.definition, unit)

          unless is_visible_side
            base_material, local_assignments = direct_definition_material_profile(unit)

            if same_material_identity?(base_material, source_material)
              assignments.concat(local_assignments)
            end
          end

          scan.call(unit.definition.entities)
        end
      end

      assignments
    rescue => e
      puts "MHDESIGN Material Matched Band Scan Error: #{e.message}"
      []
    end

    def dominant_band_from_assignments(assignments)
      counts = Hash.new(0)

      assignments.each do |_face, _side, material|
        counts[material] += 1 if material
      end

      counts.max_by { |_material, count| count }&.first
    rescue => e
      puts "MHDESIGN Dominant Band Error: #{e.message}"
      nil
    end

    def replace_cached_band_assignments(assignments, _source_band, replacement)
      changed = 0

      assignments.each do |face, side, old_material|
        next unless face && face.valid?
        next unless old_material
        next if old_material == replacement

        # كل خامات الشريط التي تم اكتشافها داخل ضلف ووشوش أدراج المستوى
        # تتحول إلى خامة مستوى واحدة، مهما كانت خاماتها الأصلية مختلفة.
        if side == :back
          face.back_material = replacement
        else
          face.material = replacement
        end

        changed += 1
      end

      changed
    rescue => e
      puts "MHDESIGN Replace Cached Band Error: #{e.message}"
      changed || 0
    end

    # المنطق السريع:
    #
    # أول مرة فقط:
    # - مرور واحد داخل دفنشنات الضلف ووشوش الأدراج فقط.
    # - نحفظ كل Face عليه خامة شريط في الذاكرة.
    # - نستخدم خامة الشريط الغالبة فقط كمصدر لإنشاء Duplicate SKM.
    # - بعد ذلك نبدل كل Faces الشريط المحفوظة بخامة المستوى الواحدة،
    #   حتى لو كانت خاماتها الأصلية مختلفة.
    # - لا يوجد Traverse ثانٍ.
    #
    # بعد إنشاء خامة المستوى:
    # - لا يتم فحص أي Face.
    # - يتم تحديث Appearance لخامة المستوى مباشرة.
    #
    # لا Make Unique ولا تعديل للخامات الأصلية.
    # --------------------------- Chassis band appearance ---------------------------
    #
    # لا نعتمد على اسم ثابت مثل "شريط حرف ابيض".
    # نبحث عن كل قطعة خامتها الأساسية تساوي خامة الشاسيه،
    # ثم نغيّر Appearance لكل خامة شريط مستخدمة داخل هذه القطعة،
    # مع الإبقاء على اسم خامة الشريط كما هو.

    def sync_chassis_band_materials(entities, preferred_source = nil, material_name = nil)
      # توافق خلفي فقط: هذه الدالة القديمة لا تعرف المستوى،
      # لذلك تكتفي بتحديث الخامات الموجودة دون إنشاء خامة مستوى.
      changed = 0

      Array(entities).each do |ent|
        next unless ent && ent.valid?

        source = preferred_source

        if source.nil? && material_name && !material_name.to_s.strip.empty?
          source = find_original_material(ent, material_name)
          source ||= exact_model_material(material_name)
        end

        next unless source

        assignments = collect_material_matched_band_assignments([ent], source, true)
        assignments.map { |_face, _side, material| material }.compact.uniq.each do |target|
          next if target == source
          changed += 1 if copy_material_appearance(source, target)
        end
      end

      current_model.active_view.invalidate if changed > 0
      changed
    rescue => e
      puts "MHDESIGN Chassis Band Sync Error: #{e.message}"
      changed || 0
    end

    # خامة شاسيه مستقلة لكل مستوى.
    #
    # أول مرة:
    # - بحث فعلي داخل وحدات المستوى
    # - Duplicate لخامة الشريط المستخدمة
    # - إعادة ربط Faces بخامة: "خامة شاسيه <اسم المستوى>"
    #
    # بعد ذلك:
    # - لا بحث ولا إعادة ربط
    # - تحديث Appearance فقط بالاسم المباشر
    def sync_level_chassis_band_material(level, source_material, entities)
      return 0 unless level && source_material

      final_name = level_chassis_band_material_name(level['name'])
      target_band = exact_model_material(final_name)

      # بعد أول تجهيز: تحديث مباشر للخامة فقط، بدون أي بحث.
      if target_band
        changed = copy_material_appearance(source_material, target_band) ? 1 : 0
        current_model.active_view.invalidate if changed > 0
        puts "MHDESIGN fast-updated #{final_name} without chassis search"
        return changed
      end

      valid_entities = Array(entities).select { |entity| entity && entity.valid? }
      return 0 if valid_entities.empty?

      # أول مرة فقط: بحث مباشر عن الاسم الثابت "شريط حرف ابيض".
      # لا يوجد تصنيف قطع، ولا حساب مساحات، ولا بحث عن خامة غالبة.
      assignments = collect_fixed_chassis_band_assignments(valid_entities)

      if assignments.empty?
        puts 'MHDESIGN Level Chassis Band: fixed material "شريط حرف ابيض" was not found'
        return 0
      end

      source_band = CHASSIS_BAND_MATERIAL_NAMES.lazy.map do |name|
        exact_model_material(name)
      end.find { |material| material }

      # احتياطي: نأخذ الخامة من أول Face تم اكتشافه.
      source_band ||= assignments.first[2] rescue nil

      unless source_band
        puts 'MHDESIGN Level Chassis Band: source material was not found'
        return 0
      end

      target_band, error = duplicate_model_material(source_band.name.to_s, final_name)
      raise error if error
      raise MHDESIGN::Language.for_tool('materials').t('TEXT_114FEF34DE17') unless target_band

      changed = replace_cached_band_assignments(assignments, nil, target_band)
      copy_material_appearance(source_material, target_band)

      current_model.active_view.invalidate

      puts(
        "MHDESIGN prepared #{final_name} by fixed-name search; " \
        "matched #{assignments.length} assignments and changed #{changed}"
      )

      changed
    rescue => e
      puts "MHDESIGN Level Chassis Band Sync Error: #{e.message}"
      0
    end

    # --------------------------- Visible side exception ---------------------------
    #
    # كل منطق شريط المستوى الأصلي يظل كما هو.
    # الاستثناء الوحيد: أي قطعة اسمها "جنب ظاهر" يكون لها شريط مستقل
    # يأخذ شكل خامة الجنب الظاهر نفسها، وليس خامة ضلفة المستوى.
    #
    # مثال:
    #   خامة الجنب الظاهر = HPL
    #   خامة الشريط = شريط حرف لون جنب ظاهر HPL

    def visible_side_definition?(definition, instance = nil)
      names = []
      names << definition.name.to_s if definition
      names << instance.name.to_s if instance && instance.respond_to?(:name)

      normalize_ar(names.join(' ')).include?(normalize_ar('جنب ظاهر'))
    rescue
      false
    end

    def any_edge_band_material?(material)
      generic_edge_band_material?(material)
    rescue
      false
    end

    def visible_side_band_material_name(base_material)
      base_name = clean_material_name(
        base_material.respond_to?(:display_name) ? base_material.display_name.to_s : base_material.name.to_s
      )
      base_name = clean_material_name(base_material.name.to_s) if base_name.empty?
      base_name = 'خامة' if base_name.empty?

      "شريط حرف لون جنب ظاهر #{base_name}"
    rescue
      'شريط حرف لون جنب ظاهر'
    end

    # قراءة خامة الجنب الظاهر الفعلية، وجمع أسطح الشريط الموجودة داخله.
    # الخامة الأساسية هي أكبر خامة غير شريط من حيث مساحة الأسطح.
    def inspect_visible_side_piece(instance)
      definition = instance.definition
      return [nil, []] unless definition

      base_scores = Hash.new(0.0)
      band_assignments = []
      visited = {}

      if instance.respond_to?(:material) && instance.material && !any_edge_band_material?(instance.material)
        base_scores[instance.material] += 1_000_000_000.0
      end

      scan = nil
      scan = lambda do |collection|
        collection.each do |entity|
          if entity.is_a?(Sketchup::Face)
            area = entity.area.to_f
            area = 1.0 if area <= 0.0

            front = entity.material
            back  = entity.back_material

            if front
              if any_edge_band_material?(front)
                band_assignments << [entity, :front, front]
              else
                base_scores[front] += area
              end
            end

            if back
              if any_edge_band_material?(back)
                band_assignments << [entity, :back, back]
              else
                base_scores[back] += area
              end
            end

            next
          end

          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)

          if entity.respond_to?(:material) && entity.material && !any_edge_band_material?(entity.material)
            base_scores[entity.material] += 1_000_000.0
          end

          nested_definition = entity.definition
          next unless nested_definition

          key = nested_definition.object_id
          next if visited[key]

          visited[key] = true
          scan.call(nested_definition.entities)
        end
      end

      visited[definition.object_id] = true
      scan.call(definition.entities)

      base_material = base_scores.max_by { |_material, score| score }&.first
      [base_material, band_assignments]
    rescue => e
      puts "MHDESIGN Visible Side Inspect Error: #{e.message}"
      [nil, []]
    end

    def collect_visible_side_instances(level_entities)
      result = []
      visited_search_definitions = {}
      visited_visible_definitions = {}

      search = nil
      search = lambda do |collection|
        collection.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)

          definition = entity.definition
          next unless definition

          if visible_side_definition?(definition, entity)
            key = definition.object_id
            next if visited_visible_definitions[key]

            visited_visible_definitions[key] = true
            result << entity
            next
          end

          key = definition.object_id
          next if visited_search_definitions[key]

          visited_search_definitions[key] = true
          search.call(definition.entities)
        end
      end

      Array(level_entities).each do |unit|
        next unless unit && unit.valid?
        next unless unit.respond_to?(:definition) && unit.definition

        if visible_side_definition?(unit.definition, unit)
          key = unit.definition.object_id
          next if visited_visible_definitions[key]

          visited_visible_definitions[key] = true
          result << unit
        else
          key = unit.definition.object_id
          next if visited_search_definitions[key]

          visited_search_definitions[key] = true
          search.call(unit.definition.entities)
        end
      end

      result
    rescue => e
      puts "MHDESIGN Visible Side Collect Error: #{e.message}"
      []
    end

    def same_material_identity?(material_a, material_b)
      return false unless material_a && material_b
      return true if material_a == material_b

      name_a = material_a.respond_to?(:display_name) ? material_a.display_name.to_s : material_a.name.to_s
      name_b = material_b.respond_to?(:display_name) ? material_b.display_name.to_s : material_b.name.to_s

      name_a = material_a.name.to_s if name_a.empty?
      name_b = material_b.name.to_s if name_b.empty?

      normalize_ar(clean_material_name(name_a)) == normalize_ar(clean_material_name(name_b))
    rescue
      false
    end

    def sync_visible_side_band_materials(entities, level_source_material, level_target_band)
      changed_total = 0

      collect_visible_side_instances(entities).each do |visible_side|
        base_material, assignments = inspect_visible_side_piece(visible_side)
        next unless base_material
        next if assignments.empty?

        # لو خامة الجنب الظاهر هي نفسها خامة ضلفة المستوى:
        # يدخل مع شريط المستوى العادي ولا ننشئ له خامة مستقلة.
        if same_material_identity?(base_material, level_source_material)
          next unless level_target_band

          changed = replace_cached_band_assignments(assignments, nil, level_target_band)
          changed_total += changed

          puts(
            "MHDESIGN visible side joined level band: #{level_target_band.name}; " \
            "cached #{assignments.length} assignments and changed #{changed}"
          )
          next
        end

        # لو خامته مختلفة عن خامة الضلفة:
        # نبحث في الموديل كله عن شريط جنب ظاهر يحمل نفس اسم خامته.
        # لو موجود نستخدمه، ولو غير موجود ننشئه مرة واحدة فقط.
        final_name = visible_side_band_material_name(base_material)
        target_band = exact_model_material(final_name)

        unless target_band
          source_band = dominant_band_from_assignments(assignments)
          next unless source_band

          target_band, error = duplicate_model_material(source_band.name.to_s, final_name)
          raise error if error
          next unless target_band
        end

        changed = replace_cached_band_assignments(assignments, nil, target_band)
        changed_total += changed

        # خامة شريط الجنب الظاهر تأخذ شكل خامة الجنب الظاهر نفسها.
        copy_material_appearance(base_material, target_band)

        puts(
          "MHDESIGN visible side separate band: #{final_name}; " \
          "cached #{assignments.length} assignments and changed #{changed}"
        )
      end

      current_model.active_view.invalidate if changed_total > 0
      changed_total
    rescue => e
      puts "MHDESIGN Visible Side Band Sync Error: #{e.message}"
      changed_total || 0
    end

    def sync_level_band_material(level, source_material, entities)
      return 0 unless level && source_material

      # أهم خطوة: عزل Definitions الخاصة بوحدات هذا المستوى.
      # بدونها تكون Faces الشريط مشتركة بين المستوى الأول والثاني.
      entities = ensure_level_geometry_unique!(level, entities)

      final_name = level_band_material_name(level['name'])
      target_band = exact_model_material(final_name)

      # نجمع Faces الشريط من وحدات المستوى الحالي فقط بعد عزلها.
      # لا نستخدم المسار السريع القديم؛ لأن وجود خامة المستوى لا يضمن
      # أن Faces هذا المستوى مرتبطة بها فعلًا.
      assignments = collect_named_piece_band_assignments(
        entities,
        :door
      )

      if assignments.empty?
        puts 'MHDESIGN Level Band: no material-matched band faces found'
        return 0
      end

      unless target_band
        source_band = dominant_band_from_assignments(assignments)
        unless source_band
          puts 'MHDESIGN Level Band: no source band material found'
          return 0
        end

        target_band, error = duplicate_model_material(source_band.name.to_s, final_name)
        raise error if error
        raise MHDESIGN::Language.for_tool('materials').t('TEXT_761946907F48') unless target_band
      end

      # إعادة ربط جميع Faces الشريط المكتشفة بخامة المستوى الحالية.
      # هذا يعالج أيضًا أي مستوى سبق أن أخذ شريط مستوى آخر بالخطأ.
      changed = replace_cached_band_assignments(assignments, nil, target_band)
      copy_material_appearance(source_material, target_band)

      visible_changed = sync_visible_side_band_materials(
        entities,
        source_material,
        target_band
      )

      current_model.active_view.invalidate

      puts(
        "MHDESIGN synced #{final_name}; " \
        "matched #{assignments.length} band assignments and changed #{changed}"
      )

      changed + visible_changed
    rescue => e
      puts "MHDESIGN Level Band Sync Error: #{e.message}"
      0
    end

    def apply_material(level_id, target, image_path)
      item = find_library_item(image_path)
      unless item
        execute_js(tr("finishBusy(false, 'تعذر العثور على ملف الخامة داخل المكتبة.');"))
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_DB93DB9350FF'))
        return
      end

      level = levels.find { |x| x['id'].to_s == level_id.to_s }
      unless level
        execute_js(tr("finishBusy(false, 'تعذر العثور على المستوى.');"))
        return
      end

      entities = find_level_entities(level)
      if entities.empty?
        execute_js(tr("finishBusy(false, 'المستوى لا يحتوي على وحدات صالحة.');"))
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_0A7649E4132D'))
        return
      end

      d = dc
      unless d
        execute_js(tr("finishBusy(false, 'Dynamic Components غير محمل.');"))
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_8D1A22F4D18F'))
        return
      end

      execute_js(tr("updateBusy('جاري قراءة خامات المستوى...', 18);"))
      current_model.start_operation('MHDESIGN Change Existing Material Texture', true)

      materials_to_update = []
      missing_units = []

      level_door_material_name =
        if target == 'carcass'
          level_actual_door_material_name(entities)
        else
          ''
        end

      entities.each do |ent|
        attrs = dc_material_attributes(ent, target)

        if attrs.empty?
          missing_units << ent
          next
        end

        unit_found = false

        attrs.each do |attr|
          current_name = current_dc_material_name(d, ent, attr['key'])
          next if current_name.empty?

          if target == 'carcass' &&
             canonical_material_option_name(current_name) == 'بنفس خامة الضلفه' &&
             !level_door_material_name.to_s.strip.empty?
            current_name = level_door_material_name
          end

          material = find_original_material(ent, current_name)
          next unless material

          materials_to_update << material unless materials_to_update.include?(material)
          unit_found = true
        end

        missing_units << ent unless unit_found
      end

      execute_js(tr("updateBusy('جاري تطبيق الخامة الجديدة...', 42);"))

      changed = materials_to_update.count do |material|
        update_original_material_appearance(material, item)
      end

      source_material = materials_to_update.first

      if target == 'door' && source_material
        band_name = level_band_material_name(level['name'])

        if exact_model_material(band_name)
          execute_js(tr("updateBusy('جاري تحديث شريط قطع المستوى...', 72);"))
        else
          execute_js(tr("updateBusy('جاري تحديث شريط قطع المستوى...', 62);"))
        end

        sync_level_band_material(level, source_material, entities)

      elsif target == 'carcass' && source_material
        band_name = level_chassis_band_material_name(level['name'])

        if exact_model_material(band_name)
          execute_js(tr("updateBusy('جاري تحديث خامة شاسيه المستوى...', 72);"))
        else
          execute_js(tr("updateBusy('جاري تحديث شريط الشاسيه...', 62);"))
        end

        sync_level_chassis_band_material(level, source_material, entities)
      else
        execute_js(tr("updateBusy('جاري تحديث العرض...', 78);"))
      end

      level['last_target'] = target
      save_levels(levels)

      execute_js(tr("updateBusy('جاري إنهاء التحديث...', 92);"))

      current_model.commit_operation
      current_model.active_view.invalidate
      push_state

      if changed > 0
        names = materials_to_update.map { |m| m.display_name.to_s rescue m.name.to_s }.uniq.join('، ')
        execute_js(tr("finishBusy(true, #{js_json("تم تطبيق الخامة بنجاح: #{names}")});"))
      else
        execute_js(tr("finishBusy(false, 'لم يتم العثور على الخامة الأصلية داخل الموديل.');"))
      end

      if changed == 0
        UI.messagebox(MHDESIGN::Language.for_tool('materials').t('TEXT_4EC5ED34E854'))
      elsif !missing_units.empty?
        UI.messagebox(tr("تم تغيير صورة #{changed} خامة أصلية، و#{missing_units.uniq.length} وحدة لم توجد بها خامة مطابقة."))
      end
    rescue => e
      current_model.abort_operation rescue nil
      execute_js(tr("finishBusy(false, #{js_json("حدث خطأ أثناء تطبيق الخامة: #{e.message}")});"))
      UI.messagebox(tr("حدث خطأ أثناء تغيير صورة الخامة الأصلية:\n#{e.message}"))
    end

    # --------------------------- Dialog communication ---------------------------

    # --------------------------- Rotate face texture ---------------------------

    class RotateFaceTextureTool
      def initialize(owner)
        @owner = owner
        @ip = Sketchup::InputPoint.new
        @hover_face = nil
      end

      def activate
        Sketchup.set_status_text(
          'اضغط على الفيس المطلوب لتدوير خامته 90 درجة. اضغط Esc للإنهاء.',
          SB_PROMPT
        )
      end

      def deactivate(view)
        @hover_face = nil
        view.invalidate if view
        @owner.texture_rotate_tool_finished
      rescue
      end

      def onCancel(_reason, view)
        Sketchup.active_model.select_tool(nil)
        view.invalidate if view
      rescue
      end

      def onMouseMove(_flags, x, y, view)
        @ip.pick(view, x, y)
        @hover_face = @ip.face
        view.tooltip = @hover_face ? 'تدوير خامة هذا الفيس 90°' : 'اختر فيس عليه خامة'
        view.invalidate
      rescue
        @hover_face = nil
      end

      def draw(view)
        return unless @hover_face && @hover_face.valid?

        points = @hover_face.vertices.map do |vertex|
          vertex.position.transform(@ip.transformation)
        end
        return if points.length < 3

        view.drawing_color = Sketchup::Color.new(35, 165, 255)
        view.line_width = 3
        view.draw(GL_LINE_LOOP, points)
      rescue
      end

      def onLButtonDown(_flags, x, y, view)
        @ip.pick(view, x, y)
        face = @ip.face

        unless face && face.valid?
          UI.beep
          Sketchup.set_status_text('لازم تضغط على فيس عليه خامة.', SB_PROMPT)
          return
        end

        result = @owner.rotate_texture_on_face(face, @ip.instance_path, @ip.position, @ip.transformation)
        if result
          Sketchup.set_status_text(
            'تم تدوير خامة الفيس 90°. اختر فيس آخر أو اضغط Esc للإنهاء.',
            SB_PROMPT
          )
        end
        view.invalidate
      rescue => e
        UI.messagebox("#{MHDESIGN::Language.for_tool('materials').t('TEXT_0C1D73CF5FDE')}#{e.message}")
      end
    end

    def start_texture_rotate_tool
      model = current_model
      @texture_rotate_tool = RotateFaceTextureTool.new(self)
      model.select_tool(@texture_rotate_tool)
      execute_js("textureRotateStarted();")
    rescue => e
      execute_js(tr("textureRotateFailed(#{js_json("تعذر تشغيل أداة تدوير الخامة: #{e.message}")});"))
    end

    def texture_rotate_tool_finished
      @texture_rotate_tool = nil
      Sketchup.set_status_text('', SB_PROMPT)
      execute_js("textureRotateEnded();")
    rescue
    end

    def textured_face_material(face, instance_path = nil, preferred_front = true)
      front = face.material
      back = face.back_material

      return [front, true, false] if front && front.texture
      return [back, false, false] if back && back.texture

      # لو الخامة جاية من Group أو Component أب، نستخدمها على الناحية
      # الظاهرة التي ضغط عليها المستخدم فقط.
      path = []
      begin
        path = instance_path.to_a if instance_path
      rescue
        path = []
      end

      path.reverse_each do |entity|
        next if entity == face
        next unless entity.respond_to?(:material)

        material = entity.material
        return [material, preferred_front, true] if material && material.texture
      end

      [nil, preferred_front, false]
    rescue
      [nil, preferred_front, false]
    end

    def face_mapping_points(face)
      vertices = face.outer_loop.vertices
      return nil if vertices.length < 3

      p1 = vertices[0].position
      p2 = nil
      p3 = nil

      vertices[1..-1].each do |vertex|
        candidate = vertex.position
        next if candidate.distance(p1) < 0.001
        p2 = candidate
        break
      end
      return nil unless p2

      base = p2 - p1
      vertices[1..-1].each do |vertex|
        candidate = vertex.position
        cross = base.cross(candidate - p1)
        if cross.length > 0.000001
          p3 = candidate
          break
        end
      end

      p3 ? [p1, p2, p3] : nil
    rescue
      nil
    end

    def uv_point_from_uvq(uvq)
      q = uvq.z.to_f
      q = 1.0 if q.abs < 0.0000001
      Geom::Point3d.new(uvq.x.to_f / q, uvq.y.to_f / q, 1.0)
    end

    def rotate_uv_visually_90(uv, center_u, center_v, texture_width, texture_height)
      width = texture_width.to_f
      height = texture_height.to_f
      width = 1.0 if width.abs < 0.000001
      height = 1.0 if height.abs < 0.000001

      # UV ليست مسافات متساوية عندما تكون صورة الخامة مستطيلة.
      # نحولها أولاً إلى المقاس الفعلي للخامة، نلف 90°، ثم نعيدها إلى UV.
      # بهذه الطريقة اتجاه الخامة يتغير لكن حجمها الحقيقي لا يتغير.
      du_real = (uv.x.to_f - center_u) * width
      dv_real = (uv.y.to_f - center_v) * height

      rotated_u = center_u - (dv_real / width)
      rotated_v = center_v + (du_real / height)

      Geom::Point3d.new(rotated_u, rotated_v, 1.0)
    end

    def clicked_face_front?(face, clicked_point = nil, instance_transform = nil)
      transform = instance_transform || Geom::Transformation.new
      world_point =
        if clicked_point
          clicked_point
        else
          face.bounds.center.transform(transform)
        end

      world_normal = face.normal.transform(transform)
      to_camera = current_model.active_view.camera.eye - world_point
      world_normal.dot(to_camera) >= 0.0
    rescue
      true
    end

    def apply_inherited_material_to_clicked_side(face, material, front)
      if front
        face.material = material
      else
        face.back_material = material
      end
    end

    def read_face_uvs(face, points, front)
      # get_UVHelper يحتاج Sketchup::TextureWriter كوسيط ثالث،
      # وليس View. تمرير الـ View كان سبب رسالة:
      # wrong argument type (expected Sketchup::TextureWriter)
      texture_writer = Sketchup.create_texture_writer
      helper = face.get_UVHelper(true, true, texture_writer)

      points.map do |point|
        uvq =
          if front
            helper.get_front_UVQ(point)
          else
            helper.get_back_UVQ(point)
          end
        uv_point_from_uvq(uvq)
      end
    end

    def position_rotated_material(face, material, points, uvs, front)
      center_u = uvs.sum { |uv| uv.x.to_f } / uvs.length.to_f
      center_v = uvs.sum { |uv| uv.y.to_f } / uvs.length.to_f

      texture_width = material.texture.width.to_f
      texture_height = material.texture.height.to_f

      rotated = uvs.map do |uv|
        rotate_uv_visually_90(
          uv,
          center_u,
          center_v,
          texture_width,
          texture_height
        )
      end

      mapping = []
      points.each_with_index do |point, index|
        mapping << point
        mapping << rotated[index]
      end

      face.position_material(material, mapping, front)
    end

    def rotate_texture_on_face(face, instance_path = nil, clicked_point = nil, instance_transform = nil)
      preferred_front = clicked_face_front?(face, clicked_point, instance_transform)
      material, front, inherited = textured_face_material(face, instance_path, preferred_front)

      unless material && material.texture
        execute_js(tr("showToast('الفيس المحدد مفيهوش خامة بصورة قابلة للتدوير');"))
        UI.beep
        return false
      end

      points = face_mapping_points(face)
      unless points
        execute_js(tr("showToast('تعذر قراءة هذا الفيس');"))
        UI.beep
        return false
      end

      model = current_model
      model.start_operation('MHDESIGN Visual Rotate Texture 90', true)

      # في الخامة الموروثة: نثبت نفس الخامة أولاً على الفيس الذي تم الضغط
      # عليه فقط. بعدها SketchUp ينشئ لها Mapping طبيعي، ثم نلفه بصرياً 90°.
      apply_inherited_material_to_clicked_side(face, material, front) if inherited

      uvs = read_face_uvs(face, points, front)
      position_rotated_material(face, material, points, uvs, front)

      model.commit_operation
      model.active_view.invalidate

      execute_js(tr("showToast('تم تدوير الخامة ظاهرياً 90 درجة');"))
      true
    rescue => e
      model.abort_operation rescue nil
      execute_js(tr("showToast(#{js_json("تعذر تدوير الخامة: #{e.message}")});"))
      false
    end

    # --------------------------- Smart model watcher ---------------------------

    # يبني بصمة خفيفة لحالة ربط الوحدات بالمستويات داخل الملف الحالي.
    # النسخ يحتفظ بعلامة المستوى، والحذف يزيل الوحدة من البصمة تلقائياً.
    # مراقب معاملات SketchUp: لا يعمل فحصاً متكرراً أثناء تحريك الكاميرا.
    # يتم التحديث فقط بعد Copy / Paste / Delete / Undo / Redo أو أي عملية تعديل فعلية.
    class LevelModelObserver < Sketchup::ModelObserver
      def initialize(owner)
        @owner = owner
      end

      def onTransactionCommit(_model)
        @owner.schedule_level_reconcile
      rescue
      end

      def onTransactionUndo(_model)
        @owner.schedule_level_reconcile
      rescue
      end

      def onTransactionRedo(_model)
        @owner.schedule_level_reconcile
      rescue
      end

      def onEraseAll(_model)
        @owner.schedule_level_reconcile
      rescue
      end
    end

    def reconcile_levels_from_model
      return if @level_watch_busy
      @level_watch_busy = true

      data = levels
      return false if data.empty?

      changed = false

      data.each do |level|
        # find_level_entities يدعم أيضاً الملفات القديمة التي كانت تعتمد على persistent_id فقط.
        entities = find_level_entities(level).select { |entity| entity && entity.valid? }
        fresh_ids = entities.map { |entity| entity_pid(entity) }.reject(&:zero?).uniq.sort
        stored_ids = Array(level['unit_ids']).map(&:to_i).reject(&:zero?).uniq.sort

        if fresh_ids != stored_ids
          level['unit_ids'] = fresh_ids
          changed = true
        end

        # التأكد أن الاسم الداخلي للوحدة يواكب إعادة تسمية المستوى.
        entities.each do |entity|
          saved_name = entity.get_attribute(MODEL_DICT, UNIT_LEVEL_NAME_KEY, '').to_s rescue ''
          next if saved_name == level['name'].to_s

          entity.set_attribute(MODEL_DICT, UNIT_LEVEL_NAME_KEY, level['name'].to_s)
          changed = true
        end
      end

      if changed
        save_levels(data)
        push_state if @dialog && @dialog.visible?
      end

      changed
    rescue => e
      puts "MHDESIGN Reconcile Levels Warning: #{e.message}"
      false
    ensure
      @level_watch_busy = false
    end

    def schedule_level_reconcile(delay = 0.20)
      return unless @dialog && @dialog.visible?
      return if @level_watch_busy

      if @level_reconcile_timer
        UI.stop_timer(@level_reconcile_timer) rescue nil
        @level_reconcile_timer = nil
      end

      @level_reconcile_timer = UI.start_timer(delay.to_f, false) do
        @level_reconcile_timer = nil
        reconcile_levels_from_model
      end
    rescue => e
      puts "MHDESIGN Schedule Level Reconcile Warning: #{e.message}"
    end

    def start_level_watcher
      stop_level_watcher

      model = current_model
      @level_model_observer = LevelModelObserver.new(self)
      model.add_observer(@level_model_observer)
      @level_observed_model = model
    rescue => e
      puts "MHDESIGN Start Level Watcher Warning: #{e.message}"
      @level_model_observer = nil
      @level_observed_model = nil
    end

    def stop_level_watcher
      if @level_reconcile_timer
        UI.stop_timer(@level_reconcile_timer) rescue nil
        @level_reconcile_timer = nil
      end

      if @level_observed_model && @level_model_observer
        @level_observed_model.remove_observer(@level_model_observer) rescue nil
      end

      @level_model_observer = nil
      @level_observed_model = nil
      @level_watch_signature = nil
      @level_watch_busy = false
    end

    def state_payload
      data = clean_levels!
      {
        'levels' => data.map do |level|
          level.merge('unit_count' => find_level_entities(level).length)
        end,
        'folder' => materials_folder,
        'presentation_mode' => !!@presentation_mode_active,
        'presentation_selecting' => !!@presentation_awaiting_selection
      }
    end

    def execute_js(code)
      @dialog.execute_script(code) if @dialog && @dialog.visible?
    rescue
    end

    def push_state
      execute_js("receiveState(#{js_json(state_payload)});")
    end

    def push_library
      execute_js("receiveLibrary(#{js_json(scan_library)});")
    end

    def size_pref_key(expanded, axis)
      mode = expanded ? 'expanded' : 'collapsed'
      "#{SIZE_PREF_PREFIX}_#{mode}_#{axis}"
    end

    def stored_dialog_size(expanded)
      default_width = expanded ? EXPANDED_WIDTH : COLLAPSED_WIDTH
      width = Sketchup.read_default(PLUGIN_NAME, size_pref_key(expanded, 'width'), default_width).to_i
      height = Sketchup.read_default(PLUGIN_NAME, size_pref_key(expanded, 'height'), DIALOG_HEIGHT).to_i

      min_width = expanded ? 760 : 390
      width = [[width, min_width].max, 1400].min
      height = [[height, 520].max, 1000].min
      [width, height]
    rescue
      [expanded ? EXPANDED_WIDTH : COLLAPSED_WIDTH, DIALOG_HEIGHT]
    end

    def save_dialog_size(expanded = @expanded)
      return unless @dialog
      size = @dialog.get_size rescue nil
      return unless size.is_a?(Array) && size.length >= 2

      width = size[0].to_i
      height = size[1].to_i
      return if width <= 0 || height <= 0

      Sketchup.write_default(PLUGIN_NAME, size_pref_key(expanded, 'width'), width)
      Sketchup.write_default(PLUGIN_NAME, size_pref_key(expanded, 'height'), height)
    rescue => e
      puts "MHDESIGN Save Dialog Size Warning: #{e.message}"
    end

    def start_size_watcher
      stop_size_watcher
      # لا يوجد Timer مستمر. قراءة حجم HtmlDialog كل نصف ثانية كانت تسبب
      # تقطيعًا عامًا في SketchUp. الحفظ يتم عند تغيير الوضع أو الإغلاق.
      @size_watch_timer = nil
    rescue => e
      puts "MHDESIGN Size Watcher Warning: #{e.message}"
    end

    def stop_size_watcher
      if @size_watch_timer
        UI.stop_timer(@size_watch_timer) rescue nil
        @size_watch_timer = nil
      end
    end

    def open
      stop_size_watcher
      stop_level_watcher
      @dialog.close rescue nil if @dialog
      recover_stale_presentation_state(current_model)
      @expanded = false
      collapsed_width, collapsed_height = stored_dialog_size(false)

      @dialog = UI::HtmlDialog.new(
        dialog_title: tr('MHDESIGN - مستويات وخامات المطبخ'),
        preferences_key: 'MHDESIGN_KITCHEN_LEVELS_MATERIALS_V3',
        scrollable: false,
        resizable: true,
        width: collapsed_width,
        height: collapsed_height,
        min_width: 390,
        min_height: 520,
        max_width: 1400,
        max_height: 1000,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      @dialog.set_html(html)
      register_callbacks
      @dialog.set_on_closed do
        begin
          disable_presentation_mode(false)
        ensure
          save_dialog_size(@expanded)
          stop_size_watcher
          stop_level_watcher
          @dialog = nil
        end
      end
      @dialog.show

      UI.start_timer(0.10, false) do
        begin
          @dialog.set_size(collapsed_width, collapsed_height) if @dialog
        rescue
        end
        start_size_watcher
        start_level_watcher
      end
    end

    def resize_dialog(expanded)
      return unless @dialog

      # احفظ الحجم الذي اختاره المستخدم للوضع الحالي قبل الانتقال.
      save_dialog_size(@expanded)
      @expanded = !!expanded
      width, height = stored_dialog_size(@expanded)

      # عند أول فتح للمكتبة نحافظ على ارتفاع النافذة الحالي إن لم يكن هناك ارتفاع محفوظ.
      begin
        current_size = @dialog.get_size
        height = current_size[1].to_i if current_size.is_a?(Array) && current_size[1].to_i >= 520
      rescue
      end

      begin
        @dialog.set_size(width, height)
      rescue => e
        puts "MHDESIGN Dialog Resize Warning: #{e.message}"
      end

      UI.start_timer(0.08, false) do
        begin
          @dialog.set_size(width, height) if @dialog
        rescue
        end
      end

      UI.start_timer(0.14, false) do
        execute_js("setLibraryExpanded(#{@expanded ? 'true' : 'false'});")
        save_dialog_size(@expanded)
      end
    end

    def register_callbacks
      @dialog.add_action_callback('ready') { |_ctx| push_state; push_library }
      @dialog.add_action_callback('choose_folder') { |_ctx| choose_materials_folder }
      @dialog.add_action_callback('add_level') { |_ctx, name| add_level(name) }
      @dialog.add_action_callback('rename_level') { |_ctx, id, name| rename_level(id, name) }
      @dialog.add_action_callback('delete_level') { |_ctx, id| delete_level(id) }
      @dialog.add_action_callback('reset_levels') { |_ctx| reset_levels }
      @dialog.add_action_callback('toggle_presentation_mode') { |_ctx| toggle_presentation_mode }
      @dialog.add_action_callback('assign_selection') { |_ctx, id| assign_selection_to_level(id) }
      @dialog.add_action_callback('add_selection') { |_ctx, id| add_selection_to_level(id) }
      @dialog.add_action_callback('select_units') { |_ctx, id| select_level_units(id) }
      @dialog.add_action_callback('apply_material') { |_ctx, level_id, target, path| apply_material(level_id, target, path) }
      @dialog.add_action_callback('request_material_names') { |_ctx, level_id, target| push_material_name_choices(level_id, target) }
      @dialog.add_action_callback('change_material_name') { |_ctx, level_id, target, value| change_material_name(level_id, target, value) }
      @dialog.add_action_callback('duplicate_material_name') do |_ctx, level_id, target, source_name, new_name|
        duplicate_material_for_level(level_id, target, source_name, new_name)
      end
      @dialog.add_action_callback('rename_material_name') do |_ctx, level_id, target, old_name, new_name|
        rename_model_material_and_attributes(level_id, target, old_name, new_name)
      end
      @dialog.add_action_callback('save_material_settings') do |_ctx, path, payload|
        data = JSON.parse(payload.to_s) rescue {}
        save_material_setting(path, data)
        item = find_library_item(path)
        push_library
        execute_js(tr("showToast('تم حفظ إعدادات الخامة');"))
      end
      @dialog.add_action_callback('refresh') { |_ctx| push_state; push_library }
      @dialog.add_action_callback('toggle_library') { |_ctx, expanded| resize_dialog(expanded == true || expanded.to_s == 'true') }
      @dialog.add_action_callback('rotate_texture') { |_ctx| start_texture_rotate_tool }
    end

    def html
      direction = ui_direction
      locale = ui_locale
      raw_html = <<~HTML
      <!DOCTYPE html>
      <html lang="#{html_escape(locale)}" dir="#{html_escape(direction)}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
          :root {
            color-scheme: dark;
            --bg-app: #0B111A;
            --bg-header: #101B27;
            --bg-panel: #111F2C;
            --bg-card: #172633;
            --bg-elevated: #253443;
            --bg-input: #101923;
            --accent: #08C9C3;
            --accent-hover: #13DDD2;
            --accent-bright: #27E5DC;
            --text-primary: #F4F7FA;
            --text-secondary: #A6B5C3;
            --text-muted: #8495A5;
            --border: #34495B;
            --border-active: #27E5DC;
            --danger: #EF5965;
            --warning: #F2B72F;
            --header: linear-gradient(110deg, #07111B 0%, #102332 60%, #075C62 100%);
            --primary: linear-gradient(90deg, #08BDB8 0%, #13DDD2 55%, #05B9B5 100%);
            --active: linear-gradient(135deg, #063C44 0%, #087D80 100%);
            --panel: linear-gradient(145deg, #1D3040 0%, #111E2B 100%);
            --gap: 12px;
            --radius: 12px;
          }
          * { box-sizing: border-box; }
          html, body { height: 100%; margin: 0; overflow: hidden; }
          body { background: var(--bg-app); color: var(--text-primary); font: 13px/1.45 Cairo, Tajawal, "Segoe UI", Tahoma, sans-serif; }
          button, input, select { min-width: 0; color: inherit; font: inherit; }
          button { cursor: pointer; }
          button:focus, input:focus, select:focus { outline: 2px solid var(--border-active); outline-offset: 2px; }
          button:disabled, select:disabled { opacity: .55; cursor: default; }
          input, select {
            min-height: 38px; width: 100%; padding: 6px 9px;
            background: var(--bg-input); border: 1px solid var(--border); border-radius: 8px;
          }
          input::placeholder { color: var(--text-muted); }
          ::-webkit-scrollbar { width: 8px; height: 8px; }
          ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 8px; }

          .app { height: 100%; display: grid; grid-template-rows: auto minmax(0, 1fr) auto; }
          .hero {
            position: relative; display: grid; grid-template-columns: 1fr minmax(0, 2.6fr) 1fr;
            align-items: center; gap: 12px; min-height: 92px; padding: 10px 18px;
            overflow: hidden; direction: ltr; background: var(--header); border-bottom: 1px solid var(--border);
          }
          .brand { display: flex; align-items: center; gap: 8px; color: var(--text-primary); letter-spacing: .07em; }
          .brand .logo { display: block; flex: none; width: 36px; height: 36px; object-fit: contain; }
          .brandName { font-size: 13px; }
          .heroText { z-index: 1; min-width: 0; text-align: center; }
          .title { margin: 0; font-size: 24px; line-height: 1.25; overflow-wrap: anywhere; }
          .sub { margin: 4px 0 0; font-size: 12px; color: var(--text-secondary); overflow-wrap: anywhere; }
          .cabinetDrawing {
            position: absolute; right: 10px; bottom: -8px; width: 130px; height: 82px;
            color: var(--accent-hover); opacity: .32; pointer-events: none;
          }
          .workspace {
            display: grid; grid-template-columns: minmax(0, 1fr); grid-template-rows: minmax(0, 1fr);
            min-height: 0; gap: var(--gap); padding: var(--gap); direction: ltr;
          }
          .app.expanded .workspace { grid-template-columns: minmax(0, 48fr) minmax(0, 52fr); }
          .left, .library {
            display: flex; flex-direction: column; min-width: 0; min-height: 0;
            border: 1px solid var(--border); border-radius: var(--radius); background: var(--bg-panel);
          }
          .app:not(.expanded) .library { display: none; }
          .toolbar, .libHead {
            flex: none; padding: var(--gap); border-bottom: 1px solid var(--border);
            border-radius: var(--radius) var(--radius) 0 0; background: var(--panel);
          }
          .toolbar, .libToolbar, .materialNameEditorRow { display: flex; align-items: center; gap: 8px; }
          .nameInput, .search, .materialNameInput { flex: 1 1 0; }
          .toolbar button, .libHead button, .libToolbar button, .materialNameEditorRow button { flex: none; max-width: 48%; }
          .content, .libraryScroll {
            flex: 1 1 0; min-height: 0; overflow: auto; overscroll-behavior: contain; scrollbar-gutter: stable;
          }
          .content { padding: var(--gap); }
          .empty, .hint { color: var(--text-secondary); text-align: center; padding: 24px 12px; }
          .presentationBar { flex: none; padding: 10px var(--gap); border-top: 1px solid var(--border); }
          .presentationBtn { width: 100%; }
          .presentationBtn.selecting { color: var(--warning); border-color: var(--warning); }
          .presentationBtn.active:not(.selecting) { color: var(--danger); border-color: var(--danger); }

          .level {
            margin: 0 0 12px; padding: 12px; background: var(--bg-card);
            border: 1px solid var(--border); border-radius: var(--radius);
          }
          .level:last-child { margin-bottom: 0; }
          .level.active { border-color: var(--accent); box-shadow: inset 0 0 0 1px rgba(8,201,195,.14); }
          .levelHead { display: flex; align-items: center; flex-wrap: wrap; gap: 6px; }
          .levelName { flex: 1 1 100px; min-width: 0; font-size: 16px; font-weight: 700; overflow-wrap: anywhere; }
          .levelName { padding: 0; border: 0; background: transparent; text-align: start; }
          .levelName:hover { color: var(--accent-hover); background: transparent; }
          .count { padding: 2px 6px; border-radius: 6px; background: var(--bg-elevated); color: var(--text-secondary); font-size: 11px; }
          .levelBody { display: grid; gap: 8px; padding-top: 10px; }
          .targets, .actions { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }
          .actions { border-top: 1px solid var(--border); padding-top: 8px; }
          .target, .small { font-size: 12px; }

          button {
            min-height: 36px; padding: 5px 9px; border: 1px solid var(--border); border-radius: 8px;
            background: var(--bg-input); font-weight: 700; overflow-wrap: anywhere;
          }
          button:hover { background: var(--bg-elevated); border-color: var(--accent); }
          .primary, .materialsBtn, .renameSave, .materialApplyName {
            color: #04191C; background: var(--primary); border-color: transparent;
          }
          .primary:hover, .materialsBtn:hover, .renameSave:hover, .materialApplyName:hover { background: var(--accent-hover); }
          .target.active, .tab.active, .materialManageButtons button.active, .rotateTextureBtn.active {
            color: var(--text-primary); background: var(--active); border-color: var(--border-active);
          }
          .iconBtn, .edit { flex: none; width: 34px; min-height: 34px; padding: 0; font-size: 16px; }
          .danger, .resetBtn, .resetConfirm { color: #FFB6BC; border-color: #843B46; background: #351D27; }
          .danger:hover, .resetBtn:hover, .resetConfirm:hover { border-color: var(--danger); background: #4B2632; }

          .libHead { display: flex; align-items: center; gap: 10px; }
          .libIntro { flex: 1; min-width: 0; }
          .libTitle { margin: 0; font-size: 16px; overflow-wrap: anywhere; }
          .folder { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; margin-top: 3px; color: var(--text-secondary); font-size: 11px; text-align: start; overflow-wrap: anywhere; }
          .libraryScroll { padding: var(--gap); }
          .materialSelector { border: 1px solid var(--border); border-radius: 10px; background: var(--bg-card); }
          .materialSelectorHead {
            width: 100%; min-height: 38px; display: flex; align-items: center; gap: 8px;
            border: 0; text-align: start; background: transparent;
          }
          .materialSelectorTitle { flex: 1; min-width: 0; overflow-wrap: anywhere; }
          .materialSelectorToggle { color: var(--accent-hover); }
          .materialSelectorBody { padding: 4px 8px 8px; }
          .materialSelector.collapsed .materialSelectorBody { display: none; }
          .materialManageButtons { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; margin-top: 8px; }
          .materialNameEditor { display: none; margin-top: 8px; padding-top: 8px; border-top: 1px solid var(--border); }
          .materialNameEditor.show { display: block; }
          .materialManageHint { margin-top: 5px; color: var(--text-secondary); font-size: 11px; overflow-wrap: anywhere; }
          .libToolbar { margin-top: 12px; }
          .tabs { display: flex; flex-wrap: wrap; gap: 6px; margin: 8px 0 12px; }
          .tab { min-height: 32px; max-width: 100%; padding-inline: 10px; border-radius: 999px; font-size: 12px; }
          .grid {
            display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, max(116px, calc((100% - 20px) / 3))), 1fr));
            gap: 10px; align-items: stretch;
          }
          .mat { min-width: 0; border: 1px solid var(--border); border-radius: 10px; background: var(--bg-card); }
          .mat:hover, .mat:focus-within { border-color: var(--border-active); }
          .swatch {
            position: relative; display: block; width: 100%; min-height: 0; height: 0; padding: 100% 0 0;
            border: 0; border-radius: 9px 9px 0 0; background: var(--bg-input); overflow: hidden;
          }
          .swatch:focus { outline-offset: -2px; }
          .thumb { position: absolute; inset: 0; display: block; width: 100%; height: 100%; object-fit: cover; }
          .matMeta { display: flex; align-items: center; gap: 6px; min-width: 0; padding: 6px; }
          .matName { flex: 1; min-width: 0; font-size: 12px; overflow-wrap: anywhere; text-align: start; }
          .edit { width: 30px; min-height: 30px; }
          .hint { grid-column: 1 / -1; }

          .footer {
            display: flex; flex-wrap: wrap; justify-content: space-between; gap: 8px; padding: 8px 12px;
            background: var(--bg-header); border-top: 1px solid var(--border); direction: ltr;
          }
          .footerLeft { display: flex; flex: 1 1 160px; flex-wrap: wrap; gap: 8px; }
          .footerLeft button { flex: 0 1 auto; max-width: 100%; }
          .footer > button { flex: 0 1 auto; max-width: 100%; }

          .modal, .resetOverlay, .renameOverlay, .busyOverlay {
            position: fixed; inset: 0; display: none; align-items: center; justify-content: center;
            padding: 14px; background: rgba(3,10,15,.78); z-index: 20;
          }
          .modal.show, .resetOverlay.show, .renameOverlay.show, .busyOverlay.show { display: flex; }
          .modalBox, .resetBox, .renameBox, .busyBox {
            width: min(440px, 100%); max-height: 100%; overflow: auto; background: var(--bg-card);
            border: 1px solid var(--border); border-radius: var(--radius); box-shadow: 0 16px 38px rgba(0,0,0,.45);
          }
          .resetBox, .renameBox, .busyBox { width: min(390px, 100%); padding: 16px; }
          .modalHead { display: flex; align-items: center; gap: 8px; padding: 10px 12px; background: var(--panel); }
          .modalHead span { flex: 1; font-weight: 700; overflow-wrap: anywhere; }
          .modalBody { padding: 12px; }
          .preview { display: block; width: 100%; height: min(205px, 32vh); object-fit: contain; background: var(--bg-input); border-radius: 8px; }
          .formGrid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; margin-top: 8px; }
          .field label, .renameLabel { display: block; margin-bottom: 4px; color: var(--text-secondary); }
          .modalActions, .resetActions, .renameActions { display: flex; gap: 8px; margin-top: 8px; }
          .modalActions { padding: 0 12px 12px; margin-top: 0; }
          .modalActions button, .resetActions button, .renameActions button { flex: 1 1 0; }
          .resetTitle, .renameTitle, .busyLogo { margin-bottom: 8px; font-size: 16px; font-weight: 700; }
          .resetText, .busyText { color: var(--text-secondary); }
          .resetWarning { margin-top: 8px; padding: 8px; color: #FFB6BC; background: #351D27; border-radius: 8px; }
          .renameError { margin-top: 5px; color: var(--danger); }
          .busyOverlay { z-index: 40; }
          .busyBox { text-align: center; }
          .busyBar { height: 8px; margin-top: 10px; border-radius: 999px; overflow: hidden; background: var(--bg-input); direction: ltr; }
          .busyFill { height: 100%; width: 8%; background: var(--primary); }
          .busyPercent { margin-top: 4px; color: var(--text-muted); }
          .toast {
            position: fixed; left: 50%; bottom: 16px; transform: translateX(-50%); z-index: 50;
            max-width: calc(100vw - 28px); padding: 8px 12px; color: var(--text-primary);
            background: var(--bg-elevated); border: 1px solid var(--accent); border-radius: 8px;
            opacity: 0; pointer-events: none; overflow-wrap: anywhere;
          }
          .toast.show { opacity: 1; }

          @media (max-width: 740px) {
            :root { --gap: 8px; }
            .hero { grid-template-columns: 36px minmax(0, 1fr) 36px; min-height: 72px; padding: 8px 10px; }
            .brandName { display: none; }
            .title { font-size: 20px; }
            .cabinetDrawing { opacity: .17; }
          }
          @media (max-width: 620px) {
            .app.expanded .workspace { grid-template-columns: minmax(0, 1fr); grid-template-rows: minmax(0, 48fr) minmax(0, 52fr); }
            .app.expanded .libHead { padding-block: 5px; }
            .level { padding: 8px; }
          }
        #{MHDESIGN_ResponsiveHeaderUI::CSS}
:root {
  --bg-app: var(--ref-bg); --bg-panel: var(--ref-panel); --bg-card: var(--ref-panel);
  --bg-elevated: var(--ref-section); --bg-input: var(--ref-input); --border: var(--ref-border);
  --accent: var(--ref-accent); --primary: var(--ref-action); --text-primary: var(--ref-text);
}
.toolbar, .libHead, .materialSelectorHead { background: var(--ref-section); }
.level { border-color: var(--ref-border); }
.level.active { border-color: var(--ref-accent); }
        </style>
      </head>
      <body oncontextmenu="return false">
        <div class="app" id="app">
          <header class="hero mhd-ref-header">
            #{MHDESIGN_ResponsiveHeaderUI::BRAND}
            <div class="heroText" dir="#{html_escape(direction)}">
              <h1 class="title">#{MHDESIGN::Language.for_tool('materials').html('KLM_TITLE')}</h1>
              <p class="sub">#{MHDESIGN::Language.for_tool('materials').html('TEXT_724BBAE0A0C6')}</p>
            </div>
            <!-- Dressing reference header artwork is included in BRAND. -->
          </header>
          <div class="workspace">
            <section class="left" dir="#{html_escape(direction)}">
              <div class="toolbar"><input id="newLevelName" class="nameInput" placeholder="#{MHDESIGN::Language.for_tool('materials').html('TEXT_D000E691833E')}"><button class="primary" onclick="addLevel()">#{MHDESIGN::Language.for_tool('materials').html('KLM_ADD')}</button></div>
              <main class="content" id="levels"></main>
              <div class="presentationBar"><button class="presentationBtn" id="presentationBtn" type="button" onclick="togglePresentationMode()">#{MHDESIGN::Language.for_tool('materials').html('TEXT_36568D37B3FF')}</button></div>
            </section>
            <aside class="library" dir="#{html_escape(direction)}">
              <header class="libHead">
                <div class="libIntro">
                  <h2 class="libTitle">#{MHDESIGN::Language.for_tool('materials').html('KLM_MATERIALS_LIBRARY')}</h2>
                  <div class="folder" id="folderPath" dir="auto">#{MHDESIGN::Language.for_tool('materials').html('TEXT_58E546184551')}</div>
                </div>
                <button class="ghost" type="button" onclick="sketchup.choose_folder()">#{MHDESIGN::Language.for_tool('materials').html('TEXT_3583D31D337F')}</button>
              </header>
              <div class="libraryScroll">
                <div class="materialSelector" id="materialSelector">
                  <button class="materialSelectorHead" type="button" aria-expanded="true" aria-controls="materialSelectorBody" onclick="toggleMaterialSelector()">
                    <span class="materialSelectorTitle" id="materialSelectLabel">#{MHDESIGN::Language.for_tool('materials').html('TEXT_D06CD6E5350E')}</span>
                    <span class="materialSelectorToggle" id="materialSelectorToggle" aria-hidden="true">▲</span>
                  </button>
                  <div class="materialSelectorBody" id="materialSelectorBody">
                    <select class="materialSelect" id="materialNameSelect" aria-labelledby="materialSelectLabel" onchange="changeMaterialName()"><option value="">#{MHDESIGN::Language.for_tool('materials').html('TEXT_3783563F494B')}</option></select>
                    <div class="materialManageButtons">
                      <button id="duplicateMaterialBtn" type="button" onclick="openMaterialNameEditor('duplicate')">#{MHDESIGN::Language.for_tool('materials').html('TEXT_8C89E5CCEAD0')}</button>
                      <button id="renameMaterialBtn" type="button" onclick="openMaterialNameEditor('rename')">#{MHDESIGN::Language.for_tool('materials').html('TEXT_7FF91FFD4366')}</button>
                    </div>
                    <div class="materialNameEditor" id="materialNameEditor">
                      <div class="materialNameEditorRow">
                        <input class="materialNameInput" id="newMaterialName" placeholder="#{MHDESIGN::Language.for_tool('materials').html('TEXT_C0F170AAA105')}">
                        <button class="materialApplyName" type="button" onclick="applyMaterialManagement()">#{MHDESIGN::Language.for_tool('materials').html('LED_APPLY')}</button>
                      </div>
                      <div class="materialManageHint" id="materialManageHint"></div>
                    </div>
                  </div>
                </div>
                <div class="libToolbar"><input class="search" id="search" placeholder="#{MHDESIGN::Language.for_tool('materials').html('TEXT_44761585B52D')}" oninput="renderMaterials()"><button class="ghost" onclick="sketchup.refresh()">↻</button></div>
                <div class="tabs" id="tabs"></div>
                <div class="grid" id="grid"></div>
              </div>
            </aside>
          </div>
          <footer class="footer">
            <div class="footerLeft" dir="#{html_escape(direction)}">
              <button class="resetBtn footerResetBtn" onclick="openResetModal()">#{MHDESIGN::Language.for_tool('materials').html('KLM_RESET')}</button>
              <button class="rotateTextureBtn" id="rotateTextureBtn" onclick="startTextureRotate()">#{MHDESIGN::Language.for_tool('materials').html('KLM_ROTATE_TEXTURE')}</button>
            </div>
            <button class="materialsBtn" id="materialsBtn" dir="#{html_escape(direction)}" onclick="toggleLibrary()">#{MHDESIGN::Language.for_tool('materials').html('TEXT_4F4093441365')}</button>
          </footer>
        </div>
        <div class="modal" id="modal"><div class="modalBox"><div class="modalHead"><span id="editTitle">#{MHDESIGN::Language.for_tool('materials').html('TEXT_9D2E066AC72A')}</span><button class="iconBtn" onclick="closeEditor()">×</button></div><div class="modalBody"><img id="editPreview" class="preview"><div class="formGrid"><div class="field"><label>#{MHDESIGN::Language.for_tool('materials').html('TEXT_D1EE89AC5BE2')}</label><input id="editW" type="number" min="0.1" step="0.1"></div><div class="field"><label>#{MHDESIGN::Language.for_tool('materials').html('TEXT_D1D4FB880EF5')}</label><input id="editH" type="number" min="0.1" step="0.1"></div><div class="field" style="grid-column:1/-1"><label>#{MHDESIGN::Language.for_tool('materials').html('TEXT_312EC564000F')}</label><select id="editR"><option value="0">0°</option><option value="90">90°</option><option value="180">180°</option><option value="270">270°</option></select></div></div></div><div class="modalActions"><button class="ghost" onclick="closeEditor()">#{MHDESIGN::Language.for_tool('materials').html('COMMON_CANCEL')}</button><button class="primary" onclick="saveEditor()">#{MHDESIGN::Language.for_tool('materials').html('TEXT_7F84449295C5')}</button></div></div></div>
        <div class="resetOverlay" id="resetOverlay" aria-hidden="true">
          <div class="resetBox" role="dialog" aria-modal="true" aria-labelledby="resetTitle">
            <div class="resetTitle" id="resetTitle">#{MHDESIGN::Language.for_tool('materials').html('TEXT_8A03BF80855B')}</div>
            <div class="resetText">
              #{MHDESIGN::Language.for_tool('materials').html('TEXT_E206720C8DA7')}
            </div>
            <div class="resetWarning">
              #{MHDESIGN::Language.for_tool('materials').html('TEXT_0BEA73C7829E')}
            </div>
            <div class="resetActions">
              <button class="resetConfirm" type="button" onclick="confirmResetLevels()">#{MHDESIGN::Language.for_tool('materials').html('KLM_RESET')}</button>
              <button class="resetCancel" type="button" onclick="closeResetModal()">#{MHDESIGN::Language.for_tool('materials').html('COMMON_CANCEL')}</button>
            </div>
          </div>
        </div>
        <div class="renameOverlay" id="renameOverlay" aria-hidden="true">
          <div class="renameBox" role="dialog" aria-modal="true" aria-labelledby="renameTitle">
            <div class="renameTitle" id="renameTitle">#{MHDESIGN::Language.for_tool('materials').html('TEXT_DEC6FB9A60AC')}</div>
            <label class="renameLabel" for="renameLevelInput">#{MHDESIGN::Language.for_tool('materials').html('TEXT_E7479827D02A')}</label>
            <input class="renameInput" id="renameLevelInput" type="text" maxlength="80" autocomplete="off">
            <div class="renameError" id="renameError"></div>
            <div class="renameActions">
              <button class="renameSave" type="button" onclick="confirmRenameLevel()">#{MHDESIGN::Language.for_tool('materials').html('COMMON_SAVE')}</button>
              <button class="renameCancel" type="button" onclick="closeRenameModal()">#{MHDESIGN::Language.for_tool('materials').html('COMMON_CANCEL')}</button>
            </div>
          </div>
        </div>
        <div class="busyOverlay" id="busyOverlay">
          <div class="busyBox">
            <div class="busyLogo">MHDESIGN</div>
            <div class="busyText" id="busyText">#{MHDESIGN::Language.for_tool('materials').html('TEXT_0244B96629EC')}</div>
            <div class="busyBar"><div class="busyFill" id="busyFill"></div></div>
            <div class="busyPercent" id="busyPercent">0%</div>
          </div>
        </div>
        <div class="toast" id="toast"></div>
        <script>
          let state={levels:[],folder:'',presentation_mode:false,presentation_selecting:false}, library={categories:[]}, materialChoices={options:[],current:''}, activeLevel=null, activeTarget='door', activeCategory='all', editItem=null, materialManageMode=null;
          const q=s=>document.querySelector(s);
          function esc(s){return String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
          const inlineArg = value => esc(JSON.stringify(value));
          let textureRotateActive=false;

          function startTextureRotate(){
            if(textureRotateActive){
              showToast('أداة تدوير الخامة تعمل بالفعل');
              return;
            }
            sketchup.rotate_texture();
          }

          function textureRotateStarted(){
            textureRotateActive=true;
            const btn=q('#rotateTextureBtn');
            if(btn){
              btn.classList.add('active');
              btn.textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_C69F42762DAD')}';
            }
            showToast('#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_0CCE491DD582')}');
          }

          function textureRotateEnded(){
            textureRotateActive=false;
            const btn=q('#rotateTextureBtn');
            if(btn){
              btn.classList.remove('active');
              btn.textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('KLM_ROTATE_TEXTURE')}';
            }
          }

          function textureRotateFailed(message){
            textureRotateEnded();
            showToast(message||'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_033E6903F789')}');
          }

          function receiveState(data){state=data||state;if(!activeLevel&&state.levels.length)activeLevel=state.levels[0].id;if(activeLevel&&!state.levels.some(x=>x.id===activeLevel))activeLevel=state.levels[0]?.id||null;renderLevels();q('#folderPath').title=state.folder||'';q('#folderPath').textContent=state.folder||'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_58E546184551')}';setPresentationMode(!!state.presentation_mode);setPresentationSelectionMode(!!state.presentation_selecting);requestMaterialChoices()}

          let presentationModeActive=false;
          function togglePresentationMode(){sketchup.toggle_presentation_mode()}
          function setPresentationMode(active){
            presentationModeActive=!!active;
            const btn=q('#presentationBtn');
            if(!btn)return;
            btn.classList.toggle('active',presentationModeActive);
            btn.textContent=presentationModeActive?'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_A1A84D3D81C3')}':'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_36568D37B3FF')}';
          }
          function setPresentationSelectionMode(active){
            const btn=q('#presentationBtn');
            if(!btn)return;
            btn.classList.toggle('selecting',!!active);
            if(active)btn.textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_DC6C491B6A52')}';
            else if(!presentationModeActive)btn.textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_36568D37B3FF')}';
          }

          let materialSelectorCollapsed=false;
          function toggleMaterialSelector(){materialSelectorCollapsed=!materialSelectorCollapsed;let box=q('#materialSelector');box.classList.toggle('collapsed',materialSelectorCollapsed);box.querySelector('.materialSelectorHead').setAttribute('aria-expanded',String(!materialSelectorCollapsed));q('#materialSelectorToggle').textContent=materialSelectorCollapsed?'▼':'▲'}
          function targetLabel(){return activeTarget==='door'?'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_C00A3F5C6446')}':activeTarget==='carcass'?'#{MHDESIGN::Language.for_tool('materials').js_fragment('OPT_CARCASS_MATERIAL')}':'#{MHDESIGN::Language.for_tool('materials').js_fragment('OPT_BACK_MATERIAL')}'}
          function requestMaterialChoices(){if(activeLevel)sketchup.request_material_names(activeLevel,activeTarget);else receiveMaterialChoices({options:[],current:''})}
          function receiveMaterialChoices(data){materialChoices=data||{options:[],current:''};let select=q('#materialNameSelect');q('#materialSelectLabel').textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_5E54FE30E445')} '+targetLabel()+' #{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_12C29CE25CE2')}';if(!materialChoices.options.length){select.innerHTML='<option value="">#{MHDESIGN::Language.for_tool('materials').html('TEXT_AC7343D8E07C')}</option>';select.disabled=true;return}select.disabled=false;select.innerHTML='<option value="">#{MHDESIGN::Language.for_tool('materials').html('TEXT_70D3C74B1109')}</option>'+materialChoices.options.map(o=>`<option value="${esc(o.value)}">${esc(o.label)}</option>`).join('');let match=materialChoices.options.find(o=>o.label===materialChoices.current||o.value===materialChoices.current);if(match)select.value=match.value}
          function changeMaterialName(){
            let value=q('#materialNameSelect').value;
            if(!activeLevel||!value)return;
            if(!startBusy('جاري تجهيز تغيير مسمى الخامة...'))return;
            // نترك للواجهة فرصة أن تظهر قبل بدء إعادة رسم الـ Dynamic Components.
            setTimeout(()=>sketchup.change_material_name(activeLevel,activeTarget,value),60);
          }
          function selectedMaterialName(){let s=q('#materialNameSelect');return s&&s.value?s.value:(materialChoices.current||'')}
          function openMaterialNameEditor(mode){
            let source=selectedMaterialName();
            if(!activeLevel){showToast('اختر مستوى أولاً');return}
            if(!source){showToast('اختر مسمى الخامة أولاً');return}
            materialManageMode=mode;
            q('#materialNameEditor').classList.add('show');
            q('#duplicateMaterialBtn').classList.toggle('active',mode==='duplicate');
            q('#renameMaterialBtn').classList.toggle('active',mode==='rename');
            q('#newMaterialName').value='';
            q('#newMaterialName').placeholder=mode==='duplicate'?'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_7CC5AFCBA8C7')}':'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_E8940DB7BBA0')}';
            q('#materialManageHint').textContent=mode==='duplicate'
              ?'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_07A3BB27C86F')} '+source+' #{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_736523728A98')}'
              :'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_28CBA79ADF61')} '+source+' #{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_EC6234992D8F')}';
            q('#newMaterialName').focus();
          }
          function applyMaterialManagement(){
            let source=selectedMaterialName(),name=q('#newMaterialName').value.trim();
            if(!materialManageMode||!source){showToast('اختر العملية والخامة أولاً');return}
            if(!name){showToast('اكتب الاسم الجديد');return}

            const mode=materialManageMode;
            const loadingText=mode==='duplicate'
              ?'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_9337D57BC753')}'
              :'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_3C2F0EB51BE1')}';

            if(!startBusy(loadingText))return;

            setTimeout(()=>{
              if(mode==='duplicate'){
                sketchup.duplicate_material_name(activeLevel,activeTarget,source,name);
              }else{
                sketchup.rename_material_name(activeLevel,activeTarget,source,name);
              }
            },70);
          }
          function finishMaterialManagement(newName,message){
            materialManageMode=null;
            q('#materialNameEditor').classList.remove('show');
            q('#duplicateMaterialBtn').classList.remove('active');
            q('#renameMaterialBtn').classList.remove('active');
            q('#newMaterialName').value='';
            requestMaterialChoices();
            finishBusy(true,message||'تم تنفيذ العملية');
          }
          function receiveLibrary(data){library=data||{categories:[]};q('#folderPath').title=library.root||'';q('#folderPath').textContent=library.root||'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_58E546184551')}';if(activeCategory!=='all'&&!library.categories.some(x=>x.name===activeCategory))activeCategory='all';renderTabs();renderMaterials()}
          let libraryExpanded=false;
          function toggleLibrary(){sketchup.toggle_library(!libraryExpanded)}
          function setLibraryExpanded(value){
            libraryExpanded=!!value;
            q('#app').classList.toggle('expanded',libraryExpanded);
            q('#materialsBtn').innerHTML=libraryExpanded?'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_F5E2FE90E66E')}':'#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_4F4093441365')}';
          }
          let resetInProgress=false;
          function openResetModal(){
            if(!state.levels||!state.levels.length){
              showToast('لا توجد مستويات لإعادة تعيينها');
              return;
            }
            q('#resetOverlay').classList.add('show');
            q('#resetOverlay').setAttribute('aria-hidden','false');
          }
          function closeResetModal(){
            if(resetInProgress)return;
            q('#resetOverlay').classList.remove('show');
            q('#resetOverlay').setAttribute('aria-hidden','true');
          }
          function confirmResetLevels(){
            if(resetInProgress)return;
            resetInProgress=true;
            q('#resetOverlay').classList.remove('show');
            q('#resetOverlay').setAttribute('aria-hidden','true');

            if(startBusy('جاري إعادة تعيين مستويات الملف...')){
              setTimeout(()=>sketchup.reset_levels(),60);
            }else{
              sketchup.reset_levels();
            }
          }
          function finishResetLevels(success,message){
            resetInProgress=false;
            activeLevel=null;
            activeTarget='door';
            if(q('#busyOverlay').classList.contains('show')){
              finishBusy(success,message);
            }else{
              showToast(message||(success?'تمت إعادة التعيين':'تعذر إتمام العملية'));
            }
          }
          function addLevel(){let n=q('#newLevelName').value.trim();sketchup.add_level(n);q('#newLevelName').value=''}
          function setActive(id){activeLevel=id;let l=state.levels.find(x=>x.id===id);activeTarget=(l?.last_target==='drawer'?'door':(l?.last_target||activeTarget));renderLevels();requestMaterialChoices()}
          function setTarget(id,target){activeLevel=id;activeTarget=target;renderLevels();requestMaterialChoices()}
          let renameLevelId=null;
          function renameLevel(id,current){
            let supplied=[id,current];
            let levelId=supplied.length>0&&supplied[0]!=null?String(supplied[0]):String(activeLevel||'');
            let currentName=supplied.length>1&&supplied[1]!=null?String(supplied[1]):'';

            if(!currentName){
              let card=document.querySelector('[data-level-id="'+CSS.escape(levelId)+'"]');
              if(card){
                let n=card.querySelector('.levelName,[data-role="level-name"],h3,strong');
                if(n)currentName=(n.textContent||'').trim();
              }
            }

            if(!levelId){showToast('تعذر تحديد المستوى');return}
            renameLevelId=levelId;
            q('#renameLevelInput').value=currentName;
            q('#renameError').textContent='';
            q('#renameOverlay').classList.add('show');
            q('#renameOverlay').setAttribute('aria-hidden','false');
            setTimeout(()=>{q('#renameLevelInput').focus();q('#renameLevelInput').select()},30);
          }
          function closeRenameModal(){
            q('#renameOverlay').classList.remove('show');
            q('#renameOverlay').setAttribute('aria-hidden','true');
            q('#renameError').textContent='';
            renameLevelId=null;
          }
          function confirmRenameLevel(){
            let value=(q('#renameLevelInput').value||'').trim();
            if(!renameLevelId){closeRenameModal();return}
            if(!value){q('#renameError').textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_367A7D73E828')}';q('#renameLevelInput').focus();return}
            if(value.length>80){q('#renameError').textContent='#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_07C8127FEB59')}';return}

            let id=renameLevelId;
            closeRenameModal();
            sketchup.rename_level(id,value);
          }

          function deleteLevel(id){if(confirm('#{MHDESIGN::Language.for_tool('materials').js_fragment('TEXT_540E9E11CB51')}'))sketchup.delete_level(id)}
          function renderLevels(){let box=q('#levels');if(!state.levels.length){box.innerHTML='<div class="empty">#{MHDESIGN::Language.for_tool('materials').html('TEXT_A286DB888CE6')} <b>#{MHDESIGN::Language.for_tool('materials').html('TEXT_0CA22D0D09CB')}</b>.</div>';return}box.innerHTML=state.levels.map(l=>`<div class="level ${l.id===activeLevel?'active':''}" onclick="setActive(${inlineArg(l.id)})"><div class="levelHead"><button class="levelName" type="button" dir="auto">${esc(l.name)}</button><div class="count">${l.unit_count||0} وحدة</div><button class="iconBtn" title="#{MHDESIGN::Language.for_tool('materials').html('TEXT_DEC6FB9A60AC')}" onclick="event.stopPropagation();renameLevel(${inlineArg(l.id)},${inlineArg(l.name)})">✎</button><button class="iconBtn danger" title="#{MHDESIGN::Language.for_tool('materials').html('COMMON_DELETE')}" onclick="event.stopPropagation();deleteLevel(${inlineArg(l.id)})">×</button></div><div class="levelBody"><div class="targets"><button class="target ${l.id===activeLevel&&activeTarget==='door'?'active':''}" onclick="event.stopPropagation();setTarget(${inlineArg(l.id)},'door')">#{MHDESIGN::Language.for_tool('materials').html('TEXT_C00A3F5C6446')}</button><button class="target ${l.id===activeLevel&&activeTarget==='carcass'?'active':''}" onclick="event.stopPropagation();setTarget(${inlineArg(l.id)},'carcass')">#{MHDESIGN::Language.for_tool('materials').html('OPT_CARCASS_MATERIAL')}</button><button class="target ${l.id===activeLevel&&activeTarget==='back'?'active':''}" onclick="event.stopPropagation();setTarget(${inlineArg(l.id)},'back')">#{MHDESIGN::Language.for_tool('materials').html('OPT_BACK_MATERIAL')}</button></div><div class="actions"><button class="small" onclick="event.stopPropagation();sketchup.assign_selection(${inlineArg(l.id)})">#{MHDESIGN::Language.for_tool('materials').html('TEXT_0CA22D0D09CB')}</button><button class="small" onclick="event.stopPropagation();sketchup.add_selection(${inlineArg(l.id)})">#{MHDESIGN::Language.for_tool('materials').html('TEXT_176675B99533')}</button><button class="small" onclick="event.stopPropagation();sketchup.select_units(${inlineArg(l.id)})">#{MHDESIGN::Language.for_tool('materials').html('TEXT_6B0FACB813EF')}</button></div></div></div>`).join('')}
          function renderTabs(){q('#tabs').innerHTML=`<button class="tab ${activeCategory==='all'?'active':''}" onclick="activeCategory='all';renderTabs();renderMaterials()">#{MHDESIGN::Language.for_tool('materials').html('REPORT_ALL')}</button>`+library.categories.map(c=>`<button class="tab ${activeCategory===c.name?'active':''}" onclick="activeCategory=${inlineArg(c.name)};renderTabs();renderMaterials()">${esc(c.name)}</button>`).join('')}
          function allItems(){return library.categories.flatMap(c=>c.images||[])}
          function renderMaterials(){let items=allItems(),s=q('#search').value.trim().toLowerCase();if(activeCategory!=='all')items=items.filter(x=>x.category===activeCategory);if(s)items=items.filter(x=>(x.name+' '+x.category).toLowerCase().includes(s));if(!library.root&&!state.folder){q('#grid').innerHTML='<div class="hint">#{MHDESIGN::Language.for_tool('materials').html('TEXT_82F7ACE04377')}<br>#{MHDESIGN::Language.for_tool('materials').html('TEXT_289788D1D0D3')}</div>';return}if(!items.length){q('#grid').innerHTML='<div class="hint">#{MHDESIGN::Language.for_tool('materials').html('TEXT_4624F5AC5443')}</div>';return}renderSwatches(items)}
          function renderSwatches(items){
            q('#grid').innerHTML=items.map(m=>`
              <div class="mat">
                <button class="swatch" type="button" aria-label="${esc(m.name)}" title="${esc(m.name)}" onclick="applyMat(${inlineArg(encodeURIComponent(m.path))})">
                  <img class="thumb" src="${esc(m.url)}" alt="">
                </button>
                <div class="matMeta">
                  <div class="matName" dir="auto">${esc(m.name)}</div>
                  <button class="edit" type="button" title="#{MHDESIGN::Language.for_tool('materials').html('TEXT_9D2E066AC72A')}" onclick="openEditor(${inlineArg(m)})">✎</button>
                </div>
              </div>`).join('');
          }
          let busy=false;
          function startBusy(message){
            if(busy)return false;
            busy=true;
            q('#busyText').textContent=message||'جاري التجهيز...';
            q('#busyFill').style.width='8%';
            q('#busyPercent').textContent='8%';
            q('#busyOverlay').classList.add('show');
            return true;
          }
          function updateBusy(message,percent){
            q('#busyText').textContent=message||'جاري التجهيز...';
            let p=Math.max(0,Math.min(100,Number(percent)||0));
            q('#busyFill').style.width=p+'%';
            q('#busyPercent').textContent=Math.round(p)+'%';
          }
          function finishBusy(success,message){
            updateBusy(success?'تم بنجاح':'تعذر إتمام العملية',100);
            setTimeout(()=>{
              q('#busyOverlay').classList.remove('show');
              busy=false;
              showToast(message||(success?'تم التنفيذ بنجاح':'تعذر إتمام العملية'));
            },320);
          }
          function applyMat(encoded){
            if(!activeLevel){showToast('اختر مستوى أولاً');return}
            if(!startBusy('جاري تجهيز الخامة...'))return;
            // التأخير البسيط يسمح للنافذة بالظهور قبل بدء Ruby الثقيل،
            // فلا يشعر المستخدم أن SketchUp توقف.
            setTimeout(()=>sketchup.apply_material(activeLevel,activeTarget,decodeURIComponent(encoded)),60);
          }
          function openEditor(item){editItem=item;q('#editTitle').textContent='تعديل: '+item.name;q('#editPreview').src=item.url;q('#editW').value=item.width_cm;q('#editH').value=item.height_cm;q('#editR').value=String(item.rotation||0);q('#modal').classList.add('show')}
          function closeEditor(){q('#modal').classList.remove('show');editItem=null}
          function saveEditor(){if(!editItem)return;let data={width_cm:parseFloat(q('#editW').value)||100,height_cm:parseFloat(q('#editH').value)||100,rotation:parseInt(q('#editR').value)||0};sketchup.save_material_settings(editItem.path,JSON.stringify(data));closeEditor()}
          let toastTimer;function showToast(t){let x=q('#toast');x.textContent=t;x.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>x.classList.remove('show'),2300)}
          document.addEventListener('DOMContentLoaded',()=>{setLibraryExpanded(false);sketchup.ready()});

          document.addEventListener('keydown',function(e){
            const resetOverlay=q('#resetOverlay');
            if(resetOverlay&&resetOverlay.classList.contains('show')){
              if(e.key==='Escape'){e.preventDefault();closeResetModal();}
              else if(e.key==='Enter'){e.preventDefault();confirmResetLevels();}
              return;
            }

            const overlay=q('#renameOverlay');
            if(!overlay||!overlay.classList.contains('show'))return;
            if(e.key==='Escape'){e.preventDefault();closeRenameModal();}
            else if(e.key==='Enter'){e.preventDefault();confirmRenameLevel();}
          });
          document.addEventListener('click',function(e){
            const resetOverlay=q('#resetOverlay');
            if(resetOverlay&&resetOverlay.classList.contains('show')&&e.target===resetOverlay){
              closeResetModal();
              return;
            }

            const overlay=q('#renameOverlay');
            if(overlay&&overlay.classList.contains('show')&&e.target===overlay)closeRenameModal();
          });

        </script>
      </body></html>
      HTML

      engine = language_engine
      engine ? engine.translate_source(raw_html) : raw_html
    rescue
      raw_html || ''
    end

    unless file_loaded?(__FILE__)
      recover_stale_presentation_state(current_model)
      menu = UI.menu('Extensions').add_submenu('MHDESIGN') rescue UI.menu('Extensions')
      menu.add_item(tr('مستويات وخامات المطبخ')) { open }

      # لا يتم إنشاء Toolbar أو أيقونة مستقلة لهذه الأداة.
      file_loaded(__FILE__)
      puts 'MHDESIGN Kitchen Levels & Materials v1.0.69 loaded'
    end
  end
end
