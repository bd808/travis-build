require 'fileutils'

module SpecHelpers
  module Sexp
    def sexp_fold(fold, sexp)
      [:fold, fold, [:cmds, [sexp]]]
    end

    def sexp_includes?(sexp, part)
      if sexp == part || sexp.include?(part)
        true
      elsif sexp.is_a?(Array)
        case sexp.first
        when Array
          sexp.detect { |sexp| sexp_includes?(sexp, part) }
        when :script, :cmds, :then, :else
          sexp_includes?(sexp[1], part)
        when :fold
          sexp_includes?(sexp[2], part)
        when :if, :elif
          sexp_includes?(sexp[2..-1], part)
        end
      else
        false
      end
    end

    def sexp_find(sexp, *parts)
      parts.map { |part| sexp = sexp_filter(sexp, part).first }.last
    end

    def sexp_filter(sexp, part, result = [])
      return result unless sexp.is_a?(Array)
      result << sexp if sexp[0, part.length] == part
      sexp.each { |sexp| sexp_filter(sexp, part, result) }
      result
    end

    def store_example(name = nil)
      const_name = described_class.name.split('::').last.gsub(/([A-Z]+)/,'_\1').gsub(/^_/, '').downcase
      name = [const_name, name].compact.join('-').gsub(' ', '_')

      case described_class
      when Travis::Build::Script
        type = :build
        code = script.compile
      else
        type = :addon
        code = Travis::Shell.generate(subject)
      end

      FileUtils.mkdir_p('examples') unless File.directory?('examples')
      File.open("examples/#{type}-#{name}.sh", 'w+') { |f| f.write(code) }
    end
  end
end
