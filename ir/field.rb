# frozen_string_literal: true

class JavaField
  attr_accessor :name, :cls, :attributes, :type

  def initialize(name, cls, type, attributes)
    @name = name
    @cls = cls
    @attributes = attributes
    @type = type
  end

  def final?
    @attributes.include? 'final'
  end

  def static?
    @attributes.include? 'static'
  end

  def to_s
    "#{name}"
  end
end
