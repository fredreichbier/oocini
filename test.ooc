import io/FileReader
import oocini/Parser

main: func {
    parser := State new()
    reader := FileReader new("test.ini")
    parser parse(reader)
    parser file sections get("FooBar") values get("key") println()
}
