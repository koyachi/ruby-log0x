# -*- coding: utf-8 -*-
module Log0x
  module CLI
    class << self
      def run(argv)
        opt = parse_argv argv
        if opt['workers'] == nil or opt['workers'].length == 0
          abort help
        end
        Log0x.run opt
      end

      def parse_argv(argv)
        options = {}
        opts = OptionParser.new do |opts|
          opts.version = Log0x::VERSION
          opts.banner = "Usage: workerstarter [] [arguments]"

          opts.on('-f', '--file config_file', 'config file path') do |config_file|
            config = YAML.load_file config_file
            options.merge! config
          end

          # 個別オプション...
        end
        begin
          opts.parse! argv
        rescue OptionParser::InvalidOption => e
          abort e.message
        end
        options
      end

      def help
        help = <<HELP
USAGE

  $ ruby worker_starter.rb /path/to/your/config.yaml

CONFIG SAMPLE

#-- config.yaml --
worker_process:
  - name: foo
    cmd: 'echo "hello"'
    num: 2
  - name: foo
    cmd: 'echo "hello 2"'
    num: 3
  - name: foo
    cmd: 'ruby -e "loop {p \"loop!\"; sleep 2}"'
    num: 3

HELP
      end
    end
  end
end
