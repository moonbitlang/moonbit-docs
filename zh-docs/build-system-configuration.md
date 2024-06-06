# MoonBit 构建系统配置

<!-- Generated with [json-schema-static-docs](https://tomcollins.github.io/json-schema-static-docs/) -->
<!-- TODO: use docusaurus-json-schema-plugin -->

## moon.mod.json的JSON Schema

<p>月兔的一个模块</p>

<table>
<tbody>

<tr><th>$schema</th><td>http://json-schema.org/draft-07/schema#</td></tr>
</tbody>
</table>

### 属性

<table class="jssd-properties-table"><thead><tr><th colspan="2">名称</th><th>类型</th></tr></thead><tbody><tr><td colspan="2"><a href="#name">name</a></td><td>String</td></tr><tr><td colspan="2"><a href="#version">version</a></td><td>String</td></tr><tr><td colspan="2"><a href="#deps">deps</a></td><td>Object</td></tr><tr><td colspan="2"><a href="#readme">readme</a></td><td>String</td></tr><tr><td colspan="2"><a href="#repository">repository</a></td><td>String</td></tr><tr><td colspan="2"><a href="#license">license</a></td><td>String</td></tr></tbody></table>

### name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">模块名称</td>
    </tr>
    <tr><th>类型</th><td colspan="2">String</td></tr>
    <tr>
      <th>必填</th>
      <td colspan="2">是</td>
    </tr>
    
  </tbody>
</table>

### version


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">模块版本号，遵循 Semantic Versioning 2.0.0</td>
    </tr>
    <tr><th>类型</th><td colspan="2">String</td></tr>
    <tr>
      <th>必填</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>

### deps

<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">模块的第三方依赖</td>
    </tr>
    <tr><th>类型</th><td colspan="2">Object</td></tr>
    <tr>
      <th>必填</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>

### readme

<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">模块“读我“文件路径</td>
    </tr>
    <tr><th>类型</th><td colspan="2">字符串</td></tr>
    <tr>
      <th>必填</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>

### repository

<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">模块仓库链接</td>
    </tr>
    <tr><th>类型</th><td colspan="2">String</td></tr>
    <tr>
      <th>必填</th>
      <td colspan="2">否</td>
    </tr>
    <tr>
      <th>格式</th>
      <td colspan="2">uri</td>
    </tr>
  </tbody>
</table>

### license


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">模块的许可证，一个SPDX标识符</td>
    </tr>
    <tr><th>类型</th><td colspan="2">String</td></tr>
    <tr>
      <th>必填</th>
      <td colspan="2">否</td>
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

## moon.pkg.json的JSON Schema

<p>月兔的一个包</p>

<table>
<tbody>

<tr><th>$schema</th><td>http://json-schema.org/draft-07/schema#</td></tr>
</tbody>
</table>
### 属性

<table class="jssd-properties-table"><thead><tr><th colspan="2">名称</th><th>类型</th></tr></thead><tbody><tr><td colspan="2"><a href="#name">name</a></td><td>字符串</td></tr><tr><td colspan="2"><a href="#is-main">is-main</a></td><td>布尔值</td></tr><tr><th rowspan="2">import</th><td rowspan="2">其中之一：</td><td>对象</td></tr><tr><td>数组</td></tr><tr><th rowspan="2">link</th><td rowspan="2">其中之一：</td><td>布尔值</td></tr><tr><td>对象</td></tr></tbody></table>

### name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">包的名称（已弃用）</td>
    </tr>
    <tr><th>类型</th><td colspan="2">字符串</td></tr>
    <tr>
      <th>必需</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>




### is-main


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">指定该包是否为主包</td>
    </tr>
    <tr><th>类型</th><td colspan="2">布尔值</td></tr>
    <tr>
      <th>必需</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>




### import


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">导入的包</td>
    </tr>
    <tr><tr><th rowspan="2">类型</th><td rowspan="2">其中之一：</td><td>对象</td></tr><tr><td>数组</td></tr></tr>
    <tr>
      <th>必需</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>



#### import.0


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>标题</th>
      <td colspan="2">对象形式</td>
    </tr>
    <tr><th>类型</th><td colspan="2">对象</td></tr>
    
  </tbody>
</table>




#### import.1


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>标题</th>
      <td colspan="2">数组形式</td>
    </tr>
    <tr><th>类型</th><td colspan="2">数组</td></tr>
    
  </tbody>
</table>

### link


<table class="jssd-property-table">
  <tbody>
    <tr><tr><th rowspan="2">类型</th><td rowspan="2">其中之一：</td><td>布尔值</td></tr><tr><td>对象</td></tr></tr>
    <tr>
      <th>必需</th>
      <td colspan="2">否</td>
    </tr>
    
  </tbody>
</table>



#### link.0


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>标题</th>
      <td colspan="2">构建此包</td>
    </tr>
    <tr><th>类型</th><td colspan="2">布尔值</td></tr>
    
  </tbody>
</table>




#### link.1


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>标题</th>
      <td colspan="2">构建配置</td>
    </tr>
    <tr>
      <th>描述</th>
      <td colspan="2">为每个后端配置构建</td>
    </tr>
    <tr><th>类型</th><td colspan="2">对象</td></tr>
    
  </tbody>
</table>



#### link.1.wasm


<table class="jssd-property-table">
  <tbody>
    <tr><th>类型</th><td colspan="2">对象</td></tr>
    
  </tbody>
</table>



#### link.1.wasm.exports


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">包的导出函数</td>
    </tr>
    <tr><th>类型</th><td colspan="2">数组</td></tr>
    
  </tbody>
</table>




#### link.1.wasm.export-memory-name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">导出的内存的名称，或者不导出内存</td>
    </tr>
    <tr><th>类型</th><td colspan="2">字符串</td></tr>
    
  </tbody>
</table>




#### link.1.wasm.flags


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">包的编译标志</td>
    </tr>
    <tr><th>类型</th><td colspan="2">数组</td></tr>
    
  </tbody>
</table>





#### link.1.wasm-gc


<table class="jssd-property-table">
  <tbody>
    <tr><th>类型</th><td colspan="2">对象</td></tr>
    
  </tbody>
</table>



#### link.1.wasm-gc.exports


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">包的导出函数</td>
    </tr>
    <tr><th>类型</th><td colspan="2">数组</td></tr>
    
  </tbody>
</table>




#### link.1.wasm-gc.export-memory-name


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">导出的内存的名称，或者不导出内存</td>
    </tr>
    <tr><th>类型</th><td colspan="2">字符串</td></tr>
    
  </tbody>
</table>




#### link.1.wasm-gc.flags


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">包的编译标志</td>
    </tr>
    <tr><th>类型</th><td colspan="2">数组</td></tr>
    
  </tbody>
</table>





#### link.1.js


<table class="jssd-property-table">
  <tbody>
    <tr><th>类型</th><td colspan="2">对象</td></tr>
    
  </tbody>
</table>



#### link.1.js.exports


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">包的导出函数</td>
    </tr>
    <tr><th>类型</th><td colspan="2">数组</td></tr>
    
  </tbody>
</table>




#### link.1.js.format


<table class="jssd-property-table">
  <tbody>
    <tr>
      <th>描述</th>
      <td colspan="2">输出 JavaScript 文件的格式</td>
    </tr>
    <tr>
      <th>枚举</th>
      <td colspan="2"><ul><li>esm</li><li>cjs</li><li>iife</li></ul></td>
    </tr>
  </tbody>
</table>

### 模式

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



