library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Regfile is
	generic
	(
		reg_adr_length	: integer := 5;
		reg_data_length	: integer  :=	32
	);

	port
	(
		
		reset	: in  std_logic;
		rd	:	in	std_logic;
		wr	:	in	std_logic;
		-- Adrese za citanje i upis
		op1_rd_adr	:	in	std_logic_vector((reg_adr_length-1) downto 0);
		op2_rd_adr	:	in	std_logic_vector((reg_adr_length-1) downto 0);
		wr_adr	:	in	std_logic_vector((reg_adr_length-1) downto 0);
		--Podatak za upis
		wr_data	:	in	std_logic_vector((reg_data_length-1) downto 0);
		
		
		-- Output ports
		op1_data	:	out	std_logic_vector((reg_data_length-1) downto 0);
		op2_data	:	out	std_logic_vector((reg_data_length-1) downto 0)
	);
end Regfile;


architecture rtl of Regfile is
type register_file is array (0 to (2**reg_adr_length - 1)) of std_logic_vector((reg_data_length - 1) downto 0);
signal registers : register_file;

begin


	process (reset, rd, wr, op1_rd_adr, op2_rd_adr, wr_adr, wr_data)
	
	begin
		
		op1_data <= (others => 'Z');
		op2_data <= (others => 'Z');
		
		if (reset = '1') then
			for i in 0 to (2**reg_adr_length - 1) loop
				registers(i) <= (others => '0');
			end loop;
		else
			
	
			if (wr = '1') then
				registers(to_integer(unsigned(wr_adr))) <= wr_data;
			end if;
			
			if (rd = '1') then
				if(op1_rd_adr /= "ZZZZZ") then
					op1_data <= registers(to_integer(unsigned(op1_rd_adr)));
				end if;
				if(op2_rd_adr /= "ZZZZZ") then
					op2_data <= registers(to_integer(unsigned(op2_rd_adr)));
				end if;
			end if;
			
		end if;
		
		
	end process;
	

end rtl;