import std.array;
import std.typecons;
import std.typetuple;
import std.range;
import std.algorithm;

// "dynamic" version

public struct CartesianProduct(T)
{
    private T[][] ranges_;
    private int[] current_;

public:
    this(T[][] ranges)
    {
        ranges_ = ranges;
        current_.length = ranges.length;
    }

    @property auto front()
    {
        T[] ret;
        ret.length = ranges_.length;

        foreach(i, r; ranges_)
            ret[i] = r[current_[i]];

        return ret;
    }

    @property CartesianProduct save()
    {
        auto ret = this;
        ret.current_ = current_.dup;

        return ret;
    }

    @property void popFront()
    {
        foreach (i, r; ranges_)
        {
            if ((++current_[i]) == ranges_[i].length && i != current_.length - 1)
                current_[i] = 0;
            else
                break;
        }
    }

    @property bool empty()
    {
        return current_[$-1] == ranges_[$-1].length;
    }
}

public auto cartesianProduct(T)(T[][] arg)
{
    return CartesianProduct!T(arg);
}

unittest {
    assert(isForwardRange!(CartesianProduct!int));

    // test save
    auto cp = cartesianProduct([[1, 2], [3, 4, 5]]);
    assert(equal([[1, 3], [2, 3], [1, 4], [2, 4], [1, 5], [2, 5]], cp.save));
    foreach (i; 0..2)
        cp.popFront;
    auto cp_save = cp.save;
    foreach (i; 0..2)
        cp.popFront;
    assert(equal([[1, 4], [2, 4], [1, 5], [2, 5]], cp_save));
    assert(equal([[1, 5], [2, 5]], cp));

    // behavior tests
    auto a1 = ["1", "2"];
    auto a2 = ["a", "b", "c"];
    assert(equal(
               [["1", "a"], ["2", "a"], ["1", "b"], ["2", "b"], ["1", "c"], ["2", "c"]],
               CartesianProduct!string([a1, a2])));

    // same, to test a1 and a2 are not modified
    assert(equal(
               [["1", "a"], ["2", "a"], ["1", "b"], ["2", "b"], ["1", "c"], ["2", "c"]],
               CartesianProduct!string([a1, a2])));

    auto cp2 = CartesianProduct!string([["1", "2"], ["1.1", "2.2", "3.3"], ["a", "b", "c"]]);
    assert(equal(cp2, [["1", "1.1", "a"],
                       ["2", "1.1", "a"],
                       ["1", "2.2", "a"],
                       ["2", "2.2", "a"],
                       ["1", "3.3", "a"],
                       ["2", "3.3", "a"],
                       ["1", "1.1", "b"],
                       ["2", "1.1", "b"],
                       ["1", "2.2", "b"],
                       ["2", "2.2", "b"],
                       ["1", "3.3", "b"],
                       ["2", "3.3", "b"],
                       ["1", "1.1", "c"],
                       ["2", "1.1", "c"],
                       ["1", "2.2", "c"],
                       ["2", "2.2", "c"],
                       ["1", "3.3", "c"],
                       ["2", "3.3", "c"]]
               ));



}
