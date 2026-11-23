# discourse-upload-content-filter

A Discourse plugin that blocks uploaded files where the content match regular expressions.

Requires Discourse 3.5.0 or later.

## Docker Installation

Add the plugin to your `containers/app.yml`, following the [standard plugin install guide](https://meta.discourse.org/t/install-plugins-on-a-self-hosted-site/19157):

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/notSafeForDev/discourse-upload-content-filter.git
```

Then rebuild the container:

```bash
cd /var/discourse
./launcher rebuild app
```

## Configuration

Under **Admin > Settings**, search for `upload content filter`:

| Setting | Description |
|---|---|
| `upload content filter enabled` | Turns the filter on. |
| `upload content filter rules` | The rules (see below). |
| `upload content filter max file size` | Files with a matching extension that are larger than this are rejected. Default 10 MB. |
| `upload content filter timeout` | How long, in milliseconds, each regex may take to evaluate. Default 1000 (one second). |

Rule:

| Field | Description |
|---|---|
| `extension` | The file extension the rule applies to, e.g. `json`. Case-insensitive, and a leading dot is ignored. |
| `regex` | A [regular expression](https://docs.ruby-lang.org/en/master/Regexp.html) searched for anywhere in the file's contents. |
| `message` | Optional error shown to the uploader. If empty, a generic message is used. |

Note: the file's extension must also be listed in the `authorized extensions` setting.

### Notes

- Only files where the extension matches a rule are read. All other uploads are unaffected.
- Content is read as UTF-8 text, so the filter is meant for text-based formats such as JSON.
- A pattern that takes longer than the timeout to evaluate rejects the upload, rather than letting it through unchecked.
- A rule with an invalid regex rejects uploads of its extension until the regex is fixed.

## Development

Run the specs from a Discourse development checkout with this plugin in its `plugins` folder:

```bash
LOAD_PLUGINS=1 bin/rspec plugins/discourse-upload-content-filter/spec
```

## License

MIT
