# frozen_string_literal: true

require_relative 'ir/method'

def rpo(method, &block)
  ordered = []
  visited = {}
  def walk(bb, visited, ordered)
    visited[bb] = true
    bb.succs.each do |succ|
      walk(succ, visited, ordered) unless succ.nil? || visited.include?(succ)
    end
    ordered << bb
  end
  walk(method.entry_bb, visited, ordered)
  ordered.reverse.each { |bb| block.call(bb) }
end
