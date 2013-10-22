require 'rspec'
require 'debugger'
require 'fileutils'
require 'find'

require File.expand_path(File.join('..', 'AO_Xcodeproj', 'lib', 'ao_xcodeproj.rb'))

module Spec_helper

  def self.find_helper(file_path, query)
    results = []
    Find.find(file_path) do |path|
      results << path
      file_path = path
    end
    
    for file in results
      if file[query] == file_path[query] && file_path[query] != nil
        return file_path
      end
    end
  end


end
