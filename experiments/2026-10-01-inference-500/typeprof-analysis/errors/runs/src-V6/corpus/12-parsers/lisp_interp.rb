class LispError < StandardError
end

class Env
  attr_reader :vars, :parent

  def initialize(parent)
    @vars = {}
    @parent = parent
  end

  def find(sym)
    cur = self
    while cur
      return cur if cur.vars.key?(sym)
      cur = cur.parent
    end
    raise LispError, "unbound symbol: #{sym}"
  end

  def lookup(sym) = find(sym).vars[sym]
  def define(sym, v) = @vars[sym] = v
  def assign(sym, v) = find(sym).vars[sym] = v
end

class Lambda
  attr_reader :params, :body, :env, :name

  def initialize(params, body, env, name)
    @params = params
    @body = body
    @env = env
    @name = name
  end
end

class Prim
  attr_reader :name, :fn

  def initialize(name, fn)
    @name = name
    @fn = fn
  end
end

def tokenize(src) = src.gsub(/;[^\n]*/, "").scan(/[()']|[^\s()']+/)

def read_form(tokens)
  t = tokens.shift
  raise LispError, "unexpected end of input" if !t    
  case t
  when "("
    list = []
    loop do
      nt = tokens.first
      raise LispError, "missing ')'" if !nt    
      if nt == ")"
        tokens.shift
        return list
      end
      list << read_form(tokens)
    end
  when ")" then raise LispError, "unexpected ')'"
  when "'" then [:quote, read_form(tokens)]
  when /\A-?\d+\z/ then t.to_i
  when "#t" then true
  when "#f" then false
  else t.to_sym
  end
end

def show(v)
  case v
  when Array then "(" + v.map { |x| show(x) }.join(" ") + ")"
  when true then "#t"
  when false then "#f"
  when Lambda then "#<lambda #{v.name || "anonymous"}>"
  when Prim then "#<primitive #{v.name}>"
  else v.to_s
  end
end

def truthy?(v) = v != false

def lisp_eval(x, env)
  case x
  when Symbol then env.lookup(x)
  when Integer, true, false then x
  when Array
    return x if x.empty?
    head = x[0]
    case head
    when :quote then x[1]
    when :if
      truthy?(lisp_eval(x[1], env)) ? lisp_eval(x[2], env) : (x.size > 3 ? lisp_eval(x[3], env) : false)
    when :define
      target = x[1]
      if target.is_a?(Array)
        name = target[0]
        env.define(name, Lambda.new(target.drop(1), x.drop(2), env, name))
        name
      else
        env.define(target, lisp_eval(x[2], env))
        target
      end
    when :set! then env.assign(x[1], lisp_eval(x[2], env))
    when :lambda then Lambda.new(x[1], x.drop(2), env, nil)
    when :let
      inner = Env.new(env)
      x[1].each { |(name, expr)| inner.define(name, lisp_eval(expr, env)) }
      eval_body(x.drop(2), inner)
    when :begin then eval_body(x.drop(1), env)
    when :cond
      x.drop(1).each do |clause|
        test = clause[0]
        return eval_body(clause.drop(1), env) if test == :else || truthy?(lisp_eval(test, env))
      end
      false
    else
      f = lisp_eval(head, env)
      args = x.drop(1).map { |a| lisp_eval(a, env) }
      apply(f, args)
    end
  end
end

def eval_body(forms, env)
  forms.reduce(false) { |_, form| lisp_eval(form, env) }
end

def apply(f, args)
  case f
  when Prim then f.fn.call(args)
  when Lambda
    if f.params.size != args.size
      raise LispError, "#{show(f)} expects #{f.params.size} args, got #{args.size}"
    end
    env = Env.new(f.env)
    f.params.zip(args).each { |p, a| env.define(p, a) }
    eval_body(f.body, env)
  else
    raise LispError, "not a procedure: #{show(f)}"
  end
end

PRIMITIVES = {
  :+ => ->(args) { args.sum },
  :* => ->(args) { args.reduce(1, :*) },
  :- => ->(args) { args.size == 1 ? -args[0] : args.drop(1).reduce(args[0], :-) },
  :/ => ->(args) { args[0] / args[1] },
  :< => ->(args) { args[0] < args[1] },
  :"=" => ->(args) { args[0] == args[1] },
  :car => lambda { |args|
    raise LispError, "car of empty list" if args[0].empty?
    args[0][0]
  },
  :cdr => ->(args) { args[0].drop(1) },
  :cons => ->(args) { [args[0], *args[1]] },
  :list => ->(args) { args },
  :null? => ->(args) { args[0].empty? }
}

def global_env
  env = Env.new(nil)
  PRIMITIVES.each { |name, fn| env.define(name, Prim.new(name, fn)) }
  env
end

PROGRAMS = [
  "(define (fact n) (if (< n 2) 1 (* n (fact (- n 1)))))
   (fact 10)
   (fact 20)",
  "(define (fib n) (cond ((< n 2) n) (else (+ (fib (- n 1)) (fib (- n 2))))))
   (fib 12)",
  "(define (map f xs) (if (null? xs) '() (cons (f (car xs)) (map f (cdr xs)))))
   (define (filter p xs) (cond ((null? xs) '()) ((p (car xs)) (cons (car xs) (filter p (cdr xs)))) (else (filter p (cdr xs)))))
   (define (foldl f acc xs) (if (null? xs) acc (foldl f (f acc (car xs)) (cdr xs))))
   (map (lambda (x) (* x x)) '(1 2 3 4 5))
   (filter (lambda (x) (< 2 x)) (list 5 1 4 2 3))
   (foldl + 0 (map (lambda (x) (* 2 x)) '(1 2 3)))
   (foldl (lambda (acc x) (cons x acc)) '() '(a b c d))",
  "(define (make-counter)
     (let ((n 0))
       (lambda () (set! n (+ n 1)) n)))
   (define c1 (make-counter))
   (define c2 (make-counter))
   (c1) (c1) (c2) (c1)
   (list (c1) (c2))
   make-counter
   car",
  "(define x 5)
   (+ x y)",
  "(car '())",
  "(define (f a b) a)
   (f 1)",
  "(1 2 3)",
  "(+ 1 (* 2 3)"
]

PROGRAMS.each_with_index do |src, i|
  puts "-- program #{i + 1}"
  env = global_env
  begin
    tokens = tokenize(src)
    until tokens.empty?
      form = read_form(tokens)
      puts "#{show(form)} => #{show(lisp_eval(form, env))}"
    end
  rescue LispError => e
    puts "error: #{e.message}"
  end
end
