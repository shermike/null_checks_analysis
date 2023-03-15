# frozen_string_literal: true

class MethodSignature
  attr_accessor :type, :cls, :name, :params, :attrs

  def initialize(return_type, cls, name, params, attrs)
    @type = return_type
    @cls = cls
    @name = name
    @params = params
    @attrs = attrs
  end

  def constructor?
    @name == '<init>'
  end

  def to_s
    "type=#{@type}, name=#{@name}, params=#{@params}, attrs=#{@attrs}"
  end

  def inspect
    to_s
  end

end
