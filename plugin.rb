# frozen_string_literal: true

# name: discourse-upload-content-filter
# about: Blocks uploads whose file contents match admin-defined regex rules
# version: 0.1.0
# authors: notSafeForDev
# url: https://github.com/notSafeForDev/discourse-upload-content-filter
# required_version: 3.5.0

enabled_site_setting :upload_content_filter_enabled

after_initialize do
  on(:before_upload_creation) do |file, _is_image, upload, validate|
    next if validate == false

    extension_string = File.extname(upload.original_filename.to_s).delete_prefix(".").downcase
    rules_array = JSON.parse(SiteSetting.upload_content_filter_rules.presence || "[]")
    rules_array.each do |rule_hash|
      rule_hash["extension"] = rule_hash["extension"].delete_prefix(".").downcase
    end
    matching_rules_array =
      rules_array.select { |rule_hash| rule_hash["extension"] == extension_string }
    next if matching_rules_array.empty?

    max_bytes_integer = SiteSetting.upload_content_filter_max_file_size.kilobytes
    if File.size(file.path) > max_bytes_integer
      upload.errors.add(:base, I18n.t("upload_content_filter.too_large_to_validate"))
      next
    end

    file_content_string = File.binread(file.path).force_encoding(Encoding::UTF_8).scrub
    timeout_seconds_float = SiteSetting.upload_content_filter_timeout / 1000.0

    matching_rules_array.each do |rule_hash|
      regex = Regexp.new(rule_hash["regex"], timeout: timeout_seconds_float)
      next if !regex.match?(file_content_string)

      message_string = rule_hash["message"].presence || I18n.t("upload_content_filter.blocked")
      upload.errors.add(:base, message_string)
      break
    end
  rescue RegexpError, Regexp::TimeoutError
    upload.errors.add(:base, I18n.t("upload_content_filter.validation_failed"))
  end
end
