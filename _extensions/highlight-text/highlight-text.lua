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

--- Extension name constant
local EXTENSION_NAME = "highlight-text"

--- Load utils module
local utils = require(quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", ""))

--- Flag to track if deprecation warning has been shown
--- @type boolean
local deprecation_warning_shown = false

--- Gets a colour value from brand theme or formats it for later use
--- @param theme string The brand theme to use (light/dark)
--- @param colour string|nil The colour value or brand colour reference
--- @return string|nil The processed colour value
local function get_brand_colour(theme, colour)
  local brand = require('modules/brand/brand')


  if colour then
    local brand_colour_key = colour

    -- Check for deprecated "brand-color." prefix
    brand_colour_key = colour:gsub('^brand%-color%.', '')
    if not deprecation_warning_shown then
      if colour:match("^brand%-color%.") then
        utils.log_warning(
          EXTENSION_NAME,
          'Using "brand-color." prefix is deprecated.' ..
          ' Please use the colour name directly (e.g., "' .. brand_colour_key .. '" instead of "' .. colour .. '").'
        )
        deprecation_warning_shown = true
      end
    end

    local brand_colour = brand.get_color(theme, brand_colour_key)
    if brand_colour ~= nil then
      colour = brand_colour
    else
      if FORMAT:match 'typst' and colour ~= nil then
        colour = 'rgb("' .. colour .. '")'
      end
    end
  end
  return colour
end

--- Applies HTML styling to an element
--- @param element table The element to style
--- @param settings table The highlight settings
--- @param is_block boolean Whether this is a block-level element
--- @param constructor any The Pandoc constructor (pandoc.Span or pandoc.Div)
--- @return table The styled element(s)
local function apply_html_styling(element, settings, is_block, constructor)
  local result = {}
  local theme_keys = {}

  for key, _ in pairs(settings) do
    table.insert(theme_keys, key)
  end

  local padding = is_block and '0.5rem' or '0 0.2rem 0 0.2rem'

  for _, theme in ipairs(theme_keys) do
    local themed_element = constructor(element.content)
    local colour = settings[theme].colour
    local bg_colour = settings[theme].bg_colour
    local border_colour = settings[theme].border_colour
    local border_style = settings[theme].border_style

    for k, v in pairs(element.attributes) do
      themed_element.attributes[k] = v
    end

    if themed_element.attributes['style'] == nil then
      themed_element.attributes['style'] = ''
    elseif themed_element.attributes['style']:sub(-1) ~= ';' then
      themed_element.attributes['style'] = themed_element.attributes['style'] .. ';'
    end

    themed_element.classes = themed_element.classes or {}
    table.insert(themed_element.classes, theme .. '-content')

    if colour ~= nil then
      themed_element.attributes['colour'] = nil
      themed_element.attributes['color'] = nil
      themed_element.attributes['style'] = themed_element.attributes['style'] .. 'color: ' .. colour .. ';'
    end

    if bg_colour ~= nil then
      themed_element.attributes['bg-colour'] = nil
      themed_element.attributes['bg-color'] = nil
      themed_element.attributes['style'] = themed_element.attributes['style'] ..
          'border-radius: 0.2rem; padding: ' .. padding .. ';' .. 'background-color: ' .. bg_colour .. ';'
    end

    if border_colour ~= nil then
      themed_element.attributes['bc'] = nil
      themed_element.attributes['border-colour'] = nil
      themed_element.attributes['border-color'] = nil
      themed_element.attributes['bs'] = nil
      themed_element.attributes['border-style'] = nil
      local style = border_style or 'solid'
      themed_element.attributes['style'] = themed_element.attributes['style'] ..
          'border: 1px ' .. style .. ' ' .. border_colour .. ';'
    end

    table.insert(result, themed_element)
  end

  if #result == 1 then
    return result[1]
  else
    return result
  end
end

--- Applies text and background colour styling for HTML-based outputs
--- @param span table The span element to modify
--- @param settings table The highlight settings containing colour and background colour
--- @return table The modified span with HTML styling
local function highlight_html(span, settings)
  return apply_html_styling(span, settings, false, pandoc.Span)
end

--- Applies text and background colour styling for HTML-based outputs (block level)
--- @param div table The div element to modify
--- @param settings table The highlight settings containing colour and background colour
--- @return table The modified div with HTML styling
local function highlight_html_block(div, settings)
  return apply_html_styling(div, settings, true, pandoc.Div)
end

--- Applies text and background colour styling for LaTeX-based outputs
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply
--- @param border_style string The border style to apply
--- @param par boolean Whether to wrap in a paragraph box
--- @return table The span content with LaTeX markup
local function highlight_latex(span, colour, bg_colour, border_colour, border_style, par)
  local is_lualatex = quarto.doc.pdf_engine() == 'lualatex'

  if is_lualatex and bg_colour ~= nil then
    quarto.doc.use_latex_package('luacolor, lua-ul')
  end

  if border_colour ~= nil then
    quarto.doc.use_latex_package('tikz')
  end

  local colour_open, colour_close
  if colour == nil then
    colour_open = ''
    colour_close = ''
  else
    colour_open = '\\textcolor[HTML]{' .. colour:gsub('^#', '') .. '}{'
    colour_close = '}'
  end

  local bg_colour_open, bg_colour_close
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

  local border_open, border_close
  if border_colour == nil then
    border_open = ''
    border_close = ''
  else
    -- Map border styles to TikZ line styles
    local tikz_style = ''
    if border_style == 'dashed' then
      tikz_style = ', dashed'
    elseif border_style == 'dotted' then
      tikz_style = ', dotted'
    elseif border_style == 'double' then
      tikz_style = ', double'
    end

    border_open = '\\tikz[baseline=(text.base)]{\\node[draw={rgb,255:red,' ..
        tonumber(border_colour:sub(2, 3), 16) .. ';green,' ..
        tonumber(border_colour:sub(4, 5), 16) .. ';blue,' ..
        tonumber(border_colour:sub(6, 7), 16) .. '}' .. tikz_style .. ', inner sep=0.1em] (text) {\\strut '
    border_close = '};}'
  end

  table.insert(
    span.content, 1,
    pandoc.RawInline('latex', border_open .. colour_open .. bg_colour_open)
  )
  table.insert(span.content, pandoc.RawInline('latex', bg_colour_close .. colour_close .. border_close))

  return span.content
end

--- Applies text and background colour styling for LaTeX-based outputs (block level)
--- @param div table The div element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply
--- @param border_style string The border style to apply
--- @return table A modified div with LaTeX environment wrapping
local function highlight_latex_block(div, colour, bg_colour, border_colour, border_style)
  local is_lualatex = quarto.doc.pdf_engine() == 'lualatex'

  if bg_colour ~= nil then
    if is_lualatex then
      quarto.doc.use_latex_package('luacolor, lua-ul')
    else
      quarto.doc.use_latex_package('xcolor')
    end
  end

  if border_colour ~= nil then
    quarto.doc.use_latex_package('tikz')
  end

  local latex_begin = ''
  local latex_end = ''

  if border_colour ~= nil then
    -- Map border styles to TikZ line styles
    local tikz_style = ''
    if border_style == 'dashed' then
      tikz_style = ', dashed'
    elseif border_style == 'dotted' then
      tikz_style = ', dotted'
    elseif border_style == 'double' then
      tikz_style = ', double'
    end

    latex_begin = '\\begin{tikzpicture}\\node[draw={rgb,255:red,' ..
        tonumber(border_colour:sub(2, 3), 16) .. ';green,' ..
        tonumber(border_colour:sub(4, 5), 16) .. ';blue,' ..
        tonumber(border_colour:sub(6, 7), 16) ..
        '}' .. tikz_style .. ', inner sep=0.5em, text width=\\dimexpr\\linewidth-1em\\relax]{'
    latex_end = '};\\end{tikzpicture}'

    if colour ~= nil and bg_colour ~= nil then
      if is_lualatex then
        latex_begin = latex_begin ..
            '{\\color[HTML]{' .. colour:gsub('^#', '') .. '}\\highLight[{[HTML]{' .. bg_colour:gsub('^#', '') .. '}}]{'
        latex_end = '}}' .. latex_end
      else
        latex_begin = latex_begin ..
            '\\colorbox[HTML]{' ..
            bg_colour:gsub('^#', '') ..
            '}{\\parbox{\\dimexpr\\linewidth-2em}{\\color[HTML]{' .. colour:gsub('^#', '') .. '}'
        latex_end = '}}' .. latex_end
      end
    elseif bg_colour ~= nil then
      if is_lualatex then
        latex_begin = latex_begin .. '\\highLight[{[HTML]{' .. bg_colour:gsub('^#', '') .. '}}]{'
        latex_end = '}' .. latex_end
      else
        latex_begin = latex_begin ..
            '\\colorbox[HTML]{' .. bg_colour:gsub('^#', '') .. '}{\\parbox{\\dimexpr\\linewidth-2em}{'
        latex_end = '}}' .. latex_end
      end
    elseif colour ~= nil then
      latex_begin = latex_begin .. '{\\color[HTML]{' .. colour:gsub('^#', '') .. '}'
      latex_end = '}' .. latex_end
    end
  elseif colour ~= nil and bg_colour ~= nil then
    if is_lualatex then
      latex_begin = '{\\color[HTML]{' ..
          colour:gsub('^#', '') .. '}\\highLight[{[HTML]{' .. bg_colour:gsub('^#', '') .. '}}]{'
      latex_end = '}}'
    else
      latex_begin = '\\colorbox[HTML]{' ..
          bg_colour:gsub('^#', '') ..
          '}{\\parbox{\\dimexpr\\linewidth-2\\fboxsep}{\\color[HTML]{' .. colour:gsub('^#', '') .. '}'
      latex_end = '}}'
    end
  elseif bg_colour ~= nil then
    if is_lualatex then
      latex_begin = '\\highLight[{[HTML]{' .. bg_colour:gsub('^#', '') .. '}}]{'
      latex_end = '}'
    else
      latex_begin = '\\colorbox[HTML]{' .. bg_colour:gsub('^#', '') .. '}{\\parbox{\\dimexpr\\linewidth-2\\fboxsep}{'
      latex_end = '}}'
    end
  elseif colour ~= nil then
    latex_begin = '{\\color[HTML]{' .. colour:gsub('^#', '') .. '}'
    latex_end = '}'
  end

  table.insert(div.content, 1, pandoc.RawBlock('latex', latex_begin))
  table.insert(div.content, pandoc.RawBlock('latex', latex_end))

  return div.content
end

--- Applies text and background colour styling for Word documents
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply
--- @param border_style string The border style to apply
--- @return table The span content with OpenXML markup for Word
local function highlight_openxml_docx(span, colour, bg_colour, border_colour, border_style)
  local spec = '<w:r><w:rPr>'
  if bg_colour ~= nil then
    spec = spec .. '<w:shd w:val="clear" w:fill="' .. bg_colour:gsub('^#', '') .. '"/>'
  end
  if colour ~= nil then
    spec = spec .. '<w:color w:val="' .. colour:gsub('^#', '') .. '"/>'
  end
  if border_colour ~= nil then
    -- Map border styles to Word border values
    local word_style = 'single'
    if border_style == 'dashed' then
      word_style = 'dashed'
    elseif border_style == 'dotted' then
      word_style = 'dotted'
    elseif border_style == 'double' then
      word_style = 'double'
    end
    spec = spec ..
        '<w:bdr w:val="' .. word_style .. '" w:sz="4" w:space="0" w:color="' .. border_colour:gsub('^#', '') .. '"/>'
  end
  spec = spec .. '</w:rPr><w:t>'

  table.insert(span.content, 1, pandoc.RawInline('openxml', spec))
  table.insert(span.content, pandoc.RawInline('openxml', '</w:t></w:r>'))

  return span.content
end

--- Applies text and background colour styling for Word documents (block level)
--- @param div table The div element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply
--- @param border_style string The border style to apply
--- @return table The div content with OpenXML markup for Word
local function highlight_openxml_docx_block(div, colour, bg_colour, border_colour, border_style)
  local spec = '<w:pPr>'
  if bg_colour ~= nil then
    spec = spec .. '<w:shd w:val="clear" w:fill="' .. bg_colour:gsub('^#', '') .. '"/>'
  end
  if border_colour ~= nil then
    -- Map border styles to Word border values
    local word_style = 'single'
    if border_style == 'dashed' then
      word_style = 'dashed'
    elseif border_style == 'dotted' then
      word_style = 'dotted'
    elseif border_style == 'double' then
      word_style = 'double'
    end
    local border_spec = '<w:pBdr><w:top w:val="' ..
        word_style .. '" w:sz="4" w:space="1" w:color="' .. border_colour:gsub('^#', '') .. '"/>' ..
        '<w:left w:val="' .. word_style .. '" w:sz="4" w:space="1" w:color="' .. border_colour:gsub('^#', '') .. '"/>' ..
        '<w:bottom w:val="' ..
        word_style .. '" w:sz="4" w:space="1" w:color="' .. border_colour:gsub('^#', '') .. '"/>' ..
        '<w:right w:val="' ..
        word_style .. '" w:sz="4" w:space="1" w:color="' .. border_colour:gsub('^#', '') .. '"/></w:pBdr>'
    spec = spec .. border_spec
  end
  spec = spec .. '</w:pPr>'

  table.insert(div.content, 1, pandoc.RawBlock('openxml', spec))

  if colour ~= nil then
    for idx = 2, #div.content do
      if div.content[idx].t == 'Para' or div.content[idx].t == 'Plain' then
        local para = div.content[idx]
        local colour_spec = '<w:r><w:rPr><w:color w:val="' .. colour:gsub('^#', '') .. '"/></w:rPr><w:t>'
        table.insert(para.content, 1, pandoc.RawInline('openxml', colour_spec))
        table.insert(para.content, pandoc.RawInline('openxml', '</w:t></w:r>'))
      end
    end
  end

  return div.content
end

--- Applies text and background colour styling for PowerPoint presentations
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply (not supported for inline text)
--- @return table Raw inline containing OpenXML markup for PowerPoint
local function highlight_openxml_pptx(span, colour, bg_colour, border_colour)
  -- Note: PowerPoint does not support rectangular borders on inline text runs
  -- Border colour is ignored for inline spans in PowerPoint format
  -- Use block-level divs for border support
  local spec = '<a:r><a:rPr dirty="0">'
  if colour ~= nil then
    spec = spec .. '<a:solidFill><a:srgbClr val="' .. colour:gsub('^#', '') .. '" /></a:solidFill>'
  end
  if bg_colour ~= nil then
    spec = spec .. '<a:highlight><a:srgbClr val="' .. bg_colour:gsub('^#', '') .. '" /></a:highlight>'
  end
  spec = spec .. '</a:rPr><a:t>'

  local span_content_string = ''
  for _, inline in ipairs(span.content) do
    span_content_string = span_content_string .. pandoc.utils.stringify(inline)
  end

  return pandoc.RawInline('openxml', spec .. span_content_string .. '</a:t></a:r>')
end

--- Applies text and background colour styling for PowerPoint presentations (block level)
--- @param div table The div element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply (not supported)
--- @return table The div content with OpenXML markup for PowerPoint
local function highlight_openxml_pptx_block(div, colour, bg_colour, border_colour)
  -- Note: PowerPoint does not support rectangular borders on text paragraphs
  -- Border colour is ignored for PowerPoint format
  -- Borders in PowerPoint can only be applied to shapes or table cells
  for idx = 1, #div.content do
    if div.content[idx].t == 'Para' or div.content[idx].t == 'Plain' then
      local para = div.content[idx]
      local para_content_string = ''
      for _, inline in ipairs(para.content) do
        para_content_string = para_content_string .. pandoc.utils.stringify(inline)
      end

      local spec = '<a:r><a:rPr dirty="0">'
      if colour ~= nil then
        spec = spec .. '<a:solidFill><a:srgbClr val="' .. colour:gsub('^#', '') .. '" /></a:solidFill>'
      end
      if bg_colour ~= nil then
        spec = spec .. '<a:highlight><a:srgbClr val="' .. bg_colour:gsub('^#', '') .. '" /></a:highlight>'
      end
      spec = spec .. '</a:rPr><a:t>'

      para.content = { pandoc.RawInline('openxml', spec .. para_content_string .. '</a:t></a:r>') }
    end
  end

  return div.content
end

--- Applies text and background colour styling for Typst output
--- @param span table The span element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply
--- @param border_style string The border style to apply
--- @return table The span content with Typst markup
local function highlight_typst(span, colour, bg_colour, border_colour, border_style)
  local colour_open, colour_close
  if colour == nil then
    colour_open = ''
    colour_close = ''
  else
    colour_open = '#text(' .. colour .. ')['
    colour_close = ']'
  end

  local bg_colour_open, bg_colour_close
  local border_open, border_close

  -- Build Typst stroke specification with optional dash pattern
  local function build_stroke(stroke_colour, style)
    if style == 'dashed' then
      return '(paint: ' .. stroke_colour .. ', dash: "dashed")'
    elseif style == 'dotted' then
      return '(paint: ' .. stroke_colour .. ', dash: "dotted")'
    elseif style == 'double' then
      return '(paint: ' .. stroke_colour .. ', thickness: 2pt)'
    else
      return stroke_colour
    end
  end

  -- When both border and background are present, combine them in a single box
  if border_colour ~= nil and bg_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#box(stroke: ' .. stroke_spec .. ', fill: ' .. bg_colour .. ', inset: (x: 0.2em, y: 0.45em))['
    border_close = ']'
    bg_colour_open = ''
    bg_colour_close = ''
  elseif border_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#box(stroke: ' .. stroke_spec .. ', inset: (x: 0.2em, y: 0.45em))['
    border_close = ']'
    bg_colour_open = ''
    bg_colour_close = ''
  elseif bg_colour ~= nil then
    bg_colour_open = '#highlight(fill: ' .. bg_colour .. ')['
    bg_colour_close = ']'
    border_open = ''
    border_close = ''
  else
    bg_colour_open = ''
    bg_colour_close = ''
    border_open = ''
    border_close = ''
  end

  table.insert(
    span.content, 1,
    pandoc.RawInline('typst', border_open .. colour_open .. bg_colour_open)
  )
  table.insert(
    span.content,
    pandoc.RawInline('typst', bg_colour_close .. colour_close .. border_close)
  )

  return span.content
end

--- Applies text and background colour styling for Typst output (block level)
--- @param div table The div element to modify
--- @param colour string The text colour to apply
--- @param bg_colour string The background colour to apply
--- @param border_colour string The border colour to apply
--- @param border_style string The border style to apply
--- @return table The div content with Typst markup
local function highlight_typst_block(div, colour, bg_colour, border_colour, border_style)
  local colour_open, colour_close
  if colour == nil then
    colour_open = ''
    colour_close = ''
  else
    colour_open = '#text(' .. colour .. ')['
    colour_close = ']'
  end

  local bg_colour_open, bg_colour_close
  local border_open, border_close

  -- Build Typst stroke specification with optional dash pattern
  local function build_stroke(stroke_colour, style)
    if style == 'dashed' then
      return '(paint: ' .. stroke_colour .. ', dash: "dashed")'
    elseif style == 'dotted' then
      return '(paint: ' .. stroke_colour .. ', dash: "dotted")'
    elseif style == 'double' then
      return '(paint: ' .. stroke_colour .. ', thickness: 2pt)'
    else
      return stroke_colour
    end
  end

  -- When both border and background are present, combine them in a single block
  if border_colour ~= nil and bg_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#block(stroke: ' ..
        stroke_spec .. ', fill: ' .. bg_colour .. ', inset: (x: 0.5em, y: 0.9em), radius: 0.2em)['
    border_close = ']'
    bg_colour_open = ''
    bg_colour_close = ''
  elseif border_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#block(stroke: ' .. stroke_spec .. ', inset: (x: 0.5em, y: 0.9em), radius: 0.2em)['
    border_close = ']'
    bg_colour_open = ''
    bg_colour_close = ''
  elseif bg_colour ~= nil then
    bg_colour_open = '#block(fill: ' .. bg_colour .. ', inset: 0.5em, radius: 0.2em)['
    bg_colour_close = ']'
    border_open = ''
    border_close = ''
  else
    bg_colour_open = ''
    bg_colour_close = ''
    border_open = ''
    border_close = ''
  end

  table.insert(
    div.content, 1,
    pandoc.RawBlock('typst', border_open .. colour_open .. bg_colour_open)
  )
  table.insert(
    div.content,
    pandoc.RawBlock('typst', bg_colour_close .. colour_close .. border_close)
  )

  return div.content
end

--- Extracts colour attributes from element attributes
--- @param attributes table The element attributes
--- @return string|nil colour The foreground colour
--- @return string|nil bg_colour The background colour
--- @return string|nil border_colour The border colour
--- @return string|nil border_style The border style
local function get_colour_attributes(attributes)
  local colour = attributes['ink'] or attributes['fg'] or attributes['colour'] or attributes['color']
  local bg_colour = attributes['paper'] or attributes['bg'] or attributes['bg-colour'] or attributes['bg-color']
  local border_colour = attributes['bc'] or attributes['border-colour'] or attributes['border-color']
  local border_style = attributes['bs'] or attributes['border-style']
  return colour, bg_colour, border_colour, border_style
end

--- Processes colour settings for light and dark themes
--- @param colour string|nil The foreground colour
--- @param bg_colour string|nil The background colour
--- @param border_colour string|nil The border colour
--- @param border_style string|nil The border style
--- @return table|nil highlight_settings The processed highlight settings
local function process_highlight_settings(colour, bg_colour, border_colour, border_style)
  local highlight_settings = {}

  if quarto.brand.has_mode('light') or quarto.brand.has_mode('dark') then
    local modes = { 'light', 'dark' }
    for _, mode in ipairs(modes) do
      if quarto.brand.has_mode(mode) then
        highlight_settings[mode] = {
          colour = get_brand_colour(mode, colour),
          bg_colour = get_brand_colour(mode, bg_colour),
          border_colour = get_brand_colour(mode, border_colour),
          border_style = border_style
        }
      end
    end
  else
    highlight_settings.light = {
      colour = get_brand_colour('light', colour),
      bg_colour = get_brand_colour('light', bg_colour),
      border_colour = get_brand_colour('light', border_colour),
      border_style = border_style
    }
  end

  if highlight_settings.light == nil and highlight_settings.dark == nil then
    return nil
  end

  if highlight_settings.light == nil then
    highlight_settings.light = highlight_settings.dark
  end

  return highlight_settings
end

--- Main filter function that processes span elements and applies highlighting
--- based on the output format and specified attributes
--- @param span table The span element from the document
--- @return table The modified span or span content with appropriate styling
local function highlight(span)
  local colour, bg_colour, border_colour, border_style = get_colour_attributes(span.attributes)
  local highlight_settings = process_highlight_settings(colour, bg_colour, border_colour, border_style)

  if highlight_settings == nil then
    return span
  end

  colour = highlight_settings.light.colour
  bg_colour = highlight_settings.light.bg_colour
  border_colour = highlight_settings.light.border_colour
  border_style = highlight_settings.light.border_style

  if colour == nil and bg_colour == nil and border_colour == nil then
    return span
  end

  local par = span.attributes['par'] ~= nil
  span.attributes['par'] = nil

  if quarto.doc.is_format('html') or quarto.doc.is_format('revealjs') then
    return highlight_html(span, highlight_settings)
  elseif quarto.doc.is_format('latex') or quarto.doc.is_format('beamer') then
    return highlight_latex(span, colour, bg_colour, border_colour, border_style, par)
  elseif quarto.doc.is_format('docx') then
    return highlight_openxml_docx(span, colour, bg_colour, border_colour, border_style)
  elseif quarto.doc.is_format('pptx') then
    return highlight_openxml_pptx(span, colour, bg_colour, border_colour)
  elseif quarto.doc.is_format('typst') then
    return highlight_typst(span, colour, bg_colour, border_colour, border_style)
  else
    return span
  end
end

--- Main filter function that processes div elements and applies highlighting
--- based on the output format and specified attributes
--- @param div table The div element from the document
--- @return table The modified div or div content with appropriate styling
local function highlight_block(div)
  local colour, bg_colour, border_colour, border_style = get_colour_attributes(div.attributes)
  local highlight_settings = process_highlight_settings(colour, bg_colour, border_colour, border_style)

  if highlight_settings == nil then
    return div
  end

  colour = highlight_settings.light.colour
  bg_colour = highlight_settings.light.bg_colour
  border_colour = highlight_settings.light.border_colour
  border_style = highlight_settings.light.border_style

  if colour == nil and bg_colour == nil and border_colour == nil then
    return div
  end

  -- Clean up attributes
  div.attributes['fg'] = nil
  div.attributes['colour'] = nil
  div.attributes['color'] = nil
  div.attributes['bg'] = nil
  div.attributes['bg-colour'] = nil
  div.attributes['bg-color'] = nil
  div.attributes['bc'] = nil
  div.attributes['border-colour'] = nil
  div.attributes['border-color'] = nil
  div.attributes['bs'] = nil
  div.attributes['border-style'] = nil

  if quarto.doc.is_format('html') or quarto.doc.is_format('revealjs') then
    return highlight_html_block(div, highlight_settings)
  elseif quarto.doc.is_format('latex') or quarto.doc.is_format('beamer') then
    return highlight_latex_block(div, colour, bg_colour, border_colour, border_style)
  elseif quarto.doc.is_format('docx') then
    return highlight_openxml_docx_block(div, colour, bg_colour, border_colour, border_style)
  elseif quarto.doc.is_format('pptx') then
    return highlight_openxml_pptx_block(div, colour, bg_colour, border_colour)
  elseif quarto.doc.is_format('typst') then
    return highlight_typst_block(div, colour, bg_colour, border_colour, border_style)
  else
    return div
  end
end

return {
  { Span = highlight },
  { Div = highlight_block },
}
