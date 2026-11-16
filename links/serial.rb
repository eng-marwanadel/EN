# encoding: UTF-8
require 'sketchup.rb'
require File.join(__dir__, 'MHDESIGN_Language') unless defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:for_tool)


# ==================== MHDESIGN SERIAL LANGUAGE BRIDGE ====================
module MHDESIGN_SERIAL_LANG
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
    payload = MHDESIGN::Language.for_tool('serial').ui_payload
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
    MHDESIGN_SERIAL_LANG.messagebox(t(message), *args)
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
# ========================================================================

module MHDESIGN
  module SafeCODSequencerForDC

    # أي أقواس في الاسم
    ANY_PARENS_REGEX = /\([^)]*\)/
    # إزالة الهاشتاج آخر الاسم فقط: " #1" أو "#1"
    HASH_SUFFIX_REGEX = /\s*#\d+\s*\z/

    def self.activate_tool
      Sketchup.active_model.select_tool(Tool.new)
    end

    # ==========================================================
    # ✅ Busy Popup (Spinner + delayed execution)
    # ==========================================================
    class BusyPopup
      WIDTH  = 300
      HEIGHT = 140

      def initialize
        @dlg = UI::HtmlDialog.new(
          dialog_title: MHDESIGN_SERIAL_LANG.t("MHDESIGN"),
          preferences_key: "mhdesign_busy_popup_serial",
          style: UI::HtmlDialog::STYLE_DIALOG,
          width: WIDTH,
          height: HEIGHT,
          resizable: false,
          scrollable: false
        )

        html = <<~HTML
          <!doctype html>
          <html lang="#{MHDESIGN_SERIAL_LANG.current == 'en' ? 'en' : 'ar'}" dir="#{MHDESIGN_SERIAL_LANG.current == 'en' ? 'ltr' : 'rtl'}">
          <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge" />
            <style>
              html, body {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 100%;
                overflow: hidden;
                background: #102D35;
                font-family: Arial, sans-serif;
              }

              body {
                display: flex;
                align-items: center;
                justify-content: center;
              }

              .wrap {
                width: 100%;
                height: 100%;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-direction: column;
                text-align: center;
                box-sizing: border-box;
                padding: 14px;
                background: #102D35;
              }

              .spinner {
                width: 34px;
                height: 34px;
                border: 4px solid #43656C;
                border-top: 4px solid #D9FA57;
                border-radius: 50%;
                animation: spin 0.9s linear infinite;
                flex: 0 0 auto;
              }

              .msg {
                margin-top: 12px;
                font-size: 16px;
                color: #E6F7F5;
                line-height: 1.5;
                font-weight: bold;
              }

              .sub {
                margin-top: 6px;
                font-size: 12px;
                color: #ABC8C8;
                line-height: 1.4;
              }

              @keyframes spin {
                0%   { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
              }
            
          html{color-scheme:dark}
          :focus-visible{outline:2px solid #D9FA57;outline-offset:2px}
          input[type=checkbox],input[type=radio],input[type=range]{accent-color:#D9FA57}
          ::selection{background:#D9FA57;color:#102D35}
</style>
          </head>
          <body>
            <div class="wrap">
              <div class="spinner"></div>
              <div class="msg">#{MHDESIGN_SERIAL_LANG.t("جاري التسمية...")}</div>
              <div class="sub">#{MHDESIGN_SERIAL_LANG.t("فضلاً انتظر")}</div>
            </div>
          </body>
          </html>
        HTML

        @dlg.set_html(html)
      end

      def show
        begin
          @dlg.show
        rescue
        end

        begin
          @dlg.bring_to_front
        rescue
        end

        begin
          @dlg.center
        rescue
        end

        begin
          Sketchup.active_model.active_view.invalidate
        rescue
        end

        UI.start_timer(0.01, false) do
          begin
            @dlg.bring_to_front
            Sketchup.active_model.active_view.invalidate
          rescue
          end
        end
      rescue
      end

      def close
        @dlg.close
      rescue
      end
    end

    class Tool
      def initialize
        @ip = Sketchup::InputPoint.new
        Sketchup.status_text = MHDESIGN::Language.for_tool('serial').translate_source(MHDESIGN_SERIAL_LANG.t("لو محدد كذا وحدة: شغّل الأداة للتسلسل. لو وحدة واحدة: كليك عليها. (ESC للخروج)"))
      end

      # ✅ ESC للخروج من الأداة
      def onKeyDown(key, repeat, flags, view)
        if key == 27 # ESC
          Sketchup.active_model.select_tool(nil)
          Sketchup.status_text = MHDESIGN::Language.for_tool('serial').translate_source("")
        end
      end

      def onCancel(reason, view)
        Sketchup.status_text = MHDESIGN::Language.for_tool('serial').translate_source("")
      end

      def deactivate(view)
        Sketchup.status_text = MHDESIGN::Language.for_tool('serial').translate_source("")
      end

      def onMouseMove(flags, x, y, view)
        @ip.pick(view, x, y)
        view.invalidate
      end

      def draw(view)
        @ip.draw(view) if @ip.valid?
      end

      def activate
        model = Sketchup.active_model
        sel = model.selection.to_a.select { |e|
          e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
        }

        if sel.length >= 2
          run_on_entities(sel, ask_sequence: true)
          model.select_tool(nil)
        else
          Sketchup.status_text = MHDESIGN::Language.for_tool('serial').translate_source(MHDESIGN_SERIAL_LANG.t("كليك على وحدة واحدة لتغيير الكود. أو حدّد كذا وحدة قبل تشغيل الأداة للتسلسل. (ESC للخروج)"))
        end
      end

      def onLButtonDown(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick(x, y)
        picked = ph.best_picked
        return unless picked

        if picked.is_a?(Sketchup::ComponentInstance) || picked.is_a?(Sketchup::Group)
          run_on_entities([picked], ask_sequence: false)
        else
          UI.beep
          Sketchup.status_text = MHDESIGN::Language.for_tool('serial').translate_source(MHDESIGN_SERIAL_LANG.t("لازم تختار Component أو Group."))
        end
      end

      private

      def run_on_entities(entities, ask_sequence:)
        model = Sketchup.active_model

        # ✅ الترتيب (شمال -> يمين): X تصاعدي
        sorted = entities.sort_by { |e|
          bb = e.bounds
          [bb.min.x.to_f, bb.min.y.to_f, bb.min.z.to_f]
        }

        if ask_sequence
          input = UI.inputbox(
            [MHDESIGN_SERIAL_LANG.t("اكتب بداية التسلسل (مثال: 01 أو س01 أو ع 1):")],
            ["01"],
            MHDESIGN_SERIAL_LANG.t("Sequence codes for selected units")
          )
          return unless input

          seed = input[0].to_s
          prefix, start_num, pad = parse_seed(seed)

          busy = BusyPopup.new
          busy.show

          begin
            Sketchup.active_model.active_view.invalidate
          rescue
          end

          UI.start_timer(0, false) do
            UI.start_timer(0.08, false) do
              begin
                model.start_operation(MHDESIGN_SERIAL_LANG.t("Sequence Code for Selection"), true)

                sorted.each_with_index do |ent, i|
                  code = build_code(prefix, start_num + i, pad)
                  process_one(ent, code, make_unique: true)
                  process_children(ent, code)
                end

                model.commit_operation
                busy.close
                MHDESIGN_SERIAL_LANG.messagebox("#{MHDESIGN::Language.for_tool('serial').t('TEXT_EB7921DC1958')}")

              rescue => e
                model.abort_operation rescue nil
                busy.close rescue nil
                MHDESIGN_SERIAL_LANG.messagebox("#{MHDESIGN::Language.for_tool('serial').t('TEXT_E76C0C70BEBF')}#{e.message}")
              end
            end
          end

        else
          input = UI.inputbox(
            [MHDESIGN_SERIAL_LANG.t("اكتب الكود الجديد:")],
            ["01"],
            MHDESIGN_SERIAL_LANG.t("Replace Code")
          )
          return unless input

          code = input[0].to_s.strip
          if code.empty?
            MHDESIGN_SERIAL_LANG.messagebox("#{MHDESIGN::Language.for_tool('serial').t('TEXT_A19697D3EA69')}")
            return
          end

          busy = BusyPopup.new
          busy.show

          begin
            Sketchup.active_model.active_view.invalidate
          rescue
          end

          UI.start_timer(0, false) do
            UI.start_timer(0.08, false) do
              begin
                model.start_operation(MHDESIGN_SERIAL_LANG.t("Replace Code One Unit"), true)

                ent = sorted.first
                process_one(ent, code, make_unique: true)
                process_children(ent, code)

                model.commit_operation
                busy.close
                MHDESIGN_SERIAL_LANG.messagebox("#{MHDESIGN::Language.for_tool('serial').t('TEXT_EB7921DC1958')}")

              rescue => e
                model.abort_operation rescue nil
                busy.close rescue nil
                MHDESIGN_SERIAL_LANG.messagebox("#{MHDESIGN::Language.for_tool('serial').t('TEXT_E76C0C70BEBF')}#{e.message}")
              end
            end
          end
        end
      end

      # ==============================
      # Sequencing helpers
      # ==============================
      def parse_seed(seed)
        s = seed.to_s
        if s =~ /(.*?)(\d+)\s*\z/
          prefix = $1
          num_str = $2
          start_num = num_str.to_i
          pad = (num_str.length > 1 && num_str[0] == '0') ? num_str.length : 0
          [prefix, start_num, pad]
        else
          [s, 1, 0]
        end
      end

      def build_code(prefix, num, pad)
        if pad && pad > 0
          "#{prefix}#{num.to_s.rjust(pad, '0')}"
        else
          "#{prefix}#{num}"
        end
      end

      # ==============================
      # Processing unit + children
      # ==============================
      def process_children(root, code)
        inner = []
        collect_instances_recursive(root, inner)
        inner.each do |inst|
          process_one(inst, code, make_unique: true)
        end
      end

      def process_one(entity, code, make_unique:)
        if entity.is_a?(Sketchup::ComponentInstance)
          begin
            entity.make_unique if make_unique
          rescue
          end

          defn = entity.definition

          # (A) Definition name
          oldn = defn.name.to_s
          newn = replace_parens_and_strip_hash(oldn, code)
          defn.name = newn if newn != oldn

          # (B) DC safe attributes (Definition + Instance)
          # هنا نبدّل اللي بين القوسين فقط بدون إزالة الهاشتاج من الـ attributes
          update_dc_name_attributes(defn, code)
          update_dc_name_attributes(entity, code)

          # (C) redraw
          safe_dc_redraw(entity)

        elsif entity.is_a?(Sketchup::Group)
          oldg = entity.name.to_s
          newg = replace_parens_and_strip_hash(oldg, code)
          entity.name = newg if newg != oldg

          # في الجروب برضه: تعديل القوسين فقط داخل attributes بدون شيل الهاشتاج
          update_dc_name_attributes(entity, code)
        end
      end

      # ==============================
      # للـ Definition / Group name:
      # - يشيل #N في آخر الاسم
      # - يبدل آخر (...) بأي مكان في النص إلى (code)
      # ==============================
      def replace_parens_and_strip_hash(str, code)
        s = str.to_s

        # 1) شيل الهاشتاج آخر الاسم فقط
        s = s.gsub(HASH_SUFFIX_REGEX, '').strip

        # 2) لو مفيش أقواس: مفيش تغيير إضافي
        return s unless s =~ ANY_PARENS_REGEX

        # 3) بدّل آخر occurrence من (...) في أي مكان بالنص
        s = s.sub(/\([^)]*\)(?!.*\([^)]*\))/, "(#{code})").strip

        s
      end

      # ==============================
      # للـ Attributes فقط:
      # - يبدل آخر (...) إلى (code)
      # - بدون إزالة أي هاشتاج
      # ==============================
      def replace_parens_only(str, code)
        s = str.to_s

        # لو مفيش أقواس: مفيش تغيير
        return s unless s =~ ANY_PARENS_REGEX

        # بدّل آخر occurrence من (...) فقط
        s = s.sub(/\([^)]*\)(?!.*\([^)]*\))/, "(#{code})").strip

        s
      end

      # ==============================
      # DC safe attribute update
      # - يبدل القوسين فقط
      # - لا يشيل الهاشتاج من الـ attributes
      # ==============================
      def update_dc_name_attributes(owner, code)
        return unless owner.respond_to?(:attribute_dictionary)

        dict = owner.attribute_dictionary("dynamic_attributes", false)
        return unless dict

        ["_name", "name", "NAME"].each do |key|
          val = dict[key]
          next unless val.is_a?(String)

          newv = replace_parens_only(val, code)
          next if newv == val

          dict[key] = newv
        end
      end

      def safe_dc_redraw(inst)
        begin
          if defined?($dc_observers) && $dc_observers.respond_to?(:get_latest_class)
            dc = $dc_observers.get_latest_class
            if dc && dc.respond_to?(:redraw_with_undo)
              dc.redraw_with_undo(inst)
              return
            end
          end
        rescue
        end

        begin
          Sketchup.active_model.active_view.invalidate
        rescue
        end
      end

      # ==============================
      # Recursion
      # ==============================
      def collect_instances_recursive(root, out_array)
        ents = inner_entities_of(root)
        return unless ents

        ents.each do |e|
          if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
            out_array << e
            collect_instances_recursive(e, out_array)
          end
        end
      end

      def inner_entities_of(obj)
        if obj.is_a?(Sketchup::ComponentInstance)
          obj.definition.entities
        elsif obj.is_a?(Sketchup::Group)
          obj.entities
        else
          nil
        end
      end
    end

  end
end