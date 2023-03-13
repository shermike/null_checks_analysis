# frozen_string_literal: true

require 'ostruct'

class Bytecode
  INFO = Hash[*File.readlines("#{__dir__}/bytecode.csv", chomp: true)
                   .select { |x| !x.start_with? '#' }
                   .map { |x| x.split(', ').map(&:strip) }
                   .map { |x| [x[1].to_sym, OpenStruct.new(code: x[0].to_i,
                                                           opcode: x[1].to_sym,
                                                           format: x[2],
                                                           return: x[3].to_sym,
                                                           stack: x[4].to_i,
                                                           pop: x[5].to_i,
                                                           push: x[6].to_i)]}.flatten]
end