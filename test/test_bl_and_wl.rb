require 'rubygems'
gem 'minitest'
#require 'minitest/autorun'
require 'minitest/spec'
require 'hiera'
require 'hiera/backend/wrapper_backend'

class Hiera
  module Backend
    describe Wrapper_backend do
      hiera_config=YAML.load_file("test/etc/hiera_bl_and_wl.yaml")

      before do
        Config.load(hiera_config)
        @new_out,@new_err = capture_subprocess_io do
          @backend=Wrapper_backend.new()
        end
      end

      it "Should announce its creation" do
        assert_equal("",@new_out)
        assert_match(/Hiera WRAP backend starting/,@new_err)
      end

      it "lookup should fail when not found in either backend" do
        result=""
        out,err = capture_subprocess_io do
          result=@backend.lookup("no_such_key",{},nil, :priority)
        end
        assert_equal(nil,result)
      end

      # cases:
      # bl, wl, result
      # 00 -> reject
      # 01 -> found
      # 10 -> reject
      # 11 -> reject*
      # proove a few multi-backend cases?

      it "lookup of bl should not return value" do
        result = ""
        out,err = capture_subprocess_io do
          result=@backend.lookup("bl",{},nil, :priority)
        end
        assert_equal(nil,result)
      end 

      it "lookup of wl should return value" do
        result = ""
        out,err = capture_subprocess_io do
          result=@backend.lookup("wl",{},nil, :priority)
        end
        assert_equal("should_be_allowed",result)
      end 

      it "lookup of black_and_white should not return value" do
        result=""
        out,err = capture_subprocess_io do
          result=@backend.lookup("black_and_white",{},nil, :priority)
        end
        assert_equal(nil,result)
      end 

    end
  end
end

