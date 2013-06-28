import std.stdio;
import std.array;
import std.getopt;
import std.typecons;
import std.typetuple;
import std.range;
import std.process;
import std.algorithm;
import std.regex;
import std.datetime;

struct CartesianProduct(Args...)
    if (Args.length > 1)
{
    private Args ranges_;
    private Args current_;

    alias staticMap!(ElementType, Args) ElementTypes;

public:
    this(Args ranges)
    {
        foreach (i, ref r; ranges)
        {
            ranges_[i] = r.save;
            current_[i] = r.save;
        }
    }

    @property auto front()
    {
        Tuple!ElementTypes ret;
        foreach (i, r; current_)
            ret[i] = r.front;
        return ret;
    }

    @property void popFront()
    {
        foreach (i, ref r; current_)
        {
            r.popFront;
            if (r.empty && i != current_.length - 1)
                r = ranges_[i].save;
            else
                break;
        }
    }

    @property bool empty()
    {
        return current_[$-1].empty;
    }
}

auto cartesianProduct(Args...)(Args args)
if (Args.length > 1)
{
    return CartesianProduct!(Args)(args);
}

unittest {
    auto cp = cartesianProduct([1, 2], [1.1, 2.2, 3.3]);
    assert(equal(cp, [
                     Tuple!(int, double)(1, 1.1),
                     Tuple!(int, double)(2, 1.1),
                     Tuple!(int, double)(1, 2.2),
                     Tuple!(int, double)(2, 2.2),
                     Tuple!(int, double)(1, 3.3),
                     Tuple!(int, double)(2, 3.3)
                     ]
               ));

    auto cp2 = cartesianProduct([1, 2], [1.1, 2.2, 3.3], ["a", "b", "c"]);
    assert(equal(cp2, [Tuple!(int, double, string)(1, 1.1, "a"),
                       Tuple!(int, double, string)(2, 1.1, "a"),
                       Tuple!(int, double, string)(1, 2.2, "a"),
                       Tuple!(int, double, string)(2, 2.2, "a"),
                       Tuple!(int, double, string)(1, 3.3, "a"),
                       Tuple!(int, double, string)(2, 3.3, "a"),
                       Tuple!(int, double, string)(1, 1.1, "b"),
                       Tuple!(int, double, string)(2, 1.1, "b"),
                       Tuple!(int, double, string)(1, 2.2, "b"),
                       Tuple!(int, double, string)(2, 2.2, "b"),
                       Tuple!(int, double, string)(1, 3.3, "b"),
                       Tuple!(int, double, string)(2, 3.3, "b"),
                       Tuple!(int, double, string)(1, 1.1, "c"),
                       Tuple!(int, double, string)(2, 1.1, "c"),
                       Tuple!(int, double, string)(1, 2.2, "c"),
                       Tuple!(int, double, string)(2, 2.2, "c"),
                       Tuple!(int, double, string)(1, 3.3, "c"),
                       Tuple!(int, double, string)(2, 3.3, "c")]
               ));
    // auto m = match("hel%(lo)qq%(zxcv)q", regex(`%\(.*?\)`, "g"));
    // if (!m.empty)
    //     writeln(m.pre, " | ", m.hit, " | ", m.post);
}

struct CartesianProduct(T)
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

auto cartesianProduct(T)(T[][] arg)
{
    return CartesianProduct!T(arg);
}

unittest {
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


    assert(equal([[1, 3], [2, 3], [1, 4], [2, 4], [1, 5], [2, 5]],
                 cartesianProduct([[1, 2], [3, 4, 5]])));
}

/**
   Splits the patch extracting macros

   Returns: array with the following structure: [, macro, post]
 */
// string[] splitMacros(string patch, string open_delim = "($", string close_delim = ")")
// {

// }


/**
   int <end>
   int <begin> <end>
   int <begin> <end> <step>
   double <begin> <end> <number>
   enum <value> <value> ...
 */

struct StepMacro(T)
    if (
        is(typeof(T.init + T.init)) &&
        is(typeof(T.init >= T.init) == bool)
        )
{
private:
    T begin_;
    T end_;
    T step_;
public:
    this(T begin, T end, T step)
    in
    {
        assert((step > 0) && (begin <= end) ||
               (step < 0) && (begin >= end));
    }
    body
    {
        begin_ = begin;
        end_   = end;
        step_  = step;
    }

    @property T front() { return begin_; }
    @property void popFront() { begin_ += step_; }
    @property bool empty() { return
            (step_ > 0) && (begin_ >= end_) ||
            (step_ < 0) && (begin_ <= end_);
    }
}

unittest {
    assert(equal(StepMacro!int(0, 10, 1), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    assert(equal(StepMacro!int(3, 10, 2), [3, 5, 7, 9]));
    assert(equal(StepMacro!long(4, 10, 2), [4, 6, 8]));
    assert(equal(StepMacro!byte(10, -3, -3), [10, 7, 4, 1, -2]));
}

struct Macro
{
public:
    this(string m)
    {
        auto splitted = m
            .splitter(' ')
            .filter!(s => !s.empty)
            .array;

        switch (splitted[0]) {
        case "int":
            break;
        default:
            throw new Exception("Unrecognized macro");
        }
    }
}

unittest {
    auto m = Macro("int 3 3 1");

    // auto m = match("hel%(lo)qq%(zxcv)q", regex(`%\(.*?\)`, "g"));
    // if (!m.empty)
    //     writeln(m.pre, " | ", m.hit, " | ", m.post);
    // foreach (m; match("hel%(lo)qq%(zxcv)q", regex(`%\(.*?\)`, "g")))
    //     writeln(m.pre, " | ", m.hit, " | ", m.post);



//    writeln(splitter("hello  world", " "));
}

void main(string args[])
{
    if (args.length <= 2)
    {
        writeln("Usage: ", args[0], " <path-to-git-repo> <patch>");
        return;
    }

    string repo_path = args[1];
    string patch =
        q"DELIM
diff --git a/tld.hpp b/tld.hpp
index e2861cd..2d028de 100644
--- a/tld.hpp
+++ b/tld.hpp
@@ -22,11 +22,11 @@ const float NN_THRESHOLD = 0.61f;
 const float NN_POS_THRESHOLD = 0.72f;
 const float NN_NEG_THRESHOLD = 0.39f;

-const float FERNS_THRESHOLD     = 0.5f;
-const float FERNS_POS_THRESHOLD = 0.5f;
-const float FERNS_NEG_THRESHOLD = 0.5f;
-const float OVERLAP_LOW    = 0.2f;
-const float OVERLAP_UP     = 0.6f;
+const float FERNS_THRESHOLD      = 0.5f;
+const float FERNS_POS_THRESHOLD  = 0.5f;
+const float FERNS_NEG_THRESHOLD  = 0.5f;
+const float OVERLAP_LOW          = 0.2f;
+const float OVERLAP_UP           = 0.6f;

 //#define TLD_SHOW_DEBUGGING_WINDOWS 1
DELIM";

    foreach (t; cartesianProduct(
                 ["0.4f", "0.5f", "0.6f", "0.7f", "0.8f"],
                 ["0.1f", "0.3f", "0.5f", "0.7f", "0.9f"],
                 ["0.3f", "0.5f", "0.7f", "0.9f"]
                 ))
    {
        // auto m = match(patch, regex(`\+.*OVERLAP_LOW *= 0.2f`));
        // string current = m.pre ~ "+const float OVERLAP_LOW          = " ~ t[0] ~ m.post;
        // m = match(current, regex(`\+.*OVERLAP_UP *= 0.6f`));
        // current = m.pre ~ "+const float OVERLAP_UP           = " ~ t[1] ~ m.post;

        auto m = match(patch, regex(`\+.*FERNS_THRESHOLD *= 0.5f`));
        string current = m.pre ~ "+const float FERNS_THRESHOLD          = " ~ t[0] ~ m.post;
        m = match(current, regex(`\+.*FERNS_POS_THRESHOLD *= 0.5f`));
        current = m.pre ~ "+const float FERNS_POS_THRESHOLD           = " ~ t[1] ~ m.post;
        m = match(current, regex(`\+.*FERNS_NEG_THRESHOLD *= 0.5f`));
        current = m.pre ~ "+const float FERNS_NEG_THRESHOLD           = " ~ t[2] ~ m.post;

        string filename = "ferns-thresh."~t[0]~"."~t[1]~"."~t[2]~".patch";

        auto f = File(repo_path ~ "/" ~ filename, "w");
        f.write(current);
        f.close();

        writeln(t);
        writeln(shell("cd " ~ repo_path ~ " && git checkout -- tld.hpp"));
        writeln(shell("cd " ~ repo_path ~ " && patch -i " ~ filename));
        writeln(shell("ninja -C /home/sergei/Projects/CoreVisionAPI/build-desk/"));
        shell("python /home/sergei/Projects/tracking/scripts/run.py -e /home/sergei/Projects/tracking/algorithms/cvapi_tld.py -D /home/sergei/Projects/tracking/datasets/ -a cvapi_tld_ORIG cvapi_tld cvapi_tld_YUV cvapi_tld_NEW >/home/sergei/Projects/CoreVisionAPI/modules/core_vision_api/src/trackers/ferns-results/" ~ filename ~ ".txt");
    }
}
