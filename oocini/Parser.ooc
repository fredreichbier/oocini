import io/Reader
import text/StringBuffer
import structs/HashMap

ParseError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
}

unescape: func (chr: Char, out: Char*) -> Bool {
     cOut: Char = match chr {
        case '\\' => '\\'
        case '0' => '\0'
        case 'b' => '\b'
        case 't' => '\t'
        case 'r' => '\r'
        case 'n' => '\n'
        case ';' => ';'
        case '#' => '#'
        case '=' => '='
        case ':' => ':'
        case '"' => '"'
        case '\'' => '\''
        case => -1
        /* TODO: unicode characters! */
    }
    out@ = cOut
    return cOut != -1
}

escape: func (chr: Char, out: Char*) -> Bool {
     cOut: Char = match chr {
        case '\\' => '\\'
        case '\0' => '0'
        case '\b' => 'b'
        case '\t' => 't'
        case '\r' => 'r'
        case '\n' => 'n'
        case ';' => ';'
        case '#' => '#'
        case '=' => '='
        case ':' => ':'
        case '"' => '"'
        case '\'' => '\''
        case => -1
        /* TODO: unicode characters! */
    }
    out@ = cOut
    return cOut != -1
}

escape: func ~string (s: String) -> String {
    buffer := StringBuffer new(s length())
    out, chr: Char
    for(i: SizeT in 0..s length()) {
        chr = s[i]
        if(escape(chr, out&)) {
            buffer append('\\') .append(out)
        } else {
            buffer append(chr)
        }
    }
    return buffer toString()
}

INISection: class {
    values: HashMap<String>

    init: func {
        values = HashMap<String> new()
    }

    addValue: func (key, value: String) {
        values put(key, value)
    }

    dump: func (buffer: StringBuffer) {
        for(key: String in values keys) {
            value := values get(key)
            value = escape(value)
            buffer append("%s = %s\n" format(key, value))
        }
    }
}

INIFile: class {
    sections: HashMap<INISection>

    init: func {
        sections = HashMap<INISection> new()
    }

    addSection: func (name: String) -> INISection {
        section := INISection new()
        sections put(name, section)
        section
    }

    hasSection: func (name: String) -> Bool {
        sections contains(name)
    }

    getSection: func (name: String) -> INISection {
        if(!hasSection(name)) {
            addSection(name)
        }
        sections get(name)
    }

    dump: func -> String {
        buffer := StringBuffer new()
        for(name: String in sections keys) {
            if(!name isEmpty()) {
                buffer append("[%s]\n" format(name))
            }
            sections get(name) dump(buffer)
            buffer append("\n")
        }
        buffer toString()
    }
}

State: class {
    state: Int
    section, key: String
    quoted: Char
    escapeSeq: Bool
    file: INIFile
    value: StringBuffer

    init: func {
        reset()
    }

    reset: func {
        setState(States section)
        section = ""
        quoted = 0
        file = INIFile new()
        value = StringBuffer new()
        /* add 'default' section */
        file addSection("")
        escapeSeq = false
    }

    setState: func (=state) {}

    resetValue: func {
        value = StringBuffer new()
    }

    feed: func ~string (data: String, length: SizeT) {
        for(i: Int in 0..length) {
            feed(data[i])
        }
    }

    feed: func (data: Char) {
        match state {
            case States section => {
                if(data == ';') {
                    /* comment starting! */
                    resetValue()
                    setState(States comment)
                } else if(data == '[') {
                    /* section name starting! */
                    resetValue()
                    setState(States sectionName)
                } else if(data == '\n' || data == ' ') {
                    /* whitespace, ignore. */
                } else if(data == '#' || data == ';') {
                    /* comment. change state. */
                    setState(States comment)
                } else {
                    /* key starting. */
                    /* check if the char is valid. */
                    if(data == '=') {
                        ParseError new(This, "Unexpected char: '='") throw()
                    } else {
                        /* valid char! */
                        value append(data)
                        /* new state: key. */
                        setState(States key)
                    }
                }
            }
            case States key => {
                if(escapeSeq) {
                    /* escape sequence, second char. */
                    out: Char
                    if(unescape(data, out&)) {
                        /* valid escape sequence! */
                        value append(out)
                    } else {
                        /* invalid escape sequence, just append the current char. */
                        value append(data)
                    }
                    escapeSeq = false
                } else if(data == '=' || data == ':') {
                    /* value starting! */
                    /* save trimmed key */
                    key = value toString() trim()
                    resetValue()
                    /* new state: value */
                    setState(States value)
                } else if(data == ';' || data == '#' || data == '\n') {
                    /* invalid char. */
                    value toString() println()
                    ParseError new(This, "Unexpected char: '%c'" format(data)) throw()
                } else if(data == '\\') {
                    /* escape sequence starting */
                    escapeSeq = true
                } else {
                    /* key is continued. */
                    value append(data)
                }
            }
            case States value => {
                if(escapeSeq) {
                    /* escape sequence, second char. */
                    out: Char
                    if(unescape(data, out&)) {
                        /* valid escape sequence! */
                        value append(out)
                    } else {
                        /* invalid escape sequence, just append the current char. */
                        value append(data)
                    }
                    escapeSeq = false
                } else if((data == '"' || data == '\'') && value toString() isEmpty()) {
                    /* quoted. */
                    quoted = data
                }
                else if(data == ' ' && value toString() isEmpty()) {
                    /* strip whitespace at the beginning */
                }
                else if(\
                    (!quoted && (data == ';' || data == '#')) \
                    || (quoted && data == quoted) \
                    || data == '\n') {
                    /* comment starting (end of value) OR newline (also end of value) OR quotation end. */
                    /* trim the value. */
                    theValue := value toString()
                    if(!quoted) {
                        theValue = theValue trim()
                    }
                    quoted = 0
                    file sections get(section) addValue(key, theValue)
                    /* reset */
                    resetValue()
                    setState(match data {
                        case '\n' => States section
                        case '"' => States section
                        case '\'' => States section
                        case ';' => States comment
                        case '#' => States comment
                    })
                } else if(data == '\\') {
                    /* escape sequence starting */
                    escapeSeq = true
                } else {
                    /* part of the value. */
                    value append(data)
                }
            }
            case States comment => {
                if(data == '\n') {
                    /* newline, so new state is section */
                    setState(States section)
                    /* no need to resetValue here. */
                } else {
                    /* otherwise: just ignore - it's a comment, baby. */
                }
            }
            case States sectionName => {
                if(data == ']') {
                    /* end of section name, set it, new state: section */
                    section = value toString()
                    file addSection(section)
                    resetValue()
                    setState(States section)
                } /* TODO: check invalid chars */ else {
                    value append(data)
                }
            }
        }
    }

    parse: func (reader: Reader) {
        bufferSize := const 10
        chars := String new(bufferSize)
        while(true) {
            count := reader read(chars, 0, 10)
            feed(chars, count)
            if(count < bufferSize) {
                break
            }
        }
    }
}

States: class {
    section := const static 0
    key := const static 1
    value := const static 2
    comment := const static 3
    sectionName := const static 4
}
