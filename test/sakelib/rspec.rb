require_relative "ref/rspec"

# The Sake spec (rspec.sake) in RSpec's own DSL, run by the plain-Ruby reference (the rspec gem is not
# installed; its output has colours and timings anyway).

def square(x) = x * x

describe "Array" do
  it "pushes at the end" do
    a = [1]
    a.push(2)
    expect(a).to eq([1, 2])
    expect(a).not_to eq([2, 1])
    expect(a).to include(2)
    expect(a).to include(1, 2)
    expect(a).not_to include(3)
    expect(a).to have_size(2)
    expect(a).not_to be_empty
    expect(a).to contain_exactly(2, 1)
    expect(a).to match_array([2, 1])
    expect(a).to all { |x| x > 0 }
  end
  it "fails on eq" do
    expect([1, 2].sum).to eq(4)
  end
  context "when empty" do
    it "has no first element" do
      expect([].first).to be_nil
      expect([]).to be_empty
      expect([].first).to be_falsey
    end
    it "fails on include" do
      expect([]).to include(1)
    end
    context "and nested deeper" do
      it("still reports") { expect([].size).to eq(0) }
    end
  end
  it "is not yet written"
  xit("is skipped for now") { expect(1).to eq(2) }
end

describe "String" do
  it "matches and starts" do
    s = "hello world"
    expect(s).to match(/wor/)
    expect(s).not_to match(/xyz/)
    expect(s).to start_with("hello")
    expect(s).to end_with("world")
    expect(s).to include("lo w")
    expect(s).to have_size(11)
    expect(s.upcase).to eq("HELLO WORLD")
    expect("").to be_empty
  end
  it "fails on match" do
    expect("abc").to match(/\d/)
  end
  it "fails on start_with" do
    expect("abc").to start_with("b")
  end
  # expect(42).to match(/4/) is a type error before running in Sake; here it would be a NoMethodError.
end

describe "numbers" do
  it "compares" do
    expect(square(3)).to eq(9)
    expect(3.14159).to be_within(0.01).of(3.14)
    expect(10).to be > 9
    expect(10).to be >= 10
    expect(10).to be < 11
    expect(10).to be <= 10
    expect(5).to be_between(1, 10)
    expect(7).to satisfy("be odd") { |x| x.odd? }
    expect(0).to be_truthy
    expect(nil).to be_falsey
    expect(nil).to be_nil
    expect(1).not_to be_nil
    expect(:a).to be(:a)
  end
  it "fails on be_within" do
    expect(3.0).to be_within(0.1).of(3.5)
  end
  it "fails on be_truthy" do
    expect(nil).to be_truthy
  end
  it "fails on be >" do
    expect(1).to be > 2
  end
  it "fails on satisfy" do
    expect(8).to satisfy("be odd") { |x| x.odd? }
  end
end

describe "errors" do
  it "raises" do
    expect { raise "boom" }.to raise_error
    expect { raise "boom" }.to raise_error("boom")
    expect { raise "boom" }.to raise_error(/bo+m/)
    expect { 1 / 0 }.to raise_error(/divided/)
    msg = expect { Integer("x") }.to raise_error
    expect(msg).to include("invalid value")
    expect { 1 + 1 }.not_to raise_error
  end
  it "fails when nothing is raised" do
    expect { 1 + 1 }.to raise_error
  end
  it "fails on the message" do
    expect { raise "boom" }.to raise_error("bang")
  end
  it "fails on an unexpected error" do
    expect { raise "oops" }.not_to raise_error
  end
  it "fails by raising" do
    raise "the example itself raised"
  end
  it "is pending from inside" do
    pending "waiting for a fix"
  end
end

describe "Hash" do
  it "has keys" do
    h = {"a" => 1, "b" => 2}
    expect(h).to have_key("a")
    expect(h).to include("b")
    expect(h).not_to include("c")
    expect(h).to eq({"a" => 1, "b" => 2})
    expect(h.keys).to contain_exactly("b", "a")
  end
  it "fails on have_key" do
    expect({"a" => 1}).to have_key("z")
  end
end

# the long-hand form of the Sake version has no counterpart; the same expectations:
describe "long-hand" do
  it "uses the operations directly" do
    expect(1 + 1).to eq(2)
    expect(1.0).to be_within(0.5).of(1.2)
    expect { raise "x" }.to raise_error("x")
  end
end

ok = RSpecRef.report
puts
p ok
