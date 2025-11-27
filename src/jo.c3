module jo;

import std::io;
import std::os::process;
import color;
import xml;

const VERSION = "0.3";

faultdef STDOUT_NOT_FOUND;

struct Opts {
    bool list;
    bool tests;
}

fn void main(String[] args)
{
    switch (args[1]) {
        case "list"     :
        case "--list"   :
        case "-l"       : list(args);
        case "tests"    :
        case "--tests"  :
        case "-t"       : tests(args);
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
                        case "tests"    :
                        case "--tests"  :
                        case "-t"       : tests(args);
                    }
            }
    }
}

fn void list(String[] args)
{
    String[] files;
    list_files(args, &files);
    String cwd = os::getcwd(tmem)!!;
    foreach(file: files) {
        if (file::is_file(file)) io::printfn("%s/%s", cwd, file);
    }
}

fn void list_files(String[] args, String[]* files)
{
    switch (args.len) {
        case 1:
        case 2: *files = rg_files(); 
        case 3: 
            if (args[1] == "list") *files = rg_files(args[2]);
            if (args[1] == "-l"  ) *files = rg_files(args[2]);
            if (args[2] == "list") *files = rg_files(args[1]);
            if (args[2] == "-l"  ) *files = rg_files(args[1]);
    }
}

fn void show_stdout(String[] files)
{
    String cwd = os::getcwd(tmem)!!;
    foreach(file: files) {
        if (!file::is_file(file)) continue;
        if(try standard_output(string::tformat("%s/%s", cwd, file))) {
            io::printfn("%s/%s", cwd, file);
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

fn void? standard_output(String path)
{
    xml::Parser parser = xml::load_file(path)!;
    Node html = parser.root;
    NodeList div_class_tab;
    html.find(fn (node) {
        if (node.name != "div") return false;
        if (!node.attributes.has_key("class")) return false; 
        return node.attributes.get("class")!! == "tab";
    }, &div_class_tab);

    foreach(div : div_class_tab) {
        foreach (child: div.children) {
            if (child.value != "Standard output") continue;
            if (try span = div.get("span")) {
                if (try pre = span.get("pre")) {
                    io::printfn("%s", parse(pre.value));
                }
            }
        }
    }
}

fn void tests(String[] args)
{
    String[] files;
    switch (args.len) {
        case 2: files = rg_files();
        default: files = rg_files(args[1]);
    }
    String cwd = os::getcwd(tmem)!!;
    foreach(file: files) {
        if (!file::is_file(file)) continue; 
        if(try file_tests = parse_tests(string::tformat("%s/%s", cwd, file))) {
            io::printfn("%s", file_tests);
        }
    }
}

fn String? parse_tests(String path)
{
    io::printfn("%s", path);
    xml::Parser parser = xml::load_file(path)!;
    Node html = parser.root;
    NodeList div_class_tab;
    html.find(fn (node) {
        if (node.name != "div") return false;
        if(!node.attributes.has_key("class")) return false; 
        return node.attributes.get("class")!! == "tab";
    }, &div_class_tab);

    Node* table;
    foreach(d, div : div_class_tab) {
        foreach (c, child: div.children) {
            if (child.value != "Tests") continue;
            table = div.get("table")!;
        }
    }

    NodeList trs;
    table.find(fn (node) => node.name == "tr", &trs);

    foreach(idx, tr: trs) {
        NodeList test = tr.children;
        String name = test[0].value;
        String duration = test[1].value;
        String result = test[2].value;
        switch (result) {
            case "passed" : result = color::green(" ");
            case "ignored": result = color::gray(" ");
            case "failed" : result = color::red(" ");
        }
        if (idx == 0) continue; // headers titles
        io::printfn("%-29s %-9s %s", result, duration, name);
    }
    return "";
}

fn String parse(String str)
{
    DString result;
    if (!str.len) return "";

    for (int i; i < str.len; i++) {
        switch {
            case i+1 < str.len && str[i..i+1].contains("?["):
                result.append('\e');
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
    io::printfn("  tests   -t                    show the test results");
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

// ----------------------------------------
// xml.c3 EXTENSION
// does not work on references: use .get()
// ----------------------------------------
fn Node*? Node.get(&self, String name) @operator([])
{
	if (self.name == name) return self;
	foreach (child: self.children) {
        if (child.name == name) return @clone(child);
    }
    return NOT_FOUND?;
}

