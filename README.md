:caution: This is a work in progress. Even a repository name is not fixed yet.

# pandoc-coderunner

Pandoc's lua filter that evaluates codes and reflects the results in the output.

`````markdown
`1 + 1` is `1 + 1`{.lua eval=true}

```{.lua eval=true}
return "- foo\
- bar"
```
`````

becomes

```markdown
`1 + 1` is `2`

- foo
- bar
```


