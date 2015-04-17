class 'BaseEntity'

function BaseEntity:__init(attributes, component)
	self.component = component;
	self.entity = component.entity;
	self.level = component.entity.level;
end

return {
	name = "BaseEntity",
	value = BaseEntity
};