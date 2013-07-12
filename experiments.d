import std.stdio;
import std.file;
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
            (step_ > 0) && (begin_ > end_) ||
            (step_ < 0) && (begin_ < end_);
    }
}

unittest {
    assert(equal(StepMacro!int(0, 10, 1), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    assert(equal(StepMacro!int(3, 10, 2), [3, 5, 7, 9]));
    assert(equal(StepMacro!long(4, 10, 2), [4, 6, 8, 10]));
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
    assert(equal(constructMacro("int 0 10 1"), ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]));
    assert(equal(constructMacro("int 3 10 2"), ["3", "5", "7", "9"]));
    assert(equal(constructMacro("int 4 10 2"), ["4", "6", "8", "10"]));
    assert(equal(constructMacro("int 10 -3 -3"), ["10", "7", "4", "1", "-2"]));

    assert(equal(constructMacro("double 3.43 4.11 0.1"), ["3.43", "3.53", "3.63", "3.73", "3.83", "3.93", "4.03"]));
    assert(equal(constructMacro("double 4.43 3.11 -0.11"), ["4.43", "4.32", "4.21", "4.1", "3.99", "3.88", "3.77", "3.66", "3.55", "3.44", "3.33", "3.22", "3.11"]));

    assert(constructMacro("enum").empty);
    assert(constructMacro("enum  ").empty);
    assert(equal(constructMacro("enum sf 1sdf& szv &11"), ["sf", "1sdf&", "szv", "&11"]));
}

struct PatchRange
{
private:
    string patch_parts_[];
    string macros_[];
public:
    this(string patch, string open = `\$\(`, string close = `\)`)
    {
        string re = open~`.*?`~close;

        auto m = match(patch, regex(re));
        while (!m.empty)
        {
            patch_parts_ ~= m.pre;
            macros_ ~= m.hit[open.length - open.count('\\') .. $ - close.length + close.count('\\')];

            patch = patch[m.pre.length + m.hit.length .. $];
            m = match(patch, regex(re));
        }
        patch_parts_ ~= m.post;
    }

    auto opSlice()
    {
        return
            reduce!((a, b) => a ~ b.constructMacro.array)(cast(string[][])[], macros_)
            .cartesianProduct
            .map!(m => reduce!((a, b) => a ~ b)("", roundRobin(patch_parts_, m)));
    }
}

unittest {
    auto p = PatchRange("abc $(int 2 4 2) bcd $(enum a b c)");

    assert(equal(p[],["abc 2 bcd a",
                      "abc 4 bcd a",
                      "abc 2 bcd b",
                      "abc 4 bcd b",
                      "abc 2 bcd c",
                      "abc 4 bcd c"]));
}

void main(string args[])
{
    if (args.length <= 2)
    {
        writeln("Usage: ", args[0], " <path-to-git-repo> <patch>");
        return;
    }

    int i = 0;
    foreach (t; args[1].readText.PatchRange[])
    {
        string filename = (++i).to!string~".patch";

        auto f = File(filename, "w");
        f.write(t);
        f.close();

        writeln(shell("git checkout -- ."));
        writeln(shell("patch -i " ~ filename));
        //writeln(shell(args[2]));
    }
}
