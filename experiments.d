import std.stdio;
import std.array;
import std.getopt;
import std.typecons;
import std.typetuple;
import std.range;
import std.process;
import std.algorithm;
import std.regex;

struct CartesianProduct(Args...)
{
    private Args ranges_;
    private Args current_;

    alias staticMap!(ElementType, Args) ElementTypes;
public:
    this(Args ranges) {
        foreach (i, ref r; ranges)
        {
            ranges_[i] = r.save;
            current_[i] = r.save;
        }
    }

    @property auto front() {
        Tuple!ElementTypes ret;
        foreach (i, r; current_) {
            ret[i] = r.front;
        }
        return ret;
    }

    @property void popFront() {
        foreach (i, ref r; current_)
        {
            r.popFront;
            if (r.empty && i != current_.length - 1)
                r = ranges_[i].save;
            else
                break;
        }
    }

    @property bool empty() {
        return current_[$-1].empty;
    }
}

auto cartesianProduct(Args...)(Args args)
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

struct InputPatch
{
    private string patch_;
    private string current_;

    this(string patch) {
        patch_ = patch;

        for (;;)
        {

        }
    }
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
