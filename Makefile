ALL_FINAL_TARGETS := README.md index.html resume/resume.docx resume/resume.html resume/resume.md resume/resume_latex.pdf resume/resume_md.html resume/resume_typ.pdf
DIRS = intermediate resume tmp
ADDITIONAL_OUTPUTS := intermediate/resume.tex intermediate/resume.typ resume/*.aux resume/*.log resume/*.out src/template tmp/resume.html tmp/resume_md.html
ALL_OUTPUTS := $(ALL_FINAL_TARGETS) $(DIRS) $(ADDITIONAL_OUTPUTS)
TEMPLATE_DEPS=src/resume.json5 $(TEMPLATE_EXEC) src/resume.tmpl
TEMPLATE_EXEC?=src/template

.PHONY: all clean

all: $(ALL_FINAL_TARGETS)

README.md: resume/resume.md src/README_footer.md
	cp $< $@ && cat src/README_footer.md >> $@

index.html: resume/resume.html src/index_footer.html
	cp $< $@ && cat src/index_footer.html >> $@

resume/resume.docx: tmp/resume_docx.html src/styles.docx | resume
	pandoc -s --reference-doc=src/styles.docx -f html -t docx $< -o $@

resume/resume.md: src/resume.md.tmpl src/resume.json5 $(TEMPLATE_EXEC) src/resume.tmpl | resume
	$(TEMPLATE_EXEC) $< > $@

resume/resume_latex.pdf: intermediate/resume.tex src/ft_resume.sty src/resume.sty | resume
	pdflatex -output-format=pdf -output-directory=resume $< && mv resume/resume.pdf resume/resume_latex.pdf

resume/resume_typ.pdf: intermediate/resume.typ src/style.typ | resume
	typst compile --root . -f pdf $< $@

intermediate/resume.tex: src/resume.tex.tmpl $(TEMPLATE_DEPS) | intermediate
	$(TEMPLATE_EXEC) $< > $@

intermediate/resume.typ: src/resume.typ.tmpl $(TEMPLATE_DEPS) | intermediate
	$(TEMPLATE_EXEC) $< > $@

tmp/resume_md.html: resume/resume.md | tmp
	pandoc -s -M document-css=false -M pagetitle="Glenn Hartmann - Resume" -f markdown -t html $< > $@

resume/%.html: tmp/%.html | resume
	prettier --parser=html --print-width 9999 < $< > $@

tmp/%.html: src/%.html.tmpl $(TEMPLATE_DEPS) | tmp
	$(TEMPLATE_EXEC) $< > $@

$(TEMPLATE_EXEC): src/template.go src/latex/latex.go
	cd src && go build -o template

$(DIRS):
	mkdir $@

clean:
	rm -rf $(ALL_OUTPUTS)
