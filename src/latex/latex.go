package latex

import (
	"bytes"
	"fmt"
	"regexp"
	"strings"
)

const indentStr = "    "

var (
	beginRx = regexp.MustCompile(`\\begin{.*}`)
	endRx   = regexp.MustCompile(`\\end{.*}`)
)

var texEscaper = strings.NewReplacer(
	"&", `\&`,
	"#", `\#`,
)

func EscapeTex(s string) string {
	return texEscaper.Replace(s)
}

func Indent(b []byte) []byte {
	sp := bytes.Split(b, []byte{'\n'})

	var buf bytes.Buffer
	level := 0
	for i, line := range sp {
		if i == len(sp)-1 && len(line) == 0 {
			continue
		}

		if len(line) > 0 {
			hasBegin := beginRx.Match(line)
			hasEnd := endRx.Match(line)

			if hasEnd && !hasBegin {
				level--
			}

			if level > 0 {
				writeIndent(&buf, level)
			}

			if hasBegin && !hasEnd {
				level++
			}

			if level < 0 {
				panic(fmt.Sprintf("unmatched \\end{} on line %d", i+1))
			}
		}

		if _, err := buf.Write(append(line, '\n')); err != nil {
			panic(fmt.Sprintf("buf.Write(): %+v", err))
		}
	}

	return buf.Bytes()
}

func writeIndent(buf *bytes.Buffer, level int) {
	for i := 0; i < level; i++ {
		if _, err := buf.Write([]byte(indentStr)); err != nil {
			panic(fmt.Sprintf("buf.Write() (indent level %d): %+v", i, err))
		}
	}
}
