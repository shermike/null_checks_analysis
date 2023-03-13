#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'optparse'
require 'ostruct'
require 'tmpdir'

require_relative '../null_check_analysis'
require_relative '../ir_builder_javap'

$checks_count = 0
$files_count = 0

$options = OpenStruct.new
OptionParser.new do |opts|
  opts.on('--glob=STRING', 'Glob to find test files')
  opts.on('-v', '--verbose', 'Verbose logging')
end.parse!(into: $options)

def options; $options; end

raise "Please provide '--glob' argument" unless options.glob

def command(cmd)
  puts "COMMAND: #{cmd}" if options.verbose
  output, status = Open3.capture2e(cmd.to_s)
  if status.signaled? || status.exitstatus != 0
    raise "Command failed '#{cmd}':\n#{output}"
  end
  puts output if options.verbose
  output
end

def run_test(filename)
  puts "Run test: #{filename}"
  true_checks = []
  false_checks = []

  File.readlines(filename).each_with_index do |line, index|
    true_checks << index + 2 if line.include? '// NEXTLINE: ALWAYS_TRUE_NULL_CHECK'
    false_checks << index + 2 if line.include? '// NEXTLINE: ALWAYS_FALSE_NULL_CHECK'
  end
  basename = File.basename(filename, '.*')
  classname = "#{Dir.tmpdir}/test/#{basename}.class"

  command("javac -d #{Dir.tmpdir} #{filename}")

  disasm = command("javap -p -l -c #{classname}")
  cls = IrBuilderJavap.new.build_from_lines(disasm.split("\n"), filename)

  true_lines = []
  false_lines = []
  cls.methods.each do |method|
    nca = NullCheckAnalysis.new(method, quiet = !options.verbose)
    nca.run
    # It is not an error, we treat true lines as false, and vise versa, because javac inverts opcode for expressions
    # like this `if(x == null)`: it inserts `ifnonull` here and swap successors for the basic block.
    false_lines.append(*nca.true_lines)
    true_lines.append(*nca.false_lines)
  end
  true_lines.sort!
  false_lines.sort!

  raise "FAILED TRUE CHECKS: expected lines: #{true_checks}, result lines: #{true_lines}" if true_checks != true_lines
  raise "FAILED FALSE CHECKS: expected lines: #{false_checks}, result lines: #{false_lines}" if false_checks != false_lines

  $files_count += 1
  $checks_count += true_lines.size + false_lines.size
end

def main
  Dir.glob(options.glob) { |file| run_test(file) }
  puts "PASSED! Files: #{$files_count}, checks: #{$checks_count}"
end

main