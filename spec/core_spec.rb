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
  end

  describe '._hup' do
  end

  describe '.add_worker_loadpath' do
  end

  describe '.load_worker_class' do
  end

  describe '.init' do
  end

  describe '.start_process' do
  end

  describe '.run' do
  end
end
