# -*- encoding : utf-8 -*-

module Phrase::Tool::Formats
  autoload :Base, 'phrase/tool/formats/base'
  autoload :Yaml, 'phrase/tool/formats/yaml'
  autoload :Gettext, 'phrase/tool/formats/gettext'
  autoload :GettextPot, 'phrase/tool/formats/gettext_pot'
  autoload :Xml, 'phrase/tool/formats/xml'
  autoload :Strings, 'phrase/tool/formats/strings'
  autoload :Xliff, 'phrase/tool/formats/xliff'
  autoload :QtPhraseBook, 'phrase/tool/formats/qt_phrase_book'
  autoload :QtTranslationSource, 'phrase/tool/formats/qt_translation_source'
  autoload :Json, 'phrase/tool/formats/json'
  autoload :Resx, 'phrase/tool/formats/resx'
  autoload :Ini, 'phrase/tool/formats/ini'
  autoload :Properties, 'phrase/tool/formats/properties'
  autoload :Plist, 'phrase/tool/formats/plist'
  autoload :Custom, 'phrase/tool/formats/custom'
  
  SUPPORTED_FORMATS = {
    custom: Phrase::Tool::Formats::Custom,
    yml: Phrase::Tool::Formats::Yaml,
    po: Phrase::Tool::Formats::Gettext,
    pot: Phrase::Tool::Formats::GettextPot,
    xml: Phrase::Tool::Formats::Xml,
    strings: Phrase::Tool::Formats::Strings,
    xlf: Phrase::Tool::Formats::Xliff,
    qph: Phrase::Tool::Formats::QtPhraseBook,
    ts: Phrase::Tool::Formats::QtTranslationSource,
    json: Phrase::Tool::Formats::Json,
    resx: Phrase::Tool::Formats::Resx,
    ini: Phrase::Tool::Formats::Ini,
    properties: Phrase::Tool::Formats::Properties,
    plist: Phrase::Tool::Formats::Plist,
  }

  def self.config
    @config ||= get_config
  end

  def self.get_config
    config = Phrase::Tool::Config.new
    config.load
  end

  def self.custom_handler
    handler_class_for_format(:custom)
  end

  def self.target_directory(format_name)
    handler = handler_class_for_format(format_name)
    custom_handler.target_directory || handler.target_directory
  end
  
  def self.directory_for_locale_in_format(locale, format_name)
    handler = handler_class_for_format(format_name)
    custom_directory = custom_handler.directory_for_locale(locale, format_name)
    custom_directory || handler.directory_for_locale(locale)
  end
  
  def self.filename_for_locale_in_format(locale, format_name)
    handler = handler_class_for_format(format_name)
    custom_filename = custom_handler.filename_for_locale(locale, format_name)
    custom_filename || handler.filename_for_locale(locale)
  end
  
  def self.file_format_exposes_locale?(file_path)
    format = guess_possible_file_format_from_file_path(file_path)
    format.nil? ? false : handler_class_for_format(format).locale_aware?
  end
  
  def self.detect_locale_name_from_file_path(file_path)
    format = guess_possible_file_format_from_file_path(file_path)
    format.nil? ? nil : handler_class_for_format(format).extract_locale_name_from_file_path(file_path)
  end
  
  def self.handler_class_for_format(format_name)
    SUPPORTED_FORMATS.fetch(format_name.to_sym)
  end
  private_class_method :handler_class_for_format
  
  def self.guess_possible_file_format_from_file_path(file_path)
    extension = file_path.split('.').last.downcase
    return SUPPORTED_FORMATS.has_key?(extension.to_sym) ? extension.to_sym : nil
  end
  private_class_method :guess_possible_file_format_from_file_path
end
