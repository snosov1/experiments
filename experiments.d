import std.stdio;
import std.getopt;
import std.process;
import std.array;
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
        if (splitted.length == 2)
            return inputRangeObject(map!(to!string)
                                    (StepMacro!int(0, splitted[1].to!int, 1)));
        else if (splitted.length == 3)
            return inputRangeObject(map!(to!string)
                                    (StepMacro!int(splitted[1].to!int, splitted[2].to!int, 1)));
        else if (splitted.length == 4)
            return inputRangeObject(map!(to!string)
                                    (StepMacro!int(splitted[1].to!int, splitted[2].to!int, splitted[3].to!int)));
        else
            throw new Exception("Bad number of parameters");
        break;
    case "double":
        if (splitted.length == 2)
            return inputRangeObject(map!(to!string)
                                    (StepMacro!double(0, splitted[1].to!double, 1)));
        else if (splitted.length == 3)
            return inputRangeObject(map!(to!string)
                                    (StepMacro!double(splitted[1].to!double, splitted[2].to!double, 1)));
        else if (splitted.length == 4)
            return inputRangeObject(map!(to!string)
                                    (StepMacro!double(splitted[1].to!double, splitted[2].to!double, splitted[3].to!double)));
        else
            throw new Exception("Bad number of parameters");
        break;
    case "enum":
        return inputRangeObject(splitted[1..$]);
        break;
    default:
        throw new Exception("Unrecognized macro");
    }
}

unittest {
    //auto m = constructMacro("int 3 10 1");
    auto m = constructMacro("enum 3.4 10 1");

    writeln(m);

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
