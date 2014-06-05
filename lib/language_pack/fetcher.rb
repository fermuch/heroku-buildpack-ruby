require "yaml"
require "language_pack/shell_helpers"

module LanguagePack
  class Fetcher
    include ShellHelpers
    CDN_YAML_FILE = File.expand_path("../../../config/cdn.yml", __FILE__)

    def initialize(host_url, cache = nil)
      @cache    = cache
      @config   = load_config
      @host_url = fetch_cdn(host_url)
    end

    def fetch(path)
      base_path = File.basename(path)
      cache base_path do
        curl = curl_command("-O #{@host_url.join(path)}")
        run!(curl)
      end
    end

    def fetch_untar(path)
      base_path = File.basename(path)
      fetch(path)
      run!("cat #{base_path} | tar zxf -")
      FileUtils.rm_rf(base_path)
    end

    def fetch_bunzip2(path)
      base_path = File.basename(path)
      fetch(path)
      run!("cat #{base_path} | tar jxf -")
      FileUtils.rm_rf(base_path)
    end

    private

    def cache base_path
      cache = @cache
      if cache and cache.exists? base_path
        puts "== fetch_untar cache-hit: #{base_path}"
        cache.load base_path
      else
        puts "== fetch_untar cache-miss: #{base_path}" if cache
        yield
        cache.store base_path if cache
      end
    end

    def curl_command(command)
      "set -o pipefail; curl --fail --retry 3 --retry-delay 1 --connect-timeout 3 --max-time #{curl_timeout_in_seconds} #{command}"
    end

    def curl_timeout_in_seconds
      ENV['CURL_TIMEOUT'] || 150
    end

    def load_config
      YAML.load_file(CDN_YAML_FILE) || {}
    end

    def fetch_cdn(url)
      url = @config[url] || url
      Pathname.new(url)
    end
  end
end
