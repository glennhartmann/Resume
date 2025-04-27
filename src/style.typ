#let headerNameFontSize = 14.4pt
#let mainFontSize = 11pt
#let headerAscent = 30pt

#let style(title, author, header, body) = {
  set document(title: title, author: author)

  set page(
    paper: "us-letter",
    margin: (
      top: 1in + headerNameFontSize + mainFontSize * 2 + headerAscent,
      bottom: 1in,
      x: 1in
    ),
    header: header,
    header-ascent: headerAscent,
  )

  set text(
    font: "New Computer Modern", // STIX Two Text is also not bad
    size: mainFontSize,
  )

  set par(justify: true)

  show heading: it => [
    #set text(weight: "bold")
    #smallcaps(it)
  ]

  show link: it => [
    #set text(fill: blue)
    #underline[#it]]

  body
}

#let fancyHeader(name, address, phone, email) = {
  align(center)[
    #text(size: headerNameFontSize, weight: "bold")[
      #name
    ]
  ]
  grid(
    columns: (1fr, 1fr, 1fr),
  )[
    #align(left)[#address]
  ][
    #align(center)[#phone]
  ][
    #align(right)[#email]
  ]
  line(length: 100%)
}

#let subheader(it) = [*#it*]

#let subsection(a, b) = [*#a, * #b]

#let indent(it) = {
  pad(left: 0.5in)[#it]
}
