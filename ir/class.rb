# frozen_string_literal: true

require_relative 'field'
require_relative 'method'

class JavaClass
  attr_reader :name, :filename
  attr_accessor :fields, :methods

  def initialize(name, filename)
    @name = name
    @fields = {}
    @methods = []
    @filename = filename
  end

  def constructors
    @methods.select(&:constructor?)
  end

  def static_initializer
    @methods.find(&:static_initializer?)
  end

  def find_method(name)
    @methods.find { |x| x.name == name }
  end
end
