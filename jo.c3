import std::io;
import std::os::process;

fn void main(String[] args)
{
    Path cwd = path::new_cwd()!!;
    String[] files = rg_files();
    bool list;

    if (args.len > 1) {
        switch (args[1]) {
            case "list": 
                list = true;
                if (args.len > 2) files = rg_files(args[2]);
            default: files = rg_files(args[1]);
        }
    } 
    
    foreach(file: files) {
        if (file::is_file(file)) {
            if(stdout(string::tformat("%s/%s", cwd, file), !list)) {
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

fn bool stdout(String path, bool print = true)
{
    String input = (String) file::load_temp(path)!!;
    String[] lines = input.trim().tsplit("\n");
    int start, end;
    bool has_stdout;
    for(int i; i<lines.len; i++) {
        if (lines[i].contains("<h2>Standard output</h2>")) has_stdout = true;
        if (lines[i].contains("<pre>")) start = i;
        if (lines[i].contains("</pre>")) end = i-1; // skip </pre>
    }
    if (!has_stdout) return false;
    String[] stdout = lines[start..end];
    stdout[0] = (String) stdout[0][5..]; // skip <pre>

    foreach(out: stdout) {
        if (print) io::printfn("%s", parse(out));
    }
    return true;
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

