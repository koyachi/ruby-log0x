# -*- coding: utf-8 -*-
require 'timeout'
module Log0x
  class << self
    def protect_from_signals
      (@protect_from_signals_mutex ||= Mutex.new).synchronize do
        interrupted = false
        previous_handler = Signal.trap(:INT) {interrupted = true}
        val = yield
        Signal.trap(:INT, previous_handler)
        # ガード中に割り込み受けたらガード対象処理終わってからハンドラを起動する
        previous_handler.call if interrupted
        val
      end
    end

    def _huntsman
      Signal.trap :CHLD, 'IGNORE'
      @logger.info "log0x._huntsman #{Log0x.active.inspect}"
      pss = `ps aux | grep ruby`.split("\n").map{|l| l.split(/\s/).grep(/[^\s]/)[1].to_i}.sort
      @logger.info "RUBY PROCESSES = #{pss.inspect}"
      Log0x.active.keys.each do |pid| 
        @logger.info "pid = #{pid}"
        next unless pss.include? pid
        begin
          Process.detach pid
          result = Process.kill 'INT', pid
          child_pid = nil
          begin
            Timeout.timeout(10){ child_pid = Process.waitpid pid }
            @logger.info "Process.kill[#{pid}] result = #{result}, waitpid = #{child_pid}"
          rescue Timeout::Error
            child_pid = Process.waitpid pid, Process::WNOHANG
            Process.kill 'KILL', pid
            @logger.info "Process.kill(-KILL)[#{pid}] result = #{result}, waitpid = #{child_pid}"
          end
        rescue Errno::ECHILD => e
          @logger.warn "Errno::ECHILD(Process.kill[#{pid}]) #{e.inspect}"
        rescue Errno::ESRCH => e
          @logger.warn "Errno::ESRCH(Process.kill[#{pid}]) #{e.inspect}"
        rescue Exception => e
          @logger.warn "ERROR(Process.kill[#{pid}]) #{e.inspect}"
          Process.detach pid
          Process.kill 'KILL', pid
        end
      end
      exit
    end

    def add_worker_loadpath(path)
      $:.unshift path
    end

    attr_accessor :loaded_workers
    def load_worker_class(load_cls, process_config)
      @loaded_workers ||= {}
      return @loaded_workers[load_cls] if @loaded_workers[load_cls]
      clss = load_cls.split('::')
      filepath = (process_config.include? 'file') ? process_config['file'] : clss.map{|c| c.downcase}.join('/')
      require filepath
      root = Module
      worker_cls = clss.inject(root){|parent,child| parent.const_get child}
      @loaded_workers[load_cls] = worker_cls
      worker_cls
    end

    attr_accessor :active, :logger, :config
    def init(config)
      @logger = Logger.new(STDOUT)
#      @logger.level = Logger::WARN
      @logger.level = Logger::DEBUG
      @logger.info "start process runner: [#{$$}]"
      @active = {}
      @logger.info config
      @config = config
      config['paths'].each {|path| add_worker_loadpath path}

#      Log0x::BootLoader.add_worker_module :q4m, 'Log0x::Worker::Q4M'
#      Log0x::BootLoader.add_worker_module :gearman, 'Log0x::Worker::Gearman'

      config['workers'].each do |process|
        process['num'].times {start_process process}
      end
    end

    class RedirectLogger
      def initialize(filename)
        @logger = Logger.new filename, 'weekly'
      end

      def write(obj)
        output = (obj.to_s =~ /\n\Z/) ? obj.to_s.chomp : obj.to_s
        return if output == ''
        @logger.info output
      end

      def self.enable_log(file_id, dir='./')
        $stdout = self.new File.expand_path(File.join(dir, "log0x_stdout_#{file_id}.log"))
        $stderr = self.new File.expand_path(File.join(dir, "log0x_stderr_#{file_id}.log"))
      end
    end

    def start_process(process_config)
      starter = if process_config['class']
        worker_class = load_worker_class(process_config['class'], process_config)
        @logger.info "worker class: #{worker_class}"
        # include Log0x::Workerizeしてるか確認
        if Log0x::BootLoader.supported?(worker_class)
          lambda do
            cls = worker_class.to_s.split('::').join('-')
            RedirectLogger.enable_log cls, @config['log']
            Log0x::BootLoader.start worker_class, process_config, @config
          end
        else
          @logger.warn "#{worker_class} is not supported."
          nil
        end
      elsif process_config['cmd']
        lambda do
          RedirectLogger.enable_log process_config['cmd'].split(/\s/).join('-'), @config['log']
          exec process_config['cmd']
          exit
        end
      else
        # error?
        @logger.warn "unkown worker info(not class/cmd)"
        nil
      end

      if starter == nil
        @logger.warn "unknown worker process: #{process.inspect}"
        return
      end

      pid = protect_from_signals {fork}
      if pid
        # parent process
        @logger.info "start: [#{pid}] #{process_config['name']}"
        @active[pid] = process_config
      else
        # child process
        starter.call
      end
    end

    def run(config)
      Signal.trap(:INT) {self._huntsman}
      Signal.trap(:TERM) {self._huntsman}
      Signal.trap(:HUP) {self._huntsman}
      self.init config

      loop do
        @logger.debug "active processes: [#{@active.keys.sort.join(",")}]"
        sleep 10
        @active.keys.each do |pid|
          _pid = Process.waitpid pid, Process::WNOHANG
          if _pid
            @logger.info "process has gone. restart: [#{pid}] #{@active[pid]['name']}"
            process = @active.delete pid
            start_process process
          end
        end
      end
    end
  end
end
