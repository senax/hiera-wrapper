require 'rubygems'
gem 'minitest'
#require 'minitest/autorun'
require 'minitest/spec'
require 'hiera'
require 'hiera/backend/wrapper_backend'

class Hiera
  module Backend
    describe Wrapper_backend do
      hiera_config=YAML.load_file("test/etc/hiera_nolists.yaml")

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

      it ":priority lookup should fail when not found in either backend" do
      result=""
          out,err = capture_subprocess_io do
            result=@backend.lookup("no_such_key",{},nil, :priority)
          end
          assert_equal(nil,result)
      end

      it ":array lookup should fail when not found in either backend" do
          result=""
          out,err = capture_subprocess_io do
            result=@backend.lookup("no_such_key",{},nil, :array)
          end
                assert_equal(nil,result)
      end

      it ":hash lookup should fail when not found in either backend" do
        result=""
          out,err = capture_subprocess_io do
            result=@backend.lookup("no_such_key",{},nil, :hash)
          end
          assert_equal(nil,result)
      end

      it "element lookup should fail when not found in either backend" do
          result=""
          out,err = capture_subprocess_io do
            result=@backend.lookup("no_such_key.element",{},nil, :priority)
          end
          assert_equal(nil,result)
      end

      it "lookup of json_only should return value from json" do
        result = ""
        out,err = capture_subprocess_io do
          result=@backend.lookup("json_only",{},nil, :priority)
        end
        assert_equal("json_only_value",result)
      end 

      it "lookup of yaml_only should return value from yaml" do
        result = ""
        out,err = capture_subprocess_io do
          result=@backend.lookup("yaml_only",{},nil, :priority)
        end
        assert_equal("yaml_only_value",result)
      end 

      it "lookup of json_and_yaml :priority should return value from json" do
        result = ""
        out,err = capture_subprocess_io do
          result=@backend.lookup("json_and_yaml",{},nil, :priority)
        end
        assert_equal("json_and_yaml_json_value",result)
      end 

      it "lookup of json_and_yaml, :array should return value from both" do
        result = ""
        out,err = capture_subprocess_io do
          result=@backend.lookup("json_and_yaml",{},nil, :array)
          #  lookup(key, scope, order_override, resolution_type, context)
        end
        #assert_equal([["json_and_yaml_json_value"], ["json_and_yaml_yaml_value"]],result)
        assert_equal(["json_and_yaml_json_value", "json_and_yaml_yaml_value"],result)
      end 

      it "lookup of json_and_yaml (string), :hash should raise exception" do
        result = ""
        raised=false
        begin
          out,err = capture_subprocess_io do
            result=@backend.lookup("json_and_yaml",{},nil, :hash)
          end
        rescue Exception
          raised=true
        end
        assert_equal(true,raised)
      end 

    end
  end
end
