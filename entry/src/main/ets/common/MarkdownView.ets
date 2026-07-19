import { MarkdownPart, parseMarkdown, InlineSpan, parseInline } from './MarkdownParser'

@Component
export struct MarkdownView {
  @Prop text: string = ''
  @State parts: MarkdownPart[] = []

  aboutToAppear(): void { this.reparse() }
  onDidChange(): void { this.reparse() }
  reparse(): void { this.parts = parseMarkdown(this.text) }

  build() {
    Column() {
      ForEach(this.parts, (p: MarkdownPart, idx: number) => {
        if (p.type === 'blank') {
          Blank().height(8)
        } else if (p.type === 'code') {
          Column() {
            if (p.lang) {
              Text(p.lang).fontSize(10).fontColor('#888888').padding({ left: 12, top: 8, right: 12 })
            }
            Text(p.text).fontSize(12).fontFamily('monospace')
              .fontColor('#d4d4d4').backgroundColor('#1e1e1e')
              .padding(12).borderRadius(8).width('100%')
          }.width('100%').margin({ top: 8, bottom: 8 })
        } else if (p.type === 'h1') {
          Text(p.text).fontSize(22).fontWeight(FontWeight.Bold).padding({ top: 16, bottom: 4 }).width('100%')
        } else if (p.type === 'h2') {
          Text(p.text).fontSize(19).fontWeight(FontWeight.Bold).padding({ top: 12, bottom: 4 }).width('100%')
        } else if (p.type === 'h3') {
          Text(p.text).fontSize(16).fontWeight(FontWeight.Bold).padding({ top: 10, bottom: 4 }).width('100%')
        } else {
          // Paragraph with inline formatting
          this.buildInline(p.text)
        }
      }, (p: MarkdownPart, idx: number) => idx.toString() + p.type)
    }.width('100%')
  }

  @Builder
  buildInline(text: string) {
    Text() {
      ForEach(parseInline(text), (s: InlineSpan) => {
        if (s.type === 'bold') {
          Span(s.text).fontWeight(FontWeight.Bold)
        } else if (s.type === 'italic') {
          Span(s.text).fontStyle(FontStyle.Italic)
        } else if (s.type === 'code') {
          Span(s.text).fontColor('#e06c75').fontFamily('monospace')
            .fontSize(12).backgroundColor('#2d2d2d').borderRadius(3)
        } else {
          Span(s.text)
        }
      })
    }.fontSize(14).lineHeight(22).width('100%')
  }
}
