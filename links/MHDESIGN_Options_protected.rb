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
      <div class="mhd-ref-brand"><picture><source media="(max-width: 620px)" srcset="https://mhdesign-eg.com/SKETCHUP022/skp/mhdesign-logo-v.png" width="1162" height="1030"><img class="mhd-ref-logo" alt="MHDESIGN" width="1600" height="533" src="https://mhdesign-eg.com/SKETCHUP022/skp/mhdesign-logo.png"></picture></div>
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


# ==================== MHDESIGN OPTIONS LANGUAGE BRIDGE ====================
module MHDESIGN_OPTIONS_LANG
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
    payload = MHDESIGN::Language.for_tool('options').ui_payload
    payload[:source_map] || payload['source_map'] || {}
  rescue
    {}
  end

  # Translate a stable translation KEY from the language file "texts" section.
  # Example: OPT_CARCASS_WIDTH, DC_BASE_WITH_BACK.
  def t(key, fallback = nil)
    key_text = key.to_s
    fallback_text = fallback.nil? ? key_text : fallback.to_s

    return fallback_text if key_text.empty?

    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('options').t(key_text, fallback_text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? key.to_s : fallback.to_s
  end


  def normalize_dc_display_text(value)
    text = value.to_s.dup
    text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    text = text.gsub(/%u([0-9A-Fa-f]{4})/) { [$1.hex].pack("U") }
    text = CGI.unescape(text) rescue text

    text = text.gsub(/<[^>]*>/, " ")
    text = text.gsub(/\bNo\.\s*/i, " ")
    text = text.gsub(/\bNo\s*/i, " ")
    text = text.gsub(/[=|_]+/, " ")
    text = text.gsub(/\s+/, " ").strip

    normalized = text.dup
    normalized = normalized.tr("أإآٱ", "اااا")
    normalized = normalized.tr("ةى", "هي")
    normalized = normalized.gsub(/[ًٌٍَُِّْـ]/, "")
    normalized = normalized.gsub(/\s+/, "")
    normalized.downcase
  rescue
    value.to_s.downcase.gsub(/\s+/, "")
  end

  def semantic_dc_option(value)
    normalized = normalize_dc_display_text(value)
    return nil if normalized.empty?

    # نوع الضلفة 1: قبضة J داخلية / بداخل الضلفة.
    inset =
      (normalized.include?("قبض") || normalized.include?("مقبض")) &&
      (
        normalized.include?("بداخل") ||
        normalized.include?("داخل") ||
        normalized.include?("بدخل") ||
        normalized.include?("بناتبدخل")
      )

    return t("DC_DOOR_TYPE_INSET", "قبضة J داخلية") if inset

    # نوع الضلفة 2: مقبض عادي أو كلاسيك.
    standard =
      (normalized.include?("قبض") || normalized.include?("مقبض")) &&
      (
        normalized.include?("عادي") ||
        normalized.include?("كلاس") ||
        normalized.include?("كلاسيك")
      )

    return t("DC_DOOR_TYPE_STANDARD", "مقبض عادي أو كلاسيك") if standard

    # نوع الضلفة 3: قبضة J خارجية / على الحافة.
    outer =
      (normalized.include?("قبض") || normalized.include?("مقبض")) &&
      (
        normalized.include?("اخر") ||
        normalized.include?("خارج") ||
        normalized.include?("الحافه") ||
        normalized.include?("حافه")
      )

    return t("DC_DOOR_TYPE_OUTER", "قبضة J خارجية") if outer

    # نوع الوحدة.
    if normalized.include?("baseunit") || normalized.include?("سفلي")
      return t("DC_BASE_WITHOUT_BACK", "وحدة سفلية بدون ضهر") if normalized.include?("بدون") &&
                                                (normalized.include?("backpanel") || normalized.include?("ضهر") || normalized.include?("ظهر"))
      return t("DC_BASE_WITH_BACK", "وحدة سفلية بضهر") if normalized.include?("مع") &&
                                             (normalized.include?("backpanel") || normalized.include?("ضهر") || normalized.include?("ظهر"))
    end

    # خامة الضهر.
    if normalized.include?("backpanel") || normalized.include?("ضهر") || normalized.include?("ظهر")
      return t("DC_BACK_WHITE", "ضهر أبيض") if normalized.include?("ابيض")
      return t("DC_BACK_WOOD", "ضهر خشابي") if normalized.include?("خشبي") || normalized.include?("خشابي")
    end

    nil
  rescue
    nil
  end

  def display(value)
    text = value.to_s
    return text if text.empty? || current == 'ar_EG'

    semantic = semantic_dc_option(text)
    return semantic unless semantic.nil? || semantic.empty?

    translated =
      if defined?(MHDESIGN::Language)
        MHDESIGN::Language.for_tool('options').translate_source(text)
      else
        t(text)
      end

    translated = translated.gsub(/\bNo\.\s*/i, '')
    translated = translated.gsub(/\bNo\s*/i, '')
    translated = translated.gsub(/\s+/, ' ').strip
    translated = translated.gsub(/\s+([,.;:])/, '\1')
    translated = translated.gsub(/\s{2,}/, ' ').strip
    translated
  rescue
    value.to_s
  end


  SOURCE_KEY_MAP_JSON = <<~JSON.freeze
{
  "مقاسات الوحدة": "OPT_GROUP_UNIT_DIMENSIONS",
  "الشاسيه": "OPT_GROUP_CARCASS",
  "الضلفة": "OPT_GROUP_DOOR",
  "الضلفه": "OPT_GROUP_DOOR",
  "الضهر": "OPT_GROUP_BACK",
  "اكسسوار": "OPT_GROUP_ACCESSORY",
  "الأدراج": "OPT_GROUP_DRAWERS",
  "خيارات إضافية": "OPT_GROUP_ADDITIONAL",
  "عرض وحدات الصف": "OPT_GROUP_ROW_WIDTHS",
  "عرض الشاسيه": "OPT_CARCASS_WIDTH",
  "عمق الشاسيه": "OPT_CARCASS_DEPTH",
  "ارتفاع الشاسيه": "OPT_CARCASS_HEIGHT",
  "ارتفاع الرجول": "OPT_LEG_HEIGHT",
  "طريقة التجميع": "OPT_ASSEMBLY_METHOD",
  "نوع القرصه": "OPT_TOP_RAIL_TYPE",
  "جنب ظاهر": "OPT_VISIBLE_SIDE",
  "فصل خامة الاجناب": "OPT_SEPARATE_SIDE_MATERIAL",
  "خامة الشاسيه": "OPT_CARCASS_MATERIAL",
  "نوع الوحدة": "OPT_UNIT_TYPE",
  "تخانة الكونتر": "OPT_PANEL_THICKNESS",
  "تخانة الشاسيه": "OPT_CARCASS_THICKNESS",
  "عدد الارفف": "OPT_SHELF_COUNT",
  "فصل خامة الاجناب+القاعده": "OPT_SEPARATE_SIDE_BASE_MATERIAL",
  "قص الرف من الامام": "OPT_TRIM_SHELF_FRONT",
  "نوع الضلفه": "OPT_DOOR_TYPE",
  "خلوص الضلفه": "OPT_DOOR_CLEARANCE",
  "خامة الضلفه": "OPT_DOOR_MATERIAL",
  "نوع الضلفه فوق الفرن": "OPT_DOOR_TYPE_ABOVE_OVEN",
  "نوع الضلفه اسفل الفرن": "OPT_DOOR_TYPE_BELOW_OVEN",
  "نوع الضلفه العلويه": "OPT_UPPER_DOOR_TYPE",
  "خامة الضلفه العلويه": "OPT_UPPER_DOOR_MATERIAL",
  "نوع الضلفه السفليه": "OPT_LOWER_DOOR_TYPE",
  "خامة الضلفه السفليه": "OPT_LOWER_DOOR_MATERIAL",
  "ارتفاع الفراغ السفلي": "OPT_LOWER_GAP_HEIGHT",
  "عدد دراع الباكم لكل ضلفه": "OPT_LIFT_ARMS_PER_DOOR",
  "بداية الشاسيه من الضهر": "OPT_CARCASS_START_FROM_BACK",
  "بداية الضهر من الخلف": "OPT_BACK_OFFSET",
  "تخانة الضهر": "OPT_BACK_THICKNESS",
  "سقوط المفحار": "OPT_GROOVE_DROP",
  "خامة الضهر": "OPT_BACK_MATERIAL",
  "إضافة اكسسوار": "OPT_ADD_ACCESSORY",
  "نوع الاكسسوار": "OPT_ACCESSORY_TYPE",
  "قيم مختلفة": "OPT_MIXED_VALUES",
  "تجاهل القيم المختلفة": "OPT_IGNORE_MIXED_VALUES",
  "نعم": "OPT_YES",
  "لا": "OPT_NO"
}
  JSON

  def source_key_map
    @source_key_map ||= JSON.parse(SOURCE_KEY_MAP_JSON)
  rescue
    {}
  end

  def key_for_source(value)
    text = value.to_s.strip
    return nil if text.empty?
    source_key_map[text]
  rescue
    nil
  end

  def keyed(value)
    text = value.to_s
    key = key_for_source(text)
    return t(key, text) if key && !key.to_s.empty?
    display(text)
  rescue
    value.to_s
  end

  def messagebox(message, *args)
    UI.messagebox(display(message), *args)
  end

  def payload_json
    payload =
      if defined?(MHDESIGN::Language)
        MHDESIGN::Language.for_tool('options').ui_payload
      else
        {
          locale: current,
          direction: (current == 'en' ? 'ltr' : 'rtl'),
          texts: {},
          source_map: {}
        }
      end

    {
      locale: payload[:locale] || payload['locale'] || current,
      direction: payload[:direction] || payload['direction'] || 'rtl',
      texts: payload[:texts] || payload['texts'] || {},
      source_map: payload[:source_map] || payload['source_map'] || {}
    }.to_json
  rescue
    '{"locale":"ar_EG","direction":"rtl","texts":{},"source_map":{}}'
  end
end
# ========================================================================

module MHDESIGN
  module PremiumComponentOptions

    DC_DICT  = "dynamic_attributes"
    LOGO_URL = "https://mhdesign-eg.com/SKETCHUP/components/logo3.png"

    # خامات شريط الحرف التي تتبع شكل خامة الضلفة أو الشاسيه.
    DOOR_BAND_MATERIAL_NAMES = [
      "شريط حرف لون علوي",
      "شريط حرف لون سفلي",
      "شريط حرف لون دولاب"
    ].freeze

    CHASSIS_BAND_MATERIAL_NAMES = [
      "شريط حرف ابيض"
    ].freeze

    GROUP_ORDER = [
      "مقاسات الوحدة",
      "الشاسيه",
      "الضلفة",
      "الضهر",
      "خيارات إضافية"
    ]

    LABEL_GROUPS = {
      "مقاسات الوحدة" => [
        "عرض الشاسيه",
        "عمق الشاسيه",
        "ارتفاع الشاسيه",
        "عمق الجنب الشمال",
        "عمق الجنب اليمين",
        "ارتفاع الرجول"
      ],
      "الشاسيه" => [
        "طريقة التجميع",
        "نوع القرصه",
        "جنب ظاهر",
        "فصل خامة الاجناب",
        "خامة الشاسيه",
        "نوع الوحدة",
        "تخانة الكونتر",
        "تخانة الشاسيه",
        "عدد الارفف",
        "فصل خامة الاجناب+القاعده",
        "رف كامل",
        "رف سابق و لاحق",
        "قص الرف من الامام"
      ],
      "الضلفة" => [
        "نوع الضلفه",
        "خلوص الضلفه",
        "خامة الضلفه",
        "نوع الضلفه فوق الفرن",
        "نوع الضلفه اسفل الفرن",
        "نوع الضلفه العلويه",
        "خامة الضلفه العلويه",
        "نوع الضلفه السفليه",
        "خامة الضلفه السفليه",
        "ارتفاع الفراغ السفلي",
        "عدد دراع الباكم لكل ضلفه"
      ],
      "الضهر" => [
        "بداية الشاسيه من الضهر",
        "بداية الضهر من الخلف",
        "تخانة الضهر",
        "سقوط المفحار",
        "خامة الضهر"
      ],
      "اكسسوار" => [
        "إضافة اكسسوار",
        "نوع الاكسسوار",
        "قطر السله الدواره"
      ]
    }

    @dlg = nil
    @observer_added = false
    @selection_observer = nil
    @refresh_timer = nil
    @saving_now = false
    @last_selection_sig = nil

    def self.dc
      return nil unless defined?($dc_observers) && $dc_observers
      $dc_observers.get_latest_class
    rescue
      nil
    end

    def self.selected_component
      ent = Sketchup.active_model.selection.first
      ent.is_a?(Sketchup::ComponentInstance) ? ent : nil
    end

    def self.selected_components
      Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
    rescue
      []
    end

    def self.decode_text(str)
      s = str.to_s.gsub(/%u([0-9A-Fa-f]{4})/) { [$1.hex].pack("U") }
      begin
        CGI.unescape(s)
      rescue
        s
      end
    end

    def self.clean_html(str)
      decode_text(str).gsub(/<[^>]*>/, "").strip
    end

    def self.cm_display(value, units)
      return value.to_s unless units.to_s.upcase == "CENTIMETERS"
      n = (value.to_f * 2.54).round(2)
      n = n.to_i if n == n.to_i
      "#{n} cm"
    end

    def self.to_dc_value(value, units)
      v = value.to_s.gsub("cm", "").strip
      return v unless units.to_s.upcase == "CENTIMETERS"
      v.to_f / 2.54
    end

    def self.parse_options(str)
      return [] if str.to_s.strip.empty? || str.to_s.strip == "&"

      str.to_s.split("&").reject { |x| x.strip.empty? }.map do |item|
        decoded = decode_text(item)
        label, value = decoded.split("=", 2)

        {
          "label" => (label || decoded).to_s.strip,
          "value" => (value || label || decoded).to_s.strip
        }
      end
    end

    # قراءة الـ Formula المخزنة للخاصية لاستخدامها فقط في عرض الاختيار الحالي.
    # Dynamic Components يخزن المعادلة غالباً بدون علامة =،
    # بينما قيمة الاختيار داخل القائمة تبدأ بعلامة =.
    def self.read_attribute_formula(ent, key)
      formula_key = "_#{key}_formula"

      value = ent.get_attribute(DC_DICT, formula_key, nil)

      if (value.nil? || value.to_s.strip.empty?) && ent.respond_to?(:definition)
        value = ent.definition.get_attribute(DC_DICT, formula_key, nil)
      end

      formula = value.to_s.strip
      return "" if formula.empty?

      formula.start_with?("=") ? formula : "=#{formula}"
    rescue
      ""
    end

    def self.keys_from_definition(ent)
      dict = ent.definition.attribute_dictionary(DC_DICT, false)
      return [] unless dict

      keys = []

      dict.each_pair do |k, _|
        k = k.to_s
        next unless k.start_with?("_") && k.end_with?("_access")
        keys << k.sub(/^_/, "").sub(/_access$/, "")
      end

      keys.uniq
    end

    def self.normalize_ar(str)
      s = clean_html(str).to_s
      s = s.tr("أإآٱ", "اااا")
      s = s.tr("ةى", "هي")
      s = s.gsub(/[ًٌٍَُِّْـ]/, "")
      s = s.gsub(/\s+/, "")
      s.strip.downcase
    end

    def self.separator_text?(str)
      clean_html(str).to_s.include?("---")
    end

    def self.fixed_group_for_label(label)
      n = normalize_ar(label)

      LABEL_GROUPS.each do |group, labels|
        labels.each do |item|
          return group if n == normalize_ar(item)
        end
      end

      is_drawer_label = n.include?("درج")

      if !is_drawer_label && n.include?("عرض") && (n.include?("شاسي") || n.include?("شاسه"))
        return "مقاسات الوحدة"
      end

      if !is_drawer_label && n.include?("عمق") && (n.include?("شاسي") || n.include?("شاسه"))
        return "مقاسات الوحدة"
      end

      if !is_drawer_label && n.include?("ارتفاع") && (n.include?("شاسي") || n.include?("شاسه"))
        return "مقاسات الوحدة"
      end

      if !is_drawer_label && n.include?("ارتفاع") && (n.include?("رجل") || n.include?("رجول") || n.include?("ارجل"))
        return "مقاسات الوحدة"
      end

      nil
    end

    def self.read_attrs(ent)
      d = dc
      raise "#{MHDESIGN::Language.for_tool('options').t('TEXT_F409C94BF268')}" unless d

      attrs = []
      dynamic_sections = []
      current_section = nil

      keys_from_definition(ent).each do |key|
        begin
          access = d.get_attribute_access(ent, key).to_s.upcase
        rescue
          access = ""
        end

        begin
          raw_label = d.get_attribute_formlabel(ent, key).to_s
        rescue
          raw_label = key
        end

        label = clean_html(raw_label)
        label = key if label.empty?

        begin
          raw_value = d.get_attribute_value(ent, key).to_s
        rescue
          raw_value = ent.get_attribute(DC_DICT, key, "").to_s
        end

        if separator_text?(raw_value) || separator_text?(label)
          title = label.to_s.gsub(/[-–—_]+/, "").strip
          title = "خيارات إضافية" if title.empty?
          current_section = title
          dynamic_sections << title unless dynamic_sections.include?(title)
          next
        end

        next if access.empty? || access == "NONE" || access == "VIEW"

        begin
          units = d.get_attribute_formulaunits(ent, key).to_s
        rescue
          units = ""
        end

        if units.empty?
          begin
            units = d.get_attribute_units(ent, key).to_s
          rescue
            units = ""
          end
        end

        begin
          options_raw = d.get_attribute_options(ent, key).to_s
        rescue
          options_raw = ""
        end

        fixed_group = fixed_group_for_label(label)

        group = if fixed_group
          fixed_group
        elsif current_section && !GROUP_ORDER.include?(current_section)
          current_section
        else
          "خيارات إضافية"
        end

        attrs << {
          "key" => key,
          "label" => label,
          "access" => access,
          "units" => units,
          "raw_value" => raw_value,
          "formula_value" => read_attribute_formula(ent, key),
          "display_value" => cm_display(raw_value, units),
          "options" => parse_options(options_raw),
          "group" => group
        }
      end

      order = ["مقاسات الوحدة", "الشاسيه", "الضلفة", "الضهر"]
      dynamic_sections.each do |g|
        next if order.include?(g) || g == "خيارات إضافية"
        order << g
      end
      order << "خيارات إضافية"

      rebalance_repeated_labels!(attrs)

      indexed = attrs.each_with_index.map { |a, i| [a, i] }
      indexed.sort_by! do |a, i|
        gi = order.index(a["group"]) || order.length
        [gi, i]
      end

      indexed.map(&:first)
    end

    def self.rebalance_repeated_labels!(attrs)
      return attrs if attrs.nil? || attrs.empty?

      group_order = []
      attrs.each do |a|
        g = a["group"].to_s
        group_order << g unless g.empty? || group_order.include?(g)
      end

      group_order.each_with_index do |group_name, gi|
        next if gi == 0

        prev_group = group_order[gi - 1]
        current_items = attrs.select { |a| a["group"].to_s == group_name }
        prev_items    = attrs.select { |a| a["group"].to_s == prev_group }

        next if current_items.length < 2 || prev_items.empty?

        labels = current_items.map { |a| normalize_ar(a["label"].to_s) }
        duplicated_labels = labels.select { |x| !x.empty? && labels.count(x) > 1 }.uniq

        duplicated_labels.each do |normalized_label|
          next if prev_items.any? { |a| normalize_ar(a["label"].to_s) == normalized_label }

          items_with_label = current_items.select { |a| normalize_ar(a["label"].to_s) == normalized_label }
          next if items_with_label.length < 2

          item_to_move = items_with_label.first
          item_to_move["group"] = prev_group
        end
      end

      attrs
    end

    MULTI_MIXED_VALUE = "__MHD_MIXED__"

    def self.multi_attr_allowed?(attr)
      group = attr["group"].to_s
      label = attr["label"].to_s
      n = normalize_ar(label)

      return true if group == "الضلفة"
      return true if group == "الضهر"
      return true if group == "الشاسيه" && n == normalize_ar("خامة الشاسيه")

      is_drawer_face_material =
        n.include?("درج") &&
        n.include?("خام") &&
        (n.include?("وش") || n.include?("وجه") || n.include?("واجه"))

      return true if is_drawer_face_material

      false
    end

    def self.multi_group_for_attr(attr)
      n = normalize_ar(attr["label"].to_s)
      is_drawer_face_material =
        n.include?("درج") &&
        n.include?("خام") &&
        (n.include?("وش") || n.include?("وجه") || n.include?("واجه"))

      return "الأدراج" if is_drawer_face_material
      attr["group"].to_s
    end

    # =========================================================
    # إضافة آمنة للتعديل الجماعي:
    # عند تحديد وحدات في صف واحد وبنفس الاتجاه، يظهر قسم مستقل
    # يحتوي على اسم كل وحدة وخانة تعديل عرضها فقط.
    # =========================================================

    ROW_DIRECTION_DOT_TOLERANCE = 0.985
    ROW_ALIGNMENT_TOLERANCE_CM  = 5.0

    def self.unit_display_name(ent)
      name = ent.get_attribute(DC_DICT, "name", "").to_s.strip
      name = MHDESIGN::Language.original_definition_name(ent.definition).to_s.strip if name.empty?
      name = "وحدة" if name.empty?
      clean_html(name)
    rescue
      "وحدة"
    end

    def self.width_attr_for(ent)
      read_attrs(ent).find do |attr|
        n = normalize_ar(attr["label"].to_s)
        next false if n.include?("درج")

        attr["group"].to_s == "مقاسات الوحدة" &&
          n.include?("عرض") &&
          (n.include?("شاسي") || n.include?("شاسه"))
      end
    rescue
      nil
    end

    def self.normalized_axis(vector)
      v = vector.clone
      return nil if v.length <= 0.000001
      v.normalize!
      v
    rescue
      nil
    end

    def self.project_point(point, axis)
      point.x.to_f * axis.x.to_f +
        point.y.to_f * axis.y.to_f +
        point.z.to_f * axis.z.to_f
    end

    # البحث عن خاصية العمق أو الارتفاع داخل مقاسات الوحدة.
    # هذه الإضافة مستقلة تماماً عن نظام عرض وحدات الصف والتحريك التلقائي.
    def self.dimension_attr_for(ent, dimension)
      read_attrs(ent).find do |attr|
        n = normalize_ar(attr["label"].to_s)
        next false if n.include?("درج")
        next false unless attr["group"].to_s == "مقاسات الوحدة"

        chassis = n.include?("شاسي") || n.include?("شاسه")

        case dimension
        when :depth
          chassis && n.include?("عمق")
        when :height
          chassis && n.include?("ارتفاع") &&
            !n.include?("رجل") && !n.include?("رجول") && !n.include?("ارجل")
        else
          false
        end
      end
    rescue
      nil
    end

    def self.dimension_numeric_value(attr)
      raw = attr["raw_value"].to_f
      units = attr["units"].to_s.upcase
      units == "CENTIMETERS" ? raw * 2.54 : raw
    rescue
      0.0
    end

    def self.dimension_value_label(attr)
      text = attr["display_value"].to_s.strip
      return text unless text.empty?

      value = dimension_numeric_value(attr).round(2)
      value = value.to_i if value == value.to_i
      units = attr["units"].to_s.upcase == "CENTIMETERS" ? " cm" : ""
      "#{value}#{units}"
    rescue
      attr["raw_value"].to_s
    end

    # يبني خانة جماعية واحدة للعمق أو الارتفاع داخل قسم "مقاسات الوحدة".
    # لو القيم مختلفة تظهر "قيم مختلفة".
    # عند اختيار "تجاهل القيم المختلفة = نعم" يطبق التعديل على أكبر مجموعة
    # من الوحدات التي تحمل نفس القيمة الحالية، ويتجاهل القيم الشاذة.
    # عند اختيار "لا" يطبق المقاس الجديد على كل الوحدات المحددة.
    def self.multi_dimension_attr(ents, dimension)
      return nil unless ents.is_a?(Array) && ents.length > 1

      items = []

      ents.each_with_index do |ent, ent_index|
        attr = dimension_attr_for(ent, dimension)
        next unless attr

        compare_value = dimension_numeric_value(attr).round(2)

        items << {
          "ent_index" => ent_index,
          "attr" => attr,
          "compare_value" => compare_value
        }
      end

      return nil if items.length < 2

      buckets = {}
      bucket_order = []

      items.each do |item|
        key = item["compare_value"]

        unless buckets.key?(key)
          buckets[key] = []
          bucket_order << key
        end

        buckets[key] << item
      end

      # أكبر مجموعة متشابهة، ولو فيه تعادل نأخذ أول قيمة ظهرت في التحديد.
      similar_items = bucket_order
        .map { |key| buckets[key] }
        .max_by { |group_items| group_items.length }

      similar_items = [] unless similar_items && similar_items.length >= 2

      first_attr = items.first["attr"]
      raw_values = items.map { |item| item["attr"]["raw_value"].to_s }.uniq
      formula_values = items.map { |item| item["attr"]["formula_value"].to_s }.uniq
      mixed = raw_values.length > 1 || formula_values.length > 1

      label = dimension == :depth ? "عمق الشاسيه" : "ارتفاع الشاسيه"

      all_targets = items.map do |item|
        attr = item["attr"]

        {
          "ent_index" => item["ent_index"],
          "key" => attr["key"],
          "units" => attr["units"]
        }
      end

      similar_targets = similar_items.map do |item|
        attr = item["attr"]

        {
          "ent_index" => item["ent_index"],
          "key" => attr["key"],
          "units" => attr["units"]
        }
      end

      {
        "key" => first_attr["key"],
        "label" => label,
        "access" => first_attr["access"],
        "units" => first_attr["units"],
        "raw_value" => mixed ? MULTI_MIXED_VALUE : first_attr["raw_value"],
        "formula_value" => mixed ? "" : first_attr["formula_value"].to_s,
        "display_value" => mixed ? "" : first_attr["display_value"],
        "placeholder" => mixed ? "قيم مختلفة" : "",
        "mixed" => mixed,
        "options" => first_attr["options"] || [],
        "group" => "مقاسات الوحدة",
        "multi_dimension" => true,
        "dimension_type" => dimension.to_s,
        "targets" => all_targets,
        "all_targets" => all_targets,
        "similar_targets" => similar_targets
      }
    rescue => e
      puts "MHDESIGN Multi Dimension Detection Error: #{e.message}"
      nil
    end

    def self.same_row_width_attrs(ents)
      return [] unless ents.is_a?(Array) && ents.length > 1

      first = ents.first
      first_tr = first.transformation
      row_axis = normalized_axis(first_tr.xaxis)
      side_axis = normalized_axis(first_tr.yaxis)
      up_axis = normalized_axis(first_tr.zaxis)
      return [] unless row_axis && side_axis && up_axis

      # الاتجاهات يجب أن تكون متطابقة فعلياً، وليس مجرد محاور متوازية عكسية.
      same_direction = ents.all? do |ent|
        tr = ent.transformation
        x = normalized_axis(tr.xaxis)
        y = normalized_axis(tr.yaxis)
        z = normalized_axis(tr.zaxis)

        x && y && z &&
          x.dot(row_axis) >= ROW_DIRECTION_DOT_TOLERANCE &&
          y.dot(side_axis) >= ROW_DIRECTION_DOT_TOLERANCE &&
          z.dot(up_axis) >= ROW_DIRECTION_DOT_TOLERANCE
      end

      return [] unless same_direction

      origins = ents.map { |ent| ent.transformation.origin }
      side_values = origins.map { |pt| project_point(pt, side_axis) }
      up_values   = origins.map { |pt| project_point(pt, up_axis) }
      row_values  = origins.map { |pt| project_point(pt, row_axis) }

      tolerance = ROW_ALIGNMENT_TOLERANCE_CM.cm.to_f

      # نفس خط الواجهة ونفس المنسوب تقريباً.
      return [] if (side_values.max - side_values.min).abs > tolerance
      return [] if (up_values.max - up_values.min).abs > tolerance

      # يجب أن يكون هناك امتداد حقيقي على اتجاه العرض.
      return [] if (row_values.max - row_values.min).abs <= tolerance

      indexed_ents = ents.each_with_index.map { |ent, index| [ent, index] }
      indexed_ents.sort_by! { |ent, _index| project_point(ent.transformation.origin, row_axis) }

      result = []

      indexed_ents.each_with_index do |(ent, original_index), row_index|
        width_attr = width_attr_for(ent)
        return [] unless width_attr

        result << {
          "key" => width_attr["key"],
          "label" => "#{row_index + 1}. #{unit_display_name(ent)}",
          "access" => width_attr["access"],
          "units" => width_attr["units"],
          "raw_value" => width_attr["raw_value"],
          "formula_value" => width_attr["formula_value"].to_s,
          "display_value" => width_attr["display_value"],
          "placeholder" => "",
          "mixed" => false,
          "options" => width_attr["options"] || [],
          "group" => "عرض وحدات الصف",
          "targets" => [
            {
              "ent_index" => original_index,
              "key" => width_attr["key"],
              "units" => width_attr["units"]
            }
          ]
        }
      end

      result
    rescue => e
      puts "MHDESIGN Row Width Detection Error: #{e.message}"
      []
    end



    # ترجمة اسم الاختيار الظاهر باستخدام سياق الخاصية نفسها.
    # هذا يحل النصوص القديمة أو المشوهة داخل Dynamic Component Options
    # بدون تغيير opt["value"] أو أي قيمة داخلية.
    def self.option_display_label(attribute_label, option_label, option_value, option_index)
      original_label = option_label.to_s
      return original_label if MHDESIGN_OPTIONS_LANG.current == "ar_EG"

      attr = normalize_ar(attribute_label)
      option_text = "#{option_label} #{option_value}"
      normalized = MHDESIGN_OPTIONS_LANG.normalize_dc_display_text(option_text)

      # -----------------------------------------
      # طريقة التجميع
      # -----------------------------------------
      if attr == normalize_ar("طريقة التجميع")
        if normalized.include?("جنب") && normalized.include?("قاعد")
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_ASSEMBLY_SIDE_ON_BASE",
            "جنب على القاعدة"
          )
        end

        if normalized.include?("جنب") &&
           (
             normalized.include?("كامل") ||
             normalized.include?("سحابي") ||
             normalized.include?("slab")
           )
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_ASSEMBLY_FULL_SIDE",
            "جنب كامل (سحابي)"
          )
        end

        return option_index.to_i == 0 ?
          mhdKey("DC_ASSEMBLY_SIDE_ON_BASE", "جنب على القاعدة") :
          mhdKey("DC_ASSEMBLY_FULL_SIDE", "جنب كامل (سحابي)")
      end

      # -----------------------------------------
      # نوع اللوح العلوي / القرصة
      # -----------------------------------------
      if attr == normalize_ar("نوع القرصه")
        if normalized.include?("شداد") ||
           normalized.include?("عارض") ||
           normalized.include?("rail")
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_TOP_PANEL_RAILS",
            "شدادات"
          )
        end

        if normalized.include?("قرص") ||
           normalized.include?("كامل") ||
           normalized.include?("full")
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_TOP_PANEL_FULL",
            "قرصة كاملة"
          )
        end

        return option_index.to_i == 0 ?
          mhdKey("DC_TOP_PANEL_RAILS", "شدادات") :
          mhdKey("DC_TOP_PANEL_FULL", "قرصة كاملة")
      end

      # -----------------------------------------
      # خامة الهيكل / الشاسيه
      # -----------------------------------------
      if attr == normalize_ar("خامة الشاسيه")
        if normalized.include?("نفس") &&
           (
             normalized.include?("ضلف") ||
             normalized.include?("باب")
           )
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_CARCASS_SAME_AS_DOOR",
            "نفس خامة الضلفة"
          )
        end

        if normalized.include?("ابيض") ||
           normalized.include?("white")
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_CARCASS_WHITE_BOARD",
            "كونتر أبيض"
          )
        end

        if normalized.include?("خشبي") ||
           normalized.include?("خشابي") ||
           normalized.include?("wood")
          return MHDESIGN_OPTIONS_LANG.t(
            "DC_CARCASS_WOOD_BOARD",
            "كونتر خشابي"
          )
        end

        fallback_by_index = [
          mhdKey("DC_CARCASS_WHITE_BOARD", "كونتر أبيض"),
          mhdKey("DC_CARCASS_WOOD_BOARD", "كونتر خشابي"),
          mhdKey("DC_CARCASS_SAME_AS_DOOR", "نفس خامة الضلفة")
        ]

        return fallback_by_index[option_index.to_i] ||
          MHDESIGN_OPTIONS_LANG.keyed(original_label)
      end

      # -----------------------------------------
      # نوع الضلفة
      # -----------------------------------------
      if attr == normalize_ar("نوع الضلفه")
        # المقبض العادي أو الكلاسيك.
        if normalized.include?("عادي") ||
           normalized.include?("كلاس") ||
           normalized.include?("كلاسيك")
          return mhdKey("DC_DOOR_TYPE_STANDARD", "مقبض عادي أو كلاسيك")
        end

        # قبضة J داخل الضلفة.
        if normalized.include?("بداخل") ||
           normalized.include?("داخل") ||
           normalized.include?("بدخل") ||
           normalized.include?("داخلي")
          return mhdKey("DC_DOOR_TYPE_INSET", "قبضة J داخلية")
        end

        # قبضة J على الحافة الخارجية.
        if normalized.include?("اخر") ||
           normalized.include?("خارج") ||
           normalized.include?("خارجي") ||
           normalized.include?("حافه")
          return mhdKey("DC_DOOR_TYPE_OUTER", "قبضة J خارجية")
        end

        # دعم الوحدات القديمة التي تحمل نصوصًا غير مقروءة:
        # الترتيب المعتاد داخل قائمة نوع الضلفة.
        fallback_by_index = [
          mhdKey("DC_DOOR_TYPE_STANDARD", "مقبض عادي أو كلاسيك"),
          mhdKey("DC_DOOR_TYPE_INSET", "قبضة J داخلية"),
          mhdKey("DC_DOOR_TYPE_OUTER", "قبضة J خارجية")
        ]
        return fallback_by_index[option_index.to_i] || MHDESIGN_OPTIONS_LANG.keyed(original_label)
      end

      # -----------------------------------------
      # نوع الوحدة
      # -----------------------------------------
      if attr == normalize_ar("نوع الوحدة")
        if normalized.include?("بدون")
          return mhdKey("DC_BASE_WITHOUT_BACK", "وحدة سفلية بدون ضهر")
        end

        if normalized.include?("مع") ||
           normalized.include?("ضهر") ||
           normalized.include?("ظهر") ||
           normalized.include?("backpanel")
          return mhdKey("DC_BASE_WITH_BACK", "وحدة سفلية بضهر")
        end

        return option_index.to_i == 0 ?
          mhdKey("DC_BASE_WITH_BACK", "وحدة سفلية بضهر") :
          mhdKey("DC_BASE_WITHOUT_BACK", "وحدة سفلية بدون ضهر")
      end

      # -----------------------------------------
      # خامة الضهر
      # -----------------------------------------
      if attr == normalize_ar("خامة الضهر")
        if normalized.include?("ابيض") ||
           normalized.include?("white")
          return mhdKey("DC_BACK_WHITE", "ضهر أبيض")
        end

        if normalized.include?("خشبي") ||
           normalized.include?("خشابي") ||
           normalized.include?("wood")
          return mhdKey("DC_BACK_WOOD", "ضهر خشابي")
        end

        return option_index.to_i == 0 ?
          mhdKey("DC_BACK_WHITE", "ضهر أبيض") :
          mhdKey("DC_BACK_WOOD", "ضهر خشابي")
      end

      # باقي خصائص القوائم تستخدم المترجم العام.
      MHDESIGN_OPTIONS_LANG.keyed(original_label)
    rescue
      option_label.to_s
    end

    def self.translate_display_payload!(payload)
      return payload unless payload.is_a?(Hash)

      payload["message"] = MHDESIGN_OPTIONS_LANG.display(payload["message"]) if payload.key?("message")
      payload["title"]   = MHDESIGN_OPTIONS_LANG.display(payload["title"])   if payload.key?("title")
      payload["desc"]    = MHDESIGN_OPTIONS_LANG.display(payload["desc"])    if payload.key?("desc")

      attrs = payload["attrs"]
      if attrs.is_a?(Array)
        attrs.each do |attr|
          next unless attr.is_a?(Hash)

          attr["display_label"] = MHDESIGN_OPTIONS_LANG.keyed(attr["label"])
          attr["display_group"] = MHDESIGN_OPTIONS_LANG.keyed(attr["group"])
          attr["display_placeholder"] = MHDESIGN_OPTIONS_LANG.keyed(attr["placeholder"])

          options = attr["options"]
          if options.is_a?(Array)
            options.each_with_index do |opt, option_index|
              next unless opt.is_a?(Hash)

              opt["display_label"] = option_display_label(
                attr["label"],
                opt["label"],
                opt["value"],
                option_index
              )
            end
          end
        end
      end

      payload
    rescue
      payload
    end

    def self.payload_for_multi_selection(ents)
      all_items = []

      ents.each_with_index do |ent, ent_index|
        read_attrs(ent).each do |attr|
          next unless multi_attr_allowed?(attr)

          group = multi_group_for_attr(attr)
          identity = "#{group}|#{normalize_ar(attr["label"])}"

          all_items << {
            "identity" => identity,
            "ent_index" => ent_index,
            "key" => attr["key"],
            "label" => attr["label"],
            "access" => attr["access"],
            "units" => attr["units"],
            "raw_value" => attr["raw_value"],
            "formula_value" => attr["formula_value"].to_s,
            "display_value" => attr["display_value"],
            "options" => attr["options"] || [],
            "group" => group
          }
        end
      end

      buckets = {}
      order = []

      all_items.each do |item|
        id = item["identity"]
        unless buckets[id]
          buckets[id] = []
          order << id
        end
        buckets[id] << item
      end

      attrs = []

      order.each do |id|
        items = buckets[id]
        first = items.first

        raw_values = items.map { |x| x["raw_value"].to_s }.uniq
        formula_values = items.map { |x| x["formula_value"].to_s }.uniq
        mixed = raw_values.length > 1 || formula_values.length > 1

        options = []
        seen_options = {}

        items.each do |x|
          (x["options"] || []).each do |opt|
            sig = "#{opt["label"]}|#{opt["value"]}"
            next if seen_options[sig]

            seen_options[sig] = true
            options << opt
          end
        end

        access = items.any? { |x| x["access"].to_s.upcase == "LIST" } ? "LIST" : first["access"]

        attrs << {
          "key" => first["key"],
          "label" => first["label"],
          "access" => access,
          "units" => first["units"],
          "raw_value" => mixed ? MULTI_MIXED_VALUE : first["raw_value"],
          "formula_value" => mixed ? "" : first["formula_value"].to_s,
          "display_value" => mixed ? "" : first["display_value"],
          "placeholder" => mixed ? "قيم مختلفة" : "",
          "mixed" => mixed,
          "options" => options,
          "group" => first["group"],
          "targets" => items.map {
            |x| {
              "ent_index" => x["ent_index"],
              "key" => x["key"],
              "units" => x["units"]
            }
          }
        }
      end

      group_order = ["عرض وحدات الصف", "مقاسات الوحدة", "الشاسيه", "الضلفة", "الضهر", "الأدراج"]

      indexed = attrs.each_with_index.map { |a, i| [a, i] }
      indexed.sort_by! do |a, i|
        gi = group_order.index(a["group"].to_s) || group_order.length
        [gi, i]
      end

      attrs = indexed.map(&:first)

      # الإضافة المستقرة: عرض مستقل لكل وحدة عند اكتشاف صف واحد.
      row_width_attrs = same_row_width_attrs(ents)

      # قسم واحد مستقل باسم "مقاسات الوحدة" يحتوي العمق والارتفاع.
      # هذه الإضافة لا تغيّر نظام عرض الصف أو التحريك التلقائي.
      dimension_attrs = []
      depth_attr = multi_dimension_attr(ents, :depth)
      height_attr = multi_dimension_attr(ents, :height)
      dimension_attrs << depth_attr if depth_attr
      dimension_attrs << height_attr if height_attr

      attrs = row_width_attrs + dimension_attrs + attrs

      if attrs.empty?
        return {
          "ok" => false,
          "message" => "التحديد الجماعي لا يحتوي على خامات قابلة للتعديل",
          "title" => "MHDESIGN - تعديل جماعي",
          "desc" => "عدد الوحدات المحددة: #{ents.length}",
          "attrs" => [],
          "can_swap_units" => (ents.length == 2)
        }
      end

      {
        "ok" => true,
        "message" => "",
        "title" => "MHDESIGN - تعديل جماعي",
        "desc" => "عدد الوحدات المحددة: #{ents.length}",
        "attrs" => attrs,
        "can_swap_units" => (ents.length == 2)
      }
    end

    def self.payload_for_current_selection
      ents = selected_components
      return payload_for_multi_selection(ents) if ents.length > 1

      ent = ents.first

      unless ent
        return {
          "ok" => false,
          "message" => "اختار Dynamic Component",
          "title" => "MHDESIGN",
          "desc" => "",
          "attrs" => []
        }
      end

      attrs = read_attrs(ent)

      if attrs.empty?
        return {
          "ok" => false,
          "message" => "العنصر المحدد لا يحتوي على Component Options",
          "title" => "MHDESIGN",
          "desc" => "",
          "attrs" => []
        }
      end

      {
        "ok" => true,
        "message" => "",
        "title" => ent.get_attribute(DC_DICT, "name", MHDESIGN::Language.original_definition_name(ent.definition)).to_s,
        "desc" => clean_html(ent.get_attribute(DC_DICT, "description", "").to_s),
        "attrs" => attrs
      }
    rescue => e
      {
        "ok" => false,
        "message" => e.message,
        "title" => "MHDESIGN",
        "desc" => "",
        "attrs" => []
      }
    end


    # تطبيق قيمة الـ Dynamic Component مع دعم خيارات القوائم التي تحتوي على Formula
    # مثل: =BASE_UNIT_1!BASE_UNIT_1_f
    def self.apply_dc_attribute(d, ent, key, value)
      text = value.to_s.strip

      if text.start_with?("=")
        formula = text.sub(/\A=/, "")

        begin
          if d.respond_to?(:set_attribute_formula)
            d.set_attribute_formula(ent, key, formula)
          else
            ent.set_attribute(DC_DICT, "_#{key}_formula", formula)
          end
        rescue
          ent.set_attribute(DC_DICT, "_#{key}_formula", formula)
        end
      else
        # لو الخاصية كانت حالياً مرتبطة بـ Formula مثل "بنفس خامة الضلفة"،
        # فلا يكفي حفظ Value عادية لأن الـ Formula تظل لها الأولوية.
        #
        # الحل الصحيح هو استبدال الـ Formula نفسها بقيمة ثابتة:
        # النصوص تُحفظ كـ "كونتر ابيض"
        # والأرقام تُحفظ كرقم مباشر.
        formula_key = "_#{key}_formula"

        current_formula = ent.get_attribute(DC_DICT, formula_key, nil)

        if (current_formula.nil? || current_formula.to_s.strip.empty?) && ent.respond_to?(:definition)
          current_formula = ent.definition.get_attribute(DC_DICT, formula_key, nil)
        end

        if current_formula && !current_formula.to_s.strip.empty?
          fixed_formula =
            if text.match?(/\A[-+]?\d+(?:\.\d+)?\z/)
              text
            elsif ["TRUE", "FALSE"].include?(text.upcase)
              text.upcase
            else
              escaped = text.gsub("\\", "\\\\").gsub('"', '\\"')
              "\"#{escaped}\""
            end

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
            d.set_attribute(ent, key, value)
          rescue
            ent.set_attribute(DC_DICT, key, value)
          end
        end
      end
    end


    # =========================================================
    # تحريك تلقائي للوحدات المجاورة بعد تعديل عرض وحدة في الصف.
    # نحفظ ترتيب الصف والمسافات قبل إعادة رسم الـ Dynamic Components،
    # ثم نعيد رص الوحدات على نفس المحور مع تثبيت أول وحدة.
    # =========================================================

    def self.bounds_projection_range(ent, axis)
      bb = ent.bounds
      values = (0..7).map { |i| project_point(bb.corner(i), axis) }
      [values.min, values.max]
    rescue
      origin_value = project_point(ent.transformation.origin, axis)
      [origin_value, origin_value]
    end

    def self.row_layout_snapshot(ents)
      return nil unless ents.is_a?(Array) && ents.length > 1

      first = ents.first
      row_axis  = normalized_axis(first.transformation.xaxis)
      side_axis = normalized_axis(first.transformation.yaxis)
      up_axis   = normalized_axis(first.transformation.zaxis)
      return nil unless row_axis && side_axis && up_axis

      same_direction = ents.all? do |ent|
        tr = ent.transformation
        x = normalized_axis(tr.xaxis)
        y = normalized_axis(tr.yaxis)
        z = normalized_axis(tr.zaxis)

        x && y && z &&
          x.dot(row_axis) >= ROW_DIRECTION_DOT_TOLERANCE &&
          y.dot(side_axis) >= ROW_DIRECTION_DOT_TOLERANCE &&
          z.dot(up_axis) >= ROW_DIRECTION_DOT_TOLERANCE
      end
      return nil unless same_direction

      origins = ents.map { |ent| ent.transformation.origin }
      tolerance = ROW_ALIGNMENT_TOLERANCE_CM.cm.to_f

      side_values = origins.map { |pt| project_point(pt, side_axis) }
      up_values   = origins.map { |pt| project_point(pt, up_axis) }
      return nil if (side_values.max - side_values.min).abs > tolerance
      return nil if (up_values.max - up_values.min).abs > tolerance

      ordered = ents.sort_by do |ent|
        range = bounds_projection_range(ent, row_axis)
        range[0]
      end

      gaps = []
      ordered.each_cons(2) do |previous_ent, current_ent|
        previous_range = bounds_projection_range(previous_ent, row_axis)
        current_range  = bounds_projection_range(current_ent, row_axis)
        gaps << current_range[0] - previous_range[1]
      end

      {
        "axis" => row_axis,
        "units" => ordered,
        "gaps" => gaps,
        # حفظ طرفي الصف قبل تغيير المقاسات، حتى نثبت الطرف المختار فعلياً.
        "left_anchor" => bounds_projection_range(ordered.first, row_axis)[0],
        "right_anchor" => bounds_projection_range(ordered.last, row_axis)[1]
      }
    rescue => e
      puts "MHDESIGN Row Snapshot Error: #{e.message}"
      nil
    end

    def self.restore_row_layout(snapshot, shift_direction = "left")
      return false unless snapshot.is_a?(Hash)

      axis  = snapshot["axis"]
      units = snapshot["units"]
      gaps  = snapshot["gaps"]
      return false unless axis && units.is_a?(Array) && units.length > 1
      return false unless units.all? { |ent| ent && ent.valid? }

      # left: نفس السلوك القديم؛ تثبيت أول وحدة ورص الباقي بعدها.
      # right: تثبيت آخر وحدة ورص الوحدات السابقة في الاتجاه العكسي.
      if shift_direction.to_s == "right"
        # بعد الـ redraw قد يقل عرض آخر وحدة مع بقاء بدايتها ثابتة.
        # ننقلها أولاً بفرق المقاس حتى يرجع طرف الصف اليمين لمكانه القديم.
        right_anchor = snapshot["right_anchor"]
        if right_anchor
          last_ent = units.last
          last_range = bounds_projection_range(last_ent, axis)
          anchor_movement = right_anchor.to_f - last_range[1]

          if anchor_movement.abs > 0.001
            anchor_vector = Geom::Vector3d.new(
              axis.x.to_f * anchor_movement,
              axis.y.to_f * anchor_movement,
              axis.z.to_f * anchor_movement
            )
            last_ent.transform!(Geom::Transformation.translation(anchor_vector))
          end
        end

        (units.length - 2).downto(0) do |index|
          current_ent = units[index]
          next_ent    = units[index + 1]
          gap = gaps[index].to_f

          current_range = bounds_projection_range(current_ent, axis)
          next_range    = bounds_projection_range(next_ent, axis)

          desired_end = next_range[0] - gap
          movement = desired_end - current_range[1]
          next if movement.abs <= 0.001

          vector = Geom::Vector3d.new(
            axis.x.to_f * movement,
            axis.y.to_f * movement,
            axis.z.to_f * movement
          )

          current_ent.transform!(Geom::Transformation.translation(vector))
        end
      else
        # تثبيت طرف الصف الشمال في مكانه القديم حتى لو تغيّر تعريف الوحدة
        # أو كان الـ Dynamic Component يعيد بناء حدوده أثناء الـ redraw.
        left_anchor = snapshot["left_anchor"]
        if left_anchor
          first_ent = units.first
          first_range = bounds_projection_range(first_ent, axis)
          anchor_movement = left_anchor.to_f - first_range[0]

          if anchor_movement.abs > 0.001
            anchor_vector = Geom::Vector3d.new(
              axis.x.to_f * anchor_movement,
              axis.y.to_f * anchor_movement,
              axis.z.to_f * anchor_movement
            )
            first_ent.transform!(Geom::Transformation.translation(anchor_vector))
          end
        end

        (1...units.length).each do |index|
          previous_ent = units[index - 1]
          current_ent  = units[index]
          gap = gaps[index - 1].to_f

          previous_range = bounds_projection_range(previous_ent, axis)
          current_range  = bounds_projection_range(current_ent, axis)

          desired_start = previous_range[1] + gap
          movement = desired_start - current_range[0]
          next if movement.abs <= 0.001

          vector = Geom::Vector3d.new(
            axis.x.to_f * movement,
            axis.y.to_f * movement,
            axis.z.to_f * movement
          )

          current_ent.transform!(Geom::Transformation.translation(vector))
        end
      end

      Sketchup.active_model.active_view.invalidate
      true
    rescue => e
      puts "MHDESIGN Restore Row Error: #{e.message}"
      false
    end

    # =========================================================
    # الحركة الحسابية الثابتة عند تعديل عمق الشاسيه.
    #
    # المسافة = العمق الجديد - العمق القديم
    # مثال:
    # 60 -> 55 = -5 سم
    # 55 -> 60 = +5 سم
    #
    # ثم تتحرك الوحدة بهذه المسافة على محور Y المحلي الخاص بها.
    # لا يوجد قياس لنقطة الظهر ولا تعويض إضافي بعد الـ redraw.
    # =========================================================

    def self.depth_attribute_item?(item)
      return true if item["multi_dimension"] == true && item["dimension_type"].to_s == "depth"

      label = normalize_ar(item["label"].to_s)
      return false if label.include?("درج")

      label.include?("عمق") &&
        (label.include?("شاسي") || label.include?("شاسه"))
    rescue
      false
    end

    # قراءة القيمة الحالية الفعلية للخاصية بوحدة التخزين الداخلية للـ DC.
    def self.current_dc_numeric_value(d, ent, key)
      value = begin
        d.get_attribute_value(ent, key)
      rescue
        ent.get_attribute(DC_DICT, key, 0.0)
      end

      value.to_f
    rescue
      0.0
    end

    # تجهيز حركة العمق قبل تطبيق القيمة الجديدة.
    def self.depth_move_snapshot(d, ent, key, new_value)
      return nil unless ent && ent.valid?

      axis = normalized_axis(ent.transformation.yaxis)
      return nil unless axis

      old_value = current_dc_numeric_value(d, ent, key)
      new_numeric = new_value.to_f
      delta = new_numeric - old_value

      {
        "ent" => ent,
        "axis" => axis,
        "old_value" => old_value,
        "new_value" => new_numeric,
        "delta" => delta
      }
    rescue => e
      puts "MHDESIGN Depth Move Snapshot Error: #{e.message}"
      nil
    end

    # تنفيذ الحركة الحسابية بعد إعادة رسم الـ Dynamic Component.
    def self.apply_depth_move(snapshot)
      return false unless snapshot.is_a?(Hash)

      ent = snapshot["ent"]
      axis = snapshot["axis"]
      delta = snapshot["delta"].to_f
      return false unless ent && ent.valid? && axis
      return true if delta.abs <= 0.000001

      # عكس اتجاه الحركة على محور Y المحلي:
      # تقليل العمق يعطي Delta سالبة، وبعد العكس تتحرك الوحدة للخلف.
      # زيادة العمق تعطي Delta موجبة، وبعد العكس تتحرك في الاتجاه المقابل.
      move_delta = -delta

      vector = Geom::Vector3d.new(
        axis.x.to_f * move_delta,
        axis.y.to_f * move_delta,
        axis.z.to_f * move_delta
      )

      ent.transform!(Geom::Transformation.translation(vector))
      true
    rescue => e
      puts "MHDESIGN Depth Arithmetic Move Error: #{e.message}"
      false
    end

    # =========================================================
    # تبديل وحدتين من الصفر بدون نقل Scale من وحدة للأخرى.
    #
    # - كل وحدة تنتقل إلى مكان واتجاه الأخرى.
    # - كل وحدة تأخذ قيم العرض والعمق والارتفاع من الأخرى.
    # - لا يتم نقل Scale الموجود داخل Transformation الوحدة الأخرى.
    # - لا يتم استخدام Scale Tool أو Stretch يدوي.
    # - Redraw هو آخر خطوة هندسية.
    # =========================================================

    def self.swap_dimension_attrs_for(ent)
      {
        width: width_attr_for(ent),
        depth: dimension_attr_for(ent, :depth),
        height: dimension_attr_for(ent, :height)
      }
    rescue
      {}
    end

    def self.swap_slot_snapshot(ent)
      tr = ent.transformation

      xaxis = normalized_axis(tr.xaxis)
      yaxis = normalized_axis(tr.yaxis)
      zaxis = normalized_axis(tr.zaxis)
      return nil unless xaxis && yaxis && zaxis

      {
        origin: tr.origin.clone,
        xaxis: xaxis,
        yaxis: yaxis,
        zaxis: zaxis
      }
    rescue => e
      puts "MHDESIGN Swap Slot Snapshot Error: #{e.message}"
      nil
    end

    # نقل الوحدة إلى مكان واتجاه Slot أخرى بحركة صلبة فقط:
    # Translation + Rotation، بدون إنشاء Scale جديد أو نسخ Scale الوحدة الأخرى.
    def self.place_entity_in_rigid_slot(ent, slot)
      return false unless ent && ent.valid? && slot.is_a?(Hash)

      current_slot = swap_slot_snapshot(ent)
      return false unless current_slot

      current_rigid = Geom::Transformation.axes(
        current_slot[:origin],
        current_slot[:xaxis],
        current_slot[:yaxis],
        current_slot[:zaxis]
      )

      target_rigid = Geom::Transformation.axes(
        slot[:origin],
        slot[:xaxis],
        slot[:yaxis],
        slot[:zaxis]
      )

      rigid_delta = target_rigid * current_rigid.inverse
      ent.transform!(rigid_delta)

      true
    rescue => e
      puts "MHDESIGN Place Rigid Slot Error: #{e.message}"
      false
    end

    def self.swap_read_raw_value(d, ent, attr)
      return nil unless attr

      begin
        d.get_attribute_value(ent, attr["key"].to_s).to_f
      rescue
        attr["raw_value"].to_f
      end
    rescue
      nil
    end

    def self.swap_selected_units
      ents = selected_components

      unless ents.length == 2
        MHDESIGN_OPTIONS_LANG.messagebox("#{MHDESIGN::Language.for_tool('options').t('TEXT_3808C62F0FD6')}")
        return false
      end

      unit_a, unit_b = ents
      d = dc

      unless d
        MHDESIGN_OPTIONS_LANG.messagebox("#{MHDESIGN::Language.for_tool('options').t('TEXT_F409C94BF268')}")
        return false
      end

      attrs_a = swap_dimension_attrs_for(unit_a)
      attrs_b = swap_dimension_attrs_for(unit_b)
      dimensions = [:width, :depth, :height]

      missing = dimensions.select do |dimension|
        attrs_a[dimension].nil? || attrs_b[dimension].nil?
      end

      unless missing.empty?
        names = { width: "العرض", depth: "العمق", height: "الارتفاع" }

        MHDESIGN_OPTIONS_LANG.messagebox(
          "#{MHDESIGN::Language.for_tool('options').t('TEXT_7AD5E7829065')}
" +
          missing.map { |key| names[key] }.join("، ")
        )
        return false
      end

      slot_a = swap_slot_snapshot(unit_a)
      slot_b = swap_slot_snapshot(unit_b)

      unless slot_a && slot_b
        MHDESIGN_OPTIONS_LANG.messagebox("#{MHDESIGN::Language.for_tool('options').t('TEXT_FE66B135D0E2')}")
        return false
      end

      values_a = {}
      values_b = {}

      dimensions.each do |dimension|
        values_a[dimension] =
          swap_read_raw_value(d, unit_a, attrs_a[dimension])

        values_b[dimension] =
          swap_read_raw_value(d, unit_b, attrs_b[dimension])
      end

      if values_a.values.any?(&:nil?) || values_b.values.any?(&:nil?)
        MHDESIGN_OPTIONS_LANG.messagebox("#{MHDESIGN::Language.for_tool('options').t('TEXT_58582FBC5072')}")
        return false
      end

      model = Sketchup.active_model
      @saving_now = true

      # كل خطوات التبديل داخل Operation واحدة:
      # Ctrl+Z يرجع العملية كلها مرة واحدة.
      model.start_operation("MHDESIGN Swap Units", true)

      # 1) تبديل المكان والاتجاه فقط بحركة صلبة.
      unless place_entity_in_rigid_slot(unit_a, slot_b) &&
             place_entity_in_rigid_slot(unit_b, slot_a)
        raise "#{MHDESIGN::Language.for_tool('options').t('TEXT_C68FEF777944')}"
      end

      forced_values_a = {}
      forced_values_b = {}

      # 2) كتابة قيم العرض والعمق والارتفاع كقيم DC فعلية.
      dimensions.each do |dimension|
        attr_a = attrs_a[dimension]
        attr_b = attrs_b[dimension]

        key_a = attr_a["key"].to_s
        key_b = attr_b["key"].to_s

        value_for_a = values_b[dimension]
        value_for_b = values_a[dimension]

        forced_values_a[key_a] = value_for_a
        forced_values_b[key_b] = value_for_b

        apply_dc_attribute(d, unit_a, key_a, value_for_a)
        apply_dc_attribute(d, unit_b, key_b, value_for_b)
      end

      # 3) نفس دورة التحديث التي نجحت في اختبار الوحدة المشوهة:
      # Forced Config Values -> Formulas -> Redraw -> Last Sizes.
      forced_values_a.each do |key, value|
        d.set_forced_config_value(unit_a, key, value)
      end

      forced_values_b.each do |key, value|
        d.set_forced_config_value(unit_b, key, value)
      end

      [unit_a, unit_b].each do |ent|
        d.run_all_formulas(ent)
        d.redraw(ent, false, false)
        d.update_last_sizes(ent)
      end

      # 4) إزالة القيم الإجبارية ثم دورة نهائية لتثبيت النتيجة.
      d.clear_forced_config_values(unit_a)
      d.clear_forced_config_values(unit_b)

      [unit_a, unit_b].each do |ent|
        d.run_all_formulas(ent)
        d.redraw(ent, false, false)
        d.update_last_sizes(ent)
      end

      # لا يتم لمس Transformation بعد آخر Redraw.
      # لا نحدّث نوافذ Dynamic Components الأصلية هنا؛ إعادة الرسم تمت بالفعل،
      # ونافذة MHDESIGN ستحدّث نفسها بالـ timer أسفل الدالة. الاستدعاء القديم
      # كان يعيد تحليل خصائص كل المكونات ويزيد زمن العملية بلا فائدة.

      model.commit_operation

      @saving_now = false
      @last_selection_sig = nil
      model.active_view.invalidate

      UI.start_timer(0.15, false) {
        refresh_dialog(true)
      }

      true
    rescue => e
      @saving_now = false

      begin
        d.clear_forced_config_values(unit_a) if d && unit_a
      rescue
      end

      begin
        d.clear_forced_config_values(unit_b) if d && unit_b
      rescue
      end

      begin
        model.abort_operation
      rescue
      end

      MHDESIGN_OPTIONS_LANG.messagebox("#{MHDESIGN::Language.for_tool('options').t('TEXT_34D5C896FA0A')}
#{e.message}")
      false
    end


    # =========================================================
    # مزامنة شكل خامات شريط الحرف مع خامة الضلفة أو الشاسيه
    # بدون تغيير اسم خامة الشريط أو منطق الـ Dynamic Component.
    # =========================================================

    def self.band_material_name_matches?(material, name)
      return false unless material

      wanted = normalize_ar(name)
      normalize_ar(material.display_name) == wanted ||
        normalize_ar(material.name) == wanted
    rescue
      false
    end

    def self.band_material?(material)
      names = DOOR_BAND_MATERIAL_NAMES + CHASSIS_BAND_MATERIAL_NAMES
      names.any? { |name| band_material_name_matches?(material, name) }
    rescue
      false
    end

    def self.exact_model_material(name)
      wanted = normalize_ar(name)

      Sketchup.active_model.materials.find do |material|
        normalize_ar(material.display_name) == wanted ||
          normalize_ar(material.name) == wanted
      end
    rescue
      nil
    end

    def self.collect_component_materials(entities, result, visited)
      entities.each do |entity|
        if entity.respond_to?(:material)
          material = entity.material
          result << material if material && !result.include?(material)
        end

        case entity
        when Sketchup::Face
          front_material = entity.material
          back_material  = entity.back_material

          result << front_material if front_material && !result.include?(front_material)
          result << back_material if back_material && !result.include?(back_material)

        when Sketchup::ComponentInstance
          definition = entity.definition
          definition_id = definition.object_id
          next if visited[definition_id]

          visited[definition_id] = true
          collect_component_materials(definition.entities, result, visited)

        when Sketchup::Group
          definition_id = entity.entities.object_id
          next if visited[definition_id]

          visited[definition_id] = true
          collect_component_materials(entity.entities, result, visited)
        end
      end
    end

    def self.materials_used_in_component(ent)
      result = []
      visited = {}

      result << ent.material if ent.respond_to?(:material) && ent.material
      collect_component_materials(ent.definition.entities, result, visited)
      result.compact.uniq
    rescue => e
      puts "MHDESIGN Material Scan Error: #{e.message}"
      []
    end

    def self.same_as_door_material_option?(label, value)
      [label, value, value.to_s.sub(/\A=/, "")].any? do |text|
        normalized = normalize_ar(text)

        normalized.include?(normalize_ar("نفس خامة الضلفه")) ||
          normalized.include?(normalize_ar("بنفس خامة الضلفه"))
      end
    rescue
      false
    end

    # قراءة الاختيار الحالي للخاصية بعد الـ redraw، مع احترام الـ Formula.
    def self.current_material_option(ent, wanted_label)
      attr = read_attrs(ent).find do |item|
        normalize_ar(item["label"].to_s) == normalize_ar(wanted_label)
      end
      return nil unless attr

      current_stored = attr["formula_value"].to_s.strip
      current_stored = attr["raw_value"].to_s.strip if current_stored.empty?

      option = (attr["options"] || []).find do |item|
        item["value"].to_s.strip == current_stored
      end

      option ||= (attr["options"] || []).find do |item|
        item["label"].to_s.strip == attr["raw_value"].to_s.strip
      end

      option || {
        "label" => attr["raw_value"].to_s,
        "value" => current_stored
      }
    rescue => e
      puts "MHDESIGN Current Material Option Error: #{e.message}"
      nil
    end

    def self.find_band_source_material(ent, chosen_label, chosen_value, type = :door)
      if type == :chassis && same_as_door_material_option?(chosen_label, chosen_value)
        door_option = current_material_option(ent, "خامة الضلفه")

        if door_option
          found = find_band_source_material(
            ent,
            door_option["label"],
            door_option["value"],
            :door
          )
          return found if found
        end
      end

      used_materials = materials_used_in_component(ent)

      candidates = [
        chosen_label,
        chosen_value,
        chosen_value.to_s.sub(/\A=/, ""),
        chosen_label.to_s.sub(/\A=/, "")
      ].map(&:to_s).map(&:strip).reject(&:empty?).uniq

      candidates.each do |candidate|
        found = used_materials.find do |material|
          !band_material?(material) && band_material_name_matches?(material, candidate)
        end
        return found if found
      end

      candidates.each do |candidate|
        found = exact_model_material(candidate)
        return found if found && !band_material?(found)
      end

      candidates.each do |candidate|
        wanted = normalize_ar(candidate)
        next if wanted.empty?

        found = used_materials.find do |material|
          next false if band_material?(material)

          material_name = normalize_ar(material.display_name)
          material_name.include?(wanted) || wanted.include?(material_name)
        end
        return found if found
      end

      if type == :chassis && same_as_door_material_option?(chosen_label, chosen_value)
        textured = used_materials.find do |material|
          !band_material?(material) && material.texture
        rescue
          false
        end
        return textured if textured
      end

      nil
    rescue => e
      puts "MHDESIGN Band Source Detection Error: #{e.message}"
      nil
    end

    def self.copy_band_material_appearance(source, target)
      return false unless source && target
      return false if source == target

      begin
        target.color = source.color
      rescue => e
        puts "MHDESIGN Band Color Copy Warning: #{e.message}"
      end

      begin
        target.alpha = source.alpha
      rescue => e
        puts "MHDESIGN Band Alpha Copy Warning: #{e.message}"
      end

      if source.texture
        texture_file = source.texture.filename.to_s

        unless texture_file.empty?
          begin
            target.texture = texture_file

            if target.texture
              target.texture.size = [
                source.texture.width,
                source.texture.height
              ]
            end
          rescue => e
            puts "MHDESIGN Band Texture Copy Warning: #{e.message}"
          end
        end
      else
        begin
          target.texture = nil
        rescue
        end
      end

      true
    end

    def self.band_materials_for_component(ent, type)
      names = type == :chassis ? CHASSIS_BAND_MATERIAL_NAMES : DOOR_BAND_MATERIAL_NAMES
      used_materials = materials_used_in_component(ent)
      result = []

      names.each do |name|
        material = used_materials.find do |used_material|
          band_material_name_matches?(used_material, name)
        end

        # نفس منطق المحاكي المستقر: لو لم تظهر الخامة في المسح الداخلي،
        # نصل إليها من خامات الموديل بالاسم الثابت.
        material ||= exact_model_material(name)
        result << material if material
      end

      result.compact.uniq
    rescue => e
      puts "MHDESIGN Band Material Detection Error: #{e.message}"
      []
    end

    def self.sync_band_materials(ent, type)
      return false unless ent && ent.valid?

      option_label = type == :chassis ? "خامة الشاسيه" : "خامة الضلفه"
      option = current_material_option(ent, option_label)
      return false unless option

      source = find_band_source_material(
        ent,
        option["label"],
        option["value"],
        type
      )
      return false unless source

      targets = band_materials_for_component(ent, type)
      return false if targets.empty?

      changed = false
      targets.each do |target|
        changed = true if copy_band_material_appearance(source, target)
      end

      Sketchup.active_model.active_view.invalidate if changed
      changed
    rescue => e
      puts "MHDESIGN Band Sync Error: #{e.message}"
      false
    end

    def self.band_sync_type_for_item(item)
      label = normalize_ar(item["label"].to_s)

      return :chassis if label == normalize_ar("خامة الشاسيه")

      is_door_material =
        label.include?(normalize_ar("خامه")) &&
        label.include?(normalize_ar("ضلف"))

      return :door if is_door_material
      nil
    rescue
      nil
    end

    def self.live_save(json)
      ents = selected_components
      return if ents.empty?

      @saving_now = true
      d = dc
      return unless d

      data = JSON.parse(json)
      model = Sketchup.active_model

      row_width_edit = data.any? do |item|
        item["group"].to_s == "عرض وحدات الصف" && item["skip"] != true
      end

      row_shift_direction = data.find do |item|
        item["group"].to_s == "عرض وحدات الصف" && item["skip"] != true
      end
      row_shift_direction = row_shift_direction ? row_shift_direction["row_shift_direction"].to_s : "left"
      row_shift_direction = "left" unless ["left", "right"].include?(row_shift_direction)

      row_snapshot = row_width_edit ? row_layout_snapshot(ents) : nil

      model.start_operation("MHDESIGN Live Option", true)

      touched = []
      depth_moves = {}
      band_sync_requests = {}

      data.each do |item|
        next if item["skip"] == true
        next if item["value"].to_s == MULTI_MIXED_VALUE

        targets = item["targets"]

        if item["multi_dimension"] == true
          ignore_different = item["ignore_different_values"] != false

          targets =
            if ignore_different
              item["similar_targets"]
            else
              item["all_targets"]
            end

          # لو لا توجد مجموعة متشابهة فعلية، لا نغيّر أي وحدة عند اختيار "نعم".
          next if ignore_different && (!targets.is_a?(Array) || targets.empty?)
        end

        if targets && targets.is_a?(Array) && !targets.empty?
          targets.each do |target|
            ent_index = target["ent_index"].to_i
            ent = ents[ent_index]
            next unless ent && ent.valid?

            key = target["key"].to_s
            units = target["units"].to_s
            value = to_dc_value(item["value"], units)

            if depth_attribute_item?(item)
              entity_key = ent.respond_to?(:persistent_id) ? ent.persistent_id : ent.entityID
              depth_moves[entity_key] ||= depth_move_snapshot(d, ent, key, value)
            end

            apply_dc_attribute(d, ent, key, value)

            sync_type = band_sync_type_for_item(item)
            if sync_type
              entity_key = ent.respond_to?(:persistent_id) ? ent.persistent_id : ent.entityID
              band_sync_requests[entity_key] ||= { "ent" => ent, "types" => [] }
              types = band_sync_requests[entity_key]["types"]
              types << sync_type unless types.include?(sync_type)
            end

            touched << ent unless touched.include?(ent)
          end
        else
          ent = ents.first
          next unless ent && ent.valid?

          key = item["key"].to_s
          value = to_dc_value(item["value"], item["units"])

          if depth_attribute_item?(item)
            entity_key = ent.respond_to?(:persistent_id) ? ent.persistent_id : ent.entityID
            depth_moves[entity_key] ||= depth_move_snapshot(d, ent, key, value)
          end

          apply_dc_attribute(d, ent, key, value)

          sync_type = band_sync_type_for_item(item)
          if sync_type
            entity_key = ent.respond_to?(:persistent_id) ? ent.persistent_id : ent.entityID
            band_sync_requests[entity_key] ||= { "ent" => ent, "types" => [] }
            types = band_sync_requests[entity_key]["types"]
            types << sync_type unless types.include?(sync_type)
          end

          touched << ent unless touched.include?(ent)
        end
      end

      touched.each do |ent|
        begin
          d.redraw(ent)
        rescue
          begin
            d.redraw_with_undo(ent)
          rescue
          end
        end
      end

      # بعد اكتمال الـ redraw نحدّث شكل خامات الشريط المطلوبة فقط.
      band_sync_requests.each_value do |request|
        ent = request["ent"]
        next unless ent && ent.valid?

        request["types"].each do |sync_type|
          sync_band_materials(ent, sync_type)
        end
      end

      # تطبيق الحركة الحسابية الواضحة: الجديد - القديم على محور Y المحلي.
      depth_moves.each_value do |snapshot|
        apply_depth_move(snapshot) if snapshot
      end

      # الإضافة المستقرة:
      # بعد تغيير عرض أي وحدة من قسم "عرض وحدات الصف"،
      # تتحرك الوحدات التالية تلقائياً وتحافظ على المسافات الأصلية.
      restore_row_layout(row_snapshot, row_shift_direction) if row_snapshot

      # إعادة الرسم تمت بالفعل، ونافذة MHDESIGN تحدّث نفسها أسفل الدالة.
      # تحديث نوافذ الـDC الأصلية هنا كان يعيد تحليل كل الخصائص ويبطّئ الحفظ.

      model.commit_operation
      @saving_now = false
      @last_selection_sig = nil

      UI.start_timer(0.15, false) {
        refresh_dialog(true)
      }
    rescue => e
      @saving_now = false

      begin
        model.abort_operation
      rescue
      end

      MHDESIGN_OPTIONS_LANG.messagebox("حصل خطأ:\n#{e.message}")
    end

    def self.selection_signature
      selected_components.map {
        |e| e.respond_to?(:persistent_id) ? e.persistent_id : e.entityID
      }.join("|")
    rescue
      ""
    end

    def self.schedule_refresh(delay = 0.20)
      return unless @dlg
      return if @saving_now

      @refresh_timer = UI.start_timer(delay, false) {
        @refresh_timer = nil

        # تحديث إجباري عند أي تغيير في التحديد.
        # التعديل ده فقط لمنع بقاء بيانات الوحدة السابقة في القائمة،
        # مع الحفاظ على منطق الرفوف وخيار "بنفس خامة الضلفة" كما هو.
        refresh_dialog(true)
      }
    rescue
    end

    def self.refresh_dialog(force = false)
      return unless @dlg
      return if @saving_now

      sig = selection_signature
      return if !force && sig == @last_selection_sig

      @last_selection_sig = sig
      payload = translate_display_payload!(payload_for_current_selection)
      js = "window.setMHDData(#{payload.to_json});"

      begin
        @dlg.execute_script(js)
      rescue
      end
    end

    class SelectionWatcher < Sketchup::SelectionObserver
      def onSelectionBulkChange(selection)
        MHDESIGN::PremiumComponentOptions.schedule_refresh
      end

      def onSelectionCleared(selection)
        MHDESIGN::PremiumComponentOptions.schedule_refresh
      end

      def onSelectionAdded(selection, entity)
        MHDESIGN::PremiumComponentOptions.schedule_refresh
      end

      def onSelectionRemoved(selection, entity)
        MHDESIGN::PremiumComponentOptions.schedule_refresh
      end
    end

    def self.add_observer_once
      return if @observer_added

      @selection_observer = SelectionWatcher.new
      Sketchup.active_model.selection.add_observer(@selection_observer)
      @observer_added = true
    rescue
    end

    def self.open
      add_observer_once

      # Recreate the dialog when opening so the current language and direction
      # are read fresh from manifest/language JSON.
      begin
        if @dlg
          @dlg.close rescue nil
          @dlg = nil
        end
      rescue
        @dlg = nil
      end

      html = <<~HTML
      <!DOCTYPE html>
      <html lang="#{MHDESIGN_OPTIONS_LANG.current}" dir="#{defined?(MHDESIGN::Language) ? MHDESIGN::Language.direction : 'rtl'}">
      <head>
        <meta charset="UTF-8">
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

          ::-webkit-scrollbar-track{
            background:var(--mhd-app);
          }

          ::-webkit-scrollbar-thumb{
            background:var(--mhd-border);
            border-radius:20px;
            border:2px solid var(--mhd-app);
          }

          ::-webkit-scrollbar-thumb:hover{
            background:var(--mhd-hover);
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
          }

          .head-text{
            flex:1;
            overflow:hidden;
          }

          .title{
            font-size:13px;
            font-weight:900;
            color:#fff;
            white-space:nowrap;
            overflow:hidden;
            text-overflow:ellipsis;
          }

          .desc{
            margin-top:5px;
            font-size:10px;
            line-height:1.4;
            color:var(--mhd-muted);
            height:28px;
            overflow:hidden;
          }

          .wrap{
            height:calc(100vh - 74px);
            overflow:auto;
            padding:10px;
            background:var(--mhd-app);
          }

          .status{
            padding:24px 10px;
            text-align:center;
            color:#c7d6df;
            font-size:13px;
          }

          .search{
            width:100%;
            height:30px;
            margin-bottom:10px;
            padding:6px 10px;
            background:var(--mhd-card);
            color:#fff;
            border:none;
            border-radius:8px;
            outline:1px solid var(--mhd-border);
            font-size:12px;
            text-align:right;
          }

          .search:focus{
            outline:2px solid var(--mhd-accent);
          }

          .group{
            background:var(--mhd-card);
            border:1px solid var(--mhd-border);
            border-radius:10px;
            margin-bottom:10px;
            overflow:hidden;
          }

          .group-title{
            padding:7px 10px;
            background:var(--mhd-panel);
            color:var(--mhd-accent);
            font-size:12px;
            font-weight:900;
            border-bottom:1px solid var(--mhd-border);
            cursor:pointer;
            user-select:none;
          }

          .group-title span{
            color:#fff;
            margin-left:5px;
          }

          .group[data-group="عرض وحدات الصف"]{
            border-color:var(--mhd-border);
          }

          .group[data-group="عرض وحدات الصف"] .group-title{
            background:var(--mhd-panel);
          }

          .row-direction-picker{
            display:grid;
            grid-template-columns:1fr 1fr;
            gap:7px;
            margin:2px 0 9px;
            padding-bottom:9px;
            border-bottom:1px solid var(--mhd-border);
          }

          .row-direction-btn{
            height:30px;
            border:1px solid var(--mhd-border);
            border-radius:7px;
            background:var(--mhd-input);
            color:var(--mhd-text);
            font-size:11px;
            font-weight:900;
            cursor:pointer;
          }

          .row-direction-btn:hover{
            background:var(--mhd-hover);
          }

          .row-direction-btn.active{
            background:var(--mhd-accent);
            border-color:var(--mhd-accent);
            color:#fff;
            box-shadow:0 3px 9px rgba(8,201,195,.18);
          }

          .group[data-group="مقاسات الوحدة"]{
            border-color:var(--mhd-border);
          }

          .group[data-group="مقاسات الوحدة"] .group-title{
            background:var(--mhd-panel);
            color:var(--mhd-bright);
          }

          .ignore-different-row{
            display:grid;
            grid-template-columns:105px 1fr;
            gap:8px;
            align-items:center;
            margin-top:8px;
            padding-top:8px;
            border-top:1px solid var(--mhd-border);
          }

          .ignore-different-row label{
            color:var(--mhd-muted);
          }

          .group-body{
            padding:6px 8px 8px;
          }

          .field-row{
            display:grid;
            grid-template-columns:105px 1fr;
            gap:8px;
            align-items:center;
            margin-bottom:6px;
          }

          .field-row:last-child{
            margin-bottom:0;
          }

          label{
            font-size:11px;
            font-weight:800;
            color:var(--mhd-text);
            text-align:right;
            line-height:1.3;
          }

          input,select{
            width:100%;
            height:28px;
            padding:4px 8px;
            border:none;
            border-radius:6px;
            background:var(--mhd-input);
            color:#fff;
            font-size:12px;
            outline:1px solid var(--mhd-border);
            text-align:right;
          }

          input:focus,select:focus{
            outline:2px solid var(--mhd-accent);
            background:var(--mhd-input);
          }

          select{
            cursor:pointer;
            color-scheme:dark;
          }

          select option{
            background:var(--mhd-input);
            color:#ffffff;
          }

          select option:checked,
          select option:hover{
            background:var(--mhd-hover);
            color:#ffffff;
          }

          .swap-units-btn{
            width:100%;
            height:34px;
            margin-bottom:10px;
            border:none;
            border-radius:8px;
            background:var(--mhd-accent);
            color:#fff;
            font-size:12px;
            font-weight:900;
            cursor:pointer;
            box-shadow:0 4px 12px rgba(0,0,0,.24);
          }

          .swap-units-btn:hover{
            background:var(--mhd-bright);
          }

          .swap-units-btn:disabled{
            opacity:.6;
            cursor:default;
          }

          .saving{
            position:fixed;
            bottom:10px;
            left:10px;
            background:var(--mhd-accent);
            color:#fff;
            padding:6px 10px;
            border-radius:20px;
            font-size:11px;
            font-weight:bold;
            display:none;
            box-shadow:0 4px 14px rgba(0,0,0,.35);
          }

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
  body { height: 100vh; display: flex; flex-direction: column; }
  body > .wrap { flex: 1 1 0; height: auto; min-height: 0; }
  .group[data-group="عرض وحدات الصف"] .group-title,
  .group[data-group="مقاسات الوحدة"] .group-title {
    background: var(--mhd-section); color: var(--mhd-bright);
  }
  .saving { background: var(--mhd-primary); color: var(--mhd-ink); }
  .search { text-align: start; }
  .swap-units-btn { height: auto; min-height: 36px; padding: 6px 8px; }
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
        <div class="hero mhd-tool-header mhd-ref-header">
          #{MHDESIGN_ResponsiveHeaderUI::BRAND}
          <div class="head-text">
            <div class="title" id="title">MHDESIGN</div>
            <div class="desc" id="desc"></div>
          </div>
        <!-- Dressing reference header artwork is included in BRAND. --></div>

        <div class="wrap" id="content"></div>
        <div class="saving" id="saving">#{MHDESIGN_OPTIONS_LANG.t("جاري التحديث...")}</div>

        <script>
          document.addEventListener('contextmenu',e=>e.preventDefault());
          document.addEventListener('dragstart',e=>e.preventDefault());
          document.addEventListener('selectstart',e=>e.preventDefault());
          window.oncontextmenu=()=>false;


          const MHD_L10N = #{MHDESIGN_OPTIONS_LANG.payload_json};
          const MHD_TEXTS = MHD_L10N.texts || {};
          const MHD_MAP = MHD_L10N.source_map || {};

          function mhdKey(key, fallback){
            const value = MHD_TEXTS[String(key || "")];
            return value == null || String(value).trim() === ""
              ? String(fallback == null ? key : fallback)
              : String(value);
          }

          function mhdTranslate(value){
            value = String(value ?? "");
            if(MHD_L10N.locale === "ar_EG") return value;
            if(Object.prototype.hasOwnProperty.call(MHD_MAP, value)) return String(MHD_MAP[value]);

            let result = value;

            result = result
              .replace(/\bNo\.\s*/gi, "")
              .replace(/\bNo\s*/gi, "")
              .replace(/\s+/g, " ")
              .trim();

            const norm = result
              .normalize("NFKD")
              .replace(/[\u064B-\u065F\u0670\u0640]/g, "")
              .replace(/[أإآٱ]/g, "ا")
              .replace(/[ة]/g, "ه")
              .replace(/[ى]/g, "ي")
              .replace(/\s+/g, "")
              .toLowerCase();

            const hasHandle = norm.includes("قبض") || norm.includes("مقبض");

            if(hasHandle && (
              norm.includes("بداخل") ||
              norm.includes("داخل") ||
              norm.includes("بدخل")
            )) return mhdKey("DC_DOOR_TYPE_INSET", "قبضة J داخلية");

            if(hasHandle && (
              norm.includes("عادي") ||
              norm.includes("كلاس") ||
              norm.includes("كلاسيك")
            )) return mhdKey("DC_DOOR_TYPE_STANDARD", "مقبض عادي أو كلاسيك");

            if(hasHandle && (
              norm.includes("اخر") ||
              norm.includes("خارج") ||
              norm.includes("الحافه") ||
              norm.includes("حافه")
            )) return mhdKey("DC_DOOR_TYPE_OUTER", "قبضة J خارجية");

            return result;
          }

          document.documentElement.lang = MHD_L10N.locale === "en" ? "en" : "ar";
          document.documentElement.dir = MHD_L10N.direction || (MHD_L10N.locale === "en" ? "ltr" : "rtl");

          let attrs = [];
          let saveTimer = null;
          let currentPayloadOk = false;
          let ignoreDifferentValues = true;
          let canSwapUnits = false;
          let rowShiftDirection = "left";

          function esc(v){
            return String(v ?? "")
              .replace(/&/g,"&amp;")
              .replace(/</g,"&lt;")
              .replace(/>/g,"&gt;")
              .replace(/"/g,"&quot;");
          }

          window.setMHDData = function(payload){
            currentPayloadOk = payload.ok === true;
            attrs = payload.attrs || [];
            canSwapUnits = payload.can_swap_units === true;

            document.getElementById("title").innerText = mhdTranslate(payload.title || "MHDESIGN");
            document.getElementById("desc").innerText = mhdTranslate(payload.desc || "");

            render(payload.message || "");
          }

          function render(message){
            const content = document.getElementById("content");
            content.innerHTML = "";

            if(!currentPayloadOk || !attrs.length){
              content.innerHTML = `<div class="status">${esc(mhdTranslate(message || "#{MHDESIGN::Language.for_tool('options').js_fragment('TEXT_2836399D764C')}"))}</div>`;
              return;
            }

            content.innerHTML = `
              ${canSwapUnits ? `<button class="swap-units-btn" id="swapUnitsBtn" onclick="swapUnits()">${esc(mhdTranslate("تبديل الوحدتين"))}</button>` : ``}
              <input class="search" id="searchBox" placeholder="${esc(mhdTranslate("بحث عن خاصية..."))}" oninput="renderFiltered()">
              <div id="groupsBox"></div>
            `;

            renderFiltered();
          }

          function renderFiltered(){
            const box = document.getElementById("groupsBox");
            const searchBox = document.getElementById("searchBox");
            const search = (searchBox ? searchBox.value : "").trim().toLowerCase();

            box.innerHTML = "";

            const filtered = attrs.filter(a=>{
              if(!search) return true;

              return String(a.display_label || a.label).toLowerCase().includes(search) ||
                     String(a.display_group || a.group).toLowerCase().includes(search);
            });

            const groups = {};

            filtered.forEach(a=>{
              const groupKey = a.group; if(!groups[groupKey]) groups[groupKey] = [];
              groups[groupKey].push(a);
            });

            Object.keys(groups).forEach(groupName=>{
              const group = document.createElement("div");
              group.className = "group";
              group.setAttribute("data-group", groupName);

              let html = `
                <div class="group-title" onclick="toggleGroup(this)">
                  <span>▼</span>${esc(mhdTranslate(groupName))}
                </div>
                <div class="group-body">
              `;

              if(groupName === "عرض وحدات الصف"){
                html += `
                  <div class="row-direction-picker">
                    <button type="button" class="row-direction-btn ${rowShiftDirection === "left" ? "active" : ""}" onclick="setRowShiftDirection('left')">${esc(mhdTranslate("تثبيت الشمال"))}</button>
                    <button type="button" class="row-direction-btn ${rowShiftDirection === "right" ? "active" : ""}" onclick="setRowShiftDirection('right')">${esc(mhdTranslate("تثبيت اليمين"))}</button>
                  </div>
                `;
              }

              groups[groupName].forEach(a=>{
                const index = attrs.indexOf(a);
                let control = "";

                if(String(a.access).toUpperCase() === "LIST"){
                  control = `<select data-index="${index}" onchange="saveNow(this)">`;

                  if(a.mixed){
                    control += `<option value="__MHD_MIXED__" selected disabled>${esc(a.display_placeholder || mhdTranslate(a.placeholder || "قيم مختلفة"))}</option>`;
                  }

                  // الإصلاح:
                  // الأولوية في تحديد الاختيار الحالي تكون لعمود Value فقط.
                  // ده يمنع تعارض عدد الأرفف، مثل:
                  // الظاهر 1 = القيمة 2
                  // الظاهر 2 = القيمة 3
                  // لو الخاصية مربوطة بـ Formula مثل "بنفس خامة الضلفة"،
                  // نعرض اختيار الـ Formula نفسه بدل القيمة الناتجة منها مثل "كونتر أبيض".
                  const currentStoredValue =
                    String(a.formula_value || "").trim() ||
                    String(a.raw_value || "").trim();

                  const hasExactValueMatch = a.options.some(opt =>
                    String(opt.value).trim() === currentStoredValue
                  );

                  a.options.forEach(opt=>{
                    let selected = "";

                    if(!a.mixed){
                      if(hasExactValueMatch){
                        selected =
                          String(opt.value).trim() === currentStoredValue
                            ? "selected"
                            : "";
                      }else{
                        selected =
                          String(opt.label).trim() === String(a.raw_value).trim()
                            ? "selected"
                            : "";
                      }
                    }

                    const visibleOptionText =
                      String(opt.display_label || "").trim() ||
                      mhdTranslate(opt.label || opt.value);

                    control += `<option value="${esc(opt.value)}" ${selected}>${esc(visibleOptionText)}</option>`;
                  });

                  control += `</select>`;
                }else{
                  const ph = a.placeholder ? ` placeholder="${esc(a.placeholder)}"` : "";

                  control = `<input data-index="${index}" value="${esc(a.display_value)}"${ph} oninput="saveDebounced(this)" onblur="saveInputNow(this)" onkeydown="if(event.key === 'Enter'){event.preventDefault(); this.blur();}">`;
                }

                html += `
                  <div class="field-row">
                    <label>${esc(a.display_label || mhdTranslate(a.label))}</label>
                    ${control}
                  </div>
                `;
              });

              const hasMultiDimensions = groups[groupName].some(a=>a.multi_dimension === true);

              if(groupName === "مقاسات الوحدة" && hasMultiDimensions){
                html += `
                  <div class="ignore-different-row">
                    <label>${esc(mhdTranslate("تجاهل القيم المختلفة"))}</label>
                    <select onchange="setIgnoreDifferentValues(this)">
                      <option value="yes" ${ignoreDifferentValues ? "selected" : ""}>${esc(mhdTranslate("نعم"))}</option>
                      <option value="no" ${ignoreDifferentValues ? "" : "selected"}>${esc(mhdTranslate("لا"))}</option>
                    </select>
                  </div>
                `;
              }

              html += `</div>`;
              group.innerHTML = html;
              box.appendChild(group);
            });
          }

          function toggleGroup(el){
            const body = el.parentElement.querySelector(".group-body");
            const icon = el.querySelector("span");

            if(body.style.display === "none"){
              body.style.display = "block";
              icon.innerText = "▼";
            }else{
              body.style.display = "none";
              icon.innerText = "▶";
            }
          }

          function setIgnoreDifferentValues(el){
            ignoreDifferentValues = String(el.value) === "yes";
          }

          function setRowShiftDirection(direction){
            rowShiftDirection = direction === "right" ? "right" : "left";
            renderFiltered();
          }

          function collectOne(el){
            if(!el) return null;

            const i = el.getAttribute("data-index");

            if(attrs[i]){
              attrs[i].value = el.value;
              attrs[i].ignore_different_values = ignoreDifferentValues;
              attrs[i].row_shift_direction = rowShiftDirection;
              attrs[i].skip =
                (el.value === "__MHD_MIXED__") ||
                (attrs[i].mixed && String(el.value).trim() === "");

              return attrs[i];
            }

            return null;
          }

          function showSaving(){
            const s = document.getElementById("saving");
            s.style.display = "block";

            clearTimeout(window._hideSaving);

            window._hideSaving = setTimeout(()=>{
              s.style.display = "none";
            }, 900);
          }

          function saveNow(el){
            const item = collectOne(el);
            if(!item || item.skip) return;

            showSaving();
            sketchup.live_save(JSON.stringify([item]));
          }

          function swapUnits(){
            const btn = document.getElementById("swapUnitsBtn");
            if(btn){
              btn.disabled = true;
              btn.innerText = mhdTranslate("جاري التبديل...");
            }

            showSaving();
            sketchup.swap_units();
          }

          function saveDebounced(el){
            clearTimeout(saveTimer);
            // ننتظر ثانيتين بعد آخر رقم حتى يقدر المستخدم يكتب المقاس براحة.
            saveTimer = setTimeout(()=>{
              saveTimer = null;
              saveNow(el);
            }, 2000);
          }

          function saveInputNow(el){
            if(saveTimer === null) return;
            clearTimeout(saveTimer);
            saveTimer = null;
            saveNow(el);
          }
        </script>
      </body>
      </html>
      HTML

      if @dlg
        begin
          @dlg.close
        rescue
        end
      end

      @dlg = UI::HtmlDialog.new(
        dialog_title: "MHDESIGN Options",
        preferences_key: "mhdesign_premium_component_options_live",
        scrollable: false,
        resizable: true,
        width: 330,
        height: 640,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      @dlg.set_html(html)

      @dlg.add_action_callback("live_save") do |_d, json|
        # نرجع التحكم إلى HtmlDialog فوراً، ثم ننفذ إعادة بناء الـDC
        # خارج نداء JavaScript حتى لا تظهر رسالة العملية تستغرق وقتاً طويلاً.
        payload = json.to_s.dup
        UI.start_timer(0.01, false) {
          live_save(payload)
        }
      end

      @dlg.add_action_callback("swap_units") do |_d|
        UI.start_timer(0.01, false) {
          swap_selected_units
        }
      end

      @dlg.show

      UI.start_timer(0.25, false) {
        refresh_dialog(true)
      }
    rescue => e
      MHDESIGN_OPTIONS_LANG.messagebox("حصل خطأ:\n#{e.message}")
    end

    unless file_loaded?(__FILE__)
      cmd = UI::Command.new("MHDESIGN Options") {
        self.open
      }

      cmd.tooltip = "MHDESIGN Component Options"
      cmd.status_bar_text = MHDESIGN_OPTIONS_LANG.t("لوحة MHDESIGN لتعديل Dynamic Component Options مباشرة")

      UI.menu("Plugins").add_item(MHDESIGN_OPTIONS_LANG.t("MHDESIGN - Live Component Options")) {
        self.open
      }

      file_loaded(__FILE__)
    end

  end
end
