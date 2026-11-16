# encoding: UTF-8
# MHDESIGN - تقرير الوحدات
# Smart Classification + Editable + Resizable Images + Manual Unit Snapshot + Rectangle Crop
# Grouped into 3 tables: BASE / WALL / TALL

require 'sketchup'
require 'json'
require 'cgi'
require 'base64'
require 'tmpdir'


# ==================== MHDESIGN REPORT LANGUAGE BRIDGE ====================
module MHDESIGN_REPORT_LANG
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

  def source_map
    return {} unless defined?(MHDESIGN::Language)
    payload = MHDESIGN::Language.for_tool('reports').ui_payload
    payload[:source_map] || payload['source_map'] || {}
  rescue
    {}
  end

  def t(value)
    text = value.to_s
    return text if text.empty? || current == 'ar_EG'

    map = source_map
    exact = map[text]
    return exact.to_s unless exact.nil? || exact.to_s.empty?

    text
  rescue
    value.to_s
  end

  def messagebox(message, *args)
    UI.messagebox(t(message), *args)
  end

  def payload_json
    {
      locale: current,
      direction: (defined?(MHDESIGN::Language) ? MHDESIGN::Language.direction : (current == 'en' ? 'ltr' : 'rtl')),
      source_map: source_map
    }.to_json
  rescue
    '{"locale":"ar_EG","direction":"rtl","source_map":{}}'
  end
end
# =======================================================================

module MHDESIGN
  module ReportUnits
    EXT_NAME = MHDESIGN_REPORT_LANG.t("MHDESIGN - اصدار تقرير للوحدات")

    MATERIALS = [
      "ضهر ابيض", "ضهر خشابي",
      "كونتر ابيض", "كونتر خشابي",
      "HPL", "POLYLACK", "UVLACK", "PVC", "MELAMIN"
    ].freeze

    @dlg = nil
    @unit_images = {}
    @capture_pid = nil
    @saved_selection_pids = []
    @saved_hidden_states = nil
    @saved_rendering_options = nil
    @capture_tool = nil
    @progress_dlg = nil
    @capture_watchdog = nil

    def self.h(s)
      CGI.escapeHTML((s || "").to_s)
    end

    def self.clean_text(s)
      s.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
       .strip
       .gsub(/\u00A0/, " ")
       .gsub(/\s+/, " ")
    end

    def self.norm_mat(s)
      clean_text(s).upcase
    end

    def self.library_material?(mat_name)
      return false if mat_name.nil? || clean_text(mat_name).empty?
      MATERIALS.any? { |m| norm_mat(m) == norm_mat(mat_name) }
    end

    def self.to_cm(v)
      (v.to_f * 2.54).round(1)
    end

    def self.extract_index(name)
      m = name.to_s.match(/\((\d+)\)/)
      m ? m[1].to_i : 9999
    end

    def self.unit_category(inst)
      def_name = MHDESIGN::Language.original_definition_name(inst.definition).to_s.upcase
      return :base if def_name.include?("BASE")
      return :wall if def_name.include?("WALL")
      return :tall if def_name.include?("TALL")
      :other
    end

    def self.category_title(cat)
      case cat
      when :base then MHDESIGN_REPORT_LANG.t("الوحدات السفلية")
      when :wall then MHDESIGN_REPORT_LANG.t("الوحدات العلوية")
      when :tall then MHDESIGN_REPORT_LANG.t("الدواليب")
      else MHDESIGN_REPORT_LANG.t("وحدات أخرى")
      end
    end

    def self.unit_name(inst)
      dict = inst.attribute_dictionary("dynamic_attributes", false)
      clean_text(dict ? (dict["name"] || MHDESIGN::Language.original_definition_name(inst.definition)) : MHDESIGN::Language.original_definition_name(inst.definition))
    end

    def self.visible?(ent)
      return false if ent.deleted? rescue false
      return false if ent.hidden?
      return false if ent.respond_to?(:layer) && ent.layer && !ent.layer.visible?
      true
    end

    def self.definition_name(ent)
      if ent.is_a?(Sketchup::ComponentInstance)
        clean_text(MHDESIGN::Language.original_definition_name(ent.definition))
      elsif ent.is_a?(Sketchup::Group)
        clean_text(ent.name)
      else
        ""
      end
    end

    def self.canonical_name(s)
      t = clean_text(s)
      t = t.gsub(/\s*#\d+\s*$/, "")
      t = t.gsub(/\s*\(\s*/, "(")
      t = t.gsub(/\s*\)\s*/, ")")
      t = t.gsub(/\s+/, " ")
      t = t.gsub(/\s+\(/, "(")
      t.strip
    end

    def self.entity_material(ent)
      return clean_text(ent.material.display_name) if ent.material && ent.material.display_name
      mat_attr = ent.get_attribute("dynamic_attributes", "material")
      return clean_text(mat_attr) unless clean_text(mat_attr).empty?
      nil
    end

    def self.entity_dims(ent)
      lenx = ent.get_attribute("dynamic_attributes", "lenx").to_f
      leny = ent.get_attribute("dynamic_attributes", "leny").to_f
      lenz = ent.get_attribute("dynamic_attributes", "lenz").to_f

      if lenx > 0 && leny > 0 && lenz > 0
        w = to_cm(lenx)
        d = to_cm(leny)
        h = to_cm(lenz)
      else
        bb = ent.bounds
        w = to_cm(bb.width)
        d = to_cm(bb.depth)
        h = to_cm(bb.height)
      end

      [w, d, h].map { |x| (x <= 0.5 ? nil : x.round(1)) }
    end

    def self.unit_dims_str(ent)
      w, d, h = entity_dims(ent)
      return "" unless w && d && h
      "<div style='font-size:11px;line-height:1.5;text-align:center'>
        #{MHDESIGN_REPORT_LANG.t("عرض")}: #{w} #{MHDESIGN_REPORT_LANG.t("سم")}<br>
        #{MHDESIGN_REPORT_LANG.t("ارتفاع")}: #{h} #{MHDESIGN_REPORT_LANG.t("سم")}<br>
        #{MHDESIGN_REPORT_LANG.t("عمق")}: #{d} #{MHDESIGN_REPORT_LANG.t("سم")}
      </div>"
    end

    def self.entity_size(ent)
      dims = entity_dims(ent).compact.select { |x| x >= 2.0 }.sort.reverse
      return "" if dims.size < 2
      "#{dims[0]}×#{dims[1]}"
    end

    def self.role_for_name(def_name)
      n = canonical_name(def_name)

      return :door if n.include?("ضلفه قزاز")
      return :door if n.include?("ضلفه زجاج")
      return :door if n.include?("ضلفه يمين")
      return :door if n.include?("ضلفه شمال")
      return :door if n.include?("وش درج")

      has_chassis_word = n.include?("شاسيه") || n.include?("شاسه")
      has_back_word    = n.include?("ضهر") || n.include?("ظهر")
      return :chassis if has_chassis_word && has_back_word

      return :back if n.include?("ضهر")
      return :back if n.include?("ظهر")
      return :back if n.include?("قاعده الدرج")
      return :back if n.include?("قاعدة الدرج")

      return :visible_side if n.include?("جنب ظاهر")
      return :filler if n.include?("فيلر")

      :chassis
    end

    def self.display_piece_name(def_name)
      n = canonical_name(def_name)
      base = n.split("(").first.to_s.strip
      base = n if base.empty?

      return MHDESIGN_REPORT_LANG.t("ضلفه زجاج") if base.include?("ضلفه قزاز") || base.include?("ضلفه زجاج") || base.include?("قزاز") || base.include?("زجاج")

      return MHDESIGN_REPORT_LANG.t("وش الأدراج") if base.include?("وش شاسيه الدرج") || base.include?("وش شاسه الدرج")
      return MHDESIGN_REPORT_LANG.t("ضهر الأدراج") if (base.include?("شاسيه") || base.include?("شاسه")) && (base.include?("ضهر") || base.include?("ظهر"))
      return MHDESIGN_REPORT_LANG.t("أجناب الأدراج") if base.include?("جنب شاسيه") || base.include?("جنب شاسه")

      return MHDESIGN_REPORT_LANG.t("ضلفه يمين") if base.include?("ضلفه يمين")
      return MHDESIGN_REPORT_LANG.t("ضلفه شمال") if base.include?("ضلفه شمال")
      return MHDESIGN_REPORT_LANG.t("وش درج") if base.include?("وش درج")
      return MHDESIGN_REPORT_LANG.t("فيلر") if base.include?("فيلر")
      return MHDESIGN_REPORT_LANG.t("جنب ظاهر") if base.include?("جنب ظاهر")

      return MHDESIGN_REPORT_LANG.t("ضهر") if base.include?("ضهر") || base.include?("ظهر")
      return MHDESIGN_REPORT_LANG.t("قاعدة درج") if base.include?("قاعده الدرج") || base.include?("قاعدة الدرج")

      return MHDESIGN_REPORT_LANG.t("سدابة دعم") if base.include?("سدابة دعم") || base.include?("سدابه دعم")
      return MHDESIGN_REPORT_LANG.t("مراية") if base.include?("مرايا") || base.include?("مراية")
      return MHDESIGN_REPORT_LANG.t("قرصة") if base.include?("قرصة") || base.include?("قرصه")
      return MHDESIGN_REPORT_LANG.t("قاعدة") if base.include?("قاعدة") || base.include?("قاعده")
      return MHDESIGN_REPORT_LANG.t("سدة") if base.include?("سده") || base.include?("سدة")
      return MHDESIGN_REPORT_LANG.t("شداد") if base.include?("شداد")
      return MHDESIGN_REPORT_LANG.t("رف") if base.match?(/(?:\A|[\s(])رف(?:\z|[\s(])/u)
      return MHDESIGN_REPORT_LANG.t("أجناب الوحدة") if base.include?("جنب")

      base
    end

    def self.glass_door_name?(def_name)
      n = canonical_name(def_name)
      base = n.split("(").first.to_s.strip
      base = n if base.empty?

      base.include?("ضلفه زجاج") || base.include?("ضلفه قزاز")
    end

    def self.child_entities(ent)
      if ent.is_a?(Sketchup::ComponentInstance)
        ent.definition.entities
      elsif ent.is_a?(Sketchup::Group)
        ent.entities
      else
        []
      end
    end

    def self.has_direct_child_with_same_name?(ent)
      parent_name = canonical_name(definition_name(ent))
      return false if parent_name.empty?

      child_entities(ent).each do |child|
        next unless child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
        next unless visible?(child)

        child_name = canonical_name(definition_name(child))
        return true if !child_name.empty? && child_name == parent_name
      end
      false
    end

    def self.collect_pieces(ent, arr = [])
      return arr unless (ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group))
      return arr unless visible?(ent)

      mat = entity_material(ent)
      def_name = definition_name(ent)
      is_glass_door = glass_door_name?(def_name)

      if library_material?(mat) || is_glass_door
        arr << ent

        # مهم جدًا:
        # لو القطعة ضلفه زجاج، نقف هنا وما ندخلش جوّاها
        return arr if is_glass_door
      end

      return arr if has_direct_child_with_same_name?(ent)

      child_entities(ent).each { |e| collect_pieces(e, arr) }
      arr
    end

    def self.collect_unit(inst)
      name = unit_name(inst)
      dims_str = unit_dims_str(inst)
      pid = (inst.persistent_id rescue inst.object_id)

      data = {
        chassis: Hash.new { |h, k| h[k] = Hash.new(0) },
        back: Hash.new { |h, k| h[k] = Hash.new(0) },
        door: Hash.new { |h, k| h[k] = Hash.new(0) }
      }

      pieces = collect_pieces(inst, [])

      door_materials = []
      pieces.each do |p|
        mat = entity_material(p)
        def_name = definition_name(p)
        next unless library_material?(mat) || glass_door_name?(def_name)

        role = role_for_name(def_name)
        door_materials << norm_mat(mat) if role == :door && mat
      end
      door_materials.uniq!

      pieces.each do |p|
        mat = entity_material(p)
        def_name = definition_name(p)

        is_glass_door = glass_door_name?(def_name)
        next unless library_material?(mat) || is_glass_door

        role = role_for_name(def_name)
        role = :door if role == :visible_side

        if role == :filler
          if mat && door_materials.include?(norm_mat(mat))
            role = :door
          else
            next
          end
        end

        next unless data.key?(role)

        piece_name = display_piece_name(def_name)
        size = entity_size(p)
        next if size.empty?

        group_title = mat
        group_title = MHDESIGN_REPORT_LANG.t("ضلفه زجاج") if piece_name == MHDESIGN_REPORT_LANG.t("ضلفه زجاج")
        group_title = MHDESIGN_REPORT_LANG.t("بدون خامة") if group_title.nil? || group_title.to_s.strip.empty?

        key = "#{piece_name}|||#{size}"
        data[role][group_title][key] += 1
      end

      {
        pid: pid,
        name: MHDESIGN_REPORT_LANG.t(name),
        dims: dims_str,
        data: data,
        category: unit_category(inst),
        index: report_unit_index(inst)
      }
    end

    def self.render_cell(group_hash)
      return "" if group_hash.empty?

      group_hash.map do |mat, items|
        rendered_items = items.sort_by { |label, _count| label }.map do |label, count|
          name_part, size_part = label.split("|||", 2)
          text = [name_part, size_part].compact.join(" | ")

          "<div class='line'>
             <div class='line-name' contenteditable='true'>#{h(text)}</div>
             <div class='line-count' contenteditable='true'>#{count}</div>
           </div>"
        end.join

        "<div class='mat-block'>
          <div class='mat-title' contenteditable='true'>#{h(mat)}</div>
          <div class='mat-items'>#{rendered_items}</div>
        </div>"
      end.join("<hr>")
    end

    def self.unit_image_html(pid)
      img = @unit_images[pid]
      return "" if img.nil? || img.empty?

      "<div class='unit-shot-wrap'>
         <div class='resizable' style='width:190px'>
           <img src='#{img}' alt='unit snapshot'>
           <div class='resizer br'></div>
         </div>
       </div>"
    end

    def self.build_rows(units)
      units.each_with_index.map do |u, i|
        "<tr>
          <td>#{i + 1}</td>
          <td contenteditable='true' style='text-align:center'>
            <div class='unit-name'>#{h(u[:name])}</div>
            <div class='unit-shot-actions' contenteditable='false'>
              <button class='shot-btn' onclick='captureUnit(#{u[:pid]})' type='button'>#{MHDESIGN::Language.for_tool('reports').html('TEXT_09AB067B011A')}</button>
            </div>
            #{unit_image_html(u[:pid])}
            <div class='unit-dims'>#{u[:dims]}</div>
          </td>
          <td>#{render_cell(u[:data][:chassis])}</td>
          <td>#{render_cell(u[:data][:back])}</td>
          <td>#{render_cell(u[:data][:door])}</td>
          <td data-unit-accessories='pending'><span>#{MHDESIGN::Language.for_tool('reports').html('TEXT_E14A570F0FDD')}</span></td>
          <td contenteditable='true'></td>
        </tr>"
      end.join
    end

    def self.build_section(title, units, table_id)
      return "" if units.empty?

      <<-HTML
      <div class="section-wrap">
        <div class="section-title">#{h(title)}</div>
        <table id="#{h(table_id)}" class="report-table">
          <thead>
            <tr>
              <th style="width:3%">#{MHDESIGN::Language.for_tool('reports').html('REPORT_INDEX')}</th>
              <th style="width:18%">#{MHDESIGN::Language.for_tool('reports').html('TEXT_234E7F336568')}</th>
              <th style="width:17%">#{MHDESIGN::Language.for_tool('reports').html('OPT_GROUP_CARCASS')}</th>
              <th style="width:15%">#{MHDESIGN::Language.for_tool('reports').html('OPT_GROUP_BACK')}</th>
              <th style="width:15%">#{MHDESIGN::Language.for_tool('reports').html('OPT_GROUP_DOOR')}</th>
              <th data-unit-accessory-heading="true" style="width:17%">#{MHDESIGN::Language.for_tool('reports').html('TEXT_B50F22FF3FA8')}</th>
              <th style="width:15%">#{MHDESIGN::Language.for_tool('reports').html('REPORT_NOTES')}</th>
            </tr>
          </thead>
          <tbody>#{build_rows(units)}</tbody>
        </table>
      </div>
      HTML
    end

    def self.build_html(units)
      bases  = units.select { |u| u[:category] == :base }.sort_by { |u| u[:index] }
      walls  = units.select { |u| u[:category] == :wall }.sort_by { |u| u[:index] }
      talls  = units.select { |u| u[:category] == :tall }.sort_by { |u| u[:index] }
      others = units.select { |u| u[:category] == :other }.sort_by { |u| u[:index] }

      sections_html = ""
      sections_html << build_section(MHDESIGN_REPORT_LANG.t("الوحدات السفلية"), bases, "report-table-base")
      sections_html << build_section(MHDESIGN_REPORT_LANG.t("الوحدات العلوية"), walls, "report-table-wall")
      sections_html << build_section(MHDESIGN_REPORT_LANG.t("الدواليب"), talls, "report-table-tall")
      sections_html << build_section(MHDESIGN_REPORT_LANG.t("وحدات أخرى"), others, "report-table-other") unless others.empty?

      <<-HTML
      <!DOCTYPE html>
      <html dir="rtl" lang="ar">
      <head>
        <meta charset="UTF-8">
        <title>#{EXT_NAME}</title>
        <style>
          *{box-sizing:border-box}
          body{font-family:Tahoma,Arial;background:#f6f8fb;padding:20px;color:#1f2937}
          .actions{margin-bottom:12px;text-align:left}
          button{
            padding:7px 12px;margin-left:6px;border:none;border-radius:8px;
            background:#1f2937;color:#fff;cursor:pointer;font-size:12px
          }
          button:hover{opacity:.92}
          .shot-btn{
            background:#2563eb;
            margin:8px 0;
            padding:6px 10px;
            font-size:11px
          }
          .header{
            text-align:center;margin-bottom:16px;background:#fff;padding:14px;
            border:1px solid #d7dee7;border-radius:12px
          }
          .client{text-align:right;font-weight:bold;margin-bottom:6px;font-size:14px}
          .free-text{text-align:center;font-weight:bold;font-size:14px;margin-top:6px}

          .section-wrap{
            margin-bottom:24px;
            background:#fff;
            border:1px solid #d7dee7;
            border-radius:14px;
            overflow:hidden
          }
          .section-title{
            font-weight:bold;
            font-size:18px;
            padding:12px 16px;
            background:#e9f0f8;
            border-bottom:1px solid #d7dee7;
            text-align:right
          }

          table{
            width:100%;border-collapse:collapse;margin-bottom:0;table-layout:fixed;
            background:#fff;border:none
          }
          th,td{
            border:1px solid #cfd8e3;padding:8px;text-align:center;vertical-align:top;
            font-size:13px;overflow:hidden
          }
          th{background:#eef3f8;font-weight:bold}
          td[contenteditable="true"]{background:#fffdf4;position:relative}
          .unit-name{font-weight:bold;font-size:13px;margin-bottom:6px}
          .unit-dims{color:#475569;font-size:11px;line-height:1.5}
          .unit-shot-actions{margin:6px 0}
          .unit-shot-wrap{
            display:flex;
            justify-content:center;
            margin:8px 0 10px
          }

          .mat-block{text-align:right}
          .mat-title{
            display:inline-block;
            font-weight:bold;
            background:#eef3f8;
            border-radius:6px;
            padding:3px 8px;
            margin-bottom:6px
          }
          .mat-items{display:block}

          .line{
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap:8px;
            padding:4px 0;
            border-bottom:1px dashed #e8edf3;
          }
          .line:last-child{border-bottom:none}
          .line-name{
            flex:1;
            text-align:right;
            background:#fffdf4;
            padding:2px 0;
          }
          .line-count{
            min-width:34px;
            text-align:left;
            font-weight:bold;
            background:#eef3f8;
            border-radius:6px;
            padding:2px 6px;
          }

          hr{
            border:none;border-top:1px solid #dbe3ec;margin:10px 0
          }
          small{color:#555;font-size:11px}

          .resizable {
            position: relative;
            display:inline-block;
            cursor:move;
            border:1px dashed #777;
            border-radius:3px;
            max-width:100%;
            background:#fff;
          }
          .resizable img {
            width:100%;
            height:auto;
            display:block;
            pointer-events:none;
            user-select:none;
          }
          .resizer {
            width:8px; height:8px;
            background:#00aaff;
            position:absolute;
            border-radius:50%;
            cursor:nwse-resize;
          }
          .resizer.br {bottom:-4px;right:-4px;}

          @media print {
            @page { size: A4 landscape; margin: 15mm; }
            body{padding:0;background:#fff}
            .actions { display:none; }
            .shot-btn { display:none; }
            .header{border:none;padding:0;margin-bottom:10px}
            .section-wrap{border:none;border-radius:0;margin-bottom:16px}
            .section-title{
              background:#eee !important;
              -webkit-print-color-adjust:exact;
              print-color-adjust:exact
            }
            .resizer, .resizable { border:none; }
            th{background:#eee !important;-webkit-print-color-adjust:exact;print-color-adjust:exact}
          }
          @media screen {
            body,#material-page,#accessory-page,#accessory-prices-page{background:#EDF5FB}
            #format-bar .editor-brand,.report-page-toolbar .editor-brand,.accessory-page-bar{background:#E1EDF7;color:#101B27}
            /* The editor adds more specific button styles when it opens. */
            body button{background:#253443!important;color:#F4F7FA!important;border-color:#253443!important}
            body button.primary,
            body .accessory-report>.manual-accessory-controls button:first-child,
            body .accessory-report>.board-panel>.board-local-controls button:first-child{
              background:#101B27!important;border-color:#101B27!important
            }
            body .accessory-report>.manual-accessory-controls button:not(:first-child),
            body .accessory-report>.board-panel>.board-local-controls button:not(:first-child){
              background:#253443!important;color:#F4F7FA!important;border-color:#253443!important
            }
          }
        </style>
      </head>
      <body>
        <div class="actions">
          <button onclick="refreshReport()">#{MHDESIGN::Language.for_tool('reports').html('REPORT_REFRESH')}</button>
          <button onclick="window.print()">#{MHDESIGN::Language.for_tool('reports').html('TEXT_698901F17EE1')}</button>
          <button onclick="exportCSV()">#{MHDESIGN::Language.for_tool('reports').html('TEXT_E2B4A3247AC2')}</button>
        </div>

        <div class="header">
          <div class="client" contenteditable="true">#{MHDESIGN::Language.for_tool('reports').html('SHOP_REPORT_CLIENT_NAME')}</div>
          <div class="free-text" contenteditable="true">#{MHDESIGN::Language.for_tool('reports').html('TEXT_C244E0E70796')}</div>
        </div>

        #{sections_html}

        <script>
        function refreshReport(){
          if (window.sketchup && window.sketchup.refresh_report) {
            window.sketchup.refresh_report();
          }
        }

        function captureUnit(pid){
          if (window.sketchup && window.sketchup.capture_unit_image) {
            window.sketchup.capture_unit_image(String(pid));
          }
        }

        function collectTablesCSV(){
          const tables = Array.from(document.querySelectorAll('body > .section-wrap .report-table'));
          const parts = [];

          tables.forEach(table => {
            const sectionTitle = table.parentElement.querySelector('.section-title');
            if(sectionTitle){
              parts.push(`"${(sectionTitle.innerText || '').replace(/"/g, '""').trim()}"`);
            }

            const rows = Array.from(table.querySelectorAll('tr'));
            const csvRows = rows.map(row => {
              const cols = Array.from(row.querySelectorAll('th,td'));
              return cols.map(col => {
                const text = (col.innerText || '').replace(/\\n+/g, ' | ').replace(/"/g, '""').trim();
                return `"${text}"`;
              }).join(',');
            });

            parts.push(...csvRows);
            parts.push('');
          });

          return parts.join('\\n');
        }

        function exportCSV(){
          const csv = collectTablesCSV();
          const blob = new Blob(["\\uFEFF" + csv], {type: 'text/csv;charset=utf-8;'});
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'report_units.csv';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        }

        document.addEventListener('paste', e => {
          const items = (e.clipboardData || e.originalEvent.clipboardData).items;
          for (let i = 0; i < items.length; i++){
            if(items[i].type.indexOf('image') !== -1){
              e.preventDefault();
              const blob = items[i].getAsFile();
              const reader = new FileReader();
              reader.onload = ev => {
                const wrap = document.createElement('div');
                wrap.className = 'resizable';
                wrap.style.width = '150px';

                const img = document.createElement('img');
                img.src = ev.target.result;

                const resizer = document.createElement('div');
                resizer.className = 'resizer br';

                wrap.appendChild(img);
                wrap.appendChild(resizer);

                const sel = window.getSelection();
                if (!sel.rangeCount) return;
                const range = sel.getRangeAt(0);
                range.insertNode(wrap);
              };
              reader.readAsDataURL(blob);
            }
          }
        });

        let selected = null, startX, startY, startW, startH;
        document.addEventListener('mousedown', e => {
          if(e.target.classList.contains('resizer')){
            selected = e.target.parentElement;
            startX = e.clientX;
            startY = e.clientY;
            startW = parseFloat(getComputedStyle(selected).width);
            startH = parseFloat(getComputedStyle(selected).height);
            e.preventDefault();
          } else if(e.target.classList.contains('resizable')){
            selected = e.target;
            selected.dataset.dragging = true;
            startX = e.clientX - selected.offsetLeft;
            startY = e.clientY - selected.offsetTop;
            e.preventDefault();
          }
        });

        document.addEventListener('mousemove', e => {
          if(selected){
            if(selected.dataset.dragging){
              selected.style.position = 'relative';
              selected.style.left = (e.clientX - startX) + 'px';
              selected.style.top = (e.clientY - startY) + 'px';
            } else {
              const ratio = startH / startW;
              const w = startW + (e.clientX - startX);
              selected.style.width = w + 'px';
              selected.style.height = (w * ratio) + 'px';
            }
          }
        });

        document.addEventListener('mouseup', () => {
          if(selected){
            delete selected.dataset.dragging;
            selected = null;
          }
        });
        </script>
      
<script>
(function(){
  const MHD_L10N = #{MHDESIGN_REPORT_LANG.payload_json};
  const MAP = MHD_L10N.source_map || {};

  function translateText(value){value=String(value ?? "");return Object.prototype.hasOwnProperty.call(MAP,value)?String(MAP[value]):value;}

  window.MHD_LT = translateText;
  document.documentElement.lang = MHD_L10N.locale === 'en' ? 'en' : 'ar';
  document.documentElement.dir = MHD_L10N.direction || (MHD_L10N.locale === 'en' ? 'ltr' : 'rtl');

})();
</script>


<script>
(function(){
  const MHD_REPORT_L10N = #{MHDESIGN_REPORT_LANG.payload_json};
  const TEXTS = MHD_REPORT_L10N.texts || {};
  const MAP = MHD_REPORT_L10N.source_map || {};

  function mhdReportKey(key, fallback){
    const value = TEXTS[String(key || '')];
    return value == null || String(value).trim() === ''
      ? String(fallback == null ? key : fallback)
      : String(value);
  }

  function mhdReportTranslate(value){value=String(value ?? "");return Object.prototype.hasOwnProperty.call(MAP,value)?String(MAP[value]):value;}

  window.MHD_REPORT_T = mhdReportTranslate;
  window.MHD_REPORT_KEY = mhdReportKey;

  document.documentElement.lang = MHD_REPORT_L10N.locale || 'ar_EG';
  document.documentElement.dir = MHD_REPORT_L10N.direction || 'rtl';

})();
</script>

</body>
      </html>
      HTML
    end

    def self.read_file_as_data_uri(path)
      return nil unless File.exist?(path)
      bin = File.binread(path)
      "data:image/png;base64,#{Base64.strict_encode64(bin)}"
    rescue
      nil
    end

    def self.save_current_selection
      model = Sketchup.active_model
      @saved_selection_pids = model.selection.map { |e| e.persistent_id rescue nil }.compact
    rescue
      @saved_selection_pids = []
    end

    def self.restore_saved_selection
      model = Sketchup.active_model
      selection = model.selection
      selection.clear
      @saved_selection_pids.each do |pid|
        ent = model.find_entity_by_persistent_id(pid) rescue nil
        selection.add(ent) if ent && ent.valid?
      end
    rescue
    end

    def self.save_hidden_context(target_ent)
      model = Sketchup.active_model
      ents = model.active_entities
      target_pid = target_ent.persistent_id rescue nil

      @saved_hidden_states = []
      operation_started = false

      begin
        # نجمع الحالات أولاً قبل أي تعديل.
        ents.each do |e|
          next unless e.respond_to?(:hidden?) && e.respond_to?(:hidden=)
          pid = (e.persistent_id rescue nil)
          next if pid.nil?
          @saved_hidden_states << [pid, e.hidden?]
        end

        # كل الإخفاء يظهر للمستخدم كخطوة Undo واحدة فقط.
        model.start_operation(MHDESIGN_REPORT_LANG.t("MHDESIGN - إخفاء مؤقت للتصوير"), true)
        operation_started = true

        ents.each do |e|
          next unless e.respond_to?(:hidden=)
          pid = (e.persistent_id rescue nil)
          next if pid.nil?
          e.hidden = (pid != target_pid)
        end

        model.commit_operation
        operation_started = false
        model.active_view.invalidate
      rescue
        model.abort_operation if operation_started rescue nil
        @saved_hidden_states = []
        raise
      end
    end

    def self.restore_hidden_context
      model = Sketchup.active_model
      states = @saved_hidden_states
      return if states.nil?

      operation_started = false
      begin
        model.start_operation(MHDESIGN_REPORT_LANG.t("MHDESIGN - استرجاع الوحدات بعد التصوير"), true)
        operation_started = true

        states.each do |pid, hidden_state|
          ent = model.find_entity_by_persistent_id(pid) rescue nil
          next unless ent && ent.valid? && ent.respond_to?(:hidden=)
          ent.hidden = hidden_state
        end

        model.commit_operation
        operation_started = false
        model.active_view.invalidate
      rescue
        model.abort_operation if operation_started rescue nil
      ensure
        @saved_hidden_states = nil
      end
    end

    def self.save_background_context
      ro = Sketchup.active_model.rendering_options
      @saved_rendering_options = {
        "BackgroundColor" => ro["BackgroundColor"],
        "SkyColor" => ro["SkyColor"],
        "GroundColor" => ro["GroundColor"],
        "DisplaySky" => ro["DisplaySky"],
        "DisplayGround" => ro["DisplayGround"]
      }
    rescue
      @saved_rendering_options = nil
    end

    def self.set_white_background
      ro = Sketchup.active_model.rendering_options
      white = Sketchup::Color.new(255, 255, 255)
      ro["BackgroundColor"] = white if ro["BackgroundColor"]
      ro["SkyColor"] = white if ro["SkyColor"]
      ro["GroundColor"] = white if ro["GroundColor"]
      ro["DisplaySky"] = false unless ro["DisplaySky"].nil?
      ro["DisplayGround"] = false unless ro["DisplayGround"].nil?
    rescue
    end

    def self.restore_background_context
      return if @saved_rendering_options.nil?
      ro = Sketchup.active_model.rendering_options
      @saved_rendering_options.each do |k, v|
        begin
          ro[k] = v
        rescue
        end
      end
      @saved_rendering_options = nil
    rescue
      @saved_rendering_options = nil
    end

    def self.show_progress_dialog(message = MHDESIGN_REPORT_LANG.t("جاري الالتقاط..."))
      html = <<-HTML
      <!DOCTYPE html>
      <html dir="rtl" lang="ar">
      <head>
        <meta charset="UTF-8">
        <style>
          html, body{
            margin:0;
            width:100%;
            height:100%;
            font-family:Tahoma,Arial;
            background:#ffffff;
          }
          body{
            display:flex;
            align-items:center;
            justify-content:center;
          }
          .box{
            text-align:center;
            padding:20px 24px;
            border:1px solid #d7dee7;
            border-radius:14px;
            box-shadow:0 8px 24px rgba(0,0,0,0.08);
            min-width:240px;
            background:#fff;
          }
          .spinner{
            width:34px;
            height:34px;
            margin:0 auto 12px;
            border:4px solid #e5e7eb;
            border-top:4px solid #2563eb;
            border-radius:50%;
            animation:spin 1s linear infinite;
          }
          .title{
            font-size:15px;
            font-weight:bold;
            color:#111827;
            margin-bottom:6px;
          }
          .sub{
            font-size:12px;
            color:#6b7280;
          }
          @keyframes spin{
            0%{transform:rotate(0deg)}
            100%{transform:rotate(360deg)}
          }
        </style>
      </head>
      <body>
        <div class="box">
          <div class="spinner"></div>
          <div class="title">#{h(message)}</div>
          <div class="sub">#{h(MHDESIGN_REPORT_LANG.t("يرجى الانتظار..."))}</div>
        </div>
      
<script>
(function(){
  const MHD_L10N = #{MHDESIGN_REPORT_LANG.payload_json};
  const MAP = MHD_L10N.source_map || {};

  function translateText(value){value=String(value ?? "");return Object.prototype.hasOwnProperty.call(MAP,value)?String(MAP[value]):value;}

  window.MHD_LT = translateText;
  document.documentElement.lang = MHD_L10N.locale === 'en' ? 'en' : 'ar';
  document.documentElement.dir = MHD_L10N.direction || (MHD_L10N.locale === 'en' ? 'ltr' : 'rtl');

})();
</script>

</body>
      </html>
      HTML

      @progress_dlg&.close
      @progress_dlg = UI::HtmlDialog.new(
        dialog_title: "MHDESIGN",
        width: 300,
        height: 170,
        resizable: false,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      @progress_dlg.set_html(html)
      @progress_dlg.show
    rescue
    end

    def self.hide_progress_dialog
      @progress_dlg&.close
      @progress_dlg = nil
    @capture_watchdog = nil
    rescue
      @progress_dlg = nil
    @capture_watchdog = nil
    end

    class RectangleCaptureTool
      def initialize
        @dragging = false
        @start_x = nil
        @start_y = nil
        @end_x = nil
        @end_y = nil
      end

      def activate
        Sketchup.active_model.active_view.invalidate
      end

      def deactivate(view)
        view.invalidate if view
      end

      def onLButtonDown(_flags, x, y, view)
        @dragging = true
        @start_x = x
        @start_y = y
        @end_x = x
        @end_y = y
        view.invalidate
      end

      def onMouseMove(_flags, x, y, view)
        return unless @dragging
        @end_x = x
        @end_y = y
        view.invalidate
      end

      def onLButtonUp(_flags, x, y, view)
        return unless @dragging
        @end_x = x
        @end_y = y
        @dragging = false
        view.invalidate

        rect = normalized_rect
        if rect[:w] < 10 || rect[:h] < 10
          MHDESIGN_REPORT_LANG.messagebox("#{MHDESIGN::Language.for_tool('reports').t('TEXT_20CEB4A45743')}")
          return
        end

        MHDESIGN::ReportUnits.finish_rectangle_capture(rect)
      end

      def onKeyDown(key, _repeat, _flags, _view)
        if key == 27
          MHDESIGN::ReportUnits.cancel_rectangle_capture
        end
      end

      def draw(view)
        return unless @start_x && @start_y && @end_x && @end_y

        rect = normalized_rect
        x = rect[:x]
        y = rect[:y]
        w = rect[:w]
        h = rect[:h]

        pts = [
          Geom::Point3d.new(x, y, 0),
          Geom::Point3d.new(x + w, y, 0),
          Geom::Point3d.new(x + w, y + h, 0),
          Geom::Point3d.new(x, y + h, 0)
        ]

        view.line_width = 2
        view.drawing_color = Sketchup::Color.new(37, 99, 235)
        view.draw2d(GL_LINE_LOOP, pts)

        text_pt = Geom::Point3d.new(x + 6, [y - 22, 5].max, 0)
        view.draw_text(text_pt, MHDESIGN_REPORT_LANG.t("اسحب لتحديد مساحة القص - ESC للإلغاء"))
      rescue
      end

      private

      def normalized_rect
        x1 = [@start_x, @end_x].min
        y1 = [@start_y, @end_y].min
        x2 = [@start_x, @end_x].max
        y2 = [@start_y, @end_y].max
        { x: x1, y: y1, w: x2 - x1, h: y2 - y1 }
      end
    end

    def self.start_rectangle_capture_tool
      @capture_tool = RectangleCaptureTool.new
      Sketchup.active_model.select_tool(@capture_tool)
    rescue
      @capture_tool = nil
    end

    def self.stop_rectangle_capture_tool
      Sketchup.active_model.select_tool(nil)
      @capture_tool = nil
    rescue
      @capture_tool = nil
    end

    def self.png_dimensions(path)
      File.open(path, "rb") do |f|
        signature = f.read(24)
        return nil unless signature && signature.bytesize >= 24
        return nil unless signature.byteslice(0, 8) == "\x89PNG\r\n\x1A\n".b
        [signature.byteslice(16, 4).unpack1("N"), signature.byteslice(20, 4).unpack1("N")]
      end
    rescue
      nil
    end

    def self.crop_png_to_rect(src_path, dst_path, rect, viewport_w, viewport_h)
      src_ps = src_path.to_s.gsub("'", "''")
      dst_ps = dst_path.to_s.gsub("'", "''")

      actual = png_dimensions(src_path)
      actual_w = actual ? actual[0].to_f : viewport_w.to_f
      actual_h = actual ? actual[1].to_f : viewport_h.to_f
      scale_x = viewport_w.to_f > 0 ? actual_w / viewport_w.to_f : 1.0
      scale_y = viewport_h.to_f > 0 ? actual_h / viewport_h.to_f : 1.0

      # إحداثيات أداة الرسم Logical Pixels، بينما write_image قد ينتج
      # Physical Pixels في SketchUp 2025/2026 مع Display Scaling.
      x = (rect[:x].to_f * scale_x).round
      y = (rect[:y].to_f * scale_y).round
      w = (rect[:w].to_f * scale_x).round
      h = (rect[:h].to_f * scale_y).round

      script = <<~PS
        Add-Type -AssemblyName System.Drawing
        $src = '#{src_ps}'
        $dst = '#{dst_ps}'
        $img = [System.Drawing.Image]::FromFile($src)
        try {
          $imgW = $img.Width
          $imgH = $img.Height

          $x = #{x}
          $y = #{y}
          $w = #{w}
          $h = #{h}

          if ($x -lt 0) { $x = 0 }
          if ($y -lt 0) { $y = 0 }
          if ($w -lt 1) { $w = 1 }
          if ($h -lt 1) { $h = 1 }

          if ($x + $w -gt $imgW) { $w = $imgW - $x }
          if ($y + $h -gt $imgH) { $h = $imgH - $y }

          if ($w -lt 1) { $w = 1 }
          if ($h -lt 1) { $h = 1 }

          $bmp = New-Object System.Drawing.Bitmap($w, $h)
          $g = [System.Drawing.Graphics]::FromImage($bmp)
          try {
            $g.DrawImage($img,
              (New-Object System.Drawing.Rectangle(0, 0, $w, $h)),
              (New-Object System.Drawing.Rectangle($x, $y, $w, $h)),
              [System.Drawing.GraphicsUnit]::Pixel)
          } finally {
            $g.Dispose()
          }

          $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
          $bmp.Dispose()
        } finally {
          $img.Dispose()
        }
      PS

      command = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", script
      ]

      system(*command)
      File.exist?(dst_path)
    rescue
      false
    end

    def self.capture_entity_snapshot_with_rect(pid, rect)
      model = Sketchup.active_model
      ent = model.find_entity_by_persistent_id(pid.to_i) rescue nil
      return false unless ent && ent.valid?

      view = model.active_view
      raw_path = File.join(Dir.tmpdir, "mh_report_unit_raw_#{pid}.png")
      crop_path = File.join(Dir.tmpdir, "mh_report_unit_crop_#{pid}.png")

      begin
        img_w = view.vpwidth
        img_h = view.vpheight

        opts = {
          filename: raw_path,
          width: img_w,
          height: img_h,
          antialias: true,
          compression: 0.9,
          transparent: false
        }
        view.write_image(opts)

        final_path = raw_path
        if crop_png_to_rect(raw_path, crop_path, rect, img_w, img_h)
          final_path = crop_path
        end

        data_uri = read_file_as_data_uri(final_path)
        @unit_images[pid.to_i] = data_uri if data_uri && !data_uri.empty?
      rescue => e
        MHDESIGN_REPORT_LANG.messagebox("تعذر أخذ لقطة للوحدة:\n#{e.message}")
      end

      true
    end

    def self.stop_capture_watchdog
      UI.stop_timer(@capture_watchdog) if @capture_watchdog
      @capture_watchdog = nil
    rescue
      @capture_watchdog = nil
    end

    def self.start_capture_watchdog
      stop_capture_watchdog
      # حماية إضافية: لو أداة الالتقاط لم تكمل لأي سبب، ترجع حالة الملف تلقائياً.
      @capture_watchdog = UI.start_timer(45.0, false) do
        next if @saved_hidden_states.nil?
        hide_progress_dialog
        cleanup_capture_mode
        MHDESIGN_REPORT_LANG.messagebox("#{MHDESIGN::Language.for_tool('reports').t('TEXT_BF8B114EA586')}")
        UI.start_timer(0.05, false) { show }
      end
    rescue
      @capture_watchdog = nil
    end

    def self.cleanup_capture_mode
      stop_capture_watchdog
      stop_rectangle_capture_tool
      restore_hidden_context
      restore_background_context
      restore_saved_selection
      @capture_pid = nil
    end

    def self.finish_rectangle_capture(rect)
      show_progress_dialog("جاري الالتقاط...")

      # ندي فرصة للنافذة إنها ترسم المحتوى فعلاً
      UI.start_timer(0.20, false) do
        begin
          capture_entity_snapshot_with_rect(@capture_pid, rect)
        ensure
          hide_progress_dialog
          cleanup_capture_mode
          UI.start_timer(0.05, false) { show }
        end
      end
    end

    def self.cancel_rectangle_capture
      cleanup_capture_mode
      UI.start_timer(0.05, false) { show }
    end

    def self.enter_rectangle_capture_mode(pid)
      model = Sketchup.active_model
      ent = model.find_entity_by_persistent_id(pid.to_i) rescue nil
      return show unless ent && ent.valid?

      @capture_pid = pid.to_i
      save_current_selection

      begin
        model.selection.clear
        model.selection.add(ent)
        save_hidden_context(ent)
        save_background_context
        set_white_background
        start_rectangle_capture_tool
        start_capture_watchdog
      rescue => e
        cleanup_capture_mode
        MHDESIGN_REPORT_LANG.messagebox("تعذر بدء وضع الالتقاط:\n#{e.message}")
        return show
      end

      MHDESIGN_REPORT_LANG.messagebox("اسحب مستطيل بالماوس لتحديد مساحة اللقطة.\nاضغط ESC للإلغاء.")
    end

    def self.capture_unit_image(pid)
      @dlg&.close
      UI.start_timer(0.1, false) { enter_rectangle_capture_mode(pid) }
    end

    def self.show
      sel = Sketchup.active_model.selection
      comps = sel.grep(Sketchup::ComponentInstance)

      if comps.empty?
        MHDESIGN_REPORT_LANG.messagebox("#{MHDESIGN::Language.for_tool('reports').t('TEXT_E43215EC2386')}")
        return
      end

      units = comps.map { |i| collect_unit(i) }
      units.sort_by! do |u|
        category_rank =
          case u[:category]
          when :base then 0
          when :wall then 1
          when :tall then 2
          else 3
          end
        [category_rank, u[:index]]
      end

      html = build_html(units)

      @dlg&.close
      @dlg = UI::HtmlDialog.new(
        dialog_title: EXT_NAME,
        width: 1400,
        height: 750,
        resizable: true
      )
      @dlg.set_html(html)
      @dlg.add_action_callback("save_report_aliases") do |dialog, raw|
        begin
          parsed = JSON.parse(raw.to_s)
          safe = {}
          %w[chassis back door].each do |role|
            safe[role] = {}
            (parsed[role].is_a?(Hash) ? parsed[role] : {}).each { |key, value| safe[role][key.to_s] = value.to_s[0, 250] }
          end
          Sketchup.write_default('MHDESIGN_Report', 'material_aliases', JSON.generate(safe))
          @dlg.execute_script('window.reportAliasesSaved(true)')
        rescue
          @dlg.execute_script('window.reportAliasesSaved(false)')
        end
      end
      @dlg.add_action_callback("refresh_report") { |_dlg, _param| show }
      @dlg.add_action_callback("capture_unit_image") { |_dlg, pid| capture_unit_image(pid) }
      @dlg.show
    end
  end
end


# ==================== MHDESIGN REPORT LANGUAGE BRIDGE ====================
module MHDESIGN_REPORT_LANG
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
      MHDESIGN::Language.for_tool('reports').t(key_name.to_s, fallback_text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? key_name.to_s : fallback.to_s
  end

  def t(value, fallback = nil)
    text = value.to_s
    fallback_text = fallback.nil? ? text : fallback.to_s
    return fallback_text if text.empty?

    if text.start_with?('REPORT_')
      return key(text, fallback_text)
    end

    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('reports').translate_source(text)
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
    payload =
      if defined?(MHDESIGN::Language)
        MHDESIGN::Language.for_tool('reports').ui_payload
      else
        { locale: current, direction: direction, texts: {}, source_map: {} }
      end

    {
      locale: payload[:locale] || payload['locale'] || current,
      direction: payload[:direction] || payload['direction'] || direction,
      texts: payload[:texts] || payload['texts'] || {},
      source_map: payload[:source_map] || payload['source_map'] || {}
    }.to_json
  rescue
    '{"locale":"ar_EG","direction":"rtl","texts":{},"source_map":{}}'
  end
end
# =====================================================================



# MHDESIGN experimental library-aware report reader.
module MHDESIGN
  module ReportUnits
    def self.dc_read(ent, key)
      v = ent.get_attribute('dynamic_attributes', key, nil)
      if v.nil? && ent.respond_to?(:definition)
        v = ent.definition.get_attribute('dynamic_attributes', key, nil)
      end
      v
    rescue
      nil
    end

    def self.report_norm(value)
      clean_text(value).gsub(/<[^>]*>/, '').tr('أإآٱةى', 'ااااهي').gsub(/[ًٌٍَُِّْـ]/, '').gsub(/\s+/, '').downcase
    end

    def self.report_slot_role(label)
      n = report_norm(label)
      return nil unless n.include?(report_norm('خامة'))
      return nil if n.include?(report_norm('فصل'))
      return :chassis if n.include?(report_norm('شاسيه')) || n.include?(report_norm('شاسه'))
      return :back if n.include?(report_norm('ضهر')) || n.include?(report_norm('ظهر'))
      return :door if n.include?(report_norm('ضلف')) || (n.include?(report_norm('درج')) && (n.include?(report_norm('وش')) || n.include?(report_norm('وجه'))))
      nil
    end

    def self.report_slots(ent)
      result = {}
      sources = []
      sources << ent.definition if ent.respond_to?(:definition)
      sources << ent
      sources.each do |source|
        dict = source.attribute_dictionary('dynamic_attributes', false)
        next unless dict
        dict.each_pair do |k, v|
          m = k.to_s.match(/\A_(.+)_formlabel\z/i)
          next unless m
          role = report_slot_role(v)
          result[m[1].downcase] = role if role
        end
      end
      result
    end

    def self.report_context_name(ent)
      clean_text(dc_read(ent, '_name')).downcase
    end

    # Stop at the semantic option, BEFORE following its value/formula.
    def self.report_trace(ent, key, chain, seen = {})
      token = [ent.object_id, key.downcase]
      return [] if seen[token]
      seen = seen.merge(token => true)
      slot = report_slots(ent)[key.downcase]
      return [slot] if slot
      formula = dc_read(ent, "_#{key.downcase}_formula").to_s
      return [] if formula.empty? || formula.strip.start_with?('"')
      roles = []
      # Split formula syntax; component names may contain spaces and Arabic.
      formula.scan(/([^(),=<>+*\/&|]+)!\s*([\p{L}\p{N}_]+)/u).each do |raw_name, ref_key|
        wanted = raw_name.strip.sub(/\A=/, '').downcase
        target = if wanted == 'parent'
          chain[-2]
        else
          chain.reverse.find { |candidate| report_context_name(candidate) == wanted }
        end
        next unless target
        index = chain.rindex(target)
        roles.concat(report_trace(target, ref_key, chain[0..index], seen))
      end
      # Local intermediates such as MAT and BACKMAT.
      local = formula.gsub(/"[^"]*"/, '').gsub(/([^(),=<>+*\/&|]+)!\s*([\p{L}\p{N}_]+)/u, '')
      local.scan(/[\p{L}_][\p{L}\p{N}_]*/u).uniq.each do |ref_key|
        next if %w[if true false and or not].include?(ref_key.downcase)
        next if dc_read(ent, ref_key.downcase).nil? && dc_read(ent, "_#{ref_key.downcase}_formula").nil?
        roles.concat(report_trace(ent, ref_key, chain, seen))
      end
      roles.uniq
    end

    def self.report_material(ent, chain)
      value = entity_material(ent)
      value = clean_text(dc_read(ent, 'material')) if value.nil? || value.empty?
      if value.nil? || value.empty?
        chain.reverse_each do |parent|
          value = entity_material(parent)
          break if value && !value.empty?
        end
      end
      value.nil? || value.empty? ? 'بدون خامة' : value
    end

    def self.report_walk(ent, chain, records, depth = 0)
      return if depth > 30 || !visible?(ent)
      return unless ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group)
      chain = chain + [ent]
      children = child_entities(ent).select { |e| (e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)) && visible?(e) }
      name = definition_name(ent)
      roles = report_trace(ent, 'material', chain)
      role = roles.length == 1 ? roles.first : nil
      formula = dc_read(ent, '_material_formula').to_s
      if depth > 0 && role
        size = entity_size(ent)
        if size.empty?
          @report_audit << [name, 'مقاس غير صالح؛ لم يتم حسابها']
          children.each { |child| report_walk(child, chain, records, depth + 1) }
        else
          records << [ent, role, report_material(ent, chain[0...-1])]
        end
        return
      end
      if depth > 0 && (!formula.empty? || !dc_read(ent, 'material').to_s.empty? || ent.material)
        reason = roles.length > 1 ? 'روابط الخامة تشير لأكثر من تصنيف؛ لم تدخل الجدول' : 'لم يتم العثور على ارتباط بخاصية خامة تصنيف؛ لم تدخل الجدول'
        @report_audit << [name, reason]
      end
      children.each { |child| report_walk(child, chain, records, depth + 1) }
    end

    def self.collect_unit(inst)
      @report_audit = []
      records = []
      report_walk(inst, [], records)
      data = { chassis: Hash.new { |h,k| h[k] = Hash.new(0) }, back: Hash.new { |h,k| h[k] = Hash.new(0) }, door: Hash.new { |h,k| h[k] = Hash.new(0) } }
      records.each do |ent, role, mat|
        piece = display_piece_name(definition_name(ent))

        data[role][mat]["#{piece}|||#{entity_size(ent)}"] += 1
      end
      name = unit_name(inst)
      { pid: (inst.persistent_id rescue inst.object_id), name: MHDESIGN_REPORT_LANG.t(name), dims: unit_dims_str(inst), data: data, category: unit_category(inst), index: report_unit_index(inst), audit: @report_audit.dup, piece_count: records.length }
    end

    class << self
      alias_method :report_original_build_html, :build_html unless method_defined?(:report_original_build_html)
    end
    def self.build_html(units)
      html = report_original_build_html(units)
      audit = units.map do |unit|
        lines = unit[:audit].map { |name, reason| "<li>#{h(name)} — #{h(reason)}</li>" }.join
        "<details><summary>#{h(unit[:name])} — #{unit[:piece_count]} قطعة محسوبة / #{unit[:audit].length} ملاحظة</summary><ul>#{lines}</ul></details>"
      end.join
      panel = "<section style='background:#fff;padding:16px;margin:20px 0;border:2px solid #d99c22;direction:rtl'><h3>#{MHDESIGN::Language.for_tool('reports').html('TEXT_59C75F71FA88')}</h3><p>#{MHDESIGN::Language.for_tool('reports').html('TEXT_DFD919F34641')}</p>#{audit}</section>"
      html.sub('</body>', panel + '</body>')
    end
  end
end


module MHDESIGN
  module ReportUnits
    def self.report_aliases
      JSON.parse(Sketchup.read_default('MHDESIGN_Report', 'material_aliases', '{}'))
    rescue
      {}
    end

    def self.unit_image_html(pid)
      img = @unit_images[pid]
      unless img && !img.empty?
        ent = Sketchup.active_model.find_entity_by_persistent_id(pid) rescue nil
        if ent && ent.respond_to?(:definition)
          unless img
            path = File.join(Dir.tmpdir, "mh_report_thumb_#{pid}.png")
            begin
              img = read_file_as_data_uri(path) if ent.definition.save_thumbnail(path)
            ensure
              File.delete(path) if File.exist?(path)
            end
          end
        end
      end
      return ("<div class='no-unit-image'>" + MHDESIGN::Language.for_tool('reports').html('TEXT_35A8110D9F4A') + "</div>") unless img && !img.empty?
      "<div class='unit-shot-wrap'><div class='resizable' style='width:160px'><img src='#{h(img)}' alt='#{MHDESIGN::Language.for_tool('reports').html('TEXT_EEBB5C958C3E')}' onerror=\"this.style.display='none';this.parentElement.querySelector('.image-error').hidden=false\"><span class='image-error' hidden>#{MHDESIGN::Language.for_tool('reports').html('TEXT_E6854F8803F4')}</span><div class='resizer br'></div></div></div>"
    rescue
      ("<div class='no-unit-image'>" + MHDESIGN::Language.for_tool('reports').html('TEXT_320C37F5BAD0') + "</div>")
    end

    class << self
      alias_method :report_v4_base_html, :build_html unless method_defined?(:report_v4_base_html)
    end
    def self.build_html(units)
      html = report_v4_base_html(units)
      names = { chassis: [], back: [], door: [] }
      units.each { |u| names.each_key { |role| names[role].concat(u[:data][role].keys) } }
      names.each_value(&:uniq!)
      payload = JSON.generate({ names: names, aliases: report_aliases }).gsub('<', '\\u003c')
      css = <<~CSS
        <style>
        #format-bar{position:relative;z-index:50;background:#132c3d;color:white;padding:12px;border-radius:12px;display:flex;align-items:center;flex-wrap:wrap;gap:8px;margin-bottom:18px;box-shadow:0 4px 18px #0002}
        #format-bar label{font-size:12px} #format-bar select,#format-bar input{border:1px solid #abc;border-radius:5px;padding:5px;max-width:150px}
        #format-bar button{margin:0;background:#256b70} .section-wrap.active-report{outline:2px solid #26858a}
        .report-table{font-family:var(--report-font,Tahoma)} .report-table th,.report-table td,.report-table .unit-name{font-size:var(--report-size,13px)}
        .report-table .unit-dims,.report-table .unit-dims div{font-size:var(--report-size,13px)!important}
        #material-page{position:fixed;inset:0;background:#f4f7fa;z-index:100;overflow:auto;padding:28px;direction:rtl}
        #material-page[hidden]{display:none} .names-card{max-width:850px;margin:auto;background:white;padding:24px;border-radius:14px}
        .name-row{display:grid;grid-template-columns:1fr 2fr;gap:14px;align-items:center;padding:8px;border-bottom:1px solid #eee}
        .name-row input{width:100%;padding:9px;border:1px solid #bccbd4;border-radius:6px} .names-card h3{color:#24666b}
        .no-unit-image,.image-error{font-size:11px;color:#64748b} #format-note{font-size:11px;color:#d7e5e9}
        @media print{#format-bar,#material-page,.report-audit{display:none!important}.section-wrap.active-report{outline:none}}
        </style>
      CSS
      toolbar = <<~HTML
        <div id="format-bar" contenteditable="false">
          <label>#{MHDESIGN::Language.for_tool('reports').html('TEXT_324923502D06')} <select id="table-picker"></select></label>
          <button type="button" id="add-table">#{MHDESIGN::Language.for_tool('reports').html('TEXT_987E8A1092CD')}</button><button type="button" id="remove-table">#{MHDESIGN::Language.for_tool('reports').html('TEXT_5DB247E5642C')}</button><button type="button" id="undo-table">#{MHDESIGN::Language.for_tool('reports').html('TEXT_EC424CFC2020')}</button>
          <label>#{MHDESIGN::Language.for_tool('reports').html('REPORT_WIDTH')} <input id="table-width" type="number" min="30" max="100" value="100" style="width:65px"> %</label>
          <label>#{MHDESIGN::Language.for_tool('reports').html('SHOP_REPORT_FONT_SIZE')} <input id="font-size" type="number" min="8" max="36" value="13" style="width:60px"></label>
          <label>#{MHDESIGN::Language.for_tool('reports').html('TEXT_4004B5DC6406')} <select id="font-family"><option>Tahoma</option><option>Arial</option><option>Segoe UI</option><option>Times New Roman</option></select></label>
          <button type="button" id="add-row">#{MHDESIGN::Language.for_tool('reports').html('TEXT_E1DC2E242BC0')}</button><button type="button" id="remove-row">#{MHDESIGN::Language.for_tool('reports').html('TEXT_038212B82E15')}</button>
          <button type="button" id="material-names">#{MHDESIGN::Language.for_tool('reports').html('TEXT_BCEDB41C33F3')}</button><button type="button" id="print-pdf" onclick="window.print()">#{MHDESIGN::Language.for_tool('reports').html('TEXT_698901F17EE1')}</button><button type="button" id="save-html">#{MHDESIGN::Language.for_tool('reports').html('TEXT_DD69432AA27A')}</button>
          <span id="format-note">#{MHDESIGN::Language.for_tool('reports').html('TEXT_87F52090AD74')}</span>
        </div>
        <div id="material-page" hidden><div class="names-card"><h2>#{MHDESIGN::Language.for_tool('reports').html('TEXT_624BC4FAD440')}</h2><p>#{MHDESIGN::Language.for_tool('reports').html('TEXT_0512CB948CE6')}</p><div id="material-fields"></div><button type="button" id="apply-names">#{MHDESIGN::Language.for_tool('reports').html('TEXT_32B273507E6F')}</button><button type="button" id="cancel-names">#{MHDESIGN::Language.for_tool('reports').html('COMMON_BACK')}</button><p id="names-status"></p></div></div>
      HTML
      js = REPORT_EDITOR_JS
      html = html.sub('</head>', css + "<style id=\"report-print-pagination\">@media print{.report-table{overflow:visible!important}.report-table thead{display:table-header-group!important}.report-table tbody{break-inside:auto;page-break-inside:auto}.report-table tr,.report-table tbody>tr,.boards-table tr{break-inside:avoid!important;page-break-inside:avoid!important}.report-table td,.report-table th,.boards-table td,.boards-table th{break-inside:avoid!important;page-break-inside:avoid!important}.section-wrap,.accessory-report,.board-panel{overflow:visible!important;max-height:none!important;break-inside:auto;page-break-inside:auto}.section-title,.board-panel>h3{break-after:avoid-page;page-break-after:avoid}.unit-shot-wrap,.unit-dims,.mat-block,.line{break-inside:avoid!important;page-break-inside:avoid!important}.accessory-cost-summary{break-inside:avoid!important;page-break-inside:avoid!important}.resizable{max-width:100%!important}}</style>" + '</head>')
      html = html.sub('<body>', '<body>' + toolbar)
      html.sub('</body>', "<script>window.MHD_REPORT_CONFIG=#{payload};\n#{js}</script></body>")
    end
  end
end

require 'digest'
require 'fileutils'
module MHDESIGN
  module ReportUnits
    REPORT_FORMAT = 'MHDESIGN_REPORT' unless const_defined?(:REPORT_FORMAT)
    def self.draft_path
      @draft_keys ||= {}
      model = Sketchup.active_model
      key = @draft_keys[model.object_id] ||= (model.path.to_s.empty? ? "unsaved-#{Process.pid}-#{model.object_id}" : File.expand_path(model.path))
      directory = File.join(ENV['LOCALAPPDATA'] || Dir.tmpdir, 'MHDESIGN', 'ReportDrafts')
      FileUtils.mkdir_p(directory)
      File.join(directory, Digest::SHA256.hexdigest(key) + '.mhreport')
    end
    def self.report_document(raw)
      doc = raw.is_a?(String) ? JSON.parse(raw) : raw
      raise MHDESIGN::Language.for_tool('reports').t('TEXT_6B4F5ADD6AEF') unless doc.is_a?(Hash) && doc['format'] == REPORT_FORMAT && doc['version'] == 1 && doc['state'].is_a?(Hash)
      raise MHDESIGN::Language.for_tool('reports').t('TEXT_61BF94F32D3A') unless doc['state']['sections'].is_a?(Array) && doc['state']['sections'].all? { |s| s.is_a?(String) }
      doc
    end
    def self.write_report(path, doc)
      text = JSON.generate(doc)
      tmp = path + '.writing'
      File.open(tmp, 'wb') { |file| file.write(text); file.flush; file.fsync }
      File.rename(tmp, path)
    ensure
      File.delete(tmp) if tmp && File.exist?(tmp)
    end
    def self.read_report(path)
      raise MHDESIGN::Language.for_tool('reports').t('TEXT_7C4981286EDC') if File.size(path) > 50 * 1024 * 1024
      report_document(File.read(path, encoding: 'UTF-8'))
    end
    def self.report_send_restore(dialog, doc, recovery = false)
      safe = JSON.generate(doc['state']).gsub('<', '\\u003c')
      dialog.execute_script("window.restoreMHDReport(#{safe}, #{JSON.generate(doc['saved_at'])}, #{recovery})")
    end
    def self.show
      model = Sketchup.active_model
      current_draft_path = draft_path
      units = model.selection.grep(Sketchup::ComponentInstance).map { |ent| collect_unit(ent) }
      draft = nil
      begin
        draft = read_report(current_draft_path) if File.exist?(current_draft_path)
      rescue => error
        MHDESIGN_REPORT_LANG.messagebox("تعذر استرجاع المسودة؛ الملف محفوظ ولم يتم حذفه:\n#{error.message}")
      end
      @dlg&.close
      @dlg = UI::HtmlDialog.new(dialog_title: MHDESIGN::Language.for_tool('reports').t('TEXT_380C24EA6AA2'), width: 1400, height: 800, resizable: true, preferences_key: 'mhdesign_report_editor')
      page = build_html(units)
      key = JSON.generate(Digest::SHA256.hexdigest(draft_path))
      page = page.sub('<body>', "<body><script>window.MHD_REPORT_MODEL_KEY=#{key};window.MHD_REPORT_SELECTION=#{JSON.generate(model.selection.grep(Sketchup::ComponentInstance).map { |ent| ent.persistent_id.to_s }.sort)};</script>")
      @dlg.set_html(page)
      report_window = @dlg
      @dlg.add_action_callback('report_ready') { |dialog, _| if draft; report_window.execute_script("window.offerMHDReport(#{JSON.generate(draft).gsub('<', '\\u003c')})"); else; report_window.execute_script('window.restoreMHDLocalOnly()'); end }
      @dlg.add_action_callback('report_autosave') do |dialog, raw|
        begin
          doc = report_document(raw)
          write_report(current_draft_path, doc)
          report_window.execute_script('window.reportSaveStatus(true)')
        rescue => error
          report_window.execute_script("window.reportSaveStatus(false,#{JSON.generate(error.message)})")
        end
      end
      @dlg.add_action_callback('report_save_file') do |dialog, raw|
        begin
          doc = report_document(raw)
          path = UI.savepanel('حفظ تقرير MHDESIGN', nil, 'تقرير الوحدات.mhreport')
          next unless path
          path += '.mhreport' unless path.downcase.end_with?('.mhreport')
          write_report(path, doc)
          write_report(current_draft_path, doc)
          report_window.execute_script('window.reportSaveStatus(true,"تم حفظ ملف التقرير")')
        rescue => error
          MHDESIGN_REPORT_LANG.messagebox("تعذر حفظ التقرير:\n#{error.message}")
        end
      end
      @dlg.add_action_callback('report_open_file') do |dialog, _|
        begin
          path = UI.openpanel('فتح تقرير MHDESIGN', nil, 'تقارير MHDESIGN|*.mhreport||')
          next unless path
          doc = read_report(path)
          report_send_restore(report_window, doc)
          write_report(current_draft_path, doc)
        rescue => error
          MHDESIGN_REPORT_LANG.messagebox("تعذر فتح التقرير:\n#{error.message}")
        end
      end
      @dlg.add_action_callback('report_update_selected') do |dialog, _|
        selected = model.selection.grep(Sketchup::ComponentInstance)
        if selected.empty?
          MHDESIGN_REPORT_LANG.messagebox(MHDESIGN::Language.for_tool('reports').t('TEXT_418A29B3FD33'))
          next
        end
        rows = selected.map do |ent|
          unit = collect_unit(ent)
          { pid: unit[:pid].to_s, row: build_rows([unit]) }
        end
        report_window.execute_script("window.updateMHDUnits(#{JSON.generate(rows).gsub('<', '\\u003c')})")
      end
      @dlg.add_action_callback('refresh_report') { |dialog, _| report_window.execute_script('window.requestMHDUpdate()') }
      @dlg.add_action_callback('capture_unit_image') { |_dialog, pid| capture_unit_image(pid) }
      @dlg.add_action_callback('save_report_aliases') do |dialog, raw|
        begin
          parsed = JSON.parse(raw.to_s)
          safe = {}
          %w[chassis back door].each { |role| safe[role] = parsed[role].is_a?(Hash) ? parsed[role].transform_values { |value| value.to_s[0,250] } : {} }
          Sketchup.write_default('MHDESIGN_Report', 'material_aliases', JSON.generate(safe))
          report_window.execute_script('window.reportAliasesSaved(true)')
        rescue
          report_window.execute_script('window.reportAliasesSaved(false)')
        end
      end
      watched = []
      compare_units = lambda do
        report_current_signatures(watched.map { |u| u['pid'] }, model).select do |current|
          old = watched.find { |u| u['pid'].to_s == current[:pid] }
          old && old['signature'].to_s != current[:signature]
        end.map { |row| { pid: row[:pid], signature: row[:signature], name: row[:name], deleted: row[:deleted] } }
      end
      report_window.add_action_callback('report_watch') do |_context, raw|
        list = JSON.parse(raw.to_s) rescue []
        watched = list.is_a?(Array) ? list.select { |u| u.is_a?(Hash) && u['pid'].to_s.match?(/\A\d+\z/) }.uniq { |u| u['pid'] } : []
      end
      report_window.add_action_callback('report_compare') do |_context, raw|
        list = JSON.parse(raw.to_s) rescue []
        changes = report_current_signatures(list.map { |u| u['pid'] }, model).select do |current|
          old = list.find { |u| u['pid'].to_s == current[:pid] }
          old && old['signature'].to_s != current[:signature]
        end.map { |row| { pid: row[:pid], signature: row[:signature], name: row[:name], deleted: row[:deleted] } }
        report_window.execute_script("window.reportCompared(#{JSON.generate(changes).gsub('<', '\\u003c')})")
      end
      report_window.add_action_callback('report_new_selected') do |_context, _|
        state = report_new_state(model)
        report_window.execute_script("window.applyNewMHDReport(#{JSON.generate(state).gsub('<', '\\u003c')})")
      end
      report_window.add_action_callback('report_update_ids') do |_context, raw|
        ids = JSON.parse(raw.to_s) rescue []
        next unless ids.is_a?(Array)
        rows = report_current_rows(ids.select { |id| watched.any? { |u| u['pid'].to_s == id.to_s } }, model)
        report_window.execute_script("window.updateMHDUnits(#{JSON.generate(rows).gsub('<', '\\u003c')})")
      end
      report_window.add_action_callback('report_check_now') do |_context, _|
        report_window.execute_script("window.reportModelChanged(#{JSON.generate(compare_units.call).gsub('<', '\\u003c')},true)")
      end
      UI.stop_timer(@report_watch_timer) if @report_watch_timer
      if @report_observed_model && @report_model_observer
        @report_observed_model.remove_observer(@report_model_observer) rescue nil
      end
      scene_dirty = false
      pending_timer = nil
      check_pending = lambda do
        next unless scene_dirty && Sketchup.active_model == model && report_window.visible?
        scene_dirty = false
        begin
          changes = compare_units.call
          report_window.execute_script("window.reportModelChanged(#{JSON.generate(changes).gsub('<', '\\u003c')})") unless changes.empty?
        rescue => error
          puts "MHDESIGN Report Watch: #{error.message}"
        end
      end
      schedule_check = lambda do
        scene_dirty = true
        report_window.execute_script('if(window.markMHDAccessoriesStale)window.markMHDAccessoriesStale()') if report_window.visible?
        UI.stop_timer(pending_timer) if pending_timer
        pending_timer = UI.start_timer(0.8, false) { pending_timer = nil; check_pending.call }
      end
      observer_class = Class.new(Sketchup::ModelObserver)
      [:onTransactionCommit, :onTransactionUndo, :onTransactionRedo, :onTransactionAbort].each do |event|
        observer_class.send(:define_method, event) { |_changed_model| schedule_check.call }
      end
      model_observer = observer_class.new
      model.add_observer(model_observer)
      @report_observed_model = model
      @report_model_observer = model_observer
      report_window.add_action_callback('report_sort_order') do |_context, raw|
        ids = JSON.parse(raw.to_s) rescue []
        orders = {}
        ids.each do |pid|
          ent = model.find_entity_by_persistent_id(pid.to_i) rescue nil
          orders[pid.to_s] = report_unit_index(ent) if ent && ent.valid? && ent.is_a?(Sketchup::ComponentInstance)
        end
        report_window.execute_script("window.applyMHDOrder(#{JSON.generate(orders)})")
      end
      report_window.add_action_callback('report_accessories') do |_context, raw|
        begin
          ids = JSON.parse(raw.to_s)
          raise MHDESIGN::Language.for_tool('reports').t('TEXT_EEBE91797D25') unless ids.is_a?(Array) && ids.all? { |id| id.to_s.match?(/\A\d+\z/) }
          html = accessory_section(ids, model)
          report_window.execute_script("window.showMHDAccessories(#{JSON.generate(html).gsub('<', '\\u003c')})")
        rescue => error
          report_window.execute_script("window.showMHDAccessories(null,#{JSON.generate(error.message)})")
        end
      end
      report_window.add_action_callback('accessory_price_catalog') do |_context, _|
        report_window.execute_script("window.receiveAccessoryPrices(#{JSON.generate(price_catalog(model)).gsub('<', '\\u003c')})")
      end
      report_window.add_action_callback('accessory_prices_save') do |_context, raw|
        begin
          clean = clean_accessory_prices(raw)
          write_report(accessory_prices_path, { 'format' => 'MHDESIGN_ACCESSORY_PRICES', 'version' => 1, 'currency' => accessory_currency(raw), 'precision' => accessory_precision(raw), 'prices' => clean })
          report_window.execute_script("window.accessoryPricesSaved(#{JSON.generate({ prices: clean, currency: accessory_currency(raw), precision: accessory_precision(raw) }).gsub('<', '\\u003c')})")
        rescue => error
          report_window.execute_script("window.accessoryPriceError(#{JSON.generate(error.message)})")
        end
      end
      report_window.add_action_callback('accessory_prices_export') do |_context, raw|
        begin
          clean = clean_accessory_prices(raw)
          path = UI.savepanel('تصدير أسعار الإكسسوارات', nil, 'اسعار الاكسسوارات.mhprices')
          next unless path
          path += '.mhprices' unless path.downcase.end_with?('.mhprices')
          write_report(path, { 'format' => 'MHDESIGN_ACCESSORY_PRICES', 'version' => 1, 'currency' => accessory_currency(raw), 'precision' => accessory_precision(raw), 'prices' => clean })
        rescue => error
          report_window.execute_script("window.accessoryPriceError(#{JSON.generate(error.message)})")
        end
      end
      report_window.add_action_callback('accessory_prices_import') do |_context, _|
        begin
          path = UI.openpanel('استيراد أسعار الإكسسوارات', nil, 'اسعار الإكسسوارات|*.mhprices||')
          next unless path
          raise MHDESIGN::Language.for_tool('reports').t('TEXT_2B86757D3CB1') if File.size(path) > 2 * 1024 * 1024
          imported = File.read(path, encoding: 'UTF-8')
          clean = clean_accessory_prices(imported)
          report_window.execute_script("window.importAccessoryPrices(#{JSON.generate({ prices: clean, currency: accessory_currency(imported), precision: accessory_precision(imported) }).gsub('<', '\\u003c')})")
        rescue => error
          report_window.execute_script("window.accessoryPriceError(#{JSON.generate(error.message)})")
        end
      end
      selection_timer = nil
      selection_callback = lambda do
        UI.stop_timer(selection_timer) if selection_timer
        selection_timer = UI.start_timer(0.4, false) do
          selected_ids = model.selection.grep(Sketchup::ComponentInstance).map { |ent| ent.persistent_id.to_s }.sort
          report_window.execute_script("window.reportSelectionChanged(#{JSON.generate(selected_ids)})") if report_window.visible?
        end
      end
      selection_observer_class = Class.new(Sketchup::SelectionObserver)
      [:onSelectionBulkChange, :onSelectionAdded, :onSelectionRemoved, :onSelectionCleared].each do |event|
        selection_observer_class.send(:define_method, event) { |*_args| selection_callback.call }
      end
      selection_observer = selection_observer_class.new
      model.selection.add_observer(selection_observer)

      report_window.add_action_callback('report_unit_accessories') do |_context, raw|
        ids = JSON.parse(raw.to_s) rescue []
        next unless ids.is_a?(Array)
        ids = ids.select { |id| id.to_s.match?(/\A\d+\z/) }.map(&:to_s).uniq
        @unit_accessory_job = (@unit_accessory_job || 0) + 1
        job = @unit_accessory_job
        done = 0
        step = nil
        step = lambda do
          next unless @dlg.equal?(report_window) && job == @unit_accessory_job && Sketchup.active_model == model
          if done >= ids.length
            report_window.execute_script('window.finishUnitAccessoryLoading()')
            next
          end
          pid = ids[done]
          begin
            html = unit_accessories_html(pid)
          rescue => error
            html = "<span class='unit-accessory-error'>#{h('تعذر قراءة الإكسسوارات: ' + error.message)}</span>"
          end
          done += 1
          payload = JSON.generate([{ pid: pid, html: html }]).gsub('<', '\\u003c')
          report_window.execute_script("window.receiveUnitAccessories(#{payload});window.unitAccessoryProgress(#{done},#{ids.length});")
          UI.start_timer(0.025, false) { step.call }
        end
        UI.start_timer(0.08, false) { step.call }
      end

      report_window.add_action_callback('report_check_pending') { |_context, _| check_pending.call }
      report_window.set_on_closed do
        UI.stop_timer(pending_timer) if pending_timer
        UI.stop_timer(selection_timer) if selection_timer
        model.selection.remove_observer(selection_observer) rescue nil
        model.remove_observer(model_observer) rescue nil
      end
      @dlg.show
    end
  end
end

module MHDESIGN
  module ReportUnits
    def self.report_signature(unit)
      Digest::SHA256.hexdigest(JSON.generate([unit[:name], unit[:dims], unit[:data]]))
    end
    class << self
      alias_method :v8_build_rows_base, :build_rows unless method_defined?(:v8_build_rows_base)
    end
    def self.build_rows(units)
      units.each_with_index.map do |unit, index|
        v8_build_rows_base([unit]).sub('<tr>', "<tr data-unit-pid='#{unit[:pid]}' data-unit-order='#{unit[:index]}' data-unit-signature='#{report_signature(unit)}'>").sub('<td>1</td>', "<td>#{index+1}</td>")
      end.join
    end
    def self.report_current_signatures(ids, model)
      ids.map do |pid|
        ent = model.find_entity_by_persistent_id(pid.to_i) rescue nil
        if ent && ent.valid? && ent.is_a?(Sketchup::ComponentInstance)
          unit = collect_unit(ent)
          { pid: pid.to_s, signature: report_signature(unit), name: unit[:name] }
        else
          { pid: pid.to_s, deleted: true, signature: 'deleted', name: 'وحدة محذوفة من الموديل' }
        end
      end
    end
    def self.report_current_rows(ids, model)
      ids.map do |pid|
        ent = model.find_entity_by_persistent_id(pid.to_i) rescue nil
        if ent && ent.valid? && ent.is_a?(Sketchup::ComponentInstance)
          unit = collect_unit(ent)
          { pid: pid.to_s, row: build_rows([unit]), signature: report_signature(unit), name: unit[:name] }
        else
          { pid: pid.to_s, deleted: true, signature: 'deleted', name: 'وحدة محذوفة من الموديل' }
        end
      end
    end
    def self.report_unit_index(inst)
      match = MHDESIGN::Language.original_definition_name(inst.definition).to_s.match(/\((\d+)\)/)
      return match[1].to_i if match
      extract_index(unit_name(inst))
    end
    def self.report_new_state(model)
      units = model.selection.grep(Sketchup::ComponentInstance).map { |ent| collect_unit(ent) }
      parts = [:base, :wall, :tall, :other].map do |category|
        build_section(category_title(category), units.select { |unit| unit[:category] == category }.sort_by { |unit| unit[:index] }, "report-table-#{category}")
      end.reject(&:empty?)
      names = { chassis: [], back: [], door: [] }
      units.each { |unit| names.each_key { |role| names[role].concat(unit[:data][role].keys) } }
      { sections: parts, header: ("<div class=\"client\" contenteditable=\"true\">" + MHDESIGN::Language.for_tool('reports').html('SHOP_REPORT_CLIENT_NAME') + "</div><div class=\"free-text\" contenteditable=\"true\">" + MHDESIGN::Language.for_tool('reports').html('TEXT_08D77A54E22F') + "</div>"), aliases: report_aliases, names: names.transform_values(&:uniq) }
    end
  end
end

module MHDESIGN
  module ReportUnits
    def self.accessory_kind(name)
      n = report_norm(name.to_s.split('(').first)
      handle = n.match?(/مقبض|مقبد|مقض|مقبظ/u)
      return [:meter, 'مقبض بلت إن'] if handle && (n.include?(report_norm('بلت')) || n.include?(report_norm('حفر')))
      return [:meter, 'وزرة'] if n.include?(report_norm('وزر'))
      return [:count, 'رجل بلاستيك'] if n.include?(report_norm('رجل')) && n.include?(report_norm('بلاست'))
      return [:count, nil] if handle
      return [:count, nil] if %w[مفصلة مفصله ترولي مطبقية مطبقيه سلة سله باكم افنتوس افتنوس فنتوس سحابة سحابه مجرى مجري مجرة مجره سكة سكه حامل اكسسوار درجصاج].any? { |word| n.include?(report_norm(word)) }
      nil
    end
    def self.accessory_label(name, fallback)
      text = canonical_name(name).split('(').first.to_s.strip
      text = text.sub(/\s*(?:BASE|WALL|TALL)_UNIT.*\z/i, '').sub(/\s*#\d+\s*\z/, '').sub(/[\s\d]+\z/, '').strip
      text.empty? ? fallback.to_s : text
    end
    def self.accessory_material_name(ent)
      material = ent.material
      if material
        name = clean_text(material.display_name)
        return name if accessory_kind(name)
      end
      # Painted faces can supply a single accessory material when the component has none.
      candidates = child_entities(ent).select { |child| child.is_a?(Sketchup::Face) }.flat_map do |face|
        [face.material, face.back_material].compact.map { |mat| clean_text(mat.display_name) }
      end.uniq.select { |name| accessory_kind(name) }
      candidates.length == 1 ? candidates.first : nil
    end
    def self.accessory_length(ent, transform)
      bounds = ent.respond_to?(:definition) ? ent.definition.bounds : ent.entities.bounds
      lengths = [Geom::Vector3d.new(bounds.width,0,0), Geom::Vector3d.new(0,bounds.depth,0), Geom::Vector3d.new(0,0,bounds.height)].map { |vector| vector.transform(transform).length.to_f * 0.0254 }
      lengths.max.to_f
    end
    def self.accessory_walk(ent, chain, transform, items, unknown, unit_label, depth = 0)
      return if depth > 30 || !visible?(ent)
      return unless ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group)
      chain = chain + [ent]
      world = transform * ent.transformation
      name = definition_name(ent)
      # Accessory names are used only in this independent report; wood classification remains formula-based.
      dressing_hardware = depth > 0 && report_dressing_role(ent) == :hardware
      material_name = depth > 0 ? accessory_material_name(ent) : nil
      material_name ||= clean_text(ent.material.display_name) if dressing_hardware && ent.material
      wood_roles = depth > 0 && !material_name ? report_trace(ent, 'material', chain) : []
      kind = if depth == 0
        nil
      elsif material_name
        accessory_kind(material_name) || (dressing_hardware ? [:count, nil] : nil)
      elsif wood_roles.empty?
        accessory_kind(name) || (dressing_hardware ? [:count, nil] : nil)
      end
      if kind
        measure, fallback = kind
        label = material_name || (fallback == 'رجل بلاستيك' ? fallback : accessory_label(name, fallback))
        unknown << [unit_label, name, 'تم حساب الإكسسوار بالاسم لعدم وجود خامة إكسسوار واضحة؛ راجع النوع'] unless material_name
        amount = measure == :meter ? accessory_length(ent, world) : 1
        if amount <= 0
          unknown << [unit_label, name, 'تعذر حساب الطول']
        else
          key = [label, measure]
          entry = items[key] ||= { name: label, measure: measure, quantity: 0.0, pieces: 0, units: {} }
          entry[:quantity] += amount
          entry[:pieces] += 1
          entry[:units][unit_label] ||= { quantity: 0.0, pieces: 0 }
          entry[:units][unit_label][:quantity] += amount
          entry[:units][unit_label][:pieces] += 1
        end
        return
      end
      children = child_entities(ent).select { |child| child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group) }
      if depth > 0 && children.empty? && report_trace(ent, 'material', chain).empty?
        unknown << [unit_label, name, 'عنصر غير مرتبط بخامات الألواح ولم يتعرف عليه حصر الإكسسوارات']
      end
      children.each { |child| accessory_walk(child, chain, world, items, unknown, unit_label, depth + 1) }
    end
    def self.accessory_section(ids, model)
      items = {}; unknown = []; missing = []; counted = 0
      ids.uniq.each do |pid|
        ent = model.find_entity_by_persistent_id(pid.to_i) rescue nil
        unless ent && ent.valid? && ent.is_a?(Sketchup::ComponentInstance)
          missing << pid.to_s
          next
        end
        label = "#{unit_name(ent)} [#{report_unit_index(ent)}]"
        accessory_walk(ent, [], Geom::Transformation.new, items, unknown, label)
        counted += 1
      end
      rows = items.values.sort_by { |entry| [entry[:measure].to_s, entry[:name]] }.each_with_index.map do |entry, index|
        quantity = entry[:measure] == :meter ? format('%.3f', entry[:quantity]) : entry[:pieces].to_s
        measure = entry[:measure] == :meter ? 'متر طولي' : 'قطعة'
        breakdown = entry[:units].map do |unit, detail|
          value = entry[:measure] == :meter ? format('%.3f م', detail[:quantity]) : "#{detail[:pieces]} قطعة"
          "<div>#{h(unit)}: #{h(value)}</div>"
        end.join
        "<tr data-accessory-name='#{h(entry[:name])}' data-accessory-quantity='#{entry[:quantity]}' data-accessory-pieces='#{entry[:pieces]}'><td>#{index+1}</td><td contenteditable='true'>#{h(entry[:name])}</td><td contenteditable='true'>#{quantity}</td><td>#{measure}</td><td>#{entry[:pieces]}</td><td><details><summary>#{MHDESIGN::Language.for_tool('reports').html('TEXT_05B4B23AAFD9')}</summary>#{breakdown}</details></td></tr>"
      end.join
      review = unknown.uniq.map { |unit, name, reason| "<li>#{h(unit)} — #{h(name)}: #{h(reason)}</li>" }.join
      summary = "تم فحص #{counted} وحدة. التجميع حسب خامة الإكسسوار الفعلية؛ الاسم يُستخدم عند غياب خامة معروفة مع تنبيه للمراجعة. الأطوال صافي أطوال القطع الظاهرة بدون هالك أو تقريب لأطوال تجارية؛ القياس من أطول بُعد محلي بعد تطبيق التحجيم. العناصر المخفية لا تُحسب."
      summary += " تعذر العثور على #{missing.length} وحدة؛ افتح الموديل الأصلي." unless missing.empty?
      "<div class='section-wrap accessory-report' data-accessory-report='true'><div class='section-title' contenteditable='true'>#{MHDESIGN::Language.for_tool('reports').html('TEXT_353498195A95')}</div><table class='report-table' id='accessory-table'><thead><tr><th>#{MHDESIGN::Language.for_tool('reports').html('REPORT_INDEX')}</th><th>#{MHDESIGN::Language.for_tool('reports').html('TEXT_0BE76B046A76')}</th><th>#{MHDESIGN::Language.for_tool('reports').html('REPORT_TOTAL')}</th><th>#{MHDESIGN::Language.for_tool('reports').html('TEXT_02E927A2FBF5')}</th><th>#{MHDESIGN::Language.for_tool('reports').html('TEXT_7839AC5A77EA')}</th><th>#{MHDESIGN::Language.for_tool('reports').html('TEXT_D5315A16D31D')}</th></tr></thead><tbody>#{rows}</tbody></table></div>"
    end
  end
end

module MHDESIGN
  module ReportUnits
    def self.accessory_prices_path
      directory = File.join(ENV['LOCALAPPDATA'] || Dir.tmpdir, 'MHDESIGN')
      FileUtils.mkdir_p(directory)
      File.join(directory, 'accessory-prices.json')
    end
    def self.clean_accessory_prices(raw)
      data = raw.is_a?(String) ? JSON.parse(raw) : raw
      data = data['prices'] if data.is_a?(Hash) && data['format'] == 'MHDESIGN_ACCESSORY_PRICES'
      raise MHDESIGN::Language.for_tool('reports').t('TEXT_DD33AE9D3C7C') unless data.is_a?(Hash)
      clean = {}
      data.each do |name, entry|
        next unless entry.is_a?(Hash)
        mode = entry['mode'].to_s
        next unless %w[piece meter pack].include?(mode)
        price = entry['price'].nil? || entry['price'].to_s.empty? ? nil : Float(entry['price'])
        raise MHDESIGN::Language.for_tool('reports').t('TEXT_074FF2229F79') if price && (!price.finite? || price < 0)
        size = [entry['pack_size'].to_i, 1].max
        clean[name.to_s[0,250]] = { 'mode' => mode, 'price' => price, 'pack_size' => size, 'whole_packs' => entry['whole_packs'] != false }
      end
      clean
    end
    def self.accessory_prices
      File.exist?(accessory_prices_path) ? clean_accessory_prices(File.read(accessory_prices_path, encoding: 'UTF-8')) : {}
    rescue
      {}
    end
    def self.accessory_currency(raw = nil)
      data = raw.nil? ? (File.exist?(accessory_prices_path) ? JSON.parse(File.read(accessory_prices_path, encoding: 'UTF-8')) : {}) : (raw.is_a?(String) ? JSON.parse(raw) : raw)
      value = data.is_a?(Hash) ? data['currency'].to_s.upcase : ''
      value.match?(/\A[A-Z]{3}\z/) ? value : 'EGP'
    rescue
      'EGP'
    end
    def self.accessory_precision(raw = nil)
      data = raw.nil? ? (File.exist?(accessory_prices_path) ? JSON.parse(File.read(accessory_prices_path, encoding: 'UTF-8')) : {}) : (raw.is_a?(String) ? JSON.parse(raw) : raw)
      value = data.is_a?(Hash) ? data['precision'] : nil
      value.nil? ? 2 : [[Integer(value), 0].max, 6].min
    rescue
      2
    end
    def self.price_catalog(model)
      names = model.materials.map { |material| clean_text(material.display_name) }.select { |name| accessory_kind(name) }.uniq
      { prices: accessory_prices, names: names, currency: accessory_currency, precision: accessory_precision }
    end
  end
end

module MHDESIGN
  module ReportUnits
    def self.unit_accessories_html(pid)
      ent = Sketchup.active_model.find_entity_by_persistent_id(pid.to_i) rescue nil
      return '' unless ent && ent.valid?
      items = {}; unknown = []
      accessory_walk(ent, [], Geom::Transformation.new, items, unknown, unit_name(ent))
      items.values.reject do |item|
        normalized = report_norm(item[:name])
        (normalized.include?(report_norm('رجل')) && normalized.include?(report_norm('بلاست'))) || normalized.include?(report_norm('وزر'))
      end.sort_by { |item| item[:name] }.map do |item|
        key = "#{item[:name]}|||#{item[:measure]}"
        quantity = item[:measure] == :meter ? "#{format('%.3f', item[:quantity])} م" : "#{item[:pieces]} قطعة"
        "<div class='unit-accessory-item' data-unit-accessory-key='#{h(key)}'><span>#{h(item[:name])} — #{h(quantity)}</span><button type='button' class='unit-accessory-remove' data-remove-unit-accessory='true' title='#{MHDESIGN::Language.for_tool('reports').html('TEXT_BCA96314328F')}'>−</button></div>"
      end.join
    end
  end
end

module MHDESIGN
  module ReportUnits
    def self.report_dressing_badges(ent)
      owners = [ent]
      owners << ent.definition if ent.respond_to?(:definition)
      owners.flat_map do |owner|
        raw = owner.get_attribute('MHD_DRESSING', 'INTERNAL_BADGES', nil)
        raw.is_a?(Array) ? raw.map(&:to_s) : raw.to_s.split(/[;,|]/).map(&:strip)
      end.map { |tag| tag.strip.upcase }.reject(&:empty?).uniq
    rescue
      []
    end
    def self.report_dressing_role(ent)
      tags = report_dressing_badges(ent)
      return :hardware unless (tags & %w[HARDWARE ACCESSORY]).empty?
      return :back unless (tags & %w[BACK_PANEL DRAWER_BOTTOM]).empty?
      return :door unless (tags & %w[DOOR_PANEL DRAWER_FRONT GLASS_DOOR KITCHEN_GOLA_WOOD_HANDLE]).empty?
      chassis = %w[MAIN_CARCASS CORNER_CARCASS PARTITION BAY_INTERNAL_PARTITION SHELF DRAWER_CHASSIS DRAWER_SIDE DRAWER_BOX DRAWER_BACK WOOD_PLINTH TOP_CORNICE DRAWER_ORGANIZER HINGE_SUPPORT FILLER_RETURN]
      return :chassis unless (tags & chassis).empty?
      nil
    end
    class << self
      alias_method :report_v30_formula_trace, :report_trace unless method_defined?(:report_v30_formula_trace)
    end
    def self.report_trace(ent, key, chain, seen = {})
      if key.to_s.downcase == 'material'
        role = report_dressing_role(ent)
        return [] if role == :hardware
        return [role] if role
      end
      report_v30_formula_trace(ent, key, chain, seen)
    end
  end
end

UI.start_timer(0.1, false) { MHDESIGN::ReportUnits.show }

module MHDESIGN
  module ReportUnits
    REPORT_EDITOR_JS = <<~'MHD_REPORT_EDITOR_JAVASCRIPT'.freeze
function MHD_REPORT_TPL(value){return String(value).replace(/\u0001([HT]):([A-Z0-9_]+)\u0002/g,function(_,kind,key){const text=window.MHD_REPORT_KEY(key,key);if(kind!=='H')return text;return text.replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;', '"':'&quot;',"'":'&#39;'}[c]));});}
(function(){
'use strict';
const config=window.MHD_REPORT_CONFIG, titles={chassis:MHD_REPORT_TPL('\u0001T:OPT_GROUP_CARCASS\u0002'),back:MHD_REPORT_TPL('\u0001T:OPT_GROUP_BACK\u0002'),door:MHD_REPORT_TPL('\u0001T:OPT_GROUP_DOOR\u0002')};
let active=null, deleted=[];
const $=id=>document.getElementById(id), picker=$('table-picker');
function sections(){return Array.from(document.querySelectorAll('.section-wrap'));}
function select(section){
  sections().forEach(s=>s.classList.toggle('active-report',s===section)); active=section;
  if(!section)return;
  picker.value=section.dataset.editorId;
  $('table-width').value=parseInt(section.style.width)||100;
  $('font-size').value=section.style.getPropertyValue('--report-size').replace('px','')||13;
  $('font-family').value=section.style.getPropertyValue('--report-font')||'Tahoma';
}
function refreshPicker(){
 picker.replaceChildren();sections().forEach((s,i)=>{s.dataset.editorId=s.dataset.editorId||('table-'+Date.now()+'-'+i);const o=document.createElement('option');o.value=s.dataset.editorId;o.textContent=s.querySelector('.section-title').textContent||MHD_REPORT_TPL('\u0001T:TEXT_E1C39FB7C144\u0002');picker.appendChild(o);});
 if(active&&active.isConnected)picker.value=active.dataset.editorId;else select(sections()[0]||null);
}
function annotate(){
 sections().forEach(section=>section.querySelectorAll('tbody tr').forEach(row=>['chassis','back','door'].forEach((role,i)=>{
 const cell=row.cells[i+2];if(!cell)return;
 cell.querySelectorAll('.mat-title').forEach(el=>{if(!el.dataset.materialOriginal)el.dataset.materialOriginal=el.textContent.trim();el.dataset.materialRole=role;el.contentEditable='false';el.title=MHD_REPORT_TPL('\u0001T:TEXT_D7C13F400575\u0002');});
 })));
}
function applyAliases(){document.querySelectorAll('[data-material-original]').forEach(el=>{const group=config.aliases[el.dataset.materialRole]||{};el.textContent=group[el.dataset.materialOriginal]||el.dataset.materialOriginal;});}
picker.onchange=()=>select(sections().find(s=>s.dataset.editorId===picker.value));
document.addEventListener('click',e=>{const section=e.target.closest('.section-wrap');if(section&&section.parentElement===document.body)select(section);});
document.addEventListener('input',e=>{if(e.target.matches('.section-title'))refreshPicker();});
$('table-width').oninput=e=>{if(active)active.style.width=Math.max(30,Math.min(100,Number(e.target.value)||100))+'%';};
$('font-size').oninput=e=>{if(active)active.style.setProperty('--report-size',Math.max(8,Math.min(36,Number(e.target.value)||13))+'px');};
$('font-family').onchange=e=>{if(active)active.style.setProperty('--report-font',e.target.value);};
$('add-table').onclick=()=>{
 const s=document.createElement('div');s.className='section-wrap';
 const title=document.createElement('div');title.className='section-title';title.contentEditable='true';title.textContent=MHD_REPORT_TPL('\u0001T:TEXT_A760B1DCA56B\u0002');s.appendChild(title);
 const table=document.createElement('table');table.className='report-table';table.id='report-extra-'+Date.now();
 const head=table.createTHead().insertRow();[MHD_REPORT_TPL('\u0001T:REPORT_INDEX\u0002'),MHD_REPORT_TPL('\u0001T:TEXT_234E7F336568\u0002'),MHD_REPORT_TPL('\u0001T:OPT_GROUP_CARCASS\u0002'),MHD_REPORT_TPL('\u0001T:OPT_GROUP_BACK\u0002'),'الضلفة','ملاحظات'].forEach(t=>{const th=document.createElement('th');th.textContent=t;th.contentEditable='true';head.appendChild(th);});table.createTBody();s.appendChild(table);
 const last=sections().slice(-1)[0];if(last)last.after(s);else document.querySelector('.header').after(s);
 select(s);refreshPicker();$('add-row').click();s.scrollIntoView({block:'center'});
};
$('remove-table').onclick=()=>{if(!active)return;deleted.push({node:active,parent:active.parentNode,next:active.nextSibling});active.remove();active=null;refreshPicker();};
$('undo-table').onclick=()=>{const item=deleted.pop();if(!item)return;item.parent.insertBefore(item.node,item.next&&item.next.isConnected?item.next:null);select(item.node.classList.contains('section-wrap')?item.node:item.node.closest('.section-wrap'));refreshPicker();};
$('add-row').onclick=()=>{if(!active)return;const body=active.querySelector('tbody');const row=body.insertRow();for(let i=0;i<active.querySelector('thead tr').cells.length;i++){const cell=row.insertCell();cell.contentEditable='true';cell.textContent=i===0?body.rows.length:'';}};
$('remove-row').onclick=()=>{if(!active)return;const body=active.querySelector('tbody');if(body.rows.length){const row=body.rows[body.rows.length-1];deleted.push({node:row,parent:body,next:null});row.remove();}};
$('material-names').onclick=()=>{
 const fields=$('material-fields');fields.replaceChildren();
 Object.keys(titles).forEach(role=>{const h=document.createElement('h3');h.textContent=titles[role];fields.appendChild(h);
 const names=new Set(config.names[role]||[]);document.querySelectorAll('[data-material-original]').forEach(el=>{if(el.dataset.materialRole===role)names.add(el.dataset.materialOriginal);});
 if(!names.size){const p=document.createElement('p');p.textContent=MHD_REPORT_TPL('\u0001T:TEXT_EB69345DD4D6\u0002');fields.appendChild(p);}
 names.forEach(name=>{const row=document.createElement('label');row.className='name-row';const span=document.createElement('span');span.textContent=name;const input=document.createElement('input');input.dataset.role=role;input.dataset.original=name;input.value=(config.aliases[role]||{})[name]||'';input.placeholder=MHD_REPORT_TPL('\u0001T:TEXT_48677AD4F4EF\u0002');row.append(span,input);fields.appendChild(row);});});
 $('names-status').textContent='';$('material-page').hidden=false;
};
$('cancel-names').onclick=()=>$('material-page').hidden=true;
$('apply-names').onclick=()=>{
 $('material-fields').querySelectorAll('input').forEach(input=>{const group=config.aliases[input.dataset.role]||(config.aliases[input.dataset.role]={});const v=input.value.trim();if(v)group[input.dataset.original]=v;else delete group[input.dataset.original];});
 applyAliases();if(window.sketchup&&window.sketchup.save_report_aliases){window.sketchup.save_report_aliases(JSON.stringify(config.aliases));$('material-page').hidden=true;}else{$('names-status').textContent=MHD_REPORT_TPL('\u0001T:TEXT_943C04DCE599\u0002');}
};
window.reportAliasesSaved=function(ok){if(!ok){$('material-page').hidden=false;$('names-status').textContent=MHD_REPORT_TPL('\u0001T:TEXT_2C5A3BE83D88\u0002');}};
$('save-html').onclick=()=>{
 document.querySelectorAll('input').forEach(el=>el.setAttribute('value',el.value));
 document.querySelectorAll('select').forEach(el=>Array.from(el.options).forEach(o=>o.toggleAttribute('selected',o.selected)));
 const old=document.querySelector('#saved-report-config');if(old)old.remove();
 const saved=document.createElement('script');saved.id='saved-report-config';saved.textContent='window.MHD_REPORT_CONFIG='+JSON.stringify(config).replace(/</g,'\\u003c')+';';
 const scripts=Array.from(document.scripts);const main=scripts.find(s=>s.textContent.includes('window.MHD_REPORT_CONFIG=')&&s.textContent.includes('function sections()'));if(main)main.before(saved);
 const original=main?main.textContent:null;if(main)main.textContent=main.textContent.replace(/window\.MHD_REPORT_CONFIG=.*?;\n/,'');
 const blob=new Blob(['<!DOCTYPE html>\n'+document.documentElement.outerHTML],{type:'text/html;charset=utf-8'});if(main)main.textContent=original;saved.remove();
 const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='MHDESIGN-report.html';a.click();setTimeout(()=>URL.revokeObjectURL(url),2000);
};
document.querySelectorAll('.section-title').forEach(el=>el.contentEditable='true');
const audit=Array.from(document.querySelectorAll('section')).find(s=>s.textContent.includes('مراجعة التصنيف'));if(audit)audit.classList.add('report-audit');
annotate();applyAliases();refreshPicker();
// V6 persistence uses data-only snapshots. Imported report files cannot add executable scripts.
let restoring=false, initialReady=false, saveTimer=null;
let reportModelKey=window.MHD_REPORT_MODEL_KEY;
const status=document.createElement('span');status.id='draft-status';status.style.fontSize='12px';$('format-bar').appendChild(status);
$('save-html').textContent=MHD_REPORT_TPL('\u0001T:TEXT_91772FE04BA0\u0002');
const openButton=document.createElement('button');openButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_DAB7D96F7E11\u0002');openButton.type='button';$('save-html').after(openButton);
const updateButton=document.createElement('button');updateButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_116D38F31929\u0002');updateButton.type='button';openButton.after(updateButton);
$('format-note').textContent=MHD_REPORT_TPL('\u0001T:TEXT_3750D794DA03\u0002');
const refreshButton=document.querySelector('.actions button');if(refreshButton)refreshButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_CCF452B24FC9\u0002');
function markRows(){
 document.querySelectorAll('.report-table tbody tr').forEach(row=>{
  const button=row.querySelector('button[onclick],button[data-capture-pid]');
  if(button){const m=(button.getAttribute('onclick')||'').match(/captureUnit\((\d+)\)/);if(m&&button.dataset.capturePid!==m[1])button.dataset.capturePid=m[1];if(button.dataset.capturePid&&row.dataset.unitPid!==button.dataset.capturePid)row.dataset.unitPid=button.dataset.capturePid;}
 });
}
function safeHTML(value){
 const template=document.createElement('template');template.innerHTML=String(value||'');
 template.content.querySelectorAll('script,iframe,object,embed,link,meta,base,form,svg,math,style').forEach(el=>el.remove());
 template.content.querySelectorAll('*').forEach(el=>Array.from(el.attributes).forEach(attr=>{
  if(/^on/i.test(attr.name)||['srcdoc','action','formaction'].includes(attr.name))el.removeAttribute(attr.name);
  if(['href','src','xlink:href'].includes(attr.name)&&!(/^(data:image\/(png|jpeg|gif|webp|bmp);base64,|https?:\/\/)/i.test(attr.value)))el.removeAttribute(attr.name);
 }));
 return template.innerHTML;
}
function snapshot(){
 markRows();
 const header=document.querySelector('.header');
 return {format:'MHDESIGN_REPORT',version:1,saved_at:new Date().toISOString(),state:{model_key:reportModelKey,header:header?header.innerHTML:'',sections:sections().map(s=>s.outerHTML),aliases:config.aliases,names:config.names}};
}
function persist(){
 clearTimeout(saveTimer);saveTimer=null;if(restoring)return;
 const doc=snapshot();try{localStorage.setItem(recoveryKey,JSON.stringify(doc));}catch(error){}
 if(window.sketchup&&window.sketchup.report_autosave){status.textContent=MHD_REPORT_TPL('\u0001T:TEXT_5A508A690DFB\u0002');window.sketchup.report_autosave(JSON.stringify(doc));}
}
function queueSave(){if(restoring)return;status.textContent=MHD_REPORT_TPL('\u0001T:TEXT_5E6E5FD1F195\u0002');clearTimeout(saveTimer);saveTimer=setTimeout(persist,700);}
window.reportSaveStatus=function(ok,message){status.textContent=ok?(message||MHD_REPORT_TPL('\u0001T:TEXT_FAB24CC5F7CB\u0002')):(MHD_REPORT_TPL('\u0001T:TEXT_F20CFE1BD64A\u0002 ')+(message||''));status.style.color=ok?'#b9f5cf':'#ffbdbd';};
window.restoreMHDReport=function(state){
 if(!state||!Array.isArray(state.sections))return;
 restoring=true;
 try{
  const fragments=state.sections.map(html=>{const t=document.createElement('template');t.innerHTML=safeHTML(html);const s=t.content.firstElementChild;if(!s||!s.matches('.section-wrap')||!s.querySelector('.report-table'))throw Error(MHD_REPORT_TPL('\u0001T:TEXT_5CF63E09F7A1\u0002'));return s;});
  const header=document.querySelector('.header');if(header)header.innerHTML=safeHTML(state.header);
  sections().forEach(s=>s.remove());let anchor=header;
  fragments.forEach(s=>{anchor.after(s);anchor=s;});
  config.aliases=state.aliases&&typeof state.aliases==='object'?state.aliases:{};
  config.names=state.names&&typeof state.names==='object'?state.names:{chassis:[],back:[],door:[]};
  document.querySelectorAll('.report-audit').forEach(el=>el.remove());
  deleted=[];active=null;annotate();applyAliases();refreshPicker();markRows();if(window.restoreAccessoryPricing)window.restoreAccessoryPricing(state);
  window.reportSaveStatus(true,'تم استرجاع التقرير بتعديلاته ✓');
 }catch(error){window.reportSaveStatus(false,error.message);}
 finally{restoring=false;}
};
// Restored image buttons have no inline handlers; route validated IDs explicitly.
document.addEventListener('click',event=>{const button=event.target.closest('button[data-capture-pid]');if(button&&!button.hasAttribute('onclick'))captureUnit(button.dataset.capturePid);});
$('save-html').onclick=()=>{persist();if(window.sketchup)window.sketchup.report_save_file(JSON.stringify(snapshot()));};
openButton.onclick=()=>{persist();if(window.sketchup)window.sketchup.report_open_file();};
window.requestMHDUpdate=function(){if(reportModelKey!==window.MHD_REPORT_MODEL_KEY){status.textContent=MHD_REPORT_TPL("\u0001T:TEXT_3887925C6C7D\u0002");return;}persist();if(window.sketchup)window.sketchup.report_update_selected();};
updateButton.onclick=window.requestMHDUpdate;
window.updateMHDUnits=function(updates){
 let count=0,missing=0;
 updates.forEach(update=>{
  const old=Array.from(document.querySelectorAll('tr[data-unit-pid]')).find(row=>row.dataset.unitPid===String(update.pid));
  if(!old){missing++;return;}
  const table=document.createElement('table');table.innerHTML='<tbody>'+update.row+'</tbody>';const fresh=table.rows[0];if(!fresh)return;
  // Preserve row position, numbering, notes, and custom description; replace measured data and materials.
  const preserved=old.cloneNode(true);fresh.dataset.unitPid=String(update.pid);
  if(fresh.cells[0]&&old.cells[0])fresh.cells[0].innerHTML=old.cells[0].innerHTML;
  if(fresh.cells.length&&old.cells.length)fresh.cells[fresh.cells.length-1].innerHTML=old.cells[old.cells.length-1].innerHTML;
  if(fresh.cells[1]&&old.cells[1]){const a=old.querySelector('.unit-name'),b=fresh.querySelector('.unit-name');if(a&&b)b.innerHTML=a.innerHTML;}
  deleted.push({node:preserved,parent:old.parentNode,next:old.nextSibling,replacement:fresh});old.replaceWith(fresh);count++;
 });
 annotate();applyAliases();markRows();document.querySelectorAll('.report-audit').forEach(el=>el.remove());persist();
 status.textContent=MHD_REPORT_TPL('\u0001T:TEXT_8B718416DE3E\u0002 ')+count+MHD_REPORT_TPL(' \u0001T:SHOP_UNIT\u0002')+(missing?MHD_REPORT_TPL('\u0001T:TEXT_86C741617C55\u0002 ')+missing+MHD_REPORT_TPL(' \u0001T:TEXT_75BBBB199648\u0002'):'');
};
const originalUndo=$('undo-table').onclick;
$('undo-table').onclick=()=>{const last=deleted[deleted.length-1];if(last&&last.replacement){deleted.pop();if(last.replacement.isConnected)last.replacement.replaceWith(last.node);else last.parent.appendChild(last.node);annotate();applyAliases();markRows();select(last.node.closest('.section-wrap'));refreshPicker();queueSave();}else originalUndo();};
const observer=new MutationObserver(mutations=>{if(restoring||!initialReady)return;const changed=mutations.some(m=>{const el=m.target.nodeType===1?m.target:m.target.parentElement;if(el&&el.closest('.section-wrap,.header'))return true;return Array.from(m.addedNodes).concat(Array.from(m.removedNodes)).some(n=>n.nodeType===1&&n.matches('.section-wrap'));});if(changed){queueSave();}});
// Observe only report content so save status changes cannot trigger another save.
observer.observe(document.body,{subtree:true,childList:true,characterData:true,attributes:true,attributeFilter:['style','data-material-original','data-material-role','data-unit-pid','data-capture-pid']});
document.addEventListener('input',event=>{if(!event.target.closest('#material-page'))queueSave();});
document.addEventListener('change',queueSave);
document.addEventListener('pointerup',()=>{if(saveTimer)persist();});
document.addEventListener('focusout',()=>{if(saveTimer)persist();});
window.addEventListener('beforeunload',persist);
// A local recovery snapshot covers edits made immediately before the native close button.
const recoveryKey='mhreport-recovery-'+window.MHD_REPORT_MODEL_KEY;
function localBackup(){if(!initialReady)return;try{localStorage.setItem(recoveryKey,JSON.stringify(snapshot()));}catch(error){/* Native autosave status still reports disk persistence. */}}



const baseRestore=window.restoreMHDReport;
window.restoreMHDReport=function(state,savedAt,recovery){
 if(recovery){try{const local=JSON.parse(localStorage.getItem(recoveryKey)||'null');if(local&&local.saved_at&&(!savedAt||local.saved_at>savedAt))state=local.state;}catch(error){}}
 baseRestore(state);initialReady=true;reportModelKey=state.model_key||window.MHD_REPORT_MODEL_KEY;localBackup();
};
window.restoreMHDLocalOnly=function(){try{const local=JSON.parse(localStorage.getItem(recoveryKey)||'null');if(local){baseRestore(local.state);reportModelKey=local.state.model_key||window.MHD_REPORT_MODEL_KEY;}}catch(error){}initialReady=true;localBackup();};
markRows();
// V8 clear toolbar and report lifecycle decisions.
let decisionOpen=false, lastNotice='', ignoredChanges={}, latestChanges=[], pendingStartup=null;
const style=document.createElement('style');style.textContent=`
#format-bar{display:block;background:#fff;color:#203445;border:1px solid #dce5eb;padding:0;position:relative;overflow:hidden}
.editor-brand{background:#12394a;color:white;padding:12px 18px;display:flex;justify-content:space-between;align-items:center}.editor-brand strong{font-size:17px}
.editor-groups{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:0}.editor-group{min-width:0;padding:12px;border-left:1px solid #e3eaef;display:flex;gap:7px;align-items:center;flex-wrap:wrap}.editor-group b{display:block;width:100%;font-size:11px;color:#64808d;margin-bottom:3px}
#format-bar{position:relative!important;top:auto;left:auto;right:auto;margin:0 0 18px;max-height:none;overflow:visible;z-index:auto;border-radius:12px}#format-bar button{white-space:nowrap;background:#edf3f6;color:#183c4b;padding:8px 11px;border:1px solid #d7e3e9;font-size:12px}#format-bar button.primary{background:#087f82;color:white;border-color:#087f82}#format-bar label{display:flex;gap:5px;align-items:center}
#format-note{display:block;color:#627d8a;padding:8px 16px;background:#f7fafb}#draft-status{color:inherit!important;font-size:11px}
#decision-overlay{position:fixed;inset:0;z-index:500;background:#142b4266;backdrop-filter:blur(8px);display:flex;align-items:center;justify-content:center;padding:24px;direction:rtl}#decision-overlay[hidden]{display:none}
.decision-card{width:560px;max-width:100%;background:#fff;border-radius:20px;box-shadow:0 24px 80px #132c3d44;padding:28px;text-align:right}.decision-card h2{font-size:22px;margin:0 0 12px;color:#163e50}.decision-card p{line-height:1.8;color:#58707d}.decision-card button{display:block;width:100%;text-align:right;padding:13px 16px;margin:9px 0;background:#eff4f7;color:#1a4252;border:1px solid #dce6ec;font-size:14px}.decision-card button:first-child{background:#087f82;color:white}.decision-list{max-height:140px;overflow:auto;line-height:1.8;color:#426271}
.empty-report{padding:65px;text-align:center;color:#617d8b;background:white;border:2px dashed #cadbe4;border-radius:16px;margin:20px 0}.empty-report h2{color:#244a5e}
@media print{body{padding-top:0!important}#decision-overlay,.empty-report{display:none!important}}
`;document.head.appendChild(style);
const bar=$('format-bar');const brand=document.createElement('div');brand.className='editor-brand';brand.innerHTML=MHD_REPORT_TPL('<strong>\u0001H:TEXT_334B7083DAA9\u0002</strong>');brand.appendChild(status);
const groups=document.createElement('div');groups.className='editor-groups';bar.prepend(brand,groups);
function group(title,nodes){const box=document.createElement('div');box.className='editor-group';const name=document.createElement('b');name.textContent=title;box.appendChild(name);nodes.filter(Boolean).forEach(n=>box.appendChild(n));groups.appendChild(box);}
function labelOf(id){return $(id).closest('label');}
const newButton=document.createElement('button');newButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_1AE9FDF9EC1B\u0002');newButton.type='button';
const printButton=document.querySelector('.actions button[onclick*="print"]'),csvButton=document.querySelector('.actions button[onclick*="exportCSV"]');
group(MHD_REPORT_TPL('\u0001T:TEXT_4EC793C37034\u0002'),[$('save-html'),openButton,newButton,$('print-pdf'),csvButton]);$('save-html').classList.add('primary');$('print-pdf').classList.add('primary');
group('بيانات الوحدات',[updateButton,$('material-names')]);updateButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_E6E7E03B0A41\u0002');
group(MHD_REPORT_TPL('\u0001T:TEXT_DCCA8735C6A6\u0002'),[labelOf('table-picker'),$('add-table'),$('remove-table'),$('undo-table'),$('add-row'),$('remove-row')]);$('undo-table').textContent=MHD_REPORT_TPL('\u0001T:TEXT_13A4E68F97A6\u0002');
group(MHD_REPORT_TPL('\u0001T:TEXT_E1BE0F2004AB\u0002'),[labelOf('table-width'),labelOf('font-size'),labelOf('font-family')]);
const note=$('format-note');bar.replaceChildren(brand,groups,note);const actions=document.querySelector('.actions');if(actions)actions.hidden=true;
const overlay=document.createElement('div');overlay.id='decision-overlay';overlay.hidden=true;overlay.innerHTML='<div class="decision-card" role="dialog" aria-modal="true" aria-labelledby="decision-title"><h2 id="decision-title"></h2><p id="decision-text"></p><div class="decision-list"></div><div class="decision-buttons"></div></div>';document.body.appendChild(overlay);
function modal(title,text,choices,names=[]){decisionOpen=true;$('decision-title').textContent=title;$('decision-text').textContent=text;const list=overlay.querySelector('.decision-list');list.replaceChildren();names.forEach(name=>{const d=document.createElement('div');d.textContent='• '+name;list.appendChild(d);});const buttons=overlay.querySelector('.decision-buttons');buttons.replaceChildren();choices.forEach(choice=>{const button=document.createElement('button');button.textContent=choice.text;button.onclick=()=>{overlay.hidden=true;decisionOpen=false;choice.run();};buttons.appendChild(button);});overlay.hidden=false;buttons.querySelector('button').focus();}
function emptyState(){let empty=$('empty-report');if(!sections().length&&!empty){empty=document.createElement('div');empty.id='empty-report';empty.className='empty-report';empty.innerHTML=MHD_REPORT_TPL('<h2>\u0001H:TEXT_E30C4957C2FD\u0002</h2><p>\u0001H:TEXT_2E77950D1F54\u0002</p>');document.querySelector('.header').after(empty);}if(sections().length&&empty)empty.remove();}
function watch(){markRows();const units=Array.from(document.querySelectorAll('tr[data-unit-pid]')).map(row=>({pid:row.dataset.unitPid,signature:row.dataset.unitSignature||''}));if(window.sketchup)window.sketchup.report_watch(JSON.stringify(units));emptyState();}
const v8Persist=persist;persist=function(){if(decisionOpen||pendingStartup)return;v8Persist();};
const v8Restore=window.restoreMHDReport;
window.restoreMHDReport=function(state,savedAt,recovery){if(!recovery){v8Restore(state,savedAt,false);watch();return;}window.offerMHDReport({format:'MHDESIGN_REPORT',version:1,saved_at:savedAt,state});};
function finishRestore(doc){pendingStartup=null;v8Restore(doc.state,doc.saved_at,false);initialReady=true;watch();persist();}
window.offerMHDReport=function(doc){
 try{const local=JSON.parse(localStorage.getItem(recoveryKey)||'null');if(local&&(!doc||local.saved_at>doc.saved_at))doc=local;}catch(error){}
 if(!doc){initialReady=true;watch();localBackup();return;}
 pendingStartup=doc;
 const state=doc.state, foreign=state.model_key&&state.model_key!==window.MHD_REPORT_MODEL_KEY;
 const rows=document.createElement('div');state.sections.forEach(html=>{const part=document.createElement('div');part.innerHTML=safeHTML(html);part.querySelectorAll('tr[data-unit-pid]').forEach(row=>rows.appendChild(row));});
 const ids=Array.from(rows.querySelectorAll('tr')).map(row=>({pid:row.dataset.unitPid,signature:row.dataset.unitSignature||''}));
 if(foreign){startupChoices(doc,[]);return;}
 if(window.sketchup)window.sketchup.report_compare(JSON.stringify(ids));else startupChoices(doc,[]);
};
function startupChoices(doc,changes){
 const changed=changes.length>0;
 modal(changed?'فيه وحدات اتعدّلت':'فيه تقرير محفوظ',changed?'لقينا تقريرك السابق، وفيه اختلافات في بيانات الوحدات. اختار الطريقة اللي تحب تكمل بيها.':'تقدر تكمل آخر نسخة بكل تنسيقها وتعديلاتك، أو تبدأ قراءة جديدة للوحدات المحددة.',[
 {text:'استرجاع التقرير السابق كما هو',run:()=>{finishRestore(doc);changes.forEach(c=>ignoredChanges[c.pid]=c.signature);}},
 ...(changed?[{text:'استرجاع التقرير وتحديث الوحدات المتغيرة',run:()=>{finishRestore(doc);updateChanged(changes);}}]:[]),
 {text:'تقرير جديد من الوحدات المحددة',run:()=>requestNew()},
 {text:'فتح ملف تقرير آخر',run:()=>{pendingStartup=null;initialReady=true;openButton.click();}}
 ],changes.map(c=>c.name));
}
window.reportCompared=function(changes){if(pendingStartup)startupChoices(pendingStartup,changes);};
function requestNew(){pendingStartup=null;ignoredChanges={};lastNotice='';if(window.sketchup)window.sketchup.report_new_selected();}
window.applyNewMHDReport=function(state){state.model_key=window.MHD_REPORT_MODEL_KEY;pendingStartup=null;v8Restore(state,null,false);initialReady=true;ignoredChanges={};lastNotice='';watch();persist();};
newButton.onclick=()=>modal('تقرير جديد','التقرير الجديد هيقرأ الوحدات المحددة من البداية. احفظ ملف التقرير الحالي لو عاوز تحتفظ بنسخة مستقلة.',[{text:'ابدأ من الوحدات المحددة',run:requestNew},{text:'الرجوع للتقرير الحالي',run:()=>{}}]);
function updateChanged(changes){if(window.sketchup)window.sketchup.report_update_ids(JSON.stringify(changes.map(c=>c.pid)));}
window.reportModelChanged=function(changes,force=false){
 latestChanges=changes.filter(c=>force||ignoredChanges[c.pid]!==c.signature);
 if(!latestChanges.length){if(force)window.reportSaveStatus(true,'بيانات التقرير مطابقة للموديل');return;}
 const key=JSON.stringify(latestChanges.map(c=>[c.pid,c.signature]));if(decisionOpen||pendingStartup||(!force&&lastNotice===key))return;lastNotice=key;
 const captured=latestChanges.slice();
 modal('تم تعديل وحدات في SketchUp','تحديث البيانات هيحافظ على باقي التقرير والتنسيق والملاحظات. خانات القطع والمقاسات للوحدات المتغيرة هتتبدل بالقراءة الجديدة.',[
 {text:'تحديث الوحدات المتغيرة داخل التقرير',run:()=>updateChanged(captured)},
 {text:'الاحتفاظ بالتقرير الحالي بدون تحديث',run:()=>{captured.forEach(c=>ignoredChanges[c.pid]=c.signature);persist();}},
 {text:'بدء تقرير جديد من المحدد',run:requestNew}
 ],captured.map(c=>c.name));
};
window.requestMHDUpdate=function(){watch();if(window.sketchup)window.sketchup.report_check_now();};updateButton.onclick=window.requestMHDUpdate;
const v8Update=window.updateMHDUnits;
window.updateMHDUnits=function(updates){
 const deletedUnits=updates.filter(u=>u.deleted);deletedUnits.forEach(u=>{const row=Array.from(document.querySelectorAll('tr[data-unit-pid]')).find(r=>r.dataset.unitPid===u.pid);if(row){deleted.push({node:row,parent:row.parentNode,next:row.nextSibling});row.remove();}});
 v8Update(updates.filter(u=>!u.deleted));updates.forEach(u=>delete ignoredChanges[u.pid]);lastNotice='';watch();persist();
};
window.restoreMHDLocalOnly=function(){let doc=null;try{doc=JSON.parse(localStorage.getItem(recoveryKey)||'null');}catch(error){}window.offerMHDReport(doc);};
watch();

['remove-table','undo-table','remove-row','add-table','add-row'].forEach(id=>{const old=$(id).onclick;$(id).onclick=function(event){old.call(this,event);watch();};});
window.applyMHDOrder=function(orders){
 document.querySelectorAll('.report-table tbody').forEach(body=>{
  const rows=Array.from(body.rows), units=rows.filter(row=>row.dataset.unitPid);
  units.forEach(row=>{const value=orders[row.dataset.unitPid];if(value!==undefined)row.dataset.unitOrder=String(value);});
  const sorted=units.map((row,i)=>({row,i,order:Number(row.dataset.unitOrder||9999)})).sort((a,b)=>a.order-b.order||a.i-b.i).map(item=>item.row);
  if(units.some((row,i)=>row!==sorted[i])){const slots=units.map(row=>{const slot=document.createComment('unit-slot');row.replaceWith(slot);return slot;});slots.forEach((slot,i)=>slot.replaceWith(sorted[i]));}
  Array.from(body.rows).forEach((row,i)=>{if(row.cells[0]&&row.cells[0].textContent!==String(i+1))row.cells[0].textContent=String(i+1);});
 });
};
const orderedWatch=watch;watch=function(){orderedWatch();const ids=Array.from(document.querySelectorAll('tr[data-unit-pid]')).map(row=>row.dataset.unitPid);if(window.sketchup&&window.sketchup.report_sort_order)window.sketchup.report_sort_order(JSON.stringify(ids));};

document.body.style.removeProperty('padding-top');
window.addEventListener('focus',()=>{if(window.sketchup&&window.sketchup.report_check_pending)window.sketchup.report_check_pending();});
const accessoryButton=document.createElement('button');accessoryButton.type='button';accessoryButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_DD916149CA8F\u0002');accessoryButton.className='primary';updateButton.parentElement.appendChild(accessoryButton);
accessoryButton.onclick=()=>{
 if(reportModelKey!==window.MHD_REPORT_MODEL_KEY){window.reportSaveStatus(false,MHD_REPORT_TPL('\u0001T:TEXT_C65D5908BF9C\u0002'));return;}
 const ids=Array.from(new Set(Array.from(document.querySelectorAll('tr[data-unit-pid]')).map(row=>row.dataset.unitPid)));
 if(!ids.length){window.reportSaveStatus(false,'أضف وحدات للتقرير أولًا');return;}
 accessoryButton.disabled=true;accessoryButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_6BC0EECE0987\u0002');
 if(window.sketchup&&window.sketchup.report_accessories)window.sketchup.report_accessories(JSON.stringify(ids));
};
window.showMHDAccessories=function(html,error){
 accessoryButton.disabled=false;accessoryButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_DD916149CA8F\u0002');
 if(error){window.reportSaveStatus(false,error);return;}
 const template=document.createElement('template');template.innerHTML=safeHTML(html);const section=template.content.firstElementChild;if(!section)return;
 document.querySelectorAll('[data-accessory-report]').forEach(old=>old.remove());
 const last=sections().slice(-1)[0];if(last)last.after(section);else document.querySelector('.header').after(section);
 refreshPicker();select(section);section.scrollIntoView({behavior:'smooth',block:'start'});queueSave();
};

window.markMHDAccessoriesStale=function(){document.querySelectorAll('[data-accessory-report]').forEach(section=>{if(section.querySelector('.accessory-stale'))return;const note=document.createElement('p');note.className='accessory-stale';note.style.cssText='padding:12px;background:#fff3cc;color:#765400';note.textContent=MHD_REPORT_TPL('\u0001T:TEXT_52B289FE7E64\u0002');section.querySelector('.section-title').after(note);});};

let accessoryPrices={},accessoryCatalog=[],accessorySource=null,priceVisible=true,pricePagePending=false,lastSelectionKey='',pendingSelection=null;
const priceButton=document.createElement('button');priceButton.type='button';priceButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_19EE8A0EDAC5\u0002');accessoryButton.after(priceButton);
const pricingStyle=document.createElement('style');pricingStyle.textContent=`
#accessory-page,#accessory-prices-page{position:fixed;inset:0;z-index:150;background:#f3f7fa;overflow:auto;padding:22px;direction:rtl}#accessory-page[hidden],#accessory-prices-page[hidden]{display:none}
.accessory-page-bar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;background:#12394a;color:white;padding:14px;border-radius:12px;margin-bottom:16px}.accessory-page-bar h2{margin:0;flex:1;min-width:200px;font-size:20px}.accessory-page-bar button{background:#087f82}.price-card{background:#fff;padding:18px;border-radius:12px}.price-card input,.price-card select{padding:7px;width:100%;border:1px solid #c5d5de;border-radius:5px}.price-card table{table-layout:auto}.price-message{padding:12px;color:#865900}.prices-hidden .price-col,.prices-hidden .accessory-cost-summary{display:none!important}.accessory-cost-summary{padding:16px;background:#e5f5ee;font-weight:bold;font-size:18px}.accessory-total-row td{font-weight:bold;background:#e5f5ee}.price-card th{white-space:nowrap}
@media print{#accessory-page{display:none!important}body.accessory-print{padding:0!important}body.accessory-print> *:not(#accessory-page){display:none!important}body.accessory-print #accessory-page{position:static!important;inset:auto;padding:0;overflow:visible;background:white;display:block!important}body.accessory-print .accessory-page-bar{display:none!important}body.accessory-print .section-wrap{outline:none!important;border:0!important}#accessory-prices-page{display:none!important}}
`;document.head.appendChild(pricingStyle);
const accessoryPage=document.createElement('div');accessoryPage.id='accessory-page';accessoryPage.hidden=true;accessoryPage.innerHTML=MHD_REPORT_TPL('<div class="accessory-page-bar"><h2>\u0001H:TEXT_DD916149CA8F\u0002</h2><button id="accessory-pricing-open">\u0001H:TEXT_19EE8A0EDAC5\u0002</button><button id="accessory-toggle-prices">\u0001H:TEXT_63F097D38CC7\u0002</button><button id="accessory-print">\u0001H:TEXT_85ADA0D31A1D\u0002</button><button id="accessory-attach">\u0001H:TEXT_3D1B1CD887EB\u0002</button><button id="accessory-back">\u0001H:TEXT_EA69E7B8FE9A\u0002</button></div><div id="accessory-page-content"></div>');document.body.appendChild(accessoryPage);
const pricesPage=document.createElement('div');pricesPage.id='accessory-prices-page';pricesPage.style.zIndex='160';pricesPage.hidden=true;pricesPage.innerHTML=MHD_REPORT_TPL('<div class="accessory-page-bar"><h2>\u0001H:TEXT_19EE8A0EDAC5\u0002</h2><button id="prices-save">\u0001H:TEXT_D9157013254C\u0002</button><button id="prices-export">\u0001H:TEXT_BFBF8269A25C\u0002</button><button id="prices-import">\u0001H:TEXT_640F9F8330A2\u0002</button><button id="prices-back">\u0001H:COMMON_BACK\u0002</button></div><div class="price-card"><p>\u0001H:TEXT_5FAE6D19C6FA\u0002</p><div id="price-fields"></div><div id="price-message" class="price-message"></div></div>');document.body.appendChild(pricesPage);
function money(value){return Number(value).toLocaleString('en-US',{minimumFractionDigits:numberPrecision,maximumFractionDigits:numberPrecision});}
function defaultPrice(name){return /رجل.*بلاست/.test(name)?{mode:'pack',pack_size:4,whole_packs:true,price:null}:{mode:/بلت|وزر|حفر/.test(name)?'meter':'piece',pack_size:1,whole_packs:true,price:null};}
function computeAccessoryCost(quantity,pieces,price){
 const size=Math.max(1,Number(price.pack_size)||1);let billable=price.mode==='meter'?Number(quantity):Number(pieces);
 if(price.mode==='pack'){billable=Number(pieces)/size;if(price.whole_packs!==false)billable=Math.ceil(billable-1e-10);}
 const rate=price.price===null||price.price===''||price.price===undefined?null:Number(price.price);
 return {billable,rate,total:rate===null?null:billable*rate};
}
function priceSection(section){
 section.classList.toggle('prices-hidden',!priceVisible);section.querySelectorAll('.price-col,.accessory-cost-summary,.accessory-total-row').forEach(el=>el.remove());
 const table=section.querySelector('table'),head=table&&table.querySelector('thead tr');if(!head)return;['سعر الوحدة '+currencySymbol(),'التكلفة '+currencySymbol()].forEach(title=>{const th=document.createElement('th');th.className='price-col';th.textContent=title;head.appendChild(th);});
 let total=0,missing=0;
 table.querySelectorAll('tbody tr[data-accessory-name]').forEach(row=>{
 const name=row.dataset.accessoryName,entry=effectiveAccessoryPrice(name,row),calc=computeAccessoryCost(Number(row.dataset.accessoryQuantity),Number(row.dataset.accessoryPieces),entry);
 const unit=entry.mode==='meter'?'متر طولي':entry.mode==='pack'?'طقم ('+entry.pack_size+' قطع)':'قطعة';
 const quantityText=Number(calc.billable.toFixed(3)).toString();
 if(head.cells[2])head.cells[2].textContent=MHD_REPORT_TPL('\u0001T:TEXT_D0BB81F8194A\u0002');
 if(head.cells[3])head.cells[3].textContent=MHD_REPORT_TPL('\u0001T:TEXT_1BBB5C6E7475\u0002');
 if(head.cells[4])head.cells[4].textContent=MHD_REPORT_TPL('\u0001T:TEXT_DAD20B6F6D38\u0002');
 row.cells[2].textContent=entry.mode==='meter'?Number(Number(row.dataset.accessoryQuantity).toFixed(3)).toString():row.dataset.accessoryPieces+MHD_REPORT_TPL(' \u0001T:TEXT_848514ABBBFD\u0002');
 row.cells[3].textContent=unit;
 row.cells[4].textContent=entry.mode==='pack'?quantityText+MHD_REPORT_TPL(' \u0001T:TEXT_663173F1DAA4\u0002'):entry.mode==='meter'?quantityText+MHD_REPORT_TPL(' \u0001T:TEXT_10B928080354\u0002')+row.dataset.accessoryPieces+MHD_REPORT_TPL(' \u0001T:TEXT_FCB7F19E689E\u0002'):quantityText+MHD_REPORT_TPL(' \u0001T:TEXT_848514ABBBFD\u0002');
 row.cells[4].title=entry.mode==='pack'?(entry.whole_packs!==false?MHD_REPORT_TPL('\u0001T:TEXT_3EBC78A3FD42\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_549BC7BA84DD\u0002')):'';
 const values=[calc.rate===null?MHD_REPORT_TPL('\u0001T:TEXT_5A0374F3FF5A\u0002'):money(calc.rate),calc.total===null?'—':money(calc.total)];values.forEach(value=>{const cell=row.insertCell();cell.className='price-col';cell.textContent=value;if(row.cells.length===7){cell.contentEditable='true';cell.dataset.reportPriceEdit='true';cell.textContent=calc.rate===null?'':money(calc.rate);cell.title=MHD_REPORT_TPL('\u0001T:TEXT_4372D71AAAB0\u0002');cell.style.background='#fff8df';}});if(calc.total===null)missing++;else total+=calc.total;
 });
 const summary=document.createElement('div');summary.className='accessory-cost-summary';summary.textContent=MHD_REPORT_TPL('\u0001T:TEXT_F8C88EB3CBA9\u0002 ')+money(total)+' '+currencySymbol()+(missing?' — '+missing+MHD_REPORT_TPL(' \u0001T:TEXT_6CA398D5F09B\u0002'):'');section.appendChild(summary);
}
function renderAccessoryPage(){if(!accessorySource)return;const content=$('accessory-page-content');content.replaceChildren(accessorySource.cloneNode(true));priceSection(content.firstElementChild);}
window.receiveAccessoryPrices=function(payload){accessoryPrices=payload.prices||{};accessoryCatalog=payload.names||[];if(accessorySource)renderAccessoryPage();if(pricePagePending){pricePagePending=false;renderPriceFields();}};
window.accessoryPricesSaved=function(prices){accessoryPrices=prices;pricesPage.hidden=true;renderAccessoryPage();document.querySelectorAll('body > .section-wrap[data-accessory-report]').forEach(priceSection);queueSave();window.reportSaveStatus(true,'تم حفظ أسعار الإكسسوارات على الجهاز');};
window.accessoryPriceError=function(message){$('price-message').textContent=message;pricesPage.hidden=false;};
window.importAccessoryPrices=function(prices){accessoryPrices=prices;renderPriceFields();$('price-message').textContent=MHD_REPORT_TPL('\u0001T:TEXT_9F9018B929CB\u0002');};
function renderPriceFields(){
 const names=new Set([...accessoryCatalog,...Object.keys(accessoryPrices)]);if(accessorySource)accessorySource.querySelectorAll('[data-accessory-name]').forEach(row=>names.add(row.dataset.accessoryName));
 const table=document.createElement('table');table.innerHTML=MHD_REPORT_TPL('<thead><tr><th>\u0001H:TEXT_0BE76B046A76\u0002</th><th>\u0001H:TEXT_540ECF1B863C\u0002</th><th>\u0001H:TEXT_D33B9320F468\u0002</th><th>\u0001H:TEXT_EFD15ECF3507\u0002</th><th>\u0001H:TEXT_259862E8B313\u0002</th></tr></thead><tbody></tbody>');const body=table.querySelector('tbody');
 Array.from(names).sort().forEach(name=>{const entry=accessoryPrices[name]||defaultPrice(name);const row=body.insertRow();row.dataset.priceName=name;row.insertCell().textContent=name;
 const mode=document.createElement('select');[['piece',MHD_REPORT_TPL('\u0001T:TEXT_486B48BA67CB\u0002')],['meter',MHD_REPORT_TPL('\u0001T:TEXT_9E23A62DF30D\u0002')],['pack',MHD_REPORT_TPL('\u0001T:TEXT_DBD20D83E803\u0002')]].forEach(([value,label])=>{const o=document.createElement('option');o.value=value;o.textContent=label;mode.appendChild(o);});mode.value=entry.mode;mode.dataset.field='mode';row.insertCell().appendChild(mode);
 const size=document.createElement('input');size.type='number';size.min='1';size.step='1';size.value=entry.pack_size||1;size.dataset.field='pack_size';row.insertCell().appendChild(size);
 const whole=document.createElement('input');whole.type='checkbox';whole.checked=entry.whole_packs!==false;whole.dataset.field='whole_packs';row.insertCell().appendChild(whole);
 const price=document.createElement('input');price.type='number';price.min='0';price.step='any';price.value=entry.price??'';price.placeholder=MHD_REPORT_TPL('\u0001T:TEXT_5A0374F3FF5A\u0002');price.dataset.field='price';row.insertCell().appendChild(price);
 mode.onchange=()=>{size.disabled=mode.value!=='pack';whole.disabled=mode.value!=='pack';};mode.onchange();
 });$('price-fields').replaceChildren(table);$('price-message').textContent='';
}
function gatherPrices(){const result={...accessoryPrices};$('price-fields').querySelectorAll('tr[data-price-name]').forEach(row=>{const field=key=>row.querySelector('[data-field="'+key+'"]');const raw=field('price').value;const rate=raw===''?null:Number(raw);if(rate!==null&&(!Number.isFinite(rate)||rate<0))throw Error('راجع سعر '+row.dataset.priceName);const size=Number(field('pack_size').value);if(!Number.isInteger(size)||size<1)throw Error('عدد قطع الطقم يجب أن يكون عددًا صحيحًا موجبًا');result[row.dataset.priceName]={mode:field('mode').value,pack_size:size,whole_packs:field('whole_packs').checked,price:rate};});return result;}
function openPrices(){renderPriceFields();pricesPage.hidden=false;pricePagePending=true;if(window.sketchup)window.sketchup.accessory_price_catalog();}
priceButton.onclick=openPrices;$('accessory-pricing-open').onclick=openPrices;
$('prices-save').onclick=()=>{try{if(window.sketchup)window.sketchup.accessory_prices_save(JSON.stringify(currencyPricePayload()));}catch(error){window.accessoryPriceError(error.message);}};
$('prices-export').onclick=()=>{try{if(window.sketchup)window.sketchup.accessory_prices_export(JSON.stringify(currencyPricePayload()));}catch(error){window.accessoryPriceError(error.message);}};
$('prices-import').onclick=()=>{if(window.sketchup)window.sketchup.accessory_prices_import();};$('prices-back').onclick=()=>{pricesPage.hidden=true;pricePagePending=false;};
window.showMHDAccessories=function(html,error){accessoryButton.disabled=false;accessoryButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_DD916149CA8F\u0002');if(error){window.reportSaveStatus(false,error);return;}const template=document.createElement('template');template.innerHTML=safeHTML(html);accessorySource=template.content.firstElementChild;if(!accessorySource)return;renderAccessoryPage();accessoryPage.hidden=false;if(window.sketchup)window.sketchup.accessory_price_catalog();};
$('accessory-back').onclick=()=>accessoryPage.hidden=true;
$('accessory-toggle-prices').onclick=()=>{priceVisible=!priceVisible;$('accessory-toggle-prices').textContent=priceVisible?MHD_REPORT_TPL('\u0001T:TEXT_63F097D38CC7\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_5F70B7513632\u0002');renderAccessoryPage();};
$('accessory-print').onclick=()=>{document.body.classList.add('accessory-print');window.print();};window.addEventListener('afterprint',()=>document.body.classList.remove('accessory-print'));
$('accessory-attach').onclick=()=>{const source=$('accessory-page-content').firstElementChild;if(!source)return;document.querySelectorAll('body > [data-accessory-report]').forEach(el=>el.remove());const copy=source.cloneNode(true);copy.id='attached-accessory-report';const last=sections().filter(s=>!s.closest('#accessory-page')).slice(-1)[0];if(last)last.after(copy);else document.querySelector('.header').after(copy);refreshPicker();queueSave();window.reportSaveStatus(true,'تمت إضافة تقرير تكلفة تحت الوحدات');};
// The independent page is excluded from unit tables, snapshots, numbering, CSV, and editor selection.
sections=function(){return Array.from(document.querySelectorAll('body > .section-wrap'));};
let lastSelectionOffered='';
function showSelectionNotice(){if(!pendingSelection||decisionOpen||pendingStartup)return;const ids=pendingSelection;pendingSelection=null;const key=ids.join(',');if(key===lastSelectionOffered)return;lastSelectionOffered=key;modal('تحديد الوحدات اتغيّر','التحديد الحالي في SketchUp مختلف عن وحدات التقرير. تقدر تعيد توليد التقرير من المحدد أو تحتفظ بالتقرير الحالي.',[{text:'توليد تقرير من التحديد الحالي',run:requestNew},{text:'تجاهل والاحتفاظ بالتقرير الحالي',run:()=>{}}]);}
window.reportSelectionChanged=function(ids){const selected=ids.slice().sort(),key=selected.join(',');if(key===lastSelectionKey)return;lastSelectionKey=key;const report=Array.from(new Set(Array.from(document.querySelectorAll('body > .section-wrap tr[data-unit-pid]')).map(row=>row.dataset.unitPid))).sort();if(key===report.join(',')){pendingSelection=null;lastSelectionOffered='';return;}pendingSelection=selected;showSelectionNotice();};
document.addEventListener('click',()=>{if(pendingSelection)setTimeout(showSelectionNotice,0);});


let reportPriceOverrides={},currentCurrency='EGP',cachedCurrency='EGP',reportCurrencyChosen=false;
function currencySymbol(code=currentCurrency){try{return new Intl.NumberFormat('ar-EG',{style:'currency',currency:code,currencyDisplay:'narrowSymbol'}).formatToParts(0).find(part=>part.type==='currency').value.replace(/[\u200e\u200f]/g,'');}catch(error){return code;}}
function currencyPricePayload(){return {format:'MHDESIGN_ACCESSORY_PRICES',version:1,currency:currentCurrency,prices:gatherPrices()};}
function effectiveAccessoryPrice(name,row){const base={...(accessoryPrices[name]||defaultPrice(name))};if(Object.prototype.hasOwnProperty.call(reportPriceOverrides,name))base.price=reportPriceOverrides[name];return base;}
function parseReportPrice(text){const digits='٠١٢٣٤٥٦٧٨٩',persian='۰۱۲۳۴۵۶۷۸۹';let value=String(text).trim().replace(/[٠-٩]/g,d=>digits.indexOf(d)).replace(/[۰-۹]/g,d=>persian.indexOf(d)).replace(/[\u200e\u200f\u061c]/g,'').replace(/٬/g,'').replace(/٫/g,'.').replace(/,/g,'');if(!value)return null;const number=Number(value);if(!Number.isFinite(number)||number<0)throw Error('اكتب سعرًا صحيحًا موجبًا أو صفرًا');return number;}
const currencyLabel=document.createElement('label');currencyLabel.style.cssText='display:flex;align-items:center;gap:10px;padding:12px;font-weight:bold';currencyLabel.textContent=MHD_REPORT_TPL('\u0001T:TEXT_30CE3A1DAE2C\u0002');
const currencySelect=document.createElement('select');currencySelect.id='accessory-currency';currencySelect.style.cssText='max-width:360px;width:100%;padding:8px';
let currencies=[];try{currencies=Intl.supportedValuesOf('currency');}catch(error){currencies='AED AFN ALL AMD AOA ARS AUD AWG AZN BAM BBD BDT BGN BHD BIF BMD BND BOB BRL BSD BTN BWP BYN BZD CAD CDF CHF CLP CNY COP CRC CUP CVE CZK DJF DKK DOP DZD EGP ERN ETB EUR FJD FKP GBP GEL GHS GIP GMD GNF GTQ GYD HKD HNL HTG HUF IDR ILS INR IQD IRR ISK JMD JOD JPY KES KGS KHR KMF KRW KWD KYD KZT LAK LBP LKR LRD LSL LYD MAD MDL MGA MKD MMK MNT MOP MRU MUR MVR MWK MXN MYR MZN NAD NGN NIO NOK NPR NZD OMR PAB PEN PGK PHP PKR PLN PYG QAR RON RSD RUB RWF SAR SBD SCR SDG SEK SGD SHP SLE SOS SRD SSP STN SYP SZL THB TJS TMT TND TOP TRY TTD TWD TZS UAH UGX USD UYU UZS VES VND VUV WST XAF XCD XOF XPF YER ZAR ZMW'.split(' ');}
let currencyNames=null;try{currencyNames=new Intl.DisplayNames(['ar'],{type:'currency'});}catch(error){}
currencies.forEach(code=>{const o=document.createElement('option');o.value=code;o.textContent=currencySymbol(code)+' — '+code+(currencyNames?' — '+currencyNames.of(code):'');currencySelect.appendChild(o);});currencySelect.value=currentCurrency;currencyLabel.appendChild(currencySelect);$('price-fields').before(currencyLabel);
function repriceAll(){renderAccessoryPage();document.querySelectorAll('body > .section-wrap[data-accessory-report]').forEach(priceSection);}
currencySelect.onchange=()=>{currentCurrency=currencySelect.value;reportCurrencyChosen=true;repriceAll();queueSave();};
const currencyReceive=window.receiveAccessoryPrices;window.receiveAccessoryPrices=function(payload){cachedCurrency=payload.currency||'EGP';if(!reportCurrencyChosen)currentCurrency=cachedCurrency;currencySelect.value=currentCurrency;currencyReceive(payload);};
const currencySaved=window.accessoryPricesSaved;window.accessoryPricesSaved=function(payload){if(payload.prices){currentCurrency=payload.currency||currentCurrency;cachedCurrency=currentCurrency;reportCurrencyChosen=true;currencySelect.value=currentCurrency;currencySaved(payload.prices);}else currencySaved(payload);};
const currencyImport=window.importAccessoryPrices;window.importAccessoryPrices=function(payload){if(payload.prices){currentCurrency=payload.currency||'EGP';reportCurrencyChosen=true;currencySelect.value=currentCurrency;currencyImport(payload.prices);}else currencyImport(payload);};
function recalcAccessoryTotals(section){let total=0,missing=0;section.querySelectorAll('tbody tr[data-accessory-name]').forEach(row=>{const entry=effectiveAccessoryPrice(row.dataset.accessoryName,row),calc=computeAccessoryCost(Number(row.dataset.accessoryQuantity),Number(row.dataset.accessoryPieces),entry);if(row.cells[7])row.cells[7].textContent=calc.total===null?'—':money(calc.total);if(calc.total===null)missing++;else total+=calc.total;});updateKitchenSummary(section,total,missing);}
document.addEventListener('input',event=>{const cell=event.target.closest('[data-report-price-edit]');if(!cell)return;const row=cell.closest('tr');try{const price=parseReportPrice(cell.textContent);reportPriceOverrides[row.dataset.accessoryName]=price;cell.removeAttribute('aria-invalid');cell.style.outline='';recalcAccessoryTotals(row.closest('.accessory-report'));queueSave();}catch(error){cell.setAttribute('aria-invalid','true');cell.style.outline='2px solid #c44';}});
document.addEventListener('focusout',event=>{const cell=event.target.closest('[data-report-price-edit]');if(!cell)return;if(cell.getAttribute('aria-invalid')==='true'){const entry=effectiveAccessoryPrice(cell.closest('tr').dataset.accessoryName);cell.textContent=entry.price===null?'':String(entry.price);cell.removeAttribute('aria-invalid');cell.style.outline='';}repriceAll();queueSave();});
const resetKitchenPrices=document.createElement('button');resetKitchenPrices.textContent=MHD_REPORT_TPL('\u0001T:TEXT_B842A3D4B3A1\u0002');resetKitchenPrices.type='button';$('accessory-toggle-prices').after(resetKitchenPrices);resetKitchenPrices.onclick=()=>{reportPriceOverrides={};repriceAll();queueSave();};
const pricingHelp=document.createElement('p');pricingHelp.textContent=MHD_REPORT_TPL('\u0001T:TEXT_BE3471DD6D25\u0002');pricingHelp.style.cssText='padding:8px;color:#58707d';$('accessory-page-content').before(pricingHelp);
const currencySnapshot=snapshot;snapshot=function(){const doc=currencySnapshot();doc.state.accessory_pricing={overrides:reportPriceOverrides,currency:currentCurrency,price_visible:priceVisible};if(accessorySource)doc.state.accessory_source=accessorySource.outerHTML;return doc;};
window.restoreAccessoryPricing=function(state){const pricing=state.accessory_pricing||{};reportPriceOverrides=pricing.overrides&&typeof pricing.overrides==='object'?pricing.overrides:{};currentCurrency=pricing.currency||cachedCurrency;reportCurrencyChosen=!!pricing.currency;priceVisible=pricing.price_visible!==false;currencySelect.value=currentCurrency;if(state.accessory_source){const template=document.createElement('template');template.innerHTML=safeHTML(state.accessory_source);accessorySource=template.content.firstElementChild;}else accessorySource=null;$('accessory-toggle-prices').textContent=priceVisible?MHD_REPORT_TPL('\u0001T:TEXT_63F097D38CC7\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_5F70B7513632\u0002');repriceAll();};
const currencyNew=window.applyNewMHDReport;window.applyNewMHDReport=function(state){reportPriceOverrides={};reportCurrencyChosen=false;currentCurrency=cachedCurrency;accessorySource=null;currencyNew(state);};

let kitchenBoards=[],boardsVisible=true,boardSequence=0;
const boardStyle=document.createElement('style');boardStyle.textContent=`
.board-panel{margin:18px 12px;border:1px solid #ccdbe4;border-radius:10px;overflow:hidden}.board-panel[hidden]{display:none!important}.board-panel h3{margin:0;padding:12px;background:#edf3f8}.board-panel table{table-layout:fixed}.board-panel td[contenteditable=true]{background:#fff8df}.board-panel .board-delete{background:#a34545}.prices-hidden .board-price{display:none!important}
.accessory-cost-summary{display:block;text-align:right;line-height:1.7;padding:18px 22px!important}.kitchen-total-line{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap}.kitchen-total-value{direction:ltr;unicode-bidi:isolate;font-size:24px}.kitchen-total-note{font-size:13px;font-weight:normal;color:#73582b;margin-top:5px}.kitchen-total-breakdown{font-size:13px;font-weight:normal;color:#42685a}
@media print{.board-delete,.board-action-col{display:none!important}}
`;document.head.appendChild(boardStyle);
const addBoardButton=document.createElement('button');addBoardButton.type='button';addBoardButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_CB79EB3B6D76\u0002');$('accessory-attach').before(addBoardButton);
const toggleBoardsButton=document.createElement('button');toggleBoardsButton.type='button';toggleBoardsButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_54C4971B652F\u0002');addBoardButton.after(toggleBoardsButton);
function boardAmount(row){const qty=Number(row.quantity)||0,price=row.price===null||row.price===''||row.price===undefined?null:Number(row.price);return {quantity:qty,price,total:price===null?null:qty*price};}
function kitchenCost(accessoryTotal,accessoryMissing,rows,includeBoards){if(!accessoriesVisible){accessoryTotal=0;accessoryMissing=0;}let boardsTotal=0,boardsMissing=0;if(includeBoards)rows.forEach(row=>{const amount=boardAmount(row);if(amount.quantity<=0)return;if(amount.total===null)boardsMissing++;else boardsTotal+=amount.total;});return {total:accessoryTotal+boardsTotal,accessoryTotal,boardsTotal,missing:accessoryMissing+boardsMissing};}
function renderBoardBlock(section){
 section.querySelectorAll('.board-panel').forEach(el=>el.remove());
 const panel=document.createElement('div');panel.className='board-panel';panel.hidden=!boardsVisible||!kitchenBoards.length;
 const title=document.createElement('h3');title.textContent=MHD_REPORT_TPL('\u0001T:TEXT_D7A400110965\u0002');panel.appendChild(title);
 const table=document.createElement('table');table.className='boards-table';table.innerHTML=MHD_REPORT_TPL('<thead><tr><th>\u0001H:TEXT_5738A202755C\u0002</th><th>\u0001H:TEXT_411E77BA01BD\u0002</th><th class="board-price">\u0001H:TEXT_539CCD853527\u0002</th><th class="board-price">\u0001H:TEXT_4D5BCF198D93\u0002</th><th class="board-action-col">\u0001H:COMMON_DELETE\u0002</th></tr></thead><tbody></tbody>');
 const body=table.querySelector('tbody');kitchenBoards.forEach(board=>{
 const row=body.insertRow();row.dataset.boardId=board.id;
 [['name',board.name],['quantity',board.quantity],['price',board.price??'']].forEach(([field,value])=>{const cell=row.insertCell();cell.contentEditable='true';cell.dataset.boardField=field;cell.textContent=field==='price'&&value!==''?money(value):String(value);if(field==='price')cell.className='board-price';});
 const cost=row.insertCell();cost.className='board-price';cost.dataset.boardCost='true';const amount=boardAmount(board);cost.textContent=amount.total===null?'—':money(amount.total)+' '+currencySymbol();
 const actions=row.insertCell();actions.className='board-action-col';const remove=document.createElement('button');remove.type='button';remove.className='board-delete';remove.dataset.removeBoard=board.id;remove.textContent=MHD_REPORT_TPL('\u0001T:COMMON_DELETE\u0002');actions.appendChild(remove);
 });panel.appendChild(table);const summary=section.querySelector('.accessory-cost-summary');if(summary)summary.before(panel);else section.appendChild(panel);
}
function updateKitchenSummary(section,accessoryTotal,accessoryMissing){
 let summary=section.querySelector('.accessory-cost-summary');if(!summary){summary=document.createElement('div');summary.className='accessory-cost-summary';section.appendChild(summary);}
 const result=kitchenCost(accessoryTotal,accessoryMissing,kitchenBoards,boardsVisible);summary.replaceChildren();
 const line=document.createElement('div');line.className='kitchen-total-line';const label=document.createElement('span');label.textContent=MHD_REPORT_TPL('\u0001T:TEXT_F8C88EB3CBA9\u0002');const amount=document.createElement('bdi');amount.className='kitchen-total-value';amount.textContent=money(result.total)+' '+currencySymbol();line.append(label,amount);summary.appendChild(line);
 if(boardsVisible&&kitchenBoards.length){const breakdown=document.createElement('div');breakdown.className='kitchen-total-breakdown';breakdown.textContent=MHD_REPORT_TPL('\u0001T:TEXT_751DDC044161\u0002 ')+money(result.accessoryTotal)+' '+currencySymbol()+MHD_REPORT_TPL(' \u0001T:TEXT_169CB82ADF4F\u0002 ')+money(result.boardsTotal)+' '+currencySymbol();summary.appendChild(breakdown);}
 if(result.missing){const note=document.createElement('div');note.className='kitchen-total-note';note.textContent=result.missing+MHD_REPORT_TPL(' \u0001T:TEXT_6EE69EF91978\u0002');summary.appendChild(note);}
 summary.dataset.accessorySubtotal=String(accessoryTotal);summary.dataset.accessoryMissing=String(accessoryMissing);
}
const boardBasePriceSection=priceSection;priceSection=function(section){boardBasePriceSection(section);renderBoardBlock(section);recalcAccessoryTotals(section);};
function refreshBoards(){repriceAll();toggleBoardsButton.textContent=boardsVisible?MHD_REPORT_TPL('\u0001T:TEXT_54C4971B652F\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_C1F464BDFBDD\u0002');queueSave();}
addBoardButton.onclick=()=>{kitchenBoards.push({id:'board-'+Date.now()+'-'+(++boardSequence),name:MHD_REPORT_TPL('\u0001T:TEXT_6CEAAA7A3BA7\u0002'),quantity:1,price:null});boardsVisible=true;refreshBoards();};
toggleBoardsButton.onclick=()=>{boardsVisible=!boardsVisible;refreshBoards();};
document.addEventListener('click',event=>{const button=event.target.closest('[data-remove-board]');if(!button)return;const removed=kitchenBoards.find(row=>row.id===button.dataset.removeBoard);if(removed&&removed.material_key)excludedBoardMaterials.add(removed.material_key);kitchenBoards=kitchenBoards.filter(row=>row.id!==button.dataset.removeBoard);refreshBoards();});
document.addEventListener('input',event=>{const cell=event.target.closest('[data-board-field]');if(!cell)return;const row=cell.closest('[data-board-id]'),board=kitchenBoards.find(item=>item.id===row.dataset.boardId);if(!board)return;const field=cell.dataset.boardField;try{if(field==='name')board.name=cell.textContent;else {const value=parseReportPrice(cell.textContent);board[field]=field==='quantity'?(value??0):value;}cell.removeAttribute('aria-invalid');cell.style.outline='';const amount=boardAmount(board),cost=row.querySelector('[data-board-cost]');if(cost)cost.textContent=amount.total===null?'—':money(amount.total)+' '+currencySymbol();recalcAccessoryTotals(row.closest('.accessory-report'));queueSave();}catch(error){cell.setAttribute('aria-invalid','true');cell.style.outline='2px solid #c44';}});
document.addEventListener('focusout',event=>{if(!event.target.closest('[data-board-field]'))return;refreshBoards();});
const boardsSnapshot=snapshot;snapshot=function(){const doc=boardsSnapshot();doc.state.kitchen_boards={visible:boardsVisible,rows:kitchenBoards};return doc;};
const boardsRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){const data=state.kitchen_boards||{};kitchenBoards=Array.isArray(data.rows)?data.rows.map((row,i)=>({id:String(row.id||'board-restored-'+i),material_key:typeof row.material_key==='string'?row.material_key:null,auto_name:typeof row.auto_name==='string'?row.auto_name:null,name:String(row.name||''),quantity:Math.max(0,Number(row.quantity)||0),price:row.price===null||row.price===undefined?null:Math.max(0,Number(row.price)||0)})):[];boardsVisible=data.visible!==false;toggleBoardsButton.textContent=boardsVisible?MHD_REPORT_TPL('\u0001T:TEXT_54C4971B652F\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_C1F464BDFBDD\u0002');boardsRestore(state);};

let excludedBoardMaterials=new Set();
function boardMaterialKey(name){return String(name).trim().replace(/\s+/g,' ').toUpperCase();}
function reportBoardMaterials(){
 const materials=new Map();document.querySelectorAll('body > .section-wrap:not([data-accessory-report]) .mat-title[data-material-original]').forEach(el=>{
  const original=el.dataset.materialOriginal.trim();if(!original||/^(بدون خامة|ضلفه زجاج|ضلفة زجاج)$/.test(original))return;
  const key=boardMaterialKey(original);if(!materials.has(key))materials.set(key,{key,original,name:el.textContent.trim()||original});
 });return Array.from(materials.values());
}
function seedReportBoards(restoreDeleted=false){
 if(restoreDeleted)excludedBoardMaterials.clear();let added=0;
 reportBoardMaterials().forEach(material=>{
  if(excludedBoardMaterials.has(material.key))return;
  let existing=kitchenBoards.find(board=>board.material_key===material.key||(!board.material_key&&boardMaterialKey(board.name)===boardMaterialKey(material.name)));
  if(existing){existing.material_key=material.key;if(!existing.auto_name)existing.auto_name=existing.name;return;}
  kitchenBoards.push({id:'board-auto-'+Date.now()+'-'+(++boardSequence),name:material.name,quantity:0,price:null,material_key:material.key,auto_name:material.name});added++;
 });return added;
}
const detectBoardButton=document.createElement('button');detectBoardButton.type='button';detectBoardButton.textContent=MHD_REPORT_TPL('\u0001T:TEXT_530CFACC1474\u0002');detectBoardButton.title=MHD_REPORT_TPL('\u0001T:TEXT_1409B4E467BD\u0002');addBoardButton.before(detectBoardButton);detectBoardButton.onclick=()=>{seedReportBoards(true);refreshBoards();};
const autoBoardsShow=window.showMHDAccessories;window.showMHDAccessories=function(html,error){if(!error)seedReportBoards();autoBoardsShow(html,error);if(!error)queueSave();};
const autoBoardsRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){excludedBoardMaterials=new Set((state.kitchen_boards&&state.kitchen_boards.excluded_materials)||[]);autoBoardsRestore(state);seedReportBoards();repriceAll();};
const autoBoardsSnapshot=snapshot;snapshot=function(){const doc=autoBoardsSnapshot();doc.state.kitchen_boards.excluded_materials=Array.from(excludedBoardMaterials);return doc;};
const autoBoardsUpdate=window.updateMHDUnits;window.updateMHDUnits=function(updates){autoBoardsUpdate(updates);if(seedReportBoards()){repriceAll();queueSave();}};
// Share the same toolbar structure and colors as the unit editor.
const unifiedStyle=document.createElement('style');unifiedStyle.textContent=`
.report-page-toolbar{background:#fff;border:1px solid #dce5eb;border-radius:12px;overflow:hidden;box-shadow:0 4px 18px #0002;margin-bottom:22px;color:#203445}.report-page-toolbar .editor-brand{background:#12394a;color:#fff;padding:12px 18px;display:flex;justify-content:space-between;gap:12px}.report-page-toolbar .editor-brand strong{font-size:17px}.report-page-toolbar .editor-groups{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr))}.report-page-toolbar .editor-group{padding:12px;border-left:1px solid #e3eaef;display:flex;gap:7px;align-items:center;flex-wrap:wrap;min-width:0}.report-page-toolbar .editor-group b{display:block;width:100%;font-size:11px;color:#64808d;margin-bottom:3px}.report-page-toolbar button{background:#edf3f6;color:#183c4b;padding:8px 11px;border:1px solid #d7e3e9;font-size:12px;white-space:nowrap;margin:0}.report-page-toolbar button.primary{background:#087f82;color:#fff;border-color:#087f82}.report-page-toolbar .toolbar-note{display:block;color:#627d8a;padding:8px 16px;background:#f7fafb;font-size:11px}.report-page-toolbar .toolbar-status{font-size:11px}.report-page-toolbar label{display:flex;align-items:center;gap:6px;font-size:12px}.report-page-toolbar select,.report-page-toolbar input{padding:5px;border:1px solid #abc;border-radius:5px}.board-panel .board-source-note{padding:10px 12px;color:#627d8a;font-size:12px;margin:0}
@media print{.report-page-toolbar,.accessory-page-help{display:none!important}}
`;document.head.appendChild(unifiedStyle);
function makePageToolbar(page,title,groupDefinitions,note){
 const legacy=page.querySelector('.accessory-page-bar');const toolbar=document.createElement('div');toolbar.className='report-page-toolbar';const top=document.createElement('div');top.className='editor-brand';const heading=document.createElement('strong');heading.textContent='MHDESIGN · '+title;top.appendChild(heading);const saveState=document.createElement('span');saveState.className='toolbar-status';saveState.textContent='';top.appendChild(saveState);toolbar.appendChild(top);
 const groupArea=document.createElement('div');groupArea.className='editor-groups';toolbar.appendChild(groupArea);page.insertBefore(toolbar,legacy);
 groupDefinitions.forEach(([label,controls])=>{const box=document.createElement('div');box.className='editor-group';const titleNode=document.createElement('b');titleNode.textContent=label;box.appendChild(titleNode);groupArea.appendChild(box);controls.forEach(control=>{if(control)box.appendChild(control);});});
 const help=document.createElement('div');help.className='toolbar-note';help.textContent=note;toolbar.appendChild(help);if(legacy)legacy.remove();return {toolbar,saveState};
}
const accessoryToolbar=makePageToolbar(accessoryPage,MHD_REPORT_TPL('\u0001T:TEXT_5C14BD4FA913\u0002'),[
 [MHD_REPORT_TPL('\u0001T:TEXT_4EC793C37034\u0002'),[$('accessory-print'),$('accessory-attach'),$('accessory-back')]],
 ['الأسعار',[$('accessory-pricing-open'),$('accessory-toggle-prices'),resetKitchenPrices]],
 ['الألواح',[detectBoardButton,addBoardButton,toggleBoardsButton]]
],'أسماء الألواح تُقرأ من خامات تقرير الوحدات. أدخل العدد والسعر يدويًا؛ الكمية صفر تعني أن عدد الألواح لم يُحدد بعد.');
$('accessory-print').classList.add('primary');$('accessory-attach').classList.add('primary');
const pricesToolbar=makePageToolbar(pricesPage,'أسعار الإكسسوارات',[
 ['قائمة الأسعار',[$('prices-save'),$('prices-export'),$('prices-import'),$('prices-back')]],
 ['العملة',[currencyLabel]]
],'الأسعار الأساسية محفوظة على الجهاز. تعديل سعر الوحدة داخل التقرير يخص المطبخ الحالي فقط.');$('prices-save').classList.add('primary');currencyLabel.style.padding='0';
pricingHelp.classList.add('accessory-page-help');
const unifiedSaveStatus=window.reportSaveStatus;window.reportSaveStatus=function(ok,message){unifiedSaveStatus(ok,message);accessoryToolbar.saveState.textContent=status.textContent;};


// Keep board controls next to their table, outside the hideable panel.
const boardControls=document.createElement('div');boardControls.className='board-local-controls';
[addBoardButton,detectBoardButton,toggleBoardsButton].forEach(button=>boardControls.appendChild(button));
const emptyBoardGroup=accessoryToolbar.toolbar.querySelectorAll('.editor-group');emptyBoardGroup.forEach(group=>{if(!group.querySelector('button,input,select'))group.remove();});
const localBoardStyle=document.createElement('style');localBoardStyle.textContent='.board-local-controls{display:flex;align-items:center;gap:8px;flex-wrap:wrap;padding:12px;margin:18px 12px 0;background:#edf3f8;border:1px solid #ccdbe4;border-radius:10px}.board-local-controls button{margin:0;background:#edf3f6;color:#183c4b;border:1px solid #ccdbe4;padding:8px 12px}.board-local-controls button:first-child{background:#087f82;color:white}.board-local-controls+.board-panel{margin-top:8px}@media print{.board-local-controls{display:none!important}}';document.head.appendChild(localBoardStyle);
const boardLocalRender=renderBoardBlock;renderBoardBlock=function(section){
 boardLocalRender(section);
 section.querySelectorAll('.board-local-controls').forEach(el=>el.remove());
 const panel=section.querySelector('.board-panel');if(!panel)return;
 const isIndependent=!!section.closest('#accessory-page');
 if(isIndependent){panel.before(boardControls);}else{
  const controls=document.createElement('div');controls.className='board-local-controls';
  [addBoardButton,detectBoardButton,toggleBoardsButton].forEach(original=>{const button=document.createElement('button');button.type='button';button.textContent=original===toggleBoardsButton?(boardsVisible?MHD_REPORT_TPL('\u0001T:TEXT_54C4971B652F\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_C1F464BDFBDD\u0002')):original.textContent;button.onclick=()=>original.click();controls.appendChild(button);});panel.before(controls);
 }
};
const localBoardSnapshot=snapshot;snapshot=function(){const doc=localBoardSnapshot();doc.state.sections=doc.state.sections.map(html=>{const template=document.createElement('template');template.innerHTML=html;template.content.querySelectorAll('.board-local-controls').forEach(el=>el.remove());return template.innerHTML;});return doc;};

const attachWithBoardControls=$('accessory-attach').onclick;$('accessory-attach').onclick=()=>{attachWithBoardControls();document.querySelectorAll('body > .section-wrap[data-accessory-report]').forEach(renderBoardBlock);};
let numberPrecision=2,cachedNumberPrecision=2,reportPrecisionChosen=false;
function validNumberPrecision(value){const n=Number(value);return Number.isInteger(n)&&n>=0&&n<=6?n:2;}
const precisionLabel=document.createElement('label');precisionLabel.textContent=MHD_REPORT_TPL('\u0001T:TEXT_A15CC6D7CEB1\u0002');const precisionSelect=document.createElement('select');precisionSelect.id='accessory-number-precision';for(let i=0;i<=6;i++){const option=document.createElement('option');option.value=String(i);option.textContent=i===0?'0':'0.'+'0'.repeat(i);precisionSelect.appendChild(option);}precisionSelect.value=String(numberPrecision);precisionLabel.appendChild(precisionSelect);currencyLabel.after(precisionLabel);
precisionSelect.onchange=()=>{numberPrecision=validNumberPrecision(precisionSelect.value);reportPrecisionChosen=true;repriceAll();queueSave();};
const precisionPayload=currencyPricePayload;currencyPricePayload=function(){const payload=precisionPayload();payload.precision=numberPrecision;return payload;};
const precisionReceive=window.receiveAccessoryPrices;window.receiveAccessoryPrices=function(payload){cachedNumberPrecision=validNumberPrecision(payload.precision);if(!reportPrecisionChosen)numberPrecision=cachedNumberPrecision;precisionSelect.value=String(numberPrecision);precisionReceive(payload);};
const precisionSaved=window.accessoryPricesSaved;window.accessoryPricesSaved=function(payload){if(payload.prices){numberPrecision=validNumberPrecision(payload.precision);cachedNumberPrecision=numberPrecision;reportPrecisionChosen=true;precisionSelect.value=String(numberPrecision);}precisionSaved(payload);};
const precisionImport=window.importAccessoryPrices;window.importAccessoryPrices=function(payload){if(payload.prices){numberPrecision=validNumberPrecision(payload.precision);reportPrecisionChosen=true;precisionSelect.value=String(numberPrecision);}precisionImport(payload);repriceAll();};
const precisionSnapshot=snapshot;snapshot=function(){const doc=precisionSnapshot();doc.state.accessory_pricing.precision=numberPrecision;return doc;};
const precisionRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){const stored=state.accessory_pricing&&state.accessory_pricing.precision;reportPrecisionChosen=stored!==undefined;numberPrecision=stored===undefined?cachedNumberPrecision:validNumberPrecision(stored);precisionSelect.value=String(numberPrecision);precisionRestore(state);};

let manualAccessories=[];
const manualStyle=document.createElement('style');manualStyle.textContent='.manual-accessory-controls{padding:12px;display:flex;gap:8px}.manual-accessory-controls button{background:#087f82;color:white}.manual-item-actions{display:flex;gap:6px;margin-top:6px}.manual-item-actions button{padding:3px 8px;font-size:11px}#manual-accessory-editor{position:fixed;inset:0;z-index:220;background:#142b4266;backdrop-filter:blur(6px);display:flex;align-items:center;justify-content:center;padding:20px}#manual-accessory-editor[hidden]{display:none}.manual-accessory-card{background:white;border-radius:16px;padding:24px;width:520px;max-height:90vh;overflow:auto}.manual-accessory-card label{display:block;margin:10px 0}.manual-accessory-card input,.manual-accessory-card select{display:block;width:100%;padding:8px;margin-top:5px;border:1px solid #b8cbd6;border-radius:6px}@media print{.manual-accessory-controls,.manual-item-actions,#manual-accessory-editor{display:none!important}}';document.head.appendChild(manualStyle);
const manualEditor=document.createElement('div');manualEditor.id='manual-accessory-editor';manualEditor.hidden=true;manualEditor.innerHTML=MHD_REPORT_TPL('<div class="manual-accessory-card"><h2>\u0001H:TEXT_019832F7B975\u0002</h2><label>\u0001H:TEXT_DC2525ED398A\u0002<input id="manual-name"></label><label>\u0001H:TEXT_A90DD7465949\u0002<select id="manual-mode"><option value="piece">\u0001H:TEXT_486B48BA67CB\u0002</option><option value="meter">\u0001H:TEXT_9E23A62DF30D\u0002</option><option value="pack">\u0001H:TEXT_DBD20D83E803\u0002</option></select></label><label><span id="manual-quantity-label">\u0001H:TEXT_7839AC5A77EA\u0002</span><input id="manual-quantity" type="number" min="0" step="any"></label><label id="manual-pack-label">\u0001H:TEXT_767DFD6239C3\u0002<input id="manual-pack" type="number" min="1" step="1" value="4"></label><label id="manual-pieces-label">\u0001H:TEXT_64FF8B8395FD\u0002<input id="manual-pieces" type="number" min="1" step="1" value="1"></label><label>\u0001H:TEXT_969DEB10A7CC\u0002<input id="manual-rate" type="number" min="0" step="any" placeholder="\u0001H:TEXT_33408684704E\u0002"></label><p id="manual-error" style="color:#b33"></p><button id="manual-save">\u0001H:TEXT_C6ED8CF197FC\u0002</button><button id="manual-cancel">\u0001H:COMMON_BACK\u0002</button></div>');document.body.appendChild(manualEditor);let editingManualId=null;
function manualModeLabels(){const mode=$('manual-mode').value;$('manual-quantity-label').textContent=mode==='meter'?MHD_REPORT_TPL('\u0001T:TEXT_7E6BCFFCD635\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_9A137B34636E\u0002');$('manual-pack-label').hidden=mode!=='pack';$('manual-pieces-label').hidden=mode!=='meter';}
$('manual-mode').onchange=manualModeLabels;
function openManualAccessory(id){const entry=manualAccessories.find(item=>item.id===id);editingManualId=entry?entry.id:null;$('manual-name').value=entry?entry.name:'';$('manual-mode').value=entry?entry.mode:'piece';$('manual-quantity').value=entry?entry.quantity:1;$('manual-pack').value=entry?entry.pack_size:4;$('manual-pieces').value=entry?entry.pieces:1;$('manual-rate').value=entry?(reportPriceOverrides['manual:'+entry.id]??entry.price??''):'';$('manual-error').textContent='';manualModeLabels();manualEditor.hidden=false;}
$('manual-cancel').onclick=()=>manualEditor.hidden=true;
$('manual-save').onclick=()=>{try{const name=$('manual-name').value.trim(),mode=$('manual-mode').value,quantity=Number($('manual-quantity').value),pack=Number($('manual-pack').value),pieces=Number($('manual-pieces').value),price=parseReportPrice($('manual-rate').value);if(!name)throw Error('اكتب اسم الإكسسوار');if(!Number.isFinite(quantity)||quantity<=0)throw Error('الكمية يجب أن تكون أكبر من صفر');if(mode!=='meter'&&!Number.isInteger(quantity))throw Error('عدد القطع يجب أن يكون عددًا صحيحًا');if(mode==='pack'&&(!Number.isInteger(pack)||pack<1))throw Error('راجع عدد قطع الطقم');if(mode==='meter'&&(!Number.isInteger(pieces)||pieces<1))throw Error('راجع عدد القطع');const id=editingManualId||'custom-'+Date.now()+'-'+Math.random().toString(36).slice(2,7);const entry={id,name,mode,quantity,pack_size:pack||1,pieces:mode==='meter'?pieces:quantity,price,whole_packs:true};const index=manualAccessories.findIndex(item=>item.id===id);if(index<0)manualAccessories.push(entry);else manualAccessories[index]=entry;delete reportPriceOverrides['manual:'+id];manualEditor.hidden=true;repriceAll();queueSave();}catch(error){$('manual-error').textContent=error.message;}};
const manualEffectiveBase=effectiveAccessoryPrice;effectiveAccessoryPrice=function(name,row){if((row&&row.dataset.manualAccessoryId)||String(name).startsWith('manual:')){const id=row&&row.dataset.manualAccessoryId||String(name).slice(7);const entry=manualAccessories.find(item=>item.id===id);if(entry){const result={...entry};if(Object.prototype.hasOwnProperty.call(reportPriceOverrides,name))result.price=reportPriceOverrides[name];return result;}}return manualEffectiveBase(name,row);};
function populateManualAccessories(section){
 const heading=section.querySelector('.section-title');if(heading)heading.textContent=MHD_REPORT_TPL('\u0001T:TEXT_353498195A95\u0002');
 section.querySelectorAll('[data-manual-accessory-id],.manual-accessory-controls').forEach(el=>el.remove());
 // Remove verbose diagnostics from older saved reports as well.
 Array.from(section.children).forEach(el=>{if(el.tagName==='P'&&el.textContent.includes('تم فحص'))el.remove();if(el.tagName==='DETAILS'&&el.textContent.includes('عناصر تحتاج مراجعة'))el.remove();});
 const table=section.querySelector('table');if(!table)return;const controls=document.createElement('div');controls.className='manual-accessory-controls';const add=document.createElement('button');add.type='button';add.dataset.addManualAccessory='true';add.textContent=MHD_REPORT_TPL('\u0001T:TEXT_AAD8B297303C\u0002');controls.appendChild(add);table.before(controls);
 const body=table.querySelector('tbody');manualAccessories.forEach(entry=>{const row=body.insertRow();row.dataset.manualAccessoryId=entry.id;row.dataset.accessoryName='manual:'+entry.id;row.dataset.accessoryQuantity=String(entry.quantity);row.dataset.accessoryPieces=String(entry.pieces);for(let i=0;i<6;i++)row.insertCell();row.cells[1].textContent=entry.name;const actions=document.createElement('div');actions.className='manual-item-actions';[['editManualAccessory',MHD_REPORT_TPL('\u0001T:SURVEY_EDIT\u0002')],['removeManualAccessory',MHD_REPORT_TPL('\u0001T:COMMON_DELETE\u0002')]].forEach(([key,label])=>{const button=document.createElement('button');button.type='button';button.dataset[key]=entry.id;button.textContent=label;actions.appendChild(button);});row.cells[1].appendChild(actions);row.cells[5].textContent=MHD_REPORT_TPL('\u0001T:TEXT_4B7E1C0402CF\u0002');});Array.from(body.rows).forEach((row,i)=>row.cells[0].textContent=String(i+1));
}
const manualPriceSection=priceSection;priceSection=function(section){populateManualAccessories(section);manualPriceSection(section);};
document.addEventListener('click',event=>{const add=event.target.closest('[data-add-manual-accessory]'),edit=event.target.closest('[data-edit-manual-accessory]'),remove=event.target.closest('[data-remove-manual-accessory]');if(add)openManualAccessory(null);if(edit)openManualAccessory(edit.dataset.editManualAccessory);if(remove){const id=remove.dataset.removeManualAccessory;manualAccessories=manualAccessories.filter(entry=>entry.id!==id);delete reportPriceOverrides['manual:'+id];repriceAll();queueSave();}});
const manualSnapshot=snapshot;snapshot=function(){const doc=manualSnapshot();doc.state.manual_accessories=manualAccessories;return doc;};
const manualRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){manualAccessories=Array.isArray(state.manual_accessories)?state.manual_accessories.filter(entry=>entry&&entry.id&&entry.name&&['piece','meter','pack'].includes(entry.mode)&&Number(entry.quantity)>0).map(entry=>({...entry,quantity:Number(entry.quantity),pieces:Math.max(1,Number(entry.pieces)||1),pack_size:Math.max(1,Number(entry.pack_size)||1),price:entry.price===null?null:Math.max(0,Number(entry.price)||0)})):[];manualRestore(state);};
const costAttach=$('accessory-attach').onclick;$('accessory-attach').onclick=()=>{costAttach();accessoryPage.hidden=true;const attached=$('attached-accessory-report');if(attached){select(attached);requestAnimationFrame(()=>attached.scrollIntoView({behavior:'smooth',block:'start'}));}};


let accessoriesVisible=true;
const localAccessoryStyle=document.createElement('style');localAccessoryStyle.textContent='.manual-accessory-controls{display:flex;align-items:center;gap:8px;flex-wrap:wrap;padding:12px;margin:18px 12px 8px;background:#edf3f8;border:1px solid #ccdbe4;border-radius:10px}.manual-accessory-controls button{margin:0;background:#edf3f6;color:#183c4b;border:1px solid #ccdbe4;padding:8px 12px}.manual-accessory-controls button:first-child{background:#087f82;color:white}.accessories-excluded>table{display:none!important}#report-back-to-top{position:fixed;left:22px;bottom:24px;z-index:190;background:#12394a;color:white;border:1px solid #d8e4ec;border-radius:25px;padding:11px 17px;box-shadow:0 4px 15px #0003;font-size:14px;cursor:pointer}@media print{#report-back-to-top{display:none!important}}';document.head.appendChild(localAccessoryStyle);
const sharedPricesButton=$('accessory-toggle-prices');sharedPricesButton.hidden=true;
function refreshCostVisibility(){repriceAll();queueSave();}
const visibilityPriceSection=priceSection;priceSection=function(section){
 visibilityPriceSection(section);section.classList.toggle('accessories-excluded',!accessoriesVisible);
 const controls=section.querySelector('.manual-accessory-controls');if(!controls)return;
 const toggle=document.createElement('button');toggle.type='button';toggle.dataset.toggleAccessories='true';toggle.textContent=accessoriesVisible?MHD_REPORT_TPL('\u0001T:TEXT_808B874A75AF\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_AD3667E8D7E4\u0002');
 const prices=document.createElement('button');prices.type='button';prices.dataset.toggleCostPrices='true';prices.textContent=priceVisible?MHD_REPORT_TPL('\u0001T:TEXT_54327840D20B\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_7953627FDCE1\u0002');controls.append(toggle,prices);
};
document.addEventListener('click',event=>{if(event.target.closest('[data-toggle-accessories]')){accessoriesVisible=!accessoriesVisible;refreshCostVisibility();}if(event.target.closest('[data-toggle-cost-prices]')){priceVisible=!priceVisible;sharedPricesButton.textContent=priceVisible?MHD_REPORT_TPL('\u0001T:TEXT_63F097D38CC7\u0002'):MHD_REPORT_TPL('\u0001T:TEXT_5F70B7513632\u0002');refreshCostVisibility();}});
const visibilitySnapshot=snapshot;snapshot=function(){const doc=visibilitySnapshot();doc.state.accessories_visible=accessoriesVisible;return doc;};
const visibilityRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){accessoriesVisible=state.accessories_visible!==false;visibilityRestore(state);};
const backTop=document.createElement('button');backTop.id='report-back-to-top';backTop.type='button';backTop.textContent=MHD_REPORT_TPL('\u0001T:TEXT_8D403A77D843\u0002');backTop.title=MHD_REPORT_TPL('\u0001T:TEXT_30EE558018B1\u0002');document.body.appendChild(backTop);backTop.onclick=()=>{const current=!pricesPage.hidden?pricesPage:!accessoryPage.hidden?accessoryPage:null;if(current)current.scrollTo({top:0,behavior:'smooth'});else window.scrollTo({top:0,behavior:'smooth'});};


const consistentTablesStyle=document.createElement('style');consistentTablesStyle.textContent=`
.accessory-report>.section-title,.accessory-report>.board-panel>h3{margin:0!important;padding:14px 16px!important;background:#e9f0f8!important;border:0!important;border-bottom:1px solid #d7dee7!important;font-size:18px!important;font-weight:bold!important;text-align:right;line-height:1.5}
.accessory-report>.board-panel{margin:18px 0 0!important;border:0!important;border-top:1px solid #d7dee7!important;border-radius:0!important;overflow:hidden}
.accessory-report>.manual-accessory-controls,.accessory-report>.board-panel>.board-local-controls{display:flex;align-items:center;justify-content:flex-start;gap:8px;flex-wrap:wrap;margin:14px 12px 8px!important;padding:12px!important;background:#edf3f8!important;border:1px solid #ccdbe4!important;border-radius:10px!important}
.accessory-report>.manual-accessory-controls button,.accessory-report>.board-panel>.board-local-controls button{margin:0!important;border:1px solid #ccdbe4!important;background:#edf3f6!important;color:#183c4b!important;padding:8px 12px!important;font-size:12px!important;border-radius:8px!important}
.accessory-report>.manual-accessory-controls button:first-child,.accessory-report>.board-panel>.board-local-controls button:first-child{background:#087f82!important;color:#fff!important;border-color:#087f82!important}
.accessory-report>.board-panel>.boards-table,.accessory-report>table{width:100%;border-collapse:collapse;margin:0!important;border-radius:0!important}
.accessory-report>.board-panel>.boards-table th,.accessory-report>table th{background:#eef3f8!important;padding:8px;font-size:13px}
@media print{.accessory-report>.board-panel{margin-top:16px!important}.accessory-report>.board-panel>.board-local-controls{display:none!important}}
`;document.head.appendChild(consistentTablesStyle);
const consistentBoardRender=renderBoardBlock;renderBoardBlock=function(section){
 consistentBoardRender(section);
 const panel=section.querySelector('.board-panel');if(!panel)return;
 const localControls=Array.from(section.children).find(el=>el.classList.contains('board-local-controls'));
 if(localControls){const title=panel.querySelector('h3');if(title)title.after(localControls);else panel.prepend(localControls);}
 // Keep the show button accessible even when board rows are excluded.
 panel.hidden=false;const table=panel.querySelector('table');if(table)table.hidden=!boardsVisible||!kitchenBoards.length;
};

const distributionPrintStyle=document.createElement('style');distributionPrintStyle.textContent='@media print{.print-omit-distribution>thead>tr>th:nth-child(6),.print-omit-distribution>thead>tr>td:nth-child(6),.print-omit-distribution>tbody>tr>td:nth-child(6){display:none!important}}';document.head.appendChild(distributionPrintStyle);
function prepareDistributionPrint(){document.querySelectorAll('[data-accessory-report]').forEach(section=>{const table=Array.from(section.children).find(el=>el.tagName==='TABLE');if(!table)return;const open=Array.from(table.querySelectorAll('tbody tr')).some(row=>row.cells[5]&&row.cells[5].querySelector('details[open]'));table.classList.toggle('print-omit-distribution',!open);});}
window.addEventListener('beforeprint',prepareDistributionPrint);
window.addEventListener('afterprint',()=>document.querySelectorAll('.print-omit-distribution').forEach(table=>table.classList.remove('print-omit-distribution')));

let removedUnitAccessories={};
const unitAccessoryStyle=document.createElement('style');unitAccessoryStyle.textContent='.unit-accessory-item{display:flex;align-items:flex-start;justify-content:space-between;gap:6px;padding:5px 0;border-bottom:1px dashed #dce5eb;text-align:right;font-size:12px;line-height:1.6}.unit-accessory-remove{margin:0;padding:0 7px;flex-shrink:0;border:1px solid #e6b4b4;background:#fff0f0;color:#a63232;font-size:18px;line-height:24px}.unit-accessory-item:last-child{border-bottom:0}@media print{.unit-accessory-remove{display:none!important}.unit-accessory-item{break-inside:avoid;page-break-inside:avoid}}';document.head.appendChild(unitAccessoryStyle);
function ensureUnitAccessoryColumns(){
 document.querySelectorAll('body > .section-wrap:not([data-accessory-report]) .report-table').forEach(table=>{
  if(!table.querySelector('tr[data-unit-pid]'))return;
  const head=table.querySelector('thead tr');if(head&&!head.querySelector('[data-unit-accessory-heading]')){const th=document.createElement('th');th.dataset.unitAccessoryHeading='true';th.textContent=MHD_REPORT_TPL('\u0001T:TEXT_B50F22FF3FA8\u0002');head.insertBefore(th,head.cells[5]||null);}
  table.querySelectorAll('tbody tr[data-unit-pid]').forEach(row=>{if(!row.querySelector('[data-unit-accessories]')){const td=document.createElement('td');td.dataset.unitAccessories='pending';row.insertBefore(td,row.cells[5]||null);}});
 });
}
function filterRemovedUnitAccessories(){document.querySelectorAll('tr[data-unit-pid]').forEach(row=>{const removed=removedUnitAccessories[row.dataset.unitPid]||[];row.querySelectorAll('[data-unit-accessory-key]').forEach(item=>{if(removed.includes(item.dataset.unitAccessoryKey))item.remove();});});}
window.receiveUnitAccessories=function(entries){entries.forEach(entry=>{document.querySelectorAll('tr[data-unit-pid]').forEach(row=>{if(row.dataset.unitPid!==String(entry.pid))return;const cell=row.querySelector('[data-unit-accessories]');if(cell){cell.innerHTML=safeHTML(entry.html);cell.dataset.unitAccessories='ready';}});});filterRemovedUnitAccessories();queueSave();};
const accessoriesColumnWatch=watch;watch=function(){accessoriesColumnWatch();ensureUnitAccessoryColumns();filterRemovedUnitAccessories();const ids=Array.from(new Set(Array.from(document.querySelectorAll('body > .section-wrap tr[data-unit-pid]')).filter(row=>row.querySelector('[data-unit-accessories="pending"]')).map(row=>row.dataset.unitPid)));if(ids.length)requestUnitAccessoryBatch(ids);};
document.addEventListener('click',event=>{const button=event.target.closest('[data-remove-unit-accessory]');if(!button)return;const item=button.closest('[data-unit-accessory-key]'),row=button.closest('tr[data-unit-pid]');if(!item||!row)return;const ids=removedUnitAccessories[row.dataset.unitPid]||(removedUnitAccessories[row.dataset.unitPid]=[]);if(!ids.includes(item.dataset.unitAccessoryKey))ids.push(item.dataset.unitAccessoryKey);item.remove();queueSave();});
const accessoriesColumnSnapshot=snapshot;snapshot=function(){const doc=accessoriesColumnSnapshot();doc.state.removed_unit_accessories=removedUnitAccessories;return doc;};
const accessoriesColumnRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){removedUnitAccessories=state.removed_unit_accessories||{};accessoriesColumnRestore(state);};


function hideExcludedUnitAccessoryItems(){document.querySelectorAll('[data-unit-accessories] [data-unit-accessory-key]').forEach(item=>{const name=(item.dataset.unitAccessoryKey||'').split('|||')[0].replace(/[أإآٱ]/g,'ا').replace(/ة/g,'ه').replace(/s+/g,'');if((name.includes('رجل')&&name.includes('بلاست'))||name.includes('وزر'))item.remove();});}
const exclusionsFilter=filterRemovedUnitAccessories;filterRemovedUnitAccessories=function(){exclusionsFilter();hideExcludedUnitAccessoryItems();};

let unitAccessoriesBusy=false;
const unitLoadingStyle=document.createElement('style');unitLoadingStyle.textContent='#unit-accessories-loading{position:fixed;inset:0;z-index:600;display:flex;align-items:center;justify-content:center;padding:24px;background:rgba(12,35,48,.62);backdrop-filter:blur(7px);direction:rtl}#unit-accessories-loading[hidden]{display:none}.unit-loading-card{width:500px;max-width:100%;padding:32px;background:#f6fbff;border:1px solid #a5c8d9;border-radius:18px;box-shadow:0 18px 70px #081d3c44;text-align:center;color:#163f52}.unit-loading-brand{font-size:25px;font-weight:bold;margin-bottom:18px}.unit-loading-title{font-size:17px;font-weight:bold;margin-bottom:20px}.unit-loading-track{height:11px;overflow:hidden;border-radius:20px;background:#dceaf2;border:1px solid #bed3e0;direction:ltr}.unit-loading-fill{height:100%;width:0;background:linear-gradient(90deg,#086e83,#33afc1);transition:width .15s ease;border-radius:20px}.unit-loading-percent{margin-top:12px;color:#466c80;font-size:15px}.unit-loading-count{font-size:12px;margin-top:7px;color:#648293}@media print{#unit-accessories-loading{display:none!important}}';document.head.appendChild(unitLoadingStyle);
const unitLoadingOverlay=document.createElement('div');unitLoadingOverlay.id='unit-accessories-loading';unitLoadingOverlay.hidden=true;unitLoadingOverlay.innerHTML=MHD_REPORT_TPL('<div class="unit-loading-card" role="dialog" aria-modal="true" aria-label="\u0001H:TEXT_F0C060B26266\u0002"><div class="unit-loading-brand">MHDESIGN</div><div class="unit-loading-title">\u0001H:TEXT_D0F7AA644420\u0002</div><div class="unit-loading-track" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0"><div class="unit-loading-fill"></div></div><div class="unit-loading-percent">0%</div><div class="unit-loading-count"></div></div>');document.body.appendChild(unitLoadingOverlay);
window.unitAccessoryProgress=function(done,total){const percent=total?Math.round(done/total*100):100;unitLoadingOverlay.querySelector('.unit-loading-fill').style.width=percent+'%';unitLoadingOverlay.querySelector('.unit-loading-percent').textContent=percent+'%';unitLoadingOverlay.querySelector('.unit-loading-count').textContent=MHD_REPORT_TPL('\u0001T:TEXT_390404164CF4\u0002 ')+done+MHD_REPORT_TPL(' \u0001T:SHOP_FROM\u0002 ')+total+MHD_REPORT_TPL(' \u0001T:SHOP_UNIT\u0002');unitLoadingOverlay.querySelector('[role="progressbar"]').setAttribute('aria-valuenow',String(percent));};
window.finishUnitAccessoryLoading=function(){unitAccessoriesBusy=false;unitLoadingOverlay.hidden=true;queueSave();watch();};
function requestUnitAccessoryBatch(ids){if(unitAccessoriesBusy||!ids.length)return;unitAccessoriesBusy=true;document.querySelectorAll('tr[data-unit-pid]').forEach(row=>{if(ids.includes(row.dataset.unitPid)){const cell=row.querySelector('[data-unit-accessories]');if(cell)cell.dataset.unitAccessories='loading';}});window.unitAccessoryProgress(0,ids.length);unitLoadingOverlay.hidden=false;setTimeout(()=>{if(window.sketchup&&window.sketchup.report_unit_accessories)window.sketchup.report_unit_accessories(JSON.stringify(ids));else window.finishUnitAccessoryLoading();},50);}
const loadingSnapshot=snapshot;snapshot=function(){const doc=loadingSnapshot();doc.state.sections=doc.state.sections.map(html=>html.replace(/data-unit-accessories="loading"/g,'data-unit-accessories="pending"'));return doc;};

let unitManualAccessories={};
const unitPlusStyle=document.createElement('style');unitPlusStyle.textContent='.unit-accessory-plus{margin:6px 0;padding:0 8px;border:1px solid #91c5c6;background:#edfafa;color:#087f82;font-size:20px;line-height:26px;border-radius:7px}#unit-accessory-editor{position:fixed;inset:0;z-index:230;display:flex;justify-content:center;align-items:center;background:#142b4266;backdrop-filter:blur(6px);padding:20px}#unit-accessory-editor[hidden]{display:none}.unit-accessory-card{width:440px;max-width:100%;padding:24px;background:white;border-radius:16px}.unit-accessory-card label{display:block;margin:12px 0}.unit-accessory-card input,.unit-accessory-card select{display:block;width:100%;padding:8px;border:1px solid #bbced9;border-radius:6px;margin-top:5px}@media print{.unit-accessory-plus,#unit-accessory-editor{display:none!important}}';document.head.appendChild(unitPlusStyle);
const unitEditor=document.createElement('div');unitEditor.id='unit-accessory-editor';unitEditor.hidden=true;unitEditor.innerHTML=MHD_REPORT_TPL('<div class="unit-accessory-card"><h2>\u0001H:TEXT_9763DF1738EC\u0002</h2><p id="unit-accessory-owner"></p><label>\u0001H:TEXT_DC2525ED398A\u0002<input id="unit-extra-name"></label><label>\u0001H:REPORT_QUANTITY\u0002<input id="unit-extra-quantity" type="number" min="0" step="any" value="1"></label><label>\u0001H:TEXT_02E927A2FBF5\u0002<select id="unit-extra-measure"><option value="piece">\u0001H:TEXT_848514ABBBFD\u0002</option><option value="meter">\u0001H:TEXT_761646B38174\u0002</option><option value="pack">\u0001H:TEXT_663173F1DAA4\u0002</option></select></label><p id="unit-extra-error" style="color:#b33"></p><button id="unit-extra-save">\u0001H:INV_ADD\u0002</button><button id="unit-extra-cancel">\u0001H:COMMON_BACK\u0002</button></div>');document.body.appendChild(unitEditor);let unitExtraPid=null;
function renderUnitManualAccessories(){document.querySelectorAll('body > .section-wrap tr[data-unit-pid]').forEach(row=>{const cell=row.querySelector('[data-unit-accessories]');if(!cell)return;cell.querySelectorAll('[data-unit-manual-id],.unit-accessory-plus').forEach(el=>el.remove());const pid=row.dataset.unitPid;(unitManualAccessories[pid]||[]).forEach(entry=>{const line=document.createElement('div');line.className='unit-accessory-item';line.dataset.unitManualId=entry.id;const label=document.createElement('span');label.textContent=entry.name+' — '+entry.quantity+' '+({piece:MHD_REPORT_TPL('\u0001T:TEXT_848514ABBBFD\u0002'),meter:MHD_REPORT_TPL('\u0001T:TEXT_761646B38174\u0002'),pack:MHD_REPORT_TPL('\u0001T:TEXT_663173F1DAA4\u0002')}[entry.measure]||MHD_REPORT_TPL('\u0001T:TEXT_848514ABBBFD\u0002'));const remove=document.createElement('button');remove.type='button';remove.className='unit-accessory-remove';remove.dataset.removeUnitManual=entry.id;remove.textContent='−';remove.title=MHD_REPORT_TPL('\u0001T:TEXT_ECB437BDB301\u0002');line.append(label,remove);cell.appendChild(line);});const add=document.createElement('button');add.type='button';add.className='unit-accessory-plus';add.dataset.addUnitManual=pid;add.textContent='+';add.title=MHD_REPORT_TPL('\u0001T:TEXT_73E8BAB286AD\u0002');cell.appendChild(add);});}
const unitManualFilter=filterRemovedUnitAccessories;filterRemovedUnitAccessories=function(){unitManualFilter();renderUnitManualAccessories();};
document.addEventListener('click',event=>{const add=event.target.closest('[data-add-unit-manual]');if(add){unitExtraPid=add.dataset.addUnitManual;const name=add.closest('tr').querySelector('.unit-name');$('unit-accessory-owner').textContent=name?name.textContent:'';$('unit-extra-name').value='';$('unit-extra-quantity').value='1';$('unit-extra-measure').value='piece';$('unit-extra-error').textContent='';unitEditor.hidden=false;$('unit-extra-name').focus();}const remove=event.target.closest('[data-remove-unit-manual]');if(remove){const pid=remove.closest('tr').dataset.unitPid;unitManualAccessories[pid]=(unitManualAccessories[pid]||[]).filter(entry=>entry.id!==remove.dataset.removeUnitManual);renderUnitManualAccessories();queueSave();}});
$('unit-extra-cancel').onclick=()=>unitEditor.hidden=true;
$('unit-extra-save').onclick=()=>{try{const name=$('unit-extra-name').value.trim(),quantity=parseReportPrice($('unit-extra-quantity').value),measure=$('unit-extra-measure').value;if(!name)throw Error('اكتب اسم الإكسسوار');if(quantity===null||quantity<=0)throw Error('اكتب كمية أكبر من صفر');if(measure!=='meter'&&!Number.isInteger(quantity))throw Error('عدد القطع أو الأطقم يجب أن يكون عددًا صحيحًا');if(!unitExtraPid)throw Error('الوحدة غير محددة');const entries=unitManualAccessories[unitExtraPid]||(unitManualAccessories[unitExtraPid]=[]);entries.push({id:'unit-extra-'+Date.now()+'-'+Math.random().toString(36).slice(2,7),name,quantity,measure});unitEditor.hidden=true;renderUnitManualAccessories();queueSave();}catch(error){$('unit-extra-error').textContent=error.message;}};
const unitManualSnapshot=snapshot;snapshot=function(){const doc=unitManualSnapshot();doc.state.unit_manual_accessories=unitManualAccessories;return doc;};
const unitManualRestore=window.restoreAccessoryPricing;window.restoreAccessoryPricing=function(state){const raw=state.unit_manual_accessories||{};unitManualAccessories={};Object.keys(raw).forEach(pid=>{if(!/^\d+$/.test(pid)||!Array.isArray(raw[pid]))return;unitManualAccessories[pid]=raw[pid].filter(entry=>entry&&entry.name&&Number(entry.quantity)>0&&['piece','meter','pack'].includes(entry.measure));});unitManualRestore(state);};

lastSelectionKey=(window.MHD_REPORT_SELECTION||[]).slice().sort().join(',');
if(window.sketchup&&window.sketchup.accessory_price_catalog)window.sketchup.accessory_price_catalog();
if(window.sketchup&&window.sketchup.report_ready)window.sketchup.report_ready();

})();
MHD_REPORT_EDITOR_JAVASCRIPT
  end
end
