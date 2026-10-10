// The "fibonacci" micro benchmark, written by hand in Rust.
fn fib(n: i64) -> i64 {
    if n < 2 { return n; }
    fib(n - 1) + fib(n - 2)
}

fn main() {
    let u: i64 = std::env::args().nth(1).unwrap().parse().unwrap();
    let mut r: i64 = 0;
    let mut i: i64 = 1;
    while i < u {
        r += fib(i);
        i += 1;
    }
    println!("{}", r);
}
