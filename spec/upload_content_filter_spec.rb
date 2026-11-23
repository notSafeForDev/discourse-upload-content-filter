# frozen_string_literal: true

RSpec.describe UploadCreator do
  fab!(:user)

  before do
    SiteSetting.upload_content_filter_enabled = true
    SiteSetting.authorized_extensions = "funscript|txt"
    SiteSetting.upload_content_filter_rules = [
      { "extension" => "funscript", "regex" => "(?i)fungen", "message" => "Not allowed." },
    ].to_json
  end

  def upload(content, filename: "script.funscript")
    file = Tempfile.new(["upload", File.extname(filename)])
    file.write(content)
    file.rewind
    UploadCreator.new(file, filename).create_for(user.id)
  end

  it "blocks files whose contents match the regex" do
    expect(upload("made with FunGen").errors.full_messages).to contain_exactly("Not allowed.")
  end

  it "allows files that don't match" do
    expect(upload("made by hand")).to be_persisted
  end

  it "only checks files with the rule's extension" do
    expect(upload("made with FunGen", filename: "notes.txt")).to be_persisted
  end

  it "ignores letter case and a leading dot in the rule's extension" do
    SiteSetting.upload_content_filter_rules = [
      { "extension" => ".FunScript", "regex" => "fungen" },
    ].to_json

    expect(upload("fungen", filename: "SCRIPT.FUNSCRIPT")).not_to be_persisted
  end

  it "shows a generic message when the rule has none" do
    SiteSetting.upload_content_filter_rules = [
      { "extension" => "funscript", "regex" => "fungen" },
    ].to_json

    expect(upload("fungen").errors.full_messages).to contain_exactly(
      I18n.t("upload_content_filter.blocked"),
    )
  end

  it "rejects the file when the regex is invalid" do
    SiteSetting.upload_content_filter_rules = [
      { "extension" => "funscript", "regex" => "(unclosed" },
    ].to_json

    expect(upload("anything").errors.full_messages).to contain_exactly(
      I18n.t("upload_content_filter.validation_failed"),
    )
  end

  it "rejects the file when the regex takes too long" do
    SiteSetting.upload_content_filter_timeout = 1
    # The backreference stops Ruby's regex cache from making this pattern fast.
    SiteSetting.upload_content_filter_rules = [
      { "extension" => "funscript", "regex" => '^(a+)+\1$' },
    ].to_json

    expect(upload("a" * 50 + "b").errors.full_messages).to contain_exactly(
      I18n.t("upload_content_filter.validation_failed"),
    )
  end

  it "rejects files that are too large to validate" do
    SiteSetting.upload_content_filter_max_file_size = 1

    expect(upload("a" * 2.kilobytes).errors.full_messages).to contain_exactly(
      I18n.t("upload_content_filter.too_large_to_validate"),
    )
  end

  it "does nothing when the plugin is disabled" do
    SiteSetting.upload_content_filter_enabled = false

    expect(upload("made with FunGen")).to be_persisted
  end
end
