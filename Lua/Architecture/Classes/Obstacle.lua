-- depends on BaseEntity
if not BaseEntity then return end
class 'Obstacle' (BaseEntity)

function Obstacle:__init(attributes, component)
	Polyghtgons.Classes.Scripting.BaseEntity.__init(self, attributes, component);
end

function Obstacle:activate()
	-- remove edges with neighbours
	local server = Polyghtgons.Classes.AI.Server.getSingleton();

	local neighbours = Polyghtgons.Classes.Logic.Level.Level.neighbours(self.entity, self.level);
	for _, neighbour in ipairs(neighbours) do
		server:removeEdge(self.entity.position, neighbour.position);
	end

	return true;
end

return {
	name = "Obstacle",
	value = Obstacle
};