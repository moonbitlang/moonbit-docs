# MoonBit's Build System Configuration

<!-- Generated with [json-schema-static-docs](https://tomcollins.github.io/json-schema-static-docs/) -->
<!-- TODO: use docusaurus-json-schema-plugin -->

## JSON schema for Moonbit moon.mod.json files

<p>A module of Moonbit lang</p>

<table>
<tbody>

<tr><th>$schema</th><td>http://json-schema.org/draft-07/schema#</td></tr>
</tbody>
</table>

### Properties

<table class="jssd-properties-table"><thead><tr><th colspan="2">Name</th><th>Type</th></tr></thead><tbody><tr><td colspan="2"><a href="#name">name</a></td><td>String</td></tr><tr><td colspan="2"><a href="#version">version</a></td><td>String</td></tr><tr><td colspan="2"><a href="#deps">deps</a></td><td>Object</td></tr><tr><td colspan="2"><a href="#readme">readme</a></td><td>String</td></tr><tr><td colspan="2"><a href="#repository">repository</a></td><td>String</td></tr><tr><td colspan="2"><a href="#license">license</a></td><td>String</td></tr></tbody></table>

### name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Name of the module</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">Yes</td>
    </tr>
    
  </tbody>
</table>




### version


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Version of the module, following Semantic Versioning 2.0.0</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>

### deps

<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Third-party dependencies of the module</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>

### readme

<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Path to module&#x27;s README file</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>

### repository

<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">URL to module&#x27;s repository</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    <tr>
      <th>Format</th>
      <td colspan="2">uri</td>
    </tr>
  </tbody>
</table>

### license


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">License of the module, an SPDX identifier</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>

### Schema
```
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "JSON schema for Moonbit moon.mod.json files",
    "description": "A module of Moonbit lang",
    "type": "object",
    "properties": {
        "name": {
            "description": "Name of the module",
            "type": "string"
        },
        "version": {
            "description": "Version of the module, following Semantic Versioning 2.0.0",
            "type": "string"
        },
        "deps": {
            "description": "Third-party dependencies of the module",
            "type": "object",
            "additionalProperties": {
                "type": "string"
            }
        },
        "readme": {
            "description": "Path to module's README file",
            "type": "string"
        },
        "repository": {
            "description": "URL to module's repository",
            "type": "string",
            "format": "uri"
        },
        "license": {
            "description": "License of the module, an SPDX identifier",
            "type": "string"
        }
    },
    "required": [
        "name"
    ]
}
```

## JSON schema for Moonbit moon.pkg.json files

<p>A package in Moonbit lang</p>

<table>
<tbody>

<tr><th>$schema</th><td>http://json-schema.org/draft-07/schema#</td></tr>
</tbody>
</table>

### Properties

<table class="jssd-properties-table"><thead><tr><th colspan="2">Name</th><th>Type</th></tr></thead><tbody><tr><td colspan="2"><a href="#name">name</a></td><td>String</td></tr><tr><td colspan="2"><a href="#is-main">is-main</a></td><td>Boolean</td></tr><tr><th rowspan="2">import</th><td rowspan="2">One of:</td><td>Object</td></tr><tr><td>Array</td></tr><tr><th rowspan="2">link</th><td rowspan="2">One of:</td><td>Boolean</td></tr><tr><td>Object</td></tr></tbody></table>

### name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Name of the package (Deprecated)</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>




### is-main


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Specify whether this package is a main package or not</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Boolean</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>




### import


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Imported packages of the package</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Object</td></tr><tr><td>Array</td></tr></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>



#### import.0


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Title</th>
      <td colspan="2">Object form</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>




#### import.1


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Title</th>
      <td colspan="2">Array form</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>

### link


<table class="jssd-property-table">
  <tbody>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Boolean</td></tr><tr><td>Object</td></tr></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    
  </tbody>
</table>



#### link.0


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Title</th>
      <td colspan="2">Build this package</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Boolean</td></tr>
    
  </tbody>
</table>




#### link.1


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Title</th>
      <td colspan="2">Build configuration</td>
    </tr>
    <tr>
      <th>Description</th>
      <td colspan="2">Configure the build for each backend</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



#### link.1.wasm


<table class="jssd-property-table">
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



#### link.1.wasm.exports


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Exported functions of the package</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>




#### link.1.wasm.export-memory-name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Name of the exported memory, or no memory will be exported</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




#### link.1.wasm.flags


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Flags for the compilation of the package</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>





#### link.1.wasm-gc


<table class="jssd-property-table">
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



#### link.1.wasm-gc.exports


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Exported functions of the package</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>




#### link.1.wasm-gc.export-memory-name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Name of the exported memory, or no memory will be exported</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




#### link.1.wasm-gc.flags


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Flags for the compilation of the package</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>





#### link.1.js


<table class="jssd-property-table">
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



#### link.1.js.exports


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Exported functions of the package</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>




#### link.1.js.format


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">Format of the output JavaScript file</td>
    </tr>
    
    <tr>
      <th>Enum</th>
      <td colspan="2"><ul><li>esm</li><li>cjs</li><li>iife</li></ul></td>
    </tr>
  </tbody>
</table>

### Schema
```
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "JSON schema for Moonbit moon.pkg.json files",
    "description": "A package in Moonbit lang",
    "type": "object",
    "properties": {
        "name": {
            "description": "Name of the package (Deprecated)",
            "type": "string"
        },
        "is-main": {
            "description": "Specify whether this package is a main package or not",
            "type": "boolean",
            "default": false
        },
        "import": {
            "description": "Imported packages of the package",
            "oneOf": [
                {
                    "title": "Object form",
                    "type": "object",
                    "additionalProperties": {
                        "description": "Path and alias of an imported package",
                        "type": [
                            "string",
                            "null"
                        ]
                    }
                },
                {
                    "title": "Array form",
                    "type": "array",
                    "items": {
                        "oneOf": [
                            {
                                "title": "Package without alias",
                                "description": "Path of an imported package",
                                "type": "string"
                            },
                            {
                                "title": "Package with alias",
                                "description": "Path and alias of an imported package",
                                "type": "object",
                                "properties": {
                                    "path": {
                                        "description": "Path of an imported package",
                                        "type": "string"
                                    },
                                    "alias": {
                                        "description": "Alias of an imported package",
                                        "type": "string"
                                    }
                                },
                                "additionalProperties": false,
                                "required": [
                                    "path",
                                    "alias"
                                ]
                            }
                        ]
                    }
                }
            ]
        },
        "link": {
            "oneOf": [
                {
                    "title": "Build this package",
                    "type": "boolean"
                },
                {
                    "title": "Build configuration",
                    "description": "Configure the build for each backend",
                    "type": "object",
                    "properties": {
                        "wasm": {
                            "type": "object",
                            "properties": {
                                "exports": {
                                    "description": "Exported functions of the package",
                                    "type": "array",
                                    "items": {
                                        "description": "Name of an exported function, or followed by a colon and the alias name",
                                        "type": "string"
                                    }
                                },
                                "export-memory-name": {
                                    "description": "Name of the exported memory, or no memory will be exported",
                                    "type": "string"
                                },
                                "flags": {
                                    "description": "Flags for the compilation of the package",
                                    "type": "array",
                                    "items": {
                                        "type": "string",
                                        "enum": [
                                            "-no-block-params"
                                        ]
                                    }
                                }
                            },
                            "additionalProperties": false
                        },
                        "wasm-gc": {
                            "type": "object",
                            "properties": {
                                "exports": {
                                    "description": "Exported functions of the package",
                                    "type": "array",
                                    "items": {
                                        "description": "Name of an exported function, or followed by a colon and the alias name",
                                        "type": "string"
                                    }
                                },
                                "export-memory-name": {
                                    "description": "Name of the exported memory, or no memory will be exported",
                                    "type": "string"
                                },
                                "flags": {
                                    "description": "Flags for the compilation of the package",
                                    "type": "array",
                                    "items": {
                                        "type": "string",
                                        "enum": [
                                            "-no-block-params"
                                        ]
                                    }
                                }
                            },
                            "additionalProperties": false
                        },
                        "js": {
                            "type": "object",
                            "properties": {
                                "exports": {
                                    "description": "Exported functions of the package",
                                    "type": "array",
                                    "items": {
                                        "description": "Name of an exported function, or followed by a colon and the alias name",
                                        "type": "string"
                                    }
                                },
                                "format": {
                                    "description": "Format of the output JavaScript file",
                                    "enum": [
                                        "esm",
                                        "cjs",
                                        "iife"
                                    ]
                                }
                            },
                            "additionalProperties": false
                        }
                    },
                    "additionalProperties": false
                }
            ]
        }
    },
    "required": []
}
```


