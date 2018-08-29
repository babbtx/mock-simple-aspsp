module OpenBankingObjectSerializer
  extend ActiveSupport::Concern
  include FastJsonapi::ObjectSerializer

  included do
    # OpenBanking camel cases all attributes
    set_key_transform :camel
  end

  # OpenBanking capitalizes data, links, meta and included
  def serializable_hash
    hash = super
    new_hash = {Data: hash[:data], Links: hash[:links], Meta: hash[:meta], Included: hash[:included]}
    new_hash.delete_if {|k,v| v.nil?}
  end

  class_methods do
    # OpenBanking deviates from JSON-API and doesn't return type and id
    def id_hash(*args)
      {}
    end

    # instead it returns the type name in place of 'attributes'
    def record_hash(*args)
      hash = super
      attrs = hash.delete(:attributes)
      hash[record_type] = attrs if attrs
      hash
    end
  end
end