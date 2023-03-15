# frozen_string_literal: true


class NullCheckAnalysis
  attr_reader :true_lines, :false_lines

  NON_DETERMINISTIC = 0
  ALWAYS_TRUE = 1
  ALWAYS_FALSE = 2

  def initialize(method, quiet = false)
    @method = method
    # Contains line numbers indicating that the null-check is always true
    @true_lines = []
    # Contains line numbers indicating that the null-check is always false
    @false_lines = []
    # Suppress logging
    @quiet = quiet
  end

  def run
    @method.instructions.each do |inst|
      if inst.opcode == :ifnull || inst.opcode == :ifnonnull
        input = inst.inputs[0]
        input_result = get_value_from_inst(inst.inputs[0])
        case
        when input_result != NON_DETERMINISTIC
          report(inst, input_result == ALWAYS_TRUE)
        when input.opcode == :phi
          res = analyze_phi(inst)
          report(inst, res) if res != NON_DETERMINISTIC
        when input.opcode == :getfield || input.opcode == :getstatic
          analyze_getfield(inst)
        when input.invoke?
          analyze_invoke(inst)
        else
          analyze_input(inst)
        end
      end
    end
  end

  # Check whether the null-check input produces deterministic value.
  def get_value_from_inst(inst)
    case inst.opcode
    when :aconst_null
      return ALWAYS_FALSE
    when :new, :anewarray, :multianewarray
      return ALWAYS_TRUE
    when :invokespecial
      return ALWAYS_TRUE if inst.signature.constructor?
    when :ldc
      return ALWAYS_TRUE
    end
    NON_DETERMINISTIC
  end

  # If input of the null-check is a phi instruction, then check all its inputs in case all of them have
  # the same deterministic value.
  def analyze_phi(inst)
    phi = inst.inputs[0]
    values = []
    phi.inputs.each do |input|
      values << get_value_from_inst(input)
    end
    return NON_DETERMINISTIC if values.empty?
    return ALWAYS_TRUE if values.all? { |x| x == ALWAYS_TRUE }
    return ALWAYS_FALSE if values.all? { |x| x == ALWAYS_FALSE }
    NON_DETERMINISTIC
  end

  # If input of the check is a getfield instruction, then we can remove the chec if field is final.
  # If it is final, we need to analyze all constructors to check whether all of them set field to same value:
  # null or not null.
  def analyze_getfield(inst)
    getfield = inst.inputs[0]
    return unless getfield.field.final?
    values = []
    if getfield.opcode == :getstatic
      values << get_field_value_from_method(getfield.field, @method.cls.static_initializer, :putstatic) if @method.cls.static_initializer
    else
      @method.cls.constructors.each do |ctor|
        values << get_field_value_from_method(getfield.field, ctor, :putfield)
      end
    end
    return if values.empty?
    if values.all? { |x| x == ALWAYS_TRUE }
      report(inst, true)
    elsif values.all? { |x| x == ALWAYS_FALSE }
      report(inst, false)
    end
  end

  # Input of the check is a result of invoke instruction. Try to analyze a callee method and figure out whether return
  # value is deterministic.
  def analyze_invoke(inst)
    invoke = inst.inputs[0]
    # Callee is an external class method, skip it
    return if invoke.signature.cls != @method.cls.name
    callee = @method.cls.find_method(invoke.signature.name)
    raise "Can't find callee method #{invoke.signature.name}" if callee.nil?

    values = get_return_value_from_method(callee)
    return if values.empty?
    if values.all? { |x| x == ALWAYS_TRUE }
      report(inst, true)
    elsif values.all? { |x| x == ALWAYS_FALSE }
      report(inst, false)
    end
  end

  # Analyse the def instruction of the null-check. There are some patterns, when another uses of the def instruction
  # can prove the check redundancy. See cases below.
  def analyze_input(inst)
    input = inst.inputs[0]
    input.uses.each do |use|
      next if use == inst
      case
      # Find another null-check in input dependencies, and if it dominates our check, then we can remove it.
      when use.opcode == :ifnull || use.opcode == :ifnonnull
        # TODO: handle more complex control flow (dom tree is needed)
        if use.bb.true_succ == inst.bb
          report(inst, inst.opcode != use.opcode)
        elsif use.bb.false_succ == inst.bb
          report(inst, inst.opcode == use.opcode)
        end
      # If there is method invocation of the checked object, then we can remove the check, because the invoke bytecode
      # contains implicit null-check.
      when use.opcode == :invokevirtual
        next unless use.inputs[0] == input
        # TODO: We rely on the pc value to determine an instructions order. But instructions can be reordered, so
        # the todo is to implement a proper instructions numbering.
        same_bb = use.bb == inst.bb && use.pc < inst.pc
        next unless use.bb.succs.include?(inst.bb) || same_bb
        report(inst, true)
      end
    end
  end

  # For the given field, find the `putfield` instruction in the method.
  def get_field_value_from_method(field, method, opcode)
    method.instructions.each do |inst|
      if inst.opcode == opcode && inst.field == field
        input = inst.inputs[0]
        return ALWAYS_TRUE if input.opcode == :new
        return ALWAYS_TRUE if input.invoke? && input.signature.constructor?
        return ALWAYS_FALSE if input.opcode == :aconst_null
        return analyze_phi(inst) if input.opcode == :phi
        return NON_DETERMINISTIC
      end
    end
    raise "putfield not found for field: #{field}"
  end

  # Gather all instructions that are returned from the method.
  def get_return_value_from_method(method)
    values = []
    method.instructions.each do |inst|
      if inst.opcode == :areturn
        result = get_value_from_inst(inst.inputs[0])
        return [NON_DETERMINISTIC] if result == NON_DETERMINISTIC
        values << result
      end
    end
    values
  end

  # Report null-check redundancy.
  # If `value` is true, then the input for the null check is not null. Otherwise, it is null.
  def report(inst, value)
    case value
    when ALWAYS_TRUE; value = true
    when ALWAYS_FALSE; value = false
    end
    if inst.opcode == :ifnull
      result = !value
    elsif inst.opcode == :ifnonnull
      result = value
    else
      raise "Unexpected instruction: #{inst}"
    end

    # Inverse report result, since javac transforms `if(x == null)` to `ifnonnull`. I.e. in IR, null-check condition
    # is inverted.
    if result
      @true_lines << inst.line
      puts "Null check is always false: #{@method.cls.filename}:#{inst.line}" unless @quiet
    else
      @false_lines << inst.line
      puts "Null check is always true: #{@method.cls.filename}:#{inst.line}" unless @quiet
    end
  end
end
