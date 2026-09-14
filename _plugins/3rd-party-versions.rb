# frozen_string_literal: true

# Expand the `{{version}}` placeholders in `third_party_libraries.*.url`, which
# the theme emits verbatim. Replaces the `jekyll-3rd-party-libraries` gem, dropped
# because its `css_parser < 2.0` pin made GHSA-9pmc-p236-855h unpatchable. That
# gem's `download: true` mode is not reimplemented; libraries stay on the CDN.

module ThirdPartyLibraryVersions
  PLACEHOLDER = "{{version}}"

  # `url` is usually flat, but highlightjs nests `url.css.light` / `url.css.dark`.
  def self.expand!(node, version)
    case node
    when Hash then node.each { |key, value| node[key] = expand!(value, version) }
    when String then node.gsub(PLACEHOLDER, version)
    else node
    end
  end

  def self.placeholder?(node)
    case node
    when Hash then node.each_value.any? { |value| placeholder?(value) }
    when String then node.include?(PLACEHOLDER)
    else false
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  libraries = site.config["third_party_libraries"]
  next unless libraries.is_a?(Hash)

  libraries.each do |name, library|
    next unless library.is_a?(Hash)

    urls = library["url"]
    next unless urls.is_a?(Hash)
    next unless ThirdPartyLibraryVersions.placeholder?(urls)

    version = library["version"].to_s
    if version.empty?
      Jekyll.logger.warn "3rd party libraries:", "`#{name}` has no `version`; leaving its URLs unexpanded"
      next
    end

    ThirdPartyLibraryVersions.expand!(urls, version)
  end
end
