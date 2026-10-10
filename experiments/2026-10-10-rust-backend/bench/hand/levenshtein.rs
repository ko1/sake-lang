// The "levenshtein" micro benchmark, written by hand in Rust.
fn levenshtein(s: &str, t: &str) -> i64 {
    let a = s.as_bytes();
    let b = t.as_bytes();
    let m = a.len();
    let n = b.len();
    if m == 0 { return n as i64; }
    if n == 0 { return m as i64; }
    let mut prev = vec![0i64; n + 1];
    let mut curr = vec![0i64; n + 1];
    for j in 0..=n { prev[j] = j as i64; }
    for i in 1..=m {
        curr[0] = i as i64;
        for j in 1..=n {
            let cost = if a[i - 1] == b[j - 1] { 0 } else { 1 };
            let del = prev[j] + 1;
            let ins = curr[j - 1] + 1;
            let sub = prev[j - 1] + cost;
            let mut best = del;
            if ins < best { best = ins; }
            if sub < best { best = sub; }
            curr[j] = best;
        }
        std::mem::swap(&mut prev, &mut curr);
    }
    prev[n]
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let count = args.len();
    let mut min: i64 = -1;
    let mut times: i64 = 0;
    for i in 0..count {
        for j in 0..count {
            if i != j {
                let d = levenshtein(&args[i], &args[j]);
                if min == -1 || d < min { min = d; }
                times += 1;
            }
        }
    }
    println!("times: {}", times);
    println!("min_distance: {}", min);
}
