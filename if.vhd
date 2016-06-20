library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity if_jedinica is
	generic
	(
		addr_length: integer := 32;
		instr_length : integer := 32
	);


	port
	(
		clk : in std_logic;
		reset: in std_logic;
		initial_PC: in std_logic_vector((addr_length-1) downto 0);
		IF_addr: out std_logic_vector((addr_length-1) downto 0);-- prosledjujemo PC instrCache-u
		instr:in std_logic_vector((instr_length-1) downto 0);--instrukcija iz kesa
		ird:out std_logic;--signal instrCache da hoce da cita
		pc_out: out std_logic_vector((addr_length-1) downto 0);--prosledjivanje pc u narednu fazu
		instr_to_decode: out std_logic_vector((instr_length-1) downto 0);--prosledjivanje instr u narednu fazu
		stall: in std_logic;
		flush_out: out std_logic;
		
		pc_to_pred : out std_logic_vector (addr_length-1 downto 0); -- pc saljemo u prediktor
		pc_predicted : in std_logic_vector (addr_length-1 downto 0); -- prediktovana vrednost pc-a
		pc_predicted_out : out std_logic_vector (addr_length-1 downto 0); --prosl u decode
		branch_predicted : in std_logic; -- predvidjanje da li ce doci do skoka
		branch_predicted_out : out std_logic;
		misprediction : in std_logic;
		branch_pc : in std_logic_vector (addr_length-1 downto 0);  --ispravna vrednost pc-a kad se desi mispred (dolazi iz exe)
		
		idle : in std_logic
	);
end if_jedinica;


architecture impl of if_jedinica is

	signal pc, pc_next, pc_reg_out : std_logic_vector((addr_length-1) downto 0);
	
begin

	process (clk, reset) is
	begin 
	
		if (reset = '1') then
			pc_next<= initial_PC;
			ird<= '0';
		elsif (rising_edge(clk)) then
		if(idle = '0') then
			
			if (branch_predicted = '1') then 
				pc_next <= std_logic_vector(unsigned(pc_predicted) + 2);
				pc <= std_logic_vector(unsigned(pc_predicted) + 1);
			else 
				pc_next <= std_logic_vector(unsigned(pc_next) + 1);
				pc <= pc_next;
			end if;
			if (misprediction = '1') then 
				pc_next <= std_logic_vector(unsigned(branch_pc) + 1);
				pc <= branch_pc;
				
			end if;
			
			ird<='1';
			if (branch_predicted = '0') then
				pc_reg_out <= pc;
			else
				pc_reg_out <= pc_predicted;
			end if;
			flush_out <=misprediction;
			
			
			
			if(stall='1') then
				pc_next <= pc_next;
				pc <= pc;
				pc_reg_out<= pc_reg_out;
			end if;
	
			end if;
		end if;
	end process;
	instr_to_decode<=instr;
	IF_addr <= pc_predicted when branch_predicted = '1' else
			  	  pc when stall = '0' 
				  else pc_reg_out;
	pc_out <= pc_reg_out;
	pc_to_pred <=  pc_predicted when branch_predicted = '1' else
						pc when stall = '0' 
						else pc_reg_out;
	branch_predicted_out <= branch_predicted;					
	pc_predicted_out <= pc_predicted;
--	pc <= pc_predicted when branch_predicted = '1' else pc_reg_out;
	
end impl;
