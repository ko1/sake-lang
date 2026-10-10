// The "shapes" micro benchmark by hand in Rust, with a trait object: dynamic dispatch through a vtable.
trait Shape {
    fn area(&self) -> i64;
    fn name(&self) -> &'static str;
    fn describe(&self) -> String { format!("{}: {}", self.name(), self.area()) }
}

struct Circle { r: i64 }
struct Rect { w: i64, h: i64 }
struct Tri { b: i64, h: i64 }

impl Shape for Circle {
    fn area(&self) -> i64 { 3 * self.r * self.r }
    fn name(&self) -> &'static str { "circle" }
}
impl Shape for Rect {
    fn area(&self) -> i64 { self.w * self.h }
    fn name(&self) -> &'static str { "rect" }
}
impl Shape for Tri {
    fn area(&self) -> i64 { self.b * self.h / 2 }
    fn name(&self) -> &'static str { "tri" }
}

fn main() {
    let rounds: i64 = std::env::args().nth(1).unwrap().parse().unwrap();
    let mut shapes: Vec<Box<dyn Shape>> = Vec::new();
    for i in 0..1000i64 {
        shapes.push(match i % 3 {
            0 => Box::new(Circle { r: i }),
            1 => Box::new(Rect { w: i, h: 2 }),
            _ => Box::new(Tri { b: i, h: 4 }),
        });
    }
    let mut total: i64 = 0;
    for _ in 0..rounds {
        for s in shapes.iter() { total += s.area(); }
    }
    println!("{}", total);
    println!("{}", shapes[1].describe());
}
