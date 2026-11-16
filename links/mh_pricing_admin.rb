# encoding: UTF-8
# MHDESIGN Pricing Admin Prototype
# Single-file SketchUp extension prototype for pricing-by-unit database management.

require 'json'
require 'fileutils'
require 'sketchup'
require 'cgi'

module MHDESIGN
  module PricingAdmin
    extend self

    PLUGIN_ID   = 'mhdesign_pricing_admin'.freeze
    PLUGIN_NAME = 'MHDESIGN Pricing Admin'.freeze
    FILE_NAME   = 'mh_pricing_admin_data.json'.freeze
    MATCHING_FILE_NAME = 'mh_matching_file.json'.freeze

    DEFAULT_DATA = {
      'meta' => {
        'version' => '0.1.0',
        'updated_at' => nil
      },
      'manufacturing_profiles' => [
        {
          'id' => 1,
          'category' => 'base',
          'label' => 'الوحدات السفلية',
          'assembly_method' => 'جنب على القاعدة',
          'back_type' => 'HDF',
          'back_thickness' => '6',
          'counter_type' => 'كونتر',
          'counter_thickness' => '18',
          'visible_side_policy' => 'حسب الوحدة',
          'shelf_policy' => 'حسب الوحدة',
          'notes' => ''
        },
        {
          'id' => 2,
          'category' => 'wall',
          'label' => 'الوحدات العلوية',
          'assembly_method' => 'جنب كامل',
          'back_type' => 'HDF',
          'back_thickness' => '6',
          'counter_type' => 'بدون',
          'counter_thickness' => '0',
          'visible_side_policy' => 'حسب الوحدة',
          'shelf_policy' => 'حسب الوحدة',
          'notes' => ''
        },
        {
          'id' => 3,
          'category' => 'tall',
          'label' => 'وحدات الدواليب',
          'assembly_method' => 'جنب كامل',
          'back_type' => 'MDF',
          'back_thickness' => '8',
          'counter_type' => 'بدون',
          'counter_thickness' => '0',
          'visible_side_policy' => 'حسب الوحدة',
          'shelf_policy' => 'حسب الوحدة',
          'notes' => ''
        }
      ],
      'materials' => [
        {
          'id' => 1,
          'name' => 'كونتر 18',
          'code' => 'MAT-001',
          'group' => 'carcass',
          'group_label' => 'خامة الشاسيه',
          'thickness' => '18',
          'pricing_type' => 'فرق سعر',
          'price' => 0,
          'active' => true
        },
        {
          'id' => 2,
          'name' => 'MDF 8',
          'code' => 'MAT-002',
          'group' => 'back',
          'group_label' => 'خامة الظهر',
          'thickness' => '8',
          'pricing_type' => 'فرق سعر',
          'price' => 0,
          'active' => true
        },
        {
          'id' => 3,
          'name' => 'PVC',
          'code' => 'MAT-003',
          'group' => 'door',
          'group_label' => 'خامة الضلفة',
          'thickness' => '18',
          'pricing_type' => 'فرق سعر',
          'price' => 300,
          'active' => true
        }
      ],
      'accessories' => [
        {
          'id' => 1,
          'name' => 'مفصلة سوفت',
          'library_name' => 'مفصلة سوفت',
          'code' => 'ACC-001',
          'kind' => 'مفصلة سوفت',
          'pricing_type' => 'إضافة ثابتة',
          'price' => 180,
          'active' => true
        }
      ],
      'handles' => [
        {
          'id' => 1,
          'name' => 'مقبض 96 مم',
          'library_name' => 'مقبض عادي او تاتش',
          'code' => 'HAN-001',
          'kind' => 'مقبض عادي او تاتش',
          'pricing_type' => 'سعر ثابت',
          'price' => 0,
          'active' => true
        }
      ],
      'units' => [
        {
          'id' => 1,
          'commercial_name' => 'وحدة سفلي 2 ضلفة 50',
          'internal_name' => 'base_double_door_50',
          'code' => 'B-101',
          'category' => 'base',
          'category_label' => 'وحدات سفلية',
          'unit_type' => 'door',
          'base_price' => 3200,
          'widths' => [40, 45, 50, 60],
          'height' => 72,
          'depth' => 58,
          'nearest_width_policy' => 'down',
          'max_width_diff' => 5,
          'fields' => [
            { 'key' => 'assembly_method', 'label' => 'طريقة التجميع', 'mode' => 'mandatory', 'default' => 'جنب على القاعدة', 'allowed' => ['جنب على القاعدة', 'جنب كامل', 'شددات', 'أرصة كاملة'], 'affects_price' => false, 'affects_review' => true },
            { 'key' => 'carcass_material', 'label' => 'خامة الشاسيه', 'mode' => 'mandatory', 'default' => 'كونتر 18', 'allowed' => ['كونتر 18'], 'affects_price' => true, 'affects_review' => true },
            { 'key' => 'door_material', 'label' => 'خامة الضلفة', 'mode' => 'optional', 'default' => 'PVC', 'allowed' => ['PVC'], 'affects_price' => true, 'affects_review' => true },
            { 'key' => 'back_material', 'label' => 'خامة الظهر', 'mode' => 'mandatory', 'default' => 'MDF 8', 'allowed' => ['MDF 8'], 'affects_price' => true, 'affects_review' => true },
            { 'key' => 'accessory', 'label' => 'الإكسسوار', 'mode' => 'optional', 'default' => 'مفصلة سوفت', 'allowed' => ['مفصلة سوفت'], 'affects_price' => true, 'affects_review' => true },
            { 'key' => 'shelves_count', 'label' => 'عدد الأرفف', 'mode' => 'mandatory', 'default' => '1', 'allowed' => ['1', '2', '3'], 'affects_price' => true, 'affects_review' => true },
            { 'key' => 'visible_side', 'label' => 'جنب ظاهر', 'mode' => 'optional', 'default' => 'لا', 'allowed' => ['نعم', 'لا'], 'affects_price' => true, 'affects_review' => true }
          ],
          'pricing_rules' => [
            { 'name' => 'سعر أساسي عرض 50', 'condition' => 'width = 50', 'action' => 'set_base_price', 'value' => 3200, 'priority' => 1, 'stackable' => false },
            { 'name' => 'زيادة خامة PVC', 'condition' => 'door_material = PVC', 'action' => 'add', 'value' => 300, 'priority' => 10, 'stackable' => true },
            { 'name' => 'زيادة مفصلة سوفت', 'condition' => 'accessory = مفصلة سوفت', 'action' => 'add', 'value' => 180, 'priority' => 20, 'stackable' => true }
          ],
          'notes' => ''
        }
      ],
      'review_rules' => [
        {
          'id' => 1,
          'scope' => 'category',
          'category' => 'base',
          'field_key' => 'assembly_method',
          'expected_value' => 'جنب على القاعدة',
          'rule_type' => 'mismatch',
          'message' => 'الوحدات السفلية يجب أن تكون جنب على القاعدة.'
        }
      ]
    }.freeze

    @dialog = nil

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

    def plugin_dir
      @plugin_dir ||= File.dirname(__FILE__)
    end

    def ensure_data_dir!
      FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
    rescue StandardError
      nil
    end

    def data_path
      ensure_data_dir!
      File.join(DATA_DIR, FILE_NAME)
    end

    def matching_path
      ensure_data_dir!
      File.join(DATA_DIR, MATCHING_FILE_NAME)
    end

    def read_matching_data
      return {} unless File.exist?(matching_path)
      data = JSON.parse(File.read(matching_path, encoding: 'UTF-8'))
      return data if data.is_a?(Hash)
      {}
    rescue => e
      puts "#{PLUGIN_NAME} Matching JSON Error: #{e.message}" rescue nil
      {}
    end

    def deep_copy(obj)
      JSON.parse(JSON.generate(obj))
    end

    def ensure_data_file!
      return if File.exist?(data_path)
      write_data(DEFAULT_DATA)
    rescue => e
      UI.messagebox("#{PLUGIN_NAME}\nتعذر إنشاء ملف البيانات:\n#{e.message}")
    end

    def read_data
      ensure_data_file!
      JSON.parse(File.read(data_path, encoding: 'UTF-8'))
    rescue => e
      UI.messagebox("#{PLUGIN_NAME}\nتعذر قراءة ملف البيانات، سيتم إعادة إنشائه.\n#{e.message}")
      write_data(DEFAULT_DATA)
      deep_copy(DEFAULT_DATA)
    end

    def write_data(data)
      data['meta'] ||= {}
      data['meta']['updated_at'] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      File.write(data_path, JSON.pretty_generate(data), mode: 'w:UTF-8')
      true
    rescue => e
      UI.messagebox("#{PLUGIN_NAME}\nتعذر حفظ البيانات:\n#{e.message}")
      false
    end

    def escape_js(str)
      str.to_s.gsub('\\', '\\\\').gsub("\n", '\\n').gsub("\r", '').gsub("'", "\\\\'")
    end

    def json_for_js(obj)
      JSON.generate(obj)
    end

    def next_id(list)
      ids = list.map { |item| item['id'].to_i }
      ids.empty? ? 1 : ids.max + 1
    end

    def open_dialog
      ensure_data_file!

      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      @dialog = UI::HtmlDialog.new(
        dialog_title: PLUGIN_NAME,
        preferences_key: PLUGIN_ID,
        scrollable: true,
        resizable: true,
        width: 1380,
        height: 920,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      attach_callbacks(@dialog)
      @dialog.set_html(build_html)
      @dialog.show
    end

    def attach_callbacks(dialog)
      dialog.add_action_callback('mh_ready') do |_ctx, _payload|
        push_all_data(dialog)
      end

      dialog.add_action_callback('mh_save_all') do |_ctx, payload|
        begin
          parsed = JSON.parse(payload)
          ok = write_data(parsed)
          push_all_data(dialog) if ok
        rescue => e
          UI.messagebox("خطأ أثناء حفظ البيانات:\n#{e.message}")
        end
      end

      dialog.add_action_callback('mh_reset_defaults') do |_ctx, _payload|
        write_data(deep_copy(DEFAULT_DATA))
        push_all_data(dialog)
      end

      dialog.add_action_callback('mh_import_json') do |_ctx, _payload|
        path = UI.openpanel('اختر ملف JSON للاستيراد', DATA_DIR, 'JSON Files|*.json||')
        next unless path && File.exist?(path)
        begin
          data = JSON.parse(File.read(path, encoding: 'UTF-8'))
          write_data(data)
          push_all_data(dialog)
          UI.messagebox('تم استيراد البيانات بنجاح.')
        rescue => e
          UI.messagebox("تعذر استيراد الملف:\n#{e.message}")
        end
      end

      dialog.add_action_callback('mh_export_json') do |_ctx, _payload|
        path = UI.savepanel('حفظ نسخة من ملف البيانات', DATA_DIR, FILE_NAME)
        next unless path
        begin
          FileUtils.cp(data_path, path)
          UI.messagebox('تم تصدير الملف بنجاح.')
        rescue => e
          UI.messagebox("تعذر التصدير:\n#{e.message}")
        end
      end
    end

    def push_all_data(dialog = @dialog)
      return unless dialog
      data = read_data
      matching = read_matching_data
      script = "window.MH_MATCHING_DATA = #{json_for_js(matching)}; window.MH_APP && window.MH_APP.loadData(#{json_for_js(data)});"
      dialog.execute_script(script)
    rescue => e
      UI.messagebox("#{PLUGIN_NAME}\nتعذر إرسال البيانات للواجهة:\n#{e.message}")
    end

    def build_html
      <<~HTML
      <!doctype html>
      <html lang="ar" dir="rtl">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{PLUGIN_NAME}</title>
        <style>
          :root {
            --bg: #0f172a;
            --panel: #111827;
            --panel-2: #1f2937;
            --card: #ffffff;
            --muted: #6b7280;
            --text: #111827;
            --line: #e5e7eb;
            --accent: #2563eb;
            --accent-2: #1d4ed8;
            --success: #059669;
            --danger: #dc2626;
            --warning: #d97706;
            --radius: 18px;
            --shadow: 0 16px 40px rgba(15, 23, 42, .12);
          }
          * { box-sizing: border-box; }
          html, body {
            margin: 0;
            padding: 0;
            background: linear-gradient(160deg, #eef2ff 0%, #f8fafc 55%, #eef2f7 100%);
            color: var(--text);
            font-family: Tahoma, Arial, sans-serif;
            min-height: 100%;
          }
          body { padding: 18px; }
          .topbar {
            background: linear-gradient(135deg, #0f172a, #1e3a8a);
            color: #fff;
            border-radius: 24px;
            padding: 24px;
            box-shadow: var(--shadow);
            display: grid;
            grid-template-columns: 1.5fr 1fr;
            gap: 16px;
            margin-bottom: 18px;
          }
          .title { font-size: 30px; font-weight: 700; margin: 0 0 6px; }
          .subtitle { margin: 0; opacity: .9; line-height: 1.8; }
          .top-actions { display: flex; gap: 10px; flex-wrap: wrap; justify-content: flex-start; align-content: flex-start; }
          .btn {
            border: 0;
            border-radius: 14px;
            padding: 12px 18px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 700;
            transition: .18s ease;
          }
          .btn:hover { transform: translateY(-1px); }
          .btn.primary { background: var(--accent); color: #fff; }
          .btn.primary:hover { background: var(--accent-2); }
          .btn.secondary { background: rgba(255,255,255,.12); color: #fff; border: 1px solid rgba(255,255,255,.16); }
          .btn.white { background: #fff; color: #111827; }
          .layout {
            display: grid;
            grid-template-columns: 280px minmax(0, 1fr);
            gap: 18px;
          }
          .sidebar {
            background: rgba(255,255,255,.9);
            backdrop-filter: blur(10px);
            border-radius: 22px;
            padding: 14px;
            box-shadow: var(--shadow);
            position: sticky;
            top: 18px;
            height: calc(100vh - 36px);
            overflow: auto;
          }
          .menu-title {
            font-size: 13px;
            color: var(--muted);
            margin: 8px 6px 10px;
            font-weight: 700;
          }
          .nav-btn {
            display: block;
            width: 100%;
            text-align: right;
            background: transparent;
            border: 0;
            border-radius: 14px;
            padding: 13px 14px;
            margin-bottom: 8px;
            cursor: pointer;
            font-size: 15px;
            font-weight: 700;
            color: #111827;
          }
          .nav-btn.active,
          .nav-btn:hover {
            background: #dbeafe;
            color: #1d4ed8;
          }
          .content {
            min-width: 0;
          }
          .panel {
            background: rgba(255,255,255,.9);
            backdrop-filter: blur(10px);
            border-radius: 22px;
            box-shadow: var(--shadow);
            padding: 18px;
            display: none;
          }
          .panel.active { display: block; }
          .panel-head {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 12px;
            flex-wrap: wrap;
            margin-bottom: 16px;
          }
          .panel-title { margin: 0; font-size: 24px; }
          .panel-desc { margin: 6px 0 0; color: var(--muted); }
          .stats { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 14px; margin-bottom: 18px; }
          .stat {
            background: #fff;
            border-radius: 18px;
            padding: 16px;
            border: 1px solid var(--line);
          }
          .stat .k { color: var(--muted); font-size: 13px; margin-bottom: 8px; }
          .stat .v { font-size: 28px; font-weight: 800; }
          .grid { display: grid; gap: 16px; }
          .grid.cards-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
          .grid.cards-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
          .card {
            background: #fff;
            border: 1px solid var(--line);
            border-radius: 20px;
            padding: 16px;
            min-width: 0;
          }
          .card h3, .card h4 { margin: 0 0 12px; }
          .field-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
          .field-grid.three { grid-template-columns: repeat(3, minmax(0, 1fr)); }
          .field { min-width: 0; }
          .field label {
            display: block;
            margin-bottom: 6px;
            font-size: 13px;
            color: #374151;
            font-weight: 700;
          }
          input[type="text"], input[type="number"], textarea, select {
            width: 100%;
            padding: 11px 12px;
            border: 1px solid #d1d5db;
            border-radius: 12px;
            background: #fff;
            font-size: 14px;
            outline: none;
          }
          textarea { min-height: 92px; resize: vertical; }
          .chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
          .chip {
            font-size: 12px;
            background: #eef2ff;
            color: #3730a3;
            padding: 6px 10px;
            border-radius: 999px;
            font-weight: 700;
          }
          .table-wrap { overflow: auto; border: 1px solid var(--line); border-radius: 18px; background: #fff; }
          table { width: 100%; border-collapse: collapse; min-width: 920px; }
          th, td { padding: 12px 10px; border-bottom: 1px solid var(--line); text-align: right; vertical-align: top; }
          th { background: #f8fafc; font-size: 13px; color: #374151; position: sticky; top: 0; z-index: 2; }
          tr:last-child td { border-bottom: 0; }
          .small { font-size: 12px; color: var(--muted); }
          .toolbar { display: flex; gap: 10px; flex-wrap: wrap; }
          .toolbar .btn { padding: 10px 14px; }
          .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 9px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 800;
          }
          .badge.success { background: #ecfdf5; color: #065f46; }
          .badge.warn { background: #fff7ed; color: #9a3412; }
          .badge.info { background: #eff6ff; color: #1d4ed8; }
          .row-actions { display: flex; gap: 8px; flex-wrap: wrap; }
          .mini-btn {
            border: 0;
            border-radius: 10px;
            padding: 8px 10px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 800;
          }
          .mini-btn.edit { background: #eff6ff; color: #1d4ed8; }
          .mini-btn.delete { background: #fef2f2; color: #b91c1c; }
          .unit-item-actions {
            display: flex;
            gap: 8px;
            flex-wrap: nowrap;
            align-items: stretch;
            margin-bottom: 10px;
          }
          .unit-item-actions .mini-btn {
            flex: 1 1 0;
            min-width: 0;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            white-space: nowrap;
          }
          .unit-card { background: #fff; border: 1px solid var(--line); border-radius: 20px; padding: 16px; }
          .unit-top { display: flex; justify-content: space-between; gap: 12px; align-items: flex-start; margin-bottom: 10px; }
          .unit-meta { color: var(--muted); font-size: 13px; margin-top: 4px; }
          .unit-price { font-size: 24px; font-weight: 800; color: #0f172a; }
          .list { display: grid; gap: 8px; }
          .units-browser { display: grid; grid-template-columns: 340px minmax(0, 1fr); gap: 16px; align-items: start; }
          .unit-list { background:#fff; border:1px solid var(--line); border-radius:20px; padding:12px; max-height:70vh; overflow:auto; }
          .library-card { border:1px solid var(--line); border-radius:18px; padding:14px; margin-bottom:10px; cursor:pointer; transition:.18s ease; background:#fff; }
          .library-card:hover, .library-card.active { border-color:#93c5fd; background:#eff6ff; box-shadow:0 8px 20px rgba(37,99,235,.08); }
          .library-card .name { font-weight:800; margin-bottom:6px; }
          .library-card .meta { color:var(--muted); font-size:12px; }
          .items-stack { display:grid; gap:14px; }
          .entry-card { background:#fff; border:1px solid var(--line); border-radius:20px; padding:16px; }
          .entry-card-head { display:flex; align-items:center; justify-content:space-between; gap:10px; margin-bottom:12px; }
          .entry-card-title { font-size:18px; font-weight:800; }
          .material-stack { display:grid; gap:10px; }
          .material-row { display:grid; grid-template-columns: minmax(0, 1fr) auto auto; gap:10px; align-items:center; background:#f8fafc; border:1px solid #e5e7eb; border-radius:16px; padding:10px; min-width:0; }
          .material-name { min-width:0; }
          .material-name input { width:100%; max-width:100%; }
          .material-actions { display:flex; align-items:center; gap:8px; flex-wrap:wrap; justify-content:flex-end; }
          .material-toggle { display:flex; align-items:center; gap:6px; font-size:12px; color:#374151; background:#fff; border:1px solid #e5e7eb; border-radius:12px; padding:8px 10px; white-space:nowrap; }
          .empty-state { background:#fff; border:1px dashed #cbd5e1; border-radius:20px; padding:28px; text-align:center; color:var(--muted); }
          .list-item {
            background: #f8fafc;
            border: 1px solid #e5e7eb;
            border-radius: 14px;
            padding: 10px 12px;
          }
          .footer-note {
            margin-top: 14px;
            color: var(--muted);
            font-size: 12px;
          }
          .statusbar {
            position: fixed;
            left: 18px;
            bottom: 18px;
            background: #111827;
            color: #fff;
            padding: 10px 14px;
            border-radius: 999px;
            box-shadow: 0 10px 24px rgba(0,0,0,.18);
            font-size: 12px;
            z-index: 999;
          }



          .unit-print-options {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
            background: #f8fafc;
            border: 1px solid #e5e7eb;
            border-radius: 14px;
            padding: 8px 10px;
          }
          .unit-print-options label {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            margin: 0;
            color: #374151;
            font-size: 13px;
            font-weight: 800;
            white-space: nowrap;
          }
          .unit-print-options input[type="checkbox"] {
            width: auto;
            transform: scale(1.08);
          }
          .accessory-picker-btn {
            width: 100%;
            min-height: 43px;
            border: 1px solid #d1d5db;
            background: #fff;
            color: #111827;
            border-radius: 12px;
            padding: 10px 12px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 800;
            text-align: right;
          }
          .accessory-picker-btn:hover {
            border-color: #93c5fd;
            background: #eff6ff;
            color: #1d4ed8;
          }
          .accessory-summary {
            margin-top: 8px;
            min-height: 32px;
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 6px;
          }
          .accessory-summary .summary-chip {
            background: #eef2ff;
            color: #3730a3;
            border-radius: 999px;
            padding: 6px 9px;
            font-size: 12px;
            font-weight: 800;
          }
          .price-preview {
            background: #f8fafc;
            border: 1px solid #e5e7eb;
            border-radius: 16px;
            padding: 12px;
          }
          .price-preview .line {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            font-size: 13px;
            color: #374151;
            margin-bottom: 7px;
          }
          .price-preview .line:last-child { margin-bottom: 0; }
          .price-preview .total {
            border-top: 1px dashed #cbd5e1;
            padding-top: 9px;
            margin-top: 9px;
            font-size: 16px;
            color: #0f172a;
            font-weight: 900;
          }
          .mh-modal-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, .55);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 18px;
            z-index: 5000;
          }
          .mh-modal-backdrop.show { display: flex; }
          .mh-modal {
            width: min(720px, 96vw);
            max-height: 86vh;
            overflow: auto;
            background: #fff;
            border-radius: 22px;
            box-shadow: 0 24px 80px rgba(15, 23, 42, .35);
            border: 1px solid #e5e7eb;
          }
          .mh-modal-head {
            position: sticky;
            top: 0;
            z-index: 2;
            background: #fff;
            border-bottom: 1px solid #e5e7eb;
            padding: 16px;
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
          }
          .mh-modal-title {
            font-size: 20px;
            font-weight: 900;
            margin-bottom: 4px;
          }
          .mh-modal-body { padding: 16px; }
          .mh-modal-actions {
            position: sticky;
            bottom: 0;
            background: #fff;
            border-top: 1px solid #e5e7eb;
            padding: 14px 16px;
            display: flex;
            justify-content: flex-start;
            gap: 10px;
            flex-wrap: wrap;
          }
          .accessory-qty-row {
            display: grid;
            grid-template-columns: minmax(0, 1fr) 110px 120px;
            gap: 10px;
            align-items: center;
            padding: 12px;
            border: 1px solid #e5e7eb;
            border-radius: 16px;
            background: #f8fafc;
            margin-bottom: 10px;
          }
          .accessory-qty-row .acc-name { font-weight: 900; }
          .accessory-qty-row .acc-meta { color: #6b7280; font-size: 12px; margin-top: 4px; }
          .accessory-qty-row input[type="number"] { text-align: center; font-weight: 800; }

          @media (max-width: 1200px) {
            .layout { grid-template-columns: 1fr; }
            .sidebar { position: relative; top: auto; height: auto; }
            .grid.cards-3, .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
          }
          @media (max-width: 800px) {
            .topbar { grid-template-columns: 1fr; }
            .grid.cards-3, .grid.cards-2, .stats, .field-grid, .field-grid.three { grid-template-columns: 1fr; }
          }
        </style>
      </head>
      <body>
        <div class="topbar">
          <div>
            <h1 class="title">لوحة تحكم تسعير المطابخ بالوحدة</h1>
            <p class="subtitle"> تم تصميم هذه الإضافه بواسطة امتشديزاين للتصميم الرقمي و الهندسي</p>
            <p class="subtitle"> mhdesign-eg.com - +201100211340</p>
          </div>
          <div class="top-actions">
            <button class="btn white" onclick="MH.saveAll()">حفظ كل التعديلات</button>
            <button class="btn secondary" onclick="MH.exportJson()">تصدير JSON</button>
            <button class="btn secondary" onclick="MH.importJson()">استيراد JSON</button>
            <button class="btn secondary" onclick="MH.resetDefaults()">إعادة الضبط</button>
          </div>
        </div>

        <div class="layout">
          <aside class="sidebar">
            <div class="menu-title">القائمة</div>
            <button class="nav-btn active" data-panel="dashboard">نظرة عامة</button>
            <button class="nav-btn" data-panel="materials">الخامات</button>
            <button class="nav-btn" data-panel="accessories">الإكسسوارات</button>
            <button class="nav-btn" data-panel="handles">المقابض</button>
            <button class="nav-btn" data-panel="units">الوحدات</button>
          </aside>

          <main class="content">
            <section class="panel active" id="panel-dashboard"></section>
            <section class="panel" id="panel-materials"></section>
            <section class="panel" id="panel-accessories"></section>
            <section class="panel" id="panel-handles"></section>
            <section class="panel" id="panel-units"></section>
          </main>
        </div>

        <div class="statusbar" id="statusbar">جاهز</div>


        <div class="mh-modal-backdrop" id="handle_modal_backdrop">
          <div class="mh-modal">
            <div class="mh-modal-head">
              <div>
                <div class="mh-modal-title">اختيار المقابض</div>
                <div class="small" id="handle_modal_subtitle">حدد العدد المطلوب لكل مقبض في هذا البند.</div>
              </div>
              <button class="mini-btn delete" onclick="MH.closeHandlePicker()">إغلاق</button>
            </div>
            <div class="mh-modal-body" id="handle_modal_body"></div>
            <div class="mh-modal-actions">
              <button class="btn primary" onclick="MH.applyHandlePicker()">تطبيق الاختيارات</button>
              <button class="btn white" onclick="MH.clearHandlePicker()">مسح الكل</button>
              <button class="btn secondary" style="background:#f3f4f6;color:#111827;border:1px solid #e5e7eb" onclick="MH.closeHandlePicker()">إلغاء</button>
            </div>
          </div>
        </div>

        <div class="mh-modal-backdrop" id="accessory_modal_backdrop">
          <div class="mh-modal">
            <div class="mh-modal-head">
              <div>
                <div class="mh-modal-title">اختيار الإكسسوارات</div>
                <div class="small" id="accessory_modal_subtitle">حدد العدد المطلوب لكل إكسسوار في هذا البند.</div>
              </div>
              <button class="mini-btn delete" onclick="MH.closeAccessoryPicker()">إغلاق</button>
            </div>
            <div class="mh-modal-body" id="accessory_modal_body"></div>
            <div class="mh-modal-actions">
              <button class="btn primary" onclick="MH.applyAccessoryPicker()">تطبيق الاختيارات</button>
              <button class="btn white" onclick="MH.clearAccessoryPicker()">مسح الكل</button>
              <button class="btn secondary" style="background:#f3f4f6;color:#111827;border:1px solid #e5e7eb" onclick="MH.closeAccessoryPicker()">إلغاء</button>
            </div>
          </div>
        </div>


        <script>
          const MH = {
            data: null,
            matchingData: null,
            libraryNames: { accessories: [], handles: [], units: [] },
            matchingStatus: '',

            ready() {
              this.bindNav();
              window.MH_APP = this;
              window.MH = this;
              if (window.sketchup && window.sketchup.mh_ready) {
                window.sketchup.mh_ready('1');
              }
            },
            normalizeData(data) {
              data.meta = data.meta || {};
              data.manufacturing_profiles = Array.isArray(data.manufacturing_profiles) ? data.manufacturing_profiles : [];
              data.materials = Array.isArray(data.materials) ? data.materials : [];
              data.accessories = Array.isArray(data.accessories) ? data.accessories : [];
              data.handles = Array.isArray(data.handles) ? data.handles : [];
              data.accessories = data.accessories.map(a => ({
                ...a,
                library_name: String(a.library_name || a.kind || '').trim(),
                kind: String(a.library_name || a.kind || '').trim(),
                name: String(a.name || '').trim()
              }));
              data.handles = data.handles.map(h => ({
                ...h,
                library_name: String(h.library_name || h.kind || '').trim(),
                kind: String(h.library_name || h.kind || '').trim(),
                name: String(h.name || '').trim()
              }));
              data.review_rules = Array.isArray(data.review_rules) ? data.review_rules : [];
              data.units = Array.isArray(data.units) ? data.units : [];

              data.units = data.units.map((unit, index) => {
                const isCatalog = Array.isArray(unit.items);
                if (isCatalog) {
                  unit.id = Number(unit.id || index + 1);
                  unit.library_name = unit.library_name || unit.internal_name || ('وحدة مكتبة ' + (index + 1));
                  unit.category = unit.category || 'base';
                  unit.category_label = unit.category_label || 'وحدات سفلية';
                  unit.items = unit.items.map((item, itemIndex) => this.normalizeUnitItem(item, unit, itemIndex));
                  return unit;
                }

                const migratedItem = this.normalizeUnitItem({
                  commercial_name: unit.commercial_name || 'بند جديد',
                  code: unit.code || '',
                  width: Array.isArray(unit.widths) && unit.widths.length ? Number(unit.widths[0]) : 50,
                  carcass_material: this.findFieldDefault(unit, 'carcass_material'),
                  door_material: this.findFieldDefault(unit, 'door_material'),
                  back_material: this.findFieldDefault(unit, 'back_material'),
                  depth: Number(unit.depth || 0),
                  height: Number(unit.height || 0),
                  assembly_method: this.findFieldDefault(unit, 'assembly_method'),
                  counter_type: this.findFieldDefault(unit, 'counter_type'),
                  counter_thickness: this.findFieldDefault(unit, 'counter_thickness'),
                  back_thickness: this.findFieldDefault(unit, 'back_thickness'),
                  drawers_count: Number(this.findFieldDefault(unit, 'drawers_count', 0)),
                  handle_name: this.findFieldDefault(unit, 'handle_name'),
                  handle_items: this.findFieldDefault(unit, 'handle_name') ? [{ name: this.findFieldDefault(unit, 'handle_name'), qty: 1 }] : [],
                  accessory_name: this.findFieldDefault(unit, 'accessory'),
                  accessory_items: this.findFieldDefault(unit, 'accessory') ? [{ name: this.findFieldDefault(unit, 'accessory'), qty: 1 }] : [],
                  visible_side: Number(this.findFieldDefault(unit, 'visible_side', 0)),
                  shelves_count: Number(this.findFieldDefault(unit, 'shelves_count', 0)),
                  ignore_shelf: String(this.findFieldDefault(unit, 'ignore_shelf', 'false')) === 'true',
                  has_accessory: !!this.findFieldDefault(unit, 'accessory'),
                  fixed_price: Number(unit.base_price || 0),
                  notes: unit.notes || ''
                }, unit, 0);

                return {
                  id: Number(unit.id || index + 1),
                  library_name: unit.internal_name || unit.commercial_name || ('وحدة مكتبة ' + (index + 1)),
                  category: unit.category || 'base',
                  category_label: unit.category_label || 'وحدات سفلية',
                  notes: unit.notes || '',
                  items: [migratedItem]
                };
              });

              if (typeof this.activeUnitIndex !== 'number') this.activeUnitIndex = 0;
              if (this.activeUnitIndex >= data.units.length) this.activeUnitIndex = Math.max(0, data.units.length - 1);
              return data;
            },

            normalizeUnitItem(item, unit, itemIndex) {
              return {
                id: Number(item.id || itemIndex + 1),
                commercial_name: item.commercial_name || 'بند جديد',
                code: item.code || '',
                width: Number(item.width || 50),
                depth: Number(item.depth || 0),
                height: Number(item.height || 0),
                carcass_material: item.carcass_material || '',
                door_material: item.door_material || '',
                back_material: item.back_material || '',
                assembly_method: item.assembly_method || '',
                counter_type: item.counter_type || '',
                counter_thickness: item.counter_thickness || '',
                back_thickness: item.back_thickness || '',
                drawers_count: Number(item.drawers_count || 0),
                handle_name: item.handle_name || '',
                handle_items: this.normalizeHandleItems(item),
                accessory_name: item.accessory_name || '',
                accessory_items: this.normalizeAccessoryItems(item),
                has_accessory: !!(item.has_accessory || item.accessory_name || (Array.isArray(item.accessory_items) && item.accessory_items.length)),
                visible_side: Number(item.visible_side || 0),
                shelves_count: Number(item.shelves_count || 0),
                ignore_shelf: !!item.ignore_shelf,
                fixed_price: Number(item.fixed_price || item.base_price || 0),
                notes: item.notes || ''
              };
            },

            normalizeHandleItems(item) {
              if (Array.isArray(item.handle_items)) {
                return item.handle_items
                  .map(row => ({
                    name: String(row && row.name ? row.name : '').trim(),
                    qty: Math.max(0, Number(row && row.qty ? row.qty : 0))
                  }))
                  .filter(row => row.name && row.qty > 0);
              }

              if (item.handle_name) {
                return [{ name: String(item.handle_name).trim(), qty: 1 }];
              }

              return [];
            },

            normalizeAccessoryItems(item) {
              if (Array.isArray(item.accessory_items)) {
                return item.accessory_items
                  .map(row => ({
                    name: String(row && row.name ? row.name : '').trim(),
                    qty: Math.max(0, Number(row && row.qty ? row.qty : 0))
                  }))
                  .filter(row => row.name && row.qty > 0);
              }

              if (Array.isArray(item.accessory_names)) {
                return item.accessory_names
                  .map(name => ({ name: String(name || '').trim(), qty: 1 }))
                  .filter(row => row.name);
              }

              if (item.accessory_name) {
                return [{ name: String(item.accessory_name).trim(), qty: 1 }];
              }

              return [];
            },

            getAccessoryByName(name) {
              const n = String(name || '').trim();
              return (this.data.accessories || []).find(a => {
                return String(a.name || '').trim() === n || String(a.library_name || a.kind || '').trim() === n;
              }) || null;
            },

            getHandleByName(name) {
              const n = String(name || '').trim();
              return (this.data.handles || []).find(h => {
                return String(h.name || '').trim() === n || String(h.library_name || h.kind || '').trim() === n;
              }) || null;
            },

            isHandleMeterPricing(handle) {
              const type = String(handle && handle.pricing_type ? handle.pricing_type : '').trim().toLowerCase();
              return type === 'بالمتر' || type === 'سعر بالمتر' || type === 'متر' || type === 'meter' || type === 'per_meter' || type === 'per meter';
            },

            handleRowPrice(handle, item, qty) {
              if (!handle || handle.active === false) return 0;
              const price = Number(handle.price || 0);
              const count = Number(qty || 0);
              if (this.isHandleMeterPricing(handle)) {
                const widthMeter = Math.max(0, Number(item && item.width ? item.width : 0)) / 100.0;
                return price * widthMeter * count;
              }
              return price * count;
            },

            handlePrice(item) {
              return this.normalizeHandleItems(item)
                .reduce((sum, row) => {
                  const h = this.getHandleByName(row.name);
                  return sum + this.handleRowPrice(h, item, row.qty);
                }, 0);
            },

            accessorySubtotal(item) {
              return this.normalizeAccessoryItems(item)
                .reduce((sum, row) => {
                  const acc = this.getAccessoryByName(row.name);
                  const price = acc && acc.active !== false ? Number(acc.price || 0) : 0;
                  return sum + (price * Number(row.qty || 0));
                }, 0);
            },

            itemTotalPrice(item) {
              return Number(item.fixed_price || 0) + this.handlePrice(item) + this.accessorySubtotal(item);
            },

            money(value) {
              const n = Number(value || 0);
              return n.toLocaleString('ar-EG', { maximumFractionDigits: 2 });
            },

            handleSummary(item) {
              const rows = this.normalizeHandleItems(item);
              if (!rows.length) return '<span class="small">بدون مقبض</span>';
              return rows.map(row => `<span class="summary-chip">${this.esc(row.name)} × ${Number(row.qty || 0)}</span>`).join('');
            },

            accessorySummary(item) {
              const rows = this.normalizeAccessoryItems(item);
              if (!rows.length) return '<span class="small">بدون إكسسوارات</span>';
              return rows.map(row => `<span class="summary-chip">${this.esc(row.name)} × ${Number(row.qty || 0)}</span>`).join('');
            },

            findFieldDefault(unit, key, fallback='') {
              const field = Array.isArray(unit.fields) ? unit.fields.find(f => f && f.key === key) : null;
              return field ? (field.default ?? fallback) : fallback;
            },

            unitItemsCount() {
              return (this.data.units || []).reduce((sum, unit) => sum + ((unit.items || []).length), 0);
            },

            materialOptions(group) {
              return (this.data.materials || []).filter(m => m.group === group && m.active !== false);
            },

            renderSelectOptions(items, selected, includeEmpty=true, emptyLabel='— اختر —') {
              const opts = [];
              if (includeEmpty) opts.push(`<option value="">${emptyLabel}</option>`);
              items.forEach(item => {
                const value = this.esc(item.name || '');
                opts.push(`<option value="${value}" ${(item.name || '') === (selected || '') ? 'selected' : ''}>${value}</option>`);
              });
              return opts.join('');
            },

            loadData(data) {
              try {
                this.data = this.normalizeData(data || {});
                this.loadMatchingFile();
                this.render();
                this.status(this.matchingStatus || 'تم تحميل البيانات');
              } catch (e) {
                console.error('LoadData Error:', e);
                this.status('حدث خطأ أثناء تحميل البيانات - راجع Ruby Console');
                const root = document.getElementById('panel-dashboard');
                if (root) {
                  root.innerHTML = `<div class="empty-state"><b>خطأ في تحميل لوحة التحكم</b><br>${this.esc(e && e.message ? e.message : e)}</div>`;
                }
              }
            },

            loadMatchingFile() {
              try {
                const raw = (window.MH_MATCHING_DATA && typeof window.MH_MATCHING_DATA === 'object') ? window.MH_MATCHING_DATA : {};
                this.matchingData = raw;
                this.libraryNames = { accessories: [], handles: [], units: [] };

                const readNames = (arr) => {
                  const out = [];
                  (Array.isArray(arr) ? arr : []).forEach(row => {
                    if (!row || row.active === false) return;
                    const name = String(row.name || '').trim();
                    if (name && !out.includes(name)) out.push(name);
                  });
                  return out;
                };

                this.libraryNames.accessories = readNames(raw.accessories);
                this.libraryNames.handles = readNames(raw.handles);
                this.libraryNames.units = readNames(raw.units);

                const count = this.libraryNames.accessories.length + this.libraryNames.handles.length + this.libraryNames.units.length;
                this.matchingStatus = count > 0 ? `تم تحميل ملف المطابقة (${count} مسمى)` : 'ملف المطابقة غير موجود أو فارغ - تم استخدام القوائم القديمة';
              } catch (e) {
                console.error('Matching Load Error:', e);
                this.matchingData = null;
                this.libraryNames = { accessories: [], handles: [], units: [] };
                this.matchingStatus = 'ملف المطابقة غير صالح - تم استخدام القوائم القديمة';
              }
            },

            status(text) {
              const el = document.getElementById('statusbar');
              if (el) el.textContent = text;
            },

            bindNav() {
              document.querySelectorAll('.nav-btn').forEach(btn => {
                btn.addEventListener('click', () => {
                  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
                  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
                  btn.classList.add('active');
                  const panel = document.getElementById('panel-' + btn.dataset.panel);
                  if (panel) panel.classList.add('active');
                });
              });
            },

            getEl(id) {
              return document.getElementById(id);
            },

            readValue(id, fallback='') {
              const el = this.getEl(id);
              return el ? el.value : fallback;
            },

            readNumber(id, fallback=0) {
              const el = this.getEl(id);
              if (!el) return Number(fallback || 0);
              const n = Number(el.value || 0);
              return Number.isNaN(n) ? Number(fallback || 0) : n;
            },

            readChecked(id, fallback=false) {
              const el = this.getEl(id);
              return el ? !!el.checked : !!fallback;
            },

            captureMaterials() {
              (this.data.materials || []).forEach((m, i) => {
                m.name = this.readValue(`mat_name_${i}`, m.name || '');
                m.active = this.readChecked(`mat_active_${i}`, m.active !== false);
              });
            },

            captureAccessories() {
              (this.data.accessories || []).forEach((a, i) => {
                a.name = this.readValue(`acc_name_${i}`, a.name || '');
                a.code = this.readValue(`acc_code_${i}`, a.code || '');
                a.library_name = this.readValue(`acc_library_name_${i}`, a.library_name || a.kind || '');
                a.kind = a.library_name; // توافق مع النسخ القديمة
                a.pricing_type = this.readValue(`acc_pricing_${i}`, a.pricing_type || '');
                a.price = this.readNumber(`acc_price_${i}`, a.price || 0);
                a.active = this.readChecked(`acc_active_${i}`, !!a.active);
              });
            },

            captureHandles() {
              (this.data.handles || []).forEach((h, i) => {
                h.name = this.readValue(`han_name_${i}`, h.name || '');
                h.code = this.readValue(`han_code_${i}`, h.code || '');
                h.library_name = this.readValue(`han_library_name_${i}`, h.library_name || h.kind || '');
                h.kind = h.library_name; // توافق مع النسخ القديمة
                h.pricing_type = this.readValue(`han_pricing_${i}`, h.pricing_type || '');
                h.price = this.readNumber(`han_price_${i}`, h.price || 0);
                h.active = this.readChecked(`han_active_${i}`, !!h.active);
              });
            },

            captureManufacturing() {
              (this.data.manufacturing_profiles || []).forEach((item, i) => {
                item.category = this.readValue(`mfg_category_${i}`, item.category || '');
                item.label = this.readValue(`mfg_label_${i}`, item.label || '');
                item.assembly_method = this.readValue(`mfg_assembly_method_${i}`, item.assembly_method || '');
                item.back_type = this.readValue(`mfg_back_type_${i}`, item.back_type || '');
                item.back_thickness = this.readValue(`mfg_back_thickness_${i}`, item.back_thickness || '');
                item.counter_type = this.readValue(`mfg_counter_type_${i}`, item.counter_type || '');
                item.counter_thickness = this.readValue(`mfg_counter_thickness_${i}`, item.counter_thickness || '');
                item.visible_side_policy = this.readValue(`mfg_visible_side_policy_${i}`, item.visible_side_policy || '');
                item.shelf_policy = this.readValue(`mfg_shelf_policy_${i}`, item.shelf_policy || '');
                item.notes = this.readValue(`mfg_notes_${i}`, item.notes || '');
              });
            },

            captureUnitCard(unitIndex=this.activeUnitIndex) {
              const unit = (this.data.units || [])[unitIndex];
              if (!unit) return;
              unit.library_name = this.readValue(`unit_library_name_${unitIndex}`, unit.library_name || '');
              unit.category = this.readValue(`unit_category_${unitIndex}`, unit.category || 'base');
              unit.category_label = this.readValue(`unit_category_label_${unitIndex}`, unit.category_label || '');
              unit.notes = this.readValue(`unit_notes_${unitIndex}`, unit.notes || '');
            },

            captureUnitItem(unitIndex=this.activeUnitIndex, itemIndex=null) {
              const unit = (this.data.units || [])[unitIndex];
              if (!unit || !Array.isArray(unit.items)) return;
              const indices = itemIndex === null ? unit.items.map((_, i) => i) : [itemIndex];
              indices.forEach(i => {
                const item = unit.items[i];
                if (!item) return;
                item.commercial_name = this.readValue(`item_commercial_name_${unitIndex}_${i}`, item.commercial_name || '');
                item.code = this.readValue(`item_code_${unitIndex}_${i}`, item.code || '');
                item.width = this.readNumber(`item_width_${unitIndex}_${i}`, item.width || 0);
                item.depth = this.readNumber(`item_depth_${unitIndex}_${i}`, item.depth || 0);
                item.height = this.readNumber(`item_height_${unitIndex}_${i}`, item.height || 0);
                item.carcass_material = this.readValue(`item_carcass_material_${unitIndex}_${i}`, item.carcass_material || '');
                item.door_material = this.readValue(`item_door_material_${unitIndex}_${i}`, item.door_material || '');
                item.back_material = this.readValue(`item_back_material_${unitIndex}_${i}`, item.back_material || '');
                item.assembly_method = this.readValue(`item_assembly_method_${unitIndex}_${i}`, item.assembly_method || '');
                item.counter_type = this.readValue(`item_counter_type_${unitIndex}_${i}`, item.counter_type || '');
                item.counter_thickness = this.readValue(`item_counter_thickness_${unitIndex}_${i}`, item.counter_thickness || '');
                item.back_thickness = this.readValue(`item_back_thickness_${unitIndex}_${i}`, item.back_thickness || '');
                item.drawers_count = this.readNumber(`item_drawers_count_${unitIndex}_${i}`, item.drawers_count || 0);
                item.handle_items = this.normalizeHandleItems(item);
                item.handle_name = item.handle_items.length ? item.handle_items.map(row => row.name).join(', ') : '';
                item.accessory_items = this.normalizeAccessoryItems(item);
                item.accessory_name = item.accessory_items.length ? item.accessory_items.map(row => row.name).join(', ') : '';
                item.has_accessory = item.accessory_items.length > 0;
                item.visible_side = this.readNumber(`item_visible_side_${unitIndex}_${i}`, item.visible_side || 0);
                item.shelves_count = this.readNumber(`item_shelves_count_${unitIndex}_${i}`, item.shelves_count || 0);
                item.ignore_shelf = this.readValue(`item_ignore_shelf_${unitIndex}_${i}`, item.ignore_shelf ? 'true' : 'false') === 'true';
                item.fixed_price = this.readNumber(`item_fixed_price_${unitIndex}_${i}`, item.fixed_price || 0);
                item.notes = this.readValue(`item_notes_${unitIndex}_${i}`, item.notes || '');
              });
            },

            captureAllEdits() {
              this.captureManufacturing();
              this.captureMaterials();
              this.captureAccessories();
              this.captureHandles();
              (this.data.units || []).forEach((u, i) => {
                this.captureUnitCard(i);
                this.captureUnitItem(i);
              });
            },

            saveUnitCard(unitIndex=this.activeUnitIndex) {
              this.captureUnitCard(unitIndex);
              this.renderUnits();
              this.status('تم حفظ كارت الوحدة محليًا');
            },

            saveUnitItem(unitIndex=this.activeUnitIndex, itemIndex) {
              this.captureUnitItem(unitIndex, itemIndex);
              const unit = (this.data.units || [])[unitIndex];
              const item = unit && Array.isArray(unit.items) ? unit.items[itemIndex] : null;
              if (item && this.isDuplicateUnitCode(item.code, unitIndex, itemIndex)) {
                alert('تحذير: كود الوحدة مستخدم بالفعل داخل نفس الوحدة. من فضلك اكتب كود مختلف.');
                this.renderUnits();
                return;
              }
              this.renderUnits();
              this.status('تم حفظ البند محليًا');
            },

            saveManufacturingLocal() {
              this.captureManufacturing();
              this.renderManufacturing();
              this.status('تم حفظ قواعد التصنيع محليًا');
            },

            saveMaterialsLocal() {
              this.captureMaterials();
              this.renderMaterials();
              this.status('تم حفظ الخامات محليًا');
            },

            saveAccessoriesLocal() {
              this.captureAccessories();
              this.renderAccessories();
              this.status('تم حفظ الإكسسوارات محليًا');
            },

            saveHandlesLocal() {
              this.captureHandles();
              this.renderHandles();
              this.status('تم حفظ المقابض محليًا');
            },

            saveAll() {
              if (!this.data) return;
              this.captureAllEdits();
              if (window.sketchup && window.sketchup.mh_save_all) {
                window.sketchup.mh_save_all(JSON.stringify(this.data));
                this.status('تم إرسال التعديلات للحفظ');
              }
            },

            exportJson() {
              if (window.sketchup && window.sketchup.mh_export_json) {
                window.sketchup.mh_export_json('1');
              }
            },

            importJson() {
              if (window.sketchup && window.sketchup.mh_import_json) {
                window.sketchup.mh_import_json('1');
              }
            },

            resetDefaults() {
              if (!confirm('هل تريد إعادة ضبط البيانات الافتراضية؟')) return;
              if (window.sketchup && window.sketchup.mh_reset_defaults) {
                window.sketchup.mh_reset_defaults('1');
              }
            },

            set(path, value) {
              const keys = path.replace(/\[(\d+)\]/g, '.$1').split('.');
              let ref = this.data;
              for (let i = 0; i < keys.length - 1; i++) {
                ref = ref[keys[i]];
              }
              ref[keys[keys.length - 1]] = value;
            },

            removeFrom(listName, index) {
              this.captureAllEdits();
              if (!confirm('حذف العنصر؟')) return;
              this.data[listName].splice(index, 1);
              this.render();
            },

            materialGroupDefs() {
              return [
                { key: 'carcass', label: 'خامة الشاسيه' },
                { key: 'door', label: 'خامة الضلفة' },
                { key: 'back', label: 'خامة الظهر' }
              ];
            },

            groupedCustomMaterialGroups() {
              const reserved = this.materialGroupDefs().map(g => g.key);
              const map = {};
              (this.data.materials || []).forEach(m => {
                const key = (m.group || '').trim();
                if (!key || reserved.includes(key)) return;
                if (!map[key]) {
                  map[key] = {
                    key,
                    label: (m.group_label || key).trim()
                  };
                }
              });
              return Object.values(map);
            },

            addMaterial(group='carcass', label='خامة الشاسيه') {
              this.captureMaterials();
              const id = this.nextId(this.data.materials);
              this.data.materials.push({
                id,
                name: 'خامة جديدة',
                code: '',
                group,
                group_label: label,
                thickness: '',
                pricing_type: '',
                price: 0,
                active: true
              });
              this.render();
            },

            addCustomMaterialGroup() {
              const label = prompt('اكتب اسم مجموعة الخامة الجديدة');
              if (!label) return;
              const cleanLabel = String(label).trim();
              if (!cleanLabel) return;
              const group = 'custom_' + cleanLabel.replace(/\s+/g, '_').replace(/[^\w\u0600-\u06FF_]/g, '').toLowerCase();
              this.addMaterial(group, cleanLabel);
            },

            addAccessory() {
              this.captureAccessories();
              const id = this.nextId(this.data.accessories);
              this.data.accessories.push({ id, name: 'إكسسوار تجاري جديد', library_name: '', code: 'ACC-' + String(id).padStart(3, '0'), kind: '', pricing_type: 'سعر ثابت', price: 0, active: true });
              this.render();
            },

            addHandle() {
              this.captureHandles();
              const id = this.nextId(this.data.handles);
              this.data.handles.push({ id, name: 'مقبض تجاري جديد', library_name: '', code: 'HAN-' + String(id).padStart(3, '0'), kind: '', pricing_type: 'سعر ثابت', price: 0, active: true });
              this.render();
            },

            addReviewRule() {
              const id = this.nextId(this.data.review_rules);
              this.data.review_rules.push({ id, scope: 'category', category: 'base', field_key: 'assembly_method', expected_value: 'جنب على القاعدة', rule_type: 'mismatch', message: 'قاعدة مراجعة جديدة' });
              this.render();
            },

            addUnit() {
              this.captureAllEdits();
              const id = this.nextId(this.data.units);
              this.data.units.push({
                id,
                library_name: 'اسم وحدة المكتبة ' + id,
                category: 'base',
                category_label: 'وحدات سفلية',
                notes: '',
                items: []
              });
              this.activeUnitIndex = this.data.units.length - 1;
              this.render();
            },

            addUnitItem(unitIndex) {
              this.captureUnitCard(unitIndex);
              this.captureUnitItem(unitIndex);
              const unit = this.data.units[unitIndex];
              if (!unit) return;
              unit.items = Array.isArray(unit.items) ? unit.items : [];
              const newId = this.nextId(unit.items);
              unit.items.push({
                id: newId,
                commercial_name: 'بند جديد',
                code: '',
                width: 50,
                depth: 0,
                height: 0,
                carcass_material: '',
                door_material: '',
                back_material: '',
                assembly_method: '',
                counter_type: '',
                counter_thickness: '',
                back_thickness: '',
                drawers_count: 0,
                handle_name: '',
                handle_items: [],
                accessory_name: '',
                accessory_items: [],
                has_accessory: false,
                visible_side: 0,
                shelves_count: 0,
                ignore_shelf: false,
                fixed_price: 0,
                notes: ''
              });
              this.render();
            },

            removeUnitItem(unitIndex, itemIndex) {
              this.captureUnitItem(unitIndex);
              if (!confirm('حذف البند؟')) return;
              const unit = this.data.units[unitIndex];
              if (!unit || !Array.isArray(unit.items)) return;
              unit.items.splice(itemIndex, 1);
              this.render();
            },

            duplicateUnitItem(unitIndex, itemIndex) {
              this.captureUnitItem(unitIndex);
              const unit = this.data.units[unitIndex];
              if (!unit || !Array.isArray(unit.items)) return;
              const sourceItem = unit.items[itemIndex];
              if (!sourceItem) return;
              const newItem = JSON.parse(JSON.stringify(sourceItem));
              newItem.id = this.nextId(unit.items);
              newItem.code = '';
              unit.items.splice(itemIndex + 1, 0, newItem);
              this.renderUnits();
              this.status('تم تكرار البند بدون كود الوحدة');
            },

            isDuplicateUnitCode(code, unitIndex=this.activeUnitIndex, itemIndex=null) {
              const normalized = String(code || '').trim().toLowerCase();
              if (!normalized) return false;
              const unit = (this.data.units || [])[unitIndex];
              if (!unit || !Array.isArray(unit.items)) return false;
              return unit.items.some((item, i) => {
                if (itemIndex !== null && i === itemIndex) return false;
                return String(item.code || '').trim().toLowerCase() === normalized;
              });
            },

            selectUnit(index) {
              this.captureUnitCard(this.activeUnitIndex);
              this.captureUnitItem(this.activeUnitIndex);
              this.activeUnitIndex = index;
              this.renderUnits();
            },

            nextId(list) {
              return Math.max(0, ...list.map(item => Number(item.id || 0))) + 1;
            },

            onInput(path, el, type='text') {
              let value;
              if (type === 'checkbox') value = !!el.checked;
              else if (type === 'number') value = Number(el.value || 0);
              else if (type === 'select-bool') value = String(el.value) === 'true';
              else value = el.value;
              this.set(path, value);
              this.status('تم تعديل البيانات محليًا - احفظ للتثبيت');
            },

            parseWidths(unitIndex, value) {
              const arr = String(value).split(',').map(v => Number(v.trim())).filter(v => !Number.isNaN(v));
              this.data.units[unitIndex].widths = arr;
              this.status('تم تعديل المقاسات');
            },

            parseAllowed(unitIndex, fieldIndex, value) {
              const arr = String(value).split(',').map(v => v.trim()).filter(Boolean);
              this.data.units[unitIndex].fields[fieldIndex].allowed = arr;
              this.status('تم تعديل القيم المسموحة');
            },

            unitFilterOptions() {
              return [
                { value: 'all', label: 'الكل' },
                { value: 'base', label: 'وحدات سفلية' },
                { value: 'wall', label: 'وحدات علوية' },
                { value: 'tall', label: 'دواليب' }
              ];
            },

            unitMatchesFilter(unit, filterValue) {
              const value = String(filterValue || 'all');
              if (value === 'all') return true;
              return String(unit?.category || '') === value;
            },

            setUnitFilter(value) {
              this.unitFilter = String(value || 'all');
              this.renderUnits();
            },

            unitItemFilterDefs() {
              return [
                { value: '', label: 'بدون تصفية' },
                { value: 'width', label: 'عرض الوحدة' },
                { value: 'assembly_method', label: 'طريقة التجميع' },
                { value: 'carcass_material', label: 'خامة الشاسيه' },
                { value: 'door_material', label: 'خامة الضلفة' },
                { value: 'back_material', label: 'خامة الظهر' },
                { value: 'accessory', label: 'نوع الإكسسوار' },
                { value: 'handle', label: 'نوع المقبض' }
              ];
            },

            getUnitItemFilterState(unitIndex=this.activeUnitIndex) {
              if (!this.unitItemFilters || typeof this.unitItemFilters !== 'object') this.unitItemFilters = {};
              const key = String(unitIndex);
              if (!this.unitItemFilters[key]) this.unitItemFilters[key] = { field: '', value: '' };
              return this.unitItemFilters[key];
            },

            setUnitItemFilterField(unitIndex, field) {
              this.captureUnitCard(unitIndex);
              this.captureUnitItem(unitIndex);
              const state = this.getUnitItemFilterState(unitIndex);
              state.field = String(field || '');
              state.value = '';
              this.renderUnits();
              this.status(state.field ? 'تم اختيار نوع تصفية البنود' : 'تم إلغاء تصفية البنود');
            },

            setUnitItemFilterValue(unitIndex, value) {
              this.captureUnitCard(unitIndex);
              this.captureUnitItem(unitIndex);
              const state = this.getUnitItemFilterState(unitIndex);
              state.value = String(value || '');
              this.renderUnits();
              this.status(state.value ? 'تم تطبيق تصفية البنود داخل الوحدة' : 'تم عرض كل البنود داخل الوحدة');
            },

            clearUnitItemFilter(unitIndex=this.activeUnitIndex) {
              this.captureUnitCard(unitIndex);
              this.captureUnitItem(unitIndex);
              const state = this.getUnitItemFilterState(unitIndex);
              state.field = '';
              state.value = '';
              this.renderUnits();
              this.status('تم مسح تصفية البنود داخل الوحدة');
            },

            unitItemFieldValues(item, field) {
              const clean = (value) => String(value ?? '').trim();
              if (!item) return [];
              switch (String(field || '')) {
                case 'width': {
                  const n = Number(item.width || 0);
                  return n > 0 ? [String(n)] : [];
                }
                case 'assembly_method':
                  return clean(item.assembly_method) ? [clean(item.assembly_method)] : [];
                case 'carcass_material':
                  return clean(item.carcass_material) ? [clean(item.carcass_material)] : [];
                case 'door_material':
                  return clean(item.door_material) ? [clean(item.door_material)] : [];
                case 'back_material':
                  return clean(item.back_material) ? [clean(item.back_material)] : [];
                case 'accessory': {
                  const rows = this.normalizeAccessoryItems(item).map(row => clean(row.name)).filter(Boolean);
                  return rows.length ? rows : ['بدون إكسسوارات'];
                }
                case 'handle': {
                  const rows = this.normalizeHandleItems(item).map(row => clean(row.name)).filter(Boolean);
                  return rows.length ? rows : ['بدون مقبض'];
                }
                default:
                  return [];
              }
            },

            getUnitItemFilterValues(unit, field) {
              const values = [];
              if (!unit || !field) return values;
              (unit.items || []).forEach(item => {
                this.unitItemFieldValues(item, field).forEach(value => {
                  if (value && !values.includes(value)) values.push(value);
                });
              });
              if (field === 'width') {
                return values.sort((a, b) => Number(a) - Number(b));
              }
              return values.sort((a, b) => a.localeCompare(b, 'ar'));
            },

            unitItemMatchesFilter(item, state) {
              const field = state && state.field ? String(state.field) : '';
              const value = state && state.value ? String(state.value) : '';
              if (!field || !value) return true;
              return this.unitItemFieldValues(item, field).includes(value);
            },


            printText(value, fallback='—') {
              const text = String(value ?? '').trim();
              return text ? this.esc(text) : fallback;
            },

            printItemsSummary(rows, emptyLabel) {
              const list = Array.isArray(rows) ? rows : [];
              if (!list.length) return emptyLabel || '—';
              return list.map(row => {
                const name = this.printText(row && row.name ? row.name : '', '—');
                const qty = Number(row && row.qty ? row.qty : 0);
                return `${name} × ${qty}`;
              }).join('<br>');
            },

            buildUnitPrintHtml(unit, showPrices=false) {
              const unitName = this.printText(unit && unit.library_name ? unit.library_name : 'وحدة مكتبة', 'وحدة مكتبة');
              const items = (unit && Array.isArray(unit.items)) ? unit.items : [];
              const today = new Date().toLocaleDateString('ar-EG');
              const priceHeaders = showPrices ? '<th>السعر الثابت</th><th>سعر المقبض</th><th>الإكسسوارات</th><th>الإجمالي</th>' : '';
              const rows = items.map((item, index) => {
                const handles = this.printItemsSummary(this.normalizeHandleItems(item), '—');
                const accessories = this.printItemsSummary(this.normalizeAccessoryItems(item), 'بدون');
                const priceCells = showPrices ? `
                  <td>${this.money(item.fixed_price || 0)}</td>
                  <td>${this.money(this.handlePrice(item))}</td>
                  <td>${this.money(this.accessorySubtotal(item))}</td>
                  <td><b>${this.money(this.itemTotalPrice(item))}</b></td>
                ` : '';
                return `
                  <tr>
                    <td>${index + 1}</td>
                    <td>${this.printText(item.code)}</td>
                    <td class="unit-name-cell">${this.printText(item.commercial_name)}</td>
                    <td>${this.printText(item.width)}</td>
                    <td>${this.printText(item.depth)}</td>
                    <td>${this.printText(item.height)}</td>
                    <td>${this.printText(item.assembly_method)}</td>
                    <td>${this.printText(item.carcass_material)}</td>
                    <td>${this.printText(item.door_material)}</td>
                    <td>${this.printText(item.back_material)}</td>
                    <td>${this.printText(item.counter_type)}</td>
                    <td>${this.printText(item.counter_thickness)}</td>
                    <td>${this.printText(item.back_thickness)}</td>
                    <td>${this.printText(item.drawers_count)}</td>
                    <td>${handles}</td>
                    <td>${accessories}</td>
                    <td>${Number(item.visible_side || 0) === 0 ? 'لا' : this.printText(item.visible_side)}</td>
                    <td>${this.printText(item.shelves_count)}</td>
                    ${priceCells}
                  </tr>
                `;
              }).join('');

              const colspan = showPrices ? 22 : 18;
              return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<title>طباعة ${unitName}</title>
<style>
  @page { size: A4 landscape; margin: 8mm; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: Tahoma, Arial, sans-serif; color: #111827; background: #fff; direction: rtl; }
  .print-page { padding: 8px; }
  .print-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; margin-bottom: 12px; border: 1px solid #d8dee8; border-radius: 14px; padding: 12px; background: #f8fafc; }
  .brand { font-size: 12px; color: #64748b; font-weight: 700; }
  h1 { margin: 0 0 6px; font-size: 22px; color: #0f172a; }
  .meta { color: #475569; font-size: 12px; line-height: 1.8; }
  .info-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 12px; }
  .info-box { border: 1px solid #d8dee8; border-radius: 12px; padding: 10px; min-height: 54px; }
  .info-box .label { color: #64748b; font-size: 12px; margin-bottom: 6px; font-weight: 700; }
  .info-box .value { font-size: 15px; font-weight: 800; }
  table { width: 100%; border-collapse: collapse; table-layout: fixed; }
  th, td { border: 1px solid #d8dee8; padding: 7px 6px; text-align: center; vertical-align: middle; font-size: 11px; line-height: 1.45; word-break: break-word; }
  th { background: #f1f5f9; color: #0f172a; font-size: 11px; font-weight: 900; }
  tbody tr:nth-child(even) td { background: #fcfcfd; }
  .unit-name-cell { font-weight: 800; }
  .notes { text-align: right; }
  .footer { margin-top: 10px; display: flex; justify-content: space-between; color: #64748b; font-size: 11px; }
  .no-print { margin-bottom: 10px; display: flex; gap: 8px; }
  .no-print button { border: 0; border-radius: 10px; padding: 9px 14px; cursor: pointer; font-weight: 800; }
  .primary { background: #2563eb; color: #fff; }
  .secondary { background: #e5e7eb; color: #111827; }
  @media print { .no-print { display: none; } body { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
</style>
</head>
<body>
  <div class="print-page">
    <div class="no-print">
      <button class="primary" onclick="window.print()">طباعة</button>
      <button class="secondary" onclick="window.close()">إغلاق</button>
    </div>
    <div class="print-header">
      <div>
        <div class="brand">MHDESIGN Pricing Admin</div>
        <h1>${unitName}</h1>
        <div class="meta">شيت فني لبنود الوحدة داخل قاعدة التسعير</div>
      </div>
      <div class="meta">تاريخ الطباعة: ${today}<br>عدد البنود: ${items.length}<br>${showPrices ? 'الأسعار ظاهرة' : 'بدون أسعار'}</div>
    </div>
    <table>
      <thead>
        <tr>
          <th style="width:34px;">#</th>
          <th style="width:55px;">كود</th>
          <th style="width:110px;">اسم الوحدة</th>
          <th>العرض</th>
          <th>العمق</th>
          <th>الارتفاع</th>
          <th style="width:86px;">طريقة التجميع</th>
          <th>خامة الشاسيه</th>
          <th>خامة الضلفة</th>
          <th>خامة الظهر</th>
          <th>نوع القرصة</th>
          <th>تخانة الكونتر</th>
          <th>تخانة الظهر</th>
          <th>الأدراج</th>
          <th style="width:120px;">نوع المقبض</th>
          <th style="width:120px;">الإكسسوارات</th>
          <th>الجنب الظاهر</th>
          <th>عدد الرفوف</th>
          ${priceHeaders}
        </tr>
      </thead>
      <tbody>
        ${rows || `<tr><td colspan="${colspan}">لا توجد بنود داخل هذه الوحدة.</td></tr>`}
      </tbody>
    </table>
    <div class="footer">
      <div>تم تصميم هذه الإضافة بواسطة MHDESIGN</div>
      <div>mhdesign-eg.com - +201100211340</div>
    </div>
  </div>
</body>
</html>`;
            },

            printUnit(unitIndex=this.activeUnitIndex) {
              this.captureUnitCard(unitIndex);
              this.captureUnitItem(unitIndex);
              const unit = (this.data.units || [])[unitIndex];
              if (!unit) {
                alert('لم يتم العثور على الوحدة للطباعة.');
                return;
              }
              const showPrices = this.readChecked(`unit_print_show_prices_${unitIndex}`, false);
              const html = this.buildUnitPrintHtml(unit, showPrices);
              let frame = document.getElementById('mh_unit_print_frame');
              if (frame && frame.parentNode) frame.parentNode.removeChild(frame);

              frame = document.createElement('iframe');
              frame.id = 'mh_unit_print_frame';
              frame.setAttribute('title', 'MHDESIGN Unit Print');
              frame.style.position = 'fixed';
              frame.style.left = '0';
              frame.style.bottom = '0';
              frame.style.width = '1px';
              frame.style.height = '1px';
              frame.style.opacity = '0';
              frame.style.pointerEvents = 'none';
              frame.style.border = '0';
              document.body.appendChild(frame);

              const doc = frame.contentWindow || frame.contentDocument;
              const frameDoc = frame.contentDocument || (doc && doc.document);
              if (!frameDoc) {
                alert('تعذر تجهيز صفحة الطباعة داخل نفس النافذة.');
                return;
              }

              frameDoc.open();
              frameDoc.write(html);
              frameDoc.close();
              this.status('تم تجهيز شيت الطباعة');

              setTimeout(() => {
                try {
                  frame.contentWindow.focus();
                  frame.contentWindow.print();
                  this.status('تم إرسال شيت الوحدة للطباعة');
                } catch (e) {
                  console.error('Print Error:', e);
                  alert('تعذر تنفيذ أمر الطباعة. جرّب الضغط على حفظ كل التعديلات ثم افتح اللوحة مرة أخرى.');
                }
              }, 450);
            },

            openHandlePicker(unitIndex, itemIndex) {
              this.captureUnitItem(unitIndex, itemIndex);
              this.handlePicker = { unitIndex, itemIndex };
              const unit = (this.data.units || [])[unitIndex];
              const item = unit && Array.isArray(unit.items) ? unit.items[itemIndex] : null;
              if (!item) return;

              const body = document.getElementById('handle_modal_body');
              const subtitle = document.getElementById('handle_modal_subtitle');
              const current = {};
              this.normalizeHandleItems(item).forEach(row => { current[row.name] = Number(row.qty || 0); });

              if (subtitle) {
                subtitle.textContent = `البند: ${item.commercial_name || ('بند ' + (itemIndex + 1))}`;
              }

              const activeHandles = (this.data.handles || []).filter(h => h.active !== false);
              if (!body) {
                alert('تعذر فتح نافذة المقابض: عنصر النافذة غير موجود.');
                return;
              }
              if (!activeHandles.length) {
                body.innerHTML = '<div class="empty-state">لا توجد مقابض مفعلة. أضف المقابض من قسم المقابض أولاً.</div>';
              } else {
                body.innerHTML = activeHandles.map((h, i) => {
                  const qty = Number(current[h.name] || 0);
                  return `
                    <div class="accessory-qty-row">
                      <div>
                        <div class="acc-name">${this.esc(h.name || '')}</div>
                        <div class="acc-meta">داخل المكتبة: ${this.esc(h.library_name || h.kind || 'غير مرتبط')} • الكود: ${this.esc(h.code || '—')} • ${this.isHandleMeterPricing(h) ? 'بالمتر' : 'سعر ثابت'} • السعر: ${this.money(h.price || 0)}</div>
                      </div>
                      <div class="field" style="margin:0;">
                        <label>العدد</label>
                        <input id="modal_handle_qty_${i}" type="number" min="0" step="1" value="${qty}" data-handle-name="${this.esc(h.name || '')}">
                      </div>
                      <div class="small">الإجمالي: <b>${this.money(this.handleRowPrice(h, item, qty))}</b></div>
                    </div>
                  `;
                }).join('');
              }

              const backdrop = document.getElementById('handle_modal_backdrop');
              if (backdrop) backdrop.classList.add('show');
            },

            closeHandlePicker() {
              const backdrop = document.getElementById('handle_modal_backdrop');
              if (backdrop) backdrop.classList.remove('show');
              this.handlePicker = null;
            },

            clearHandlePicker() {
              document.querySelectorAll('#handle_modal_body input[type="number"]').forEach(input => {
                input.value = 0;
              });
              this.status('تم مسح كميات المقابض داخل النافذة');
            },

            applyHandlePicker() {
              const state = this.handlePicker;
              if (!state) return;
              const unit = (this.data.units || [])[state.unitIndex];
              const item = unit && Array.isArray(unit.items) ? unit.items[state.itemIndex] : null;
              if (!item) return;

              const rows = [];
              document.querySelectorAll('#handle_modal_body input[type="number"]').forEach(input => {
                const name = input.dataset.handleName || '';
                const qty = Math.max(0, Number(input.value || 0));
                if (name && qty > 0) rows.push({ name, qty });
              });

              item.handle_items = rows;
              item.handle_name = rows.map(row => row.name).join(', ');
              this.closeHandlePicker();
              this.renderUnits();
              this.status('تم تطبيق المقابض والكميات على البند');
            },

            openAccessoryPicker(unitIndex, itemIndex) {
              this.captureUnitItem(unitIndex, itemIndex);
              this.accessoryPicker = { unitIndex, itemIndex };
              const unit = (this.data.units || [])[unitIndex];
              const item = unit && Array.isArray(unit.items) ? unit.items[itemIndex] : null;
              if (!item) return;

              const body = document.getElementById('accessory_modal_body');
              const subtitle = document.getElementById('accessory_modal_subtitle');
              const current = {};
              this.normalizeAccessoryItems(item).forEach(row => { current[row.name] = Number(row.qty || 0); });

              if (subtitle) {
                subtitle.textContent = `البند: ${item.commercial_name || ('بند ' + (itemIndex + 1))}`;
              }

              const activeAccessories = (this.data.accessories || []).filter(a => a.active !== false);
              if (!activeAccessories.length) {
                body.innerHTML = '<div class="empty-state">لا توجد إكسسوارات مفعلة. أضف الإكسسوارات من قسم الإكسسوارات أولاً.</div>';
              } else {
                body.innerHTML = activeAccessories.map((acc, i) => {
                  const qty = Number(current[acc.name] || 0);
                  return `
                    <div class="accessory-qty-row">
                      <div>
                        <div class="acc-name">${this.esc(acc.name || '')}</div>
                        <div class="acc-meta">داخل المكتبة: ${this.esc(acc.library_name || acc.kind || 'غير مرتبط')} • الكود: ${this.esc(acc.code || '—')} • السعر: ${this.money(acc.price || 0)}</div>
                      </div>
                      <div class="field" style="margin:0;">
                        <label>العدد</label>
                        <input id="modal_acc_qty_${i}" type="number" min="0" step="1" value="${qty}" data-acc-name="${this.esc(acc.name || '')}">
                      </div>
                      <div class="small">الإجمالي: <b>${this.money(Number(acc.price || 0) * qty)}</b></div>
                    </div>
                  `;
                }).join('');
              }

              const backdrop = document.getElementById('accessory_modal_backdrop');
              if (backdrop) backdrop.classList.add('show');
            },

            closeAccessoryPicker() {
              const backdrop = document.getElementById('accessory_modal_backdrop');
              if (backdrop) backdrop.classList.remove('show');
              this.accessoryPicker = null;
            },

            clearAccessoryPicker() {
              document.querySelectorAll('#accessory_modal_body input[type="number"]').forEach(input => {
                input.value = 0;
              });
              this.status('تم مسح كميات الإكسسوارات داخل النافذة');
            },

            applyAccessoryPicker() {
              const state = this.accessoryPicker;
              if (!state) return;
              const unit = (this.data.units || [])[state.unitIndex];
              const item = unit && Array.isArray(unit.items) ? unit.items[state.itemIndex] : null;
              if (!item) return;

              const rows = [];
              document.querySelectorAll('#accessory_modal_body input[type="number"]').forEach(input => {
                const name = input.dataset.accName || '';
                const qty = Math.max(0, Number(input.value || 0));
                if (name && qty > 0) rows.push({ name, qty });
              });

              item.accessory_items = rows;
              item.accessory_name = rows.map(row => row.name).join(', ');
              item.has_accessory = rows.length > 0;
              this.closeAccessoryPicker();
              this.renderUnits();
              this.status('تم تطبيق الإكسسوارات والكميات على البند');
            },

            applyGeneralUnitIncrease() {
              this.captureAllEdits();
              const rawValue = this.readValue('unit_bulk_increase_value', '');
              const amount = Number(rawValue);
              const mode = this.readValue('unit_bulk_increase_type', 'fixed');
              if (rawValue === '' || Number.isNaN(amount)) {
                this.status('اكتب قيمة زيادة صحيحة أولاً');
                return;
              }
              if (amount === 0) {
                this.status('قيمة الزيادة تساوي صفر، لم يتم تعديل الأسعار');
                return;
              }
              if (!confirm('تطبيق الزيادة العامة على كل أسعار بنود الوحدات؟')) return;

              let changed = 0;
              (this.data.units || []).forEach(unit => {
                (unit.items || []).forEach(item => {
                  const current = Number(item.fixed_price || 0);
                  const next = mode === 'percent' ? (current * (1 + (amount / 100.0))) : (current + amount);
                  item.fixed_price = Math.round((next + Number.EPSILON) * 100) / 100;
                  changed += 1;
                });
              });

              this.renderUnits();
              this.status(mode === 'percent'
                ? `تم تطبيق زيادة بنسبة ${amount}% على ${changed} بند`
                : `تم تطبيق زيادة سعر ${amount} على ${changed} بند`);
            },

            render() {
              if (!this.data) return;
              const safe = (fn, panelId) => {
                try {
                  if (panelId && !document.getElementById(panelId)) return;
                  if (typeof this[fn] === 'function') this[fn]();
                } catch (e) {
                  console.error(fn + ' Error:', e);
                  this.status('خطأ في عرض ' + fn + ' - راجع Ruby Console');
                }
              };
              safe('renderDashboard', 'panel-dashboard');
              safe('renderManufacturing', 'panel-manufacturing');
              safe('renderMaterials', 'panel-materials');
              safe('renderAccessories', 'panel-accessories');
              safe('renderHandles', 'panel-handles');
              safe('renderUnits', 'panel-units');
              safe('renderReviews', 'panel-reviews');
              safe('renderRaw', 'panel-raw');
            },

            renderDashboard() {
              const root = document.getElementById('panel-dashboard');
              const d = this.data;
              root.innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">نظرة عامة</h2>
                    <p class="panel-desc">ملخص سريع لقاعدة بيانات التسعير الحالية.</p>
                  </div>
                  <div class="badge info">آخر تحديث: ${d.meta?.updated_at || '—'}</div>
                  <div class="badge success">${this.esc(this.matchingStatus || '')}</div>
                </div>
                <div class="stats">
                  <div class="stat"><div class="k">قواعد التصنيع</div><div class="v">${d.manufacturing_profiles.length}</div></div>
                  <div class="stat"><div class="k">الخامات</div><div class="v">${d.materials.length}</div></div>
                  <div class="stat"><div class="k">الإكسسوارات</div><div class="v">${d.accessories.length}</div></div>
                  <div class="stat"><div class="k">المقابض</div><div class="v">${(d.handles || []).length}</div></div>
                  <div class="stat"><div class="k">كروت وحدات المكتبة</div><div class="v">${d.units.length}</div></div>
                  <div class="stat"><div class="k">بنود الوحدات</div><div class="v">${this.unitItemsCount()}</div></div>
                </div>
              `;
            },

            renderManufacturing() {
              const root = document.getElementById('panel-manufacturing');
              if (!root) return;
              const cards = this.data.manufacturing_profiles.map((item, i) => `
                <div class="card">
                  <h3>${item.label}</h3>
                  <div class="field-grid">
                    <div class="field"><label>التصنيف</label><input id="mfg_category_${i}" type="text" value="${this.esc(item.category)}" oninput="MH.onInput('manufacturing_profiles[${i}].category', this)"></div>
                    <div class="field"><label>اسم الكارت</label><input id="mfg_label_${i}" type="text" value="${this.esc(item.label)}" oninput="MH.onInput('manufacturing_profiles[${i}].label', this)"></div>
                    <div class="field"><label>طريقة التجميع</label><input id="mfg_assembly_method_${i}" type="text" value="${this.esc(item.assembly_method)}" oninput="MH.onInput('manufacturing_profiles[${i}].assembly_method', this)"></div>
                    <div class="field"><label>نوع الظهر</label><input id="mfg_back_type_${i}" type="text" value="${this.esc(item.back_type)}" oninput="MH.onInput('manufacturing_profiles[${i}].back_type', this)"></div>
                    <div class="field"><label>سمك الظهر</label><input id="mfg_back_thickness_${i}" type="text" value="${this.esc(item.back_thickness)}" oninput="MH.onInput('manufacturing_profiles[${i}].back_thickness', this)"></div>
                    <div class="field"><label>نوع الكونتر</label><input id="mfg_counter_type_${i}" type="text" value="${this.esc(item.counter_type)}" oninput="MH.onInput('manufacturing_profiles[${i}].counter_type', this)"></div>
                    <div class="field"><label>سمك الكونتر</label><input id="mfg_counter_thickness_${i}" type="text" value="${this.esc(item.counter_thickness)}" oninput="MH.onInput('manufacturing_profiles[${i}].counter_thickness', this)"></div>
                    <div class="field"><label>سياسة الجنب الظاهر</label><input id="mfg_visible_side_policy_${i}" type="text" value="${this.esc(item.visible_side_policy)}" oninput="MH.onInput('manufacturing_profiles[${i}].visible_side_policy', this)"></div>
                    <div class="field"><label>سياسة الأرفف</label><input id="mfg_shelf_policy_${i}" type="text" value="${this.esc(item.shelf_policy)}" oninput="MH.onInput('manufacturing_profiles[${i}].shelf_policy', this)"></div>
                    <div class="field" style="grid-column:1/-1"><label>ملاحظات</label><textarea id="mfg_notes_${i}" oninput="MH.onInput('manufacturing_profiles[${i}].notes', this)">${this.esc(item.notes || '')}</textarea></div>
                  </div>
                </div>
              `).join('');

              root.innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">قواعد التصنيع</h2>
                    <p class="panel-desc">القواعد العامة على مستوى الوحدات السفلية والعلوية والدواليب.</p>
                  </div>
                  <div class="toolbar"><button class="btn white" onclick="MH.saveManufacturingLocal()">حفظ قواعد التصنيع</button></div>
                </div>
                <div class="grid cards-3">${cards}</div>
              `;
            },

            renderMaterials() {
              const defs = [...this.materialGroupDefs(), ...this.groupedCustomMaterialGroups()];

              const cardHtml = defs.map(def => {
                const groupItems = (this.data.materials || []).map((m, i) => ({ m, i }))
                  .filter(row => row.m.group === def.key)
                  .map(row => `
                    <div class="material-row">
                      <div class="material-name">
                        <input id="mat_name_${row.i}" type="text" value="${this.esc(row.m.name)}" placeholder="اسم الخامة" oninput="MH.onInput('materials[${row.i}].name', this)">
                      </div>
                      <label class="material-toggle">
                        <input id="mat_active_${row.i}" type="checkbox" ${row.m.active !== false ? 'checked' : ''} onchange="MH.onInput('materials[${row.i}].active', this, 'checkbox')">
                        <span>مفعل</span>
                      </label>
                      <div class="material-actions">
                        <button class="mini-btn delete" onclick="MH.removeFrom('materials', ${row.i})">حذف</button>
                      </div>
                    </div>
                  `).join('');

                return `
                  <div class="card">
                    <div class="panel-head" style="margin-bottom:12px;">
                      <div>
                        <h3 style="margin:0;">${this.esc(def.label)}</h3>
                        <div class="small">أضف أسماء الخامات التي ستظهر داخل اختيارات الوحدة.</div>
                      </div>
                      <div class="toolbar">
                        <button class="btn primary" onclick="MH.addMaterial('${this.esc(def.key)}', '${this.esc(def.label)}')">إضافة خامة</button>
                      </div>
                    </div>

                    <div class="material-stack">
                      ${groupItems || `<div class="empty-state" style="padding:18px;">لا توجد خامات مسجلة في هذا القسم.</div>`}
                    </div>
                  </div>
                `;
              }).join('');

              document.getElementById('panel-materials').innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">الخامات</h2>
                    <p class="panel-desc">الخامات مقسمة بوضوح حسب نوعها، واسم الخامة فقط هو الذي سيظهر داخل اختيارات الوحدات.</p>
                  </div>
                  <div class="toolbar"><button class="btn white" onclick="MH.saveMaterialsLocal()">حفظ الخامات</button><button class="btn secondary" onclick="MH.addCustomMaterialGroup()">إضافة تكوين جديد</button></div>
                </div>
                <div class="grid cards-3">${cardHtml}</div>
              `;
            },

            uniqueClean(list) {
              const out = [];
              (list || []).forEach(v => {
                const t = String(v || '').trim();
                if (t && !out.includes(t)) out.push(t);
              });
              return out;
            },

            accessoryLibraryNames() {
              const fromMatching = (this.libraryNames && this.libraryNames.accessories) ? this.libraryNames.accessories : [];
              if (fromMatching.length) return this.uniqueClean(fromMatching);
              const defaults = [
                'مطبعية عادية', 'مطبقيه عاديه',
                'مجرة جانبي', 'مجره جانبي',
                'مجرة سفلي', 'مجره سفلي',
                'مفصلة سوفت'
              ];
              const fromDb = [];
              (this.data.accessories || []).forEach(a => {
                fromDb.push(a.library_name || a.kind || '');
              });
              (this.data.units || []).forEach(u => (u.items || []).forEach(item => {
                this.normalizeAccessoryItems(item).forEach(row => fromDb.push(row.library_name || row.name || ''));
              }));
              return this.uniqueClean([...defaults, ...fromDb]);
            },

            handleLibraryNames() {
              const fromMatching = (this.libraryNames && this.libraryNames.handles) ? this.libraryNames.handles : [];
              if (fromMatching.length) return this.uniqueClean(fromMatching);
              const defaults = [
                'مقبض بلت ان سفلي حرف L',
                'مقبض بلت ان سفلي حرف سي',
                'مقبض بلت ان علوي حرف ال',
                'مقبض عادي او تاتش',
                'مقبض بلت ان حفر سفلي',
                'مقبض بلت ان حفر علوي'
              ];
              const fromDb = [];
              (this.data.handles || []).forEach(h => {
                fromDb.push(h.library_name || h.kind || '');
              });
              (this.data.units || []).forEach(u => (u.items || []).forEach(item => {
                this.normalizeHandleItems(item).forEach(row => fromDb.push(row.library_name || row.name || ''));
              }));
              return this.uniqueClean([...defaults, ...fromDb]);
            },

            renderLibraryNameOptions(items, selected) {
              const sel = String(selected || '').trim();
              const values = this.uniqueClean([sel, ...(items || [])]);
              const opts = [`<option value="" ${sel === '' ? 'selected' : ''}>غير مرتبط بمسمى داخل المكتبة</option>`];
              values.forEach(v => {
                if (!v) return;
                opts.push(`<option value="${this.esc(v)}" ${v === sel ? 'selected' : ''}>${this.esc(v)}</option>`);
              });
              return opts.join('');
            },

            renderAccessories() {
              const accLibNames = this.accessoryLibraryNames();
              const rows = this.data.accessories.map((a, i) => `
                <tr>
                  <td>${a.id}</td>
                  <td><input id="acc_name_${i}" type="text" value="${this.esc(a.name)}" oninput="MH.onInput('accessories[${i}].name', this)"></td>
                  <td><input id="acc_code_${i}" type="text" value="${this.esc(a.code)}" oninput="MH.onInput('accessories[${i}].code', this)"></td>
                  <td><select id="acc_library_name_${i}" onchange="MH.onInput('accessories[${i}].library_name', this); MH.set('accessories[${i}].kind', this.value)">${this.renderLibraryNameOptions(accLibNames, a.library_name || a.kind || '')}</select></td>
                  <td><input id="acc_pricing_${i}" type="text" value="${this.esc(a.pricing_type)}" oninput="MH.onInput('accessories[${i}].pricing_type', this)"></td>
                  <td><input id="acc_price_${i}" type="number" value="${Number(a.price||0)}" oninput="MH.onInput('accessories[${i}].price', this, 'number')"></td>
                  <td><input id="acc_active_${i}" type="checkbox" ${a.active ? 'checked' : ''} onchange="MH.onInput('accessories[${i}].active', this, 'checkbox')"></td>
                  <td><button class="mini-btn delete" onclick="MH.removeFrom('accessories', ${i})">حذف</button></td>
                </tr>
              `).join('');

              document.getElementById('panel-accessories').innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">الإكسسوارات</h2>
                    <p class="panel-desc">اكتب الاسم التجاري الذي سيظهر في التسعير، واربطه بمسمى الإكسسوار داخل المكتبة للمطابقة. يمكن ترك الربط فارغًا لو الإكسسوار يدوي فقط.</p>
                  </div>
                  <div class="toolbar"><button class="btn white" onclick="MH.saveAccessoriesLocal()">حفظ الإكسسوارات</button><button class="btn primary" onclick="MH.addAccessory()">إضافة إكسسوار</button></div>
                </div>
                <div class="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>#</th><th>الاسم التجاري</th><th>الكود</th><th>الاسم داخل المكتبة</th><th>نوع التسعير</th><th>السعر / سعر المتر</th><th>مفعل</th><th></th>
                      </tr>
                    </thead>
                    <tbody>${rows}</tbody>
                  </table>
                </div>
              `;
            },


            renderHandles() {
              const handleLibNames = this.handleLibraryNames();
              const rows = (this.data.handles || []).map((h, i) => `
                <tr>
                  <td>${h.id}</td>
                  <td><input id="han_name_${i}" type="text" value="${this.esc(h.name)}" oninput="MH.onInput('handles[${i}].name', this)"></td>
                  <td><input id="han_code_${i}" type="text" value="${this.esc(h.code)}" oninput="MH.onInput('handles[${i}].code', this)"></td>
                  <td><select id="han_library_name_${i}" onchange="MH.onInput('handles[${i}].library_name', this); MH.set('handles[${i}].kind', this.value)">${this.renderLibraryNameOptions(handleLibNames, h.library_name || h.kind || '')}</select></td>
                  <td>
                    <select id="han_pricing_${i}" onchange="MH.onInput('handles[${i}].pricing_type', this)">
                      <option value="سعر ثابت" ${String(h.pricing_type || 'سعر ثابت') === 'سعر ثابت' || String(h.pricing_type || '') === 'إضافة ثابتة' ? 'selected' : ''}>سعر ثابت</option>
                      <option value="بالمتر" ${String(h.pricing_type || '') === 'بالمتر' || String(h.pricing_type || '') === 'سعر بالمتر' ? 'selected' : ''}>بالمتر</option>
                    </select>
                  </td>
                  <td><input id="han_price_${i}" type="number" value="${Number(h.price||0)}" oninput="MH.onInput('handles[${i}].price', this, 'number')"></td>
                  <td><input id="han_active_${i}" type="checkbox" ${h.active ? 'checked' : ''} onchange="MH.onInput('handles[${i}].active', this, 'checkbox')"></td>
                  <td><button class="mini-btn delete" onclick="MH.removeFrom('handles', ${i})">حذف</button></td>
                </tr>
              `).join('');

              document.getElementById('panel-handles').innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">المقابض</h2>
                    <p class="panel-desc">اكتب الاسم التجاري للمقبض، واربطه بمسمى المقبض داخل المكتبة للمطابقة. نوع التسعير: سعر ثابت أو بالمتر حسب عرض الوحدة × سعر المتر × العدد.</p>
                  </div>
                  <div class="toolbar"><button class="btn white" onclick="MH.saveHandlesLocal()">حفظ المقابض</button><button class="btn primary" onclick="MH.addHandle()">إضافة مقبض</button></div>
                </div>
                <div class="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>#</th><th>الاسم التجاري</th><th>الكود</th><th>الاسم داخل المكتبة</th><th>نوع التسعير</th><th>السعر / سعر المتر</th><th>مفعل</th><th></th>
                      </tr>
                    </thead>
                    <tbody>${rows || '<tr><td colspan="8" class="empty-table">لا توجد مقابض.</td></tr>'}</tbody>
                  </table>
                </div>
              `;
            },

            renderUnits() {
              const root = document.getElementById('panel-units');
              const units = this.data.units || [];
              if (typeof this.activeUnitIndex !== 'number') this.activeUnitIndex = 0;
              if (!this.unitFilter) this.unitFilter = 'all';

              const filteredUnits = units
                .map((unit, index) => ({ unit, index }))
                .filter(entry => this.unitMatchesFilter(entry.unit, this.unitFilter));

              if (this.activeUnitIndex >= units.length) this.activeUnitIndex = Math.max(0, units.length - 1);
              const activeEntry = filteredUnits.find(entry => entry.index === this.activeUnitIndex) || filteredUnits[0] || null;
              if (activeEntry) this.activeUnitIndex = activeEntry.index;
              const activeUnit = activeEntry ? activeEntry.unit : null;

              const filterOptionsHtml = this.unitFilterOptions().map(opt => `
                <option value="${opt.value}" ${this.unitFilter === opt.value ? 'selected' : ''}>${opt.label}</option>
              `).join('');

              const listHtml = filteredUnits.map(({ unit, index }) => `
                <div class="library-card ${index === this.activeUnitIndex ? 'active' : ''}" onclick="MH.selectUnit(${index})">
                  <div class="name">${this.esc(unit.library_name || ('وحدة مكتبة ' + (index + 1)))}</div>
                  <div class="meta">${this.esc(unit.category_label || unit.category || '')} • ${(unit.items || []).length} بند</div>
                </div>
              `).join('');

              let detailHtml = `<div class="empty-state">لا توجد وحدات مطابقة للتصنيف المختار.</div>`;

              if (activeUnit) {
                const itemFilterState = this.getUnitItemFilterState(this.activeUnitIndex);
                const itemFilterDefs = this.unitItemFilterDefs();
                const itemFilterValues = this.getUnitItemFilterValues(activeUnit, itemFilterState.field);
                if (itemFilterState.value && !itemFilterValues.includes(itemFilterState.value)) {
                  itemFilterState.value = '';
                }

                const itemFilterFieldOptions = itemFilterDefs.map(opt => `
                  <option value="${this.esc(opt.value)}" ${itemFilterState.field === opt.value ? 'selected' : ''}>${this.esc(opt.label)}</option>
                `).join('');

                const itemFilterValueOptions = [
                  `<option value="">${itemFilterState.field ? 'كل القيم' : 'اختر نوع التصفية أولاً'}</option>`,
                  ...itemFilterValues.map(value => `<option value="${this.esc(value)}" ${itemFilterState.value === value ? 'selected' : ''}>${this.esc(value)}</option>`)
                ].join('');

                const allItemEntries = (activeUnit.items || []).map((item, itemIndex) => ({ item, itemIndex }));
                const filteredItemEntries = allItemEntries.filter(entry => this.unitItemMatchesFilter(entry.item, itemFilterState));
                const isItemFilterActive = !!(itemFilterState.field && itemFilterState.value);

                const itemCards = filteredItemEntries.map(({ item, itemIndex }) => `
                  <div class="entry-card">
                    <div class="entry-card-head">
                      <div>
                        <div class="entry-card-title">${this.esc(item.commercial_name || ('بند ' + (itemIndex + 1)))}</div>
                        <div class="small">هذا البند هو التعريف التجاري الثابت الذي سيطابقه البلجن مع الرسم لاحقًا.</div>
                      </div>
                      <div class="unit-item-actions"><button class="mini-btn" style="background:#eff6ff;color:#1d4ed8" onclick="MH.saveUnitItem(${this.activeUnitIndex}, ${itemIndex})">حفظ البند</button><button class="mini-btn" style="background:#eef2ff;color:#4338ca" onclick="MH.duplicateUnitItem(${this.activeUnitIndex}, ${itemIndex})">تكرار</button><button class="mini-btn delete" onclick="MH.removeUnitItem(${this.activeUnitIndex}, ${itemIndex})">حذف البند</button></div>
                    </div>

                    <div class="field-grid three">
                      <div class="field"><label>الاسم التجاري</label><input id="item_commercial_name_${this.activeUnitIndex}_${itemIndex}" type="text" value="${this.esc(item.commercial_name || '')}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].commercial_name', this)"></div>
                      <div class="field"><label>كود الوحدة</label><input id="item_code_${this.activeUnitIndex}_${itemIndex}" type="text" value="${this.esc(item.code || '')}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].code', this)"></div>
                      <div class="field"><label>عرض الوحدة</label><input id="item_width_${this.activeUnitIndex}_${itemIndex}" type="number" value="${Number(item.width || 0)}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].width', this, 'number')"></div>

                      <div class="field"><label>عمق الوحدة</label><input id="item_depth_${this.activeUnitIndex}_${itemIndex}" type="number" value="${Number(item.depth || 0)}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].depth', this, 'number')"></div>
                      <div class="field"><label>ارتفاع الوحدة</label><input id="item_height_${this.activeUnitIndex}_${itemIndex}" type="number" value="${Number(item.height || 0)}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].height', this, 'number')"></div>
                      <div class="field"><label>طريقة التجميع</label>
                        <select id="item_assembly_method_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].assembly_method', this)">
                          <option value="" ${!item.assembly_method ? 'selected' : ''}>— اختر —</option>
                          <option value="جنب على القاعدة" ${item.assembly_method === 'جنب على القاعدة' ? 'selected' : ''}>جنب على القاعدة</option>
                          <option value="جنب كامل(سباحي)" ${item.assembly_method === 'جنب كامل(سباحي)' ? 'selected' : ''}>جنب كامل(سباحي)</option>
                        </select>
                      </div>

                      <div class="field"><label>خامة الشاسيه</label>
                        <select id="item_carcass_material_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].carcass_material', this)">
                          ${this.renderSelectOptions(this.materialOptions('carcass'), item.carcass_material)}
                        </select>
                      </div>

                      <div class="field"><label>خامة الضلفة</label>
                        <select id="item_door_material_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].door_material', this)">
                          ${this.renderSelectOptions(this.materialOptions('door'), item.door_material)}
                        </select>
                      </div>

                      <div class="field"><label>خامة الظهر</label>
                        <select id="item_back_material_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].back_material', this)">
                          ${this.renderSelectOptions(this.materialOptions('back'), item.back_material)}
                        </select>
                      </div>

                      <div class="field"><label>نوع القرصة</label>
                        <select id="item_counter_type_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].counter_type', this)">
                          <option value="" ${!item.counter_type ? 'selected' : ''}>— اختر —</option>
                          <option value="شدادات" ${item.counter_type === 'شدادات' ? 'selected' : ''}>شدادات</option>
                          <option value="قرصة كاملة" ${item.counter_type === 'قرصة كاملة' ? 'selected' : ''}>قرصة كاملة</option>
                        </select>
                      </div>
                      <div class="field"><label>تخانة الكونتر</label><input id="item_counter_thickness_${this.activeUnitIndex}_${itemIndex}" type="text" value="${this.esc(item.counter_thickness || '')}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].counter_thickness', this)"></div>
                      <div class="field"><label>تخانة الظهر</label><input id="item_back_thickness_${this.activeUnitIndex}_${itemIndex}" type="text" value="${this.esc(item.back_thickness || '')}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].back_thickness', this)"></div>

                      <div class="field"><label>الأدراج</label>
                        <select id="item_drawers_count_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].drawers_count', this, 'number')">
                          ${[0,1,2,3,4,5,6].map(n => `<option value="${n}" ${Number(item.drawers_count || 0) === n ? 'selected' : ''}>${n}</option>`).join('')}
                        </select>
                      </div>
                      <div class="field"><label>نوع المقبض</label>
                        <button type="button" class="accessory-picker-btn" onclick="MH.openHandlePicker(${this.activeUnitIndex}, ${itemIndex})">اختيار المقابض والكميات</button>
                        <div class="accessory-summary">${this.handleSummary(item)}</div>
                      </div>
                      <div class="field"><label>نوع الإكسسوار</label>
                        <button type="button" class="accessory-picker-btn" onclick="MH.openAccessoryPicker(${this.activeUnitIndex}, ${itemIndex})">اختيار الإكسسوارات والكميات</button>
                        <div class="accessory-summary">${this.accessorySummary(item)}</div>
                      </div>

                      <div class="field"><label>الجنب الظاهر</label>
                        <select id="item_visible_side_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].visible_side', this, 'number')">
                          <option value="0" ${Number(item.visible_side || 0) === 0 ? 'selected' : ''}>لا</option>
                          <option value="1" ${Number(item.visible_side || 0) === 1 ? 'selected' : ''}>1</option>
                          <option value="2" ${Number(item.visible_side || 0) === 2 ? 'selected' : ''}>2</option>
                        </select>
                      </div>

                      <div class="field"><label>عدد الرفوف</label><input id="item_shelves_count_${this.activeUnitIndex}_${itemIndex}" type="number" value="${Number(item.shelves_count || 0)}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].shelves_count', this, 'number')"></div>
                      <div class="field"><label>تجاهل الرف</label>
                        <select id="item_ignore_shelf_${this.activeUnitIndex}_${itemIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].ignore_shelf', this, 'select-bool')">
                          <option value="false" ${item.ignore_shelf ? '' : 'selected'}>لا</option>
                          <option value="true" ${item.ignore_shelf ? 'selected' : ''}>نعم</option>
                        </select>
                      </div>
                      <div class="field"><label>السعر الثابت</label><input id="item_fixed_price_${this.activeUnitIndex}_${itemIndex}" type="number" value="${Number(item.fixed_price || 0)}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].fixed_price', this, 'number')"></div>
                      <div class="field">
                        <label>معاينة السعر</label>
                        <div class="price-preview">
                          <div class="line"><span>السعر الثابت</span><b>${this.money(item.fixed_price || 0)}</b></div>
                          <div class="line"><span>سعر المقبض</span><b>${this.money(this.handlePrice(item))}</b></div>
                          <div class="line"><span>إجمالي الإكسسوارات</span><b>${this.money(this.accessorySubtotal(item))}</b></div>
                          <div class="line total"><span>السعر النهائي</span><b>${this.money(this.itemTotalPrice(item))}</b></div>
                        </div>
                      </div>
                    </div>

                    <div class="field" style="margin-top:12px;">
                      <label>ملاحظات البند</label>
                      <textarea id="item_notes_${this.activeUnitIndex}_${itemIndex}" oninput="MH.onInput('units[${this.activeUnitIndex}].items[${itemIndex}].notes', this)">${this.esc(item.notes || '')}</textarea>
                    </div>
                  </div>
                `).join('');

                const itemsEmptyHtml = allItemEntries.length
                  ? '<div class="empty-state">لا يوجد بنود مطابقة للتصفية الحالية داخل هذه الوحدة.</div>'
                  : '<div class="empty-state">لا يوجد بنود داخل هذه الوحدة حتى الآن. اضغط إضافة بند.</div>';

                detailHtml = `
                  <div class="card">
                    <div class="panel-head" style="margin-bottom:12px;">
                      <div>
                        <h3 style="margin:0;">${this.esc(activeUnit.library_name || '')}</h3>
                        <div class="small">ده اسم وحدة المكتبة. داخله تقدر تضيف عدد غير محدود من البنود التجارية.</div>
                      </div>
                      <div class="toolbar">
                        <div class="unit-print-options">
                          <label><input id="unit_print_show_prices_${this.activeUnitIndex}" type="checkbox"> إظهار السعر في الطباعة</label>
                          <button class="btn white" onclick="MH.printUnit(${this.activeUnitIndex})">طباعة الوحدة</button>
                        </div>
                        <button class="btn white" onclick="MH.saveUnitCard(${this.activeUnitIndex})">حفظ كارت الوحدة</button>
                        <button class="btn primary" onclick="MH.addUnitItem(${this.activeUnitIndex})">إضافة بند</button>
                      </div>
                    </div>

                    <div class="field-grid three">
                      <div class="field"><label>اسم وحدة المكتبة</label><input id="unit_library_name_${this.activeUnitIndex}" type="text" value="${this.esc(activeUnit.library_name || '')}" readonly disabled></div>
                      <div class="field"><label>التصنيف</label>
                        <select id="unit_category_${this.activeUnitIndex}" onchange="MH.onInput('units[${this.activeUnitIndex}].category', this)">
                          <option value="base" ${activeUnit.category === 'base' ? 'selected' : ''}>base</option>
                          <option value="wall" ${activeUnit.category === 'wall' ? 'selected' : ''}>wall</option>
                          <option value="tall" ${activeUnit.category === 'tall' ? 'selected' : ''}>tall</option>
                        </select>
                      </div>
                      <div class="field"><label>اسم التصنيف الظاهر</label><input id="unit_category_label_${this.activeUnitIndex}" type="text" value="${this.esc(activeUnit.category_label || '')}" oninput="MH.onInput('units[${this.activeUnitIndex}].category_label', this)"></div>
                    </div>

                    <div class="field" style="margin-top:12px;">
                      <label>ملاحظات عامة على كارت الوحدة</label>
                      <textarea id="unit_notes_${this.activeUnitIndex}" oninput="MH.onInput('units[${this.activeUnitIndex}].notes', this)">${this.esc(activeUnit.notes || '')}</textarea>
                    </div>
                  </div>

                  <div class="card" style="margin-top:14px;">
                    <div style="display:flex;justify-content:space-between;align-items:flex-end;gap:12px;flex-wrap:wrap;">
                      <div class="field" style="min-width:220px;flex:1;">
                        <label>تصفية البنود حسب</label>
                        <select id="unit_item_filter_field_${this.activeUnitIndex}" onchange="MH.setUnitItemFilterField(${this.activeUnitIndex}, this.value)">
                          ${itemFilterFieldOptions}
                        </select>
                      </div>
                      <div class="field" style="min-width:220px;flex:1;">
                        <label>اختيار القيمة</label>
                        <select id="unit_item_filter_value_${this.activeUnitIndex}" ${itemFilterState.field ? '' : 'disabled'} onchange="MH.setUnitItemFilterValue(${this.activeUnitIndex}, this.value)">
                          ${itemFilterValueOptions}
                        </select>
                      </div>
                      <div style="display:flex;gap:8px;align-items:flex-end;flex-wrap:wrap;">
                        <button class="btn white" onclick="MH.clearUnitItemFilter(${this.activeUnitIndex})">مسح التصفية</button>
                        <span class="badge ${isItemFilterActive ? 'info' : 'success'}">${filteredItemEntries.length} من ${allItemEntries.length} بند</span>
                      </div>
                    </div>
                    <div class="small" style="margin-top:8px;">التصفية هنا بتشتغل على بنود الوحدة الحالية فقط، والقيم بتتجمع تلقائيًا من البنود الموجودة بدون تكرار.</div>
                  </div>

                  <div class="items-stack" style="margin-top:14px;">
                    ${itemCards || itemsEmptyHtml}
                  </div>
                `;
              }

              root.innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">الوحدات</h2>
                    <p class="panel-desc">اختَر كارت اسم وحدة من المكتبة، ثم أضف داخله البنود التجارية المستطيلة التي لها عرض ثابت وخامات ثابتة وسعر ثابت.</p>
                  </div>
                  <div class="toolbar"></div>
                </div>

                <div class="card" style="margin-bottom:14px;">
                  <div style="display:flex;justify-content:space-between;align-items:flex-end;gap:12px;flex-wrap:wrap;">
                    <div class="field" style="max-width:320px;min-width:240px;">
                      <label>تصفية كروت الوحدات</label>
                      <select id="unit_filter_select" onchange="MH.setUnitFilter(this.value)">
                        ${filterOptionsHtml}
                      </select>
                    </div>
                    <div style="display:flex;align-items:flex-end;gap:10px;flex-wrap:wrap;justify-content:flex-start;">
                      <div class="field" style="width:120px;">
                        <label>قيمة الزيادة</label>
                        <input id="unit_bulk_increase_value" type="number" step="0.01" placeholder="مثال 10">
                      </div>
                      <div class="field" style="width:150px;">
                        <label>نوع الزيادة</label>
                        <select id="unit_bulk_increase_type">
                          <option value="fixed">سعر</option>
                          <option value="percent">نسبة مئوية</option>
                        </select>
                      </div>
                      <div>
                        <button class="btn primary" style="min-width:120px;" onclick="MH.applyGeneralUnitIncrease()">تطبيق الزيادة</button>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="units-browser">
                  <div class="unit-list">
                    ${listHtml || '<div class="empty-state">لا توجد وحدات ضمن التصنيف المختار.</div>'}
                  </div>
                  <div>${detailHtml}</div>
                </div>
              `;
            },

            renderReviews() {
              const rows = this.data.review_rules.map((r, i) => `
                <tr>
                  <td>${r.id}</td>
                  <td><input type="text" value="${this.esc(r.scope)}" oninput="MH.onInput('review_rules[${i}].scope', this)"></td>
                  <td><input type="text" value="${this.esc(r.category || '')}" oninput="MH.onInput('review_rules[${i}].category', this)"></td>
                  <td><input type="text" value="${this.esc(r.field_key)}" oninput="MH.onInput('review_rules[${i}].field_key', this)"></td>
                  <td><input type="text" value="${this.esc(r.expected_value)}" oninput="MH.onInput('review_rules[${i}].expected_value', this)"></td>
                  <td><input type="text" value="${this.esc(r.rule_type)}" oninput="MH.onInput('review_rules[${i}].rule_type', this)"></td>
                  <td><input type="text" value="${this.esc(r.message)}" oninput="MH.onInput('review_rules[${i}].message', this)"></td>
                  <td><button class="mini-btn delete" onclick="MH.removeFrom('review_rules', ${i})">حذف</button></td>
                </tr>
              `).join('');

              document.getElementById('panel-reviews').innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">قواعد المراجعة</h2>
                    <p class="panel-desc">نواة أولية للمقارنة بين قواعد المعرض وما يقرأه البلجن لاحقًا من SketchUp.</p>
                  </div>
                  <div class="toolbar"><button class="btn primary" onclick="MH.addReviewRule()">إضافة قاعدة مراجعة</button></div>
                </div>
                <div class="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>#</th><th>النطاق</th><th>التصنيف</th><th>البند</th><th>القيمة المتوقعة</th><th>نوع القاعدة</th><th>الرسالة</th><th></th>
                      </tr>
                    </thead>
                    <tbody>${rows}</tbody>
                  </table>
                </div>
                <div class="footer-note">النسخة الحالية لا تقرأ الموديل بعد، لكنها تجهّزك بوضوح لشكل قواعد المراجعة اللي هنبني عليها لاحقًا.</div>
              `;
            },

            renderRaw() {
              document.getElementById('panel-raw').innerHTML = `
                <div class="panel-head">
                  <div>
                    <h2 class="panel-title">JSON خام</h2>
                    <p class="panel-desc">للمراجعة السريعة لو حبيت تشوف شكل البيانات بالكامل.</p>
                  </div>
                </div>
                <div class="card"><textarea style="min-height:620px;font-family:Consolas, monospace;direction:ltr;text-align:left">${this.esc(JSON.stringify(this.data, null, 2))}</textarea></div>
              `;
            },

            esc(v) {
              return String(v ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;');
            }
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
