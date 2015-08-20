class Hiera
  module Backend
    class Backend1xWrapper
      def initialize(wrapped)
        @wrapped = wrapped
      end

      def lookup(key, scope, order_override, resolution_type, context)
        Hiera.debug("Using Hiera 1.x backend API to access instance of class #{@wrapped.class.name}. Lookup recursion will not be detected")
        value = @wrapped.lookup(key, scope, order_override, resolution_type.is_a?(Hash) ? :hash : resolution_type)

        # The most likely cause when an old backend returns nil is that the key was not found. In any case, it is
        # impossible to know the difference between that and a found nil. The throw here preserves the old behavior.
        throw (:no_such_key) if value.nil?
        value
      end
    end

    class Wrapper_backend
      def initialize(cache=nil)
        require 'yaml'
        Hiera.debug("Hiera WRAP backend starting")

        @cache = cache || Filecache.new
        load_backends
      end

      def load_backends
        Config[:wrapper][:backends].each do |wrap_entry|
          backend=wrap_entry.keys.first.to_s
          begin
            require "hiera/backend/#{backend.to_s.downcase}_backend"
          rescue LoadError => e
            Hiera.warn "Cannot load backend #{backend}: #{e}"
          end
        end
      end

      def find_backend(backend_constant)
        backend = Backend.const_get(backend_constant).new
        return backend.method(:lookup).arity == 4 ? Backend1xWrapper.new(backend) : backend
      end

      def check_filters(options,key)
        # if there is a blacklist, make sure the key does not match any of the entries.
        # if there is a whitelist, make sure the key matches at least one of those entries.
        #
        # Hiera.debug("Check_filters: #{options.inspect} #{key.inspect}")
        return if options.nil?
        return unless options.is_a?(Hash)
        if options.has_key?(:blacklist) and options[:blacklist].is_a?(Array) and options[:blacklist].size >0
          options[:blacklist].each do |bl|
            if Regexp.new(bl) =~ key
              Hiera.debug("blacklist reject, found #{key} in #{options[:blacklist].inspect}")
              throw :no_such_key
            end
          end
        end
        if options.has_key?(:whitelist) and options[:whitelist].is_a?(Array) and options[:whitelist].size >0 
          options[:whitelist].each do |wl| 
            return if Regexp.new(wl) =~ key
          end
          Hiera.debug("whitelist reject, not found #{key} in #{options[:whitelist].inspect}")
          throw :no_such_key
        end
      end

#      def lookup(key, scope, order_override, resolution_type, context)
      def lookup(key, scope, order_override, resolution_type)

        Hiera.debug("WRAP.lookup #{key.inspect}, resolution_type = #{resolution_type.inspect}")
        @backends ||= {}
        answer = nil
        found = false
        Hiera.debug("WRAP config: #{Config[:wrapper].inspect}")

        # order_override is kept as an explicit argument for backwards compatibility, but should be specified
        # in the context for internal handling.
        context ||= {}
        order_override ||= context[:order_override]
        context[:order_override] ||= order_override

        strategy = resolution_type.is_a?(Hash) ? :hash : resolution_type

        segments = key.split('.')
        subsegments = nil
        if segments.size > 1
          raise ArgumentError, "Resolution type :#{strategy} is illegal when doing segmented key lookups" unless strategy.nil? || strategy == :priority
          subsegments = segments.drop(1)
        end

        found = false
        Config[:wrapper][:backends].each do |wrap_entry|
          backend=wrap_entry.keys.first.to_s
          options=wrap_entry[backend.to_sym]
          backend_constant = "#{backend.to_s.capitalize}_backend"
          backend = (@backends[backend] ||= find_backend(backend_constant))
          found_in_backend = false
          new_answer = catch(:no_such_key) do
            check_filters(options,key)
            value = backend.lookup(segments[0], scope, order_override, resolution_type, context)
            value = Backend.qualified_lookup(subsegments, value) unless subsegments.nil?
            found_in_backend = true
            value
          end
          next unless found_in_backend
          found = true

          case strategy
          when :array
            raise Exception, "Hiera type mismatch for key '#{key}': expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch for key '#{key}': expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer, answer, resolution_type)
          else
            answer = new_answer
            break
          end
        end

        throw :no_such_key unless found
        return answer
      end # lookup
    end # Wrapper_backend
  end # backend
end # class hiera

