-- cite style constants
local kBibStyleDefault = 'numberednames'
local kBibStyles = {'numbered','numberednames','authoryear'}
local kBibStyleAuthYr = 'elsarticle-harv'
local kBibStyleNumber = 'elsarticle-num'
local kBibStyleNumberName = 'elsarticle-num-names'
local kBibStyleUnknown = kBibStyleNumberName

-- layout and style
local kFormatting = pandoc.List({'preprint', 'review', 'doubleblind'})
local kModels = pandoc.List({'1p', '3p', '5p'})
local kLayouts = pandoc.List({'onecolumn', 'twocolumn'})


local function setBibStyle(meta, style) 
  meta['biblio-style'] = style
  quarto.doc.addFormatResource('bib/' .. style .. '.bst')
end

local function hasClassOption(meta, option) 
  if meta['classoption'] == nil then
    return false
  end

  for i,v in ipairs(meta['classoption']) do
    if v[1].text == option then
      return true
    end
  end
  return false
end

local function addClassOption(meta, option)
  if meta['classoption'] == nil then
    meta['classoption'] = pandoc.List({})
  end

  if not hasClassOption(meta, option) then
    meta['classoption']:insert({ pandoc.Str(option)})
  end
end

local function printList(list) 
  local result = ''
  local sep = ''
  for i,v in ipairs(list) do
    result = result .. sep .. v
    sep = ', '
  end
  return result
end



return {
    {
      Meta = function(meta)
        -- If citeproc is being used, switch to the proper
        -- CSL file
        if quarto.doc.citeMethod() == 'citeproc' and meta['csl'] == nil then
            meta['csl'] = quarto.utils.resolvePath('bib/elsevier-harvard.csl')
        end


        if quarto.doc.isFormat("pdf") then
         
          -- read the journal settings
          local journal = meta['journal']
          local citestyle = nil
          local formatting = nil 
          local model = nil
          local layout = nil

          if journal ~= nil then         
            citestyle = journal['cite-style']
            formatting = journal['formatting']
            model = journal['model']
            layout = journal['layout']
          end

          -- process the site style
          if citestyle ~= nil then
            citestyle = pandoc.utils.stringify(citestyle)
          else 
            citestyle = kBibStyleDefault
          end

          if citestyle == 'authoryear' then
            setBibStyle(meta, kBibStyleAuthYr)
          elseif citestyle == 'numbered' then
            setBibStyle(meta, kBibStyleNumber)
          elseif citestyle == 'numberednames' then
            setBibStyle(meta, kBibStyleNumberName)
          else 
            error("Unknown journal cite-style " .. citestyle .. "\nPlease use one of " .. printList(kBibStyles))
            setBibStyle(meta, kBibStyleUnknown)
          end

          -- process the layout
          if formatting ~= nil then
            formatting = pandoc.utils.stringify(formatting)
            if kFormatting:includes(formatting) then
              addClassOption(meta, formatting)
            else
              error("Unknown journal formatting " .. formatting .. "\nPlease use one of " .. printList(kFormatting))
            end
          end

          -- process the type
          if model ~= nil then
            model = pandoc.utils.stringify(model)
            if kModels:includes(model) then
              addClassOption(meta, model)
            else
              error("Unknown journal model " .. model .. "\nPlease use one of " .. printList(kModels))
            end
          end

          -- 5p models should be two column always
          if model == '5p' and layout == nil then
            layout = 'twocolumn'             
          end

          -- process the type
          if layout ~= nil then
            layout = pandoc.utils.stringify(layout)
            if kLayouts:includes(layout) then
              addClassOption(meta, layout)
              if layout == 'twocolumn' then
                quarto.doc.includeFile('in-header', 'partials/_two-column-longtable.tex')
              end
            else
              error("Unknown journal layout " .. layout .. "\nPlease use one of " .. printList(kLayouts))
            end
          end         
        end

        return meta
      end
    }
  }
  



  