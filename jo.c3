module jo;

import std::io;
import std::os::process;
import color;

const VERSION = "0.2";

faultdef STDOUT_NOT_FOUND;

struct Opts {
    bool list;
}

fn void main(String[] args)
{
    switch (args[1]) {
        case "list"     :
        case "--list"   :
        case "-l"       : list(args);
        case "version"  : 
        case "--version": 
        case "-v"       : version(args);
        case "help"     : 
        case "--help"   : 
        case "-h"       : help(args);
        default       : 
            switch (args.len) {
                case 1: show_stdout(rg_files());
                case 2: show_stdout(rg_files(args[1]));
                default:
                    switch (args[2]) {
                        case "list"     :
                        case "--list"   :
                        case "-l"       : list(args);
                    }
            }
    }
}

fn void list(String[] args)
{
    String[] files;

    switch (args.len) {
        case 1:
        case 2: files = rg_files(); 
        case 3: 
            if (args[1] == "list") files = rg_files(args[2]);
            if (args[1] == "-l"  ) files = rg_files(args[2]);
            if (args[2] == "list") files = rg_files(args[1]);
            if (args[2] == "-l"  ) files = rg_files(args[1]);
    }
    String cwd = os::getcwd(tmem)!!;
    foreach(file: files) {
        if (file::is_file(file)) io::printfn("%s/%s", cwd, file);
    }
}

fn void show_stdout(String[] files)
{
    String cwd = os::getcwd(tmem)!!;
    foreach(file: files) {
        if (file::is_file(file)) {
            if(try stdout(string::tformat("%s/%s", cwd, file))) {
                io::printfn("%s/%s", cwd, file);
            }
        }
    }
}

fn String[] rg_files(String filter = "")
{
    DString rg_res;
    SubProcess rg = process::create({ "rg", "--no-ignore", "--files", "-g", string::tformat("*%s*Test.html", filter) })!!;
    InStream stream = &&rg.stdout();
    while (try char byte = stream.read_byte()) {
        rg_res.append_char(byte);
    }
    return rg_res.str_view().trim().tsplit("\n");  
}

fn void? stdout(String path)
{
    String input = (String) file::load_temp(path)!!;
    String[] lines = input.trim().tsplit("\n");
    int start, end;
    bool has_stdout;
    for(int i; i<lines.len; i++) {
        if (lines[i].contains("<h2>Standard output</h2>")) {
            has_stdout = true;
            continue;
        }
        if (has_stdout && lines[i].contains("<pre>")) {
            start = i;
            continue;
        }
        if (has_stdout && lines[i].contains("</pre>")) {
            end = i-1; // skip </pre>
            break; // done
        }
    }
    if (!has_stdout) return STDOUT_NOT_FOUND?;
    String[] stdout = lines[start..end];
    stdout[0] = (String) stdout[0][5..]; // skip <pre>
    foreach(out: stdout) {
        io::printfn("%s", parse(out));
    }
}

fn String parse(String str)
{
    DString result;
    if (!str.len) return "";

    for (int i; i < str.len; i++) {
        switch {
            case i+1 < str.len && str[i..i+1].contains("?["):
                result.append('\e');
            case i+1 < str.len && str[i..i+1].contains("\n"):
                result.append('\n');
                i++;
            case i+3 < str.len && str[i..i+3].contains("&gt;"):
                result.append('>');
                i+=3;
            case i+3 < str.len && str[i..i+3].contains("&lt;"):
                result.append('<');
                i+=3;
            case i+5 < str.len && str[i..i+5].contains("&quot;"):
                result.append('"');
                i+=5;
            case i+6 < str.len && str[i..i+6].contains("\\&quot;"):
                result.append('"');
                i+=6;
            default: 
                result.append(str[i]);
        }
    }
    return result.str_view();
}

fn void help(String[] args)
{
    String commands = color::rainbow("commands", span: 2);
    String options = color::rainbow("options", span: 2);
    io::printfn("junit output v%s", VERSION);
    io::printfn("                                           ");
    io::printfn("usage: %s [<%s>] [<%s>] [<args>]", args[0], commands, options);
    io::printfn("");
    io::printfn("%s:", commands);
    io::printfn("  list    -l                    list the junit standard out files");
    io::printfn("");
    io::printfn("%s:", options);
    io::printfn("  -h      help                  print the help");
    io::printfn("  -v      version               print the version");
    io::printfn("");
}

fn void version(String[] args)
{
    io::printfn("%s", VERSION);
}

module color;
import std::math::random;

const String RESET_COLOR = "\x1b[0m";
const String ANSI_FG = "\x1b[38;2;%d;%d;%d;m%s%s";
const String ANSI_BG = "\x1b[48;2;%d;%d;%d;m%s%s";
const String ANSI_FG_CHAR = "\x1b[38;2;%d;%d;%d;m%c%s";

alias Color = int[3];

fn String String.fg(&self, Color color) => string::tformat(ANSI_FG, color[0], color[1], color[2], *self, color::RESET_COLOR);
fn String String.bg(&self, Color color) => string::tformat(ANSI_BG, color[0], color[1], color[2], *self, color::RESET_COLOR);

fn String random(String str) => string::tformat(ANSI_FG, rand(150)+50, rand(150)+50, rand(150)+50, str, RESET_COLOR);
fn String green(String str)  => str.fg({120, 240, 120});   // #78f078
fn String cyan(String str)   => str.fg({69, 133, 136});    // #458588
fn String blue(String str)   => str.fg({70, 130, 200});    // #4682C8
fn String gold(String str)   => str.fg({200, 280, 60});    // #C8B43C
fn String red(String str)    => str.fg({180, 50, 70});     // #B43246
fn String pink(String str)   => str.fg({255, 105, 180});   // #FF69B4
fn String purple(String str) => str.fg({120,  60, 180});   // #783CB4
fn String gray(String str)   => str.fg({128, 128, 128});   // #808080

fn String rainbow(String str, int span = 1)
{
    DString out;
    Color c = {rand(150)+50, rand(150)+50, rand(150)+50};
    foreach(i, ch: str) {
        if (i % span == 0) {
            c = {rand(150)+50, rand(150)+50, rand(150)+50};
        }
        out.append(string::tformat(ANSI_FG_CHAR, c[0], c[1], c[2], ch, RESET_COLOR));
    }
    return out.str_view();
} 

