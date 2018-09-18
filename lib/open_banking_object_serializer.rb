module OpenBankingObjectSerializer
  extend ActiveSupport::Concern
  include FastJsonapi::ObjectSerializer

  included do
    # OpenBanking camel cases all attributes
    set_key_transform :camel
  end

  # OpenBanking capitalizes data, links, meta
  # FIXME? maybe the single-element array for a single resource should be fixed here rather than below
  def hash_for_one_record
    hash = super
    new_hash = {Data: hash[:data], Links: hash[:links], Meta: hash[:meta]}
    new_hash.delete_if {|k,v| v.nil?}
  end

  # Transform what is usually {data: [{type: Account, id: 1, attributes: {...}}]}
  # And what is now {data: [{Account: [{...}]}]}
  # To OpenBanking format, which is {Data: {Account: [{},{}]}}
  # Also capitalize the other keys
  def hash_for_collection
    hash = super
    data_hash = {}
    data_hash[self.class.record_type] = (hash[:data] || []).collect{|obj| obj[self.class.record_type]}.flatten
    new_hash = {Data: data_hash, Links: hash[:links], Meta: hash[:meta]}
    new_hash.delete_if {|k,v| v.nil?}
  end

  class_methods do
    # OpenBanking deviates from JSON-API and doesn't return type and id
    def id_hash(*args)
      {}
    end

    # instead it returns the type name in place of 'attributes'
    # like {Account: {...}}
    # only bizarrely it returns a single element in an array, too
    # like {Account: [{...}]}
    def record_hash(*args)
      hash = super
      attrs = hash.delete(:attributes)
      hash[record_type] = [attrs] if attrs
      hash
    end
  end
end