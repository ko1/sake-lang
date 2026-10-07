require 'date'

class TimesheetPay
  def initialize
    @employees = {}  # id -> {name:, rate:}
    @shifts = {}  # id -> [{date:, start_time:, end_time:, break_mins:}]
    @line_num = 0
  end

  def run(input)
    input.each_line do |line|
      @line_num += 1
      process_line(line)
    end
    output_report
  end

  private

  def process_line(line)
    line = line.strip
    return if line.empty?

    parts = line.split
    command = parts[0]

    case command
    when 'EMP'
      process_emp(parts)
    when 'SHIFT'
      process_shift(parts)
    else
      puts "line #{@line_num}: error: unknown command"
    end
  end

  def validate_emp_id(id)
    id =~ /^E\d{3}$/
  end

  def validate_name(name)
    name =~ /^[A-Za-z]{1,10}$/
  end

  def validate_rate(rate)
    rate =~ /^\d+\.\d{2}$/ && rate.to_f >= 0
  end

  def validate_date(date)
    parts = date.split('-')
    return false unless parts.length == 3
    year, month, day = parts.map(&:to_i)
    return false if year < 1970 || year > 2099
    begin
      Date.new(year, month, day)
      true
    rescue
      false
    end
  end

  def validate_time(time)
    parts = time.split(':')
    return false unless parts.length == 2
    hour, min = parts.map(&:to_i)
    hour >= 0 && hour <= 23 && min >= 0 && min <= 59
  end

  def process_emp(parts)
    unless parts.length == 4
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    id = parts[1]
    name = parts[2]
    rate = parts[3]

    unless validate_emp_id(id)
      puts "line #{@line_num}: error: bad id"
      return
    end

    unless validate_name(name)
      puts "line #{@line_num}: error: bad name"
      return
    end

    unless validate_rate(rate)
      puts "line #{@line_num}: error: bad rate"
      return
    end

    if @employees[id]
      puts "line #{@line_num}: error: duplicate employee #{id}"
      return
    end

    @employees[id] = {name: name, rate: rate.to_f}
  end

  def process_shift(parts)
    unless parts.length == 5 || parts.length == 6
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    emp_id = parts[1]
    date = parts[2]
    start_time = parts[3]
    end_time = parts[4]
    break_mins = parts.length == 6 ? parts[5].to_i : 0

    unless validate_emp_id(emp_id)
      puts "line #{@line_num}: error: bad id"
      return
    end

    unless @employees[emp_id]
      puts "line #{@line_num}: error: unknown employee #{emp_id}"
      return
    end

    unless validate_date(date)
      puts "line #{@line_num}: error: bad date"
      return
    end

    unless validate_time(start_time)
      puts "line #{@line_num}: error: bad time"
      return
    end

    unless validate_time(end_time)
      puts "line #{@line_num}: error: bad time"
      return
    end

    if parts.length == 6
      unless parts[5] =~ /^\d+$/
        puts "line #{@line_num}: error: bad break"
        return
      end
      break_mins = parts[5].to_i
    else
      break_mins = 0
    end

    # Parse times
    start_parts = start_time.split(':').map(&:to_i)
    start_hour, start_min = start_parts[0], start_parts[1]
    end_parts = end_time.split(':').map(&:to_i)
    end_hour, end_min = end_parts[0], end_parts[1]

    # Calculate duration
    start_mins_from_midnight = start_hour * 60 + start_min
    end_mins_from_midnight = end_hour * 60 + end_min

    if end_mins_from_midnight <= start_mins_from_midnight && end_mins_from_midnight != start_mins_from_midnight
      # Shift spans to next day
      duration_mins = (24 * 60 - start_mins_from_midnight) + end_mins_from_midnight
    elsif end_mins_from_midnight == start_mins_from_midnight
      # 24 hour shift
      duration_mins = 24 * 60
    else
      # Same day
      duration_mins = end_mins_from_midnight - start_mins_from_midnight
    end

    # Check break is less than shift length
    if break_mins >= duration_mins
      puts "line #{@line_num}: error: bad break"
      return
    end

    # Apply minimum break rule
    if duration_mins > 6 * 60 && break_mins < 30
      break_mins = 30
    end

    # Check for overlaps
    @shifts[emp_id] ||= []
    new_shift = {
      date: date,
      start_hour: start_hour,
      start_min: start_min,
      end_hour: end_hour,
      end_min: end_min,
      break_mins: break_mins,
      duration_mins: duration_mins,
      worked_mins: duration_mins - break_mins
    }

    # Check overlap with existing shifts
    if shifts_overlap?(emp_id, new_shift)
      puts "line #{@line_num}: error: overlapping shift"
      return
    end

    @shifts[emp_id].push(new_shift)
  end

  def shifts_overlap?(emp_id, new_shift)
    return false unless @shifts[emp_id]

    new_date = new_shift[:date]
    new_start_hour = new_shift[:start_hour]
    new_start_min = new_shift[:start_min]
    new_end_hour = new_shift[:end_hour]
    new_end_min = new_shift[:end_min]

    @shifts[emp_id].each do |shift|
      if shifts_overlap_pair?(new_date, new_start_hour, new_start_min, new_end_hour, new_end_min,
                               shift[:date], shift[:start_hour], shift[:start_min], shift[:end_hour], shift[:end_min])
        return true
      end
    end

    false
  end

  def shifts_overlap_pair?(date1, start_h1, start_m1, end_h1, end_m1,
                           date2, start_h2, start_m2, end_h2, end_m2)
    # Convert dates to comparable values (year-month-day)
    # Convert times to minutes from start of day

    # Get the actual date objects
    date1_obj = Date.parse(date1)
    date2_obj = Date.parse(date2)

    # For each shift, find the actual time range
    # A shift on date D from start_time to end_time spans from:
    # date D at start_time to date (D or D+1) at end_time

    start1_mins = start_h1 * 60 + start_m1
    end1_mins = end_h1 * 60 + end_m1
    start2_mins = start_h2 * 60 + start_m2
    end2_mins = end_h2 * 60 + end_m2

    # If end is before start, it goes to next day
    end1_date = date1_obj
    end1_date = end1_date + 1 if end1_mins < start1_mins && end1_mins != start1_mins

    end2_date = date2_obj
    end2_date = end2_date + 1 if end2_mins < start2_mins && end2_mins != start2_mins

    # Special case: if start == end, it's a 24-hour shift
    if start1_mins == end1_mins
      end1_mins = 24 * 60
      end1_date = date1_obj + 1
    end

    if start2_mins == end2_mins
      end2_mins = 24 * 60
      end2_date = date2_obj + 1
    end

    # Now check if the ranges overlap
    # Range 1: date1_obj, start1_mins to end1_date, end1_mins
    # Range 2: date2_obj, start2_mins to end2_date, end2_mins

    start_time1 = date1_obj.to_time.to_i * 60 + start1_mins
    end_time1 = end1_date.to_time.to_i * 60 + end1_mins
    start_time2 = date2_obj.to_time.to_i * 60 + start2_mins
    end_time2 = end2_date.to_time.to_i * 60 + end2_mins

    # Ranges overlap if: start1 < end2 and start2 < end1
    start_time1 < end_time2 && start_time2 < end_time1
  end

  def output_report
    # Calculate pay for each employee
    employee_data = {}

    @employees.keys.sort.each do |emp_id|
      regular_mins = 0
      overtime_mins = 0

      if @shifts[emp_id]
        # Sort shifts by date, then by start time
        sorted_shifts = @shifts[emp_id].sort_by { |s| [s[:date], s[:start_hour] * 60 + s[:start_min]] }

        # Track daily and weekly regular hours
        daily_hours = {}  # date -> minutes worked
        weekly_regular = {}  # week_start_date -> regular minutes

        sorted_shifts.each do |shift|
          date = shift[:date]
          worked = shift[:worked_mins]

          # Daily limit: first 8 hours are regular
          daily_hours[date] ||= 0
          daily_limit_remaining = 8 * 60 - daily_hours[date]
          daily_regular = [worked, daily_limit_remaining].min

          # Weekly limit: first 40 hours are regular
          week_start = week_start_date(Date.parse(date))
          weekly_regular[week_start] ||= 0
          weekly_limit_remaining = 40 * 60 - weekly_regular[week_start]

          # Take from daily_regular up to weekly limit
          regular_from_shift = [daily_regular, weekly_limit_remaining].min
          overtime_from_shift = worked - regular_from_shift

          regular_mins += regular_from_shift
          overtime_mins += overtime_from_shift

          daily_hours[date] = daily_hours[date] + worked
          weekly_regular[week_start] = weekly_regular[week_start] + regular_from_shift
        end
      end

      rate = @employees[emp_id][:rate]
      regular_pay = (regular_mins.to_f / 60) * rate
      overtime_pay = (overtime_mins.to_f / 60) * rate * 1.5
      total_pay = regular_pay + overtime_pay

      # Round half up
      total_pay = (total_pay * 100).round / 100.0

      employee_data[emp_id] = {
        name: @employees[emp_id][:name],
        regular_mins: regular_mins,
        overtime_mins: overtime_mins,
        pay: total_pay
      }
    end

    # Output table
    puts "%-4s %-10s %8s %8s %10s" % ["id", "name", "regular", "overtime", "pay"]

    total_regular = 0
    total_overtime = 0
    total_pay = 0.0

    employee_data.each do |emp_id, data|
      regular_time = format_time(data[:regular_mins])
      overtime_time = format_time(data[:overtime_mins])
      pay_str = format("%.2f", data[:pay])
      puts "%-4s %-10s %8s %8s %10s" % [emp_id, data[:name], regular_time, overtime_time, pay_str]

      total_regular += data[:regular_mins]
      total_overtime += data[:overtime_mins]
      total_pay += data[:pay]
    end

    # Total row
    total_regular_time = format_time(total_regular)
    total_overtime_time = format_time(total_overtime)
    total_pay_str = format("%.2f", total_pay)
    puts "%-4s %-10s %8s %8s %10s" % ["", "total", total_regular_time, total_overtime_time, total_pay_str]
  end

  def week_start_date(date)
    # Monday = 1, Sunday = 7
    days_since_monday = (date.wday - 1) % 7
    date - days_since_monday
  end

  def format_time(minutes)
    hours = minutes / 60
    mins = minutes % 60
    "#{hours}:#{format('%02d', mins)}"
  end
end

sim = TimesheetPay.new
sim.run(STDIN.read)
