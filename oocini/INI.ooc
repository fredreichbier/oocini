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

    getOption: func (sectionName, key: String) -> String {
        section := file sections get(sectionName)
        value := section values get(key) /* TODO: segfault protection for the uncool ones */
        /* TODO: ensure it returns null for unknown values */
        return value
    }

    getOption: func ~implicitSection (key: String) -> String {
        section := this section
        if(section == null)
            section = ""
        return getOption(section, key)
    }

    getOption: func ~withDefault (sectionName, key, def: String) -> String {
        value := getOption(sectionName, key)
        if(value == null) {
            value = def
        }
        return value    
    }

    getOption: func ~implicitSectionWithDefault (key, def: String) -> String {
        value := getOption(key)
        if(value == null) {
            value = def
        }
        return value
    }

    setOption: func (sectionName, key: String, val: String) {
        section := this file sections get(sectionName)
        if(!section) {
            section = this file addSection(sectionName)
        }
        section addValue(key, val)
    }

    setOption: func ~implicitSection (key: String, val: String) {
        section := this section
        if(section == null)
            section = ""
        setOption(section, key, val)
    }

    hasOption: func (sectionName, key: String) -> Bool {
        (file hasSection(sectionName)) ? file sections get(sectionName) hasValue(key) : false 
    }

    sections: func -> Iterable<String> {
        file sections
    }
}


 


