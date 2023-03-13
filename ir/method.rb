# frozen_string_literal: true

require_relative 'basic_block'
require_relative '../bytecode'
require_relative 'field'
require_relative '../rpo'

class JavaMethod < JavaField
  attr_accessor :instructions
  attr_reader :basic_blocks

  PRIMITIVE_TYPES = %w(byte short int long float double char boolean)

  def initialize(name, args, cls, attributes)
    if attributes.size == 1
      self.name = name
      self.cls = cls
      self.attributes = attributes
      self.type = 'void'
      args = [@cls.name]
      @is_ctor = true
    else
      super(name, cls, attributes)
      @is_ctor = false
      args.prepend(@cls.name) unless static?
    end
    @instructions = []
    @linetable = nil
    @basic_blocks = []
    @bb_id = 0
    unless args.empty?
      entry_bb = new_block
      args.each_with_index do |x, i|
        entry_bb.instructions << Instruction.new(-1 - i, :parameter, [i], Bytecode::INFO[:parameter])
      end
    end
  end

  def constructor?
    @is_ctor
  end

  def static?
    @attributes.include? 'static'
  end

  def entry_bb
    @basic_blocks.first
  end

  def new_block
    @basic_blocks << BasicBlock.new(@bb_id, self)
    @bb_id += 1
    @basic_blocks.last
  end

  # Create control flow graph
  def construct_cfg
    bb = new_block
    @basic_blocks[-2].set_true_succ(bb) if @basic_blocks.size == 2
    # Key is a `pc`, value is a basic block, starting from this pc
    bb_map = {0 => bb}

    # First, create all possible basic blocks
    @instructions.each_with_index do |inst, index|
      target_bb = bb_map[inst.pc]

      if target_bb && target_bb != bb
        bb = target_bb
        next
      end

      if inst.cfg?
        continuation_bb = bb_map[@instructions[index + 1].pc]
        unless continuation_bb
          continuation_bb = new_block
          bb_map[@instructions[index + 1].pc] = continuation_bb
        end
        bb_map[inst.offset] = new_block unless bb_map.include?(inst.offset)
        bb = continuation_bb
      end
    end

    # Second, fill the basic blocks by instructions and connect them to each other.
    bb = bb_map[0]
    @instructions.each do |inst|
      next_bb = bb_map[inst.pc]

      if next_bb && next_bb != bb
        last = bb.instructions.last
        if last.cfg?
          target_bb = bb_map[last.offset]
          raise "invalid cfg" if target_bb.nil?
          bb.set_true_succ(target_bb)
          bb.set_false_succ(next_bb) if last.if?
        else
          bb.set_true_succ(next_bb) unless last.terminator?
        end
        bb = next_bb
      end
      bb.append_inst(inst)
    end
  end

  def set_linetable(linetable)
    hlines = Hash[linetable]
    line = nil
    @instructions.each do |inst|
      line = hlines[inst.pc] if hlines.include?(inst.pc)
      inst.line = line
    end
  end

  def dump
    puts "#{@attributes.join(' ')} #{@name} {"
    @basic_blocks.each(&:dump)
    puts '}'
  end
end
