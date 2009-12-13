import io/[File, FileReader, FileWriter]

import oocini/Parser

INI: class {

    fileName: String
    state: State
    file: INIFile
    section = null: String

    init: func {
        state = State new()
    }

    init: func ~explicitFilename (=fileName) {
        this()
        state parse(FileReader new(fileName))
        file = state file
    }

    dump: func ~explicitFileName (fileName: String) {
        writer := FileWriter new(fileName)
        writer write(file dump())
        writer close()
    }
    
    dump: func {
        writer := FileWriter new(fileName)
        writer write(file dump())
        writer close()    
    }

    dumpToString: func -> String {
        file dump()
    }

    dump: func ~explicitFile (fptr: File) {
        writer := FileWriter new(fptr)
        writer write(file dump())
        writer close()    
    }

    setCurrentSection: func(=section) {}

    getOption: func<T> (sectionName, key: String, def: T) -> T {
        section := file sections get(sectionName)
        value := section values get(key) /* TODO: segfault protection for the uncool ones */
        if(value == null) {
            return def
        } else {
            match T {
                case String => {
                    return value
                }
                case Bool => {
                    first := value[0]
                    if(first == 'y' \
                        || first == 'Y' \
                        || first == 't' \
                        || first == 'T' \
                        || first == '1') {
                        return true
                    } else if(first == 'n' \
                        || first == 'N' \
                        || first == 'f' \
                        || first == 'F' \
                        || first == '0') {
                        return false
                    } else {
                        return def
                    }
                }
                case Int => {
                    return value toInt()
                }
                case Double => {
                    return value toDouble()
                }
                case => {
                    "STRANGE STUFF MAN! Unknown type." println()
                }
            }
        }
    }

    getOption: func<T> ~implicitSection (key: String, def: T) -> T {
        section := this section
        if(section == null)
            section = ""
        return getOption(section, key, def)
    }

    setOption: func (sectionName, key: String, val: String) {
        section := this file sections get(sectionName)
        section addValue(key, val)
    }

    setOption: func ~implicitSection (key: String, val: String) {
        section := this section
        if(section == null)
            section = ""
        setOption(section, key, val)
    }
}


 


