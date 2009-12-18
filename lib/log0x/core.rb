# -*- coding: utf-8 -*-
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
      @logger.info Log0x.active
      Log0x.active.keys.each do |pid| 
        begin
          Process.detach pid
          result = Process.kill 'INT', pid
          @logger.info "Process.kill result = #{result}"
        rescue Exception => e
          @logger.warn "ERROR(Process.kill) #{e.inspect}"
        end
      end
      exit
    end

    def _hup
      Signal.trap :CHLD, 'IGNORE'
      Log0x.active.keys.each {|pid| Process.kill 'HUP', pid}
    end

    def add_worker_loadpath(path)
      $:.unshift path
    end

    attr_accessor :loaded_workers
    def load_worker_class(load_cls)
      @loaded_workers ||= {}
      return @loaded_workers[load_cls] if @loaded_workers[load_cls]
      clss = load_cls.split('::')
      require clss.map{|c| c.downcase}.join('/')
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

    def start_process(process_config)
      starter = if process_config['class']
        worker_class = load_worker_class(process_config['class'])
        @logger.info "worker class: #{worker_class}"
        # include Log0x::Workerizeしてるか確認
        if Log0x::BootLoader.supported?(worker_class)
          lambda {Log0x::BootLoader.start worker_class, process_config, @config}
        else
          @logger.warn "#{worker_class} is not supported."
          nil
        end
      elsif process_config['cmd']
        lambda {
          exec process_config['cmd']
          exit
        }
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
      Signal.trap(:HUP) {self._hup}
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
