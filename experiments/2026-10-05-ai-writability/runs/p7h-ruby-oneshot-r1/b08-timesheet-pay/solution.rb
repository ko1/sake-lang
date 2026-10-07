#!/usr/bin/env ruby

require 'date'

class TimesheetPay
  def initialize
    @employees = {}
    @shifts = {}
    @line_errors = {}
  end

  def run
    line_num = 0
    STDIN.each_line do |line|
      line_num += 1
      line.strip!
      next if line.empty?

      parts = line.split
      command = parts[0]

      case command
      when 'EMP'
        handle_emp(line_num, parts)
      when 'SHIFT'
        handle_shift(line_num, parts)
      else
        puts "line #{line_num}: error: unknown command"
      end
    end

    print_report
  end

  def handle_emp(line_num, parts)
    if parts.size != 4
      puts "line #{line_num}: error: wrong field count"
      return
    end

    id = parts[1]
    name = parts[2]
    rate_str = parts[3]

    if !valid_emp_id?(id)
      puts "line #{line_num}: error: bad id"
      return
    end
    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      return
    end
    if !valid_rate?(rate_str)
      puts "line #{line_num}: error: bad rate"
      return
    end
    if @employees[id]
      puts "line #{line_num}: error: duplicate employee ID"
      return
    end

    @employees[id] = { name: name, rate: rate_str.to_f }
    @shifts[id] = []
  end

  def handle_shift(line_num, parts)
    if parts.size < 5 || parts.size > 6
      puts "line #{line_num}: error: wrong field count"
      return
    end

    id = parts[1]
    date_str = parts[2]
    start_str = parts[3]
    end_str = parts[4]
    break_str = parts[5] || '0'

    if !valid_emp_id?(id)
      puts "line #{line_num}: error: bad id"
      return
    end
    if !@employees[id]
      puts "line #{line_num}: error: unknown employee #{id}"
      return
    end
    if !valid_date?(date_str)
      puts "line #{line_num}: error: bad date"
      return
    end
    if !valid_time?(start_str)
      puts "line #{line_num}: error: bad time"
      return
    end
    if !valid_time?(end_str)
      puts "line #{line_num}: error: bad time"
      return
    end
    if !valid_break?(break_str)
      puts "line #{line_num}: error: bad break"
      return
    end

    start_h, start_m = start_str.split(':').map(&:to_i)
    end_h, end_m = end_str.split(':').map(&:to_i)
    break_min = break_str.to_i

    start_date = Date.parse(date_str)
    end_date = start_date

    start_total_min = start_h * 60 + start_m
    end_total_min = end_h * 60 + end_m

    if end_total_min < start_total_min
      end_date = start_date + 1
      end_total_min += 24 * 60
    elsif end_total_min == start_total_min
      end_total_min = 24 * 60
    end

    shift_length = end_total_min - start_total_min

    if break_min >= shift_length
      puts "line #{line_num}: error: bad break"
      return
    end

    if shift_length > 6 * 60 && break_min < 30
      break_min = 30
    end

    worked_min = shift_length - break_min

    shift = {
      date: start_date,
      start_time: start_total_min,
      end_time: end_total_min,
      worked_min: worked_min,
      break_min: break_min
    }

    if overlaps?(@shifts[id], shift)
      puts "line #{line_num}: error: overlapping shift"
      return
    end

    @shifts[id] << shift
  end

  def overlaps?(existing_shifts, new_shift)
    existing_shifts.each do |shift|
      next unless shift[:date] == new_shift[:date]
      if (new_shift[:start_time] < shift[:end_time]) && (new_shift[:end_time] > shift[:start_time])
        return true
      end
    end
    false
  end

  def valid_emp_id?(id)
    /^E\d{3}$/.match?(id)
  end

  def valid_name?(name)
    /^[A-Za-z]{1,10}$/.match?(name)
  end

  def valid_rate?(rate)
    /^\d+\.\d{2}$/.match?(rate) && rate.to_f > 0
  end

  def valid_date?(date_str)
    begin
      d = Date.parse(date_str)
      d.year >= 1970 && d.year <= 2099
    rescue
      false
    end
  end

  def valid_time?(time_str)
    /^\d{2}:\d{2}$/.match?(time_str) && time_str.split(':')[0].to_i < 24 && time_str.split(':')[1].to_i < 60
  end

  def valid_break?(break_str)
    /^\d+$/.match?(break_str)
  end

  def print_report
    puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")

    total_regular_min = 0
    total_overtime_min = 0
    total_pay = 0.0

    @employees.keys.sort.each do |id|
      emp = @employees[id]
      emp_shifts = @shifts[id].sort_by { |s| [s[:date], s[:start_time]] }

      regular_min = 0
      overtime_min = 0

      daily_worked = {}
      weekly_worked = {}

      emp_shifts.each do |shift|
        date = shift[:date]
        week_start = date - (date.wday - 1)

        daily_worked[date] ||= 0
        weekly_worked[week_start] ||= 0

        worked = shift[:worked_min]

        daily_so_far = daily_worked[date]
        if daily_so_far + worked > 8 * 60
          daily_overtime = daily_so_far + worked - 8 * 60
          daily_regular = worked - daily_overtime
        else
          daily_regular = worked
          daily_overtime = 0
        end

        weekly_so_far = weekly_worked[week_start]
        already_regular = weekly_so_far
        if already_regular + daily_regular > 40 * 60
          weekly_overtime = already_regular + daily_regular - 40 * 60
          final_regular = daily_regular - weekly_overtime
          final_overtime = daily_overtime + weekly_overtime
        else
          final_regular = daily_regular
          final_overtime = daily_overtime
        end

        regular_min += final_regular
        overtime_min += final_overtime

        daily_worked[date] += worked
        weekly_worked[week_start] += worked
      end

      pay = (regular_min * emp[:rate] + overtime_min * emp[:rate] * 1.5) / 60.0
      pay = (pay * 100).round / 100.0

      regular_hours = regular_min / 60
      regular_mins = regular_min % 60
      overtime_hours = overtime_min / 60
      overtime_mins = overtime_min % 60

      puts format("%-4s %-10s %8s %8s %10s",
                  id,
                  emp[:name],
                  "#{regular_hours}:#{format('%02d', regular_mins)}",
                  "#{overtime_hours}:#{format('%02d', overtime_mins)}",
                  format('%.2f', pay))

      total_regular_min += regular_min
      total_overtime_min += overtime_min
      total_pay += pay
    end

    total_regular_hours = total_regular_min / 60
    total_regular_mins = total_regular_min % 60
    total_overtime_hours = total_overtime_min / 60
    total_overtime_mins = total_overtime_min % 60

    puts format("%-4s %-10s %8s %8s %10s",
                "",
                "total",
                "#{total_regular_hours}:#{format('%02d', total_regular_mins)}",
                "#{total_overtime_hours}:#{format('%02d', total_overtime_mins)}",
                format('%.2f', total_pay))
  end
end

pay = TimesheetPay.new
pay.run
