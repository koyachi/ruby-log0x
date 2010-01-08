# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require 'spec_helper'
require 'fileutils'

include FileUtils

describe Log0x do
  before do
    @cached_protect_from_signals_mutex
  end

  after do
  end

  describe '.protect_from_signals' do
    it 'should initialize @protect_from_signals_mutex' do
      Log0x.instance_variable_get(:@protect_from_signals_mutex).should be_nil
      Log0x.protect_from_signals{'hello'}
      @cached_protect_from_signals_mutex = Log0x.instance_variable_get(:@protect_from_signals_mutex)
      @cached_protect_from_signals_mutex.should be_an_instance_of(Mutex)
    end

    it 'should protect from SIGINT and call sighandler after prtected block' do
      order = []
      Signal.trap(:INT){order << 4}
      order << 1

      result = Log0x.protect_from_signals do
        order << 2
        Process.kill :INT, Process.pid
        order << 3
        100
      end

      order.should == [1,2,3,4]
      result.should == 100
    end
  end

  describe '._huntsman' do
    it 'should detach & kill(INT) pids in @active' do
      except_pids = [10, 20, 30]
      Process.should_receive(:detach).exactly(3).and_return do |pid|
        except_pids.should include(pid)
        except_pids = except_pids - [pid]
      end
      except_pids2 = [10, 20, 30]
      Process.should_receive(:kill).exactly(3).and_return do |sig,pid|
        sig.should == 'INT'
        except_pids2.should include(pid)
        except_pids2 = except_pids - [pid]
      end
      class Foo
        def initialize
        end
        def info(msg)
        end
        def warn(msg)
        end
      end
      Log0x.logger = Foo.new
      Log0x.should_receive(:exit)
      Log0x.active = {
        10 => 'test_1',
        20 => 'test_2',
        30 => 'test_3',
      }
      Log0x._huntsman
    end
  end

  describe '._hup' do
    it 'should kill(HUP) pids in @active' do
      except_pids = [10, 20, 30]
      Process.should_receive(:kill).exactly(3).and_return do |sig,pid|
        sig.should == 'HUP'
        except_pids.should include(pid)
        except_pids = except_pids - [pid]
      end
      class DummyLogger
        def initialize
        end
        def info(msg)
        end
        def warn(msg)
        end
      end
      Log0x.logger = DummyLogger.new
      Log0x.active = {
        10 => 'test_1',
        20 => 'test_2',
        30 => 'test_3',
      }
      Log0x._hup
    end
  end

  describe '.add_worker_loadpath' do
    it 'should add path to $:' do
      prev = $:.clone
      Log0x.add_worker_loadpath 'foobar'
      ($: - prev).should == ['foobar']
    end
  end

  describe '.load_worker_class' do
    it 'should require "load_cls" and set worker class to @loaded_workers[load_cls]' do
      Log0x.add_worker_loadpath fixture('')
      result = Log0x.load_worker_class('MyWorker::Sample1', {:this => :is_config_for_process})
      result.should == ::MyWorker::Sample1
      Log0x.loaded_workers['MyWorker::Sample1'].should == ::MyWorker::Sample1
    end
  end

  describe '.init' do
    it 'should set members from config' do
      Log0x.module_eval do |m|
        class Logger
          attr_accessor :level
          def initialize(args)
          end
          def info(msg)
          end
        end
      end
      except_worker_configs = [
                               {
                                 'class' => 'MyWorker::A',
                                 'num' => 2,
                               },
                               {
                                 'class' => 'MyWorker::B',
                                 'num' => 3,
                               },
                              ]
      Log0x.should_receive(:start_process).exactly(2 + 3).and_return do |process|
        except_worker_configs.should include(process)
      end

      Log0x.init({
                   'paths' => %w[path_a path_b path_c],
                   'workers' => [
                                 {
                                   'class' => 'MyWorker::A',
                                   'num' => 2,
                                 },
                                 {
                                   'class' => 'MyWorker::B',
                                   'num' => 3,
                                 }
                                ]
                 })
      Log0x.config.should == {
        'paths' => %w[path_a path_b path_c],
        'workers' => [
                      {
                        'class' => 'MyWorker::A',
                        'num' => 2,
                      },
                      {
                        'class' => 'MyWorker::B',
                        'num' => 3,
                      }
                     ]
      }
      %w[path_a path_b path_c].each do |path|
        $:.should include(path)
      end
    end

  end

  describe '.start_process' do
    it 'should save process_config to @active[pid] if forked process is parent' do
      class DummyLogger
        def initialzie
        end
        def info(msg)
        end
        def warn(msg)
        end
      end
      Log0x.logger = DummyLogger.new

      Log0x::BootLoader.should_receive(:supported?).and_return do |worker_class|
        worker_class.should == 'MyWorker::A(load_worker_class)'
        true
      end
#      Log0x::BootLoader.should_receive(:start).and_return do |worker_class, process_config, global_config|
#        worker_class.should == 'MyWorker::A'
#        process_config.should == {'class'=>'MyWorker::A'}
#        global_config.should == {:hoge => 'fuga'}
#      end

      Log0x.should_receive(:load_worker_class).and_return do |cls, process_config|
        cls.should == 'MyWorker::A'
        'MyWorker::A(load_worker_class)'
      end
      Log0x.should_receive(:protect_from_signals).and_return do
        100
      end

      Log0x.config = {:hoge => 'fuga'}
      Log0x.start_process({'class'=>'MyWorker::A'})
      Log0x.active[100].should == {'class'=>'MyWorker::A'}
    end
  end

  describe '.run' do
  end
end
