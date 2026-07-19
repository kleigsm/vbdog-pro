// Simple Markdown parser for VBDog Pro
// Handles: headings, bold, italic, inline code, code blocks, paragraphs

export interface MarkdownPart {
  type: 'h1' | 'h2' | 'h3' | 'p' | 'code' | 'blank'
  text: string
  lang?: string
}

export function parseMarkdown(raw: string): MarkdownPart[] {
  if (!raw || raw.trim().length === 0) return []
  const parts: MarkdownPart[] = []
  const segments = raw.split('```')
  for (let i = 0; i < segments.length; i++) {
    if (i % 2 === 0) {
      parts.push(...parseTextBlock(segments[i]))
    } else {
      const lines = segments[i].split('\n')
      const first = lines[0].trim()
      const hasLang = first.length > 0 && first.length < 24 && !first.includes(' ')
      const lang = hasLang ? first : ''
      const body = hasLang ? lines.slice(1).join('\n') : segments[i]
      if (body.trim().length > 0) {
        parts.push({ type: 'code', text: body, lang: lang })
      }
    }
  }
  return parts
}

function parseTextBlock(text: string): MarkdownPart[] {
  const parts: MarkdownPart[] = []
  const lines = text.split('\n')
  for (const line of lines) {
    const t = line.trim()
    if (t.length === 0) {
      parts.push({ type: 'blank', text: '' })
    } else if (t.startsWith('### ')) {
      parts.push({ type: 'h3', text: t.slice(4) })
    } else if (t.startsWith('## ')) {
      parts.push({ type: 'h2', text: t.slice(3) })
    } else if (t.startsWith('# ')) {
      parts.push({ type: 'h1', text: t.slice(2) })
    } else {
      parts.push({ type: 'p', text: line })
    }
  }
  return parts
}

// Inline span types for rich text within a paragraph
export interface InlineSpan {
  type: 'text' | 'bold' | 'italic' | 'code'
  text: string
}

export function parseInline(text: string): InlineSpan[] {
  const spans: InlineSpan[] = []
  let i = 0
  while (i < text.length) {
    // Bold **...**
    if (text[i] === '*' && text[i + 1] === '*' && i + 2 < text.length) {
      const end = text.indexOf('**', i + 2)
      if (end > i) {
        spans.push({ type: 'bold', text: text.slice(i + 2, end) })
        i = end + 2
        continue
      }
    }
    // Italic *...*
    if (text[i] === '*' && text[i + 1] !== '*' && i + 1 < text.length) {
      const end = text.indexOf('*', i + 1)
      if (end > i) {
        spans.push({ type: 'italic', text: text.slice(i + 1, end) })
        i = end + 1
        continue
      }
    }
    // Inline code `...`
    if (text[i] === '`') {
      const end = text.indexOf('`', i + 1)
      if (end > i) {
        spans.push({ type: 'code', text: text.slice(i + 1, end) })
        i = end + 1
        continue
      }
    }
    // Plain text — grab until next special char
    let j = i
    while (j < text.length && text[j] !== '*' && text[j] !== '`') { j++ }
    if (j > i) {
      spans.push({ type: 'text', text: text.slice(i, j) })
    }
    i = j
  }
  return spans
}
