# frozen_string_literal: true

require_relative 'instruction'

class BasicBlock
  attr_accessor :method
  attr_reader :id, :succs, :preds, :instructions

  TRUE_INDEX = 0
  FALSE_INDEX = 1

  def initialize(id, method)
    @id = id
    @preds = []
    @succs = [nil, nil]
    @instructions = []
    @method = method
  end

  def pc
    @instructions.empty? ? nil : @instructions.first.pc
  end

  def true_succ
    @succs[TRUE_INDEX]
  end

  def false_succ
    @succs[FALSE_INDEX]
  end

  def set_true_succ(bb)
    raise "True successor is not nil: #{true_succ.id}" unless @succs[TRUE_INDEX].nil?
    @succs[0] = bb
    bb.preds << self
  end

  def set_false_succ(bb)
    raise "False successor is not nil" unless @succs[FALSE_INDEX].nil?
    @succs[FALSE_INDEX] = bb
    bb.preds << self
  end

  def append_inst(inst)
    @instructions.last&.set_next(inst)
    @instructions << inst
    inst.bb = self
  end

  def preppend_inst(inst)
    @instructions.prepend(inst)
    inst.set_next(@instructions.last)
    inst.bb = self
  end

  def empty?
    @instructions.empty?
  end

  def dump
    tsucc = true_succ ? " bb.#{true_succ.id}" : 'end'
    fsucc = false_succ ? ', f->bb.' + false_succ.id.to_s : ''
    succs = "[t->#{tsucc}#{fsucc}]"
    preds_str = " [preds: #{@preds.join(', ')}]" unless @preds.empty?
    puts "  bb.#{@id}# {succs}#{preds_str}"
    @instructions.each(&:dump)
  end

  def to_s
    "bb.#{@id}"
  end
end
