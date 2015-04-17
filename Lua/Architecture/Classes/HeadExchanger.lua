-- depends on BaseEntity
if not BaseEntity then return end
class 'HeadExchanger' (BaseEntity)

local Messages = Polyghtgons.Classes.Logic.Messages;

function HeadExchanger:__init(attributes, component)
	Polyghtgons.Classes.Scripting.BaseEntity.__init(self, attributes, component);

	self.twinExchanger = attributes.lua_data.twin_exchanger;
	self.ready = false;
	self.currentEntity = nil;

	self.exchanging = false;
	self.exchangeTime = attributes.lua_data.exchange_time;

	self.closing = false;
	self.closingTime = 1.4;

	self.opening = false;
	self.openingTime = 0.4;
end

function HeadExchanger:onTouch(message)
	-- check if the entity which entered is a Polyghtgon and store it
	if message.entity.type ~= "Polyghtgon" then
		return;
	end

	-- did it enter or exit?
	if message.enter and self.currentEntity == nil then
		self.ready = true;
		self.currentEntity = message.entity;

		self:checkIfActive();
	elseif not message.enter then
		-- only deactivate if it's the Polyghtgon we got inside
		if self.currentEntity.name == message.entity.name then
			self.ready = false;
			self.currentEntity = nil;
		end
	end
end

function HeadExchanger:checkIfActive()
	-- check if brother HeadExchanger is active
	local twin = Polyghtgons.Instances[self.twinExchanger];

	if twin.ready then
		self:activateExchanger(true);
		twin:activateExchanger(false);
	end
end

-- when an exchanger is activated, we tell it if it's responsible of sending heads when animation concludes, or not
function HeadExchanger:activateExchanger(responsibleOfSendingHeads)
	self.responsibleOfSendingHeads = responsibleOfSendingHeads;

	self.closing = true;
	self.currentTimeClosing = 0.0;
	self.entity:emitMessage(Messages.SetAnimation(false, "Closing"), self.component);

	-- lock exchangers' entities
	if self.responsibleOfSendingHeads then
		local twin = Polyghtgons.Instances[self.twinExchanger];

		-- stop them immediately
		self.currentEntity:emitMessage(Messages.RouteTo(true, self.entity.position), self.component);
		twin.currentEntity:emitMessage(Messages.RouteTo(true, self.entity.position), self.component);

		-- prevent movement
		self.currentEntity:emitMessage(Messages.Message(Messages.Message.LOCK_CONTROLS), self.component);
		twin.currentEntity:emitMessage(Messages.Message(Messages.Message.LOCK_CONTROLS), self.component);

	end
end

function HeadExchanger:tick(secs)
	if self.closing then
		self.currentTimeClosing = self.currentTimeClosing + secs;

		if self.currentTimeClosing >= self.closingTime then
			self.closing = false;

			-- activate it
			self.exchanging = true;
			self.currentTimeExchanging = 0.0;
			self.entity:emitMessage(Messages.ActivateParticle(true), self.component);
			self.entity:emitMessage(Messages.SetAnimation(true, "Activated"), self.component);
			self.entity:emitMessage(Messages.ChangeMaterial(0, true, "ExchangerExchanging", false), self.component);
		end
	end

	if self.opening then
		self.currentTimeOpening = self.currentTimeOpening + secs;

		if self.currentTimeOpening >= self.openingTime then
			self.opening = false;
			self.entity:emitMessage(Messages.SetAnimation(true, "IdleOpened"), self.component);
		end
	end

	if self.exchanging then
		self.currentTimeExchanging = self.currentTimeExchanging + secs;

		if self.currentTimeExchanging >= self.exchangeTime then
			self.exchanging = false;

			-- turn off our particle system
			self.entity:emitMessage(Messages.ActivateParticle(false), self.component);

			-- access twin
			local twin = Polyghtgons.Instances[self.twinExchanger];

			if self.currentEntity and twin.currentEntity and self.responsibleOfSendingHeads then
				-- tell twin's entity to send its head to our entity
				twin.currentEntity:emitMessage(Messages.SendHead(self.currentEntity), self.component);

				-- tell our entity to send its head to twin's entity
				self.currentEntity:emitMessage(Messages.SendHead(twin.currentEntity), self.component);

				-- unlock exchangers' entities
				local twin = Polyghtgons.Instances[self.twinExchanger];
				self.currentEntity:emitMessage(Messages.Message(Messages.Message.UNLOCK_CONTROLS), self.component);
				twin.currentEntity:emitMessage(Messages.Message(Messages.Message.UNLOCK_CONTROLS), self.component);
			end

			-- since our messaging system is a post-tick one, they will both process the message in the next tick and thus send a ChangeHead message to the other entity with their head. Those new messages will be processed in the next tick, so they will receive their new heads instead of creating a feedback loop

			-- and now tell it to open
			self.opening = true;
			self.currentTimeOpening = 0.0;
			self.entity:emitMessage(Messages.SetAnimation(false, "Opening"), self.component);
			self.entity:emitMessage(Messages.ChangeMaterial(0, true, "Exchanger", false), self.component);
		end
	end
end

return {
	name = "HeadExchanger",
	value = HeadExchanger
};