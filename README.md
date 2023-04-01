# k8s-doc-checksync.rb

Translation status reporter for Kubernetes document translators

## Usage

```
$ bundle exec ./k8s-doc-checksync.rb <websitefolder> [<branch> [<language>]]  > <htmlfile>
```

- *websitefolder*: your Kubernetes website working folder.
- *branch*: target branch to fetch (usually 'main`).
- *language*: target language (such as `ja`).
- *htmlfile*: html file to export a status.

Example
```
$ bundle exec ./k8s-doc-checksync.rb ~/working/kubernetes/website main ja > status-ja.html
```

## Environment value

- `QUIET=true`: silent mode
- `SKIP_FETCH=true`: skip running git fetch

## Modify

Modify `upstream_branch = 'main'` line if your working git folder uses the other branch name for syncing with upstream's main branch.

## License

MIT License

```
Copyright (c) 2023 Kenshi Muto

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
