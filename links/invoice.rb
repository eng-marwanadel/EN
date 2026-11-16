# encoding: UTF-8
# MHDESIGN - MHInvoice (Kitchen Metering + Invoice + Clients)
# نسخة معدلة للعمل من داخل المكتبة فقط
# بدون Menu / Toolbar
# التخزين المحلي ثابت داخل:
# %AppData%/MHDESIGN/Data/

require 'json'
require 'csv'
require 'fileutils'
require 'securerandom'


# ==================== MHDESIGN INVOICE LANGUAGE BRIDGE ====================
module MHDESIGN_INVOICE_LANG
  extend self

  SOURCE_KEY_MAP = {
    "إصدار فاتورة - MHDESIGN" => "INV_TITLE_CREATE",
    "فاتورة - MHDESIGN" => "INV_TITLE_PRINT",
    "بيانات الشركة" => "INV_COMPANY_DETAILS",
    "أسعار الخامات" => "INV_MATERIAL_PRICES",
    "إدارة العملاء" => "INV_CLIENT_MANAGEMENT",
    "حفظ الفاتورة للعميل" => "INV_SAVE_TO_CLIENT",
    "إصدار الفاتورة" => "INV_CREATE",
    "بيانات العميل وبيانات الفاتورة" => "INV_CLIENT_INVOICE_DETAILS",
    "اسم العميل" => "INV_CLIENT_NAME",
    "الفرع" => "INV_BRANCH",
    "رقم إستمارة التعاقد" => "INV_CONTRACT_NUMBER",
    "تاريخ الإصدار" => "INV_ISSUE_DATE",
    "المصمم / المسئول" => "INV_DESIGNER",
    "ملاحظة عامة" => "INV_GENERAL_NOTE",
    "إعدادات الحساب" => "INV_CALC_SETTINGS",
    "وضع الحساب" => "INV_CALC_MODE",
    "متر طولي (عرض)" => "INV_LINEAR_METER",
    "متر مربع (عرض × ارتفاع)" => "INV_SQUARE_METER",
    "نسبة الخصم %" => "INV_DISCOUNT_PERCENT",
    "إظهار وحدات غير محددة" => "INV_SHOW_EMPTY",
    "إجمالي تلقائي عند التعديل" => "INV_AUTO_TOTAL",
    "بيان تفصيلي للوحدات" => "INV_UNIT_DETAILS",
    "الوحدة" => "INV_UNIT",
    "العرض (سم)" => "INV_WIDTH_CM",
    "الارتفاع (سم)" => "INV_HEIGHT_CM",
    "الكمية" => "INV_QUANTITY",
    "الخامة" => "INV_MATERIAL",
    "المتر (حسب الوضع)" => "INV_METERS",
    "سعر/متر" => "INV_PRICE_PER_METER",
    "الإجمالي" => "INV_TOTAL",
    "ملاحظات" => "INV_NOTES",
    "اسم الوحدة" => "INV_UNIT_NAME",
    "إضافة وحدة" => "INV_ADD_UNIT",
    "ملاحظة: يمكنك تعديل الاسم/الخامة/الكمية/العرض/الارتفاع لكل وحدة مباشرة من الجدول." => "INV_EDIT_NOTE",
    "تحديث الوحدات" => "INV_REFRESH_UNITS",
    "مسح الجدول" => "INV_CLEAR_TABLE",
    "إجمالي الأمتار" => "INV_TOTAL_METERS",
    "عدد الوحدات" => "INV_UNIT_COUNT",
    "الإكسسوارات الإضافية" => "INV_ACCESSORIES",
    "البند" => "INV_ITEM",
    "سعر الوحدة" => "INV_UNIT_PRICE",
    "العدد" => "INV_COUNT",
    "اسم البند" => "INV_ITEM_NAME",
    "إضافة" => "INV_ADD",
    "اسم الشركة" => "INV_COMPANY_NAME",
    "هاتف" => "INV_PHONE",
    "العنوان" => "INV_ADDRESS",
    "رابط اللوجو (URL)" => "INV_LOGO_URL",
    "ملاحظات الفوتر (تظهر في أسفل الفاتورة)" => "INV_FOOTER_NOTES",
    "إلغاء" => "INV_CANCEL",
    "حفظ" => "INV_SAVE",
    "خامة جديدة" => "INV_NEW_MATERIAL",
    "سعر" => "INV_PRICE",
    "استيراد CSV" => "INV_IMPORT_CSV",
    "إغلاق" => "INV_CLOSE",
    "بحث بالاسم/الهاتف/العنوان" => "INV_SEARCH_CLIENT",
    "عميل جديد" => "INV_NEW_CLIENT",
    "تصدير العملاء" => "INV_EXPORT_CLIENTS",
    "استيراد JSON" => "INV_IMPORT_JSON",
    "الاسم" => "INV_NAME",
    "فواتير" => "INV_INVOICES",
    "استخدام" => "INV_USE",
    "حذف" => "INV_DELETE",
    "اختر العميل" => "INV_SELECT_CLIENT",
    "عنوان/اسم الفاتورة" => "INV_INVOICE_TITLE",
    "مثال: مطبخ - عقد 123" => "INV_INVOICE_EXAMPLE",
    "فواتير العميل" => "INV_CLIENT_INVOICES",
    "التاريخ" => "INV_DATE",
    "تحميل" => "INV_LOAD",
    "نعم" => "INV_YES",
    "لا" => "INV_NO",
    "بدون اسم" => "INV_NO_NAME",
    "عميل" => "INV_CLIENT",
    "عرض" => "INV_VIEW",
    "فاتورة" => "INV_INVOICE",
    "الإجمالي قبل الخصم" => "INV_SUBTOTAL",
    "قيمة الخصم" => "INV_DISCOUNT_VALUE",
    "الإجمالي النهائي" => "INV_FINAL_TOTAL",
  }.freeze unless const_defined?(:SOURCE_KEY_MAP, false)

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

  # إعادة تحميل الترجمة عند الحاجة فقط.
  # مهم: لا نعيد تحميل الـ manifest / dictionary مع كل فتح للفواتير.
  def refresh_language!(force = false)
    return false unless defined?(MHDESIGN::Language)

    code = current.to_s
    return true if !force && @refreshed_language_code == code

    begin
      MHDESIGN::Language.reload_manifest! if MHDESIGN::Language.respond_to?(:reload_manifest!)
    rescue
    end

    begin
      if MHDESIGN::Language.respond_to?(:reload_dictionary!)
        MHDESIGN::Language.reload_dictionary!(code)
      else
        MHDESIGN::Language.instance_variable_set(:@loaded_code, nil)
        MHDESIGN::Language.instance_variable_set(:@dictionary, nil)
        MHDESIGN::Language.for_tool('invoice').load_dictionary(code)
      end
    rescue
    end

    @refreshed_language_code = code
    true
  rescue
    false
  end

  def key_for_source(value)
    SOURCE_KEY_MAP[value.to_s]
  rescue
    nil
  end

  def key(key_name, fallback = nil)
    fallback_text = fallback.nil? ? key_name.to_s : fallback.to_s
    return fallback_text unless defined?(MHDESIGN::Language)

    value = MHDESIGN::Language.for_tool('invoice').t(key_name.to_s, fallback_text)

    if value.to_s == fallback_text && key_name.to_s.start_with?("INV_")
      refresh_language!
      value = MHDESIGN::Language.for_tool('invoice').t(key_name.to_s, fallback_text)
    end

    value.to_s
  rescue
    fallback.nil? ? key_name.to_s : fallback.to_s
  end

  def t(value, fallback = nil)
    text = value.to_s
    return text if text.empty?

    stable_key = key_for_source(text)
    return key(stable_key, fallback || text) if stable_key

    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('invoice').translate_source(text)
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
    payload =
      if defined?(MHDESIGN::Language)
        MHDESIGN::Language.for_tool('invoice').ui_payload
      else
        {
          locale: current,
          direction: direction,
          texts: {},
          source_map: {}
        }
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
# ========================================================================

module MHDesign
  module MHInvoice

    EXTENSION_NAME = "MHDESIGN Invoice" unless const_defined?(:EXTENSION_NAME, false)
    ATTR_NS = "MHDESIGN_INVOICE_V1" unless const_defined?(:ATTR_NS, false)

    # ✅ مجلد البلجن القديم / الحالي (لفحص التعارض فقط + Migration)
    LEGACY_PLUGIN_DIR = begin
      plugins_dir = Sketchup.find_support_file("Plugins")
      if plugins_dir.nil? || plugins_dir.to_s.strip.empty?
        File.join(Dir.pwd, "Plugins", "MHDESIGN")
      else
        File.join(plugins_dir, "MHDESIGN")
      end
    rescue
      File.join(Dir.pwd, "Plugins", "MHDESIGN")
    end unless const_defined?(:LEGACY_PLUGIN_DIR, false)

    # ✅ مجلد البيانات الجديد الثابت
    DATA_DIR = begin
      appdata = ENV["APPDATA"].to_s
      if appdata.nil? || appdata.strip.empty?
        File.join(Dir.home, "AppData", "Roaming", "MHDESIGN", "Data")
      else
        File.join(appdata, "MHDESIGN", "Data")
      end
    rescue
      File.join(Dir.home, "AppData", "Roaming", "MHDESIGN", "Data")
    end unless const_defined?(:DATA_DIR, false)

    # مسارات ملفات التخزين الجديدة
    MATERIALS_FILE = File.join(DATA_DIR, "materials.json") unless const_defined?(:MATERIALS_FILE, false)
    COMPANY_FILE   = File.join(DATA_DIR, "company.json") unless const_defined?(:COMPANY_FILE, false)
    CLIENTS_FILE   = File.join(DATA_DIR, "clients.json") unless const_defined?(:CLIENTS_FILE, false)

    # مسارات الملفات القديمة (للهجرة فقط)
    LEGACY_MATERIALS_FILE = File.join(LEGACY_PLUGIN_DIR, "materials.json") unless const_defined?(:LEGACY_MATERIALS_FILE, false)
    LEGACY_COMPANY_FILE   = File.join(LEGACY_PLUGIN_DIR, "company.json") unless const_defined?(:LEGACY_COMPANY_FILE, false)
    LEGACY_CLIENTS_FILE   = File.join(LEGACY_PLUGIN_DIR, "clients.json") unless const_defined?(:LEGACY_CLIENTS_FILE, false)

    # ملفات قديمة يجب إزالتها من الاكستنشن مانيجر
    BLOCKING_FILES = [
      File.join(LEGACY_PLUGIN_DIR, "invoice.rb"),
      File.join(LEGACY_PLUGIN_DIR, "report_units.rb")
    ].freeze unless const_defined?(:BLOCKING_FILES, false)

    # قيم افتراضية للخامات
    DEFAULT_MATERIALS = {
      "MDF"      => 1200.0,
      "HPL"      => 1500.0,
      "Acrylic"  => 1800.0
    } unless const_defined?(:DEFAULT_MATERIALS, false)

    # --------------------------------------------
    # دوال مساعدة عامة
    # --------------------------------------------

    def self.blocking_legacy_files_present?
      BLOCKING_FILES.any? { |p| File.exist?(p) }
    rescue
      false
    end

    def self.show_uninstall_block_message
      found = BLOCKING_FILES.select { |p| File.exist?(p) rescue false }.map { |p| File.basename(p) }
      names = found.empty? ? "invoice.rb / report_units.rb" : found.join(" , ")

      MHDESIGN_INVOICE_LANG.messagebox(
        "لا يمكن فتح الفواتير الآن.\n\n" \
        "تم اكتشاف ملفات قديمة داخل مجلد المكتبة:\n" \
        "#{names}\n\n" \
        "من فضلك اعمل Uninstall لهذه الملفات من Extension Manager أولاً،\n" \
        "ثم أعد تشغيل SketchUp وجرب مرة أخرى."
      )
    end

    def self.migrate_legacy_data_if_needed!
      begin
        FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
      rescue
      end

      begin
        if !File.exist?(MATERIALS_FILE) && File.exist?(LEGACY_MATERIALS_FILE)
          FileUtils.cp(LEGACY_MATERIALS_FILE, MATERIALS_FILE)
        end
      rescue
      end

      begin
        if !File.exist?(COMPANY_FILE) && File.exist?(LEGACY_COMPANY_FILE)
          FileUtils.cp(LEGACY_COMPANY_FILE, COMPANY_FILE)
        end
      rescue
      end

      begin
        if !File.exist?(CLIENTS_FILE) && File.exist?(LEGACY_CLIENTS_FILE)
          FileUtils.cp(LEGACY_CLIENTS_FILE, CLIENTS_FILE)
        end
      rescue
      end
    end

    def self.ensure_storage_files_exist!
      # بعد أول تجهيز ناجح لا نكرر فحص/هجرة الملفات مع كل قراءة JSON.
      if @storage_ready && File.exist?(MATERIALS_FILE) && File.exist?(COMPANY_FILE) && File.exist?(CLIENTS_FILE)
        return true
      end

      begin
        FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
      rescue
      end

      # ✅ هجرة صامتة من المسار القديم للمسار الجديد إذا لزم
      migrate_legacy_data_if_needed!

      unless File.exist?(MATERIALS_FILE)
        begin
          File.write(MATERIALS_FILE, JSON.pretty_generate(DEFAULT_MATERIALS), mode: "w:utf-8")
        rescue
        end
      end

      unless File.exist?(COMPANY_FILE)
        default_company = {
          "company_name" => "MHDESIGN",
          "company_phone"=> "+20",
          "company_addr" => "Egypt",
          "logo_url"     => "",
          "footer_notes" => ""
        }
        begin
          File.write(COMPANY_FILE, JSON.pretty_generate(default_company), mode: "w:utf-8")
        rescue
        end
      end

      unless File.exist?(CLIENTS_FILE)
        default_clients = { "clients" => [] } # [{id,name,phone,addr,notes,invoices:[{id,title,date,payload}]}]
        begin
          File.write(CLIENTS_FILE, JSON.pretty_generate(default_clients), mode: "w:utf-8")
        rescue
        end
      end

      @storage_ready = File.exist?(MATERIALS_FILE) && File.exist?(COMPANY_FILE) && File.exist?(CLIENTS_FILE)
      @storage_ready
    end

    def self.read_json_file(path, fallback)
      begin
        return fallback unless File.exist?(path)
        raw = File.read(path, mode: "r:bom|utf-8")
        data = JSON.parse(raw)
        data
      rescue
        fallback
      end
    end

    def self.write_json_file(path, hash)
      begin
        FileUtils.mkdir_p(File.dirname(path)) unless Dir.exist?(File.dirname(path))
        File.write(path, JSON.pretty_generate(hash), mode: "w:utf-8")
        true
      rescue => e
        MHDESIGN_INVOICE_LANG.messagebox("تعذر حفظ الملف:\n#{path}\nالسبب: #{e}")
        false
      end
    end

    # --------------------------------------------
    # تحميل/حفظ أسعار الخامات
    # --------------------------------------------

    def self.load_prices_from_file
      ensure_storage_files_exist!
      h = read_json_file(MATERIALS_FILE, DEFAULT_MATERIALS.dup)
      (h.is_a?(Hash) ? h : DEFAULT_MATERIALS.dup)
    end

    def self.save_prices_to_file(prices_hash)
      ensure_storage_files_exist!
      write_json_file(MATERIALS_FILE, prices_hash.is_a?(Hash) ? prices_hash : DEFAULT_MATERIALS.dup)
    end

    # --------------------------------------------
    # تحميل/حفظ بيانات الشركة
    # --------------------------------------------

    def self.load_company_from_file
      ensure_storage_files_exist!
      comp = read_json_file(COMPANY_FILE, {
        "company_name" => "MHDESIGN",
        "company_phone"=> "+20",
        "company_addr" => "Egypt",
        "logo_url"     => "",
        "footer_notes" => ""
      })
      comp = {} unless comp.is_a?(Hash)
      comp["company_name"] ||= "MHDESIGN"
      comp["company_phone"]||= "+20"
      comp["company_addr"] ||= "Egypt"
      comp["logo_url"]     ||= ""
      comp["footer_notes"] ||= ""
      comp
    end

    def self.save_company_to_file(data)
      ensure_storage_files_exist!
      data = {
        "company_name" => (data["company_name"] || "MHDESIGN").to_s,
        "company_phone"=> (data["company_phone"] || "+20").to_s,
        "company_addr" => (data["company_addr"] || "Egypt").to_s,
        "logo_url"     => (data["logo_url"] || "").to_s,
        "footer_notes" => (data["footer_notes"] || "").to_s
      }
      write_json_file(COMPANY_FILE, data)
    end

    # --------------------------------------------
    # تحميل/حفظ العملاء + فواتيرهم (clients.json)
    # --------------------------------------------

    def self.load_clients_from_file
      ensure_storage_files_exist!
      data = read_json_file(CLIENTS_FILE, {"clients"=>[]})
      data = {"clients"=>[]} unless data.is_a?(Hash) && data["clients"].is_a?(Array)
      data
    end

    def self.save_clients_to_file(data)
      ensure_storage_files_exist!
      data = {"clients"=>[]} unless data.is_a?(Hash) && data["clients"].is_a?(Array)
      write_json_file(CLIENTS_FILE, data)
    end

    def self.find_client(data, cid)
      return nil unless data && data["clients"].is_a?(Array)
      data["clients"].find { |c| c["id"].to_s == cid.to_s }
    end

    # --------------------------------------------
    # حسابات قياس
    # --------------------------------------------

    def self.inches_to_cm(length_in_inches)
      length_in_inches.to_f * 2.54
    end

    # هنعتبر العرض = أكبر بُعد أفقي، والارتفاع = Z
    def self.bounds_in_cm(entity)
      lenx = entity.get_attribute("dynamic_attributes", "lenx").to_f
      lenz = entity.get_attribute("dynamic_attributes", "lenz").to_f

      if lenx > 0 && lenz > 0
        width_cm  = inches_to_cm(lenx)
        height_cm = inches_to_cm(lenz)
      else
        b = entity.bounds
        width_cm  = inches_to_cm(b.width)
        height_cm = inches_to_cm(b.height)
      end

      [width_cm.round(1), height_cm.round(1)]
    end

    # --------------------------------------------
    # أسماء المكونات
    # --------------------------------------------
    module NameResolver
      def self.get_component_name(e)
        return "Group" unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)

        dyn_name = e.get_attribute("dynamic_attributes", "name").to_s.strip
        return dyn_name unless dyn_name.empty?

        inst = e.name.to_s.strip
        return inst unless inst.empty?

        def_name = MHDESIGN::Language.original_definition_name(e.definition).to_s.strip
        return def_name unless def_name.empty?

        "Group"
      end
    end

    # --------------------------------------------
    # جمع الوحدات
    # --------------------------------------------
    def self.collect_units
      model = Sketchup.active_model
      ents  = if model.selection && model.selection.count > 0
                model.selection.to_a
              else
                model.active_entities.to_a
              end

      items = []
      ents.each do |e|
        next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
        next if e.deleted? || !e.visible?

        custom_name = e.get_attribute(ATTR_NS, "custom_name")
        name = if custom_name && !custom_name.to_s.strip.empty?
                 custom_name.to_s
               else
                 NameResolver.get_component_name(e)
               end

        w_cm, h_cm = bounds_in_cm(e)
        mat = (e.get_attribute(ATTR_NS, "material") || "MDF").to_s
        qty = (e.get_attribute(ATTR_NS, "qty") || 1).to_i
        guid = e.persistent_id.to_s

        items << {
          "guid"      => guid,
          "name"      => name,
          "display_name" => MHDESIGN_INVOICE_LANG.t(name),
          "width_m"   => w_cm,
          "height_m"  => h_cm,
          "material"  => mat,
          "qty"       => qty
        }
      end
      items
    end

    # --------------------------------------------
    # تعديل خصائص العناصر في الموديل
    # --------------------------------------------

    def self.find_entity_by_guid(guid)
      model = Sketchup.active_model
      model.entities.grep(Sketchup::Entity).find { |x|
        x.respond_to?(:persistent_id) && x.persistent_id.to_s == guid.to_s
      }
    end

    def self.set_entity_material(guid, material)
      e = find_entity_by_guid(guid)
      return unless e && (e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance))
      e.set_attribute(ATTR_NS, "material", material.to_s)

      prices = load_prices_from_file
      unless prices.key?(material.to_s)
        prices[material.to_s] = 0.0
        save_prices_to_file(prices)
      end
    end

    def self.set_entity_qty(guid, qty)
      e = find_entity_by_guid(guid)
      return unless e && (e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance))
      e.set_attribute(ATTR_NS, "qty", qty.to_i)
    end

    def self.set_entity_name(guid, name)
      e = find_entity_by_guid(guid)
      return unless e && (e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance))
      name = name.to_s
      e.set_attribute(ATTR_NS, "custom_name", name)
      begin
        e.name = name if e.respond_to?(:name)
      rescue
      end
    end

    # --------------------------------------------
    # HTML Dialog (المحرر)
    # --------------------------------------------

    def self.open_invoice_dialog
      if blocking_legacy_files_present?
        show_uninstall_block_message
        return
      end

      ensure_storage_files_exist!

      dlg = UI::HtmlDialog.new({
        :dialog_title => MHDESIGN_INVOICE_LANG.t("إصدار فاتورة - MHDESIGN"),
        :preferences_key => "MHDESIGN_MHINVOICE",
        :scrollable => true,
        :resizable => true,
        :width => 1150,
        :height => 760,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })

      dlg.set_html(invoice_editor_html)

      # جلب البيانات الأولية (الوحدات + الأسعار + بيانات الشركة + العملاء)
      dlg.add_action_callback("request_initial_data") { |_d, _p|
        items   = collect_units
        prices  = load_prices_from_file
        company = load_company_from_file
        clients = load_clients_from_file
        payload = {"items" => items, "prices" => prices, "company" => company, "clients" => clients}
        js = "window.__MH_loadInitialData(#{JSON.generate(payload)});"
        dlg.execute_script(js)
      }

      # حفظ أسعار الخامات (إلى ملف)
      dlg.add_action_callback("save_prices") { |_d, json_str|
        begin
          data = JSON.parse(json_str)
          save_prices_to_file(data) if data.is_a?(Hash)
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_4CB6877E9156')}#{e}")
        end
      }

      # حفظ بيانات الشركة (إلى ملف)
      dlg.add_action_callback("save_company") { |_d, json_str|
        begin
          data = JSON.parse(json_str)
          save_company_to_file(data) if data.is_a?(Hash)
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_49BD1F06B3DE')}#{e}")
        end
      }

      # تعيين خامة/كمية/اسم
      dlg.add_action_callback("set_entity_material") { |_d, json_str|
        begin
          data = JSON.parse(json_str)
          set_entity_material(data["guid"], data["material"])
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_FA5CD1D69B06')}#{e}")
        end
      }
      dlg.add_action_callback("set_entity_qty") { |_d, json_str|
        begin
          data = JSON.parse(json_str); set_entity_qty(data["guid"], data["qty"])
        rescue
        end
      }
      dlg.add_action_callback("set_entity_name") { |_d, json_str|
        begin
          data = JSON.parse(json_str); set_entity_name(data["guid"], data["name"])
        rescue
        end
      }

      # استيراد CSV لأسعار الخامات
      dlg.add_action_callback("import_csv_prices") { |_d, csv_text|
        prices = load_prices_from_file
        begin
          CSV.parse(csv_text, headers: true) do |row|
            mat   = (row['material'] || row[0]).to_s
            price = (row['price']    || row[1]).to_s
            next if mat.strip.empty?
            price_f = price.to_f
            next if price_f <= 0.0
            prices[mat.strip] = price_f
          end
          save_prices_to_file(prices)
          js = "window.__MH_afterImportPrices(#{JSON.generate(prices)});"
          dlg.execute_script(js)
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_C10A54DFB606')}#{e}")
        end
      }

      # ======= إدارة العملاء (Callbacks) =======
      dlg.add_action_callback("clients_read") { |_d, _|
        data = load_clients_from_file
        dlg.execute_script("window.__MH_clientsLoaded(#{JSON.generate(data)})")
      }

      dlg.add_action_callback("clients_write") { |_d, json_str|
        begin
          data = JSON.parse(json_str)
          save_clients_to_file(data)
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_DAE8CC6A471C')}#{e}")
        end
      }

      dlg.add_action_callback("client_save_invoice") { |_d, json_str|
        begin
          p = JSON.parse(json_str)
          cid = p["client_id"].to_s
          title = (p["title"] || "").to_s
          payload = p["payload"] || {}
          data = load_clients_from_file
          client = find_client(data, cid)
          if client
            client["invoices"] ||= []
            inv = {
              "id" => SecureRandom.uuid,
              "title" => title.empty? ? "فاتورة #{Time.now.strftime('%Y-%m-%d %H:%M')}" : title,
              "date"  => Time.now.strftime('%Y-%m-%d'),
              "payload" => payload
            }
            client["invoices"].unshift(inv)
            save_clients_to_file(data)
            dlg.execute_script("window.__MH_afterSaveInvoice(#{JSON.generate(inv)})")
          else
            MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_903EA48D40FD')}")
          end
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_B278930ACAC7')}#{e}")
        end
      }

      dlg.add_action_callback("client_get_invoice") { |_d, json_str|
        begin
          p = JSON.parse(json_str)
          cid = p["client_id"].to_s
          iid = p["invoice_id"].to_s
          data = load_clients_from_file
          client = find_client(data, cid)
          if client && client["invoices"].is_a?(Array)
            inv = client["invoices"].find{ |x| x["id"].to_s == iid }
            if inv
              dlg.execute_script("window.__MH_loadInvoicePayload(#{JSON.generate(inv["payload"])})")
            else
              MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_B48AFA50152F')}")
            end
          else
            MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_903EA48D40FD')}")
          end
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_F1DAC897B90D')}#{e}")
        end
      }

      dlg.add_action_callback("clients_export") { |_d, _|
        begin
          data = load_clients_from_file
          js = "window.__MH_downloadClients && window.__MH_downloadClients(#{JSON.generate(data)})"
          dlg.execute_script(js)
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_51A5000F068F')}#{e}")
        end
      }

      dlg.add_action_callback("clients_import") { |_d, json_str|
        begin
          data = JSON.parse(json_str)
          if data.is_a?(Hash) && data["clients"].is_a?(Array)
            save_clients_to_file(data)
            dlg.execute_script("window.__MH_clientsLoaded(#{JSON.generate(data)})")
          else
            MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_888B8E8460C3')}")
          end
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_B1934AA0222E')}#{e}")
        end
      }

      # توليد HTML للطباعة
      dlg.add_action_callback("generate_invoice_html") { |_d, json_str|
        begin
          payload = JSON.parse(json_str)
          inv_html = generate_printable_invoice(payload)
          inv_dlg = UI::HtmlDialog.new({
            :dialog_title => MHDESIGN_INVOICE_LANG.t("فاتورة - MHDESIGN"),
            :preferences_key => "MHDESIGN_MHINVOICE_PRINT",
            :scrollable => true,
            :resizable => true,
            :width => 1000,
            :height => 800,
            :style => UI::HtmlDialog::STYLE_DIALOG
          })
          inv_dlg.set_html(inv_html)
          inv_dlg.show
        rescue => e
          MHDESIGN_INVOICE_LANG.messagebox("#{MHDESIGN::Language.for_tool('invoice').t('TEXT_B56A2E861A49')}#{e}")
        end
      }

      dlg.show
    end

    # --------------------------------------------
    # HTML واجهة المحرر + إدارة العملاء
    # --------------------------------------------
    def self.invoice_editor_html
      locale = MHDESIGN_INVOICE_LANG.current.to_s
      if @invoice_editor_html_cache && @invoice_editor_html_cache_locale == locale
        return @invoice_editor_html_cache
      end

      html = <<~HTML_EDITOR
<!DOCTYPE html>
<html lang="#{MHDESIGN_INVOICE_LANG.current}" dir="#{MHDESIGN_INVOICE_LANG.direction}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>#{MHDESIGN_INVOICE_LANG.t('إصدار فاتورة - MHDESIGN')}</title>
<style>
  *{box-sizing:border-box;font-family:Tahoma,Arial,sans-serif}
  body{margin:0;background:#f4f6f9;color:#222}
  header{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;background:#fff;border-bottom:1px solid #e5e7eb}
  .brand{display:flex;align-items:center;gap:12px}
  .brand img{height:48px;width:auto;border-radius:8px;object-fit:contain}
  .controls{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
  .btn{padding:8px 12px;border:1px solid #ddd;background:#fff;border-radius:8px;cursor:pointer}
  .btn.primary{background:#111827;color:#fff;border-color:#111827}
  .btn.ghost{background:transparent}
  .wrap{max-width:1150px;margin:14px auto;padding:0 12px}
  .card{background:#fff;border:1px solid #e5e7eb;border-radius:12px;margin-bottom:12px}
  .card h3{margin:0;padding:12px 14px;border-bottom:1px solid #f0f0f0;font-size:15px}
  .card .content{padding:12px 14px}
  label{font-size:13px;color:#333;display:block;margin-bottom:6px}
  input[type="text"], input[type="number"], select, textarea{width:100%;padding:8px;border:1px solid #ddd;border-radius:8px}
  table{width:100%;border-collapse:collapse}
  th,td{padding:8px;border-bottom:1px solid #f1f2f4;text-align:center;font-size:13px}
  thead th{background:#fafafa}
  .small{font-size:12px;color:#666}
  .grid{display:grid;gap:10px}
  .grid-3{grid-template-columns:1fr 1fr 1fr}
  .grid-4{grid-template-columns:1fr 1fr 1fr 1fr}
  .right{direction:rtl;text-align:right}
  .left{direction:ltr;text-align:left}
  .table-wrap{overflow:auto;max-height:320px}
  .footer-note{font-size:11px;color:#666;margin-top:8px}
  .muted{color:#777}
  .modal{display:none;position:fixed;inset:60px 60px auto 60px;z-index:50}
  .modal .card{height:100%;display:flex;flex-direction:column}
  .modal .content{flex:1;overflow:auto}
  .bar{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
  @media screen {
    body{background:#EDF5FB}
    .btn,.btn.ghost{background:#253443;color:#F4F7FA;border-color:#253443}
    .btn.primary{background:#101B27;border-color:#101B27}
    .btn:not(:disabled):hover{background:#34495D;border-color:#34495D}
  }
</style>
</head>
<body>

<script>
  const MHD_L10N = #{MHDESIGN_INVOICE_LANG.payload_json};
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

  
</script>

<header>
  <div class="brand">
    <img id="logo" src="" alt="logo" onerror="this.style.display='none'"/>
    <div>
      <div id="company_name" style="font-weight:700">MHDESIGN</div>
      <div class="small"><span id="company_phone">+20</span> • <span id="company_addr">Egypt</span></div>
    </div>
  </div>
  <div class="controls">
    <button class="btn" onclick="openCompany()">#{MHDESIGN_INVOICE_LANG.t('بيانات الشركة')}</button>
    <button class="btn" onclick="openPrices()">#{MHDESIGN_INVOICE_LANG.t('أسعار الخامات')}</button>
    <button class="btn" onclick="openClients()">#{MHDESIGN_INVOICE_LANG.t('إدارة العملاء')}</button>
    <button class="btn ghost" onclick="openSaveToClient()">#{MHDESIGN_INVOICE_LANG.t('حفظ الفاتورة للعميل')}</button>
    <button class="btn primary" onclick="generateInvoice()">#{MHDESIGN_INVOICE_LANG.t('إصدار الفاتورة')}</button>
  </div>
</header>

<div class="wrap">
  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('بيانات العميل وبيانات الفاتورة')}</h3>
    <div class="content grid grid-3">
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('اسم العميل')}</label>
        <input id="client_name" type="text" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('SHOP_REPORT_CLIENT_NAME')}">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('الفرع')}</label>
        <input id="branch" type="text" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_BRANCH')}">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('رقم إستمارة التعاقد')}</label>
        <input id="contract_no" type="text" placeholder="">
      </div>

      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('تاريخ الإصدار')}</label>
        <input id="invoice_date" type="text" value="">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('المصمم / المسئول')}</label>
        <input id="designer" type="text" placeholder="">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('ملاحظة عامة')}</label>
        <input id="general_note" type="text">
      </div>
    </div>
  </div>

  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('إعدادات الحساب')}</h3>
    <div class="content grid grid-4">
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('وضع الحساب')}</label>
        <select id="mode">
          <option value="linear">#{MHDESIGN_INVOICE_LANG.t('متر طولي (عرض)')}</option>
          <option value="square">#{MHDESIGN_INVOICE_LANG.t('متر مربع (عرض × ارتفاع)')}</option>
        </select>
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('نسبة الخصم %')}</label>
        <input id="discount_percent" type="number" value="0" min="0" max="100">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('إظهار وحدات غير محددة')}</label>
        <select id="show_empty">
          <option value="1">#{MHDESIGN_INVOICE_LANG.t('نعم')}</option>
          <option value="0">#{MHDESIGN_INVOICE_LANG.t('لا')}</option>
        </select>
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('إجمالي تلقائي عند التعديل')}</label>
        <select id="auto_calc">
          <option value="1" selected>#{MHDESIGN_INVOICE_LANG.t('نعم')}</option>
          <option value="0">#{MHDESIGN_INVOICE_LANG.t('لا')}</option>
        </select>
      </div>
    </div>
  </div>

  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('بيان تفصيلي للوحدات')}</h3>
    <div class="content">
      <div class="table-wrap">
        <table id="items_table">
          <thead>
            <tr>
              <th>#</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('الوحدة')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('العرض (سم)')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('الارتفاع (سم)')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('الكمية')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('الخامة')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('المتر (حسب الوضع)')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('سعر/متر')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('الإجمالي')}</th>
              <th>#{MHDESIGN_INVOICE_LANG.t('ملاحظات')}</th>
              <th></th>
            </tr>
          </thead>
          <tbody></tbody>
        </table>
      </div>

      <div style="display:flex;gap:8px;margin:10px 0;flex-wrap:wrap;align-items:flex-end">
        <input id="add_name" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('REPORT_UNIT_NAME')}" />
        <input id="add_wcm" type="number" step="any" inputmode="decimal" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_WIDTH_CM')}" />
        <input id="add_hcm" type="number" step="any" inputmode="decimal" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_HEIGHT_CM')}" />
        <input id="add_qty" type="number" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('REPORT_QUANTITY')}" value="1" min="1"/>
        <select id="add_mat"></select>
        <button class="btn" onclick="addManualUnit()">#{MHDESIGN_INVOICE_LANG.t('إضافة وحدة')}</button>
      </div>

      <div style="display:flex;justify-content:space-between;margin-top:8px;gap:8px;flex-wrap:wrap">
        <div class="small muted">#{MHDESIGN_INVOICE_LANG.t('ملاحظة: يمكنك تعديل الاسم/الخامة/الكمية/العرض/الارتفاع لكل وحدة مباشرة من الجدول.')}</div>
        <div style="display:flex;gap:8px">
          <button class="btn" onclick="refreshItems()">#{MHDESIGN_INVOICE_LANG.t('تحديث الوحدات')}</button>
          <button class="btn" onclick="clearItems()">#{MHDESIGN_INVOICE_LANG.t('مسح الجدول')}</button>
        </div>
      </div>

      <div style="display:flex;justify-content:flex-end;gap:12px;margin-top:10px">
        <div class="small">#{MHDESIGN::Language.for_tool('invoice').html('TEXT_23D1BC64140C')} <b id="grand_meters">0</b></div>
        <div class="small">#{MHDESIGN::Language.for_tool('invoice').html('TEXT_7DCAF4630C0C')} <b id="unit_count">0</b></div>
        <div class="small">#{MHDESIGN::Language.for_tool('invoice').html('TEXT_F8C88EB3CBA9')} <b id="grand_total">0</b></div>
      </div>
    </div>
  </div>

  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('الإكسسوارات الإضافية')}</h3>
    <div class="content">
      <div class="table-wrap">
        <table id="acc_table">
          <thead><tr><th>#{MHDESIGN_INVOICE_LANG.t('البند')}</th><th>#{MHDESIGN_INVOICE_LANG.t('سعر الوحدة')}</th><th>#{MHDESIGN_INVOICE_LANG.t('العدد')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الإجمالي')}</th><th></th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
      <div style="display:flex;gap:8px;margin-top:10px">
        <input id="acc_name" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_ITEM_NAME')}">
        <input id="acc_price" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_UNIT_PRICE')}" type="number" step="any" inputmode="decimal">
        <input id="acc_qty" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_COUNT')}" type="number" value="1">
        <button class="btn" onclick="addAcc()">#{MHDESIGN_INVOICE_LANG.t('إضافة')}</button>
      </div>
    </div>
  </div>

  <div class="footer-note" style="text-align:center;">
    <div>
      #{MHDESIGN::Language.for_tool('invoice').html('TEXT_E1E050AA925B')}
      <a href="https://www.mhdesign-eg.com" target="_blank" style="color:#0073e6; text-decoration:none;">
        www.mhdesign-eg.com
      </a>
      "+201100211340"
    </div>
  </div>
</div>

<div id="modal_company" class="modal">
  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('بيانات الشركة')}</h3>
    <div class="content grid grid-3">
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('اسم الشركة')}</label>
        <input id="inp_company_name" type="text">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('هاتف')}</label>
        <input id="inp_company_phone" type="text">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('العنوان')}</label>
        <input id="inp_company_addr" type="text">
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('رابط اللوجو (URL)')}</label>
        <input id="inp_logo_url" type="text" placeholder="https://...">
      </div>
      <div style="grid-column:1/-1">
        <label>#{MHDESIGN_INVOICE_LANG.t('ملاحظات الفوتر (تظهر في أسفل الفاتورة)')}</label>
        <textarea id="inp_footer_notes" rows="3"></textarea>
      </div>
      <div style="display:flex;gap:8px;justify-content:flex-end">
        <button class="btn" onclick="closeCompany()">#{MHDESIGN_INVOICE_LANG.t('إلغاء')}</button>
        <button class="btn primary" onclick="saveCompany()">#{MHDESIGN_INVOICE_LANG.t('حفظ')}</button>
      </div>
    </div>
  </div>
</div>

<div id="modal_prices" class="modal">
  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('أسعار الخامات')}</h3>
    <div class="content">
      <div class="table-wrap" style="max-height:300px;overflow:auto">
        <table id="prices_table">
          <thead><tr><th>#{MHDESIGN_INVOICE_LANG.t('الخامة')}</th><th>#{MHDESIGN_INVOICE_LANG.t('سعر/متر')}</th><th></th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
      <div class="bar" style="margin-top:10px">
        <input id="new_mat" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_NEW_MATERIAL')}">
        <input id="new_price" type="number" step="any" inputmode="decimal" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_PRICE')}">
        <button class="btn" onclick="addMaterial()">#{MHDESIGN_INVOICE_LANG.t('إضافة')}</button>
        <label class="btn">#{MHDESIGN_INVOICE_LANG.t('استيراد CSV')}<input type="file" accept=".csv" style="display:none" onchange="importCSV(this)"></label>
        <div style="margin-inline-start:auto">
          <button class="btn" onclick="closePrices()">#{MHDESIGN_INVOICE_LANG.t('إغلاق')}</button>
          <button class="btn primary" onclick="savePrices()">#{MHDESIGN_INVOICE_LANG.t('حفظ')}</button>
        </div>
      </div>
    </div>
  </div>
</div>

<div id="modal_clients" class="modal">
  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('إدارة العملاء')}</h3>
    <div class="content">
      <div class="bar" style="margin-bottom:8px">
        <input id="cl_search" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_SEARCH_CLIENT')}" oninput="renderClients()">
        <button class="btn" onclick="newClient()">#{MHDESIGN_INVOICE_LANG.t('عميل جديد')}</button>
        <button class="btn" onclick="exportClients()">#{MHDESIGN_INVOICE_LANG.t('تصدير العملاء')}</button>
        <label class="btn">#{MHDESIGN_INVOICE_LANG.t('استيراد JSON')}<input type="file" accept=".json" style="display:none" onchange="importClients(this)"></label>
        <div style="margin-inline-start:auto">
          <button class="btn" onclick="closeClients()">#{MHDESIGN_INVOICE_LANG.t('إغلاق')}</button>
          <button class="btn primary" onclick="saveClients()">#{MHDESIGN_INVOICE_LANG.t('حفظ')}</button>
        </div>
      </div>
      <div class="table-wrap" style="max-height:320px">
        <table id="clients_table">
          <thead><tr><th>#</th><th>#{MHDESIGN_INVOICE_LANG.t('الاسم')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الهاتف')}</th><th>#{MHDESIGN_INVOICE_LANG.t('العنوان')}</th><th>#{MHDESIGN_INVOICE_LANG.t('ملاحظات')}</th><th>#{MHDESIGN_INVOICE_LANG.t('فواتير')}</th><th>#{MHDESIGN_INVOICE_LANG.t('استخدام')}</th><th>#{MHDESIGN_INVOICE_LANG.t('حذف')}</th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<div id="modal_save_to_client" class="modal">
  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('حفظ الفاتورة للعميل')}</h3>
    <div class="content grid grid-3">
      <div style="grid-column:1/3">
        <label>#{MHDESIGN_INVOICE_LANG.t('اختر العميل')}</label>
        <select id="save_client_select"></select>
      </div>
      <div>
        <label>#{MHDESIGN_INVOICE_LANG.t('عنوان/اسم الفاتورة')}</label>
        <input id="save_invoice_title" placeholder="#{MHDESIGN::Language.for_tool('invoice').html('INV_INVOICE_EXAMPLE')}">
      </div>
      <div style="grid-column:1/-1;display:flex;gap:8px;justify-content:flex-end">
        <button class="btn" onclick="closeSaveToClient()">#{MHDESIGN_INVOICE_LANG.t('إلغاء')}</button>
        <button class="btn primary" onclick="confirmSaveToClient()">#{MHDESIGN_INVOICE_LANG.t('حفظ')}</button>
      </div>
    </div>
  </div>
</div>

<div id="modal_client_invoices" class="modal">
  <div class="card">
    <h3>#{MHDESIGN_INVOICE_LANG.t('فواتير العميل')}</h3>
    <div class="content">
      <div id="client_invoices_head" class="small muted" style="margin-bottom:6px"></div>
      <div class="table-wrap" style="max-height:320px">
        <table id="client_invoices_table">
          <thead><tr><th>#</th><th>#{MHDESIGN_INVOICE_LANG.t('العنوان')}</th><th>#{MHDESIGN_INVOICE_LANG.t('التاريخ')}</th><th>#{MHDESIGN_INVOICE_LANG.t('تحميل')}</th></tr></thead>
          <tbody></tbody>
        </table>
      </div>
      <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:8px">
        <button class="btn" onclick="closeClientInvoices()">#{MHDESIGN_INVOICE_LANG.t('إغلاق')}</button>
      </div>
    </div>
  </div>
</div>

<script>
  const su = {
    cb: (name, payload="") => {
      if (window.sketchup && window.sketchup[name]) {
        window.sketchup[name](payload);
      }
    }
  };

  let STATE = {
    company: {company_name:"MHDESIGN", company_phone:"+20", company_addr:"Egypt", logo_url:"", footer_notes:""},
    prices: {},
    items: [],
    accessories: [],
    mode: "linear",
    discount_percent: 0,
    clients: {clients:[]},
  };

  let _renderTimer = null;
  function scheduleRender() {
    if (byId('auto_calc').value !== '1') return;
    clearTimeout(_renderTimer);
    _renderTimer = setTimeout(()=>{ renderItems(); }, 400);
  }

  function num(v){
    if (v === null || v === undefined) return 0;
    const s = String(v).trim().replace(',', '.');
    const n = parseFloat(s);
    return isNaN(n) ? 0 : n;
  }

  function formatMoney(v){ return Number(v||0).toLocaleString('en-US', {maximumFractionDigits:2}); }
  function byId(id){ return document.getElementById(id); }

  function openCompany(){ byId('modal_company').style.display='block'; fillCompanyForm(); }
  function closeCompany(){ byId('modal_company').style.display='none'; }
  function fillCompanyForm(){
    byId('inp_company_name').value = STATE.company.company_name || "";
    byId('inp_company_phone').value = STATE.company.company_phone || "";
    byId('inp_company_addr').value = STATE.company.company_addr || "";
    byId('inp_logo_url').value = STATE.company.logo_url || "";
    byId('inp_footer_notes').value = STATE.company.footer_notes || "";
  }
  function applyCompany(){
    byId('company_name').textContent = STATE.company.company_name || "MHDESIGN";
    byId('company_phone').textContent = STATE.company.company_phone || "+20";
    byId('company_addr').textContent = STATE.company.company_addr || "Egypt";
    const logo = byId('logo');
    if (STATE.company.logo_url){ logo.src = STATE.company.logo_url; logo.style.display='block'; } else { logo.style.display='none'; }
  }
  function saveCompany(){
    STATE.company.company_name = byId('inp_company_name').value.trim();
    STATE.company.company_phone= byId('inp_company_phone').value.trim();
    STATE.company.company_addr = byId('inp_company_addr').value.trim();
    STATE.company.logo_url     = byId('inp_logo_url').value.trim();
    STATE.company.footer_notes = byId('inp_footer_notes').value.trim();
    su.cb('save_company', JSON.stringify(STATE.company));
    applyCompany();
    closeCompany();
  }

  function openPrices(){ byId('modal_prices').style.display='block'; renderPrices(); }
  function closePrices(){ byId('modal_prices').style.display='none'; }
  function renderPrices(){
    const tb = document.querySelector('#prices_table tbody');
    tb.innerHTML = '';
    Object.keys(STATE.prices).forEach(mat=>{
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td style="text-align:center"><input data-k="mat" value="${mat}" /></td>
        <td style="text-align:center"><input data-k="price" type="number" step="any" inputmode="decimal" value="${STATE.prices[mat]||0}" /></td>
        <td style="text-align:center"><button class="btn" onclick="delMaterial('${mat}')">${mhdTranslate('حذف')}</button></td>
      `;
      tb.appendChild(tr);
    });

    const sel = byId('add_mat');
    if(sel){
      sel.innerHTML = '';
      Object.keys(STATE.prices).forEach(m=>{
        const o = document.createElement('option');
        o.value = m; o.textContent = m;
        sel.appendChild(o);
      });
    }
  }
  function addMaterial(){
    const m = byId('new_mat').value.trim();
    const p = num(byId('new_price').value);
    if(!m || !(p>0)) return;
    STATE.prices[m]=p;
    byId('new_mat').value=''; byId('new_price').value='';
    renderPrices(); renderItems();
  }
  function delMaterial(mat){
    delete STATE.prices[mat];
    renderPrices(); renderItems();
  }
  function savePrices(){
    const rows = Array.from(document.querySelectorAll('#prices_table tbody tr'));
    const newPrices = {};
    rows.forEach(r=>{
      const mat = r.querySelector('input[data-k="mat"]').value.trim();
      const price = num(r.querySelector('input[data-k="price"]').value);
      if(mat && price>0) newPrices[mat]=price;
    });
    STATE.prices = newPrices;
    su.cb('save_prices', JSON.stringify(STATE.prices));
    renderItems();
    closePrices();
  }
  function importCSV(input){
    const file = input.files[0];
    if(!file) return;
    const reader = new FileReader();
    reader.onload = function(e){
      const text = e.target.result;
      su.cb('import_csv_prices', text);
    };
    reader.readAsText(file);
  }
  window.__MH_afterImportPrices = function(prices){
    STATE.prices = prices || {};
    renderPrices();
    renderItems();
  };

  function refreshItems(){ su.cb('request_initial_data', ''); }
  window.__MH_loadInitialData = function(payload){
    STATE.items = payload.items || [];
    STATE.prices = payload.prices || {};
    STATE.company = payload.company || STATE.company;
    STATE.clients = payload.clients || {clients:[]};

    byId('invoice_date').value = new Date().toLocaleDateString('en-GB');
    applyCompany();
    renderPrices();
    renderItems();
  };

  function clearItems(){
    STATE.items = [];
    renderItems();
  }

  function addManualUnit(){
    const name = byId('add_name').value.trim() || mhdTranslate('وحدة');
    const wcm  = num(byId('add_wcm').value);
    const hcm  = num(byId('add_hcm').value);
    const qty  = parseInt(byId('add_qty').value)||1;
    const mat  = (byId('add_mat').value||'MDF');
    if(!(wcm>0) || !(hcm>=0) || !(qty>0)) return;
    const guid = 'manual-' + Date.now() + '-' + Math.floor(Math.random()*100000);
    STATE.items.push({ guid, name, width_m:wcm, height_m:hcm, material:mat, qty });
    byId('add_name').value=''; byId('add_wcm').value=''; byId('add_hcm').value=''; byId('add_qty').value='1';
    renderItems();
  }

  function renderItems(){
    const tbody = document.querySelector('#items_table tbody');
    tbody.innerHTML = '';
    let grand = 0, gmeters = 0;
    const mode = byId('mode').value || 'linear';
    STATE.mode = mode;
    STATE.discount_percent = num(byId('discount_percent').value);

    STATE.items.forEach((it, idx)=>{
      const qty = it.qty || 1;
      const width_cm = num(it.width_m);
      const height_cm= num(it.height_m);

      let meters = (mode==='linear') ? (width_cm/100.0) : ((width_cm/100.0)*(height_cm/100.0));
      meters = meters * qty;
      const price_per = num(STATE.prices[it.material]);
      const total = meters * price_per;
      grand += total;
      gmeters += meters;

      const matOptions = Object.keys(STATE.prices).map(m=>`<option value="${m}" ${m===it.material?'selected':''}>${m}</option>`).join('');
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${idx+1}</td>
        <td><input value="${(it.display_name||it.name||'').toString().replace(/"/g,'&quot;')}" oninput="onNameChange('${it.guid}', ${idx}, this.value)" /></td>
        <td><input type="number" step="any" inputmode="decimal" value="${Number(width_cm).toFixed(1)}"
               oninput="changeWidth(${idx}, this.value)" onblur="widthBlur(${idx}, this.value)" /></td>
        <td><input type="number" step="any" inputmode="decimal" value="${Number(height_cm).toFixed(1)}"
               oninput="changeHeight(${idx}, this.value)" onblur="heightBlur(${idx}, this.value)" /></td>
        <td><input type="number" min="1" value="${qty}"
               oninput="changeQty('${it.guid}', ${idx}, this.value)" onblur="qtyBlur('${it.guid}', ${idx}, this.value)" /></td>
        <td><select onchange="onChangeMaterial('${it.guid}', this.value, ${idx})">${matOptions}</select></td>
        <td>${Number(meters).toFixed(3)}</td>
        <td>${formatMoney(price_per)}</td>
        <td>${formatMoney(total)}</td>
        <td><input placeholder="${mhdTranslate('ملاحظات')}" value="${(it.note||'').toString().replace(/"/g,'&quot;')}" oninput="onNoteChange(${idx}, this.value)"/></td>
        <td><button class="btn" onclick="removeItem(${idx})">${mhdTranslate('حذف')}</button></td>
      `;
      tbody.appendChild(tr);
    });

    let acc_total = 0;
    STATE.accessories.forEach(a=> acc_total += (num(a.price) * (parseInt(a.qty)||0)));

    const discount = (grand + acc_total) * (STATE.discount_percent/100.0);
    const final_total = (grand + acc_total) - discount;

    byId('grand_total').textContent = formatMoney(final_total);
    byId('grand_meters').textContent = Number(gmeters).toFixed(3);
    byId('unit_count').textContent = STATE.items.length;
  }

  function changeWidth(idx, v){
    STATE.items[idx].width_m = num(v);
    scheduleRender();
  }
  function widthBlur(idx, v){
    STATE.items[idx].width_m = num(v);
    renderItems();
  }

  function changeHeight(idx, v){
    STATE.items[idx].height_m = num(v);
    scheduleRender();
  }
  function heightBlur(idx, v){
    STATE.items[idx].height_m = num(v);
    renderItems();
  }

  function onChangeMaterial(guid, mat, idx){
    STATE.items[idx].material = mat;
    if(!String(guid).startsWith('manual-')){
      su.cb('set_entity_material', JSON.stringify({guid: guid, material: mat}));
    }
    scheduleRender();
  }
  function changeQty(guid, idx, v){
    const n = num(v); STATE.items[idx].qty = (n>0?n:1);
    scheduleRender();
  }
  function qtyBlur(guid, idx, v){
    const n = num(v); STATE.items[idx].qty = (n>0?n:1);
    if(!String(guid).startsWith('manual-')){
      su.cb('set_entity_qty', JSON.stringify({guid: guid, qty: STATE.items[idx].qty}));
    }
    renderItems();
  }

  function onNoteChange(idx, v){ STATE.items[idx].note = v; }
  function onNameChange(guid, idx, v){
    STATE.items[idx].name = v;
    if(!String(guid).startsWith('manual-')){
      su.cb('set_entity_name', JSON.stringify({guid: guid, name: v}));
    }
  }
  function removeItem(idx){
    STATE.items.splice(idx,1);
    renderItems();
  }

  function addAcc(){
    const name = byId('acc_name').value.trim();
    const price = num(byId('acc_price').value);
    const qty = parseInt(byId('acc_qty').value) || 1;
    if(!name || price<=0) return;
    STATE.accessories.push({name, price, qty});
    byId('acc_name').value=''; byId('acc_price').value=''; byId('acc_qty').value='1';
    renderAcc();
    renderItems();
  }
  function renderAcc(){
    const tb = document.querySelector('#acc_table tbody');
    tb.innerHTML = '';
    STATE.accessories.forEach((a, idx)=>{
      const tot = (num(a.price) * (parseInt(a.qty)||0));
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${a.name}</td>
        <td><input type="number" step="any" inputmode="decimal" value="${a.price}" oninput="accPriceChange(${idx}, this.value)" onblur="accPriceBlur(${idx}, this.value)"/></td>
        <td><input type="number" min="1" value="${a.qty}" oninput="accQtyChange(${idx}, this.value)" onblur="accQtyBlur(${idx}, this.value)"/></td>
        <td>${formatMoney(tot)}</td>
        <td><button class="btn" onclick="delAcc(${idx})">${mhdTranslate('حذف')}</button></td>
      `;
      tb.appendChild(tr);
    });
  }
  function delAcc(i){ STATE.accessories.splice(i,1); renderAcc(); renderItems(); }
  function accQtyChange(i,v){ STATE.accessories[i].qty = parseInt(v)||1; scheduleRender(); }
  function accQtyBlur(i,v){ STATE.accessories[i].qty = parseInt(v)||1; renderAcc(); renderItems(); }
  function accPriceChange(i,v){ STATE.accessories[i].price = num(v); scheduleRender(); }
  function accPriceBlur(i,v){ STATE.accessories[i].price = num(v); renderAcc(); renderItems(); }

  function buildPayload(){
    return {
      company: STATE.company,
      client_name: byId('client_name').value.trim(),
      branch: byId('branch').value.trim(),
      contract_no: byId('contract_no').value.trim(),
      invoice_date: byId('invoice_date').value.trim(),
      designer: byId('designer').value.trim(),
      general_note: byId('general_note').value.trim(),
      mode: byId('mode').value,
      discount_percent: num(byId('discount_percent').value),
      items: STATE.items,
      accessories: STATE.accessories,
      prices: STATE.prices
    };
  }
  function loadPayloadIntoUI(p){
    if(!p) return;
    STATE.company = p.company || STATE.company;
    byId('client_name').value = p.client_name || '';
    byId('branch').value = p.branch || '';
    byId('contract_no').value = p.contract_no || '';
    byId('invoice_date').value = p.invoice_date || new Date().toLocaleDateString('en-GB');
    byId('designer').value = p.designer || '';
    byId('general_note').value = p.general_note || '';
    byId('mode').value = p.mode || 'linear';
    byId('discount_percent').value = (p.discount_percent!=null?p.discount_percent:0);
    STATE.items = Array.isArray(p.items) ? p.items : [];
    STATE.accessories = Array.isArray(p.accessories) ? p.accessories : [];
    STATE.prices = p.prices || STATE.prices;
    applyCompany(); renderPrices(); renderAcc(); renderItems();
  }
  function generateInvoice(){
    const payload = buildPayload();
    su.cb('generate_invoice_html', JSON.stringify(payload));
  }

  function openClients(){
    su.cb('clients_read','');
    byId('modal_clients').style.display='block';
  }
  function closeClients(){ byId('modal_clients').style.display='none'; }

  window.__MH_clientsLoaded = function(data){
    STATE.clients = (data && data.clients && Array.isArray(data.clients)) ? data : {clients:[]};
    renderClients();
    fillSaveToClientSelect();
  };

  function renderClients(){
    const tb = document.querySelector('#clients_table tbody');
    const q = (byId('cl_search').value||'').toLowerCase().trim();
    tb.innerHTML = '';
    const arr = STATE.clients.clients || [];
    arr.forEach((c, i)=>{
      const hay = `${c.name||''} ${c.phone||''} ${c.addr||''}`.toLowerCase();
      if(q && !hay.includes(q)) return;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${i+1}</td>
        <td><input value="${(c.name||'').replace(/"/g,'&quot;')}" oninput="cEdit('${c.id}','name', this.value)"></td>
        <td><input value="${(c.phone||'').replace(/"/g,'&quot;')}" oninput="cEdit('${c.id}','phone', this.value)"></td>
        <td><input value="${(c.addr||'').replace(/"/g,'&quot;')}" oninput="cEdit('${c.id}','addr', this.value)"></td>
        <td><input value="${(c.notes||'').replace(/"/g,'&quot;')}" oninput="cEdit('${c.id}','notes', this.value)"></td>
        <td><button class="btn" onclick="openClientInvoices('${c.id}#{MHDESIGN::Language.for_tool('invoice').js_fragment('TEXT_C58116834CB9')}${(c.invoices||[]).length})</button></td>
        <td><button class="btn" onclick="useClient('${c.id}')">#{MHDESIGN_INVOICE_LANG.t('استخدام')}</button></td>
        <td><button class="btn" onclick="delClient('${c.id}')">${mhdTranslate('حذف')}</button></td>
      `;
      tb.appendChild(tr);
    });
  }

  function newClient(){
    const cid = cryptoRandom();
    const c = {id: cid, name: byId('client_name').value.trim() || mhdTranslate('عميل'), phone:'', addr:'', notes:'', invoices:[]};
    STATE.clients.clients.unshift(c);
    renderClients();
    fillSaveToClientSelect();
  }
  function delClient(id){
    const a = STATE.clients.clients;
    const i = a.findIndex(x=> String(x.id)===String(id));
    if(i>=0){ a.splice(i,1); renderClients(); fillSaveToClientSelect(); }
  }
  function cEdit(id, k, v){
    const c = (STATE.clients.clients||[]).find(x=> String(x.id)===String(id));
    if(c){ c[k]=v; }
  }
  function useClient(id){
    const c = (STATE.clients.clients||[]).find(x=> String(x.id)===String(id));
    if(!c) return;
    byId('client_name').value = c.name || '';
    closeClients();
  }
  function saveClients(){
    su.cb('clients_write', JSON.stringify(STATE.clients));
    closeClients();
  }

  function exportClients(){ su.cb('clients_export',''); }
  window.__MH_downloadClients = function(data){
    try{
      const blob = new Blob([JSON.stringify(data,null,2)], {type:'application/json'});
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = 'clients.json';
      document.body.appendChild(a); a.click(); a.remove();
      URL.revokeObjectURL(url);
    }catch(e){}
  }
  function importClients(input){
    const f = input.files[0]; if(!f) return;
    const reader = new FileReader();
    reader.onload = (e)=>{
      try{
        const data = JSON.parse(e.target.result);
        su.cb('clients_import', JSON.stringify(data));
      }catch(err){ alert(mhdTranslate('ملف غير صالح.')); }
    };
    reader.readAsText(f);
  }

  function openSaveToClient(){
    fillSaveToClientSelect();
    byId('modal_save_to_client').style.display='block';
    byId('save_invoice_title').value = '';
  }
  function closeSaveToClient(){ byId('modal_save_to_client').style.display='none'; }
  function fillSaveToClientSelect(){
    const sel = byId('save_client_select');
    if(!sel) return;
    sel.innerHTML = '';
    (STATE.clients.clients||[]).forEach(c=>{
      const o = document.createElement('option');
      o.value = c.id; o.textContent = c.name || mhdTranslate('(بدون اسم)');
      sel.appendChild(o);
    });
  }
  function confirmSaveToClient(){
    const cid = byId('save_client_select').value;
    if(!cid){ alert(mhdTranslate('اختر عميلًا')); return; }
    const title = byId('save_invoice_title').value.trim();
    const payload = buildPayload();
    su.cb('client_save_invoice', JSON.stringify({client_id: cid, title, payload}));
  }
  window.__MH_afterSaveInvoice = function(inv){
    closeSaveToClient();
    alert(mhdTranslate('تم حفظ الفاتورة للعميل.'));
    su.cb('clients_read','');
  };

  let _currentInvoicesClientId = null;
  function openClientInvoices(cid){
    _currentInvoicesClientId = cid;
    const c = (STATE.clients.clients||[]).find(x=> String(x.id)===String(cid));
    if(!c) return;
    byId('client_invoices_head').textContent = `${mhdTranslate('عميل')}: ${c.name||''} — (${(c.invoices||[]).length} ${mhdTranslate('فاتورة')})`;
    const tb = document.querySelector('#client_invoices_table tbody');
    tb.innerHTML = '';
    (c.invoices||[]).forEach((inv, i)=>{
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${i+1}</td>
        <td>${(inv.title||'').toString().replace(/"/g,'&quot;')}</td>
        <td>${inv.date||''}</td>
        <td><button class="btn" onclick="loadClientInvoice('${cid}','${inv.id}')">#{MHDESIGN_INVOICE_LANG.t('تحميل')}</button></td>
      `;
      tb.appendChild(tr);
    });
    byId('modal_client_invoices').style.display='block';
  }
  function closeClientInvoices(){ byId('modal_client_invoices').style.display='none'; }
  function loadClientInvoice(cid, iid){
    su.cb('client_get_invoice', JSON.stringify({client_id: cid, invoice_id: iid}));
  }
  window.__MH_loadInvoicePayload = function(payload){
    loadPayloadIntoUI(payload);
    closeClientInvoices();
    closeClients();
  };

  function cryptoRandom(){
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
      (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
  }

  document.addEventListener('DOMContentLoaded', function(){
    byId('mode').addEventListener('change', renderItems);
    byId('discount_percent').addEventListener('input', function(){
      if(byId('auto_calc').value==='1'){ scheduleRender(); }
    });
    byId('auto_calc').addEventListener('change', function(){
      if(this.value==='1'){ renderItems(); }
    });
    setTimeout(()=>su.cb('request_initial_data', ''), 0);
  });
</script>
</body>
</html>
HTML_EDITOR
      @invoice_editor_html_cache_locale = locale
      @invoice_editor_html_cache = html.freeze
      html
    end

    # --------------------------------------------
    # HTML الفاتورة للطباعة
    # --------------------------------------------

    def self.translate_invoice_payload_for_display(payload)
      copy = Marshal.load(Marshal.dump(payload))
      if copy["items"].is_a?(Array)
        copy["items"].each do |item|
          next unless item.is_a?(Hash)
          item["display_name"] = MHDESIGN_INVOICE_LANG.t(item["name"])
          item["display_material"] = MHDESIGN_INVOICE_LANG.t(item["material"])
        end
      end
      copy
    rescue
      payload
    end

    def self.generate_printable_invoice(payload)
      payload = translate_invoice_payload_for_display(payload)
      company = payload["company"] || load_company_from_file
      items = payload["items"] || []
      prices = payload["prices"] || load_prices_from_file
      accessories = payload["accessories"] || []
      discount_percent = (payload["discount_percent"] || 0.0).to_f
      mode = payload["mode"] || "linear"

      rows_html = ""
      grand = 0.0
      total_meters = 0.0
      items.each_with_index do |it, idx|
        qty = (it["qty"] || 1).to_f
        width_cm = (it["width_m"] || 0.0).to_f
        height_cm = (it["height_m"] || 0.0).to_f
        meters = (mode == "linear") ? (width_cm/100.0) : ((width_cm/100.0) * (height_cm/100.0))
        meters = meters * qty
        price_per = prices[it["material"]] ? prices[it["material"]].to_f : 0.0
        line_total = meters * price_per
        grand += line_total
        total_meters += meters
        rows_html += <<~ROW
          <tr>
            <td style="text-align:center">#{idx+1}</td>
            <td>#{escape_html((it["display_name"] || it["name"]).to_s)}</td>
            <td style="text-align:center">#{format_num_cm(width_cm)}</td>
            <td style="text-align:center">#{format_num_cm(height_cm)}</td>
            <td style="text-align:center">#{qty.to_i}</td>
            <td style="text-align:center">#{escape_html((it["display_material"] || it["material"]).to_s)}</td>
            <td style="text-align:center">#{format_num(meters)}</td>
            <td style="text-align:center">#{format_currency(price_per)}</td>
            <td style="text-align:center">#{format_currency(line_total)}</td>
            <td>#{escape_html(it["note"].to_s)}</td>
          </tr>
        ROW
      end

      acc_rows = ""
      acc_total = 0.0
      accessories.each_with_index do |a, i|
        p = (a["price"] || 0.0).to_f
        q = (a["qty"] || 1).to_i
        t = p * q
        acc_total += t
        acc_rows += <<~AR
          <tr>
            <td>#{i+1}</td>
            <td>#{escape_html(a["name"].to_s)}</td>
            <td style="text-align:center">#{format_currency(p)}</td>
            <td style="text-align:center">#{q}</td>
            <td style="text-align:center">#{format_currency(t)}</td>
          </tr>
        AR
      end

      subtotal = grand + acc_total
      discount = subtotal * (discount_percent / 100.0)
      final_total = subtotal - discount

      html = <<~HTML_PRINT
<!DOCTYPE html>
<html lang="#{MHDESIGN_INVOICE_LANG.current}" dir="#{MHDESIGN_INVOICE_LANG.direction}">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_73AFDBF2FA8A')} #{escape_html(payload["client_name"].to_s)}</title>
<style>
  *{box-sizing:border-box;font-family:Tahoma,Arial,sans-serif}
  body{margin:20px;background:#fff;color:#222}
  header{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}
  .brand{display:flex;align-items:center;gap:12px}
  .brand img{height:70px;object-fit:contain}
  .company-info{font-size:14px}
  h2{margin:0 0 8px 0}
  table{width:100%;border-collapse:collapse;margin-bottom:8px}
  th,td{border:1px solid #ddd;padding:8px;text-align:center;font-size:13px}
  thead th{background:#f7f7f7}
  .right{direction:rtl;text-align:right}
  .totals{display:flex;justify-content:flex-end;gap:12px;margin-top:8px}
  .totals .box{min-width:260px;padding:10px;border:1px solid #ddd;background:#fafafa}
  .totals .row{display:flex;justify-content:space-between;margin:4px 0}
  footer{font-size:11px;color:#666;margin-top:14px;border-top:1px solid #eee;padding-top:10px}
  @media print {
    body{margin:0}
    header{page-break-after:avoid}
  }
</style>
</head>
<body>
  <header>
    <div class="brand">
      #{ company["logo_url"].to_s.strip.empty? ? "" : "<img src=\"#{escape_html(company['logo_url'])}\" alt=\"logo\" />" }
      <div class="company-info">
        <div style="font-weight:700;font-size:18px">#{escape_html(company['company_name'].to_s)}</div>
        <div class="small">#{escape_html(company['company_phone'].to_s)} • #{escape_html(company['company_addr'].to_s)}</div>
      </div>
    </div>
    <div style="text-align:left">
      <div style="font-weight:700">#{MHDESIGN_INVOICE_LANG.t('فاتورة حساب أمتار')}</div>
      <div class="small">#{MHDESIGN::Language.for_tool('invoice').html('TEXT_E7AE6289FC03')} #{escape_html(payload["invoice_date"].to_s)}</div>
    </div>
  </header>

  <section style="margin-bottom:8px">
    <table>
      <tr>
        <td style="width:33%"><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_7418C6FA9FD1')}</strong> #{escape_html(payload["client_name"].to_s)}</td>
        <td style="width:33%"><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_574FEB50AEE7')}</strong> #{escape_html(payload["branch"].to_s)}</td>
        <td style="width:33%"><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_8C3A8BA79E11')}</strong> #{escape_html(payload["contract_no"].to_s)}</td>
      </tr>
      <tr>
        <td><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_FD5F519903BA')}</strong> #{escape_html(payload["designer"].to_s)}</td>
        <td colspan="2"><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_477053A9274C')}</strong> #{escape_html(payload["general_note"].to_s)}</td>
      </tr>
    </table>
  </section>

  <section>
    <h3>#{MHDESIGN_INVOICE_LANG.t('بيان تفصيلي للوحدات')}</h3>
    <table>
      <thead>
        <tr>
          <th>#</th><th>#{MHDESIGN_INVOICE_LANG.t('الوحدة')}</th><th>#{MHDESIGN_INVOICE_LANG.t('العرض (سم)')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الارتفاع (سم)')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الكمية')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الخامة')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الأمتار')}</th><th>#{MHDESIGN_INVOICE_LANG.t('سعر/متر')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الإجمالي')}</th><th>#{MHDESIGN_INVOICE_LANG.t('ملاحظات')}</th>
        </tr>
      </thead>
      <tbody>
        #{rows_html}
      </tbody>
    </table>
  </section>

  <section>
    <h3>#{MHDESIGN_INVOICE_LANG.t('الإكسسوارات الإضافية')}</h3>
    <table>
      <thead><tr><th>#</th><th>#{MHDESIGN_INVOICE_LANG.t('البند')}</th><th>#{MHDESIGN_INVOICE_LANG.t('سعر الوحدة')}</th><th>#{MHDESIGN_INVOICE_LANG.t('العدد')}</th><th>#{MHDESIGN_INVOICE_LANG.t('الإجمالي')}</th></tr></thead>
      <tbody>
        #{acc_rows}
      </tbody>
    </table>
  </section>

  <div class="totals">
    <div class="box">
      <div class="row"><span><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_AABC35DE5789')}</strong></span><span>#{format_currency(grand)}</span></div>
      <div class="row"><span><strong>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_BE4544F64298')}</strong></span><span>#{format_currency(acc_total)}</span></div>
      <div class="row"><span>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_9D7B22DB0273')}</span><span>#{format_currency(subtotal)}</span></div>
      <div class="row"><span>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_0ACC805AC49E')}#{format_num(discount_percent)}%):</span><span>#{format_currency(discount)}</span></div>
      <div class="row" style="font-weight:700"><span>#{MHDESIGN::Language.for_tool('invoice').html('TEXT_B68B994D00B9')}</span><span>#{format_currency(final_total)}</span></div>
    </div>
  </div>

  <footer>
    #{escape_html(company['footer_notes'].to_s)}
  </footer>

  <script>
    window.onload = function(){ window.print(); }
  </script>
</body>
</html>
HTML_PRINT

      return html
    end

    # --------------------------------------------
    # Helpers (تنسيقات)
    # --------------------------------------------

    def self.escape_html(s)
      return "" if s.nil?
      s.to_s.gsub("&","&amp;").gsub("<","&lt;").gsub(">","&gt;").gsub('"',"&quot;")
    end

    def self.format_currency(v)
      sprintf("%0.2f", v || 0.0)
    end

    def self.format_num(v)
      sprintf("%0.3f", v || 0.0)
    end

    def self.format_num_cm(v)
      sprintf("%0.1f", v || 0.0)
    end

  end
end