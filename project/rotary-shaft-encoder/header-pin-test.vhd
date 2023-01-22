-- ---------------------
-- Header Pin Test
-- ---------------------

Library IEEE;
Use IEEE.STD_LOGIC_1164.all;

Entity J1_Header is
port (
		-- Input switch
		clear 		:	STD_LOGIC;
		
		-- Output
		active_high	:	STD_LOGIC;
);
End J1_Header;

Architecture Behavioral of J1_Header is

signal	temp 		: 	STD_LOGIC;

Begin

	-- Test clear signal
	if clear = 0 then
		temp <= '0';
	elsif clear = 1 then
		temp <= '1';
	end if;
	
	-- Pass temp to active_high
	active_high <= temp;
	
End Behavioral;