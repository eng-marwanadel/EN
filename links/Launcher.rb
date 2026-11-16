# encoding: UTF-8
require 'json'
require 'sketchup'
require 'fileutils'
require 'net/http'
require 'uri'
require 'digest'

module MHDESIGN
  module PricingLauncher
    extend self

    PLUGIN_ID     = 'mhdesign_pricing_launcher'.freeze
    PLUGIN_NAME   = 'MHDESIGN Pricing Launcher'.freeze

    DATABASE_URL  = 'https://mhdesign-eg.com/SKETCHUP/mh-pricing/mh_pricing_admin_data.json'.freeze
    MATCHING_URL  = 'https://mhdesign-eg.com/SKETCHUP/mh-pricing/mh_matching_file.json'.freeze
    UPDATE_STATUS_URL = 'https://mhdesign-eg.com/wp-json/mhdesign-updater/v1/status'.freeze

    FILE_NAME        = 'mh_pricing_admin_data.json'.freeze
    MATCHING_FILE    = 'mh_matching_file.json'.freeze
    PASSWORD_FILE    = 'pricing_launcher_password.json'.freeze
    UPDATES_FILE     = 'pricing_launcher_updates.json'.freeze
    MASTER_KEY       = 'MHDESIGN2026'.freeze

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

    DB_PATH        = File.join(DATA_DIR, FILE_NAME)
    MATCHING_PATH  = File.join(DATA_DIR, MATCHING_FILE)
    PASSWORD_PATH  = File.join(DATA_DIR, PASSWORD_FILE)
    UPDATES_PATH   = File.join(DATA_DIR, UPDATES_FILE)

    @dialog = nil

    def ensure_data_dir!
      FileUtils.mkdir_p(DATA_DIR) unless Dir.exist?(DATA_DIR)
      true
    rescue StandardError
      false
    end

    def read_json_file(path, fallback = {})
      return fallback unless File.exist?(path)
      JSON.parse(File.read(path, encoding: 'UTF-8'))
    rescue StandardError
      fallback
    end

    def write_json_file(path, payload)
      ensure_data_dir!
      File.write(path, JSON.pretty_generate(payload), mode: 'w:UTF-8')
      true
    rescue StandardError
      false
    end

    def valid_json_file?(path)
      return false unless File.exist?(path) && File.file?(path) && File.size(path).to_i > 2
      JSON.parse(File.read(path, encoding: 'UTF-8'))
      true
    rescue StandardError
      false
    end

    def database_present?
      valid_json_file?(DB_PATH)
    end

    def matching_present?
      valid_json_file?(MATCHING_PATH)
    end

    def http_get_body(url, timeout_open = 10, timeout_read = 15)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = timeout_open
      http.read_timeout = timeout_read

      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = "SketchUp/#{Sketchup.version} Ruby/#{RUBY_VERSION} #{PLUGIN_NAME}"
      request['Cache-Control'] = 'no-cache'

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        return [false, nil, "HTTP #{response.code}"]
      end

      [true, response.body.to_s, nil]
    rescue StandardError => e
      [false, nil, e.message]
    end

    def download_json_to_path(url, path, label)
      ensure_data_dir!
      ok, body, error = http_get_body(url)
      unless ok
        UI.messagebox("تعذر تحميل #{label}.\n#{error}")
        return false
      end

      begin
        JSON.parse(body)
      rescue StandardError => e
        UI.messagebox("تم تحميل رد غير صالح لملف #{label}.\n#{e.message}")
        return false
      end

      tmp = "#{path}.tmp"
      File.write(tmp, body, mode: 'w:UTF-8')
      FileUtils.mv(tmp, path)
      true
    rescue StandardError => e
      UI.messagebox("تعذر حفظ #{label}:\n#{e.message}")
      false
    ensure
      begin
        File.delete(tmp) if defined?(tmp) && tmp && File.exist?(tmp)
      rescue StandardError
      end
    end

    def download_database_if_missing
      return true if database_present?
      download_json_to_path(DATABASE_URL, DB_PATH, 'قاعدة بيانات التسعير')
    end

    def update_status
      ok, body, _error = http_get_body(UPDATE_STATUS_URL, 5, 8)
      return {} unless ok
      parsed = JSON.parse(body)
      parsed.is_a?(Hash) ? parsed : {}
    rescue StandardError
      {}
    end

    def updates_payload
      payload = read_json_file(UPDATES_PATH, {})
      payload.is_a?(Hash) ? payload : {}
    end

    def save_updates_payload(payload)
      write_json_file(UPDATES_PATH, payload.is_a?(Hash) ? payload : {})
    rescue StandardError
      false
    end

    def update_targets_include?(status, target)
      Array(status['targets']).map(&:to_s).include?(target.to_s)
    rescue StandardError
      false
    end

    def matching_update_required?(status)
      return false unless status.is_a?(Hash)
      return false unless status['has_update'] == true || status['has_update'].to_s == 'true' || status['has_update'].to_s == '1'
      return false unless update_targets_include?(status, 'matching')

      update_id = status['update_id'].to_s.strip
      return true if update_id.empty?

      applied = updates_payload['matching_update_id'].to_s.strip
      applied != update_id
    rescue StandardError
      false
    end

    def mark_matching_update_done(status)
      update_id = status.is_a?(Hash) ? status['update_id'].to_s.strip : ''
      return true if update_id.empty?

      payload = updates_payload
      payload['matching_update_id'] = update_id
      payload['matching_updated_at'] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      save_updates_payload(payload)
    rescue StandardError
      false
    end

    def download_matching_file(force = false, silent = false)
      return true if !force && matching_present?
      ok = download_json_to_path(MATCHING_URL, MATCHING_PATH, 'ملف المطابقة')
      if !ok && matching_present?
        return true
      end
      ok
    rescue StandardError => e
      UI.messagebox("تعذر تجهيز ملف المطابقة:\n#{e.message}") unless silent
      matching_present?
    end

    def download_matching_if_needed
      status = update_status
      force = matching_update_required?(status)

      # لو الملف غير موجود: لازم ينزل حتى لو مفيش تحديث معلن.
      # لو WordPress targets فيها matching ورقم التحديث جديد: ينزل حتى لو موجود.
      ok = download_matching_file(force || !matching_present?, false)
      mark_matching_update_done(status) if ok && force
      ok
    end

    def ensure_runtime_files!
      return false unless download_database_if_missing
      return false unless download_matching_if_needed
      true
    end

    def password_payload
      payload = read_json_file(PASSWORD_PATH, {})
      payload.is_a?(Hash) ? payload : {}
    end

    def password_set?
      digest = password_payload['password_sha256'].to_s.strip
      !digest.empty?
    rescue StandardError
      false
    end

    def password_digest(value)
      Digest::SHA256.hexdigest(value.to_s)
    rescue StandardError
      ''
    end

    def actual_password_match?(password)
      return false unless password_set?
      password_digest(password) == password_payload['password_sha256'].to_s
    rescue StandardError
      false
    end

    def master_key_match?(password)
      password.to_s == MASTER_KEY
    rescue StandardError
      false
    end

    def can_change_password_with_old?(old_password)
      return true unless password_set?
      actual_password_match?(old_password) || master_key_match?(old_password)
    rescue StandardError
      false
    end

    def save_password(new_password)
      pwd = new_password.to_s
      return [false, 'كلمة المرور الجديدة لا تقل عن 4 أحرف.'] if pwd.strip.length < 4

      ok = write_json_file(PASSWORD_PATH, {
        'password_sha256' => password_digest(pwd),
        'updated_at' => Time.now.strftime('%Y-%m-%d %H:%M:%S')
      })

      ok ? [true, 'تم حفظ كلمة المرور الجديدة بنجاح.'] : [false, 'تعذر حفظ كلمة المرور.']
    rescue StandardError => e
      [false, "تعذر حفظ كلمة المرور.\n#{e.message}"]
    end

    def close_selector
      return unless @dialog
      @dialog.close
      @dialog = nil
    rescue StandardError
      @dialog = nil
    end

    def push_password_state(dialog = @dialog)
      return unless dialog
      dialog.execute_script("window.MH && window.MH.setPasswordState(#{password_set? ? 'true' : 'false'});")
    rescue StandardError
      nil
    end

    def open_selector
      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      @dialog = UI::HtmlDialog.new(
        dialog_title: PLUGIN_NAME,
        preferences_key: PLUGIN_ID,
        scrollable: true,
        resizable: false,
        width: 350,
        height: 700,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      attach_callbacks(@dialog)
      @dialog.set_html(build_html)
      @dialog.show
    end

    def attach_callbacks(dialog)
      dialog.add_action_callback('mh_ready') do |_ctx, _payload|
        push_password_state(dialog)
      end

      dialog.add_action_callback('mh_open_pricing') do |_ctx, _payload|
        next unless ensure_runtime_files!

        unless defined?(MHDESIGN::PricingDesignerBoardV2) && MHDESIGN::PricingDesignerBoardV2.respond_to?(:open_dialog)
          UI.messagebox('ملف لوحة التسعير غير محمّل من كاش المكتبة.')
          next
        end

        close_selector
        MHDESIGN::PricingDesignerBoardV2.open_dialog
      end

      dialog.add_action_callback('mh_open_admin') do |_ctx, payload|
        password = payload.to_s

        unless password_set?
          dialog.execute_script("window.MH && window.MH.setAdminError('لا توجد كلمة مرور حالياً. استخدم زر تعيين / تغيير كلمة المرور أولاً.');")
          next
        end

        unless actual_password_match?(password)
          dialog.execute_script("window.MH && window.MH.setAdminError('كلمة المرور غير صحيحة.');")
          next
        end

        next unless ensure_runtime_files!

        unless defined?(MHDESIGN::PricingAdmin) && MHDESIGN::PricingAdmin.respond_to?(:open_dialog)
          UI.messagebox('ملف لوحة التحكم غير محمّل من كاش المكتبة.')
          next
        end

        close_selector
        MHDESIGN::PricingAdmin.open_dialog
      end

      dialog.add_action_callback('mh_save_password') do |_ctx, payload|
        begin
          parsed = JSON.parse(payload.to_s)
        rescue StandardError
          parsed = {}
        end

        old_password = parsed['old_password'].to_s
        new_password = parsed['new_password'].to_s
        confirm_password = parsed['confirm_password'].to_s

        if new_password.strip.empty?
          dialog.execute_script("window.MH && window.MH.setPasswordError('اكتب كلمة المرور الجديدة.');")
          next
        end

        if new_password != confirm_password
          dialog.execute_script("window.MH && window.MH.setPasswordError('تأكيد كلمة المرور غير مطابق.');")
          next
        end

        unless can_change_password_with_old?(old_password)
          dialog.execute_script("window.MH && window.MH.setPasswordError('كلمة المرور القديمة غير صحيحة. يمكنك أيضًا استخدام المفتاح الرئيسي للطوارئ.');")
          next
        end

        ok, msg = save_password(new_password)
        if ok
          dialog.execute_script("window.MH && window.MH.setPasswordSuccess(#{msg.to_json});")
          push_password_state(dialog)
        else
          dialog.execute_script("window.MH && window.MH.setPasswordError(#{msg.to_json});")
        end
      end
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
          * { box-sizing: border-box; }
          body { margin: 0; font-family: Tahoma, Arial, sans-serif; background: linear-gradient(160deg, #eef2ff 0%, #f8fafc 55%, #eef2f7 100%); color: #111827; padding: 18px; }
          .card { background: #fff; border-radius: 22px; box-shadow: 0 16px 40px rgba(15, 23, 42, .12); padding: 18px; border: 1px solid #e5e7eb; }
          .title { margin: 0 0 8px; font-size: 24px; font-weight: 700; }
          .desc { margin: 0 0 14px; color: #6b7280; line-height: 1.8; }
          .state { margin-bottom: 14px; background: #f8fafc; border: 1px solid #e5e7eb; border-radius: 14px; padding: 10px 12px; font-size: 13px; color: #374151; font-weight: 700; }
          .stack { display: grid; gap: 12px; }
          .btn { border: 0; border-radius: 14px; padding: 14px 16px; cursor: pointer; font-size: 15px; font-weight: 700; }
          .btn.primary { background: #2563eb; color: #fff; }
          .btn.dark { background: #111827; color: #fff; }
          .btn.light { background: #f3f4f6; color: #111827; }
          .panel { margin-top: 14px; padding-top: 14px; border-top: 1px solid #e5e7eb; display: none; }
          .panel.show { display: block; }
          .label { display: block; margin: 0 0 6px; font-size: 13px; font-weight: 700; color: #374151; }
          input { width: 100%; padding: 12px 14px; border-radius: 12px; border: 1px solid #d1d5db; margin-bottom: 10px; font-size: 14px; }
          .error { min-height: 20px; color: #dc2626; font-size: 13px; font-weight: 700; margin-bottom: 8px; }
          .success { min-height: 20px; color: #059669; font-size: 13px; font-weight: 700; margin-bottom: 8px; }
          .row { display: flex; gap: 10px; }
          .row .btn { flex: 1; }
          .hint { margin-top: 12px; color: #6b7280; font-size: 12px; text-align: center; line-height: 1.8; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1 class="title">لوحات التسعير</h1>
          <p class="desc">اختار اللوحة المطلوبة</p>
          <div class="state" id="passwordState">جاري فحص حالة كلمة المرور...</div>

          <div class="stack">
            <button class="btn primary" id="btnPricing">لوحة التسعير</button>
            <button class="btn dark" id="btnAdmin">لوحة التحكم</button>
            <button class="btn light" id="btnPassword">تعيين / تغيير كلمة المرور</button>
          </div>

          <div class="panel" id="adminBox">
            <div class="error" id="adminError"></div>
            <label class="label" for="adminPassword">كلمة المرور</label>
            <input type="password" id="adminPassword" placeholder="اكتب كلمة المرور">
            <div class="row">
              <button class="btn dark" id="btnAdminSubmit">دخول</button>
              <button class="btn light" id="btnAdminCancel">إلغاء</button>
            </div>
          </div>

          <div class="panel" id="passwordBox">
            <div class="error" id="passwordError"></div>
            <div class="success" id="passwordSuccess"></div>
            <div id="oldPasswordWrap">
              <label class="label" for="oldPassword">كلمة المرور القديمة </label>
              <input type="password" id="oldPassword" placeholder="اكتب القديمة">
            </div>
            <label class="label" for="newPassword">كلمة المرور الجديدة</label>
            <input type="password" id="newPassword" placeholder="اكتب كلمة المرور الجديدة">
            <label class="label" for="confirmPassword">تأكيد كلمة المرور الجديدة</label>
            <input type="password" id="confirmPassword" placeholder="أعد كتابة كلمة المرور الجديدة">
            <div class="row">
              <button class="btn dark" id="btnPasswordSubmit">حفظ</button>
              <button class="btn light" id="btnPasswordCancel">إلغاء</button>
            </div>
          </div>

          <div class="hint" id="hint">جاهز</div>
        </div>

        <script>
  (function () {
    function blockContextMenu(e) { e.preventDefault(); e.stopPropagation(); if (e.stopImmediatePropagation) e.stopImmediatePropagation(); return false; }
    window.addEventListener('contextmenu', blockContextMenu, true);
    document.addEventListener('contextmenu', blockContextMenu, true);
    document.addEventListener('DOMContentLoaded', function () {
      document.documentElement.setAttribute('oncontextmenu', 'return false;');
      document.body.setAttribute('oncontextmenu', 'return false;');
      document.querySelectorAll('*').forEach(function(el) { el.oncontextmenu = blockContextMenu; });
      document.querySelectorAll('input, textarea').forEach(function(el) { el.setAttribute('oncontextmenu', 'return false;'); });
    });
  })();

  const MH = {
    hasPassword: false,
    qs(id){ return document.getElementById(id); },
    hideAllPanels(){ this.qs('adminBox').classList.remove('show'); this.qs('passwordBox').classList.remove('show'); },
    showAdmin(){ this.hideAllPanels(); this.setAdminError(''); this.qs('adminPassword').value = ''; this.qs('adminBox').classList.add('show'); this.qs('adminPassword').focus(); },
    hideAdmin(){ this.qs('adminBox').classList.remove('show'); this.setAdminError(''); this.qs('adminPassword').value = ''; },
    showPasswordPanel(){ this.hideAllPanels(); this.setPasswordError(''); this.setPasswordSuccess(''); this.qs('oldPassword').value = ''; this.qs('newPassword').value = ''; this.qs('confirmPassword').value = ''; this.qs('oldPasswordWrap').style.display = this.hasPassword ? 'block' : 'none'; this.qs('passwordBox').classList.add('show'); (this.hasPassword ? this.qs('oldPassword') : this.qs('newPassword')).focus(); },
    hidePasswordPanel(){ this.qs('passwordBox').classList.remove('show'); this.setPasswordError(''); this.setPasswordSuccess(''); },
    setAdminError(msg){ this.qs('adminError').textContent = msg || ''; },
    setPasswordError(msg){ this.qs('passwordSuccess').textContent = ''; this.qs('passwordError').textContent = msg || ''; },
    setPasswordSuccess(msg){ this.qs('passwordError').textContent = ''; this.qs('passwordSuccess').textContent = msg || ''; },
    setPasswordState(hasPassword){ this.hasPassword = !!hasPassword; this.qs('passwordState').textContent = this.hasPassword ? 'يوجد كلمة مرور محفوظة للوحة التحكم.' : 'لا توجد كلمة مرور محفوظة حتى الآن. يمكنك تعيين واحدة الآن.'; },
    ready(){
      this.qs('btnPricing').addEventListener('click', ()=>{ if(window.sketchup && window.sketchup.mh_open_pricing){ this.qs('hint').textContent = 'جاري تجهيز قاعدة البيانات وملف المطابقة...'; window.sketchup.mh_open_pricing('1'); } });
      this.qs('btnAdmin').addEventListener('click', ()=>this.showAdmin());
      this.qs('btnAdminCancel').addEventListener('click', ()=>this.hideAdmin());
      this.qs('btnAdminSubmit').addEventListener('click', ()=>{ if(window.sketchup && window.sketchup.mh_open_admin){ this.qs('hint').textContent = 'جاري تجهيز قاعدة البيانات وملف المطابقة...'; window.sketchup.mh_open_admin(this.qs('adminPassword').value || ''); } });
      this.qs('btnPassword').addEventListener('click', ()=>this.showPasswordPanel());
      this.qs('btnPasswordCancel').addEventListener('click', ()=>this.hidePasswordPanel());
      this.qs('btnPasswordSubmit').addEventListener('click', ()=>{ const payload = { old_password: this.qs('oldPassword').value || '', new_password: this.qs('newPassword').value || '', confirm_password: this.qs('confirmPassword').value || '' }; if(window.sketchup && window.sketchup.mh_save_password){ window.sketchup.mh_save_password(JSON.stringify(payload)); } });
      if(window.sketchup && window.sketchup.mh_ready){ window.sketchup.mh_ready('1'); }
    }
  };
  document.addEventListener('DOMContentLoaded', ()=>MH.ready());
  window.MH = MH;
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
