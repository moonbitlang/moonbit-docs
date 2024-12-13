import rehypeStringify from "rehype-stringify";
import remarkParse from "remark-parse";
import remarkRehype from "remark-rehype";
import { unified } from "unified";

const processor = unified()
  .use(remarkParse)
  .use(remarkRehype)
  .use(rehypeStringify);

function mdToHtml(md: string): string {
  const file = processor.processSync(md);
  return String(file);
}

export { mdToHtml };
