// shapes_mono by hand in Rust: one struct, a direct call (the control for dispatch).
struct Circle { r: i64 }
impl Circle {
    fn area(&self) -> i64 { 3 * self.r * self.r }
    fn name(&self) -> &'static str { "circle" }
    fn describe(&self) -> String { format!("{}: {}", self.name(), self.area()) }
}

fn main() {
    let rounds: i64 = std::env::args().nth(1).unwrap().parse().unwrap();
    let mut shapes: Vec<Circle> = Vec::new();
    for i in 0..1000i64 { shapes.push(Circle { r: i }); }
    let mut total: i64 = 0;
    for _ in 0..rounds {
        for s in shapes.iter() { total += s.area(); }
    }
    println!("{}", total);
    println!("{}", shapes[1].describe());
}
