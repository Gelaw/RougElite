local pe = {
  x = 0, y = 0, color = {1, 1, 1}, timeLeft = 10,
  draw = function (self)
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", 0, 0, 10)
  end
}
table.insert(particuleEffects, pe)
