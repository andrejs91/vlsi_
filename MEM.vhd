library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEM is 
generic(
	address_length : integer := 32;
	data_length : integer := 32;
	opcode_length : integer := 6;
	reg_code_length : integer := 5
	
);
	port(
		clk : in std_logic;
		reset: in std_logic;
		
		rd:out std_logic; --citanje iz data kesa
		wr:out std_logic;  --upis u data kes
		
		opcode : in std_logic_vector((opcode_length-1) downto 0);
		opcode_out : out std_logic_vector((opcode_length-1) downto 0);
		
	-- Izlazni signali iz ALU jedinice
	data_from_alu : in std_logic_vector((data_length - 1) downto 0); -- podatak iz alu jedinice
	
	st_value : in std_logic_vector((data_length - 1) downto 0); -- vrednost registra koja se upisuje u data kes kod store instr
	
	rd_adr: in std_logic_vector(4 downto 0); -- adresa rd reg iz exe faze
	
	rd_adr_out: out std_logic_vector(4 downto 0); -- prosledjivanje u wb fazu 
	rd_reg : out std_logic_vector(31 downto 0); -- vrednost procitana iz data kesa i prosledjuje se u wb fazu
	
	
		addr_bus: out std_logic_vector(31 downto 0); --adresa ka data kesu
		data_bus_out: out std_logic_vector(31 downto 0); --podatak ka data kesu
		data_bus_in: in std_logic_vector(31 downto 0); --podatak iz data kesa (load instr)
	
	flush_out: out std_logic;
	flush_ex: in std_logic;
	
	ar_log: in std_logic;
	load : in std_logic;
	ar_log_out: out std_logic;
	load_out : out std_logic;
	idle : in std_logic
		);
end entity;

architecture rtl of MEM is
	signal d_cache : std_logic;
	signal rd_form_alu : std_logic_vector(31 downto 0);
begin

	process (clk) is
	begin
	if(rising_edge(clk)) then
		if(idle = '0') then
		if(opcode="000000" and flush_ex='0' )then -- load 
			d_cache <= '1';
		else
			d_cache <= '0';
		end if;
	
		flush_out<=flush_ex;
		rd_form_alu <= data_from_alu;
		rd_adr_out <= rd_adr;
		opcode_out <= opcode;
		ar_log_out <= ar_log;
		load_out <= load;
		end if;
	end if;
	end process;
	rd_reg <=data_bus_in when d_cache = '1' else rd_form_alu;
	addr_bus <= data_from_alu when (opcode="000000" or opcode="000001") and flush_ex='0' else (others => 'Z'); --adresa za citanje iz data mem
	data_bus_out <= st_value when opcode="000001" and flush_ex='0' else (others => 'Z');
	rd <= '1' when opcode="000000" and flush_ex='0' and idle = '0' else '0';
	wr <= '1' when opcode="000001" and flush_ex='0' and idle = '0' else '0';
	
	end architecture;
	
