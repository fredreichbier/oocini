use oocini
import structs/Array

import oocini/INI

main: func (args: Array<String>) -> Int {
    if(args size < 2) {
        "./test INIFILE" println()
        return 1
    }
    ini := INI new(args[1])
    ini dumpToString() println()
}
