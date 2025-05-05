--[[
# MIT License
#
# Copyright (c) 2025 Mickaël Canouil
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

--- Gets a colour value from brand theme or formats it for later use
--- @param theme string The brand theme to use (light/dark)
--- @param colour string The colour value or brand colour reference
--- @return string The processed colour value
local function get_brand_colour(theme, colour)
  local brand = require('modules/brand/brand')
  if colour and colour:match('^brand%-color.') then
    colour = brand.get_color(theme, colour:gsub('^brand%-color%.', ''))
  else
    if FORMAT:match 'typst' and colour  ~= nil then
      colour = 'rgb("' .. colour .. '")'
    end
  end
  return colour
end

--- Applies text and background colour styling for HTML-based outputs
--- @param span table The span element to modify
--- @param settings table The highlight settings containing colour and background colour
--- @return table The modified span with HTML styling
local function highlight_html(span, settings)
  local result = {}
  local theme_keys = {}

  for key, _ in pairs(settings) do
    table.insert(theme_keys, key)
  end

  for _, theme in ipairs(theme_keys) do
    local theme_span = pandoc.Span(span.content)
    local colour = settings[theme].colour
    local bg_colour = settings[theme].bg_colour

    for k, v in pairs(span.attributes) do
      theme_span.attributes[k] = v
    end

    if theme_span.attributes['style'] == nil then
      theme_span.attributes['style'] = ''
    elseif theme_span.attributes['style']:sub(-1) ~= ';' then
      theme_span.attributes['style'] = theme_span.attributes['style'] .. ';'
    end

    theme_span.classes = theme_span.classes or {}
    table.insert(theme_span.classes, theme .. '-content')

    if colour ~= nil then
      theme_span.attributes['colour'] = nil
      theme_span.attributes['color'] = nil
      theme_span.attributes['style'] = theme_span.attributes['style'] .. 'color: ' .. colour .. ';'
    end

    if bg_colour ~= nil then
      theme_span.attributes['bg-colour'] = nil
      theme_span.attributes['bg-color'] = nil
      theme_span.attributes['style'] = theme_span.attributes['style'] ..
        'border-radius: 0.2rem; padding: 0 0.2rem 0 0.2rem;' .. 'background-color: ' .. bg_colour .. ';'
    end

    table.insert(result, theme_span)
  end

  if #result == 1 then
    return result[1]
  else
    return result
  end
end

--- Applies text and background colour styling for LaTeX-based outputs
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param par boolean Whether to wrap in a paragraph box
--- @return table The span content with LaTeX markup
local function highlight_latex(span, colour, bg_colour, par)
  local is_lualatex = quarto.doc.pdf_engine() == 'lualatex'
  
  if is_lualatex and bg_colour ~= nil then
    quarto.doc.use_latex_package('luacolor, lua-ul')
  end
  
  if colour == nil then
    colour_open = ''
    colour_close = ''
  else
    colour_open = '\\textcolor[HTML]{' .. colour:gsub('^#', '') .. '}{'
    colour_close = '}'
  end
  
  if bg_colour == nil then
    bg_colour_open = ''
    bg_colour_close = ''
  else
    if is_lualatex then
      bg_colour_open = '\\highLight[{[HTML]{' .. bg_colour:gsub('^#', '') .. '}}]{'
      bg_colour_close = '}'
    else
      bg_colour_open = '\\colorbox[HTML]{' .. bg_colour:gsub('^#', '') .. '}{'
      bg_colour_close = '}'
    end
  end

  if par and not is_lualatex then
    bg_colour_open = bg_colour_open .. '\\parbox{\\linewidth}{'
    bg_colour_close = '}' .. bg_colour_close
  end

  table.insert(
    span.content, 1,
    pandoc.RawInline('latex', colour_open .. bg_colour_open)
  )
  table.insert(span.content, pandoc.RawInline('latex', bg_colour_close .. colour_close))

  return span.content
end

--- Applies text and background colour styling for Word documents
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @return table The span content with OpenXML markup for Word
local function highlight_openxml_docx(span, colour, bg_colour)
  local spec = '<w:r><w:rPr>'
  if bg_colour ~= nil then
    spec = spec .. '<w:shd w:val="clear" w:fill="' .. bg_colour:gsub('^#', '') .. '"/>'
  end
  if colour ~= nil then
    spec = spec .. '<w:color w:val="' .. colour:gsub('^#', '') .. '"/>'
  end
  spec = spec .. '</w:rPr><w:t>'

  table.insert(span.content, 1, pandoc.RawInline('openxml', spec))
  table.insert(span.content, pandoc.RawInline('openxml', '</w:t></w:r>'))

  return span.content
end

--- Applies text and background colour styling for PowerPoint presentations
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @return table Raw inline containing OpenXML markup for PowerPoint
local function highlight_openxml_pptx(span, colour, bg_colour)
  local spec = '<a:r><a:rPr dirty="0">'
  if colour ~= nil then
    spec = spec .. '<a:solidFill><a:srgbClr val="' .. colour:gsub('^#', '') .. '" /></a:solidFill>'
  end
  if bg_colour ~= nil then
    spec = spec .. '<a:highlight><a:srgbClr val="' .. bg_colour:gsub('^#', '') .. '" /></a:highlight>'
  end
  spec = spec .. '</a:rPr><a:t>'

  -- table.insert(span.content, 1, pandoc.RawInline('openxml', spec))
  -- table.insert(span.content, pandoc.RawInline('openxml', '</a:t></a:r>'))

  local span_content_string = ''
  for i, inline in ipairs(span.content) do
    span_content_string = span_content_string .. pandoc.utils.stringify(inline)
  end

  return pandoc.RawInline('openxml', spec .. span_content_string .. '</a:t></a:r>')
end

--- Applies text and background colour styling for Typst output
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @return table The span content with Typst markup
local function highlight_typst(span, colour, bg_colour)
  if colour == nil then
    colour_open = ''
    colour_close = ''
  else
    colour_open = '#text(' .. colour .. ')['
    colour_close = ']'
  end

  if bg_colour == nil then
    bg_colour_open = ''
    bg_colour_close = ''
  else
    bg_colour_open = '#highlight(fill: ' .. bg_colour .. ')['
    bg_colour_close = ']'
  end

  table.insert(
    span.content, 1,
    pandoc.RawInline('typst', colour_open .. bg_colour_open)
  )
  table.insert(
    span.content,
    pandoc.RawInline('typst', bg_colour_close .. colour_close)
  )

  return span.content
end

--- Main filter function that processes span elements and applies highlighting
--- based on the output format and specified attributes
--- @param span table The span element from the document
--- @return table The modified span or span content with appropriate styling
local function highlight(span)
  local colour = span.attributes['fg']
  if colour == nil then
    colour = span.attributes['colour']
  end
  if colour == nil then
    colour = span.attributes['color']
  end

  local bg_colour = span.attributes['bg']
  if bg_colour == nil then
    bg_colour = span.attributes['bg-colour']
  end
  if bg_colour == nil then
    bg_colour = span.attributes['bg-color']
  end

  local highlight_settings = {}
  if quarto.brand.has_mode('light') or quarto.brand.has_mode('dark') then
    local modes = {'light', 'dark'}
    
    for _, mode in ipairs(modes) do
      if quarto.brand.has_mode(mode) then
        highlight_settings[mode] = {
          colour = get_brand_colour(mode, colour),
          bg_colour = get_brand_colour(mode, bg_colour)
        }
      end
    end
  else
    highlight_settings.light = {
      colour = get_brand_colour('light', colour),
      bg_colour = get_brand_colour('light', bg_colour)
    }
  end

  if highlight_settings.light == nil and highlight_settings.dark == nil then
    return span
  end

  if highlight_settings.light == nil then
    highlight_settings.light = highlight_settings.dark
  end

  colour = highlight_settings.light.colour
  bg_colour = highlight_settings.light.bg_colour

  if colour == nil and bg_colour == nil then return span end

  if span.attributes['par'] == nil then
    par = false
  else
    par = true
    span.attributes['par'] = nil
  end

  if quarto.doc.is_format('html') or quarto.doc.is_format('revealjs') then
    return highlight_html(span, highlight_settings)
  elseif quarto.doc.is_format('latex') or quarto.doc.is_format('beamer') then
    return highlight_latex(span, colour, bg_colour, par)
  elseif quarto.doc.is_format('docx') then
    return highlight_openxml_docx(span, colour, bg_colour)
  elseif quarto.doc.is_format('pptx') then
    return highlight_openxml_pptx(span, colour, bg_colour)
  elseif quarto.doc.is_format('typst') then
    return highlight_typst(span, colour, bg_colour)
  else
    return span
  end
end

return {
  { Span = highlight },
}
