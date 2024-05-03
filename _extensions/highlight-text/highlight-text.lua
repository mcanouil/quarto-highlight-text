--[[
# MIT License
#
# Copyright (c) 2024 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

local function highlight_html(span, colour)
  span.attributes['colour'] = nil
  span.attributes['color'] = nil
  span.attributes['style'] = 'color: ' .. colour .. ';'
  return span
end

local function highlight_latex(span, colour)
  table.insert(
    span.content, 1,
    pandoc.RawInline('latex', '\\textcolor[HTML]{' .. colour:gsub("^#", "") .. '}{')
  )
  table.insert(
    span.content,
    pandoc.RawInline('latex', '}')
  )
  return span.content
end

local function highlight_openxml(span, colour)
  table.insert(
    span.content, 1,
    pandoc.RawInline('openxml', '<w:r><w:rPr><w:color w:val="' .. colour:gsub("^#", "") .. '"/></w:rPr><w:t>')
  )
  table.insert(
    span.content,
    pandoc.RawInline('openxml', '</w:t></w:r>')
  )
  return span.content
end

local function highlight_typst(span, colour)
  table.insert(
    span.content, 1,
    pandoc.RawInline('typst', '#text(rgb("' .. colour .. '"))[')
  )
  table.insert(
    span.content,
    pandoc.RawInline('typst', ']')
  )
  return span.content
end

function Span(span)
  colour = span.attributes['colour']
  if colour == nil then
    colour = span.attributes['color']
  end

  if colour == nil then return span end

  if FORMAT:match 'html' or FORMAT:match 'revealjs' then
    return highlight_html(span, colour)
  elseif FORMAT:match 'latex' or FORMAT:match 'beamer' then
    return highlight_latex(span, colour)
  elseif FORMAT:match 'docx' or FORMAT:match 'pptx' then
    return highlight_openxml(span, colour)
  elseif FORMAT:match 'typst' then
    return highlight_typst(span, colour)
  else
    return span
  end
end
