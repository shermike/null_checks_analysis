# frozen_string_literal: true

require_relative 'ir/class'
require_relative 'ir_builder_javap'
require_relative 'null_check_analysis'

def main
  raise "Input class file is required" unless ARGV[0]
  cls = IrBuilderJavap.new.build_from_file(ARGV[0])
  cls.methods.each do |method|
    NullCheckAnalysis.new(method).run
  end
end

main
