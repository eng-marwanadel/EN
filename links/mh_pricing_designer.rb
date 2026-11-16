# encoding: UTF-8
require 'json'
require 'sketchup'
require 'cgi'
require 'fileutils'
require 'securerandom'

module MHDESIGN
  module PricingDesignerBoardV2
    extend self

    PLUGIN_ID   = 'mhdesign_pricing_designer_board_v2'.freeze
    PLUGIN_NAME = 'MHDESIGN Pricing / Designer Board'.freeze
    DB_FILE_CANDIDATES = [
      'mh_pricing_admin_data.json',
      'mh_pricing_admin_units_master_seed.json',
      'mh_pricing_admin_data_seeded_all_found.json',
      'mh_pricing_admin_data_units_seeded.json'
    ].freeze

    @dialog = nil
    @pending_focus_payload = nil


    DATA_DIR = begin
      appdata = ENV['APPDATA'].to_s
      if appdata.nil? || appdata.strip.empty?
        File.join(Dir.home, 'AppData', 'Roaming', 'MHDESIGN', 'DesignerBoard')
      else
        File.join(appdata, 'MHDESIGN', 'DesignerBoard')
      end
    rescue StandardError
      File.join(Dir.home, 'AppData', 'Roaming', 'MHDESIGN', 'DesignerBoard')
    end

    COMPANY_FILE = File.join(DATA_DIR, 'company.json')
    CLIENTS_FILE = File.join(DATA_DIR, 'clients.json')
    CATEGORY_CACHE_FILE = File.join(DATA_DIR, 'unit_category_cache.json')
    MATCHING_FILE = File.join(DATA_DIR, 'mh_matching_file.json')

    @dialog = nil


    def ensure_storage_files_exist!
      FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
      unless File.exist?(COMPANY_FILE)
        write_json_file(COMPANY_FILE, default_company_data)
      end
      unless File.exist?(CLIENTS_FILE)
        write_json_file(CLIENTS_FILE, { 'clients' => [] })
      end
      unless File.exist?(CATEGORY_CACHE_FILE)
        write_json_file(CATEGORY_CACHE_FILE, {})
      end
    rescue StandardError
      nil
    end

    def default_company_data
      {
        'company_name' => 'MHDESIGN',
        'company_phone' => '01100211340',
        'company_addr' => 'Egypt',
        'logo_url' => '',
        'footer_notes' => '',
        'print_options' => {
          'invoice' => {
            'show_logo' => true,
            'show_company' => true,
            'show_client' => true,
            'show_code' => true,
            'show_commercial_name' => true,
            'show_dimensions' => true,
            'show_materials' => true,
            'show_assembly' => true,
            'show_qursa' => true,
            'show_thickness' => true,
            'show_drawers' => true,
            'show_shelves' => true,
            'show_visible_side' => true,
            'show_accessories' => true,
            'show_handle' => true,
            'show_notes' => true,
            'show_price' => true,
            'show_total' => true,
            'show_footer' => true
          },
          'workorder' => {
            'show_logo' => true,
            'show_company' => true,
            'show_client' => true,
            'show_code' => true,
            'show_commercial_name' => true,
            'show_dimensions' => true,
            'show_materials' => true,
            'show_assembly' => true,
            'show_qursa' => true,
            'show_thickness' => true,
            'show_drawers' => true,
            'show_shelves' => true,
            'show_visible_side' => true,
            'show_accessories' => true,
            'show_handle' => true,
            'show_notes' => true,
            'show_price' => false,
            'show_total' => false,
            'show_footer' => true
          }
        }
      }
    end

    def read_json_file(path, fallback)
      return fallback unless File.exist?(path)
      JSON.parse(File.read(path, encoding: 'UTF-8'))
    rescue StandardError
      fallback
    end

    # ============================================================
    # Matching file helpers
    # يقرأ ملف mh_matching_file.json لو موجود، ويستخدمه كقاموس أسماء فقط.
    # أي خطأ في الملف لا يوقف لوحة التسعير؛ يتم الرجوع للمنطق القديم.
    # ============================================================

    def load_matching_data
      @matching_data_loaded ||= false
      return @matching_data if @matching_data_loaded

      @matching_data_loaded = true
      @matching_data = {}
      return @matching_data unless File.exist?(MATCHING_FILE)

      data = JSON.parse(File.read(MATCHING_FILE, encoding: 'UTF-8'))
      unless data.is_a?(Hash)
        @matching_data = {}
        return @matching_data
      end

      @matching_data = data
    rescue StandardError
      @matching_data = {}
    end

    def matching_rows(kind)
      data = load_matching_data
      rows = Array(data[kind.to_s])
      rows.select { |row| row.is_a?(Hash) && row['active'] != false && present?(row['name']) }
    rescue StandardError
      []
    end

    def matching_name_equivalent?(value, row)
      raw = value.to_s
      return false if raw.strip.empty? || !row.is_a?(Hash)
      candidates = [row['name']] + Array(row['aliases'])
      normalized_raw = normalize_text(raw)
      candidates.any? do |candidate|
        n = normalize_text(candidate)
        !n.empty? && (normalized_raw == n || normalized_raw.include?(n) || n.include?(normalized_raw))
      end
    rescue StandardError
      false
    end

    def canonical_matching_name(kind, value)
      raw = value.to_s.strip
      return '' if raw.empty?
      matching_rows(kind).each do |row|
        return row['name'].to_s.strip if matching_name_equivalent?(raw, row)
      end
      raw
    rescue StandardError
      value.to_s
    end

    def find_pricing_entry_by_name(name, collection)
      n = normalize_text(name)
      return nil if n.empty?
      Array(collection).find do |entry|
        next false unless entry.is_a?(Hash)
        [entry['name'], entry['library_name'], entry['kind']].any? { |v| normalize_text(v) == n }
      end
    rescue StandardError
      nil
    end

    def canonical_name_for_matching(kind, value, collection = [])
      raw = value.to_s.strip
      return '' if raw.empty?

      entry = find_pricing_entry_by_name(raw, collection)
      if entry
        linked = entry['library_name'].to_s.strip
        linked = entry['kind'].to_s.strip if linked.empty?
        return canonical_matching_name(kind, linked) unless linked.empty?
      end

      canonical_matching_name(kind, raw)
    rescue StandardError
      value.to_s
    end

    def normalize_priced_items_for_matching(value, fallback_name = nil, kind = 'accessories', collection = [])
      normalize_priced_items(value, fallback_name).map do |row|
        {
          'name' => canonical_name_for_matching(kind, row['name'], collection),
          'qty' => row['qty'].to_f
        }
      end.group_by { |row| normalize_text(row['name']) }.values.map do |group|
        first = group.first
        { 'name' => first['name'].to_s, 'qty' => group.reduce(0.0) { |sum, row| sum + row['qty'].to_f } }
      end.select { |row| present?(row['name']) && row['qty'].to_f > 0 }
    rescue StandardError
      []
    end

    def priced_item_signature_for_matching(value, fallback_name = nil, kind = 'accessories', collection = [])
      normalize_priced_items_for_matching(value, fallback_name, kind, collection).map do |row|
        qty = row['qty'].to_f
        qty_txt = (qty % 1.0).zero? ? qty.to_i.to_s : qty.round(3).to_s
        [normalize_text(row['name']), qty_txt]
      end.reject { |name, _qty| name.empty? }.sort
    rescue StandardError
      []
    end

    def write_json_file(path, payload)
      FileUtils.mkdir_p(File.dirname(path)) unless Dir.exist?(File.dirname(path))
      File.write(path, JSON.pretty_generate(payload), mode: 'w:utf-8')
      true
    rescue StandardError
      false
    end

    def load_company_data
      ensure_storage_files_exist!
      data = read_json_file(COMPANY_FILE, default_company_data)
      default_company_data.merge(data.is_a?(Hash) ? data : {})
    end

    def save_company_data(data)
      ensure_storage_files_exist!
      payload = default_company_data.merge(data.is_a?(Hash) ? data : {})
      write_json_file(COMPANY_FILE, payload)
    end

    def load_clients_data
      ensure_storage_files_exist!
      data = read_json_file(CLIENTS_FILE, { 'clients' => [] })
      data.is_a?(Hash) && data['clients'].is_a?(Array) ? data : { 'clients' => [] }
    end

    def save_clients_data(data)
      ensure_storage_files_exist!
      payload = data.is_a?(Hash) && data['clients'].is_a?(Array) ? data : { 'clients' => [] }
      write_json_file(CLIENTS_FILE, payload)
    end

    def find_client(data, cid)
      return nil unless data.is_a?(Hash) && data['clients'].is_a?(Array)
      data['clients'].find { |c| c['id'].to_s == cid.to_s }
    end

    def load_category_cache
      ensure_storage_files_exist!
      data = read_json_file(CATEGORY_CACHE_FILE, {})
      data.is_a?(Hash) ? data : {}
    end

    def save_category_cache(data)
      ensure_storage_files_exist!
      payload = data.is_a?(Hash) ? data : {}
      write_json_file(CATEGORY_CACHE_FILE, payload)
    end

    def cache_unit_category(library_name, category, category_label_value)
      return unless present?(library_name)
      return unless present?(category)

      cache = load_category_cache
      cache[library_name.to_s] = {
        'category' => category.to_s,
        'category_label' => category_label_value.to_s
      }
      save_category_cache(cache)
    rescue StandardError
      nil
    end

    def read_cached_unit_category(library_name)
      return {} unless present?(library_name)
      cache = load_category_cache
      row = cache[library_name.to_s]
      row.is_a?(Hash) ? row : {}
    rescue StandardError
      {}
    end

    def plugin_dir
      @plugin_dir ||= File.dirname(__FILE__)
    end

    def default_db_path
      DB_FILE_CANDIDATES.each do |name|
        data_path = File.join(DATA_DIR, name)
        return data_path if File.exist?(data_path)

        legacy_path = File.join(plugin_dir, name)
        return legacy_path if File.exist?(legacy_path)
      end
      ''
    end

    def present?(value)
      !(value.nil? || value.to_s.strip.empty?)
    end

    def safe_json(obj)
      JSON.generate(obj)
    rescue StandardError
      '{}'
    end

    def strip_library_suffix(value)
      txt = value.to_s.strip
      return '' if txt.empty?
      txt.gsub(/\s*\([^\)]*\)\s*/, ' ').gsub(/\s+/, ' ').strip
    end

    def normalize_text(value)
      txt = strip_library_suffix(value).to_s
      return '' if txt.strip.empty?

      txt = txt.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
      txt = txt.tr('أإآ', 'ااا')
      txt = txt.tr('ؤ', 'و')
      txt = txt.tr('ئ', 'ي')
      txt = txt.tr('ى', 'ي')
      txt = txt.tr('ة', 'ه')
      txt = txt.gsub('ـ', '')
      txt.downcase.strip.gsub(/[\s_\-\+]+/, '').gsub(/[^\p{Alnum}\p{Arabic}]/, '')
    end

    def text_equivalent?(a, b)
      na = normalize_text(a)
      nb = normalize_text(b)
      return true if na == nb
      return false if na.empty? || nb.empty?
      short, long = [na, nb].sort_by(&:length)
      return false if short.length < 4
      long.include?(short)
    end

    def normalize_label(value)
      strip_library_suffix(value)
    end

    def map_visible_side(value)
      v = value.to_s.strip
      return value.to_i if [0, 1, 2, '0', '1', '2'].include?(value)
      return 0 if v.empty? || v == 'لا'
      return 2 if v.include?('الاتجاهين') || v.include?('اتجاهين')
      return 1 if v.include?('يمين') || v.include?('شمال')
      0
    end


    def category_label(key)
      {
        'base' => 'الوحدات السفلية',
        'wall' => 'الوحدات العلوية',
        'tall' => 'الدواليب'
      }[key.to_s] || key.to_s
    end

    def parse_database
      path = default_db_path.to_s
      return [nil, 'ملف قاعدة البيانات غير موجود بجوار الملف.'] if path.empty?
      begin
        [JSON.parse(File.read(path, encoding: 'UTF-8')), nil]
      rescue => e
        [nil, "تعذر قراءة قاعدة البيانات: #{e.message}"]
      end
    end

    def database_state
      data, error = parse_database
      units = Array(data && data['units'])
      items_count = units.reduce(0) { |s, u| s + Array(u['items']).length }
      materials = Array(data && data['materials'])
      accessories = Array(data && data['accessories'])
      handles = Array(data && data['handles'])
      {
        loaded: !data.nil?,
        path: default_db_path,
        units_count: units.length,
        items_count: items_count,
        materials_count: materials.length,
        accessories_count: accessories.length,
        handles_count: handles.length,
        error: error
      }
    end


    def hide_dialog_temporarily
      return unless @dialog
      begin
        @dialog_last_position = @dialog.get_position if @dialog.respond_to?(:get_position)
      rescue StandardError
        @dialog_last_position = nil
      end

      begin
        @dialog_last_size = @dialog.get_size if @dialog.respond_to?(:get_size)
      rescue StandardError
        @dialog_last_size = nil
      end

      begin
        if @dialog.respond_to?(:set_size)
          @dialog.set_size(420, 110)
        end
      rescue StandardError
      end

      begin
        if @dialog.respond_to?(:set_position)
          @dialog.set_position(20, 20)
        end
      rescue StandardError
      end

      begin
        @dialog.bring_to_front if @dialog.respond_to?(:bring_to_front)
      rescue StandardError
      end
    end

    def restore_dialog_temporarily_hidden
      return unless @dialog

      begin
        if @dialog_last_size.is_a?(Array) && @dialog_last_size.length >= 2 && @dialog.respond_to?(:set_size)
          @dialog.set_size(@dialog_last_size[0].to_i, @dialog_last_size[1].to_i)
        end
      rescue StandardError
      end

      begin
        if @dialog_last_position.is_a?(Array) && @dialog_last_position.length >= 2 && @dialog.respond_to?(:set_position)
          @dialog.set_position(@dialog_last_position[0].to_i, @dialog_last_position[1].to_i)
        end
      rescue StandardError
      end

      begin
        @dialog.bring_to_front if @dialog.respond_to?(:bring_to_front)
      rescue StandardError
      end

      begin
        refresh_row_from_payload(@pending_focus_payload) if @pending_focus_payload.is_a?(Hash)
      rescue StandardError
      end
    end

    class TempHighlightTool
      ESC_KEY = 27

      def initialize(mod_ref, entity)
        @mod_ref = mod_ref
        @entity = entity
      end

      def activate
        Sketchup.active_model.selection.clear
        Sketchup.active_model.selection.add(@entity) if @entity && @entity.valid?
      rescue StandardError
      end

      def deactivate(view)
        view.invalidate if view
      rescue StandardError
      end

      def onCancel(_reason, view)
        finish(view)
      end

      def onKeyDown(key, _repeat, _flags, view)
        finish(view) if key.to_i == ESC_KEY
      end

      def draw(view)
        return unless @entity && @entity.valid?
        bb = @entity.bounds
        pts = []
        8.times { |i| pts << bb.corner(i) }

        view.line_width = 4
        view.drawing_color = Sketchup::Color.new(255, 221, 0)

        edges = [
          [0,1],[1,3],[3,2],[2,0],
          [4,5],[5,7],[7,6],[6,4],
          [0,4],[1,5],[2,6],[3,7]
        ]
        edges.each do |a, b|
          view.draw(GL_LINES, pts[a], pts[b])
        end
      rescue StandardError
      end

      private

      def finish(view)
        @mod_ref.restore_dialog_temporarily_hidden if @mod_ref
        Sketchup.active_model.select_tool(nil)
        view.invalidate if view
      rescue StandardError
      end
    end

    def focus_entity_by_row_payload(payload)
      model = Sketchup.active_model
      entity = nil

      pid = payload.is_a?(Hash) ? (payload['persistent_id'] || payload[:persistent_id]) : nil
      eid = payload.is_a?(Hash) ? (payload['entity_id'] || payload[:entity_id]) : nil

      if pid && model.respond_to?(:find_entity_by_persistent_id)
        begin
          entity = model.find_entity_by_persistent_id(pid.to_i)
        rescue StandardError
          entity = nil
        end
      end

      if entity.nil? && eid
        begin
          entity = component_entities_from_active_context.find { |e| e.entityID.to_i == eid.to_i }
        rescue StandardError
          entity = nil
        end
      end

      unless entity && entity.valid?
        UI.messagebox('تعذر العثور على الوحدة داخل المشهد.')
        return false
      end

      model.selection.clear
      model.selection.add(entity)
      @pending_focus_payload = payload.is_a?(Hash) ? payload : {}
      hide_dialog_temporarily
      model.select_tool(TempHighlightTool.new(self, entity))

      true
    rescue StandardError => e
      UI.messagebox("تعذر تحديد الوحدة:\n#{e.message}")
      false
    end


    def refresh_row_from_payload(payload)
      return unless @dialog
      return unless payload.is_a?(Hash)

      settings = project_settings_payload(payload['settings'] || payload[:settings] || {})
      settings['unit_accessories'] = Array(payload['unit_accessories'] || payload[:unit_accessories])
      settings['unit_accessory_items'] = Array(payload['unit_accessory_items'] || payload[:unit_accessory_items])
      settings['unit_handle_items'] = Array(payload['unit_handle_items'] || payload[:unit_handle_items])
      settings['unit_overrides'] = (payload['unit_overrides'] || payload[:unit_overrides]).is_a?(Hash) ? (payload['unit_overrides'] || payload[:unit_overrides]) : {}

      model = Sketchup.active_model
      entity = nil

      pid = payload['persistent_id'] || payload[:persistent_id]
      eid = payload['entity_id'] || payload[:entity_id]

      if pid && model.respond_to?(:find_entity_by_persistent_id)
        begin
          entity = model.find_entity_by_persistent_id(pid.to_i)
        rescue StandardError
          entity = nil
        end
      end

      if entity.nil? && eid
        begin
          entity = component_entities_from_active_context.find { |e| e.entityID.to_i == eid.to_i }
        rescue StandardError
          entity = nil
        end
      end

      return unless entity && entity.valid?

      data, _ = parse_database
      reading = extract_entity_data(entity, data)
      match = data ? match_reading_to_db(reading, data, settings) : { status: 'no_db', message: 'قاعدة البيانات غير موجودة.', checks: [], mismatch_reasons: ['قاعدة البيانات غير موجودة.'] }
      result = format_result(reading, match)

      prev_reading = payload['reading'] || payload[:reading] || {}
      if prev_reading.is_a?(Hash)
        result[:read][:category] = prev_reading['category'] || prev_reading[:category] if result[:read].is_a?(Hash) && !present?(result[:read][:category])
        result[:read][:category_label] = prev_reading['category_label'] || prev_reading[:category_label] if result[:read].is_a?(Hash) && !present?(result[:read][:category_label])
      end

      @dialog.execute_script("window.MH && window.MH.receiveRowUpdate(#{safe_json(result)})")
    rescue StandardError
      nil
    end

    def component_entities_from_selection
      model = Sketchup.active_model
      model.selection.grep(Sketchup::ComponentInstance) + model.selection.grep(Sketchup::Group)
    end

    def component_entities_from_active_context
      model = Sketchup.active_model
      model.active_entities.grep(Sketchup::ComponentInstance) + model.active_entities.grep(Sketchup::Group)
    end

    def collect_attributes(entity)
      rows = []
      [['entity', entity], ['definition', entity.respond_to?(:definition) ? entity.definition : nil]].each do |scope, target|
        next unless target && target.respond_to?(:attribute_dictionaries)
        dicts = target.attribute_dictionaries
        next unless dicts
        dicts.each do |dict|
          dict.each_pair do |k, v|
            rows << {
              scope: scope,
              dictionary: dict.name.to_s,
              key: k.to_s,
              norm_key: normalize_text(k),
              value: v
            }
          end
        end
      end
      rows
    end

    def dynamic_maps(entries, scope = 'entity')
      rows = entries.select { |row| row[:scope].to_s == scope.to_s && row[:dictionary].to_s == 'dynamic_attributes' }
      rows.each_with_object({}) { |row, memo| memo[row[:key].to_s] = row[:value] }
    end

    def decode_option_text(text)
      return '' unless present?(text)
      s = text.to_s.gsub(/%u([0-9a-fA-F]{4})/) { [$1.hex].pack('U') }
      CGI.unescape(s)
    rescue StandardError
      text.to_s
    end

    def parse_options_map(raw)
      decoded = decode_option_text(raw)
      return {} if decoded.empty?
      decoded.split('&').map(&:strip).reject(&:empty?).each_with_object({}) do |part, memo|
        label, value = part.split('=', 2)
        next unless present?(label) && present?(value)
        memo[value.to_s.strip] = label.to_s.strip
      end
    end

    def suffix_value(map, suffixes)
      Array(suffixes).each do |suffix|
        key = map.keys.find { |k| k.downcase.end_with?(suffix.downcase) }
        return [key, map[key]] if key && present?(map[key])
      end
      [nil, nil]
    end

    def resolve_dynamic_value(entity_dyn, definition_dyn, suffixes)
      key, raw = suffix_value(entity_dyn, suffixes)
      return ['', '', ''] unless key && present?(raw)
      options_raw = definition_dyn["_#{key}_options"] || definition_dyn["#{key}_options"]
      options_map = parse_options_map(options_raw)
      value = options_map[raw.to_s.strip] || raw
      [key, raw, normalize_label(value)]
    end

    def resolve_dynamic_value_by_candidates(entity_dyn, definition_dyn, entries, exact_keys: [], suffixes: [], norm_contains: [])
      key = nil
      raw = nil

      Array(exact_keys).each do |candidate|
        found = entity_dyn.keys.find { |k| k.to_s.casecmp(candidate.to_s).zero? }
        if found && present?(entity_dyn[found])
          key = found
          raw = entity_dyn[found]
          break
        end
      end

      if key.nil?
        found_key, found_raw = suffix_value(entity_dyn, suffixes)
        if found_key && present?(found_raw)
          key = found_key
          raw = found_raw
        end
      end

      if key.nil?
        candidates = Array(norm_contains).map { |v| normalize_text(v) }.reject(&:empty?)
        row = entries.find do |r|
          next false unless r[:scope].to_s == 'entity' && r[:dictionary].to_s == 'dynamic_attributes'
          next false unless present?(r[:value])
          norm = r[:norm_key].to_s
          candidates.any? { |c| norm.include?(c) }
        end
        if row
          key = row[:key].to_s
          raw = row[:value]
        end
      end

      return ['', '', ''] unless key && present?(raw)
      options_raw = definition_dyn["_#{key}_options"] || definition_dyn["#{key}_options"]
      options_map = parse_options_map(options_raw)
      value = options_map[raw.to_s.strip] || raw
      [key, raw, normalize_label(value)]
    end

    def integerish(value)
      return nil unless present?(value)
      value.to_s.scan(/-?\d+/).first&.to_i
    end

    def parse_dimension_number(raw_value)
      return nil unless present?(raw_value)
      txt = raw_value.to_s.strip
      num = txt.gsub(',', '.').scan(/-?\d+(?:\.\d+)?/).first
      return nil unless num
      val = num.to_f
      val > 0 ? val : nil
    rescue StandardError
      nil
    end

    def parse_thickness_to_cm(raw_value)
      return nil unless present?(raw_value)
      txt = raw_value.to_s.strip.downcase.tr(',', '.')
      num = txt.scan(/-?\d+(?:\.\d+)?/).first
      return nil unless num
      val = num.to_f
      return nil unless val > 0

      if txt.include?('mm') || txt.include?('مم')
        (val / 10.0).round(3)
      elsif txt.include?('cm') || txt.include?('سم')
        val.round(3)
      elsif txt.include?('in') || txt.include?('inch') || txt.include?('"')
        (val * 2.54).round(3)
      else
        # Dynamic Attributes in SketchUp typically store raw lengths in inches.
        (val * 2.54).round(3)
      end
    rescue StandardError
      nil
    end

    def format_cm_value(value)
      n = parse_dimension_number(value)
      return '' if n.nil?
      s = format('%.3f', n).sub(/\.0+$/, '').sub(/(\.\d*?)0+$/, '\1')
      s
    end

    def numeric_or_text_match(a, b)
      an = parse_dimension_number(a)
      bn = parse_dimension_number(b)
      if !an.nil? && !bn.nil?
        return (an - bn).abs <= 0.01
      end
      normalize_text(a) == normalize_text(b)
    end

    def parse_width_candidate(raw_value)
      val = parse_dimension_number(raw_value)
      return nil unless val && val > 0
      (val * 2.54).round(3)
    end

    def child_component_names(entity)
      ents = if entity.is_a?(Sketchup::Group)
               entity.entities
             elsif entity.respond_to?(:definition) && entity.definition
               entity.definition.entities
             end
      return [] unless ents
      ents.each_with_object([]) do |child, memo|
        next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
        nm = ''
        begin
          dyn = child.attribute_dictionary('dynamic_attributes', false)
          nm = dyn && (dyn['name'] || dyn['_name']).to_s
        rescue StandardError
        end
        nm = child.definition.name.to_s if nm.to_s.strip.empty? && child.respond_to?(:definition) && child.definition
        memo << nm unless nm.to_s.strip.empty?
      end
    end

    def drawer_face_exact?(child)
      return false unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)

      names = []
      begin
        names << child.name.to_s
      rescue StandardError
      end
      begin
        names << child.definition.name.to_s if child.respond_to?(:definition) && child.definition
      rescue StandardError
      end
      begin
        dyn = child.attribute_dictionary('dynamic_attributes', false)
        if dyn
          names << dyn['name'].to_s
          names << dyn['_name'].to_s
        end
      rescue StandardError
      end

      needle = normalize_text('وش درج')
      names.compact.any? do |nm|
        normalized = normalize_text(nm)
        !normalized.empty? && normalized.include?(needle)
      end
    end

    def nested_entities_for(child)
      if child.is_a?(Sketchup::Group)
        child.entities
      elsif child.respond_to?(:definition) && child.definition
        child.definition.entities
      end
    rescue StandardError
      nil
    end

    def visible_for_drawer_count?(child)
      return false if child.nil?

      begin
        return false if child.hidden?
      rescue StandardError
      end

      begin
        layer = child.layer if child.respond_to?(:layer)
        return false if layer && layer.respond_to?(:visible?) && !layer.visible?
      rescue StandardError
      end

      begin
        dyn = child.attribute_dictionary('dynamic_attributes', false)
        if dyn
          hidden_raw = dyn['_hidden'] || dyn['hidden'] || dyn['Hidden'] || dyn['_is_hidden']
          unless hidden_raw.nil?
            hidden_norm = normalize_text(hidden_raw)
            return false if %w[1 true yes on hidden].include?(hidden_norm)
          end
        end
      rescue StandardError
      end

      true
    end

    def count_drawer_faces_recursive(entities, depth = 0)
      return 0 if entities.nil? || depth > 20

      count = 0
      entities.each do |child|
        next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
        next unless visible_for_drawer_count?(child)

        count += 1 if drawer_face_exact?(child)
        count += count_drawer_faces_recursive(nested_entities_for(child), depth + 1)
      end
      count
    end

def shelf_definition_name_match?(definition_name)
  raw = definition_name.to_s.strip
  return false if raw.empty?

  normalized = normalize_text(raw)
  return false if normalized.include?(normalize_text('رفرف'))

  # كلمة رف صريحة في بداية الاسم فقط
  !!raw.match(/\A\s*رف(?=\s|\(|#|\d|$)/)
rescue StandardError
  false
end

def visible_named_parts_recursive(entities, counts = nil, depth = 0)
  counts ||= { shelves: 0, visible_sides: 0, shaddadat: 0, qursa: 0 }
  return counts if entities.nil? || depth > 20

  entities.each do |child|
    next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
    next unless visible_for_drawer_count?(child)

    def_name = ''
    begin
      def_name = child.definition.name.to_s if child.respond_to?(:definition) && child.definition
    rescue StandardError
      def_name = ''
    end

    normalized_name = normalize_text(def_name)
    counted_shelf_here = false

    unless normalized_name.empty?
      if shelf_definition_name_match?(def_name)
        counts[:shelves] += 1
        counted_shelf_here = true
      end

      counts[:visible_sides] += 1 if normalized_name.include?(normalize_text('جنب ظاهر'))
      counts[:shaddadat] += 1 if normalized_name.include?(normalize_text('شداد'))
      counts[:qursa] += 1 if normalized_name.include?(normalize_text('قرصة')) || normalized_name.include?(normalize_text('قرصه'))
    end

    # مهم: لو العنصر نفسه رف، ما ننزلش داخله عشان ما نعدوش مرتين
    next if counted_shelf_here

    visible_named_parts_recursive(nested_entities_for(child), counts, depth + 1)
  end

  counts
end


    # ============================================================
    # Accessories scan by Definition names
    # يقرأ فقط الإكسسوارات الجديدة التي عليها scan_definition = true
    # من ملف mh_matching_file.json، لذلك المنطق القديم لا يتأثر.
    # ============================================================

    def accessory_definition_catalog
      matching_rows('accessories')
        .select { |row| row['scan_definition'] == true || row['scan_definition'].to_s == 'true' || row['scan_definition'].to_s == '1' }
        .map do |row|
          {
            'name' => row['name'].to_s,
            'aliases' => (Array(row['aliases']) + [row['name']]).map(&:to_s).uniq
          }
        end
    rescue StandardError
      []
    end

    def accessory_names_from_child(child)
      names = []
      begin
        names << child.name.to_s if child.respond_to?(:name)
      rescue StandardError
      end
      begin
        names << child.definition.name.to_s if child.respond_to?(:definition) && child.definition
      rescue StandardError
      end
      begin
        dyn = child.attribute_dictionary('dynamic_attributes', false)
        if dyn
          names << dyn['name'].to_s
          names << dyn['_name'].to_s
        end
      rescue StandardError
      end
      names.map(&:to_s).map(&:strip).reject(&:empty?)
    end

    def accessory_definition_match?(raw_name, aliases)
      normalized = normalize_text(raw_name)
      return false if normalized.empty?
      Array(aliases).any? do |candidate|
        n = normalize_text(candidate)
        !n.empty? && (normalized == n || normalized.include?(n) || n.include?(normalized))
      end
    rescue StandardError
      false
    end

    def count_accessory_definitions_recursive(entities, counts = nil, depth = 0)
      counts ||= Hash.new(0)
      return counts if entities.nil? || depth > 20

      catalog = accessory_definition_catalog
      return counts if catalog.empty?

      entities.each do |child|
        next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
        next unless visible_for_drawer_count?(child)

        names = accessory_names_from_child(child)
        matched = false
        catalog.each do |row|
          if names.any? { |nm| accessory_definition_match?(nm, row['aliases']) }
            counts[row['name']] += 1
            matched = true
            break
          end
        end

        # لو العنصر نفسه هو الإكسسوار، لا ندخل داخله حتى لا يتكرر العد.
        next if matched
        count_accessory_definitions_recursive(nested_entities_for(child), counts, depth + 1)
      end

      counts
    rescue StandardError
      counts || Hash.new(0)
    end

    def read_accessory_items_from_definitions(entity)
      counts = count_accessory_definitions_recursive(nested_entities_for(entity))
      rows = counts.map { |name, qty| { 'name' => name.to_s, 'qty' => qty.to_i } }
                   .select { |row| present?(row['name']) && row['qty'].to_i > 0 }
      [rows, 'definition names / recursive / matching scan_definition']
    rescue StandardError
      [[], '']
    end

    def merge_priced_item_rows(*collections)
      rows = []
      collections.flatten.each do |row|
        next unless row.is_a?(Hash)
        name = row['name'] || row[:name]
        qty  = row['qty'] || row[:qty] || 1
        next unless present?(name) && qty.to_f > 0
        rows << { 'name' => name.to_s.strip, 'qty' => qty.to_f }
      end

      rows.group_by { |row| normalize_text(row['name']) }.values.map do |group|
        first = group.first
        { 'name' => first['name'].to_s, 'qty' => group.reduce(0.0) { |sum, row| sum + row['qty'].to_f } }
      end.select { |row| present?(row['name']) && row['qty'].to_f > 0 }
    rescue StandardError
      []
    end

    def read_shelves_count(entity, _entity_dyn)
      counts = visible_named_parts_recursive(nested_entities_for(entity))
      [counts[:shelves].to_i, 'definition only']
    end

    def read_visible_side_from_definitions(entity)
      counts = visible_named_parts_recursive(nested_entities_for(entity))
      count = counts[:visible_sides].to_i
      return [2, 'visible definitions / recursive'] if count >= 2
      return [1, 'visible definitions / recursive'] if count == 1
      return ['لا', 'visible definitions / recursive'] if count == 0
      [nil, '']
    end

    def read_qursa_type_from_definitions(entity)
      counts = visible_named_parts_recursive(nested_entities_for(entity))
      return ['قرصة كاملة', 'visible definitions / recursive'] if counts[:qursa].to_i > 0
      return ['شدادات', 'visible definitions / recursive'] if counts[:shaddadat].to_i > 0
      [nil, '']
    end


    def handle_definition_catalog
      rows = matching_rows('handles')
      unless rows.empty?
        return rows.map do |row|
          {
            'name' => row['name'].to_s,
            'aliases' => (Array(row['aliases']) + [row['name']]).map(&:to_s).uniq
          }
        end
      end

      [
        {
          'name' => 'مقبض بلت ان سفلي حرف L',
          'aliases' => ['مقبض بلت ان سفلي حرف L', 'مقبد بلت ان سفلي حرف L', 'مقبض بلت ان سفلي حرف ال', 'مقبد بلت ان سفلي حرف ال']
        },
        {
          'name' => 'مقبض بلت ان سفلي حرف سي',
          'aliases' => ['مقبض بلت ان سفلي حرف سي', 'مقبد بلت ان سفلي حرف سي', 'مقبض بلت ان سفلي حرف C', 'مقبد بلت ان سفلي حرف C']
        },
        {
          'name' => 'مقبض بلت ان علوي حرف ال',
          'aliases' => ['مقبض بلت ان علوي حرف ال', 'مقبد بلت ان علوي حرف ال', 'مقبض بلت ان علوي حرف L', 'مقبد بلت ان علوي حرف L']
        },
        {
          'name' => 'مقبض عادي او تاتش',
          'aliases' => ['مقبض عادي او تاتش', 'مقبض عادي', 'مقبد عادي', 'تاتش', 'مقبض تاتش', 'مقبد تاتش']
        },
        {
          'name' => 'مقبض بلت ان حفر سفلي',
          'aliases' => ['مقبض بلت ان حفر سفلي', 'مقبد بلت ان حفر سفلي']
        },
        {
          'name' => 'مقبض بلت ان حفر علوي',
          'aliases' => ['مقبض بلت ان حفر علوي', 'مقبد بلت ان حفر علوي']
        }
      ]
    end

    def normalize_handle_definition_text(value)
      txt = value.to_s
      txt = txt.gsub('مقبد', 'مقبض')
      normalize_text(txt)
    rescue StandardError
      ''
    end

    def handle_definition_match?(raw_name, aliases)
      normalized = normalize_handle_definition_text(raw_name)
      return false if normalized.empty?
      Array(aliases).any? do |candidate|
        n = normalize_handle_definition_text(candidate)
        !n.empty? && normalized.include?(n)
      end
    rescue StandardError
      false
    end

    def canonical_handle_name(name)
      raw = name.to_s.strip
      return '' if raw.empty?
      handle_definition_catalog.each do |row|
        aliases = Array(row['aliases']) + [row['name']]
        return row['name'].to_s if handle_definition_match?(raw, aliases)
      end
      raw
    rescue StandardError
      name.to_s
    end

    def normalize_handle_priced_items(value, fallback_name = nil)
      rows = normalize_priced_items(value, fallback_name).map do |row|
        { 'name' => canonical_handle_name(row['name']), 'qty' => row['qty'].to_f }
      end

      rows
        .group_by { |row| normalize_handle_definition_text(row['name']) }
        .values
        .map do |group|
          first = group.first
          { 'name' => first['name'].to_s, 'qty' => group.reduce(0.0) { |sum, row| sum + row['qty'].to_f } }
        end
        .select { |row| present?(row['name']) && row['qty'].to_f > 0 }
    rescue StandardError
      []
    end

    def normalize_handle_item_signature(value, fallback_name = nil)
      normalize_handle_priced_items(value, fallback_name).map do |row|
        qty = row['qty'].to_f
        qty_txt = (qty % 1.0).zero? ? qty.to_i.to_s : qty.round(3).to_s
        [normalize_handle_definition_text(row['name']), qty_txt]
      end.reject { |name, _qty| name.empty? }.sort
    rescue StandardError
      []
    end

    def handle_names_from_child(child)
      names = []
      begin
        names << child.name.to_s if child.respond_to?(:name)
      rescue StandardError
      end
      begin
        names << child.definition.name.to_s if child.respond_to?(:definition) && child.definition
      rescue StandardError
      end
      begin
        dyn = child.attribute_dictionary('dynamic_attributes', false)
        if dyn
          names << dyn['name'].to_s
          names << dyn['_name'].to_s
        end
      rescue StandardError
      end
      names.map(&:to_s).map(&:strip).reject(&:empty?)
    end

    def count_handle_definitions_recursive(entities, counts = nil, depth = 0)
      counts ||= Hash.new(0)
      return counts if entities.nil? || depth > 20

      catalog = handle_definition_catalog
      entities.each do |child|
        next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
        next unless visible_for_drawer_count?(child)

        names = handle_names_from_child(child)
        matched = false
        catalog.each do |row|
          if names.any? { |nm| handle_definition_match?(nm, row['aliases']) }
            counts[row['name']] += 1
            matched = true
            break
          end
        end

        next if matched
        count_handle_definitions_recursive(nested_entities_for(child), counts, depth + 1)
      end

      counts
    end

    def read_handle_items_from_definitions(entity)
      counts = count_handle_definitions_recursive(nested_entities_for(entity))
      rows = counts.map { |name, qty| { 'name' => name.to_s, 'qty' => qty.to_i } }
                   .select { |row| present?(row['name']) && row['qty'].to_i > 0 }
      [rows, 'definition names / recursive']
    rescue StandardError
      [[], '']
    end

    def read_width_cm(_entity, entries)
      entity_dyn = dynamic_maps(entries, 'entity')
      ['LenX', 'lenx', '_lenx'].each do |k|
        next unless present?(entity_dyn[k])
        width = parse_width_candidate(entity_dyn[k])
        return [width.round(1), "entity / dynamic_attributes / #{k}"] if width && width > 0
      end
      key, raw = suffix_value(entity_dyn, ['_0a1'])
      if key && present?(raw)
        width = parse_width_candidate(raw)
        return [width.round(1), "entity / dynamic_attributes / #{key}"] if width && width > 0
      end
      [nil, '']
    end

    def read_depth_cm(entries)
      entity_dyn = dynamic_maps(entries, 'entity')
      ['lyny', 'LenY', 'leny', '_leny'].each do |k|
        next unless present?(entity_dyn[k])
        depth = parse_width_candidate(entity_dyn[k])
        return [depth.round(1), "entity / dynamic_attributes / #{k}"] if depth && depth > 0
      end
      _k, raw, value = resolve_dynamic_value_by_candidates(entity_dyn, dynamic_maps(entries, 'definition'), entries,
        exact_keys: ['depth', 'Depth', 'unit_depth'], suffixes: ['_depth', '_deep'], norm_contains: ['عمق', 'depth', 'deep'])
      depth = parse_width_candidate(raw || value)
      return [depth.round(1), 'entity / dynamic_attributes / depth'] if depth && depth > 0
      [nil, '']
    end

    def read_height_cm(entries)
      entity_dyn = dynamic_maps(entries, 'entity')
      ['lynz', 'LenZ', 'lenz', '_lenz'].each do |k|
        next unless present?(entity_dyn[k])
        height = parse_width_candidate(entity_dyn[k])
        return [height.round(1), "entity / dynamic_attributes / #{k}"] if height && height > 0
      end
      _k, raw, value = resolve_dynamic_value_by_candidates(entity_dyn, dynamic_maps(entries, 'definition'), entries,
        exact_keys: ['height', 'Height', 'unit_height'], suffixes: ['_height', '_high'], norm_contains: ['ارتفاع', 'height'])
      height = parse_width_candidate(raw || value)
      return [height.round(1), 'entity / dynamic_attributes / height'] if height && height > 0
      [nil, '']
    end

    def infer_category(entity_dyn, attrs, library_name)
      source_url = attrs.find { |r| r[:scope] == 'entity' && r[:dictionary] == 'MHDESIGN_SOURCE' && r[:key] == 'source_url' }&.dig(:value).to_s
      source_name = attrs.find { |r| r[:scope] == 'entity' && r[:dictionary] == 'MHDESIGN_SOURCE' && r[:key] == 'source_name' }&.dig(:value).to_s
      txt = normalize_text([source_url, source_name, library_name].join(' '))
      return 'base' if txt.include?('base') || txt.include?('سفلي') || txt.include?('سفليه')
      return 'wall' if txt.include?('wall') || txt.include?('علوي') || txt.include?('علويه')
      return 'tall' if txt.include?('tall') || txt.include?('دولاب')
      ''
    end

    def extract_entity_data(entity, data = nil)
      attrs = collect_attributes(entity)
      entity_dyn = dynamic_maps(attrs, 'entity')
      definition_dyn = dynamic_maps(attrs, 'definition')

      library_name = normalize_label(entity_dyn['name'])
      library_name = normalize_label(entity.name) unless present?(library_name)
      definition_name = entity.respond_to?(:definition) && entity.definition ? normalize_label(entity.definition.name) : ''
      library_name = definition_name if !present?(library_name)

      width_cm, width_source = read_width_cm(entity, attrs)
      depth_cm, depth_source = read_depth_cm(attrs)
      height_cm, height_source = read_height_cm(attrs)
      _ck, _cr, carcass_value = resolve_dynamic_value(entity_dyn, definition_dyn, ['_j'])
      _bk, _br, back_value    = resolve_dynamic_value(entity_dyn, definition_dyn, ['_h'])
      door_values = []
      ['_fa', '_n', '_oe', '_ohd', '_f'].each do |suffix|
        _k, _r, v = resolve_dynamic_value(entity_dyn, definition_dyn, [suffix])
        door_values << v if present?(v)
      end
      door_value = door_values.uniq.join(' / ')
      _ak, _ar, assembly_value = resolve_dynamic_value(entity_dyn, definition_dyn, ['_a1'])
      _qk, _qr, qursa_value = resolve_dynamic_value(entity_dyn, definition_dyn, ['_a11'])
      _sk, _sr, side_value = resolve_dynamic_value(entity_dyn, definition_dyn, ['_a111'])
      def_qursa_value, _def_qursa_source = read_qursa_type_from_definitions(entity)
      qursa_value = def_qursa_value if present?(def_qursa_value)
      def_side_value, _def_side_source = read_visible_side_from_definitions(entity)
      side_value = def_side_value unless def_side_value.nil?
      _hk, _hr, handle_value = resolve_dynamic_value(entity_dyn, definition_dyn, ['_ha', '_handle', '_handle_name', '_hand'])
      handle_items_from_defs, handle_items_source = read_handle_items_from_definitions(entity)
      handle_value = priced_items_label(handle_items_from_defs) if handle_items_from_defs && !handle_items_from_defs.empty?
      _ctk, counter_thickness_raw, counter_thickness_value = resolve_dynamic_value_by_candidates(entity_dyn, definition_dyn, attrs,
        exact_keys: ['BASE_UNIT_1_D', 'base_unit_1_d', 'counter_thickness', '_counter_thickness'], suffixes: ['_counter_thickness', '_cth', '_ct'], norm_contains: ['تخانة الكونتر', 'سمك الكونتر', 'counter thickness', 'counter_thickness'])
      counter_thickness_cm = parse_thickness_to_cm(counter_thickness_raw || counter_thickness_value)
      counter_thickness_value = counter_thickness_cm.nil? ? (present?(counter_thickness_raw) ? counter_thickness_raw : counter_thickness_value) : format_cm_value(counter_thickness_cm)
      _btk, back_thickness_raw, back_thickness_value = resolve_dynamic_value_by_candidates(entity_dyn, definition_dyn, attrs,
        exact_keys: ['BASE_UNIT_1_A3', 'base_unit_1_a3', 'back_thickness', '_back_thickness'], suffixes: ['_back_thickness', '_bth', '_bt'], norm_contains: ['تخانة الظهر', 'سمك الظهر', 'back thickness', 'back_thickness'])
      back_thickness_cm = parse_thickness_to_cm(back_thickness_raw || back_thickness_value)
      back_thickness_value = back_thickness_cm.nil? ? (present?(back_thickness_raw) ? back_thickness_raw : back_thickness_value) : format_cm_value(back_thickness_cm)
      counted_drawers = count_drawer_faces_recursive(nested_entities_for(entity))
      _drk, _drr, drawers_count_value = resolve_dynamic_value_by_candidates(entity_dyn, definition_dyn, attrs,
        exact_keys: ['drawers_count', '_drawers_count'], suffixes: ['_drawers_count', '_drawer_count', '_drawers'], norm_contains: ['الادراج', 'الأدراج', 'drawer'])
      drawers_count_value = counted_drawers if counted_drawers > 0

      accessory_values = []
      ['_ja', '_o', '_of', '_ohe'].each do |suffix|
        _k, _r, v = resolve_dynamic_value(entity_dyn, definition_dyn, [suffix])
        next unless present?(v)
        next if v.include?('---') || v == 'بدون اكسسوار'
        accessory_values << v
      end
      accessory_items_from_attrs = normalize_priced_items(accessory_values.join(' / '))
      accessory_items_from_defs, accessory_items_defs_source = read_accessory_items_from_definitions(entity)
      # أي إكسسوار مقروء من Definition يتم تجاهله لو ملوش بند تجاري مفعل في لوحة التحكم.
      accessory_items_from_defs = filter_active_accessory_rows(accessory_items_from_defs, data) if data.is_a?(Hash)
      merged_accessory_items = merge_priced_item_rows(accessory_items_from_attrs, accessory_items_from_defs)
      accessory_value = priced_items_label(merged_accessory_items)
      shelves_count, shelves_source = read_shelves_count(entity, entity_dyn)
      category = infer_category(entity_dyn, attrs, library_name)

      {
        entity_id: entity.entityID,
        persistent_id: (entity.respond_to?(:persistent_id) ? entity.persistent_id : nil),
        entity_type: entity.is_a?(Sketchup::Group) ? 'Group' : 'Component',
        sketchup_name: normalize_label(entity.name),
        definition_name: definition_name,
        library_name: library_name,
        width_cm: width_cm,
        width_source: width_source,
        depth_cm: depth_cm,
        depth_source: depth_source,
        height_cm: height_cm,
        height_source: height_source,
        category: category,
        category_label: category_label(category),
        carcass_material: carcass_value,
        door_material: door_value,
        back_material: back_value,
        accessory_name: accessory_value,
        accessory_items: merged_accessory_items,
        accessory_source: accessory_items_from_defs.empty? ? 'dynamic attributes' : accessory_items_defs_source,
        handle_name: handle_value,
        handle_items: handle_items_from_defs,
        handle_source: handle_items_source,
        assembly_method: assembly_value,
        qursa_type: qursa_value,
        counter_thickness: counter_thickness_value,
        back_thickness: back_thickness_value,
        drawers_count: integerish(drawers_count_value) || 0,
        visible_side: side_value,
        shelves_count: shelves_count,
        shelves_source: shelves_source
      }
    end

    def project_materials_for(settings, category)
      h = settings[category.to_s] || {}
      {
        carcass: h['carcass_material'].to_s,
        door: h['door_material'].to_s,
        back: h['back_material'].to_s,
        handle: h['handle_name'].to_s
      }
    end

    def width_matching(item_widths, observed_width)
      widths = item_widths.compact.map(&:to_f).uniq.sort
      return [nil, '', nil] if widths.empty? || observed_width.nil?
      obs = observed_width.to_f
      exact = widths.find { |w| (w - obs).abs <= 0.5 }
      return [exact, '', exact] if exact
      higher = widths.select { |w| w >= obs }.min
      chosen = higher || widths.max
      msg = "تم التسعير على عرض #{chosen.to_i} بدل #{obs.round(1)}. راجع المقاس."
      [chosen, msg, chosen]
    end

    def normalize_priced_items(value, fallback_name = nil)
      rows = []

      if value.is_a?(Array)
        value.each do |row|
          if row.is_a?(Hash)
            name = (row['name'] || row[:name] || row['label'] || row[:label]).to_s.strip
            qty  = (row['qty'] || row[:qty] || row['quantity'] || row[:quantity] || 1).to_f
            rows << { 'name' => name, 'qty' => qty } if present?(name) && qty > 0
          elsif present?(row)
            rows << { 'name' => row.to_s.strip, 'qty' => 1 }
          end
        end
      elsif value.is_a?(Hash)
        value.each do |name, qty|
          rows << { 'name' => name.to_s.strip, 'qty' => qty.to_f } if present?(name) && qty.to_f > 0
        end
      elsif present?(value)
        value.to_s.split(%r{\s*[\/،,+]\s*}).map(&:strip).reject(&:empty?).each do |name|
          rows << { 'name' => name, 'qty' => 1 }
        end
      end

      if rows.empty? && present?(fallback_name)
        fallback_name.to_s.split(%r{\s*[\/،,+]\s*}).map(&:strip).reject(&:empty?).each do |name|
          rows << { 'name' => name, 'qty' => 1 }
        end
      end

      rows
        .group_by { |row| normalize_text(row['name']) }
        .values
        .map do |group|
          first = group.first
          { 'name' => first['name'].to_s, 'qty' => group.reduce(0.0) { |sum, row| sum + row['qty'].to_f } }
        end
        .select { |row| present?(row['name']) && row['qty'].to_f > 0 }
    rescue StandardError
      []
    end

    def item_accessory_items(item)
      normalize_priced_items(item && item['accessory_items'], item && item['accessory_name'])
    end

    def item_handle_items(item)
      normalize_handle_priced_items(item && item['handle_items'], item && item['handle_name'])
    end

    def priced_items_label(rows)
      normalize_priced_items(rows).map do |row|
        qty = row['qty'].to_f
        qty_txt = (qty % 1.0).zero? ? qty.to_i.to_s : qty.round(2).to_s
        "#{row['name']} × #{qty_txt}"
      end.join(' / ')
    end

    def normalize_priced_item_set(value, fallback_name = nil)
      normalize_priced_items(value, fallback_name).map { |row| normalize_text(row['name']) }.reject(&:empty?).uniq.sort
    end

    def normalize_priced_item_signature(value, fallback_name = nil)
      normalize_priced_items(value, fallback_name).map do |row|
        qty = row['qty'].to_f
        qty_txt = (qty % 1.0).zero? ? qty.to_i.to_s : qty.round(3).to_s
        [normalize_text(row['name']), qty_txt]
      end.reject { |name, _qty| name.empty? }.sort
    end

    def db_accessory_presence(item)
      return false unless item.is_a?(Hash)
      return true unless item_accessory_items(item).empty?
      normalized_bool(item['has_accessory'])
    end

    def normalize_accessory_set(value)
      normalize_priced_item_set(value)
    end

    def pricing_entry_matches_name?(entry, row_name, kind = 'accessories')
      return false unless entry.is_a?(Hash) && entry['active'] != false
      target = row_name.to_s
      return false unless present?(target)

      target_norm = normalize_text(target)
      target_canon_norm = normalize_text(canonical_matching_name(kind, target))

      [entry['name'], entry['library_name'], entry['kind']].any? do |candidate|
        next false unless present?(candidate)
        candidate_norm = normalize_text(candidate)
        candidate_canon_norm = normalize_text(canonical_matching_name(kind, candidate))
        candidate_norm == target_norm ||
          candidate_norm == target_canon_norm ||
          candidate_canon_norm == target_norm ||
          candidate_canon_norm == target_canon_norm
      end
    rescue StandardError
      false
    end

    def find_pricing_entry_for_row(row_name, collection, kind = 'accessories')
      Array(collection).find { |entry| pricing_entry_matches_name?(entry, row_name, kind) }
    rescue StandardError
      nil
    end


    def display_pricing_name(row_name, collection, kind = 'accessories')
      raw = row_name.to_s.strip
      return '' if raw.empty?
      found = find_pricing_entry_for_row(raw, collection, kind)
      display = found && found['name'].to_s.strip
      display && !display.empty? ? display : raw
    rescue StandardError
      row_name.to_s
    end

    def display_priced_items_label(value, collection, kind = 'accessories', fallback_name = nil)
      rows = normalize_priced_items(value, fallback_name)
      rows.map do |row|
        display = display_pricing_name(row['name'], collection, kind)
        qty = row['qty'].to_f
        qty_txt = (qty % 1.0).zero? ? qty.to_i.to_s : qty.round(2).to_s
        "#{display} × #{qty_txt}"
      end.join(' / ')
    rescue StandardError
      priced_items_label(value)
    end

    def priced_collection_total(rows, collection, kind = 'accessories')
      normalized_rows = normalize_priced_items_for_matching(rows, nil, kind, Array(collection))
      source = Array(collection)
      normalized_rows.reduce(0.0) do |sum, row|
        found = find_pricing_entry_for_row(row['name'], source, kind)
        sum + (found ? found['price'].to_f * row['qty'].to_f : 0.0)
      end
    rescue StandardError
      0.0
    end

    def handle_meter_pricing?(handle)
      type = (handle && handle['pricing_type']).to_s.strip.downcase
      ['بالمتر', 'سعر بالمتر', 'متر', 'meter', 'per_meter', 'per meter'].include?(type)
    rescue StandardError
      false
    end

    def item_accessories_total(item, data)
      priced_collection_total(item_accessory_items(item), Array(data && data['accessories']), 'accessories')
    end

    def item_handles_total(item, data)
      rows = normalize_priced_items_for_matching(item_handle_items(item), nil, 'handles', Array(data && data['handles']))
      handles = Array(data && data['handles'])
      width_m = parse_dimension_number(item && item['width']).to_f / 100.0
      rows.reduce(0.0) do |sum, row|
        found = find_pricing_entry_for_row(row['name'], handles, 'handles')
        next sum unless found
        base = found['price'].to_f
        qty = row['qty'].to_f
        line_total = handle_meter_pricing?(found) ? (base * width_m * qty) : (base * qty)
        sum + line_total
      end
    rescue StandardError
      0.0
    end

    def normalized_bool(value)
      return true if [true, 1, '1', 'true', 'yes', 'نعم'].include?(value)
      return false if [false, 0, '0', 'false', 'no', 'لا', nil, ''].include?(value)
      false
    end

    def accessory_presence(value)
      !normalize_priced_items(value).empty?
    end

    # يرجع فقط الإكسسوارات التي لها بند تجاري مفعل داخل لوحة التحكم.
    # ملف المطابقة يحدد أسماء القراءة فقط، لكن الاعتماد النهائي على mh_pricing_admin_data.json.
    def filter_active_accessory_rows(rows, data)
      normalized_rows = normalize_priced_items(rows)
      return normalized_rows unless data.is_a?(Hash)

      accessories_collection = Array(data['accessories'])
      normalized_rows.select do |row|
        found = find_pricing_entry_for_row(row['name'], accessories_collection, 'accessories')
        found && found['active'] != false && present?(found['name'])
      end
    rescue StandardError
      []
    end

    def active_accessory_presence(value, data)
      !filter_active_accessory_rows(value, data).empty?
    rescue StandardError
      false
    end

    def db_active_accessory_presence(item, data)
      return false unless item.is_a?(Hash)
      !filter_active_accessory_rows(item_accessory_items(item), data).empty?
    rescue StandardError
      false
    end

    def compare_item_against_reading(it, reading, pricing_materials = {}, chosen_accessories = [], chosen_handle = '', data = nil)
      accessories_collection = Array(data && data['accessories'])
      handles_collection = Array(data && data['handles'])
      chosen_accessories = filter_active_accessory_rows(chosen_accessories, data)
      item_accessories_for_match = filter_active_accessory_rows(normalize_priced_items(it['accessory_items'], it['accessory_name']), data)
      chosen_acc_set = priced_item_signature_for_matching(chosen_accessories, nil, 'accessories', accessories_collection)
      item_acc_set = priced_item_signature_for_matching(item_accessories_for_match, nil, 'accessories', accessories_collection)
      chosen_handle_set = priced_item_signature_for_matching(chosen_handle, nil, 'handles', handles_collection)
      item_handle_set = priced_item_signature_for_matching(it['handle_items'], it['handle_name'], 'handles', handles_collection)
      reading_side = map_visible_side(reading[:visible_side])
      item_side = map_visible_side(it['visible_side'])
      ignore_shelf = normalized_bool(it['ignore_shelf'])

      checks = {
        carcass_material: normalize_text(pricing_materials[:carcass]) == normalize_text(it['carcass_material']),
        door_material: normalize_text(pricing_materials[:door]) == normalize_text(it['door_material']),
        back_material: normalize_text(pricing_materials[:back]) == normalize_text(it['back_material']),
        depth: parse_dimension_number(reading[:depth_cm]) == parse_dimension_number(it['depth']),
        height: parse_dimension_number(reading[:height_cm]) == parse_dimension_number(it['height']),
        assembly_method: text_equivalent?(reading[:assembly_method], it['assembly_method']),
        qursa_type: text_equivalent?(reading[:qursa_type], (it['qursa_type'] || it['counter_type'])),
        counter_thickness: numeric_or_text_match(reading[:counter_thickness], it['counter_thickness']),
        back_thickness: numeric_or_text_match(reading[:back_thickness], it['back_thickness']),
        drawers_count: reading[:drawers_count].to_i == it['drawers_count'].to_i,
        handle_name: chosen_handle_set == item_handle_set,
        has_accessory: active_accessory_presence(chosen_accessories, data) == db_active_accessory_presence(it, data),
        accessory_name: chosen_acc_set == item_acc_set,
        visible_side: reading_side == item_side,
        shelves_count: ignore_shelf ? true : (reading[:shelves_count].to_i == it['shelves_count'].to_i)
      }

      mismatch_count = checks.values.count(false)
      exact = mismatch_count.zero?
      score = 0
      score += 1000 if exact
      score += 100 if checks[:carcass_material]
      score += 100 if checks[:door_material]
      score += 100 if checks[:back_material]
      score += 90 if checks[:depth]
      score += 90 if checks[:height]
      score += 80 if checks[:assembly_method]
      score += 80 if checks[:qursa_type]
      score += 80 if checks[:counter_thickness]
      score += 80 if checks[:back_thickness]
      score += 80 if checks[:drawers_count]
      score += 80 if checks[:handle_name]
      score += 80 if checks[:has_accessory]
      score += 80 if checks[:accessory_name]
      score += 70 if checks[:visible_side]
      score += 70 if checks[:shelves_count]
      { checks: checks, mismatch_count: mismatch_count, exact: exact, score: score }
    end

    def choose_best_item(unit, reading, pricing_materials = {}, chosen_accessories = [], chosen_handle = '', data = nil)
      items = Array(unit['items'])
      return nil if items.empty?

      obs = reading[:width_cm]
      items_by_width = items.group_by { |it| parse_dimension_number(it['width']) }.transform_keys { |k| k ? k.to_f : nil }
      chosen_width, msg, _ = width_matching(items_by_width.keys, obs)
      candidate_items = chosen_width ? items_by_width[chosen_width] : items
      candidate_items = items if candidate_items.nil? || candidate_items.empty?

      ranked = candidate_items.map do |it|
        cmp = compare_item_against_reading(it, reading, pricing_materials, chosen_accessories, chosen_handle, data)
        [cmp[:mismatch_count], -cmp[:score], it, cmp]
      end

      ranked.sort_by! { |mismatch_count, neg_score, _it, _cmp| [mismatch_count, neg_score] }
      best = ranked.first
      item = best && best[2]
      cmp  = best && best[3]
      {
        item: item,
        width_warning: msg,
        chosen_width: chosen_width,
        match_score: cmp && cmp[:score],
        mismatch_count: cmp && cmp[:mismatch_count],
        full_exact: cmp && cmp[:exact],
        compare_checks: cmp && cmp[:checks]
      }
    end

    def row_check(label, observed, expected, status)
      { label: label, observed: observed.to_s, expected: expected.to_s, status: status }
    end

    def mismatch_reasons(match)
      reasons = []
      reasons << match[:message].to_s if present?(match[:message])
      Array(match[:checks]).each do |row|
        next unless row[:status].to_s == 'mismatch'
        reasons << "#{row[:label]}: المقروء #{row[:observed]} / المتوقع #{row[:expected]}"
      end
      reasons.uniq
    end

    def match_reading_to_db(reading, data, settings)
      units = Array(data && data['units'])
      return { status: 'not_found', message: 'قاعدة البيانات لا تحتوي على وحدات.', checks: [] } if units.empty?

      reading_library_name = canonical_matching_name('units', reading[:library_name])
      lib_norm = normalize_text(reading_library_name)
      unit = units.find do |u|
        db_name = canonical_matching_name('units', u['library_name'])
        normalize_text(db_name) == lib_norm || normalize_text(u['library_name']) == normalize_text(reading[:library_name])
      end
      return { status: 'unit_not_found', message: 'لم يتم العثور على اسم وحدة المكتبة داخل قاعدة البيانات أو ملف المطابقة.', checks: [] } unless unit

      cat = unit['category'].to_s
      cat_label = unit['category_label'].to_s.empty? ? category_label(cat) : unit['category_label'].to_s
      cache_unit_category(unit['library_name'].to_s, cat, cat_label)
      project_materials = project_materials_for(settings, cat)
      overrides = settings['unit_overrides'].is_a?(Hash) ? settings['unit_overrides'] : {}
      pricing_materials = {
        carcass: overrides['carcass_material'].to_s.empty? ? project_materials[:carcass].to_s : overrides['carcass_material'].to_s,
        door: overrides['door_material'].to_s.empty? ? project_materials[:door].to_s : overrides['door_material'].to_s,
        back: overrides['back_material'].to_s.empty? ? project_materials[:back].to_s : overrides['back_material'].to_s
      }
      unit_selected_accessories = normalize_priced_items(settings['unit_accessory_items'])
      unit_selected_accessories = normalize_priced_items(settings['unit_accessories']) if unit_selected_accessories.empty?
      chosen_accessories = if !unit_selected_accessories.empty?
                             unit_selected_accessories
                           elsif !normalize_priced_items(overrides['accessory_items']).empty?
                             normalize_priced_items(overrides['accessory_items'])
                           elsif !overrides['accessory_name'].to_s.strip.empty?
                             normalize_priced_items(overrides['accessory_name'])
                           elsif !normalize_priced_items(reading[:accessory_items]).empty?
                             normalize_priced_items(reading[:accessory_items])
                           elsif present?(reading[:accessory_name])
                             normalize_priced_items(reading[:accessory_name])
                           else
                             []
                           end
      # تجاهل أي إكسسوار ليس له اسم تجاري مفعل في لوحة التحكم حتى لو تم رصده في Definition.
      chosen_accessories = filter_active_accessory_rows(chosen_accessories, data)

      unit_selected_handles = normalize_priced_items(settings['unit_handle_items'])
      chosen_handle = if !unit_selected_handles.empty?
                        unit_selected_handles
                      elsif !normalize_priced_items(overrides['handle_items']).empty?
                        normalize_priced_items(overrides['handle_items'])
                      elsif !overrides['handle_name'].to_s.strip.empty?
                        normalize_priced_items(overrides['handle_name'])
                      elsif !project_materials[:handle].to_s.strip.empty?
                        normalize_priced_items(project_materials[:handle])
                      elsif !normalize_priced_items(reading[:handle_items]).empty?
                        normalize_priced_items(reading[:handle_items])
                      elsif present?(reading[:handle_name])
                        normalize_priced_items(reading[:handle_name])
                      else
                        []
                      end

      best = choose_best_item(unit, reading, pricing_materials, chosen_accessories, chosen_handle, data)
      unless best && best[:item]
        return {
          status: 'item_not_found',
          message: 'لا يوجد بند تسعير داخل كارت الوحدة.',
          checks: [],
          unit_library_name: unit['library_name'].to_s,
          category: cat,
          category_label: cat_label,
          commercial_name: '',
          code: '',
          fixed_price: nil,
          total_price: nil,
          notes: '',
          pricing_materials: pricing_materials,
          effective_accessory: display_priced_items_label(chosen_accessories, Array(data && data['accessories']), 'accessories'),
          effective_handle: display_priced_items_label(chosen_handle, Array(data && data['handles']), 'handles'),
          mismatch_reasons: ['لا يوجد بند تسعير داخل كارت الوحدة.']
        }
      end

      item = best[:item]

      checks = []
      checks << row_check('العرض', reading[:width_cm], best[:chosen_width] || item['width'], best[:width_warning].to_s.empty? ? 'match' : 'mismatch')
      depth_match = parse_dimension_number(reading[:depth_cm]) == parse_dimension_number(item['depth'])
      height_match = parse_dimension_number(reading[:height_cm]) == parse_dimension_number(item['height'])
      checks << row_check('العمق', reading[:depth_cm], item['depth'], depth_match ? 'match' : 'mismatch')
      checks << row_check('الارتفاع', reading[:height_cm], item['height'], height_match ? 'match' : 'mismatch')
      checks << row_check('خامة الشاسيه', pricing_materials[:carcass], item['carcass_material'], normalize_text(pricing_materials[:carcass]) == normalize_text(item['carcass_material']) ? 'match' : 'mismatch')
      checks << row_check('خامة الضلفة', pricing_materials[:door], item['door_material'], normalize_text(pricing_materials[:door]) == normalize_text(item['door_material']) ? 'match' : 'mismatch')
      checks << row_check('خامة الظهر', pricing_materials[:back], item['back_material'], normalize_text(pricing_materials[:back]) == normalize_text(item['back_material']) ? 'match' : 'mismatch')
      chosen_accessory_label = display_priced_items_label(chosen_accessories, Array(data && data['accessories']), 'accessories')
      active_item_accessories = filter_active_accessory_rows(item_accessory_items(item), data)

      # مهم: اسم الإكسسوار المعروض في نتيجة التسعير لازم يطلع من بند الوحدة نفسه،
      # وليس أول اسم تجاري مطابق في جدول الإكسسوارات.
      # مثال: لو بند W-102 فيه "مطبقيه عاديه 70"، لا نعرض "مطبقيه عاديه 60" لمجرد أن الاثنين مربوطين بنفس library_name.
      item_accessory_label = priced_items_label(active_item_accessories)

      chosen_acc_set = priced_item_signature_for_matching(chosen_accessories, nil, 'accessories', Array(data && data['accessories']))
      item_acc_set = priced_item_signature_for_matching(active_item_accessories, nil, 'accessories', Array(data && data['accessories']))
      db_has_accessory = db_active_accessory_presence(item, data)
      has_accessory_match = active_accessory_presence(chosen_accessories, data) == db_has_accessory
      accessory_match = chosen_acc_set == item_acc_set

      # عند التطابق الفعلي، خلي المعروض الأساسي هو اسم الإكسسوار الموجود داخل بند الوحدة المختار.
      # ده يحافظ على السعر والمطابقة، ويمنع ظهور اسم تجاري آخر له نفس library_name.
      chosen_accessory_label = item_accessory_label if accessory_match && present?(item_accessory_label)
      chosen_handle_label = display_priced_items_label(chosen_handle, Array(data && data['handles']), 'handles')
      item_handle_label = priced_items_label(item_handle_items(item))
      handle_match = priced_item_signature_for_matching(chosen_handle, nil, 'handles', Array(data && data['handles'])) == priced_item_signature_for_matching(item['handle_items'], item['handle_name'], 'handles', Array(data && data['handles']))
      checks << row_check('هل يوجد إكسسوار', active_accessory_presence(chosen_accessories, data) ? 'نعم' : 'لا', db_has_accessory ? 'نعم' : 'لا', has_accessory_match ? 'match' : 'mismatch')
      checks << row_check('الإكسسوار', chosen_accessory_label, item_accessory_label, accessory_match ? 'match' : 'mismatch')
      checks << row_check('نوع المقبض', chosen_handle_label, item_handle_label, handle_match ? 'match' : 'mismatch')
      checks << row_check('طريقة التجميع', reading[:assembly_method], item['assembly_method'], text_equivalent?(reading[:assembly_method], item['assembly_method']) ? 'match' : 'mismatch')
      checks << row_check('نوع القرصة', reading[:qursa_type], (item['qursa_type'] || item['counter_type']), text_equivalent?(reading[:qursa_type], (item['qursa_type'] || item['counter_type'])) ? 'match' : 'mismatch')
      checks << row_check('تخانة الكونتر', reading[:counter_thickness], item['counter_thickness'], numeric_or_text_match(reading[:counter_thickness], item['counter_thickness']) ? 'match' : 'mismatch')
      checks << row_check('تخانة الظهر', reading[:back_thickness], item['back_thickness'], numeric_or_text_match(reading[:back_thickness], item['back_thickness']) ? 'match' : 'mismatch')
      checks << row_check('الأدراج', reading[:drawers_count], item['drawers_count'], reading[:drawers_count].to_i == item['drawers_count'].to_i ? 'match' : 'mismatch')
      db_side = map_visible_side(item['visible_side'])
      design_side = map_visible_side(reading[:visible_side])
      checks << row_check('جنب ظاهر', reading[:visible_side], item['visible_side'], db_side == design_side ? 'match' : 'mismatch')
      ignore_shelf = normalized_bool(item['ignore_shelf'])
      shelf_status = ignore_shelf ? 'match' : (reading[:shelves_count].to_i == item['shelves_count'].to_i ? 'match' : 'mismatch')
      checks << row_check('عدد الرفوف', reading[:shelves_count], item['shelves_count'], shelf_status)

      fixed_price = item['fixed_price'].to_f
      fixed_price = item['base_price'].to_f if fixed_price <= 0
      handle_extra_price = item_handles_total(item, data)
      accessories_extra_price = item_accessories_total(item, data)
      calculated_total_price = fixed_price + handle_extra_price + accessories_extra_price
      has_mismatch = checks.any? { |r| r[:status].to_s == 'mismatch' }
      status = has_mismatch ? 'mismatch' : 'exact'
      if status == 'exact'
        total_price = calculated_total_price
      else
        fixed_price = nil
        total_price = nil
      end

      match = {
        status: status,
        message: best[:width_warning].to_s,
        unit_library_name: unit['library_name'].to_s,
        category: cat,
        category_label: cat_label,
        commercial_name: item['commercial_name'].to_s,
        code: item['code'].to_s,
        fixed_price: fixed_price,
        handle_extra_price: status == 'exact' ? handle_extra_price : nil,
        accessories_extra_price: status == 'exact' ? accessories_extra_price : nil,
        total_price: total_price,
        checks: checks,
        notes: item['notes'].to_s,
        pricing_materials: pricing_materials,
        effective_accessory: chosen_accessory_label,
        db_accessory: item_accessory_label,
        effective_handle: chosen_handle_label,
        db_handle: item_handle_label
      }
      match[:mismatch_reasons] = mismatch_reasons(match)
      match
    end

    def format_result(reading, match)
      final_category = reading[:category]
      final_category_label = reading[:category_label]

      if match.is_a?(Hash)
        final_category = match[:category] if present?(match[:category])
        final_category_label = match[:category_label] if present?(match[:category_label])
      end

      if !present?(final_category)
        cached = read_cached_unit_category(reading[:library_name])
        if cached.is_a?(Hash)
          final_category = cached['category'] if present?(cached['category'])
          final_category_label = cached['category_label'] if present?(cached['category_label'])
        end
      end

      {
        entity_id: reading[:entity_id],
        persistent_id: reading[:persistent_id],
        library_name: reading[:library_name],
        width_cm: reading[:width_cm],
        width_source: reading[:width_source],
        category: final_category,
        category_label: final_category_label,
        read: reading,
        match: match,
        status: match[:status],
        commercial_name: match[:commercial_name].to_s,
        code: match[:code].to_s,
        total_price: match[:total_price],
        fixed_price: match[:fixed_price],
        handle_extra_price: match[:handle_extra_price],
        accessories_extra_price: match[:accessories_extra_price]
      }
    end

    def scan_entities(entities, settings)
      state = database_state
      data, _error = parse_database
      items = entities.map do |entity|
        reading = extract_entity_data(entity, data)
        match = data ? match_reading_to_db(reading, data, settings) : { status: 'no_db', message: 'قاعدة البيانات غير موجودة.', checks: [], mismatch_reasons: ['قاعدة البيانات غير موجودة.'] }
        format_result(reading, match)
      end
      grouped = {
        'base' => items.select { |i| i[:category].to_s == 'base' },
        'wall' => items.select { |i| i[:category].to_s == 'wall' },
        'tall' => items.select { |i| i[:category].to_s == 'tall' }
      }
      total = items.reduce(0.0) { |s, i| s + i[:total_price].to_f }
      {
        source_count: entities.length,
        items: items,
        grouped: grouped,
        total_price: total,
        database: state,
        accessories_selected_count: Array(settings['accessories']).length,
        mismatch_count: items.count { |i| i[:status].to_s == 'mismatch' },
        exact_count: items.count { |i| i[:status].to_s == 'exact' }
      }
    end

    def project_settings_payload(data)
      data.is_a?(Hash) ? data : {}
    end

    def push_bootstrap
      return unless @dialog
      data, _ = parse_database
      materials = Array(data && data['materials']).select { |m| m['active'] != false }
      accessories = Array(data && data['accessories']).select { |a| a['active'] != false }
      handles = Array(data && data['handles']).select { |h| h['active'] != false }
      payload = {
        database: database_state,
        materials: materials,
        accessories: accessories,
        handles: handles,
        company: load_company_data,
        clients: load_clients_data,
        matching: load_matching_data,
        matching_loaded: !matching_rows('units').empty? || !matching_rows('accessories').empty? || !matching_rows('handles').empty?
      }
      @dialog.execute_script("window.MH && window.MH.receiveBootstrap(#{safe_json(payload)})")
    end

    def push_results(results)
      return unless @dialog
      @dialog.execute_script("window.MH && window.MH.receiveResults(#{safe_json(results)})")
    end

    def open_dialog
      if @dialog
        begin
          if @dialog.visible?
            @dialog.bring_to_front
            refresh_row_from_payload(@pending_focus_payload) if @pending_focus_payload.is_a?(Hash)
            return
          else
            @dialog.show if @dialog.respond_to?(:show)
            @dialog.bring_to_front if @dialog.respond_to?(:bring_to_front)
            refresh_row_from_payload(@pending_focus_payload) if @pending_focus_payload.is_a?(Hash)
            return
          end
        rescue StandardError
        end
      end

      @dialog = UI::HtmlDialog.new(
        dialog_title: PLUGIN_NAME,
        scrollable: true,
        resizable: true,
        width: 1460,
        height: 980,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      @dialog.set_html(html)
      @dialog.add_action_callback('mh_ready') { |_ctx, _| push_bootstrap }
      @dialog.add_action_callback('mh_focus_unit') do |_ctx, payload|
        parsed = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        focus_entity_by_row_payload(parsed)
      end
      @dialog.add_action_callback('mh_scan_selected') do |_ctx, payload|
        parsed_payload = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        settings = project_settings_payload(parsed_payload)
        entities = component_entities_from_selection
        if entities.empty?
          push_results({ source_count: 0, items: [], grouped: { 'base' => [], 'wall' => [], 'tall' => [] }, total_price: 0, message: 'لم يتم تحديد أي وحدة.', mismatch_count: 0, exact_count: 0 })
        else
          push_results(scan_entities(entities, settings))
        end
      end
      @dialog.add_action_callback('mh_scan_all') do |_ctx, payload|
        parsed_payload = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        settings = project_settings_payload(parsed_payload)
        entities = component_entities_from_active_context
        push_results(scan_entities(entities, settings))
      end
      @dialog.add_action_callback('mh_rescore_row') do |_ctx, payload|
        parsed = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        settings = project_settings_payload(parsed['settings'] || {})
        settings['unit_accessories'] = Array(parsed['unit_accessories'])
        settings['unit_accessory_items'] = Array(parsed['unit_accessory_items'])
        settings['unit_handle_items'] = Array(parsed['unit_handle_items'])
        settings['unit_overrides'] = parsed['unit_overrides'].is_a?(Hash) ? parsed['unit_overrides'] : {}
        reading = parsed['reading'] || {}
        data, _ = parse_database
        match = data ? match_reading_to_db(reading.transform_keys(&:to_sym), data, settings) : { status: 'no_db', message: 'قاعدة البيانات غير موجودة.', checks: [], mismatch_reasons: ['قاعدة البيانات غير موجودة.'] }
        result = format_result(reading.transform_keys(&:to_sym), match)
        @dialog.execute_script("window.MH && window.MH.receiveRowUpdate(#{safe_json(result)})")
      end

      @dialog.add_action_callback('mh_pick_company_logo') do |_ctx, _payload|
        begin
          src = UI.openpanel('اختار لوجو الشركة', '', 'Images|*.png;*.jpg;*.jpeg;*.webp;*.gif||')
          if src && File.exist?(src)
            dest_dir = File.join(DATA_DIR, 'assets')
            FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)

            ext = File.extname(src).to_s.downcase
            ext = '.png' if ext.empty?
            dest = File.join(dest_dir, "company_logo#{ext}")
            FileUtils.copy(src, dest)

            web_path = 'file:///' + dest.gsub('\\', '/')
            @dialog.execute_script("window.MH && window.MH.receivePickedCompanyLogo(#{safe_json(web_path)})") if @dialog
          end
        rescue StandardError => e
          UI.messagebox("تعذر اختيار اللوجو:\n#{e.message}")
        end
      end

      @dialog.add_action_callback('mh_save_company') do |_ctx, payload|
        parsed = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        save_company_data(parsed)
        push_bootstrap
      end
      @dialog.add_action_callback('mh_clients_read') do |_ctx, _|
        @dialog.execute_script("window.MH && window.MH.receiveClients(#{safe_json(load_clients_data)})") if @dialog
      end
      @dialog.add_action_callback('mh_clients_write') do |_ctx, payload|
        parsed = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          { 'clients' => [] }
        end
        save_clients_data(parsed)
        @dialog.execute_script("window.MH && window.MH.receiveClients(#{safe_json(load_clients_data)})") if @dialog
      end
      @dialog.add_action_callback('mh_client_save_invoice') do |_ctx, payload|
        parsed = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        clients = load_clients_data
        client = find_client(clients, parsed['client_id'])
        if client
          client['invoices'] ||= []
          inv = {
            'id' => SecureRandom.uuid,
            'title' => parsed['title'].to_s.strip.empty? ? "فاتورة #{Time.now.strftime('%Y-%m-%d %H:%M')}" : parsed['title'].to_s,
            'date' => Time.now.strftime('%Y-%m-%d'),
            'payload' => parsed['payload'] || {}
          }
          client['invoices'].unshift(inv)
          save_clients_data(clients)
          @dialog.execute_script("window.MH && window.MH.afterSaveInvoice(#{safe_json(inv)})") if @dialog
          @dialog.execute_script("window.MH && window.MH.receiveClients(#{safe_json(load_clients_data)})") if @dialog
        end
      end
      @dialog.add_action_callback('mh_client_get_invoice') do |_ctx, payload|
        parsed = begin
          JSON.parse(payload.to_s)
        rescue StandardError
          {}
        end
        client = find_client(load_clients_data, parsed['client_id'])
        invoice = client && Array(client['invoices']).find { |i| i['id'].to_s == parsed['invoice_id'].to_s }
        @dialog.execute_script("window.MH && window.MH.loadSavedInvoice(#{safe_json(invoice ? invoice['payload'] : {})})") if @dialog
      end
      @dialog.show
    end

    def html
      <<~HTML
      <!DOCTYPE html>
      <html lang="ar" dir="rtl">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{PLUGIN_NAME}</title>
        <style>
          *{box-sizing:border-box}body{margin:0;font-family:Segoe UI,Tahoma,Arial,sans-serif;background:#eef1f5;color:#081225}
          .wrap{max-width:1460px;margin:0 auto;padding:14px;display:grid;gap:18px}
          .card{background:#f7f8fa;border:1px solid #dfe4ea;border-radius:28px;padding:18px 20px;box-shadow:0 6px 18px rgba(8,18,37,.04)}
          .header-row{display:flex;align-items:center;justify-content:space-between;gap:16px;min-height:70px;direction:rtl}.header-rtl{}.title{margin:0;font-size:34px;font-weight:900;color:#081a40}.brand-box{display:flex;align-items:center;gap:12px;flex-direction:row;text-align:right;margin-inline-start:0;margin-inline-end:auto}.brand-logo{width:60px;height:60px;object-fit:contain;border-radius:12px;background:#fff;border:1px solid #d9dfe6;padding:4px}.brand-name{font-size:22px;font-weight:900;color:#081a40}.brand-meta{font-size:14px;color:#66768f}.header-actions,.top-actions{display:flex;flex-wrap:wrap;justify-content:flex-start;gap:10px}.invoice-meta-grid{grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.invoice-meta-card .field input{font-size:18px}@media (max-width:1100px){.header-rtl,.toolbar{flex-direction:column;align-items:stretch}.brand-box{justify-content:flex-end;margin-inline-start:0}.header-actions,.top-actions{justify-content:flex-start}.invoice-meta-grid,.three-cols{grid-template-columns:1fr}}
          .page{display:none}.page.active{display:block}.section-title{margin:0 0 18px;font-size:28px;font-weight:900;color:#081a40}
          .three-cols{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:14px}.subcard{background:#f4f6f8;border:1px solid #d9dfe6;border-radius:24px;padding:18px}
          .subcard h3{margin:0 0 8px;font-size:24px;color:#081a40}.field{display:grid;gap:8px;margin-top:10px}.field label{font-size:14px;color:#5d6b82;font-weight:700}
          select,input{width:100%;height:46px;border:1px solid #cfd7e3;border-radius:16px;padding:0 14px;background:#fff;font-size:20px;color:#081225}
          .access-row{display:grid;grid-template-columns:180px 1fr;gap:18px;align-items:start}.btn{border:none;border-radius:18px;padding:12px 22px;font-size:18px;font-weight:900;cursor:pointer}
          .btn.primary{background:#2d67ea;color:#fff}.btn.secondary{background:#fff;color:#081225;border:1px solid #cfd7e3}.btn.ghost{background:#fff;color:#081225;border:1px solid #cfd7e3;padding:10px 18px}.btn.small{font-size:16px;padding:8px 14px;border-radius:999px}
          .tags{display:flex;gap:10px;flex-wrap:wrap;justify-content:flex-end}.tag{display:inline-flex;align-items:center;gap:8px;padding:12px 18px;border:1px solid #b9d4ff;border-radius:999px;background:#f6faff;color:#2d67ea;font-weight:900}.tag button{border:none;background:transparent;color:#d62839;font-size:22px;cursor:pointer;line-height:1}
          .footer-actions{display:flex;justify-content:flex-start;margin-top:18px}
          .toolbar{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:14px}.toolbar .btn{min-width:140px}.muted{color:#66768f}
          .section-band{background:#07142e;color:#fff;font-size:24px;font-weight:900;padding:10px 22px;border-radius:18px;margin:10px 0 16px}
          .invoice-box{background:#f4f6f8;border:1px solid #d9dfe6;border-radius:24px;padding:16px 18px;margin-bottom:16px}
          .invoice-head,.invoice-row{display:grid;grid-template-columns:120px 1.5fr 1.15fr 1.15fr 1.15fr 1.15fr 1.15fr 1fr 140px;gap:10px;align-items:center}
          .invoice-head{padding:12px 16px;border:1px solid #d9dfe6;border-radius:18px;background:#f8fafb;font-weight:900;color:#081225;margin-bottom:12px}
          .invoice-row{padding:14px 16px;border:1px solid #d9dfe6;border-radius:18px;background:#fff}.cell{font-size:18px}.cell.center{text-align:center}.status-btn{display:inline-flex;align-items:center;justify-content:center;border-radius:999px;padding:10px 16px;font-weight:900;border:1px solid transparent;cursor:pointer;background:#fff;font-size:18px}
          .status-btn.exact{color:#129a63;border-color:#a9e8cb;background:#f2fff9}.status-btn.mismatch{color:#cf2f34;border-color:#f2b8bb;background:#fff9f9}.status-btn.disabled{color:#74839b;border-color:#d3dbe7;background:#f5f7fa;cursor:default}
          .inline-select{width:100%;height:42px;border:1px solid #cfd7e3;border-radius:999px;padding:0 14px;background:#fff;font-size:17px;font-weight:800;color:#081225;appearance:none;text-align:center;text-align-last:center;cursor:pointer}
          .screen-only{display:block}.print-only{display:none}.print-chip{display:inline-flex;align-items:center;justify-content:center;min-height:42px;max-width:100%;padding:8px 14px;border:1px solid #cfd7e3;border-radius:999px;background:#fff;font-size:17px;font-weight:800;color:#081225;line-height:1.25;white-space:normal;word-break:break-word;text-align:center}.print-chip.empty{color:#74839b;background:#f8fafb}
          .summary-card{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px}.summary-item{background:#fff;border:1px solid #d9dfe6;border-radius:20px;padding:16px;text-align:center}.summary-item h4{margin:0 0 8px;font-size:18px;color:#66768f}.summary-item strong{font-size:28px;color:#081225}
          .total-box{margin-top:16px;background:#07142e;color:#fff;border-radius:22px;padding:18px 24px;display:flex;justify-content:space-between;align-items:center;font-size:30px;font-weight:900}
          .hidden{display:none!important}.empty{padding:24px;text-align:center;color:#66768f;background:#fff;border:1px dashed #d0d8e4;border-radius:18px}.print-doc{display:none}.pdf-shell{background:#fff;border:1px solid #d9dfe6;border-radius:24px;padding:22px}.pdf-header{display:flex;justify-content:space-between;align-items:flex-start;gap:18px;margin-bottom:18px}.pdf-brand{display:flex;align-items:center;gap:14px}.pdf-logo{width:72px;height:72px;object-fit:contain;border-radius:14px;border:1px solid #d9dfe6;background:#fff;padding:4px}.pdf-company-name{font-size:26px;font-weight:900;color:#081a40}.pdf-company-meta{font-size:14px;color:#66768f;line-height:1.8}.pdf-doc-title{font-size:30px;font-weight:900;color:#081a40;margin-bottom:8px}.pdf-doc-meta{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.pdf-meta-box{border:1px solid #d9dfe6;border-radius:16px;padding:10px 12px;background:#f8fafb;font-size:15px}.pdf-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;margin-bottom:18px}.pdf-grid .pdf-meta-box strong{display:block;color:#66768f;font-size:13px;margin-bottom:4px}.pdf-table{width:100%;border-collapse:collapse;margin-top:10px}.pdf-table th,.pdf-table td{border:1px solid #d9dfe6;padding:10px 12px;font-size:15px;text-align:center;vertical-align:middle}.pdf-table th{background:#f4f6f8;color:#081225;font-weight:900}.pdf-table td.name{text-align:right}.pdf-subline{display:block;margin-top:6px;font-size:12px;color:#66768f}.pdf-table td.name div{margin:2px 0;text-align:right}.pdf-table td.name strong{color:#66768f}.pdf-badge{display:inline-block;padding:5px 10px;border-radius:999px;background:#f6faff;border:1px solid #b9d4ff;color:#2d67ea;font-size:12px;font-weight:800;margin:2px}.pdf-totals{margin-top:18px;display:flex;justify-content:flex-end}.pdf-total-card{width:min(360px,100%);border:1px solid #d9dfe6;border-radius:18px;background:#f8fafb;padding:16px}.pdf-total-row{display:flex;justify-content:space-between;gap:12px;padding:6px 0;font-size:15px}.pdf-total-row.grand{font-size:22px;font-weight:900;color:#081a40;border-top:1px solid #d9dfe6;margin-top:6px;padding-top:12px}.pdf-note{margin-top:16px;border:1px dashed #d9dfe6;border-radius:16px;padding:12px 14px;background:#fcfcfd;font-size:14px;color:#39465c}.pdf-footer{margin-top:18px;padding-top:12px;border-top:1px solid #e5e7eb;font-size:12px;color:#66768f;text-align:center}
          .top-actions{display:flex;justify-content:flex-start;gap:10px}.modal{position:fixed;inset:0;background:rgba(8,18,37,.42);display:none;align-items:center;justify-content:center;padding:18px}.modal.show{display:flex}.modal-card{width:min(760px,95vw);max-height:85vh;overflow:auto;background:#fff;border-radius:24px;padding:22px;border:1px solid #dbe3ee}.modal-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}.modal-head h3{margin:0;font-size:28px}.reasons{display:grid;gap:10px}.reason{padding:14px 16px;border:1px solid #f2c0c3;border-radius:16px;background:#fff8f8;color:#a32126;font-size:18px}
          body.print-invoice .only-workorder, body.print-workorder .only-invoice{display:none!important}
          body.print-workorder .col-price, body.print-workorder .col-total{display:none!important}
          body.print-invoice .col-status, body.print-workorder .col-status{display:none!important}
          body.print-invoice .summary-item.mismatch, body.print-invoice .summary-item.exact, body.print-invoice .summary-item.missing, body.print-workorder .summary-item.mismatch, body.print-workorder .summary-item.exact, body.print-workorder .summary-item.missing{display:none!important}
          body.print-workorder .total-box{display:none!important}
          body.print-invoice #printInvoiceDoc{display:block!important}
          body.print-workorder #printWorkOrderDoc{display:block!important}
          body.print-invoice #invoiceSections,body.print-invoice #summaryRow,body.print-invoice .total-box,body.print-invoice .toolbar,body.print-invoice .invoice-meta-card{display:none!important}
          body.print-workorder #invoiceSections,body.print-workorder #summaryRow,body.print-workorder .total-box,body.print-workorder .toolbar,body.print-workorder .invoice-meta-card{display:none!important}
          @media print{@page{size:A4 portrait;margin:12mm}body.print-workorder{@page{size:A4 landscape;margin:10mm}}body{background:#fff}body:not(.print-invoice):not(.print-workorder) .wrap{display:none!important}.btn,.top-actions,.modal,.header-card,#pageSetup{display:none!important}.pageInvoice.card{display:block!important;border:none!important;box-shadow:none!important;padding:0!important;background:#fff!important}.wrap{padding:0;max-width:none}.screen-only{display:none!important}.print-only{display:block!important}.print-doc{display:none}.pdf-shell{border:none!important;padding:0!important}.pdf-header{margin-bottom:14px}.pdf-logo{width:64px;height:64px}.pdf-company-name{font-size:22px}.pdf-doc-title{font-size:24px}.pdf-grid{grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin-bottom:12px}.pdf-table th,.pdf-table td{font-size:12px;padding:7px 8px;white-space:normal;word-break:break-word;vertical-align:top}.pdf-table td.num,.pdf-table th.num{text-align:center;white-space:nowrap}.pdf-total-card{border:1px solid #cfd7e3}.pdf-total-row{font-size:13px}.pdf-total-row.grand{font-size:18px}.pdf-note{font-size:12px}.pdf-footer{font-size:11px}body.print-invoice #printInvoiceDoc{display:block!important}body.print-workorder #printWorkOrderDoc{display:block!important}}
        </style>
      </head>
      <body>
        <div class="wrap">
          <section class="card header-card">
            <div class="header-row header-rtl">
              <div class="brand-box">
                <img id="headerLogo" class="brand-logo hidden" alt="logo">
                <div>
                  <div class="brand-name" id="headerCompanyName">MHDESIGN</div>
                  <div class="brand-meta"><span id="headerCompanyAddr">Egypt</span> • <span id="headerCompanyPhone">01100211340</span></div>
                </div>
              </div>
              <div class="top-actions header-actions">
                <button class="btn secondary" id="btnCompany">بيانات الشركة</button>
                <button class="btn secondary" id="btnClients">إدارة العملاء</button>
                <button class="btn secondary" id="btnSaveInvoiceClient">حفظ الفاتورة للعميل</button>
                <button class="btn primary" id="btnHeaderPrintInvoice">إصدار فاتورة</button>
                <button class="btn secondary" id="btnHeaderPrintWorkOrder">أمر شغل</button>
              </div>
            </div>
          </section>

          <section class="card page active" id="pageSetup">
            <h2 class="section-title">إعدادات تسعير المطبخ الحالي</h2>
            <div class="three-cols">
              <div class="subcard">
                <h3>الوحدات السفلية</h3>
                <div class="field"><label>خامة الشاسيه</label><select id="baseCarcass"></select></div>
                <div class="field"><label>خامة الضلفة</label><select id="baseDoor"></select></div>
                <div class="field"><label>خامة الظهر</label><select id="baseBack"></select></div>
              </div>
              <div class="subcard">
                <h3>الوحدات العلوية</h3>
                <div class="field"><label>خامة الشاسيه</label><select id="wallCarcass"></select></div>
                <div class="field"><label>خامة الضلفة</label><select id="wallDoor"></select></div>
                <div class="field"><label>خامة الظهر</label><select id="wallBack"></select></div>
              </div>
              <div class="subcard">
                <h3>وحدات الدواليب</h3>
                <div class="field"><label>خامة الشاسيه</label><select id="tallCarcass"></select></div>
                <div class="field"><label>خامة الضلفة</label><select id="tallDoor"></select></div>
                <div class="field"><label>خامة الظهر</label><select id="tallBack"></select></div>
              </div>
            </div>
            <div class="footer-actions">
              <button class="btn primary" id="btnNext">التالي</button>
            </div>
          </section>

          <section class="card page" id="pageInvoice">
            <div class="toolbar">
              <div class="top-actions">
                <button class="btn secondary" id="btnBack">رجوع</button>
                <button class="btn primary" id="btnPrintInvoice">طباعة فاتورة</button>
                <button class="btn secondary" id="btnPrintWorkOrder">طباعة أمر شغل</button>
              </div>
              <h2 class="section-title" style="margin:0">تفاصيل الوحدات</h2>
            </div>
            <div class="subcard invoice-meta-card" style="margin-bottom:16px">
              <h3>بيانات العميل وبيانات الفاتورة</h3>
              <div class="three-cols invoice-meta-grid">
                <div class="field"><label>اسم العميل</label><input id="invoiceClientName" type="text" placeholder="اسم العميل"></div>
                <div class="field"><label>الفرع</label><input id="invoiceBranch" type="text" placeholder="الفرع"></div>
                <div class="field"><label>رقم استمارة التعاقد</label><input id="invoiceContractNo" type="text" placeholder="رقم استمارة التعاقد"></div>
                <div class="field"><label>تاريخ الإصدار</label><input id="invoiceDate" type="text" placeholder="19/04/2026"></div>
                <div class="field"><label>المصمم / المسؤول</label><input id="invoiceDesigner" type="text" placeholder="المصمم / المسؤول"></div>
                <div class="field"><label>ملاحظة عامة</label><input id="invoiceNote" type="text" placeholder="ملاحظة عامة"></div>
              </div>
            </div>
            <div id="invoiceSections"></div>
            <div id="printInvoiceDoc" class="print-doc"></div>
            <div id="printWorkOrderDoc" class="print-doc"></div>
            <div class="summary-card" id="summaryRow"></div>
            <div class="total-box"><span>الإجمالي الكلي</span><span id="grandTotal">0</span></div>
          </section>
<div class="modal" id="pickerModal">
          <div class="modal-card">
            <div class="modal-head">
              <button class="btn ghost" id="closePickerModal">إغلاق</button>
              <h3 id="pickerModalTitle">اختيار</h3>
            </div>
            <div id="pickerModalList" class="reasons" style="gap:8px"></div>
            <div class="top-actions" style="margin-top:16px">
              <button class="btn primary" id="savePickerModal">حفظ</button>
              <button class="btn secondary" id="cancelPickerModal">إلغاء</button>
            </div>
          </div>
        </div>

        
        <div class="modal" id="companyModal">
          <div class="modal-card">
            <div class="modal-head"><button class="btn ghost" id="closeCompanyModal">إغلاق</button><h3>بيانات الشركة</h3></div>
            <div class="three-cols invoice-meta-grid">
              <div class="field"><label>اسم الشركة</label><input id="companyNameInput" type="text"></div>
              <div class="field"><label>هاتف</label><input id="companyPhoneInput" type="text"></div>
              <div class="field"><label>العنوان</label><input id="companyAddrInput" type="text"></div>
              <div class="field" style="grid-column:1/-1">
                <label>لوجو الشركة</label>
                <div style="display:grid;grid-template-columns:1fr auto;gap:10px;align-items:center">
                  <input id="companyLogoInput" type="text" placeholder="رابط اللوجو أو اختار ملف من الجهاز">
                  <button class="btn secondary" id="pickCompanyLogoBtn" type="button">اختيار من الجهاز</button>
                </div>
                <div class="muted" style="font-size:13px;margin-top:6px">يمكنك استخدام رابط صورة من الإنترنت أو اختيار صورة من الجهاز وسيتم حفظها داخل بيانات البرنامج.</div>
              </div>
              <div class="field" style="grid-column:1/-1"><label>ملاحظات الفوتر</label><input id="companyFooterInput" type="text" placeholder="ملاحظات تظهر في أسفل الفاتورة"></div>
            </div>
            <div class="subcard" style="margin-top:16px">
              <h3>إعدادات الطباعة - فاتورة العميل</h3>
              <div class="three-cols" id="invoicePrintOptions"></div>
            </div>
            <div class="subcard" style="margin-top:16px">
              <h3>إعدادات الطباعة - أمر الشغل</h3>
              <div class="three-cols" id="workorderPrintOptions"></div>
            </div>
            <div class="top-actions" style="margin-top:16px"><button class="btn primary" id="saveCompanyModal">حفظ</button><button class="btn secondary" id="cancelCompanyModal">إلغاء</button></div>
          </div>
        </div>

        <div class="modal" id="clientsModal">
          <div class="modal-card" style="width:min(1120px,95vw)">
            <div class="modal-head"><button class="btn ghost" id="closeClientsModal">إغلاق</button><h3>إدارة العملاء</h3></div>
            <div class="top-actions" style="margin-bottom:12px">
              <input id="clientSearch" type="text" placeholder="بحث بالاسم / رقم الهاتف / العنوان" style="flex:1">
              <button class="btn secondary" id="addClientBtn">عميل جديد</button>
              <button class="btn secondary" id="exportClientsBtn">تصدير قاعدة العملاء</button>
              <button class="btn secondary" id="importClientsBtn">استيراد قاعدة العملاء</button>
              <input id="importClientsFile" type="file" accept=".json,application/json" style="display:none">
              <button class="btn primary" id="saveClientsBtn">حفظ</button>
            </div>
            <div class="invoice-head" style="grid-template-columns:70px 1.2fr 1fr 1.2fr 130px 150px 110px;margin-bottom:10px">
              <div class="cell center">#</div>
              <div class="cell center">اسم العميل</div>
              <div class="cell center">رقم الهاتف</div>
              <div class="cell center">العنوان</div>
              <div class="cell center">استخدام في الفاتورة</div>
              <div class="cell center">فواتير العميل</div>
              <div class="cell center">حذف</div>
            </div>
            <div id="clientsTable" class="reasons" style="gap:10px"></div>
            <div class="muted" style="margin-top:12px;font-size:14px;line-height:1.8">
              التصدير والاستيراد يشملان بيانات العملاء وكل الفواتير المحفوظة داخل كل عميل.
            </div>
          </div>
        </div>

        <div class="modal" id="saveInvoiceModal">
          <div class="modal-card">
            <div class="modal-head"><button class="btn ghost" id="closeSaveInvoiceModal">إغلاق</button><h3>حفظ الفاتورة للعميل</h3></div>
            <div class="field"><label>ابحث عن العميل بالاسم أو رقم الهاتف</label><input id="saveInvoiceClientSearch" type="text" placeholder="اكتب اسم العميل أو رقم الهاتف"></div>
            <input id="saveInvoiceClientId" type="hidden">
            <div id="saveInvoiceClientResults" class="reasons" style="gap:10px;margin-top:12px"></div>
            <div class="field"><label>عنوان/اسم الفاتورة</label><input id="saveInvoiceTitle" type="text" placeholder="مثال: مطبخ - عقد 123"></div>
            <div class="top-actions" style="margin-top:16px"><button class="btn primary" id="confirmSaveInvoiceBtn">حفظ</button><button class="btn secondary" id="cancelSaveInvoiceBtn">إلغاء</button></div>
          </div>
        </div>

        <div class="modal" id="clientInvoicesModal">
          <div class="modal-card">
            <div class="modal-head"><button class="btn ghost" id="closeClientInvoicesModal">إغلاق</button><h3 id="clientInvoicesTitle">فواتير العميل</h3></div>
            <div id="clientInvoicesList" class="reasons" style="gap:10px"></div>
          </div>
        </div>

<div class="modal" id="mismatchModal">
          <div class="modal-card">
            <div class="modal-head">
              <button class="btn ghost" id="closeModal">إغلاق</button>
              <h3>تفاصيل المخالفات</h3>
            </div>
            <div class="reasons" id="mismatchReasons"></div>
          </div>
        </div>

        <script>
          window.MH = {
            bootstrap: { materials: [], accessories: [], handles: [], database: {}, company: {}, clients: {clients: []} },
            results: null,
            selectedAccessories: [],
            currentPickerRow: null,
            currentPickerType: null,
            clients: {clients: []},
            company: {},
            currentClientInvoicesId: null,

            qs(id){ return document.getElementById(id); },
            money(v){ return new Intl.NumberFormat('ar-EG').format(Number(v||0)); },
            esc(v){ return String(v == null ? '' : v).replace(/[&<>"']/g, s => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[s])); },
            page(which){ this.qs('pageSetup').classList.toggle('active', which === 'setup'); this.qs('pageInvoice').classList.toggle('active', which === 'invoice'); },
            today(){ const d = new Date(); const dd = String(d.getDate()).padStart(2,'0'); const mm = String(d.getMonth()+1).padStart(2,'0'); const yy = d.getFullYear(); return `${dd}/${mm}/${yy}`; },
            defaultPrintOptions(){ return {invoice:{show_logo:true,show_company:true,show_client:true,show_code:true,show_commercial_name:true,show_dimensions:true,show_materials:true,show_assembly:true,show_qursa:true,show_thickness:true,show_drawers:true,show_shelves:true,show_visible_side:true,show_accessories:true,show_handle:true,show_notes:true,show_price:true,show_total:true,show_footer:true},workorder:{show_logo:true,show_company:true,show_client:true,show_code:true,show_commercial_name:true,show_dimensions:true,show_materials:true,show_assembly:true,show_qursa:true,show_thickness:true,show_drawers:true,show_shelves:true,show_visible_side:true,show_accessories:true,show_handle:true,show_notes:true,show_price:false,show_total:false,show_footer:true}}; },
            normalizePrintOptions(raw){ const defs=this.defaultPrintOptions(); const out={invoice:{...defs.invoice},workorder:{...defs.workorder}}; if(raw&&typeof raw==='object'){ ['invoice','workorder'].forEach(k=>{ if(raw[k]&&typeof raw[k]==='object'){ Object.keys(out[k]).forEach(key=>{ if(Object.prototype.hasOwnProperty.call(raw[k],key)) out[k][key]=!!raw[k][key]; }); }}); } return out; },
            printOptionLabels(){ return {show_logo:'إظهار اللوجو',show_company:'إظهار بيانات الشركة',show_client:'إظهار بيانات العميل',show_code:'إظهار الكود',show_commercial_name:'إظهار الاسم التجاري',show_dimensions:'إظهار المقاسات',show_materials:'إظهار الخامات',show_assembly:'إظهار طريقة التجميع',show_qursa:'إظهار نوع القرصة',show_thickness:'إظهار التخانات',show_drawers:'إظهار الأدراج',show_shelves:'إظهار الرفوف',show_visible_side:'إظهار الجنب الظاهر',show_accessories:'إظهار الإكسسوارات',show_handle:'إظهار نوع المقبض',show_notes:'إظهار الملاحظات',show_price:'إظهار السعر',show_total:'إظهار الإجمالي',show_footer:'إظهار الفوتر'}; },
            renderPrintOptions(mode){ const wrap=this.qs(mode==='invoice'?'invoicePrintOptions':'workorderPrintOptions'); if(!wrap) return; const labels=this.printOptionLabels(); const opts=((this.company||{}).print_options||this.defaultPrintOptions())[mode]||{}; wrap.innerHTML = Object.keys(labels).map(key=>`<label class="field" style="display:flex;align-items:center;gap:10px;background:#fff;border:1px solid #d9dfe6;border-radius:16px;padding:12px 14px;margin-top:0"><input type="checkbox" data-mode="${mode}" data-key="${key}" ${opts[key]?'checked':''} style="width:20px;height:20px"><span>${labels[key]}</span></label>`).join(''); },
            readPrintOptionsFromForm(){ const defs=this.defaultPrintOptions(); const out={invoice:{...defs.invoice},workorder:{...defs.workorder}}; document.querySelectorAll('#invoicePrintOptions input[type=checkbox], #workorderPrintOptions input[type=checkbox]').forEach(el=>{ const mode=el.getAttribute('data-mode'); const key=el.getAttribute('data-key'); if(out[mode]&&Object.prototype.hasOwnProperty.call(out[mode],key)) out[mode][key]=!!el.checked; }); return out; },
            activePrintOptions(mode){ return this.normalizePrintOptions((this.company||{}).print_options||{})[mode]; },
            applyCompany(){
              const c = this.company || {};
              this.qs('headerCompanyName').textContent = c.company_name || 'MHDESIGN';
              this.qs('headerCompanyPhone').textContent = c.company_phone || '01100211340';
              this.qs('headerCompanyAddr').textContent = c.company_addr || 'Egypt';
              const img = this.qs('headerLogo');
              if(c.logo_url){ img.src = c.logo_url; img.classList.remove('hidden'); } else { img.removeAttribute('src'); img.classList.add('hidden'); }
            },
            fillCompanyForm(){ const c = this.company || {}; this.qs('companyNameInput').value = c.company_name || ''; this.qs('companyPhoneInput').value = c.company_phone || ''; this.qs('companyAddrInput').value = c.company_addr || ''; this.qs('companyLogoInput').value = c.logo_url || ''; this.qs('companyFooterInput').value = c.footer_notes || ''; this.company.print_options = this.normalizePrintOptions(c.print_options || {}); this.renderPrintOptions('invoice'); this.renderPrintOptions('workorder'); },
            pickCompanyLogo(){ if(window.sketchup && window.sketchup.mh_pick_company_logo){ window.sketchup.mh_pick_company_logo('1'); } },
            receivePickedCompanyLogo(path){ this.qs('companyLogoInput').value = path || ''; this.company.logo_url = path || ''; this.applyCompany(); this.renderInvoice(); },
            openCompany(){ this.fillCompanyForm(); this.qs('companyModal').classList.add('show'); },
            closeCompany(){ this.qs('companyModal').classList.remove('show'); },
            saveCompany(){ this.company = { company_name:this.qs('companyNameInput').value.trim(), company_phone:this.qs('companyPhoneInput').value.trim(), company_addr:this.qs('companyAddrInput').value.trim(), logo_url:this.qs('companyLogoInput').value.trim(), footer_notes:this.qs('companyFooterInput').value.trim(), print_options:this.readPrintOptionsFromForm() }; this.applyCompany(); if(window.sketchup && window.sketchup.mh_save_company){ window.sketchup.mh_save_company(JSON.stringify(this.company)); } this.closeCompany(); this.renderInvoice(); },
            receiveClients(data){ this.clients = (data && Array.isArray(data.clients)) ? data : {clients: []}; this.renderClients(); this.fillSaveInvoiceClients(); },
            openClients(){ if(window.sketchup && window.sketchup.mh_clients_read){ window.sketchup.mh_clients_read('1'); } this.qs('clientsModal').classList.add('show'); },
            closeClients(){ this.qs('clientsModal').classList.remove('show'); },
            renderClients(){ const box = this.qs('clientsTable'); const q = (this.qs('clientSearch').value || '').trim(); const norm = s => String(s||'').toLowerCase(); const rows = (this.clients.clients || []).filter(c => !q || norm(`${c.name||''} ${c.phone||''} ${c.addr||''}`).includes(norm(q))).map((c,idx)=>`<div class="invoice-row" style="grid-template-columns:70px 1.2fr 1fr 1.2fr 130px 150px 110px;"><div class="cell center">${idx+1}</div><div class="cell center"><input title="اسم العميل" placeholder="اسم العميل" value="${this.esc(c.name||'')}" oninput="MH.editClient('${this.esc(c.id)}','name',this.value)"></div><div class="cell center"><input title="رقم الهاتف" placeholder="رقم الهاتف" value="${this.esc(c.phone||'')}" oninput="MH.editClient('${this.esc(c.id)}','phone',this.value)"></div><div class="cell center"><input title="العنوان" placeholder="العنوان" value="${this.esc(c.addr||'')}" oninput="MH.editClient('${this.esc(c.id)}','addr',this.value)"></div><div class="cell center"><button class="btn secondary small" onclick="MH.useClient('${this.esc(c.id)}')">استخدام</button></div><div class="cell center"><button class="btn secondary small" onclick="MH.openClientInvoices('${this.esc(c.id)}')">عرض (${Array.isArray(c.invoices)?c.invoices.length:0})</button></div><div class="cell center"><button class="btn secondary small" onclick="MH.deleteClient('${this.esc(c.id)}')">حذف</button></div></div>`).join(''); box.innerHTML = rows || '<div class="empty">لا يوجد عملاء محفوظون.</div>'; },
            addClient(){ const id = (Date.now().toString(36) + Math.random().toString(36).slice(2,7)); this.clients.clients.unshift({id:id,name:'عميل جديد',phone:'',addr:'',notes:'',invoices:[]}); this.renderClients(); this.fillSaveInvoiceClients(); },
            editClient(id,key,value){ const c = (this.clients.clients||[]).find(x => String(x.id) === String(id)); if(c) c[key] = value; },
            deleteClient(id){ if(!confirm('هل تريد حذف هذا العميل وكل الفواتير المحفوظة داخله؟')) return; this.clients.clients = (this.clients.clients||[]).filter(x => String(x.id) !== String(id)); this.renderClients(); this.fillSaveInvoiceClients(); },
            saveClients(){ if(window.sketchup && window.sketchup.mh_clients_write){ window.sketchup.mh_clients_write(JSON.stringify(this.clients)); } },
            exportClients(){ const payload = { exported_by:'MHDESIGN Pricing / Designer Board', exported_at:new Date().toISOString(), clients:Array.isArray(this.clients.clients) ? this.clients.clients : [] }; const blob = new Blob([JSON.stringify(payload, null, 2)], {type:'application/json;charset=utf-8'}); const url = URL.createObjectURL(blob); const a = document.createElement('a'); const d = new Date(); const pad = n => String(n).padStart(2,'0'); a.href = url; a.download = `mhdesign_clients_invoices_${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}_${pad(d.getHours())}-${pad(d.getMinutes())}.json`; document.body.appendChild(a); a.click(); setTimeout(()=>{ URL.revokeObjectURL(url); a.remove(); }, 500); },
            importClientsClick(){ const inp = this.qs('importClientsFile'); if(inp){ inp.value=''; inp.click(); } },
            normalizeImportedClients(data){ let arr = []; if(Array.isArray(data)) arr = data; else if(data && Array.isArray(data.clients)) arr = data.clients; else return null; return {clients: arr.map((c,idx)=>({ id: String(c.id || (Date.now().toString(36)+idx)), name: String(c.name || ''), phone: String(c.phone || ''), addr: String(c.addr || c.address || ''), notes: String(c.notes || ''), invoices: Array.isArray(c.invoices) ? c.invoices : [] }))}; },
            importClientsFile(file){ if(!file) return; const reader = new FileReader(); reader.onload = () => { try { const parsed = JSON.parse(String(reader.result || '{}')); const normalized = this.normalizeImportedClients(parsed); if(!normalized){ alert('ملف غير صحيح. لازم يكون ملف JSON صادر من قاعدة العملاء.'); return; } const count = normalized.clients.length; if(!confirm(`سيتم استبدال قاعدة العملاء الحالية بقاعدة الملف المستورد. عدد العملاء: ${count}. هل تريد المتابعة؟`)) return; this.clients = normalized; this.renderClients(); this.fillSaveInvoiceClients(); this.saveClients(); alert('تم استيراد قاعدة العملاء والفواتير بنجاح.'); } catch(e){ alert('تعذر قراءة ملف الاستيراد: ' + e.message); } }; reader.readAsText(file, 'UTF-8'); },
            useClient(id){ const c = (this.clients.clients||[]).find(x => String(x.id) === String(id)); if(!c) return; this.qs('invoiceClientName').value = c.name || ''; this.closeClients(); },
            fillSaveInvoiceClients(){ this.renderSaveInvoiceClientResults(''); },
            renderSaveInvoiceClientResults(q){ const box = this.qs('saveInvoiceClientResults'); if(!box) return; const query = String(q || '').trim().toLowerCase(); const norm = s => String(s || '').toLowerCase(); const clients = this.clients.clients || []; const rows = clients.filter(c => { const txt = norm(`${c.name || ''} ${c.phone || ''} ${c.addr || ''}`); return !query || txt.includes(query); }).map(c => `<div class="reason" style="background:#fff;border-color:#d9dfe6;color:#081225;display:flex;justify-content:space-between;align-items:center;gap:10px"><div><strong>${this.esc(c.name || 'بدون اسم')}</strong><div class="muted">${this.esc(c.phone || 'بدون رقم')}${c.addr ? ' - ' + this.esc(c.addr) : ''}</div></div><button class="btn primary small" onclick="MH.selectInvoiceClient('${this.esc(c.id)}')">اختيار</button></div>`).join(''); box.innerHTML = rows || '<div class="empty">لا يوجد عميل مطابق للبحث.</div>'; },
            selectInvoiceClient(id){ const c = (this.clients.clients || []).find(x => String(x.id) === String(id)); if(!c) return; this.qs('saveInvoiceClientId').value = c.id; this.qs('saveInvoiceClientSearch').value = `${c.name || 'بدون اسم'}${c.phone ? ' - ' + c.phone : ''}`; this.qs('saveInvoiceClientResults').innerHTML = `<div class="reason" style="background:#f2fff9;border-color:#a9e8cb;color:#129a63">تم اختيار العميل: ${this.esc(c.name || 'بدون اسم')}</div>`; },
            openSaveInvoice(){ this.fillSaveInvoiceClients(); this.qs('saveInvoiceTitle').value=''; this.qs('saveInvoiceClientId').value=''; this.qs('saveInvoiceClientSearch').value=''; this.qs('saveInvoiceModal').classList.add('show'); setTimeout(()=>{ const el=this.qs('saveInvoiceClientSearch'); if(el) el.focus(); }, 50); },
            closeSaveInvoice(){ this.qs('saveInvoiceModal').classList.remove('show'); },
            buildInvoicePayload(){ return { company: this.company || {}, customer: { name:this.qs('invoiceClientName').value.trim(), branch:this.qs('invoiceBranch').value.trim(), contract_no:this.qs('invoiceContractNo').value.trim(), date:this.qs('invoiceDate').value.trim(), designer:this.qs('invoiceDesigner').value.trim(), note:this.qs('invoiceNote').value.trim() }, settings: this.projectSettings(), selectedAccessories: this.selectedAccessories.slice(), results: this.results || {} }; },
            saveInvoiceForClient(){ const cid = this.qs('saveInvoiceClientId').value; if(!cid){ alert('اختار العميل أولاً من نتائج البحث.'); return; } const title = this.qs('saveInvoiceTitle').value.trim(); if(window.sketchup && window.sketchup.mh_client_save_invoice){ window.sketchup.mh_client_save_invoice(JSON.stringify({client_id:cid, title:title, payload:this.buildInvoicePayload()})); } },
            afterSaveInvoice(_inv){ this.closeSaveInvoice(); },
            openClientInvoices(id){ this.currentClientInvoicesId = id; const c = (this.clients.clients||[]).find(x => String(x.id) === String(id)); if(!c) return; this.qs('clientInvoicesTitle').textContent = `فواتير العميل: ${c.name || ''}`; const list = Array.isArray(c.invoices) ? c.invoices : []; this.qs('clientInvoicesList').innerHTML = list.length ? list.map((inv,idx) => `<div class="invoice-row" style="grid-template-columns:70px 1fr 140px 120px;"><div class="cell center">${idx+1}</div><div class="cell center">${this.esc(inv.title||'')}</div><div class="cell center">${this.esc(inv.date||'')}</div><div class="cell center"><button class="btn secondary small" onclick="MH.loadClientInvoice('${this.esc(id)}','${this.esc(inv.id)}')">تحميل</button></div></div>`).join('') : '<div class="empty">لا توجد فواتير محفوظة.</div>'; this.qs('clientInvoicesModal').classList.add('show'); },
            closeClientInvoices(){ this.qs('clientInvoicesModal').classList.remove('show'); },
            loadClientInvoice(clientId, invoiceId){ if(window.sketchup && window.sketchup.mh_client_get_invoice){ window.sketchup.mh_client_get_invoice(JSON.stringify({client_id: clientId, invoice_id: invoiceId})); } },
            loadSavedInvoice(payload){ if(!payload || typeof payload !== 'object') return; this.company = payload.company || this.company || {}; this.company.print_options = this.normalizePrintOptions(this.company.print_options || {}); this.applyCompany(); const customer = payload.customer || {}; this.qs('invoiceClientName').value = customer.name || ''; this.qs('invoiceBranch').value = customer.branch || ''; this.qs('invoiceContractNo').value = customer.contract_no || ''; this.qs('invoiceDate').value = customer.date || this.today(); this.qs('invoiceDesigner').value = customer.designer || ''; this.qs('invoiceNote').value = customer.note || ''; this.selectedAccessories = Array.isArray(payload.selectedAccessories) ? payload.selectedAccessories : []; this.renderAccessoryTags(); if(payload.results){ this.results = payload.results; this.page('invoice'); this.renderInvoice(); } },
            fillSelect(el, items){ el.innerHTML = ''; items.forEach(it => { const o = document.createElement('option'); o.value = it.name || ''; o.textContent = it.name || ''; el.appendChild(o); }); if(!el.innerHTML){ const o = document.createElement('option'); o.value=''; o.textContent='—'; el.appendChild(o);} },
            receiveBootstrap(payload){
              this.bootstrap = payload || {};
              this.company = this.bootstrap.company || {};
              this.company.print_options = this.normalizePrintOptions(this.company.print_options || {});
              this.clients = (this.bootstrap.clients && Array.isArray(this.bootstrap.clients.clients)) ? this.bootstrap.clients : {clients: []};
              this.applyCompany();
              this.fillSaveInvoiceClients();
              if(!this.qs('invoiceDate').value) this.qs('invoiceDate').value = this.today();
              const mats = this.bootstrap.materials || [];
              this.fillSelect(this.qs('baseCarcass'), mats.filter(m => m.group === 'carcass'));
              this.fillSelect(this.qs('baseDoor'), mats.filter(m => m.group === 'door'));
              this.fillSelect(this.qs('baseBack'), mats.filter(m => m.group === 'back'));
              this.fillSelect(this.qs('wallCarcass'), mats.filter(m => m.group === 'carcass'));
              this.fillSelect(this.qs('wallDoor'), mats.filter(m => m.group === 'door'));
              this.fillSelect(this.qs('wallBack'), mats.filter(m => m.group === 'back'));
              this.fillSelect(this.qs('tallCarcass'), mats.filter(m => m.group === 'carcass'));
              this.fillSelect(this.qs('tallDoor'), mats.filter(m => m.group === 'door'));
              this.fillSelect(this.qs('tallBack'), mats.filter(m => m.group === 'back'));
              const handles = this.bootstrap.handles || [];
              const picker = this.qs('accessoryPicker');
              if (picker) {
                picker.innerHTML='';
                (this.bootstrap.accessories || []).forEach(a => { const o = document.createElement('option'); o.value = a.name || ''; o.textContent = a.name || ''; picker.appendChild(o); });
              }
              this.renderClients();
            },
            projectSettings(){ return { base:{carcass_material:this.qs('baseCarcass').value,door_material:this.qs('baseDoor').value,back_material:this.qs('baseBack').value}, wall:{carcass_material:this.qs('wallCarcass').value,door_material:this.qs('wallDoor').value,back_material:this.qs('wallBack').value}, tall:{carcass_material:this.qs('tallCarcass').value,door_material:this.qs('tallDoor').value,back_material:this.qs('tallBack').value}, accessories:[], unit_accessory_items:[] }; },
            addAccessory(){ return; },
            removeAccessory(name){ return; },
            renderAccessoryTags(){ const box = this.qs('accessoryTags'); if(box) box.innerHTML = ''; },
            parsePricedItems(value){
              let rows = [];
              const pushText = (txt) => {
                String(txt || '').split(/\s*[\/،,+]\s*/).map(v => v.trim()).filter(Boolean).forEach(part => {
                  const m = part.match(/^(.*?)\s*[×xX*]\s*(\d+(?:\.\d+)?)\s*$/);
                  const name = (m ? m[1] : part).trim();
                  const qty = m ? Number(m[2] || 1) : 1;
                  if(name && qty > 0) rows.push({name, qty});
                });
              };
              if(Array.isArray(value)){
                value.forEach(r => {
                  if(r && typeof r === 'object'){
                    const name = String(r.name || r.label || '').trim();
                    const qty = Math.max(0, Number(r.qty || r.quantity || 1));
                    if(name && qty > 0) rows.push({name, qty});
                  } else {
                    pushText(r);
                  }
                });
              } else if(value && typeof value === 'object'){
                Object.keys(value).forEach(name => {
                  const qty = Math.max(0, Number(value[name] || 0));
                  if(String(name).trim() && qty > 0) rows.push({name: String(name).trim(), qty});
                });
              } else {
                pushText(value);
              }
              const grouped = {};
              rows.forEach(r => {
                const key = String(r.name || '').trim();
                if(!key) return;
                if(!grouped[key]) grouped[key] = {name: key, qty: 0};
                grouped[key].qty += Number(r.qty || 0);
              });
              return Object.values(grouped).filter(r => r.name && Number(r.qty || 0) > 0);
            },
            pricedItemsLabel(rows){ const arr = this.parsePricedItems(rows); return arr.map(r => `${r.name} × ${Number(r.qty || 0)}`).join(' / '); },
            goNext(){ if(window.sketchup && window.sketchup.mh_scan_selected){ window.sketchup.mh_scan_selected(JSON.stringify(this.projectSettings())); } },
            receiveResults(payload){ this.results = payload || {}; this.page('invoice'); this.renderInvoice(); },
            getRowOverrides(item){ if(!item.user_overrides || typeof item.user_overrides !== 'object') item.user_overrides = {}; return item.user_overrides; },
            getRowValue(item, type){
              const read = item.read || {}; const match = item.match || {}; const pricing = match.pricing_materials || {}; const ov = this.getRowOverrides(item);
              if(type === 'carcass') return ov.carcass_material || pricing.carcass || read.carcass_material || '';
              if(type === 'door') return ov.door_material || pricing.door || read.door_material || '';
              if(type === 'back') return ov.back_material || pricing.back || read.back_material || '';
              if(type === 'accessory') return this.pricedItemsLabel(ov.accessory_items) || ov.accessory_name || (Array.isArray(item.user_accessory_items) ? this.pricedItemsLabel(item.user_accessory_items) : '') || (Array.isArray(item.user_accessories) ? item.user_accessories.join(' / ') : '') || match.db_accessory || match.effective_accessory || read.accessory_name || '';
              if(type === 'handle') return this.pricedItemsLabel(ov.handle_items) || ov.handle_name || (Array.isArray(item.user_handle_items) ? this.pricedItemsLabel(item.user_handle_items) : '') || match.db_handle || match.effective_handle || this.pricedItemsLabel(read.handle_items) || read.handle_name || '';
              return '';
            },
            getChoices(type){
              if(type === 'carcass') return (this.bootstrap.materials || []).filter(m => (m.group||'') === 'carcass').map(m => m.name || '').filter(Boolean);
              if(type === 'door') return (this.bootstrap.materials || []).filter(m => (m.group||'') === 'door').map(m => m.name || '').filter(Boolean);
              if(type === 'back') return (this.bootstrap.materials || []).filter(m => (m.group||'') === 'back').map(m => m.name || '').filter(Boolean);
              if(type === 'accessory') return (this.bootstrap.accessories || []).map(a => a.name || '').filter(Boolean);
              if(type === 'handle') return (this.bootstrap.handles || []).map(h => h.name || '').filter(Boolean);
              return [];
            },
            pickerTitle(type){ return ({carcass:'اختيار خامة الشاسيه', door:'اختيار خامة الضلفة', back:'اختيار خامة الظهر', accessory:'اختيار الإكسسوار', handle:'اختيار نوع المقبض'})[type] || 'اختيار'; },
            openPicker(entityId, type){
              if(!this.results || !Array.isArray(this.results.items)) return;
              const item = this.results.items.find(r => String(r.entity_id) === String(entityId));
              if(!item) return;
              this.currentPickerRow = entityId;
              this.currentPickerType = type;
              const current = this.getRowValue(item, type);
              const all = this.getChoices(type);
              const list = this.qs('pickerModalList');
              const match = item.match || {};
              const ov = this.getRowOverrides(item);
              this.qs('pickerModalTitle').textContent = this.pickerTitle(type);

              if(type === 'accessory' || type === 'handle'){
                let rows = [];
                if(type === 'accessory'){
                  rows = this.parsePricedItems(ov.accessory_items);
                  if(!rows.length) rows = this.parsePricedItems(item.user_accessory_items);
                  if(!rows.length) rows = this.parsePricedItems(ov.accessory_name);
                  if(!rows.length) rows = this.parsePricedItems(match.db_accessory);
                  if(!rows.length) rows = this.parsePricedItems(match.effective_accessory);
                  if(!rows.length) rows = this.parsePricedItems(current);
                } else {
                  rows = this.parsePricedItems(ov.handle_items);
                  if(!rows.length) rows = this.parsePricedItems(item.user_handle_items);
                  if(!rows.length) rows = this.parsePricedItems(ov.handle_name);
                  if(!rows.length) rows = this.parsePricedItems((item.read || {}).handle_items);
                  if(!rows.length) rows = this.parsePricedItems(match.db_handle);
                  if(!rows.length) rows = this.parsePricedItems(match.effective_handle);
                  if(!rows.length) rows = this.parsePricedItems(current);
                }
                const qtyMap = {};
                rows.forEach(r => { qtyMap[String(r.name || '').trim()] = Number(r.qty || 0); });
                list.innerHTML = all.length ? all.map(val => {
                  const qty = Number(qtyMap[val] || 0);
                  return `<label class="reason" style="background:#fff;color:#081225;border-color:#d9dfe6;display:grid;grid-template-columns:1fr 110px;align-items:center;gap:10px"><span><b>${this.esc(val)}</b></span><input type="number" min="0" step="1" data-picker-name="${this.esc(val)}" value="${qty}" placeholder="العدد" style="height:38px;font-size:16px;text-align:center"></label>`;
                }).join('') : '<div class="empty">لا توجد بيانات في قاعدة البيانات.</div>';
              } else {
                const currentList = [current].filter(Boolean);
                list.innerHTML = all.length ? all.map(val => `<label class="reason" style="background:#fff;color:#081225;border-color:#d9dfe6"><input type="radio" name="pickerChoice" value="${this.esc(val)}" ${currentList.includes(val) ? 'checked' : ''} style="margin-left:10px"> ${this.esc(val)}</label>`).join('') : '<div class="empty">لا توجد بيانات في قاعدة البيانات.</div>';
              }
              this.qs('pickerModal').classList.add('show');
            },
            closePickerModal(){ this.qs('pickerModal').classList.remove('show'); this.currentPickerRow = null; this.currentPickerType = null; },
            savePickerModal(){
              if(this.currentPickerRow == null || !this.currentPickerType || !this.results || !Array.isArray(this.results.items)) return;
              const item = this.results.items.find(r => String(r.entity_id) === String(this.currentPickerRow));
              if(!item) return;
              const ov = this.getRowOverrides(item);
              if(this.currentPickerType === 'accessory' || this.currentPickerType === 'handle'){
                const rows = Array.from(document.querySelectorAll('#pickerModalList input[type="number"]')).map(i => ({name: i.dataset.pickerName || '', qty: Math.max(0, Number(i.value || 0))})).filter(r => r.name && r.qty > 0);
                if(this.currentPickerType === 'accessory'){
                  ov.accessory_items = rows;
                  ov.accessory_name = rows.map(r => r.name).join(' / ');
                  item.user_accessory_items = rows;
                  item.user_accessories = rows.map(r => r.name);
                } else {
                  ov.handle_items = rows;
                  ov.handle_name = rows.map(r => r.name).join(' / ');
                  item.user_handle_items = rows;
                }
              } else {
                const selected = document.querySelector('#pickerModalList input:checked');
                const value = selected ? selected.value : '';
                if(this.currentPickerType === 'carcass') ov.carcass_material = value;
                if(this.currentPickerType === 'door') ov.door_material = value;
                if(this.currentPickerType === 'back') ov.back_material = value;
              }
              const settings = this.projectSettings();
              settings.unit_accessories = Array.isArray(item.user_accessories) ? item.user_accessories : [];
              settings.unit_accessory_items = Array.isArray(item.user_accessory_items) ? item.user_accessory_items : [];
              settings.unit_handle_items = Array.isArray(item.user_handle_items) ? item.user_handle_items : [];
              settings.unit_overrides = ov;
              if(window.sketchup && window.sketchup.mh_rescore_row){
                window.sketchup.mh_rescore_row(JSON.stringify({reading: item.read, settings: settings, unit_accessories: settings.unit_accessories, unit_accessory_items: settings.unit_accessory_items, unit_handle_items: settings.unit_handle_items, unit_overrides: ov}));
              }
              this.closePickerModal();
            },
            receiveRowUpdate(row){
              if(!row || !this.results || !Array.isArray(this.results.items)) return;
              const idx = this.results.items.findIndex(r => String(r.entity_id) === String(row.entity_id));
              if(idx < 0) return;
              const prev = this.results.items[idx];
              row.user_accessories = Array.isArray(prev.user_accessories) ? prev.user_accessories : [];
              row.user_accessory_items = Array.isArray(prev.user_accessory_items) ? prev.user_accessory_items : [];
              row.user_handle_items = Array.isArray(prev.user_handle_items) ? prev.user_handle_items : [];
              row.user_overrides = prev.user_overrides || {};
              row.read = row.read || {};
              if(row.category){ row.read.category = row.category; }
              if(row.category_label){ row.read.category_label = row.category_label; }
              this.results.items[idx] = row;
              this.results.grouped = {
                'base': this.results.items.filter(i => ((i.category || (i.read && i.read.category) || '') === 'base')),
                'wall': this.results.items.filter(i => ((i.category || (i.read && i.read.category) || '') === 'wall')),
                'tall': this.results.items.filter(i => ((i.category || (i.read && i.read.category) || '') === 'tall'))
              };
              this.results.total_price = this.results.items.reduce((s,i)=>s+Number(i.total_price||0),0);
              this.results.mismatch_count = this.results.items.filter(i => i.status === 'mismatch').length;
              this.results.exact_count = this.results.items.filter(i => i.status === 'exact').length;
              this.renderInvoice();
            },
            printChip(value, emptyLabel='—'){
              const txt = ((value || '').toString().trim()) || emptyLabel;
              const cls = txt === emptyLabel ? 'print-chip empty' : 'print-chip';
              return `<span class="${cls}">${this.esc(txt)}</span>`;
            },
            fieldButton(entityId, type, value){ const txt = (value || '—').trim() || '—'; return `<div class="screen-only"><button class="btn small secondary" onclick="MH.openPicker(${entityId}, '${type}')">${this.esc(txt)}</button></div><div class="print-only">${this.printChip(txt)}</div>`; },
            fieldSelect(entityId, type, value){
              const current = (value || '').trim();
              const choices = this.getChoices(type) || [];
              const options = ['<option value="">—</option>'].concat(choices.map(v => `<option value="${this.esc(v)}" ${current === v ? 'selected' : ''}>${this.esc(v)}</option>`)).join('');
              return `<div class="screen-only"><select class="inline-select" onchange="MH.changeInlineField(${entityId}, '${type}', this.value)">${options}</select></div><div class="print-only">${this.printChip(current || '—')}</div>`;
            },
            changeInlineField(entityId, type, value){
              if(!this.results || !Array.isArray(this.results.items)) return;
              const item = this.results.items.find(r => String(r.entity_id) === String(entityId));
              if(!item) return;
              const ov = this.getRowOverrides(item);
              if(type === 'carcass') ov.carcass_material = value;
              if(type === 'door') ov.door_material = value;
              if(type === 'back') ov.back_material = value;
              const settings = this.projectSettings();
              settings.unit_accessories = Array.isArray(item.user_accessories) ? item.user_accessories : [];
              settings.unit_accessory_items = Array.isArray(item.user_accessory_items) ? item.user_accessory_items : [];
              settings.unit_handle_items = Array.isArray(item.user_handle_items) ? item.user_handle_items : [];
              settings.unit_overrides = ov;
              if(window.sketchup && window.sketchup.mh_rescore_row){
                window.sketchup.mh_rescore_row(JSON.stringify({reading: item.read, settings: settings, unit_accessories: settings.unit_accessories, unit_accessory_items: settings.unit_accessory_items, unit_handle_items: settings.unit_handle_items, unit_overrides: ov}));
              }
            },
            focusUnit(entityId){
              if(!this.results || !Array.isArray(this.results.items)) return;
              const item = this.results.items.find(r => String(r.entity_id) === String(entityId));
              if(!item) return;
              const settings = this.projectSettings();
              settings.unit_accessories = Array.isArray(item.user_accessories) ? item.user_accessories : [];
              settings.unit_accessory_items = Array.isArray(item.user_accessory_items) ? item.user_accessory_items : [];
              settings.unit_handle_items = Array.isArray(item.user_handle_items) ? item.user_handle_items : [];
              settings.unit_overrides = this.getRowOverrides(item);
              if(window.sketchup && window.sketchup.mh_focus_unit){
                window.sketchup.mh_focus_unit(JSON.stringify({
                  entity_id: item.entity_id,
                  persistent_id: item.persistent_id || ((item.read||{}).persistent_id || null),
                  reading: item.read || {},
                  settings: settings,
                  unit_accessories: settings.unit_accessories,
                  unit_accessory_items: settings.unit_accessory_items,
                  unit_handle_items: settings.unit_handle_items,
                  unit_overrides: settings.unit_overrides
                }));
              }
            },
            sectionRows(items){ if(!items || !items.length){ return `<div class="empty">لا توجد وحدات في هذا القسم.</div>`; }
              const head = `<div class="invoice-head"><div class="cell center">كود</div><div class="cell center">اسم الوحدة</div><div class="cell center">خامة الشاسيه</div><div class="cell center">خامة الضلفة</div><div class="cell center">خامة الظهر</div><div class="cell center">الإكسسوار</div><div class="cell center">نوع المقبض</div><div class="cell center col-price">السعر</div><div class="cell center col-status">الحالة</div></div>`;
              const rows = items.map(item => { const reasons = ((item.match || {}).mismatch_reasons) || []; const status = item.status === 'mismatch' ? `<button class="status-btn mismatch" onclick='MH.openMismatch(${JSON.stringify(reasons)})'>مخالف</button>` : `<span class="status-btn exact">مطابق</span>`; const unitName = this.esc(item.commercial_name || (item.read||{}).library_name || '—'); return `<div class="invoice-row"><div class="cell center">${this.esc(item.code || '—')}</div><div class="cell center"><button class="btn small secondary" onclick="MH.focusUnit(${item.entity_id})">${unitName}</button></div><div class="cell center">${this.fieldSelect(item.entity_id, 'carcass', this.getRowValue(item, 'carcass'))}</div><div class="cell center">${this.fieldSelect(item.entity_id, 'door', this.getRowValue(item, 'door'))}</div><div class="cell center">${this.fieldSelect(item.entity_id, 'back', this.getRowValue(item, 'back'))}</div><div class="cell center">${this.fieldButton(item.entity_id, 'accessory', this.getRowValue(item, 'accessory') || 'بدون')}</div><div class="cell center">${this.fieldButton(item.entity_id, 'handle', this.getRowValue(item, 'handle') || 'بدون')}</div><div class="cell center col-price">${item.status === 'exact' && item.total_price != null ? this.money(item.total_price) : ''}</div><div class="cell center col-status">${status}</div></div>`; }).join('');
              return `<div class="invoice-box">${head}${rows}</div>`;
            },
            invoiceMeta(){ return {client_name:this.qs('invoiceClientName').value.trim(), branch:this.qs('invoiceBranch').value.trim(), contract_no:this.qs('invoiceContractNo').value.trim(), date:this.qs('invoiceDate').value.trim() || this.today(), designer:this.qs('invoiceDesigner').value.trim(), note:this.qs('invoiceNote').value.trim()}; },
            compactAccessories(item){ const txt = (this.getRowValue(item, 'accessory') || '').trim(); if(!txt || txt === 'بدون') return '<span class="pdf-subline">بدون إكسسوارات</span>'; const parts = txt.split(/\s*[\/،,+]\s*/).map(x=>x.trim()).filter(Boolean); return `<span class="pdf-subline">${parts.map(p => `<span class="pdf-badge">${this.esc(p)}</span>`).join(' ')}</span>`; },
            printColumnDefs(mode){
              const o = this.activePrintOptions(mode);
              const cols = [
                {key:'code', title:'كود', enabled: !!o.show_code, value:(item)=>this.esc(item.code || '—')},
                {key:'commercial_name', title:'اسم الوحدة', enabled: true, value:(item)=>this.esc(item.commercial_name || (item.read||{}).library_name || '—')},
                {key:'dimensions', title:'المقاس', enabled: !!o.show_dimensions, value:(item)=>{ const r=item.read||{}; return this.esc(`${r.width_cm||'—'} × ${r.depth_cm||'—'} × ${r.height_cm||'—'} سم`); }},
                {key:'carcass', title:'خامة الشاسيه', enabled: !!o.show_materials, value:(item)=>this.esc(this.getRowValue(item,'carcass') || '—')},
                {key:'door', title:'خامة الضلفة', enabled: !!o.show_materials, value:(item)=>this.esc(this.getRowValue(item,'door') || '—')},
                {key:'back', title:'خامة الظهر', enabled: !!o.show_materials, value:(item)=>this.esc(this.getRowValue(item,'back') || '—')},
                {key:'assembly', title:'طريقة التجميع', enabled: !!o.show_assembly, value:(item)=>this.esc((item.read||{}).assembly_method || '—')},
                {key:'qursa', title:'نوع القرصة', enabled: !!o.show_qursa, value:(item)=>this.esc((item.read||{}).qursa_type || '—')},
                {key:'counter_thickness', title:'تخانة الكونتر', enabled: !!o.show_thickness, value:(item)=>this.esc((item.read||{}).counter_thickness || '—')},
                {key:'back_thickness', title:'تخانة الظهر', enabled: !!o.show_thickness, value:(item)=>this.esc((item.read||{}).back_thickness || '—')},
                {key:'drawers', title:'الأدراج', enabled: !!o.show_drawers, value:(item)=>this.esc(String((item.read||{}).drawers_count ?? '—'))},
                {key:'shelves', title:'عدد الرفوف', enabled: !!o.show_shelves, value:(item)=>this.esc(String((item.read||{}).shelves_count ?? '—'))},
                {key:'visible_side', title:'الجنب الظاهر', enabled: !!o.show_visible_side, value:(item)=>this.esc((item.read||{}).visible_side || '—')},
                {key:'handle', title:'نوع المقبض', enabled: !!o.show_handle, value:(item)=>this.esc(this.getRowValue(item,'handle') || '—')},
                {key:'accessories', title:'الإكسسوارات', enabled: !!o.show_accessories, value:(item)=>this.esc(this.getRowValue(item,'accessory') || 'بدون')},
                {key:'notes', title:'ملاحظات', enabled: !!o.show_notes, value:(item)=>this.esc((item.match||{}).notes || '—')},
                {key:'price', title:'السعر', enabled: !!o.show_price, value:(item)=> item.status === 'exact' && item.match && item.match.fixed_price != null ? this.money(item.match.fixed_price) : '', cls:'num'},
                {key:'total', title:'الإجمالي', enabled: !!o.show_total, value:(item)=> item.status === 'exact' && item.total_price != null ? this.money(item.total_price) : '', cls:'num'}
              ];
              return cols.filter(col => col.enabled);
            },
            printTableHtml(mode){
              const cols = this.printColumnDefs(mode);
              const items = (this.results && Array.isArray(this.results.items)) ? this.results.items : [];
              const head = `<tr><th style="width:60px">#</th>${cols.map(col => `<th class="${col.cls||''}">${col.title}</th>`).join('')}</tr>`;
              const body = items.map((item,idx)=>`<tr><td>${idx+1}</td>${cols.map(col => { const val = col.value(item); return `<td class="${col.cls||''}">${val == null ? '' : val}</td>`; }).join('')}</tr>`).join('') || `<tr><td colspan="${cols.length + 1}">لا توجد وحدات للطباعة.</td></tr>`;
              return `<table class="pdf-table"><thead>${head}</thead><tbody>${body}</tbody></table>`;
            },
            buildPrintInvoiceDoc(){ const meta = this.invoiceMeta(); const company = this.company || {}; const opts=this.activePrintOptions('invoice'); const items = (this.results && Array.isArray(this.results.items)) ? this.results.items : []; const total = this.money((this.results && this.results.total_price) || 0); return `<div class="pdf-shell"><div class="pdf-header">${(opts.show_company||opts.show_logo)?`<div class="pdf-brand">${opts.show_logo && company.logo_url ? `<img src="${this.esc(company.logo_url)}" class="pdf-logo" alt="logo">` : ''}${opts.show_company?`<div><div class="pdf-company-name">${this.esc(company.company_name || 'MHDESIGN')}</div><div class="pdf-company-meta">${this.esc(company.company_addr || 'Egypt')}<br>${this.esc(company.company_phone || '')}</div></div>`:''}</div>`:''}<div><div class="pdf-doc-title">فاتورة</div><div class="pdf-doc-meta"><div class="pdf-meta-box"><strong>التاريخ</strong>${this.esc(meta.date || this.today())}</div><div class="pdf-meta-box"><strong>رقم التعاقد</strong>${this.esc(meta.contract_no || '—')}</div></div></div></div>${opts.show_client?`<div class="pdf-grid"><div class="pdf-meta-box"><strong>اسم العميل</strong>${this.esc(meta.client_name || '—')}</div><div class="pdf-meta-box"><strong>الفرع</strong>${this.esc(meta.branch || '—')}</div><div class="pdf-meta-box"><strong>المصمم / المسؤول</strong>${this.esc(meta.designer || '—')}</div></div>`:''}${this.printTableHtml('invoice')}<div class="pdf-totals"><div class="pdf-total-card"><div class="pdf-total-row"><span>عدد الوحدات</span><strong>${items.length}</strong></div><div class="pdf-total-row"><span>إجمالي عدد الإكسسوارات</span><strong>${this.totalAccessoriesCount()}</strong></div>${opts.show_total?`<div class="pdf-total-row grand"><span>الإجمالي النهائي</span><strong>${total}</strong></div>`:''}</div></div>${meta.note ? `<div class="pdf-note"><strong>ملاحظات:</strong> ${this.esc(meta.note)}</div>` : ''}${opts.show_footer && company.footer_notes ? `<div class="pdf-footer">${this.esc(company.footer_notes)}</div>` : ''}</div>`; },
            totalAccessoriesCount(){
              const items = (this.results && Array.isArray(this.results.items)) ? this.results.items : [];
              return items.reduce((sum, item) => {
                const txt = this.getRowValue(item, 'accessory') || '';
                if(!txt || txt === 'بدون') return sum;
                return sum + this.parsePricedItems(txt).reduce((s, row) => s + Number(row.qty || 0), 0);
              }, 0);
            },
            buildPrintWorkOrderDoc(){ const meta = this.invoiceMeta(); const company = this.company || {}; const opts=this.activePrintOptions('workorder'); const items = (this.results && Array.isArray(this.results.items)) ? this.results.items : []; const total = this.money((this.results && this.results.total_price) || 0); return `<div class="pdf-shell"><div class="pdf-header">${(opts.show_company||opts.show_logo)?`<div class="pdf-brand">${opts.show_logo && company.logo_url ? `<img src="${this.esc(company.logo_url)}" class="pdf-logo" alt="logo">` : ''}${opts.show_company?`<div><div class="pdf-company-name">${this.esc(company.company_name || 'MHDESIGN')}</div><div class="pdf-company-meta">${this.esc(company.company_addr || 'Egypt')}<br>${this.esc(company.company_phone || '')}</div></div>`:''}</div>`:''}<div><div class="pdf-doc-title">أمر شغل</div><div class="pdf-doc-meta"><div class="pdf-meta-box"><strong>التاريخ</strong>${this.esc(meta.date || this.today())}</div><div class="pdf-meta-box"><strong>العميل</strong>${this.esc(meta.client_name || '—')}</div></div></div></div>${opts.show_client?`<div class="pdf-grid"><div class="pdf-meta-box"><strong>اسم العميل</strong>${this.esc(meta.client_name || '—')}</div><div class="pdf-meta-box"><strong>الفرع</strong>${this.esc(meta.branch || '—')}</div><div class="pdf-meta-box"><strong>رقم التعاقد</strong>${this.esc(meta.contract_no || '—')}</div></div>`:''}${this.printTableHtml('workorder')}<div class="pdf-totals"><div class="pdf-total-card"><div class="pdf-total-row"><span>عدد الوحدات</span><strong>${items.length}</strong></div><div class="pdf-total-row"><span>إجمالي عدد الإكسسوارات</span><strong>${this.totalAccessoriesCount()}</strong></div>${opts.show_total?`<div class="pdf-total-row grand"><span>الإجمالي النهائي</span><strong>${total}</strong></div>`:''}</div></div>${meta.note ? `<div class="pdf-note"><strong>ملاحظات:</strong> ${this.esc(meta.note)}</div>` : ''}${opts.show_footer && company.footer_notes ? `<div class="pdf-footer">${this.esc(company.footer_notes)}</div>` : ''}</div>`; },
            renderInvoice(){ const grouped = (this.results && this.results.grouped) || {'base':[],'wall':[],'tall':[]}; const wrap = this.qs('invoiceSections'); wrap.innerHTML = `
              <div class="section-band">الوحدات السفلية</div>${this.sectionRows(grouped.base)}
              <div class="section-band">الوحدات العلوية</div>${this.sectionRows(grouped.wall)}
              <div class="section-band">الدواليب</div>${this.sectionRows(grouped.tall)}
            `;
              const accessoriesTotal = this.totalAccessoriesCount();
              this.qs('summaryRow').innerHTML = `
                <div class="summary-item units"><h4>عدد الوحدات</h4><strong>${this.results.source_count || 0}</strong></div>
                <div class="summary-item exact"><h4>مطابق</h4><strong>${this.results.exact_count || 0}</strong></div>
                <div class="summary-item mismatch"><h4>مخالف</h4><strong>${this.results.mismatch_count || 0}</strong></div>
                <div class="summary-item selected"><h4>إجمالي عدد الإكسسوارات</h4><strong>${accessoriesTotal}</strong></div>
              `;
              this.qs('grandTotal').textContent = this.money(this.results.total_price || 0);
              this.qs('printInvoiceDoc').innerHTML = this.buildPrintInvoiceDoc();
              this.qs('printWorkOrderDoc').innerHTML = this.buildPrintWorkOrderDoc();
            },
            openMismatch(reasons){ const box = this.qs('mismatchReasons'); const list = Array.isArray(reasons) ? reasons : []; box.innerHTML = (list.length ? list : ['لا توجد تفاصيل إضافية.']).map(r => `<div class="reason">${this.esc(r)}</div>`).join(''); this.qs('mismatchModal').classList.add('show'); },
            closeMismatch(){ this.qs('mismatchModal').classList.remove('show'); },
            printWithMode(mode){ document.body.classList.remove('print-invoice','print-workorder'); document.body.classList.add(mode === 'workorder' ? 'print-workorder' : 'print-invoice'); setTimeout(()=>{ window.print(); setTimeout(()=>document.body.classList.remove('print-invoice','print-workorder'), 300); }, 50); },
            printInvoice(){ this.printWithMode('invoice'); },
            printWorkOrder(){ this.printWithMode('workorder'); },
            ready(){ const btnAddAccessory = this.qs('btnAddAccessory'); if(btnAddAccessory) btnAddAccessory.addEventListener('click', ()=>this.addAccessory()); this.qs('btnNext').addEventListener('click', ()=>this.goNext()); this.qs('btnBack').addEventListener('click', ()=>this.page('setup')); this.qs('btnPrintInvoice').addEventListener('click', ()=>this.printInvoice()); this.qs('btnPrintWorkOrder').addEventListener('click', ()=>this.printWorkOrder()); this.qs('btnHeaderPrintInvoice').addEventListener('click', ()=>this.printInvoice()); this.qs('btnHeaderPrintWorkOrder').addEventListener('click', ()=>this.printWorkOrder()); this.qs('btnCompany').addEventListener('click', ()=>this.openCompany()); this.qs('btnClients').addEventListener('click', ()=>this.openClients()); this.qs('btnSaveInvoiceClient').addEventListener('click', ()=>this.openSaveInvoice()); this.qs('closeModal').addEventListener('click', ()=>this.closeMismatch()); this.qs('closePickerModal').addEventListener('click', ()=>this.closePickerModal()); this.qs('cancelPickerModal').addEventListener('click', ()=>this.closePickerModal()); this.qs('savePickerModal').addEventListener('click', ()=>this.savePickerModal()); this.qs('closeCompanyModal').addEventListener('click', ()=>this.closeCompany()); this.qs('cancelCompanyModal').addEventListener('click', ()=>this.closeCompany()); this.qs('saveCompanyModal').addEventListener('click', ()=>this.saveCompany()); this.qs('pickCompanyLogoBtn').addEventListener('click', ()=>this.pickCompanyLogo()); this.qs('closeClientsModal').addEventListener('click', ()=>this.closeClients()); this.qs('addClientBtn').addEventListener('click', ()=>this.addClient()); this.qs('exportClientsBtn').addEventListener('click', ()=>this.exportClients()); this.qs('importClientsBtn').addEventListener('click', ()=>this.importClientsClick()); this.qs('importClientsFile').addEventListener('change', e=>this.importClientsFile(e.target.files && e.target.files[0])); this.qs('saveClientsBtn').addEventListener('click', ()=>this.saveClients()); this.qs('clientSearch').addEventListener('input', ()=>this.renderClients()); this.qs('saveInvoiceClientSearch').addEventListener('input', e=>this.renderSaveInvoiceClientResults(e.target.value)); this.qs('closeSaveInvoiceModal').addEventListener('click', ()=>this.closeSaveInvoice()); this.qs('cancelSaveInvoiceBtn').addEventListener('click', ()=>this.closeSaveInvoice()); this.qs('confirmSaveInvoiceBtn').addEventListener('click', ()=>this.saveInvoiceForClient()); this.qs('closeClientInvoicesModal').addEventListener('click', ()=>this.closeClientInvoices()); if(window.sketchup && window.sketchup.mh_ready){ window.sketchup.mh_ready('1'); } }
          };
          document.addEventListener('DOMContentLoaded', () => MH.ready());
        </script>
      </body>
      </html>
      HTML
    end

    unless file_loaded?(__FILE__)
      file_loaded(__FILE__)
    end
  end
end
