actions :unzip, :zip

attribute :path, :kind_of => String, :name_attribute => true
attribute :source, :kind_of => String
attribute :overwrite, :kind_of => [ TrueClass, FalseClass ], :default => false

def initialize(name, run_context=nil)
  super
  @action = :unzip
end
