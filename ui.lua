uis = {}

function drawUIs()
  love.graphics.origin()
  for u, ui in pairs(uis) do
    drawElementAndChildren(ui)
  end
end

addDrawFunction(drawUIs, 9)

function drawElementAndChildren(ui)
  if not ui.hidden and ui.draw then
    love.graphics.push()
    love.graphics.translate(ui.x, ui.y)
    ui:draw()
    if ui.children then
      for c, child in pairs(ui.children) do
        drawElementAndChildren(child)
      end
    end
    love.graphics.pop()
  end
end

function getElementOn(x, y)
  local element
  for u, ui in pairs(uis) do
    element =  getElementOrChildOn(ui, x, y)
    if element then return element end
  end
end

function getElementOrChildOn(ui, x, y)
  local w = ui.w or ui.width
  local h = ui.h or ui.height
  if not ui.hidden and ui.x and ui.y and w and h then
    if x >= ui.x and x <= ui.x + w and y >= ui.y and y <= ui.y + h then
      if ui.children then
        for c, child in pairs(ui.children) do
          local clickedElement = getElementOrChildOn(child, x - ui.x, y - ui.y)
          if clickedElement then
            return clickedElement
          end
        end
      end
      return ui
    end
  end
end

function UIMousePress(x, y, button)
  pressed = nil
  local element = getElementOn(x, y)
  if element and (element.onClick or element.onPress) then
    if element.onPress then element:onPress() end
    pressed = element
    return true
  end
  return false
end

function UIMouseRelease(x, y, button)
  local element = getElementOn(x, y)
  if element and (element.onClick and pressed==element) then
    element:onClick()
  end
  pressed = nil
  return (element ~= nil)
end
