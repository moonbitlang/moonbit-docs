# Writing documents

## 1. Create a new documents

To add a new document to the MoonBit documentation site, follow these steps:

For English Documents:

1. Create a new Markdown file with your document content.
2. Move it to the appropriate location within the English documentation folder:

```
moonbit-docs/docs/your/english/path/yourenglishdocs.md
```

For Chinese Documents:

1. Create a new Markdown file with your document content in Chinese.
2. Move it to the corresponding location within the Chinese documentation folder, mirroring the English folder structure:

```
moonbit-docs/i18n/zh/docusaurus-plugin-content-docs/current/your/english/path/yourenglishdocs.md
```

**Note**: If you only create an English document, it will also be displayed on the Chinese site by default.

## 2. Add the Document Link to the Sidebar

After creating your document, you need to add a link to it in the sidebar configuration file to make it appear in the documentation sidebar.

1. Open the sidebar.ts file located at:

```shell
moonbit-docs/sidebar.ts
```

2. Add a link to your new document by following the sidebar [configuration guide](https://docusaurus.io/docs/sidebar/items).

## 3. Preview Your Document

**For the English Site:**

To see the English version of your document:

```shell
cd moonbit-docs
pnpm start
```

**For the Chinese Site:**

To see the Chinese version of your document:

```shell
cd moonbit-docs
pnpm zhstart
```
