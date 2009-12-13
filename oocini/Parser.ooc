import io/Reader
import text/StringBuffer
import structs/HashMap

ParseError: class extends Exception {
    init: func ~withMsg (.msg) {
        super(msg)
    }
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
            buffer append("%s = %s\n" format(key, values get(key)))
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
    file: INIFile
    value: StringBuffer

    init: func {
        setState(States section)
        section = ""
        file = INIFile new()
        value = StringBuffer new()
        /* add 'default' section */
        file addSection("")
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
                if(data == '=') {
                    /* value starting! */
                    /* save trimmed key */
                    key = value toString() trim()
                    resetValue()
                    /* new state: value */
                    setState(States value)
                }
                else if(data == ';' || data == '\n') {
                    /* invalid char. */
                    ParseError new(This, "Unexpected char: '%c'" format(data)) throw()
                } else {
                    /* key is continued. */
                    value append(data)
                }
            }
            case States value => {
                if(data == ';' || data == '\n') {
                    /* comment starting (end of value) OR newline (also end of value)! */
                    /* trim the value. */
                    file sections get(section) addValue(key, value toString() trim())
                    /* reset */
                    resetValue()
                    setState(match data {
                        case '\n' => States section
                        case ';' => States comment
                    })
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
