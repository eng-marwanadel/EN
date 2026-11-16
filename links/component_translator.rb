# encoding: UTF-8
# MHDESIGN Component & Material Translator v5.0
# يترجم أسماء الـ Definitions والخامات حتى مع اختلاف المسافات
# ويحافظ على الأقواس وأرقام # والمقاسات الموجودة داخل أسماء الخامات.

require 'sketchup.rb'
require File.join(__dir__, 'MHDESIGN_Language') unless defined?(MHDESIGN::Language) && MHDESIGN::Language.respond_to?(:for_tool)
require 'json'
require 'open-uri'
require 'fileutils'
require 'tmpdir'

module MHDESIGN
  module ComponentTranslator
    extend self

    VERSION = '5.0.0'

    DICT = 'MHDESIGN_DEFINITION_TRANSLATION'
    ORIGINAL_DEFINITION_NAME = 'original_definition_name'
    ORIGINAL_MATERIAL_NAME   = 'original_material_name'
    LAST_DEFINITION_TRANSLATION = 'last_definition_translation'


    def current_language
      if defined?(MHDESIGN::Language)
        MHDESIGN::Language.current.to_s
      else
        Sketchup.read_default('MHDESIGN', 'language_code', 'ar_EG').to_s
      end
    rescue
      'ar_EG'
    end

    # توحيد الكتابة قبل المطابقة:
    # - الهمزات والتاء المربوطة والألف المقصورة
    # - المسافات المكررة
    # - إضافة مسافة تلقائياً بين الأرقام والكلمات
    # لذلك: الدرج2يمين = الدرج 2 يمين
    def normalize(value)
      text = value.to_s
                  .encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
                  .strip
                  .downcase
                  .gsub(/[أإآ]/, 'ا')
                  .gsub('ة', 'ه')
                  .gsub('ى', 'ي')
                  .gsub(/[ـ]/, '')
                  .gsub(/[\u200E\u200F\u202A-\u202E]/, '')

      text = text.gsub(/([0-9])(?=[\p{Arabic}])/, '\1 ')
      text = text.gsub(/([\p{Arabic}])(?=[0-9])/, '\1 ')
      text = text.gsub(/([a-z])(?=[\p{Arabic}])|([\p{Arabic}])(?=[a-z])/, '\1\2 ')
      text = text.gsub(/\s+/, ' ').strip

      # توحيد أشهر اختلافات أسماء الوحدات القديمة والجديدة.
      text = text.gsub(/شاسيه\s+ال?درج/, 'شاسيه درج')
      text = text.gsub(/شاسه\s+ال?درج/, 'شاسيه درج')
      text = text.gsub(/حرف\s+ال\s+(?=سفلي|علوي)/, 'حرف ل ')
      text.strip
    rescue
      value.to_s.strip.downcase
    end

    def cache_path(code)
      FileUtils.mkdir_p(CACHE_DIR)
      File.join(CACHE_DIR, "#{code}.json")
    end

    def fetch_dictionary(code)
      MHDESIGN::Language.for_tool('component_translator').load_dictionary(code)
    end

    def dictionary(force = false)
      code = current_language

      if force || @loaded_code != code || !@dictionary.is_a?(Hash)
        @loaded_code = code
        @dictionary = fetch_dictionary(code)
        @normalized_names = nil
        @normalized_materials = nil
      end

      @dictionary || {}
    end

    def ui(key, fallback)
      value = (dictionary['ui'] || {})[key.to_s]
      value.to_s.strip.empty? ? fallback.to_s : value.to_s
    rescue
      fallback.to_s
    end

    def definition_names
      data = dictionary['definition_names']
      data.is_a?(Hash) ? data : {}
    rescue
      {}
    end

    def materials
      data = dictionary['materials']
      data.is_a?(Hash) ? data : {}
    rescue
      {}
    end

    def normalized_definition_names
      return @normalized_names if @normalized_names.is_a?(Hash)

      @normalized_names = {}
      definition_names.each do |source, target|
        @normalized_names[normalize(source)] = target.to_s
      end
      @normalized_names
    end

    def normalized_materials
      return @normalized_materials if @normalized_materials.is_a?(Hash)

      @normalized_materials = {}
      materials.each do |source, target|
        @normalized_materials[normalize(source)] = target.to_s
      end
      @normalized_materials
    end

    # يفصل اسم القطعة عن أرقام النسخ الموجودة بين أقواس، سواء ظهرت أول الاسم أو آخره.
    def split_name(full_name)
      text = full_name.to_s.strip
      return ['', ''] if text.empty?

      suffixes = text.scan(/\([^)]*\)/)
      base = text.gsub(/\s*\([^)]*\)\s*/, ' ').gsub(/\s+/, ' ').strip

      hash_match = base.match(/^(.*?)(\s*#\d+\s*)$/)
      if hash_match
        base = hash_match[1].to_s.rstrip
        suffix = hash_match[2].to_s.strip
      else
        suffix = ''
      end

      parens = text.scan(/\([^)]*\)/).join(' ')
      suffix = [parens, suffix].reject { |v| v.to_s.empty? }.join(' ')
      [base, suffix]
    end

    def translate_base_name(base_name)
      source = base_name.to_s.strip
      return source if source.empty?

      exact = definition_names[source]
      return exact.to_s unless exact.nil? || exact.to_s.empty?

      normalized_source = normalize(source)
      translated = normalized_definition_names[normalized_source]
      return translated.to_s unless translated.nil? || translated.to_s.empty?

      tokens = dictionary['name_tokens'] || {}
      return source if current_language.start_with?('ar_') || tokens.empty?
      normalized = source.gsub(/[أإآ]/, 'ا').gsub('ة', 'ه').gsub('ى', 'ي').gsub('ـ', '')
      normalized = normalized.gsub(/([0-9])(?=[\p{Arabic}])/, '\\1 ').gsub(/([\p{Arabic}])(?=[0-9])/, '\\1 ')
      pairs = tokens.each_with_object({}) { |(key, value), out| out[normalize(key)] = value }
      pattern = Regexp.new('(?<![\\p{L}])(?:' + pairs.keys.sort_by { |key| -key.length }.map { |key| Regexp.escape(key) }.join('|') + ')(?![\\p{L}])', Regexp::IGNORECASE)
      translated = normalized.gsub(pattern) { |match| pairs[normalize(match)] }
      # Do not guess when an unknown Arabic term remains.
      translated.match?(/[\p{Arabic}]/) ? source : translated
    rescue
      base_name.to_s
    end

    def translated_full_name(original_name)
      parts = original_name.to_s.split(/(\([^)]*\)|#\d+\s*$)/, -1)
      parts.each_with_index.map do |part, index|
        next part if index.odd?
        core = part.strip
        next part if core.empty?
        part.sub(core, translate_base_name(core))
      end.join
    rescue
      original_name.to_s
    end
    # يستخرج الجزء النصي من اسم خامة مركب مثل:
    # 5.0 / مقبض ليت ان حرف ال سفلي cm x 2.0 cm
    # ويعيد: مقبض ليت ان حرف ال سفلي
    def material_text_core(value)
      text = value.to_s.dup
      text.gsub!(/\b(?:cm|mm|m)\b/i, ' ')
      text.gsub!(/\d+(?:[\.,]\d+)?/, ' ')
      text.gsub!(/[×xX*\/\\|:;,_\-–—+()\[\]{}]/, ' ')
      text.gsub!(/[•●○◉]/, ' ')
      text.gsub!(/\s+/, ' ')
      text.strip
    rescue
      value.to_s.strip
    end

    def translated_material_name(original_name)
      source = original_name.to_s.strip
      return source if source.empty?

      # أولاً: مطابقة الاسم كاملاً
      exact = materials[source]
      return exact.to_s unless exact.nil? || exact.to_s.empty?

      translated = normalized_materials[normalize(source)]
      return translated.to_s unless translated.nil? || translated.to_s.empty?

      # ثانياً: ترجمة الجزء النصي فقط مع الإبقاء على السمك والمقاسات
      core = material_text_core(source)
      return source if core.empty?

      target = normalized_materials[normalize(core)]
      return source if target.nil? || target.to_s.empty?

      if source.include?(core)
        source.sub(core, target.to_s)
      else
        # احتياطياً لو كانت المسافات داخل الاسم مختلفة
        pattern = Regexp.new(Regexp.escape(core).gsub(' ', '\\s+'))
        source.sub(pattern, target.to_s)
      end
    rescue
      original_name.to_s
    end

    def definition_for(entity)
      if entity.is_a?(Sketchup::ComponentInstance)
        entity.definition
      elsif entity.is_a?(Sketchup::Group)
        entity.entities.parent
      end
    rescue
      nil
    end

    def child_entities(entity)
      if entity.is_a?(Sketchup::ComponentInstance)
        entity.definition.entities
      elsif entity.is_a?(Sketchup::Group)
        entity.entities
      else
        []
      end
    rescue
      []
    end

    def save_original_definition(definition)
      value = definition.get_attribute(DICT, ORIGINAL_DEFINITION_NAME, nil) rescue nil
      last = definition.get_attribute(DICT, LAST_DEFINITION_TRANSLATION, nil) rescue nil
      if value.nil? || value.to_s.empty? || (!last.nil? && last.to_s != definition.name.to_s)
        value = definition.name.to_s
        definition.set_attribute(DICT, ORIGINAL_DEFINITION_NAME, value) rescue nil
      end
      value.to_s
    end

    def translate_definition(definition)
      return 0 unless definition && definition.valid?

      original = save_original_definition(definition)
      translated = translated_full_name(original)
      return 0 if translated.to_s.empty?
      return 0 if translated.to_s == definition.name.to_s

      definition.name = translated.to_s
      definition.set_attribute(DICT, LAST_DEFINITION_TRANSLATION, definition.name.to_s)
      1
    rescue
      0
    end

    def material_used_by_dynamic_attributes?(material)
      model = Sketchup.active_model
      names = [material.name.to_s, material.get_attribute(DICT, ORIGINAL_MATERIAL_NAME, '').to_s].reject(&:empty?)
      owners = model.definitions.to_a + model.entities.to_a
      model.definitions.each { |definition| owners.concat(definition.entities.to_a) }
      owners.any? do |owner|
        attributes = owner.attribute_dictionary('dynamic_attributes', false)
        attributes && attributes.any? { |_key, value| value.is_a?(String) && names.any? { |name| value.include?(name) } }
      end
    rescue
      true
    end

    def translate_material(material)
      return 0 unless material
      # Material names may be identifiers in Dynamic Component formulas and option lists.
      return 0 if material_used_by_dynamic_attributes?(material)

      original = material.get_attribute(DICT, ORIGINAL_MATERIAL_NAME, nil) rescue nil
      if original.nil? || original.to_s.empty?
        original = material.display_name.to_s
        material.set_attribute(DICT, ORIGINAL_MATERIAL_NAME, original) rescue nil
      end

      translated = translated_material_name(original)
      return 0 if translated.to_s.empty?
      return 0 if translated.to_s == material.name.to_s

      material.name = translated.to_s
      1
    rescue
      0
    end

    def translate_one_material(material, visited_materials, stats)
      return unless material
      key = material.object_id
      return if visited_materials[key]

      visited_materials[key] = true
      stats[:materials] += translate_material(material)
    rescue
      nil
    end

    # يقرأ خامات الـ Component والـ Group والوجوه الأمامية والخلفية أيضاً
    def translate_entity_materials(entity, visited_materials, stats)
      if entity.respond_to?(:material)
        translate_one_material(entity.material, visited_materials, stats)
      end

      if entity.is_a?(Sketchup::Face)
        translate_one_material(entity.back_material, visited_materials, stats)
      end
    rescue
      nil
    end

    def walk(entities, visited_definitions, visited_materials, stats)
      entities.each do |entity|
        next unless entity.valid?

        translate_entity_materials(entity, visited_materials, stats)

        next unless entity.is_a?(Sketchup::ComponentInstance) ||
                    entity.is_a?(Sketchup::Group)

        definition = definition_for(entity)
        next unless definition && !visited_definitions[definition.object_id]

        visited_definitions[definition.object_id] = true
        stats[:definitions] += translate_definition(definition)
        walk(child_entities(entity), visited_definitions, visited_materials, stats)
      end
    rescue
      nil
    end

    def selected_roots
      Sketchup.active_model.selection.to_a.select do |entity|
        entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
      end
    rescue
      []
    end

    def model_roots
      Sketchup.active_model.entities.to_a.select do |entity|
        entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
      end
    rescue
      []
    end

    def process(roots, mode = :translate)
      return restore(roots) if mode == :restore

      if roots.empty?
        UI.messagebox(ui('select_first', 'حدد الوحدات أولاً.'))
        return
      end

      confirm = ui(
        'confirm',
        'سيتم ترجمة أسماء القطع والخامات المعروفة مع الحفاظ على الأقواس والأرقام والمقاسات. هل تريد المتابعة؟'
      )
      return unless UI.messagebox(confirm, MB_YESNO) == IDYES

      dictionary(true)
      if definition_names.empty?
        UI.messagebox(ui('dictionary_missing', 'تعذر تحميل قاموس الترجمة.'))
        return
      end

      model = Sketchup.active_model
      model.start_operation(ui('operation', 'MHDESIGN - ترجمة أسماء القطع والخامات'), true)

      stats = { definitions: 0, materials: 0 }
      visited_definitions = {}
      visited_materials = {}

      roots.each do |root|
        next unless root.valid?

        translate_entity_materials(root, visited_materials, stats)
        definition = definition_for(root)
        next unless definition && !visited_definitions[definition.object_id]

        visited_definitions[definition.object_id] = true
        stats[:definitions] += translate_definition(definition)
        walk(child_entities(root), visited_definitions, visited_materials, stats)
      end

      model.commit_operation

      UI.messagebox(
        "#{ui('success', 'تمت الترجمة بنجاح.')}\n\n" \
        "#{ui('definitions_count', 'أسماء القطع')}: #{stats[:definitions]}\n" \
        "#{ui('materials_count', 'الخامات')}: #{stats[:materials]}\n" \
        "#{ui('language', 'اللغة')}: #{current_language}"
      )
    rescue => error
      model.abort_operation rescue nil
      UI.messagebox("#{ui('error', 'خطأ')}: #{error.message}")
    end

    def restore_definition(definition)
      original = definition.get_attribute(DICT, ORIGINAL_DEFINITION_NAME, nil) rescue nil
      return 0 if original.nil? || original.to_s.empty?
      return 0 if definition.name.to_s == original.to_s

      definition.name = original.to_s
      1
    rescue
      0
    end

    def restore_walk(entities, visited_definitions, stats)
      entities.each do |entity|
        next unless entity.valid?
        next unless entity.is_a?(Sketchup::ComponentInstance) ||
                    entity.is_a?(Sketchup::Group)

        definition = definition_for(entity)
        next unless definition && !visited_definitions[definition.object_id]

        visited_definitions[definition.object_id] = true
        stats[:definitions] += restore_definition(definition)
        restore_walk(child_entities(entity), visited_definitions, stats)
      end
    rescue
      nil
    end

    def restore(roots)
      if roots.empty?
        UI.messagebox(ui('select_first', 'حدد الوحدات أولاً.'))
        return
      end

      return unless UI.messagebox(
        ui('confirm_restore', 'هل تريد استرجاع أسماء القطع والخامات الأصلية؟'),
        MB_YESNO
      ) == IDYES

      model = Sketchup.active_model
      model.start_operation(ui('restore_operation', 'MHDESIGN - استرجاع الأسماء الأصلية'), true)

      stats = { definitions: 0, materials: 0 }
      visited_definitions = {}

      roots.each do |root|
        definition = definition_for(root)
        next unless definition && !visited_definitions[definition.object_id]

        visited_definitions[definition.object_id] = true
        stats[:definitions] += restore_definition(definition)
        restore_walk(child_entities(root), visited_definitions, stats)
      end

      # الخامات مشتركة على مستوى الموديل، لذلك تتم استعادتها كلها بأمان
      model.materials.each do |material|
        original = material.get_attribute(DICT, ORIGINAL_MATERIAL_NAME, nil) rescue nil
        next if original.nil? || original.to_s.empty?
        next if material.name.to_s == original.to_s

        material.name = original.to_s
        stats[:materials] += 1
      end

      model.commit_operation

      UI.messagebox(
        "#{ui('restore_success', 'تم استرجاع المسميات الأصلية.')}\n\n" \
        "#{ui('definitions_count', 'أسماء القطع')}: #{stats[:definitions]}\n" \
        "#{ui('materials_count', 'الخامات')}: #{stats[:materials]}"
      )
    rescue => error
      model.abort_operation rescue nil
      UI.messagebox("#{ui('error', 'خطأ')}: #{error.message}")
    end

    def translate_selection
      process(selected_roots, :translate)
    end

    def translate_model
      process(model_roots, :translate)
    end

    def restore_selection
      process(selected_roots, :restore)
    end

    def restore_model
      process(model_roots, :restore)
    end

    def add_menu
      return if @menu_added

      submenu = UI.menu('Extensions').add_submenu(
        ui('menu_title', 'MHDESIGN - ترجمة أسماء القطع والخامات')
      )

      submenu.add_item(ui('translate_selection', 'ترجمة الوحدات المحددة')) { translate_selection }
      submenu.add_item(ui('translate_model', 'ترجمة التصميم بالكامل')) { translate_model }
      submenu.add_separator
      submenu.add_item(ui('restore_selection', 'استرجاع المحدد')) { restore_selection }
      submenu.add_item(ui('restore_model', 'استرجاع التصميم بالكامل')) { restore_model }

      @menu_added = true
    rescue => error
      puts "MHDESIGN ComponentTranslator menu error: #{error.message}"
    end
  end
end

unless file_loaded?(__FILE__)
  MHDESIGN::ComponentTranslator.add_menu
  file_loaded(__FILE__)
end
