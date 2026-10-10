// loops.rs with Ruby's floored `%` (the generated code must use it; Rust's `%` truncates). Isolates the
// cost of that semantic difference between hand-rust and sake-rust.
#[inline]
fn imod(a: i64, b: i64) -> i64 {
    if b == 0 { panic!("divided by 0") }
    let r = a % b;
    if r != 0 && ((r < 0) != (b < 0)) { r + b } else { r }
}

fn main() {
    let u: i64 = std::env::args().nth(1).unwrap().parse().unwrap();
    let r: i64 = (std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos() % 10000) as i64;
    let mut a = vec![0i64; 10000];
    let mut i: i64 = 0;
    while i < 10000 {
        let mut j: i64 = 0;
        while j < 100000 {
            a[i as usize] = a[i as usize] + imod(j, u);
            j += 1;
        }
        a[i as usize] = a[i as usize] + r;
        i += 1;
    }
    println!("{}", a[r as usize]);
}
