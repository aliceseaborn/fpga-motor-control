-- ---------------------------------------------------------------------
-- D Flip Flop Component
-- Source:	http://eelinux.ee.usm.maine.edu/courses/ele373/LECT04-2.pdf
-- Used: 	12/3/2015 @ 19:00
-- ---------------------------------------------------------------------

Library IEEE; 
Use IEEE.STD_LOGIC_1164.all;

Entity DFF is 
port (         
		D, Clk		: in	STD_LOGIC; 
		Q			: out	STD_LOGIC
);
End DFF;

Architecture Behavior of DFF is

Begin

	process (D, Clk)
	begin
		if Clk = '1' then
			Q <= D;
		end if;
	end process;

End Behavior;