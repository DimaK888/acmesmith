require 'yaml'
require 'acmesmith/storages'
require 'acmesmith/challenge_responders'
require 'acmesmith/post_issuing_hooks'

module Acmesmith
  class Config
    def self.load_yaml(path)
      new YAML.load_file(path)
    end

    def initialize(config)
      @config = config
      validate
    end

    def validate
      unless @config['storage']
        raise ArgumentError, "config['storage'] must be provided"
      end

      unless @config['endpoint']
        raise ArgumentError, "config['endpoint'] must be provided, e.g. https://acme-v01.api.letsencrypt.org/ or https://acme-staging.api.letsencrypt.org/"
      end

      if @config['post_issueing_hooks']
        warn '!! Deprecation warning: configuration "post_issueing_hooks" is now "post_issuing_hooks" (what a typo!). It will not work in the future release.'
        @config['post_issuing_hooks'] = @config.delete('post_issueing_hooks')
      end
    end

    def [](key)
      @config[key]
    end

    def merge!(pair)
      @config.merge!(pair)
    end

    def account_key_passphrase
      @config['account_key_passphrase']
    end

    def certificate_key_passphrase
      @config['certificate_key_passphrase']
    end

    def auto_authorize_on_request
      @config.fetch('auto_authorize_on_request', true)
    end

    def storage
      @storage ||= begin
        c = @config['storage'].dup
        Storages.find(c.delete('type')).new(**c.map{ |k,v| [k.to_sym, v]}.to_h)
      end
    end

    def post_issuing_hooks(common_name)
      if @config.key?('post_issuing_hooks') && @config['post_issuing_hooks'].key?(common_name)
        specs = @config['post_issuing_hooks'][common_name]
        specs.flat_map do |specs_sub|
          specs_sub.map do |k, v|
            PostIssuingHooks.find(k).new(**v.map{ |k_,v_| [k_.to_sym, v_]}.to_h)
          end
        end
      else
        []
      end
    end

    def challenge_responders
      @challenge_responders ||= begin
        specs = @config['challenge_responders'].kind_of?(Hash) ? @config['challenge_responders'].map { |k,v| [k => v] } : @config['challenge_responders']
        specs.flat_map do |specs_sub|
          specs_sub.map do |k, v|
            ChallengeResponders.find(k).new(**v.map{ |k_,v_| [k_.to_sym, v_]}.to_h)
          end
        end
      end
    end

    # def post_actions
    # end
  end
end
