// The "loops" micro benchmark, written by hand in Rust (the ceiling the generated code is compared with).
// Same semantics as loops.sake: i64 arithmetic with overflow checks on (compiled with -C overflow-checks=on).
fn main() {
    let u: i64 = std::env::args().nth(1).unwrap().parse().unwrap();
    let r: i64 = (std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos() % 10000) as i64;
    let mut a = vec![0i64; 10000];
    let mut i: i64 = 0;
    while i < 10000 {
        let mut j: i64 = 0;
        while j < 100000 {
            a[i as usize] = a[i as usize] + j % u;
            j += 1;
        }
        a[i as usize] = a[i as usize] + r;
        i += 1;
    }
    println!("{}", a[r as usize]);
}
