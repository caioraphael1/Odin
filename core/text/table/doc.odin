/*
Plain-text/markdown/HTML/custom rendering of tables.

**Custom rendering.**
Example:
    package main

    import "core:io"
    import "core:text/table"

    main :: proc() {
        stdout := table.stdio_writer()

        tbl := table.init(&table.Table{})
        table.padding(tbl, 0, 1)
        table.row(tbl, "A_LONG_ENUM", "= 54,", "// A comment about A_LONG_ENUM")
        table.row(tbl, "AN_EVEN_LONGER_ENUM", "= 1,", "// A comment about AN_EVEN_LONGER_ENUM")
        table.build(tbl, table.unicode_width_proc)
        for row in 0..<tbl.nr_rows {
            for col in 0..<tbl.nr_cols {
                table.write_table_cell(stdout, tbl, row, col)
            }
            io.write_byte(stdout, '\n')
        }
    }

Output:
    A_LONG_ENUM         = 54, // A comment about A_LONG_ENUM
    AN_EVEN_LONGER_ENUM = 1,  // A comment about AN_EVEN_LONGER_ENUM

**Plain-text rendering.**
Example:
    package main

    import "core:fmt"
    import "core:io"
    import "core:text/table"

    main :: proc() {
        stdout := table.stdio_writer()

        tbl := table.init(&table.Table{})
        defer table.destroy(tbl)

        table.caption(tbl, "This is a table caption and it is very long")

        table.padding(tbl, 1, 1) // Left/right padding of cells

        table.header(tbl, "AAAAAAAAA", "B")
        table.header(tbl, "C") // Appends to previous header row. Same as if done header("AAAAAAAAA", "B", "C") from start.

        // Create a row with two values. Since there are three columns the third
        // value will become the empty string.
        //
        // NOTE: table.header() is not allowed anymore after this.
        table.row(tbl, 123, "foo")

        // Use `format()` if you need custom formatting. This will allocate into
        // the arena specified at init.
        table.row(tbl,
            table.format(tbl, "%09d", 5),
            table.format(tbl, "%.6f", 6.28318530717958647692528676655900576))

        // A row with zero values is allowed as long as a previous row or header
        // exist. The value and alignment of each cell can then be set
        // individually.
        table.row(tbl)

        table.set_cell_value_and_alignment(tbl, table.last_row(tbl), 0, "a", .Center)
        table.set_cell_value(tbl, table.last_row(tbl), 1, "bbb")
        table.set_cell_value(tbl, table.last_row(tbl), 2, "c")

        // Headers are regular cells, too. Use header_row() as row index to modify
        // header cells.
        table.set_cell_alignment(tbl, table.header_row(tbl), 1, .Center) // Sets alignment of 'B' column to Center.
        table.set_cell_alignment(tbl, table.header_row(tbl), 2, .Right) // Sets alignment of 'C' column to Right.

        table.write_plain_table(stdout, tbl)
        fmt.println()
        table.write_markdown_table(stdout, tbl)
    }

Output:
    +-----------------------------------------------+
    |  This is a table caption and it is very long  |
    +------------------+-----------------+----------+
    | AAAAAAAAA        |        B        |        C |
    +------------------+-----------------+----------+
    | 123              | foo             |          |
    | 000000005        | 6.283185        |          |
    |        a         | bbb             | c        |
    +------------------+-----------------+----------+

    |    AAAAAAAAA     |        B        |    C     |
    |:-----------------|:---------------:|---------:|
    | 123              | foo             |          |
    | 000000005        | 6.283185        |          |
    | a                | bbb             | c        |


Additionally, if you want to set the alignment and values in-line while
constructing a table, you can use `aligned_row_of_values` or
`row_of_aligned_values` like so:

    table.aligned_row_of_values(tbl, .Center, "Foo", "Bar")
    table.row_of_aligned_values(tbl, {{.Center, "Foo"}, {.Right, "Bar"}})

**Caching Results:**

If you only need to build a table once but display it potentially many times,
it may be more efficient to cache the results of your write into a string.

Example:
    package main

    import "core:fmt"
    import "base:container/strings"
    import "core:text/table"

    main :: proc() {
        string_buffer := string_builder.builder_create()
        defer string_builder.builder_destroy(&string_buffer)

        {
            tbl: table.Table
            table.init(&tbl)
            defer table.destroy(&tbl)
            table.caption(&tbl, "Hellope!")
            table.row(&tbl, "Hellope", "World")

            builder_writer := string_builder.to_writer(&string_buffer)

            // The written table will be cached into the string builder after this call.
            table.write_plain_table(builder_writer, &tbl)
        }
        // The table is inaccessible, now that we're back in the first-level scope.

        // But now the results are stored in the string builder, which can be converted to a string.
        my_table_string := string_builder.to_string(string_buffer)

        // Remember that the string's allocated backing data lives in the
        // builder and must still be freed.
        //
        // The deferred call to `builder_destroy` will take care of that for us
        // in this simple example.
        fmt.println(my_table_string)
    }

**Regarding `Width_Procs`:**

If you know ahead of time that all the text you're parsing is ASCII, instead of
Unicode, it is more efficient to use `table.ascii_width_proc` instead of the
default `unicode_width_proc`, as that procedure has to perform in-depth lookups
to determine multiple Unicode characteristics of the codepoints parsed in order
to get the proper alignment for a variety of different scripts.

For example, you may do this instead:

    table.write_plain_table(stdout, tbl, table.ascii_width_proc)
    table.write_markdown_table(stdout, tbl, table.ascii_width_proc)

The output will still be the same, but the preprocessing is much faster.


You may also supply your own `Width_Proc`s, if you know more about how the text
is structured than what we can assume.

    simple_cjk_width_proc :: proc(str: string) -> (result: int) {
        for r in str {
            result += 2
        }
        return
    }

    table.write_plain_table(stdout, tbl, simple_cjk_width_proc)

This procedure will output 2 times the number of UTF-8 runes in a string, a
simple heuristic for CJK-only wide text.

**Unicode Support:**

This package makes use of the `grapheme_count` procedure from the
`core:unicode/utf8` package. It is a complete, standards-compliant
implementation for counting graphemes and calculating visual width of a Unicode
grapheme cluster in monospace cells.

Example:
    package main

    import "core:fmt"
    import "core:io"
    import "core:os"
    import "core:text/table"

    scripts :: proc(w: io.Writer) {
        t: table.Table
        table.init(&t)
        table.caption(&t, "Tést Suite")
        table.padding(&t, 1, 3)
        table.header_of_aligned_values(&t, {{.Left, "Script"}, {.Center, "Sample"}})

        table.row(&t, "Latin", "At vero eos et accusamus et iusto odio dignissimos ducimus,")
        table.row(&t, "Cyrillic", "Ру́сский язы́к — язык восточнославянской группы славянской")
        table.row(&t, "Greek", "Η ελληνική γλώσσα ανήκει στην ινδοευρωπαϊκή οικογένεια")
        table.row(&t, "Younger Futhark", "ᚴᚢᚱᛘᛦ ᚴᚢᚾᚢᚴᛦ ᚴᛅᚱᚦᛁ ᚴᚢᛒᛚ ᚦᚢᛋᛁ ᛅᚠᛏ ᚦᚢᚱᚢᛁ ᚴᚢᚾᚢ ᛋᛁᚾᛅ ᛏᛅᚾᛘᛅᚱᚴᛅᛦ ᛒᚢᛏ")
        table.row(&t, "Chinese hanzi", "官話為汉语的一支，主體分布在中国北部和西南部的大部分地区。")
        table.row(&t, "Japanese kana", "いろはにほへとちりぬるをわかよたれそつねならむ")
        table.row(&t, "Korean hangul", "한글, 조선글은 한국어의 공식문자로서, 세종이 한국어를")
        table.row(&t, "Thai", "ภาษาไทย หรือ ภาษาไทยกลาง เป็นภาษาในกลุ่มภาษาไท ซึ่งเป็นกลุ่มย่อยของตระกูลภาษาขร้า-ไท")
        table.row(&t, "Georgian", "ქართული ენა — ქართველურ ენათა ოჯახის ენა. ქართველების მშობლიური ენა,")
        table.row(&t, "Armenian", "Իր շուրջ հինգհազարամյա գոյության ընթացքում հայերենը շփվել է տարբեր")
        table.row(&t)
        table.row_of_aligned_values(&t, {{.Left, "Arabic"}, {.Right, "ٱللُّغَةُ ٱلْعَرَبِيَّة هي أكثر اللغات السامية تحدثًا، وإحدى أكثر"}})
        table.row_of_aligned_values(&t, {{.Left, "Hebrew"}, {.Right, "עִבְרִית היא שפה שמית, ממשפחת השפות האפרו-אסייתיות, הידועה"}})
        table.row(&t)
        table.row(&t, "Swedish", "Växjö [ˈvɛkːˌɧøː] är en tätort i södra Smålands inland samt centralort i Växjö kommun")
        table.row(&t, "Saxon", "Hwæt! We Gardena in geardagum, þeodcyninga, þrym gefrunon, hu ða æþelingas ellen fremedon.")
        table.row(&t)
        table.aligned_row_of_values(&t, .Center, "Emoji (Single codepoints)", "\U0001f4ae \U0001F600 \U0001F201 \U0001F21A")
        table.row(&t, "Excessive Diacritics", "H̷e̶l̵l̸o̴p̵e̷ ̸w̶o̸r̵l̶d̵!̴")

        table.write_plain_table(w, &t)
        fmt.println()
    }

    main :: proc() {
        stdout := os.stream_from_handle(os.stdout)

        scripts(stdout)
    }

Output:

    +----------------------------------------------------------------------------------------------------------------------------+
    |                                                        Tést Suite                                                          |
    +-----------------------------+----------------------------------------------------------------------------------------------+
    | Script                      |                                           Sample                                             |
    +-----------------------------+----------------------------------------------------------------------------------------------+
    | Latin                       | At vero eos et accusamus et iusto odio dignissimos ducimus,                                  |
    | Cyrillic                    | Ру́сский язы́к — язык восточнославянской группы славянской                                     |
    | Greek                       | Η ελληνική γλώσσα ανήκει στην ινδοευρωπαϊκή οικογένεια                                       |
    | Younger Futhark             | ᚴᚢᚱᛘᛦ ᚴᚢᚾᚢᚴᛦ ᚴᛅᚱᚦᛁ ᚴᚢᛒᛚ ᚦᚢᛋᛁ ᛅᚠᛏ ᚦᚢᚱᚢᛁ ᚴᚢᚾᚢ ᛋᛁᚾᛅ ᛏᛅᚾᛘᛅᚱᚴᛅᛦ ᛒᚢᛏ                               |
    | Chinese hanzi               | 官話為汉语的一支，主體分布在中国北部和西南部的大部分地区。                                   |
    | Japanese kana               | いろはにほへとちりぬるをわかよたれそつねならむ                                               |
    | Korean hangul               | 한글, 조선글은 한국어의 공식문자로서, 세종이 한국어를                                        |
    | Thai                        | ภาษาไทย หรือ ภาษาไทยกลาง เป็นภาษาในกลุ่มภาษาไท ซึ่งเป็นกลุ่มย่อยของตระกูลภาษาขร้า-ไท                     |
    | Georgian                    | ქართული ენა — ქართველურ ენათა ოჯახის ენა. ქართველების მშობლიური ენა,                         |
    | Armenian                    | Իր շուրջ հինգհազարամյա գոյության ընթացքում հայերենը շփվել է տարբեր                           |
    |                             |                                                                                              |
    | Arabic                      |                                     ٱللُّغَةُ ٱلْعَرَبِيَّة هي أكثر اللغات السامية تحدثًا، وإحدى أكثر   |
    | Hebrew                      |                                    עִבְרִית היא שפה שמית, ממשפחת השפות האפרו-אסייתיות, הידועה   |
    |                             |                                                                                              |
    | Swedish                     | Växjö [ˈvɛkːˌɧøː] är en tätort i södra Smålands inland samt centralort i Växjö kommun        |
    | Saxon                       | Hwæt! We Gardena in geardagum, þeodcyninga, þrym gefrunon, hu ða æþelingas ellen fremedon.   |
    |                             |                                                                                              |
    | Emoji (Single codepoints)   |                                        💮 😀 🈁 🈚                                           |
    | Excessive Diacritics        | H̷e̶l̵l̸o̴p̵e̷ ̸w̶o̸r̵l̶d̵!̴                                                                               |
    +-----------------------------+----------------------------------------------------------------------------------------------+

**Decorated Tables:**

If you'd prefer to change the borders used by the plain-text table printing,
there is the `write_decorated_table` procedure that allows you to change the
corners and dividers.

Example:
    package main

    import "core:fmt"
    import "core:io"
    import "core:os"
    import "core:text/table"

    box_drawing :: proc(w: io.Writer) {
        t: table.Table
        table.init(&t)
        table.caption(&t, "Box Drawing Example")
        table.padding(&t, 2, 2)
        table.header_of_aligned_values(&t, {{.Left, "Operating System"}, {.Center, "Year Introduced"}})

        table.row(&t, "UNIX",                "1973")
        table.row(&t, "MS-DOS",              "1981")
        table.row(&t, "Commodore 64 KERNAL", "1982")
        table.row(&t, "Mac OS",              "1984")
        table.row(&t, "Amiga",               "1985")
        table.row(&t, "Windows 1.0",         "1985")
        table.row(&t, "Linux",               "1991")
        table.row(&t, "Windows 3.1",         "1992")

        decorations := table.Decorations {
            "┌", "┬", "┐",
            "├", "┼", "┤",
            "└", "┴", "┘",
            "│", "─",
        }

        table.write_decorated_table(w, &t, decorations)
        fmt.println()
    }

    main :: proc() {
        stdout := os.stream_from_handle(os.stdout)

        box_drawing(stdout)
    }

While the decorations support multi-codepoint Unicode graphemes, do note that
each border character should not be larger than one monospace cell.

*/
