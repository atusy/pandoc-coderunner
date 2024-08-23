:caution: This is a work in progress. Even a repository name is not fixed yet.

# pandoc-coderunner

Pandoc's lua filter that evaluates codes and reflects the results in the output.

## Quick start

````` bash
echo '
`1 + 1` is `return 1 + 1`{.lua eval=true}

```{.lua eval=true}
return "- foo\
- bar"
```
' | pandoc -L lua/coderunner.lua -t markdown
`````

becomes

```markdown
`1 + 1` is `2`

- foo
- bar
```

The example above uses markdown as the input format, but any format can be used if it supports the equivalent document structure can be used.

## Usage

### Evaluating Lua language

#### Basics

Lua CodeBlocks/Codes can be evaluated by adding `eval=true` to the attributes.

The `return` value is reflected in the output, and can be a string or a Pandoc's AST.
For example, both of the following generates a bullet list.

- Returning **string** is easy but requires the same format as the output format.

    ```` markdown
    ```{.lua eval=true}
    return "- foo\
    - bar"
    ```
    ````

- Returning **Pandoc's AST** can be complex, but does not depend on the output format.

    ```` markdown
    ```{.lua eval=true}
    return pandoc.BulletList({
        pandoc.Plain({ pandoc.Str("foo") }),
        pandoc.Plain({ pandoc.Str("bar") })
    })
    ```
    ````

As the latter example indicates, CodeBlocks/Codes may use any variables and functions available in Lua filter.

#### Using context

Lua script has an access to the evaluation context as the `ctx` variable.
For the definition, see `CoderunnerContext` class in [lua/_type.lua](lua/_type.lua).

##### Tweaking options

The context includes evaluation options, and can be modified at run time.

For example, let's define `expr` engine to avoid some annoyance in Lua `Code` by setting the `expr` engine.

- No `return` statement
- No `.eval=true` attribute

For example, `` `1 + 1`{.expr} `` becomes `2`.

```lua
ctx.opts.engines.expr = function(code, env)
    code.text = "return " .. code.text
    return ctx.opts.engines.lua(code, env)
end

ctx.opts.eval.expr = true
```

##### Accessing metadata

````markdown
---
abstract: |
    This is an abstract.
---

# Title

## Abstract

```{.lua eval=true}
return ctx.meta.abstract
```
````

#### Defining variables/functions

Global variables and functions can be used in other CodeBlocks and Codes.

```` markdown
##### Defining a function

```{.lua eval=true}
function f()
    return "foo"
end
```

##### Referencing the function

```{.lua eval=true}
f()
```
````

### Evaluating other languages

The filter minimally supports languages other than Lua.

Lmitations:

- No context
- No AST return
    - Return must be stdout, and is treated as a string
- No variable/function sharing

The below is the example of evaluating a Python CodeBlock.

````` markdown
```{.python eval=true}
for i in range(10):
    print(i)
```
`````

On running the above, the code is first written to a temporary file, and then executed by the specified language (or command).
If the language needs special treatment, tweak the `ctx.opts.engines` table.

``` lua
-- Use Python in the virtual environment with the verbose option
-- Note that %s is replaced with the path to the temporary file
ctx.opts.engines.python = "/.venv/bin/python -v %s"
```
