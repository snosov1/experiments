import std.stdio;
import std.getopt;
import std.process;
import std.array;
import std.exception;
import std.typecons;
import std.typetuple;
import std.range;
import std.algorithm;
import std.regex;
import std.datetime;
import std.conv;

import cartesian;

/**
   Splits the patch extracting macros

   Returns: array with the following structure: [, macro, post]
 */
// string[] splitMacros(string patch, string open_delim = "($", string close_delim = ")")
// {

// }

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
    {
        enforce((step > 0) && (begin <= end) ||
                (step < 0) && (begin >= end));

        begin_ = begin;
        end_   = end;
        step_  = step;
    }

    this(T[] args)
    {
        if (args.length == 1)
            this(0, args[0].to!T, 1);
        else if (args.length == 2)
            this(args[0].to!T, args[1].to!T, 1);
        else if (args.length == 3)
            this(args[0].to!T, args[1].to!T, args[2].to!T);
        else
        {
            new Exception("Wrong number of elements (must be 1, 2 or 3)");
            this(T.init, T.init, T.init); // dmd bug?
        }
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

/**
   int <end>
   int <begin> <end>
   int <begin> <end> <step>
   double <begin> <end> <step>
   enum <value> <value> ...
*/
InputRange!string constructMacro(string m)
{
    auto splitted = m
        .splitter(' ')
        .filter!(s => !s.empty)
        .array;

    switch (splitted[0])
    {
    case "int":
        return splitted[1..$]
            .map!(to!int)
            .array
            .StepMacro!int
            .map!(to!string)
            .inputRangeObject;
        break;
    case "double":
        return splitted[1..$]
            .map!(to!double)
            .array
            .StepMacro!double
            .map!(to!string)
            .inputRangeObject;
        break;
    case "enum":
        return splitted[1..$]
            .inputRangeObject;
        break;
    default:
        throw new Exception("Unrecognized macro");
    }
}

unittest {
    assert(equal(constructMacro("int 0 10 1"), ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]));
    assert(equal(constructMacro("int 3 10 2"), ["3", "5", "7", "9"]));
    assert(equal(constructMacro("int 4 10 2"), ["4", "6", "8"]));
    assert(equal(constructMacro("int 10 -3 -3"), ["10", "7", "4", "1", "-2"]));

    assert(equal(constructMacro("double 3.43 4.11 0.1"), ["3.43", "3.53", "3.63", "3.73", "3.83", "3.93", "4.03"]));
    assert(equal(constructMacro("double 4.43 3.11 -0.11"), ["4.43", "4.32", "4.21", "4.1", "3.99", "3.88", "3.77", "3.66", "3.55", "3.44", "3.33", "3.22"]));

    assert(constructMacro("enum").empty);
    assert(constructMacro("enum  ").empty);
    assert(equal(constructMacro("enum sf 1sdf& szv &11"), ["sf", "1sdf&", "szv", "&11"]));
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
