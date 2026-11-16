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


# ==================== MHDESIGN LED LANGUAGE BRIDGE ====================
module MHDESIGN_LED_LANG
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

  # Stable key lookup. Future languages only translate LED_* keys in JSON.
  def key(key_name, fallback = nil)
    fallback_text = fallback.nil? ? key_name.to_s : fallback.to_s

    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('led').t(key_name.to_s, fallback_text)
    else
      fallback_text
    end
  rescue
    fallback.nil? ? key_name.to_s : fallback.to_s
  end

  # Legacy source text translation for old or dynamic messages.
  def source(value)
    text = value.to_s
    return text if text.empty?

    if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('led').translate_source(text)
    else
      text
    end
  rescue
    value.to_s
  end

  # Compatibility for old calls already present in the tool.
  def t(value, fallback = nil)
    text = value.to_s
    return fallback.to_s if text.empty? && !fallback.nil?
    return text if text.empty?

    if text.start_with?('LED_')
      key(text, fallback || text)
    else
      source(text)
    end
  rescue
    fallback.nil? ? value.to_s : fallback.to_s
  end

  def direction
    current.start_with?('ar') ? 'rtl' : 'ltr'
  rescue
    'rtl'
  end

  def payload_json
    payload = if defined?(MHDESIGN::Language)
      MHDESIGN::Language.for_tool('led').ui_payload
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

  def messagebox(message, *args)
    UI.messagebox(source(message), *args)
  end
end
# ===================================================================

module MHDESIGN

  # ==========================================================
  # ✅ LED Groove Tool (Hybrid V1 + V3 Special Cases)
  # - Default = original V1 logic for all units
  # - Special cases only = local V3 logic
  # - Activation entry: MHDESIGN::LEDGroove.activate_tool
  # ==========================================================

  module HandGroove90
    unless defined?(LOADED_ONCE)
      LOADED_ONCE = true

      IDENTITY = Geom::Transformation.new
      EPS = 0.2.mm

      DICT = "MHDESIGN_LED_GROOVE"
      KEYS = {
        margin: "end_margin_cm",
        inset:  "inset_cm",
        width:  "groove_w_cm",
        depth:  "depth_cm",
        light_enabled: "light_enabled",
        light_intensity: "light_intensity",
        light_color: "light_color",
        light_length: "light_length_cm"
      }

      # ✅ الحالات الخاصة فقط
      SPECIAL_PARENT_NAMES = [
        "ركنة علويه مشطوره",
        "ركنة علويه حرف ال"
      ]

      SPECIAL_PART_KEYWORDS = [
        "قاعدة",
        "قاعده"
      ]

      def self.activate_tool
        Sketchup.active_model.select_tool(Tool.new)
      end

      class Tool
        def initialize
          @settings = nil
          @asked = false

          @ip = Sketchup::InputPoint.new

          @face = nil
          @ents = nil
          @container = nil
          @path = nil

          @tr  = IDENTITY
          @inv = IDENTITY

          @state = :pick_start

          @start_w = nil
          @curr_w  = nil
          @start_l = nil

          # V1 world axes
          @origin_w = nil
          @axis_long_w  = nil
          @axis_short_w = nil
          @axis_mode = nil
          @n_w = nil

          # V3 local basis
          @origin_l = nil
          @axis_u_l = nil
          @axis_v_l = nil
          @axis_n_l = nil
          @axis_u_w = nil
          @axis_v_w = nil
          @drag_mode = nil

          # hybrid mode
          @use_local_special = false
        end

        # ---------- defaults ----------
        def load_defaults
          [
            Sketchup.read_default(DICT, KEYS[:margin], 0.0).to_f,
            Sketchup.read_default(DICT, KEYS[:inset],  4.0).to_f,
            Sketchup.read_default(DICT, KEYS[:width],  2.0).to_f,
            Sketchup.read_default(DICT, KEYS[:depth],  0.5).to_f
          ]
        end

        def save_defaults(vals)
          Sketchup.write_default(DICT, KEYS[:margin], vals[0].to_f)
          Sketchup.write_default(DICT, KEYS[:inset],  vals[1].to_f)
          Sketchup.write_default(DICT, KEYS[:width],  vals[2].to_f)
          Sketchup.write_default(DICT, KEYS[:depth],  vals[3].to_f)
        end

        def load_light_defaults
          {
            enabled: Sketchup.read_default(DICT, KEYS[:light_enabled], true) != false,
            intensity: Sketchup.read_default(DICT, KEYS[:light_intensity], 65).to_i,
            color: Sketchup.read_default(DICT, KEYS[:light_color], '#FFD27A').to_s,
            length_cm: Sketchup.read_default(DICT, KEYS[:light_length], 15.0).to_f
          }
        rescue
          { enabled: true, intensity: 65, color: '#FFD27A', length_cm: 15.0 }
        end

        def save_light_defaults(settings)
          return unless settings
          Sketchup.write_default(DICT, KEYS[:light_enabled], !!settings[:enabled])
          Sketchup.write_default(DICT, KEYS[:light_intensity], settings[:intensity].to_i)
          Sketchup.write_default(DICT, KEYS[:light_color], settings[:color].to_s)
          Sketchup.write_default(DICT, KEYS[:light_length], settings[:length_cm].to_f)
        end

        # ---------- UI ----------
        def settings_dialog_html(defaults, light_defaults)
          labels = [
            MHDESIGN_LED_LANG.key("LED_LENGTH_PROMPT", "مقاس الحفر (اتركه 0 لحفر كامل القطعة) (سم)"),
            MHDESIGN_LED_LANG.key("LED_START_PROMPT", "بداية الحفر (سم)"),
            MHDESIGN_LED_LANG.key("LED_WIDTH_PROMPT", "عرض الحفر (سم)"),
            MHDESIGN_LED_LANG.key("LED_DEPTH_PROMPT", "سقوط الحفر (سم)")
          ]
          title = MHDESIGN_LED_LANG.key("LED_DIALOG_TITLE", "MHDESIGN | حفر LED")
          subtitle_line_1 = MHDESIGN_LED_LANG.key("LED_DESIGNED_BY", "تم تصميم هذه الأداة بواسطة MHDESIGN")
          subtitle_line_2 = MHDESIGN_LED_LANG.key("LED_TOOL_NAME", "Hand Groove Tool")
          dimensions_group = MHDESIGN_LED_LANG.key("LED_DIMENSIONS_GROUP", "المقاسات")
          reopen_hint = MHDESIGN_LED_LANG.key("LED_REOPEN_HINT", "يمكنك فتح الإعدادات مرة أخرى أثناء العمل بالضغط على R")
          light_effect_group = MHDESIGN_LED_LANG.key("LED_LIGHT_EFFECT_GROUP", "تأثير الإضاءة")
          light_enable = MHDESIGN_LED_LANG.key("LED_ENABLE_EFFECT", "تفعيل تأثير الإضاءة داخل SketchUp")
          light_intensity = MHDESIGN_LED_LANG.key("LED_INTENSITY", "شدة الإضاءة")
          light_length = MHDESIGN_LED_LANG.key("LED_LIGHT_LENGTH", "طول الإضاءة")
          light_color = MHDESIGN_LED_LANG.key("LED_LIGHT_COLOR", "لون الإضاءة")
          cm_unit = MHDESIGN_LED_LANG.key("LED_CM", "سم")
          light_hint = MHDESIGN_LED_LANG.key("LED_EFFECT_HINT", "التأثير مرئي داخل SketchUp كمحاكاة ضوئية، ويظل الحفر الحقيقي كما هو.")
          applying_text = MHDESIGN_LED_LANG.key("LED_APPLYING", "جاري التطبيق...")
          apply_text = MHDESIGN_LED_LANG.key("LED_APPLY", "تطبيق")
          run_text = MHDESIGN_LED_LANG.key("LED_RUN_TOOL", "تشغيل الأداة")
          cancel_text = MHDESIGN_LED_LANG.key("LED_CANCEL", "إلغاء")
          logo_url = 'https://mhdesign-eg.com/SKETCHUP022/components/logo3.png'

          <<-HTML
<!DOCTYPE html>
<html lang="#{MHDESIGN_LED_LANG.current}" dir="#{MHDESIGN_LED_LANG.direction}">
<head>
<meta charset="UTF-8">
<title>#{title}</title>
<style>
  :root {
    color-scheme: dark;
    --mhd-app: #0B111A;
    --mhd-panel: #132330;
    --mhd-card: #192B39;
    --mhd-input: #0E1925;
    --mhd-hover: #223746;
    --mhd-secondary: #223444;
    --mhd-border: #34495B;
    --mhd-text: #F5F8FC;
    --mhd-muted: #A8BED0;
    --mhd-accent: #09BDB9;
    --mhd-accent-hover: #12D1CB;
    --mhd-ink: #071923;
  }
  *{box-sizing:border-box}
  html,body{height:100%;margin:0;overflow:hidden}
  body{font-family:Arial,Tahoma,sans-serif;background:var(--mhd-app);color:var(--mhd-text)}
  /* إخفاء Scrollbar ويندوز الأبيض نهائياً */
  html,body{scrollbar-width:none}
  html::-webkit-scrollbar,body::-webkit-scrollbar{width:0;height:0}
  .app{height:100vh;display:flex;flex-direction:column;background:var(--mhd-app);overflow:hidden}
  .hero{height:74px;padding:10px 12px;display:flex;align-items:center;gap:10px;background:var(--mhd-tool-header-gradient);border-bottom:1px solid var(--mhd-border)}
  .logo{width:58px;height:58px;object-fit:contain;background:var(--mhd-panel);border:1px solid var(--mhd-border);border-radius:10px;padding:5px;flex:0 0 auto}
  .head-text{flex:1;overflow:hidden;text-align:center}
  .title-main{font-size:20px;font-weight:900;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;line-height:1.2}
  .subtitle{margin-top:6px;font-size:11px;line-height:1.5;color:var(--mhd-muted)}
  .content-area{position:relative;height:calc(100vh - 74px - 58px);min-height:0;background:var(--mhd-app);overflow:hidden}
  .wrap{height:100%;min-height:0;overflow-y:auto;overflow-x:hidden;padding:10px 16px 10px 10px;background:var(--mhd-app);scrollbar-width:none}
  .wrap::-webkit-scrollbar{width:0;height:0}
  .mhd-scroll-track{position:absolute;top:6px;bottom:6px;left:4px;width:8px;background:var(--mhd-app);border-radius:20px;z-index:20}
  .mhd-scroll-thumb{position:absolute;top:0;left:0;width:8px;min-height:34px;background:var(--mhd-border);border:2px solid var(--mhd-app);border-radius:20px;cursor:pointer}
  .mhd-scroll-thumb:hover{background:var(--mhd-hover)}
  html[dir="ltr"] .mhd-scroll-track{left:auto;right:4px}
  html[dir="ltr"] .wrap{padding:10px 16px 10px 10px}
  .group{background:var(--mhd-card);border:1px solid var(--mhd-border);border-radius:10px;margin-bottom:10px;overflow:hidden}
  .group-title{padding:9px 10px;background:var(--mhd-panel);color:var(--mhd-accent);font-size:16px;font-weight:900;border-bottom:1px solid var(--mhd-border);user-select:none}
  .group-body{padding:10px}
  .preview{height:88px;display:flex;align-items:center;justify-content:center;border:1px solid var(--mhd-border);border-radius:10px;background:var(--mhd-panel);margin-bottom:10px}
  .preview svg{width:230px;height:62px}
  .piece{fill:#102b3a;stroke:var(--mhd-text);stroke-width:2}
  .groove{fill:var(--mhd-accent)}
  .dim{stroke:var(--mhd-accent);stroke-width:1.5;stroke-dasharray:4 3}
  .field-row{display:grid;grid-template-columns:1fr 110px;gap:8px;align-items:center;margin-bottom:8px}
  .field-row:last-child{margin-bottom:0}
  label{font-size:13px;font-weight:900;color:var(--mhd-text);text-align:right;line-height:1.35}
  input[type=number]{width:100%;height:34px;padding:5px 8px;border:none;border-radius:7px;background:var(--mhd-input);color:#fff;font-size:13px;outline:1px solid var(--mhd-border);text-align:center}
  input[type=number]:focus{outline:2px solid var(--mhd-accent);background:var(--mhd-input)}
  .hint{font-size:10px;color:var(--mhd-muted);margin-top:8px;line-height:1.5;text-align:center}
  .switch-row{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-bottom:12px}
  .switch-label{font-size:13px;font-weight:900;color:var(--mhd-text)}
  .switch{position:relative;width:48px;height:25px;flex:0 0 auto}
  .switch input{opacity:0;width:0;height:0}
  .slider{position:absolute;inset:0;background:var(--mhd-border);border-radius:30px;cursor:pointer;transition:.2s}
  .slider:before{content:'';position:absolute;width:19px;height:19px;left:3px;top:3px;background:var(--mhd-text);border-radius:50%;transition:.2s}
  .switch input:checked + .slider{background:var(--mhd-accent)}
  .switch input:checked + .slider:before{transform:translateX(23px)}
  .live-range-row{display:grid;grid-template-columns:110px minmax(0,1fr) 65px;gap:10px;align-items:center;margin-bottom:10px;direction:rtl}
  .live-range-row label{white-space:nowrap}
  input[type=range]{width:100%;min-width:0;accent-color:var(--mhd-accent);cursor:pointer}
  .range-value{height:32px;display:flex;align-items:center;justify-content:center;background:var(--mhd-input);border:1px solid var(--mhd-border);border-radius:7px;font-weight:900}
  .range-unit{font-size:10px;color:var(--mhd-muted);margin-right:3px}
  .color-row{display:grid;grid-template-columns:1fr 110px;gap:8px;align-items:center}
  input[type=color]{width:100%;height:34px;border:1px solid var(--mhd-border);border-radius:7px;background:var(--mhd-input);padding:3px;cursor:pointer}
  .light-preview{height:72px;margin-top:12px;border:1px solid var(--mhd-border);border-radius:10px;background:var(--mhd-panel);position:relative;overflow:hidden}
  .light-strip{position:absolute;left:18%;right:18%;top:15px;height:5px;border-radius:6px;background:#{light_defaults[:color]};box-shadow:0 0 8px #{light_defaults[:color]},0 0 18px #{light_defaults[:color]}}
  .light-beam{position:absolute;left:18%;right:18%;top:20px;height:48px;background:linear-gradient(to bottom,#{light_defaults[:color]}DD,#{light_defaults[:color]}00)}
  .footer{height:58px;padding:8px 10px;border-top:1px solid var(--mhd-border);background:var(--mhd-app);display:flex;gap:8px}
  .apply-status{position:absolute;left:50%;bottom:64px;transform:translateX(-50%) translateY(8px);z-index:50;display:flex;align-items:center;gap:7px;min-width:132px;justify-content:center;padding:7px 13px;border-radius:18px;background:var(--mhd-accent);color:#fff;font-size:12px;font-weight:900;box-shadow:0 5px 18px rgba(0,0,0,.34);opacity:0;visibility:hidden;pointer-events:none;transition:opacity .16s ease,transform .16s ease,visibility .16s}
  .apply-status.show{opacity:1;visibility:visible;transform:translateX(-50%) translateY(0)}
  .apply-spinner{width:13px;height:13px;border:2px solid rgba(255,255,255,.38);border-top-color:#fff;border-radius:50%;animation:mhdSpin .7s linear infinite}
  @keyframes mhdSpin{to{transform:rotate(360deg)}}
  .ok:disabled{opacity:.55;cursor:wait}
  button{height:40px;border-radius:10px;font-size:14px;font-weight:900;cursor:pointer;border:none}
  .ok{flex:1.35;background:var(--mhd-accent);color:var(--mhd-ink)}
  .run{flex:1.35;background:var(--mhd-secondary);color:#fff;border:1px solid var(--mhd-border)}
  .run:hover{background:var(--mhd-hover)}
  .cancel{flex:.8;background:var(--mhd-card);color:#fff;border:1px solid var(--mhd-border)}
  body { font-family: "Segoe UI", Tahoma, Arial, sans-serif; }
  button, input { font-family: inherit; min-width: 0; }
  button:focus-visible, input:focus-visible, .switch input:focus-visible + .slider {
    outline: 2px solid var(--mhd-accent-hover); outline-offset: 2px;
  }
  .content-area { flex: 1 1 0; height: auto; }
  .group-title { color: var(--mhd-accent-hover); }
  .footer { flex: none; height: auto; min-height: 58px; background: var(--mhd-panel); }
  .footer button { min-height: 40px; height: auto; padding: 4px 8px; overflow-wrap: anywhere; }
  .ok:hover:not(:disabled) { background: var(--mhd-accent-hover); }
  .apply-status { color: var(--mhd-ink); }
  .apply-spinner { border-color: rgba(7,25,35,.26); border-top-color: var(--mhd-ink); }
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
<div class="app">
  <div class="hero mhd-tool-header mhd-ref-header">
    #{MHDESIGN_ResponsiveHeaderUI::BRAND}
    <div class="head-text">
      <div class="title-main">#{title}</div>
      <div class="subtitle">#{subtitle_line_1}<br>#{subtitle_line_2}</div>
    </div>
  <!-- Dressing reference header artwork is included in BRAND. --></div>
  <div class="content-area">
  <div class="wrap" id="mhdWrap">
    <div class="group">
      <div class="group-title">▼ #{dimensions_group}</div>
      <div class="group-body">
        <div class="field-row"><label>#{labels[0]}</label><input id="margin" type="number" step="0.1" value="#{defaults[0]}"></div>
        <div class="field-row"><label>#{labels[1]}</label><input id="inset" type="number" step="0.1" value="#{defaults[1]}"></div>
        <div class="field-row"><label>#{labels[2]}</label><input id="width" type="number" step="0.1" value="#{defaults[2]}"></div>
        <div class="field-row"><label>#{labels[3]}</label><input id="depth" type="number" step="0.1" value="#{defaults[3]}"></div>
        <div class="hint">#{reopen_hint}</div>
      </div>
    </div>
    <div class="group">
      <div class="group-title">▼ #{light_effect_group}</div>
      <div class="group-body">
        <div class="switch-row">
          <div class="switch-label">#{light_enable}</div>
          <label class="switch"><input id="lightEnabled" type="checkbox" #{light_defaults[:enabled] ? 'checked' : ''}><span class="slider"></span></label>
        </div>
        <div class="live-range-row"><label>#{light_intensity}</label><input id="lightIntensity" type="range" min="10" max="100" step="1" value="#{light_defaults[:intensity]}"><div id="intensityValue" class="range-value">#{light_defaults[:intensity]}</div></div>
        <div class="live-range-row"><label>#{light_length}</label><input id="lightLength" type="range" min="5" max="100" step="1" value="#{light_defaults[:length_cm]}"><div class="range-value"><span id="lengthValue">#{light_defaults[:length_cm].to_f.round(1)}</span><span class="range-unit">#{cm_unit}</span></div></div>
        <div class="color-row"><label>#{light_color}</label><input id="lightColor" type="color" value="#{light_defaults[:color]}"></div>
        <div class="light-preview"><div id="lightStrip" class="light-strip"></div><div id="lightBeam" class="light-beam"></div></div>
        <div class="hint">#{light_hint}</div>
      </div>
    </div>
  </div>
  <div class="mhd-scroll-track" id="mhdScrollTrack"><div class="mhd-scroll-thumb" id="mhdScrollThumb"></div></div>
  </div>
  <div id="applyStatus" class="apply-status" role="status" aria-live="polite"><span class="apply-spinner"></span><span>#{applying_text}</span></div>
  <div class="footer">
    <button id="applyButton" class="ok" onclick="submitData()">#{apply_text}</button>
    <button class="run" onclick="runTool()">#{run_text}</button>
    <button class="cancel" onclick="sketchup.cancel()">#{cancel_text}</button>
  </div>
</div>
<script>
const MHD_L10N = #{MHDESIGN_LED_LANG.payload_json};
const MHD_TEXTS = MHD_L10N.texts || {};
const MHD_MAP = MHD_L10N.source_map || {};
function translateText(value){value=String(value ?? "");return Object.prototype.hasOwnProperty.call(MAP,value)?String(MAP[value]):value;}
document.documentElement.lang=MHD_L10N.locale || 'ar_EG';
document.documentElement.dir=MHD_L10N.direction || 'rtl';
document.addEventListener('contextmenu',e=>e.preventDefault());
document.addEventListener('dragstart',e=>e.preventDefault());
document.addEventListener('selectstart',e=>e.preventDefault());
function num(id){return document.getElementById(id).value;}
function currentPayload(){
  return {
    groove:[num('margin'),num('inset'),num('width'),num('depth')],
    light:{
      enabled:document.getElementById('lightEnabled').checked,
      intensity:Number(document.getElementById('lightIntensity').value),
      color:document.getElementById('lightColor').value,
      length_cm:Number(document.getElementById('lightLength').value)
    }
  };
}
let mhdApplying=false;
function submitData(){
  if(mhdApplying) return;
  mhdApplying=true;
  const status=document.getElementById('applyStatus');
  const button=document.getElementById('applyButton');
  status.classList.add('show');
  button.disabled=true;
  window.setTimeout(function(){
    sketchup.submit(JSON.stringify(currentPayload()));
  },40);
}
function mhdApplyFinished(){
  const status=document.getElementById('applyStatus');
  const button=document.getElementById('applyButton');
  window.setTimeout(function(){
    status.classList.remove('show');
    button.disabled=false;
    mhdApplying=false;
  },300);
}

// مزامنة القيم فورياً مع أداة SketchUp، حتى لو لم يضغط المستخدم على زر تطبيق.
let mhdSyncTimer=null;
function syncSettingsNow(){
  if(mhdSyncTimer){
    window.clearTimeout(mhdSyncTimer);
    mhdSyncTimer=null;
  }
  try{ sketchup.live_sync(JSON.stringify(currentPayload())); }catch(e){}
}
function queueSettingsSync(){
  if(mhdSyncTimer) window.clearTimeout(mhdSyncTimer);
  mhdSyncTimer=window.setTimeout(syncSettingsNow,60);
}
function runTool(){
  syncSettingsNow();
  window.setTimeout(function(){
    try{ sketchup.run_tool(); }catch(e){}
  },40);
}

const lightIntensity=document.getElementById('lightIntensity');
const intensityValue=document.getElementById('intensityValue');
const lightLength=document.getElementById('lightLength');
const lengthValue=document.getElementById('lengthValue');
const lightColor=document.getElementById('lightColor');
const lightStrip=document.getElementById('lightStrip');
const lightBeam=document.getElementById('lightBeam');
function updateLightPreview(){
  const c=lightColor.value;
  const a=Math.max(0.15,Number(lightIntensity.value)/100*0.65);
  intensityValue.textContent=lightIntensity.value;
  lengthValue.textContent=Number(lightLength.value).toFixed(0);
  const previewHeight=Math.max(15,Math.min(48,Number(lightLength.value)/100*48));
  lightBeam.style.height=previewHeight+'px';
  lightStrip.style.background=c;
  lightStrip.style.boxShadow='0 0 8px '+c+', 0 0 18px '+c;
  lightBeam.style.background='linear-gradient(to bottom,'+c+Math.round(a*255).toString(16).padStart(2,'0')+','+c+'00)';
  const enabled=document.getElementById('lightEnabled').checked;
  lightStrip.style.opacity=enabled?'1':'.18';
  lightBeam.style.opacity=enabled?'1':'0';
}
lightIntensity.addEventListener('input',function(){updateLightPreview();queueSettingsSync();});
lightLength.addEventListener('input',function(){updateLightPreview();queueSettingsSync();});
lightColor.addEventListener('input',function(){updateLightPreview();queueSettingsSync();});
document.getElementById('lightEnabled').addEventListener('change',function(){updateLightPreview();syncSettingsNow();});
['margin','inset','width','depth'].forEach(function(id){
  const el=document.getElementById(id);
  el.addEventListener('input',queueSettingsSync);
  el.addEventListener('change',syncSettingsNow);
});
window.addEventListener('blur',syncSettingsNow);
updateLightPreview();
// Scrollbar داخلي غامق لا يعتمد على شكل Windows
const mhdWrap=document.getElementById('mhdWrap');
const mhdTrack=document.getElementById('mhdScrollTrack');
const mhdThumb=document.getElementById('mhdScrollThumb');
function updateMhdScrollbar(){
  const maxScroll=mhdWrap.scrollHeight-mhdWrap.clientHeight;
  if(maxScroll<=1){mhdTrack.style.display='none';return;}
  mhdTrack.style.display='block';
  const trackH=mhdTrack.clientHeight;
  const thumbH=Math.max(34,trackH*(mhdWrap.clientHeight/mhdWrap.scrollHeight));
  const maxTop=trackH-thumbH;
  const top=maxScroll>0?(mhdWrap.scrollTop/maxScroll)*maxTop:0;
  mhdThumb.style.height=thumbH+'px';
  mhdThumb.style.transform='translateY('+top+'px)';
}
mhdWrap.addEventListener('scroll',updateMhdScrollbar);
window.addEventListener('resize',updateMhdScrollbar);
let mhdDrag=false,mhdStartY=0,mhdStartScroll=0;
mhdThumb.addEventListener('mousedown',function(e){mhdDrag=true;mhdStartY=e.clientY;mhdStartScroll=mhdWrap.scrollTop;e.preventDefault();});
document.addEventListener('mousemove',function(e){
  if(!mhdDrag)return;
  const maxScroll=mhdWrap.scrollHeight-mhdWrap.clientHeight;
  const movable=mhdTrack.clientHeight-mhdThumb.offsetHeight;
  if(movable>0)mhdWrap.scrollTop=mhdStartScroll+(e.clientY-mhdStartY)*(maxScroll/movable);
});
document.addEventListener('mouseup',function(){mhdDrag=false;});
mhdTrack.addEventListener('click',function(e){
  if(e.target===mhdThumb)return;
  const r=mhdTrack.getBoundingClientRect();
  const ratio=(e.clientY-r.top)/r.height;
  mhdWrap.scrollTop=ratio*(mhdWrap.scrollHeight-mhdWrap.clientHeight);
});
setTimeout(updateMhdScrollbar,0);

document.addEventListener('keydown',function(e){
  if(e.key==='Enter') submitData();
  if(e.key==='Escape') sketchup.cancel();
});
</script>
</body>
</html>
          HTML
        end

        def normalized_light_settings(light)
          {
            enabled: !!light['enabled'],
            intensity: [[light['intensity'].to_i, 10].max, 100].min,
            color: light['color'].to_s.match?(/\A#[0-9a-fA-F]{6}\z/) ? light['color'].to_s.upcase : '#FFD27A',
            length_cm: [[light['length_cm'].to_f, 5.0].max, 100.0].min
          }
        end

        def each_entity_recursive(entities, &block)
          entities.each do |entity|
            block.call(entity)
            if entity.respond_to?(:entities)
              each_entity_recursive(entity.entities, &block)
            elsif entity.is_a?(Sketchup::ComponentInstance)
              each_entity_recursive(entity.definition.entities, &block)
            end
          end
        end

        def stored_light_geometry(group)
          raw_points = group.get_attribute(DICT, 'source_groove_points')
          raw_normal = group.get_attribute(DICT, 'source_face_normal')
          return nil unless raw_points.is_a?(Array) && raw_points.length == 12
          return nil unless raw_normal.is_a?(Array) && raw_normal.length == 3

          points = raw_points.each_slice(3).map { |a| Geom::Point3d.new(a[0].to_f, a[1].to_f, a[2].to_f) }
          normal = Geom::Vector3d.new(raw_normal[0].to_f, raw_normal[1].to_f, raw_normal[2].to_f)
          return nil if normal.length < 1e-9
          normal.normalize!
          [points, normal]
        rescue
          nil
        end

        def rebuild_light_curtain(group, groove_points, normal, settings, max_drop)
          gents = group.entities
          removable = gents.to_a.reject { |e| e.get_attribute(DICT, 'effect_part') == 'led_source_line' }
          gents.erase_entities(removable) unless removable.empty?

          rgb = hex_rgb(settings[:color])
          intensity = [[settings[:intensity].to_i, 10].max, 100].min
          ratio = intensity / 100.0
          start_alpha = 0.14 + (ratio ** 0.72) * 0.84
          start_alpha = [start_alpha, 0.98].min
          strip_offset = 0.35.mm
          strip_pts = groove_points.map { |pt| offset_point(pt, normal, strip_offset) }
          previous_pts = strip_pts
          segment_count = 64

          1.upto(segment_count) do |segment|
            t = segment.to_f / segment_count.to_f
            current_pts = groove_points.map { |pt| offset_point(pt, normal, strip_offset + (max_drop * t)) }
            hold = 0.10
            if t <= hold
              fade = 1.0
            else
              u = (t - hold) / (1.0 - hold)
              smooth = u * u * (3.0 - 2.0 * u)
              fade = (1.0 - smooth) ** 1.35
            end
            alpha = segment == segment_count ? 0.0 : start_alpha * fade
            mat = led_material(Sketchup.active_model, "MHDESIGN_LED_STRAIGHT_GLOW_#{settings[:color]}_#{group.entityID}_#{segment}", rgb, alpha)
            faces = []
            faces << add_colored_face(gents, [previous_pts[0], previous_pts[1], current_pts[1], current_pts[0]], mat)
            faces << add_colored_face(gents, [previous_pts[1], previous_pts[2], current_pts[2], current_pts[1]], mat)
            faces << add_colored_face(gents, [previous_pts[2], previous_pts[3], current_pts[3], current_pts[2]], mat)
            faces << add_colored_face(gents, [previous_pts[3], previous_pts[0], current_pts[0], current_pts[3]], mat)
            faces.compact.each do |face|
              face.set_attribute(DICT, 'light_segment', segment)
              face.set_attribute(DICT, 'light_fade', fade)
              face.set_attribute(DICT, 'effect_part', 'light_curtain')
            end
            previous_pts = current_pts
          end
          group.set_attribute(DICT, 'light_length_cm', max_drop.to_cm)
        end

        def update_existing_light_effects
          model = Sketchup.active_model
          return unless model

          settings = @light_settings || load_light_defaults
          intensity = [[settings[:intensity].to_i, 10].max, 100].min
          ratio = intensity / 100.0
          target_length_cm = [[settings[:length_cm].to_f, 5.0].max, 100.0].min
          start_alpha = 0.08 + (ratio ** 0.55) * 0.90
          start_alpha = [start_alpha, 0.98].min
          rgb = hex_rgb(settings[:color])

          each_entity_recursive(model.entities) do |entity|
            next unless entity.is_a?(Sketchup::Group)
            next unless entity.get_attribute(DICT, 'effect_type') == 'led_visual_light'

            entity.set_attribute(DICT, 'intensity', intensity)
            entity.set_attribute(DICT, 'color', settings[:color].to_s)
            entity.hidden = !settings[:enabled]

            stored = stored_light_geometry(entity)
            current_length = entity.get_attribute(DICT, 'light_length_cm', 15.0).to_f
            if stored && (current_length - target_length_cm).abs > 0.01
              rebuild_light_curtain(entity, stored[0], stored[1], settings, target_length_cm.cm)
            end

            entity.entities.each do |part|
              segment = part.get_attribute(DICT, 'light_segment')
              fade = part.get_attribute(DICT, 'light_fade')

              if segment && fade && part.respond_to?(:material=)
                alpha = start_alpha * fade.to_f
                alpha = 0.0 if fade.to_f <= 0.0001
                mat = led_material(
                  model,
                  "MHDESIGN_LED_LIVE_#{entity.entityID}_#{segment}",
                  rgb,
                  alpha
                )
                part.material = mat
                part.back_material = mat if part.respond_to?(:back_material=)
              elsif part.get_attribute(DICT, 'effect_part') == 'led_source_line'
                line_alpha = 0.20 + ratio * 0.80
                mat = led_material(
                  model,
                  "MHDESIGN_LED_LIVE_LINE_#{entity.entityID}",
                  rgb,
                  line_alpha
                )
                part.material = mat if part.respond_to?(:material=)
              end
            end
          end
        rescue => e
          puts "update_existing_light_effects ERROR: #{e.class} - #{e.message}"
        end

        def ask_settings
          defaults = @settings || load_defaults
          light_defaults = @light_settings || load_light_defaults

          if @settings_dialog && @settings_dialog.visible?
            @settings_dialog.bring_to_front
            return true
          end

          dialog = UI::HtmlDialog.new(
            dialog_title: MHDESIGN_LED_LANG.key("LED_DIALOG_TITLE", "MHDESIGN | حفر LED"),
            preferences_key: 'MHDESIGN_HAND_GROOVE_UI',
            scrollable: false,
            resizable: true,
            width: 330,
            height: 640,
            style: UI::HtmlDialog::STYLE_DIALOG
          )
          @settings_dialog = dialog

          dialog.set_html(settings_dialog_html(defaults, light_defaults))
          dialog.add_action_callback('cancel') do
            dialog.close
            @settings_dialog = nil
            Sketchup.active_model.select_tool(nil)
          end

          dialog.add_action_callback('live_sync') do |_, json|
            begin
              payload = JSON.parse(json)
              groove = payload['groove'] || []
              light = payload['light'] || {}
              @settings = groove.map(&:to_f)
              @light_settings = normalized_light_settings(light)
              save_defaults(@settings)
              save_light_defaults(@light_settings)
              Sketchup.active_model.active_view.invalidate rescue nil
            rescue => e
              puts "live_sync settings ERROR: #{e.class} - #{e.message}"
            end
          end

          dialog.add_action_callback('run_tool') do
            begin
              reset_for_next_cut
              Sketchup.active_model.select_tool(self)
              Sketchup.active_model.active_view.invalidate rescue nil
            rescue => e
              puts "run_tool ERROR: #{e.class} - #{e.message}"
            end
          end

          dialog.add_action_callback('submit') do |_, json|
            begin
              payload = JSON.parse(json)
              groove = payload['groove'] || []
              light = payload['light'] || {}
              @settings = groove.map(&:to_f)
              @light_settings = normalized_light_settings(light)
              save_defaults(@settings)
              save_light_defaults(@light_settings)
              update_existing_light_effects
              Sketchup.active_model.active_view.invalidate rescue nil
            rescue => e
              puts "submit settings ERROR: #{e.class} - #{e.message}"
            ensure
              dialog.execute_script('mhdApplyFinished();') if dialog.visible?
            end
          end

          dialog.set_on_closed { @settings_dialog = nil }
          dialog.show

          # The tool is immediately ready; settings are applied only when the user presses Apply.
          @settings = defaults.map(&:to_f)
          @light_settings = light_defaults
          true
        end

        def activate
          @settings ||= load_defaults
          @light_settings ||= load_light_defaults
          ask_settings unless @settings_dialog && @settings_dialog.visible?
          Sketchup.set_status_text(MHDESIGN_LED_LANG.key("LED_STATUS", "اضغط النقطة A ← اسحب ← اضغط النقطة B للقص | R تعديل | Esc خروج"), SB_PROMPT)
        end

        def onKeyDown(key, repeat, flags, view)
          ctrl_down = begin
            defined?(COPY_MODIFIER_MASK) && (flags & COPY_MODIFIER_MASK) != 0
          rescue
            false
          end

          # أثناء تشغيل أداة مخصصة قد لا يصل Ctrl+Z لأمر SketchUp الافتراضي،
          # لذلك ننفذه صراحةً ونُعيد ضبط مرحلة الرسم الحالية.
          if ctrl_down && (key == 'Z'.ord || key == 'z'.ord)
            Sketchup.send_action('editUndo:')
            reset_for_next_cut
            view.invalidate
            return
          end

          case key
          when 27
            @settings_dialog.close if @settings_dialog && @settings_dialog.visible?
            @settings_dialog = nil
            Sketchup.active_model.select_tool(nil)
          when 'R'.ord, 'r'.ord
            ask_settings
            view.invalidate
          end
        end

        # ==========================================================
        # helpers
        # ==========================================================
        def normalize_ar(str)
          s = str.to_s.dup
          s = s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
          s.gsub!(/\s+/, "")
          s.tr!("أإآ", "ااا")
          s.tr!("ة", "ه")
          s.tr!("ى", "ي")
          s.downcase
        rescue
          str.to_s.downcase.gsub(/\s+/, "")
        end

        def text_contains_any?(text, arr)
          nt = normalize_ar(text)
          arr.any? { |x| nt.include?(normalize_ar(x)) }
        end

        def dynamic_name_of(entity)
          return "" unless entity

          val =
            entity.get_attribute("dynamic_attributes", "name") ||
            entity.get_attribute("dynamic_attributes", "_name_label") ||
            entity.get_attribute("dynamic_attributes", "Name") ||
            entity.name

          val.to_s
        rescue
          ""
        end

        def definition_name_of(entity)
          return "" unless entity

          if entity.is_a?(Sketchup::ComponentInstance)
            entity.definition ? MHDESIGN::Language.original_definition_name(entity.definition).to_s : ""
          elsif entity.is_a?(Sketchup::Group)
            entity.definition ? MHDESIGN::Language.original_definition_name(entity.definition).to_s : entity.name.to_s
          else
            ""
          end
        rescue
          ""
        end

        def full_path_transformation_to_parent(path, container)
          tr = IDENTITY
          arr = path.to_a

          arr.each do |e|
            break if e == container
            if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
              tr = tr * e.transformation
            end
          end

          if container.is_a?(Sketchup::ComponentInstance) || container.is_a?(Sketchup::Group)
            tr = tr * container.transformation
          end

          tr
        rescue
          IDENTITY
        end

        def parent_container_of_face_in_path(path, face)
          arr = path.to_a
          idx = arr.index(face)
          return nil unless idx

          (idx - 1).downto(0) do |i|
            e = arr[i]
            return e if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
          end

          nil
        end

        def local_face_plane
          p0 = @face.vertices.first.position
          n  = @face.normal
          [p0, n]
        end

        def project_point_to_face_plane(pt)
          pt.project_to_plane(local_face_plane)
        rescue
          pt
        end

        def points_too_close?(pts)
          return true if pts.nil? || pts.length < 4
          pts.each_with_index do |a, i|
            ((i + 1)...pts.length).each do |j|
              b = pts[j]
              return true if a.distance(b) < 0.1.mm
            end
          end
          false
        end

        def special_case_selected?
          return false unless @container && @path

          part_def_name = definition_name_of(@container)
          return false unless text_contains_any?(part_def_name, SPECIAL_PART_KEYWORDS)

          arr = @path.to_a
          parent_match = arr.any? do |e|
            next false unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
            unit_name = dynamic_name_of(e)
            text_contains_any?(unit_name, SPECIAL_PARENT_NAMES)
          end

          parent_match
        rescue
          false
        end

        # ==========================================================
        # picking
        # ==========================================================
        def pick_face_using_inputpoint(view, x, y)
          @face = nil
          @ents = nil
          @container = nil
          @path = nil
          @tr = IDENTITY
          @inv = IDENTITY

          @ip.pick(view, x, y)
          ip_face = @ip.face
          return unless ip_face.is_a?(Sketchup::Face)

          ph = view.pick_helper
          ph.do_pick(x, y)

          chosen_path = nil
          chosen_container = nil

          (0...ph.count).each do |i|
            pth = ph.path_at(i)
            next unless pth && pth.any?

            arr = pth.to_a
            face_index = arr.index(ip_face)
            next unless face_index

            parent = nil
            (face_index - 1).downto(0) do |j|
              e = arr[j]
              if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
                parent = e
                break
              end
            end

            chosen_path = pth
            chosen_container = parent
            break
          end

          return unless chosen_path

          if chosen_container
            ents = chosen_container.is_a?(Sketchup::Group) ? chosen_container.entities : chosen_container.definition.entities
            tr = full_path_transformation_to_parent(chosen_path, chosen_container)
          else
            ents = Sketchup.active_model.active_entities
            tr = IDENTITY
          end

          return unless ents

          @face = ip_face
          @ents = ents
          @container = chosen_container
          @path = chosen_path
          @tr = tr
          @inv = tr.inverse
          @use_local_special = special_case_selected?
        rescue => e
          puts "pick_face ERROR: #{e.class} - #{e.message}"
        end

        # ==========================================================
        # V1 geometry helpers (WORLD)
        # ==========================================================
        def compute_axes_world_from_face
          verts_w = @face.outer_loop.vertices.map { |v| v.position.transform(@tr) }
          @origin_w = verts_w.first

          edges = @face.outer_loop.edges
          long_e  = edges.max_by(&:length)
          short_e = edges.min_by(&:length)

          a = long_e.start.position.transform(@tr)
          b = long_e.end.position.transform(@tr)
          v1 = b - a
          @axis_long_w = Geom::Vector3d.new(v1.x, v1.y, v1.z)
          @axis_long_w.normalize!

          c = short_e.start.position.transform(@tr)
          d = short_e.end.position.transform(@tr)
          v2 = d - c
          @axis_short_w = Geom::Vector3d.new(v2.x, v2.y, v2.z)
          @axis_short_w.normalize!

          n_local = @face.normal
          n_w_tmp = n_local.transform(@tr)
          @n_w = Geom::Vector3d.new(n_w_tmp.x, n_w_tmp.y, n_w_tmp.z)
          @n_w.normalize!
        end

        def coord_world(pt_w, axis_w)
          d = pt_w - @origin_w
          Geom::Vector3d.new(d.x, d.y, d.z).dot(axis_w)
        end

        # ==========================================================
        # V3 local basis
        # ==========================================================
        def setup_local_basis
          verts = @face.outer_loop.vertices.map(&:position)
          raise "No face vertices found" if verts.empty?

          edges = @face.outer_loop.edges
          long_e = edges.max_by(&:length)
          raise "No valid face edges found" unless long_e

          p1 = long_e.start.position
          p2 = long_e.end.position

          axis_u = p2 - p1
          raise "Invalid long edge" if axis_u.length < 0.001.mm
          axis_u = Geom::Vector3d.new(axis_u.x, axis_u.y, axis_u.z)
          axis_u.normalize!

          axis_n = @face.normal
          axis_n = Geom::Vector3d.new(axis_n.x, axis_n.y, axis_n.z)
          axis_n.normalize!

          axis_v = axis_n * axis_u
          raise "Invalid perpendicular axis" if axis_v.length < 0.001.mm
          axis_v.normalize!

          @origin_l = p1
          @axis_u_l = axis_u
          @axis_v_l = axis_v
          @axis_n_l = axis_n

          u_w_tmp = @axis_u_l.transform(@tr)
          @axis_u_w = Geom::Vector3d.new(u_w_tmp.x, u_w_tmp.y, u_w_tmp.z)
          @axis_u_w.normalize!

          v_w_tmp = @axis_v_l.transform(@tr)
          @axis_v_w = Geom::Vector3d.new(v_w_tmp.x, v_w_tmp.y, v_w_tmp.z)
          @axis_v_w.normalize!
        end

        def coord_local(pt_l, axis_l)
          d = pt_l - @origin_l
          Geom::Vector3d.new(d.x, d.y, d.z).dot(axis_l)
        end

        def point_from_uv(u, v)
          Geom::Point3d.new(
            @origin_l.x + @axis_u_l.x * u + @axis_v_l.x * v,
            @origin_l.y + @axis_u_l.y * u + @axis_v_l.y * v,
            @origin_l.z + @axis_u_l.z * u + @axis_v_l.z * v
          )
        end

        def face_bounds_uv
          verts = @face.outer_loop.vertices.map(&:position)
          us = verts.map { |pt| coord_local(pt, @axis_u_l) }
          vs = verts.map { |pt| coord_local(pt, @axis_v_l) }
          [us.min, us.max, vs.min, vs.max]
        end

        def point_inside_face_local?(pt_l)
          klass = @face.classify_point(pt_l)
          return true if klass == Sketchup::Face::PointInside
          return true if klass == Sketchup::Face::PointOnEdge
          return true if klass == Sketchup::Face::PointOnVertex
          false
        rescue
          false
        end

        def safe_inside_face?(pts)
          pts.all? { |p| point_inside_face_local?(p) }
        end

        def safe_add_face(ents, pts)
          face = nil

          begin
            face = ents.add_face(pts)
          rescue
            face = nil
          end
          return face if face && face.valid?

          begin
            face = ents.add_face(pts.reverse)
          rescue
            face = nil
          end
          return face if face && face.valid?

          nil
        end

        # ==========================================================
        # mouse
        # ==========================================================
        def onMouseMove(flags, x, y, view)
          @ip.pick(view, x, y)
          return unless @face

          pt_w = @ip.position
          return unless pt_w.is_a?(Geom::Point3d)
          @curr_w = pt_w

          if @state == :drag
            if @use_local_special
              if @start_w && @axis_u_w && @axis_v_w
                drag = @curr_w - @start_w
                return if drag.length < 1.mm
                @drag_mode = (drag.dot(@axis_u_w).abs > drag.dot(@axis_v_w).abs) ? :u : :v
              end
            else
              if @start_w && @axis_long_w && @axis_short_w
                v_drag = @curr_w - @start_w
                return if v_drag.length < 1.mm
                @axis_mode = (v_drag.dot(@axis_long_w).abs > v_drag.dot(@axis_short_w).abs) ? :long : :short
              end
            end
          end

          view.invalidate
        rescue => e
          puts "onMouseMove ERROR: #{e.class} - #{e.message}"
        end

        def onLButtonDown(flags, x, y, view)
          if @state == :pick_start
            pick_face_using_inputpoint(view, x, y)
            return unless @face && @ents

            pt_w = @ip.position
            return unless pt_w.is_a?(Geom::Point3d)
            @start_w = pt_w

            if @use_local_special
              setup_local_basis
              @start_l = pt_w.transform(@inv)
              @drag_mode = nil
            else
              compute_axes_world_from_face
              @axis_mode = nil
            end

            @state = :drag
            return
          end

          if @state == :drag
            if @use_local_special
              return unless @drag_mode
              perform_cut_local
            else
              return unless @axis_mode
              perform_cut_world
            end
            reset_for_next_cut
            view.invalidate
          end
        rescue => e
          MHDESIGN_LED_LANG.messagebox("#{MHDESIGN_LED_LANG.key("LED_ERROR", "خطأ")}:\n#{e.class}\n#{e.message}")
          puts "onLButtonDown ERROR: #{e.class} - #{e.message}"
        end

        def reset_for_next_cut
          @face = nil
          @ents = nil
          @container = nil
          @path = nil
          @tr  = IDENTITY
          @inv = IDENTITY

          @state = :pick_start

          @start_w = nil
          @curr_w  = nil
          @start_l = nil

          @origin_w = nil
          @axis_long_w = nil
          @axis_short_w = nil
          @axis_mode = nil
          @n_w = nil

          @origin_l = nil
          @axis_u_l = nil
          @axis_v_l = nil
          @axis_n_l = nil
          @axis_u_w = nil
          @axis_v_w = nil
          @drag_mode = nil

          @use_local_special = false
        end

        # ==========================================================
        # draw
        # ==========================================================
        def draw(view)
          return unless @state == :drag && @start_w

          axis = nil
          if @use_local_special
            return unless @drag_mode
            axis = (@drag_mode == :u) ? @axis_u_w : @axis_v_w
          else
            return unless @axis_mode
            axis = (@axis_mode == :long) ? @axis_long_w : @axis_short_w
          end

          return unless axis

          a = @start_w
          b = Geom::Point3d.new(
            @start_w.x + axis.x * 140.mm,
            @start_w.y + axis.y * 140.mm,
            @start_w.z + axis.z * 140.mm
          )

          view.line_width = 3
          view.drawing_color = "black"
          view.draw(GL_LINES, [a, b])
        rescue => e
          puts "draw ERROR: #{e.class} - #{e.message}"
        end

        # ==========================================================
        # LED LIGHT EFFECT (visual simulation inside SketchUp)
        # ==========================================================
        def light_effect_enabled?
          settings = @light_settings || load_light_defaults
          settings[:enabled] == true
        rescue
          true
        end

        def hex_rgb(hex)
          text = hex.to_s.delete('#')
          text = 'FFD27A' unless text.match?(/\A[0-9a-fA-F]{6}\z/)
          [text[0, 2].to_i(16), text[2, 2].to_i(16), text[4, 2].to_i(16)]
        end

        def led_material(model, name, color, alpha)
          material = model.materials[name] || model.materials.add(name)
          material.color = Sketchup::Color.new(*color)
          material.alpha = [[alpha.to_f, 0.0].max, 1.0].min
          material
        end

        def vector_between(a, b)
          v = b - a
          Geom::Vector3d.new(v.x, v.y, v.z)
        end

        def offset_point(pt, vector, distance)
          Geom::Point3d.new(
            pt.x + vector.x * distance,
            pt.y + vector.y * distance,
            pt.z + vector.z * distance
          )
        end

        def add_colored_face(entities, points, material)
          face = safe_add_face(entities, points)
          return nil unless face && face.valid?
          face.material = material
          face.back_material = material
          face.edges.each do |edge|
            edge.hidden = true
            edge.soft = true if edge.respond_to?(:soft=)
            edge.smooth = true if edge.respond_to?(:smooth=)
          end
          face
        rescue
          nil
        end

        def expanded_rectangle(points, long_axis, width_axis, normal, drop, expand_long, expand_width)
          center = Geom::Point3d.new(
            points.sum(&:x) / 4.0,
            points.sum(&:y) / 4.0,
            points.sum(&:z) / 4.0
          )
          dropped_center = offset_point(center, normal, drop)

          long_half = [points[0].distance(points[1]), points[2].distance(points[3])].max / 2.0 + expand_long
          width_half = [points[1].distance(points[2]), points[3].distance(points[0])].max / 2.0 + expand_width

          [
            dropped_center.offset(long_axis, -long_half).offset(width_axis, -width_half),
            dropped_center.offset(long_axis,  long_half).offset(width_axis, -width_half),
            dropped_center.offset(long_axis,  long_half).offset(width_axis,  width_half),
            dropped_center.offset(long_axis, -long_half).offset(width_axis,  width_half)
          ]
        end

        def create_light_effect(entities, groove_points, face_normal)
          return unless light_effect_enabled?
          return unless entities && groove_points && groove_points.length == 4

          settings = @light_settings || load_light_defaults
          intensity = [[settings[:intensity].to_i, 10].max, 100].min
          light_length_cm = [[settings[:length_cm].to_f, 5.0].max, 100.0].min
          rgb = hex_rgb(settings[:color])
          model = Sketchup.active_model

          normal = Geom::Vector3d.new(face_normal.x, face_normal.y, face_normal.z)
          return if normal.length < 1e-9
          normal.normalize!

          long_axis = vector_between(groove_points[0], groove_points[1])
          width_axis = vector_between(groove_points[0], groove_points[3])
          return if long_axis.length < 0.1.mm || width_axis.length < 0.1.mm
          long_axis.normalize!
          width_axis.normalize!

          group = entities.add_group
          group.name = 'MHDESIGN_LED_LIGHT_EFFECT'
          group.set_attribute(DICT, 'effect_type', 'led_visual_light')
          group.set_attribute(DICT, 'intensity', intensity)
          group.set_attribute(DICT, 'color', settings[:color].to_s)
          group.set_attribute(DICT, 'segment_count', 64)
          group.set_attribute(DICT, 'light_length_cm', light_length_cm)
          group.set_attribute(DICT, 'source_groove_points', groove_points.flat_map { |pt| [pt.x.to_f, pt.y.to_f, pt.z.to_f] })
          group.set_attribute(DICT, 'source_face_normal', [normal.x.to_f, normal.y.to_f, normal.z.to_f])
          group.hidden = !settings[:enabled]
          gents = group.entities

          # LED source: one perfectly straight edge with no face and no physical thickness.
          # It sits at the centre of the groove opening, fractionally outside the cut face.
          strip_offset = 0.35.mm
          strip_pts = groove_points.map { |pt| offset_point(pt, normal, strip_offset) }
          led_start = Geom.linear_combination(0.5, strip_pts[0], 0.5, strip_pts[3])
          led_end   = Geom.linear_combination(0.5, strip_pts[1], 0.5, strip_pts[2])
          strip_mat = led_material(model, "MHDESIGN_LED_STRIP_#{settings[:color]}", rgb, 1.0)
          led_edge = gents.add_line(led_start, led_end)
          if led_edge && led_edge.valid?
            led_edge.material = strip_mat if led_edge.respond_to?(:material=)
            led_edge.set_attribute(DICT, 'effect_part', 'led_source_line')
          end

          # Straight light curtain: constant width and length from top to bottom.
          # There is deliberately no cone, widening, tapering, or end cap.
          segment_count = 64
          max_drop      = light_length_cm.cm

          # At 100% the light starts extremely strong beside the cabinet.
          # Lower intensity values still scale naturally from the same curve.
          intensity_ratio = intensity / 100.0
          start_alpha = 0.14 + (intensity_ratio ** 0.72) * 0.84
          start_alpha = [start_alpha, 0.98].min

          previous_pts = strip_pts

          1.upto(segment_count) do |segment|
            t = segment.to_f / segment_count.to_f

            # Keep the exact same rectangle for the whole drop.
            # Only its position changes, so the glow is perfectly straight.
            current_pts = groove_points.map do |pt|
              offset_point(pt, normal, strip_offset + (max_drop * t))
            end

            # Hold the strongest light close to the unit, then fade smoothly.
            # The last segment reaches true zero transparency.
            hold = 0.10
            if t <= hold
              fade = 1.0
            else
              u = (t - hold) / (1.0 - hold)
              smooth = u * u * (3.0 - 2.0 * u)
              fade = (1.0 - smooth) ** 1.35
            end

            alpha = start_alpha * fade
            alpha = 0.0 if segment == segment_count

            mat = led_material(
              model,
              "MHDESIGN_LED_STRAIGHT_GLOW_#{settings[:color]}_#{segment}",
              rgb,
              alpha
            )

            light_faces = []
            light_faces << add_colored_face(gents, [previous_pts[0], previous_pts[1], current_pts[1], current_pts[0]], mat)
            light_faces << add_colored_face(gents, [previous_pts[1], previous_pts[2], current_pts[2], current_pts[1]], mat)
            light_faces << add_colored_face(gents, [previous_pts[2], previous_pts[3], current_pts[3], current_pts[2]], mat)
            light_faces << add_colored_face(gents, [previous_pts[3], previous_pts[0], current_pts[0], current_pts[3]], mat)
            light_faces.compact.each do |face|
              face.set_attribute(DICT, 'light_segment', segment)
              face.set_attribute(DICT, 'light_fade', fade)
            end

            previous_pts = current_pts
          end

          # No bottom face is created, so the fade cannot finish as a visible box.

          # Store a clean tag/layer when possible, without failing older SketchUp versions.
          begin
            tag = model.layers['MHDESIGN LED LIGHT'] || model.layers.add('MHDESIGN LED LIGHT')
            group.layer = tag
          rescue
          end

          group
        rescue => e
          puts "create_light_effect ERROR: #{e.class} - #{e.message}"
          nil
        end

        # ==========================================================
        # CUT 1 = original V1 logic
        # ==========================================================
        def perform_cut_world
          return unless @settings && @face && @ents && @start_w

          end_margin_w = @settings[0].to_f.cm
          inset_w      = @settings[1].to_f.cm
          groove_w_w   = @settings[2].to_f.cm
          depth_w      = @settings[3].to_f.cm

          verts_w = @face.outer_loop.vertices.map { |v| v.position.transform(@tr) }

          axis = (@axis_mode == :long) ? @axis_long_w : @axis_short_w
          perp = (@axis_mode == :long) ? @axis_short_w : @axis_long_w

          a_vals = verts_w.map { |pt| coord_world(pt, axis) }
          a_min, a_max = a_vals.minmax
          full_len = (a_max - a_min).abs
          end_margin_w = 0.0 if full_len - (2.0 * end_margin_w) < 2.mm
          a_min += end_margin_w
          a_max -= end_margin_w

          b_vals = verts_w.map { |pt| coord_world(pt, perp) }
          b_min, b_max = b_vals.minmax
          full_w = (b_max - b_min).abs
          groove_w_w = [groove_w_w, full_w - 2.mm].min
          groove_w_w = 1.mm if groove_w_w < 1.mm

          pick_b = coord_world(@start_w, perp)
          dist_to_min = (pick_b - b_min).abs
          dist_to_max = (b_max - pick_b).abs
          boundary = (dist_to_min <= dist_to_max) ? b_min : b_max

          cx = cy = cz = 0.0
          verts_w.each { |p| cx += p.x; cy += p.y; cz += p.z }
          center_w = Geom::Point3d.new(cx / verts_w.length, cy / verts_w.length, cz / verts_w.length)
          center_b = coord_world(center_w, perp)
          inward_sign = (center_b >= boundary) ? +1.0 : -1.0

          available =
            if inward_sign > 0
              (b_max - boundary) - groove_w_w - EPS
            else
              (boundary - b_min) - groove_w_w - EPS
            end
          available = 0.0 if available < 0.0

          inset = inset_w
          inset = 0.0 if inset < 0.0
          inset = available if inset > available

          b1 = boundary + inward_sign * inset
          b2 = b1 + inward_sign * groove_w_w

          pw = lambda do |t, s|
            Geom::Point3d.new(
              @origin_w.x + axis.x * t + perp.x * s,
              @origin_w.y + axis.y * t + perp.y * s,
              @origin_w.z + axis.z * t + perp.z * s
            )
          end

          p1_w = pw.call(a_min, b1)
          p2_w = pw.call(a_max, b1)
          p3_w = pw.call(a_max, b2)
          p4_w = pw.call(a_min, b2)

          p1 = p1_w.transform(@inv)
          p2 = p2_w.transform(@inv)
          p3 = p3_w.transform(@inv)
          p4 = p4_w.transform(@inv)

          n_local = @face.normal
          n_local_u = Geom::Vector3d.new(n_local.x, n_local.y, n_local.z)
          n_local_u.normalize!
          n_w_vec = n_local_u.transform(@tr)
          s_n = n_w_vec.length
          s_n = 1.0 if s_n < 1e-9
          depth_local = depth_w / s_n

          model = Sketchup.active_model
          model.start_operation(MHDESIGN_LED_LANG.key("LED_OPERATION_DEFAULT", "MHDESIGN - حفر LED"), true)

          original_normal = @face.normal
          groove_face = @ents.add_face(p1, p2, p3, p4)
          if groove_face && groove_face.valid?
            begin
              groove_face.pushpull(-depth_local)
            rescue
              groove_face.reverse!
              groove_face.pushpull(-depth_local)
            end
          end

          create_light_effect(@ents, [p1, p2, p3, p4], original_normal)
          model.commit_operation
        rescue => e
          Sketchup.active_model.abort_operation rescue nil
          MHDESIGN_LED_LANG.messagebox("#{MHDESIGN_LED_LANG.key("LED_CUT_ERROR", "خطأ أثناء القطع")}:\n#{e.class}\n#{e.message}")
          puts "perform_cut_world ERROR: #{e.class} - #{e.message}"
        end

        # ==========================================================
        # CUT 2 = V3 logic for special units only
        # ==========================================================
        def perform_cut_local
          return unless @settings && @face && @ents && @start_l

          end_margin = @settings[0].to_f.cm
          inset      = @settings[1].to_f.cm
          groove_w   = @settings[2].to_f.cm
          depth      = @settings[3].to_f.cm

          u_min, u_max, v_min, v_max = face_bounds_uv

          start_u = coord_local(@start_l, @axis_u_l)
          start_v = coord_local(@start_l, @axis_v_l)

          if @drag_mode == :u
            run_min = u_min
            run_max = u_max
            side_min = v_min
            side_max = v_max
            pick_side = start_v
          else
            run_min = v_min
            run_max = v_max
            side_min = u_min
            side_max = u_max
            pick_side = start_u
          end

          full_len = (run_max - run_min).abs
          end_margin = 0.0 if full_len - (2.0 * end_margin) < 2.mm
          a1 = run_min + end_margin
          a2 = run_max - end_margin

          full_width = (side_max - side_min).abs
          groove_w = [groove_w, full_width - 2.mm].min
          groove_w = 1.mm if groove_w < 1.mm

          dist_to_min = (pick_side - side_min).abs
          dist_to_max = (side_max - pick_side).abs
          boundary = (dist_to_min <= dist_to_max) ? side_min : side_max

          face_center = @face.bounds.center
          center_u = coord_local(face_center, @axis_u_l)
          center_v = coord_local(face_center, @axis_v_l)
          center_side = (@drag_mode == :u) ? center_v : center_u

          inward_sign = (center_side >= boundary) ? +1.0 : -1.0

          available =
            if inward_sign > 0
              (side_max - boundary) - groove_w - EPS
            else
              (boundary - side_min) - groove_w - EPS
            end
          available = 0.0 if available < 0.0

          inset = 0.0 if inset < 0.0
          inset = available if inset > available

          b1 = boundary + inward_sign * inset
          b2 = b1 + inward_sign * groove_w

          if @drag_mode == :u
            p1 = point_from_uv(a1, b1)
            p2 = point_from_uv(a2, b1)
            p3 = point_from_uv(a2, b2)
            p4 = point_from_uv(a1, b2)
          else
            p1 = point_from_uv(b1, a1)
            p2 = point_from_uv(b2, a1)
            p3 = point_from_uv(b2, a2)
            p4 = point_from_uv(b1, a2)
          end

          pts = [p1, p2, p3, p4]

          if points_too_close?(pts)
            MHDESIGN_LED_LANG.messagebox(MHDESIGN_LED_LANG.key("LED_INVALID_DIMENSIONS", "تعذر إنشاء الحفرة: أبعاد الحفر صغيرة جدًا أو النقاط متداخلة."))
            return
          end

          unless safe_inside_face?(pts)
            MHDESIGN_LED_LANG.messagebox(MHDESIGN_LED_LANG.key("LED_OUTSIDE_FACE", "تعذر إنشاء الحفرة: الحفرة خرجت خارج حدود سطح القطعة. جرّب تقليل العرض أو البداية."))
            return
          end

          model = Sketchup.active_model
          model.start_operation(MHDESIGN_LED_LANG.key("LED_OPERATION_SPECIAL", "MHDESIGN - حفر LED للوحدات الخاصة"), true)

          original_normal = @face.normal
          groove_face = safe_add_face(@ents, pts)

          unless groove_face && groove_face.valid?
            raise ArgumentError, "Failed to create groove face"
          end

          begin
            groove_face.pushpull(-depth)
          rescue
            groove_face.reverse!
            groove_face.pushpull(-depth)
          end

          create_light_effect(@ents, pts, original_normal)
          model.commit_operation
        rescue => e
          Sketchup.active_model.abort_operation rescue nil
          MHDESIGN_LED_LANG.messagebox("#{MHDESIGN_LED_LANG.key("LED_CUT_ERROR", "خطأ أثناء القطع")}:\n#{e.class}\n#{e.message}")
          puts "perform_cut_local ERROR: #{e.class} - #{e.message}"
        end
      end

    end
  end

end