#!/usr/bin/env ruby

require 'date'

class TimesheetPayroll
  def initialize
    @employees = {}  # id => {name:, rate:}
    @shifts = {}  # id => [{date:, start_time:, end_time:, break_mins:, worked_mins:}, ...]
    @line_num = 0
  end

  def run
    STDIN.each_line do |line|
      @line_num += 1
      line = line.strip
      next if line.empty?

      process_line(line)
    end

    print_report
  end

  private

  def process_line(line)
    parts = line.split
    return error("unknown command") if parts.empty?

    command = parts[0]

    case command
    when "EMP"
      return error("wrong field count") if parts.size != 4
      process_emp(parts)
    when "SHIFT"
      return error("wrong field count") if parts.size < 5 || parts.size > 6
      process_shift(parts)
    else
      error("unknown command")
    end
  end

  def process_emp(parts)
    id = parts[1]
    name = parts[2]
    rate = parts[3]

    return unless validate_emp_id(id)
    return unless validate_name(name)
    return unless validate_rate(rate)
    return if duplicate_emp(id)

    @employees[id] = {name: name, rate: rate.to_f}
  end

  def process_shift(parts)
    id = parts[1]
    date = parts[2]
    start_time = parts[3]
    end_time = parts[4]
    break_mins = parts[5]&.to_i || 0

    return unless validate_emp_id(id)
    return unless employee_exists(id)
    return unless validate_date(date)
    return unless validate_time(start_time, "bad time")
    return unless validate_time(end_time, "bad time")
    return unless validate_break(break_mins)

    date_obj = Date.strptime(date, '%Y-%m-%d')
    start_mins = time_to_mins(start_time)
    end_mins = time_to_mins(end_time)

    # If end_time <= start_time, it's next day
    if end_mins <= start_mins
      end_date = date_obj + 1
      total_mins = (24 * 60 - start_mins) + end_mins
    else
      end_date = date_obj
      total_mins = end_mins - start_mins
    end

    # Apply minimum break for long shifts
    actual_break = break_mins
    if total_mins > 6 * 60 && break_mins < 30
      actual_break = 30
    end

    return unless actual_break < total_mins

    worked_mins = total_mins - actual_break

    shift = {
      date: date_obj,
      start_time: start_mins,
      end_time: end_mins,
      end_date: end_date,
      break_mins: actual_break,
      worked_mins: worked_mins
    }

    # Check for overlapping shifts
    return if overlapping_shift?(id, date_obj, start_mins, end_mins, end_date)

    @shifts[id] ||= []
    @shifts[id] << shift
  end

  def validate_emp_id(id)
    return true if id.match?(/^E\d{3}$/)
    error("bad id")
    false
  end

  def validate_name(name)
    return true if name.match?(/^[A-Za-z]{1,10}$/)
    error("bad name")
    false
  end

  def validate_rate(rate)
    return true if rate.match?(/^\d+\.\d{2}$/)
    error("bad rate")
    false
  end

  def duplicate_emp(id)
    if @employees[id]
      error("duplicate employee ID")
      return true
    end
    false
  end

  def employee_exists(id)
    return true if @employees[id]
    error("unknown employee ID")
    false
  end

  def validate_date(date)
    begin
      d = Date.strptime(date, '%Y-%m-%d')
      # Check if year is in range 1970-2099
      return true if d.year >= 1970 && d.year <= 2099
    rescue
    end
    error("bad date")
    false
  end

  def validate_time(time, msg)
    return true if time.match?(/^([01]\d|2[0-3]):([0-5]\d)$/)
    error(msg)
    false
  end

  def validate_break(break_mins)
    return true if break_mins >= 0
    error("bad break")
    false
  end

  def time_to_mins(time)
    parts = time.split(':')
    parts[0].to_i * 60 + parts[1].to_i
  end

  def overlapping_shift?(id, date, start_mins, end_mins, end_date)
    return false if !@shifts[id]

    @shifts[id].each do |existing|
      # Both shifts on same day
      if existing[:date] == date && existing[:end_date] == date
        # Check overlap on this date
        if !(end_mins <= existing[:start_time] || start_mins >= existing[:end_time])
          error("overlapping shift")
          return true
        end
      elsif existing[:date] == date && existing[:end_date] > date
        # Existing shift spans multiple days, started on same date
        if start_mins < existing[:end_time] || end_mins > 0
          # Need more careful checking
          if start_mins < 24 * 60 && end_mins > 0
            error("overlapping shift")
            return true
          end
        end
      elsif existing[:end_date] == date && existing[:date] < date
        # Existing shift ended on this date, started earlier
        if start_mins < existing[:end_time]
          error("overlapping shift")
          return true
        end
      end
    end

    false
  end

  def print_report
    # Sort employees by ID
    emp_ids = @employees.keys.sort

    puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")

    total_regular = 0
    total_overtime = 0
    total_pay = 0.0

    emp_ids.each do |id|
      emp = @employees[id]
      regular_mins, overtime_mins = calculate_pay_mins(id)

      regular_hours = regular_mins.to_f / 60
      overtime_hours = overtime_mins.to_f / 60
      pay = (regular_mins * emp[:rate] + overtime_mins * emp[:rate] * 1.5) / 60

      pay = (pay * 100).round / 100.0

      total_regular += regular_mins
      total_overtime += overtime_mins
      total_pay += pay

      regular_str = mins_to_hm(regular_mins)
      overtime_str = mins_to_hm(overtime_mins)
      pay_str = format('%.2f', pay)

      puts format("%-4s %-10s %8s %8s %10s", id, emp[:name], regular_str, overtime_str, pay_str)
    end

    total_regular_str = mins_to_hm(total_regular)
    total_overtime_str = mins_to_hm(total_overtime)
    total_pay = (total_pay * 100).round / 100.0
    total_pay_str = format('%.2f', total_pay)

    puts format("%-4s %-10s %8s %8s %10s", "", "total", total_regular_str, total_overtime_str, total_pay_str)
  end

  def calculate_pay_mins(id)
    return [0, 0] unless @shifts[id]

    shifts = @shifts[id].sort_by { |s| [s[:date], s[:start_time]] }

    regular_mins = 0
    overtime_mins = 0
    daily_totals = {}  # date => worked_mins
    weekly_totals = {}  # week_start_date => worked_mins

    shifts.each do |shift|
      worked = shift[:worked_mins]
      date = shift[:date]

      # Day of week: 0=Monday, 6=Sunday
      dow = date.wday == 0 ? 6 : date.wday - 1
      week_start = date - dow

      daily_totals[date] ||= 0
      weekly_totals[week_start] ||= 0

      # Calculate how much is overtime based on daily limit
      daily_before = daily_totals[date]
      daily_after = daily_before + worked

      if daily_after > 8 * 60
        # Some of this shift is overtime on daily basis
        daily_regular = [8 * 60 - daily_before, 0].max
        daily_overtime = worked - daily_regular
      else
        daily_regular = worked
        daily_overtime = 0
      end

      # Calculate how much is overtime based on weekly limit
      weekly_before = weekly_totals[week_start]
      weekly_after = weekly_before + daily_regular

      if weekly_after > 40 * 60
        # Some of the regular hours are actually overtime on weekly basis
        weekly_regular = [40 * 60 - weekly_before, 0].max
        weekly_overtime = daily_regular - weekly_regular
      else
        weekly_regular = daily_regular
        weekly_overtime = 0
      end

      regular_mins += weekly_regular
      overtime_mins += weekly_overtime + daily_overtime

      daily_totals[date] += worked
      weekly_totals[week_start] += worked
    end

    [regular_mins, overtime_mins]
  end

  def mins_to_hm(mins)
    hours = mins / 60
    mins_part = mins % 60
    "#{hours}:#{mins_part.to_s.rjust(2, '0')}"
  end

  def error(msg)
    puts "line #{@line_num}: error: #{msg}"
  end
end

system = TimesheetPayroll.new
system.run
