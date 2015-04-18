-- depends on PuzzleElement
if not PuzzleElement then return end
class 'Lever' (PuzzleElement)

-- some local variables to prevent tedious namespacing
local Messages = Polyghtgons.Classes.Logic.Messages;
local Logic = Polyghtgons.Classes.Logic;
local Graphics = Polyghtgons.Classes.Graphics;

-- possible status for our Lever
local LeverStatus = {
	On = 0,
	Off = 1,
	TurnOn = 2,
	TurnOff = 3
};

-- constructor
function Lever:__init(attributes, component)
	Polyghtgons.Classes.Scripting.PuzzleElement.__init(self, attributes, component);

	if attributes.lua_data then
		self.connection = attributes.lua_data.connection;
		self.turnOffAutomaticTime = attributes.lua_data.turn_off_automatic_time or 1.5; -- this "or 1.5" should be removed, because it means it will always have automatic turn off
	end
	self.currentTurnOffAutomaticTime = 0.0;
	self.colorName = attributes.color;

	self.leverStatus = LeverStatus.Off;
	self.entity:emitMessage(Messages.ChangeMaterial(-1, true, "Lever/" .. self.colorName, true), self.component);
end

-- growing
function Lever:activatePuzzle()
	self.status = self.PuzzleStatus.ACTIVATING;

	if self.leverStatus == LeverStatus.Off then
		self.leverStatus = LeverStatus.TurnOn;
		self.entity:emitMessage(Messages.SetAnimation(false, "TurnOn"), self.component);
		self.entity:emitMessage(Messages.AudioPlay("Success"), self.component);
	elseif self.leverStatus == LeverStatus.On then
		self.leverStatus = LeverStatus.TurnOff;
		self.entity:emitMessage(Messages.SetAnimation(false, "TurnOff"), self.component);
	end

	self.entity:emitMessage(Messages.ChangeMaterial(-1, true, "LeverActivating/" .. self.colorName, false), self.component);

	self.currentActivatingTime = 0.9;
	self.status = self.PuzzleStatus.ACTIVATING;

end

-- moaning
function Lever:moan()
	self.status = self.PuzzleStatus.MOANING;

	self.entity:emitMessage(Messages.ChangeMaterial(-1, true, "LeverMoaning/" .. self.colorName, false), self.component);
	self.entity:emitMessage(Messages.FadeFromSolidColor(Graphics.Vector4(0.0, 0.0, 0.0, 1.0), 5.0), self.component);

	self.entity:emitMessage(Messages.AudioPlay("Failure"), self.component);
end

-- do something per frame
function Lever:tick(secs)
	if self.status == self.PuzzleStatus.ACTIVATING then
		self.currentActivatingTime = self.currentActivatingTime - secs;

		if self.currentActivatingTime <= 0.0 then
			-- we've completed our activation
			self.status = self.PuzzleStatus.INITIAL;

			-- if we find our connected entity, get it to tell it we've changed our activation status
			local connection = Polyghtgons.Instances[self.connection];
			local leverStatusString;

			if self.leverStatus == LeverStatus.TurnOn then
				leverStatusString = "On";
			elseif self.leverStatus == LeverStatus.TurnOff then
				leverStatusString = "Off";
			end

			-- now set status, animation and tell our connection it has to change its status
			self.leverStatus = LeverStatus[leverStatusString];
			self.entity:emitMessage(Messages.SetAnimation(true, leverStatusString), self.component);

			if connection and connection["turn" .. leverStatusString] then
				connection["turn" .. leverStatusString](connection);
			end

			-- countdown to turn off automatically?
			if leverStatusString == "On" and self.turnOffAutomaticTime then
				self.currentTurnOffAutomaticTime = self.turnOffAutomaticTime;
			end
		end
	end

	-- automatic turn off?
	if self.currentTurnOffAutomaticTime > 0.0 then
		self.currentTurnOffAutomaticTime = self.currentTurnOffAutomaticTime - secs;

		if self.currentTurnOffAutomaticTime <= 0.0 then
			self:activatePuzzle();
		end
	end
end

-- return everything we need to
return {
	name = "Lever",
	value = Lever
};