# JSON schema for MoonBit moon.mod.json files

*A module of MoonBit lang*

## Properties

- **`alert-list`** *(['string', 'null'])*: Alert list setting of the module.
- **`deps`** *(['object', 'null'])*: third-party dependencies of the module. Can contain additional properties.
  - **Additional properties** *(string)*
- **`description`** *(['string', 'null'])*: description of this module.
- **`keywords`** *(['array', 'null'])*: keywords of this module.
  - **Items** *(string)*
- **`license`** *(['string', 'null'])*: license of this module.
- **`name`** *(string, required)*: name of the module.
- **`readme`** *(['string', 'null'])*: path to module's README file.
- **`repository`** *(['string', 'null'])*: url to module's repository.
- **`source`** *(['string', 'null'])*: source code directory of this module.
- **`version`** *(['string', 'null'])*: version of the module.
- **`warn-list`** *(['string', 'null'])*: Warn list setting of the module.
# JSON schema for MoonBit moon.pkg.json files

*A package of MoonBit language*

## Properties

- **`alert-list`** *(['string', 'null'])*: Alert list setting of the package.
- **`import`**: Imported packages of the package.
  - **Any of**
    - : Refer to *[#/definitions/PkgJSONImport](#definitions/PkgJSONImport)*.
    - *null*
- **`is-main`** *(['boolean', 'null'])*: Specify whether this package is a main package or not.
- **`link`**
  - **Any of**
    - : Refer to *[#/definitions/BoolOrLink](#definitions/BoolOrLink)*.
    - *null*
- **`name`** *(['string', 'null'])*
- **`test-import`**: Black box test imported packages of the package.
  - **Any of**
    - : Refer to *[#/definitions/PkgJSONImport](#definitions/PkgJSONImport)*.
    - *null*
- **`warn-list`** *(['string', 'null'])*: Warn list setting of the package.
- **`wbtest-import`**: White box test imported packages of the package.
  - **Any of**
    - : Refer to *[#/definitions/PkgJSONImport](#definitions/PkgJSONImport)*.
    - *null*
## Definitions

- <a id="definitions/BoolOrLink"></a>**`BoolOrLink`**
  - **Any of**
    - *boolean*
    - : Refer to *[#/definitions/Link](#definitions/Link)*.
- <a id="definitions/JsFormat"></a>**`JsFormat`** *(string)*: Must be one of: `["esm", "cjs", "iife"]`.
- <a id="definitions/JsLinkConfig"></a>**`JsLinkConfig`** *(object)*
  - **`exports`** *(['array', 'null'])*
    - **Items** *(string)*
  - **`format`**
    - **Any of**
      - : Refer to *[#/definitions/JsFormat](#definitions/JsFormat)*.
      - *null*
- <a id="definitions/Link"></a>**`Link`** *(object)*
  - **`js`**
    - **Any of**
      - : Refer to *[#/definitions/JsLinkConfig](#definitions/JsLinkConfig)*.
      - *null*
  - **`wasm`**
    - **Any of**
      - : Refer to *[#/definitions/WasmLinkConfig](#definitions/WasmLinkConfig)*.
      - *null*
  - **`wasm-gc`**
    - **Any of**
      - : Refer to *[#/definitions/WasmGcLinkConfig](#definitions/WasmGcLinkConfig)*.
      - *null*
- <a id="definitions/PkgJSONImport"></a>**`PkgJSONImport`**
  - **Any of**
    - *object*: Path and alias of an imported package. Can contain additional properties.
      - **Additional properties** *(['string', 'null'])*
    - *array*
      - **Items**: Refer to *[#/definitions/PkgJSONImportItem](#definitions/PkgJSONImportItem)*.
- <a id="definitions/PkgJSONImportItem"></a>**`PkgJSONImportItem`**
  - **Any of**
    - *string*
    - *object*
      - **`alias`** *(string, required)*
      - **`path`** *(string, required)*
- <a id="definitions/WasmGcLinkConfig"></a>**`WasmGcLinkConfig`** *(object)*
  - **`export-memory-name`** *(['string', 'null'])*
  - **`exports`** *(['array', 'null'])*
    - **Items** *(string)*
  - **`flags`** *(['array', 'null'])*
    - **Items** *(string)*
  - **`import-memory`**
    - **Any of**
      - : Refer to *[#/definitions/import-memory](#definitions/import-memory)*.
      - *null*
- <a id="definitions/WasmLinkConfig"></a>**`WasmLinkConfig`** *(object)*
  - **`export-memory-name`** *(['string', 'null'])*
  - **`exports`** *(['array', 'null'])*
    - **Items** *(string)*
  - **`flags`** *(['array', 'null'])*
    - **Items** *(string)*
  - **`heap-start-address`** *(['integer', 'null'], format: uint32)*: Minimum: `0.0`.
  - **`import-memory`**
    - **Any of**
      - : Refer to *[#/definitions/import-memory](#definitions/import-memory)*.
      - *null*
- <a id="definitions/import-memory"></a>**`import-memory`** *(object)*
  - **`module`** *(string, required)*
  - **`name`** *(string, required)*
