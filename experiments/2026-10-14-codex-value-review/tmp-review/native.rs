#![allow(unused, non_snake_case, non_camel_case_types, unused_comparisons, unused_must_use, unreachable_code, unused_parens, unused_labels, dead_code, unused_braces)]
use std::rc::Rc;
use std::cell::UnsafeCell;
use std::io::Write;

const FILE: &str = "native.sake";

thread_local! { static OUT: std::cell::RefCell<std::io::BufWriter<std::io::Stdout>> = std::cell::RefCell::new(std::io::BufWriter::new(std::io::stdout())); }
fn out(s: &str) { OUT.with(|o| { o.borrow_mut().write_all(s.as_bytes()); }); }
fn flush() { OUT.with(|o| { o.borrow_mut().flush(); }); }

fn fail(line: u32, kind: &str, msg: &str) -> ! {
    flush();
    eprintln!("{}:{}: {}: {}", FILE, line, kind, msg);
    std::process::exit(1)
}
fn exit_(code: i64) -> ! { flush(); std::process::exit(code as i32) }

// Values are reference types, as in Sake: an Array or an object is shared by every variable that holds it.
// No compiled program runs threads, and no reference to the contents outlives one operation.
pub struct SArr<T>(Rc<UnsafeCell<Vec<T>>>);
impl<T> Clone for SArr<T> { fn clone(&self) -> Self { SArr(self.0.clone()) } }
impl<T> Default for SArr<T> { fn default() -> Self { SArr::new(Vec::new()) } }
impl<T> SArr<T> {
    #[inline] pub fn new(v: Vec<T>) -> Self { SArr(Rc::new(UnsafeCell::new(v))) }
    #[inline] fn v(&self) -> &mut Vec<T> { unsafe { &mut *self.0.get() } }
    #[inline] pub fn len(&self) -> i64 { self.v().len() as i64 }
    #[inline] pub fn at_ref(&self, k: i64) -> &T { &self.v()[k as usize] }
}
impl<T: Show + ?Sized> Show for &T {
    fn to_s_(&self) -> String { (**self).to_s_() }
    fn inspect_(&self) -> String { (**self).inspect_() }
    fn puts_lines(&self) { (**self).puts_lines() }
}
impl<T: Clone> SArr<T> {
    #[inline] fn pos(&self, i: i64) -> Option<usize> {
        let n = self.v().len() as i64;
        let k = if i < 0 { i + n } else { i };
        if k < 0 || k >= n { None } else { Some(k as usize) }
    }
    #[inline] pub fn at(&self, k: i64) -> T { self.v()[k as usize].clone() }
    // 0 <= k < len, proved by the range analysis (lib/sake/ranges.rb).
    #[inline] pub fn at_u(&self, k: i64) -> T { unsafe { self.v().get_unchecked(k as usize).clone() } }
    #[inline] pub fn set_u(&self, k: i64, x: T) { unsafe { *self.v().get_unchecked_mut(k as usize) = x; } }
    #[inline] pub fn update_u(&self, k: i64, f: impl FnOnce(T) -> T) -> T { unsafe { let p = self.v().get_unchecked_mut(k as usize); let x = f(p.clone()); *p = x.clone(); x } }
    #[inline] pub fn fetch(&self, i: i64, line: u32) -> T {
        match self.pos(i) { Some(k) => self.v()[k].clone(), None => fail(line, "IndexError", &format!("index {} outside of array bounds: {}...{}", i, -self.len(), self.len())) }
    }
    #[inline] pub fn get(&self, i: i64) -> Option<T> { self.pos(i).map(|k| self.v()[k].clone()) }
    #[inline] pub fn set(&self, i: i64, x: T, line: u32) {
        let v = self.v();
        let n = v.len() as i64;
        if i == n { v.push(x); return; }
        match self.pos(i) { Some(k) => v[k] = x, None => fail(line, "IndexError", &format!("index {} outside of array bounds: {}...{} (the Rust backend cannot fill the gap with nil)", i, -n, n)) }
    }
    #[inline] pub fn update(&self, i: i64, f: impl FnOnce(T) -> T, line: u32) -> T {
        match self.pos(i) { Some(k) => { let v = self.v(); let x = f(v[k].clone()); v[k] = x.clone(); x }, None => fail(line, "NoMethodError", &format!("x[{}] is nil: index outside of array bounds", i)) }
    }
    #[inline] pub fn push_all(&self, xs: Vec<T>) -> Self { self.v().extend(xs); self.clone() }
    #[inline] pub fn push(&self, x: T) -> Self { self.v().push(x); self.clone() }
    pub fn first(&self) -> Option<T> { self.v().first().cloned() }
    pub fn last(&self) -> Option<T> { self.v().last().cloned() }
    pub fn pop(&self) -> Option<T> { self.v().pop() }
    pub fn shift(&self) -> Option<T> { let v = self.v(); if v.is_empty() { None } else { Some(v.remove(0)) } }
    pub fn dup(&self) -> Self { SArr::new(self.v().clone()) }
    pub fn reversed(&self) -> Self { let mut v = self.v().clone(); v.reverse(); SArr::new(v) }
}
impl<T: Clone + PartialEq> SArr<T> {
    pub fn includes(&self, x: &T) -> bool { self.v().contains(x) }
    pub fn uniq(&self) -> Self { let mut r: Vec<T> = Vec::new(); for x in self.v().iter() { if !r.contains(x) { r.push(x.clone()); } } SArr::new(r) }
}
impl<T: Clone + PartialEq> PartialEq for SArr<T> { fn eq(&self, o: &Self) -> bool { self.v() == o.v() } }
impl<T: Clone + PartialOrd> SArr<T> {
    pub fn sorted(&self) -> Self { let mut v = self.v().clone(); v.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal)); SArr::new(v) }
    pub fn min_(&self) -> Option<T> { let mut r: Option<T> = None; for x in self.v().iter() { if r.as_ref().map_or(true, |m| x < m) { r = Some(x.clone()); } } r }
    pub fn max_(&self) -> Option<T> { let mut r: Option<T> = None; for x in self.v().iter() { if r.as_ref().map_or(true, |m| x > m) { r = Some(x.clone()); } } r }
}
impl<T: Clone + std::ops::Add<Output = T>> SArr<T> { pub fn sum(&self, init: T) -> T { let mut s = init; for x in self.v().iter() { s = s + x.clone(); } s } }
impl<T: Clone + Show> SArr<T> { pub fn join(&self, sep: &str) -> String { self.v().iter().map(|x| x.to_s_()).collect::<Vec<_>>().join(sep) } }

pub struct SRef<T>(Rc<UnsafeCell<T>>);
impl<T> Clone for SRef<T> { fn clone(&self) -> Self { SRef(self.0.clone()) } }
impl<T: Default> Default for SRef<T> { fn default() -> Self { SRef::new(T::default()) } }
impl<T> SRef<T> {
    #[inline] pub fn new(x: T) -> Self { SRef(Rc::new(UnsafeCell::new(x))) }
    #[inline] pub fn with<R>(&self, f: impl FnOnce(&mut T) -> R) -> R { f(unsafe { &mut *self.0.get() }) }
}
impl<T: PartialEq> PartialEq for SRef<T> { fn eq(&self, o: &Self) -> bool { unsafe { *self.0.get() == *o.0.get() } } }

// to_s and inspect, as Kernel.to_s and Kernel.inspect give them.
pub trait Show {
    fn to_s_(&self) -> String;
    fn inspect_(&self) -> String { self.to_s_() }
    fn puts_lines(&self) { out(&self.to_s_()); out("\n"); }
}
impl Show for i64 { fn to_s_(&self) -> String { self.to_string() } }
impl Show for bool { fn to_s_(&self) -> String { self.to_string() } }
impl Show for () { fn to_s_(&self) -> String { String::new() } fn inspect_(&self) -> String { "nil".to_string() } }
impl Show for String {
    fn to_s_(&self) -> String { self.clone() }
    fn inspect_(&self) -> String {
        let mut s = String::from("\"");
        for c in self.chars() { match c { '"' => s.push_str("\\\""), '\\' => s.push_str("\\\\"), '\n' => s.push_str("\\n"), '\t' => s.push_str("\\t"), '\r' => s.push_str("\\r"), '\u{1b}' => s.push_str("\\e"), '#' => s.push('#'), c if (c as u32) < 32 => s.push_str(&format!("\\x{:02X}", c as u32)), c => s.push(c) } }
        s.push('"');
        s
    }
}
impl Show for f64 {
    fn to_s_(&self) -> String {
        let x = *self;
        if x.is_nan() { return "NaN".to_string(); }
        if x.is_infinite() { return if x > 0.0 { "Infinity" } else { "-Infinity" }.to_string(); }
        let a = x.abs();
        if a >= 1e16 || (a != 0.0 && a < 1e-4) {
            let s = format!("{:e}", x);
            let (m, e) = s.split_once('e').unwrap();
            let m = if m.contains('.') { m.to_string() } else { format!("{}.0", m) };
            let ev: i32 = e.parse().unwrap();
            return format!("{}e{}{:02}", m, if ev < 0 { "-" } else { "+" }, ev.abs());
        }
        if x == x.trunc() { format!("{:.1}", x) } else { format!("{}", x) }
    }
}
impl<T: Show> Show for Option<T> {
    fn to_s_(&self) -> String { match self { Some(x) => x.to_s_(), None => String::new() } }
    fn inspect_(&self) -> String { match self { Some(x) => x.inspect_(), None => "nil".to_string() } }
    fn puts_lines(&self) { match self { Some(x) => x.puts_lines(), None => out("\n") } }
}
impl<T: Clone + Show> Show for SArr<T> {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String { format!("[{}]", self.v().iter().map(|x| x.inspect_()).collect::<Vec<_>>().join(", ")) }
    fn puts_lines(&self) { if self.v().is_empty() { out("\n"); } for x in self.v().iter() { x.puts_lines(); } }
}
impl<T: Show> Show for SRef<T> {
    fn to_s_(&self) -> String { self.with(|o| o.to_s_()) }
    fn inspect_(&self) -> String { self.with(|o| o.inspect_()) }
}
macro_rules! tuple_show { ($($i:tt $T:ident),+) => {
    impl<$($T: Show),+> Show for ($($T,)+) {
        fn to_s_(&self) -> String { self.inspect_() }
        fn inspect_(&self) -> String { let v: Vec<String> = vec![$(self.$i.inspect_()),+]; format!("[{}]", v.join(", ")) }
        fn puts_lines(&self) { $(self.$i.puts_lines();)+ }
    }
} }
tuple_show!(0 A);
tuple_show!(0 A, 1 B);
tuple_show!(0 A, 1 B, 2 C);
tuple_show!(0 A, 1 B, 2 C, 3 D);
tuple_show!(0 A, 1 B, 2 C, 3 D, 4 E);

fn puts_<T: Show>(x: &T) { x.puts_lines(); }
fn print_<T: Show>(x: &T) { out(&x.to_s_()); }
fn p_<T: Show>(x: &T) { out(&x.inspect_()); out("\n"); }

fn argv() -> SArr<String> { SArr::new(std::env::args().skip(1).collect()) }
fn nonneg(n: i64, line: u32) -> usize { if n < 0 { fail(line, "ArgumentError", "negative array size") } n as usize }
#[inline] fn idiv(a: i64, b: i64, line: u32) -> i64 { if b == 0 { fail(line, "ZeroDivisionError", "divided by 0") } let q = a / b; if (a % b != 0) && ((a < 0) != (b < 0)) { q - 1 } else { q } }
#[inline] fn imod(a: i64, b: i64, line: u32) -> i64 { if b == 0 { fail(line, "ZeroDivisionError", "divided by 0") } let r = a % b; if r != 0 && ((r < 0) != (b < 0)) { r + b } else { r } }
fn ipow(a: i64, b: i64, line: u32) -> i64 { if b < 0 { fail(line, "ArgumentError", &format!("Integer ** negative Integer ({} ** {}) is an error", a, b)) } a.checked_pow(b as u32).unwrap_or_else(|| fail(line, "RangeError", "Integer overflow in **")) }
fn fmod(a: f64, b: f64) -> f64 { let r = a % b; if r != 0.0 && ((r < 0.0) != (b < 0.0)) { r + b } else { r } }
fn fsqrt(x: f64, line: u32) -> f64 { if x < 0.0 { fail(line, "Math::DomainError", "Numerical argument is out of domain - \"sqrt\"") } x.sqrt() }
fn f_to_i(x: f64, line: u32) -> i64 { if x.is_nan() || x.is_infinite() { fail(line, "FloatDomainError", &x.to_s_()) } x as i64 }
fn chr(x: i64, line: u32) -> String { match u32::try_from(x).ok().and_then(char::from_u32) { Some(c) => c.to_string(), None => fail(line, "RangeError", &format!("{} out of char range", x)) } }
fn str_to_i(s: &str) -> i64 {
    let t = s.trim_start();
    let (neg, t) = match t.strip_prefix('-') { Some(r) => (true, r), None => (false, t.strip_prefix('+').unwrap_or(t)) };
    let mut v: i64 = 0;
    for c in t.chars() { match c.to_digit(10) { Some(d) => v = v.saturating_mul(10).saturating_add(d as i64), None if c == '_' => continue, None => break } }
    if neg { -v } else { v }
}
fn str_to_f(s: &str) -> f64 {
    let t = s.trim_start();
    let end = t.char_indices().take_while(|(_, c)| c.is_ascii_digit() || matches!(c, '-' | '+' | '.' | 'e' | 'E' | '_')).last().map_or(0, |(k, c)| k + c.len_utf8());
    let mut u = t[..end].replace('_', "");
    loop { match u.parse::<f64>() { Ok(v) => return v, Err(_) => { if u.is_empty() { return 0.0; } u.pop(); } } }
}
thread_local! { static SEED: std::cell::Cell<u64> = std::cell::Cell::new(0x9E3779B97F4A7C15 ^ (std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_nanos() as u64).unwrap_or(1))); }
fn rand_u64() -> u64 { SEED.with(|s| { let mut x = s.get(); x ^= x << 13; x ^= x >> 7; x ^= x << 17; s.set(x); x }) }
fn rand_f() -> f64 { (rand_u64() >> 11) as f64 / (1u64 << 53) as f64 }
fn rand_i(n: i64, line: u32) -> i64 { if n <= 0 { fail(line, "ArgumentError", &format!("invalid argument - {}", n)) } (rand_u64() % (n as u64)) as i64 }

#[derive(Default, Clone, PartialEq)]
pub struct RuntimeError {
    pub message: (),
}
impl Show for RuntimeError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct RuntimeError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct ArgumentError {
    pub message: (),
}
impl Show for ArgumentError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct ArgumentError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct KeyError {
    pub message: (),
}
impl Show for KeyError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct KeyError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct IndexError {
    pub message: (),
}
impl Show for IndexError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct IndexError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct ZeroDivisionError {
    pub message: (),
}
impl Show for ZeroDivisionError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct ZeroDivisionError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct RangeError {
    pub message: (),
}
impl Show for RangeError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct RangeError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct IOError {
    pub message: (),
}
impl Show for IOError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct IOError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct EncodingError {
    pub message: (),
}
impl Show for EncodingError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct EncodingError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct RegexpError {
    pub message: (),
}
impl Show for RegexpError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct RegexpError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct FloatDomainError {
    pub message: (),
}
impl Show for FloatDomainError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct FloatDomainError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct Math_DomainError {
    pub message: (),
}
impl Show for Math_DomainError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct Math::DomainError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct NoMatchingPatternError {
    pub message: (),
}
impl Show for NoMatchingPatternError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct NoMatchingPatternError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct TypeError {
    pub message: (),
}
impl Show for TypeError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct TypeError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct EOFError {
    pub message: (),
}
impl Show for EOFError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct EOFError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct ThreadError {
    pub message: (),
}
impl Show for ThreadError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct ThreadError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct SystemStackError {
    pub message: (),
}
impl Show for SystemStackError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct SystemStackError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct NotImplementedError {
    pub message: (),
}
impl Show for NotImplementedError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct NotImplementedError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}

#[derive(Default, Clone, PartialEq)]
pub struct LocalJumpError {
    pub message: (),
}
impl Show for LocalJumpError {
    fn to_s_(&self) -> String { self.inspect_() }
    fn inspect_(&self) -> String {
        let names = ["message"];
        let vals = [self.message.inspect_()];
        let mut s = String::from("#<struct LocalJumpError");
        for (k, (n, v)) in names.iter().zip(vals.iter()).enumerate() {
            s.push_str(if k == 0 { " " } else { ", " });
            s.push_str(n); s.push('='); s.push_str(v);
        }
        s.push('>');
        s
    }
}


fn fib_0(v0: i64) -> i64 {
    let mut v0 = v0;

    {
    if (v0 < 2i64) {
    return v0;
    }
    (fib_0(v0.wrapping_sub(1i64)) + fib_0(v0.wrapping_sub(2i64))) }
}

fn main() {
    std::panic::set_hook(Box::new(|info| {
        let msg = info.payload().downcast_ref::<&str>().map(|s| s.to_string())
            .or_else(|| info.payload().downcast_ref::<String>().cloned()).unwrap_or_default();
        eprintln!("{}: error: {}", FILE, msg);
        std::process::exit(1);
    }));

    { puts_(&fib_0(20i64)); };
    flush();
}
