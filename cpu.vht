
LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY cpu_vhd_tst IS
generic
	(
		addr_length: integer := 32;
		data_length : integer := 32;
		data_cache_size: integer := 1000;
		instr_length : integer := 32;
		instr_cache_size: integer := 2000
	);
END cpu_vhd_tst;
ARCHITECTURE cpu_arch OF cpu_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL addr_bus : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL clk : STD_LOGIC;
SIGNAL data_bus_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL data_bus_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL IF_addr : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL initial_PC : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL instr_IF_cache : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL ird : STD_LOGIC;
SIGNAL rd_mem : STD_LOGIC;
SIGNAL reset : STD_LOGIC;
SIGNAL wr_mem : STD_LOGIC;
signal stop : std_LOGIC;



COMPONENT cpu
	PORT (
	addr_bus : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	clk : IN STD_LOGIC;
	data_bus_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	data_bus_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	IF_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	initial_PC : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	instr_IF_cache : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	ird : OUT STD_LOGIC;
	rd_mem : OUT STD_LOGIC;
	reset : IN STD_LOGIC;
	wr_mem : OUT STD_LOGIC;
	stop : out std_logic
	);
END COMPONENT;

COMPONENT InstrCache
	port
	(
		clk: in std_logic;
		rd: in std_logic;
		addr: in std_logic_vector((addr_length - 1) downto 0);
		instr: out std_logic_vector((instr_length - 1) downto 0) := (others =>'Z');
		initial_PC : out std_logic_vector((addr_length - 1) downto 0)
	);
end component;

component DataCache
	port
	(
	clk: in std_logic;
	rd: in std_logic;
	wr: in std_logic;
	
	addr: in std_logic_vector((addr_length - 1) downto 0);
	data_in: in std_logic_vector((data_length - 1) downto 0);
	data_out: out std_logic_vector((data_length - 1) downto 0) := (others =>'Z');
	idle: in std_logic
	);
end component;
BEGIN
	i1 : cpu
	PORT MAP (
-- list connections between master ports and signals
	addr_bus => addr_bus,
	clk => clk,
	data_bus_in => data_bus_in,
	data_bus_out => data_bus_out,
	IF_addr => IF_addr,
	initial_PC => initial_PC,
	instr_IF_cache => instr_IF_cache,
	ird => ird,
	rd_mem => rd_mem,
	reset => reset,
	wr_mem => wr_mem,
	stop => stop
	);
	icache : InstrCache
	port map (
	clk => clk,
	rd => ird,
	addr => IF_addr,
	instr => instr_IF_cache,
	initial_PC => initial_PC
	);
	dcache : DataCache
	port map (
	clk => clk,
	rd => rd_mem,
	wr => wr_mem,
	
	addr => addr_bus,
	data_in => data_bus_out,
	data_out => data_bus_in,
	idle => stop
	);
	
init : PROCESS  
	variable clk_next : std_logic := '1';
BEGIN
	reset <= '1';
	clk <= '0';
	wait for 5 ns;
	reset <= '0';
	wait for 5 ns;
	loop
		clk <= clk_next;
		clk_next := not clk_next;
		wait for 5 ns;
	end loop;                                             
END PROCESS init;                                           
always : PROCESS                                              
-- optional sensitivity list                                  
-- (        )                                                 
-- variable declarations                                      
BEGIN                                                         
        -- code executes for every event on sensitivity list  
WAIT;                                                        
END PROCESS always;                                          
END cpu_arch;
