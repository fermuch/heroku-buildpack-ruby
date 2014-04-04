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
      curl = curl_command("-O #{@host_url.join(path)}")
      run!(curl)
    end

    def fetch_untar(path)
      base_path = File.basename(path)
      if cache and cache.exists? base_path
        puts "== fetch_untar cache-hit: #{path} --> #{base_path}"
        cache.load base_path
      else
        puts "== fetch_untar cache-miss: #{path} --> #{base_path}"
        curl = curl_command("#{@host_url.join(path)} -s -o")
        run!("#{curl} #{base_path}")
        puts "== PWD: #{Dir.pwd}"
        puts Dir['./*'].join("\n")
        cache.store base_path if cache
      end
      run!("cat #{base_path} | tar zxf -")
      FileUtils.rm_rf(base_path)
    end

    def fetch_bunzip2(path)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      run!("#{curl} - | tar jxf -")
    end

    private
    attr_reader :cache

    def curl_command(command)
      "set -o pipefail; curl --fail --retry 3 --retry-delay 1 --connect-timeout 3 --max-time #{curl_timeout_in_seconds} #{command}"
    end

    def curl_timeout_in_seconds
      ENV['CURL_TIMEOUT'] || 30
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
