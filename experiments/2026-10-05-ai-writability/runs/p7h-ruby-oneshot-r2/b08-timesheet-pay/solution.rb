#!/usr/bin/env ruby

require 'date'

def valid_emp_id?(s)
  s =~ /^E\d{3}$/
end

def valid_name?(s)
  s =~ /^[A-Za-z]{1,10}$/
end

def valid_rate?(s)
  s =~ /^\d+\.\d{2}$/
end

def valid_date?(s)
  return false unless s =~ /^\d{4}-\d{2}-\d{2}$/
  begin
    year, month, day = s.split('-').map(&:to_i)
    return false if year < 1970 || year > 2099
    Date.new(year, month, day)
    true
  rescue
    false
  end
end

def valid_time?(s)
  return false unless s =~ /^\d{2}:\d{2}$/
  hour, min = s.split(':').map(&:to_i)
  hour >= 0 && hour < 24 && min >= 0 && min < 60
end

def get_week_start(date)
  date -= date.wday
end

employees = {}      # id -> {name, rate}
shifts = {}         # id -> [{date, start_min, end_min, worked_min}]
all_emp_ids = []    # in order of appearance

$stdin.each_line.with_index do |line, idx|
  line_num = idx + 1
  line = line.chomp
  next if line.empty?

  fields = line.split
  next if fields.empty?

  cmd = fields[0]
  case cmd
  when "EMP"
    if fields.size != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    id = fields[1]
    name = fields[2]
    rate_str = fields[3]

    if !valid_emp_id?(id)
      puts "line #{line_num}: error: bad id"
      next
    end
    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end
    if !valid_rate?(rate_str)
      puts "line #{line_num}: error: bad rate"
      next
    end
    if employees[id]
      puts "line #{line_num}: error: duplicate employee #{id}"
      next
    end

    rate = rate_str.to_f
    employees[id] = {name: name, rate: rate}
    all_emp_ids << id

  when "SHIFT"
    if fields.size != 5 && fields.size != 6
      puts "line #{line_num}: error: wrong field count"
      next
    end

    emp_id = fields[1]
    date_str = fields[2]
    start_str = fields[3]
    end_str = fields[4]
    break_str = fields[5] || "0"

    if !valid_emp_id?(emp_id)
      puts "line #{line_num}: error: bad id"
      next
    end
    if !employees[emp_id]
      puts "line #{line_num}: error: unknown employee #{emp_id}"
      next
    end
    if !valid_date?(date_str)
      puts "line #{line_num}: error: bad date"
      next
    end
    if !valid_time?(start_str)
      puts "line #{line_num}: error: bad time"
      next
    end
    if !valid_time?(end_str)
      puts "line #{line_num}: error: bad time"
      next
    end

    start_h, start_m = start_str.split(':').map(&:to_i)
    end_h, end_m = end_str.split(':').map(&:to_i)
    start_min = start_h * 60 + start_m
    end_min = end_h * 60 + end_m

    if end_min <= start_min
      end_min += 24 * 60
    end

    shift_len = end_min - start_min
    min_break = break_str.to_i

    if min_break < 0 || min_break >= shift_len
      puts "line #{line_num}: error: bad break"
      next
    end

    # Enforce minimum break for long shifts
    if shift_len > 6 * 60 && min_break < 30
      min_break = 30
    end

    worked_min = shift_len - min_break

    # Check for overlapping shifts
    date_obj = Date.parse(date_str)
    overlaps = false
    (shifts[emp_id] || []).each do |s|
      s_date = Date.parse(s[:date])
      s_start = s[:start_min]
      s_end = s[:end_min]
      s_len = s_end - s_start

      shift_start_min = start_min
      shift_end_min = end_min

      if s_start >= 24 * 60
        s_date = s_date.next_day
        s_start -= 24 * 60
        s_end -= 24 * 60
      end

      if shift_end_min >= 24 * 60
        next_date = date_obj.next_day
        shift_start = shift_start_min
        shift_end = shift_end_min - 24 * 60
        if s_date == date_obj && s_end > shift_start && s_start < 24 * 60
          overlaps = true
          break
        end
        if s_date == next_date && s_start < shift_end && s_end > 0
          overlaps = true
          break
        end
      else
        if s_date == date_obj && s_end > shift_start_min && s_start < shift_end_min
          overlaps = true
          break
        end
      end
    end

    if overlaps
      puts "line #{line_num}: error: overlapping shift"
      next
    end

    shifts[emp_id] ||= []
    shifts[emp_id] << {date: date_str, start_min: start_min, end_min: end_min, worked_min: worked_min}

  else
    puts "line #{line_num}: error: unknown command"
  end
end

# Calculate pay
pay_data = {}
all_emp_ids.each do |emp_id|
  emp = employees[emp_id]
  regular_min = 0
  overtime_min = 0

  emp_shifts = shifts[emp_id] || []
  emp_shifts.sort_by { |s| [s[:date], s[:start_min]] }.each do |shift|
    date = Date.parse(shift[:date])
    worked = shift[:worked_min]
    start_min = shift[:start_min]
    end_min = shift[:end_min]

    # Find week for this shift (Monday=0)
    week_start = get_week_start(date)

    # Daily overtime
    daily_regular = 0
    daily_overtime = worked
    daily_worked_so_far = (emp_shifts.select do |s|
      Date.parse(s[:date]) == date && [s[:date], s[:start_min]] < [shift[:date], shift[:start_min]]
    end.sum { |s| s[:worked_min] }) || 0

    if daily_worked_so_far < 8 * 60
      take_regular = [worked, (8 * 60 - daily_worked_so_far)].min
      daily_regular = take_regular
      daily_overtime = worked - daily_regular
    end

    # Weekly overtime
    week_regular_so_far = (emp_shifts.select do |s|
      s_date = Date.parse(s[:date])
      s_week = get_week_start(s_date)
      s_week == week_start && [s[:date], s[:start_min]] < [shift[:date], shift[:start_min]]
    end.sum { |s|
      s_daily_worked_so_far = (emp_shifts.select do |s2|
        Date.parse(s2[:date]) == Date.parse(s[:date]) && [s2[:date], s2[:start_min]] < [s[:date], s[:start_min]]
      end.sum { |s2| s2[:worked_min] }) || 0
      [[s[:worked_min], (8 * 60 - s_daily_worked_so_far)].min, 0].max
    end) || 0

    if week_regular_so_far < 40 * 60
      week_take_regular = [daily_regular, (40 * 60 - week_regular_so_far)].min
      week_overtime_from_regular = daily_regular - week_take_regular
      regular_min += week_take_regular
      overtime_min += daily_overtime + week_overtime_from_regular
    else
      overtime_min += daily_regular + daily_overtime
    end
  end

  rate = emp[:rate]
  pay = (regular_min * rate + overtime_min * rate * 1.5) / 60
  pay = (pay * 100).round / 100.0

  pay_data[emp_id] = {name: emp[:name], regular_min: regular_min, overtime_min: overtime_min, pay: pay}
end

# Output
puts format("%-4s %-10s %8s %8s %10s", "id", "name", "regular", "overtime", "pay")
total_regular = 0
total_overtime = 0
total_pay = 0
all_emp_ids.each do |emp_id|
  data = pay_data[emp_id]
  reg_h = data[:regular_min] / 60
  reg_m = data[:regular_min] % 60
  ot_h = data[:overtime_min] / 60
  ot_m = data[:overtime_min] % 60
  puts format("%-4s %-10s %8s %8s %10s", emp_id, data[:name], "#{reg_h}:#{format('%02d', reg_m)}", "#{ot_h}:#{format('%02d', ot_m)}", format('%.2f', data[:pay]))
  total_regular += data[:regular_min]
  total_overtime += data[:overtime_min]
  total_pay += data[:pay]
end

reg_h = total_regular / 60
reg_m = total_regular % 60
ot_h = total_overtime / 60
ot_m = total_overtime % 60
puts format("%-4s %-10s %8s %8s %10s", "", "total", "#{reg_h}:#{format('%02d', reg_m)}", "#{ot_h}:#{format('%02d', ot_m)}", format('%.2f', total_pay))
