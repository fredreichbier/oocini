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

    getEntry: func<T> (key: String, def: T) -> T {
        section := match this section {
            case null => file sections get("")
            case => file sections get(this section)
        }
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

    setEntry: func<T> (key: String, val: String) {
        section := match this section {
            case null => file sections get("")
            case => file sections get(this section)
        }
        section addValue(key, val)
    }
}


 


