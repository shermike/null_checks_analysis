# frozen_string_literal: true

# Construct SSA form for the method.
# Currently, supported only methods without loops.
class SsaBuilder

  def initialize(method)
    @method = method
    @defs = {}
  end

  def construct
    stack_liveout = {}
    rpo(@method) do |bb|
      stack = []

      @defs[bb] = {}

      unless bb.preds.empty?
        update_defs_from_preds(bb)

        stack_liveins = bb.preds.map { |pred| stack_liveout[pred] }
        raise "Invalid stack in #{bb}" unless stack_liveins.all? { |x| x.size == stack_liveins[0].size }

        (0...stack_liveins[0].size).each do |i|
          value = stack_liveins[0][i]
          all_same = stack_liveins.all? { |x| x[i] == value }
          if all_same
            stack << value
          else
            phi = PhiInstruction.new(bb.pc, :phi, Bytecode::INFO[:phi])
            stack_liveins.each do |livein|
              phi.add_phi_input(bb.preds[i], livein[i])
            end
            bb.preppend_inst(phi)
            stack << phi
          end
        end
      end

      bb.instructions.each do |inst|
        case
        when inst.opcode == :swap
          stack[-2], stack[-1] = stack[-1], stack[-2]
        when inst.opcode == :dup
          stack << stack[-1]
        when inst.aload?
          stack.push(get_def(bb, inst.var_index))
        when inst.astore?
          set_def(bb, inst.var_index, stack.pop)
        when inst.opcode == :parameter
          set_def(bb, inst.imm(0), inst)
        when inst.invoke?
          (0...inst.signature.params.size).each do
            inst.add_input(stack.pop)
          end
          if inst.signature.type != :T_VOID
            stack << inst
          end
        else
          (0...inst.descr.pop).each do
            raise "Stack underflow" if stack.empty?
            inst.add_input(stack.pop)
          end
          stack << inst if inst.descr.push == 1
        end
      end
      stack_liveout[bb] = stack
    end

    @method.instructions.each do |inst|
      raise "Nil input in instruction: #{inst.pc}: #{inst.opcode}" if inst.inputs.any?(&:nil?)
    end
  end

  def update_defs_from_preds(bb)
    if bb.preds.size == 1
      @defs[bb] = @defs[bb.preds[0]].clone unless @defs[bb].nil?
      raise "Block wasn't processed: bb.#{bb.preds[0]}" if @defs[bb].nil?
    elsif bb.preds.size > 1
      same_defs = bb.preds.map { |x| @defs[x].keys }.reduce(&:&)
      same_defs.each do |var|
        value = get_def(bb.preds[0], var)
        all_same = bb.preds.all? { |pred| get_def(pred, var) == value }
        if all_same
          set_def(bb, var, value)
        else
          phi = PhiInstruction.new(bb.pc, :phi, Bytecode::INFO[:phi])
          bb.preds.each do |pred|
            phi.add_phi_input(pred, get_def(pred, var))
          end
          bb.instructions.prepend(phi)
          set_def(bb, var, phi)
        end
      end
    end
  end

  def set_def(bb, var, inst)
    @defs[bb] ||= {}
    @defs[bb][var] = inst
  end

  def get_def(bb, var)
    bb_defs = @defs[bb]
    raise "Basic block #{bb} has no definitions" if bb_defs.nil?
    bb_defs[var]
  end

end
