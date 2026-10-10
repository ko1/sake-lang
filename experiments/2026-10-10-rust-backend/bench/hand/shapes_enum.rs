// The "shapes" micro benchmark by hand in Rust, with a closed enum and a match: what sabic generates.
struct Circle { r: i64 }
struct Rect { w: i64, h: i64 }
struct Tri { b: i64, h: i64 }

enum Shape { Circle(Circle), Rect(Rect), Tri(Tri) }

impl Shape {
    fn area(&self) -> i64 {
        match self {
            Shape::Circle(c) => 3 * c.r * c.r,
            Shape::Rect(x) => x.w * x.h,
            Shape::Tri(t) => t.b * t.h / 2,
        }
    }
    fn name(&self) -> &'static str {
        match self { Shape::Circle(_) => "circle", Shape::Rect(_) => "rect", Shape::Tri(_) => "tri" }
    }
    fn describe(&self) -> String { format!("{}: {}", self.name(), self.area()) }
}

fn main() {
    let rounds: i64 = std::env::args().nth(1).unwrap().parse().unwrap();
    let mut shapes: Vec<Shape> = Vec::new();
    for i in 0..1000i64 {
        shapes.push(match i % 3 {
            0 => Shape::Circle(Circle { r: i }),
            1 => Shape::Rect(Rect { w: i, h: 2 }),
            _ => Shape::Tri(Tri { b: i, h: 4 }),
        });
    }
    let mut total: i64 = 0;
    for _ in 0..rounds {
        for s in shapes.iter() { total += s.area(); }
    }
    println!("{}", total);
    println!("{}", shapes[1].describe());
}
