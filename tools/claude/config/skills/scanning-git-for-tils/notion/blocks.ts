/**
 * Notion block conversion utilities with proper TypeScript types.
 * Compare to Python version - notice discriminated unions work automatically.
 */

// Notion block types - discriminated unions
type RichText = {
  type: "text";
  text: { content: string };
};

type CodeBlock = {
  type: "code";
  code: {
    rich_text: RichText[];
    language: string;
  };
};

type Heading1 = {
  type: "heading_1";
  heading_1: { rich_text: RichText[] };
};

type Heading2 = {
  type: "heading_2";
  heading_2: { rich_text: RichText[] };
};

type Heading3 = {
  type: "heading_3";
  heading_3: { rich_text: RichText[] };
};

type BulletedListItem = {
  type: "bulleted_list_item";
  bulleted_list_item: { rich_text: RichText[] };
};

type NumberedListItem = {
  type: "numbered_list_item";
  numbered_list_item: { rich_text: RichText[] };
};

type Paragraph = {
  type: "paragraph";
  paragraph: { rich_text: RichText[] };
};

// Union type - TypeScript narrows automatically with type === "code"
export type NotionBlock =
  | CodeBlock
  | Heading1
  | Heading2
  | Heading3
  | BulletedListItem
  | NumberedListItem
  | Paragraph;

function mapLanguageAlias(language: string): string {
  const langMap: Record<string, string> = {
    "": "plain text",
    "js": "javascript",
    "ts": "typescript",
    "py": "python",
    "sh": "shell",
    "bash": "shell",
    "zsh": "shell",
  };
  return langMap[language] || language || "plain text";
}

function createCodeBlock(lines: string[], startIndex: number): [CodeBlock, number] {
  const language = mapLanguageAlias(lines[startIndex].trim().slice(3).trim());

  const codeLines: string[] = [];
  let i = startIndex + 1;

  while (i < lines.length) {
    if (lines[i].trim().startsWith("```")) break;
    codeLines.push(lines[i]);
    i++;
  }

  const block: CodeBlock = {
    type: "code",
    code: {
      rich_text: [{ type: "text", text: { content: codeLines.join("\n") } }],
      language,
    },
  };

  return [block, i + 1];
}

function createHeadingBlock(line: string): Heading1 | Heading2 | Heading3 | null {
  if (line.startsWith("### ")) {
    return {
      type: "heading_3",
      heading_3: { rich_text: [{ type: "text", text: { content: line.slice(4) } }] },
    };
  } else if (line.startsWith("## ")) {
    return {
      type: "heading_2",
      heading_2: { rich_text: [{ type: "text", text: { content: line.slice(3) } }] },
    };
  } else if (line.startsWith("# ")) {
    return {
      type: "heading_1",
      heading_1: { rich_text: [{ type: "text", text: { content: line.slice(2) } }] },
    };
  }
  return null;
}

function createListItemBlock(line: string): BulletedListItem | NumberedListItem | null {
  if (line.startsWith("- ")) {
    return {
      type: "bulleted_list_item",
      bulleted_list_item: { rich_text: [{ type: "text", text: { content: line.slice(2) } }] },
    };
  } else if (line.length > 2 && /^\d/.test(line[0]) && line.slice(1, 3) === ". ") {
    return {
      type: "numbered_list_item",
      numbered_list_item: { rich_text: [{ type: "text", text: { content: line.slice(3) } }] },
    };
  }
  return null;
}

function createParagraphBlock(line: string): Paragraph {
  if (!line.trim()) {
    return { type: "paragraph", paragraph: { rich_text: [] } };
  }
  return {
    type: "paragraph",
    paragraph: { rich_text: [{ type: "text", text: { content: line } }] },
  };
}

export function markdownToBlocks(content: string): NotionBlock[] {
  const blocks: NotionBlock[] = [];
  const lines = content.split("\n");
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];

    // Code blocks
    if (line.trim().startsWith("```")) {
      const [block, newIndex] = createCodeBlock(lines, i);
      blocks.push(block);
      i = newIndex;
      continue;
    }

    // Headings
    const headingBlock = createHeadingBlock(line);
    if (headingBlock) {
      blocks.push(headingBlock);
      i++;
      continue;
    }

    // List items
    const listBlock = createListItemBlock(line);
    if (listBlock) {
      blocks.push(listBlock);
      i++;
      continue;
    }

    // Paragraphs
    blocks.push(createParagraphBlock(line));
    i++;
  }

  return blocks;
}

export function extractPageId(url: string): string {
  if (!url) return "";

  const parts = url.replace(/\/$/, "").split("-");
  if (parts.length === 0) return "";

  const candidate = parts[parts.length - 1].split("/").pop() || "";
  return candidate.split("?")[0];
}
