actions :modify, :create

attribute :key_name, :kind_of => String
attribute :values, :kind_of => Hash

def initialize(name, run_context=nil)
  super
  @action = :modify
  @key_name = name
end
