# frozen_string_literal: true


require_relative 'ir/class'
require_relative 'ir/ssa_builder'
require_relative 'bytecode'

require 'open3'
require 'tmpdir'

# This class builds IR from the javap disasm files.
# It uses straightforward parser, based on regexps, therefore it is quite fragile and should not be used in
# the production code.
class IrBuilderJavap
  TYPE_MAP = {V: :T_VOID, C: :T_CHAR, B: :T_BYTE, I: :T_INT, J: :T_LONG, F: :T_FLOAT, D: :T_DOUBLE, L: :T_OBJECT}

  def initialize
    @class = nil
  end

  def build_from_file(filename)
    basename = File.basename(filename, '.*')
    classname = "#{Dir.tmpdir}/test/#{basename}.class"

    command("javac -d #{Dir.tmpdir} #{filename}")
    disasm = command("javap -p -l -c #{classname}")
    build_from_lines(disasm.split("\n"), filename)
  end

  def build_from_lines(lines, filename)
    @class = nil
    method = nil
    instructions = nil
    linetable = nil
    state = nil

    lines.each do |line|
      if line.empty? || line == '}'
        method.instructions = instructions if instructions
        method.set_linetable(linetable) if linetable
        method = nil
        state = nil
        linetable = nil
        instructions = nil
        next
      end
      unless @class
        class_name = /public class (.*) {/.match(line)
        @class = JavaClass.new(class_name[1], filename) if class_name
        next
      end
      case line
      when /^  (public|private|protected)/
        field = parse_declaration(line)
        if field.is_a? JavaMethod
          method = field
          @class.methods << method
        else
          @class.fields[field.name] = field
        end
      when '    Code:'
        state = :CODE
        instructions = []
      when '    LineNumberTable:'
        state = :LINETABLE
        method.instructions = instructions
        instructions = nil
        linetable = []
      else
        if state == :CODE
          instructions << build_instruction(line)
        elsif state == :LINETABLE
          data = line.strip.split
          linetable << [data[2], data[1][0..-2]].map(&:to_i)
        else
          raise "Unexpected line: #{line}"
        end
      end
    end
    @class.methods.each(&:construct_cfg)
    @class.methods.each { |method| SsaBuilder.new(method).construct }
    @class
  end

  def parse_declaration(line)
    return parse_method_decl(line) if line.include?('(')
    data = line.strip[0..-1].split
    name = data[-1].chomp(';')
    modifiers = data[0..-2]
    JavaField.new(name, @class, modifiers)
  end

  def parse_method_decl(line)
    m = /(.*) (.+)\((.*)\);/.match(line.strip)
    modifiers = m[1].split
    name = m[2]
    args = m[3].split(', ')
    JavaMethod.new(name, args, @class, modifiers)
  end

  def parse_comment(comment, opcode)
    comment.strip!
    if comment.start_with? 'Method'
      comment = comment[7..-1] # Remove 'Method '
      m = /(.*):\((.*)\)(\w+)/.match(comment)
      raise "Method signature parse failed: #{comment}" unless m
      name = m[1]
      params = m[2]&.split(';')
      return_type = TYPE_MAP[m[3][0].to_sym]
      raise "Unsupported type: #{m[3]}" unless return_type
      name_tkn = name.split('.')
      if name_tkn.size == 2
        cls = name_tkn[0]
        name = name_tkn[1].delete('"')
      else
        raise "Invalid method name token" unless name_tkn.size == 1
        cls = @class.name
        name = name_tkn[0].delete('"')
      end
      params.prepend(cls) if opcode != :invokestatic
      return MethodSignature.new(return_type, cls, name, params, [])
    elsif comment.start_with? 'Field'
      comment = comment[6..-1] # Remove 'Field '
      name = comment.split(':')[0]
      field = @class.fields[name]
      raise 'Unknown field: #{name}' if field.nil?
      return field
    end
  end

  def build_invoke(comment, pc, opcode, immediates, descr)
    sign = parse_comment(comment, opcode)
    raise "Invalid comment for invoke instruction: #{comment}" unless sign.is_a? MethodSignature
    InvokeInstruction.new(pc, opcode, descr, immediates, sign)
  end

  def build_field(comment, pc, opcode, immediates, descr)
    field = parse_comment(comment, opcode)
    raise "Invalid comment for field instruction: #{comment}" unless field.is_a? JavaField
    FieldInstruction.new(pc, opcode, descr, immediates, field)
  end

  def build_instruction(line)
    main_tkn, comment_tkn = line.split('//')
    tokens = main_tkn.strip.split
    pc = tokens[0][0...-1].to_i
    opcode = tokens[1].to_sym
    immediates = tokens[2..-1].map { |x| x.chomp(',').delete_prefix('#') }.map(&:to_i)
    descr = Bytecode::INFO[opcode.to_sym]
    raise "Description not found for opcode: #{opcode}" unless descr

    return build_invoke(comment_tkn, pc, opcode, immediates, descr) if opcode.start_with? 'invoke'
    return build_field(comment_tkn, pc, opcode, immediates, descr) if opcode == :getfield || opcode == :putfield
    Instruction.new(pc, opcode, immediates, descr)
  end

  def command(cmd)
    output, status = Open3.capture2e(cmd.to_s)
    if status.signaled? || status.exitstatus != 0
      raise "Command failed '#{cmd}':\n#{output}"
    end
    output
  end
end

