library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Exe is
generic(
	address_length : integer := 32;
	data_length : integer := 32;
	opcode_length : integer := 6;
	reg_code_length : integer := 5;
	addr_length : integer := 32;
	stack_size: integer := 32
);

port(

	clk : in std_logic;
	
	
	-- Vrednosti registara r1 i r2 
	op1_1 : in std_logic_vector((data_length - 1) downto 0);
	op2_1 : in std_logic_vector((data_length - 1) downto 0);
	
	st_value : out std_logic_vector((data_length - 1) downto 0);
	
	
	pc_addr: in std_logic_vector((address_length-1) downto 0); -- PC iz decode
	
	branch_taken: out std_logic; -- da li je doslo do skoka
	update_predictor: out std_logic;	--da li treba da se azurira prediktor
	update_value: out std_logic_vector(63 downto 0); --vrednost koja se azurira
	
		opcode_in : in std_logic_vector(5 downto 0);
		opcode_out : out std_logic_vector((opcode_length-1) downto 0);
	
		rd_adr: in std_logic_vector(4 downto 0);
		rd_adr_out: out std_logic_vector(4 downto 0);
		imm_value : in std_logic_vector (15 downto 0);
	
	
	
	-- Izlazni signali iz ALU jedinica
	data_alu_out : out std_logic_vector((data_length - 1) downto 0);
	
	flush_out: out std_logic;
	flush_id: in std_logic;
	
	
	ar_log: out std_logic;
	brnch: out std_logic; -- treba obrisati
	load : out std_logic;
	valid: out std_logic;
	
	pc_predicted : in std_logic_vector (addr_length-1 downto 0); -- prediktovana vrednost pc-a
	branch_predicted : in std_logic; -- predvidjanje da li ce doci do skoka
	misprediction : out std_logic;
	branch_pc : out std_logic_vector (addr_length-1 downto 0); --ispravna vrednost pc-a kad se desi mispred
	
	idle : in std_logic
	);
end entity;

architecture rtl of Exe is

	type stack_array is array (0 to stack_size-1) of std_logic_vector((addr_length - 1) downto 0);
	signal stack : stack_array;
	signal SP: std_logic_vector (31 downto 0) := (others => '0');

	signal enable: std_logic;
	signal flush:std_logic; -- postavlja se kod pogresno predvidjenog skoka da flushuje instrukciju iz decode koja dolazi
	begin 
	process(clk)
	
		variable update: std_logic_vector(63 downto 0);
		variable result : std_logic_vector(data_length-1 downto 0);
		
	begin
	if (rising_edge(clk)) then
	flush_out <= flush_id or flush;
	flush <= '0';
	ar_log<='0';
	load<='0';
	valid <='0';
--	brnch <= '0';
	misprediction <= '0';
	update_predictor <= '0';
	branch_taken <= '0';
	branch_pc <= (others => 'Z');
	update_value <= (others => 'Z');
	
		if (enable = '1') then
			result := (others => 'Z');
		
			case opcode_in is
			
			--LOAD
			when "000000" => 
			result := std_logic_vector((signed(op1_1)) + ("0000000000000000" & signed(imm_value)));
			load <= '1';
			
			
			--STORE
			when "000001" => 
			result := std_logic_vector((signed(op1_1)) + ("0000000000000000" & signed(imm_value)));
			
			--MOV
			when "000100" =>
				result := op1_1;
				valid <='1';
				ar_log<='1';
			
			--MOVI
			when "000101" =>
				result := "0000000000000000" & imm_value;
				valid <='1';
				ar_log<='1';
			
			--Aritmeticke i logicke instrukcije
			
			--AND
			when "010000" => 
				-- treba da modifikuje
				result := op1_1 AND op2_1;	
				
			ar_log<='1';
			valid <='1';
			
			--SUB
			when "001001" => 
				-- treba da modifikuje
				result := std_logic_vector((signed(op1_1)) - (signed(op2_1)));
				
				ar_log<='1';
				valid <='1';
				
			--SUBI
			when "001101" => 
			
				result := std_logic_vector((signed(op1_1)) - ("0000000000000000" & signed(imm_value)));
				
			ar_log<='1';
			valid <='1';
			
			--ADDI
			when "001100" => 
			
				result := std_logic_vector((signed(op1_1)) + ("0000000000000000" & signed(imm_value)));
			
			ar_log<='1';
			valid <='1';
			
			--ADD
			when "001000" => 
				-- treba da modifikuje
				result := std_logic_vector((signed(op1_1)) + (signed(op2_1)));
				ar_log<='1';
				valid <='1';
				
			--OR
			when "010001" => 
				-- treba da modifikuje
				result := std_logic_vector((unsigned(op1_1)) or (unsigned(op2_1)));
				
				
				ar_log<='1';
				valid <='1';
		
			--XOR
			when "010010" => 
				-- treba da modifikuje
				result := std_logic_vector((unsigned(op1_1)) xor (unsigned(op2_1)));
				
				ar_log<='1';
				valid <='1';
				
			--NOT
			when "010011" =>
				result := not op1_1;
				ar_log<='1';
				valid <='1';
				
			--Pomeracke instrukcije		
			--SHL
			when "011000" =>
				result := to_stdlogicvector(to_bitvector(op1_1) sll to_integer(unsigned(imm_value)));
				ar_log<='1';
				valid <='1';
			--SHR
			when "011001" =>
				result := to_stdlogicvector(to_bitvector(op1_1) srl to_integer(unsigned(imm_value)));
				ar_log<='1';
				valid <='1';
			--SAR
			when "011010" =>
				result := to_stdlogicvector(to_bitvector(op1_1) sra to_integer(unsigned(imm_value)));
				ar_log<='1';
				valid <='1';
			--ROL
			when "011011" =>
				result := to_stdlogicvector(to_bitvector(op1_1) rol to_integer(unsigned(imm_value)));
				ar_log<='1';
				valid <='1';
				--ROR
			when "011100" =>
				result := to_stdlogicvector(to_bitvector(op1_1) ror to_integer(unsigned(imm_value)));
				ar_log<='1';
				valid <='1';
				
				
			-- Instrukcije bezuslovnog skoka
			-- Skace se na PC+imm_value
			-- Salje se prediktoru update =
			--	tag = pc_addr +
			-- data = pc+imm_value
			
			--BEQ
			when "101000" =>
			
			update(63 downto 32) := pc_addr;
			update(31 downto 0) := std_logic_vector((signed(pc_addr)+1) + (signed(imm_value)));
			update_predictor <= '1';
			
			if(op1_1 = op2_1) then 
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					--flushovati instrukcije koje su u pipelineu pre ove i poslati ispravnu vrednot pc-a
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
			else
				branch_taken <= '0';
				if (branch_predicted = '1') then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= std_logic_vector(unsigned(pc_addr) + 1);
				end if;
			end if;
			
			--BNQ
			when "101001" =>
			
			update(63 downto 32) := pc_addr;
			update(31 downto 0) := std_logic_vector((signed(pc_addr)+1) + (signed(imm_value)));
			update_predictor <= '1';
			
			if(op1_1 /= op2_1) then 
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					--flushovati instrukcije koje su u pipelineu pre ove i poslati ispravnu vrednot pc-a
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
			else
				branch_taken <= '0';
				if (branch_predicted = '1') then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= std_logic_vector(unsigned(pc_addr) + 1);
				end if;
			end if;
			
			--BGT
			when "101010" =>
			
			update(63 downto 32) := pc_addr;
			update(31 downto 0) := std_logic_vector((signed(pc_addr)+1) + (signed(imm_value)));
			update_predictor <= '1';
			
			if(op1_1 > op2_1) then 
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					--flushovati instrukcije koje su u pipelineu pre ove i poslati ispravnu vrednot pc-a
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
			else
				branch_taken <= '0';
				if (branch_predicted = '1') then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= std_logic_vector(unsigned(pc_addr) + 1);
				end if;
			end if;
			
			--BLT
			when "101011" =>
			
			update(63 downto 32) := pc_addr;
			update(31 downto 0) := std_logic_vector((signed(pc_addr)+1) + (signed(imm_value)));
			update_predictor <= '1';
			
			if(op1_1 < op2_1) then 
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					--flushovati instrukcije koje su u pipelineu pre ove i poslati ispravnu vrednot pc-a
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
			else
				branch_taken <= '0';
				if (branch_predicted = '1') then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= std_logic_vector(unsigned(pc_addr) + 1);
				end if;
			end if;
			
			--BGE
			when "101100" =>
			
			update(63 downto 32) := pc_addr;
			update(31 downto 0) := std_logic_vector((signed(pc_addr)+1) + (signed(imm_value)));
			update_predictor <= '1';
			
			if(op1_1 >= op2_1) then 
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					--flushovati instrukcije koje su u pipelineu pre ove i poslati ispravnu vrednot pc-a
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
			else
				branch_taken <= '0';
				if (branch_predicted = '1') then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= std_logic_vector(unsigned(pc_addr) + 1);
				end if;
			end if;
			
			--BLE
			when "101101" =>
			
			update(63 downto 32) := pc_addr;
			update(31 downto 0) := std_logic_vector((signed(pc_addr)+1) + (signed(imm_value)));
			update_predictor <= '1';
			
			if(op1_1 <= op2_1) then 
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					--flushovati instrukcije koje su u pipelineu pre ove i poslati ispravnu vrednot pc-a
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
			else
				branch_taken <= '0';
				if (branch_predicted = '1') then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= std_logic_vector(unsigned(pc_addr) + 1);
				end if;
			end if;
			
			--JMP
			when "100000" =>
			
				update(63 downto 32) := pc_addr;
				update(31 downto 0) := std_logic_vector((signed(op1_1)) + (signed(imm_value)));
				update_predictor <= '1';
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
				
			--JSR
			when "100001" =>
				stack(to_integer(unsigned(SP))) <= std_logic_vector(unsigned(pc_addr)+1);
				SP <= std_logic_vector(unsigned(SP)+1);
				
				update(63 downto 32) := pc_addr;
				update(31 downto 0) := std_logic_vector((signed(op1_1)) + (signed(imm_value)));
				update_predictor <= '1';
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
				
			--RTS
			when "100010" =>
				
				update(63 downto 32) := pc_addr;
				update(31 downto 0) := stack(to_integer(unsigned(SP)-1));
				update_predictor <= '1';
				branch_taken <= '1';
				if (branch_predicted = '0' or pc_predicted /= update(31 downto 0)) then --nije dobro predvidjeno
					flush <= '1';
					misprediction <= '1';
					branch_pc <= update(31 downto 0);
				end if;
				stack(to_integer(unsigned(SP)-1)) <= (others=>'0');
				SP <= std_logic_vector(unsigned(SP)-1);
				
			--PUSH
			when "100100" =>
			
				stack(to_integer(unsigned(SP))) <= op1_1;
				SP <= std_logic_vector(unsigned(SP)+1);
				
			--POP
			when "100101" =>
				
				result := stack(to_integer(unsigned (SP)-1));
				ar_log<='1';
				valid <='1';
				SP <= std_logic_vector(unsigned(SP)-1);
			
			when others =>
				null;
			end case;
		
			data_alu_out <= result;
			
			update_value <= update (63 downto 0);
			
			st_value <= op2_1;
			rd_adr_out <= rd_adr;
			opcode_out <= opcode_in;
			
			
		else
			data_alu_out <= (others => 'Z');
			update_value <= (others => 'Z');
			rd_adr_out <= (others => 'Z');
			opcode_out  <= (others => 'Z');
			st_value <= (others => 'Z');
			
		end if;
	end if;
	end process;
	
	enable<= '0' when flush_id='1' or flush='1' or idle = '1' else '1';
	
end architecture;