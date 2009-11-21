# DO NOT MODIFY THIS FILE
module Bundler
 file = File.expand_path(__FILE__)
 dir = File.dirname(file)

  ENV["PATH"]     = "#{dir}/bin:#{ENV["PATH"]}"
  ENV["RUBYOPT"]  = "-r#{file} #{ENV["RUBYOPT"]}"

  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/httparty-0.4.5/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/httparty-0.4.5/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/hashie-0.1.5/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/hashie-0.1.5/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/oauth-0.3.6/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/oauth-0.3.6/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/crack-0.1.4/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/crack-0.1.4/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/ruby-hmac-0.3.2/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/ruby-hmac-0.3.2/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/json_pure-1.2.0/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/json_pure-1.2.0/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/twitter-0.7.5/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/twitter-0.7.5/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/nokogiri-1.4.0/bin")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/nokogiri-1.4.0/lib")
  $LOAD_PATH.unshift File.expand_path("#{dir}/gems/nokogiri-1.4.0/ext")

  @gemfile = "#{dir}/../../Gemfile"

  require "rubygems"

  @bundled_specs = {}
  @bundled_specs["httparty"] = eval(File.read("#{dir}/specifications/httparty-0.4.5.gemspec"))
  @bundled_specs["httparty"].loaded_from = "#{dir}/specifications/httparty-0.4.5.gemspec"
  @bundled_specs["oauth"] = eval(File.read("#{dir}/specifications/oauth-0.3.6.gemspec"))
  @bundled_specs["oauth"].loaded_from = "#{dir}/specifications/oauth-0.3.6.gemspec"
  @bundled_specs["hashie"] = eval(File.read("#{dir}/specifications/hashie-0.1.5.gemspec"))
  @bundled_specs["hashie"].loaded_from = "#{dir}/specifications/hashie-0.1.5.gemspec"
  @bundled_specs["ruby-hmac"] = eval(File.read("#{dir}/specifications/ruby-hmac-0.3.2.gemspec"))
  @bundled_specs["ruby-hmac"].loaded_from = "#{dir}/specifications/ruby-hmac-0.3.2.gemspec"
  @bundled_specs["crack"] = eval(File.read("#{dir}/specifications/crack-0.1.4.gemspec"))
  @bundled_specs["crack"].loaded_from = "#{dir}/specifications/crack-0.1.4.gemspec"
  @bundled_specs["json_pure"] = eval(File.read("#{dir}/specifications/json_pure-1.2.0.gemspec"))
  @bundled_specs["json_pure"].loaded_from = "#{dir}/specifications/json_pure-1.2.0.gemspec"
  @bundled_specs["nokogiri"] = eval(File.read("#{dir}/specifications/nokogiri-1.4.0.gemspec"))
  @bundled_specs["nokogiri"].loaded_from = "#{dir}/specifications/nokogiri-1.4.0.gemspec"
  @bundled_specs["twitter"] = eval(File.read("#{dir}/specifications/twitter-0.7.5.gemspec"))
  @bundled_specs["twitter"].loaded_from = "#{dir}/specifications/twitter-0.7.5.gemspec"

  def self.add_specs_to_loaded_specs
    Gem.loaded_specs.merge! @bundled_specs
  end

  def self.add_specs_to_index
    @bundled_specs.each do |name, spec|
      Gem.source_index.add_spec spec
    end
  end

  add_specs_to_loaded_specs
  add_specs_to_index

  def self.require_env(env = nil)
    context = Class.new do
      def initialize(env) @env = env && env.to_s ; end
      def method_missing(*) ; end
      def only(env)
        old, @only = @only, _combine_onlys(env)
        yield
        @only = old
      end
      def except(env)
        old, @except = @except, _combine_excepts(env)
        yield
        @except = old
      end
      def gem(name, *args)
        opt = args.last || {}
        only = _combine_onlys(opt[:only] || opt["only"])
        except = _combine_excepts(opt[:except] || opt["except"])
        files = opt[:require_as] || opt["require_as"] || name
        files = [files] unless files.respond_to?(:each)

        return unless !only || only.any? {|e| e == @env }
        return if except && except.any? {|e| e == @env }

        files.each { |f| require f }
        yield if block_given?
        true
      end
      private
      def _combine_onlys(only)
        return @only unless only
        only = [only].flatten.compact.uniq.map { |o| o.to_s }
        only &= @only if @only
        only
      end
      def _combine_excepts(except)
        return @except unless except
        except = [except].flatten.compact.uniq.map { |o| o.to_s }
        except |= @except if @except
        except
      end
    end
    context.new(env && env.to_s).instance_eval(File.read(@gemfile))
  end
end

module Gem
  def source_index.refresh!
    super
    Bundler.add_specs_to_index
  end
end
