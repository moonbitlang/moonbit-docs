import rehypeStringify from "rehype-stringify";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import { unified } from "unified";
import { visit } from "unist-util-visit";

const processor = unified()
  .use(remarkParse)
  .use(remarkRehype)
  .use(rehypeStringify);

function mdToHtml(md: string): string {
  const file = processor.processSync(md);
  return String(file);
}

function getFirstH1Title(md: string): string | null {
  const tree = unified().use(remarkParse).parse(md);
  let title: string | null = null;

  visit(tree, "heading", (node) => {
    if (node.depth === 1 && !title) {
      title = node.children.map((child: any) => child.value).join("");
    }
  });

  return title;
}

export { getFirstH1Title, mdToHtml };
