# frozen_string_literal: true

class JavaField
  attr_accessor :name, :cls, :attributes, :type

  def initialize(name, cls, attributes)
    @name = name
    @cls = cls
    @attributes = attributes[0..-2]
    @type = attributes[-1]
  end

  def final?
    @attributes.include? 'final'
  end

  def to_s
    "#{name}"
  end
end
