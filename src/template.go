package main

import (
	"bytes"
	"fmt"
	"html"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"

	"github.com/glennhartmann/Resume/src/latex"

	"github.com/titanous/json5"
)

const (
	dataFile         = "src/resume.json5"
	mainTemplateFile = "src/resume.tmpl"

	htmlTemplateFileSuffix  = ".html.tmpl"
	latexTemplateFileSuffix = ".tex.tmpl"
	typstTemplateFileSuffix = ".typ.tmpl"
)

var multilineRx = regexp.MustCompile(`(?m)\n{3,}`)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <template_file>\n", os.Args[0])
		os.Exit(1)
	}
	templateFile := os.Args[1]

	b, err := ioutil.ReadFile(dataFile)
	if err != nil {
		panic(fmt.Sprintf("ioutil.ReadFile(): %+v", err))
	}

	var r any
	if err := json5.Unmarshal(b, &r); err != nil {
		panic(fmt.Sprintf("json5.Unmarshal(): %+v", err))
	}

	var transformer func(string) string
	switch {
	case strings.HasSuffix(templateFile, htmlTemplateFileSuffix):
		transformer = html.EscapeString
	case strings.HasSuffix(templateFile, latexTemplateFileSuffix):
		transformer = latex.EscapeTex
	case strings.HasSuffix(templateFile, typstTemplateFileSuffix):
		transformer = escapeTypst
	}
	if transformer != nil {
		r = transformStrings(r, transformer)
	}

	b, err = ioutil.ReadFile(mainTemplateFile)
	if err != nil {
		panic(fmt.Sprintf("ioutil.ReadFile(): %+v", err))
	}

	// In markdown, sufficient indentation causes code blocks. Typst also
	// doesn't seem to like it. Plus, the intendation is kind of arbitrary
	// anyway, so we might as well just strip it everywhere.
	b = trimSpace(b)

	t := template.New(mainTemplateFile)
	t, err = t.Parse(string(b))
	if err != nil {
		panic(fmt.Sprintf("t.Parse(): %+v", err))
	}

	t, err = t.ParseFiles(templateFile)
	if err != nil {
		panic(fmt.Sprintf("t.ParseFiles(): %+v", err))
	}

	var buf bytes.Buffer
	if err := t.ExecuteTemplate(&buf, filepath.Base(templateFile), r); err != nil {
		panic(fmt.Sprintf("t.ExecuteTemplate(): %+v", err))
	}

	// Get rid of a lot of extra newlines.
	b = multilineRx.ReplaceAll(buf.Bytes(), []byte{'\n', '\n'})

	if strings.HasSuffix(templateFile, latexTemplateFileSuffix) {
		b = latex.Indent(b)
	}

	if _, err := os.Stdout.Write(b); err != nil {
		panic(fmt.Sprintf("os.Stdout.Write(): %+v", err))
	}
}

func transformStrings(data any, f func(string) string) any {
	switch v := data.(type) {
	case map[string]any:
		for k, val := range v {
			v[k] = transformStrings(val, f)
		}
		return v
	case []any:
		for i, val := range v {
			v[i] = transformStrings(val, f)
		}
		return v
	case string:
		return f(v)
	}

	panic(fmt.Sprintf("invalid type in json: %T (%v)", data, data))
}

var typstEscaper = strings.NewReplacer(
	"#", `\#`,
)

func escapeTypst(s string) string {
	return typstEscaper.Replace(s)
}

func trimSpace(b []byte) []byte {
	sp := bytes.Split(b, []byte{'\n'})
	for i := range sp {
		sp[i] = bytes.TrimSpace(sp[i])
	}
	return bytes.Join(sp, []byte{'\n'})
}
