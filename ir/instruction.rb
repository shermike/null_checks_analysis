# frozen_string_literal: true

require_relative 'method_signature'

class Instruction
  attr_accessor :bb, :prev, :next, :line
  attr_reader :pc, :opcode, :operands, :descr, :inputs, :uses

  def initialize(pc, opcode, immediates, descr)
    raise "Wrong parameters type" unless pc.is_a?(Integer)
    raise "opcode must be a symbol" unless opcode.is_a? Symbol
    @pc = pc
    @opcode = opcode
    @immediates = immediates ? immediates : []
    @descr = descr
    @inputs = []
    @uses = []
  end

  def cfg?
    @descr[:format].include? 'o'
  end

  def if?
    @opcode.start_with?('if')
  end

  def invoke?
    @opcode.start_with?('invoke')
  end

  def aload?
    @opcode.start_with?('aload')
  end

  def aload_index
    raise "Not an aload instruction" unless aload?
    return @immediates[0] if opcode == :aload
    opcode.to_s[6].to_i
  end

  def astore?
    @opcode.start_with?('astore')
  end

  def astore_index
    raise "Not an astore instruction" unless astore?
    return @immediates[0] if opcode == :astore
    opcode.to_s[7].to_i
  end

  def var_index
    aload? ? aload_index : (astore? ? astore_index : nil)
  end

  def imm(index)
    @immediates[index]
  end

  def terminator?
    @opcode.end_with?('return')
  end

  def offset
    raise "Get offset from a non-cfg instruction" unless cfg?
    raise "Unexpected operands count" if @immediates.empty?
    @immediates[0]
  end

  def add_input(input)
    @inputs << input
    input.uses << self
  end

  def set_next(inst)
    @next = inst
    inst.prev = self if inst
  end

  def to_s
    s = "#{@pc}: #{@opcode.to_s}"
    s += " #{@immediates.map { |x| '#' + x.to_s }.join(', ')}" unless @immediates.empty?
    s += " (#{@inputs.map(&:pc).join(', ')})" unless @inputs.empty?
    s
  end

  def inspect
    "#{@pc}: #{@opcode.to_s}"
  end

  def dump
    puts "    #{to_s}"
  end
end

class InvokeInstruction < Instruction
  attr_reader :signature

  def initialize(pc, opcode, descr, immediates, signature)
    super(pc, opcode, immediates, descr)
    @signature = signature
  end
end

class FieldInstruction < Instruction
  attr_reader :field

  def initialize(pc, opcode, descr, immediates, field)
    super(pc, opcode, immediates, descr)
    @field = field
  end
end

class PhiInstruction < Instruction
  attr_reader :basic_blocks

  def initialize(pc, opcode, descr)
    super(pc, opcode, [], descr)
    @basi_blocks = []
  end

  def add_phi_input(bb, inst)
    raise "Inconsitant state of Phi instruction" unless @basi_blocks.size == @inputs.size
    add_input(inst)
    @basi_blocks << bb
  end
end
