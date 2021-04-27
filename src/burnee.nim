import asynchttpserver, asyncdispatch
import karax / [karaxdsl, vdom]
import parseutils
import os

const
  geminiExts = [".gemini", ".gmi"]
  gemtext = {'#', '`', '*', '>', '='}
  whitespace = {' ', '\t'}
  rootDir = "pub/localhost.localdomain/"
  style = "style.css"

proc parseToken(line: string): string =
  discard line.parseWhile(result, gemtext)

proc gmi2html(path: string): string =
  var line: string

  let file = open(rootDir / path)
  
  let vnode = buildHtml(body):
    while file.readLine(line):
      if line.len > 0:
        let token = line.parseToken()
        let content = line[token.len..^1]
      
        case token
        of "#": h1(text content)
        of "##": h2(text content)
        of "###": h3(text content)
        of ">": blockquote(text content)
        of "=>":
          var
            start: int
            url: string
        
          start = content.skipWhile(whitespace)
          discard content.parseUntil(url, whitespace, start)        
          start = url.len + content.skipWhile(whitespace, url.len + 1)
        
          a(href = url):
            p:
              text if start < content.high:
                     content[start..^1]
                   else: url
        of "*":
          ul:
            while line.parseToken() == "*":
              li: text line[1..^1]
              if not file.readLine(line): break
        of "```":
          pre:
            while file.readLine(line) and line != "```":
              text line & '\n'
        else: p(text line)

  file.close()

  when style.len > 0:
    let head = buildHtml(head):
      link(rel = "stylesheet", `type`="text/css", href=style)
  
    return $head & $vnode
  else:
    return $vnode

proc cb(req: Request) {.async.} =
  try:
    if splitFile(req.url.path).ext in geminiExts:
      await req.respond(Http200, gmi2html(req.url.path), newHttpHeaders())
    else:
      await req.respond(Http403, "Not a gemini file")
  except IOError:
    await req.respond(Http404, "File not found")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9090), cb)
